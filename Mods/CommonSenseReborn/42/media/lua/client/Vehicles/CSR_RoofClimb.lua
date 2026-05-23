--
-- CSR_RoofClimb (client)
-- =========================================================================
-- Lets the player scramble onto the roof of a parked vehicle for a higher
-- vantage point. Right-click the vehicle and pick "Climb onto roof".
--
-- Design notes:
-- * No per-vehicle hardcoded offset table. Roof anchor uses the vehicle's
--   own coordinates (it already accounts for length/width). Tall vehicles
--   are detected at runtime from the vehicle script extents.
-- * No custom animation XMLs. We use the vanilla "Loot" anim during the
--   timed climb action.
-- * Player position is pinned via Events.OnPlayerUpdate while the modData
--   csrOnVehicleRoof entry is set. Pin is read-only on the server -- the
--   client owns visual position; modData is the persistent truth.
-- * If the vehicle drives, despawns, or the player loads in already on a
--   roof, we drop them safely back to ground.
-- =========================================================================

CSR_RoofClimb = CSR_RoofClimb or {}

local CSR_FeatureFlags = CSR_FeatureFlags
local TALL_EXTENTS_Z = 0.85   -- vans/pickups/trucks above this
local DRIVE_AWAY_KMH = 8      -- > this and you fall
local HOLD_ON_KMH    = 3      -- > this triggers a "Hold on!" warning
local PEER_VISUAL_SYNC_TICKS = 3

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

-- =========================================================================
-- Vehicle classification (no per-script lookup table)
-- =========================================================================

local function isTallVehicle(vehicle)
    if not vehicle or not vehicle.getScript then return false end
    local script = vehicle:getScript()
    if not script then return false end
    local ok, extents = pcall(function() return script:getExtents() end)
    if not ok or not extents then return false end
    local z = 0
    pcall(function() z = extents:z() end)
    return z > TALL_EXTENTS_Z
end

local function getRoofZ(vehicle)
    -- Vehicle Z is the ground square; roof position sits one floor above.
    -- Sedans look bad with the full +1 lift because their visual roof is
    -- closer to ~0.6, so we taper a little for short cars while keeping
    -- vans/trucks at the full storey height.
    local base = vehicle:getZ() or 0
    if isTallVehicle(vehicle) then return base + 1 end
    return base + 0.85
end

-- Roof footprint radius (in tiles) the player can wander while standing
-- on top. Bigger than the car's grid square so they can step around the
-- hood/bed without the per-tick pin yanking them back to the centre.
local ROOF_RADIUS_TILES = 2.5
local ROOF_RADIUS_TALL  = 3.0

local function getRoofRadius(vehicle)
    return isTallVehicle(vehicle) and ROOF_RADIUS_TALL or ROOF_RADIUS_TILES
end

-- =========================================================================
-- Mount / Dismount (called from CSR_ClimbVehicleAction:perform)
-- =========================================================================

-- Clear the vanilla falling state. Without this the engine keeps the
-- player in a continuous fall animation even though we've pinned them to
-- the roof Z, so they look stuck mid-fall until they dismount.
local function clearFallingState(player)
    pcall(function()
        if type(player.setbFalling) == "function" then player:setbFalling(false) end
        if type(player.setFallTime) == "function" then player:setFallTime(0) end
        if type(player.setLastFallSpeed) == "function" then player:setLastFallSpeed(0) end
        if type(player.setOnFloor) == "function" then player:setOnFloor(true) end
    end)
end

function CSR_RoofClimb.applyMount(player, vehicle)
    if not player or not vehicle then return end
    local md = player:getModData()
    md.csrOnVehicleRoof = {
        vehicleId = vehicle:getId(),
        startedAt = getTimestamp and getTimestamp() or 0,
    }
    player:setX(vehicle:getX())
    player:setY(vehicle:getY())
    player:setZ(getRoofZ(vehicle))
    clearFallingState(player)
    if isClient and isClient() then
        sendClientCommand(player, "CommonSenseReborn", "RoofClimbSet", {
            vehicleId = vehicle:getId(),
        })
    end
    if player.transmitModData then player:transmitModData() end
end

function CSR_RoofClimb.applyDismount(player)
    if not player then return end
    local md = player:getModData()
    md.csrOnVehicleRoof = nil
    -- Drop to the ground square Z, not blind 0 -- some map tiles sit at
    -- raised baselines and snapping to 0 would also leave them mid-air.
    local groundZ = 0
    pcall(function()
        local cell = getCell()
        if cell then
            local sq = cell:getGridSquare(player:getX(), player:getY(), 0)
            if sq then groundZ = sq:getZ() or 0 end
        end
    end)
    player:setZ(groundZ)
    clearFallingState(player)
    if isClient and isClient() then
        sendClientCommand(player, "CommonSenseReborn", "RoofClimbClear", {})
    end
    if player.transmitModData then player:transmitModData() end
end

-- =========================================================================
-- Per-tick pin + drive-away handling
-- =========================================================================

local _haltOnce = {}

local function applyFallDamage(player, severe)
    local bd = player and player:getBodyDamage()
    if not bd then return end
    local part = severe and BodyPartType.Foot_R or BodyPartType.Foot_L
    bd:AddDamage(BodyPartType.Hand_L, 8 + ZombRand(8))
    if severe then
        local foot = bd:getBodyPart(part)
        if foot and foot.setFractureTime then foot:setFractureTime(20.0) end
        bd:AddDamage(BodyPartType.UpperLeg_R, 12 + ZombRand(10))
    end
end

local function dropToGround(player, severe)
    if not player then return end
    local md = player:getModData()
    md.csrOnVehicleRoof = nil
    player:setZ(0)
    player:setOnFloor(true)
    if severe and sandbox().RoofClimbFallDamage ~= false then
        applyFallDamage(player, true)
        if player.Say then player:Say(getText("IGUI_CSR_RoofClimbFell")) end
    end
    if isClient and isClient() then
        sendClientCommand(player, "CommonSenseReborn", "RoofClimbClear", {})
    end
    if player.transmitModData then player:transmitModData() end
end

-- Events.OnPlayerUpdate fires the callback with a single argument (the
-- IsoPlayer). The previous signature `(playerIndex, player)` made `player`
-- always nil, so the early-return at the top turned the entire roof-pin
-- loop into a no-op: the player never actually got pinned to the vehicle,
-- never fell when the vehicle drove away, and zombie-visibility reduction
-- ran but with no movement enforcement.
local function pinTick(player)
    if not player then return end
    local md = player:getModData()
    local state = md.csrOnVehicleRoof
    if not state then
        _haltOnce[player] = nil
        return
    end
    -- Vehicle gone? drop player.
    local vehicle = state.vehicleId and getVehicleById and getVehicleById(state.vehicleId) or nil
    if not vehicle or not vehicle:getCurrentSquare() then
        dropToGround(player, false)
        return
    end
    -- Sit/sprint/seat exit: clear the flag.
    if player:getVehicle() then
        md.csrOnVehicleRoof = nil
        return
    end
    -- Driving away?
    local speed = math.abs(vehicle:getCurrentSpeedKmHour() or 0)
    if speed > DRIVE_AWAY_KMH then
        dropToGround(player, true)
        return
    end
    if speed > HOLD_ON_KMH and not _haltOnce[player] then
        _haltOnce[player] = true
        if player.Say then player:Say(getText("IGUI_CSR_RoofClimbHoldOn")) end
    end
    -- Allow the player to walk freely within a small footprint above the
    -- vehicle. Only the Z axis is enforced every tick; if they stray
    -- outside the roof radius we drop them off the side.
    local dx = (player:getX() or 0) - (vehicle:getX() or 0)
    local dy = (player:getY() or 0) - (vehicle:getY() or 0)
    local distSq = dx * dx + dy * dy
    local r = getRoofRadius(vehicle)
    if distSq > (r * r) then
        dropToGround(player, false)
        return
    end
    player:setZ(getRoofZ(vehicle))
    pcall(function()
        if type(player.setbFalling) == "function" then player:setbFalling(false) end
        if type(player.setFallTime) == "function" then player:setFallTime(0) end
        if type(player.setLastFallSpeed) == "function" then player:setLastFallSpeed(0) end
        if type(player.setOnFloor) == "function" then player:setOnFloor(true) end
    end)
end

Events.OnPlayerUpdate.Add(pinTick)

-- =========================================================================
-- Same-roof peer visual sync
-- =========================================================================

CSR_RoofClimb.peerRoofStates = CSR_RoofClimb.peerRoofStates or {}
local _peerPinned = {}
local _peerTickCounter = 0
local _peerRosterRequested = false

local function isPeerVisualSyncEnabled()
    return isClient and isClient()
        and sandbox().RoofClimbPeerVisualSync == true
end

local function getOnlineId(player)
    return player and player.getOnlineID and player:getOnlineID() or nil
end

local function isLocalOnlineId(onlineId)
    if not onlineId then return false end
    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, count - 1 do
        local localPlayer = getSpecificPlayer(i)
        if getOnlineId(localPlayer) == onlineId then
            return true
        end
    end
    return false
end

local function localPlayerIsOnVehicleRoof(vehicleId)
    if not vehicleId then return false end
    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, count - 1 do
        local localPlayer = getSpecificPlayer(i)
        local md = localPlayer and localPlayer.getModData and localPlayer:getModData() or nil
        local state = md and md.csrOnVehicleRoof or nil
        if state and tonumber(state.vehicleId) == tonumber(vehicleId) then
            return true
        end
    end
    return false
end

local function findOnlinePlayerById(onlineId)
    if not onlineId or not getOnlinePlayers then return nil end
    local players = getOnlinePlayers()
    if not players then return nil end
    for i = 0, players:size() - 1 do
        local candidate = players:get(i)
        if getOnlineId(candidate) == onlineId then
            return candidate
        end
    end
    return nil
end

local function setRemoteRoofZ(remotePlayer, vehicle)
    if not remotePlayer or not vehicle then return end
    if not remotePlayer.getZ or not remotePlayer.setZ then return end

    local roofZ = getRoofZ(vehicle)
    local currentZ = remotePlayer:getZ() or 0
    if math.abs(currentZ - roofZ) > 0.05 then
        remotePlayer:setZ(roofZ)
    end
    clearFallingState(remotePlayer)
end

local function clearRemoteRoofZ(remotePlayer, vehicle)
    if not remotePlayer or not vehicle or not remotePlayer.setZ then return end
    remotePlayer:setZ(vehicle:getZ() or 0)
    clearFallingState(remotePlayer)
end

local function onRoofPeerSync(args)
    if not args then return end

    local onlineId = tonumber(args.playerOnlineID)
    if not onlineId then return end

    if args.active then
        local vehicleId = tonumber(args.vehicleId)
        if vehicleId then
            CSR_RoofClimb.peerRoofStates[onlineId] = {
                vehicleId = vehicleId,
            }
        end
        return
    end

    local previous = CSR_RoofClimb.peerRoofStates[onlineId]
    if previous and _peerPinned[onlineId] then
        local vehicle = getVehicleById and getVehicleById(previous.vehicleId) or nil
        clearRemoteRoofZ(findOnlinePlayerById(onlineId), vehicle)
    end
    CSR_RoofClimb.peerRoofStates[onlineId] = nil
    _peerPinned[onlineId] = nil
end

local function tableHasAny(t)
    if not t then return false end
    for _ in pairs(t) do
        return true
    end
    return false
end

local function peerVisualTick()
    if not isPeerVisualSyncEnabled() then return end
    if not tableHasAny(CSR_RoofClimb.peerRoofStates) and not tableHasAny(_peerPinned) then return end

    _peerTickCounter = _peerTickCounter + 1
    if _peerTickCounter < PEER_VISUAL_SYNC_TICKS then return end
    _peerTickCounter = 0

    for onlineId, state in pairs(CSR_RoofClimb.peerRoofStates) do
        if not isLocalOnlineId(onlineId) then
            local vehicleId = state and tonumber(state.vehicleId) or nil
            local vehicle = vehicleId and getVehicleById and getVehicleById(vehicleId) or nil
            local remotePlayer = findOnlinePlayerById(onlineId)

            if not vehicle then
                CSR_RoofClimb.peerRoofStates[onlineId] = nil
                _peerPinned[onlineId] = nil
            elseif remotePlayer and localPlayerIsOnVehicleRoof(vehicleId) then
                setRemoteRoofZ(remotePlayer, vehicle)
                _peerPinned[onlineId] = vehicleId
            elseif _peerPinned[onlineId] then
                clearRemoteRoofZ(remotePlayer, vehicle)
                _peerPinned[onlineId] = nil
            end
        end
    end
end

local function requestRoofPeerRoster()
    if _peerRosterRequested or not isPeerVisualSyncEnabled() then return end
    local localPlayer = getSpecificPlayer(0)
    if not localPlayer then return end
    sendClientCommand(localPlayer, "CommonSenseReborn", "RoofClimbRequestRoster", {})
    _peerRosterRequested = true
end

local function onRoofServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    if command ~= "RoofClimbPeerSync" then return end
    if not isPeerVisualSyncEnabled() then return end
    onRoofPeerSync(args)
end

if Events.OnTick then Events.OnTick.Add(peerVisualTick) end
if Events.OnServerCommand then Events.OnServerCommand.Add(onRoofServerCommand) end
if Events.OnGameStart then Events.OnGameStart.Add(requestRoofPeerRoster) end

-- =========================================================================
-- Reduce zombie sight while on roof (sandbox-tunable)
-- =========================================================================

local _origGetVisualDist = nil
if IsoZombie and IsoZombie.getVisualDistance and not IsoZombie.__csr_roofVisPatched then
    IsoZombie.__csr_roofVisPatched = true
    _origGetVisualDist = IsoZombie.getVisualDistance
    function IsoZombie:getVisualDistance(target)
        local base = _origGetVisualDist(self, target)
        if target and target.getModData then
            local ok, md = pcall(target.getModData, target)
            if ok and md and md.csrOnVehicleRoof then
                local pct = sandbox().RoofClimbZombieVisibility or 50
                if pct < 100 then
                    return (base or 0) * (pct / 100)
                end
            end
        end
        return base
    end
end

-- =========================================================================
-- Context menu
-- =========================================================================

local function getNearestParkedVehicle(player)
    local v = player.getNearVehicle and player:getNearVehicle() or nil
    if not v then return nil end
    if math.abs(v:getCurrentSpeedKmHour() or 0) > 0.2 then return nil end
    return v
end

local function canClimbCheck(player, vehicle)
    if player:getVehicle() then return false, getText("IGUI_CSR_RoofClimbDriving") end
    local stats = player:getStats()
    if stats and stats.getEndurance and stats:getEndurance() < 0.05 then
        return false, getText("IGUI_CSR_RoofClimbTired")
    end
    local strength = player:getPerkLevel(Perks.Strength) or 0
    local needed = isTallVehicle(vehicle)
        and (sandbox().RoofClimbTallStrengthRequired or 5)
        or  (sandbox().RoofClimbStrengthRequired or 3)
    if strength < needed then
        if isTallVehicle(vehicle) then
            return false, getText("IGUI_CSR_RoofClimbTooTall")
        end
        return false, getText("IGUI_CSR_RoofClimbTooWeak")
    end
    return true, nil
end

local function startClimbUp(worldobjects, player, vehicle)
    local obj = (type(player) == "number") and getSpecificPlayer(player) or player
    if not obj or not vehicle then return end
    local ok, why = canClimbCheck(obj, vehicle)
    if not ok then
        obj:Say(why or "")
        return
    end
    if ISTimedActionQueue.isPlayerDoingAction(obj) then
        ISTimedActionQueue.clear(obj)
    end
    -- Step adjacent to the vehicle first using vanilla path action.
    local sq = vehicle:getCurrentSquare()
    if sq then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(obj, sq))
    end
    ISTimedActionQueue.add(CSR_ClimbVehicleAction:new(obj, vehicle, "up", 60))
end

local function startClimbDown(worldobjects, player, vehicle)
    local obj = (type(player) == "number") and getSpecificPlayer(player) or player
    if not obj then return end
    if ISTimedActionQueue.isPlayerDoingAction(obj) then
        ISTimedActionQueue.clear(obj)
    end
    ISTimedActionQueue.add(CSR_ClimbVehicleAction:new(obj, vehicle, "down", 30))
end

local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isRoofClimbEnabled() then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local md = player:getModData()
    if md.csrOnVehicleRoof then
        -- Already on a roof: offer climb-down on any vehicle context menu.
        local v = md.csrOnVehicleRoof.vehicleId
            and getVehicleById and getVehicleById(md.csrOnVehicleRoof.vehicleId) or nil
        if v then
            context:addOption(getText("IGUI_CSR_RoofClimbDown"), worldobjects, startClimbDown, player, v)
        end
        return
    end

    local vehicle
    for i = 1, #worldobjects do
        local obj = worldobjects[i]
        if obj and instanceof(obj, "BaseVehicle") then
            vehicle = obj
            break
        end
    end
    if not vehicle then
        vehicle = getNearestParkedVehicle(player)
    end
    if not vehicle then return end
    if math.abs(vehicle:getCurrentSpeedKmHour() or 0) > 0.2 then return end
    -- Don't offer if player is currently in this vehicle.
    if player:getVehicle() == vehicle then return end

    local opt = context:addOption(getText("IGUI_CSR_RoofClimbUp"), worldobjects, startClimbUp, player, vehicle)
    local ok, why = canClimbCheck(player, vehicle)
    if not ok then
        opt.notAvailable = true
        local tt = ISWorldObjectContextMenu.addToolTip()
        tt.description = why or ""
        opt.toolTip = tt
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

-- =========================================================================
-- Reconnect / load safety: if modData says we were on a roof, validate it.
-- =========================================================================

local function onCreatePlayer(playerIndex, player)
    if not player then return end
    local md = player:getModData()
    if not md.csrOnVehicleRoof then return end
    -- Validate later (vehicle may not be loaded yet); pinTick handles it.
    requestRoofPeerRoster()
end

Events.OnCreatePlayer.Add(onCreatePlayer)

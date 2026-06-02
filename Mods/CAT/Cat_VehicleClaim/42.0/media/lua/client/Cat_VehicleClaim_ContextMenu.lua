-- =============================================================================
-- Cat Vehicle Claim — Client (context menus, radial menu hooks, timed actions)
-- =============================================================================
if isServer() then return end

Cat_VehicleClaim = Cat_VehicleClaim or {}
Cat_VehicleClaim.claims = Cat_VehicleClaim.claims or {}

-- ---------------------------------------------------------------------------
-- Server response handler
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= "Cat_VehicleClaim" then return end

    if command == "syncClaim" then
        Cat_VehicleClaim._initialSyncComplete = true
        local vid = args.vehicleId
        if args.owner ~= nil then
            Cat_VehicleClaim.claims[vid] = {
                owner = args.owner,
                guests = args.guests or {},
                everyone = args.everyone or nil,
                name = args.name,
            }
        else
            -- Explicitly store "unclaimed" so we don't re-request every right-click
            Cat_VehicleClaim.claims[vid] = {
                owner = false,
                guests = {},
                everyone = nil,
                name = args.name,
            }
        end
        -- Refresh UI if open
        if Cat_VehicleClaim._permissionsUI and Cat_VehicleClaim._permissionsUI.vehicleId == vid then
            Cat_VehicleClaim._permissionsUI:refreshData()
        end
        if Cat_VehicleClaim._myVehiclesUI then
            Cat_VehicleClaim._myVehiclesUI:refreshData()
        end

    elseif command == "syncComplete" then
        Cat_VehicleClaim._initialSyncComplete = true
        print("[Cat_VehicleClaim] Initial sync complete from server.")

    elseif command == "haloText" then
        local player = getSpecificPlayer(0)
        if player then
            if args.bad then
                HaloTextHelper.addBadText(player, args.text or "")
            else
                HaloTextHelper.addGoodText(player, args.text or "")
            end
        end
    end
end
Events.OnServerCommand.Add(onServerCommand)

-- ---------------------------------------------------------------------------
-- Request full sync on join / reconnect / new character
-- ---------------------------------------------------------------------------
Cat_VehicleClaim._initialSyncComplete = false

local function requestFullSync()
    if not getPlayer() then return end
    sendClientCommand("Cat_VehicleClaim", "requestFullSync", {})
end

Events.OnGameStart.Add(requestFullSync)
Events.OnCreatePlayer.Add(requestFullSync)

if getPlayer() then
    requestFullSync()
end

-- Aggressive retry every 30 ticks (~0.5s) for the first 10 seconds
local syncTickCount = 0
local function aggressiveSyncTick()
    if Cat_VehicleClaim._initialSyncComplete then
        Events.OnTick.Remove(aggressiveSyncTick)
        return
    end
    syncTickCount = syncTickCount + 1
    if syncTickCount % 30 == 0 then
        requestFullSync()
    end
    if syncTickCount >= 600 then -- 10 seconds, give up
        Cat_VehicleClaim._initialSyncComplete = true
        Events.OnTick.Remove(aggressiveSyncTick)
        print("[Cat_VehicleClaim] Sync timeout — allowing fallback.")
    end
end
Events.OnTick.Add(aggressiveSyncTick)

-- ---------------------------------------------------------------------------
-- Context menu hook (right-click on vehicle)
-- ---------------------------------------------------------------------------
local original_FillMenuOutsideVehicle = ISVehicleMenu.FillMenuOutsideVehicle
function ISVehicleMenu.FillMenuOutsideVehicle(player, context, vehicle, test)
    original_FillMenuOutsideVehicle(player, context, vehicle, test)
    if test then return end
    if not vehicle then return end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    -- Remove Vehicle Repair Overhaul "Salvage Vehicle" option if no mechanics permission
    if ISVehicleMenu.onVehicleSalvage then
        if not Cat_VehicleClaim.canUseMechanics(playerObj, vehicle) then
            context:removeOptionByName(getText("ContextMenu_SalvageVehicle"))
        end
    end

    local vid = Cat_VehicleClaim.getVehicleIdentifier(vehicle)
    local claim = Cat_VehicleClaim.claims[vid]

    if claim == nil then
        -- We haven't received sync data yet; request it in the background
        sendClientCommand("Cat_VehicleClaim", "requestClaim", { vehicleId = vid })
        -- Optimistic fallback: assume unclaimed (server will reject if actually claimed)
        context:addOption("Claim Vehicle", vehicle, function(v)
            local script = v:getScript()
            local rawName = script and (script:getCarModelName() or script:getName()) or nil
            local name = rawName and getText("IGUI_VehicleName" .. rawName) or rawName
            sendClientCommand("Cat_VehicleClaim", "claimVehicle", {
                vehicleId = Cat_VehicleClaim.getVehicleIdentifier(v),
                name = name,
            })
        end)
    elseif not claim.owner then
        context:addOption("Claim Vehicle", vehicle, function(v)
            local script = v:getScript()
            local rawName = script and (script:getCarModelName() or script:getName()) or nil
            local name = rawName and getText("IGUI_VehicleName" .. rawName) or rawName
            sendClientCommand("Cat_VehicleClaim", "claimVehicle", {
                vehicleId = Cat_VehicleClaim.getVehicleIdentifier(v),
                name = name,
            })
        end)
    elseif claim.owner == playerObj:getUsername() or Cat_VehicleClaim.isAdmin(playerObj) then
        context:addOption("Manage Permissions...", vehicle, function(v)
            Cat_VehicleClaim.OpenPermissionsUI(v)
        end)
        context:addOption("Unclaim Vehicle", vehicle, function(v)
            sendClientCommand("Cat_VehicleClaim", "unclaimVehicle", { vehicleId = Cat_VehicleClaim.getVehicleIdentifier(v) })
        end)
    else
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = "This vehicle is claimed by " .. tostring(claim.owner) .. "."
        local opt = context:addOption("Claimed by " .. tostring(claim.owner), nil, nil)
        opt.notAvailable = true
        opt.toolTip = tooltip
    end
end

-- ---------------------------------------------------------------------------
-- Radial menu hook (Q / V menu)
-- ---------------------------------------------------------------------------
local original_showRadialMenuOutside = ISVehicleMenu.showRadialMenuOutside
function ISVehicleMenu.showRadialMenuOutside(playerObj)
    local playerIndex = playerObj:getPlayerNum()
    local menu = getPlayerRadialMenu(playerIndex)

    local vehicle = ISVehicleMenu.getVehicleToInteractWith(playerObj)
    local canMech = true
    local canEnter = true
    local canTrunk = true

    if vehicle then
        canMech = Cat_VehicleClaim.canUseMechanics(playerObj, vehicle)
        canEnter = Cat_VehicleClaim.canEnter(playerObj, vehicle)
        canTrunk = Cat_VehicleClaim.canUseTrunk(playerObj, vehicle)
    end

    local original_addSlice = menu.addSlice
    menu.addSlice = function(self, text, texture, onSelect, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        if not canMech and text == getText("ContextMenu_VehicleMechanics") then
            return nil
        end
        if not canEnter and text == getText("IGUI_EnterVehicle") then
            return nil
        end
        if not canEnter then
            -- Hide smash-window slice for non-passengers
            if onSelect == ISVehiclePartMenu.onSmashWindow then
                return nil
            end
        end
        if not canMech then
            -- Hide fuel add/siphon slices for non-mechanics
            if onSelect == ISVehiclePartMenu.onAddGasoline or onSelect == ISVehiclePartMenu.onTakeGasoline then
                return nil
            end
        end
        if not canTrunk then
            if text == getText("IGUI_OpenTrunk") or text == getText("IGUI_CloseTrunk")
               or text == getText("IGUI_UnlockTrunk") or text == getText("IGUI_LockTrunk") then
                return nil
            end
            if (onSelect == ISVehicleMenu.onOpenDoor or onSelect == ISVehicleMenu.onCloseDoor
                or onSelect == ISVehicleMenu.onUnlockDoor or onSelect == ISVehicleMenu.onLockDoor)
                and arg2 and arg2.getId then
                local part = arg2
                local pid = part:getId()
                if pid == "TrunkDoor" or pid == "DoorRear" then
                    return nil
                end
            end
        end
        return original_addSlice(self, text, texture, onSelect, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    end

    original_showRadialMenuOutside(playerObj)
    menu.addSlice = original_addSlice
end

-- ---------------------------------------------------------------------------
-- Mechanics callback hook
-- ---------------------------------------------------------------------------
local original_onMechanic = ISVehicleMenu.onMechanic
function ISVehicleMenu.onMechanic(playerObj, vehicle)
    if not Cat_VehicleClaim.canUseMechanics(playerObj, vehicle) then
        HaloTextHelper.addBadText(playerObj, "You do not have permission to use mechanics on this vehicle.")
        return
    end
    original_onMechanic(playerObj, vehicle)
end

-- ---------------------------------------------------------------------------
-- Enter vehicle callback hook
-- ---------------------------------------------------------------------------
local original_onShowSeatUI = ISVehicleMenu.onShowSeatUI
function ISVehicleMenu.onShowSeatUI(playerObj, vehicle)
    if not Cat_VehicleClaim.canEnter(playerObj, vehicle) then
        HaloTextHelper.addBadText(playerObj, "You do not have permission to enter this vehicle.")
        return
    end
    original_onShowSeatUI(playerObj, vehicle)
end

-- ---------------------------------------------------------------------------
-- Door open callback hook (all doors)
-- ---------------------------------------------------------------------------
local original_onOpenDoor = ISVehicleMenu.onOpenDoor
function ISVehicleMenu.onOpenDoor(playerObj, part)
    if part then
        local id = part:getId()
        local vehicle = part:getVehicle()
        if id == "TrunkDoor" or id == "DoorRear" then
            if not Cat_VehicleClaim.canUseTrunk(playerObj, vehicle) then
                HaloTextHelper.addBadText(playerObj, "You do not have permission to access this trunk.")
                return
            end
        elseif id == "EngineDoor" then
            if not Cat_VehicleClaim.canUseMechanics(playerObj, vehicle) then
                HaloTextHelper.addBadText(playerObj, "You do not have permission to use mechanics on this vehicle.")
                return
            end
        else
            -- Passenger doors
            if not Cat_VehicleClaim.canEnter(playerObj, vehicle) then
                HaloTextHelper.addBadText(playerObj, "You do not have permission to enter this vehicle.")
                return
            end
        end
    end
    original_onOpenDoor(playerObj, part)
end

-- ---------------------------------------------------------------------------
-- Timed action: Enter vehicle
-- ---------------------------------------------------------------------------
local original_ISEnterVehicle_isValid = ISEnterVehicle.isValid
function ISEnterVehicle:isValid()
    if not original_ISEnterVehicle_isValid(self) then return false end
    if not Cat_VehicleClaim.canEnter(self.character, self.vehicle) then
        return false
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Timed action: Open mechanics UI
-- ---------------------------------------------------------------------------
local original_ISOpenMechanicsUIAction_isValid = ISOpenMechanicsUIAction.isValid
function ISOpenMechanicsUIAction:isValid()
    if not original_ISOpenMechanicsUIAction_isValid(self) then return false end
    if not Cat_VehicleClaim.canUseMechanics(self.character, self.vehicle) then
        return false
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Timed action: Open vehicle door (all doors)
-- ---------------------------------------------------------------------------
local original_ISOpenVehicleDoor_isValid = ISOpenVehicleDoor.isValid
function ISOpenVehicleDoor:isValid()
    if not original_ISOpenVehicleDoor_isValid(self) then return false end
    if self.part then
        local id = self.part:getId()
        if id == "TrunkDoor" or id == "DoorRear" then
            if not Cat_VehicleClaim.canUseTrunk(self.character, self.vehicle) then
                return false
            end
        elseif id == "EngineDoor" then
            if not Cat_VehicleClaim.canUseMechanics(self.character, self.vehicle) then
                return false
            end
        else
            -- Passenger doors
            if not Cat_VehicleClaim.canEnter(self.character, self.vehicle) then
                return false
            end
        end
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Timed action: Close vehicle door (all doors)
-- ---------------------------------------------------------------------------
local original_ISCloseVehicleDoor_isValid = ISCloseVehicleDoor.isValid
function ISCloseVehicleDoor:isValid()
    if not original_ISCloseVehicleDoor_isValid(self) then return false end
    if self.part then
        local id = self.part:getId()
        if id == "TrunkDoor" or id == "DoorRear" then
            if not Cat_VehicleClaim.canUseTrunk(self.character, self.vehicle) then
                return false
            end
        elseif id == "EngineDoor" then
            if not Cat_VehicleClaim.canUseMechanics(self.character, self.vehicle) then
                return false
            end
        else
            -- Passenger doors
            if not Cat_VehicleClaim.canEnter(self.character, self.vehicle) then
                return false
            end
        end
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Timed action: Smash vehicle window
-- ---------------------------------------------------------------------------
local original_ISSmashVehicleWindow_isValid = ISSmashVehicleWindow.isValid
function ISSmashVehicleWindow:isValid()
    if not original_ISSmashVehicleWindow_isValid(self) then return false end
    if self.vehicle and not Cat_VehicleClaim.canEnter(self.character, self.vehicle) then
        return false
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Timed action: Add gasoline to vehicle
-- ---------------------------------------------------------------------------
local original_ISAddGasolineToVehicle_isValid = ISAddGasolineToVehicle.isValid
function ISAddGasolineToVehicle:isValid()
    if not original_ISAddGasolineToVehicle_isValid(self) then return false end
    if self.vehicle and not Cat_VehicleClaim.canUseMechanics(self.character, self.vehicle) then
        return false
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Timed action: Take gasoline from vehicle (siphon)
-- ---------------------------------------------------------------------------
local original_ISTakeGasolineFromVehicle_isValid = ISTakeGasolineFromVehicle.isValid
function ISTakeGasolineFromVehicle:isValid()
    if not original_ISTakeGasolineFromVehicle_isValid(self) then return false end
    if self.vehicle and not Cat_VehicleClaim.canUseMechanics(self.character, self.vehicle) then
        return false
    end
    return true
end

print("[Cat_VehicleClaim] Client context menu loaded.")

-- ---------------------------------------------------------------------------
-- Global context menu: Manage Vehicles (always available)
-- ---------------------------------------------------------------------------
local function addGlobalVehicleMenu(playerNum, context, worldObjects, test)
    if test then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    context:addOption("Manage Vehicles", nil, function()
        Cat_VehicleClaim.OpenMyVehiclesUI()
    end)
end
Events.OnFillWorldObjectContextMenu.Add(addGlobalVehicleMenu)

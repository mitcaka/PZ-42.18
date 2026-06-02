require "CSR_FeatureFlags"
require "CSR_VehicleClaim"

--[[
    CSR_VehicleClaimClient.lua
    Adds "Claim Vehicle" / "Unclaim Vehicle" slices to the vehicle radial menu.
    In MP, claim/unclaim is sent as a server command. In SP, it's instant.
]]

CSR_VehicleClaimClient = CSR_VehicleClaimClient or {}

local MODULE = "CommonSenseReborn"

local function notify(playerObj, text)
    if not playerObj then return end
    if HaloTextHelper and HaloTextHelper.addTextWithArrow then
        HaloTextHelper.addTextWithArrow(playerObj, text, true, HaloTextHelper.getColorGreen())
    elseif playerObj.Say then
        playerObj:Say(text)
    end
end

local function notifyError(playerObj, text)
    if not playerObj then return end
    if HaloTextHelper and HaloTextHelper.addTextWithArrow then
        HaloTextHelper.addTextWithArrow(playerObj, text, false, HaloTextHelper.getColorRed())
    elseif playerObj.Say then
        playerObj:Say(text)
    end
end

local function commandArgsForVehicle(vehicle)
    if not vehicle then return {} end
    local key = ""
    if CSR_VehicleClaim and CSR_VehicleClaim.getVehicleKey then
        key = CSR_VehicleClaim.getVehicleKey(vehicle, false) or ""
    end
    return {
        vehicleKey = key,
    }
end

local function vehicleIsHotwired(vehicle)
    return vehicle and vehicle.isHotwired and vehicle:isHotwired() == true
end

local function onlinePlayerNames(playerObj, allowed)
    local out = {}
    local seen = {}
    local myName = playerObj and playerObj.getUsername and tostring(playerObj:getUsername() or "") or ""
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players or not players.size or not players.get then return out end
    local count = tonumber(players:size()) or 0
    for i = 0, count - 1 do
        local other = players:get(i)
        local name = other and other.getUsername and tostring(other:getUsername() or "") or ""
        if name ~= "" and name ~= myName and not seen[name] then
            local alreadyAllowed = false
            for j = 1, #allowed do
                if allowed[j] == name then alreadyAllowed = true; break end
            end
            if not alreadyAllowed then
                out[#out + 1] = name
                seen[name] = true
            end
        end
    end
    table.sort(out)
    return out
end

-- =============================================
-- CLAIM
-- =============================================
local function onClaimVehicle(playerObj)
    local vehicle = playerObj and playerObj:getVehicle() or nil
    if not vehicle then return end
    local username = playerObj:getUsername()

    -- v1.8.5: admins skip the client-side "already claimed" / cap rejects so
    -- the server-side admin force-claim path can run.
    local access = playerObj.getAccessLevel and playerObj:getAccessLevel() or ""
    local isAdmin = (access == "admin" or access == "Admin")

    if not isAdmin and CSR_VehicleClaim.isClaimed(vehicle) then
        notifyError(playerObj, "Vehicle already claimed")
        return
    end

    if not isAdmin then
        local count = CSR_VehicleClaim.getClaimCount(username)
        local max = CSR_VehicleClaim.getMaxClaims()
        if count >= max then
            notifyError(playerObj, "Max vehicles claimed (" .. max .. ")")
            return
        end
    end

    if isClient() then
        sendClientCommand(playerObj, MODULE, "ClaimVehicle", commandArgsForVehicle(vehicle))
    else
        CSR_VehicleClaim.setOwner(vehicle, username)
        vehicle:transmitModData()
        notify(playerObj, "Vehicle claimed!")
    end
end

-- =============================================
-- UNCLAIM
-- =============================================
local function onUnclaimVehicle(playerObj)
    local vehicle = playerObj and playerObj:getVehicle() or nil
    if not vehicle then return end

    if not CSR_VehicleClaim.isOwner(vehicle, playerObj) then
        notifyError(playerObj, "Not your vehicle")
        return
    end

    if isClient() then
        sendClientCommand(playerObj, MODULE, "UnclaimVehicle", commandArgsForVehicle(vehicle))
    else
        CSR_VehicleClaim.clearOwner(vehicle)
        vehicle:transmitModData()
        notify(playerObj, "Vehicle unclaimed")
    end
end

-- =============================================
-- MANAGE (add/remove allowed players) — context menu
-- =============================================
local function showManageContext(playerObj)
    local vehicle = playerObj and playerObj:getVehicle() or nil
    if not vehicle then return end
    if not CSR_VehicleClaim.isOwner(vehicle, playerObj) then return end

    local context = ISContextMenu.get(playerObj:getPlayerNum(), getMouseX(), getMouseY())
    local owner = CSR_VehicleClaim.getOwner(vehicle)
    local allowed = CSR_VehicleClaim.getAllowed(vehicle)

    context:addOption("Owner: " .. tostring(owner), nil, nil).notAvailable = true

    -- List allowed players with remove option
    if #allowed > 0 then
        for _, name in ipairs(allowed) do
            context:addOption("Remove: " .. name, playerObj, function(pObj)
                if isClient() then
                    local args = commandArgsForVehicle(vehicle)
                    args.targetName = name
                    sendClientCommand(pObj, MODULE, "VehicleRemoveAllowed", args)
                else
                    CSR_VehicleClaim.removeAllowed(vehicle, name)
                    vehicle:transmitModData()
                    notify(pObj, name .. " removed")
                end
            end)
        end
    end

    -- Add online players (MP only)
    if isClient() and getOnlinePlayers then
        local names = onlinePlayerNames(playerObj, allowed)
        local root = context:addOption("Add Online Player", nil, nil)
        local sub = ISContextMenu:getNew(context)
        context:addSubMenu(root, sub)
        if #names == 0 then
            local opt = sub:addOption("(no eligible online players)", nil, nil)
            opt.notAvailable = true
        else
            for i = 1, #names do
                local otherName = names[i]
                sub:addOption(otherName, playerObj, function(pObj)
                    local args = commandArgsForVehicle(vehicle)
                    args.targetName = otherName
                    sendClientCommand(pObj, MODULE, "VehicleAddAllowed", args)
                end)
            end
        end
    end
end

-- =============================================
-- ADMIN FORCE RELEASE (v1.8.5)
-- =============================================
local function isAdminPlayer(playerObj)
    if not playerObj or not playerObj.getAccessLevel then return false end
    local access = playerObj:getAccessLevel()
    return access == "admin" or access == "Admin"
end

local function onAdminForceRelease(playerObj)
    local vehicle = playerObj and playerObj:getVehicle() or nil
    if not vehicle then return end
    if not isAdminPlayer(playerObj) then
        notifyError(playerObj, "Admin only")
        return
    end
    if isClient() then
        sendClientCommand(playerObj, MODULE, "UnclaimVehicle", commandArgsForVehicle(vehicle))
    else
        CSR_VehicleClaim.clearOwner(vehicle)
        vehicle:transmitModData()
        notify(playerObj, "Vehicle force-released")
    end
end

local function onReissueClaimKey(playerObj)
    local vehicle = playerObj and playerObj:getVehicle() or nil
    if not vehicle then return end
    if not isAdminPlayer(playerObj) and not CSR_VehicleClaim.isOwner(vehicle, playerObj) then
        notifyError(playerObj, "Not your vehicle")
        return
    end
    if isClient() then
        sendClientCommand(playerObj, MODULE, "VehicleReissueClaimKey", commandArgsForVehicle(vehicle))
    else
        notifyError(playerObj, "Claim key reissue is MP/server only")
    end
end

local function onRemoveClaimHotwire(playerObj)
    local vehicle = playerObj and playerObj:getVehicle() or nil
    if not vehicle then return end
    if not isAdminPlayer(playerObj) and not CSR_VehicleClaim.isOwner(vehicle, playerObj) then
        notifyError(playerObj, "Not your vehicle")
        return
    end
    if vehicle.isDriver and not vehicle:isDriver(playerObj) then
        notifyError(playerObj, "Sit in the driver seat")
        return
    end
    if (vehicle.isEngineRunning and vehicle:isEngineRunning())
            or (vehicle.isEngineStarted and vehicle:isEngineStarted()) then
        notifyError(playerObj, "Turn the engine off first")
        return
    end
    if isClient() then
        sendClientCommand(playerObj, MODULE, "VehicleRemoveClaimHotwire", commandArgsForVehicle(vehicle))
    else
        if vehicle.cheatHotwire then
            vehicle:cheatHotwire(false, false)
        elseif vehicle.setHotwired then
            vehicle:setHotwired(false)
        end
        notify(playerObj, "Vehicle hotwire removed")
    end
end

-- =============================================
-- RADIAL MENU HOOK
-- =============================================
local function addVehicleClaimSlices(playerObj)
    local vehicle = playerObj and playerObj:getVehicle() or nil
    if not vehicle then return end
    if not CSR_VehicleClaim.isEnabled() then return end

    local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
    if not menu then return end

    local owner = CSR_VehicleClaim.getOwner(vehicle)

    if not owner then
        -- Unclaimed: show claim option
        menu:addSlice(
            "Claim Vehicle",
            getTexture("media/ui/CSR_ClaimVehicle.png"),
            onClaimVehicle,
            playerObj
        )
    elseif CSR_VehicleClaim.isOwner(vehicle, playerObj) then
        -- Owner: show unclaim and manage
        menu:addSlice(
            "Unclaim Vehicle",
            getTexture("media/ui/CSR_UnclaimVehicle.png"),
            onUnclaimVehicle,
            playerObj
        )
        menu:addSlice(
            "Manage Vehicle",
            getTexture("media/ui/gears.png"),
            showManageContext,
            playerObj
        )
        menu:addSlice(
            "Reissue Claim Key",
            getTexture("media/ui/vehicles/vehicle_ignitionON.png"),
            onReissueClaimKey,
            playerObj
        )
        if vehicleIsHotwired(vehicle) then
            menu:addSlice(
                "Remove Claim Hotwire",
                getTexture("media/ui/vehicles/vehicle_ignitionOFF.png"),
                onRemoveClaimHotwire,
                playerObj
            )
        end
    elseif isAdminPlayer(playerObj) then
        -- v1.8.5: admin override -- foreign-owned vehicle gets a clickable
        -- "Force Release" slice instead of the dead "Owned: X" info slice.
        menu:addSlice(
            "Force Release: " .. tostring(owner),
            getTexture("media/ui/CSR_UnclaimVehicle.png"),
            onAdminForceRelease,
            playerObj
        )
        menu:addSlice(
            "Force Claim",
            getTexture("media/ui/CSR_ClaimVehicle.png"),
            onClaimVehicle,
            playerObj
        )
        menu:addSlice(
            "Reissue Claim Key",
            getTexture("media/ui/vehicles/vehicle_ignitionON.png"),
            onReissueClaimKey,
            playerObj
        )
        if vehicleIsHotwired(vehicle) then
            menu:addSlice(
                "Remove Claim Hotwire",
                getTexture("media/ui/vehicles/vehicle_ignitionOFF.png"),
                onRemoveClaimHotwire,
                playerObj
            )
        end
    else
        -- Not owner, not admin: show "Owned by X" info
        local infoSlice = menu:addSlice(
            "Owned: " .. tostring(owner),
            getTexture("media/ui/lock.png"),
            nil
        )
    end
end

local function hookRadialForClaim()
    if not ISVehicleMenu or not ISVehicleMenu.showRadialMenu or ISVehicleMenu.__csr_claim_patched then
        return
    end
    ISVehicleMenu.__csr_claim_patched = true
    local original = ISVehicleMenu.showRadialMenu
    function ISVehicleMenu.showRadialMenu(playerObj)
        original(playerObj)
        local vehicle = playerObj and playerObj:getVehicle() or nil
        if vehicle then
            addVehicleClaimSlices(playerObj)
        end
    end
end

-- =============================================
-- ENFORCEMENT: prevent non-owners from entering or starting a claimed vehicle
-- =============================================
local function hookEnforcement()
    if not ISVehicleMenu or ISVehicleMenu.__csr_claim_enforce_patched then return end
    ISVehicleMenu.__csr_claim_enforce_patched = true

    -- Block entering the vehicle (single chokepoint -- all enter paths funnel through onEnter)
    if ISVehicleMenu.onEnter then
        local origOnEnter = ISVehicleMenu.onEnter
        function ISVehicleMenu.onEnter(playerObj, vehicle, seat)
            if CSR_VehicleClaim.isEnabled() and vehicle and playerObj
                    and not CSR_VehicleClaim.isAllowed(vehicle, playerObj) then
                local owner = CSR_VehicleClaim.getOwner(vehicle) or "?"
                notifyError(playerObj, "Vehicle owned by " .. tostring(owner))
                return
            end
            return origOnEnter(playerObj, vehicle, seat)
        end
    end

    -- Defense-in-depth: block engine start
    if ISVehicleMenu.onStartEngine then
        local origStart = ISVehicleMenu.onStartEngine
        function ISVehicleMenu.onStartEngine(playerObj, ...)
            local vehicle = playerObj and playerObj:getVehicle() or nil
            if CSR_VehicleClaim.isEnabled() and vehicle
                    and not CSR_VehicleClaim.isAllowed(vehicle, playerObj) then
                local owner = CSR_VehicleClaim.getOwner(vehicle) or "?"
                notifyError(playerObj, "Vehicle owned by " .. tostring(owner))
                return
            end
            if CSR_VehicleClaim.isEnabled() and vehicle
                    and CSR_VehicleClaim.isClaimKeyBound
                    and CSR_VehicleClaim.isClaimKeyBound(vehicle)
                    and CSR_VehicleClaim.playerHasClaimKey
                    and not CSR_VehicleClaim.playerHasClaimKey(playerObj, vehicle) then
                notifyError(playerObj, "CSR claim key required")
                return
            end
            return origStart(playerObj, ...)
        end
    end
end

-- =============================================
-- SERVER RESPONSE HANDLER
-- =============================================
local function onServerCommand(module, command, args)
    if module ~= MODULE then return end
    local player = getPlayer()
    if not player then return end

    if command == "VehicleClaimResult" then
        local msg = args and args.text or ""
        local success = args and args.success
        if success then
            notify(player, msg)
        else
            notifyError(player, msg)
        end
        return
    end

    -- v1.8.5: server broadcasts this when a vehicle-row is removed from the
    -- claim registry. Clear the legacy modData mirror on whichever client
    -- has the chunk loaded so old per-vehicle modData can never resurface
    -- as ghost ownership after a release.
    if command == "CSR_VehicleClaimCleared" then
        local cleared = false
        local key = args and args.vehicleKey
        if key and key ~= "" and CSR_VehicleClaim
                and CSR_VehicleClaim.findLoadedVehicleByKey then
            local v = CSR_VehicleClaim.findLoadedVehicleByKey(key)
            if v and CSR_VehicleClaim.clearOwner then
                CSR_VehicleClaim.clearOwner(v)
                if v.transmitModData then v:transmitModData() end
                cleared = true
            end
        end

        local v = (not cleared) and player.getVehicle and player:getVehicle() or nil
        if not cleared and key and v and CSR_VehicleClaim and CSR_VehicleClaim.getVehicleKeyCandidates then
            local keys = CSR_VehicleClaim.getVehicleKeyCandidates(v, false)
            for i = 1, #keys do
                if keys[i] == key then
                    CSR_VehicleClaim.clearOwner(v)
                    if v.transmitModData then v:transmitModData() end
                    break
                end
            end
        end
        return
    end
end

-- =============================================
-- INIT
-- =============================================
local function init()
    hookRadialForClaim()
    hookEnforcement()
end

if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(init) end
    if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
end

return CSR_VehicleClaimClient

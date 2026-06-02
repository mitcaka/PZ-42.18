--[[
    CSR_PadlockClient.lua
    -------------------------------------------------------------------------
    v1.9.0 -- right-click context menus to install / remove / break padlocks
    on container furniture and vehicles. Server validates everything; this
    file is purely UI + bolt-cut timed action + access enforcement.

    Hard rules:
      * MP only.
      * No nested tables in modData.
      * Bolt-cut timed action defined at file scope so MP can resolve it.
      * Submenu always shown when a lockable container is right-clicked.
      * Admins/Moderators bypass all access restrictions.
--]]

CSR_PadlockClient = CSR_PadlockClient or {}

require "CSR_FeatureFlags"
require "CSR_VehicleClaim"
require "CSR_Claims/CSR_ClaimPermissions"

local function _mpOnly()
    return isClient and isClient()
end

local function flagOn()
    local sb = (SandboxVars and SandboxVars.CommonSenseReborn) or nil
    if not sb then return false end
    if sb.ClaimPadlockEnabled == false then return false end
    return true
end

local function isAdminOrModerator(player)
    if not player then return false end
    if not player.getAccessLevel then return false end
    local lvl = player:getAccessLevel()
    if not lvl then return false end
    return lvl == "Admin" or lvl == "Moderator"
end

local function safeUsername(player)
    if not player then return "" end
    if player.getUsername then
        local u = player:getUsername()
        if u then return tostring(u) end
    end
    return ""
end

local function isPadlocked(obj)
    if not obj or not obj.getModData then return false end
    local md = obj:getModData()
    return md and md.csrPadlocked == 1
end

local function getPadlockOwner(obj)
    if not obj or not obj.getModData then return nil end
    local md = obj:getModData()
    if not md or md.csrPadlocked ~= 1 then return nil end
    local owner = tostring(md.csrPadlockOwner or "")
    return owner ~= "" and owner or nil
end

local function ownsMatchingKey(player, obj)
    if not player or not obj or not obj.getModData then return false end
    local md = obj:getModData()
    if not md or md.csrPadlocked ~= 1 then return false end
    local hash = tostring(md.csrPadlockKeyHash or "")
    if hash == "" then return false end
    local inv = player:getInventory()
    if not inv or not inv.getAllEvalRecurse then return false end
    local found = inv:getAllEvalRecurse(function(it)
        if not it or not it.getModData then return false end
        local imd = it:getModData()
        return imd and tostring(imd.csrPadlockKeyHash or "") == hash
    end, ArrayList.new())
    return found and found:size() > 0
end

local function resolveItemTag(name)
    if not name or not ItemTag then return nil end
    local tag = ItemTag[name] or ItemTag[string.upper(name)]
    if tag then return tag end
    if ItemTag.get and ResourceLocation and ResourceLocation.of then
        return ItemTag.get(ResourceLocation.of(name))
    end
    return nil
end

local function getFirstByResolvedTags(inv, names)
    if not inv or not inv.getFirstTagRecurse then return nil end
    for i = 1, #names do
        local tag = resolveItemTag(names[i])
        if tag then
            local item = inv:getFirstTagRecurse(tag)
            if item then return item end
        end
    end
    return nil
end

local function inventoryHasMatchingItem(inv, predicate)
    if not inv or not inv.getAllEvalRecurse then return false end
    local found = inv:getAllEvalRecurse(predicate, ArrayList.new())
    return found and found:size() > 0
end

local function isPadlockItem(item)
    if not item then return false end
    local ft = item.getFullType and tostring(item:getFullType() or "") or ""
    local typ = item.getType and tostring(item:getType() or "") or ""
    return ft == "Base.Padlock"
        or ft == "Base.CombinationPadlock"
        or typ == "Padlock"
        or typ == "CombinationPadlock"
end

local function isBoltCutterItem(item)
    if not item then return false end
    local ft = item.getFullType and tostring(item:getFullType() or "") or ""
    local typ = item.getType and tostring(item:getType() or "") or ""
    return ft == "Base.BoltCutters" or typ == "BoltCutters"
end

local function hasPadlockItem(player)
    if not player or not player.getInventory then return false end
    local inv = player:getInventory()
    if not inv then return false end
    if getFirstByResolvedTags(inv, { "base:lock", "base:padlock", "Lock" }) then return true end
    if inv.containsTypeRecurse then
        return inv:containsTypeRecurse("Base.Padlock")
            or inv:containsTypeRecurse("Base.CombinationPadlock")
            or inv:containsTypeRecurse("Padlock")
            or inv:containsTypeRecurse("CombinationPadlock")
    end
    return inventoryHasMatchingItem(inv, isPadlockItem)
end

local function hasBoltCutters(player)
    if not player or not player.getInventory then return false end
    local inv = player:getInventory()
    if getFirstByResolvedTags(inv, { "base:boltcutters", "BoltCutters" }) then return true end
    if inv and inv.containsTypeRecurse then
        if inv:containsTypeRecurse("Base.BoltCutters")
            or inv:containsTypeRecurse("BoltCutters") then return true end
    end
    return inventoryHasMatchingItem(inv, isBoltCutterItem)
end

local function vehicleKeyFor(vehicle)
    if not vehicle or not CSR_VehicleClaim or not CSR_VehicleClaim.getVehicleKey then
        return ""
    end
    return tostring(CSR_VehicleClaim.getVehicleKey(vehicle, false) or "")
end

local function vehicleSqlIdFor(vehicle)
    if CSR_VehicleClaim and CSR_VehicleClaim.getVehicleSqlId then
        return tostring(CSR_VehicleClaim.getVehicleSqlId(vehicle) or "")
    end
    if vehicle and vehicle.getSqlId then
        local id = tonumber(vehicle:getSqlId())
        if id and id > 0 then return tostring(math.floor(id)) end
    end
    return ""
end

local function vehicleScriptFor(vehicle)
    if not vehicle or not vehicle.getScript then return "" end
    local script = vehicle:getScript()
    if not script or not script.getName then return "" end
    return tostring(script:getName() or "")
end

local function vehicleCoord(vehicle, getter)
    if not vehicle then return 0 end
    local value = 0
    if getter == "x" and vehicle.getX then value = vehicle:getX()
    elseif getter == "y" and vehicle.getY then value = vehicle:getY()
    elseif getter == "z" and vehicle.getZ then value = vehicle:getZ() end
    return math.floor(tonumber(value) or 0)
end

local function vehicleCommandArgs(vehicle)
    return {
        vehicleKey = vehicleKeyFor(vehicle),
        vehicleSqlId = vehicleSqlIdFor(vehicle),
        vehicleScript = vehicleScriptFor(vehicle),
        x = vehicleCoord(vehicle, "x"),
        y = vehicleCoord(vehicle, "y"),
        z = vehicleCoord(vehicle, "z"),
    }
end

local function vehicleClaimRow(vehicle)
    if not vehicle or not CSR_VehicleClaim or not CSR_VehicleClaim.getRegistryRow then
        return nil
    end
    return CSR_VehicleClaim.getRegistryRow(vehicle)
end

local function canInstallVehiclePadlock(player, vehicle)
    if isAdminOrModerator(player) then return vehicleClaimRow(vehicle) ~= nil end
    local row = vehicleClaimRow(vehicle)
    if not row or not CSR_ClaimPermissions or not CSR_ClaimPermissions.canDo then return false end
    return CSR_ClaimPermissions.canDo(row, safeUsername(player), "padlock_install", player) == true
end

local function canRemoveVehiclePadlock(player, vehicle)
    if isAdminOrModerator(player) then return true end
    if ownsMatchingKey(player, vehicle) then return true end
    local row = vehicleClaimRow(vehicle)
    if not row or not CSR_ClaimPermissions or not CSR_ClaimPermissions.canDo then return false end
    return CSR_ClaimPermissions.canDo(row, safeUsername(player), "padlock_remove", player) == true
end

-- =========================================================================
-- Access check: does this player have permission to open a padlocked object?
-- =========================================================================

local function hasAccessToPadlocked(player, obj)
    if not isPadlocked(obj) then return true end
    if isAdminOrModerator(player) then return true end
    if ownsMatchingKey(player, obj) then return true end
    return false
end

-- =========================================================================
-- Bolt-cut timed action (file-scope class)
-- =========================================================================

CSR_PadlockBoltCutAction = ISBaseTimedAction:derive("CSR_PadlockBoltCutAction")

function CSR_PadlockBoltCutAction:isValid()
    if not self.character then return false end
    if not hasBoltCutters(self.character) then return false end
    if self.vehicleKey and self.vehicleKey ~= "" then
        return true
    end
    return true
end

function CSR_PadlockBoltCutAction:waitToStart()
    if self.targetX and self.targetY and self.character.faceLocation then
        self.character:faceLocation(self.targetX, self.targetY)
    end
    return self.character:shouldBeTurning()
end

function CSR_PadlockBoltCutAction:start()
    self:setActionAnim("VehicleWorkOnMid")
    self:setOverrideHandModels(nil, nil)
end

function CSR_PadlockBoltCutAction:perform()
    sendClientCommand(self.character, "CommonSenseReborn", "CSR_PadlockBreak", {
        x = self.targetX, y = self.targetY, z = self.targetZ,
        vehicleKey = self.vehicleKey,
        vehicleSqlId = self.vehicleSqlId,
        vehicleScript = self.vehicleScript,
    })
    ISBaseTimedAction.perform(self)
end

function CSR_PadlockBoltCutAction:new(character, x, y, z, vehicleKey, vehicleSqlId, vehicleScript)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.targetX, o.targetY, o.targetZ = x, y, z
    o.vehicleKey = vehicleKey
    o.vehicleSqlId = vehicleSqlId
    o.vehicleScript = vehicleScript
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    o.maxTime = (tonumber(sb.ClaimPadlockBreakSeconds) or 180) * 20
    o.stopOnWalk   = true
    o.stopOnRun    = true
    o.stopOnAim    = false
    return o
end

-- =========================================================================
-- World context menu (containers + vehicles)
-- =========================================================================

local function getTargetObjectAt(worldobjects)
    if not worldobjects then return nil, nil end
    for i = 1, #worldobjects do
        local wo = worldobjects[i]
        if wo and wo.getContainer then
            local c = wo:getContainer()
            if c then return wo, wo:getSquare() end
        end
    end
    return nil, nil
end

local function onInstallContainer(worldobjects, playerNum)
    local p = getSpecificPlayer(playerNum)
    if not p then return end
    local obj, sq = getTargetObjectAt(worldobjects)
    if not obj or not sq then return end
    sendClientCommand(p, "CommonSenseReborn", "CSR_PadlockInstall", {
        x = sq:getX(), y = sq:getY(), z = sq:getZ(),
    })
end

local function onRemoveContainer(worldobjects, playerNum)
    local p = getSpecificPlayer(playerNum)
    if not p then return end
    local obj, sq = getTargetObjectAt(worldobjects)
    if not obj or not sq then return end
    sendClientCommand(p, "CommonSenseReborn", "CSR_PadlockRemove", {
        x = sq:getX(), y = sq:getY(), z = sq:getZ(),
    })
end

local function onCutContainer(worldobjects, playerNum)
    local p = getSpecificPlayer(playerNum)
    if not p then return end
    local obj, sq = getTargetObjectAt(worldobjects)
    if not obj or not sq then return end
    if luautils and luautils.walkAdj then
        if not luautils.walkAdj(p, sq) then return end
    end
    ISTimedActionQueue.add(CSR_PadlockBoltCutAction:new(p, sq:getX(), sq:getY(), sq:getZ(), nil))
end

local function makeTooltip(text)
    local tt = ISWorldObjectContextMenu.addToolTip()
    tt.description = text
    return tt
end

local function fillWorldMenu(playerNum, context, worldobjects)
    if not _mpOnly() or not flagOn() then return end
    local p = getSpecificPlayer(playerNum)
    if not p then return end
    local obj, sq = getTargetObjectAt(worldobjects)
    if not obj or not sq then return end

    local sub = nil
    local function getSub()
        if sub then return sub end
        local opt = context:addOption(getText("ContextMenu_CSR_PadlockRoot"), worldobjects, nil)
        sub = ISContextMenu:getNew(context)
        context:addSubMenu(opt, sub)
        return sub
    end

    local isAdmin = isAdminOrModerator(p)

    if isPadlocked(obj) then
        local owner = getPadlockOwner(obj)
        local ownerText = owner and (getText("ContextMenu_CSR_PadlockLockedBy") .. " " .. owner)
            or getText("ContextMenu_CSR_PadlockLocked")

        -- Status line: always shown, non-clickable
        local statusOpt = getSub():addOption(ownerText, nil, nil)
        statusOpt.notAvailable = true

        local hasKey = ownsMatchingKey(p, obj)

        -- Remove (key holder or admin)
        if hasKey or isAdmin then
            getSub():addOption(getText("ContextMenu_CSR_PadlockRemove"), worldobjects, onRemoveContainer, playerNum)
        else
            local opt = getSub():addOption(getText("ContextMenu_CSR_PadlockRemove"), nil, nil)
            opt.notAvailable = true
            opt.toolTip = makeTooltip(getText("Tooltip_CSR_PadlockNeedKey"))
        end

        -- Bolt-cut (anyone with bolt cutters can cut)
        if hasBoltCutters(p) then
            getSub():addOption(getText("ContextMenu_CSR_PadlockCut"), worldobjects, onCutContainer, playerNum)
        else
            local opt = getSub():addOption(getText("ContextMenu_CSR_PadlockCut"), nil, nil)
            opt.notAvailable = true
            opt.toolTip = makeTooltip(getText("Tooltip_CSR_PadlockNeedBoltCutters"))
        end
    else
        -- Not padlocked: offer install
        if hasPadlockItem(p) then
            getSub():addOption(getText("ContextMenu_CSR_PadlockInstall"), worldobjects, onInstallContainer, playerNum)
        else
            local opt = getSub():addOption(getText("ContextMenu_CSR_PadlockInstall"), nil, nil)
            opt.notAvailable = true
            opt.toolTip = makeTooltip(getText("Tooltip_CSR_PadlockNeedPadlock"))
        end
    end
end

-- =========================================================================
-- Access enforcement: block non-key-holders from moving padlocked containers
-- =========================================================================

local _hooksInstalled = false

local function getPlayerForNum(num)
    if num ~= nil then return getSpecificPlayer(num) end
    return getPlayer and getPlayer() or nil
end

local function resolveObjectFromMoveablesAction(self)
    if self and self.moveProps and self.moveProps.object then
        return self.moveProps.object
    end
    if self and self.object then return self.object end
    return nil
end

local function resolveObjectFromMoveableCursor(cursor)
    if not cursor then return nil end
    if cursor.cacheObject then return cursor.cacheObject end
    if cursor.currentMoveProps and cursor.currentMoveProps.object then
        return cursor.currentMoveProps.object
    end
    if cursor.objectListCache and cursor.objectIndex then
        local entry = cursor.objectListCache[cursor.objectIndex]
        if entry and entry.object then return entry.object end
    end
    return nil
end

local function resolveObjectFromDestroyCursor(cursor)
    if not cursor then return nil end
    if cursor.currentObject then return cursor.currentObject end
    if cursor.getObjectList then
        local objects = cursor:getObjectList()
        if objects and cursor.objectIndex and cursor.objectIndex >= 1 then
            local obj = objects[cursor.objectIndex]
            if obj then return obj end
        end
        if objects and #objects > 0 then return objects[1] end
    end
    return nil
end

local _orig_ISMoveablesAction_isValid = nil
local _orig_ISMoveableCursor_isValid  = nil
local _orig_ISDestroyCursor_isValid   = nil

local BLOCKED_MOVEABLE_MODES = { pickup = true, rotate = true, scrap = true }

local function notifyBlocked(player, owner)
    if not player then return end
    local msg = owner
        and (getText("ContextMenu_CSR_PadlockLockedBy") .. " " .. owner)
        or getText("ContextMenu_CSR_PadlockLocked")
    if player.setHaloNote then
        player:setHaloNote(msg)
    end
end

local function installAccessHooks()
    if _hooksInstalled then return end
    if not _mpOnly() or not flagOn() then return end

    if ISMoveablesAction and ISMoveablesAction.isValid then
        _orig_ISMoveablesAction_isValid = ISMoveablesAction.isValid
        ISMoveablesAction.isValid = function(self)
            local ok = _orig_ISMoveablesAction_isValid(self)
            if ok ~= true then return ok end
            local mode = self and self.mode
            if not BLOCKED_MOVEABLE_MODES[mode] then return ok end
            local object = resolveObjectFromMoveablesAction(self)
            if not isPadlocked(object) then return ok end
            local player = getPlayerForNum(self and self.playerNum)
            if hasAccessToPadlocked(player, object) then return ok end
            notifyBlocked(player, getPadlockOwner(object))
            return false
        end
    end

    if ISMoveableCursor and ISMoveableCursor.isValid then
        _orig_ISMoveableCursor_isValid = ISMoveableCursor.isValid
        ISMoveableCursor.isValid = function(self, square)
            local ok = _orig_ISMoveableCursor_isValid(self, square)
            if ok ~= true then
                if self then self.colorMod = { r = 1, g = 0, b = 0 } end
                return ok or false
            end
            local mode = nil
            if self and self.player ~= nil and ISMoveableCursor.mode then
                mode = ISMoveableCursor.mode[self.player]
            end
            if not BLOCKED_MOVEABLE_MODES[mode] then return ok end
            local object = resolveObjectFromMoveableCursor(self)
            if not isPadlocked(object) then return ok end
            local player = getPlayerForNum(self and self.player)
            if hasAccessToPadlocked(player, object) then return ok end
            if self then self.colorMod = { r = 1, g = 0, b = 0 } end
            return false
        end
    end

    if ISDestroyCursor and ISDestroyCursor.isValid then
        _orig_ISDestroyCursor_isValid = ISDestroyCursor.isValid
        ISDestroyCursor.isValid = function(self, square)
            local ok = _orig_ISDestroyCursor_isValid(self, square)
            if ok ~= true then return ok end
            local object = resolveObjectFromDestroyCursor(self)
            if not isPadlocked(object) then return ok end
            local player = getPlayerForNum(self and self.player)
            if hasAccessToPadlocked(player, object) then return ok end
            return false
        end
    end

    _hooksInstalled = true
end

-- =========================================================================
-- Vehicle context menu
-- =========================================================================

local function fillVehicleMenu(playerNum, context, vehicle, test)
    if not _mpOnly() or not flagOn() then return end
    if test then return end
    if CSR_FeatureFlags and CSR_FeatureFlags.isCSRRadialMenuEnabled
            and CSR_FeatureFlags.isCSRRadialMenuEnabled() then
        return
    end
    local p = getSpecificPlayer(playerNum)
    if not p or not vehicle then return end
    local vehicleKey = vehicleKeyFor(vehicle)
    if vehicleKey == "" then return end

    local md = vehicle.getModData and vehicle:getModData() or nil
    local locked = md and md.csrPadlocked == 1

    local sub = nil
    local function getSub()
        if sub then return sub end
        local opt = context:addOption("Padlock", vehicle, nil)
        sub = ISContextMenu:getNew(context)
        context:addSubMenu(opt, sub)
        return sub
    end

    local isAdmin = isAdminOrModerator(p)

    if locked then
        local owner = md and tostring(md.csrPadlockOwner or "") or ""
        if owner == "" then owner = nil end
        local ownerText = owner and (getText("ContextMenu_CSR_PadlockLockedBy") .. " " .. owner)
            or getText("ContextMenu_CSR_PadlockLocked")

        local statusOpt = getSub():addOption(ownerText, nil, nil)
        statusOpt.notAvailable = true

        if canRemoveVehiclePadlock(p, vehicle) then
            getSub():addOption(getText("ContextMenu_CSR_PadlockRemove"), nil, function()
                sendClientCommand(p, "CommonSenseReborn", "CSR_PadlockRemove", vehicleCommandArgs(vehicle))
            end)
        else
            local opt = getSub():addOption(getText("ContextMenu_CSR_PadlockRemove"), nil, nil)
            opt.notAvailable = true
            opt.toolTip = makeTooltip(getText("Tooltip_CSR_PadlockNeedKey"))
        end

        if hasBoltCutters(p) then
            getSub():addOption(getText("ContextMenu_CSR_PadlockCut"), nil, function()
                local args = vehicleCommandArgs(vehicle)
                ISTimedActionQueue.add(CSR_PadlockBoltCutAction:new(
                    p, args.x, args.y, args.z, args.vehicleKey, args.vehicleSqlId, args.vehicleScript))
            end)
        else
            local opt = getSub():addOption(getText("ContextMenu_CSR_PadlockCut"), nil, nil)
            opt.notAvailable = true
            opt.toolTip = makeTooltip(getText("Tooltip_CSR_PadlockNeedBoltCutters"))
        end
    else
        local canInstall = canInstallVehiclePadlock(p, vehicle)
        if canInstall and hasPadlockItem(p) then
            getSub():addOption(getText("ContextMenu_CSR_PadlockInstall"), nil, function()
                sendClientCommand(p, "CommonSenseReborn", "CSR_PadlockInstall", vehicleCommandArgs(vehicle))
            end)
        elseif canInstall then
            local opt = getSub():addOption(getText("ContextMenu_CSR_PadlockInstall"), nil, nil)
            opt.notAvailable = true
            opt.toolTip = makeTooltip(getText("Tooltip_CSR_PadlockNeedPadlock"))
        else
            local opt = getSub():addOption(getText("ContextMenu_CSR_PadlockInstall"), nil, nil)
            opt.notAvailable = true
            opt.toolTip = makeTooltip("Only claim co-owners can install vehicle padlocks.")
        end
    end
end

local function addVehicleRadialSlices(playerObj, vehicle)
    if not _mpOnly() or not flagOn() then return end
    if not playerObj or not vehicle then return end
    local vehicleKey = vehicleKeyFor(vehicle)
    if vehicleKey == "" then return end

    local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
    if not menu then return end

    local md = vehicle.getModData and vehicle:getModData() or nil
    local locked = md and md.csrPadlocked == 1
    local isAdmin = isAdminOrModerator(playerObj)

    if locked then
        if canRemoveVehiclePadlock(playerObj, vehicle) then
            menu:addSlice(getText("ContextMenu_CSR_PadlockRemove"),
                getTexture("media/ui/vehicles/vehicle_lockdoors.png"),
                function()
                    sendClientCommand(playerObj, "CommonSenseReborn", "CSR_PadlockRemove",
                        vehicleCommandArgs(vehicle))
                end)
        end
        if hasBoltCutters(playerObj) then
            menu:addSlice(getText("ContextMenu_CSR_PadlockCut"),
                getTexture("Item_BoltCutters"),
                function()
                    local sq = vehicle.getSquare and vehicle:getSquare() or nil
                    if sq and luautils and luautils.walkAdj and not luautils.walkAdj(playerObj, sq) then
                        return
                    end
                    local args = vehicleCommandArgs(vehicle)
                    ISTimedActionQueue.add(CSR_PadlockBoltCutAction:new(
                        playerObj,
                        args.x,
                        args.y,
                        args.z,
                        args.vehicleKey,
                        args.vehicleSqlId,
                        args.vehicleScript
                    ))
                end)
        end
    elseif canInstallVehiclePadlock(playerObj, vehicle) and hasPadlockItem(playerObj) then
        menu:addSlice(getText("ContextMenu_CSR_PadlockInstall"),
            getTexture("Item_Padlock"),
            function()
                sendClientCommand(playerObj, "CommonSenseReborn", "CSR_PadlockInstall",
                    vehicleCommandArgs(vehicle))
            end)
    end
end

local function hookVehicleRadial()
    if not ISVehicleMenu or ISVehicleMenu.__csr_padlock_radial then return end
    ISVehicleMenu.__csr_padlock_radial = true

    if ISVehicleMenu.showRadialMenu then
        local originalShowRadialMenu = ISVehicleMenu.showRadialMenu
        ISVehicleMenu.showRadialMenu = function(playerObj, ...)
            originalShowRadialMenu(playerObj, ...)
            local vehicle = playerObj and playerObj.getVehicle and playerObj:getVehicle() or nil
            if vehicle then
                addVehicleRadialSlices(playerObj, vehicle)
            end
        end
    end

    if ISVehicleMenu.showRadialMenuOutside then
        local originalShowRadialMenuOutside = ISVehicleMenu.showRadialMenuOutside
        ISVehicleMenu.showRadialMenuOutside = function(playerObj, ...)
            originalShowRadialMenuOutside(playerObj, ...)
            if not playerObj or playerObj:getVehicle() then return end
            local vehicle = ISVehicleMenu.getVehicleToInteractWith
                and ISVehicleMenu.getVehicleToInteractWith(playerObj) or nil
            if vehicle then
                addVehicleRadialSlices(playerObj, vehicle)
            end
        end
    end
end

-- Install hooks and register events
local function onGameStart()
    installAccessHooks()
    hookVehicleRadial()
end

-- Also try late install in case cursors load after game start
local function lateInstallHooks()
    installAccessHooks()
    if _hooksInstalled then
        Events.EveryOneMinute.Remove(lateInstallHooks)
    end
end

Events.OnGameStart.Add(onGameStart)
Events.EveryOneMinute.Add(lateInstallHooks)

if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(fillWorldMenu)
end

if Events and Events.OnFillVehicleContextMenu then
    Events.OnFillVehicleContextMenu.Add(fillVehicleMenu)
end

return CSR_PadlockClient

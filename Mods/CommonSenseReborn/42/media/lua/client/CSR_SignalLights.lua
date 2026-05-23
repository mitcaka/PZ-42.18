require "TimedActions/ISBaseTimedAction"
require "ISUI/ISToolTip"
require "CSR_Utils"

CSR_SignalLights = CSR_SignalLights or {}

local SIGNAL_MODULE = "CommonSenseReborn"
local SIGNAL_COMMAND = "SignalLight"
local GLOWSTICK_DURATION_MS = 1200000

local activeLights = {}
local tickRegistered = false

local SIGNAL_TYPES = {
    ["Base.CSR_GlowstickRed"] = { r = 255, g = 40, b = 28, radius = 9, durationMs = GLOWSTICK_DURATION_MS },
    ["Base.CSR_GlowstickGreen"] = { r = 45, g = 255, b = 55, radius = 9, durationMs = GLOWSTICK_DURATION_MS },
    ["Base.CSR_GlowstickBlue"] = { r = 45, g = 90, b = 255, radius = 9, durationMs = GLOWSTICK_DURATION_MS },
    ["Base.CSR_GlowstickWhite"] = { r = 245, g = 245, b = 220, radius = 9, durationMs = GLOWSTICK_DURATION_MS },
    ["Base.CSR_GlowstickYellow"] = { r = 255, g = 235, b = 35, radius = 9, durationMs = GLOWSTICK_DURATION_MS },
    ["Base.CSR_GlowstickPurple"] = { r = 160, g = 65, b = 255, radius = 9, durationMs = GLOWSTICK_DURATION_MS },
    ["Base.CSR_HandFlareRed"] = { r = 255, g = 45, b = 35, radius = 16, durationMs = 720000 },
    ["Base.CSR_HandFlareGreen"] = { r = 45, g = 255, b = 70, radius = 16, durationMs = 720000 },
    ["Base.CSR_HandFlareBlue"] = { r = 55, g = 95, b = 255, radius = 16, durationMs = 720000 },
    ["Base.CSR_HandFlareWhite"] = { r = 245, g = 245, b = 220, radius = 16, durationMs = 720000 },
    ["Base.CSR_SignalFlareRound"] = { r = 255, g = 115, b = 45, radius = 22, durationMs = 540000 },
}

local HAND_FLARES = {
    ["Base.CSR_HandFlareRed"] = true,
    ["Base.CSR_HandFlareGreen"] = true,
    ["Base.CSR_HandFlareBlue"] = true,
    ["Base.CSR_HandFlareWhite"] = true,
}

local function nowMs()
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    if os and os.time then return os.time() * 1000 end
    return 0
end

local function removeLight(entry)
    local cell = getCell and getCell() or nil
    if cell and entry and entry.light and cell.removeLamppost then
        cell:removeLamppost(entry.light)
    end
end

local function updateLights()
    if #activeLights == 0 then
        if tickRegistered and Events and Events.OnTick then
            Events.OnTick.Remove(updateLights)
            tickRegistered = false
        end
        return
    end

    local now = nowMs()
    for i = #activeLights, 1, -1 do
        local entry = activeLights[i]
        if now >= entry.expiresAt then
            removeLight(entry)
            table.remove(activeLights, i)
        end
    end
end

local function ensureTick()
    if tickRegistered then return end
    if Events and Events.OnTick then
        Events.OnTick.Add(updateLights)
        tickRegistered = true
    end
end

local function playSoundAt(x, y, z, sound)
    if not sound or sound == "" then return end
    local cell = getCell and getCell() or nil
    local square = cell and cell.getGridSquare and cell:getGridSquare(x, y, z) or nil
    if square and square.playSound then
        square:playSound(sound)
    end
end

local function removeInventoryItem(player, item)
    if not item then return false end
    if player and player.getPrimaryHandItem and player:getPrimaryHandItem() == item and player.setPrimaryHandItem then
        player:setPrimaryHandItem(nil)
    end
    if player and player.getSecondaryHandItem and player:getSecondaryHandItem() == item and player.setSecondaryHandItem then
        player:setSecondaryHandItem(nil)
    end
    local container = item.getContainer and item:getContainer() or (player and player.getInventory and player:getInventory() or nil)
    if not container then return false end
    if container.DoRemoveItem then
        container:DoRemoveItem(item)
    elseif container.Remove then
        container:Remove(item)
    else
        return false
    end
    if sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(container, item)
    end
    return true
end

local function textOr(key, fallback, ...)
    if getTextOrNull then
        local value = getTextOrNull(key)
        if value then
            if select("#", ...) > 0 then
                return getText(key, ...)
            end
            return value
        end
    end
    if getText then
        local value = getText(key, ...)
        if value and value ~= key then return value end
    end
    if select("#", ...) > 0 then
        return string.format(fallback, ...)
    end
    return fallback
end

function CSR_SignalLights.addLight(x, y, z, r, g, b, radius, durationMs)
    local cell = getCell and getCell() or nil
    if not cell or not IsoLightSource then return false end

    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)
    z = math.floor(tonumber(z) or 0)
    local light = IsoLightSource.new(x, y, z, tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255, tonumber(radius) or 10)
    cell:addLamppost(light)
    activeLights[#activeLights + 1] = {
        light = light,
        expiresAt = nowMs() + math.max(1000, tonumber(durationMs) or 600000),
    }
    ensureTick()
    return true
end

function CSR_SignalLights.addSignalType(fullType, x, y, z, overrides)
    local spec = SIGNAL_TYPES[tostring(fullType or "")]
    if not spec then return false end
    overrides = overrides or {}
    return CSR_SignalLights.addLight(
        x,
        y,
        z,
        overrides.r or spec.r,
        overrides.g or spec.g,
        overrides.b or spec.b,
        overrides.radius or spec.radius,
        overrides.durationMs or spec.durationMs)
end

function CSR_SignalLights.addGlowstickImpact(fullType, x, y, z)
    if not (CSR_Throwables and CSR_Throwables.isGlowstickType and CSR_Throwables.isGlowstickType(fullType)) then
        return false
    end
    return CSR_SignalLights.addSignalType(fullType, x, y, z)
end

function CSR_SignalLights.isHandFlare(item)
    return item and item.getFullType and HAND_FLARES[item:getFullType()] == true
end

local CSR_UseSignalFlareAction = ISBaseTimedAction:derive("CSR_UseSignalFlareAction")

function CSR_UseSignalFlareAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.itemId = item and item.getID and item:getID() or nil
    o.itemType = item and item.getFullType and item:getFullType() or nil
    o.maxTime = 80
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end

function CSR_UseSignalFlareAction:resolveItem()
    self.item = CSR_Utils.findInventoryItemById(self.character, self.itemId, self.itemType) or self.item
    return self.item
end

function CSR_UseSignalFlareAction:isValid()
    return CSR_SignalLights.isHandFlare(self:resolveItem())
end

function CSR_UseSignalFlareAction:start()
    self:resolveItem()
    self:setActionAnim("LightItem")
    self:setOverrideHandModels(self.item, nil)
    self.jobType = textOr("ContextMenu_CSR_IgniteSignalFlare", "Ignite Signal Flare")
end

function CSR_UseSignalFlareAction:perform()
    local item = self:resolveItem()
    if item then
        if isClient() then
            sendClientCommand(self.character, SIGNAL_MODULE, "SignalUseHandFlare", {
                itemId = self.itemId,
                itemType = self.itemType,
                requestId = CSR_Utils.makeRequestId(self.character, "SignalUseHandFlare"),
                requestTimestamp = nowMs(),
            })
        else
            local x = math.floor(self.character:getX())
            local y = math.floor(self.character:getY())
            local z = math.floor(self.character:getZ())
            removeInventoryItem(self.character, item)
            CSR_SignalLights.addSignalType(self.itemType, x, y, z)
            playSoundAt(x, y, z, "LightbulbBurnedOut")
            if addSound then addSound(self.character, x, y, z, 18, 12) end
        end
    end
    ISBaseTimedAction.perform(self)
end

local CSR_FireSignalPistolAction = ISBaseTimedAction:derive("CSR_FireSignalPistolAction")

function CSR_FireSignalPistolAction:new(character, weapon, targetX, targetY, targetZ)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.weapon = weapon
    o.weaponId = weapon and weapon.getID and weapon:getID() or nil
    o.targetX = targetX
    o.targetY = targetY
    o.targetZ = targetZ
    o.maxTime = 70
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end

function CSR_FireSignalPistolAction:resolveWeapon()
    self.weapon = CSR_Utils.findInventoryItemById(self.character, self.weaponId, "Base.CSR_SignalPistol") or self.weapon
    return self.weapon
end

function CSR_FireSignalPistolAction:isValid()
    local weapon = self:resolveWeapon()
    if not weapon or not weapon.getFullType or weapon:getFullType() ~= "Base.CSR_SignalPistol" then return false end
    local ammo = weapon.getCurrentAmmoCount and weapon:getCurrentAmmoCount() or 0
    return ammo > 0
end

function CSR_FireSignalPistolAction:waitToStart()
    if self.character.faceLocation then
        self.character:faceLocation((self.targetX or self.character:getX()) + 0.5, (self.targetY or self.character:getY()) + 0.5)
    end
    return self.character.shouldBeTurning and self.character:shouldBeTurning()
end

function CSR_FireSignalPistolAction:start()
    self:resolveWeapon()
    self:setActionAnim("Loot")
    self:setOverrideHandModels(self.weapon, nil)
    self.jobType = textOr("ContextMenu_CSR_FireSignalRoundHere", "Fire Signal Round Here")
end

function CSR_FireSignalPistolAction:perform()
    local weapon = self:resolveWeapon()
    if weapon then
        if isClient() then
            sendClientCommand(self.character, SIGNAL_MODULE, "SignalFirePistol", {
                weaponId = self.weaponId,
                targetX = self.targetX,
                targetY = self.targetY,
                targetZ = self.targetZ,
                requestId = CSR_Utils.makeRequestId(self.character, "SignalFirePistol"),
                requestTimestamp = nowMs(),
            })
        else
            local ammo = weapon.getCurrentAmmoCount and weapon:getCurrentAmmoCount() or 0
            if ammo > 0 and weapon.setCurrentAmmoCount then
                weapon:setCurrentAmmoCount(ammo - 1)
                local x = math.floor(tonumber(self.targetX) or self.character:getX())
                local y = math.floor(tonumber(self.targetY) or self.character:getY())
                local z = math.floor(tonumber(self.targetZ) or self.character:getZ())
                CSR_SignalLights.addSignalType("Base.CSR_SignalFlareRound", x, y, z)
                playSoundAt(x, y, z, "M9Shoot")
                if addSound then addSound(self.character, x, y, z, 48, 30) end
            end
        end
    end
    ISBaseTimedAction.perform(self)
end

local function mouseSquare(playerNum, player)
    if not player or not getCell or not ISCoordConversion or not ISCoordConversion.ToWorld then return nil end
    local core = getCore and getCore() or nil
    local zoom = core and core.getZoom and core:getZoom(playerNum) or 1
    local mx = (getMouseX and getMouseX() or 0) * zoom
    local my = (getMouseY and getMouseY() or 0) * zoom
    local wx, wy = ISCoordConversion.ToWorld(mx, my, player:getZ())
    if not wx or not wy then return nil end
    return getCell():getGridSquare(math.floor(wx), math.floor(wy), math.floor(player:getZ()))
end

local function clickedSquare(worldObjects, playerNum, player)
    local fetch = ISWorldObjectContextMenu and ISWorldObjectContextMenu.fetchVars or nil
    if fetch and fetch.clickedSquare then
        return fetch.clickedSquare
    end
    local worldMenu = ISMenuContextWorld and ISMenuContextWorld.getContextData and ISMenuContextWorld.getContextData(playerNum) or nil
    if worldMenu then
        if worldMenu.sqTrue then return worldMenu.sqTrue end
        if worldMenu.sq then return worldMenu.sq end
        if worldMenu.squares and worldMenu.squares[1] then return worldMenu.squares[1] end
    end
    for _, obj in ipairs(worldObjects or {}) do
        local sq = obj and obj.getSquare and obj:getSquare() or nil
        if sq then return sq end
    end
    return mouseSquare(playerNum, player)
end

local function onUseHandFlare(player, item)
    if not player or not item then return end
    ISTimedActionQueue.add(CSR_UseSignalFlareAction:new(player, item))
end

local function onFireSignalPistol(player, weapon, square)
    if not player or not weapon or not square then return end
    ISTimedActionQueue.add(CSR_FireSignalPistolAction:new(player, weapon, square:getX(), square:getY(), square:getZ()))
end

local function addInventoryContext(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local actualItems = items
    if ISInventoryPane and ISInventoryPane.getActualItems then
        actualItems = ISInventoryPane.getActualItems(items)
    end

    for i = 1, #actualItems do
        local item = actualItems[i]
        if CSR_SignalLights.isHandFlare(item) then
            context:addOption(textOr("ContextMenu_CSR_IgniteSignalFlare", "Ignite Signal Flare"), player, onUseHandFlare, item)
            return
        end
    end
end

local function addWorldContext(playerNum, context, worldObjects, test)
    if test then return end
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() then return end

    local weapon = player.getPrimaryHandItem and player:getPrimaryHandItem() or nil
    if not weapon or not weapon.getFullType or weapon:getFullType() ~= "Base.CSR_SignalPistol" then return end

    local square = clickedSquare(worldObjects, playerNum, player)
    if not square then return end

    local option = context:addOption(textOr("ContextMenu_CSR_FireSignalRoundHere", "Fire Signal Round Here"), player, onFireSignalPistol, weapon, square)
    local ammo = weapon.getCurrentAmmoCount and weapon:getCurrentAmmoCount() or 0
    local dx = square:getX() + 0.5 - player:getX()
    local dy = square:getY() + 0.5 - player:getY()
    if ammo <= 0 then
        option.notAvailable = true
        option.toolTip = ISToolTip:new()
        option.toolTip:initialise()
        option.toolTip.description = textOr("IGUI_CSR_SignalNoAmmo", "Signal pistol is empty.")
    elseif dx * dx + dy * dy > 30 * 30 then
        option.notAvailable = true
        option.toolTip = ISToolTip:new()
        option.toolTip:initialise()
        option.toolTip.description = textOr("ContextMenu_CSR_ThrowTooFar", "Target is too far.")
    end
end

local function onServerCommand(module, command, args)
    if module ~= SIGNAL_MODULE or command ~= SIGNAL_COMMAND or not args then return end
    local x = math.floor(tonumber(args.x) or 0)
    local y = math.floor(tonumber(args.y) or 0)
    local z = math.floor(tonumber(args.z) or 0)
    CSR_SignalLights.addLight(x, y, z, args.r, args.g, args.b, args.radius, args.durationMs)
    playSoundAt(x, y, z, args.sound)
end

if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(addInventoryContext)
end

if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(addWorldContext)
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end

return CSR_SignalLights

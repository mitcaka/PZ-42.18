require "CSR_Throwables"
require "CSR_FeatureFlags"
require "CSR_Utils"
require "CSR_SignalLights"
require "ISUI/ISPanel"
require "TimedActions/CSR_ThrowItemAction"

CSR_ThrowablesClient = CSR_ThrowablesClient or {}

local MAX_MENU_ITEMS = 15
local PROJECTILE_BASE_SIZE = 28

local featureEnabled
local activeProjectiles = {}
local projectilePanel = nil

local function nowMs()
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    if os and os.time then return os.time() * 1000 end
    return 0
end

local CSR_ThrowableProjectilePanel = ISPanel:derive("CSR_ThrowableProjectilePanel")

function CSR_ThrowableProjectilePanel:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = false
    return o
end

function CSR_ThrowableProjectilePanel:isMouseOver()
    return false
end

function CSR_ThrowableProjectilePanel:prerender()
    local core = getCore()
    local sw = core:getScreenWidth()
    local sh = core:getScreenHeight()
    if self.width ~= sw or self.height ~= sh then
        self:setWidth(sw)
        self:setHeight(sh)
        if self.javaObject then
            self.javaObject:setWidth(sw)
            self.javaObject:setHeight(sh)
        end
    end
end

function CSR_ThrowableProjectilePanel:render()
    if #activeProjectiles == 0 then return end
    local core = getCore()
    local zoom = core:getZoom(0)
    local offX = IsoCamera.getOffX()
    local offY = IsoCamera.getOffY()
    local now = nowMs()

    for i = #activeProjectiles, 1, -1 do
        local p = activeProjectiles[i]
        local t = (now - p.startMs) / p.durationMs
        if t >= 1.0 then
            table.remove(activeProjectiles, i)
        else
            if t < 0 then t = 0 end
            local wx = p.sx + (p.tx - p.sx) * t
            local wy = p.sy + (p.ty - p.sy) * t
            local wz = p.sz + (p.tz - p.sz) * t + math.sin(t * math.pi) * p.arc
            local sx = IsoUtils.XToScreen(wx, wy, wz, 0)
            local sy = IsoUtils.YToScreen(wx, wy, wz, 0)
            sx = (sx - offX) / zoom
            sy = (sy - offY) / zoom

            local fade = t > 0.82 and math.max(0.0, (1.0 - t) / 0.18) or 1.0
            local size = p.size / zoom
            self:drawRect(sx - size * 0.18, sy + size * 0.32, size * 0.36, math.max(1, 2 / zoom), 0.22 * fade, 0, 0, 0)
            self:drawTextureScaledAspect(p.tex, sx - size / 2, sy - size / 2, size, size, fade, 1.0, 1.0, 1.0)
        end
    end
end

local function ensureProjectilePanel()
    if projectilePanel and projectilePanel.javaObject then return end
    local core = getCore()
    projectilePanel = CSR_ThrowableProjectilePanel:new(0, 0, core:getScreenWidth(), core:getScreenHeight())
    projectilePanel:initialise()
    projectilePanel:instantiate()
    projectilePanel.javaObject:setConsumeMouseEvents(false)
end

local function queueProjectile(tex, sourceX, sourceY, sourceZ, targetX, targetY, targetZ)
    if not (tex and sourceX and sourceY and targetX and targetY) then return end
    local sx = tonumber(sourceX) or 0
    local sy = tonumber(sourceY) or 0
    local sz = tonumber(sourceZ) or 0
    local tx = (tonumber(targetX) or sx) + 0.5
    local ty = (tonumber(targetY) or sy) + 0.5
    local tz = tonumber(targetZ) or sz
    local dx = tx - sx
    local dy = ty - sy
    local dist = math.sqrt(dx * dx + dy * dy)

    ensureProjectilePanel()
    table.insert(activeProjectiles, {
        tex = tex,
        sx = sx,
        sy = sy,
        sz = sz,
        tx = tx,
        ty = ty,
        tz = tz,
        arc = math.max(0.35, math.min(0.95, dist * 0.08)),
        size = PROJECTILE_BASE_SIZE,
        startMs = nowMs(),
        durationMs = math.max(260, math.min(700, 230 + dist * 34)),
    })
end

function CSR_ThrowablesClient.spawnProjectile(item, character, targetX, targetY, targetZ)
    if not featureEnabled() then return end
    if not (item and character and targetX and targetY) then return end
    local tex = item.getTex and item:getTex() or nil
    if not tex and item.getTexture then tex = item:getTexture() end
    if not tex then return end

    queueProjectile(tex, character:getX(), character:getY(), character:getZ(), targetX, targetY, targetZ)
end

function CSR_ThrowablesClient.spawnProjectileFromType(itemType, sourceX, sourceY, sourceZ, targetX, targetY, targetZ)
    if not featureEnabled() then return end
    if not (itemType and sourceX and sourceY and targetX and targetY) then return end
    local item = instanceItem(tostring(itemType))
    if not item then return end
    local tex = item.getTex and item:getTex() or nil
    if not tex and item.getTexture then tex = item:getTexture() end
    if not tex then return end

    queueProjectile(tex, sourceX, sourceY, sourceZ, targetX, targetY, targetZ)
end

function featureEnabled()
    if CSR_FeatureFlags and CSR_FeatureFlags.isThrowableItemsEnabled then
        return CSR_FeatureFlags.isThrowableItemsEnabled()
    end
    return not (SandboxVars and SandboxVars.CommonSenseReborn and SandboxVars.CommonSenseReborn.EnableThrowableItems == false)
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

local function makeTooltip(text)
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip.description = text
    return tooltip
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

local function collectThrowables(player)
    local out = {}
    local seen = {}
    local inv = player and player.getInventory and player:getInventory() or nil
    if not inv then return out end

    local function scan(container)
        if not container or seen[container] then return end
        seen[container] = true
        local items = container.getItems and container:getItems() or nil
        if not items then return end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and CSR_Throwables.isThrowable(item) then
                out[#out + 1] = item
                if #out >= MAX_MENU_ITEMS then return end
            end
        end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local subInv = item and item.getInventory and item:getInventory() or nil
            if subInv then
                scan(subInv)
                if #out >= MAX_MENU_ITEMS then return end
            end
        end
    end

    scan(inv)
    table.sort(out, function(a, b)
        local an = a and a.getDisplayName and a:getDisplayName() or ""
        local bn = b and b.getDisplayName and b:getDisplayName() or ""
        return an < bn
    end)
    return out
end

local function startThrow(player, item, square)
    if not player or not item or not square then return end
    ISTimedActionQueue.add(CSR_ThrowItemAction:new(player, item, square:getX(), square:getY(), square:getZ()))
end

local function addInventoryContext(playerNum, context, items)
    if not featureEnabled() then return end
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() or player:getVehicle() then return end

    local actualItems = items
    if ISInventoryPane and ISInventoryPane.getActualItems then
        actualItems = ISInventoryPane.getActualItems(items)
    end

    for i = 1, #actualItems do
        local item = actualItems[i]
        local profile = CSR_Throwables.getProfile(item)
        if profile and profile.category == "glowstick" then
            local square = player.getCurrentSquare and player:getCurrentSquare() or nil
            local option = context:addOption(textOr("ContextMenu_CSR_ActivateGlowstick", "Activate Glow Stick"), player, startThrow, item, square)
            if item and item.getTexture then
                option.iconTexture = item:getTexture()
            end
            if not square then
                option.notAvailable = true
                option.toolTip = makeTooltip(textOr("ContextMenu_CSR_ThrowTooFar", "No clear target."))
            end
            return
        end
    end
end

local function addContext(playerNum, context, worldObjects, test)
    if test or not featureEnabled() then return end
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() or player:getVehicle() then return end

    local square = clickedSquare(worldObjects, playerNum, player)
    if not square then return end

    local items = collectThrowables(player)
    if #items <= 0 then return end

    local root = context:addOption(textOr("ContextMenu_CSR_ThrowablesRoot", "Throw Item Here..."), worldObjects, nil)
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(root, submenu)

    for i = 1, #items do
        local item = items[i]
        local profile = CSR_Throwables.getProfile(item)
        local name = item and item.getDisplayName and item:getDisplayName() or tostring(item)
        local option = submenu:addOption(textOr("ContextMenu_CSR_ThrowItemHere", "Throw %s", name), player, startThrow, item, square)
        if item and item.getTexture then
            option.iconTexture = item:getTexture()
        end

        local dx = square:getX() + 0.5 - player:getX()
        local dy = square:getY() + 0.5 - player:getY()
        local maxRange = CSR_Throwables.getMaxRange(profile)
        if dx * dx + dy * dy > maxRange * maxRange then
            option.notAvailable = true
            option.toolTip = makeTooltip(textOr("ContextMenu_CSR_ThrowTooFar", "Target is too far."))
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= CSR_Throwables.MODULE or command ~= CSR_Throwables.CMD_IMPACT then
        return
    end
    if not args then return end

    local x = tonumber(args.x)
    local y = tonumber(args.y)
    local z = tonumber(args.z) or 0
    if not x or not y then return end

    local player = getPlayer()
    if player then
        local dx = player:getX() - x
        local dy = player:getY() - y
        if dx * dx + dy * dy > 45 * 45 then
            return
        end
    end

    local sq = getCell() and getCell():getGridSquare(x, y, z) or nil
    if sq and sq.playSound and args.sound and args.sound ~= "" then
        sq:playSound(args.sound)
    end

    if CSR_SignalLights and CSR_SignalLights.addGlowstickImpact then
        CSR_SignalLights.addGlowstickImpact(args.itemType, x, y, z)
    end

    local playerOnlineID = player and player.getOnlineID and player:getOnlineID() or nil
    local sourceOnlineID = args.sourceOnlineID ~= nil and tonumber(args.sourceOnlineID) or nil
    if sourceOnlineID == nil or playerOnlineID == nil or sourceOnlineID ~= playerOnlineID then
        CSR_ThrowablesClient.spawnProjectileFromType(
            args.itemType,
            args.sourceX,
            args.sourceY,
            args.sourceZ,
            x,
            y,
            z)
    end
end

if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(addContext)
end

if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(addInventoryContext)
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end

if Events and Events.OnPostUIDraw then
    Events.OnPostUIDraw.Add(function()
        if #activeProjectiles == 0 then return end
        if not projectilePanel or not projectilePanel.javaObject then return end
        projectilePanel:prerender()
        projectilePanel:render()
    end)
end

return CSR_ThrowablesClient

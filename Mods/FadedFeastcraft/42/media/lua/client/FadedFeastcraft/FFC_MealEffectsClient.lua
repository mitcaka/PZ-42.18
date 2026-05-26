require "FadedFeastcraft/FFC_Boot"
require "ISUI/ISUIElement"

if isServer and isServer() then return end

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.MealEffectsClient = FadedFeastcraft.MealEffectsClient or {}

local Client = FadedFeastcraft.MealEffectsClient
local Effects = FadedFeastcraft.MealEffects
local Utils = FadedFeastcraft.Utils

local TAG = "[FFC-MealEffects]"
local SLOT_W = 38
local SLOT_H = 38
local SLOT_GAP = 5
local textureCache = {}
local hudInstance = nil

local function nowMs()
    return (getTimestampMs and getTimestampMs()) or (os.time() * 1000)
end

local function nowRealMinutes()
    return nowMs() / 60000
end

local function loadTexture(name)
    if not name or name == "" or not getTexture then return nil end
    if textureCache[name] ~= nil then return textureCache[name] end
    local ok, texture = pcall(getTexture, name)
    if ok and texture then
        textureCache[name] = texture
        return texture
    end
    textureCache[name] = false
    return nil
end

local function getActive(player)
    if not player or not player.getModData then return {} end
    local md = player:getModData()
    md[Effects.ACTIVE_KEY] = md[Effects.ACTIVE_KEY] or {}
    return md[Effects.ACTIVE_KEY]
end

function Client.getActive(player)
    return getActive(player)
end

local function showText(player, message, good)
    if not player or not HaloTextHelper then return end
    if good then
        HaloTextHelper.addGoodText(player, message)
    else
        HaloTextHelper.addText(player, message)
    end
end

function Client.applyFromItem(player, item, portion)
    if not Utils.sbBool("EnableMealEffects", true) then return false end
    if not player or not item then return false end

    local data, spec = Effects.readMealEffect(item)
    if not data or not spec then return false end

    local tag = tostring(data.tag or spec.tag or "")
    if tag == "" then return false end

    local cookLevel = tonumber(data.cookLevel) or 0
    local duration = Effects.durationForLevel(cookLevel, portion or 1.0)
    if duration <= 0 then return false end

    local mag = Effects.magnitudeForLevel(cookLevel) * Utils.sbNumber("MealBuffStrength", 1.0, 0.0, 3.0)
    if mag <= 0 then return false end

    local active = getActive(player)
    local now = nowRealMinutes()
    local existing = active[tag]
    if existing and existing.specKey == tag then
        existing.expiry = math.max(tonumber(existing.expiry) or 0, now + duration)
        existing.mag = math.max(tonumber(existing.mag) or 0, mag)
    else
        active[tag] = {
            tag = tag,
            specKey = tag,
            name = spec.name,
            desc = spec.desc,
            cookName = tostring(data.cookName or "Unknown"),
            cookLevel = cookLevel,
            expiry = now + duration,
            mag = mag,
            lastTick = 0,
        }
    end

    if player.transmitModData then
        pcall(function() player:transmitModData() end)
    end

    showText(player, tostring(spec.name or tag) .. " active", true)
    return true
end

local loggedMissing = {}

local function applyComponent(player, component, mag)
    if not player or not component then return end
    local value = (tonumber(component.base) or 0) * (tonumber(mag) or 1)
    if value == 0 then return end
    local stat = tostring(component.stat or "")
    if stat == "" then return end

    if stat == "HEALTH" then
        local bodyDamage = nil
        pcall(function()
            if player.getBodyDamage then bodyDamage = player:getBodyDamage() end
        end)
        if bodyDamage and bodyDamage.AddGeneralHealth then
            pcall(function() bodyDamage:AddGeneralHealth(value) end)
        elseif not loggedMissing[stat] then
            loggedMissing[stat] = true
            Utils.debug(TAG .. " missing BodyDamage.AddGeneralHealth")
        end
        return
    end

    if CharacterStat and CharacterStat[stat] ~= nil then
        local stats = nil
        pcall(function()
            if player.getStats then stats = player:getStats() end
        end)
        if stats and stats.add then
            pcall(function() stats:add(CharacterStat[stat], value) end)
        end
    elseif not loggedMissing[stat] then
        loggedMissing[stat] = true
        Utils.debug(TAG .. " unknown CharacterStat: " .. stat)
    end
end

function Client.tick(player)
    if not Utils.sbBool("EnableMealEffects", true) then return end
    if not player then return end
    local active = getActive(player)
    local now = nowRealMinutes()
    local ms = nowMs()
    local expired = false

    for tag, entry in pairs(active) do
        if (tonumber(entry.expiry) or 0) <= now then
            active[tag] = nil
            expired = true
        end
    end

    for tag, entry in pairs(active) do
        if ms - (tonumber(entry.lastTick) or 0) >= 1000 then
            entry.lastTick = ms
            local spec = Effects.specForTag(entry.specKey or tag)
            if spec and spec.components then
                for _, component in ipairs(spec.components) do
                    applyComponent(player, component, entry.mag or 1.0)
                end
            end
        end
    end

    if expired and player.transmitModData then
        pcall(function() player:transmitModData() end)
    end
end

local function hookEatAction()
    if Client.eatHooked then return end
    if not (ISEatFoodAction and ISEatFoodAction.perform) then
        Utils.debug(TAG .. " ISEatFoodAction unavailable; meal effect hook deferred")
        return
    end

    Client.eatHooked = true
    local originalPerform = ISEatFoodAction.perform
    function ISEatFoodAction:perform(...)
        local item = self.item
        local player = self.character or (getPlayer and getPlayer()) or nil
        local portion = tonumber(self.percentage) or 1.0
        if portion < 0 then portion = 0 end
        if portion > 1 then portion = 1 end

        local result = originalPerform(self, ...)
        pcall(function()
            Client.applyFromItem(player, item, portion)
        end)
        return result
    end
    Utils.debug(TAG .. " eat hook installed")
end

local FFCMealEffectsHUD = ISUIElement:derive("FFCMealEffectsHUD")

function FFCMealEffectsHUD:initialise()
    ISUIElement.initialise(self)
end

function FFCMealEffectsHUD:render()
    if not Utils.sbBool("EnableMealEffectsHUD", true) then return end
    local player = getPlayer and getPlayer() or nil
    if not player then return end
    local active = getActive(player)
    local now = nowRealMinutes()
    local visible = {}
    for _, tag in ipairs(Effects.SLOT_ORDER) do
        if active[tag] then visible[#visible + 1] = tag end
    end

    local hover = nil
    local mx = self:getMouseX()
    local my = self:getMouseY()
    for i, tag in ipairs(visible) do
        local entry = active[tag]
        local spec = Effects.specForTag(tag)
        local x = 0
        local y = (i - 1) * (SLOT_H + SLOT_GAP)
        self:drawRect(x, y, SLOT_W, SLOT_H, 0.58, 0.01, 0.03, 0.04)
        self:drawRectBorder(x, y, SLOT_W, SLOT_H, 0.85, 0.1, 0.72, 0.95)
        local texture = spec and loadTexture(spec.texture)
        if texture and self.drawTextureScaled then
            self:drawTextureScaled(texture, x, y, SLOT_W, SLOT_H, 0.98, 1, 1, 1)
        else
            self:drawText(string.sub(tag, 1, 2), x + 10, y + 10, 0.6, 0.95, 1, 1, UIFont.Medium)
        end

        local remaining = math.max(0, math.floor((tonumber(entry.expiry) or 0) - now))
        local label = tostring(remaining) .. "m"
        self:drawText(label, x + 5, y + SLOT_H - 15, 0, 0, 0, 0.85, UIFont.Small)
        self:drawText(label, x + 4, y + SLOT_H - 16, 0.8, 1, 1, 1, UIFont.Small)

        if mx >= x and mx <= x + SLOT_W and my >= y and my <= y + SLOT_H then
            hover = { tag = tag, entry = entry, spec = spec, remaining = remaining }
        end
    end

    if hover then
        local title = tostring((hover.spec and hover.spec.name) or hover.tag)
        local cook = tostring(hover.entry.cookName or "Unknown") .. " (Cooking " .. tostring(hover.entry.cookLevel or 0) .. ")"
        local lines = { title, tostring((hover.spec and hover.spec.desc) or ""), "Cooked by: " .. cook, "Time remaining: " .. tostring(hover.remaining) .. " min" }
        for _, component in ipairs((hover.spec and hover.spec.components) or {}) do
            lines[#lines + 1] = Effects.statLabel(component.stat)
        end
        local width = 220
        local height = 18 + #lines * 14
        local tx = -width - 10
        local ty = 0
        self:drawRect(tx, ty, width, height, 0.94, 0.02, 0.03, 0.04)
        self:drawRectBorder(tx, ty, width, height, 0.95, 0.1, 0.72, 0.95)
        local lineY = ty + 8
        for index, line in ipairs(lines) do
            local r, g, b = 0.86, 0.94, 0.96
            if index == 1 then r, g, b = 0.45, 0.95, 1 end
            self:drawText(tostring(line), tx + 8, lineY, r, g, b, 1, index == 1 and UIFont.Medium or UIFont.Small)
            lineY = lineY + 14
        end
    end
end

local function ensureHUD()
    if hudInstance or not Utils.sbBool("EnableMealEffectsHUD", true) then return end
    local core = getCore and getCore() or nil
    if not core then return end
    local width = SLOT_W
    local height = SLOT_H * #Effects.SLOT_ORDER + SLOT_GAP * (#Effects.SLOT_ORDER - 1)
    local x = core:getScreenWidth() - width - 58
    local y = math.floor(core:getScreenHeight() * 0.24)
    hudInstance = FFCMealEffectsHUD:new(x, y, width, height)
    hudInstance:initialise()
    hudInstance:instantiate()
    hudInstance:addToUIManager()
    hudInstance:setVisible(true)
    Client.hud = hudInstance
end

if Events and Events.OnGameStart and not Client.gameStartRegistered then
    Client.gameStartRegistered = true
    Events.OnGameStart.Add(function()
        hookEatAction()
        ensureHUD()
    end)
end

if Events and Events.OnPlayerUpdate and not Client.updateRegistered then
    Client.updateRegistered = true
    Events.OnPlayerUpdate.Add(function(player)
        if player and getPlayer and player == getPlayer() then
            if not Client.eatHooked then hookEatAction() end
            Client.tick(player)
        end
    end)
end

return Client

if isServer() then return end

local function uiScale(value)
    if FWPUIScale and FWPUIScale.value then return FWPUIScale.value(value) end
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function textOrFallback(key, fallback)
    if getText and key then
        local value = getText(key)
        if value and value ~= key then return value end
    end
    return fallback or tostring(key or "")
end

local function normalizeSelectedItems(items)
    local result = {}
    if not items then return result end
    for _, entry in ipairs(items) do
        if type(entry) == "table" and entry.items then
            for _, stackedItem in ipairs(entry.items) do
                result[#result + 1] = stackedItem
            end
        else
            result[#result + 1] = entry
        end
    end
    return result
end

local function getItemFullType(item)
    if not item then return nil end
    if item.getFullType then
        local ok, fullType = pcall(item.getFullType, item)
        if ok and fullType and tostring(fullType) ~= "" then return tostring(fullType) end
    end
    if item.getModule and item.getType then
        return tostring(item:getModule()) .. "." .. tostring(item:getType())
    end
    return nil
end

local function isBulletPress(item)
    local fullType = getItemFullType(item)
    if not fullType then return false end
    for _, pressType in ipairs(FWPAmmoManufacture.PRESS_TYPES) do
        if fullType == pressType then return true end
    end
    return false
end

local AMMO_MANUFACTURE_BACKGROUND = "media/textures/fwpAmmoManufactureBackground.png"
local ammoManufactureBackground = nil
local ammoManufactureBackgroundLoaded = false

local function getAmmoManufactureBackground()
    if not ammoManufactureBackgroundLoaded and getTexture then
        ammoManufactureBackground = getTexture(AMMO_MANUFACTURE_BACKGROUND)
        ammoManufactureBackgroundLoaded = true
    end
    return ammoManufactureBackground
end

local COLORS = {
    good = { r = 0.43, g = 0.86, b = 0.55, a = 1.0 },
    bad = { r = 0.95, g = 0.38, b = 0.34, a = 1.0 },
    text = { r = 0.92, g = 0.92, b = 0.88, a = 1.0 },
    muted = { r = 0.63, g = 0.66, b = 0.66, a = 1.0 },
    accent = { r = 0.93, g = 0.72, b = 0.38, a = 1.0 },
    bg = { r = 0.055, g = 0.06, b = 0.065, a = 0.96 },
    panel = { r = 0.09, g = 0.10, b = 0.105, a = 0.92 },
    border = { r = 0.45, g = 0.40, b = 0.32, a = 0.95 },
}

FWPAmmoManufactureWindow = ISCollapsableWindow:derive("FWPAmmoManufactureWindow")

local instance = nil

function FWPAmmoManufactureWindow:new(x, y, width, height, character)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    o.character = character
    o.title = textOrFallback("IGUI_FWP_AMMO_MANUFACTURE_TITLE", "Ammo Manufacture")
    o.backgroundColor = COLORS.bg
    o.borderColor = COLORS.border
    o.pin = false
    o:setResizable(false)
    return o
end

function FWPAmmoManufactureWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    local pad = uiScale(12)
    local titleH = self:titleBarHeight()
    local listW = uiScale(230)
    local btnH = uiScale(28)

    self.recipeList = ISScrollingListBox:new(pad, titleH + pad, listW, self.height - titleH - pad * 2)
    self.recipeList:initialise()
    self.recipeList.itemheight = uiScale(24)
    self.recipeList.selected = 1
    self.recipeList.backgroundColor = { r = 0.035, g = 0.038, b = 0.04, a = 0.82 }
    self.recipeList.borderColor = COLORS.border
    self:addChild(self.recipeList)

    for _, recipe in ipairs(FWPAmmoManufacture.RECIPES) do
        self.recipeList:addItem(textOrFallback(recipe.nameKey, recipe.id), recipe)
    end

    self.craftButton = ISButton:new(self.width - pad - uiScale(150), self.height - pad - btnH, uiScale(150), btnH, textOrFallback("IGUI_FWP_AMMO_MANUFACTURE_CRAFT", "Manufacture"), self, FWPAmmoManufactureWindow.onCraft)
    self.craftButton:initialise()
    self.craftButton.backgroundColor = { r = 0.20, g = 0.16, b = 0.10, a = 0.95 }
    self.craftButton.backgroundColorMouseOver = { r = 0.29, g = 0.22, b = 0.13, a = 1.0 }
    self.craftButton.borderColor = COLORS.border
    self:addChild(self.craftButton)
end

function FWPAmmoManufactureWindow:getSelectedRecipe()
    if not self.recipeList or not self.recipeList.items then return nil end
    local row = self.recipeList.items[self.recipeList.selected or 1]
    return row and row.item or nil
end

function FWPAmmoManufactureWindow:prerender()
    ISCollapsableWindow.prerender(self)
    local recipe = self:getSelectedRecipe()
    local canCraft = false
    if recipe then canCraft = FWPAmmoManufacture.canCraft(self.character, recipe) end
    if self.craftButton then self.craftButton.enable = canCraft == true end
end

local function drawRequirement(self, y, label, have, need)
    local ok = (have or 0) >= (need or 0)
    local c = ok and COLORS.good or COLORS.bad
    self:drawText(label, self.detailX, y, COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a, UIFont.Small)
    self:drawText(tostring(have or 0) .. " / " .. tostring(need or 0), self.detailX + uiScale(230), y, c.r, c.g, c.b, c.a, UIFont.Small)
end

function FWPAmmoManufactureWindow:render()
    ISCollapsableWindow.render(self)
    local pad = uiScale(12)
    local titleH = self:titleBarHeight()
    local detailX = pad + uiScale(250)
    self.detailX = detailX
    local y = titleH + pad
    local w = self.width - detailX - pad
    local background = getAmmoManufactureBackground()
    if background then
        local bgY = titleH
        local bgH = math.max(1, self.height - titleH)
        self:drawTextureScaled(background, 0, bgY, self.width, bgH, 0.58, 1.0, 1.0, 1.0)
        self:drawRect(0, bgY, self.width, bgH, 0.34, 0.0, 0.0, 0.0)
    end
    self:drawRect(detailX - pad, y, w + pad, self.height - titleH - pad * 2, 0.76, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    local recipe = self:getSelectedRecipe()
    if not recipe then return end

    local status = FWPAmmoManufacture.getStatus(self.character, recipe)
    self:drawText(textOrFallback(recipe.nameKey, recipe.id), detailX, y + uiScale(8), COLORS.accent.r, COLORS.accent.g, COLORS.accent.b, COLORS.accent.a, UIFont.Medium)
    self:drawText(textOrFallback("IGUI_FWP_AMMO_MANUFACTURE_OUTPUT", "Output") .. ": " .. tostring(recipe.outputCount) .. " " .. textOrFallback(recipe.nameKey, recipe.id), detailX, y + uiScale(38), COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a, UIFont.Small)
    self:drawText(textOrFallback("IGUI_FWP_AMMO_MANUFACTURE_SKILL", "Reloading") .. ": " .. tostring(status.reloading) .. " / " .. tostring(status.requiredSkill), detailX, y + uiScale(62), status.reloading >= status.requiredSkill and COLORS.good.r or COLORS.bad.r, status.reloading >= status.requiredSkill and COLORS.good.g or COLORS.bad.g, status.reloading >= status.requiredSkill and COLORS.good.b or COLORS.bad.b, 1, UIFont.Small)

    local reqY = y + uiScale(96)
    drawRequirement(self, reqY, textOrFallback("IGUI_FWP_AMMO_MANUFACTURE_PRESS", "Bullet press"), status.press and 1 or 0, 1)
    drawRequirement(self, reqY + uiScale(24), textOrFallback("IGUI_FWP_AMMO_MANUFACTURE_PRIMER", "Primer pack"), status.primer, 1)
    drawRequirement(self, reqY + uiScale(48), textOrFallback("IGUI_FWP_AMMO_MANUFACTURE_PROJECTILE", "Projectile pack"), status.projectile, 1)
    drawRequirement(self, reqY + uiScale(72), textOrFallback("IGUI_FWP_AMMO_MANUFACTURE_CASING", "Casings or hulls"), status.casing, status.casingRequired)
    drawRequirement(self, reqY + uiScale(96), textOrFallback("IGUI_FWP_AMMO_MANUFACTURE_POWDER", "Gunpowder units"), status.powder, status.powderRequired)

    self:drawText(textOrFallback("IGUI_FWP_AMMO_MANUFACTURE_HINT", "Recovered casings and looted bags both count."), detailX, self.height - pad - uiScale(58), COLORS.muted.r, COLORS.muted.g, COLORS.muted.b, COLORS.muted.a, UIFont.Small)
end

function FWPAmmoManufactureWindow:onCraft()
    local recipe = self:getSelectedRecipe()
    if not recipe then return end
    if isClient and isClient() and sendClientCommand then
        sendClientCommand(FWPAmmoManufacture.MODULE, FWPAmmoManufacture.COMMAND_CRAFT, { recipeId = recipe.id })
    else
        FWPAmmoManufacture.performCraft(self.character, recipe.id)
    end
end

function FWPAmmoManufactureWindow:close()
    ISCollapsableWindow.close(self)
    instance = nil
end

function FWPAmmoManufactureWindow.open(character)
    if instance then
        instance:setVisible(true)
        instance:bringToTop()
        return instance
    end
    local core = getCore()
    local width = uiScale(680)
    local height = uiScale(420)
    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2
    instance = FWPAmmoManufactureWindow:new(x, y, width, height, character)
    instance:initialise()
    instance:addToUIManager()
    return instance
end

FWPAmmoManufactureUI = {
    open = FWPAmmoManufactureWindow.open
}

local function onInventoryContext(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    for _, item in ipairs(normalizeSelectedItems(items)) do
        if item and isBulletPress(item) then
            context:addOption(textOrFallback("ContextMenu_FWP_OpenAmmoManufacture", "Open Ammo Manufacture"), item, function()
                FWPAmmoManufactureWindow.open(player)
            end)
            return
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onInventoryContext)

require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISInventoryPaneContextMenu"
require "Entity/ISEntityUI"
require "Entity/TimedActions/ISHandcraftAction"
require "FadedFeastcraft/FFC_Boot"
require "FadedFeastcraft/FFC_Balance"
require "FadedFeastcraft/FFC_Preservation"
require "FadedFeastcraft/FFC_Compatibility"
require "FadedFeastcraft/UI/FFC_Theme"
require "FadedFeastcraft/UI/FFC_CookingStatusPanel"
require "FadedFeastcraft/TimedActions/FFC_QueuedStationCookAction"

FadedFeastcraft = FadedFeastcraft or {}

local Utils = FadedFeastcraft.Utils
local Branding = FadedFeastcraft.Branding
local Scanner = FadedFeastcraft.IngredientScanner
local ExpiryTracker = FadedFeastcraft.ExpiryTracker
local Recipes = FadedFeastcraft.RecipeIndex
local Planner = FadedFeastcraft.MealPlanner
local AutoPlanner = FadedFeastcraft.AutoCookPlanner
local MealEffects = FadedFeastcraft.MealEffects
local Net = FadedFeastcraft.Net
local Theme = FadedFeastcraft.Theme
local SourcePacks = FadedFeastcraft.SourcePackRegistry
local Operations = FadedFeastcraft.OperationRegistry
local Actions = FadedFeastcraft.SourceActionIndex
local CookingStation = FadedFeastcraft.CookingStation
local DirectRecipes = FadedFeastcraft.DirectRecipeRegistry
local Balance = FadedFeastcraft.Balance
local Preservation = FadedFeastcraft.Preservation
local Compatibility = FadedFeastcraft.Compatibility

FFC_MainWindow = ISCollapsableWindow:derive("FFC_MainWindow")
FFC_MainWindow.instance = nil

local DETAIL_GAP = 18
local LIST_SCROLLBAR_RESERVE = 18
local WINDOW_PAD = 10
local CONTROL_GAP = 6
local CONTROL_H = 24
local FOOTER_TOP_GAP = 12
local FOOTER_BOTTOM_PAD = 16
local LIST_WIDTH_RATIO = 0.45
local MIN_LIST_WIDTH = 260
local MIN_DETAIL_WIDTH = 340
local MIN_WINDOW_WIDTH = 720
local MIN_WINDOW_HEIGHT = 420

local TABS = {
    { id = "ingredients", label = "Pantry" },
    { id = "recipes", label = "Cookbook" },
    { id = "station", label = "Cook" },
    { id = "meal", label = "Builder" },
    { id = "operations", label = "Prep" },
    { id = "preservation", label = "Preserve" },
    { id = "expiry", label = "Expiry" },
    { id = "help", label = "Guide" },
    { id = "advanced", label = "Advanced" },
}

local RECIPE_VIEW_FILTERS = {
    { id = "craftable", label = "Craftable" },
    { id = "known", label = "Known" },
    { id = "almost", label = "Almost" },
    { id = "all", label = "All" },
}

local GUIDE_SECTIONS = {
    {
        name = "Start here",
        detail = "The shortest path through FFC when the window feels busy.",
        lines = {
            "Faded's Feastcraft is a food command center. It gathers cooking, prep, storage, nutrition, expiry, and preservation into one searchable window.",
            "You do not need every tab every session. Press Refresh after moving food, then pick the task you care about.",
            "For day-to-day cooking: Pantry shows what is safe, Cookbook handles known recipes, Cook uses nearby heat, Builder packs selected food into an FFC meal, and Preserve helps plan long-term storage.",
            "Rows with warnings are there to prevent bad clicks. Actual inventory changes still go through server validation.",
        },
    },
    {
        name = "What FFC adds",
        detail = "The main gameplay additions at a glance.",
        lines = {
            "A searchable food dashboard instead of overloaded right-click menus.",
            "Server-authoritative meal building, prep operations, station cooking, and direct FFC recipes.",
            "Cooking skill tuning for FFC-created meals: nutrition retention, weight handling, freshness bonuses, and meal-effect metadata.",
            "Preserved FFC foods with stamped shelf-life data that appears in Pantry, Expiry, and item details.",
            "Compatibility checks for B42.18, CSR helpers, duplicate embedded source packs, and common food UI overlap.",
        },
    },
    {
        name = "Use this order",
        detail = "A simple loop for normal play.",
        lines = {
            "1. Refresh: rebuild the current food scan after looting, cooking, or moving containers.",
            "2. Pantry: inspect safe, blocked, frozen, rotten, burned, and preserved food.",
            "3. Cook: use nearby stoves, grills, campfires, microwaves, vessels, and safe ingredients.",
            "4. Builder: choose ingredients manually or use Suggest Meal to create an FFC field meal.",
            "5. Expiry: decide what to eat first.",
            "6. Advanced: review storage, nutrition, library, CSR, and compatibility diagnostics when you need them.",
        },
    },
    {
        name = "Tabs in plain English",
        detail = "What each tab is meant to answer.",
        lines = {
            "Pantry: all scanned food and whether FFC considers it usable.",
            "Cookbook: known, craftable, almost-ready, and all food recipes with requirements shown in FFC.",
            "Cook: nearby heat, freeform hot meals, and craftable cooking recipes.",
            "Builder: manual or suggested FFC meal creation.",
            "Prep: open, unpack, package, and recipe-focused prep operations.",
            "Preserve: long-term food planning and preservation recipes.",
            "Expiry: what should be eaten soon; Scan Room adds current-room containers once.",
            "Guide: quick help.",
            "Advanced: storage, nutrition, library, compatibility, and CSR diagnostics.",
        },
    },
    {
        name = "Why food is blocked",
        detail = "What warning rows mean before you craft.",
        lines = {
            "Frozen food is blocked for normal FFC meals unless a specific action allows it.",
            "Rotten, burned, and dangerous raw food are blocked so FFC does not quietly create unsafe meals.",
            "Prepared FFC meals cannot be reused as regular Builder ingredients.",
            "A blocked recipe or operation usually means a tool, safe ingredient, or accessible container changed since the last scan.",
            "Refresh after moving food or tools. If the row still warns you, trust the warning.",
        },
    },
    {
        name = "Preservation basics",
        detail = "How the Preserve and Expiry systems fit together.",
        lines = {
            "Preserve is for planning long-term food, not just browsing recipes.",
            "FFC direct preservation recipes create packed or preserved FFC foods when the required source meal is available.",
            "Preserved FFC items receive FFC_Preservation metadata with method, source, created world age, and estimated shelf days.",
            "Expiry reads that metadata first, so preserved food sorts as pantry-stable instead of behaving like a normal fresh meal.",
            "The sandbox preservation balance mode changes shelf-life estimates without changing the whole UI.",
        },
    },
    {
        name = "Multiplayer safety",
        detail = "What happens when you press a crafting button.",
        lines = {
            "The client scans and previews. The server decides.",
            "Craft buttons send item IDs and simple request data, then the server rechecks access, duplicates, item state, tools, and expected outputs.",
            "If food moved, spoiled, thawed, froze, or disappeared after the scan, the server can reject the action.",
            "Batch Safe is still server validated one operation at a time, with a sandbox limit.",
            "This is why some actions say they are waiting for server validation even in local play.",
        },
    },
}

local function itemColor(record)
    if record.blocked or record.usable == false then return Theme.colors.bad end
    if record.kind == "expiry" and record.expiryStatus == "Rotten" then return Theme.colors.bad end
    if record.kind == "expiry" and record.expirySort and record.expirySort < 1 then return Theme.colors.warn end
    if record.kind == "expiry" and record.expirySort and record.expirySort < 3 then return { r = 1.0, g = 0.76, b = 0.35, a = 1 } end
    if record.kind == "expiry" and record.expirySort and record.expirySort >= 999998 then return Theme.colors.cyan end
    if record.kind == "stationRecipe" and not record.blocked then return Theme.colors.good end
    if record.kind == "quickAction" or record.kind == "guide" then return Theme.colors.cyan end
    if record.kind == "compat" and record.severity == "warn" then return Theme.colors.warn end
    if record.kind == "compat" and record.severity == "ok" then return Theme.colors.good end
    if record.frozen then return Theme.colors.warn end
    return Theme.colors.text
end

local function setButtonTitle(button, title)
    if not button then return end
    if button.setTitle then
        button:setTitle(title)
    else
        button.title = title
    end
end

local function loadCookingIcon()
    if not getTexture then return nil end
    local ok, texture = pcall(getTexture, "media/ui/FFC_CookingIcon.png")
    if ok then return texture end
    return nil
end

local textureCache = {}

local function loadTexture(textureName)
    if not textureName or textureName == "" or not getTexture then return nil end
    if textureCache[textureName] ~= nil then return textureCache[textureName] end
    local ok, texture = pcall(getTexture, textureName)
    if ok and texture then
        textureCache[textureName] = texture
        return texture
    end
    textureCache[textureName] = false
    return nil
end

local function textureForRecord(record, fallback)
    if not record then return fallback end
    local texture = loadTexture(record.textureName)
    if texture then return texture end
    if record.resultType and Utils and Utils.getScriptItem and Utils.getScriptItemTextureName then
        texture = loadTexture(Utils.getScriptItemTextureName(Utils.getScriptItem(record.resultType)))
        if texture then return texture end
    end
    return fallback
end

local recipeHoverName

local function drawRecordIconStrip(ui, records, x, y, maxWidth, fallback)
    if not ui or not ui.drawTextureScaled or not records or #records == 0 then return y end
    local size = 24
    local gap = 5
    local drawn = 0
    local limit = math.max(1, math.floor((maxWidth + gap) / (size + gap)))
    for _, record in ipairs(records) do
        if drawn >= limit then break end
        local texture = textureForRecord(record, fallback)
        if texture then
            local ix = x + drawn * (size + gap)
            ui:drawTextureScaled(texture, ix, y, size, size, record.blocked and 0.45 or 0.9, 1, 1, 1)
            ui:drawRectBorder(ix - 1, y - 1, size + 2, size + 2, 0.32, 0.1, 0.65, 0.82)
            if ui.getMouseX and ui.getMouseY then
                local mx = ui:getMouseX()
                local my = ui:getMouseY()
                if mx >= ix and mx <= ix + size and my >= y and my <= y + size then
                    ui.iconHoverText = recipeHoverName(record)
                end
            end
            drawn = drawn + 1
        end
    end
    if drawn > 0 then return y + size + 8 end
    return y
end

local function scrubSourceText(value)
    if Branding and Branding.scrubText then
        return Branding.scrubText(value)
    end
    return tostring(value or "")
end

local function foodName(value, fallback)
    if Branding and Branding.foodName then
        return Branding.foodName(value, fallback)
    end
    return scrubSourceText(value)
end

local function recipeResultName(record)
    if not record or not record.resultType or record.resultType == "" then
        return "dynamic result"
    end
    return foodName(record.resultType, "recipe result")
end

local function displayTitle(record, text)
    if not record then return tostring(text or "") end
    if record.kind == "craftRecipe" or record.kind == "recipe" or record.kind == "directRecipeAction" then
        return scrubSourceText(text or record.name or "")
    end
    return tostring(text or "")
end

local function recipeKindLabel(record)
    if record.kind == "craftRecipe" then return "FFC handcraft recipe" end
    if record.kind == "recipe" then return "Legacy recipe" end
    return "Recipe"
end

local function inHouseCraftStarted(context, action)
    if not context then return end
    context.action = action
    if context.logic and context.logic.startCraftAction then
        pcall(context.logic.startCraftAction, context.logic, action)
    end
end

local function inHouseCraftCancelled(context)
    if not context or context.completed then return end
    context.cancelled = true
    if context.logic and context.logic.stopCraftAction then
        pcall(context.logic.stopCraftAction, context.logic)
    end
    local win = context.window
    if win then
        win:restoreAfterQueuedCooking()
        win:setActiveTab(context.tabId or "recipes")
        win.detailRecord = context.record
        win.detailLines = Recipes and Recipes.describeRecipe and Recipes.describeRecipe(context.record, getSpecificPlayer and getSpecificPlayer(0) or nil) or win:detailForRecord(context.record)
        win.detailLines[#win.detailLines + 1] = "Craft cancelled before completion."
    end
end

local function inHouseCraftCompleted(context)
    if not context or context.cancelled or context.completed then return end
    context.completed = true
    if context.logic and context.logic.stopCraftAction then
        pcall(context.logic.stopCraftAction, context.logic)
    end
    local win = context.window
    if win then
        win:restoreAfterQueuedCooking()
        win:setActiveTab(context.tabId or "recipes")
        win:refreshData()
        win.detailRecord = context.record
        win.detailLines = Recipes and Recipes.describeRecipe and Recipes.describeRecipe(context.record, getSpecificPlayer and getSpecificPlayer(0) or nil) or win:detailForRecord(context.record)
        win.detailLines[#win.detailLines + 1] = "Craft completed through FFC."
    end
end

local function isPreservationRecipe(record)
    if not record then return false end
    if record.family == "preservation" then return true end
    local text = Utils.lower(tostring(record.name or "") .. " " .. tostring(record.source or "") .. " " .. tostring(record.tags or "") .. " " .. tostring(record.resultType or ""))
    local keywords = {
        "preserv",
        "canning",
        "canned",
        "canof",
        "jar",
        "pickl",
        "salt",
        "dry",
        "dried",
        "smok",
    }
    for _, keyword in ipairs(keywords) do
        if string.find(text, keyword, 1, true) then return true end
    end
    return false
end

local PRESERVATION_FILTERS = {
    { id = "all", label = "All", words = {} },
    { id = "canning", label = "Canning", words = { "can", "canning", "canned", "canof" } },
    { id = "jars", label = "Jars", words = { "jar", "jarred" } },
    { id = "drying", label = "Drying", words = { "dry", "dried" } },
    { id = "salting", label = "Salting", words = { "salt", "salted" } },
    { id = "pickling", label = "Pickling", words = { "pickl" } },
    { id = "smoking", label = "Smoking", words = { "smok" } },
}

local function preservationFilterLabel(filterId)
    for _, filter in ipairs(PRESERVATION_FILTERS) do
        if filter.id == filterId then return filter.label end
    end
    return PRESERVATION_FILTERS[1].label
end

local function nextPreservationFilter(filterId)
    for index, filter in ipairs(PRESERVATION_FILTERS) do
        if filter.id == filterId then
            local nextFilter = PRESERVATION_FILTERS[index + 1] or PRESERVATION_FILTERS[1]
            return nextFilter.id, nextFilter.label
        end
    end
    return PRESERVATION_FILTERS[1].id, PRESERVATION_FILTERS[1].label
end

local function preservationModeMatches(record, filterId)
    local id = tostring(filterId or "all")
    if id == "all" then return true end
    local filter = nil
    for _, candidate in ipairs(PRESERVATION_FILTERS) do
        if candidate.id == id then
            filter = candidate
            break
        end
    end
    if not filter then return true end
    local text = Utils.lower(tostring(record.name or "") .. " " .. tostring(record.resultType or "") .. " " .. tostring(record.tags or "") .. " " .. tostring(record.search or ""))
    for _, word in ipairs(filter.words or {}) do
        if string.find(text, word, 1, true) then return true end
    end
    return false
end

local function measureText(font, text)
    if getTextManager then
        return getTextManager():MeasureStringX(font or UIFont.Small, tostring(text or ""))
    end
    return string.len(tostring(text or "")) * 7
end

local function fitText(font, text, maxWidth)
    text = tostring(text or "")
    maxWidth = tonumber(maxWidth) or 0
    if maxWidth <= 0 or measureText(font, text) <= maxWidth then return text end
    local suffix = "..."
    while #text > 1 and measureText(font, text .. suffix) > maxWidth do
        text = string.sub(text, 1, #text - 1)
    end
    return text .. suffix
end

local function wrapText(font, text, maxWidth)
    text = tostring(text or "")
    if text == "" then return { "" } end
    local out = {}
    for rawLine in string.gmatch(text, "([^\n]+)") do
        local line = ""
        for word in string.gmatch(rawLine, "%S+") do
            local candidate = line == "" and word or (line .. " " .. word)
            if line ~= "" and measureText(font, candidate) > maxWidth then
                out[#out + 1] = line
                line = word
            else
                line = candidate
            end
        end
        out[#out + 1] = line
    end
    return out
end

local function tabWidth(tab)
    if tab.id == "dashboard" then return 54 end
    if tab.id == "recipes" then return 82 end
    if tab.id == "ingredients" then return 66 end
    if tab.id == "expiry" then return 62 end
    if tab.id == "storage" then return 56 end
    if tab.id == "nutrition" then return 56 end
    if tab.id == "operations" then return 48 end
    if tab.id == "preservation" then return 74 end
    if tab.id == "station" then return 56 end
    if tab.id == "meal" then return 72 end
    if tab.id == "sources" then return 70 end
    if tab.id == "compat" then return 66 end
    if tab.id == "csr" then return 48 end
    if tab.id == "help" then return 58 end
    if tab.id == "advanced" then return 82 end
    return 64
end

local function recipeViewFilterLabel(filterId)
    local id = tostring(filterId or "craftable")
    for _, filter in ipairs(RECIPE_VIEW_FILTERS) do
        if filter.id == id then return filter.label end
    end
    return RECIPE_VIEW_FILTERS[1].label
end

local function nextRecipeViewFilter(filterId)
    local current = tostring(filterId or "craftable")
    for index, filter in ipairs(RECIPE_VIEW_FILTERS) do
        if filter.id == current then
            local nextFilter = RECIPE_VIEW_FILTERS[index + 1] or RECIPE_VIEW_FILTERS[1]
            return nextFilter.id, nextFilter.label
        end
    end
    return RECIPE_VIEW_FILTERS[1].id, RECIPE_VIEW_FILTERS[1].label
end

local function directRecipeMatchesView(record, filterId)
    local id = tostring(filterId or "craftable")
    if id == "all" or id == "known" then return true end
    if id == "craftable" then return record and record.blocked ~= true end
    if id == "almost" then return record and record.blocked == true end
    return true
end

local function storageSummaryLines(cache)
    local groups = {}
    local order = {}
    for _, record in ipairs((cache and cache.records) or {}) do
        local origin = tostring(record.origin or "Inventory")
        local container = tostring(record.containerType or "")
        if container == "" then container = "food container" end
        local key = origin .. " / " .. container
        if not groups[key] then
            groups[key] = { total = 0, safe = 0, blocked = 0 }
            order[#order + 1] = key
        end
        groups[key].total = groups[key].total + 1
        if record.usable == false or record.frozen or record.rotten or record.burnt then
            groups[key].blocked = groups[key].blocked + 1
        else
            groups[key].safe = groups[key].safe + 1
        end
    end
    table.sort(order)
    local lines = {
        "Storage summary: " .. tostring(#order) .. " food locations in the current scan.",
    }
    for i, key in ipairs(order) do
        if i > 4 then
            lines[#lines + 1] = "Storage: +" .. tostring(#order - 4) .. " more locations."
            break
        end
        local group = groups[key]
        lines[#lines + 1] = "Storage: " .. key .. " - " .. tostring(group.total) .. " foods, " .. tostring(group.safe) .. " safe, " .. tostring(group.blocked) .. " blocked."
    end
    return lines
end

local function nutritionSummaryLines(cache)
    local totals = { count = 0, blocked = 0, hunger = 0, calories = 0, proteins = 0, lipids = 0, carbohydrates = 0 }
    for _, record in ipairs((cache and cache.records) or {}) do
        totals.count = totals.count + 1
        if record.usable == false or record.frozen or record.rotten or record.burnt then
            totals.blocked = totals.blocked + 1
        else
            totals.hunger = totals.hunger + (tonumber(record.hunger) or 0)
            totals.calories = totals.calories + (tonumber(record.calories) or 0)
            totals.proteins = totals.proteins + (tonumber(record.proteins) or 0)
            totals.lipids = totals.lipids + (tonumber(record.lipids) or 0)
            totals.carbohydrates = totals.carbohydrates + (tonumber(record.carbohydrates) or 0)
        end
    end
    return {
        "Nutrition summary: " .. tostring(totals.count) .. " scanned foods, " .. tostring(totals.blocked) .. " blocked.",
        "Safe hunger reduction: " .. tostring(Utils.round(math.abs(totals.hunger * 100), 1)),
        "Safe calories: " .. tostring(Utils.round(totals.calories, 0)),
        "Protein/Fat/Carbs: " .. tostring(Utils.round(totals.proteins, 1)) .. " / " .. tostring(Utils.round(totals.lipids, 1)) .. " / " .. tostring(Utils.round(totals.carbohydrates, 1)),
    }
end

local function recipePrepMatches(recipe, opRecord)
    if not recipe or not opRecord then return true end
    local recipeText = Utils.lower(tostring(recipe.requirementText or "") .. " " .. tostring(recipe.search or "") .. " " .. tostring(recipe.resultType or ""))
    if recipeText == "" then return true end
    local opText = Utils.lower(tostring(opRecord.fullType or "") .. " " .. tostring(opRecord.name or "") .. " " .. tostring(opRecord.search or "") .. " " .. scrubSourceText(Operations and Operations.outputPreview and Operations.outputPreview(opRecord.operation) or ""))
    if opText == "" then return false end
    for token in string.gmatch(opText, "[%w_%.]+") do
        if #token >= 4 and string.find(recipeText, token, 1, true) then return true end
    end
    return false
end

function recipeHoverName(record)
    if not record then return "" end
    local name = tostring(record.name or record.fullType or "")
    local category = tostring(record.category or "")
    local freshness = tostring(record.freshness or "")
    if category ~= "" or freshness ~= "" then
        return name .. "  " .. category .. "  " .. freshness
    end
    return name
end

local function setFrame(control, x, y, w, h)
    if not control then return end
    if x ~= nil then
        if control.setX then control:setX(x) else control.x = x end
    end
    if y ~= nil then
        if control.setY then control:setY(y) else control.y = y end
    end
    if w ~= nil then
        if control.setWidth then control:setWidth(w) else control.width = w end
    end
    if h ~= nil then
        if control.setHeight then control:setHeight(h) else control.height = h end
    end
end

function FFC_MainWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    self.navButtons = {}
    local x = 10
    local y = self:titleBarHeight() + 8
    for _, tab in ipairs(TABS) do
        local w = tabWidth(tab)
        local button = ISButton:new(x, y, w, 24, tab.label, self, FFC_MainWindow.onTabButton)
        button.internal = tab.id
        button:initialise()
        button:instantiate()
        self:addChild(button)
        self.navButtons[tab.id] = button
    end

    self.refreshButton = ISButton:new(self.width - 102, y, 92, 24, "Refresh", self, FFC_MainWindow.onRefresh)
    self.refreshButton.anchorLeft = false
    self.refreshButton.anchorRight = true
    self.refreshButton:initialise()
    self.refreshButton:instantiate()
    self:addChild(self.refreshButton)

    self.searchBox = ISTextEntryBox:new("", 10, y + 34, self.width - 20, 24)
    self.searchBox:initialise()
    self.searchBox:instantiate()
    self.searchBox:setAnchorRight(true)
    self.searchBox:setText("")
    self.searchBox.target = self
    self.searchBox.onTextChangeFunction = FFC_MainWindow.onSearchTextChanged
    self.searchBox.onCommandEntered = FFC_MainWindow.onSearchCommandEntered
    self:addChild(self.searchBox)

    self.list = ISScrollingListBox:new(10, y + 66, math.floor(self.width * 0.48), self.height - y - 86)
    self.list:initialise()
    self.list:instantiate()
    self.list:setAnchorBottom(true)
    self.list.itemheight = 48
    self.list.doDrawItem = FFC_MainWindow.drawListItem
    self.list.target = self
    self.list.onMouseDown = FFC_MainWindow.onListMouseDown
    self.list.onMouseMove = FFC_MainWindow.onListMouseMove
    self.list.onMouseUp = FFC_MainWindow.onListMouseUp
    self.list.onMouseUpOutside = FFC_MainWindow.onListMouseUpOutside
    self:addChild(self.list)

    self.craftButton = ISButton:new(self.width - 150, self.height - 34, 140, 24, "Build Meal", self, FFC_MainWindow.onPrimaryAction)
    self.craftButton.anchorLeft = false
    self.craftButton.anchorRight = true
    self.craftButton.anchorTop = false
    self.craftButton.anchorBottom = true
    self.craftButton:initialise()
    self.craftButton:instantiate()
    self:addChild(self.craftButton)

    self.secondaryButton = ISButton:new(self.width - 268, self.height - 34, 112, 24, "Suggest", self, FFC_MainWindow.onSecondaryAction)
    self.secondaryButton.anchorLeft = false
    self.secondaryButton.anchorRight = true
    self.secondaryButton.anchorTop = false
    self.secondaryButton.anchorBottom = true
    self.secondaryButton:initialise()
    self.secondaryButton:instantiate()
    self:addChild(self.secondaryButton)

    self.modeButton = ISButton:new(self.width - 434, self.height - 34, 160, 24, "Mode: Balanced", self, FFC_MainWindow.onModeButton)
    self.modeButton.anchorLeft = false
    self.modeButton.anchorRight = true
    self.modeButton.anchorTop = false
    self.modeButton.anchorBottom = true
    self.modeButton:initialise()
    self.modeButton:instantiate()
    self:addChild(self.modeButton)

    self.cookingIcon = loadCookingIcon()
    self:layoutChrome()
    self:setActiveTab("ingredients")
end

function FFC_MainWindow:layoutChrome()
    if not self.navButtons then return end
    local pad = WINDOW_PAD
    local gap = CONTROL_GAP
    local rowH = CONTROL_H
    local baseY = self:titleBarHeight() + 8
    local refreshW = 92
    local refreshX = math.max(pad, self.width - refreshW - pad)
    setFrame(self.refreshButton, refreshX, baseY, refreshW, rowH)

    local x = pad
    local row = 0
    local firstRowRight = refreshX - gap
    local fullRowRight = self.width - pad
    for _, tab in ipairs(TABS) do
        local button = self.navButtons[tab.id]
        local w = tabWidth(tab)
        local rowRight = row == 0 and firstRowRight or fullRowRight
        if x + w > rowRight and x > pad then
            row = row + 1
            x = pad
            rowRight = fullRowRight
        end
        setFrame(button, x, baseY + row * (rowH + gap), w, rowH)
        x = x + w + gap
    end

    local contentY = baseY + (row + 1) * (rowH + gap) + 4
    setFrame(self.searchBox, pad, contentY, self.width - (pad * 2), 24)

    local listY = contentY + 32
    local footerY = math.max(listY + 132, self.height - FOOTER_BOTTOM_PAD - rowH)
    local panelH = math.max(120, footerY - listY - FOOTER_TOP_GAP)
    local contentW = math.max(240, self.width - (pad * 2))
    local panelW = math.max(180, contentW - DETAIL_GAP)
    local listW = math.floor(panelW * LIST_WIDTH_RATIO)
    local maxListW = math.max(120, panelW - MIN_DETAIL_WIDTH)
    local minListW = math.min(MIN_LIST_WIDTH, math.floor(panelW * 0.55))
    if listW > maxListW then listW = maxListW end
    if listW < minListW then listW = minListW end
    listW = math.max(120, listW)

    local detailX = pad + listW + DETAIL_GAP
    local detailW = math.max(160, self.width - detailX - pad)
    setFrame(self.list, pad, listY, listW, panelH)
    self.detailFrame = { x = detailX, y = listY, w = detailW, h = panelH }

    local craftW = 128
    local secondaryW = 106
    local modeW = 142
    local actionTotalW = modeW + secondaryW + craftW + (gap * 2)
    if actionTotalW > detailW then
        modeW = math.max(118, modeW - (actionTotalW - detailW))
        actionTotalW = modeW + secondaryW + craftW + (gap * 2)
    end
    local actionX = math.max(detailX, self.width - pad - actionTotalW)
    if actionX + actionTotalW > self.width - pad then
        actionX = math.max(pad, self.width - pad - actionTotalW)
    end
    local buttonY = footerY
    setFrame(self.modeButton, actionX, buttonY, modeW, rowH)
    setFrame(self.secondaryButton, actionX + modeW + gap, buttonY, secondaryW, rowH)
    setFrame(self.craftButton, actionX + modeW + gap + secondaryW + gap, buttonY, craftW, rowH)
end

function FFC_MainWindow:onTabButton(button)
    self:setActiveTab(button.internal)
end

function FFC_MainWindow:setActiveTab(tabId)
    self.activeTab = tabId or "ingredients"
    for id, button in pairs(self.navButtons or {}) do
        if id == self.activeTab then
            button.backgroundColor = { r = 0.05, g = 0.35, b = 0.46, a = 0.9 }
        else
            button.backgroundColor = { r = 0.05, g = 0.07, b = 0.08, a = 0.85 }
        end
    end
    self.selectedIngredientIds = self.selectedIngredientIds or {}
    if self.activeTab ~= "operations" then
        self.selectedOperationRecord = nil
    end
    if self.activeTab ~= "station" then
        self.selectedStationCandidate = nil
    end
    if self.activeTab ~= "ingredients" then
        self.selectedPantryRecord = nil
    end
    if self.activeTab ~= "recipes" and self.activeTab ~= "preservation" then
        self.selectedRecipeRecord = nil
    end
    self.detailRecord = nil
    self:refreshList()
end

function FFC_MainWindow:onRefresh()
    self:refreshData(true)
end

function FFC_MainWindow:onSearchChanged(entry, committed)
    self.selectedRecipeRecord = nil
    self.selectedStationCandidate = nil
    self.selectedOperationRecord = nil
    self.detailRecord = nil
    self:refreshList()
end

function FFC_MainWindow.onSearchTextChanged(target, entry)
    if target and target.onSearchChanged then
        target:onSearchChanged(entry, false)
    end
end

function FFC_MainWindow.onSearchCommandEntered(entry)
    local target = entry and entry.target or nil
    if target and target.onSearchChanged then
        target:onSearchChanged(entry, true)
    end
    if entry and entry.unfocus then entry:unfocus() end
end

function FFC_MainWindow:onModeButton()
    if self.activeTab == "recipes" then
        self.recipeViewFilterId = nextRecipeViewFilter(self.recipeViewFilterId or "craftable")
        self.selectedRecipeRecord = nil
        self.detailRecord = nil
        self:refreshList()
        return
    elseif self.activeTab == "preservation" then
        self.preservationViewFilterId = nextRecipeViewFilter(self.preservationViewFilterId or "craftable")
        self.selectedRecipeRecord = nil
        self.detailRecord = nil
        self:refreshList()
        return
    end
    local mode = AutoPlanner and AutoPlanner.nextMode and AutoPlanner.nextMode(self.cookModeId or "balanced") or nil
    self.cookModeId = mode and mode.id or "balanced"
    self.selectedStationCandidate = nil
    local stationCache = CookingStation and CookingStation.getCache and CookingStation.getCache() or nil
    self:refreshData(false, {
        includeNearby = self.activeTab == "station" and stationCache and stationCache.includeNearby == true,
    })
end

function FFC_MainWindow:onSecondaryAction()
    if self.activeTab == "meal" then
        self:onSuggestMeal()
    elseif self.activeTab == "operations" then
        self:onBatchOperations()
    elseif self.activeTab == "station" then
        self:onScanCookingNearby()
    elseif self.activeTab == "expiry" then
        self:onScanExpiryRoom()
    elseif self.activeTab == "recipes" then
        self.recipeFilterId = Recipes and Recipes.nextFilter and Recipes.nextFilter(self.recipeFilterId or "all") or "all"
        self.selectedRecipeRecord = nil
        self.detailRecord = nil
        self:refreshList()
    elseif self.activeTab == "preservation" then
        self.preservationFilterId = nextPreservationFilter(self.preservationFilterId or "all")
        self.selectedRecipeRecord = nil
        self.detailRecord = nil
        self:refreshList()
    end
end

function FFC_MainWindow:refreshData(force, options)
    force = force == true
    options = options or {}
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local includeNearby = options.includeNearby == true
    local needsRecipeIndex = force
        or self.activeTab == "recipes"
        or self.activeTab == "preservation"
        or self.activeTab == "station"
        or self.activeTab == "advanced"
    local needsDirectRecipes = force
        or self.activeTab == "recipes"
        or self.activeTab == "preservation"
        or self.activeTab == "advanced"

    FadedFeastcraft.CSR.refresh()
    if Actions and Actions.build and (force or self.activeTab == "operations" or self.activeTab == "advanced") then
        Actions.build(force)
    end
    Scanner.scan(player, { includeNearby = includeNearby })
    if ExpiryTracker and ExpiryTracker.scan and (force or self.activeTab == "expiry" or self.activeTab == "advanced") then
        ExpiryTracker.scan(player, { includeRoom = false })
    end
    if DirectRecipes and DirectRecipes.build and needsDirectRecipes then
        DirectRecipes.build(force)
    end
    if Recipes and Recipes.build and needsRecipeIndex then
        Recipes.build(force)
    end
    if CookingStation and CookingStation.scan and (force or self.activeTab == "station") then
        CookingStation.scan(player, {
            modeId = self.cookModeId or "balanced",
            includeNearby = includeNearby,
        })
    end
    if Compatibility and Compatibility.refresh and (force or self.activeTab == "advanced" or self.activeTab == "compat") then
        Compatibility.refresh()
    end
    self:refreshList()
end

function FFC_MainWindow:passesSearch(record)
    local text = self.searchBox and self.searchBox:getText() or ""
    return Utils.containsText(record.search or record.name or "", text)
end

function FFC_MainWindow:refreshDashboardTab()
    local cache = Scanner.getCache()
    local csr = FadedFeastcraft.CSR.getStatus()
    local totals = SourcePacks and SourcePacks.getAssetTotals and SourcePacks.getAssetTotals() or {}
    local actionStats = Actions and Actions.getStats and Actions.getStats() or {}
    local recipeStats = Recipes and Recipes.getStats and Recipes.getStats() or {}
    local directStats = DirectRecipes and DirectRecipes.getStats and DirectRecipes.getStats() or {}
    local compat = Compatibility and Compatibility.getCache and Compatibility.getCache() or { summary = {} }
    self.detailLines = {
        "Choose a food task on the left.",
        "Cook: use a nearby stove, oven, microwave, grill, or campfire.",
        "Builder: combine safe unfrozen foods into one FFC field meal.",
        "Prep: use Batch Safe to open or unpack multiple visible safe items through one server-validated request.",
        "Cookbook: inspect requirements and start supported food crafts inside FFC.",
        "Pantry scanned: " .. tostring(cache.stats.total or 0) .. " foods, " .. tostring(cache.stats.flagged or 0) .. " blocked.",
        "Cookbook indexed: " .. tostring(recipeStats.total or 0) .. " recipes, " .. tostring(recipeStats.actionable or 0) .. " FFC handcraft actions.",
        "Direct GUI recipes: " .. tostring(directStats.total or 0) .. " safe server recipes.",
        "Preservation indexed: " .. tostring(recipeStats.preservation or 0) .. " recipes.",
        "Compatibility warnings: " .. tostring((compat.summary and compat.summary.warnings) or 0),
        "CSR helpers detected: " .. tostring(csr.detected == true),
        "Use Refresh after moving food between bags or containers.",
    }
    self.list:addItem("Cook nearby food", { kind = "quickAction", name = "Cook nearby food", targetTab = "station", detail = "Scan heat sources and cook from the GUI." })
    self.list:addItem("Build an FFC meal", { kind = "quickAction", name = "Build an FFC meal", targetTab = "meal", detail = "Pick safe ingredients, then create a field meal." })
    self.list:addItem("Browse cookbook", { kind = "quickAction", name = "Browse cookbook", targetTab = "recipes", detail = "Pick a recipe, see requirements, then craft from FFC when supported." })
    self.list:addItem("Scan pantry", { kind = "quickAction", name = "Scan pantry", targetTab = "ingredients", detail = "Review safe and blocked scanned food." })
    self.list:addItem("Track expiring food", { kind = "quickAction", name = "Track expiring food", targetTab = "expiry", detail = "Sort inventory and room food by expiry." })
    self.list:addItem("Review storage", { kind = "quickAction", name = "Review storage", targetTab = "storage", detail = "Summarize where scanned food is stored." })
    self.list:addItem("Nutrition summary", { kind = "quickAction", name = "Nutrition summary", targetTab = "nutrition", detail = "Review calories and macros from scanned food." })
    self.list:addItem("Preserve food", { kind = "quickAction", name = "Preserve food", targetTab = "preservation", detail = "Browse FFC canning, drying, salting, and jar recipes." })
    self.list:addItem("Check compatibility", { kind = "quickAction", name = "Check compatibility", targetTab = "compat", detail = "Review B42.18, MP, and duplicate source-pack diagnostics." })
end

function FFC_MainWindow:refreshRecipesTab()
    local filterId = self.recipeFilterId or "all"
    local viewFilterId = self.recipeViewFilterId or "craftable"
    local filterLabel = Recipes and Recipes.getFilterLabel and Recipes.getFilterLabel(filterId) or tostring(filterId)
    local viewFilterLabel = recipeViewFilterLabel(viewFilterId)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local pantryCache = Scanner.getCache()
    local directRecords, directStats = {}, {}
    if DirectRecipes and DirectRecipes.availableForRecords then
        directRecords, directStats = DirectRecipes.availableForRecords(pantryCache.records or {}, self.searchBox and self.searchBox:getText() or "", filterId)
    end
    local count = 0
    for _, directRecord in ipairs(directRecords or {}) do
        if directRecipeMatchesView(directRecord, viewFilterId) then
            self.list:addItem(directRecord.name, directRecord)
            count = count + 1
        end
    end
    for _, recipe in ipairs(Recipes.search(self.searchBox and self.searchBox:getText() or "", 160, filterId, viewFilterId, player)) do
        self.list:addItem(recipe.name, recipe)
        count = count + 1
        if count >= 180 then break end
    end
    self.detailLines = {
        "Cookbook",
        "Pick a recipe on the left.",
        "Rows marked direct craft through FFC server validation; supported handcraft rows launch as timed FFC actions.",
        "Current filter: " .. tostring(filterLabel) .. ". Press Filter to cycle recipe groups.",
        "View: " .. tostring(viewFilterLabel) .. ". Press Mode to show Known, Almost Ready, or All recipes.",
        "Visible recipes: " .. tostring(count),
        "Direct ready / blocked: " .. tostring((directStats and directStats.available) or 0) .. " / " .. tostring((directStats and directStats.blocked) or 0),
        "Recipe details show outputs, requirements, and missing items without opening the vanilla craft window.",
    }
end

function FFC_MainWindow:refreshPreservationTab()
    local searchText = self.searchBox and self.searchBox:getText() or ""
    local filterId = self.preservationFilterId or "all"
    local viewFilterId = self.preservationViewFilterId or "craftable"
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local pantryCache = Scanner.getCache()
    local directRecords = DirectRecipes and DirectRecipes.availableForRecords and DirectRecipes.availableForRecords(pantryCache.records or {}, searchText, "preservation") or {}
    local cache = Recipes.build(false)
    local visible = 0
    for _, directRecord in ipairs(directRecords or {}) do
        if preservationModeMatches(directRecord, filterId) and directRecipeMatchesView(directRecord, viewFilterId) then
            self.list:addItem(directRecord.name, directRecord)
            visible = visible + 1
        end
    end
    for _, recipe in ipairs(cache.recipes or {}) do
        if isPreservationRecipe(recipe)
            and preservationModeMatches(recipe, filterId)
            and self:passesSearch(recipe)
            and (not Recipes.matchesViewFilter or Recipes.matchesViewFilter(recipe, player, viewFilterId)) then
            self.list:addItem(recipe.name, recipe)
            visible = visible + 1
            if visible >= 160 then break end
        end
    end
    self.detailLines = {
        "FFC preservation desk",
        "Browse canning, drying, salting, pickling, and jar recipes without hunting through context menus.",
        "Current filter: " .. tostring(preservationFilterLabel(filterId)) .. ". Press Filter to cycle preservation modes.",
        "View: " .. tostring(recipeViewFilterLabel(viewFilterId)) .. ". Press Mode to show Known, Almost Ready, or All recipes.",
        "Visible preservation recipes: " .. tostring(visible),
        Utils.trim(searchText) == "" and "Use search to narrow this to cans, jars, dried meat, salted fish, or specific ingredients." or "Search filter: " .. tostring(searchText),
        "Press Craft Recipe on supported rows; FFC shows requirements and keeps vanilla craft menus closed.",
    }
end

function FFC_MainWindow:refreshPantryOrMealTab()
    local cache = Scanner.getCache()
    for _, record in ipairs(cache.records or {}) do
        if self:passesSearch(record) then
            self.list:addItem(record.name, record)
        end
    end
    if self.activeTab == "meal" then
        self:updateMealDetails()
    else
        self.detailLines = {
            "Pantry scanner",
            "Frozen, rotten, burned, and dangerous raw food is flagged before use.",
            "Safe items can be sent to Builder; food actions route through Prep when available.",
            "Scanned food items: " .. tostring((cache.stats and cache.stats.total) or 0),
            "Nearby containers: " .. tostring((cache.stats and cache.stats.includeNearby) == true and "included" or "not scanned"),
            "Blocked or unsafe items: " .. tostring((cache.stats and cache.stats.flagged) or 0),
        }
        for _, line in ipairs(storageSummaryLines(cache)) do self.detailLines[#self.detailLines + 1] = line end
        for _, line in ipairs(nutritionSummaryLines(cache)) do self.detailLines[#self.detailLines + 1] = line end
        self.detailLines[#self.detailLines + 1] = "CSR expiry/freshness helpers are used when CSR is loaded."
    end
end

function FFC_MainWindow:refreshExpiryTab()
    local cache = ExpiryTracker and ExpiryTracker.getCache and ExpiryTracker.getCache() or nil
    if not cache or not cache.stats then
        cache = ExpiryTracker and ExpiryTracker.scan and ExpiryTracker.scan(getSpecificPlayer(0), { includeRoom = false }) or { records = {}, stats = {} }
    end
    for _, record in ipairs(cache.records or {}) do
        if self:passesSearch(record) then
            local label = tostring(record.expiryLabel or record.expiryStatus or "") .. "  " .. tostring(record.name or "Food")
            self.list:addItem(label, record)
        end
    end
    self.detailLines = {
        "Food expiry tracker",
        "Scope: player inventory" .. tostring(cache.includeRoom and " plus current-room containers." or ". Press Scan Room to include current-room containers once."),
        "Foods tracked: " .. tostring((cache.stats and cache.stats.total) or 0),
        "Expires today: " .. tostring((cache.stats and cache.stats.today) or 0),
        "Expires soon: " .. tostring((cache.stats and cache.stats.soon) or 0),
        "Rotten: " .. tostring((cache.stats and cache.stats.rotten) or 0),
        "Room containers scanned: " .. tostring((cache.stats and cache.stats.roomContainers) or 0),
        "Room scan mode: " .. tostring(cache.includeRoom and "included in this view" or "not scanned"),
        "CSR expiry helpers are used when detected; otherwise FFC estimates from vanilla age/off-age values.",
    }
end

function FFC_MainWindow:refreshStorageTab()
    local cache = Scanner.getCache()
    local groups = {}
    local order = {}
    for _, record in ipairs(cache.records or {}) do
        if self:passesSearch(record) then
            local origin = tostring(record.origin or "Inventory")
            local container = tostring(record.containerType or "")
            if container == "" then container = "food container" end
            local key = origin .. " / " .. container
            if not groups[key] then
                groups[key] = { name = key, total = 0, safe = 0, blocked = 0, categories = {} }
                order[#order + 1] = key
            end
            local group = groups[key]
            group.total = group.total + 1
            if record.usable == false then group.blocked = group.blocked + 1 else group.safe = group.safe + 1 end
            group.categories[record.category or "Food"] = (group.categories[record.category or "Food"] or 0) + 1
        end
    end
    table.sort(order)
    for _, key in ipairs(order) do
        local group = groups[key]
        local categoryParts = {}
        for category, count in pairs(group.categories) do
            categoryParts[#categoryParts + 1] = tostring(category) .. "=" .. tostring(count)
        end
        table.sort(categoryParts)
        local detail = "Foods: " .. tostring(group.total) .. ", safe: " .. tostring(group.safe) .. ", blocked: " .. tostring(group.blocked) .. ". " .. table.concat(categoryParts, ", ")
        self.list:addItem(group.name, { kind = "summary", name = group.name, detail = detail, category = "Storage group" })
    end
    self.detailLines = {
        "Food storage overview",
        "This view uses the current manual scan cache; it does not poll containers every frame.",
        "Storage groups visible: " .. tostring(#order),
        "Scanned food items: " .. tostring((cache.stats and cache.stats.total) or 0),
        "Blocked or unsafe items: " .. tostring((cache.stats and cache.stats.flagged) or 0),
        "Use Refresh after moving food. Use Expiry > Scan Room when you specifically want current-room expiry included.",
    }
end

function FFC_MainWindow:refreshNutritionTab()
    local cache = Scanner.getCache()
    local totals = { count = 0, blocked = 0, hunger = 0, calories = 0, proteins = 0, lipids = 0, carbohydrates = 0 }
    local groups = {}
    local order = {}
    for _, record in ipairs(cache.records or {}) do
        if self:passesSearch(record) then
            local category = tostring(record.category or "Food")
            if not groups[category] then
                groups[category] = { name = category, count = 0, blocked = 0, hunger = 0, calories = 0, proteins = 0, lipids = 0, carbohydrates = 0 }
                order[#order + 1] = category
            end
            local group = groups[category]
            group.count = group.count + 1
            totals.count = totals.count + 1
            if record.usable == false then
                group.blocked = group.blocked + 1
                totals.blocked = totals.blocked + 1
            else
                local hunger = tonumber(record.hunger) or 0
                local calories = tonumber(record.calories) or 0
                local proteins = tonumber(record.proteins) or 0
                local lipids = tonumber(record.lipids) or 0
                local carbohydrates = tonumber(record.carbohydrates) or 0
                group.hunger = group.hunger + hunger
                group.calories = group.calories + calories
                group.proteins = group.proteins + proteins
                group.lipids = group.lipids + lipids
                group.carbohydrates = group.carbohydrates + carbohydrates
                totals.hunger = totals.hunger + hunger
                totals.calories = totals.calories + calories
                totals.proteins = totals.proteins + proteins
                totals.lipids = totals.lipids + lipids
                totals.carbohydrates = totals.carbohydrates + carbohydrates
            end
        end
    end
    table.sort(order)
    for _, category in ipairs(order) do
        local group = groups[category]
        local detail = "Items: " .. tostring(group.count)
            .. ", blocked: " .. tostring(group.blocked)
            .. ", calories: " .. tostring(Utils.round(group.calories, 0))
            .. ", P/F/C: " .. tostring(Utils.round(group.proteins, 1)) .. " / " .. tostring(Utils.round(group.lipids, 1)) .. " / " .. tostring(Utils.round(group.carbohydrates, 1))
        self.list:addItem(category, { kind = "summary", name = category, detail = detail, category = "Nutrition group" })
    end
    self.detailLines = {
        "Nutrition overview",
        "Totals count only food currently visible in the manual scan cache and skip blocked foods for macro totals.",
        "Visible food items: " .. tostring(totals.count),
        "Blocked or unsafe items: " .. tostring(totals.blocked),
        "Safe hunger reduction: " .. tostring(Utils.round(math.abs(totals.hunger * 100), 1)),
        "Safe calories: " .. tostring(Utils.round(totals.calories, 0)),
        "Protein/Fat/Carbs: " .. tostring(Utils.round(totals.proteins, 1)) .. " / " .. tostring(Utils.round(totals.lipids, 1)) .. " / " .. tostring(Utils.round(totals.carbohydrates, 1)),
        "Builder and Cook use these same safety rules before sending anything to the server.",
    }
end

function FFC_MainWindow:refreshOperationsTab()
    local cache = Scanner.getCache()
    local records, stats = Actions.availableForRecords(cache.records or {}, self.searchBox and self.searchBox:getText() or "")
    local focus = self.prepRecipeRecord
    local focusedRecords = {}
    local otherRecords = {}
    for _, opRecord in ipairs(records or {}) do
        if focus and recipePrepMatches(focus, opRecord) then
            focusedRecords[#focusedRecords + 1] = opRecord
        else
            otherRecords[#otherRecords + 1] = opRecord
        end
    end
    local displayRecords = focus and #focusedRecords > 0 and focusedRecords or records
    for _, opRecord in ipairs(displayRecords or {}) do
        self.list:addItem(opRecord.name, opRecord)
    end
    local byType = {}
    for actionType, n in pairs(stats.byType or {}) do
        byType[#byType + 1] = tostring(actionType) .. "=" .. tostring(n)
    end
    table.sort(byType)
    self.detailLines = {
        "Faded's Feastcraft operations console",
        "Supported visible food actions: " .. tostring(stats.total or 0),
        focus and ("Recipe prep focus: " .. scrubSourceText(focus.name or "selected recipe")) or "Recipe prep focus: none.",
        focus and ("Matching prep actions: " .. tostring(#focusedRecords) .. ". Select another recipe to change the focus.") or "Select a Cookbook or Preserve recipe first to focus Prep around that recipe.",
        "Visible after search: " .. tostring(#(displayRecords or {})),
        "Blocked by safety checks: " .. tostring(stats.blocked or 0),
        "Action types: " .. tostring(table.concat(byType, ", ")),
        "Open, unpack, preserve, and prep actions are normalized into FFC records before the server touches inventory.",
        "Recipe-aware Prep prioritizes actions whose inputs or outputs match the selected recipe requirements.",
        "Batch Safe runs the visible unblocked operations up to the sandbox limit: " .. tostring((Balance and Balance.maxBatchOperations and Balance.maxBatchOperations()) or 10) .. ".",
        "Frozen items stay blocked unless the exact action declares frozen food support.",
        "Final item changes are server-authoritative.",
    }
end

function FFC_MainWindow:refreshStationTab()
    local stationCache = CookingStation and CookingStation.getCache and CookingStation.getCache() or nil
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not stationCache or not stationCache.stats then
        stationCache = CookingStation and CookingStation.scan and CookingStation.scan(player, { modeId = self.cookModeId or "balanced" }) or { candidates = {}, stations = {}, tools = {}, stats = {} }
    end
    local searchText = self.searchBox and self.searchBox:getText() or ""
    local playableRecipes = Recipes and Recipes.search and Recipes.search(searchText, 60, "cooking", "craftable", player, {
        includeNearby = stationCache and stationCache.includeNearby == true,
    }) or {}
    local playableCount = 0
    for _, candidate in ipairs(stationCache.candidates or {}) do
        local show = candidate.kind == "stationRecipe" or Utils.trim(searchText) ~= ""
        if show and self:passesSearch(candidate) then
            self.list:addItem(candidate.name, candidate)
        end
    end
    for _, recipe in ipairs(playableRecipes or {}) do
        self.list:addItem(recipe.name, recipe)
        playableCount = playableCount + 1
    end
    local nearest = stationCache.stations and stationCache.stations[1] or nil
    self.detailLines = {
        "Cooking Station",
        "Nearby heat sources: " .. tostring((stationCache.stats and stationCache.stats.stations) or 0),
        "Nearest station: " .. tostring(nearest and nearest.name or "none"),
        "Nearby containers: " .. tostring((stationCache.stats and stationCache.stats.includeNearby) == true and "included" or "not scanned"),
        "Cooking vessels: " .. tostring((stationCache.stats and stationCache.stats.vessels) or 0),
        "Blades / can openers / utensils: " .. tostring((stationCache.stats and stationCache.stats.blades) or 0) .. " / " .. tostring((stationCache.stats and stationCache.stats.canOpeners) or 0) .. " / " .. tostring((stationCache.stats and stationCache.stats.utensils) or 0),
        "Safe unfrozen foods: " .. tostring((stationCache.stats and stationCache.stats.safeFoods) or 0),
        "Planner mode: " .. tostring((AutoPlanner and AutoPlanner.getMode and AutoPlanner.getMode(self.cookModeId).label) or "Balanced"),
        "Craftable cooking recipes visible: " .. tostring(playableCount),
        "Select FFC Hot Meal for a freeform cooked meal, or select a recipe row to craft a known cooking recipe.",
        "Scan Nearby pulls nearby container food and tools into this Cook tab on demand.",
        "If it is blocked, the selected row tells you exactly what is missing.",
        "Recipe-index rows are hidden unless they are craftable now or you search for adapter targets.",
    }
end

function FFC_MainWindow:refreshAdvancedTab()
    local cache = Scanner.getCache()
    local recipeStats = Recipes and Recipes.getStats and Recipes.getStats() or {}
    local directStats = DirectRecipes and DirectRecipes.getStats and DirectRecipes.getStats() or {}
    local actionStats = Actions and Actions.getStats and Actions.getStats() or {}
    local sourceTotals = SourcePacks and SourcePacks.getAssetTotals and SourcePacks.getAssetTotals() or {}
    local compat = Compatibility and Compatibility.getCache and Compatibility.getCache() or { summary = {}, warnings = {} }
    local csr = FadedFeastcraft.CSR.getStatus()
    local function addAdvanced(name, detail, lines)
        local record = {
            kind = "advanced",
            name = name,
            detail = detail,
            lines = lines,
            search = Utils.lower(tostring(name) .. " " .. tostring(detail) .. " " .. table.concat(lines or {}, " ")),
        }
        if self:passesSearch(record) then self.list:addItem(name, record) end
    end

    local pantryLines = {
        "Pantry maintenance summary",
        "Scanned food items: " .. tostring((cache.stats and cache.stats.total) or 0),
        "Blocked or unsafe items: " .. tostring((cache.stats and cache.stats.flagged) or 0),
    }
    for _, line in ipairs(storageSummaryLines(cache)) do pantryLines[#pantryLines + 1] = line end
    for _, line in ipairs(nutritionSummaryLines(cache)) do pantryLines[#pantryLines + 1] = line end
    addAdvanced("Pantry summaries", "Storage and nutrition totals from the current scan.", pantryLines)

    addAdvanced("Recipe indexes", "Cookbook, preservation, and direct recipe counts.", {
        "Recipe indexes",
        "Cookbook indexed: " .. tostring(recipeStats.total or 0),
        "FFC handcraft actions: " .. tostring(recipeStats.actionable or 0),
        "Legacy inspect-only recipes: " .. tostring(recipeStats.legacy or 0),
        "Direct GUI recipes: " .. tostring(directStats.total or 0),
        "Preservation recipes: " .. tostring(recipeStats.preservation or 0),
    })

    addAdvanced("Food libraries", "Integrated library and adapter diagnostics.", {
        "Food libraries",
        "Integrated FFC shelves: " .. tostring(SourcePacks and SourcePacks.countEmbedded and SourcePacks.countEmbedded() or 0),
        "Script groups: " .. tostring(sourceTotals.scripts or 0),
        "Texture groups: " .. tostring(sourceTotals.textures or 0),
        "Model groups: " .. tostring(sourceTotals.models or 0),
        "Action adapters: " .. tostring(actionStats.adapters or 0),
        "Indexed static GUI actions: " .. tostring(actionStats.indexed or 0),
    })

    addAdvanced("Compatibility", "Runtime, version, duplicate source-pack, and warning count.", {
        "Compatibility",
        "Runtime: " .. tostring((compat.summary and compat.summary.mode) or "unknown"),
        "Version: " .. tostring((compat.summary and compat.summary.version) or "unknown"),
        "Target: " .. tostring((compat.summary and compat.summary.target) or "42.18"),
        "Warnings: " .. tostring((compat.summary and compat.summary.warnings) or 0),
        "Duplicate embedded source packs: " .. tostring((compat.summary and compat.summary.duplicateSourcePacks) or 0),
    })

    addAdvanced("CSR integration", "Optional CSR helper status.", {
        "CSR integration",
        "CSR detected: " .. tostring(csr.detected == true),
        "CSR integration enabled: " .. tostring(csr.enabled == true),
        "CSR version: " .. tostring(csr.version or "unknown"),
        "CSR utility table: " .. tostring(csr.hasUtils == true),
        "CSR-aware GUI action adapters: " .. tostring(actionStats.csrAware or 0),
    })

    self.detailLines = {
        "Advanced",
        "Maintenance and diagnostic information lives here so the main workflow stays focused.",
        "Use Pantry for storage/nutrition summaries during normal play.",
        "Search narrows these diagnostic cards.",
    }
end

function FFC_MainWindow:refreshSourcesTab()
    local totals = SourcePacks and SourcePacks.getAssetTotals and SourcePacks.getAssetTotals() or {}
    local actionStats = Actions and Actions.getStats and Actions.getStats() or {}
    self.detailLines = {
        "FFC food library",
        "Integrated FFC shelves: " .. tostring(SourcePacks and SourcePacks.countEmbedded and SourcePacks.countEmbedded() or 0),
        "Script groups: " .. tostring(totals.scripts or 0),
        "Texture groups: " .. tostring(totals.textures or 0),
        "Model groups: " .. tostring(totals.models or 0),
        "Action adapters: " .. tostring(actionStats.adapters or 0),
        "Indexed static GUI actions: " .. tostring(actionStats.indexed or 0),
        "Loot and prep callbacks are routed through FFC-owned GUI actions.",
    }
    if Actions and Actions.getAdapters then
        for index, adapter in ipairs(Actions.getAdapters()) do
            local search = tostring(adapter.label or "") .. " " .. tostring(adapter.id or "") .. " " .. tostring(adapter.coverage or "")
            if self:passesSearch({ search = search }) then
                local label = "Food action adapter " .. tostring(index) .. " [" .. tostring(adapter.status or "unknown") .. "]"
                self.list:addItem(label, { kind = "adapter", name = label, adapter = adapter, adapterIndex = index, search = search })
            end
        end
    end
    if SourcePacks and SourcePacks.getPacks then
        for index, pack in ipairs(SourcePacks.getPacks()) do
            if self:passesSearch({ search = tostring(pack.label or "") .. " " .. tostring(pack.id or "") .. " " .. tostring(pack.workshopId or "") }) then
                local mode = pack.embedded and "integrated" or "compatibility"
                local label = "Food library " .. tostring(index) .. " [" .. mode .. "]"
                self.list:addItem(label, { kind = "sourcePack", name = label, pack = pack, packIndex = index, search = tostring(pack.label or "") })
            end
        end
    end
end

function FFC_MainWindow:refreshCompatTab()
    local compat = Compatibility and Compatibility.getCache and Compatibility.getCache() or { rows = {}, warnings = {}, summary = {} }
    for _, row in ipairs(compat.rows or {}) do
        if self:passesSearch(row) then
            self.list:addItem(row.name, row)
        end
    end
    self.detailLines = {
        "B42.18 compatibility desk",
        "Runtime: " .. tostring((compat.summary and compat.summary.mode) or "unknown"),
        "Version: " .. tostring((compat.summary and compat.summary.version) or "unknown"),
        "Target: " .. tostring((compat.summary and compat.summary.target) or "42.18"),
        "Warnings: " .. tostring((compat.summary and compat.summary.warnings) or 0),
        "Duplicate embedded source packs: " .. tostring((compat.summary and compat.summary.duplicateSourcePacks) or 0),
        "FFC keeps gameplay changes server-authoritative and keeps external food-library mods as compatibility risks unless they are reference-only.",
    }
    for i, warning in ipairs(compat.warnings or {}) do
        if i <= 5 then self.detailLines[#self.detailLines + 1] = "Warning: " .. tostring(warning) end
    end
end

function FFC_MainWindow:refreshCsrTab()
    local csr = FadedFeastcraft.CSR.getStatus()
    local actionStats = Actions and Actions.getStats and Actions.getStats() or {}
    self.detailLines = {
        "CSR detected: " .. tostring(csr.detected == true),
        "CSR integration enabled: " .. tostring(csr.enabled == true),
        "CSR version: " .. tostring(csr.version or "unknown"),
        "CSR utility table: " .. tostring(csr.hasUtils == true),
        "CSR feature flags: " .. tostring(csr.hasFeatureFlags == true),
        "CSR-aware GUI action adapters: " .. tostring(actionStats.csrAware or 0),
        "FFC integrated libraries: " .. tostring(SourcePacks and SourcePacks.countEmbedded and SourcePacks.countEmbedded() or 0),
    }
    for _, system in ipairs(csr.systems or {}) do
        local value = system.value
        local label = value == nil and "unknown" or tostring(value)
        self.list:addItem(system.key .. ": " .. label, { kind = "csr", name = system.key, detail = label })
    end
end

function FFC_MainWindow:refreshHelpTab()
    self.detailLines = {
        "FFC Guide",
        "Pick a topic on the left for a short explanation.",
        "Use this tab when the window feels busy or you are not sure which tab should handle the food in front of you.",
        "Most sessions only need Refresh, Pantry, Cook, Builder, Preserve, and Expiry.",
    }
    for _, section in ipairs(GUIDE_SECTIONS) do
        local search = Utils.lower(tostring(section.name or "") .. " " .. tostring(section.detail or "") .. " " .. table.concat(section.lines or {}, " "))
        local record = {
            kind = "guide",
            name = section.name,
            detail = section.detail,
            lines = section.lines,
            category = "Guide",
            search = search,
        }
        if self:passesSearch(record) then
            self.list:addItem(section.name, record)
        end
    end
end

function FFC_MainWindow:refreshList()
    if not self.list then return end
    self.list:clear()
    if self.list.setScrollHeight then self.list:setScrollHeight(0) end
    if self.list.setYScroll then self.list:setYScroll(0) end
    self.list.smoothScrollY = nil
    self.list.smoothScrollTargetY = nil
    self.detailLines = {}

    if self.activeTab == "dashboard" then
        self:refreshDashboardTab()
    elseif self.activeTab == "recipes" then
        self:refreshRecipesTab()
    elseif self.activeTab == "preservation" then
        self:refreshPreservationTab()
    elseif self.activeTab == "ingredients" or self.activeTab == "meal" then
        self:refreshPantryOrMealTab()
    elseif self.activeTab == "expiry" then
        self:refreshExpiryTab()
    elseif self.activeTab == "storage" then
        self:refreshStorageTab()
    elseif self.activeTab == "nutrition" then
        self:refreshNutritionTab()
    elseif self.activeTab == "operations" then
        self:refreshOperationsTab()
    elseif self.activeTab == "station" then
        self:refreshStationTab()
    elseif self.activeTab == "advanced" then
        self:refreshAdvancedTab()
    elseif self.activeTab == "sources" then
        self:refreshSourcesTab()
    elseif self.activeTab == "compat" then
        self:refreshCompatTab()
    elseif self.activeTab == "csr" then
        self:refreshCsrTab()
    elseif self.activeTab == "help" then
        self:refreshHelpTab()
    end

    if self.activeTab == "operations" then
        setButtonTitle(self.craftButton, "Run Operation")
    elseif self.activeTab == "station" then
        setButtonTitle(self.craftButton, "Start Cooking")
    elseif self.activeTab == "recipes" or self.activeTab == "preservation" then
        setButtonTitle(self.craftButton, "Inspect Recipe")
    elseif self.activeTab == "ingredients" then
        setButtonTitle(self.craftButton, "Use Item")
    else
        setButtonTitle(self.craftButton, "Create Meal")
    end
    self.craftButton:setVisible(self.activeTab == "meal" or self.activeTab == "ingredients" or self.activeTab == "operations" or self.activeTab == "station" or self.activeTab == "recipes" or self.activeTab == "preservation")
    if self.secondaryButton then
        self.secondaryButton:setVisible(self.activeTab == "meal" or self.activeTab == "operations" or self.activeTab == "station" or self.activeTab == "expiry" or self.activeTab == "recipes" or self.activeTab == "preservation")
        if self.activeTab == "station" then
            setButtonTitle(self.secondaryButton, "Scan Nearby")
        elseif self.activeTab == "operations" then
            setButtonTitle(self.secondaryButton, "Batch Safe")
        elseif self.activeTab == "expiry" then
            setButtonTitle(self.secondaryButton, "Scan Room")
        elseif self.activeTab == "recipes" then
            local label = Recipes and Recipes.getFilterLabel and Recipes.getFilterLabel(self.recipeFilterId or "all") or "All"
            setButtonTitle(self.secondaryButton, "Filter: " .. tostring(label))
        elseif self.activeTab == "preservation" then
            setButtonTitle(self.secondaryButton, "Filter: " .. tostring(preservationFilterLabel(self.preservationFilterId or "all")))
        else
            setButtonTitle(self.secondaryButton, "Suggest Meal")
        end
    end
    if self.modeButton then
        if self.activeTab == "recipes" then
            setButtonTitle(self.modeButton, "View: " .. tostring(recipeViewFilterLabel(self.recipeViewFilterId or "craftable")))
        elseif self.activeTab == "preservation" then
            setButtonTitle(self.modeButton, "View: " .. tostring(recipeViewFilterLabel(self.preservationViewFilterId or "craftable")))
        else
            local mode = AutoPlanner and AutoPlanner.getMode and AutoPlanner.getMode(self.cookModeId or "balanced") or { label = "Balanced" }
            setButtonTitle(self.modeButton, "Mode: " .. tostring(mode.label))
        end
        self.modeButton:setVisible(self.activeTab == "meal" or self.activeTab == "station" or self.activeTab == "recipes" or self.activeTab == "preservation")
    end
end

function FFC_MainWindow:updateMealDetails()
    local selected = {}
    local selectedIds = self.selectedIngredientIds or {}
    local cache = Scanner.getCache()
    for _, record in ipairs(cache.records or {}) do
        if record.id and selectedIds[tostring(record.id)] then
            selected[#selected + 1] = record
        end
    end
    local estimate = Planner.estimate(selected)
    self.mealEstimate = estimate
    self.detailLines = Planner.formatEstimate(estimate)
end

function FFC_MainWindow:onSuggestMeal()
    if self.activeTab ~= "meal" or not AutoPlanner then return end
    local cache = Scanner.getCache()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local plan = AutoPlanner.buildPlan(cache.records or {}, player, {
        modeId = self.cookModeId or "balanced",
        maxItems = math.min(6, (Balance and Balance.maxMealIngredients and Balance.maxMealIngredients()) or FadedFeastcraft.Config.MAX_MEAL_INGREDIENTS or 8),
        maxDuplicate = 2,
        maxSpices = 2,
        smartSpices = true,
    })

    self.selectedIngredientIds = {}
    for _, id in ipairs(plan.itemIds or {}) do
        self.selectedIngredientIds[tostring(id)] = true
    end
    self.detailRecord = plan.records and plan.records[1] or nil
    self:updateMealDetails()

    local lines = AutoPlanner.formatPlan(plan)
    local estimateLines = Planner.formatEstimate(self.mealEstimate)
    lines[#lines + 1] = ""
    for _, line in ipairs(estimateLines or {}) do
        lines[#lines + 1] = line
    end
    self.detailLines = lines
end

function FFC_MainWindow:onBatchOperations()
    if self.activeTab ~= "operations" then return end
    local cache = Scanner.getCache()
    local records = Actions and Actions.availableForRecords and Actions.availableForRecords(cache.records or {}, self.searchBox and self.searchBox:getText() or "") or {}
    local focus = self.prepRecipeRecord
    local limit = Balance and Balance.maxBatchOperations and Balance.maxBatchOperations() or 10
    local itemIds = {}
    local preview = {}
    for _, opRecord in ipairs(records or {}) do
        if (not focus or recipePrepMatches(focus, opRecord)) and not opRecord.blocked and opRecord.ingredient and opRecord.ingredient.id then
            itemIds[#itemIds + 1] = opRecord.ingredient.id
            preview[#preview + 1] = tostring(opRecord.name or opRecord.ingredient.name or opRecord.ingredient.fullType)
            if #itemIds >= limit then break end
        end
    end

    self.detailLines = {
        "Batch Safe prep",
        focus and ("Recipe focus: " .. scrubSourceText(focus.name or "selected recipe")) or "Recipe focus: none",
        "Visible safe operations selected: " .. tostring(#itemIds),
        "Sandbox batch limit: " .. tostring(limit),
    }
    for i, name in ipairs(preview) do
        if i <= 8 then self.detailLines[#self.detailLines + 1] = tostring(i) .. ". " .. name end
    end
    if #itemIds == 0 then
        self.detailLines[#self.detailLines + 1] = "Server request not sent: no visible unblocked prep operations."
        return
    end
    if Net.requestBatchOperations and Net.requestBatchOperations(getSpecificPlayer(0), itemIds) then
        self.detailLines[#self.detailLines + 1] = "Waiting for server validation..."
    else
        self.detailLines[#self.detailLines + 1] = "Server request not sent: FFC command channel is unavailable."
    end
end

function FFC_MainWindow:onScanCookingNearby()
    if self.activeTab ~= "station" then return end
    self.selectedStationCandidate = nil
    self.detailRecord = nil
    self:refreshData(false, { includeNearby = true })
    self.detailLines = self.detailLines or {}
    self.detailLines[#self.detailLines + 1] = "Nearby container food and tools are included for this cooking scan."
end

function FFC_MainWindow:onAutoFillStation()
    if self.activeTab ~= "station" then return end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local existingCache = CookingStation and CookingStation.getCache and CookingStation.getCache() or nil
    local stationCache = CookingStation and CookingStation.scan and CookingStation.scan(player, {
        modeId = self.cookModeId or "balanced",
        includeNearby = existingCache and existingCache.includeNearby == true,
    }) or nil
    self:refreshList()

    local selected = nil
    for _, candidate in ipairs((stationCache and stationCache.candidates) or {}) do
        if candidate.recipeId == "ffc_hot_meal" then
            selected = candidate
            break
        end
    end
    self.selectedStationCandidate = selected
    if selected then
        self.detailRecord = selected
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = selected.blocked and "Planner refresh found the blocker above." or "Planner refresh is ready. Press Start Cooking."
    else
        self.detailRecord = nil
        self.detailLines = { "Cooking Station", "Planner refresh found no FFC station recipe." }
    end
end

function FFC_MainWindow:onScanExpiryRoom()
    if self.activeTab ~= "expiry" then return end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local cache = ExpiryTracker and ExpiryTracker.scan and ExpiryTracker.scan(player, { includeRoom = true }) or nil
    self:refreshList()
    self.detailLines = {
        "Food expiry tracker",
        "Manual room scan complete.",
        "Foods tracked: " .. tostring((cache and cache.stats and cache.stats.total) or 0),
        "Room containers scanned: " .. tostring((cache and cache.stats and cache.stats.roomContainers) or 0),
        "Room food items visited: " .. tostring((cache and cache.stats and cache.stats.roomItemsVisited) or 0),
        "Press Refresh for inventory-only expiry again, or Scan Room when you want room containers included.",
    }
end

function FFC_MainWindow:drawListItem(y, item, alt)
    local record = item.item
    local selected = self.selected == item.index
    local rowW = math.max(40, self:getWidth() - LIST_SCROLLBAR_RESERVE)
    if selected then
        self:drawRect(0, y, rowW, item.height - 1, 0.22, 0.18, 0.82, 1.0)
    elseif alt then
        self:drawRect(0, y, rowW, item.height - 1, 0.12, 0.08, 0.12, 0.14)
    end
    self:drawRectBorder(0, y, rowW, item.height, 0.35, 0.1, 0.55, 0.72)

    local c = itemColor(record or {})
    local texture = textureForRecord(record, self.target and self.target.cookingIcon or nil)
    local textX = texture and 48 or 8
    if texture and self.drawTextureScaled then
        self:drawTextureScaled(texture, 8, y + 7, 32, 32, record and record.blocked and 0.45 or 0.95, 1, 1, 1)
        self:drawRectBorder(7, y + 6, 34, 34, 0.42, 0.1, 0.65, 0.82)
    end
    local prefix = ""
    if self.target and self.target.activeTab == "meal" and record and record.id then
        prefix = (self.target.selectedIngredientIds and self.target.selectedIngredientIds[tostring(record.id)]) and "[x] " or "[ ] "
    elseif record and record.kind == "operation" then
        prefix = record.blocked and "[!] " or "[>] "
    elseif record and (record.kind == "stationRecipe" or record.kind == "stationRecipeHint") then
        prefix = record.blocked and "[!] " or "[>] "
    elseif record and record.kind == "directRecipeAction" then
        prefix = record.blocked and "[!] " or "[>] "
    elseif record and record.kind == "guide" then
        prefix = "[?] "
    end
    local title = fitText(UIFont.Small, prefix .. displayTitle(record, item.text), rowW - textX - 8)
    self:drawText(title, textX, y + 5, c.r, c.g, c.b, 1, UIFont.Small)

    local sub = ""
    if record then
        if record.kind == "operation" then
            sub = tostring(record.category or "food-operation") .. "  ->  " .. scrubSourceText(Operations.outputPreview and Operations.outputPreview(record.operation) or "")
        elseif record.kind == "expiry" then
            sub = tostring(record.expiryStatus or "Unknown") .. "  " .. tostring(record.origin or "") .. "  " .. tostring(record.category or "")
        elseif record.kind == "stationRecipe" or record.kind == "stationRecipeHint" then
            sub = tostring(record.category or "") .. "  " .. tostring(record.effectName or record.stationName or record.blockedReason or "")
        elseif record.kind == "directRecipeAction" then
            sub = tostring(record.familyLabel or "Direct") .. "  FFC direct recipe  " .. scrubSourceText(DirectRecipes and DirectRecipes.outputPreview and DirectRecipes.outputPreview(record) or "")
        elseif record.kind == "compat" then
            sub = tostring(record.status or "") .. "  " .. tostring(record.detail or "")
        elseif record.kind == "craftRecipe" or record.kind == "recipe" then
            sub = tostring(record.familyLabel or "Pantry") .. "  " .. recipeKindLabel(record) .. "  " .. recipeResultName(record)
        elseif record.kind == "quickAction" then
            sub = tostring(record.detail or "")
        elseif record.kind == "guide" then
            sub = tostring(record.detail or "")
        else
            sub = tostring(record.category or record.detail or "")
        end
        if record.freshness then sub = sub .. "  " .. tostring(record.freshness) end
        if record.effectName then sub = sub .. "  " .. tostring(record.effectName) end
    end
    self:drawText(fitText(UIFont.Small, sub, rowW - textX - 8), textX, y + 26, 0.55, 0.72, 0.78, 1, UIFont.Small)
    return y + item.height
end

local function listScrollbarHit(list, x)
    return list and list.vscroll and list.isVScrollBarVisible and list:isVScrollBarVisible() and x >= list.vscroll.x
end

function FFC_MainWindow:onListMouseMove(dx, dy)
    if self.vscroll and self.vscroll.scrolling then
        return self.vscroll:onMouseMove(dx, dy)
    end
    return ISScrollingListBox.onMouseMove(self, dx, dy)
end

function FFC_MainWindow:onListMouseUp(x, y)
    if self.vscroll and (self.vscroll.scrolling or self.vscroll.getIsCaptured and self.vscroll:getIsCaptured()) then
        return self.vscroll:onMouseUp(x - self.vscroll.x, y + self:getYScroll() - self.vscroll.y)
    end
    return ISScrollingListBox.onMouseUp(self, x, y)
end

function FFC_MainWindow:onListMouseUpOutside(x, y)
    if self.vscroll then
        self.vscroll:onMouseUpOutside(x - self.vscroll.x, y + self:getYScroll() - self.vscroll.y)
    end
    return ISScrollingListBox.onMouseUpOutside(self, x, y)
end

function FFC_MainWindow:onListMouseDown(x, y)
    if listScrollbarHit(self, x) then
        self.smoothScrollTargetY = nil
        self.smoothScrollY = nil
        return self.vscroll:onMouseDown(x - self.vscroll.x, y + self:getYScroll() - self.vscroll.y)
    end
    ISScrollingListBox.onMouseDown(self, x, y)
    local parent = self.target
    if not parent then return end
    local row = self:rowAt(x, y)
    if row == -1 then return end
    local item = self.items[row]
    local record = item and item.item
    if not record then return end

    if record.kind == "quickAction" and record.targetTab then
        parent.detailRecord = nil
        parent:setActiveTab(record.targetTab)
        return
    end

    parent.detailRecord = record

    if parent.activeTab == "ingredients" and record.id then
        parent.selectedPantryRecord = record
        parent.detailLines = parent:detailForRecord(record)
        local action = Actions and Actions.actionForFullType and Actions.actionForFullType(record.fullType) or nil
        if action and action.operation then
            parent.detailLines[#parent.detailLines + 1] = "Press Use Item to route this through the Prep tab."
        elseif record.usable == false or record.frozen or record.rotten or record.burnt then
            parent.detailLines[#parent.detailLines + 1] = "This item is blocked for Builder until the warning is resolved."
        else
            parent.detailLines[#parent.detailLines + 1] = "Press Use Item to add this to Builder."
        end
    elseif parent.activeTab == "meal" and record.id then
        if record.usable == false or record.frozen or record.rotten or record.burnt or record.fullType == FadedFeastcraft.Config.RESULT_FIELD_MEAL then
            parent.detailLines = parent:detailForRecord(record)
            parent.detailLines[#parent.detailLines + 1] = "This ingredient is blocked for meal building."
            return
        end
        local key = tostring(record.id)
        if parent.selectedIngredientIds[key] then
            parent.selectedIngredientIds[key] = nil
        else
            parent.selectedIngredientIds[key] = true
        end
        parent:updateMealDetails()
    elseif parent.activeTab == "operations" and record.kind == "operation" then
        parent.selectedOperationRecord = record
        parent.detailLines = parent:detailForRecord(record)
    elseif parent.activeTab == "station" and (record.kind == "stationRecipe" or record.kind == "stationRecipeHint") then
        parent.selectedStationCandidate = record
        parent.selectedRecipeRecord = nil
        parent.detailLines = parent:detailForRecord(record)
        setButtonTitle(parent.craftButton, "Start Cooking")
    elseif parent.activeTab == "station" and record.kind == "craftRecipe" then
        parent.selectedRecipeRecord = record
        parent.selectedStationCandidate = nil
        parent.prepRecipeRecord = record
        parent.detailLines = parent:detailForRecord(record)
        parent.detailLines[#parent.detailLines + 1] = "Prep tab will focus available prep actions for this recipe."
        setButtonTitle(parent.craftButton, "Craft Recipe")
    elseif (parent.activeTab == "recipes" or parent.activeTab == "preservation") and (record.kind == "craftRecipe" or record.kind == "recipe" or record.kind == "directRecipeAction") then
        parent.selectedRecipeRecord = record
        if record.kind == "craftRecipe" or record.kind == "recipe" then
            parent.prepRecipeRecord = record
        end
        parent.detailLines = parent:detailForRecord(record)
        if record.kind == "craftRecipe" or record.kind == "recipe" then
            parent.detailLines[#parent.detailLines + 1] = "Prep tab will focus available prep actions for this recipe."
        end
        if record.kind == "directRecipeAction" or record.kind == "craftRecipe" then
            setButtonTitle(parent.craftButton, "Craft Recipe")
        else
            setButtonTitle(parent.craftButton, "Inspect Recipe")
        end
    elseif record.kind == "advanced" then
        parent.detailLines = {}
        for _, line in ipairs(record.lines or {}) do
            parent.detailLines[#parent.detailLines + 1] = tostring(line)
        end
    elseif record.kind == "summary" or record.kind == "csr" then
        parent.detailLines = { tostring(record.name), tostring(record.detail or "") }
    elseif record.kind == "compat" then
        parent.detailLines = parent:detailForRecord(record)
    else
        parent.detailLines = parent:detailForRecord(record)
    end
end

function FFC_MainWindow:detailForRecord(record)
    if not record then return {} end
    if record.kind == "craftResult" then
        local result = record.result or {}
        local lines = {
            "Meal complete",
            tostring(record.message or "The server created the meal."),
            "Dish: " .. tostring(result.name or record.name or "FFC meal"),
            "Item class: " .. foodName(result.fullType or record.fullType or ""),
            "Station: " .. tostring(record.stationName or "Heat Source"),
            "Ingredients used: " .. tostring(record.ingredientCount or 0),
        }
        if result.hunger then
            lines[#lines + 1] = "Hunger: " .. tostring(Utils.round(math.abs((tonumber(result.hunger) or 0) * 100), 1))
        end
        if result.calories then
            lines[#lines + 1] = "Calories: " .. tostring(Utils.round(result.calories or 0, 0))
            lines[#lines + 1] = "Protein/Fat/Carbs: "
                .. tostring(Utils.round(result.proteins or 0, 1)) .. " / "
                .. tostring(Utils.round(result.lipids or 0, 1)) .. " / "
                .. tostring(Utils.round(result.carbohydrates or 0, 1))
        end
        if type(result.balance) == "table" and Balance and Balance.describeMealTuning then
            for _, line in ipairs(Balance.describeMealTuning(result.balance)) do lines[#lines + 1] = line end
        end
        if type(result.effect) == "table" then
            lines[#lines + 1] = "Meal effect: " .. tostring(result.effect.name or result.effect.tag or "stamped")
            if result.effect.desc then lines[#lines + 1] = tostring(result.effect.desc) end
            if result.effect.cookName then
                lines[#lines + 1] = "Cooked by: " .. tostring(result.effect.cookName) .. " (Cooking " .. tostring(result.effect.cookLevel or 0) .. ")"
            end
        end
        if type(result.preservation) == "table" and Preservation and Preservation.describe then
            for _, line in ipairs(Preservation.describe(result.preservation)) do lines[#lines + 1] = line end
        end
        lines[#lines + 1] = "Press Refresh or choose another tab to keep cooking."
        return lines
    end
    if record.kind == "guide" then
        local lines = {
            tostring(record.name or "Guide"),
            tostring(record.detail or ""),
        }
        for _, line in ipairs(record.lines or {}) do
            lines[#lines + 1] = tostring(line)
        end
        return lines
    end
    if record.kind == "directRecipeAction" then
        local lines = {
            scrubSourceText(record.name or "FFC direct recipe"),
            "Type: FFC direct recipe",
            "Category: " .. tostring(record.familyLabel or "Direct"),
            "Output: " .. scrubSourceText(DirectRecipes and DirectRecipes.outputPreview and DirectRecipes.outputPreview(record) or "unknown"),
            "Server action: consumes the first accessible matching ingredients after validation.",
        }
        local reqParts = {}
        for _, requirement in ipairs(record.requirements or {}) do
            reqParts[#reqParts + 1] = tostring(requirement.count or 1) .. "x " .. table.concat(requirement.fullTypes or {}, " or ")
        end
        if #reqParts > 0 then lines[#lines + 1] = "Needs: " .. table.concat(reqParts, "; ") end
        local tools = {}
        for _, tool in ipairs(record.toolGroups or {}) do tools[#tools + 1] = tostring(tool.label or tool.group) end
        if #tools > 0 then lines[#lines + 1] = "Tool: " .. table.concat(tools, ", ") end
        if record.blockedReason then lines[#lines + 1] = "Warning: " .. tostring(record.blockedReason) end
        lines[#lines + 1] = record.blocked and "Resolve the warning before crafting." or "Press Craft Recipe to send this to the server."
        return lines
    end
    if record.kind == "craftRecipe" or record.kind == "recipe" then
        if Recipes and Recipes.describeRecipe then
            local stationCache = CookingStation and CookingStation.getCache and CookingStation.getCache() or nil
            local options = self.activeTab == "station" and stationCache and stationCache.includeNearby == true and { includeNearby = true } or nil
            return Recipes.describeRecipe(record, getSpecificPlayer and getSpecificPlayer(0) or nil, options)
        end
        local lines = {
            scrubSourceText(record.name or "Recipe"),
            "Type: " .. recipeKindLabel(record),
            "Category: " .. tostring(record.familyLabel or "Pantry"),
            "Result: " .. recipeResultName(record),
            "Result data: " .. tostring(record.tags and record.tags ~= "" and "available" or "auto-detected"),
            record.kind == "craftRecipe" and "Action: crafts from FFC when requirements are met." or "Action: inspect-only until a safe adapter is added.",
        }
        if record.kind ~= "craftRecipe" then
            lines[#lines + 1] = "Legacy recipes are view-only here until a safe adapter is added."
        else
            lines[#lines + 1] = "Press Craft Recipe to start the timed craft from FFC."
        end
        return lines
    end
    if record.kind == "sourcePack" and record.pack then
        local pack = record.pack
        return {
            tostring(record.name or "Food library"),
            "FFC index: " .. tostring(record.packIndex or "unknown"),
            "Status: " .. tostring(pack.embedded and "integrated" or "compatibility hook"),
            "Content: " .. tostring(pack.scripts or 0) .. " scripts, " .. tostring(pack.textures or 0) .. " textures, " .. tostring(pack.models or 0) .. " models",
            "Notes: Visible labels and GUI flow stay under FFC.",
        }
    end
    if record.kind == "adapter" and record.adapter then
        local adapter = record.adapter
        return {
            tostring(record.name or "Food action adapter"),
            "Adapter index: " .. tostring(record.adapterIndex or "unknown"),
            "Mode: " .. tostring(adapter.mode or "unknown"),
            "Status: " .. tostring(adapter.status or "unknown"),
            "Coverage: FFC-integrated food actions",
            "CSR aware: " .. tostring(adapter.csrAware == true),
        }
    end
    if record.kind == "compat" then
        return {
            tostring(record.name or "Compatibility check"),
            "Status: " .. tostring(record.status or "unknown"),
            "Severity: " .. tostring(record.severity or "info"),
            "Detail: " .. tostring(record.detail or ""),
        }
    end
    if record.kind == "operation" and record.operation then
        local operation = record.operation
        local action = record.action
        local ingredient = record.ingredient or {}
        local lines = {
            tostring((action and action.label) or operation.label or "FFC operation"),
            "Action type: " .. tostring(action and action.actionType or "food-operation"),
            "Input: " .. tostring(ingredient.name or record.fullType or operation.input),
            "Item class: " .. foodName(record.fullType or operation.input or ""),
            "Output: " .. scrubSourceText(action and action.outputPreview or Operations.outputPreview and Operations.outputPreview(operation) or "unknown"),
            "Tool: " .. tostring((action and action.requiresTool) or operation.toolLabel or "none"),
            "Frozen allowed: " .. tostring(not operation.rejectFrozen),
            "Consumes: " .. tostring(operation.consumeUse and "one package use" or "selected item"),
            "Runs through Faded's Feastcraft with server validation.",
        }
        local reason = Operations.previewBlockReason and Operations.previewBlockReason(operation, ingredient) or nil
        if reason then
            lines[#lines + 1] = "Warning: " .. tostring(reason)
        end
        return lines
    end
    if record.kind == "expiry" then
        local exp = record.expiry or {}
        local lines = {
            tostring(record.name or "Food"),
            "Expiry status: " .. tostring(record.expiryStatus or "Unknown"),
            "Time at room temp: " .. tostring(record.expiryLabel or "unknown"),
            "Fridge estimate: " .. tostring(exp.fridgeDays and (Utils.round(exp.fridgeDays, 1) .. "d") or "unknown"),
            "Location: " .. tostring(record.origin or "Inventory"),
            "Container: " .. tostring(record.roomContainerType or record.containerType or "unknown"),
            "Category: " .. tostring(record.category or "Food"),
            "Freshness: " .. tostring(record.freshness or "unknown"),
            "Freshness path: " .. tostring(Branding.displaySource(exp.source or "FFC", "FFC")),
        }
        if record.frozen then lines[#lines + 1] = "Warning: frozen item is excluded from normal meal crafting." end
        if record.rotten then lines[#lines + 1] = "Warning: rotten food should be discarded or handled with a specific safe action." end
        if record.burnt then lines[#lines + 1] = "Warning: burned food is blocked for FFC meals." end
        if record.preservation and Preservation and Preservation.describe then
            for _, line in ipairs(Preservation.describe(record.preservation)) do lines[#lines + 1] = line end
        end
        return lines
    end
    if record.kind == "stationRecipe" or record.kind == "stationRecipeHint" then
        local itemCount = 0
        for _, _ in ipairs(record.itemIds or {}) do itemCount = itemCount + 1 end
        local lines = {
            tostring(record.name or "Cooking Station recipe"),
            "Type: " .. tostring(record.kind or "stationRecipe"),
            "Status: " .. tostring(record.blocked and "Blocked" or "Ready"),
            "Station: " .. tostring(record.stationName or "none"),
            "Result: " .. tostring(record.resultType and foodName(record.resultType) or "FFC hot meal"),
            "Planner mode: " .. tostring(record.plannerMode or "Balanced"),
            "Meal effect: " .. tostring(record.effectName or "none"),
            "Selected safe ingredients: " .. tostring(itemCount),
            "Details: " .. tostring(record.detail or ""),
        }
        if record.blockedReason then
            lines[#lines + 1] = "Warning: " .. tostring(record.blockedReason)
        end
        if record.kind == "stationRecipeHint" then
            lines[#lines + 1] = "Recipe-specific server adapter required before this indexed recipe can launch."
        else
            lines[#lines + 1] = "Runs through FFC server validation before inventory changes."
        end
        for _, note in ipairs(record.plannerNotes or {}) do
            lines[#lines + 1] = tostring(note)
        end
        if record.plannerRecords and #record.plannerRecords > 0 then
            lines[#lines + 1] = "Will use:"
        end
        for i, ingredient in ipairs(record.plannerRecords or {}) do
            if i <= 5 then
                lines[#lines + 1] = tostring(i) .. ". " .. tostring(ingredient.name or ingredient.fullType or "ingredient")
                    .. " [" .. tostring(ingredient.category or "Food") .. ", " .. tostring(ingredient.freshness or "freshness unknown") .. "]"
            end
        end
        if record.effectTag and MealEffects and MealEffects.describeSpec then
            local effectLines = MealEffects.describeSpec(record.effectTag, 0)
            for i = 2, math.min(#effectLines, 5) do
                lines[#lines + 1] = effectLines[i]
            end
        end
        return lines
    end
    local lines = {
        record.name or "Ingredient",
        "Item class: " .. foodName(record.fullType or ""),
        "Category: " .. tostring(record.category or ""),
        "Freshness: " .. tostring(record.freshness or ""),
        "Hunger: " .. tostring(Utils.round(math.abs((record.hunger or 0) * 100), 1)),
        "Calories: " .. tostring(Utils.round(record.calories or 0, 0)),
        "Frozen/rotten/burned: " .. tostring(record.frozen) .. " / " .. tostring(record.rotten) .. " / " .. tostring(record.burnt),
    }
    local action = Actions and Actions.actionForFullType and Actions.actionForFullType(record.fullType) or nil
    if action and action.operation then
        lines[#lines + 1] = "Action: FFC Prep can run " .. tostring(action.label or "this operation") .. "."
    elseif record.usable ~= false and not record.frozen and not record.rotten and not record.burnt then
        lines[#lines + 1] = "Action: usable in Builder or Cook."
    else
        lines[#lines + 1] = "Action: blocked until the unsafe state is resolved."
    end
    if record.effectName then
        lines[#lines + 1] = "Meal effect: " .. tostring(record.effectName)
        lines[#lines + 1] = "Cooked by: " .. tostring(record.cookName or "unknown") .. (record.cookLevel and (" (Cooking " .. tostring(record.cookLevel) .. ")") or "")
        if MealEffects and MealEffects.describeSpec then
            local effectLines = MealEffects.describeSpec(record.effectTag, record.cookLevel)
            for i = 2, math.min(#effectLines, 5) do
                lines[#lines + 1] = effectLines[i]
            end
        end
    end
    if record.preservation and Preservation and Preservation.describe then
        for _, line in ipairs(Preservation.describe(record.preservation)) do lines[#lines + 1] = line end
    end
    if record.item and record.item.getModData and Balance and Balance.describeMealTuning then
        local md = record.item:getModData()
        for _, line in ipairs(Balance.describeMealTuning(md and md.FFC_Balance)) do lines[#lines + 1] = line end
    end
    return lines
end

function FFC_MainWindow:onPrimaryAction()
    if self.activeTab == "operations" then
        self:onRunOperation()
        return
    end
    if self.activeTab == "ingredients" then
        self:onUsePantryItem()
        return
    end
    if self.activeTab == "station" then
        if self.selectedRecipeRecord and self.selectedRecipeRecord.kind == "craftRecipe" then
            self:onStartInHouseRecipe(self.selectedRecipeRecord)
            return
        end
        self:onStartStationCooking()
        return
    end
    if self.activeTab == "recipes" or self.activeTab == "preservation" then
        self:onOpenRecipe()
        return
    end
    self:onBuildMeal()
end

function FFC_MainWindow:onUsePantryItem()
    if self.activeTab ~= "ingredients" then return end
    local selected = self.selectedPantryRecord
    if not selected then
        self.detailLines[#self.detailLines + 1] = "Choose a pantry item first."
        return
    end

    local action = Actions and Actions.actionForFullType and Actions.actionForFullType(selected.fullType) or nil
    if action and action.operation then
        local opRecord = Actions.recordForIngredient(selected)
        if opRecord then
            self:setActiveTab("operations")
            self.selectedOperationRecord = opRecord
            self.detailRecord = opRecord
            self.detailLines = self:detailForRecord(opRecord)
            self.detailLines[#self.detailLines + 1] = opRecord.blocked and "Prep route found, but the selected item is blocked." or "Prep route ready. Press Run Operation."
            return
        end
    end

    if selected.usable == false or selected.frozen or selected.rotten or selected.burnt or selected.fullType == FadedFeastcraft.Config.RESULT_FIELD_MEAL then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "This item cannot be added to Builder until the blocker is resolved."
        return
    end

    if selected.id then
        self.selectedIngredientIds = self.selectedIngredientIds or {}
        self.selectedIngredientIds[tostring(selected.id)] = true
    end
    self:setActiveTab("meal")
    self.detailRecord = selected
    self:updateMealDetails()
    self.detailLines[#self.detailLines + 1] = "Added to Builder. Add more ingredients or press Create Meal."
end

function FFC_MainWindow:onRunOperation()
    if self.activeTab ~= "operations" then return end
    local selected = self.selectedOperationRecord
    if not selected or not selected.operation or not selected.ingredient then
        self.detailLines[#self.detailLines + 1] = "Server request not sent: choose an operation first."
        return
    end
    if selected.blocked then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "Server request not sent: thaw or replace the blocked item first."
        return
    end

    local ingredient = selected.ingredient
    self.detailLines = self:detailForRecord(selected)
    if Net.requestOperation(getSpecificPlayer(0), ingredient.id, selected.operation.id, ingredient.fullType) then
        self.detailLines[#self.detailLines + 1] = "Operation request sent to server."
    else
        self.detailLines[#self.detailLines + 1] = "Server request not sent: FFC command channel is unavailable."
    end
end

function FFC_MainWindow:onBuildMeal()
    if self.activeTab ~= "meal" then return end
    self:updateMealDetails()
    if self.mealEstimate and self.mealEstimate.blocked then
        self.detailLines[#self.detailLines + 1] = "Server request not sent: unsafe or invalid selection."
        return
    end
    local ids = {}
    for id, enabled in pairs(self.selectedIngredientIds or {}) do
        if enabled then ids[#ids + 1] = tonumber(id) end
    end
    if #ids == 0 then
        self.detailLines[#self.detailLines + 1] = "Server request not sent: choose at least one ingredient."
        return
    end
    if Net.requestFieldMeal(getSpecificPlayer(0), ids) then
        self.detailLines[#self.detailLines + 1] = "Waiting for server validation..."
    else
        self.detailLines[#self.detailLines + 1] = "Server request not sent: FFC command channel is unavailable."
    end
end

function FFC_MainWindow:onOpenRecipe()
    if self.activeTab ~= "recipes" and self.activeTab ~= "preservation" then return end
    local selected = self.selectedRecipeRecord
    if not selected then
        self.detailLines[#self.detailLines + 1] = "Choose a recipe first."
        return
    end
    if selected.kind == "directRecipeAction" then
        self.detailLines = self:detailForRecord(selected)
        if selected.blocked then
            self.detailLines[#self.detailLines + 1] = "Server request not sent: resolve the blocked recipe requirement first."
            return
        end
        if Net.requestDirectRecipe(getSpecificPlayer(0), selected.id) then
            self.detailLines[#self.detailLines + 1] = "Waiting for server validation..."
        else
            self.detailLines[#self.detailLines + 1] = "Server request not sent: FFC command channel is unavailable."
        end
        return
    end
    if selected.kind == "craftRecipe" and selected.recipeObject then
        self:onStartInHouseRecipe(selected)
        return
    end

    if selected.kind ~= "craftRecipe" or not selected.recipeObject then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "This recipe is inspect-only until an FFC adapter is added."
        return
    end
end

function FFC_MainWindow:onStartInHouseRecipe(selected)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "Craft not started: no player is available."
        return
    end

    local availability = Recipes and Recipes.recipeAvailability and Recipes.recipeAvailability(selected, player) or nil
    local logic = availability and availability.logic or nil
    if not logic then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "Craft not started: " .. tostring(availability and availability.message or "handcraft logic is unavailable.")
        return
    end
    if availability.canPerform ~= true then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "Craft not started: missing requirements."
        return
    end
    if not (ISEntityUI and ISEntityUI.HandcraftStart and ISTimedActionQueue) then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "Craft not started: timed handcraft actions are unavailable."
        return
    end

    Utils.safeSet(logic, "setManualSelectInputs", true)
    Utils.safeCall(logic, "autoPopulateInputs")
    Utils.safeCall(logic, "canPerformCurrentRecipe")
    Utils.safeCall(logic, "updateManualInputAllowedItemTypes")
    local ok, action = pcall(ISEntityUI.HandcraftStart, player, logic, false, false)
    if not ok or not action then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "Craft not started: the recipe could not be queued."
        return
    end

    local context = {
        window = self,
        logic = logic,
        record = selected,
        tabId = self.activeTab,
    }
    if action.setOnStart then action:setOnStart(inHouseCraftStarted, context) end
    if action.setOnCancel then action:setOnCancel(inHouseCraftCancelled, context) end
    if action.setOnComplete then action:setOnComplete(inHouseCraftCompleted, context) end

    self.detailLines = self:detailForRecord(selected)
    self.detailLines[#self.detailLines + 1] = "Timed craft queued. FFC will reopen when the animation finishes."
    self:hideForTimedAction({ requestId = "recipe:" .. tostring(selected.name or "craft"), stationName = selected.name or "FFC recipe" })
    ISTimedActionQueue.add(action)
end

function FFC_MainWindow:hideMenuButtonForTimedAction()
    local button = FFC_MenuButton and FFC_MenuButton.instance or nil
    self.timedActionMenuButtonWasVisible = button and button.getIsVisible and button:getIsVisible() == true
    if self.timedActionMenuButtonWasVisible then
        button:setVisible(false)
        button:removeFromUIManager()
    end
end

function FFC_MainWindow:restoreAfterQueuedCooking()
    FadedFeastcraft.HideCookingStatus()
    self:setVisible(true)
    self:addToUIManager()
    if self.timedActionMenuButtonWasVisible then
        local button = FFC_MenuButton and FFC_MenuButton.instance or nil
        if button then
            button:addToUIManager()
            button:setVisible(true)
        elseif FadedFeastcraft.EnsureMenuButton then
            FadedFeastcraft.EnsureMenuButton()
        end
    end
    self.timedActionMenuButtonWasVisible = false
    self.pendingTimedActionContext = nil
    if self.bringToTop then self:bringToTop() end
end

function FFC_MainWindow:hideForTimedAction(context)
    self.pendingTimedActionContext = context
    FadedFeastcraft.HideCookingStatus()
    self:hideMenuButtonForTimedAction()
    self:setVisible(false)
    self:removeFromUIManager()
end

function FFC_MainWindow:minimizeForQueuedCooking(context)
    self.pendingCookRequestId = context and context.requestId or nil
    self.pendingCookContext = context
    self:hideForTimedAction(context)
end

function FFC_MainWindow:sendQueuedStationCooking(context)
    if not context then return false end
    FadedFeastcraft.UpdateCookingStatus("Finishing...", "Server validation")
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local sent = Net.requestStationCooking(player, context.recipeId, context.stationKey, context.itemIds, context.requestId)
    if not sent then
        self:onQueuedCookingFailed(context, "Server request not sent: FFC command channel is unavailable.")
    end
    return sent
end

function FFC_MainWindow:onQueuedCookingFailed(context, message)
    FadedFeastcraft.HideCookingStatus()
    if self.pendingCookRequestId == (context and context.requestId) then
        self.pendingCookRequestId = nil
        self.pendingCookContext = nil
    end
    self:restoreAfterQueuedCooking()
    self:setActiveTab("station")
    self.detailRecord = context and context.previewRecord or nil
    self.detailLines = {
        "Cooking did not complete",
        tostring(message or "The queued cooking action was interrupted."),
        "No FFC meal was created by this queued action.",
    }
end

function FFC_MainWindow:queueStationCooking(selected)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then
        self.detailLines[#self.detailLines + 1] = "Server request not sent: no player was available."
        return
    end

    local context = {
        requestId = Net.makeRequestId and Net.makeRequestId(player) or tostring(getTimestampMs and getTimestampMs() or ZombRand and ZombRand(1000000) or 0),
        recipeId = selected.recipeId,
        stationKey = selected.stationKey,
        stationName = selected.stationName or "Heat Source",
        itemIds = selected.itemIds or {},
        plannerRecords = selected.plannerRecords or {},
        previewRecord = selected,
        resultType = selected.resultType,
    }
    self.detailLines = self:detailForRecord(selected)
    self.detailLines[#self.detailLines + 1] = "Queued cooking action. FFC will reopen when the server confirms the result."
    self:minimizeForQueuedCooking(context)

    if ISTimedActionQueue and FFC_QueuedStationCookAction then
        ISTimedActionQueue.add(FFC_QueuedStationCookAction:new(player, context))
    else
        self:sendQueuedStationCooking(context)
    end
end

function FFC_MainWindow:showQueuedCookingResult(args, context)
    FadedFeastcraft.HideCookingStatus()
    self.pendingCookRequestId = nil
    self.pendingCookContext = nil
    self:restoreAfterQueuedCooking()
    self.selectedIngredientIds = {}
    self:setActiveTab("station")
    self:refreshData()

    if not (args and args.ok) then
        self.detailRecord = context and context.previewRecord or nil
        self.detailLines = {
            "Cooking failed",
            tostring(args and args.message or "The server rejected the cooking request."),
            "The visible action finished, but final inventory changes are server-authoritative.",
        }
        return
    end

    local result = args.result or {}
    local record = {
        kind = "craftResult",
        name = result.name or "FFC Hot Meal",
        fullType = result.fullType or (context and context.resultType) or FadedFeastcraft.Config.RESULT_FIELD_MEAL,
        resultType = result.fullType or (context and context.resultType) or FadedFeastcraft.Config.RESULT_FIELD_MEAL,
        textureName = result.textureName,
        category = "Completed dish",
        result = result,
        message = args.message,
        stationName = context and context.stationName or "Heat Source",
        ingredientCount = #(context and context.itemIds or {}),
        plannerRecords = context and context.plannerRecords or {},
        search = Utils.lower(tostring(result.name or "") .. " " .. tostring(result.fullType or "") .. " meal complete"),
    }
    self.detailRecord = record
    self.detailLines = self:detailForRecord(record)
end

function FFC_MainWindow:onCraftResult(args)
    local requestId = args and args.requestId or nil
    local queued = self.pendingCookRequestId and tostring(requestId or "") == tostring(self.pendingCookRequestId)
    if queued then
        self:showQueuedCookingResult(args, self.pendingCookContext)
        return
    end

    local message = tostring(args and args.message or "FFC response")
    self.detailLines = self.detailLines or {}
    if args and args.ok then
        self.selectedIngredientIds = {}
        self:refreshData()
    end
    self.detailLines = self.detailLines or {}
    self.detailLines[#self.detailLines + 1] = message
end

function FFC_MainWindow:onStartStationCooking()
    if self.activeTab ~= "station" then return end
    local selected = self.selectedStationCandidate
    if not selected then
        self.detailLines[#self.detailLines + 1] = "Server request not sent: choose a cooking station recipe first."
        return
    end
    if selected.blocked then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "Server request not sent: resolve the blocked station requirement first."
        return
    end
    if selected.recipeId ~= "ffc_hot_meal" then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "Server request not sent: this indexed recipe needs an adapter first."
        return
    end
    if not selected.itemIds or #selected.itemIds == 0 then
        self.detailLines = self:detailForRecord(selected)
        self.detailLines[#self.detailLines + 1] = "Server request not sent: no safe ingredients were selected by the station scan."
        return
    end
    self:queueStationCooking(selected)
end

function FadedFeastcraft.SendQueuedStationCooking(context)
    local win = FFC_MainWindow and FFC_MainWindow.instance or nil
    if win and win.sendQueuedStationCooking then
        return win:sendQueuedStationCooking(context)
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    return FadedFeastcraft.Net and FadedFeastcraft.Net.requestStationCooking and FadedFeastcraft.Net.requestStationCooking(player, context and context.recipeId, context and context.stationKey, context and context.itemIds, context and context.requestId)
end

function FadedFeastcraft.CancelQueuedStationCooking(context, message)
    local win = FFC_MainWindow and FFC_MainWindow.instance or nil
    if win and win.onQueuedCookingFailed then
        win:onQueuedCookingFailed(context, message)
    else
        FadedFeastcraft.HideCookingStatus()
    end
end

function FFC_MainWindow:prerender()
    ISCollapsableWindow.prerender(self)
    local bg = Theme.colors.bg
    self:drawRect(0, self:titleBarHeight(), self.width, self.height - self:titleBarHeight(), bg.a, bg.r, bg.g, bg.b)
    Theme.drawGlowBorder(self, 2, self:titleBarHeight() + 2, self.width - 4, self.height - self:titleBarHeight() - 4)
end

function FFC_MainWindow:render()
    ISCollapsableWindow.render(self)
    local frame = self.detailFrame or { x = self.list.x + self.list.width + DETAIL_GAP, y = self.list.y, w = self.width - self.list.x - self.list.width - DETAIL_GAP - WINDOW_PAD, h = self.list.height }
    local detailX = frame.x
    local detailY = frame.y
    local detailW = frame.w
    local detailH = frame.h
    if detailW <= 24 or detailH <= 24 then return end
    Theme.drawPanel(self, detailX, detailY, detailW, detailH, 0.7)
    local c = Theme.colors.cyan
    if not self.cookingIcon then self.cookingIcon = loadCookingIcon() end
    local headerTexture = textureForRecord(self.detailRecord, self.cookingIcon)
    local headerSize = self.detailRecord and self.detailRecord.kind == "craftResult" and 58 or 34
    if headerTexture and self.drawTextureScaled then
        self:drawTextureScaled(headerTexture, detailX + 8, detailY + 6, headerSize, headerSize, 0.95, 1, 1, 1)
        self:drawRectBorder(detailX + 7, detailY + 5, headerSize + 2, headerSize + 2, 0.42, 0.1, 0.65, 0.82)
        self:drawText(self.detailRecord and self.detailRecord.kind == "craftResult" and "Meal Ready" or "FFC", detailX + headerSize + 18, detailY + 10, c.r, c.g, c.b, 1, UIFont.Medium)
    else
        self:drawText("FFC", detailX + 10, detailY + 8, c.r, c.g, c.b, 1, UIFont.Medium)
    end
    local y = detailY + (self.detailRecord and self.detailRecord.kind == "craftResult" and 76 or 48)
    local stripRecords = nil
    self.iconHoverText = nil
    if self.detailRecord and self.detailRecord.plannerRecords then
        stripRecords = self.detailRecord.plannerRecords
    elseif self.activeTab == "meal" and self.selectedIngredientIds then
        stripRecords = {}
        local cache = Scanner.getCache()
        for _, record in ipairs(cache.records or {}) do
            if record.id and self.selectedIngredientIds[tostring(record.id)] then
                stripRecords[#stripRecords + 1] = record
            end
        end
    end
    y = drawRecordIconStrip(self, stripRecords, detailX + 10, y, detailW - 20, self.cookingIcon)
    if self.iconHoverText and self.iconHoverText ~= "" then
        local cyan = Theme.colors.cyan
        self:drawText(fitText(UIFont.Small, "Ingredient: " .. tostring(self.iconHoverText), detailW - 20), detailX + 10, y, cyan.r, cyan.g, cyan.b, 1, UIFont.Small)
        y = y + 18
    end
    for _, line in ipairs(self.detailLines or {}) do
        local color = Theme.colors.text
        if string.find(line, "Warning:", 1, true) then color = Theme.colors.warn end
        if string.find(line, "blocked", 1, true) or string.find(line, "not sent", 1, true) or string.find(line, "failed", 1, true) then color = Theme.colors.bad end
        if string.find(line, "Created", 1, true) or string.find(line, "opened", 1, true) then color = Theme.colors.good end
        for _, wrapped in ipairs(wrapText(UIFont.Small, line, detailW - 20)) do
            self:drawText(tostring(wrapped), detailX + 10, y, color.r, color.g, color.b, 1, UIFont.Small)
            y = y + 18
            if y > detailY + detailH - 18 then break end
        end
        if y > detailY + detailH - 18 then break end
    end
end

function FFC_MainWindow:onMouseWheel(del)
    if self.list and self.list.onMouseWheel then
        return self.list:onMouseWheel(del)
    end
    return true
end

function FFC_MainWindow:onResize()
    ISCollapsableWindow.onResize(self)
    self:layoutChrome()
end

function FFC_MainWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    FFC_MainWindow.instance = nil
end

function FFC_MainWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o:setTitle("FFC")
    o.resizable = true
    o.minimumWidth = MIN_WINDOW_WIDTH
    o.minimumHeight = MIN_WINDOW_HEIGHT
    o.activeTab = "ingredients"
    o.selectedIngredientIds = {}
    o.cookModeId = "balanced"
    o.recipeFilterId = "all"
    o.recipeViewFilterId = "craftable"
    o.preservationFilterId = "all"
    o.preservationViewFilterId = "craftable"
    o.detailLines = {}
    return o
end

function FadedFeastcraft.OpenWindow()
    if not FFC_MainWindow.instance then
        local w, h = 840, 540
        local x = getCore and math.floor((getCore():getScreenWidth() - w) / 2) or 100
        local y = getCore and math.floor((getCore():getScreenHeight() - h) / 2) or 80
        FFC_MainWindow.instance = FFC_MainWindow:new(x, y, w, h)
        FFC_MainWindow.instance:initialise()
        FFC_MainWindow.instance:addToUIManager()
        FFC_MainWindow.instance:setVisible(true)
        FFC_MainWindow.instance:refreshData(false)
        return FFC_MainWindow.instance
    end
    local win = FFC_MainWindow.instance
    win:setVisible(true)
    win:addToUIManager()
    if win.bringToTop then win:bringToTop() end
    win:refreshList()
    return win
end

function FadedFeastcraft.ToggleWindow()
    if FFC_MainWindow.instance and FFC_MainWindow.instance:getIsVisible() == true then
        local win = FFC_MainWindow.instance
        win:setVisible(false)
        win:removeFromUIManager()
    else
        FadedFeastcraft.OpenWindow()
    end
end

function FadedFeastcraft.OpenForItem(item)
    local win = FadedFeastcraft.OpenWindow()
    if not win or not item then return win end

    local fullType = Utils.getFullType(item)
    local action = Actions and Actions.actionForFullType and Actions.actionForFullType(fullType) or nil
    local operation = action and action.operation or nil
    if action and operation then
        win:setActiveTab("operations")
    else
        win:setActiveTab("ingredients")
    end

    if win.searchBox then
        win.searchBox:setText(Utils.getDisplayName(item))
    end
    win:refreshData(false)

    local itemId = item.getID and item:getID() or nil
    local cache = Scanner.getCache()
    local found = nil
    for _, record in ipairs(cache.records or {}) do
        if itemId and record.id == itemId then
            found = record
            break
        end
    end
    found = found or {
        id = itemId,
        name = Utils.getDisplayName(item),
        fullType = fullType,
        textureName = Utils.getItemTextureName and Utils.getItemTextureName(item) or nil,
        source = SourcePacks and SourcePacks.sourceForFullType and SourcePacks.sourceForFullType(fullType) or "",
        frozen = Utils.safeCall(item, "isFrozen") == true,
        rotten = Utils.safeCall(item, "isRotten") == true,
        burnt = Utils.safeCall(item, "isBurnt") == true,
    }

    if action and operation then
        local opRecord = Actions.recordForIngredient(found)
        opRecord = opRecord or {
            kind = "operation",
            name = tostring(action.label or operation.label or "Operation") .. ": " .. tostring(found.name or fullType),
            action = action,
            operation = operation,
            ingredient = found,
            fullType = fullType,
            source = action.source or operation.source,
            frozen = found.frozen,
            rotten = found.rotten,
            burnt = found.burnt,
        }
        opRecord.blocked = Operations.isBlockedByRecord and Operations.isBlockedByRecord(operation, found) or false
        win.selectedOperationRecord = opRecord
        win.detailLines = win:detailForRecord(opRecord)
    else
        win.detailLines = win:detailForRecord(found)
    end
    return win
end

return FFC_MainWindow

if isServer() then return end

require "BCR_DisplaySettings"
require "BCR_Scale"
require "BCR_Utils"
require "BCR_Debug"
require "BCR_IconResolver"
require "BCR_RecipeIndex"
require "BCR_BuildIndex"
require "BCR_Availability"
require "BCR_UserData"
require "BCR_Actions"

BCR_HubWindow = BCR_HubWindow or {}

local HubPanel = ISPanel:derive("BCR_HubWindow")

local BASE_MIN_W = 920
local BASE_MIN_H = 430
local BASE_DEFAULT_W = 1040
local BASE_DEFAULT_H = 620
local BASE_COLLAPSED_W = 230
local NO_CATEGORY = "__none"
local ALL_CATEGORIES = "__all"
local LIVE_REFRESH_MS = 650
local AVAILABLE_BATCH_SIZE = 16
local AVAILABLE_RESULTS_REFRESH_MS = 160
local SEARCH_DEBOUNCE_MS = 120
local DEEP_SEARCH_BATCH_SIZE = 24
local DEEP_SEARCH_REFRESH_MS = 140
local INDEX_BATCH_SIZE = 64
local INDEX_RESULTS_REFRESH_MS = 120
local INDEX_PREVIEW_LIMIT = 240
local RESULT_PAGE_SIZE = 5
local ROW_RENDER_LOG_MS = 1000
local MAX_CATEGORY_TAB_BUTTONS = 10
local CATEGORY_TAB_PAGE_STEP = 6
local AREA_SCAN_STALE_MARGIN = 2

local COLORS = {
    bg = { r = 0.050, g = 0.055, b = 0.060, a = 0.96 },
    header = { r = 0.075, g = 0.083, b = 0.090, a = 0.98 },
    panel = { r = 0.068, g = 0.075, b = 0.080, a = 0.94 },
    row = { r = 0.060, g = 0.066, b = 0.070, a = 0.96 },
    rowAlt = { r = 0.072, g = 0.078, b = 0.082, a = 0.96 },
    rowHover = { r = 0.105, g = 0.122, b = 0.130, a = 0.96 },
    border = { r = 0.32, g = 0.36, b = 0.38, a = 0.82 },
    text = { r = 0.92, g = 0.93, b = 0.90, a = 1.00 },
    muted = { r = 0.66, g = 0.69, b = 0.68, a = 1.00 },
    toolbar = { r = 0.105, g = 0.125, b = 0.135, a = 1.00 },
    toolbarBorder = { r = 0.38, g = 0.46, b = 0.48, a = 0.76 },
    toolbarButton = { r = 0.20, g = 0.245, b = 0.26, a = 1.00 },
    toolbarActive = { r = 0.18, g = 0.52, b = 0.56, a = 1.00 },
    active = { r = 0.16, g = 0.42, b = 0.45, a = 0.96 },
    selected = { r = 0.105, g = 0.220, b = 0.245, a = 0.96 },
    button = { r = 0.095, g = 0.105, b = 0.110, a = 0.96 },
    disabled = { r = 0.22, g = 0.235, b = 0.245, a = 0.96 },
    primaryButton = { r = 0.18, g = 0.56, b = 0.34, a = 1.00 },
    blockedButton = { r = 0.55, g = 0.20, b = 0.17, a = 1.00 },
    favoriteButton = { r = 0.22, g = 0.40, b = 0.58, a = 1.00 },
    repeatButton = { r = 0.34, g = 0.32, b = 0.58, a = 1.00 },
    close = { r = 0.48, g = 0.20, b = 0.18, a = 0.96 },
    craft = { r = 0.45, g = 0.72, b = 0.48, a = 1.00 },
    build = { r = 0.64, g = 0.58, b = 0.88, a = 1.00 },
    ready = { r = 0.35, g = 0.78, b = 0.46, a = 1.00 },
    missing = { r = 0.95, g = 0.36, b = 0.30, a = 1.00 },
    warning = { r = 0.95, g = 0.66, b = 0.28, a = 1.00 },
    info = { r = 0.48, g = 0.72, b = 0.86, a = 1.00 },
    iconBg = { r = 0.105, g = 0.118, b = 0.125, a = 0.96 },
    iconBorder = { r = 0.36, g = 0.42, b = 0.44, a = 0.86 },
}

local function scalePx(value)
    if BCR_Scale and BCR_Scale.px then
        return BCR_Scale.px(value)
    end
    return value
end

local function scaleFactor()
    if BCR_Scale and BCR_Scale.factor then
        return BCR_Scale.factor()
    end
    return 1.0
end

local function scaleFont(value)
    if BCR_Scale and BCR_Scale.font then
        return BCR_Scale.font(value)
    end
    return UIFont.Small
end

local function fontHeight(font)
    local tm = getTextManager and getTextManager() or nil
    if tm then return tm:getFontHeight(font or UIFont.Small) or scalePx(14) end
    return scalePx(14)
end

local function makeMetrics()
    local font = scaleFont(14)
    local lineH = fontHeight(font) + scalePx(3)
    return {
        factor = scaleFactor(),
        minW = scalePx(BASE_MIN_W),
        minH = scalePx(BASE_MIN_H),
        defaultW = scalePx(BASE_DEFAULT_W),
        defaultH = scalePx(BASE_DEFAULT_H),
        collapsedW = scalePx(BASE_COLLAPSED_W),
        headerH = scalePx(30),
        toolbarH = scalePx(34),
        pad = scalePx(10),
        tabW = scalePx(76),
        tabGap = scalePx(6),
        buttonH = scalePx(24),
        closeW = scalePx(24),
        collapseW = scalePx(74),
        refreshW = scalePx(82),
        sortW = scalePx(88),
        filterW = scalePx(96),
        pageW = scalePx(24),
        categoryTabH = scalePx(22),
        categoryPagerW = scalePx(24),
        categoryTabGap = scalePx(4),
        actionW = scalePx(88),
        areaScanW = scalePx(92),
        categoryW = scalePx(205),
        detailsW = scalePx(360),
        grip = scalePx(16),
        icon = scalePx(32),
        detailIcon = scalePx(32),
        resultH = math.max(scalePx(58), lineH * 2 + scalePx(18)),
        categoryH = math.max(scalePx(28), lineH + scalePx(10)),
        font = font,
        lineH = lineH,
    }
end

local function defaultMetrics()
    return makeMetrics()
end

local function currentMetrics(list)
    if list and list.bcrMetrics then return list.bcrMetrics end
    return defaultMetrics()
end

local function minWindowWidth()
    return defaultMetrics().minW
end

local function minWindowHeight()
    return defaultMetrics().minH
end

local function defaultWindowWidth()
    return defaultMetrics().defaultW
end

local function defaultWindowHeight()
    return defaultMetrics().defaultH
end

local function screenSize()
    local core = getCore and getCore() or nil
    return core and core:getScreenWidth() or 1280,
        core and core:getScreenHeight() or 768
end

local function clampWindowSize(width, height)
    local sw, sh = screenSize()
    local margin = scalePx(12)
    local m = defaultMetrics()
    width = math.max(m.minW, math.min(width, sw - margin * 2))
    height = math.max(m.minH, math.min(height, sh - margin * 2))
    return width, height
end

local function contentAwareDefaultSize()
    local m = defaultMetrics()
    return clampWindowSize(m.defaultW, m.defaultH)
end

local function centerWindowPosition(width, height)
    local sw, sh = screenSize()
    return BCR_Utils.clampToScreen(math.floor((sw - width) / 2), math.floor((sh - height) / 2), width, height)
end

local function textWidth(font, text)
    local tm = getTextManager and getTextManager() or nil
    if not tm then return string.len(tostring(text or "")) * 7 end
    return tm:MeasureStringX(font or UIFont.Small, tostring(text or ""))
end

local function ellipsize(font, text, maxWidth)
    text = tostring(text or "")
    if maxWidth <= 0 then return "" end
    if textWidth(font, text) <= maxWidth then return text end
    local suffix = "..."
    while string.len(text) > 0 and textWidth(font, text .. suffix) > maxWidth do
        text = string.sub(text, 1, string.len(text) - 1)
    end
    if text == "" then return suffix end
    return text .. suffix
end

local function wrapText(font, text, maxWidth)
    text = tostring(text or "")
    if maxWidth <= 0 or text == "" then return { text } end

    local out = {}
    for rawLine in string.gmatch(text .. "\n", "([^\n]*)\n") do
        local line = ""
        for word in string.gmatch(rawLine, "%S+") do
            local candidate = line == "" and word or (line .. " " .. word)
            if line ~= "" and textWidth(font, candidate) > maxWidth then
                table.insert(out, line)
                line = word
            else
                line = candidate
            end
        end
        if line ~= "" then
            table.insert(out, line)
        elseif rawLine == "" then
            table.insert(out, "")
        end
    end
    if #out == 0 then table.insert(out, text) end
    return out
end

local function applyButtonColor(btn, color)
    if not btn or not color then return end
    btn.backgroundColor = { r = color.r, g = color.g, b = color.b, a = color.a }
    btn.backgroundColorMouseOver = { r = math.min(color.r + 0.10, 1), g = math.min(color.g + 0.10, 1), b = math.min(color.b + 0.10, 1), a = 1 }
    btn.borderColor = { r = math.min(color.r + 0.34, 1), g = math.min(color.g + 0.34, 1), b = math.min(color.b + 0.34, 1), a = 0.78 }
    btn.backgroundColorEnabled = { r = color.r, g = color.g, b = color.b, a = color.a }
    btn.borderColorEnabled = { r = btn.borderColor.r, g = btn.borderColor.g, b = btn.borderColor.b, a = btn.borderColor.a }
    btn.textColor = { r = 0.96, g = 0.98, b = 0.96, a = 1.00 }
end

local function makeButton(parent, x, y, w, label, target, onclick, h)
    local m = parent and parent.metrics or defaultMetrics()
    local btn = ISButton:new(x, y, w, h or m.buttonH, label, target, onclick)
    btn:initialise()
    btn:instantiate()
    btn.font = m.font
    applyButtonColor(btn, COLORS.button)
    parent:addChild(btn)
    return btn
end

local function setChildVisible(child, visible)
    if child and child.setVisible then
        child:setVisible(visible == true)
    end
end

local function setButtonEnabled(btn, enabled)
    if not btn then return end
    if btn.setEnable then
        btn:setEnable(enabled == true)
    else
        btn.enable = enabled == true
    end
end

local function playerSquareSignature(player)
    if not player then return "no-player" end
    local square = player.getCurrentSquare and player:getCurrentSquare() or nil
    if square then
        return table.concat({
            tostring(square:getX()),
            tostring(square:getY()),
            tostring(square:getZ()),
        }, "|")
    end
    local x = player.getX and math.floor(tonumber(player:getX()) or 0) or 0
    local y = player.getY and math.floor(tonumber(player:getY()) or 0) or 0
    local z = player.getZ and math.floor(tonumber(player:getZ()) or 0) or 0
    return tostring(x) .. "|" .. tostring(y) .. "|" .. tostring(z)
end

local function itemKindLabel(kind)
    if kind == "build" then
        return BCR_Utils.tr("UI_BCR_KindBuild", "Build")
    end
    return BCR_Utils.tr("UI_BCR_KindCraft", "Craft")
end

local function displayCategory(category)
    if not category or category == "" then
        return BCR_Utils.tr("UI_BCR_Uncategorized", "Uncategorized")
    end
    return BCR_Utils.displayLabel(category, BCR_Utils.tr("UI_BCR_Uncategorized", "Uncategorized"))
end

local function hasCategorySelection(categoryKey)
    return categoryKey ~= nil and categoryKey ~= "" and categoryKey ~= NO_CATEGORY
end

local SORT_MODES = { "name_az", "name_za", "category", "type" }
local BASE_FILTER_MODES = { "all", "favorites", "materials", "ready", "blocked" }

local function availabilityFilterActive(mode)
    return mode == "materials" or mode == "ready" or mode == "blocked"
end

local function sourceFilterKey(mode)
    return string.match(tostring(mode or ""), "^source:(.+)$")
end

local function sourceFilterMode(key)
    return "source:" .. tostring(key or "")
end

local function isVanillaSource(source)
    local key = BCR_Utils.lower(source)
    return key == "" or key == "base" or key == "vanilla" or key == "unknown"
end

local function nextModeValue(values, current)
    for index, value in ipairs(values) do
        if value == current then
            return values[(index % #values) + 1]
        end
    end
    return values[1]
end

local function sortModeLabel(mode)
    if mode == "name_za" then return BCR_Utils.tr("UI_BCR_Sort_NameZA", "Sort: Z-A") end
    if mode == "category" then return BCR_Utils.tr("UI_BCR_Sort_Category", "Sort: Cat") end
    if mode == "type" then return BCR_Utils.tr("UI_BCR_Sort_Type", "Sort: Type") end
    return BCR_Utils.tr("UI_BCR_Sort_NameAZ", "Sort: A-Z")
end

local function filterModeLabel(mode)
    if mode == "favorites" then return BCR_Utils.tr("UI_BCR_Filter_Favorites", "Show: Favs") end
    if mode == "materials" then return BCR_Utils.tr("UI_BCR_Filter_Materials", "Show: Mats") end
    if mode == "ready" then return BCR_Utils.tr("UI_BCR_Filter_Ready", "Show: Ready") end
    if mode == "blocked" then return BCR_Utils.tr("UI_BCR_Filter_Blocked", "Show: Blocked") end
    return BCR_Utils.tr("UI_BCR_Filter_All", "Show: All")
end

local function queryLongEnoughForDeepSearch(query)
    return string.len(BCR_Utils.trim(query or "")) >= 3
end

local function deepSearchStateKey(panel)
    return table.concat({
        BCR_Utils.lower(panel and panel.searchText or ""),
        tostring(panel and panel.mode or "all"),
        tostring(panel and panel.filterMode or "all"),
        tostring(panel and panel.categoryKey or ""),
        tostring(BCR_RecipeIndex and BCR_RecipeIndex._buildGeneration or 0),
        tostring(BCR_BuildIndex and BCR_BuildIndex._buildGeneration or 0),
        tostring(#(panel and panel.availableItems or {})),
        tostring(panel and panel.availabilityQueueIndex or 0),
        tostring(panel and panel.availabilityScanComplete == true),
    }, "|")
end

local function matchesItemQuery(item, query, terms, allowUncachedDeep)
    if BCR_Utils.matchesQueryTermsLower(item and item.searchKey or "", terms) then
        return true
    end
    if not queryLongEnoughForDeepSearch(query) then
        return false
    end

    local deepKey = item and item.deepSearchKey or nil
    if not deepKey and allowUncachedDeep then
        if item and item.kind == "craft" and BCR_RecipeIndex.deepSearchText then
            BCR_RecipeIndex.deepSearchText(item)
        elseif item and item.kind == "build" and BCR_BuildIndex.deepSearchText then
            BCR_BuildIndex.deepSearchText(item)
        end
        deepKey = item and item.deepSearchKey or nil
    end
    if deepKey then
        return BCR_Utils.matchesQueryTermsLower(deepKey, terms)
    end
    return false
end

local function categorySort(a, b)
    return BCR_Utils.lower(a.label) < BCR_Utils.lower(b.label)
end

local function indexPeek(index)
    if index and index.peek then
        return index.peek() or {}
    end
    return index and index._items or {}
end

local function indexReady(index)
    if index and index.isReady then
        return index.isReady() == true
    end
    return index == nil or index._items ~= nil
end

local function cleanItemString(itemString)
    if not itemString or itemString == "" then return "" end
    local value = tostring(itemString)
    if string.sub(value, 1, 1) == "!" then
        value = string.sub(value, 2)
    end
    return value
end

local function drawItemIcon(surface, row, x, y, size, font, kindColor)
    kindColor = kindColor or COLORS.muted
    local icon = BCR_IconResolver and BCR_IconResolver.textureFor and BCR_IconResolver.textureFor(row) or nil
    if icon and surface.drawTextureScaled then
        surface:drawTextureScaled(icon, x, y, size, size, 0.96, 1, 1, 1)
        return true
    end

    surface:drawRect(x, y, size, size, COLORS.iconBg.a, COLORS.iconBg.r, COLORS.iconBg.g, COLORS.iconBg.b)
    surface:drawRectBorder(x, y, size, size, COLORS.iconBorder.a, COLORS.iconBorder.r, COLORS.iconBorder.g, COLORS.iconBorder.b)
    if kindColor then
        surface:drawRect(x, y, scalePx(3), size, 0.90, kindColor.r, kindColor.g, kindColor.b)
    end

    local label = BCR_Utils.displayLabel(row and row.label or "", row and row.id or "?")
    local letter = string.upper(string.sub(label ~= "" and label or "?", 1, 1))
    local textX = x + math.floor((size - textWidth(font, letter)) / 2)
    local textY = y + math.floor((size - fontHeight(font)) / 2)
    surface:drawText(letter, textX, textY, kindColor.r, kindColor.g, kindColor.b, 0.95, font)
    return false
end

local function statusTextFor(row, status)
    if not status then return "" end
    local text = status.available and BCR_Utils.tr("UI_BCR_StatusReady", "Ready") or BCR_Utils.tr("UI_BCR_StatusBlocked", "Blocked")
    if status.available and row and row.kind == "craft" and status.count and status.count > 1 then
        text = text .. " x" .. tostring(status.count)
    end
    return text
end

local function statusColorFor(status)
    if not status then return COLORS.muted end
    if status.available then return COLORS.ready end
    if status.unknown then return COLORS.warning end
    return COLORS.missing
end

local function detailColorFor(line)
    local text = BCR_Utils.lower(line)
    if string.find(text, "blocked", 1, true)
        or string.find(text, "missing", 1, true)
        or string.find(text, "not learned", 1, true)
        or string.find(text, "too dark", 1, true)
        or string.find(text, "failed", 1, true) then
        return COLORS.missing
    end
    if string.find(text, "ready", 1, true)
        or string.find(text, "queued", 1, true)
        or string.find(text, "started", 1, true) then
        return COLORS.ready
    end
    if string.find(text, "tool:", 1, true)
        or string.find(text, "keeps:", 1, true)
        or string.find(text, "surface:", 1, true)
        or string.find(text, "skill:", 1, true) then
        return COLORS.info
    end
    if string.find(text, "consumes:", 1, true) then
        return COLORS.warning
    end
    return COLORS.muted
end

function HubPanel:new(x, y, playerIndex, width, height)
    local metrics = makeMetrics()
    local o = ISPanel.new(self, x, y, width or metrics.defaultW, height or metrics.defaultH)
    setmetatable(o, self)
    self.__index = self
    o.metrics = metrics
    o.lastScaleFactor = metrics.factor
    o.playerIndex = playerIndex or 0
    o.mode = "all"
    o.sortMode = "name_az"
    o.filterMode = "all"
    o.categoryKey = nil
    o.categoryTabOffset = 1
    o.categoryTabEndIndex = 1
    o.sourceFilterLabels = {}
    o.sourceFilterOptionsCache = nil
    o.sourceFilterOptionsCacheMode = nil
    o.searchText = ""
    o.searchTerms = {}
    o.searchPending = false
    o.searchRefreshAt = 0
    o.deepSearchQueue = nil
    o.deepSearchQueueIndex = 1
    o.deepSearchQueryKey = nil
    o.deepSearchComplete = true
    o.lastDeepSearchResultsRefresh = 0
    o.filteredItems = {}
    o.totalFilteredItems = 0
    o.resultPage = 1
    o.pageStartIndex = 1
    o.pageEndIndex = 0
    o.categoryItems = {}
    o.sourceItemsCache = nil
    o.sourceItemsCacheMode = nil
    o.sourceItemsCacheGeneration = nil
    o.craftCount = 0
    o.buildCount = 0
    o.indexBuildPending = false
    o.lastIndexResultsRefresh = 0
    o.availability = nil
    o.statusCache = {}
    o.availableItems = {}
    o.availabilityQueue = nil
    o.availabilityQueueIndex = 1
    o.availabilityContext = nil
    o.availabilityScanComplete = false
    o.lastAvailableResultsRefresh = 0
    o.contextIsoObject = nil
    o.contextQueryOverride = "*"
    o.contextIgnoreFindSurface = false
    o.contextInventoryItem = nil
    o.contextRecipe = nil
    o.pendingSelectionKind = nil
    o.pendingSelectionRecipe = nil
    o.selectedItem = nil
    o.detailLines = {}
    o.wrappedDetailLines = nil
    o.wrappedDetailWidth = 0
    o.wrappedDetailFont = nil
    o.lastActionMessage = nil
    o.liveDirty = true
    o.liveReason = "open"
    o.lastLiveCheck = 0
    o.lastLiveRefresh = 0
    o.lastLiveSignature = ""
    o.lastSquareSignature = ""
    o.areaContainers = nil
    o.areaContainerCount = 0
    o.areaScanOrigin = nil
    o.areaScanMessage = nil
    o.placementCollapseEntity = nil
    o.placementCollapseShouldRestore = false
    o.collapsed = false
    o.expandedWidth = width or metrics.defaultW
    o.expandedHeight = height or metrics.defaultH
    o.dragging = false
    o.resizing = false
    o.dragX = 0
    o.dragY = 0
    o.resizeStartW = metrics.defaultW
    o.resizeStartH = metrics.defaultH
    o.resizeMouseX = 0
    o.resizeMouseY = 0
    o.backgroundColor = COLORS.bg
    o.borderColor = COLORS.border
    return o
end

function HubPanel:refreshMetrics()
    local factor = scaleFactor()
    if self.metrics and math.abs((self.lastScaleFactor or 0) - factor) <= 0.001 then
        return self.metrics
    end

    self.metrics = makeMetrics()
    self.lastScaleFactor = self.metrics.factor
    if self.collapsed then
        self:setWidth(self.metrics.collapsedW)
        self:setHeight(self.metrics.headerH + scalePx(6))
    else
        if self.width < self.metrics.minW then self:setWidth(self.metrics.minW) end
        if self.height < self.metrics.minH then self:setHeight(self.metrics.minH) end
    end
    self:layoutChildren()
    return self.metrics
end

function HubPanel:initialise()
    ISPanel.initialise(self)
end

function HubPanel:createChildren()
    ISPanel.createChildren(self)

    local m = self.metrics or makeMetrics()
    self.metrics = m

    self.closeBtn = makeButton(self, self.width - m.pad - m.closeW, scalePx(3), m.closeW, BCR_Utils.tr("UI_BCR_Setting_Close", "X"), self, self.onClose)
    self.closeBtn.anchorRight = true
    self.closeBtn.anchorTop = true
    applyButtonColor(self.closeBtn, COLORS.close)

    self.minimizeBtn = makeButton(self, self.width - m.pad - m.closeW - m.collapseW - scalePx(4), scalePx(3), m.collapseW, BCR_Utils.tr("UI_BCR_Collapse", "Collapse"), self, self.onMinimize)
    self.minimizeBtn.anchorRight = true
    self.minimizeBtn.anchorTop = true

    local tabY = m.headerH + scalePx(5)
    local tabStep = m.tabW + m.tabGap
    self.availableBtn = makeButton(self, m.pad, tabY, m.tabW, BCR_Utils.tr("UI_BCR_TabAvailable", "Available"), self, self.onModeButton)
    self.availableBtn.mode = "available"
    self.craftBtn = makeButton(self, m.pad + tabStep, tabY, m.tabW, BCR_Utils.tr("UI_BCR_TabCraft", "Craft"), self, self.onModeButton)
    self.craftBtn.mode = "craft"
    self.buildBtn = makeButton(self, m.pad + tabStep * 2, tabY, m.tabW, BCR_Utils.tr("UI_BCR_TabBuild", "Build"), self, self.onModeButton)
    self.buildBtn.mode = "build"
    self.favoritesBtn = makeButton(self, m.pad + tabStep * 3, tabY, m.tabW, BCR_Utils.tr("UI_BCR_TabFavorites", "Favs"), self, self.onModeButton)
    self.favoritesBtn.mode = "favorites"
    self.recentBtn = makeButton(self, m.pad + tabStep * 4, tabY, m.tabW, BCR_Utils.tr("UI_BCR_TabRecent", "Recent"), self, self.onModeButton)
    self.recentBtn.mode = "recent"

    self.refreshBtn = makeButton(self, self.width - m.pad - m.refreshW, tabY, m.refreshW, BCR_Utils.tr("UI_BCR_Refresh", "Refresh"), self, self.onRefresh)
    self.refreshBtn.anchorRight = true
    self.refreshBtn.anchorTop = true

    self.searchEntry = ISTextEntryBox:new("", m.pad + m.categoryW + scalePx(8), m.headerH + m.toolbarH + scalePx(6), self:mainListWidth(), m.buttonH)
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    self.searchEntry.onTextChange = HubPanel.onSearchTextChange
    self.searchEntry.target = self
    if self.searchEntry.setClearButton then
        self.searchEntry:setClearButton(true)
    end
    if self.searchEntry.setPlaceholderText then
        self.searchEntry:setPlaceholderText(BCR_Utils.tr("UI_BCR_SearchPlaceholder", "Search recipes and buildables"))
    end
    self:addChild(self.searchEntry)

    self.sortBtn = makeButton(self, 0, 0, m.sortW, sortModeLabel(self.sortMode), self, self.onSortButton)
    self.sortBtn.anchorTop = true

    self.filterBtn = makeButton(self, 0, 0, m.filterW, filterModeLabel(self.filterMode), self, self.onFilterButton)
    self.filterBtn.anchorTop = true

    self.pagePrevBtn = makeButton(self, 0, 0, m.pageW, "<", self, self.onResultPagePrev)
    self.pagePrevBtn.anchorTop = true

    self.pageNextBtn = makeButton(self, 0, 0, m.pageW, ">", self, self.onResultPageNext)
    self.pageNextBtn.anchorTop = true

    self.categoryPrevBtn = makeButton(self, 0, 0, m.categoryPagerW, "<", self, self.onCategoryTabsPrev, m.categoryTabH)
    self.categoryPrevBtn.anchorTop = true

    self.categoryNextBtn = makeButton(self, 0, 0, m.categoryPagerW, ">", self, self.onCategoryTabsNext, m.categoryTabH)
    self.categoryNextBtn.anchorTop = true

    self.categoryTabButtons = {}
    for index = 1, MAX_CATEGORY_TAB_BUTTONS do
        local btn = makeButton(self, 0, 0, scalePx(76), "", self, self.onCategoryTabButton, m.categoryTabH)
        btn.anchorTop = true
        btn.categoryTabIndex = index
        btn:setVisible(false)
        table.insert(self.categoryTabButtons, btn)
    end

    local listY = self.searchEntry:getBottom() + 8
    self.categoryList = ISScrollingListBox:new(m.pad, listY, m.categoryW, self.height - listY - m.pad)
    self.categoryList:initialise()
    self.categoryList:instantiate()
    self.categoryList.itemheight = m.categoryH
    self.categoryList.font = m.font
    self.categoryList.target = self
    self.categoryList.bcrMetrics = m
    self.categoryList.doDrawItem = HubPanel.drawCategoryItem
    self.categoryList:setOnMouseDownFunction(self, HubPanel.onCategorySelected)
    self:addChild(self.categoryList)

    self.resultList = ISScrollingListBox:new(m.pad + m.categoryW + scalePx(8), listY, self:mainListWidth(), self.height - listY - m.pad)
    self.resultList:initialise()
    self.resultList:instantiate()
    self.resultList.itemheight = m.resultH
    self.resultList.font = m.font
    self.resultList.target = self
    self.resultList.bcrMetrics = m
    self.resultList.doDrawItem = HubPanel.drawResultItem
    self.resultList:setOnMouseDownFunction(self, HubPanel.onResultSelected)
    self.resultList.onMouseWheel = HubPanel.onResultListMouseWheel
    self:addChild(self.resultList)

    self.actionBtn = makeButton(self, self.width - m.pad - m.actionW, m.headerH + m.toolbarH + scalePx(10), m.actionW, BCR_Utils.tr("UI_BCR_ActionMake", "Make"), self, self.onPrimaryAction)
    self.actionBtn.anchorRight = true
    self.actionBtn.anchorTop = true
    applyButtonColor(self.actionBtn, COLORS.primaryButton)

    self.favoriteToggleBtn = makeButton(self, self.width - m.pad - m.actionW, m.headerH + m.toolbarH + scalePx(38), m.actionW, BCR_Utils.tr("UI_BCR_Favorite", "Favorite"), self, self.onFavoriteToggle)
    self.favoriteToggleBtn.anchorRight = true
    self.favoriteToggleBtn.anchorTop = true

    self.repeatBtn = makeButton(self, self.width - m.pad - m.actionW, m.headerH + m.toolbarH + scalePx(66), m.actionW, BCR_Utils.tr("UI_BCR_Repeat", "Repeat"), self, self.onRepeatAction)
    self.repeatBtn.anchorRight = true
    self.repeatBtn.anchorTop = true

    self.areaScanBtn = makeButton(self, self.width - m.pad - m.actionW, m.headerH + m.toolbarH + scalePx(94), m.actionW, BCR_Utils.tr("UI_BCR_AreaScan", "Scan Area"), self, self.onAreaScan)
    self.areaScanBtn.anchorRight = true
    self.areaScanBtn.anchorTop = true

    self:layoutChildren()
    if not self.deferInitialRefresh then
        self:refreshAll(false)
    end
end

function HubPanel:mainListWidth()
    local m = self.metrics or makeMetrics()
    return math.max(scalePx(260), self.width - self:detailsWidth() - m.categoryW - m.pad * 4 - scalePx(8))
end

function HubPanel:detailsWidth()
    local m = self.metrics or makeMetrics()
    return math.min(scalePx(460), math.max(m.detailsW, math.floor(self.width * 0.34)))
end

function HubPanel:detailsRect()
    local m = self.metrics or makeMetrics()
    local detailsW = self:detailsWidth()
    local detailsX = self.width - detailsW - m.pad
    local detailsY = m.headerH + m.toolbarH + scalePx(6)
    local detailsH = self.height - detailsY - m.pad
    return detailsX, detailsY, detailsW, detailsH
end

function HubPanel:detailsActionY()
    local _, detailsY = self:detailsRect()
    return detailsY + scalePx(29)
end

function HubPanel:detailsContentY()
    local m = self.metrics or makeMetrics()
    return self:detailsActionY() + math.max(m.buttonH, scalePx(28)) + scalePx(12)
end

function HubPanel:categoryTabsY()
    if self.searchEntry then
        return self.searchEntry:getBottom() + scalePx(6)
    end
    local m = self.metrics or makeMetrics()
    return m.headerH + m.toolbarH + m.buttonH + scalePx(12)
end

function HubPanel:listY()
    local m = self.metrics or makeMetrics()
    if self.searchEntry then
        return self:categoryTabsY() + m.categoryTabH + scalePx(8)
    end
    return m.headerH + m.toolbarH + m.buttonH + m.categoryTabH + scalePx(20)
end

function HubPanel:filterModeTitle()
    local sourceKey = sourceFilterKey(self.filterMode)
    if sourceKey then
        local label = self.sourceFilterLabels and self.sourceFilterLabels[sourceKey] or sourceKey
        return BCR_Utils.format(BCR_Utils.tr("UI_BCR_Filter_Source", "Mod: %1"), label)
    end
    return filterModeLabel(self.filterMode)
end

function HubPanel:sourceFilterSourceItems(force)
    if self.mode == "build" then
        return self:buildItems(force)
    end
    if self.mode == "craft" then
        return self:craftItems(force)
    end
    if self.mode == "favorites" then
        local favorites = {}
        for _, item in ipairs(self:craftItems(force)) do
            if BCR_UserData.isFavorite(item, self.playerIndex) then
                table.insert(favorites, item)
            end
        end
        for _, item in ipairs(self:buildItems(force)) do
            if BCR_UserData.isFavorite(item, self.playerIndex) then
                table.insert(favorites, item)
            end
        end
        return favorites
    end
    if self.mode == "recent" then
        local allItems = {}
        for _, item in ipairs(self:craftItems(force)) do
            allItems[item.key] = item
        end
        for _, item in ipairs(self:buildItems(force)) do
            allItems[item.key] = item
        end
        local recent = {}
        for _, key in ipairs(BCR_UserData.recents(self.playerIndex)) do
            if allItems[key] then
                table.insert(recent, allItems[key])
            end
        end
        return recent
    end
    if self.mode == "available" then
        self:startAvailabilityScan(force)
        return self.availableItems or {}
    end

    local results = {}
    for _, item in ipairs(self:craftItems(force)) do
        table.insert(results, item)
    end
    for _, item in ipairs(self:buildItems(force)) do
        table.insert(results, item)
    end
    return results
end

function HubPanel:resolveItemSource(item)
    if not item then return nil, nil end
    if item.sourceResolved then
        return item.source, item.sourceKey
    end
    if item.kind == "craft" and BCR_RecipeIndex.sourceForItem then
        return BCR_RecipeIndex.sourceForItem(item)
    end
    if item.kind == "build" and BCR_BuildIndex.sourceForItem then
        return BCR_BuildIndex.sourceForItem(item)
    end
    return item.source, item.sourceKey
end

function HubPanel:sourceFilterOptions(force)
    if self.sourceFilterOptionsCache and self.sourceFilterOptionsCacheMode == self.mode and not force then
        return self.sourceFilterOptionsCache
    end

    local byKey = {}
    for _, item in ipairs(self:sourceFilterSourceItems(force)) do
        local source, key = self:resolveItemSource(item)
        if key and key ~= "" and not isVanillaSource(source) then
            if not byKey[key] then
                byKey[key] = { key = key, label = source, count = 0 }
            end
            byKey[key].count = byKey[key].count + 1
        end
    end

    local options = {}
    for _, option in pairs(byKey) do
        table.insert(options, option)
    end
    table.sort(options, function(a, b)
        local left = BCR_Utils.lower(a and a.label or "")
        local right = BCR_Utils.lower(b and b.label or "")
        if left ~= right then return left < right end
        return (a and a.key or "") < (b and b.key or "")
    end)
    self.sourceFilterOptionsCache = options
    self.sourceFilterOptionsCacheMode = self.mode
    return options
end

function HubPanel:filterModes()
    local modes = {}
    for _, mode in ipairs(BASE_FILTER_MODES) do
        table.insert(modes, mode)
    end

    self.sourceFilterLabels = {}
    for _, source in ipairs(self:sourceFilterOptions(false)) do
        self.sourceFilterLabels[source.key] = source.label
        table.insert(modes, sourceFilterMode(source.key))
    end
    return modes
end

function HubPanel:invalidateSourceCache(reason)
    self.sourceItemsCache = nil
    self.sourceItemsCacheMode = nil
    self.sourceItemsCacheGeneration = nil
    self.sourceFilterOptionsCache = nil
    self.sourceFilterOptionsCacheMode = nil
    if reason then
        BCR_Debug.log("Hub source cache invalidated: " .. tostring(reason))
    end
end

function HubPanel:setDetailLines(lines)
    self.detailLines = lines or {}
    self.wrappedDetailLines = nil
    self.wrappedDetailWidth = 0
    self.wrappedDetailFont = nil
end

function HubPanel:wrappedDetailLinesFor(maxWidth)
    local m = self.metrics or makeMetrics()
    if self.wrappedDetailLines and self.wrappedDetailWidth == maxWidth and self.wrappedDetailFont == m.font then
        return self.wrappedDetailLines
    end

    local wrappedLines = {}
    for _, line in ipairs(self.detailLines or {}) do
        local color = detailColorFor(line)
        for _, wrapped in ipairs(wrapText(m.font, line, maxWidth)) do
            table.insert(wrappedLines, { text = wrapped, color = color })
        end
    end
    self.wrappedDetailLines = wrappedLines
    self.wrappedDetailWidth = maxWidth
    self.wrappedDetailFont = m.font
    return wrappedLines
end

function HubPanel:queueSearchRefresh()
    local now = BCR_Utils.nowMs()
    self.searchPending = true
    self.searchRefreshAt = now > 0 and (now + SEARCH_DEBOUNCE_MS) or 0
    self.deepSearchQueue = nil
    self.deepSearchQueueIndex = 1
    self.deepSearchQueryKey = nil
    self.deepSearchComplete = true
    self.lastDeepSearchResultsRefresh = 0
end

function HubPanel:processPendingSearch()
    if not self.searchPending then return end
    local now = BCR_Utils.nowMs()
    if now > 0 and self.searchRefreshAt and now < self.searchRefreshAt then
        return
    end
    self.searchPending = false
    self:refreshResults(false, true)
end

function HubPanel:stopDeepSearchScan()
    self.deepSearchQueue = nil
    self.deepSearchQueueIndex = 1
    self.deepSearchQueryKey = nil
    self.deepSearchComplete = true
    self.lastDeepSearchResultsRefresh = 0
end

function HubPanel:layoutChildren()
    local m = self.metrics or makeMetrics()
    if self.closeBtn then
        self.closeBtn:setX(self.width - m.pad - m.closeW)
        self.closeBtn:setWidth(m.closeW)
        self.closeBtn:setHeight(m.buttonH)
        self.closeBtn.font = m.font
    end
    if self.minimizeBtn then
        self.minimizeBtn:setX(self.width - m.pad - m.closeW - m.collapseW - scalePx(4))
        self.minimizeBtn:setWidth(m.collapseW)
        self.minimizeBtn:setHeight(m.buttonH)
        self.minimizeBtn.font = m.font
        self.minimizeBtn:setTitle(self.collapsed and BCR_Utils.tr("UI_BCR_Expand", "Expand") or BCR_Utils.tr("UI_BCR_Collapse", "Collapse"))
    end
    if self.refreshBtn then
        self.refreshBtn:setX(self.width - m.pad - m.refreshW)
        self.refreshBtn:setY(m.headerH + scalePx(5))
        self.refreshBtn:setWidth(m.refreshW)
        self.refreshBtn:setHeight(m.buttonH)
        self.refreshBtn.font = m.font
    end
    local tabY = m.headerH + scalePx(5)
    local tabStep = m.tabW + m.tabGap
    local tabs = { self.availableBtn, self.craftBtn, self.buildBtn, self.favoritesBtn, self.recentBtn }
    for index, tab in ipairs(tabs) do
        if tab then
            tab:setX(m.pad + tabStep * (index - 1))
            tab:setY(tabY)
            tab:setWidth(m.tabW)
            tab:setHeight(m.buttonH)
            tab.font = m.font
        end
    end
    if self.searchEntry then
        local gap = scalePx(6)
        local searchX = m.pad + m.categoryW + scalePx(8)
        self.searchEntry:setY(m.headerH + m.toolbarH + scalePx(6))
        self.searchEntry:setX(searchX)
        self.searchEntry:setWidth(math.max(scalePx(110), self:mainListWidth() - m.sortW - m.filterW - m.pageW * 2 - gap * 5))
        self.searchEntry:setHeight(m.buttonH)
        if self.sortBtn then
            self.sortBtn:setX(self.searchEntry:getRight() + gap)
            self.sortBtn:setY(self.searchEntry:getY())
            self.sortBtn:setWidth(m.sortW)
            self.sortBtn:setHeight(m.buttonH)
            self.sortBtn.font = m.font
            self.sortBtn:setTitle(sortModeLabel(self.sortMode))
        end
        if self.filterBtn then
            self.filterBtn:setX(self.sortBtn and (self.sortBtn:getRight() + gap) or (self.searchEntry:getRight() + gap))
            self.filterBtn:setY(self.searchEntry:getY())
            self.filterBtn:setWidth(m.filterW)
            self.filterBtn:setHeight(m.buttonH)
            self.filterBtn.font = m.font
            self.filterBtn:setTitle(ellipsize(m.font, self:filterModeTitle(), m.filterW - scalePx(8)))
        end
        if self.pagePrevBtn then
            self.pagePrevBtn:setX(self.filterBtn and (self.filterBtn:getRight() + gap) or (self.searchEntry:getRight() + gap))
            self.pagePrevBtn:setY(self.searchEntry:getY())
            self.pagePrevBtn:setWidth(m.pageW)
            self.pagePrevBtn:setHeight(m.buttonH)
            self.pagePrevBtn.font = m.font
        end
        if self.pageNextBtn then
            self.pageNextBtn:setX(self.pagePrevBtn and (self.pagePrevBtn:getRight() + gap) or (self.searchEntry:getRight() + gap))
            self.pageNextBtn:setY(self.searchEntry:getY())
            self.pageNextBtn:setWidth(m.pageW)
            self.pageNextBtn:setHeight(m.buttonH)
            self.pageNextBtn.font = m.font
        end
    end
    self:layoutCategoryTabs()
    local listY = self:listY()
    if self.categoryList then
        self.categoryList:setX(m.pad)
        self.categoryList:setY(listY)
        self.categoryList:setWidth(m.categoryW)
        self.categoryList:setHeight(math.max(scalePx(130), self.height - listY - m.pad))
        self.categoryList.itemheight = m.categoryH
        self.categoryList.font = m.font
        self.categoryList.bcrMetrics = m
    end
    if self.resultList then
        self.resultList:setX(m.pad + m.categoryW + scalePx(8))
        self.resultList:setY(listY)
        self.resultList:setWidth(self:mainListWidth())
        self.resultList:setHeight(math.max(m.resultH, self.height - listY - m.pad))
        self.resultList.itemheight = m.resultH
        self.resultList.font = m.font
        self.resultList.bcrMetrics = m
    end
    local detailsX, _, detailsW = self:detailsRect()
    local actionGap = scalePx(6)
    local actionButtonW = math.floor((detailsW - m.pad * 2 - actionGap * 3) / 4)
    local actionButtonH = math.max(m.buttonH, scalePx(28))
    local actionButtons = {
        self.actionBtn,
        self.areaScanBtn,
        self.favoriteToggleBtn,
        self.repeatBtn,
    }
    for index, btn in ipairs(actionButtons) do
        if btn then
            btn:setX(detailsX + m.pad + (actionButtonW + actionGap) * (index - 1))
            btn:setY(self:detailsActionY())
            btn:setWidth(actionButtonW)
            btn:setHeight(actionButtonH)
            btn.font = m.font
        end
    end
    self:updateButtonState()
    self:updateContentVisibility()
end

function HubPanel:layoutCategoryTabs()
    local m = self.metrics or makeMetrics()
    local buttons = self.categoryTabButtons or {}
    local categories = self.categoryItems or {}
    local visible = not self.collapsed and #categories > 0 and self.searchEntry ~= nil

    if not visible then
        setChildVisible(self.categoryPrevBtn, false)
        setChildVisible(self.categoryNextBtn, false)
        for _, btn in ipairs(buttons) do
            setChildVisible(btn, false)
        end
        return
    end

    local areaX = m.pad + m.categoryW + scalePx(8)
    local areaY = self:categoryTabsY()
    local areaW = self:mainListWidth()
    local pagerW = m.categoryPagerW
    local gap = m.categoryTabGap
    local tabX = areaX + pagerW + gap
    local maxX = areaX + areaW - pagerW - gap

    self.categoryTabOffset = math.max(1, math.min(self.categoryTabOffset or 1, #categories))
    local selectedIndex = 1
    for index, category in ipairs(categories) do
        if category.key == self.categoryKey then
            selectedIndex = index
            break
        end
    end
    if selectedIndex < self.categoryTabOffset then
        self.categoryTabOffset = selectedIndex
    end

    if self.categoryPrevBtn then
        self.categoryPrevBtn:setX(areaX)
        self.categoryPrevBtn:setY(areaY)
        self.categoryPrevBtn:setWidth(pagerW)
        self.categoryPrevBtn:setHeight(m.categoryTabH)
        self.categoryPrevBtn.font = m.font
        setChildVisible(self.categoryPrevBtn, true)
        setButtonEnabled(self.categoryPrevBtn, self.categoryTabOffset > 1)
        applyButtonColor(self.categoryPrevBtn, self.categoryTabOffset > 1 and COLORS.button or COLORS.disabled)
    end
    if self.categoryNextBtn then
        self.categoryNextBtn:setX(areaX + areaW - pagerW)
        self.categoryNextBtn:setY(areaY)
        self.categoryNextBtn:setWidth(pagerW)
        self.categoryNextBtn:setHeight(m.categoryTabH)
        self.categoryNextBtn.font = m.font
        setChildVisible(self.categoryNextBtn, true)
    end

    local buttonIndex = 1
    local categoryIndex = self.categoryTabOffset
    while categoryIndex <= #categories and buttonIndex <= #buttons do
        local category = categories[categoryIndex]
        local label = category.label
        local countText = category.count and category.count > 0 and (" " .. tostring(category.count)) or ""
        local rawTitle = label .. countText
        local desiredW = math.min(scalePx(132), math.max(scalePx(58), textWidth(m.font, rawTitle) + scalePx(18)))
        if tabX + desiredW > maxX and buttonIndex > 1 then
            break
        end
        desiredW = math.min(desiredW, math.max(scalePx(48), maxX - tabX))
        if desiredW < scalePx(48) then
            break
        end

        local btn = buttons[buttonIndex]
        btn.categoryKey = category.key
        btn:setX(tabX)
        btn:setY(areaY)
        btn:setWidth(desiredW)
        btn:setHeight(m.categoryTabH)
        btn.font = m.font
        btn:setTitle(ellipsize(m.font, rawTitle, desiredW - scalePx(10)))
        if btn.setTooltip then
            btn:setTooltip(label .. " (" .. tostring(category.count or 0) .. ")")
        end
        setChildVisible(btn, true)
        applyButtonColor(btn, category.key == self.categoryKey and COLORS.active or COLORS.button)

        tabX = tabX + desiredW + gap
        buttonIndex = buttonIndex + 1
        categoryIndex = categoryIndex + 1
    end

    for index = buttonIndex, #buttons do
        buttons[index].categoryKey = nil
        setChildVisible(buttons[index], false)
    end

    self.categoryTabEndIndex = math.max(self.categoryTabOffset, categoryIndex - 1)
    local canNext = self.categoryTabEndIndex < #categories
    setButtonEnabled(self.categoryNextBtn, canNext)
    applyButtonColor(self.categoryNextBtn, canNext and COLORS.button or COLORS.disabled)
end

function HubPanel:updateContentVisibility()
    local visible = not self.collapsed
    local alwaysVisibleWhenExpanded = {
        self.refreshBtn,
        self.availableBtn,
        self.craftBtn,
        self.buildBtn,
        self.favoritesBtn,
        self.recentBtn,
        self.searchEntry,
        self.sortBtn,
        self.filterBtn,
        self.pagePrevBtn,
        self.pageNextBtn,
        self.categoryList,
        self.resultList,
        self.areaScanBtn,
    }
    for _, child in ipairs(alwaysVisibleWhenExpanded) do
        setChildVisible(child, visible)
    end

    if not visible then
        local contextualChildren = {
            self.actionBtn,
            self.favoriteToggleBtn,
            self.repeatBtn,
            self.areaScanBtn,
        }
        for _, child in ipairs(contextualChildren) do
            setChildVisible(child, false)
        end
    end

    if visible then
        self:layoutCategoryTabs()
    else
        setChildVisible(self.categoryPrevBtn, false)
        setChildVisible(self.categoryNextBtn, false)
        for _, btn in ipairs(self.categoryTabButtons or {}) do
            setChildVisible(btn, false)
        end
    end

    setChildVisible(self.closeBtn, true)
    setChildVisible(self.minimizeBtn, true)
end

function HubPanel:needsAvailability()
    return self.mode == "available" or availabilityFilterActive(self.filterMode)
end

function HubPanel:isAreaScanValid(player)
    if not self.areaContainers or not self.areaScanOrigin then return false end
    player = player or (getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer())
    if not player then return false end
    local origin = self.areaScanOrigin
    local px = player.getX and math.floor(tonumber(player:getX()) or 0) or origin.x
    local py = player.getY and math.floor(tonumber(player:getY()) or 0) or origin.y
    local pz = player.getZ and math.floor(tonumber(player:getZ()) or 0) or origin.z
    if pz ~= origin.z then return false end
    local maxDelta = (origin.radius or 0) + AREA_SCAN_STALE_MARGIN
    return math.abs(px - origin.x) <= maxDelta and math.abs(py - origin.y) <= maxDelta
end

function HubPanel:containersForCurrentScope(player)
    player = player or (getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer())
    if self:isAreaScanValid(player) then
        return self.areaContainers
    end
    if BCR_ContainerSearch and BCR_ContainerSearch.getVisibleContainers then
        return BCR_ContainerSearch.getVisibleContainers(player)
    end
    if BCR_ContainerSearch and BCR_ContainerSearch.getContainers then
        return BCR_ContainerSearch.getContainers(player)
    end
    if player and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getContainers then
        return ISInventoryPaneContextMenu.getContainers(player)
    end
    return nil
end

function HubPanel:updateAreaScanButton()
    if not self.areaScanBtn then return end
    if self.collapsed then
        self.areaScanBtn:setVisible(false)
        return
    end
    local player = getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
    local valid = self:isAreaScanValid(player)
    local label = BCR_Utils.tr("UI_BCR_AreaScan", "Scan Area")
    if self.areaContainers then
        if valid then
            label = BCR_Utils.format(BCR_Utils.tr("UI_BCR_AreaScanActive", "Area: %1"), self.areaContainerCount or 0)
        else
            label = BCR_Utils.tr("UI_BCR_AreaScanStaleButton", "Rescan Area")
        end
    end
    self.areaScanBtn:setTitle(ellipsize(self.metrics and self.metrics.font or UIFont.Small, label, (self.areaScanBtn:getWidth() or scalePx(92)) - scalePx(8)))
    applyButtonColor(self.areaScanBtn, valid and COLORS.ready or COLORS.info)
end

function HubPanel:resultPageSize()
    local m = self.metrics or makeMetrics()
    local height = self.resultList and self.resultList:getHeight() or (m.resultH * RESULT_PAGE_SIZE)
    return math.max(1, math.floor(height / math.max(1, m.resultH)))
end

function HubPanel:maxResultPage(totalItems)
    local total = tonumber(totalItems)
    if total == nil then total = self.totalFilteredItems or 0 end
    return math.max(1, math.ceil(total / self:resultPageSize()))
end

function HubPanel:resultRangeText()
    local text = BCR_Utils.format(
        BCR_Utils.tr("UI_BCR_ResultRange", "%1-%2 of %3 | Page %4/%5"),
        self.pageStartIndex or 0,
        self.pageEndIndex or 0,
        self.totalFilteredItems or 0,
        self.resultPage or 1,
        self:maxResultPage()
    )
    if queryLongEnoughForDeepSearch(self.searchText) and not self.deepSearchComplete then
        text = text .. " | " .. BCR_Utils.tr("UI_BCR_SearchingInputs", "Searching inputs...")
    end
    return text
end

function HubPanel:updatePageButtons()
    local maxPage = self:maxResultPage()
    local canPrev = (self.resultPage or 1) > 1
    local canNext = (self.resultPage or 1) < maxPage
    if self.pagePrevBtn then
        setButtonEnabled(self.pagePrevBtn, canPrev)
        applyButtonColor(self.pagePrevBtn, canPrev and COLORS.button or COLORS.disabled)
        if self.pagePrevBtn.setTooltip then self.pagePrevBtn:setTooltip(self:resultRangeText()) end
    end
    if self.pageNextBtn then
        setButtonEnabled(self.pageNextBtn, canNext)
        applyButtonColor(self.pageNextBtn, canNext and COLORS.button or COLORS.disabled)
        if self.pageNextBtn.setTooltip then self.pageNextBtn:setTooltip(self:resultRangeText()) end
    end
end

function HubPanel:updateButtonState()
    if self.availableBtn then applyButtonColor(self.availableBtn, self.mode == "available" and COLORS.toolbarActive or COLORS.toolbarButton) end
    if self.craftBtn then applyButtonColor(self.craftBtn, self.mode == "craft" and COLORS.toolbarActive or COLORS.toolbarButton) end
    if self.buildBtn then applyButtonColor(self.buildBtn, self.mode == "build" and COLORS.toolbarActive or COLORS.toolbarButton) end
    if self.favoritesBtn then applyButtonColor(self.favoritesBtn, self.mode == "favorites" and COLORS.toolbarActive or COLORS.toolbarButton) end
    if self.recentBtn then applyButtonColor(self.recentBtn, self.mode == "recent" and COLORS.toolbarActive or COLORS.toolbarButton) end
    if self.refreshBtn then applyButtonColor(self.refreshBtn, COLORS.toolbarButton) end
    if self.sortBtn then
        self.sortBtn:setTitle(sortModeLabel(self.sortMode))
        applyButtonColor(self.sortBtn, self.sortMode ~= "name_az" and COLORS.favoriteButton or COLORS.button)
    end
    if self.filterBtn then
        self.filterBtn:setTitle(ellipsize(self.metrics and self.metrics.font or UIFont.Small, self:filterModeTitle(), (self.metrics and self.metrics.filterW or scalePx(96)) - scalePx(8)))
        applyButtonColor(self.filterBtn, self.filterMode ~= "all" and COLORS.warning or COLORS.button)
    end
    self:updatePageButtons()
    self:updateAreaScanButton()
    self:updateFavoriteButton()
    self:updateActionButton()
    self:updateRepeatButton()
    self:updateContentVisibility()
end

function HubPanel:onClose()
    local saveWidth = self.collapsed and math.max(minWindowWidth(), self.expandedWidth or self.width) or self.width
    local saveHeight = self.collapsed and math.max(minWindowHeight(), self.expandedHeight or self.height) or self.height
    BCR_UserData.setHubLayout(self.playerIndex, self:getX(), self:getY(), saveWidth, saveHeight)
    self:setVisible(false)
    BCR_HubWindow.isVisible = false
end

function HubPanel:sendCollapsedBehindUI()
    if not self.collapsed or not self.javaObject or not UIManager or not UIManager.getUI then
        return false
    end

    local uiList = UIManager.getUI()
    if not uiList or not uiList.remove or not uiList.add then
        return false
    end

    local count = BCR_Utils.listSize(uiList)
    local foundIndex = nil
    for index = 0, count - 1 do
        if BCR_Utils.listGet(uiList, index) == self.javaObject then
            foundIndex = index
            break
        end
    end
    if not foundIndex or foundIndex == 0 then
        return foundIndex == 0
    end

    uiList:remove(foundIndex)
    uiList:add(0, self.javaObject)
    return true
end

function HubPanel:bringInventoryWindowsForward()
    local playerIndex = self.playerIndex or 0
    local windows = {}
    if getPlayerInventory then
        table.insert(windows, getPlayerInventory(playerIndex))
    end
    if getPlayerLoot then
        table.insert(windows, getPlayerLoot(playerIndex))
    end

    for _, window in ipairs(windows) do
        if window and window ~= self and window.bringToTop then
            local visible = true
            if window.getIsVisible then
                visible = window:getIsVisible()
            end
            if visible then
                window:bringToTop()
            end
        end
    end
end

function HubPanel:fallBackCollapsedLayer()
    if not self.collapsed then return end
    self:sendCollapsedBehindUI()
    self:bringInventoryWindowsForward()
end

function HubPanel:setCollapsed(collapsed)
    local shouldCollapse = collapsed == true
    if self.collapsed == shouldCollapse then return end
    local m = self.metrics or makeMetrics()
    if shouldCollapse then
        self.expandedWidth = math.max(minWindowWidth(), self.width)
        self.expandedHeight = math.max(minWindowHeight(), self.height)
        self.collapsed = true
        self.resizing = false
        self:setWidth(m.collapsedW)
        self:setHeight(m.headerH + scalePx(6))
    else
        local restoreW, restoreH = clampWindowSize(self.expandedWidth or m.defaultW, self.expandedHeight or m.defaultH)
        self.collapsed = false
        self:setWidth(restoreW)
        self:setHeight(restoreH)
    end
    local nx, ny = BCR_Utils.clampToScreen(self:getX(), self:getY(), self.width, self.height)
    self:setX(nx)
    self:setY(ny)
    self:layoutChildren()
    if self.collapsed then
        self:fallBackCollapsedLayer()
    elseif self.bringToTop then
        self:bringToTop()
    end
end

function HubPanel:onMinimize()
    self.placementCollapseEntity = nil
    self.placementCollapseShouldRestore = false
    self:setCollapsed(not self.collapsed)
end

function HubPanel:startPlacementCollapse(buildEntity)
    if not buildEntity then return end
    self.placementCollapseEntity = buildEntity
    self.placementCollapseShouldRestore = not self.collapsed
    self:setCollapsed(true)
end

function HubPanel:currentDragEntity()
    local cell = getCell and getCell() or nil
    if not cell or not cell.getDrag then return nil end
    return cell:getDrag(self.playerIndex or 0)
end

function HubPanel:updatePlacementCollapse()
    if not self.placementCollapseEntity then return end
    if self:currentDragEntity() == self.placementCollapseEntity then return end

    local shouldRestore = self.placementCollapseShouldRestore
    self.placementCollapseEntity = nil
    self.placementCollapseShouldRestore = false
    if shouldRestore and self.getIsVisible and self:getIsVisible() then
        self:setCollapsed(false)
        self:bringToTop()
    end
end

function HubPanel:onAreaScan()
    local player = getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
    if not player or not BCR_ContainerSearch or not BCR_ContainerSearch.scanAreaContainers then
        self.areaScanMessage = BCR_Utils.tr("UI_BCR_AreaScanFailed", "Area scan unavailable.")
        self.lastActionMessage = self.areaScanMessage
        return
    end

    local containers = BCR_ContainerSearch.scanAreaContainers(player)
    local count = BCR_ContainerSearch.count and BCR_ContainerSearch.count(containers) or 0
    local square = player.getCurrentSquare and player:getCurrentSquare() or nil
    self.areaContainers = containers
    self.areaContainerCount = count
    self.areaScanOrigin = {
        x = square and square:getX() or math.floor(tonumber(player:getX()) or 0),
        y = square and square:getY() or math.floor(tonumber(player:getY()) or 0),
        z = square and square:getZ() or math.floor(tonumber(player:getZ()) or 0),
        radius = BCR_ContainerSearch.radius and BCR_ContainerSearch.radius() or 0,
    }
    self.areaScanMessage = BCR_Utils.format(BCR_Utils.tr("UI_BCR_AreaScanComplete", "Area scan found %1 containers."), count)
    self.lastActionMessage = self.areaScanMessage
    self:clearAvailabilityState()
    self:refreshAll(false, true)
    self:updateButtonState()
end

function HubPanel:setResultPage(page)
    local nextPage = math.max(1, math.min(tonumber(page) or 1, self:maxResultPage()))
    if nextPage == (self.resultPage or 1) then return false end
    self.resultPage = nextPage
    self:populateResultPage(false, true)
    return true
end

function HubPanel:onResultPagePrev()
    return self:setResultPage((self.resultPage or 1) - 1)
end

function HubPanel:onResultPageNext()
    return self:setResultPage((self.resultPage or 1) + 1)
end

function HubPanel.onResultListMouseWheel(list, del)
    local panel = list and list.target or nil
    if not panel or not del or del == 0 then return false end
    if del > 0 then
        panel:onResultPageNext()
    else
        panel:onResultPagePrev()
    end
    return true
end

function HubPanel:onModeButton(btn)
    if not btn or not btn.mode then return end
    if self.mode == btn.mode then return end
    self.mode = btn.mode
    self.categoryKey = nil
    self.categoryTabOffset = 1
    self.resultPage = 1
    self.selectedItem = nil
    self:setDetailLines({})
    self:clearAvailabilityState()
    self:stopDeepSearchScan()
    self:refreshAll(false)
    self:updateButtonState()
end

function HubPanel:onSortButton()
    self.sortMode = nextModeValue(SORT_MODES, self.sortMode)
    self.resultPage = 1
    self:refreshResults(false, true)
    self:updateButtonState()
end

function HubPanel:onFilterButton()
    self.filterMode = nextModeValue(self:filterModes(), self.filterMode)
    self.categoryKey = nil
    self.categoryTabOffset = 1
    self.resultPage = 1
    if availabilityFilterActive(self.filterMode) then
        self:startAvailabilityScan(false)
    end
    self:stopDeepSearchScan()
    self:refreshAll(false, true)
    self:updateButtonState()
end

function HubPanel:setMode(mode)
    mode = mode or "all"
    if self.mode == mode then return end
    self.mode = mode
    self.categoryKey = nil
    self.categoryTabOffset = 1
    self.resultPage = 1
    self.selectedItem = nil
    self:setDetailLines({})
    self:clearAvailabilityState()
    self:stopDeepSearchScan()
    self:refreshAll(false)
    self:updateButtonState()
end

function HubPanel:onRefresh()
    self:markDirty("manual")
    self:clearAvailabilityState()
    self.resultPage = 1
    self.sourceFilterOptionsCache = nil
    self.sourceFilterOptionsCacheMode = nil
    self.sourceFilterLabels = {}
    if BCR_IconResolver and BCR_IconResolver.invalidate then
        BCR_IconResolver.invalidate("manual-refresh")
    end
    self:stopDeepSearchScan()
    self:refreshAll(true, true)
end

function HubPanel:resetToHome()
    self.mode = "all"
    self.categoryKey = nil
    self.categoryTabOffset = 1
    self.resultPage = 1
    self.selectedItem = nil
    self.searchText = ""
    self:setDetailLines({})
    self:clearOpenContext()
    self:clearAvailabilityState()
    self:stopDeepSearchScan()
    if self.searchEntry then
        self.suppressSearchChange = true
        self.searchEntry:setText("")
        self.suppressSearchChange = false
    end
    self:refreshAll(false)
    self:updateButtonState()
end

function HubPanel:markDirty(reason)
    self.liveDirty = true
    self.liveReason = reason or "changed"
end

function HubPanel:refreshLive(force)
    if self.getIsVisible and not self:getIsVisible() then return end
    local now = BCR_Utils.nowMs()
    if not force and now > 0 and (now - (self.lastLiveCheck or 0)) < LIVE_REFRESH_MS then
        return
    end
    self.lastLiveCheck = now

    local player = getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
    local squareSignature = playerSquareSignature(player)
    if self.lastSquareSignature == "" then
        self.lastSquareSignature = squareSignature
    elseif squareSignature ~= self.lastSquareSignature then
        self.lastSquareSignature = squareSignature
        if self:needsAvailability() then
            self:markDirty("move")
        else
            self:updateAreaScanButton()
        end
    end

    if not force and not self.liveDirty then
        return
    end

    self.liveDirty = false
    self.liveReason = nil
    self.lastLiveSignature = squareSignature
    self.lastLiveRefresh = now
    if self:needsAvailability() or self:isAreaScanValid(player) then
        self:clearAvailabilityState()
        self:refreshAll(false, true)
    else
        self:updateActionButton()
        self:updateAreaScanButton()
    end
end

function HubPanel:updateFavoriteButton()
    if not self.favoriteToggleBtn then return end
    if self.collapsed then
        self.favoriteToggleBtn:setVisible(false)
        return
    end
    if not self.selectedItem then
        self.favoriteToggleBtn:setVisible(false)
        return
    end
    self.favoriteToggleBtn:setVisible(true)
    local isFavorite = BCR_UserData.isFavorite(self.selectedItem, self.playerIndex)
    self.favoriteToggleBtn:setTitle(isFavorite and BCR_Utils.tr("UI_BCR_Unfavorite", "Unfavorite") or BCR_Utils.tr("UI_BCR_Favorite", "Favorite"))
    applyButtonColor(self.favoriteToggleBtn, isFavorite and COLORS.warning or COLORS.favoriteButton)
end

local function setButtonEnabled(button, enabled)
    if not button then return end
    button.bcrEnabled = enabled == true
    if button.setEnable then
        button:setEnable(enabled == true)
    else
        button.enable = enabled == true
    end
    if not enabled then
        applyButtonColor(button, COLORS.disabled)
    end
end

function HubPanel:updateActionButton()
    if not self.actionBtn then return end
    if self.collapsed then
        self.actionBtn:setVisible(false)
        return
    end
    if not self.selectedItem then
        self.actionBtn:setVisible(false)
        return
    end

    self.actionBtn:setVisible(true)
    if self.selectedItem.kind == "build" then
        self.actionBtn:setTitle(BCR_Utils.tr("UI_BCR_ActionPlace", "Place"))
    else
        self.actionBtn:setTitle(BCR_Utils.tr("UI_BCR_ActionMake", "Make"))
    end

    local status = self:statusForItem(self.selectedItem)
    local canAct = not status or status.available ~= false
    setButtonEnabled(self.actionBtn, canAct)
    if canAct then
        applyButtonColor(self.actionBtn, COLORS.primaryButton)
    else
        applyButtonColor(self.actionBtn, COLORS.disabled)
    end
end

function HubPanel:itemForKey(key, allowStart)
    if not key then return nil end
    local craftItems = allowStart == false and indexPeek(BCR_RecipeIndex) or self:craftItems(false)
    for _, item in ipairs(craftItems) do
        if item.key == key then return item end
    end
    local buildItems = allowStart == false and indexPeek(BCR_BuildIndex) or self:buildItems(false)
    for _, item in ipairs(buildItems) do
        if item.key == key then return item end
    end
    return nil
end

function HubPanel:updateRepeatButton()
    if not self.repeatBtn then return end
    if self.collapsed then
        self.repeatBtn:setVisible(false)
        return
    end
    local item = self:itemForKey(BCR_UserData.lastActionKey(self.playerIndex), false)
    self.repeatBtn:setVisible(item ~= nil)
    if item then
        setButtonEnabled(self.repeatBtn, true)
        applyButtonColor(self.repeatBtn, COLORS.repeatButton)
    end
end

function HubPanel:onFavoriteToggle()
    if not self.selectedItem then return end
    BCR_UserData.toggleFavorite(self.selectedItem, self.playerIndex)
    self:invalidateSourceCache("favorite")
    self:updateFavoriteButton()
    if self.mode == "favorites" then
        self:refreshAll(false)
    end
end

function HubPanel:onPrimaryAction()
    if not self.selectedItem or not BCR_Actions or not BCR_Actions.perform then return end
    if self.actionBtn and self.actionBtn.bcrEnabled == false then return end
    local player = getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
    if not player then return end

    local result = BCR_Actions.perform(self.playerIndex, self.selectedItem, {
        isoObject = self.contextIsoObject,
        queryOverride = self.contextQueryOverride,
        ignoreFindSurface = self.contextIgnoreFindSurface,
        inventoryItem = self.contextInventoryItem,
        recipe = self.contextRecipe,
        containers = self:containersForCurrentScope(player),
    })
    self.lastActionMessage = result and result.message or nil
    if result and result.ok then
        BCR_UserData.addRecent(self.selectedItem, self.playerIndex)
        BCR_UserData.setLastAction(self.selectedItem, self.playerIndex)
        self:invalidateSourceCache("recent")
        if self.selectedItem.kind == "build" and result.buildEntity then
            self:startPlacementCollapse(result.buildEntity)
        end
    end
    self:clearAvailabilityState()
    self:setDetailLines(self:detailLinesFor(self.selectedItem, player, self:statusForItem(self.selectedItem)))
    self:updateActionButton()
    self:updateRepeatButton()
end

function HubPanel:onRepeatAction()
    local item = self:itemForKey(BCR_UserData.lastActionKey(self.playerIndex))
    if not item then return end
    self.selectedItem = item
    self.contextInventoryItem = nil
    self.contextRecipe = nil
    self:onPrimaryAction()
end

function HubPanel.onSearchTextChange(box)
    if not box or not box.target then return end
    if box.target.suppressSearchChange then return end
    box.target.searchText = box:getInternalText()
    box.target.resultPage = 1
    box.target:queueSearchRefresh()
end

function HubPanel:onCategorySelected(item)
    if not item or not item.key then return end
    self.categoryKey = item.key
    self.categoryTabOffset = self:categoryIndexForKey(item.key) or self.categoryTabOffset or 1
    self.resultPage = 1
    self.selectedItem = nil
    self:setDetailLines({})
    self:stopDeepSearchScan()
    self:refreshResults(false)
    self:layoutCategoryTabs()
end

function HubPanel:categoryIndexForKey(key)
    for index, category in ipairs(self.categoryItems or {}) do
        if category.key == key then
            return index
        end
    end
    return nil
end

function HubPanel:onCategoryTabButton(btn)
    if not btn or not btn.categoryKey then return end
    self.categoryKey = btn.categoryKey
    self.resultPage = 1
    self.selectedItem = nil
    self:setDetailLines({})
    self:stopDeepSearchScan()
    self:refreshResults(false)
    self:layoutCategoryTabs()
end

function HubPanel:onCategoryTabsPrev()
    self.categoryTabOffset = math.max(1, (self.categoryTabOffset or 1) - CATEGORY_TAB_PAGE_STEP)
    self:layoutCategoryTabs()
end

function HubPanel:onCategoryTabsNext()
    local categories = self.categoryItems or {}
    local nextOffset = math.min(#categories, (self.categoryTabEndIndex or self.categoryTabOffset or 1) + 1)
    if nextOffset > 0 then
        self.categoryTabOffset = nextOffset
    end
    self:layoutCategoryTabs()
end

function HubPanel:onResultSelected(item)
    self.selectedItem = item
    if item and not self.suppressRecent then
        BCR_UserData.addRecent(item, self.playerIndex)
    end
    local player = getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
    local status = self:statusForItem(item)
    self:setDetailLines(self:detailLinesFor(item, player, status))
    self:updateFavoriteButton()
    self:updateActionButton()
    self:updateRepeatButton()
end

function HubPanel:detailLinesFor(item, player, status)
    local lines = {}
    if item and item.kind == "craft" then
        lines = BCR_RecipeIndex.describe(item, player, status)
    elseif item and item.kind == "build" then
        lines = BCR_BuildIndex.describe(item, player, status)
    end
    if self.lastActionMessage and self.lastActionMessage ~= "" then
        table.insert(lines, 1, self.lastActionMessage)
    end
    return lines
end

function HubPanel:craftItems(force)
    local items = {}
    if BCR_RecipeIndex and BCR_RecipeIndex.ensureStarted and BCR_RecipeIndex.peek then
        BCR_RecipeIndex.ensureStarted(force == true)
        items = BCR_RecipeIndex.peek() or {}
        self.indexBuildPending = not self:indexesReady()
    elseif BCR_RecipeIndex and BCR_RecipeIndex.build then
        items = BCR_RecipeIndex.build(force) or {}
    end
    self.craftCount = #items
    return items
end

function HubPanel:buildItems(force)
    local items = {}
    if BCR_BuildIndex and BCR_BuildIndex.ensureStarted and BCR_BuildIndex.peek then
        BCR_BuildIndex.ensureStarted(force == true)
        items = BCR_BuildIndex.peek() or {}
        self.indexBuildPending = not self:indexesReady()
    elseif BCR_BuildIndex and BCR_BuildIndex.build then
        items = BCR_BuildIndex.build(force) or {}
    end
    self.buildCount = #items
    return items
end

function HubPanel:indexesReady()
    return indexReady(BCR_RecipeIndex) and indexReady(BCR_BuildIndex)
end

function HubPanel:updateIndexCounts()
    self.craftCount = #(indexPeek(BCR_RecipeIndex) or {})
    self.buildCount = #(indexPeek(BCR_BuildIndex) or {})
    self.indexBuildPending = not self:indexesReady()
end

function HubPanel:processIndexBuild()
    if self.getIsVisible and not self:getIsVisible() then return end

    local processed = 0
    if BCR_RecipeIndex and BCR_RecipeIndex.processBuild and not indexReady(BCR_RecipeIndex) then
        local count = BCR_RecipeIndex.processBuild(INDEX_BATCH_SIZE)
        processed = processed + (tonumber(count) or 0)
    end
    if BCR_BuildIndex and BCR_BuildIndex.processBuild and not indexReady(BCR_BuildIndex) then
        local count = BCR_BuildIndex.processBuild(INDEX_BATCH_SIZE)
        processed = processed + (tonumber(count) or 0)
    end

    local wasPending = self.indexBuildPending == true
    self:updateIndexCounts()
    if processed <= 0 and wasPending == self.indexBuildPending then
        return
    end

    local now = BCR_Utils.nowMs()
    if self.indexBuildPending and now > 0 and (now - (self.lastIndexResultsRefresh or 0)) < INDEX_RESULTS_REFRESH_MS then
        return
    end

    self.lastIndexResultsRefresh = now
    if self.mode == "available" or availabilityFilterActive(self.filterMode) then
        self:clearAvailabilityState()
    else
        self:invalidateSourceCache("index-batch")
    end
    self:refreshAll(false, true)
    self:updateButtonState()
end

function HubPanel:playerAndIsoObject(forAvailable)
    local player = getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
    local isoObject = self.contextIsoObject
    if not isoObject and forAvailable and ISEntityUI and ISEntityUI.FindCraftSurface and not self.contextIgnoreFindSurface then
        isoObject = ISEntityUI.FindCraftSurface(player, 1)
    end
    return player, isoObject
end

function HubPanel:clearAvailabilityState()
    self.availability = nil
    self.statusCache = {}
    self.availableItems = {}
    self.availabilityQueue = nil
    self.availabilityQueueIndex = 1
    self.availabilityContext = nil
    self.availabilityScanComplete = false
    self.lastAvailableResultsRefresh = 0
    self:invalidateSourceCache("availability")
end

function HubPanel:startAvailabilityScan(force)
    if self.availabilityQueue and not force then return end
    if self.availabilityScanComplete and not force then return end

    local startedAt = BCR_Utils.nowMs()
    local player, isoObject = self:playerAndIsoObject(true)
    local containers = self:containersForCurrentScope(player)
    local queue = {}
    for _, item in ipairs(self:craftItems(force)) do
        table.insert(queue, item)
    end
    for _, item in ipairs(self:buildItems(force)) do
        table.insert(queue, item)
    end

    self.statusCache = {}
    self.availableItems = {}
    self.availabilityQueue = queue
    self.availabilityQueueIndex = 1
    self.availabilityContext = BCR_Availability.newContext(player, isoObject, containers)
    self.availabilityScanComplete = #queue == 0
    self.lastAvailableResultsRefresh = 0
    self:invalidateSourceCache("availability-start")
    BCR_Debug.timing("Availability scan start", startedAt, "(" .. tostring(#queue) .. " rows)")
end

function HubPanel:processAvailabilityScan()
    if self.mode ~= "available" and not availabilityFilterActive(self.filterMode) then return end
    if not self.availabilityQueue then return end
    local player = getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
    if not player then return end

    local startedAt = BCR_Utils.nowMs()
    local changed = false
    local processed = 0
    while self.availabilityQueue and self.availabilityQueueIndex <= #self.availabilityQueue and processed < AVAILABLE_BATCH_SIZE do
        local item = self.availabilityQueue[self.availabilityQueueIndex]
        local status = BCR_Availability.evaluateItem(item, player, nil, self.availabilityContext)
        if item and status then
            self.statusCache[item.key] = status
            if status.available then
                table.insert(self.availableItems, item)
                changed = true
            end
        end
        self.availabilityQueueIndex = self.availabilityQueueIndex + 1
        processed = processed + 1
    end

    if self.availabilityQueueIndex > #(self.availabilityQueue or {}) then
        self.availabilityQueue = nil
        self.availabilityContext = nil
        self.availabilityScanComplete = true
        changed = true
    end

    local now = BCR_Utils.nowMs()
    if changed or now <= 0 or (now - (self.lastAvailableResultsRefresh or 0)) >= AVAILABLE_RESULTS_REFRESH_MS then
        self.lastAvailableResultsRefresh = now
        self:invalidateSourceCache("availability-scan")
        self:refreshAll(false, true)
    end
    BCR_Debug.timing("Availability batch", startedAt, "(" .. tostring(processed) .. " rows)")
end

function HubPanel:statusForItem(item)
    if not item then return nil end
    if self.statusCache and self.statusCache[item.key] then
        return self.statusCache[item.key]
    end
    local player, isoObject = self:playerAndIsoObject(self.mode == "available")
    if not self:needsAvailability() and not self:isAreaScanValid(player) then
        return nil
    end

    local startedAt = BCR_Utils.nowMs()
    local context = BCR_Availability.newContext(player, isoObject, self:containersForCurrentScope(player))
    local status = BCR_Availability.evaluateItem(item, player, isoObject, context)
    if not self.statusCache then self.statusCache = {} end
    self.statusCache[item.key] = status
    BCR_Debug.timing("On-demand craftability check", startedAt, "(" .. tostring(item.key or "?") .. ")")
    return status
end

function HubPanel:rawItemsForMode(force)
    if force then
        self:invalidateSourceCache("force")
    end

    local sourceModeKey = tostring(self.mode or "all") .. ":" .. tostring(self.filterMode or "all")
    local generation = table.concat({
        tostring(BCR_RecipeIndex and BCR_RecipeIndex._buildGeneration or 0),
        tostring(BCR_BuildIndex and BCR_BuildIndex._buildGeneration or 0),
        tostring(#(self.availableItems or {})),
        tostring(self.availabilityQueueIndex or 0),
        tostring(self.availabilityScanComplete == true),
    }, "|")
    if self.sourceItemsCache and self.sourceItemsCacheMode == sourceModeKey and self.sourceItemsCacheGeneration == generation and not force then
        return self.sourceItemsCache
    end

    local results = {}
    if self.mode == "build" then
        results = self:buildItems(force)
    elseif self.mode == "craft" then
        results = self:craftItems(force)
    elseif self.mode == "available" then
        self:startAvailabilityScan(force)
        if self.filterMode == "materials" or self.filterMode == "blocked" then
            for _, item in ipairs(self:craftItems(force)) do
                table.insert(results, item)
            end
            for _, item in ipairs(self:buildItems(force)) do
                table.insert(results, item)
            end
        else
            results = self.availableItems or {}
        end
    elseif self.mode == "favorites" then
        for _, item in ipairs(self:craftItems(force)) do
            if BCR_UserData.isFavorite(item, self.playerIndex) then
                table.insert(results, item)
            end
        end
        for _, item in ipairs(self:buildItems(force)) do
            if BCR_UserData.isFavorite(item, self.playerIndex) then
                table.insert(results, item)
            end
        end
        table.sort(results, BCR_Utils.sortByLabel)
    elseif self.mode == "recent" then
        local allItems = {}
        for _, item in ipairs(self:craftItems(force)) do
            allItems[item.key] = item
        end
        for _, item in ipairs(self:buildItems(force)) do
            allItems[item.key] = item
        end
        for _, key in ipairs(BCR_UserData.recents(self.playerIndex)) do
            if allItems[key] then
                table.insert(results, allItems[key])
            end
        end
    else
        for _, item in ipairs(self:craftItems(force)) do
            table.insert(results, item)
        end
        for _, item in ipairs(self:buildItems(force)) do
            table.insert(results, item)
        end
        table.sort(results, BCR_Utils.sortByLabel)
    end

    generation = table.concat({
        tostring(BCR_RecipeIndex and BCR_RecipeIndex._buildGeneration or 0),
        tostring(BCR_BuildIndex and BCR_BuildIndex._buildGeneration or 0),
        tostring(#(self.availableItems or {})),
        tostring(self.availabilityQueueIndex or 0),
        tostring(self.availabilityScanComplete == true),
    }, "|")
    self.sourceItemsCache = results
    self.sourceItemsCacheMode = sourceModeKey
    self.sourceItemsCacheGeneration = generation
    return results
end

function HubPanel:itemMatchesFilter(item)
    local mode = self.filterMode or "all"
    if mode == "all" then return true end
    local sourceKey = sourceFilterKey(mode)
    if sourceKey then
        local _, key = self:resolveItemSource(item)
        return key == sourceKey
    end
    if mode == "favorites" then
        return BCR_UserData.isFavorite(item, self.playerIndex) == true
    end
    if mode == "materials" or mode == "ready" or mode == "blocked" then
        self:startAvailabilityScan(false)
        local status = item and self.statusCache and self.statusCache[item.key] or nil
        if mode == "materials" then
            return status and status.materialsAvailable == true
        end
        if mode == "ready" then
            return status and status.available == true
        end
        return status and status.available == false
    end
    return true
end

function HubPanel:sortItems(items)
    local mode = self.sortMode or "name_az"
    table.sort(items, function(a, b)
        local aLabel = BCR_Utils.lower(a and a.label or "")
        local bLabel = BCR_Utils.lower(b and b.label or "")
        if mode == "name_za" then
            if aLabel ~= bLabel then return aLabel > bLabel end
        elseif mode == "category" then
            local aCategory = BCR_Utils.lower(displayCategory(a and a.category or ""))
            local bCategory = BCR_Utils.lower(displayCategory(b and b.category or ""))
            if aCategory ~= bCategory then return aCategory < bCategory end
        elseif mode == "type" then
            local aKind = BCR_Utils.lower(itemKindLabel(a and a.kind or "craft"))
            local bKind = BCR_Utils.lower(itemKindLabel(b and b.kind or "craft"))
            if aKind ~= bKind then return aKind < bKind end
        end
        if aLabel ~= bLabel then return aLabel < bLabel end
        return BCR_Utils.lower(a and a.key or "") < BCR_Utils.lower(b and b.key or "")
    end)
    return items
end

function HubPanel:buildCategoryItems(force)
    local source = self:rawItemsForMode(force)
    local byKey = {}
    local totalCount = 0
    for _, item in ipairs(source) do
        if self:itemMatchesFilter(item) then
            local key = displayCategory(item.category)
            if not byKey[key] then
                byKey[key] = { key = key, label = key, count = 0 }
            end
            byKey[key].count = byKey[key].count + 1
            totalCount = totalCount + 1
        end
    end

    local categories = {
        {
            key = ALL_CATEGORIES,
            label = BCR_Utils.tr("UI_BCR_AllCategories", "All Categories"),
            count = totalCount,
        },
    }
    for _, category in pairs(byKey) do
        table.insert(categories, category)
    end
    table.sort(categories, categorySort)
    return categories
end

function HubPanel:refreshCategories(force)
    self.categoryItems = self:buildCategoryItems(force)
    if not self.categoryList then return end
    self.categoryList:clear()
    self.categoryList:setScrollHeight(0)

    local selectedIndex = 0
    local categoryExists = false
    for index, category in ipairs(self.categoryItems) do
        self.categoryList:addItem(category.label, category)
        if category.key == self.categoryKey then
            selectedIndex = index
            categoryExists = true
        end
    end

    if not categoryExists then
        self.categoryKey = #self.categoryItems > 0 and ALL_CATEGORIES or nil
        selectedIndex = #self.categoryItems > 0 and 1 or 0
    end
    self.categoryList.selected = selectedIndex
    self.categoryTabOffset = math.max(1, math.min(self.categoryTabOffset or 1, #self.categoryItems))
    if selectedIndex > 0 and selectedIndex < self.categoryTabOffset then
        self.categoryTabOffset = selectedIndex
    end
    self:layoutCategoryTabs()
end

function HubPanel:itemsForMode(force)
    if not hasCategorySelection(self.categoryKey) then
        return {}
    end
    local source = self:rawItemsForMode(force)
    self.searchTerms = BCR_Utils.queryTerms(self.searchText)
    local results = {}
    local previewLimit = self.indexBuildPending and INDEX_PREVIEW_LIMIT or nil
    for _, item in ipairs(source) do
        local categoryOk = self.categoryKey == ALL_CATEGORIES or displayCategory(item.category) == self.categoryKey
        if categoryOk and self:itemMatchesFilter(item) and matchesItemQuery(item, self.searchText, self.searchTerms, false) then
            table.insert(results, item)
            if previewLimit and #results >= previewLimit then
                break
            end
        end
    end
    return self:sortItems(results)
end

function HubPanel:startDeepSearchScan()
    if not hasCategorySelection(self.categoryKey) then
        self:stopDeepSearchScan()
        return
    end
    if not queryLongEnoughForDeepSearch(self.searchText) then
        self:stopDeepSearchScan()
        return
    end

    local stateKey = deepSearchStateKey(self)
    if self.deepSearchQueryKey == stateKey and (self.deepSearchQueue or self.deepSearchComplete) then
        return
    end

    local startedAt = BCR_Utils.nowMs()
    local terms = self.searchTerms or BCR_Utils.queryTerms(self.searchText)
    local queue = {}
    for _, item in ipairs(self:rawItemsForMode(false)) do
        local categoryOk = self.categoryKey == ALL_CATEGORIES or displayCategory(item.category) == self.categoryKey
        if categoryOk and self:itemMatchesFilter(item) and not BCR_Utils.matchesQueryTermsLower(item.searchKey, terms) and not item.deepSearchKey then
            table.insert(queue, item)
        end
    end

    self.deepSearchQueue = queue
    self.deepSearchQueueIndex = 1
    self.deepSearchQueryKey = stateKey
    self.deepSearchComplete = #queue == 0
    self.lastDeepSearchResultsRefresh = 0
    BCR_Debug.timing("Deep search queue", startedAt, "(" .. tostring(#queue) .. " rows)")
end

function HubPanel:processDeepSearchScan()
    if not self.deepSearchQueue or self.deepSearchComplete then return end
    if not queryLongEnoughForDeepSearch(self.searchText) then
        self:stopDeepSearchScan()
        return
    end
    if self.deepSearchQueryKey ~= deepSearchStateKey(self) then
        self:stopDeepSearchScan()
        self:startDeepSearchScan()
        return
    end

    local startedAt = BCR_Utils.nowMs()
    local processed = 0
    local queue = self.deepSearchQueue
    while self.deepSearchQueueIndex <= #queue and processed < DEEP_SEARCH_BATCH_SIZE do
        local item = queue[self.deepSearchQueueIndex]
        if item and not item.deepSearchKey then
            if item.kind == "craft" and BCR_RecipeIndex.deepSearchText then
                BCR_RecipeIndex.deepSearchText(item)
            elseif item.kind == "build" and BCR_BuildIndex.deepSearchText then
                BCR_BuildIndex.deepSearchText(item)
            end
        end
        self.deepSearchQueueIndex = self.deepSearchQueueIndex + 1
        processed = processed + 1
    end

    if self.deepSearchQueueIndex > #queue then
        self.deepSearchQueue = nil
        self.deepSearchComplete = true
    end

    local now = BCR_Utils.nowMs()
    if processed > 0 and (self.deepSearchComplete or now <= 0 or (now - (self.lastDeepSearchResultsRefresh or 0)) >= DEEP_SEARCH_REFRESH_MS) then
        self.lastDeepSearchResultsRefresh = now
        self:refreshResults(false, true)
    end
    BCR_Debug.timing("Deep search batch", startedAt, "(" .. tostring(processed) .. " rows)")
end

function HubPanel:refreshAll(force, preserveSelection)
    self:refreshCategories(force)
    self:refreshResults(false, preserveSelection)
end

function HubPanel:populateResultPage(preserveSelection, suppressAutoRecent)
    local selectedKey = preserveSelection and self.selectedItem and self.selectedItem.key or nil
    local allItems = self.filteredItems or {}
    self.totalFilteredItems = #allItems
    local pageSize = self:resultPageSize()
    local maxPage = self:maxResultPage(#allItems)
    self.resultPage = math.max(1, math.min(self.resultPage or 1, maxPage))
    local selectedGlobalIndex = nil
    if selectedKey then
        for index, item in ipairs(allItems) do
            if item.key == selectedKey then
                selectedGlobalIndex = index
                self.resultPage = math.max(1, math.ceil(index / pageSize))
                break
            end
        end
    end
    self.pageStartIndex = (#allItems == 0) and 0 or ((self.resultPage - 1) * pageSize + 1)
    self.pageEndIndex = math.min(#allItems, self.pageStartIndex + pageSize - 1)

    if not self.resultList then return 0 end
    self.resultList:clear()
    self.resultList:setScrollHeight(0)
    local displayItems = {}
    for index = self.pageStartIndex, self.pageEndIndex do
        local item = allItems[index]
        if item then
            table.insert(displayItems, item)
        end
    end
    for _, item in ipairs(displayItems) do
        self.resultList:addItem(item.label, item)
    end
    if #displayItems > 0 and not (self.indexBuildPending and not selectedKey) then
        local selectedIndex = 1
        if selectedKey and selectedGlobalIndex then
            selectedIndex = selectedGlobalIndex - self.pageStartIndex + 1
        elseif selectedKey then
            for index, item in ipairs(displayItems) do
                if item.key == selectedKey then
                    selectedIndex = index
                    break
                end
            end
        end
        self.resultList.selected = selectedIndex
        local suppressRecent = self.suppressRecent
        self.suppressRecent = preserveSelection == true or suppressAutoRecent == true
        self:onResultSelected(displayItems[selectedIndex])
        self.suppressRecent = suppressRecent
    else
        self.selectedItem = nil
        self:setDetailLines({})
        self:updateFavoriteButton()
        self:updateActionButton()
        self:updateRepeatButton()
    end
    if self.pendingSelectionRecipe then
        self:selectMatchingItem(self.pendingSelectionKind, self.pendingSelectionRecipe)
        if not self.indexBuildPending then
            self.pendingSelectionKind = nil
            self.pendingSelectionRecipe = nil
        end
    end
    self:updatePageButtons()
    return #displayItems
end

function HubPanel:refreshResults(force, preserveSelection, suppressAutoRecent)
    local startedAt = BCR_Utils.nowMs()
    self.filteredItems = self:itemsForMode(force)
    local displayCount = self:populateResultPage(preserveSelection, suppressAutoRecent)
    self:startDeepSearchScan()
    BCR_Debug.timing("Hub search refresh", startedAt, "(" .. tostring(displayCount) .. "/" .. tostring(#self.filteredItems) .. " rows)")
end

function HubPanel:selectMatchingItem(kind, recipeOrBuildRecipe)
    if not recipeOrBuildRecipe or not self.resultList then return end
    local source = self:rawItemsForMode(false)
    for index, item in ipairs(source) do
        local matches = false
        if item and kind == "craft" then
            matches = item.raw == recipeOrBuildRecipe
        elseif item and kind == "build" then
            local info = item.raw
            matches = info and info.getRecipe and info:getRecipe() == recipeOrBuildRecipe
        end
        if matches then
            self.categoryKey = displayCategory(item.category)
            self.categoryTabOffset = self:categoryIndexForKey(self.categoryKey) or self.categoryTabOffset or 1
            self.selectedItem = item
            self.pendingSelectionKind = nil
            self.pendingSelectionRecipe = nil
            self:refreshResults(false, true)
            for localIndex, row in ipairs(self.resultList.items or {}) do
                if row and row.item == item then
                    self.resultList.selected = localIndex
                    self:onResultSelected(item)
                    if self.resultList.ensureVisible then
                        self.resultList:ensureVisible(localIndex)
                    end
                    break
                end
            end
            self:layoutCategoryTabs()
            return
        end
    end
end

function HubPanel:applyOpenContext(kind, recipeOrBuildRecipe, itemString, context)
    self.mode = kind or self.mode or "all"
    self.contextIsoObject = context and context.isoObject or nil
    self.contextQueryOverride = context and context.queryOverride or "*"
    self.contextIgnoreFindSurface = context and context.ignoreFindSurface == true or false
    self.contextInventoryItem = context and context.inventoryItem or nil
    self.contextRecipe = context and context.recipe or recipeOrBuildRecipe
    self.pendingSelectionKind = kind
    self.pendingSelectionRecipe = recipeOrBuildRecipe
    self.lastActionMessage = nil
    self.categoryKey = nil
    self.categoryTabOffset = 1
    self.resultPage = 1
    self.searchText = cleanItemString(itemString)
    self:clearAvailabilityState()
    if self.searchEntry then
        self.suppressSearchChange = true
        self.searchEntry:setText(self.searchText)
        self.suppressSearchChange = false
    end
    self:refreshAll(false)
    self:updateButtonState()
    self:selectMatchingItem(kind, recipeOrBuildRecipe)
end

function HubPanel:clearOpenContext()
    self.contextIsoObject = nil
    self.contextQueryOverride = "*"
    self.contextIgnoreFindSurface = false
    self.contextInventoryItem = nil
    self.contextRecipe = nil
    self.pendingSelectionKind = nil
    self.pendingSelectionRecipe = nil
    self.lastActionMessage = nil
end

function HubPanel.drawCategoryItem(list, y, item, alt)
    local m = currentMetrics(list)
    item.height = list.itemheight
    if item.height <= 0 then return y + item.height end
    if (y + list:getYScroll() + list.itemheight < 0) or (y + list:getYScroll() >= list.height) then
        return y + item.height
    end

    local row = item.item
    if list.selected == item.index then
        list:drawRect(0, y, list:getWidth(), item.height - 1, COLORS.selected.a, COLORS.selected.r, COLORS.selected.g, COLORS.selected.b)
    elseif (list.mouseoverselected == item.index) and list:isMouseOver() and not list:isMouseOverScrollBar() then
        list:drawRect(0, y, list:getWidth(), item.height - 1, COLORS.rowHover.a, COLORS.rowHover.r, COLORS.rowHover.g, COLORS.rowHover.b)
    elseif alt then
        list:drawRect(0, y, list:getWidth(), item.height, COLORS.rowAlt.a, COLORS.rowAlt.r, COLORS.rowAlt.g, COLORS.rowAlt.b)
    else
        list:drawRect(0, y, list:getWidth(), item.height, COLORS.row.a, COLORS.row.r, COLORS.row.g, COLORS.row.b)
    end
    list:drawRectBorder(0, y, list:getWidth(), item.height, 0.22, COLORS.border.r, COLORS.border.g, COLORS.border.b)

    local label = row and row.label or item.text
    local count = row and row.count or 0
    local countText = tostring(count)
    local labelX = m.pad - scalePx(2)
    local countW = math.max(scalePx(30), textWidth(m.font, countText) + scalePx(10))
    local countX = list:getWidth() - m.pad - scalePx(18) - countW
    local maxLabelWidth = countX - labelX - scalePx(8)
    label = ellipsize(m.font, label, maxLabelWidth)
    local textY = y + math.floor((item.height - fontHeight(m.font)) / 2)
    local countColor = list.selected == item.index and COLORS.text or COLORS.muted
    list:drawText(label, labelX, textY, COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a, m.font)
    list:drawRect(countX, textY - scalePx(2), countW, fontHeight(m.font) + scalePx(4), 0.18, COLORS.border.r, COLORS.border.g, COLORS.border.b)
    list:drawTextRight(countText, countX + countW - scalePx(4), textY, countColor.r, countColor.g, countColor.b, countColor.a, m.font)
    return y + item.height
end

function HubPanel.drawResultItem(list, y, item, alt)
    local m = currentMetrics(list)
    item.height = list.itemheight
    if item.height <= 0 then return y + item.height end
    if (y + list:getYScroll() + list.itemheight < 0) or (y + list:getYScroll() >= list.height) then
        return y + item.height
    end

    local debugStartedAt = BCR_Debug.enabled() and BCR_Utils.nowMs() or nil
    local function finish(nextY)
        if debugStartedAt and list.target then
            local elapsed = BCR_Utils.nowMs() - debugStartedAt
            list.target.visibleRowRenderMs = (list.target.visibleRowRenderMs or 0) + elapsed
            list.target.visibleRowRenderCount = (list.target.visibleRowRenderCount or 0) + 1
            local now = BCR_Utils.nowMs()
            if now <= 0 or (now - (list.target.lastVisibleRowRenderLog or 0)) >= ROW_RENDER_LOG_MS then
                BCR_Debug.log("Visible row render in " .. tostring(list.target.visibleRowRenderMs or 0) .. "ms (" .. tostring(list.target.visibleRowRenderCount or 0) .. " rows)")
                list.target.visibleRowRenderMs = 0
                list.target.visibleRowRenderCount = 0
                list.target.lastVisibleRowRenderLog = now
            end
        end
        return nextY
    end

    local row = item.item
    if list.selected == item.index then
        list:drawRect(0, y, list:getWidth(), item.height - 1, COLORS.selected.a, COLORS.selected.r, COLORS.selected.g, COLORS.selected.b)
    elseif (list.mouseoverselected == item.index) and list:isMouseOver() and not list:isMouseOverScrollBar() then
        list:drawRect(0, y, list:getWidth(), item.height - 1, COLORS.rowHover.a, COLORS.rowHover.r, COLORS.rowHover.g, COLORS.rowHover.b)
    elseif alt then
        list:drawRect(0, y, list:getWidth(), item.height, COLORS.rowAlt.a, COLORS.rowAlt.r, COLORS.rowAlt.g, COLORS.rowAlt.b)
    else
        list:drawRect(0, y, list:getWidth(), item.height, COLORS.row.a, COLORS.row.r, COLORS.row.g, COLORS.row.b)
    end
    list:drawRectBorder(0, y, list:getWidth(), item.height, 0.28, COLORS.border.r, COLORS.border.g, COLORS.border.b)

    local label = row and row.label or item.text
    local category = row and displayCategory(row.category) or ""
    local kind = row and itemKindLabel(row.kind) or ""
    local kindColor = row and row.kind == "build" and COLORS.build or COLORS.craft
    local showRowStatus = list.target and (list.target.mode == "available" or availabilityFilterActive(list.target.filterMode))
    local status = showRowStatus and row and list.target and list.target.statusCache and list.target.statusCache[row.key] or nil
    local playerIndex = list.target and list.target.playerIndex or 0
    local isFavorite = row and BCR_UserData.isFavorite(row, playerIndex) or false
    local statusText = statusTextFor(row, status)
    local statusColor = statusColorFor(status)
    local accentColor = status and statusColor or kindColor
    list:drawRect(0, y, scalePx(3), item.height - 1, 0.92, accentColor.r, accentColor.g, accentColor.b)

    local iconX = m.pad - scalePx(2)
    local iconY = y + math.floor((item.height - m.icon) / 2)
    drawItemIcon(list, row, iconX, iconY, m.icon, m.font, kindColor)

    local textX = iconX + m.icon + scalePx(8)
    local rightPad = scalePx(10)
    local statusW = statusText ~= "" and (textWidth(m.font, statusText) + scalePx(18)) or 0
    local favW = isFavorite and scalePx(14) or 0
    local maxTitleW = list:getWidth() - textX - statusW - favW - rightPad
    label = ellipsize(m.font, BCR_Utils.displayLabel(label, item.text), maxTitleW)
    category = ellipsize(m.font, category, list:getWidth() - textX - rightPad - favW)

    local titleY = y + scalePx(6)
    local subY = y + item.height - fontHeight(m.font) - scalePx(6)
    list:drawText(label, textX, titleY, COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a, m.font)
    list:drawText(kind, textX, subY, kindColor.r, kindColor.g, kindColor.b, kindColor.a, m.font)
    list:drawText(category, textX + textWidth(m.font, kind) + scalePx(10), subY, COLORS.muted.r, COLORS.muted.g, COLORS.muted.b, COLORS.muted.a, m.font)
    if isFavorite then
        list:drawText("*", list:getWidth() - scalePx(12), titleY, COLORS.active.r, COLORS.active.g, COLORS.active.b, COLORS.active.a, m.font)
    end
    if statusText ~= "" then
        local badgeH = math.max(scalePx(18), fontHeight(m.font) + scalePx(5))
        local badgeX = list:getWidth() - rightPad - favW - statusW
        local badgeY = titleY - scalePx(1)
        list:drawRect(badgeX, badgeY, statusW, badgeH, 0.20, statusColor.r, statusColor.g, statusColor.b)
        list:drawRectBorder(badgeX, badgeY, statusW, badgeH, 0.58, statusColor.r, statusColor.g, statusColor.b)
        list:drawText(statusText, badgeX + scalePx(7), badgeY + math.floor((badgeH - fontHeight(m.font)) / 2), statusColor.r, statusColor.g, statusColor.b, statusColor.a, m.font)
    end
    return finish(y + item.height)
end

function HubPanel:prerender()
    self:refreshMetrics()
    local m = self.metrics or makeMetrics()
    ISPanel.prerender(self)
    local alpha = COLORS.bg.a
    if BCR_DisplaySettings and BCR_DisplaySettings.get and BCR_DisplaySettings.get("TransparencyOnMouseout") and not self:isMouseOver() then
        alpha = 0.72
    end
    self:drawRect(0, 0, self.width, self.height, alpha, COLORS.bg.r, COLORS.bg.g, COLORS.bg.b)
    self:drawRect(0, 0, self.width, m.headerH, COLORS.header.a, COLORS.header.r, COLORS.header.g, COLORS.header.b)
    if not self.collapsed then
        self:drawRect(0, m.headerH, self.width, m.toolbarH, COLORS.toolbar.a, COLORS.toolbar.r, COLORS.toolbar.g, COLORS.toolbar.b)
        self:drawRectBorder(0, m.headerH, self.width, m.toolbarH, COLORS.toolbarBorder.a, COLORS.toolbarBorder.r, COLORS.toolbarBorder.g, COLORS.toolbarBorder.b)
    end
    self:drawRectBorder(0, 0, self.width, self.height, COLORS.border.a, COLORS.border.r, COLORS.border.g, COLORS.border.b)
    local titleMax = self.width - m.pad * 2 - m.closeW - m.collapseW - scalePx(14)
    local title = ellipsize(m.font, BCR_Utils.tr("UI_BCR_Hub_Title", "Craft / Build"), titleMax)
    self:drawText(title, m.pad, scalePx(7), COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a, m.font)
end

function HubPanel:update()
    if ISPanel.update then
        ISPanel.update(self)
    end
    self:refreshLive(false)
    self:processIndexBuild()
    self:processPendingSearch()
    self:processDeepSearchScan()
    self:processAvailabilityScan()
    self:updatePlacementCollapse()
end

function HubPanel:render()
    ISPanel.render(self)
    local m = self.metrics or makeMetrics()

    if self.collapsed then return end

    local craftCount = self.craftCount or (BCR_RecipeIndex and BCR_RecipeIndex._items and #BCR_RecipeIndex._items) or 0
    local buildCount = self.buildCount or (BCR_BuildIndex and BCR_BuildIndex._items and #BCR_BuildIndex._items) or 0
    local countText = BCR_Utils.tr("UI_BCR_Counts", "Craft: %1 | Build: %2")
    countText = BCR_Utils.format(countText, craftCount, buildCount)
    self:drawTextRight(countText, self.width - m.pad - m.closeW - m.collapseW - scalePx(16), scalePx(8), COLORS.muted.r, COLORS.muted.g, COLORS.muted.b, COLORS.muted.a, m.font)

    local categoryY = self:listY() - m.lineH - scalePx(6)
    self:drawText(BCR_Utils.tr("UI_BCR_CategoryList", "Categories"), m.pad, categoryY, COLORS.muted.r, COLORS.muted.g, COLORS.muted.b, COLORS.muted.a, m.font)
    if self.resultList then
        self:drawTextRight(self:resultRangeText(), self.resultList:getRight(), categoryY, COLORS.muted.r, COLORS.muted.g, COLORS.muted.b, COLORS.muted.a, m.font)
    end

    local detailsX, detailsY, detailsW, detailsH = self:detailsRect()
    local detailTextBottom = detailsY + detailsH - m.pad
    self:drawRect(detailsX, detailsY, detailsW, detailsH, COLORS.panel.a, COLORS.panel.r, COLORS.panel.g, COLORS.panel.b)
    self:drawRectBorder(detailsX, detailsY, detailsW, detailsH, 0.45, COLORS.border.r, COLORS.border.g, COLORS.border.b)

    self:drawText(BCR_Utils.tr("UI_BCR_Details", "Details"), detailsX + m.pad, detailsY + scalePx(8), COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a, m.font)
    if self.selectedItem or self.areaScanBtn or self:itemForKey(BCR_UserData.lastActionKey(self.playerIndex), false) then
        local actionY = self:detailsActionY()
        local actionH = math.max(m.buttonH, scalePx(28))
        self:drawRect(detailsX + m.pad - scalePx(3), actionY - scalePx(3), detailsW - m.pad * 2 + scalePx(6), actionH + scalePx(6), 0.32, COLORS.header.r, COLORS.header.g, COLORS.header.b)
        self:drawRectBorder(detailsX + m.pad - scalePx(3), actionY - scalePx(3), detailsW - m.pad * 2 + scalePx(6), actionH + scalePx(6), 0.42, COLORS.border.r, COLORS.border.g, COLORS.border.b)
    end

    local lineY = self:detailsContentY()
    if self.selectedItem then
        local icon = BCR_IconResolver and BCR_IconResolver.textureFor and BCR_IconResolver.textureFor(self.selectedItem) or nil
        local titleX = detailsX + m.pad
        local iconPad = scalePx(3)
        self:drawRect(titleX - iconPad, lineY - iconPad, m.detailIcon + iconPad * 2, m.detailIcon + iconPad * 2, COLORS.iconBg.a, COLORS.iconBg.r, COLORS.iconBg.g, COLORS.iconBg.b)
        self:drawRectBorder(titleX - iconPad, lineY - iconPad, m.detailIcon + iconPad * 2, m.detailIcon + iconPad * 2, COLORS.iconBorder.a, COLORS.iconBorder.r, COLORS.iconBorder.g, COLORS.iconBorder.b)
        if icon and self.drawTextureScaled then
            self:drawTextureScaled(icon, titleX, lineY, m.detailIcon, m.detailIcon, 1.00, 1, 1, 1)
            titleX = titleX + m.detailIcon + scalePx(8)
        else
            local kindColor = self.selectedItem.kind == "build" and COLORS.build or COLORS.craft
            drawItemIcon(self, self.selectedItem, titleX, lineY, m.detailIcon, m.font, kindColor)
            titleX = titleX + m.detailIcon + scalePx(8)
        end

        local titleMaxW = detailsW - (titleX - detailsX) - m.pad
        self:drawText(ellipsize(m.font, self.selectedItem.label, titleMaxW), titleX, lineY + scalePx(2), COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a, m.font)
        lineY = lineY + math.max(m.detailIcon, m.lineH * 2) + scalePx(8)
        for _, line in ipairs(self:wrappedDetailLinesFor(detailsW - m.pad * 2)) do
            if lineY < detailTextBottom - m.lineH then
                local color = line.color or COLORS.muted
                self:drawText(line.text, detailsX + m.pad, lineY, color.r, color.g, color.b, color.a, m.font)
                lineY = lineY + m.lineH
            end
        end
    elseif self.indexBuildPending then
        self:drawText(BCR_Utils.tr("UI_BCR_Indexing", "Indexing craft/build entries..."), detailsX + m.pad, lineY, COLORS.warning.r, COLORS.warning.g, COLORS.warning.b, COLORS.warning.a, m.font)
    elseif not hasCategorySelection(self.categoryKey) then
        self:drawText(BCR_Utils.tr("UI_BCR_SelectCategory", "Select a category to view entries."), detailsX + m.pad, lineY, COLORS.muted.r, COLORS.muted.g, COLORS.muted.b, COLORS.muted.a, m.font)
    elseif (self.mode == "available" or availabilityFilterActive(self.filterMode)) and not self.availabilityScanComplete then
        self:drawText(BCR_Utils.tr("UI_BCR_AvailablePending", "Available-now indexing pending."), detailsX + m.pad, lineY, COLORS.warning.r, COLORS.warning.g, COLORS.warning.b, COLORS.warning.a, m.font)
    else
        self:drawText(BCR_Utils.tr("UI_BCR_EmptyResults", "No matching entries."), detailsX + m.pad, lineY, COLORS.muted.r, COLORS.muted.g, COLORS.muted.b, COLORS.muted.a, m.font)
    end

    local gripX = self.width - m.grip
    local gripY = self.height - m.grip
    self:drawRect(gripX, gripY, m.grip - scalePx(2), m.grip - scalePx(2), 0.18, COLORS.border.r, COLORS.border.g, COLORS.border.b)
    self:drawRectBorder(gripX, gripY, m.grip - scalePx(2), m.grip - scalePx(2), 0.35, COLORS.border.r, COLORS.border.g, COLORS.border.b)
end

function HubPanel:onMouseDown(x, y)
    local m = self.metrics or makeMetrics()
    if not self.collapsed and x >= self.width - m.grip and y >= self.height - m.grip then
        self.resizing = true
        self.resizeStartW = self.width
        self.resizeStartH = self.height
        self.resizeMouseX = getMouseX and getMouseX() or 0
        self.resizeMouseY = getMouseY and getMouseY() or 0
        return true
    end
    if y <= m.headerH then
        self.dragging = true
        self.dragX = x
        self.dragY = y
        return true
    end
    return ISPanel.onMouseDown(self, x, y)
end

function HubPanel:onMouseDoubleClick(x, y)
    local m = self.metrics or makeMetrics()
    if y <= m.headerH then
        self:onMinimize()
        return true
    end
    if ISPanel.onMouseDoubleClick then
        return ISPanel.onMouseDoubleClick(self, x, y)
    end
    return false
end

function HubPanel:onMouseMove(dx, dy)
    if self.dragging then
        local mx = getMouseX and getMouseX() or self:getX()
        local my = getMouseY and getMouseY() or self:getY()
        self:setX(mx - self.dragX)
        self:setY(my - self.dragY)
        return true
    end
    if self.resizing and not self.collapsed then
        local m = self.metrics or makeMetrics()
        local mx = getMouseX and getMouseX() or self.resizeMouseX
        local my = getMouseY and getMouseY() or self.resizeMouseY
        self:setWidth(math.max(m.minW, self.resizeStartW + (mx - self.resizeMouseX)))
        self:setHeight(math.max(m.minH, self.resizeStartH + (my - self.resizeMouseY)))
        self:layoutChildren()
        return true
    end
    return ISPanel.onMouseMove(self, dx, dy)
end

function HubPanel:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function HubPanel:onMouseUp(x, y)
    local resized = self.resizing == true
    self.dragging = false
    self.resizing = false
    local nx, ny = BCR_Utils.clampToScreen(self:getX(), self:getY(), self.width, self.height)
    self:setX(nx)
    self:setY(ny)
    local saveWidth = self.collapsed and math.max(minWindowWidth(), self.expandedWidth or self.width) or self.width
    local saveHeight = self.collapsed and math.max(minWindowHeight(), self.expandedHeight or self.height) or self.height
    BCR_UserData.setHubLayout(self.playerIndex, nx, ny, saveWidth, saveHeight)
    if self.collapsed then
        self:fallBackCollapsedLayer()
    end
    if resized and not self.collapsed then
        self:populateResultPage(true, true)
    end
    return ISPanel.onMouseUp(self, x, y)
end

function HubPanel:onMouseUpOutside(x, y)
    return self:onMouseUp(x, y)
end

BCR_HubWindow._panel = nil
BCR_HubWindow.isVisible = false
BCR_HubWindow._eventsInstalled = BCR_HubWindow._eventsInstalled or false

function BCR_HubWindow.markDirty(reason)
    local panel = BCR_HubWindow._panel
    if panel and panel.markDirty then
        panel:markDirty(reason)
    end
end

function BCR_HubWindow.invalidateCaches(reason)
    local panel = BCR_HubWindow._panel
    if not panel then return end
    if panel.clearAvailabilityState then
        panel:clearAvailabilityState()
    end
    if panel.invalidateSourceCache then
        panel:invalidateSourceCache(reason or "manual")
    end
    if panel.stopDeepSearchScan then
        panel:stopDeepSearchScan()
    end
    if panel.markDirty then
        panel:markDirty(reason or "manual")
    end
end

function BCR_HubWindow.onContainerUpdate(container)
    BCR_HubWindow.markDirty("container")
end

function BCR_HubWindow.onInventoryRefresh(playerNum, inventory)
    BCR_HubWindow.markDirty("inventory")
end

function BCR_HubWindow.onObjectAdded(square, object)
    BCR_HubWindow.markDirty("world")
end

function BCR_HubWindow.onObjectAboutToBeRemoved(object)
    BCR_HubWindow.markDirty("world")
end

function BCR_HubWindow.installLiveEvents()
    if BCR_HubWindow._eventsInstalled or not Events then return end
    if Events.OnContainerUpdate then Events.OnContainerUpdate.Add(BCR_HubWindow.onContainerUpdate) end
    if Events.OnRefreshInventoryWindowContainers then Events.OnRefreshInventoryWindowContainers.Add(BCR_HubWindow.onInventoryRefresh) end
    if Events.OnObjectAdded then Events.OnObjectAdded.Add(BCR_HubWindow.onObjectAdded) end
    if Events.OnObjectAboutToBeRemoved then Events.OnObjectAboutToBeRemoved.Add(BCR_HubWindow.onObjectAboutToBeRemoved) end
    BCR_HubWindow._eventsInstalled = true
end

function BCR_HubWindow.open(playerIndex, anchorX, anchorY, options)
    local startedAt = BCR_Utils.nowMs()
    BCR_HubWindow.installLiveEvents()
    if BCR_HubWindow._panel then
        BCR_HubWindow._panel.playerIndex = playerIndex or 0
        BCR_HubWindow._panel:setVisible(true)
        if BCR_HubWindow._panel.setCollapsed then
            BCR_HubWindow._panel:setCollapsed(false)
        end
        local x, y
        if anchorX and anchorY then
            x, y = BCR_Utils.clampToScreen(anchorX, anchorY, BCR_HubWindow._panel.width, BCR_HubWindow._panel.height)
        else
            x, y = centerWindowPosition(BCR_HubWindow._panel.width, BCR_HubWindow._panel.height)
        end
        BCR_HubWindow._panel:setX(x)
        BCR_HubWindow._panel:setY(y)
        BCR_HubWindow._panel:bringToTop()
        if options then
            BCR_HubWindow._panel:applyOpenContext(options.kind, options.recipe, options.itemString, options.context)
        else
            BCR_HubWindow._panel:resetToHome()
        end
        BCR_HubWindow.isVisible = true
        BCR_Debug.timing("Hub open", startedAt, "(reused)")
        return BCR_HubWindow._panel
    end

    local layout = BCR_UserData.getHubLayout(playerIndex)
    local defaultW, defaultH = contentAwareDefaultSize()
    local width = layout and math.max(minWindowWidth(), layout.width) or defaultW
    local height = layout and math.max(minWindowHeight(), layout.height) or defaultH
    width, height = clampWindowSize(width, height)
    local x, y
    if anchorX and anchorY then
        x, y = BCR_Utils.clampToScreen(anchorX, anchorY, width, height)
    else
        x, y = centerWindowPosition(width, height)
    end
    local panel = HubPanel:new(x, y, playerIndex, width, height)
    panel.deferInitialRefresh = true
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    BCR_HubWindow._panel = panel
    BCR_HubWindow.isVisible = true
    if options then
        panel:applyOpenContext(options.kind, options.recipe, options.itemString, options.context)
    else
        panel:resetToHome()
    end
    BCR_Debug.timing("Hub open", startedAt, "(created)")
    return panel
end

function BCR_HubWindow.toggle(playerIndex, anchorX, anchorY)
    local startedAt = BCR_Utils.nowMs()
    BCR_HubWindow.installLiveEvents()
    if BCR_HubWindow._panel then
        local visible = not BCR_HubWindow._panel:getIsVisible()
        BCR_HubWindow._panel:setVisible(visible)
        BCR_HubWindow.isVisible = visible
        if visible then
            BCR_HubWindow._panel.playerIndex = playerIndex or 0
            if BCR_HubWindow._panel.setCollapsed then
                BCR_HubWindow._panel:setCollapsed(false)
            end
            local x, y
            if anchorX and anchorY then
                x, y = BCR_Utils.clampToScreen(anchorX, anchorY, BCR_HubWindow._panel.width, BCR_HubWindow._panel.height)
            else
                x, y = centerWindowPosition(BCR_HubWindow._panel.width, BCR_HubWindow._panel.height)
            end
            BCR_HubWindow._panel:setX(x)
            BCR_HubWindow._panel:setY(y)
            BCR_HubWindow._panel:resetToHome()
            BCR_HubWindow._panel:bringToTop()
            BCR_Debug.timing("Hub open", startedAt, "(toggle)")
        end
        return BCR_HubWindow._panel
    end
    return BCR_HubWindow.open(playerIndex, anchorX, anchorY)
end

function BCR_HubWindow.openFor(player, kind, recipeOrBuildRecipe, itemString, context)
    local playerIndex = 0
    if player and player.getPlayerNum then
        playerIndex = player:getPlayerNum()
    elseif type(player) == "number" then
        playerIndex = player
    end
    return BCR_HubWindow.open(playerIndex, nil, nil, {
        kind = kind,
        recipe = recipeOrBuildRecipe,
        itemString = itemString,
        context = context,
    })
end

function BCR_HubWindow.openSearch(playerIndex, searchText, context)
    return BCR_HubWindow.open(playerIndex or 0, nil, nil, {
        kind = "all",
        recipe = nil,
        itemString = searchText,
        context = context,
    })
end

function BCR_HubWindow.destroy()
    if BCR_HubWindow._panel then
        BCR_HubWindow._panel:removeFromUIManager()
        BCR_HubWindow._panel = nil
        BCR_HubWindow.isVisible = false
    end
end

if Events then
    BCR_HubWindow.installLiveEvents()
end

return BCR_HubWindow

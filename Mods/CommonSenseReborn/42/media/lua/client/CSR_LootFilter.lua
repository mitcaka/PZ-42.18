
require "CSR_FeatureFlags"
require "CSR_Theme"
require "CSR_Utils"

CSR_LootFilter = {
    panel = nil,
}

local MODDATA_KEY = "CSRLootFilter"
local DEFAULT_KEY = Keyboard and Keyboard.KEY_BACKSLASH or 43
local HIDE_EQUIPPED_DEFAULT_KEY = Keyboard and Keyboard.KEY_DECIMAL or 83
local FILTERS = {
    { key = "Underwear", group = "Apparel", tooltip = getText("Tooltip_CSR_Filter_Underwear"), matcher = "bodyLocContains", terms = { "underwear", "socks", "stockings", "swimwear" } },
    { key = "Cotton", group = "Apparel", tooltip = getText("Tooltip_CSR_Filter_Cotton"), matcher = "tag", terms = { ItemTag.RIP_CLOTHING_COTTON } },
    { key = "Denim", group = "Apparel", tooltip = getText("Tooltip_CSR_Filter_Denim"), matcher = "tag", terms = { ItemTag.RIP_CLOTHING_DENIM } },
    { key = "Jewelry", group = "Apparel", tooltip = getText("Tooltip_CSR_Filter_Jewelry"), matcher = "bodyLocContains", terms = { "necklace", "ring", "ears", "eartop", "belly" } },
    { key = "Cups", group = "Household", tooltip = getText("Tooltip_CSR_Filter_Cups"), matcher = "fullTypeExact", terms = { "Base.PlasticCup", "Base.Mug", "Base.TeaCup", "Base.GlassTumbler", "Base.FountainCup", "Base.DrinkingGlass", "Base.GlassWine", "Base.Teacup" } },
    { key = "Cookware", group = "Household", tooltip = getText("Tooltip_CSR_Filter_Cookware"), matcher = "fullTypeExact", terms = { "Base.BakingTray", "Base.BakingPan", "Base.RoastingPan", "Base.MuffinTray", "Base.Saucepan" } },
    { key = "Utensils", group = "Household", tooltip = getText("Tooltip_CSR_Filter_Utensils"), matcher = "fullTypeExact", terms = { "Base.Spoon", "Base.Fork", "Base.ButterKnife", "Base.BreadKnife", "Base.PlasticKnife", "Base.Strainer", "Base.Ladle", "Base.Spatula", "Base.CarvingFork", "Base.Whisk", "Base.CheeseGrater", "Base.PizzaCutter", "Base.CuttingBoard", "Base.PlasticTray", "Base.BastingBrush", "Base.Plate" } },
    { key = "Toiletries", group = "Household", tooltip = getText("Tooltip_CSR_Filter_Toiletries"), matcher = "fullTypePrefix", terms = { "Base.Comb", "Base.Razor", "Base.Tooth", "Base.ToiletBrush", "Base.Plunger", "Base.Mirror", "Base.RubberDuck", "Base.Makeup", "Base.Lipstick" } },
    { key = "Magazines", group = "Literature", tooltip = getText("Tooltip_CSR_Filter_Magazines"), matcher = "fullTypePrefix", terms = { "Base.Magazine", "Base.TVMag" } },
    { key = "Writing", group = "Literature", tooltip = getText("Tooltip_CSR_Filter_Writing"), matcher = "fullTypePrefix", terms = { "Base.Pen", "Base.RedPen", "Base.BluePen", "Base.Marker", "Base.Photo", "Base.Diary", "Base.Journal", "Base.Catalog", "Base.Notebook", "Base.Notepad", "Base.SheetPaper", "Base.GraphPaper", "Base.Clipboard", "Base.MenuCard", "Base.Phonebook", "Base.ParkingTicket", "Base.SpeedingTicket", "Base.Paperwork", "Base.Letter", "Base.GenericMail", "Base.Receipt", "Base.Note" } },
    { key = "Recycling", group = "Literature", tooltip = getText("Tooltip_CSR_Filter_Recycling"), matcher = "displayCategory", terms = { "brochure", "flier", "newspaper" } },
    { key = "Junk", group = "Trash", tooltip = getText("Tooltip_CSR_Filter_Junk"), matcher = "fullTypePrefix", terms = { "Base.IDcard", "Base.Card_", "Base.Straw", "Base.CameraFilm", "Base.IndexCard", "Base.BusinessCard", "Base.CreditCard", "Base.CompassGeometry", "Base.CorrectionFluid", "Base.Staple", "Base.MagnifyingGlass", "Base.HolePunch", "Base.RubberBand", "Base.TongueDepressor", "Base.Mov_SaltLick", "Base.BathTowel", "Base.DishCloth", "Base.CheeseCloth" } },
    { key = "Toys", group = "Trash", tooltip = getText("Tooltip_CSR_Filter_Toys"), matcher = "fullTypePrefix", terms = { "Base.CatToy", "Base.DogChew", "Base.Clitter", "Base.Toy", "Base.Doll", "Base.Crayons", "Base.Bricktoys", "Base.Cube", "Base.CardDeck", "Base.GamePiece", "Base.Chess", "Base.Backgammon", "Base.CheckerBoard", "Base.Dice", "Base.Birdie", "Base.GolfBall" } },
    { key = "Scrap", group = "Trash", tooltip = getText("Tooltip_CSR_Filter_Scrap"), matcher = "fullTypeExact", terms = { "Base.TinCanEmpty", "Base.PopEmpty", "Base.Pop2Empty", "Base.Pop3Empty", "Base.SodaCan" } },
    { key = "ManualUnwanted", group = "Personal", tooltip = getText("Tooltip_CSR_Filter_ManualUnwanted"), matcher = "unwanted", terms = {} },
    { key = "ClipboardItems", group = "Personal", tooltip = getText("Tooltip_CSR_Filter_ClipboardItems"), matcher = "clipboard", terms = {} },
}

local options = nil
local showFilterKeyBind = nil
local hideEquippedKeyBind = nil
if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.create then
    options = PZAPI.ModOptions:create("CommonSenseRebornLootFilter", "Common Sense Reborn - Loot Filter")
    if options and options.addKeyBind then
        showFilterKeyBind = options:addKeyBind("showLootFilter", "Loot Filter Hotkey", DEFAULT_KEY)
        hideEquippedKeyBind = options:addKeyBind("hideEquippedToggle", "Toggle Hide Equipped", HIDE_EQUIPPED_DEFAULT_KEY)
    end
end

local function getBoundKey()
    if showFilterKeyBind and showFilterKeyBind.getValue then
        return showFilterKeyBind:getValue()
    end
    return DEFAULT_KEY
end

local function getHideEquippedKey()
    if hideEquippedKeyBind and hideEquippedKeyBind.getValue then
        return hideEquippedKeyBind:getValue()
    end
    return HIDE_EQUIPPED_DEFAULT_KEY
end

local function getPlayerSafe()
    return getPlayer and getPlayer() or nil
end

local function applyDefaultFilters(state)
    if not state then
        return
    end

    -- v1.8.7: ship with NO category filters enabled by default. Previously
    -- Underwear / Toiletries / ManualUnwanted shipped ON, which silently hid
    -- those items from the loot view on a freshly-looted body until the user
    -- clicked a category tab (drewthegreat87 report). Filtering must now be
    -- an explicit user opt-in.
    state.filters = state.filters or {}
    for _, filter in ipairs(FILTERS) do
        state.filters[filter.key] = false
    end
    state.enabled = false
    state.whitelistRaw = ""
    state.whitelist = {}
end

local function getState()
    local player = getPlayerSafe()
    if not player then
        return nil
    end

    local modData = player:getModData()
    modData[MODDATA_KEY] = modData[MODDATA_KEY] or {
        enabled = false, -- v1.8.7: filter master switch defaults OFF
        locked = false,
        hideEquipped = false,
        x = nil,
        y = nil,
        filters = {},
        whitelistRaw = "",
        whitelist = {},
    }

    local state = modData[MODDATA_KEY]
    state.filters = state.filters or {}
    state.whitelistRaw = state.whitelistRaw or ""
    state.whitelist = state.whitelist or {}
    if state.hideEquipped == nil then state.hideEquipped = false end
    for _, filter in ipairs(FILTERS) do
        if state.filters[filter.key] == nil then
            applyDefaultFilters(state)
            break
        end
    end

    return state
end

local function getLootPane()
    local player = getPlayerSafe()
    if not player then
        return nil
    end

    local playerNum = player:getPlayerNum()
    local lootWindow = getPlayerLoot and getPlayerLoot(playerNum) or nil
    return lootWindow and lootWindow.inventoryPane or nil
end

local refreshLootPane  -- forward declaration; defined after filter helpers

local function rebuildWhitelist(state)
    if not state then
        return
    end

    state.whitelist = {}
    local raw = state.whitelistRaw or ""
    for entry in string.gmatch(raw, "([^,]+)") do
        local clean = entry:gsub("^%s*(.-)%s*$", "%1")
        if clean ~= "" then
            state.whitelist[#state.whitelist + 1] = clean
        end
    end
end

local function isWhitelisted(item, state)
    if not item or not state or type(state.whitelist) ~= "table" or #state.whitelist == 0 then
        return false
    end

    local fullType = item.getFullType and item:getFullType() or ""
    local displayName = item.getDisplayName and item:getDisplayName() or ""
    if type(fullType) ~= "string" then
        fullType = ""
    end
    if type(displayName) ~= "string" then
        displayName = ""
    end
    local fullTypeLower = string.lower(fullType)
    local displayNameLower = string.lower(displayName)

    for _, entry in ipairs(state.whitelist) do
        local needle = type(entry) == "string" and string.lower(entry) or ""
        if needle ~= "" then
            if fullTypeLower == needle or fullTypeLower:find(needle, 1, true) or displayNameLower:find(needle, 1, true) then
                return true
            end
        end
    end

    return false
end

local function getActualItem(group)
    if not group then
        return nil
    end

    if instanceof and instanceof(group, "InventoryItem") then
        return group
    end

    local items = group.items
    if items and items[1] then
        return items[1]
    end

    return nil
end

local function matchesTerms(source, terms)
    if type(source) ~= "string" or type(terms) ~= "table" then
        return false
    end

    local lowerSource = string.lower(source)
    for _, term in ipairs(terms) do
        local lowerTerm = type(term) == "string" and string.lower(term) or nil
        if lowerTerm and lowerTerm ~= "" and lowerSource:find(lowerTerm, 1, true) then
            return true
        end
    end
    return false
end

local _clipboardNamesCache = nil
local _clipboardNamesCacheTick = -1

local function getClipboardNamesCache(player)
    local tick = getTimestampMs and getTimestampMs() or 0
    if _clipboardNamesCache and (tick - _clipboardNamesCacheTick) < 2000 then
        return _clipboardNamesCache
    end
    _clipboardNamesCache = CSR_Utils.getClipboardItemNames(player)
    _clipboardNamesCacheTick = tick
    return _clipboardNamesCache
end

local function matchesFilter(item, filter, player)
    if not item or not filter then
        return false
    end

    if filter.matcher == "unwanted" then
        return item.isUnwanted and player and item:isUnwanted(player) == true
    end

    if filter.matcher == "clipboard" then
        if not player or not CSR_Utils then return false end
        local names = getClipboardNamesCache(player)
        local displayName = item.getDisplayName and item:getDisplayName() or nil
        if displayName and type(displayName) == "string" and names[displayName] then
            return true
        end
        return false
    end

    if filter.matcher == "bodyLocContains" then
        local bodyLoc = item.getBodyLocation and item:getBodyLocation() or nil
        if bodyLoc and type(bodyLoc) ~= "string" then bodyLoc = tostring(bodyLoc) end
        return matchesTerms(bodyLoc, filter.terms)
    end

    if filter.matcher == "displayCategory" then
        local displayCategory = item.getDisplayCategory and item:getDisplayCategory() or nil
        if displayCategory and type(displayCategory) ~= "string" then displayCategory = tostring(displayCategory) end
        return matchesTerms(displayCategory, filter.terms)
    end

    if filter.matcher == "tag" then
        if not item or not item.hasTag then
            return false
        end

        for _, tag in ipairs(filter.terms) do
            if tag and item:hasTag(tag) then
                return true
            end
        end
        return false
    end

    local fullType = item.getFullType and item:getFullType() or nil
    if not fullType then
        return false
    end

    if filter.matcher == "fullTypeExact" then
        for _, term in ipairs(filter.terms) do
            if fullType == term then
                return true
            end
        end
        return false
    end

    if filter.matcher == "fullTypePrefix" then
        for _, term in ipairs(filter.terms) do
            if fullType:find(term, 1, true) == 1 then
                return true
            end
        end
    end

    return false
end

local function shouldHideItem(item)
    if not CSR_FeatureFlags.isLootFilterEnabled() then
        return false
    end

    local player = getPlayerSafe()
    local state = getState()
    if not player or not state then
        return false
    end

    -- Hide equipped items check (independent of filter enabled state)
    -- Only hide items the PLAYER has equipped, not items equipped on zombies/corpses
    if state.hideEquipped == true and item then
        local itemContainer = item.getContainer and item:getContainer() or nil
        local playerInv = player.getInventory and player:getInventory() or nil
        if itemContainer and playerInv and itemContainer == playerInv then
            if (player.isEquippedClothing and player:isEquippedClothing(item))
                or (player.getPrimaryHandItem and player:getPrimaryHandItem() == item)
                or (player.getSecondaryHandItem and player:getSecondaryHandItem() == item)
                -- Hotbar-attached items: getAttachedSlot() > -1 means the item occupies
                -- a hotbar slot (B42 API confirmed in ISHotbar.lua lines 102/389/551)
                or (item.getAttachedSlot and item:getAttachedSlot() > -1) then
                return true
            end
        end
    end

    if state.enabled ~= true then
        return false
    end

    if isWhitelisted(item, state) then
        return false
    end

    for _, filter in ipairs(FILTERS) do
        if state.filters[filter.key] == true and matchesFilter(item, filter, player) then
            return true
        end
    end

    return false
end

CSR_LootFilter.shouldHideItem = shouldHideItem

local function filterPane(pane, page, applyCategories)
    if not pane or type(pane.itemslist) ~= "table" then return end

    local searchText = ""
    if page and page.csrSearchEntry and not page.csrLootFilterSuppressed then
        searchText = string.lower(page.csrSearchEntry:getText() or "")
    end

    local state = getState()
    local doFilter = false
    if applyCategories then
        doFilter = state ~= nil and state.enabled == true
    end
    local doHideEquipped = state ~= nil and state.hideEquipped == true

    local hasSearch = searchText ~= ""
    if not hasSearch and not doFilter and not doHideEquipped then return end

    local removedCount = 0
    for i = #pane.itemslist, 1, -1 do
        local group = pane.itemslist[i]
        local actualItem = getActualItem(group)
        if actualItem then
            local hide = false

            if hasSearch then
                local nameOk, displayName = pcall(function() return actualItem:getDisplayName() end)
                if not nameOk then displayName = "" end
                if type(displayName) ~= "string" then displayName = "" end
                if not string.lower(displayName):find(searchText, 1, true) then
                    hide = true
                end
            end

            if not hide and doFilter then
                local filterOk, filterResult = pcall(shouldHideItem, actualItem)
                if filterOk and filterResult then
                    hide = true
                end
            end

            if not hide and doHideEquipped then
                local eqOk, eqResult = pcall(shouldHideItem, actualItem)
                if eqOk and eqResult then
                    hide = true
                end
            end

            if hide then
                table.remove(pane.itemslist, i)
                removedCount = removedCount + 1
            end
        end
    end

    if removedCount > 0 and type(pane.updateScrollbars) == "function" then
        pane:updateScrollbars()
    end
end

local ensureInventoryFilterControls = nil

local function csrApplyAllFilters()
    if not CSR_FeatureFlags.isLootFilterEnabled() then return end

    local player = getPlayerSafe()
    if not player then return end

    -- Skip filtering while items are being dragged to prevent index desync
    if ISMouseDrag and ISMouseDrag.dragging and type(ISMouseDrag.dragging) == "table" and #ISMouseDrag.dragging > 0 then
        return
    end

    -- Skip filtering during active timed actions to avoid interference with transfers
    if ISTimedActionQueue and ISTimedActionQueue.hasAction then
        local queue = ISTimedActionQueue.getTimedActionQueue(player)
        if queue and ISTimedActionQueue.hasAction(queue) then
            return
        end
    end

    local playerNum = player:getPlayerNum()

    local lootWindow = getPlayerLoot and getPlayerLoot(playerNum) or nil
    if lootWindow then
        if ensureInventoryFilterControls then pcall(ensureInventoryFilterControls, lootWindow) end
        pcall(filterPane, lootWindow.inventoryPane, lootWindow, true)
    end

    local invWindow = getPlayerInventory and getPlayerInventory(playerNum) or nil
    if invWindow then
        if ensureInventoryFilterControls then pcall(ensureInventoryFilterControls, invWindow) end
        pcall(filterPane, invWindow.inventoryPane, invWindow, false)
    end
end

refreshLootPane = function()
    local pane = getLootPane()
    if pane and pane.refreshContainer then
        pane:refreshContainer()
    end
    csrApplyAllFilters()
end
-- ─────────────────────────────────────────────────────
-- v1.8.25: Filter UI is now a dropdown attached to the F button.
-- The old floating LootFilterPanel was deleted. All filter engine
-- state still lives in player modData via getState().
-- ─────────────────────────────────────────────────────

local function getFilterButton(playerNum)
    local invWindow = getPlayerInventory and getPlayerInventory(playerNum) or nil
    local lootWindow = getPlayerLoot and getPlayerLoot(playerNum) or nil
    if lootWindow and lootWindow.csrFilterBtn then return lootWindow.csrFilterBtn end
    if invWindow and invWindow.csrFilterBtn then return invWindow.csrFilterBtn end
    return nil
end

local function checkmark(on)
    return on and "[X] " or "[ ] "
end

local function openFilterDropdown(anchor)
    if not CSR_FeatureFlags.isLootFilterEnabled() then return end
    local player = getPlayerSafe()
    if not player then return end
    local state = getState()
    if not state then return end
    local playerNum = player:getPlayerNum()

    local btn = anchor or getFilterButton(playerNum)
    local x, y = 0, 0
    if btn and btn.getAbsoluteX then
        x = btn:getAbsoluteX()
        y = btn:getAbsoluteY() + (btn.height or 22)
    else
        x = getMouseX and getMouseX() or 0
        y = getMouseY and getMouseY() or 0
    end

    local context = ISContextMenu.get(playerNum, x, y)

    -- Master ON/OFF
    context:addOption(checkmark(state.enabled) .. "Filter " .. (state.enabled and "ON" or "OFF"), nil, function()
        local s = getState(); if not s then return end
        s.enabled = s.enabled ~= true
        refreshLootPane()
    end)

    -- Hide equipped
    context:addOption(checkmark(state.hideEquipped) .. (getText("IGUI_CSR_FilterHideEquipped") or "Hide Equipped Items"), nil, function()
        local s = getState(); if not s then return end
        s.hideEquipped = s.hideEquipped ~= true
        refreshLootPane()
        local pl = getPlayerSafe()
        if pl then
            local pn = pl:getPlayerNum()
            local invWindow = getPlayerInventory and getPlayerInventory(pn) or nil
            if invWindow and invWindow.inventoryPane and invWindow.inventoryPane.refreshContainer then
                invWindow.inventoryPane:refreshContainer()
                filterPane(invWindow.inventoryPane, invWindow, false)
            end
        end
    end)

    -- Categories grouped via submenus
    local groupOrder = { "Apparel", "Household", "Literature", "Trash", "Personal" }
    local grouped = {}
    for _, f in ipairs(FILTERS) do
        grouped[f.group] = grouped[f.group] or {}
        table.insert(grouped[f.group], f)
    end

    for _, gname in ipairs(groupOrder) do
        local entries = grouped[gname]
        if entries then
            -- Count active in this group for label hint
            local activeCount = 0
            for _, f in ipairs(entries) do
                if state.filters[f.key] then activeCount = activeCount + 1 end
            end
            local label = string.format(getText("IGUI_CSR_FilterCategories") or "Categories: %s", gname)
            if activeCount > 0 then label = label .. " (" .. activeCount .. ")" end
            local opt = context:addOption(label, nil, nil)
            local sub = ISContextMenu:getNew(context)
            context:addSubMenu(opt, sub)
            for _, f in ipairs(entries) do
                local on = state.filters[f.key] == true
                local subOpt = sub:addOption(checkmark(on) .. f.key, nil, function()
                    local s = getState(); if not s then return end
                    s.filters[f.key] = s.filters[f.key] ~= true
                    refreshLootPane()
                end)
                if f.tooltip and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addToolTip then
                    subOpt.toolTip = ISInventoryPaneContextMenu.addToolTip()
                    subOpt.toolTip.description = f.tooltip
                end
            end
        end
    end

    -- Whitelist editor
    context:addOption(getText("IGUI_CSR_FilterEditWhitelist") or "Edit Whitelist...", nil, function()
        local s = getState(); if not s then return end
        local modal = ISTextBox:new(getCore():getScreenWidth() / 2 - 200, getCore():getScreenHeight() / 2 - 80,
            400, 160,
            getText("IGUI_CSR_FilterWhitelistPrompt") or "Whitelist (comma-separated full types or search text):",
            s.whitelistRaw or "", nil, function(self, btn)
                if btn.internal == "OK" then
                    local st = getState()
                    if st then
                        st.whitelistRaw = self.entry:getText() or ""
                        rebuildWhitelist(st)
                        refreshLootPane()
                    end
                end
            end)
        modal:initialise()
        modal:addToUIManager()
    end)

    -- Reset
    context:addOption(getText("IGUI_CSR_FilterResetAll") or "Reset All Filters", nil, function()
        local s = getState(); if not s then return end
        applyDefaultFilters(s)
        rebuildWhitelist(s)
        refreshLootPane()
    end)

    -- Wire context to be rendered
    if context.setVisible then context:setVisible(true) end
    return context
end

CSR_LootFilter.openFilterDropdown = openFilterDropdown

-- ─────────────────────────────────────────────────────
-- Search bar + F button (inline in inventory + loot window headers)
-- ─────────────────────────────────────────────────────

local SEARCH_BAR_H = 22
local FILTER_BTN_W = 48
local _overridesInstalled = false

local function uiDim(ui, methodName, fieldName)
    if not ui then return 0 end
    if methodName and type(ui[methodName]) == "function" then
        return tonumber(ui[methodName](ui)) or 0
    end
    return tonumber(ui[fieldName]) or 0
end

local function isTrashLootWindow(page)
    if not page or page.onCharacter then return false end
    local controls = page.controlsUI
    if not controls or not controls.getDisplayedObject then return false end
    local obj = controls:getDisplayedObject()
    if not obj or not instanceof(obj, "IsoObject") then return false end
    local sprite = obj.getSprite and obj:getSprite() or nil
    local props = sprite and sprite.getProperties and sprite:getProperties() or nil
    return props and props:has("IsTrashCan") == true
end

local function layoutInventoryFilterControls(page)
    if not page or not page.csrSearchEntry or not page.csrFilterBtn then return end
    if not page.titleBarHeight then return end

    local titleBarH = page:titleBarHeight()
    local pageW = uiDim(page, "getWidth", "width")
    local pageH = uiDim(page, "getHeight", "height")
    local buttonSize = page.buttonSize or 0
    local pad = 2
    local availW = math.max(96, pageW - buttonSize - (pad * 2))
    local entryW = availW - FILTER_BTN_W - pad
    if entryW < 80 then entryW = math.max(48, availW - FILTER_BTN_W - pad) end
    local rowY = titleBarH
    local visible = page.isCollapsed ~= true
    local suppressForTrash = visible and isTrashLootWindow(page)
    local controlsVisible = visible and not suppressForTrash
    local paneY = titleBarH + (controlsVisible and SEARCH_BAR_H or 0)
    page.csrLootFilterSuppressed = suppressForTrash == true

    page.csrSearchEntry:setX(pad)
    page.csrSearchEntry:setY(rowY)
    page.csrSearchEntry:setWidth(entryW)
    page.csrSearchEntry:setHeight(SEARCH_BAR_H)
    page.csrSearchEntry:setVisible(controlsVisible)

    page.csrFilterBtn:setX(pad + entryW + pad)
    page.csrFilterBtn:setY(rowY)
    page.csrFilterBtn:setWidth(FILTER_BTN_W)
    page.csrFilterBtn:setHeight(SEARCH_BAR_H)
    page.csrFilterBtn:setVisible(controlsVisible)

    if visible and page.inventoryPane then
        local resizeH = uiDim(page.resizeWidget, "getHeight", "height")
        local controlsH = uiDim(page.controlsUI, "getHeight", "height")
        local paneH = pageH - paneY - resizeH - controlsH
        if paneH < 1 then paneH = 1 end
        page.inventoryPane:setY(paneY)
        page.inventoryPane:setHeight(paneH)
    end

    if visible and page.containerButtonPanel then
        page.containerButtonPanel:setY(page.inventoryPane and page.inventoryPane.y or paneY)
        if page.inventoryPane then
            page.containerButtonPanel:setHeight(page.inventoryPane.height)
        end
        if page.backpacks and #page.backpacks > 0 and page.backpacks[#page.backpacks].getBottom
            and page.containerButtonPanel.setScrollHeight then
            page.containerButtonPanel:setScrollHeight(page.backpacks[#page.backpacks]:getBottom())
        end
    end

    if page.csrSearchEntry.bringToTop then page.csrSearchEntry:bringToTop() end
    if page.csrFilterBtn.bringToTop then page.csrFilterBtn:bringToTop() end
end

local function wipeArray(t)
    if not t then return end
    if table.wipe then
        table.wipe(t)
        return
    end
    for k, _ in pairs(t) do
        t[k] = nil
    end
end

local function getTextFallback(key, fallback)
    if getTextOrNull then
        local text = getTextOrNull(key)
        if text then return text end
    end
    if getText then
        local text = getText(key)
        if text then return text end
    end
    return fallback or key
end

local function isUsableContainer(container)
    return container
        and container.getType
        and container.getItems
        and container.getEffectiveCapacity
end

local function addContainedBags(page, container)
    if not page or not isUsableContainer(container) then return end
    local items = container:getItems()
    if not items or not items.size or not items.get then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.getCategory and item:getCategory() == "Container"
            and item.getInventory and item:getInventory() then
            local itemContainer = item:getInventory()
            if isUsableContainer(itemContainer) and itemContainer:getType() ~= nil then
                local button = page:addContainerButton(
                    itemContainer,
                    item.getTex and item:getTex() or nil,
                    item.getName and item:getName() or "",
                    item.getName and item:getName() or ""
                )
                if button and item.getVisual and item.getClothingItem
                    and item:getVisual() and item:getClothingItem() then
                    local tint = item:getVisual():getTint(item:getClothingItem())
                    if tint then
                        button:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
                    end
                end
            end
        end
    end
end

local function addVehiclePartContainer(page, vehicle, playerObj, partIndex, truckBedPass)
    if not page or not vehicle or not vehicle.getPartByIndex then return end
    local part = vehicle:getPartByIndex(partIndex)
    if not part or not part.getItemContainer then return end

    local container = part:getItemContainer()
    if not isUsableContainer(container) then return end

    local partId = part.getId and part:getId() or nil
    local isTruckBed = partId == "TruckBed"
    if isTruckBed ~= truckBedPass then return end

    local containerType = container:getType()
    if containerType == nil then return end
    local titleKey = "IGUI_VehiclePart" .. tostring(containerType or partId or "Container")
    local title = getTextFallback(titleKey, tostring(containerType or partId or "Container"))
    local button = page:addContainerButton(container, nil, title, title)
    if button and page.checkExplored then
        page:checkExplored(button.inventory, playerObj)
    end

    if partId ~= "GloveBox" then
        addContainedBags(page, container)
    end
end

local function finishSafeRefresh(page, playerObj, oldNumBackpacks)
    if triggerEvent then
        triggerEvent("OnRefreshInventoryWindowContainers", page, "buttonsAdded")
    end

    local found = false
    local foundIndex = -1
    for index, containerButton in ipairs(page.backpacks) do
        if page.inventoryPane and containerButton.inventory == page.inventoryPane.inventory then
            foundIndex = index
            found = true
            break
        end
    end

    if page.buttonPool then
        for _, button in ipairs(page.buttonPool) do
            if page.mouseOverColoredContainer and page.getContainerParent
                and page:getContainerParent(button.inventory) == page.mouseOverColoredContainer then
                if page.stopHighlightContainer then
                    page:stopHighlightContainer(page.mouseOverColoredContainer)
                end
                page.mouseOverColoredContainer = nil
                break
            end
        end
    end

    if page.inventoryPane then
        page.inventoryPane.inventory = page.inventoryPane.lastinventory
        page.inventory = page.inventoryPane.inventory
    end

    if page.backpackChoice ~= nil and playerObj and playerObj.getJoypadBind
        and playerObj:getJoypadBind() ~= -1 then
        if not page.onCharacter and oldNumBackpacks == 1 and #page.backpacks > 1 then
            page.backpackChoice = 1
        end
        if page.backpackChoice > #page.backpacks then
            page.backpackChoice = 1
        end
        if page.backpacks[page.backpackChoice] ~= nil and page.inventoryPane then
            page.inventoryPane.inventory = page.backpacks[page.backpackChoice].inventory
            page.capacity = page.backpacks[page.backpackChoice].capacity
        end
    elseif page.inventoryPane then
        if not page.onCharacter and oldNumBackpacks == 1 and #page.backpacks > 1 then
            page.inventoryPane.inventory = page.backpacks[1].inventory
            page.capacity = page.backpacks[1].capacity
        elseif found then
            page.inventoryPane.inventory = page.backpacks[foundIndex].inventory
            page.capacity = page.backpacks[foundIndex].capacity
        elseif not found and #page.backpacks > 0 then
            page.inventoryPane.inventory = page.backpacks[1].inventory
            page.capacity = page.backpacks[1].capacity
        elseif page.inventoryPane.lastinventory ~= nil then
            page.inventoryPane.inventory = page.inventoryPane.lastinventory
        end
    end

    if page.forceSelectedContainer then
        if page.forceSelectedContainerTime and page.forceSelectedContainerTime > getTimestampMs() then
            for _, containerButton in ipairs(page.backpacks) do
                if containerButton.inventory == page.forceSelectedContainer and page.inventoryPane then
                    page.inventoryPane.inventory = containerButton.inventory
                    page.capacity = containerButton.capacity
                    break
                end
            end
        else
            page.forceSelectedContainer = nil
        end
    end

    if page.inventoryPane and page.inventoryPane.bringToTop then page.inventoryPane:bringToTop() end
    if page.resizeWidget2 and page.resizeWidget2.bringToTop then page.resizeWidget2:bringToTop() end
    if page.resizeWidget and page.resizeWidget.bringToTop then page.resizeWidget:bringToTop() end

    page.inventory = page.inventoryPane and page.inventoryPane.inventory or page.inventory
    page.title = nil
    page.selectedButton = nil
    for _, containerButton in ipairs(page.backpacks) do
        if containerButton.inventory == page.inventory then
            page.selectedButton = containerButton
            containerButton:setBackgroundRGBA(0.7, 0.7, 0.7, 1.0)
            page.title = containerButton.name
        else
            containerButton:setBackgroundRGBA(0.0, 0.0, 0.0, 0.0)
        end
    end

    if page.inventoryPane and page.inventoryPane.refreshContainer then
        page.inventoryPane:refreshContainer()
    end
    if page.refreshWeight then page:refreshWeight() end
    if page.updateItemCount then page:updateItemCount() end

    if page.controlsUI and page.controlsUI.arrange then
        page.controlsUI:arrange()
    end
    if page.inventoryPane and page.resizeWidget and page.controlsUI then
        page.inventoryPane:setHeight(page.height - page.inventoryPane.y - page.resizeWidget.height - page.controlsUI.height)
    end
    if page.containerButtonPanel and page.inventoryPane then
        page.containerButtonPanel:setHeight(page.inventoryPane.height)
        page.containerButtonPanel:setY(page.inventoryPane.y)
        if #page.backpacks > 0 and page.containerButtonPanel.setScrollHeight
            and page.backpacks[#page.backpacks].getBottom then
            page.containerButtonPanel:setScrollHeight(page.backpacks[#page.backpacks]:getBottom())
        end
    end

    if triggerEvent then
        triggerEvent("OnRefreshInventoryWindowContainers", page, "end")
    end
end

local function safeRefreshVehicleBackpacks(page, playerObj, vehicle)
    if not page or not playerObj or not vehicle or not vehicle.getPartCount then return false end
    if not page.inventoryPane or not page.containerButtonPanel or not page.addContainerButton then return false end

    if ISHandCraftPanel then ISHandCraftPanel.drawDirty = true end
    if ISBuildPanel then ISBuildPanel.drawDirty = true end

    page.buttonPool = page.buttonPool or {}
    for i, button in ipairs(page.backpacks) do
        page.containerButtonPanel:removeChild(button)
        table.insert(page.buttonPool, i, button)
    end

    page.inventoryPane.lastinventory = page.inventoryPane.inventory
    if page.inventoryPane.hideButtons then page.inventoryPane:hideButtons() end

    local oldNumBackpacks = #page.backpacks
    wipeArray(page.backpacks)

    if triggerEvent then
        triggerEvent("OnRefreshInventoryWindowContainers", page, "begin")
    end

    local partCount = vehicle:getPartCount()
    if type(partCount) ~= "number" or partCount <= 0 then
        finishSafeRefresh(page, playerObj, oldNumBackpacks)
        return true
    end

    -- B42 can throw inside vehicle access checks while a vehicle layout is
    -- settling. When the player is inside the vehicle, keep the loot page alive
    -- by showing valid item containers and skipping only invalid part records.
    for partIndex = 0, partCount - 1 do
        addVehiclePartContainer(page, vehicle, playerObj, partIndex, false)
    end
    for partIndex = 0, partCount - 1 do
        addVehiclePartContainer(page, vehicle, playerObj, partIndex, true)
    end

    finishSafeRefresh(page, playerObj, oldNumBackpacks)
    return true
end

local function trySafeRefreshBackpacks(page)
    if not page or page.onCharacter then return false end
    local playerObj = getSpecificPlayer and getSpecificPlayer(page.player) or nil
    local vehicle = playerObj and playerObj.getVehicle and playerObj:getVehicle() or nil
    if not vehicle then return false end
    return safeRefreshVehicleBackpacks(page, playerObj, vehicle)
end

local function installInventoryOverrides()
    if _overridesInstalled then return end
    if not ISInventoryPage then return end
    _overridesInstalled = true

    function ISInventoryPage:csrOnSearchChange(entry)
        if self.inventoryPane and self.inventoryPane.refreshContainer then
            self.inventoryPane:refreshContainer()
        end
        local applyCategories = not self.onCharacter
        filterPane(self.inventoryPane, self, applyCategories)
    end

    function ISInventoryPage:csrOnFilterToggle()
        openFilterDropdown(self.csrFilterBtn)
    end

    ensureInventoryFilterControls = function(page)
        if not page then return end
        if not CSR_FeatureFlags.isLootFilterEnabled() then return end
        if not page.titleBarHeight then return end

        if not page.csrSearchEntry then
            page.csrSearchEntry = ISTextEntryBox:new("", 2, page:titleBarHeight(), 120, SEARCH_BAR_H)
            page.csrSearchEntry.anchorRight = true
            page.csrSearchEntry:initialise()
            page.csrSearchEntry:instantiate()
            page.csrSearchEntry:setPlaceholderText(getText("IGUI_CSR_SearchPlaceholder") or "Search...")
            if page.csrSearchEntry.setClearButton then page.csrSearchEntry:setClearButton(true) end
            page.csrSearchEntry.target = page
            page.csrSearchEntry.onTextChangeFunction = ISInventoryPage.csrOnSearchChange
            page:addChild(page.csrSearchEntry)
        end

        if not page.csrFilterBtn then
            local label = getText("IGUI_CSR_FilterBtnLabel") or "Filter"
            page.csrFilterBtn = ISButton:new(0, page:titleBarHeight(),
                FILTER_BTN_W, SEARCH_BAR_H, label, page, ISInventoryPage.csrOnFilterToggle)
            page.csrFilterBtn.anchorRight = true
            page.csrFilterBtn.anchorLeft = false
            page.csrFilterBtn:initialise()
            page.csrFilterBtn:instantiate()
            page.csrFilterBtn.tooltip = getText("Tooltip_CSR_FilterOpenMenu")
            page.csrFilterBtn.borderColor = {r = 0.55, g = 0.55, b = 0.55, a = 0.95}
            page.csrFilterBtn.backgroundColor = {r = 0.18, g = 0.18, b = 0.20, a = 0.95}
            page.csrFilterBtn.backgroundColorMouseOver = {r = 0.32, g = 0.32, b = 0.34, a = 0.95}
            local _origPrerender = page.csrFilterBtn.prerender
            page.csrFilterBtn.prerender = function(btn)
                local st = getState()
                local hasCat = false
                if st and st.filters then
                    for _, f in ipairs(FILTERS) do
                        if st.filters[f.key] then hasCat = true; break end
                    end
                end
                local active = (st and st.enabled == true and hasCat) or (st and st.hideEquipped == true)
                if active then
                    btn.borderColor = {r = 0.95, g = 0.30, b = 0.30, a = 1.0}
                    btn.backgroundColor = {r = 0.40, g = 0.10, b = 0.10, a = 0.95}
                    btn.tooltip = getText("Tooltip_CSR_FilterActive")
                else
                    btn.borderColor = {r = 0.55, g = 0.55, b = 0.55, a = 0.95}
                    btn.backgroundColor = {r = 0.18, g = 0.18, b = 0.20, a = 0.95}
                    btn.tooltip = getText("Tooltip_CSR_FilterOpenMenu")
                end
                if _origPrerender then return _origPrerender(btn) end
            end
            page:addChild(page.csrFilterBtn)
        end

        layoutInventoryFilterControls(page)
    end

    local _origCreateChildren = ISInventoryPage.createChildren
    function ISInventoryPage:createChildren()
        _origCreateChildren(self)

        -- v1.8.x: filter button is now shown on BOTH the loot pane and the
        -- player's own inventory pane (previously loot-only). On the player
        -- pane the dropdown still toggles the same global filter state -- it
        -- gives users a visible entry point without remembering the hotkey.
        ensureInventoryFilterControls(self)
    end

    local function applyInventoryFilterLayout(page)
        if ensureInventoryFilterControls then pcall(ensureInventoryFilterControls, page) end
        if layoutInventoryFilterControls then pcall(layoutInventoryFilterControls, page) end
    end

    -- Keep pane movement in vanilla layout/update passes so mouse hit testing
    -- uses the same geometry the player sees.
    local _origUpdate = ISInventoryPage.update
    function ISInventoryPage:update(...)
        _origUpdate(self, ...)
        applyInventoryFilterLayout(self)
    end

    local _origRefreshBackpacks = ISInventoryPage.refreshBackpacks
    function ISInventoryPage:refreshBackpacks(...)
        if not trySafeRefreshBackpacks(self) then
            _origRefreshBackpacks(self, ...)
        end
        applyInventoryFilterLayout(self)
    end

    if ISInventoryPage.onInventoryContainerSizeChanged then
        local _origOnInventoryContainerSizeChanged = ISInventoryPage.onInventoryContainerSizeChanged
        function ISInventoryPage:onInventoryContainerSizeChanged(...)
            _origOnInventoryContainerSizeChanged(self, ...)
            applyInventoryFilterLayout(self)
        end
    end
end

local function toggleHideEquipped()
    local state = getState()
    if not state then return end

    state.hideEquipped = state.hideEquipped ~= true

    refreshLootPane()
    local player = getPlayerSafe()
    if player then
        local playerNum = player:getPlayerNum()
        local invWindow = getPlayerInventory and getPlayerInventory(playerNum) or nil
        if invWindow and invWindow.inventoryPane and invWindow.inventoryPane.refreshContainer then
            invWindow.inventoryPane:refreshContainer()
            filterPane(invWindow.inventoryPane, invWindow, false)
        end
    end
end

local function onKeyPressed(key)
    if key == getBoundKey() then
        openFilterDropdown()
    end
    if key == getHideEquippedKey() then
        toggleHideEquipped()
    end
end

local function onGameStart()
    installInventoryOverrides()
    local state = getState()
    rebuildWhitelist(state)
    csrApplyAllFilters()
end

local function onCreatePlayer()
    installInventoryOverrides()
    local state = getState()
    rebuildWhitelist(state)
    csrApplyAllFilters()
end

if Events then
    -- v1.8.7: defer event registration to OnGameStart and gate on the
    -- feature flag (Phoenix II). Events that fire on every container refresh
    -- and every keypress are skipped entirely on installs that disable the
    -- loot filter.
    local _csrLootFilterRegistered = false
    local function csrEnsureLootFilterRegistered()
        if _csrLootFilterRegistered then return end
        if not (CSR_FeatureFlags and CSR_FeatureFlags.isLootFilterEnabled
            and CSR_FeatureFlags.isLootFilterEnabled()) then return end
        _csrLootFilterRegistered = true
        if Events.OnKeyPressed then Events.OnKeyPressed.Add(onKeyPressed) end
        if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end
        if Events.OnRefreshInventoryWindowContainers then Events.OnRefreshInventoryWindowContainers.Add(csrApplyAllFilters) end
        onGameStart()
    end
    if Events.OnGameStart then Events.OnGameStart.Add(csrEnsureLootFilterRegistered) end
end

return CSR_LootFilter

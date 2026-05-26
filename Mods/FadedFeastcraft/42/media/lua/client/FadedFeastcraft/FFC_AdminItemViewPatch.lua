require "FadedFeastcraft/FFC_Boot"

FadedFeastcraft = FadedFeastcraft or {}

local SourcePacks = FadedFeastcraft.SourcePackRegistry

local FFC_ADMIN_TAB = "FadedFeastcraft"

local FFC_MODULES = {
    FadedFeastcraft = true,
    VFX = true,
    AbuelitaLinda = true,
    Ted = true,
    SnackTime89 = true,
    MR = true,
    AdvancedDrying42 = true,
    DriedFoodMod = true,
    ExtraCraft = true,
    MattSimpleAddons = true,
}

local FFC_BASE_HINTS = {
    "vfx",
    "canof",
    "canned",
    "jarfood",
    "ffc_",
}

local function safeCall(obj, methodName, ...)
    if not obj or not methodName or type(obj[methodName]) ~= "function" then return nil end
    local ok, result = pcall(obj[methodName], obj, ...)
    if ok then return result end
    return nil
end

local function safeText(value)
    if value == nil then return "" end
    if type(value) == "string" then return value end
    if type(value) == "number" or type(value) == "boolean" then return tostring(value) end
    if type(value.toString) == "function" then
        local ok, result = pcall(function() return value:toString() end)
        if ok and result ~= nil then return tostring(result) end
    end
    return tostring(value or "")
end

local function lower(value)
    return string.lower(safeText(value))
end

local function fullTypeFor(item)
    return safeText(safeCall(item, "getFullName") or safeCall(item, "getFullType") or safeCall(item, "getName"))
end

local function moduleNameFor(item)
    return safeText(safeCall(item, "getModuleName"))
end

local function itemListSafe(item)
    if not item then return false end
    if safeCall(item, "getItemType") == nil then return false end
    if safeCall(item, "getDisplayName") == nil then return false end
    return true
end

local function isFadedFeastcraftItem(item)
    local moduleName = moduleNameFor(item)
    if FFC_MODULES[moduleName] then return true end

    local fullType = fullTypeFor(item)
    if SourcePacks and SourcePacks.sourceForFullType and SourcePacks.sourceForFullType(fullType) then
        return true
    end

    if moduleName == "Base" then
        local probe = lower(fullType)
        for _, hint in ipairs(FFC_BASE_HINTS) do
            if string.find(probe, hint, 1, true) then return true end
        end
    end

    return false
end

local function addItemToModule(viewer, moduleNames, moduleSeen, moduleName, item)
    if not viewer.module[moduleName] then
        viewer.module[moduleName] = {}
        if not moduleSeen[moduleName] then
            moduleSeen[moduleName] = true
            moduleNames[#moduleNames + 1] = moduleName
        end
    end
    viewer.module[moduleName][#viewer.module[moduleName] + 1] = item
end

local function patchAdminItemViewer()
    pcall(require, "ISUI/AdminPanel/ISItemsListTable")
    pcall(require, "ISUI/AdminPanel/ISItemsListViewer")

    if not ISItemsListViewer or not ISItemsListTable then return end
    if ISItemsListViewer._ffcConsolidatedTabs then return end
    ISItemsListViewer._ffcConsolidatedTabs = true

    function ISItemsListViewer:initList()
        self.items = getAllItems()
        self.module = {}

        local moduleNames = {}
        local moduleSeen = {}
        local allItems = {}
        local skipped = 0

        for i = 0, self.items:size() - 1 do
            local item = self.items:get(i)
            if item and safeCall(item, "getObsolete") ~= true and safeCall(item, "isHidden") ~= true then
                if itemListSafe(item) then
                    local moduleName = isFadedFeastcraftItem(item) and FFC_ADMIN_TAB or moduleNameFor(item)
                    if moduleName == "" then moduleName = "Unknown" end
                    addItemToModule(self, moduleNames, moduleSeen, moduleName, item)
                    allItems[#allItems + 1] = item
                else
                    skipped = skipped + 1
                end
            end
        end

        if skipped > 0 then
            print("[FFC] Admin Item Viewer skipped " .. tostring(skipped) .. " malformed item(s).")
        end

        table.sort(moduleNames, function(a, b) return not string.sort(a, b) end)

        local listBox = ISItemsListTable:new(0, 0, self.panel.width, self.panel.height - self.panel.tabHeight, self)
        listBox:initialise()
        self.panel:addView("All", listBox)
        listBox:initList(allItems)

        for _, moduleName in ipairs(moduleNames) do
            if moduleName ~= "Moveables" then
                local tab = ISItemsListTable:new(0, 0, self.panel.width, self.panel.height - self.panel.tabHeight, self)
                tab:initialise()
                self.panel:addView(moduleName, tab)
                tab:initList(self.module[moduleName])
            end
        end

        self.panel:activateView("All")
    end
end

FadedFeastcraft.PatchAdminItemViewer = patchAdminItemViewer

if Events and Events.OnGameBoot and not FadedFeastcraft.AdminItemViewPatchBootRegistered then
    FadedFeastcraft.AdminItemViewPatchBootRegistered = true
    Events.OnGameBoot.Add(patchAdminItemViewer)
end

if Events and Events.OnGameStart and not FadedFeastcraft.AdminItemViewPatchGameRegistered then
    FadedFeastcraft.AdminItemViewPatchGameRegistered = true
    Events.OnGameStart.Add(patchAdminItemViewer)
end

patchAdminItemViewer()

return FadedFeastcraft.PatchAdminItemViewer

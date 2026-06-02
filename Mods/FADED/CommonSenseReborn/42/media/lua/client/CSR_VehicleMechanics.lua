require "CSR_FeatureFlags"

CSR_VehicleMechanics = CSR_VehicleMechanics or {}

local CATEGORY_DEFS = {
    {
        key = "tires",
        label = getText("ContextMenu_CSR_UninstallAllTires"),
        include = { "tire" },
        exclude = { "spare", "carrier", "cover" },
    },
    {
        key = "lights",
        label = getText("ContextMenu_CSR_UninstallAllLights"),
        include = { "headlight", "headlamp", "taillight", "taillamp", "rearlight", "lightrear", "brakelight", "spotlight", "lamp" },
        exclude = { "interior", "dashboard", "cab", "dome", "glove", "roomlight" },
    },
    {
        key = "windows",
        label = getText("ContextMenu_CSR_UninstallAllWindows"),
        include = { "window" },
        exclude = {},
    },
    {
        key = "doors",
        label = getText("ContextMenu_CSR_UninstallAllDoors"),
        include = { "door" },
        exclude = { "window" },
    },
    {
        key = "seats",
        label = getText("ContextMenu_CSR_UninstallAllSeats"),
        include = { "seat" },
        exclude = {},
    },
    {
        key = "brakes",
        label = getText("ContextMenu_CSR_UninstallAllBrakes"),
        include = { "brake" },
        exclude = {},
    },
    {
        key = "suspension",
        label = getText("ContextMenu_CSR_UninstallAllSuspension"),
        include = { "suspension" },
        exclude = {},
    },
}

local function partIdMatches(part, category)
    local partId = part and part.getId and string.lower(part:getId() or "") or ""
    if partId == "" then
        return false
    end

    for _, excluded in ipairs(category.exclude or {}) do
        if string.find(partId, excluded, 1, true) then
            return false
        end
    end

    for _, included in ipairs(category.include or {}) do
        if string.find(partId, included, 1, true) then
            return true
        end
    end

    return false
end

local function playerHasVehicleAccess(player, vehicle)
    local ok, result = pcall(function()
        for i = 0, vehicle:getPartCount() - 1 do
            local part = vehicle:getPartByIndex(i)
            if VehicleUtils.RequiredKeyNotFound(part, player) then
                return false
            end
        end
        return true
    end)
    return ok and result
end

-- ==========================================
-- Dependency resolution (adapted from Better Auto Mechanics)
-- Recursively finds parts that must be uninstalled before a given part
-- ==========================================
local function getRequiredUninstalledParts(part)
    local required = {}
    local ok, keyvalues = pcall(part.getTable, part, "uninstall")
    if not ok or not keyvalues or not keyvalues.requireUninstalled then return required end

    local splitOk, split = pcall(function()
        local result = {}
        for token in string.gmatch(keyvalues.requireUninstalled, "[^;]+") do
            table.insert(result, token)
        end
        return result
    end)
    if not splitOk or not split then return required end

    local vehicle = part:getVehicle()
    for _, partId in ipairs(split) do
        local reqPart = vehicle:getPartById(partId)
        if reqPart then
            -- Recursively resolve deeper dependencies
            local deeper = getRequiredUninstalledParts(reqPart)
            for _, dp in ipairs(deeper) do
                table.insert(required, dp)
            end
            table.insert(required, reqPart)
        end
    end
    return required
end

-- ==========================================
-- Recipe display (safe)
-- ==========================================
local function getRecipeDisplay(recipe)
    if type(getRecipeDisplayName) ~= "function" then return tostring(recipe) end
    local displayName = getRecipeDisplayName(recipe)
    if not displayName then return tostring(recipe) end
    if type(getText) ~= "function" then return tostring(displayName) end
    return getText("Tooltip_vehicle_requireRecipe", displayName) or tostring(displayName)
end

local function getRequiredRecipes(parts, player)
    local recipes = {}
    for _, part in ipairs(parts) do
        if part and part.getTable then
            local keyvalues = part:getTable("uninstall")
            if keyvalues and keyvalues.recipes and type(keyvalues.recipes) == "string" and keyvalues.recipes ~= "" then
                for token in string.gmatch(keyvalues.recipes, "[^;]+") do
                    if token and token ~= "" then
                        local known = player and player.isRecipeKnown and player:isRecipeKnown(token, true) or false
                        recipes[token] = known
                    end
                end
            end
        end
    end
    return recipes
end

-- ==========================================
-- Tool detection with color-coded inventory check (inspired by BAM)
-- ==========================================
local function getRequiredToolsWithStatus(parts, player)
    local tools = {}
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory then return tools end

    -- Phase 1: Collect raw tool IDs/tags from all parts
    local rawTools = {}
    for _, part in ipairs(parts) do
        local ok, keyvalues = true, nil
        if part and part.getTable then
            ok, keyvalues = pcall(function() return part:getTable("uninstall") end)
            if not ok then keyvalues = nil end
        end
        if keyvalues and keyvalues.items then
            local itemsTable = {}
            if type(keyvalues.items) == "string" then
                for token in string.gmatch(keyvalues.items, "[^;]+") do
                    table.insert(itemsTable, token)
                end
            elseif type(keyvalues.items) == "table" then
                itemsTable = keyvalues.items
            end

            for _, toolDef in pairs(itemsTable) do
                if type(toolDef) == "table" then
                    if toolDef.type and type(toolDef.type) == "string" then
                        local toolID = string.gsub(toolDef.type, "%s+", "")
                        if not string.find(toolID, "%.") then toolID = "Base." .. toolID end
                        rawTools[toolID] = false
                    elseif toolDef.tags and type(toolDef.tags) == "string" then
                        local tagID = string.gsub(toolDef.tags, "%s+", "")
                        rawTools[tagID] = true
                    end
                elseif type(toolDef) == "string" then
                    local toolID = string.match(toolDef, "^([^=]+)") or toolDef
                    toolID = string.gsub(toolID, "%s+", "")
                    if toolID ~= "" then
                        if not string.find(toolID, "%.") then toolID = "Base." .. toolID end
                        rawTools[toolID] = false
                    end
                end
            end
        end
    end

    -- Phase 2: Determine which tool categories are needed (matches BAM approach)
    local needsScrewdriver = false
    local needsWrench = false
    local needsLugWrench = false
    local needsJack = false

    for toolID, _ in pairs(rawTools) do
        local low = string.lower(toolID)
        if string.find(low, "screwdriver") then
            needsScrewdriver = true
        elseif string.find(low, "lug") then
            needsLugWrench = true
        elseif string.find(low, "wrench") then
            needsWrench = true
        elseif string.find(low, "jack") then
            needsJack = true
        end
    end

    -- Phase 3: Check inventory using ItemTag constants (B42) with display names
    local scriptManager = getScriptManager()
    if not scriptManager then return tools end

    if needsScrewdriver then
        local hasIt = false
        if ItemTag and ItemTag.SCREWDRIVER then
            hasIt = inventory:getFirstTagRecurse(ItemTag.SCREWDRIVER) ~= nil
        end
        local name = "Screwdriver"
        local si = scriptManager:getItem("Base.Screwdriver")
        if si and si.getDisplayName then name = si:getDisplayName() end
        local mn = scriptManager:getItem("Base.Multitool")
        if mn and mn.getDisplayName then name = name .. " / " .. mn:getDisplayName() end
        tools.screwdriver = { name = name, owned = hasIt }
    end

    if needsWrench then
        local hasIt = false
        if ItemTag and ItemTag.WRENCH then
            hasIt = inventory:getFirstTagRecurse(ItemTag.WRENCH) ~= nil
        end
        local name = "Wrench"
        local si = scriptManager:getItem("Base.Wrench")
        if si and si.getDisplayName then name = si:getDisplayName() end
        local rn = scriptManager:getItem("Base.Ratchet")
        if rn and rn.getDisplayName then name = name .. " / " .. rn:getDisplayName() end
        tools.wrench = { name = name, owned = hasIt }
    end

    if needsLugWrench then
        local hasIt = false
        if ItemTag and ItemTag.LUG_WRENCH then
            hasIt = inventory:getFirstTagRecurse(ItemTag.LUG_WRENCH) ~= nil
        end
        local name = "Lug Wrench"
        local si = scriptManager:getItem("Base.LugWrench")
        if si and si.getDisplayName then name = si:getDisplayName() end
        local tn = scriptManager:getItem("Base.TireIron")
        if tn and tn.getDisplayName then name = name .. " / " .. tn:getDisplayName() end
        tools.lugwrench = { name = name, owned = hasIt }
    end

    if needsJack then
        local hasIt = inventory:getFirstTypeRecurse("Jack") ~= nil
        local name = "Jack"
        local si = scriptManager:getItem("Base.Jack")
        if si and si.getDisplayName then name = si:getDisplayName() end
        tools.jack = { name = name, owned = hasIt }
    end

    return tools
end

-- ==========================================
-- Part collection
-- ==========================================
local function collectCategoryParts(player, vehicle, category)
    local parts = {}

    local pcOk, partCount = pcall(vehicle.getPartCount, vehicle)
    if not pcOk or not partCount then return parts end
    for i = 0, partCount - 1 do
        pcall(function()
            local part = vehicle:getPartByIndex(i)
            if part and part.getInventoryItem and part:getInventoryItem() and part.getTable and part:getTable("uninstall") and partIdMatches(part, category) then
                table.insert(parts, part)
            end
        end)
    end

    pcall(function()
        table.sort(parts, function(a, b)
            return tostring(a:getId() or "") < tostring(b:getId() or "")
        end)
    end)

    return parts
end

local function collectAvailableParts(player, vehicle, category)
    local parts = {}
    local seen = {}

    for _, part in ipairs(collectCategoryParts(player, vehicle, category)) do
        -- Add prerequisite parts that must be removed first (dependency resolution)
        local reqParts = getRequiredUninstalledParts(part)
        for _, rp in ipairs(reqParts) do
            if rp:getInventoryItem() and not seen[rp:getId()] then
                local canDo, canResult = pcall(function()
                    return rp:getVehicle():canUninstallPart(player, rp)
                end)
                if canDo and canResult then
                    seen[rp:getId()] = true
                    table.insert(parts, rp)
                end
            end
        end

        -- Add the target part itself
        if not seen[part:getId()] then
            local canDo, canResult = pcall(function()
                return part:getVehicle():canUninstallPart(player, part)
            end)
            if canDo and canResult then
                seen[part:getId()] = true
                table.insert(parts, part)
            end
        end
    end
    return parts
end

-- ==========================================
-- Tooltip builder (color-coded, crash-proof)
-- ==========================================
local function makeTooltip(player, vehicle, category, parts, availableParts)
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)

    local msg = "Sequentially uninstall " .. tostring(#availableParts) .. " part(s)."
    msg = msg .. " <LINE>Uses vanilla mechanics actions -- XP is awarded per part."

    -- Tool check using simple direct calls (no nested pcall)
    local tools = getRequiredToolsWithStatus(parts, player)
    if tools and type(tools) == "table" then
        local hasAny = false
        for _ in pairs(tools) do hasAny = true; break end
        if hasAny then
            msg = msg .. " <LINE> <LINE>Needs:"
            for _, info in pairs(tools) do
                local color = info.owned and "<GREEN>" or "<RED>"
                msg = msg .. " <LINE>" .. color .. " - " .. tostring(info.name)
            end
        end
    end

    -- Recipe check
    local recipes = getRequiredRecipes(parts, player)
    if recipes and type(recipes) == "table" then
        local hasAny = false
        for _ in pairs(recipes) do hasAny = true; break end
        if hasAny then
            msg = msg .. " <LINE> <LINE>Recipes:"
            for recipe, known in pairs(recipes) do
                local color = known and "<GREEN>" or "<RED>"
                local disp = getRecipeDisplay(recipe) or tostring(recipe)
                msg = msg .. " <LINE>" .. color .. " - " .. tostring(disp)
            end
        end
    end

    if not playerHasVehicleAccess(player, vehicle) then
        msg = msg .. " <LINE> <LINE><ORANGE>Vehicle access may block some parts."
    end

    if #availableParts < #parts then
        msg = msg .. " <LINE> <LINE><RGB:0.7,0.7,0.7>Some parts need prerequisites removed first."
    end

    tooltip.description = msg
    return tooltip
end

-- ==========================================
-- Batch uninstall: queue all parts via vanilla onUninstallPart
-- (simpler & more reliable than chain-on-complete; vanilla TimedActionQueue
-- already serializes each path + uninstall pair, and XP is awarded per part).
-- ==========================================
local function startBatchUninstall(player, category, vehicle)
    if not player or not category or not vehicle then return end

    ISTimedActionQueue.clear(player)

    local parts = collectAvailableParts(player, vehicle, category)
    if #parts == 0 then
        if player.setHaloNote then
            player:setHaloNote("No " .. tostring(category.label or "parts") .. " available", 255, 128, 128, 200)
        end
        return
    end

    -- Queue each uninstall via vanilla flow. onUninstallPart handles
    -- transferRequiredItems / equipRequiredItems / pathing / uninstall action.
    for _, part in ipairs(parts) do
        ISVehiclePartMenu.onUninstallPart(player, part)
    end

    if player.setHaloNote then
        player:setHaloNote("Queued " .. #parts .. " part(s) to uninstall", 128, 255, 128, 300)
    end
end

-- ==========================================
-- Patch ISVehicleMechanics to add our context menu
-- ==========================================
local function patchVehicleMechanics()
    if not ISVehicleMechanics or not ISVehicleMechanics.doPartContextMenu or not ISVehiclePartMenu or ISVehicleMechanics.__csr_mechanics_patched then
        return
    end

    ISVehicleMechanics.__csr_mechanics_patched = true

    local original_doPartContextMenu = ISVehicleMechanics.doPartContextMenu

    local emptyFixingList = {
        isEmpty = function() return true end,
        size = function() return 0 end,
        get = function() return nil end,
    }

    local function isUsableFixingList(fixingList)
        if not fixingList then
            return false
        end

        local ok = pcall(function()
            local _ = fixingList:isEmpty()
            local _ = fixingList:size()
        end)

        return ok
    end

    local function callOriginalPartContextMenu(selfObj, part, x, y)
        if not FixingManager or not FixingManager.getFixes then
            return original_doPartContextMenu(selfObj, part, x, y)
        end

        local partItem = nil
        pcall(function()
            partItem = part and part.getInventoryItem and part:getInventoryItem() or nil
        end)

        local originalGetFixes = FixingManager.getFixes
        local originalBuildFixingMenu = ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.buildFixingMenu or nil

        FixingManager.getFixes = function(item)
            if partItem and item == partItem then
                local ok, fixingList = pcall(function()
                    return originalGetFixes(item)
                end)
                if ok and isUsableFixingList(fixingList) then
                    return fixingList
                end
                return emptyFixingList
            end
            return originalGetFixes(item)
        end

        if originalBuildFixingMenu then
            ISInventoryPaneContextMenu.buildFixingMenu = function(...)
                local ok, result = pcall(originalBuildFixingMenu, ...)
                if ok then return result end
                print("[CSR] Vehicle mechanics repair option skipped: " .. tostring(result))
                return nil
            end
        end

        local ok, result = pcall(function()
            return original_doPartContextMenu(selfObj, part, x, y)
        end)

        FixingManager.getFixes = originalGetFixes
        if originalBuildFixingMenu then
            ISInventoryPaneContextMenu.buildFixingMenu = originalBuildFixingMenu
        end

        if not ok then
            print("[CSR] Vehicle mechanics context menu fallback: " .. tostring(result))
            if UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return nil end
            selfObj.context = ISContextMenu.get(selfObj.playerNum,
                (x or 0) + selfObj:getAbsoluteX(),
                (y or 0) + selfObj:getAbsoluteY())
            return nil
        end

        return result
    end

    local function isSafeForVanillaContextMenu(part)
        if not part then return false end

        local itemTypes = nil
        local ok = pcall(function()
            itemTypes = part:getItemType()
        end)
        if not ok then return false end

        if itemTypes ~= nil then
            local isEmpty = nil
            ok = pcall(function()
                isEmpty = itemTypes:isEmpty()
            end)
            if not ok then return false end

            if isEmpty == false then
                local typeCount = 0
                ok = pcall(function()
                    typeCount = itemTypes:size()
                end)
                if not ok or type(typeCount) ~= "number" then return false end

                if typeCount > 0 then
                    ok = pcall(function()
                        local _ = itemTypes:get(0)
                    end)
                    if not ok then return false end
                end

                local inventoryItem = nil
                ok = pcall(function()
                    inventoryItem = part:getInventoryItem()
                end)
                if not ok then return false end

                if inventoryItem then
                    local scriptPart = nil
                    ok = pcall(function()
                        scriptPart = part:getScriptPart()
                    end)
                    if not ok or not scriptPart then return false end

                    ok = pcall(function()
                        local _ = scriptPart:isRepairMechanic()
                    end)
                    if not ok then return false end
                end
            end
        end

        return true
    end

    function ISVehicleMechanics:doPartContextMenu(part, x, y, ...)
        -- Vanilla ISVehicleMechanics:doPartContextMenu can crash before
        -- our submenu attaches when modded parts expose incomplete Java
        -- data. Known B42.18 paths include:
        --     if part:getItemType() and not part:getItemType():isEmpty() then
        --     FixingManager.getFixes(part:getInventoryItem())
        --     if part:getScriptPart():isRepairMechanic() and not fixingList:isEmpty() then
        -- The repair lookup is guarded while vanilla builds the rest of its
        -- menu, so a bad fixing definition cannot block uninstall/install.
        local safeForVanilla = isSafeForVanillaContextMenu(part)

        local result = nil
        if safeForVanilla then
            result = callOriginalPartContextMenu(self, part, x, y)
        else
            -- Vanilla unsafe - open an empty context menu so our submenu
            -- can attach. Mirrors vanilla's first two lines.
            if UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return end
            self.context = ISContextMenu.get(self.playerNum,
                (x or 0) + self:getAbsoluteX(),
                (y or 0) + self:getAbsoluteY())
        end

        if not CSR_FeatureFlags.isVehicleMechanicsQoLEnabled() or not self.context or not self.vehicle or not self.chr then
            return result
        end

        local parent = self.context:addOption(getText("ContextMenu_CSR_VehicleWork"), nil, nil)
        parent.iconTexture = getTexture("Item_Wrench")

        local subMenu = ISContextMenu:getNew(self.context)
        self.context:addSubMenu(parent, subMenu)

        local anyEnabled = false
        for _, category in ipairs(CATEGORY_DEFS) do
            local parts = collectCategoryParts(self.chr, self.vehicle, category)
            local availableParts = collectAvailableParts(self.chr, self.vehicle, category)
            local label = category.label .. " (" .. tostring(#availableParts) .. ")"
            local option = subMenu:addOption(label, self.chr, startBatchUninstall, category, self.vehicle)
            option.toolTip = makeTooltip(self.chr, self.vehicle, category, parts, availableParts)
            if #availableParts == 0 then
                option.notAvailable = true
            else
                anyEnabled = true
            end
        end

        if not anyEnabled then
            parent.notAvailable = true
        end

        return result
    end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(patchVehicleMechanics)
end

return CSR_VehicleMechanics

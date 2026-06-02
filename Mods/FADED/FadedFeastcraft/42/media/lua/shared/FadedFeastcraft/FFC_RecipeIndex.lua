require "FadedFeastcraft/FFC_Config"
require "FadedFeastcraft/FFC_Utils"
require "FadedFeastcraft/FFC_Branding"
require "FadedFeastcraft/FFC_SourcePackRegistry"

FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.RecipeIndex = FadedFeastcraft.RecipeIndex or {}

local RecipeIndex = FadedFeastcraft.RecipeIndex
local Utils = FadedFeastcraft.Utils
local Branding = FadedFeastcraft.Branding
local SourcePacks = FadedFeastcraft.SourcePackRegistry

RecipeIndex.cache = RecipeIndex.cache or { recipes = {}, built = false }

local RECIPE_FAMILIES = {
    all = { id = "all", label = "All" },
    cooking = { id = "cooking", label = "Cooking" },
    preservation = { id = "preservation", label = "Preservation" },
    prep = { id = "prep", label = "Prep" },
    drinks = { id = "drinks", label = "Drinks" },
    sweets = { id = "sweets", label = "Sweets" },
    rations = { id = "rations", label = "Rations" },
    pantry = { id = "pantry", label = "Pantry" },
}

local FAMILY_ORDER = {
    "all",
    "cooking",
    "preservation",
    "prep",
    "drinks",
    "sweets",
    "rations",
    "pantry",
}

local FOOD_RECIPE_WORDS = {
    "food",
    "cook",
    "meal",
    "ingredient",
    "pantry",
    "preserv",
    "canning",
    "canned",
    "canof",
    "jar",
    "pickle",
    "salt",
    "dry",
    "dried",
    "smok",
    "meat",
    "fish",
    "beef",
    "pork",
    "chicken",
    "turkey",
    "mutton",
    "venison",
    "steak",
    "fruit",
    "vegetable",
    "veg",
    "herb",
    "spice",
    "bread",
    "biscuit",
    "cake",
    "pie",
    "soup",
    "stew",
    "rice",
    "pasta",
    "ramen",
    "drink",
    "coffee",
    "tea",
    "juice",
    "water",
    "soda",
    "cola",
    "milk",
    "chocolate",
    "candy",
    "cereal",
    "cheese",
    "sausage",
    "burger",
    "taco",
    "burrito",
    "beans",
    "egg",
    "flour",
    "sugar",
    "butter",
    "oil",
    "mre",
    "ration",
    "butcher",
    "carve",
    "rabbit",
    "squirrel",
    "animal",
    "smallanimal",
    "smallbird",
    "frog",
}

local NON_FOOD_RECIPE_WORDS = {
    "bundle",
    "bundled",
    "material",
    "materials",
    "plank",
    "planks",
    "log stack",
    "logs",
    "scrap",
    "metal",
    "nails",
    "screws",
    "sheet rope",
    "ripped sheets",
    "rag",
    "twine",
    "rope",
    "wire",
    "thread",
    "fabric",
    "leather",
    "stone",
    "gravel",
    "charcoal",
    "battery",
    "electrical",
    "mechanics",
    "carpentry",
    "masonry",
    "paper bag",
    "clothing",
    "cloth",
    "ammo",
    "ammunition",
    "rounds",
    "bullet",
    "bullets",
    "shell",
    "shells",
    "cartridge",
    "cartridges",
    "magazine",
    "gun",
    "firearm",
    "weapon",
    "shotgun",
    "rifle",
    "pistol",
}

local function includeSource(source)
    if Branding and Branding.isCSRSource and Branding.isCSRSource(source) then
        return Utils.sbBool("EnableCSRRecipeScanning", true)
    end
    return true
end

local function callAny(recipe, names)
    for _, name in ipairs(names) do
        local value = Utils.safeCall(recipe, name)
        if value ~= nil then return value end
    end
    return nil
end

local function tagsToText(recipe)
    local tags = Utils.safeCall(recipe, "getTags")
    if not tags or not tags.size or not tags.get then return "" end
    local parts = {}
    for i = 0, tags:size() - 1 do
        parts[#parts + 1] = tostring(tags:get(i))
    end
    return table.concat(parts, ", ")
end

local function textureFromFullType(fullType)
    local scriptItem = Utils.getScriptItem and Utils.getScriptItem(fullType) or nil
    return Utils.getScriptItemTextureName and Utils.getScriptItemTextureName(scriptItem) or nil
end

local function craftRecipeResultInfo(recipe)
    local outputs = Utils.safeCall(recipe, "getOutputs")
    if outputs and outputs.size and outputs.get then
        for outputIndex = 0, outputs:size() - 1 do
            local outputScript = outputs:get(outputIndex)
            local itemList = outputScript and Utils.safeCall(outputScript, "getPossibleResultItems") or nil
            if itemList and itemList.size and itemList.get then
                for itemIndex = 0, itemList:size() - 1 do
                    local scriptItem = itemList:get(itemIndex)
                    if scriptItem then
                        local fullType = Utils.safeCall(scriptItem, "getFullName")
                            or Utils.safeCall(scriptItem, "getFullType")
                            or Utils.safeCall(scriptItem, "getName")
                        local textureName = Utils.getScriptItemTextureName and Utils.getScriptItemTextureName(scriptItem) or nil
                        if textureName or fullType then
                            return tostring(fullType or ""), textureName
                        end
                    end
                end
            end
        end
    end

    local resultItem = callAny(recipe, { "getFullResultItem", "getResultItem" })
    if resultItem then
        return tostring(resultItem), textureFromFullType(resultItem)
    end
    return "", nil
end

local function sourceForRecipe(name, moduleName, tags)
    local probe = Utils.lower(tostring(name) .. " " .. tostring(moduleName) .. " " .. tostring(tags))
    if string.find(probe, "csr_", 1, true)
        or string.find(probe, "csrtest", 1, true)
        or string.find(probe, "csr test", 1, true)
        or string.find(probe, "commonsensereborn", 1, true)
        or string.find(probe, "common sense reborn", 1, true) then
        return Branding.displaySource("Common Sense Reborn")
    end
    if string.find(probe, "ffc_", 1, true) or string.find(probe, "fadedfeastcraft", 1, true) then return "FFC Core" end
    local source = SourcePacks and SourcePacks.sourceForProbe and SourcePacks.sourceForProbe(name, moduleName, tags)
    if source then return source end
    if string.find(probe, "dry", 1, true) then return "FFC Preservation Bench" end
    return Branding.displaySource(moduleName, "FFC Indexed Pantry")
end

local function hasAny(text, words)
    for _, word in ipairs(words or {}) do
        if string.find(text, word, 1, true) then return true end
    end
    return false
end

local function scriptItemIsFood(fullType)
    local scriptItem = Utils.getScriptItem and Utils.getScriptItem(fullType) or nil
    if not scriptItem then return false end

    if Utils.safeCall(scriptItem, "isFood") == true or Utils.safeCall(scriptItem, "IsFood") == true then
        return true
    end

    local exactParts = {
        Utils.safeCall(scriptItem, "getType"),
        Utils.safeCall(scriptItem, "getItemType"),
        Utils.safeCall(scriptItem, "getDisplayCategory"),
        Utils.safeCall(scriptItem, "getCategory"),
    }
    for _, part in ipairs(exactParts) do
        if Utils.lower(part) == "food" then return true end
    end

    local foodType = Utils.safeCall(scriptItem, "getFoodType")
    if foodType and tostring(foodType) ~= "" and Utils.lower(foodType) ~= "none" then
        return true
    end

    local tags = Utils.safeCall(scriptItem, "getTags")
    if tags and tags.size and tags.get then
        for i = 0, tags:size() - 1 do
            local tag = Utils.lower(tags:get(i))
            if tag == "food" or tag == "cooking" or tag == "ingredient" then
                return true
            end
        end
    end
    return false
end

local function isFoodFacingRecipe(name, resultType, tags, source)
    local text = Utils.lower(tostring(name or "") .. " " .. tostring(resultType or "") .. " " .. tostring(tags or ""))
    local hasFoodWords = hasAny(text, FOOD_RECIPE_WORDS)

    if resultType and resultType ~= "" and scriptItemIsFood(resultType) then
        return true
    end

    if hasFoodWords and not hasAny(text, NON_FOOD_RECIPE_WORDS) then
        return true
    end

    return false
end

local function familyForRecipe(name, resultType, tags, source)
    local text = Utils.lower(tostring(name or "") .. " " .. tostring(resultType or "") .. " " .. tostring(tags or "") .. " " .. tostring(source or ""))

    if hasAny(text, {
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
    }) then
        return "preservation"
    end

    if hasAny(text, {
        "mre",
        "ration",
        "field meal",
        "military",
        "survival meal",
    }) then
        return "rations"
    end

    if hasAny(text, {
        "drink",
        "coffee",
        "tea",
        "juice",
        "water",
        "soda",
        "cola",
        "beverage",
        "atole",
        "chocolatecaliente",
        "hot chocolate",
    }) then
        return "drinks"
    end

    if hasAny(text, {
        "cake",
        "pie",
        "candy",
        "sweet",
        "chocolate",
        "cookie",
        "cereal",
        "dessert",
        "churro",
        "flan",
        "dulce",
    }) then
        return "sweets"
    end

    if hasAny(text, {
        "cut",
        "slice",
        "chop",
        "butcher",
        "open",
        "unpack",
        "divide",
        "split",
        "mix",
        "prepare",
    }) then
        return "prep"
    end

    if hasAny(text, {
        "cook",
        "bake",
        "boil",
        "grill",
        "roast",
        "fry",
        "soup",
        "stew",
        "rice",
        "pasta",
        "casserole",
        "ramen",
        "meal",
        "taco",
        "tamale",
        "pozole",
        "chili",
        "chile",
        "omelet",
    }) then
        return "cooking"
    end

    return "pantry"
end

local function familyLabel(family)
    local record = RECIPE_FAMILIES[family or ""] or RECIPE_FAMILIES.pantry
    return record.label
end

local function listSize(list)
    if not list then return 0 end
    if type(list) == "table" then return #list end
    if list.size then
        local ok, result = pcall(function() return list:size() end)
        if ok then return tonumber(result) or 0 end
    end
    return 0
end

local function listGet(list, index)
    if not list then return nil end
    if type(list) == "table" then return list[index + 1] end
    if list.get then
        local ok, result = pcall(function() return list:get(index) end)
        if ok then return result end
    end
    return nil
end

local function scriptItemFullType(scriptItem)
    if scriptItem == nil then return "" end
    if type(scriptItem) == "string" then return scriptItem end
    local fullType = callAny(scriptItem, { "getFullName", "getFullType", "getFluidTypeString", "getEnergyTypeString" })
    if fullType and tostring(fullType) ~= "" then return tostring(fullType) end
    local moduleName = Utils.safeCall(scriptItem, "getModuleName") or Utils.safeCall(scriptItem, "getModule")
    local name = Utils.safeCall(scriptItem, "getName") or Utils.safeCall(scriptItem, "getType")
    if moduleName and name then return tostring(moduleName) .. "." .. tostring(name) end
    if name then return tostring(name) end
    return tostring(scriptItem)
end

local function itemDisplayName(fullType, scriptItem)
    if scriptItem and type(scriptItem) ~= "string" then
        local displayName = Utils.safeCall(scriptItem, "getDisplayName")
            or Utils.safeCall(scriptItem, "getTranslatedName")
            or Utils.safeCall(scriptItem, "getName")
        if displayName and tostring(displayName) ~= "" then return tostring(displayName) end
    end
    local item = Utils.getScriptItem and Utils.getScriptItem(fullType) or nil
    local displayName = Utils.safeCall(item, "getDisplayName")
    if displayName and tostring(displayName) ~= "" then return tostring(displayName) end
    return Branding.foodName(fullType, tostring(fullType or "item"))
end

local function compactOptions(options, limit)
    local names = {}
    local max = tonumber(limit) or 4
    for i, option in ipairs(options or {}) do
        if i > max then break end
        names[#names + 1] = tostring(option.name or Branding.foodName(option.fullType, option.fullType))
    end
    if #options > max then
        names[#names + 1] = "+" .. tostring(#options - max) .. " more"
    end
    if #names == 0 then return "matching resource" end
    return table.concat(names, " or ")
end

local function resourceKind(script)
    local resourceType = Utils.safeCall(script, "getResourceType")
    if ResourceType then
        if resourceType == ResourceType.Item then return "item" end
        if resourceType == ResourceType.Fluid then return "fluid" end
        if resourceType == ResourceType.Energy then return "energy" end
    end
    local text = Utils.lower(tostring(resourceType or ""))
    if string.find(text, "fluid", 1, true) then return "fluid" end
    if string.find(text, "energy", 1, true) then return "energy" end
    return "item"
end

local function possibleScriptItems(inputScript, methodName)
    local raw = Utils.safeCall(inputScript, methodName) or Utils.safeCall(inputScript, "getItems")
    local options = {}
    for i = 0, listSize(raw) - 1 do
        local scriptItem = listGet(raw, i)
        local fullType = scriptItemFullType(scriptItem)
        if fullType and fullType ~= "" then
            options[#options + 1] = {
                fullType = fullType,
                name = fullType == "*" and "any item" or itemDisplayName(fullType, scriptItem),
            }
        end
    end
    return options
end

local function possibleResourceOptions(script, kind, prefix)
    if kind == "fluid" then
        return possibleScriptItems(script, prefix .. "Fluids")
    elseif kind == "energy" then
        return possibleScriptItems(script, prefix .. "Energies")
    end
    return possibleScriptItems(script, prefix .. "Items")
end

local function collectAccessibleItemCounts(player, options)
    local counts = {}
    local total = 0
    local maxItems = Utils.sbNumber("MaxScannedItems", 350, 50, 1000)
    local function add(item)
        local fullType = Utils.getFullType and Utils.getFullType(item) or ""
        if fullType and fullType ~= "" then
            counts[fullType] = (counts[fullType] or 0) + 1
            total = total + 1
        end
    end
    if player and player.getInventory then
        Utils.walkInventory(player:getInventory(), add, maxItems)
        if options and options.includeNearby == true and Utils.sbBool("EnableNearbyContainerScanning", true) and total < maxItems then
            Utils.walkNearbyContainerItems(player, function(item) add(item) end, {
                radius = Utils.sbNumber("IngredientScanRadius", 2, 0, 8),
                maxContainers = Utils.sbNumber("MaxScannedContainers", 24, 4, 80),
                maxItems = math.max(0, maxItems - total),
            })
        end
    end
    counts.__total = total
    return counts
end

local function countMatchingOptions(counts, options)
    local found = 0
    for _, option in ipairs(options or {}) do
        if option.fullType == "*" then
            found = math.max(found, tonumber(counts.__total) or 0)
        else
            found = found + (tonumber(counts[option.fullType]) or 0)
        end
    end
    return found
end

local function amountForInput(inputScript, optionFullType)
    local amount = nil
    if optionFullType and optionFullType ~= "" and inputScript.getAmount then
        local ok, result = pcall(function() return inputScript:getAmount(optionFullType) end)
        if ok then amount = tonumber(result) end
    end
    amount = amount or tonumber(Utils.safeCall(inputScript, "getIntAmount"))
        or tonumber(Utils.safeCall(inputScript, "getAmount"))
        or tonumber(Utils.safeCall(inputScript, "getCount"))
        or 1
    return math.max(1, amount)
end

local function createHandcraftLogic(record, player)
    if not record or record.kind ~= "craftRecipe" or not record.recipeObject then
        return nil, "No handcraft recipe object is attached."
    end
    if not player then return nil, "No player is available." end
    if not HandcraftLogic then return nil, "Handcraft logic is unavailable." end
    if not ISInventoryPaneContextMenu or not ISInventoryPaneContextMenu.getContainers then
        return nil, "Inventory container scan is unavailable."
    end

    local isoObject = nil
    if ISEntityUI and ISEntityUI.FindCraftSurface then
        local ok, result = pcall(ISEntityUI.FindCraftSurface, player, 2)
        if ok then isoObject = result end
    end

    local ok, logic = pcall(function() return HandcraftLogic.new(player, nil, isoObject) end)
    if not ok or not logic then return nil, "Could not create handcraft logic." end

    -- B42.18's ISHandcraftAction converts manualInputs through PZNetTable.
    -- Non-manual mode passes boolean false there and can crash action creation.
    Utils.safeSet(logic, "setManualSelectInputs", true)
    Utils.safeSet(logic, "setContainers", ISInventoryPaneContextMenu.getContainers(player))
    Utils.safeSet(logic, "setRecipe", record.recipeObject)
    Utils.safeCall(logic, "autoPopulateInputs")
    Utils.safeCall(logic, "canPerformCurrentRecipe")
    return logic, nil
end

local function craftRecipeInputs(record, player, counts, logic)
    local recipe = record and record.recipeObject or nil
    local inputs = Utils.safeCall(recipe, "getInputs")
    local requirements = {}
    local missing = {}
    local allSatisfied = true
    for i = 0, listSize(inputs) - 1 do
        local inputScript = listGet(inputs, i)
        local kind = resourceKind(inputScript)
        local options = possibleResourceOptions(inputScript, kind, "getPossibleInput")
        local firstFullType = options[1] and options[1].fullType or nil
        local amount = amountForInput(inputScript, firstFullType)
        local found = 0
        local label = compactOptions(options, 4)
        if kind == "item" then
            found = tonumber(logic and Utils.safeCall(logic, "getInputCount", inputScript)) or countMatchingOptions(counts, options)
        elseif kind == "fluid" then
            amount = tonumber(Utils.safeCall(inputScript, "getAmount")) or amount
            found = tonumber(logic and Utils.safeCall(logic, "getInputUses", inputScript)) or 0
            label = "fluid: " .. label
        else
            amount = tonumber(Utils.safeCall(inputScript, "getAmount")) or amount
            label = "energy: " .. label
            found = amount
        end

        local keep = Utils.safeCall(inputScript, "isKeep") == true
        local tool = Utils.safeCall(inputScript, "isTool") == true
        local itemCount = Utils.safeCall(inputScript, "isItemCount") == true
        local required = (keep or tool) and math.max(1, amount) or amount
        local satisfied = found >= required
        if kind == "energy" then satisfied = true end
        if not satisfied then
            allSatisfied = false
            missing[#missing + 1] = label
        end

        requirements[#requirements + 1] = {
            kind = kind,
            label = label,
            required = required,
            found = found,
            satisfied = satisfied,
            keep = keep,
            tool = tool,
            itemCount = itemCount,
        }
    end
    return requirements, missing, allSatisfied
end

local function craftRecipeOutputs(record)
    local recipe = record and record.recipeObject or nil
    local outputs = Utils.safeCall(recipe, "getOutputs")
    local out = {}
    for i = 0, listSize(outputs) - 1 do
        local outputScript = listGet(outputs, i)
        local kind = resourceKind(outputScript)
        local options = {}
        options = possibleResourceOptions(outputScript, kind, "getPossibleResult")
        out[#out + 1] = {
            kind = kind,
            label = compactOptions(options, 4),
            amount = tonumber(Utils.safeCall(outputScript, "getIntAmount"))
                or tonumber(Utils.safeCall(outputScript, "getAmount"))
                or 1,
        }
    end
    if #out == 0 and record and record.resultType and record.resultType ~= "" then
        out[#out + 1] = { kind = "item", label = itemDisplayName(record.resultType), amount = 1 }
    end
    return out
end

local function legacyRecipeInputs(record, counts)
    local recipe = record and record.recipeObject or nil
    local sources = Utils.safeCall(recipe, "getSource")
    local requirements = {}
    local missing = {}
    local allSatisfied = true
    for i = 0, listSize(sources) - 1 do
        local source = listGet(sources, i)
        local itemTypes = Utils.safeCall(source, "getItems")
        local options = {}
        for j = 0, listSize(itemTypes) - 1 do
            local fullType = tostring(listGet(itemTypes, j) or "")
            if fullType ~= "" then
                options[#options + 1] = { fullType = fullType, name = itemDisplayName(fullType) }
            end
        end
        local required = tonumber(Utils.safeCall(source, "getCount")) or 1
        local use = tonumber(Utils.safeCall(source, "getUse")) or 0
        if use > 0 then required = use end
        local found = countMatchingOptions(counts, options)
        local satisfied = found >= required
        local label = compactOptions(options, 4)
        if not satisfied then
            allSatisfied = false
            missing[#missing + 1] = label
        end
        requirements[#requirements + 1] = {
            kind = "item",
            label = label,
            required = required,
            found = found,
            satisfied = satisfied,
            keep = Utils.safeCall(source, "isKeep") == true,
        }
    end
    return requirements, missing, allSatisfied
end

local function staticCraftRecipeText(recipe)
    local parts = {}
    local inputs = Utils.safeCall(recipe, "getInputs")
    for i = 0, listSize(inputs) - 1 do
        local inputScript = listGet(inputs, i)
        local kind = resourceKind(inputScript)
        for _, option in ipairs(possibleResourceOptions(inputScript, kind, "getPossibleInput")) do
            parts[#parts + 1] = tostring(option.fullType or "")
            parts[#parts + 1] = tostring(option.name or "")
            if #parts > 40 then return table.concat(parts, " ") end
        end
    end
    local outputs = Utils.safeCall(recipe, "getOutputs")
    for i = 0, listSize(outputs) - 1 do
        local outputScript = listGet(outputs, i)
        local kind = resourceKind(outputScript)
        for _, option in ipairs(possibleResourceOptions(outputScript, kind, "getPossibleResult")) do
            parts[#parts + 1] = tostring(option.fullType or "")
            parts[#parts + 1] = tostring(option.name or "")
            if #parts > 60 then return table.concat(parts, " ") end
        end
    end
    return table.concat(parts, " ")
end

local function amountText(amount, kind)
    local value = tonumber(amount) or 0
    local rounded = Utils.round(value, value == math.floor(value) and 0 or 2)
    if kind == "fluid" then return tostring(rounded) .. "L" end
    if kind == "energy" then return tostring(rounded) end
    return tostring(rounded) .. "x"
end

local function appendRequirementLines(lines, requirements)
    if #requirements == 0 then
        lines[#lines + 1] = "Requirements: none listed."
        return
    end
    lines[#lines + 1] = "Requirements:"
    for i, requirement in ipairs(requirements) do
        if i > 10 then
            lines[#lines + 1] = "... +" .. tostring(#requirements - 10) .. " more requirements"
            break
        end
        local status = requirement.satisfied and "OK" or "Missing"
        local keep = requirement.keep and " keep" or ""
        local tool = requirement.tool and " tool" or ""
        lines[#lines + 1] = status .. ": " .. tostring(requirement.label)
            .. " (" .. amountText(requirement.found, requirement.kind)
            .. "/" .. amountText(requirement.required, requirement.kind) .. keep .. tool .. ")"
    end
end

local function appendOutputLines(lines, outputs)
    if #outputs == 0 then return end
    lines[#lines + 1] = "Outputs:"
    for i, output in ipairs(outputs) do
        if i > 6 then
            lines[#lines + 1] = "... +" .. tostring(#outputs - 6) .. " more outputs"
            break
        end
        lines[#lines + 1] = amountText(output.amount, output.kind) .. " " .. tostring(output.label)
    end
end

local function addStats(stats, recipe)
    stats.total = stats.total + 1
    stats.byKind[recipe.kind] = (stats.byKind[recipe.kind] or 0) + 1
    stats.byFamily[recipe.family] = (stats.byFamily[recipe.family] or 0) + 1
    if recipe.kind == "craftRecipe" then stats.actionable = stats.actionable + 1 end
    if recipe.kind == "recipe" then stats.legacy = stats.legacy + 1 end
    if recipe.family == "preservation" then stats.preservation = stats.preservation + 1 end
    if recipe.family == "cooking" then stats.cooking = stats.cooking + 1 end
end

local function addCraftRecipes(out)
    if not ScriptManager or not ScriptManager.instance or not ScriptManager.instance.getAllCraftRecipes then
        return
    end
    local recipes = ScriptManager.instance:getAllCraftRecipes()
    if not recipes then return end
    for i = 0, recipes:size() - 1 do
        local recipe = recipes:get(i)
        if recipe then
            local name = callAny(recipe, { "getTranslationName", "getName", "getOriginalname" }) or "Unnamed craft recipe"
            local moduleObj = Utils.safeCall(recipe, "getModule")
            local moduleName = moduleObj and (Utils.safeCall(moduleObj, "getName") or tostring(moduleObj)) or ""
            local tags = tagsToText(recipe)
            local hidden = Utils.safeCall(recipe, "isHidden")
            if hidden ~= true then
                local source = sourceForRecipe(name, moduleName, tags)
                if includeSource(source) then
                    local resultType, textureName = craftRecipeResultInfo(recipe)
                    if isFoodFacingRecipe(name, resultType, tags, source) then
                        local family = familyForRecipe(name, resultType, tags, source)
                        local requirementText = staticCraftRecipeText(recipe)
                        out[#out + 1] = {
                            kind = "craftRecipe",
                            name = tostring(name),
                            source = source,
                            family = family,
                            familyLabel = familyLabel(family),
                            actionable = true,
                            resultType = resultType,
                            textureName = textureName,
                            tags = tags,
                            requirementText = requirementText,
                            search = Utils.lower(tostring(name) .. " " .. tostring(moduleName) .. " " .. tostring(resultType or "") .. " " .. tags .. " " .. tostring(source) .. " " .. familyLabel(family) .. " " .. requirementText),
                            recipeObject = recipe,
                        }
                    end
                end
            end
        end
    end
end

local function addLegacyRecipes(out)
    if not getScriptManager or not getScriptManager().getAllRecipes then return end
    local recipes = getScriptManager():getAllRecipes()
    if not recipes then return end
    for i = 0, recipes:size() - 1 do
        local recipe = recipes:get(i)
        if recipe then
            local name = callAny(recipe, { "getOriginalname", "getName" }) or "Unnamed recipe"
            local result = Utils.safeCall(recipe, "getResult")
            local resultType = result and Utils.safeCall(result, "getFullType") or ""
            local source = sourceForRecipe(name, resultType, "")
            if includeSource(source) then
                if isFoodFacingRecipe(name, resultType, "", source) then
                    local family = familyForRecipe(name, resultType, "", source)
                    out[#out + 1] = {
                        kind = "recipe",
                        name = tostring(name),
                        source = source,
                        family = family,
                        familyLabel = familyLabel(family),
                        actionable = false,
                        resultType = resultType,
                        textureName = textureFromFullType(resultType),
                        tags = resultType,
                        search = Utils.lower(tostring(name) .. " " .. tostring(resultType) .. " " .. tostring(source) .. " " .. familyLabel(family)),
                        recipeObject = recipe,
                    }
                end
            end
        end
    end
end

local function recipeIsKnown(record, player)
    local recipe = record and record.recipeObject or nil
    if not recipe then return true end
    local needsLearning = Utils.safeCall(recipe, "needToBeLearn")
    if needsLearning ~= true then return true end
    if not player then return false end
    local known = Utils.safeCall(player, "isRecipeKnown", recipe, true)
    if known ~= nil then return known == true end
    known = Utils.safeCall(player, "isRecipeKnown", recipe)
    if known ~= nil then return known == true end
    return false
end

local function countsForAvailability(context, player)
    if context then
        if not context.counts then
            context.counts = collectAccessibleItemCounts(player, context)
        end
        return context.counts
    end
    return collectAccessibleItemCounts(player)
end

local function recipeMatchesViewFilter(record, player, viewFilter, availabilityContext)
    local filter = tostring(viewFilter or "all")
    if filter == "all" then return true end
    local known = recipeIsKnown(record, player)
    if filter == "known" then return known end
    if not known then return false end
    local availability = RecipeIndex.recipeAvailability(record, player, countsForAvailability(availabilityContext, player), availabilityContext)
    if filter == "craftable" then
        return availability and availability.canCraft == true
    elseif filter == "almost" then
        return availability and availability.canCraft ~= true and #(availability.missing or {}) > 0 and #(availability.missing or {}) <= 2
    end
    return true
end

function RecipeIndex.build(force)
    if RecipeIndex.cache.built and not force then return RecipeIndex.cache end
    local out = {}
    addCraftRecipes(out)
    addLegacyRecipes(out)
    local stats = {
        total = 0,
        actionable = 0,
        legacy = 0,
        preservation = 0,
        cooking = 0,
        byKind = {},
        byFamily = {},
    }
    for _, recipe in ipairs(out) do
        addStats(stats, recipe)
    end
    table.sort(out, function(a, b)
        if a.family ~= b.family then return tostring(a.family) < tostring(b.family) end
        if a.source ~= b.source then return tostring(a.source) < tostring(b.source) end
        return a.name < b.name
    end)
    RecipeIndex.cache = { recipes = out, built = true, count = #out, stats = stats }
    return RecipeIndex.cache
end

function RecipeIndex.search(text, limit, familyFilter, viewFilter, player, options)
    local cache = RecipeIndex.build(false)
    local out = {}
    local max = tonumber(limit) or 120
    local filter = tostring(familyFilter or "all")
    local availabilityContext = {
        fast = true,
        includeNearby = options and options.includeNearby == true,
    }
    for _, recipe in ipairs(cache.recipes or {}) do
        if (filter == "all" or recipe.family == filter)
            and Utils.containsText(recipe.search, text)
            and recipeMatchesViewFilter(recipe, player, viewFilter, availabilityContext) then
            out[#out + 1] = recipe
            if #out >= max then break end
        end
    end
    return out
end

function RecipeIndex.getStats()
    return RecipeIndex.build(false).stats or {}
end

function RecipeIndex.makeHandcraftLogic(record, player)
    return createHandcraftLogic(record, player)
end

function RecipeIndex.isKnown(record, player)
    return recipeIsKnown(record, player)
end

function RecipeIndex.matchesViewFilter(record, player, viewFilter)
    return recipeMatchesViewFilter(record, player, viewFilter)
end

function RecipeIndex.recipeAvailability(record, player, counts, options)
    counts = counts or collectAccessibleItemCounts(player, options)
    local logic, err = nil, nil
    local craftCount = 0
    local canPerform = false
    local requirements, missing, allSatisfied = {}, {}, false

    if record and record.kind == "craftRecipe" then
        if not (options and options.fast == true) then
            logic, err = createHandcraftLogic(record, player)
        end
        if logic then
            craftCount = tonumber(Utils.safeCall(logic, "getPossibleCraftCount", true)) or 0
            canPerform = Utils.safeCall(logic, "canPerformCurrentRecipe") == true
        end
        requirements, missing, allSatisfied = craftRecipeInputs(record, player, counts, logic)
        return {
            canCraft = (options and options.fast == true) and allSatisfied or (canPerform or (allSatisfied and craftCount > 0)),
            craftCount = craftCount,
            canPerform = canPerform,
            requirements = requirements,
            missing = missing,
            allSatisfied = allSatisfied,
            logic = logic,
            message = err,
        }
    end

    if record and record.kind == "recipe" then
        requirements, missing, allSatisfied = legacyRecipeInputs(record, counts)
        return {
            canCraft = false,
            craftCount = 0,
            canPerform = false,
            requirements = requirements,
            missing = missing,
            allSatisfied = allSatisfied,
            logic = nil,
            message = "Legacy recipe can be inspected here; a direct FFC adapter is required before this route can craft from the GUI.",
        }
    end

    return {
        canCraft = false,
        craftCount = 0,
        canPerform = false,
        requirements = {},
        missing = {},
        allSatisfied = false,
        logic = nil,
        message = "No recipe data is attached.",
    }
end

function RecipeIndex.describeRecipe(record, player, options)
    if not record then return {} end

    local availability = RecipeIndex.recipeAvailability(record, player, nil, options)
    local resultName = record.resultType and record.resultType ~= "" and itemDisplayName(record.resultType) or "dynamic result"
    local lines = {
        Branding.scrubText(record.name or "Recipe"),
        "Type: " .. tostring(record.kind == "craftRecipe" and "FFC handcraft recipe" or "Legacy recipe"),
        "Category: " .. tostring(record.familyLabel or familyLabel(record.family)),
        "Result: " .. tostring(resultName),
    }

    if record.kind == "craftRecipe" then
        lines[#lines + 1] = availability.canCraft and "Status: ready to craft in FFC." or "Status: missing requirements or unavailable."
        lines[#lines + 1] = "Craftable batches accessible: " .. tostring(availability.craftCount or 0)
        lines[#lines + 1] = "Launch: FFC starts the timed craft directly and keeps the vanilla craft window closed."
        if availability.message then lines[#lines + 1] = "Note: " .. tostring(availability.message) end
        appendOutputLines(lines, craftRecipeOutputs(record))
        appendRequirementLines(lines, availability.requirements or {})
        if #availability.missing > 0 then
            lines[#lines + 1] = "Missing: " .. table.concat(availability.missing, "; ")
        end
    else
        lines[#lines + 1] = "Status: inspect-only until a direct FFC adapter is added."
        lines[#lines + 1] = "Launch: FFC will not open the vanilla craft window for this recipe."
        appendRequirementLines(lines, availability.requirements or {})
        if #availability.missing > 0 then
            lines[#lines + 1] = "Missing: " .. table.concat(availability.missing, "; ")
        end
        if availability.message then lines[#lines + 1] = tostring(availability.message) end
    end

    return lines
end

function RecipeIndex.getFilters()
    local out = {}
    for _, id in ipairs(FAMILY_ORDER) do
        local family = RECIPE_FAMILIES[id]
        out[#out + 1] = { id = family.id, label = family.label }
    end
    return out
end

function RecipeIndex.getFilterLabel(filterId)
    return familyLabel(filterId == "all" and "all" or filterId)
end

function RecipeIndex.nextFilter(filterId)
    local current = tostring(filterId or "all")
    for index, id in ipairs(FAMILY_ORDER) do
        if id == current then
            local nextId = FAMILY_ORDER[index + 1] or FAMILY_ORDER[1]
            return nextId, RecipeIndex.getFilterLabel(nextId)
        end
    end
    return FAMILY_ORDER[1], RecipeIndex.getFilterLabel(FAMILY_ORDER[1])
end

return RecipeIndex

-- CSR_FieldDress.lua — last-resort corpse harvest context option.
-- Adds "Field Dress" on a dead body when the player carries a SharpKnife.
-- Output: CSR corpse-flesh food (mostly rotten, small chance fresh) + 0-1 Bone.
-- Sandbox-gated (default OFF). Defers to other harvesting/butcher mods.
local SANDBOX_FLAG = "EnableLastResortHarvest"

local function sandbox()
    return SandboxVars.CommonSenseReborn or {}
end

-- v1.8.34c: B42.17 InventoryItem.hasTag(String) Java binding is missing on
-- Clothing / ComboItem / Padlock subclasses. The previous knife search
-- iterated every container item and called it:hasTag("SharpKnife") --
-- the moment the walk hit a worn item or padlock the JVM threw
-- "No implementation found for function: hasTag" and the corpse-harvest
-- option silently never appeared. ScriptItem.getTags() is bound on every
-- InventoryItem subclass so this path can't crash.
local function scriptHasAnyTag(item, tagSet)
    if not item or not item.getScriptItem then return false end
    local script = item:getScriptItem()
    if not script or not script.getTags then return false end
    local tags = script:getTags()
    if not tags or not tags.contains then return false end
    -- v1.8.34d: tags:get(i) tripped a "call nil" on some B42.17 ComboItem /
    -- Padlock subclasses where the Stack returned by getTags() exposes
    -- contains() but not get(int) to Lua. Iterate the candidate tag set
    -- and ask Stack.contains(tag) instead -- contains is universally bound.
    for tag, _ in pairs(tagSet) do
        local ok, has = pcall(function() return tags:contains(tag) end)
        if ok and has == true then return true end
    end
    return false
end

local KNIFE_TAGS = { SharpKnife = true, MeatCleaver = true }

-- v1.8.36: B42.17 script tags are namespaced/lowercased internally
-- (`base:sharpknife`, `base:meatcleaver`). String-keyed Stack:contains()
-- against CamelCase keys never matched, which is why findKnife came up
-- empty even with a knife in the primary hand. Vanilla uses ItemTag enum
-- entries + containsTagRecurse / getFirstTagEvalRecurse, which the
-- engine normalizes correctly. Mirror that pattern here.
local function tagEnum(name)
    if not ItemTag then return nil end
    return ItemTag[name]
end

local function predicateValidKnife(item)
    if not item or item:isBroken() then return false end
    return true
end

local function findKnife(playerObj)
    local inv = playerObj:getInventory()
    if not inv then return nil end

    -- Prefer a knife already equipped (saves a swap action).
    local primary = playerObj:getPrimaryHandItem()
    if primary and not primary:isBroken() then
        local sharp = tagEnum("SHARP_KNIFE")
        local cleaver = tagEnum("MEAT_CLEAVER")
        local ok1, has1 = pcall(function() return sharp ~= nil and primary:hasTag(sharp) end)
        if ok1 and has1 == true then return primary end
        local ok2, has2 = pcall(function() return cleaver ~= nil and primary:hasTag(cleaver) end)
        if ok2 and has2 == true then return primary end
        -- Last-ditch: type whitelist for primary hand so an equipped knife
        -- always wins even if the ItemTag enum entry isn't bound.
        local ft = primary.getFullType and tostring(primary:getFullType()) or ""
        if ft:find("Knife", 1, true) or ft:find("Cleaver", 1, true) then
            return primary
        end
    end

    -- Recursive inventory search via the engine's tag-eval helper. Falls
    -- back to type-recurse for the well-known knife fullTypes when the
    -- ItemTag enum entry is missing on a particular B42 build.
    local sharp = tagEnum("SHARP_KNIFE")
    if sharp and inv.getFirstTagEvalRecurse then
        local found = nil
        pcall(function() found = inv:getFirstTagEvalRecurse(sharp, predicateValidKnife) end)
        if found then return found end
    end
    local cleaver = tagEnum("MEAT_CLEAVER")
    if cleaver and inv.getFirstTagEvalRecurse then
        local found = nil
        pcall(function() found = inv:getFirstTagEvalRecurse(cleaver, predicateValidKnife) end)
        if found then return found end
    end

    -- FullType fallback (covers vanilla + most knife-pack mods).
    local KNIFE_TYPES = {
        "Base.KitchenKnife", "Base.HuntingKnife", "Base.HandFork",
        "Base.LetterOpener", "Base.Scalpel", "Base.MeatCleaver",
        "Base.KitchenKnifeForged", "Base.HuntingKnifeForged",
        "Base.MeatCleaverForged",
    }
    for _, ft in ipairs(KNIFE_TYPES) do
        if inv.getFirstTypeRecurse then
            local it = nil
            pcall(function() it = inv:getFirstTypeRecurse(ft) end)
            if it and not it:isBroken() then return it end
        end
    end

    return nil
end

local function classifyBody(body)
    if not body then return nil end
    if body.isAnimal and body:isAnimal() then return nil end -- defer to vanilla skinning
    -- IsoDeadBody:isZombie() exists in B42; a player corpse returns false.
    if body.isZombie and body:isZombie() then return "zombie" end
    if body.isSkeleton and body:isSkeleton() then return "zombie" end
    return "human"
end

local function onFieldDress(playerNum, body, knife)
    local character = getSpecificPlayer(playerNum)
    if not character or not body or not body:getSquare() or not knife then return end
    if not luautils.walkAdj(character, body:getSquare()) then return end
    ISInventoryPaneContextMenu.transferIfNeeded(character, knife)
    ISTimedActionQueue.add(ISEquipWeaponAction:new(character, knife, 10, true, false))
    ISTimedActionQueue.add(CSR_FieldDressAction:new(character, body, knife))
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test == true then return true end
    if sandbox()[SANDBOX_FLAG] ~= true then return end

    local fetch = ISWorldObjectContextMenu.fetchVars
    local body = fetch and fetch.body or nil
    if not body then return end

    local kind = classifyBody(body)
    if not kind then return end -- animal: skip
    if kind == "human" and sandbox().AllowHumanHarvest ~= true then return end

    local character = getSpecificPlayer(playerNum)
    if not character then return end
    local knife = findKnife(character)

    local label = getText("ContextMenu_CSR_FieldDressCorpse")
    local option = context:addOption(label, playerNum, onFieldDress, body, knife)
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)
    if not knife then
        option.notAvailable = true
        tooltip.description = "<RED>" .. getText("ContextMenu_CSR_FieldDressNoKnife")
    else
        tooltip.description = getText("Tooltip_CSR_FieldDress")
    end
    option.toolTip = tooltip
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

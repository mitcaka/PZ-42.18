-- FHC_ContextMenus.lua
-- Right-click hooks: world-object (carcass), inventory-item (knife/journal/raw-hide/meat).

require "FHC_Constants"
require "FHC_Sandbox"
require "FHC_Utils"
require "FHC_TimedActions"

if isServer() then return end

local U  = FHC.Utils
local SB = FHC.SB

local KNIFE_TYPES = {
    "Base.FHC_SkinningKnife",
    "Base.FHC_HuntingKnife",
    "Base.HuntingKnife",
    "Base.KitchenKnife",
    "Base.HandAxe",
    "Base.FHC_CampHatchet",
}

local function findKnife(player)
    if not player then return nil end
    local inv = player:getInventory()
    for _, ft in ipairs(KNIFE_TYPES) do
        local it = inv:getFirstTypeRecurse(ft)
        if it then return it end
    end
    -- fallback: any tagged sharp blade
    if inv.getFirstTagRecurse then
        return inv:getFirstTagRecurse("base:sharpknife") or inv:getFirstTagRecurse("SharpKnife")
    end
    return nil
end

local function isAnimalCorpse(obj)
    return U.isAnimalCorpse(obj)
end

local function animalCallLabel(animalKey)
    local key = "IGUI_FHC_AnimalCall_" .. tostring(animalKey)
    local label = getText(key)
    if label ~= key then return label end
    local animal = FHC.ANIMALS and FHC.ANIMALS[animalKey]
    return ((animal and animal.display) or tostring(animalKey)) .. " Call"
end

local function addAnimalCallMenu(player, context)
    if not player or not FHC.ANIMAL_CALL_ORDER then return end
    local root = context:addOption(getText("ContextMenu_FHC_AnimalCall"), nil, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    local added = 0
    for _, animalKey in ipairs(FHC.ANIMAL_CALL_ORDER) do
        if U.playerKnowsAnimalCall(player, animalKey) then
            added = added + 1
            local opt = sub:addOption(animalCallLabel(animalKey), nil, function()
                if U.getAnimalCallCooldownRemaining(player, animalKey) > 0 then
                    player:Say(getText("IGUI_FHC_CallCooldown"))
                    return
                end
                ISTimedActionQueue.add(FHC_AnimalCallTA:new(player, animalKey))
            end)
            if U.getAnimalCallCooldownRemaining(player, animalKey) > 0 then
                opt.notAvailable = true
                local tt = ISToolTip:new(); tt:initialise(); tt:setVisible(false)
                tt.description = getText("IGUI_FHC_CallCooldown")
                opt.toolTip = tt
            end
        end
    end

    if added == 0 then
        local opt = sub:addOption(getText("IGUI_FHC_CallNoneLearned"), nil, nil)
        opt.notAvailable = true
    end
end

-- World right-click on an animal corpse -> Field Dress option
local function onWorldFill(playerNum, context, worldobjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    if SB.guiEnabled() then
        addAnimalCallMenu(player, context)
    end

    if not SB.fieldDress() then return end
    local carcass
    for i = 1, #worldobjects do
        if isAnimalCorpse(worldobjects[i]) then carcass = worldobjects[i]; break end
    end
    if not carcass then
        -- also try the player's square (vanilla often puts carcass into a list with mixed objects)
        local sq = player:getCurrentSquare()
        if sq then
            local okMoving, moving = U.tryCall(sq, "getStaticMovingObjects")
            for j = 0, U.listSize(moving) - 1 do
                local o = U.listGet(moving, j)
                if isAnimalCorpse(o) then carcass = o; break end
            end
        end
    end
    if not carcass then return end
    local knife = findKnife(player)
    local opt = context:addOption(getText("ContextMenu_FHC_FieldDress"), worldobjects, function()
        if not knife and SB.requireTools() then
            player:Say(getText("IGUI_FHC_NeedKnife"))
            return
        end
        local canonical = nil
        local okType, t = U.tryCall(carcass, "getAnimalType")
        canonical = okType and t and FHC.ANIMAL_BY_ALIAS[string.lower(tostring(t))] or nil
        local action = FHC_FieldDress:new(player, carcass, knife, canonical)
        ISTimedActionQueue.add(action)
    end)
    if not knife and SB.requireTools() then
        opt.notAvailable = true
        local tt = ISToolTip:new(); tt:initialise(); tt:setVisible(false)
        tt.description = getText("Tooltip_FHC_NeedKnife")
        opt.toolTip = tt
    end
end
Events.OnFillWorldObjectContextMenu.Add(onWorldFill)

-- Inventory right-click: journal opener only. Crafting stays inside the Hunter Hub.
local function onInvFill(playerNum, context, items)
    if not SB.guiEnabled() then return end
    local player = getSpecificPlayer(playerNum)
    if not player or not items then return end

    local function flatItems()
        local out = {}
        for _, v in ipairs(items) do
            if type(v) == "table" and v.items then
                for _, it in ipairs(v.items) do table.insert(out, it) end
            else
                table.insert(out, v)
            end
        end
        return out
    end

    local list = flatItems()
    local journal, scentItem, scentAnimal
    for _, it in ipairs(list) do
        if it and it.getFullType then
            local ft = it:getFullType()
            if ft == "Base.FHC_HuntersJournal" then journal = it
            elseif FHC.SCENT_BY_ITEM and FHC.SCENT_BY_ITEM[ft] and not scentItem then
                scentItem = it
                scentAnimal = FHC.SCENT_BY_ITEM[ft]
            end
        end
    end

    if journal then
        context:addOption(getText("ContextMenu_FHC_OpenJournal"), nil, function()
            if FHC.UI and FHC.UI.Main then FHC.UI.Main.toggle() end
        end)
    end

    if scentItem and scentAnimal then
        context:addOption(getText("ContextMenu_FHC_ApplyScent"), nil, function()
            ISTimedActionQueue.add(FHC_ApplyScentTA:new(player, scentItem, scentAnimal))
        end)
    end
end
Events.OnFillInventoryObjectContextMenu.Add(onInvFill)

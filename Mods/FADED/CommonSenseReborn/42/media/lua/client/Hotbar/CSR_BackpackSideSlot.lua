require "CSR_FeatureFlags"
require "NPCs/BodyLocations"

--[[
    CSR_BackpackSideSlot.lua

    Adds one dynamic hotbar slot to the left side of the currently worn
    backpack. The visual locations are registered in
    CSR_FlashlightAttachedLocations.lua and backed by model attachments in
    CSR_BackpackSideAttachments.txt.

    Unlike Back 2, this slot is not permanent: it only exists while a
    backpack-like container is worn on the Back body location. The slot type
    changes between regular and large offsets so different pack shapes get a
    better starting position without hardcoding every mod backpack. The legacy
    ALICE slot type stays recognized so old hotbar entries can be cleaned up.
]]

if not ISHotbar or not ISHotbarAttachDefinition then return end

local SLOT_REGULAR = "CSRBackpackLeft"
local SLOT_BIG     = "CSRBackpackLeftBig"
local SLOT_ALICE   = "CSRBackpackLeftALICE"

local SIDE_SLOT = {
    [SLOT_REGULAR] = true,
    [SLOT_BIG] = true,
    [SLOT_ALICE] = true,
}

local function enabled()
    return CSR_FeatureFlags
        and CSR_FeatureFlags.isBagBottomAttachEnabled
        and CSR_FeatureFlags.isBagBottomAttachEnabled()
end

local function lower(v)
    return string.lower(tostring(v or ""))
end

local function callMethod(obj, method, ...)
    if not obj or not obj[method] then return nil end
    return obj[method](obj, ...)
end

local function wornItemAt(worn, index)
    local entry = callMethod(worn, "get", index)
    local item = callMethod(entry, "getItem")
    if item then return item end

    item = callMethod(worn, "getItemByIndex", index)
    if item then return item end

    return entry
end

local function isBackLocation(item)
    local loc = lower(callMethod(item, "getBodyLocation"))
    if loc == "back" or loc == "base:back" then return true end

    local canEquip = lower(callMethod(item, "canBeEquipped"))
    return canEquip == "back" or canEquip == "base:back"
end

local function isPackLike(item)
    if not item or not isBackLocation(item) then return false end

    local isContainer = lower(callMethod(item, "getCategory")) == "container"
        or callMethod(item, "IsInventoryContainer") == true
        or item.getInventory ~= nil
    if not isContainer then return false end

    local text = table.concat({
        lower(callMethod(item, "getFullType")),
        lower(callMethod(item, "getType")),
        lower(callMethod(item, "getName")),
        lower(callMethod(item, "getDisplayName")),
    }, " ")

    if text:find("holster", 1, true)
       or text:find("sheath", 1, true)
       or text:find("quiver", 1, true)
       or text:find("sling", 1, true)
       or text:find("case", 1, true)
       or text:find("canister", 1, true)
       or text:find("tank", 1, true) then
        return false
    end

    return text:find("backpack", 1, true)
        or text:find("pack", 1, true)
        or text:find("ruck", 1, true)
        or text:find("bag", 1, true)
        or text:find("alice", 1, true)
end

local function findWornPack(playerObj)
    if not playerObj then return nil end
    if playerObj.getWornItem and ItemBodyLocation and ItemBodyLocation.BACK then
        local direct = callMethod(playerObj, "getWornItem", ItemBodyLocation.BACK)
        if isPackLike(direct) then return direct end
    end

    local worn = playerObj.getWornItems and playerObj:getWornItems() or nil
    if not worn or not worn.size then return nil end
    for i = 0, worn:size() - 1 do
        local item = wornItemAt(worn, i)
        if isPackLike(item) then return item end
    end
    return nil
end

local function itemCapacity(item)
    local cap = tonumber(callMethod(item, "getCapacity"))
    if cap then return cap end
    local inv = callMethod(item, "getInventory")
    return tonumber(inv and callMethod(inv, "getCapacity")) or 0
end

local function slotForPack(item)
    local text = table.concat({
        lower(callMethod(item, "getFullType")),
        lower(callMethod(item, "getType")),
        lower(callMethod(item, "getName")),
        lower(callMethod(item, "getDisplayName")),
    }, " ")

    if text:find("alice", 1, true) then
        return SLOT_BIG
    end

    local cap = itemCapacity(item)
    if cap >= 30
       or text:find("large", 1, true)
       or text:find("big", 1, true)
       or text:find("military", 1, true)
       or text:find("hiking", 1, true)
       or text:find("ruck", 1, true)
       or text:find("survivor", 1, true)
       or text:find("legendary", 1, true)
       or text:find("colossus", 1, true)
       or text:find("ranger", 1, true) then
        return SLOT_BIG
    end

    return SLOT_REGULAR
end

local function currentSlotType(hotbar)
    if not enabled() then return nil end
    local playerObj = hotbar and hotbar.chr or nil
    if not playerObj and hotbar and hotbar.playerNum ~= nil and getSpecificPlayer then
        playerObj = getSpecificPlayer(hotbar.playerNum)
    end
    local pack = findWornPack(playerObj)
    if not pack then return nil end
    return slotForPack(pack)
end

local function findSlotDef(slotType)
    if not slotType then return nil end
    for _, def in ipairs(ISHotbarAttachDefinition) do
        if def.type == slotType then return def end
    end
    return nil
end

local function firstFreeIndex(hotbar)
    local idx = 2
    while hotbar.availableSlot[idx] do idx = idx + 1 end
    return idx
end

local function hasSlot(hotbar, slotType)
    if not hotbar or not hotbar.availableSlot then return false end
    for _, slot in pairs(hotbar.availableSlot) do
        if slot and slot.slotType == slotType then return true end
    end
    return false
end

local function removeSideSlot(hotbar, idx)
    if not hotbar or not idx then return end
    local item = hotbar.attachedItems and hotbar.attachedItems[idx] or nil
    if item and hotbar.removeItem then
        hotbar:removeItem(item, false)
    end
    if hotbar.availableSlot then
        hotbar.availableSlot[idx] = nil
    end
end

local function replaceSlotAt(hotbar, idx, slotDef)
    if not hotbar or not idx or not slotDef then return false end
    hotbar.availableSlot[idx] = {
        slotType = slotDef.type,
        name = slotDef.name,
        def = slotDef,
    }
    return true
end

local function normalizeAttachedItem(hotbar, idx)
    if not hotbar or not idx or not hotbar.availableSlot then return false end
    local slot = hotbar.availableSlot[idx]
    local slotDef = slot and slot.def
    local item = hotbar.attachedItems and hotbar.attachedItems[idx] or nil
    if not item or not slotDef or not slotDef.attachments or not item.getAttachmentType then return false end

    local attachType = item:getAttachmentType()
    local model = attachType and slotDef.attachments[attachType] or nil
    if not model then return false end

    if item.getAttachedToModel and item:getAttachedToModel() == model then
        return false
    end

    if hotbar.chr and hotbar.chr.getInventory and hotbar.chr:getInventory()
        and not hotbar.chr:getInventory():contains(item) then
        return false
    end

    if hotbar.attachItem then
        hotbar:attachItem(item, model, idx, slotDef, false)
        return true
    end
    return false
end

local function ensureSideSlot(hotbar)
    if not hotbar or not hotbar.availableSlot then return end
    local activeType = currentSlotType(hotbar)
    local activeDef = findSlotDef(activeType)
    local activeIndex = nil
    local changed = false

    for idx, slot in pairs(hotbar.availableSlot) do
        if slot and SIDE_SLOT[slot.slotType] then
            if activeType and activeDef and not activeIndex then
                activeIndex = idx
                if slot.slotType ~= activeType then
                    replaceSlotAt(hotbar, idx, activeDef)
                    changed = true
                end
            else
                removeSideSlot(hotbar, idx)
                changed = true
            end
        end
    end

    if activeType and activeDef and not activeIndex and not hasSlot(hotbar, activeType) then
        local idx = firstFreeIndex(hotbar)
        replaceSlotAt(hotbar, idx, activeDef)
        activeIndex = idx
        changed = true
    end

    if activeIndex and normalizeAttachedItem(hotbar, activeIndex) then
        changed = true
    end

    if changed then
        if hotbar.reloadIcons then hotbar:reloadIcons() end
        if hotbar.savePosition then hotbar:savePosition() end
    end
end

if not ISHotbar.__csr_backpack_side_slot then
    ISHotbar.__csr_backpack_side_slot = true

    local origLoadPosition = ISHotbar.loadPosition
    function ISHotbar:loadPosition()
        if origLoadPosition then origLoadPosition(self) end
        ensureSideSlot(self)
    end

    local origRefresh = ISHotbar.refresh
    function ISHotbar:refresh()
        if origRefresh then origRefresh(self) end
        ensureSideSlot(self)
    end

    local origHaveThisSlot = ISHotbar.haveThisSlot
    function ISHotbar:haveThisSlot(slotType, list)
        if SIDE_SLOT[slotType] and currentSlotType(self) == slotType then
            return true
        end
        return origHaveThisSlot and origHaveThisSlot(self, slotType, list) or false
    end
end

local function refreshPlayerHotbars()
    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, count - 1 do
        local hotbar = getPlayerHotbar and getPlayerHotbar(i) or nil
        if hotbar then ensureSideSlot(hotbar) end
    end
end

if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(refreshPlayerHotbars) end
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(function() refreshPlayerHotbars() end) end
end

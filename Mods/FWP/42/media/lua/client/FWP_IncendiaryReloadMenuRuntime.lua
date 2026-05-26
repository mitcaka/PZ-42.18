-- Client menu glue for alternate reload ammo types.
if isServer() then return end

require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISReloadWeaponAction"
require "TimedActions/ISLoadBulletsInMagazine"

local function moveAmmoKeyFirst(keys, selected)
    if not (keys and selected) then return keys or {} end
    local out = {}
    local selectedText = tostring(selected)
    for _, key in ipairs(keys) do
        if tostring(key) == selectedText then
            out[#out + 1] = key
        end
    end
    for _, key in ipairs(keys) do
        if tostring(key) ~= selectedText then
            out[#out + 1] = key
        end
    end
    return out
end

local function getReloadableAmmoKeys(item, playerObj)
    local selected = nil
    if playerObj and FWPGetSelectedReloadAmmoType then
        selected = FWPGetSelectedReloadAmmoType(playerObj, item)
    end
    if FWPGetReloadableAmmoItemKeys then
        local keys = FWPGetReloadableAmmoItemKeys(item)
        if keys then return moveAmmoKeyFirst(keys, selected) end
    end
    local fallback = FWPGetAmmoItemKey and FWPGetAmmoItemKey(item) or nil
    if fallback then return { fallback } end
    return {}
end

function FWPTransferReloadableAmmoForAction(playerObj, item, currentAmmo, maxAmmo)
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not inventory then return 0 end
    local remaining = (tonumber(maxAmmo) or 0) - (tonumber(currentAmmo) or 0)
    if remaining <= 0 then return 0 end

    local transferred = 0
    local selected = nil
    for _, ammoType in ipairs(getReloadableAmmoKeys(item, playerObj)) do
        if remaining <= 0 then break end
        local count = 0
        if inventory.getItemCountRecurse then
            count = tonumber(inventory:getItemCountRecurse(ammoType)) or 0
        end
        local take = math.min(count, remaining)
        if take > 0 then
            selected = selected or ammoType
            if inventory.getSomeTypeRecurse and ISInventoryPaneContextMenu.transferIfNeeded then
                local items = inventory:getSomeTypeRecurse(ammoType, take)
                if items then
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, items)
                end
            end
            transferred = transferred + take
            remaining = remaining - take
        end
    end

    if selected and FWPSetSelectedReloadAmmoType then
        FWPSetSelectedReloadAmmoType(item, selected)
    end
    return transferred
end

local function getReloadableAmmoCount(playerObj, item, currentAmmo, maxAmmo)
    if FWPGetReloadableAmmoCount then
        local count = FWPGetReloadableAmmoCount(playerObj, item, (tonumber(maxAmmo) or 0) - (tonumber(currentAmmo) or 0))
        if tonumber(count) then return tonumber(count) end
    end
    local ammoType = FWPGetSelectedReloadAmmoType and FWPGetSelectedReloadAmmoType(playerObj, item) or (FWPGetAmmoItemKey and FWPGetAmmoItemKey(item) or nil)
    if ammoType and FWPSetSelectedReloadAmmoType then
        FWPSetSelectedReloadAmmoType(item, ammoType)
    end
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    local count = 0
    if inventory and ammoType and inventory.getItemCountRecurse then
        count = tonumber(inventory:getItemCountRecurse(ammoType)) or 0
    end
    return math.min(count, (tonumber(maxAmmo) or 0) - (tonumber(currentAmmo) or 0))
end

ISInventoryPaneContextMenu.onLoadBulletsIntoFirearm = function(playerObj, weapon)
    FWPTransferReloadableAmmoForAction(playerObj, weapon, weapon:getCurrentAmmoCount(), weapon:getMaxAmmo())
    ISInventoryPaneContextMenu.equipWeapon(weapon, true, false, playerObj:getPlayerNum())
    ISTimedActionQueue.add(ISReloadWeaponAction:new(playerObj, weapon))
end

ISInventoryPaneContextMenu.doMagazineMenu = function(playerObj, magazine, context)
    if magazine:getCurrentAmmoCount() < magazine:getMaxAmmo() then
        local ammoCount = getReloadableAmmoCount(playerObj, magazine, magazine:getCurrentAmmoCount(), magazine:getMaxAmmo())
        if ammoCount == 0 then
            local option = context:addOption(getText("ContextMenu_NoBullets", ammoCount))
            option.notAvailable = true
        else
            context:addOption(getText("ContextMenu_InsertBulletsInMagazine", ammoCount), playerObj, ISInventoryPaneContextMenu.onLoadBulletsInMagazine, magazine, ammoCount)
        end
    end

    if magazine:getCurrentAmmoCount() > 0 then
        context:addOption(getText("ContextMenu_UnloadMagazine"), playerObj, ISInventoryPaneContextMenu.onUnloadBulletsFromMagazine, magazine)
    end
end

ISInventoryPaneContextMenu.onLoadBulletsInMagazine = function(playerObj, magazine, ammoCount)
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, magazine)
    local loaded = FWPTransferReloadableAmmoForAction(playerObj, magazine, magazine:getCurrentAmmoCount(), magazine:getCurrentAmmoCount() + ammoCount)
    if loaded > 0 then
        ISTimedActionQueue.add(ISLoadBulletsInMagazine:new(playerObj, magazine, loaded))
    end
end

local FWP_12G_INCENDIARY_AMMO = "Base.FWP_12gIncendiaryShells"

local function normalizeSelectedItems(items)
    local result = {}
    if not items then return result end
    if items.size then
        for i = 0, items:size() - 1 do
            result[#result + 1] = items:get(i)
        end
        return result
    end
    for _, entry in ipairs(items) do
        if type(entry) == "table" and entry.items then
            for _, stackedItem in ipairs(entry.items) do
                result[#result + 1] = stackedItem
            end
        elseif type(entry) == "table" and entry.item then
            result[#result + 1] = entry.item
        else
            result[#result + 1] = entry
        end
    end
    return result
end

local function getItemFullType(item)
    if not item then return nil end
    if item.getFullType then
        local fullType = item:getFullType()
        if fullType and tostring(fullType) ~= "" then return tostring(fullType) end
    end
    if item.getModule and item.getType then
        return tostring(item:getModule()) .. "." .. tostring(item:getType())
    end
    return nil
end

local function selectedIncludesIncendiaryShell(items)
    for _, item in ipairs(normalizeSelectedItems(items)) do
        if getItemFullType(item) == FWP_12G_INCENDIARY_AMMO then
            return true
        end
    end
    return false
end

local function weaponAcceptsIncendiaryShells(weapon)
    if not (weapon and weapon.isRanged and weapon:isRanged()) then return false end
    if FWPGetReloadableAmmoItemKeys then
        for _, key in ipairs(FWPGetReloadableAmmoItemKeys(weapon)) do
            if key == FWP_12G_INCENDIARY_AMMO then return true end
        end
    end
    return FWPGetAmmoItemKey and FWPGetAmmoItemKey(weapon) == "Base.ShotgunShells"
end

local function loadIncendiaryShellsIntoFirearm(playerObj, weapon)
    if FWPSetSelectedReloadAmmoType then
        FWPSetSelectedReloadAmmoType(weapon, FWP_12G_INCENDIARY_AMMO)
    end
    ISInventoryPaneContextMenu.onLoadBulletsIntoFirearm(playerObj, weapon)
end

local function onIncendiaryShellContext(playerNum, context, items)
    local playerObj = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
    if not (playerObj and context and selectedIncludesIncendiaryShell(items)) then return end
    local weapon = playerObj.getPrimaryHandItem and playerObj:getPrimaryHandItem() or nil
    if not weaponAcceptsIncendiaryShells(weapon) then return end
    if weapon.getCurrentAmmoCount and weapon.getMaxAmmo and weapon:getCurrentAmmoCount() >= weapon:getMaxAmmo() then return end
    local inventory = playerObj.getInventory and playerObj:getInventory() or nil
    local count = inventory and inventory.getItemCountRecurse and tonumber(inventory:getItemCountRecurse(FWP_12G_INCENDIARY_AMMO)) or 0
    if count <= 0 then return end
    context:addOption("Load 12g Incendiary Shells", playerObj, loadIncendiaryShellsIntoFirearm, weapon)
end

Events.OnFillInventoryObjectContextMenu.Add(onIncendiaryShellContext)
print("[FWP INCENDIARY] reload context menu runtime registered")

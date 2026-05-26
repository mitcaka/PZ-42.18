require "TimedActions/ISEjectMagazine"
require "TimedActions/ISInsertMagazine"
require "TimedActions/ISReloadWeaponAction"
require "CSR_Utils"

local SPEED_RELOAD_MULTIPLIER = 1.45
local SPEED_RELOAD_FLAG = "csrSpeedReloadActive"

local function setSpeedReloadFlag(character, enabled)
    local md = character and character.getModData and character:getModData() or nil
    if not md then return end
    if enabled then
        md[SPEED_RELOAD_FLAG] = true
    else
        md[SPEED_RELOAD_FLAG] = nil
    end
end

local function isSpeedReloading(character)
    local md = character and character.getModData and character:getModData() or nil
    return md and md[SPEED_RELOAD_FLAG] == true
end

local function callWithSpeedFlag(action, parentInit)
    setSpeedReloadFlag(action.character, true)
    parentInit(action)
    setSpeedReloadFlag(action.character, false)
end

CSR_SpeedReloadActions = CSR_SpeedReloadActions or {}

local function getInventoryItems(container)
    if not container or not container.getItems then
        return nil
    end
    return container:getItems()
end

local function walkInventory(container, fn, visited)
    if not container or not fn then
        return
    end
    visited = visited or {}
    if visited[container] then
        return
    end
    visited[container] = true

    local items = getInventoryItems(container)
    if not items then
        return
    end

    for i = 0, items:size() - 1 do
        fn(items:get(i))
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and instanceof and instanceof(item, "InventoryContainer") then
            walkInventory(item.getInventory and item:getInventory() or nil, fn, visited)
        end
    end
end

local function snapshotInventoryIds(container)
    local ids = {}
    walkInventory(container, function(item)
        local id = item and item.getID and item:getID() or nil
        if id ~= nil then
            ids[id] = true
        end
    end)
    return ids
end

local function collectNewInventoryItems(container, beforeIds)
    local result = {}
    walkInventory(container, function(item)
        local id = item and item.getID and item:getID() or nil
        if id ~= nil and not beforeIds[id] then
            result[#result + 1] = item
        end
    end)
    return result
end

local function itemFullType(item)
    return item and item.getFullType and tostring(item:getFullType()) or ""
end

local function itemAmmoCount(item)
    if not item or not item.getCurrentAmmoCount then
        return nil
    end
    return tonumber(item:getCurrentAmmoCount())
end

local function chooseEjectedMagazine(candidates, expectedType, expectedAmmo)
    expectedType = tostring(expectedType or "")
    expectedAmmo = tonumber(expectedAmmo)

    if expectedType ~= "" then
        for i = 1, #candidates do
            if itemFullType(candidates[i]) == expectedType then
                return candidates[i]
            end
        end
    end

    if expectedAmmo ~= nil then
        for i = 1, #candidates do
            if itemAmmoCount(candidates[i]) == expectedAmmo then
                return candidates[i]
            end
        end
    end

    for i = 1, #candidates do
        if itemAmmoCount(candidates[i]) ~= nil then
            return candidates[i]
        end
    end

    return candidates[1]
end

local function removeFromContainer(item)
    local container = item and item.getContainer and item:getContainer() or nil
    if not container then
        return false
    end

    if container.DoRemoveItem then
        container:DoRemoveItem(item)
    elseif container.Remove then
        container:Remove(item)
    else
        return false
    end

    if sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(container, item)
    end
    return true
end

local function syncInventoryItem(item)
    if not item then
        return
    end

    if item.transmitModData then
        item:transmitModData()
    end

    local container = item.getContainer and item:getContainer() or nil
    if container and sendReplaceItemInContainer then
        sendReplaceItemInContainer(container, item, item)
    elseif sendItemStats then
        sendItemStats(item)
    end
end

local function syncCharacterInventory(character)
    local inv = character and character.getInventory and character:getInventory() or nil
    if not inv then
        return
    end
    if inv.setDrawDirty then inv:setDrawDirty(true) end
    if inv.setDirtySlots then inv:setDirtySlots(true) end
end

local function syncGun(character, gun)
    if syncHandWeaponFields then
        syncHandWeaponFields(character, gun)
    else
        syncInventoryItem(gun)
    end
    syncCharacterInventory(character)
end

local function dropExistingItem(character, item)
    local square = character and character.getCurrentSquare and character:getCurrentSquare() or nil
    if not square or not square.AddWorldInventoryItem then
        return false
    end

    local container = item and item.getContainer and item:getContainer() or nil
    if container and not removeFromContainer(item) then
        return false
    end
    square:AddWorldInventoryItem(item, ZombRandFloat(0.25, 0.75), ZombRandFloat(0.25, 0.75), 0.0)
    return true
end

local function addFallbackMagazine(character, gun, magazineType, ammoCount)
    magazineType = tostring(magazineType or "")
    if magazineType == "" or magazineType == "nil" then
        return false
    end

    local mag = instanceItem and instanceItem(magazineType) or nil
    if not mag then
        return false
    end

    ammoCount = tonumber(ammoCount) or 0
    if mag.setCurrentAmmoCount then
        local maxAmmo = mag.getMaxAmmo and tonumber(mag:getMaxAmmo()) or ammoCount
        if maxAmmo and maxAmmo > 0 then
            ammoCount = math.min(ammoCount, maxAmmo)
        end
        mag:setCurrentAmmoCount(math.max(0, ammoCount))
    end

    local square = character and character.getCurrentSquare and character:getCurrentSquare() or nil
    if square and square.AddWorldInventoryItem then
        square:AddWorldInventoryItem(mag, ZombRandFloat(0.25, 0.75), ZombRandFloat(0.25, 0.75), 0.0)
    else
        local inv = character and character.getInventory and character:getInventory() or nil
        if not inv then
            return false
        end
        inv:AddItem(mag)
        if sendAddItemToContainer then
            sendAddItemToContainer(inv, mag)
        end
    end

    if gun and gun.setContainsClip then gun:setContainsClip(false) end
    if gun and gun.setCurrentAmmoCount then gun:setCurrentAmmoCount(0) end
    syncGun(character, gun)
    return true
end

local function canUseManualMagazineFallback(gun, magazineType)
    magazineType = tostring(magazineType or "")
    if magazineType == "" or magazineType == "nil" then
        return false
    end

    local md = gun and gun.getModData and gun:getModData() or nil
    if md then
        if md.FixedMagType ~= nil then
            return false
        end
        if md.ClipType ~= nil and md.MagType == nil then
            return false
        end
    end

    return true
end

function CSR_SpeedReloadActions.dropInsertedMagazineToGround(character, gun, fallback)
    if not character or not gun or not gun.isContainsClip or not gun:isContainsClip() then
        return false
    end

    fallback = fallback or {}
    local magazineType = fallback.magazineType or (gun.getMagazineType and gun:getMagazineType() or nil)
    local ammoCount = fallback.ammoCount
    if ammoCount == nil and gun.getCurrentAmmoCount then
        ammoCount = gun:getCurrentAmmoCount()
    end

    local inv = character.getInventory and character:getInventory() or nil
    local beforeIds = snapshotInventoryIds(inv)

    local parentUnload = ISEjectMagazine and ISEjectMagazine.unloadAmmo or nil
    local csrUnload = CSR_EjectMagazineToGround and CSR_EjectMagazineToGround.unloadAmmo or nil
    if type(parentUnload) == "function" and parentUnload ~= csrUnload then
        parentUnload({ character = character, gun = gun })
    end

    if gun.isContainsClip and gun:isContainsClip() then
        return false
    end

    local candidates = collectNewInventoryItems(inv, beforeIds)
    local ejected = chooseEjectedMagazine(candidates, magazineType, ammoCount)
    if ejected then
        dropExistingItem(character, ejected)
        syncGun(character, gun)
        return true
    end

    if canUseManualMagazineFallback(gun, magazineType) then
        return addFallbackMagazine(character, gun, magazineType, ammoCount)
    end

    syncGun(character, gun)
    return true
end

if not _G.__CSR_SpeedReloadSpeedHooked and ISReloadWeaponAction and ISReloadWeaponAction.setReloadSpeed then
    local originalSetReloadSpeed = ISReloadWeaponAction.setReloadSpeed
    ISReloadWeaponAction.setReloadSpeed = function(character, rack)
        originalSetReloadSpeed(character, rack)
        if isSpeedReloading(character) then
            local current = character:getVariableFloat("ReloadSpeed", 1.0)
            character:setVariable("ReloadSpeed", current * SPEED_RELOAD_MULTIPLIER)
        end
    end
    _G.__CSR_SpeedReloadSpeedHooked = true
end

CSR_EjectMagazineToGround = ISEjectMagazine:derive("CSR_EjectMagazineToGround")

function CSR_EjectMagazineToGround:initVars()
    callWithSpeedFlag(self, ISEjectMagazine.initVars)
end

function CSR_EjectMagazineToGround:unloadAmmo()
    if isClient and isClient() then
        return
    end
    CSR_SpeedReloadActions.dropInsertedMagazineToGround(self.character, self.gun)
end

function CSR_EjectMagazineToGround:new(character, gun)
    local o = ISEjectMagazine.new(self, character, gun)
    o.maxTime = o:getDuration()
    return o
end

CSR_InsertMagazineFast = ISInsertMagazine:derive("CSR_InsertMagazineFast")

function CSR_InsertMagazineFast:initVars()
    callWithSpeedFlag(self, ISInsertMagazine.initVars)
end

function CSR_InsertMagazineFast:new(character, gun, magazine)
    local o = ISInsertMagazine.new(self, character, gun, magazine)
    o.maxTime = o:getDuration()
    return o
end

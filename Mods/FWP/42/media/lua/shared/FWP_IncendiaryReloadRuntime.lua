-- Keeps magazine and tube-fed reloads aware of alternate ammo items such as 12g incendiary shells.
require "TimedActions/ISLoadBulletsInMagazine"

local function resolveLoadAmmoType(character, item)
    local ammoType = nil
    if FWPGetSelectedReloadAmmoType then
        ammoType = FWPGetSelectedReloadAmmoType(character, item)
    end
    if ammoType == nil and FWPGetAmmoItemKey then
        ammoType = FWPGetAmmoItemKey(item)
    end
    if ammoType == nil and item and item.getAmmoType then
        local ammo = item:getAmmoType()
        if ammo and ammo.getItemKey then
            ammoType = ammo:getItemKey()
        end
    end
    if ammoType ~= nil and FWPSetSelectedReloadAmmoType then
        FWPSetSelectedReloadAmmoType(item, ammoType)
    end
    return ammoType
end

local function inventoryHasAmmo(inventory, itemKey)
    if not (inventory and itemKey) then return false end
    if inventory.containsWithModule then
        if inventory:containsWithModule(itemKey) then return true end
    end
    if inventory.getItemCountRecurse then
        local count = inventory:getItemCountRecurse(itemKey)
        if tonumber(count) and tonumber(count) > 0 then return true end
    end
    return false
end

function ISLoadBulletsInMagazine:start()
    local itemKey = resolveLoadAmmoType(self.character, self.magazine)
    if not inventoryHasAmmo(self.character:getInventory(), itemKey) then
        self:forceStop()
        return
    end
    self.ammoCountStart = self.magazine:getCurrentAmmoCount()
    self.magazine:setJobDelta(0.0)
    self:setOverrideHandModels(nil, "GunMagazine")
    self:setActionAnim(CharacterActionAnims.InsertBullets)
    self:initVars()
    self.loadedThisLoop = false
    self.updateLoadBulletsTime = 0.0
    self.character:setVariable("UpdateLoadBulletsTime", 0.0)
end

function ISLoadBulletsInMagazine:isLoadFinished()
    local itemKey = resolveLoadAmmoType(self.character, self.magazine)
    return self.magazine:getCurrentAmmoCount() >= self.magazine:getMaxAmmo() or not inventoryHasAmmo(self.character:getInventory(), itemKey)
end

function ISLoadBulletsInMagazine:animEvent(event, parameter)
    if isServer() then
        if event == "updateLoadingTime" then
            self:updateLoadingTime()
        end
    end
    if event == 'InsertBulletSound' then
        if self:isLoadFinished() then
            return
        end
        if self:isLocal() and self.loadedThisLoop then
            return
        end
        self.character:playSound(parameter)
    elseif event == 'InsertBullet' then
        if self:isLoadFinished() then
            return
        end
        if self:isLocal() and self.loadedThisLoop then
            return
        end
        self.loadedThisLoop = true
        if not isClient() then
            local chance = 5
            local xp = 1
            if self.character:getPerkLevel(Perks.Reloading) < 5 then
                chance = 2
                xp = 4
            end
            if ZombRand(chance) == 0 then
                addXp(self.character, Perks.Reloading, xp)
            end
            local itemKey = resolveLoadAmmoType(self.character, self.magazine)
            local removedBullet = self.character:getInventory():RemoveOneOf(itemKey, true)
            if removedBullet then
                if FWPRecordLoadedAmmo then
                    FWPRecordLoadedAmmo(self.magazine, removedBullet, 1)
                end
                self.magazine:setCurrentAmmoCount(self.magazine:getCurrentAmmoCount() + 1)
                if sendRemoveItemFromContainer then
                    sendRemoveItemFromContainer(self.character:getInventory(), removedBullet)
                end
                if syncItemFields then
                    syncItemFields(self.character, self.magazine)
                end
            end
        end
    elseif event == 'loadFinished' then
        if self:isLoadFinished() then
            self.loadFinished = true
            self.loadedThisLoop = false
            if isServer() then
                self.netAction:forceComplete()
            end
        end
    elseif event == 'playReloadSound' then
        if parameter == 'insertAmmoStart' and not self.playedInsertAmmoStartSound then
            local sound = self.magazine.getInsertAmmoStartSound and self.magazine:getInsertAmmoStartSound() or nil
            if sound then
                self.playedInsertAmmoStartSound = true
                self.character:playSound(sound)
            end
        end
    end
end

print("[FWP INCENDIARY] reload ammo-state runtime registered")

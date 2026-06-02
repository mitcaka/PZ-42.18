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
    if not self.gun:isContainsClip() then return end

    local magazineType = self.gun:getMagazineType()
    local ammoCount = self.gun:getCurrentAmmoCount()

    if isClient and isClient() then
        sendClientCommand(self.character, "CommonSenseReborn", "SpeedReloadDropMagazine", {
            gunId = self.gun.getID and self.gun:getID() or nil,
            magazineType = magazineType,
            ammoCount = ammoCount,
            requestId = CSR_Utils.makeRequestId(self.character, "SpeedReloadDropMagazine"),
            requestTimestamp = getTimestampMs and getTimestampMs() or os.time() * 1000,
        })
    else
        local newMag = instanceItem(magazineType)
        if not newMag then return end

        newMag:setCurrentAmmoCount(ammoCount)

        local square = self.character and self.character.getCurrentSquare and self.character:getCurrentSquare() or nil
        if square then
            square:AddWorldInventoryItem(newMag, ZombRandFloat(0.25, 0.75), ZombRandFloat(0.25, 0.75), 0.0)
        else
            local inv = self.character and self.character.getInventory and self.character:getInventory() or nil
            if inv then
                inv:AddItem(newMag)
                if sendAddItemToContainer then
                    sendAddItemToContainer(inv, newMag)
                end
            end
        end
    end

    self.gun:setContainsClip(false)
    self.gun:setCurrentAmmoCount(0)

    if syncHandWeaponFields then
        syncHandWeaponFields(self.character, self.gun)
    end
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

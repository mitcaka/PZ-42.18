if isServer() and not isClient() then return end

require "CSR_FeatureFlags"
require "ISUI/ISFirearmRadialMenu"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/CSR_SpeedReloadActions"

CSR_SpeedReload = CSR_SpeedReload or {}

local DEFAULT_KEY = 0 -- unbound by default; radial/reload-button entrypoints still work.
local DOUBLE_TAP_WINDOW_MS = 550
local speedReloadKeyBind = nil
local lastReloadTapMs = 0

if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.create then
    local opts = PZAPI.ModOptions:create("CommonSenseRebornSpeedReload", "Common Sense Reborn - Speed Reload")
    if opts and opts.addKeyBind then
        speedReloadKeyBind = opts:addKeyBind("speedReloadMagazine", "Speed Reload Magazine", DEFAULT_KEY)
    end
end

local function getBoundKey()
    if speedReloadKeyBind and speedReloadKeyBind.getValue then
        return speedReloadKeyBind:getValue()
    end
    return DEFAULT_KEY
end

local function nowMs()
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    if os and os.time then return os.time() * 1000 end
    return 0
end

local function isReloadKey(key)
    return getCore and getCore():isKey("ReloadWeapon", key)
end

local function isFeatureEnabled()
    if CSR_FeatureFlags and CSR_FeatureFlags.isSpeedReloadEnabled then
        return CSR_FeatureFlags.isSpeedReloadEnabled()
    end
    return not (SandboxVars and SandboxVars.CommonSenseReborn and SandboxVars.CommonSenseReborn.EnableSpeedReload == false)
end

local function isModActive(id)
    local mods = getActivatedMods and getActivatedMods() or nil
    return mods and mods:contains(id) == true
end

local function isGunworksReloadActive()
    return isModActive("SWMG") or isModActive("MarzGuns")
end

local function isGunworksItemKey(value)
    if not value then return false end
    local key = string.lower(tostring(value))
    return key:find("^marzguns%.") ~= nil
        or key:find("^marzguns:") ~= nil
        or key:find("^swmg%.") ~= nil
        or key:find("^swmg:") ~= nil
end

local function isGunworksReloadItem(item)
    if not isGunworksReloadActive() or not item then return false end
    if item.getFullType and isGunworksItemKey(item:getFullType()) then return true end

    local ammoType = item.getAmmoType and item:getAmmoType() or nil
    local ammoKey = ammoType and ammoType.getItemKey and ammoType:getItemKey() or nil
    if isGunworksItemKey(ammoKey) then return true end

    local md = item.getModData and item:getModData() or nil
    return md and (md.AmmoList ~= nil or md.MagazineType ~= nil or md.MagazineTypeLastIndex ~= nil) or false
end

local function getHeldGun(playerObj)
    local weapon = playerObj and playerObj.getPrimaryHandItem and playerObj:getPrimaryHandItem() or nil
    if not weapon then return nil end
    if not instanceof(weapon, "HandWeapon") then return nil end
    if not weapon:isRanged() then return nil end
    if not weapon:getMagazineType() then return nil end
    return weapon
end

local function getBestLoadedMagazine(playerObj, gun)
    if not (playerObj and gun and gun.getBestMagazine) then return nil end
    local magazine = gun:getBestMagazine(playerObj)
    if magazine and magazine.getCurrentAmmoCount and magazine:getCurrentAmmoCount() > 0 then
        return magazine
    end
    return nil
end

local function canSpeedReload(playerObj, gun)
    if not isFeatureEnabled() then return false end
    if not (playerObj and gun) then return false end
    if isGunworksReloadItem(gun) then return false end
    if isGunworksItemKey(gun:getMagazineType()) then return false end
    if not gun:isContainsClip() then return false end
    if not getBestLoadedMagazine(playerObj, gun) then return false end
    return true
end

function CSR_SpeedReload.canStart(playerObj, gun)
    return canSpeedReload(playerObj, gun or getHeldGun(playerObj))
end

function CSR_SpeedReload.start(playerObj, gun)
    gun = gun or getHeldGun(playerObj)
    if not canSpeedReload(playerObj, gun) then return false end

    local magazine = getBestLoadedMagazine(playerObj, gun)
    if not magazine then return false end

    if ISTimedActionQueue and ISTimedActionQueue.clear then
        ISTimedActionQueue.clear(playerObj)
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
        ISInventoryPaneContextMenu.transferIfNeeded(playerObj, magazine)
    end

    ISTimedActionQueue.add(CSR_EjectMagazineToGround:new(playerObj, gun))
    ISTimedActionQueue.add(CSR_InsertMagazineFast:new(playerObj, gun, magazine))
    return true
end

local function addSpeedReloadSlice(frm)
    local playerObj = frm and frm.character or nil
    local weapon = frm and frm.getWeapon and frm:getWeapon() or nil
    if not canSpeedReload(playerObj, weapon) then return end

    local magazine = getBestLoadedMagazine(playerObj, weapon)
    local countText = magazine and magazine.getCurrentAmmoCount and magazine.getMaxAmmo
        and string.format("%d/%d", magazine:getCurrentAmmoCount(), magazine:getMaxAmmo())
        or ""
    local label = "Speed Reload"
    if countText ~= "" then
        label = label .. "\n" .. countText
    end

    local menu = getPlayerRadialMenu(frm.playerNum or playerObj:getPlayerNum())
    if not menu then return end

    local icon = getTexture and getTexture("media/ui/FirearmRadial_EjectMagazine.png") or nil
    menu:addSlice(label, icon, function()
        CSR_SpeedReload.start(playerObj, weapon)
    end)
end

local function patchFirearmRadialFill()
    if _G.__CSR_SpeedReloadRadialPatched then return end
    if not (ISFirearmRadialMenu and ISFirearmRadialMenu.fillMenu) then return end

    local vanillaFillMenu = ISFirearmRadialMenu.fillMenu
    ISFirearmRadialMenu.fillMenu = function(self, ...)
        local result = vanillaFillMenu(self, ...)
        addSpeedReloadSlice(self)
        return result
    end
    _G.__CSR_SpeedReloadRadialPatched = true
end

local function onKeyPressed(key)
    local bound = getBoundKey()
    local playerObj = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    if not playerObj or playerObj:isDead() then return end

    if bound and bound ~= 0 and key == bound then
        CSR_SpeedReload.start(playerObj)
        return
    end

    if not isReloadKey(key) then return end

    local radialMenu = getPlayerRadialMenu and getPlayerRadialMenu(playerObj:getPlayerNum()) or nil
    if radialMenu and radialMenu.isReallyVisible and radialMenu:isReallyVisible() then
        lastReloadTapMs = 0
        return
    end

    local now = nowMs()
    local elapsed = lastReloadTapMs > 0 and (now - lastReloadTapMs) or 0
    lastReloadTapMs = now

    if elapsed > 0 and elapsed <= DOUBLE_TAP_WINDOW_MS then
        local gun = getHeldGun(playerObj)
        if CSR_SpeedReload.start(playerObj, gun) then
            lastReloadTapMs = 0
        end
    end
end

local function onPressReloadButton(playerObj, gun)
    if not (playerObj and gun) then return end
    if playerObj:getVariableBoolean("isUnloading") then
        CSR_SpeedReload.start(playerObj, gun)
    end
end

patchFirearmRadialFill()

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(patchFirearmRadialFill)
end
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(patchFirearmRadialFill)
end
if Events and Events.OnKeyPressed then
    Events.OnKeyPressed.Add(onKeyPressed)
end
if Events and Events.OnPressReloadButton then
    Events.OnPressReloadButton.Add(onPressReloadButton)
end

return CSR_SpeedReload

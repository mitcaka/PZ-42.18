--[[
    CSR_GaelGunStoreCompat.lua
    Neutralizes GaelGunStore's broken ISBaseTimedAction:begin() pcall wrapper.

    GGS wraps begin() in pcall(). On B42.15+, when the Java-side StartAction
    throws RuntimeException, pcall can leave Kahlua's internal call frame
    corrupted. The later symptom is a ReturnValues.put NullPointerException
    from unrelated vanilla timed actions.

    Keep this patch narrow: only protect begin(), and only restore it when the
    installed function looks like the known GGS wrapper or another wrapper that
    set GGS's marker. Do not replace perform()/stop().
]]

require "TimedActions/ISBaseTimedAction"

local function functionSource(fn)
    if type(fn) ~= "function" or not debug or type(debug.getinfo) ~= "function" then
        return ""
    end

    local ok, info = pcall(debug.getinfo, fn, "S")
    if ok and info and info.source then
        return tostring(info.source):lower()
    end

    return ""
end

local function isGGSActive()
    if not getActivatedMods then return false end
    local mods = getActivatedMods()
    if not mods or not mods.contains then return false end
    return mods:contains("GaelGunStore_B42") or mods:contains("GaelGunStore")
end

local function isGGSSource(fn)
    local src = functionSource(fn)
    return src:find("gaelgunstore", 1, true) ~= nil
        or src:find("ggs_timedactionguard", 1, true) ~= nil
end

-- Vanilla-shaped fallback used only if CSR loaded after the unsafe wrapper.
local function vanillaBegin(self)
    if not self.retriggerLastAction then
        self.character:setTimedActionToRetrigger(nil)
    end
    self:create()
    self.character:StartAction(self.action)
end

local _ggsActiveAtLoad = isGGSActive()
local _capturedBegin = ISBaseTimedAction and ISBaseTimedAction.begin or nil
local _capturedWasUnsafe = ISBaseTimedAction
    and ISBaseTimedAction.__ggsBeginGuard
    and _capturedBegin ~= nil

local _rawCleanBegin = _capturedWasUnsafe and vanillaBegin or _capturedBegin

local function guardedCleanBegin(self, ...)
    if not self or not self.character then return end
    return _rawCleanBegin(self, ...)
end

local _cleanBegin = _rawCleanBegin and guardedCleanBegin or nil
local _logged = false

local function ownsGGSGuard()
    return ISBaseTimedAction and ISBaseTimedAction.__csrGGSCompatOwnsGuard == true
end

local function markGGSGuardOwned()
    if not ISBaseTimedAction then return end
    ISBaseTimedAction.__ggsBeginGuard = true
    ISBaseTimedAction.__csrGGSCompatOwnsGuard = true
end

local function shouldRestoreBegin()
    if not ISBaseTimedAction or not _cleanBegin or not ISBaseTimedAction.begin then
        return false
    end
    if ISBaseTimedAction.begin == _cleanBegin then
        return false
    end
    if _ggsActiveAtLoad and ISBaseTimedAction.begin == _rawCleanBegin then
        return true
    end
    if isGGSSource(ISBaseTimedAction.begin) then
        return true
    end
    if ISBaseTimedAction.__ggsBeginGuard and not ownsGGSGuard() then
        return true
    end
    return false
end

local function restoreCleanBegin(reason)
    if not shouldRestoreBegin() then
        return
    end

    ISBaseTimedAction.begin = _cleanBegin
    markGGSGuardOwned()

    if not _logged then
        _logged = true
        print("[CSR] Installed safe ISBaseTimedAction:begin compatibility wrapper" .. (reason or ""))
    end
end

if ISBaseTimedAction and _ggsActiveAtLoad and not _capturedWasUnsafe then
    -- If CSR loads before GGS, this prevents GGS from installing the unsafe
    -- begin() wrapper while CSR installs the same character guard without pcall.
    markGGSGuardOwned()
end

restoreCleanBegin(" at file load")

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(function()
        restoreCleanBegin(" on OnGameBoot")
    end)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        restoreCleanBegin(" on OnGameStart")
    end)
end

if Events and Events.OnPlayerUpdate then
    local checked = false
    local function oneShotSafetyNet()
        if checked then return end
        checked = true
        restoreCleanBegin(" on first OnPlayerUpdate")
        if Events.OnPlayerUpdate.Remove then
            Events.OnPlayerUpdate.Remove(oneShotSafetyNet)
        end
    end
    Events.OnPlayerUpdate.Add(oneShotSafetyNet)
end

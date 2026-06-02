--[[
    CSR_VehicleClaimGuards.lua
    -------------------------------------------------------------------------
    Tier B (v1.8.4) -- defense-in-depth for the vehicle claim system.

    Vanilla CSR previously gated only ISVehicleMenu.onEnter and onStartEngine.
    Every other interaction path (hotwire, siphon, smash, install/uninstall,
    take engine parts, door lock toggle) reached the vehicle without an
    ownership check. This module wraps :isValid() on each timed-action class
    so non-allowed players are silently blocked at the action layer.

    Verified vanilla files (B42.17):
      shared/Vehicles/TimedActions/ISHotwireVehicle.lua
      shared/Vehicles/TimedActions/ISSmashVehicleWindow.lua
      shared/Vehicles/TimedActions/ISInstallVehiclePart.lua
      shared/Vehicles/TimedActions/ISUninstallVehiclePart.lua
      shared/Vehicles/TimedActions/ISTakeEngineParts.lua
      shared/Vehicles/TimedActions/ISLockDoors.lua
      shared/Vehicles/TimedActions/ISTakeGasolineFromVehicle.lua

    Hard rules followed:
      * Only enforce when self.character is an IsoPlayer. Zombies attacking
        vehicles (e.g. ISSmashVehicleWindow with a zombie attacker) are NEVER
        blocked.
      * Resolve self.vehicle robustly -- some classes set self.part instead.
        Fall through to allow when no vehicle is resolvable (don't break
        non-vehicle gas pump siphons or other dual-use actions).
      * Guard with explicit nil/API checks; do not hide Lua/Java failures in
        timed-action validation.
      * Sandbox flag default ON; admin and faction-member bypass live inside
        CSR_VehicleClaim.isAllowed.
      * Wrap at OnGameStart so vanilla classes are guaranteed loaded.
      * Save originals once. Idempotent against repeat hot-reloads.

    MP note:
      Client-side gates protect vanilla clients and report violations back to
      the server enforcer. The server still ejects unauthorized seated players,
      but vanilla's local vehicle command table cannot be cancelled from this
      Lua layer once a hostile client sends a raw "vehicle" command.
--]]

CSR_VehicleClaimGuards = CSR_VehicleClaimGuards or {}
CSR_VehicleClaimGuards._installed = CSR_VehicleClaimGuards._installed or false

local function flagOn()
    if not CSR_FeatureFlags then return false end
    if CSR_FeatureFlags.isVehicleClaimEnforcementStrictEnabled then
        return CSR_FeatureFlags.isVehicleClaimEnforcementStrictEnabled()
    end
    return true
end

-- Resolve the vehicle from a timed-action self. Returns nil when no
-- vehicle is involved (e.g. ISTakeFuel from a world gas pump, where the
-- same class is reused for non-vehicle siphoning in some flows).
local function resolveVehicle(act)
    if not act then return nil end
    if act.vehicle then return act.vehicle end
    if act.part and act.part.getVehicle then
        return act.part:getVehicle()
    end
    return nil
end

local function isPlayerCharacter(ch)
    if not ch then return false end
    return instanceof(ch, "IsoPlayer") == true
end

-- Notify the player once per ~3s to explain why nothing happened.
local _lastNotify = 0
local function notifyBlocked(ch, vehicle)
    if not ch then return end
    local now = (getTimestampMs and getTimestampMs()) or 0
    if now - _lastNotify < 3000 then return end
    _lastNotify = now
    local owner = nil
    if CSR_VehicleClaim and CSR_VehicleClaim.getOwner then
        owner = CSR_VehicleClaim.getOwner(vehicle)
    end
    local msg
    if owner and owner ~= "" then
        msg = "This vehicle is claimed by " .. owner .. "."
    else
        msg = "This vehicle is claimed."
    end
    if ch.setHaloNote then
        ch:setHaloNote(msg, 200, 80, 80, 250)
    end
end

local function notifyKeyRequired(ch)
    if not ch then return end
    local now = (getTimestampMs and getTimestampMs()) or 0
    if now - _lastNotify < 3000 then return end
    _lastNotify = now
    if ch.setHaloNote then
        ch:setHaloNote("CSR claim key required", 210, 150, 255, 250)
    end
end

-- v1.8.10: report an auto-Tier-4 violation to the server. Debounced per
-- (username, vehicle, kind) so a held mouse / chained isValid ticks don't
-- spam the wire. The server gates the punishment behind sandbox flag
-- VehicleClaimAutoLethalActions and re-validates ownership server-side.
local _lastViolationReport = {}
local function reportViolation(ch, vehicle, kind)
    if not isClient() then return end
    if not ch or not vehicle then return end
    local uname = ch.getUsername and ch:getUsername() or "?"
    local vehicleKey = ""
    if CSR_VehicleClaim and CSR_VehicleClaim.getVehicleKey then
        local key = CSR_VehicleClaim.getVehicleKey(vehicle, false)
        if key and key ~= "" then
            vehicleKey = tostring(key)
        end
    end
    if vehicleKey == "" then return end
    local key   = uname .. ":" .. vehicleKey .. ":" .. tostring(kind)
    local now   = (getTimestampMs and getTimestampMs()) or 0
    local prev  = _lastViolationReport[key] or 0
    if (now - prev) < 3000 then return end
    _lastViolationReport[key] = now
    sendClientCommand(ch, "CommonSenseReborn", "VehicleClaimViolation", {
        vehicleKey = vehicleKey,
        kind      = kind,
    })
end

local function vehicleFromContainer(container)
    if not container then return nil end
    local part = nil
    if container.getVehiclePart then
        part = container:getVehiclePart()
    end
    if not part and container.getOutermostContainer then
        local root = container:getOutermostContainer()
        if root and root ~= container and root.getVehiclePart then
            part = root:getVehiclePart()
        end
    end
    if part and part.getVehicle then
        return part:getVehicle()
    end
    return nil
end

local function guardTransferAllow(act)
    if not flagOn() then return true end
    local ch = act and act.character
    if not isPlayerCharacter(ch) then return true end
    local vehicle = nil
    if act then
        vehicle = vehicleFromContainer(act.srcContainer)
            or vehicleFromContainer(act.destContainer)
    end
    if not vehicle then return true end
    if not (CSR_VehicleClaim and CSR_VehicleClaim.isAllowed) then return true end
    if CSR_VehicleClaim.isAllowed(vehicle, ch) then return true end
    notifyBlocked(ch, vehicle)
    reportViolation(ch, vehicle, "container")
    return false
end

-- Core guard: returns false (deny) when the action should be blocked.
-- Returns true (allow) for non-player characters, missing vehicle,
-- unclaimed vehicle, owner, admin, faction member, or allowed-list user.
local function guardAllow(act)
    if not flagOn() then return true end
    local ch = act and act.character
    if not isPlayerCharacter(ch) then return true end
    local vehicle = resolveVehicle(act)
    if not vehicle then return true end
    if not (CSR_VehicleClaim and CSR_VehicleClaim.isAllowed) then return true end
    if CSR_VehicleClaim.isAllowed(vehicle, ch) then return true end
    notifyBlocked(ch, vehicle)
    return false
end

local function guardClaimKeyAllow(act, className)
    if not flagOn() then return true end
    local ch = act and act.character
    if not isPlayerCharacter(ch) then return true end
    local vehicle = resolveVehicle(act)
    if not vehicle then return true end
    if not (CSR_VehicleClaim and CSR_VehicleClaim.isClaimKeyBound
            and CSR_VehicleClaim.isClaimKeyBound(vehicle)) then
        return true
    end
    if className == "ISHotwireVehicle" then
        notifyKeyRequired(ch)
        reportViolation(ch, vehicle, "hotwire")
        return false
    end
    if className == "ISStartVehicleEngine"
            and CSR_VehicleClaim.playerHasClaimKey
            and not CSR_VehicleClaim.playerHasClaimKey(ch, vehicle) then
        notifyKeyRequired(ch)
        return false
    end
    return true
end

-- v1.8.10: classes that should fire an auto-Tier-4 violation report
-- when blocked. Hotwiring and any door open (which covers trunk and
-- glovebox access via the door/trunk part) are treated as theft.
local AUTO_T4_KIND = {
    ISHotwireVehicle  = "hotwire",
    ISOpenVehicleDoor = "loot",
}

local function wrapIsValid(className)
    local cls = _G[className]
    if not cls or not cls.isValid then return false end
    if cls._csrIsValidWrapped then return true end
    local _orig = cls.isValid
    local kind = AUTO_T4_KIND[className]
    cls.isValid = function(self)
        local allow = guardAllow(self)
        if not allow then
            if kind then
                local ch = self and self.character
                local v  = resolveVehicle(self)
                reportViolation(ch, v, kind)
            end
            return false
        end
        if not guardClaimKeyAllow(self, className) then return false end
        return _orig(self)
    end
    cls._csrIsValidWrapped = true
    return true
end

local function wrapInventoryTransfer()
    local cls = rawget(_G, "ISInventoryTransferAction")
    if not cls or not cls.isValid then return false end
    if cls._csrVehicleContainerWrapped then return true end
    local _orig = cls.isValid
    cls.isValid = function(self)
        local allow = guardTransferAllow(self)
        if not allow then return false end
        return _orig(self)
    end
    cls._csrVehicleContainerWrapped = true
    return true
end

local TARGETS = {
    "ISHotwireVehicle",
    "ISSmashVehicleWindow",
    "ISInstallVehiclePart",
    "ISUninstallVehiclePart",
    "ISTakeEngineParts",
    "ISLockDoors",
    "ISTakeGasolineFromVehicle",
    -- v1.8.5: expanded coverage so non-allowed players cannot loot trunks /
    -- gloveboxes (gated behind ISOpenVehicleDoor on the door/trunk part),
    -- cannot grief by locking/unlocking, and cannot deflate tires or scrap
    -- a burnt-out claimed vehicle.
    "ISOpenVehicleDoor",
    "ISCloseVehicleDoor",
    "ISLockVehicleDoor",
    "ISUnlockVehicleDoor",
    "ISDeflateTire",
    "ISInflateTire",
    "ISRemoveBurntVehicle",
    "ISShutOffVehicleEngine",
    "ISAddGasolineToVehicle",
    "ISWashVehicle",
    -- v1.8.x (May 2026) defense-in-depth additions:
    -- direct timed-action invocations bypass ISVehicleMenu, so we gate
    -- the engine-start, window toggle and engine/lightbar repair paths
    -- at the action layer. Repair classes also block "fix-up to steal"
    -- griefing where a non-allowed player tunes a claimed wreck.
    "ISStartVehicleEngine",
    "ISOpenCloseVehicleWindow",
    "ISRepairEngine",
    "ISRepairLightbar",
}

function CSR_VehicleClaimGuards.install()
    if CSR_VehicleClaimGuards._installed then return end
    local applied = 0
    for i = 1, #TARGETS do
        if wrapIsValid(TARGETS[i]) then applied = applied + 1 end
    end
    if wrapInventoryTransfer() then applied = applied + 1 end
    CSR_VehicleClaimGuards._installed = true
    if applied > 0 and getDebug and getDebug() then
        print("[CSR] Vehicle claim guards installed: " .. applied .. "/" .. #TARGETS)
    end
end

Events.OnGameStart.Add(CSR_VehicleClaimGuards.install)

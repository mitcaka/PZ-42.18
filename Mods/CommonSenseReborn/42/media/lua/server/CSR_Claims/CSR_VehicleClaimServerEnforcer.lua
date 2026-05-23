if not isServer() then return end

require "CSR_VehicleClaim"

--[[
    CSR_VehicleClaimServerEnforcer.lua  (v1.8.5+)
    -------------------------------------------------------------------------
    Server-authoritative enforcement layer for vehicle claims.

    Background:
      v1.8.4 / v1.8.5 added client-side :isValid() guards to seventeen
      vanilla vehicle timed-action classes. Those guards are sufficient
      against vanilla clients but a modified client can re-patch :isValid()
      to return true. Vanilla vehicle Java engine packets do not flow
      through Lua server hooks, so we cannot literally veto each action --
      but we CAN run a server-tick sweep that ejects any non-allowed
      character who managed to seat themselves in a claimed vehicle.

      For sandbox-default-OFF servers (claims advisory) the sweep is a
      no-op via the same flag the client uses.

    Hard rules:
      * NEVER eject zombies. The sweep only inspects IsoPlayer characters.
      * NEVER block the vehicle owner, an admin, a faction member, or an
        allowed-list user (the same isAllowed() the client guards use).
      * NEVER eject during the very first second after the player connects
        -- their vehicle reference may not be authoritative yet.
      * Tick budget: 1Hz (Events.OnTick + interval gate). Walking
        getOnlinePlayers() is O(n) where n is online count.

    Known limitation:
      Trunk / glovebox loot reachable WHILE STANDING OUTSIDE is not
      seat-state and therefore not covered by this sweep. The client-side
      ISOpenVehicleDoor guard from v1.8.5 is the only protection there.
      Closing this requires intercepting inventory-transfer packets and
      is deferred.
]]

CSR_VehicleClaimServerEnforcer = CSR_VehicleClaimServerEnforcer or {}

local SWEEP_INTERVAL_MS = 1000        -- 1Hz
local RECONCILE_INTERVAL_MS = 15000
local GRACE_AFTER_LOGIN_SEC = 1
local _lastSweepMs = 0
local _lastReconcileMs = 0
local _loginTs = setmetatable({}, { __mode = "k" })

local function flagOn()
    if not CSR_FeatureFlags then return false end
    if CSR_FeatureFlags.isVehicleClaimEnforcementStrictEnabled then
        return CSR_FeatureFlags.isVehicleClaimEnforcementStrictEnabled()
    end
    return true
end

local function nowMs()
    return (getTimestampMs and getTimestampMs()) or 0
end

local function nowSec()
    if os and os.time then return tonumber(os.time()) or 0 end
    return 0
end

-- Send a halo-style notification to the affected player. We can't call
-- HaloTextHelper server-side (client UI), so we send a server command and
-- the standard CSR_VehicleClaimClient handler displays it.
local function notifyEjected(player, owner, suffix)
    if not player then return end
    local txt = "Ejected: vehicle owned by " .. tostring(owner or "?")
    if suffix and suffix ~= "" then txt = txt .. " -- " .. suffix end
    sendServerCommand(player, "CommonSenseReborn", "VehicleClaimResult", {
        success = false,
        text    = txt,
    })
end

-- v1.8.10 punishment model:
--   * Seated time-in-vehicle drives tier escalation: every STEP_SEC seconds
--     still seated and unauthorized → +1 tier, capped at the configured
--     ceiling (VehicleClaimPunishmentTier 0..4).
--   * Sandbox flag VehicleClaimPunishmentTier defines the ceiling:
--       0 = Off (eject only, no effects, no strikes)
--       1 = Warn (eject + halo)
--       2 = Shock (electrocute)
--       3 = Burn (setOnFire — destructive)
--       4 = Lethal (burn + endurance drain + −10 HP per offence)
--   * Auto-Tier-4 actions (handleViolation) IGNORE the ceiling. These are
--     driven by reporting from CSR_VehicleClaimGuards on hotwire / loot
--     access (trunk/glovebox via ISOpenVehicleDoor) and from the CSR pry /
--     lockpick server handlers when the target vehicle is claimed by
--     someone else. Gated by sandbox flag VehicleClaimAutoLethalActions
--     (default ON; admins can disable for low-punishment servers).
--   * Three-strike rule: every applied punishment increments a per-username
--     per-vehicle strike counter. On the 3rd strike against the same
--     vehicle, the player is killed outright (HP set to 0). Strikes are
--     session-only and reset on disconnect.
--   * Burn auto-extinguish requires the player to be ≥ 4 tiles away from
--     the last vehicle they were ejected from. Inside that radius, fire
--     keeps ticking until they walk away or extinguish manually.
local _seatedSinceSec     = {}  -- [uname] = nowSec when current violation began
local _seatedVehicleKey   = {}  -- [uname] = CSR vehicleKey currently being violated
local _strikes            = {}  -- [uname] = { [vehicleKey] = count }
local _lastEjectVehicleKey = {} -- [uname] = last ejected CSR vehicleKey
local _lastEjectVeh    = setmetatable({}, { __mode = "v" }) -- weak refs
local _burning         = {}     -- [uname] = true while we have them on fire

local STEP_SEC           = 7    -- seconds per tier escalation
local KILL_STRIKES       = 3    -- 3rd offence on same vehicle = death
local EXTINGUISH_DIST_SQ = 16   -- 4 tiles squared

local function getPunishmentTier()
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    return tonumber(sb.VehicleClaimPunishmentTier) or 1
end

local function autoLethalEnabled()
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    if sb.VehicleClaimAutoLethalActions == false then return false end
    return true
end

local function vehicleAuthorityKey(vehicle)
    if not vehicle or not CSR_VehicleClaim then return nil end
    if CSR_VehicleClaim.getRegistryRow then
        local row = CSR_VehicleClaim.getRegistryRow(vehicle)
        local rowKey = row and tostring(row.vehicleKey or "") or ""
        if rowKey ~= "" then return rowKey end
    end
    if CSR_VehicleClaim.getVehicleKey then
        local key = CSR_VehicleClaim.getVehicleKey(vehicle, false)
        if key and key ~= "" then return key end
    end
    return nil
end

local function resolveVehicleFromViolation(args)
    if not args then return nil end
    local key = tostring(args.vehicleKey or "")
    if key == "" then return nil end
    if CSR_VehicleClaim and CSR_VehicleClaim.findLoadedVehicleByKey then
        return CSR_VehicleClaim.findLoadedVehicleByKey(key)
    end
    return nil
end

-- Cancel any active fire on the player. Called when an ejected player is
-- now standing outside a vehicle that has since been unclaimed -- without
-- this, setOnFire(true) burns the player to death even though the vehicle
-- they were ejected from is no longer protected.
local function extinguishPlayer(player)
    if not player then return end
    local bd = player.getBodyDamage and player:getBodyDamage()
    if bd and bd.setOnFire then bd:setOnFire(false) end
    if player.setOnFire then player:setOnFire(false) end
end

local function applyTierEffects(player, tier)
    if tier <= 0 then return "" end
    local suffix = "warn"
    if tier >= 2 then
        local bd = player.getBodyDamage and player:getBodyDamage()
        if bd and bd.setElectrocuted then bd:setElectrocuted(true) end
        suffix = "shocked"
    end
    if tier >= 3 then
        local bd = player.getBodyDamage and player:getBodyDamage()
        if bd and bd.setOnFire then bd:setOnFire(true) end
        if player.setOnFire then player:setOnFire(true) end
        suffix = "burning"
    end
    if tier >= 4 then
        local stats = player.getStats and player:getStats()
        if stats and stats.setEndurance then stats:setEndurance(0.1) end
        local bd = player.getBodyDamage and player:getBodyDamage()
        if bd and bd.setHealth then
            local cur = tonumber(bd:getHealth()) or 100
            bd:setHealth(math.max(1, cur - 10))
        end
        suffix = "burning + injured"
    end
    return suffix
end

-- Returns true if the player was killed outright (3rd strike rule).
local function bumpStrikesAndMaybeKill(player, vehicleKey)
    if not player or not vehicleKey then return false end
    local uname = player.getUsername and player:getUsername() or "?"
    local tab = _strikes[uname]
    if not tab then tab = {}; _strikes[uname] = tab end
    local n = (tab[vehicleKey] or 0) + 1
    tab[vehicleKey] = n
    if n >= KILL_STRIKES then
        local bd = player.getBodyDamage and player:getBodyDamage()
        if bd and bd.setHealth then bd:setHealth(0) end
        return true
    end
    return false
end

-- forcedTier is set by handleViolation (auto-Tier-4) and ignores the
-- sandbox ceiling. The sweep path leaves it nil so the seated timer
-- drives the tier (capped by ceiling).
local function applyPunishment(player, owner, vehicle, forcedTier)
    if not player then return "" end
    local ceiling = getPunishmentTier()
    if ceiling <= 0 and not forcedTier then return "" end

    local uname = player.getUsername and player:getUsername() or "?"
    local vehicleKey = vehicleAuthorityKey(vehicle)

    local effective
    if forcedTier then
        effective = forcedTier
    else
        local since = _seatedSinceSec[uname] or nowSec()
        local elapsed = math.max(0, nowSec() - since)
        local computed = 1 + math.floor(elapsed / STEP_SEC)
        effective = math.min(computed, ceiling)
    end

    local suffix = applyTierEffects(player, effective)
    if effective >= 3 then _burning[uname] = true end

    local killed = false
    if vehicleKey then killed = bumpStrikesAndMaybeKill(player, vehicleKey) end
    if killed then suffix = "executed (3rd strike)" end
    return suffix
end

-- Eject `player` from the vehicle they're currently seated in.
-- Uses the same `vehicle:exit(character)` API vanilla ISExitVehicle uses.
local function ejectFromVehicle(player, vehicle, owner, forcedTier)
    if not player or not vehicle then return false end
    if vehicle.exit then vehicle:exit(player) end
    local uname = player.getUsername and player:getUsername() or "?"
    _lastEjectVehicleKey[uname] = vehicleAuthorityKey(vehicle)
    _lastEjectVeh[uname] = vehicle
    local suffix = applyPunishment(player, owner, vehicle, forcedTier)
    notifyEjected(player, owner, suffix)
    return true
end

local function isAdminAccess(player)
    if not player or not player.getAccessLevel then return false end
    local a = player:getAccessLevel()
    return a == "admin" or a == "Admin"
end

local function inGrace(player)
    local t = _loginTs[player]
    if not t then return false end
    return (nowSec() - t) < GRACE_AFTER_LOGIN_SEC
end

function CSR_VehicleClaimServerEnforcer.sweep()
    local n = nowMs()
    if (n - _lastReconcileMs) >= RECONCILE_INTERVAL_MS then
        _lastReconcileMs = n
        if CSR_ClaimServer and CSR_ClaimServer.reconcileLoadedVehicleClaims then
            CSR_ClaimServer.reconcileLoadedVehicleClaims()
        end
    end

    if not flagOn() then return end
    if (n - _lastSweepMs) < SWEEP_INTERVAL_MS then return end
    _lastSweepMs = n

    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players or not players.size then return end
    local sz = tonumber(players:size()) or 0
    if sz == 0 then return end

    for i = 0, sz - 1 do
        local p = players:get(i)
        if p and not inGrace(p) and not isAdminAccess(p) then
            local uname = p.getUsername and p:getUsername() or "?"
            local v = p.getVehicle and p:getVehicle() or nil
            local handled = false
            if v and CSR_VehicleClaim and CSR_VehicleClaim.isAllowed then
                local owner = CSR_VehicleClaim.getOwner(v)
                if owner and owner ~= "" then
                    local allowed = CSR_VehicleClaim.isAllowed(v, p) == true
                    if not allowed then
                        local vehicleKey = vehicleAuthorityKey(v)
                        if _seatedVehicleKey[uname] ~= vehicleKey then
                            _seatedVehicleKey[uname] = vehicleKey
                            _seatedSinceSec[uname] = nowSec()
                        end
                        ejectFromVehicle(p, v, owner, nil)
                        handled = true
                    end
                end
            end
            if not handled then
                -- Player is outside or in legitimate vehicle -- reset timer.
                _seatedVehicleKey[uname] = nil
                _seatedSinceSec[uname] = nil
                -- Distance gate for fire extinguish (v1.8.10).
                if _burning[uname] then
                    local lastV = _lastEjectVeh[uname]
                    local far = true
                    if lastV and p.DistToSquared and lastV.getX and lastV.getY then
                        local d2 = p:DistToSquared(lastV:getX(), lastV:getY())
                        if d2 and d2 < EXTINGUISH_DIST_SQ then far = false end
                    end
                    if far then
                        extinguishPlayer(p)
                        _burning[uname] = nil
                    end
                end
            end
        end
    end
end

-- v1.8.10 violation report path. Called from the dispatcher when a client
-- guard caught a hotwire / loot access on a claimed vehicle, or from CSR
-- pry / lockpick handlers when the target vehicle is owned by someone else.
-- Forces effective Tier 4 regardless of the configured ceiling. Strike
-- counter still applies, so 3 hotwire attempts on the same car = death.
function CSR_VehicleClaimServerEnforcer.handleViolation(player, args)
    if not player or not args then return end
    if not flagOn() then return end
    if not autoLethalEnabled() then return end
    if isAdminAccess(player) then return end

    local vehicle = resolveVehicleFromViolation(args)
    if not vehicle then return end

    local owner = CSR_VehicleClaim.getOwner(vehicle)
    if not owner or owner == "" then return end

    local allowed = CSR_VehicleClaim.isAllowed(vehicle, player) == true
    if allowed then return end

    -- Best-effort eject (no-op if not seated).
    if vehicle.exit then vehicle:exit(player) end

    local uname = player.getUsername and player:getUsername() or "?"
    _lastEjectVehicleKey[uname] = vehicleAuthorityKey(vehicle)
    _lastEjectVeh[uname] = vehicle

    local suffix = applyPunishment(player, owner, vehicle, 4)
    local kind = tostring(args.kind or "violation")
    notifyEjected(player, owner, "[" .. kind .. "] " .. (suffix or ""))
end

local function onPlayerConnected(player)
    if player then _loginTs[player] = nowSec() end
end

local function onPlayerDisconnect(player)
    if player then
        _loginTs[player] = nil
        local uname = player.getUsername and player:getUsername() or nil
        if uname then
            _seatedSinceSec[uname] = nil
            _seatedVehicleKey[uname] = nil
            _strikes[uname] = nil
            _lastEjectVehicleKey[uname] = nil
            _lastEjectVeh[uname] = nil
            _burning[uname] = nil
        end
    end
end

local _installed = false
local function install()
    if _installed then return end
    _installed = true
    if Events then
        if Events.OnTick then Events.OnTick.Add(CSR_VehicleClaimServerEnforcer.sweep) end
        if Events.OnConnected then Events.OnConnected.Add(onPlayerConnected) end
        if Events.OnPlayerConnect then Events.OnPlayerConnect.Add(onPlayerConnected) end
        if Events.OnPlayerDisconnect then Events.OnPlayerDisconnect.Add(onPlayerDisconnect) end
    end
end

-- v1.8.5: install() guards against double-registration. Self-host MP
-- fires both OnServerStarted and OnGameStart in the same Lua state, so
-- without the _installed flag the OnTick sweep would run twice per tick.
Events.OnServerStarted.Add(install)
Events.OnGameStart.Add(install)

return CSR_VehicleClaimServerEnforcer

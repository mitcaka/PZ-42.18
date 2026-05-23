-- CSR_KnoxSyndicate.lua (shared)
-- Common Sense Reborn — Knox Syndicate radio support call.
-- Shared constants + sandbox helpers used by client + server.

CSR_KnoxSyndicate = CSR_KnoxSyndicate or {}
local K = CSR_KnoxSyndicate

K.MODULE = "CommonSenseReborn"

-- Knox Syndicate broadcast frequency. Chosen as an open slot in the vanilla
-- B42 radio table (between NNR 98000 and KnoxTalk 101200). Players must tune
-- a powered radio to this frequency before "Call in Knox Syndicate" works.
K.FREQUENCY = 100800  -- 100.8 FM
K.FREQUENCY_LABEL = "100.8 FM"

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

function K.isEnabled()
    return sandbox().EnableKnoxSyndicate == true
end

function K.durationSec()
    local v = tonumber(sandbox().KnoxSyndicateDurationSec or 90) or 90
    if v < 30 then v = 30 end
    if v > 300 then v = 300 end
    return v
end

function K.killIntervalSec()
    local v = tonumber(sandbox().KnoxSyndicateKillIntervalSec or 2) or 2
    if v < 1 then v = 1 end
    if v > 10 then v = 10 end
    return v
end

function K.rangeTiles()
    local v = tonumber(sandbox().KnoxSyndicateRangeTiles or 12) or 12
    if v < 4 then v = 4 end
    if v > 20 then v = 20 end
    return v
end

function K.cooldownHours()
    local v = tonumber(sandbox().KnoxSyndicateCooldownHours or 24) or 24
    if v < 1 then v = 1 end
    if v > 168 then v = 168 end
    return v
end

function K.noiseRadius()
    local v = tonumber(sandbox().KnoxSyndicateNoiseRadius or 30) or 30
    if v < 5 then v = 5 end
    if v > 60 then v = 60 end
    return v
end

-- A player can carry / vehicle can hold many radio types. We accept
-- any inventory item flagged as a radio AND turned on, OR a working
-- vehicle radio.
function K.isWorkingHandRadio(item)
    if not item then return false end
    if not (item.getDeviceData and item:getDeviceData()) then return false end
    local dd = item:getDeviceData()
    if dd.getIsTurnedOn and not dd:getIsTurnedOn() then return false end
    return true
end

-- True only if the radio (hand or vehicle device) is on AND tuned to Knox.
function K.isTunedDeviceData(dd)
    if not dd then return false end
    if dd.getIsTurnedOn and not dd:getIsTurnedOn() then return false end
    if not dd.getChannel then return false end
    local ch = dd:getChannel() or 0
    return ch == K.FREQUENCY
end

function K.isTunedHandRadio(item)
    if not item then return false end
    local dd = item.getDeviceData and item:getDeviceData()
    return K.isTunedDeviceData(dd)
end

-- World-time hour key for cooldown (in-game hours since save start).
function K.gameHour()
    local gt = GameTime and GameTime.getInstance and GameTime:getInstance()
    if not gt then return 0 end
    local days = (gt.getNightsSurvived and gt:getNightsSurvived()) or 0
    local tod  = (gt.getTimeOfDay and gt:getTimeOfDay()) or 0
    return math.floor(days * 24 + tod)
end

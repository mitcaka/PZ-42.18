-- CSR_KnoxBroadcast.lua
-- Registers CSR-authored DynamicRadio channels, including the Knox Syndicate
-- beacon on 100.8 FM. Uses vanilla DynamicRadio/RadioBroadCast/RadioLine so
-- broadcasts sync through the normal radio system in SP and MP.

require "CSR_FeatureFlags"
require "CSR_KnoxSyndicate"

if not DynamicRadio then return end

CSR_RadioBroadcasts = CSR_RadioBroadcasts or {}
local CSR_RadioBroadcasts = CSR_RadioBroadcasts

local KNOX_FREQ = (CSR_KnoxSyndicate and CSR_KnoxSyndicate.FREQUENCY) or 100800
local KNOX_LABEL = (CSR_KnoxSyndicate and CSR_KnoxSyndicate.FREQUENCY_LABEL) or "100.8 FM"

local COLORS = {
    HEADER = { r = 1.00, g = 0.74, b = 0.20 },
    BODY = { r = 0.92, g = 0.92, b = 0.88 },
    WARN = { r = 0.95, g = 0.42, b = 0.28 },
    MED = { r = 0.55, g = 0.95, b = 0.68 },
    HAM = { r = 0.62, g = 0.82, b = 1.00 },
    TV = { r = 0.72, g = 0.78, b = 1.00 },
    STATIC = { r = 0.70, g = 0.70, b = 0.70 },
}

local STATIONS = {
    {
        name = "WCSR Civil Defense Relay",
        freq = 90600,
        category = "Emergency",
        uuid = "CSR-CDR-90600",
        color = COLORS.HEADER,
        linesPerHour = 7,
        offset = 1,
        lines = {
            "[CIVDEF] This is WCSR civil defense relay. Automated public safety block follows.",
            "[CIVDEF] Boil untreated water. A rolling boil for one minute is the current minimum.",
            "[CIVDEF] Do not approach perimeter lights, military checkpoints, or parked convoy lanes.",
            "[CIVDEF] If you shelter indoors, mark occupied entrances and keep night lights covered.",
            "[CIVDEF] Radio batteries are emergency equipment. Rotate listening shifts when possible.",
            "[WARN] Do not remain in stalled traffic. Abandoned road columns are hostile terrain.",
            "[CIVDEF] Burn piles, blood pools, and open wounds are contamination hazards.",
            "[CIVDEF] County shelters outside the zone report intake delays and ration control.",
            "[CIVDEF] Keep one exit route silent. Noise discipline saves lives after dark.",
            "[CIVDEF] If power fails, assume pumps and fuel stations are unreliable until checked.",
            "[WARN] Subjects drawn to sirens may remain in the area for several hours.",
            "[CIVDEF] This message repeats with updated block order each hour.",
        },
    },
    {
        name = "KY-EMT Medical Loop",
        freq = 96600,
        category = "Emergency",
        uuid = "CSR-MED-96600",
        color = COLORS.MED,
        linesPerHour = 6,
        offset = 3,
        lines = {
            "[MED] Kentucky emergency medical loop transmitting wound-care advisories.",
            "[MED] Clean lacerations with disinfectant when available. Dirty bandages must be changed.",
            "[MED] Fever with confusion after exposure requires isolation and continuous observation.",
            "[MED] Hydration is treatment. Dehydration worsens shock, fever, and panic response.",
            "[MED] Wear gloves or improvised hand covering when handling bodies or bloodied clothing.",
            "[MED] Deep wounds: control bleeding first, disinfect second, stitch only with clean tools.",
            "[MED] Burns should be cooled with clean water. Do not pack burns with dirty fabric.",
            "[MED] Antibiotics are limited. Reserve them for obvious bacterial infection.",
            "[WARN] Bite wounds remain extreme risk. Treat all bite contamination as critical.",
            "[MED] Rest cycles are medical care. Exhausted survivors make fatal handling mistakes.",
            "[MED] End of medical loop segment. Next advisory follows after static break.",
        },
    },
    {
        name = "Route 31 Roadwatch",
        freq = 102600,
        category = "Radio",
        uuid = "CSR-R31-102600",
        color = COLORS.BODY,
        linesPerHour = 6,
        offset = 5,
        lines = {
            "[ROADWATCH] Route 31 volunteer net. Reports are unverified but repeated by consensus.",
            "[ROADWATCH] Muldraugh northbound lanes: wreck clusters, smoke pockets, dead stop traffic.",
            "[ROADWATCH] Riverside approaches: bridge traffic abandoned, shoulder passage changes daily.",
            "[ROADWATCH] Rosewood rural roads: safer by daylight, unsafe near sirens after sundown.",
            "[ROADWATCH] West Point river crossings: expect barricades, bodies, and fuel scavengers.",
            "[ROADWATCH] Louisville feeder roads: heavy density, broken glass, no reliable safe shoulder.",
            "[ROADWATCH] Carry hand tools. A quiet detour beats a fast road you cannot clear.",
            "[ROADWATCH] If you must move, scout on foot first and keep the engine cold.",
            "[WARN] Do not honk to clear roads. You will only announce dinner.",
            "[ROADWATCH] This net repeats road notes for anyone trying to stay mobile.",
        },
    },
    {
        name = "Bluegrass Free Radio",
        freq = 104400,
        category = "Amateur",
        uuid = "CSR-BFR-104400",
        color = COLORS.HAM,
        linesPerHour = 7,
        offset = 7,
        lines = {
            "[BFR] Bluegrass Free Radio, low-power community relay. If you hear us, key twice and wait.",
            "[BFR] Trade board: clean water, thread, batteries, nails. No gunfire near the exchange mark.",
            "[BFR] Mark cleared buildings with chalk or paint. Do not trust old marks after rain.",
            "[BFR] Quiet tools last longer than loud heroics. Save engines for leaving, not arriving.",
            "[BFR] Garden note: collect seed packets now. Rot comes faster than hunger admits.",
            "[BFR] Radios left on a window ledge carry farther than radios under a concrete stairwell.",
            "[BFR] If a stranger gives a true name, answer with a landmark, not your address.",
            "[WARN] We lost three people to a generator running indoors. Exhaust kills the living too.",
            "[BFR] This block repeats. Different operator, same advice: stay boring, stay alive.",
            "[BFR] End of free-radio block. Static guard resumes.",
        },
    },
    {
        name = "CSR-TV Emergency Audio",
        freq = 211,
        category = "Television",
        uuid = "CSR-TV-211",
        color = COLORS.TV,
        linesPerHour = 6,
        offset = 9,
        lines = {
            "[TV] Emergency television audio carrier. Picture may be unavailable.",
            "[TV] This is a rebroadcast of local public-service footage on reserve equipment.",
            "[TV] If the screen is snow, use the audio only. Do not adjust rooftop antennas in storms.",
            "[TV] Shelter demonstration: barricade bottom windows first, then cover sight lines.",
            "[TV] Cooking safety: extinguish stoves before sleeping. Smoke draws attention.",
            "[TV] Battery lesson: test flashlights before dusk and tape spare cells together.",
            "[TV] Medical demonstration: wash hands, clean wound, apply pressure, then bandage.",
            "[TV] This feed uses legacy television audio. Expect tone bursts and static gaps.",
            "[WARN] Emergency programming cannot confirm rescue availability inside Knox County.",
            "[TV] End of lesson reel. Stand by for the next recorded segment.",
        },
    },
    {
        name = "Knox Syndicate",
        freq = KNOX_FREQ,
        category = "Radio",
        uuid = "CSR-KNOX-1007",
        color = COLORS.HEADER,
        airCounterMultiplier = 0.5,
        requiresKnoxBroadcast = true,
        buildLines = function(_station, gt)
            local hour = gt and gt.getHour and gt:getHour() or 0
            local day = gt and gt.getNightsSurvived and gt:getNightsSurvived() or 0
            local block = ((day * 8) + math.floor(hour / 3)) % 4

            if block == 0 then
                return {
                    "[KNOX] Knox Syndicate operations beacon on " .. KNOX_LABEL .. ". Contract channel is live.",
                    "<bzzt>",
                    "[KNOX] Survivors with a powered, tuned radio may request one limited support pass.",
                    "[KNOX] We need open sky, a stable position, and a caller who can hold still.",
                    "[KNOX] Open the radio context menu and select Call in Knox Syndicate.",
                    "[WARN] Our aircraft are loud. Every corpse in earshot will try to attend.",
                    "[KNOX] Use the call when extraction is impossible and the perimeter is closing.",
                    "[KNOX] Knox Syndicate: we do not save the world. We buy you time.",
                }
            elseif block == 1 then
                return {
                    "[KNOX] Tactical advisory. Mark your fallback before calling air support.",
                    "[KNOX] Stay outside. Roofs, courtyards, parking lots, and fields give us the best angle.",
                    "[KNOX] Avoid trees, apartment interiors, and alleys with blocked exits.",
                    "<wzzt>",
                    "[KNOX] If rounds land close, do not run toward the rotor noise.",
                    "[WARN] The support pass kills threats. It does not make the area safe afterward.",
                    "[KNOX] When we call RTB, leave before the dead reorganize.",
                    "[KNOX] This is Knox Syndicate. Keep your head down and your radio dry.",
                }
            elseif block == 2 then
                return {
                    "[KNOX] Maintenance window report. Birds refuel, guns cool, invoices print.",
                    "[KNOX] Individual callers are rate-limited. The cooldown is not negotiable.",
                    "[KNOX] If you hear only static, check power, frequency, and whether you are indoors.",
                    "[KNOX] Tune exact: " .. KNOX_LABEL .. ". Close is not close enough.",
                    "<fzzt>",
                    "[WARN] False calls waste aviation fuel and bring hordes to your own doorstep.",
                    "[KNOX] Save the channel for real contact. We will answer when the board is green.",
                }
            end

            return {
                "[KNOX] After-action bulletin. A support pass is a window, not a rescue.",
                "[KNOX] Move after the guns. Loot later. Pride is heavy and does not fit in a duffel.",
                "[KNOX] Keep one radio battery fresh for the call you have not needed yet.",
                "[KNOX] If you are listening from a vehicle, leave the engine off until the pass ends.",
                "<bzzt>",
                "[WARN] Rotor noise can pull threats from beyond visual range.",
                "[KNOX] Knox Syndicate standing by on " .. KNOX_LABEL .. ". Contracts accepted on clear signal.",
            }
        end,
    },
}

local function channelAlreadyRegistered(uuid)
    for _, channel in ipairs(DynamicRadio.channels or {}) do
        if channel and channel.uuid == uuid then
            return true
        end
    end
    return false
end

local function registerChannel(station)
    if channelAlreadyRegistered(station.uuid) then
        return
    end

    table.insert(DynamicRadio.channels, {
        name = station.name,
        freq = station.freq,
        category = station.category,
        uuid = station.uuid,
        register = true,
        airCounterMultiplier = station.airCounterMultiplier or 0.8,
    })
end

local function scriptAlreadyRegistered(uuid)
    for _, script in ipairs(DynamicRadio.scripts or {}) do
        if script and script.channelUUID == uuid and script.csrDynamicRadio == true then
            return true
        end
    end
    return false
end

local function stationEnabled(station)
    if station.requiresKnoxBroadcast then
        return CSR_FeatureFlags
            and CSR_FeatureFlags.isKnoxSyndicateBroadcastEnabled
            and CSR_FeatureFlags.isKnoxSyndicateBroadcastEnabled()
    end
    return true
end

local function getWorldHour(gt)
    local day = gt and gt.getNightsSurvived and gt:getNightsSurvived() or 0
    local hour = gt and gt.getHour and gt:getHour() or 0
    return (day * 24) + hour
end

local function chooseColor(station, text)
    if not text then return station.color or COLORS.BODY end
    if string.find(text, "<", 1, true) then return COLORS.STATIC end
    if string.find(text, "[WARN]", 1, true) then return COLORS.WARN end
    if string.find(text, "[MED]", 1, true) then return COLORS.MED end
    if string.find(text, "[BFR]", 1, true) then return COLORS.HAM end
    if string.find(text, "[TV]", 1, true) then return COLORS.TV end
    if string.find(text, "[KNOX]", 1, true) then return COLORS.HEADER end
    return station.color or COLORS.BODY
end

local function addLine(broadcast, station, text)
    local color = chooseColor(station, text)
    broadcast:AddRadioLine(RadioLine.new(text, color.r, color.g, color.b))
end

local function addFuzz(broadcast, station, worldHour)
    if station.category == "Television" then
        local token = (worldHour % 2 == 0) and "<wzzt>" or "<bzzt>"
        addLine(broadcast, station, token)
        return
    end

    if worldHour % 3 == 0 then
        addLine(broadcast, station, "<bzzt>")
    elseif worldHour % 5 == 0 then
        addLine(broadcast, station, "<fzzt>")
    end
end

local function buildRotatingLines(station, gt)
    if station.buildLines then
        return station.buildLines(station, gt)
    end

    local lines = station.lines or {}
    local total = #lines
    if total == 0 then
        return {}
    end

    local count = math.min(station.linesPerHour or 6, total)
    local start = (((getWorldHour(gt) + (station.offset or 0)) * 3) % total) + 1
    local out = {}
    for i = 0, count - 1 do
        local idx = ((start + i - 1) % total) + 1
        out[#out + 1] = lines[idx]
    end
    return out
end

local function createBroadcast(station, gt)
    local worldHour = getWorldHour(gt)
    local broadcast = RadioBroadCast.new(
        "CSR-" .. station.uuid .. "-" .. tostring(worldHour) .. "-" .. tostring(ZombRand(1000, 9999)),
        -1,
        -1
    )

    addFuzz(broadcast, station, worldHour)
    local lines = buildRotatingLines(station, gt)
    for i = 1, #lines do
        addLine(broadcast, station, lines[i])
    end
    addFuzz(broadcast, station, worldHour + 1)

    return broadcast
end

local function makeScript(station)
    return {
        csrDynamicRadio = true,
        channelUUID = station.uuid,
        OnEveryHour = function(channel, gt, _radio)
            if not stationEnabled(station) then
                return
            end

            local broadcast = createBroadcast(station, gt)
            if broadcast then
                channel:setAiringBroadcast(broadcast)
            end
        end,
    }
end

for i = 1, #STATIONS do
    registerChannel(STATIONS[i])
end

function CSR_RadioBroadcasts.OnLoadRadioScripts()
    for i = 1, #STATIONS do
        local station = STATIONS[i]
        if not scriptAlreadyRegistered(station.uuid) then
            table.insert(DynamicRadio.scripts, makeScript(station))
        end
    end
end

Events.OnLoadRadioScripts.Add(CSR_RadioBroadcasts.OnLoadRadioScripts)

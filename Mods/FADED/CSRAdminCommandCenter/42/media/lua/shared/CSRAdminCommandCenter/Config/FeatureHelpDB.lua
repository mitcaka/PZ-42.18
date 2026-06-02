require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/Config/PopulationRecommendations"

local ACC = CSRAdminCommandCenter
ACC.FeatureHelpDB = ACC.FeatureHelpDB or {}

local Help = ACC.FeatureHelpDB

Help.entries = {
    {
        key = "cleanup",
        title = "Ground Cleanup",
        system = "CSR cleanup",
        liveSafe = "Read-only in MVP. Manual control requires version-specific testing.",
        performance = "Runs on timed server intervals near online players. Radius and max-per-scan drive cost.",
        risk = "Medium if configured aggressively.",
        debug = "Cleanup debug, error-only logging, export bundle.",
        logs = "CSR server console prints plus ACC cleanup snapshots.",
        recommendationKey = "cleanup",
        body = "CSR ground cleanup tags eligible dropped items, then removes old loose world inventory objects near players. It skips protected or mod-owned objects when CSR can detect that state.",
    },
    {
        key = "claims",
        title = "Claim Registry",
        system = "CSR claims",
        liveSafe = "Safe to read. Writes must use CSR server commands or verified CSR helpers.",
        performance = "ACC reads CSR claim rows through CSR's registry API only.",
        risk = "Low for read-only views; high for direct mutation.",
        debug = "Claims debug, audit tail, ownership history export.",
        logs = "CSR claim audit and ACC claim snapshots.",
        recommendationKey = "debug",
        body = "CSR stores personal, faction, and vehicle claims in an authoritative registry. Vehicle claims include durable keys, runtime IDs, SQL IDs, owner, title, and last known position.",
    },
    {
        key = "vehicle-claims",
        title = "Vehicle Claims",
        system = "CSR vehicle claim system",
        liveSafe = "Safe to inspect. Ownership changes must remain server-authoritative.",
        performance = "Reading claimed rows is cheap. Scanning every vehicle is not.",
        risk = "Medium. Incorrect durable-key handling can cause false ownership results.",
        debug = "Claims debug, vehicle tracking debug, audit export.",
        logs = "CSR claim audit, ACC claim history, ACC movement history.",
        recommendationKey = "vehicleTracking",
        body = "CSR vehicle claims use CSR vehicleKey as the identity anchor. Runtime IDs, vehicle ids, and SQL ids are not valid ACC identity sources for resolving, repairing, releasing, or mirroring ownership.",
    },
    {
        key = "authority",
        title = "Vehicle Claim Authority Snapshot",
        system = "ACC vehicle claim authority",
        liveSafe = "Safe as a passive snapshot and release-marker view. It does not repair, restore, or rewrite CSR claims.",
        performance = "Uses CSR claim rows only. It does not scan the full map or load chunks.",
        risk = "Low. It records server-side snapshots and release markers for admins without enforcing CSR state.",
        debug = "Claims debug, vehicle tracking debug, authority log, export bundle.",
        logs = "csr_acc_vehicle_claim_authority.log plus CSR claim audit.",
        recommendationKey = "vehicleTracking",
        body = "ACC keeps a server-side ModData snapshot of CSR vehicle claims keyed by durable vehicleKey. It is passive: no startup repair, no missing-row restore, and no loaded vehicle owner mirror writes.",
    },
    {
        key = "journal",
        title = "Skill Journal Use",
        system = "CSR skill journal",
        liveSafe = "Read-only monitoring in ACC. CSR still owns save and recover logic.",
        performance = "Low. ACC watches CSR journal commands and counts existing CSR journal ModData rows.",
        risk = "Medium because usage logs may contain player names and Steam IDs.",
        debug = "Player interaction debug, journal log, export bundle.",
        logs = "csr_acc_journal.log and CSR skill journal console output.",
        recommendationKey = "debug",
        body = "CSR Skill Journal saves and restores character knowledge snapshots under CSR_SkillJournal_v1. ACC detects journal modules, tracks get/save/recover/admin command use, and reports stored snapshot counts for admins.",
    },
    {
        key = "movement",
        title = "Vehicle Movement Tracking",
        system = "ACC tracking",
        liveSafe = "Safe when interval-based and claim-only.",
        performance = "Disabled by default. Uses claim rows and thresholds instead of full vehicle scans.",
        risk = "Low when read-only. Medium if admins assume unloaded means destroyed.",
        debug = "Vehicle tracking debug.",
        logs = "ACC movement history.",
        recommendationKey = "vehicleTracking",
        body = "Movement tracking should only log meaningful position changes for claimed vehicles. Unloaded vehicles are treated as unknown, not destroyed.",
    },
    {
        key = "padlocks",
        title = "Padlock Control",
        system = "CSR padlocks",
        liveSafe = "Safe when limited to loaded CSR padlocked objects and ACC command access.",
        performance = "Refresh scans loaded squares inside CSR claim bounds up to the configured tile cap, plus loaded claimed vehicles.",
        risk = "Medium. Removing a lock or giving a key bypasses CSR owner/coowner restrictions by design.",
        debug = "Claims debug, player interaction debug, export bundle.",
        logs = "CSR claim audit and ACC padlock log.",
        recommendationKey = "vehicleTracking",
        body = "CSR padlocks live on world objects and vehicles as flat modData. ACC can track loaded locks and requests removal through CSR's padlock server handler; owner rewrites and key injection are not performed by ACC.",
    },
    {
        key = "players",
        title = "Player Tracking",
        system = "ACC player monitor",
        liveSafe = "Safe when command-only and scoped to selected players.",
        performance = "Tracks selected online players on a throttled server tick and records only command names, not private chat.",
        risk = "Medium because admin action logs may include player names and Steam IDs.",
        debug = "Player interaction debug and export bundle.",
        logs = "ACC debug and access logs.",
        recommendationKey = "debug",
        body = "Admins can select an online player, follow their position on the map, filter that player's vehicle claims, and capture selected command activity for support investigations.",
    },
    {
        key = "debug",
        title = "Debug Sessions",
        system = "ACC debug",
        liveSafe = "Safe when temporary and scoped.",
        performance = "Verbose logging can grow quickly on busy servers.",
        risk = "Medium if left on permanently.",
        debug = "Debug master, per-system toggles, error-only, verbose.",
        logs = "ACC debug log and export bundle.",
        recommendationKey = "debug",
        body = "Debug mode records context needed for support without logging sensitive data unnecessarily. Use temporary sessions for reproduction, then export a bundle.",
    },
    {
        key = "map",
        title = "Vehicle Map View",
        system = "ACC map",
        liveSafe = "Safe for selected vehicle centering. Bulk markers need testing.",
        performance = "Marker count and refresh rate must be capped.",
        risk = "Low for selected vehicle, medium for many markers.",
        debug = "Map debug.",
        logs = "ACC map action log.",
        recommendationKey = "map",
        body = "The MVP centers the vanilla map on a selected vehicle's last known position. Later phases can add filtered marker overlays when Build 42 map symbol behavior is verified.",
    },
    {
        key = "access",
        title = "Command Access",
        system = "ACC security",
        liveSafe = "Safe. Server validates every request.",
        performance = "No meaningful cost.",
        risk = "High if client-only checks are trusted; this mod does not trust them.",
        debug = "Player interaction debug.",
        logs = "ACC access-denied events.",
        recommendationKey = "debug",
        body = "The command center is for higher ranked command players only. Basic players are denied server-side even if they attempt to send commands manually.",
    },
    {
        key = "settings sandbox options",
        title = "ACC Settings",
        system = "ACC sandbox options",
        liveSafe = "Safe for ACC-owned options. Server validates rank and writes through the ACC settings manager.",
        performance = "No polling cost except a small settings snapshot request when the tab opens or refreshes.",
        risk = "Medium because lowering access levels or raising marker/scan caps changes live server behavior.",
        debug = "Settings log, access-denied log, export bundle.",
        logs = "csr_acc_settings.log plus ACC diagnostic exports.",
        recommendationKey = "debug",
        body = "The Settings tab lets command staff view and control every sandbox option shipped by ACC without touching CSR files. Changes are applied to SandboxVars.CSRAdminCommandCenter and mirrored into server ModData so they can be re-applied on server start.",
    },
    {
        key = "export",
        title = "Diagnostic Export",
        system = "ACC export",
        liveSafe = "Safe for admins. Contents are server-side diagnostic data.",
        performance = "Use on demand, not on a timer.",
        risk = "Medium because exports may include player names and Steam IDs.",
        debug = "Export debug bundle.",
        logs = "ACC export log.",
        recommendationKey = "debug",
        body = "Exports package claim, cleanup, movement, debug, and detection summaries for CSR support. Avoid collecting unrelated private data.",
    },
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

function Help.search(query)
    local q = lower(query)
    local out = {}
    for i = 1, #Help.entries do
        local entry = Help.entries[i]
        local haystack = lower(entry.key .. " " .. entry.title .. " " .. entry.system .. " " .. entry.body)
        if q == "" or string.find(haystack, q, 1, true) then
            out[#out + 1] = entry
        end
    end
    return out
end

function Help.getRecommendation(entry, playerCount)
    if not entry then return nil, "small" end
    return ACC.PopulationRecommendations.get(entry.recommendationKey or "cleanup", playerCount)
end

return Help

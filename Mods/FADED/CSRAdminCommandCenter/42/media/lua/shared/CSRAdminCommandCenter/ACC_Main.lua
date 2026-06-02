CSRAdminCommandCenter = CSRAdminCommandCenter or {}

local ACC = CSRAdminCommandCenter

ACC.ID = "CSRAdminCommandCenter"
ACC.MODULE = "CSRAdminCommandCenter"
ACC.NAME = "CSR Admin Command Center"
ACC.VERSION = "0.1.7"
ACC.BUILD = 42

ACC.Commands = ACC.Commands or {
    RequestSnapshot = "RequestSnapshot",
    Snapshot = "Snapshot",
    RequestClaims = "RequestClaims",
    ClaimsPage = "ClaimsPage",
    ClaimAction = "ClaimAction",
    ClaimActionResult = "ClaimActionResult",
    RequestCleanup = "RequestCleanup",
    CleanupStatus = "CleanupStatus",
    RequestPlayers = "RequestPlayers",
    PlayersPage = "PlayersPage",
    SetPlayerTracked = "SetPlayerTracked",
    PlayerTrackState = "PlayerTrackState",
    RequestJournal = "RequestJournal",
    JournalPage = "JournalPage",
    JournalAction = "JournalAction",
    JournalActionResult = "JournalActionResult",
    RequestPadlocks = "RequestPadlocks",
    PadlocksPage = "PadlocksPage",
    PadlockAction = "PadlockAction",
    PadlockActionResult = "PadlockActionResult",
    SetDebugOption = "SetDebugOption",
    DebugState = "DebugState",
    RequestSettings = "RequestSettings",
    SettingsState = "SettingsState",
    SetSetting = "SetSetting",
    SettingsResult = "SettingsResult",
    RequestExport = "RequestExport",
    ExportResult = "ExportResult",
    AccessDenied = "AccessDenied",
    Error = "Error",
    Ping = "Ping",
    Pong = "Pong",
}

function ACC.sandbox()
    return (SandboxVars and SandboxVars.CSRAdminCommandCenter) or {}
end

function ACC.log(text)
    print("[" .. ACC.ID .. "] " .. tostring(text or ""))
end

function ACC.tableCount(tbl)
    local count = 0
    if type(tbl) ~= "table" then return count end
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function ACC.copyFlat(tbl)
    local out = {}
    if type(tbl) ~= "table" then return out end
    for k, v in pairs(tbl) do
        local tv = type(v)
        if tv == "string" or tv == "number" or tv == "boolean" or v == nil then
            out[k] = v
        end
    end
    return out
end

function ACC.toBool(value)
    return value == true or value == 1 or value == "true" or value == "1"
end

function ACC.clampNumber(value, minValue, maxValue, fallback)
    local n = tonumber(value)
    if not n then n = tonumber(fallback) or 0 end
    if minValue and n < minValue then n = minValue end
    if maxValue and n > maxValue then n = maxValue end
    return n
end

return ACC

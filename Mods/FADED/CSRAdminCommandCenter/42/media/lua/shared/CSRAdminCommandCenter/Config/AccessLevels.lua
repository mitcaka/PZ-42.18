require "CSRAdminCommandCenter/ACC_Main"

local ACC = CSRAdminCommandCenter
ACC.AccessLevels = ACC.AccessLevels or {}

local Access = ACC.AccessLevels

Access.RANKS = {
    admin = 100,
    moderator = 80,
    overseer = 70,
    gm = 60,
    observer = 20,
    none = 0,
    [""] = 0,
}

Access.SANDBOX_LEVEL_TO_NAME = {
    [1] = "admin",
    [2] = "moderator",
    [3] = "overseer",
    [4] = "gm",
    [5] = "observer",
}

function Access.normalize(accessLevel)
    local level = tostring(accessLevel or "")
    level = string.lower(level)
    if level == "administrator" then level = "admin" end
    if level == "moderators" then level = "moderator" end
    if level == "overseer " then level = "overseer" end
    if level == "game master" then level = "gm" end
    if level == "none" or level == "player" or level == "user" then level = "" end
    return level
end

function Access.rankFor(accessLevel)
    local key = Access.normalize(accessLevel)
    return Access.RANKS[key] or 0
end

function Access.requiredNameFromSandbox()
    local sb = ACC.sandbox()
    local selected = tonumber(sb.MinimumAccessLevel) or 4
    return Access.SANDBOX_LEVEL_TO_NAME[selected] or "gm"
end

function Access.requiredRankFromSandbox()
    return Access.rankFor(Access.requiredNameFromSandbox())
end

function Access.isCommandAccess(accessLevel)
    return Access.rankFor(accessLevel) >= Access.RANKS.observer
end

function Access.meets(accessLevel, requiredAccessLevel)
    return Access.rankFor(accessLevel) >= Access.rankFor(requiredAccessLevel)
end

function Access.summary(accessLevel)
    local normalized = Access.normalize(accessLevel)
    if normalized == "" then normalized = "none" end
    return {
        raw = tostring(accessLevel or ""),
        normalized = normalized,
        rank = Access.rankFor(accessLevel),
        required = Access.requiredNameFromSandbox(),
        requiredRank = Access.requiredRankFromSandbox(),
    }
end

return Access


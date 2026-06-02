require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/Config/AccessLevels"
require "CSRAdminCommandCenter/Utils/Time"

local ACC = CSRAdminCommandCenter
ACC.AdminAccess = ACC.AdminAccess or {}

local AdminAccess = ACC.AdminAccess
local Access = ACC.AccessLevels

local function sandbox()
    return ACC.sandbox()
end

function AdminAccess.isEnabled()
    local sb = sandbox()
    return sb.EnableCommandCenter ~= false
end

function AdminAccess.accessLevelFor(player)
    if not player or not player.getAccessLevel then return "" end
    return tostring(player:getAccessLevel() or "")
end

function AdminAccess.usernameFor(player)
    if not player then return "" end
    if player.getUsername then
        return tostring(player:getUsername() or "")
    end
    return ""
end

function AdminAccess.steamIdFor(player)
    if not player then return "" end
    if player.getSteamID then
        return tostring(player:getSteamID() or "")
    end
    return ""
end

function AdminAccess.hasView(player)
    if not AdminAccess.isEnabled() then return false end
    local access = AdminAccess.accessLevelFor(player)
    local rank = Access.rankFor(access)
    local requiredRank = Access.requiredRankFromSandbox()
    if rank >= requiredRank then return true end
    local sb = sandbox()
    if sb.AllowObserverReadOnly == true and Access.normalize(access) == "observer" then
        return true
    end
    return false
end

function AdminAccess.hasControl(player)
    if not AdminAccess.isEnabled() then return false end
    local access = AdminAccess.accessLevelFor(player)
    return Access.rankFor(access) >= Access.requiredRankFromSandbox()
end

function AdminAccess.hasSettingsAccess(player)
    local access = AdminAccess.accessLevelFor(player)
    return Access.rankFor(access) >= Access.requiredRankFromSandbox()
end

function AdminAccess.hasExport(player)
    if not AdminAccess.isEnabled() then return false end
    local access = AdminAccess.accessLevelFor(player)
    return Access.rankFor(access) >= Access.RANKS.admin
end

function AdminAccess.hasDataErase(player)
    if not AdminAccess.isEnabled() then return false end
    local access = AdminAccess.accessLevelFor(player)
    return Access.rankFor(access) >= Access.RANKS.admin
end

function AdminAccess.describe(player)
    local access = AdminAccess.accessLevelFor(player)
    local summary = Access.summary(access)
    summary.username = AdminAccess.usernameFor(player)
    summary.canView = AdminAccess.hasView(player)
    summary.canControl = AdminAccess.hasControl(player)
    summary.canSettings = AdminAccess.hasSettingsAccess(player)
    summary.canExport = AdminAccess.hasExport(player)
    summary.canDataErase = AdminAccess.hasDataErase(player)
    return summary
end

return AdminAccess

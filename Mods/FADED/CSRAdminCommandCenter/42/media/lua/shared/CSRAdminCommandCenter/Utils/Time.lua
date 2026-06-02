require "CSRAdminCommandCenter/ACC_Main"

local ACC = CSRAdminCommandCenter
ACC.Time = ACC.Time or {}

local Time = ACC.Time

function Time.nowSeconds()
    if os and os.time then return os.time() end
    return 0
end

function Time.worldAgeHours()
    if getGameTime then
        local gt = getGameTime()
        if gt and gt.getWorldAgeHours then
            return tonumber(gt:getWorldAgeHours()) or 0
        end
    end
    return 0
end

function Time.stamp()
    if os and os.date then
        return tostring(os.date("%Y-%m-%d %H:%M:%S"))
    end
    return tostring(Time.nowSeconds())
end

function Time.formatSeconds(seconds)
    local s = math.max(0, tonumber(seconds) or 0)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = math.floor(s % 60)
    if h > 0 then return string.format("%dh %02dm %02ds", h, m, sec) end
    if m > 0 then return string.format("%dm %02ds", m, sec) end
    return string.format("%ds", sec)
end

return Time

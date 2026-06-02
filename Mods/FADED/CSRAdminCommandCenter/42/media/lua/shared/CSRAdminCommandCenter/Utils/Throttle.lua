require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/Utils/Time"

local ACC = CSRAdminCommandCenter
ACC.Throttle = ACC.Throttle or {}

local Throttle = ACC.Throttle

function Throttle.new(intervalSeconds)
    return {
        intervalSeconds = tonumber(intervalSeconds) or 1,
        last = 0,
    }
end

function Throttle.ready(throttle, nowSeconds)
    if not throttle then return true end
    local now = tonumber(nowSeconds) or ACC.Time.nowSeconds()
    local last = tonumber(throttle.last) or 0
    if now - last >= (tonumber(throttle.intervalSeconds) or 1) then
        throttle.last = now
        return true
    end
    return false
end

return Throttle


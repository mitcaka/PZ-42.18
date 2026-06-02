require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/CSRAdapter"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/Data/Schemas"
require "CSRAdminCommandCenter/Utils/Time"
require "CSRAdminCommandCenter/Utils/VehicleIdentity"

local ACC = CSRAdminCommandCenter
ACC.VehicleTracker = ACC.VehicleTracker or {}

local VehicleTracker = ACC.VehicleTracker
local Keys = ACC.Schemas.Keys

VehicleTracker._minuteCounter = VehicleTracker._minuteCounter or 0

local function enabled()
    local sb = ACC.sandbox()
    return sb.EnableVehicleMovementTracking == true
end

local function positions()
    return ACC.Persistence.stateTable(Keys.VehiclePositions)
end

local function distanceSq(ax, ay, bx, by)
    local dx = (tonumber(ax) or 0) - (tonumber(bx) or 0)
    local dy = (tonumber(ay) or 0) - (tonumber(by) or 0)
    return dx * dx + dy * dy
end

function VehicleTracker.tick()
    -- No periodic vehicle sampling. Claim data is read only for admin requests/actions.
end

return VehicleTracker

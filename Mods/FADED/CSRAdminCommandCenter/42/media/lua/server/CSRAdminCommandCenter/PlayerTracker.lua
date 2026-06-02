require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/Data/Schemas"
require "CSRAdminCommandCenter/Utils/Time"

local ACC = CSRAdminCommandCenter
ACC.PlayerTracker = ACC.PlayerTracker or {}

local PlayerTracker = ACC.PlayerTracker
local Keys = ACC.Schemas.Keys

local function state()
    local st = ACC.Persistence.stateTable(Keys.PlayerState)
    st.tracked = st.tracked or {}
    st.last = st.last or {}
    return st
end

local function usernameFor(player)
    if not player or not player.getUsername then return "" end
    return tostring(player:getUsername() or "")
end

local function accessFor(player)
    if not player or not player.getAccessLevel then return "" end
    return tostring(player:getAccessLevel() or "")
end

local function steamIdFor(player)
    if not player or not player.getSteamID then return "" end
    return tostring(player:getSteamID() or "")
end

local function vehicleInfo(player)
    local out = { inVehicle = false, vehicleId = "", vehicleScript = "", speed = 0 }
    if not player or not player.getVehicle then return out end
    local vehicle = player:getVehicle()
    if not vehicle then return out end
    out.inVehicle = true
    if vehicle.getCurrentSpeedKmHour then out.speed = tonumber(vehicle:getCurrentSpeedKmHour()) or 0 end
    if vehicle.getScript then
        local script = vehicle:getScript()
        if script and script.getName then out.vehicleScript = tostring(script:getName() or "") end
    end
    return out
end

local function snapshot(player)
    local info = vehicleInfo(player)
    local user = usernameFor(player)
    local x, y, z = 0, 0, 0
    if player.getX then x = tonumber(player:getX()) or 0 end
    if player.getY then y = tonumber(player:getY()) or 0 end
    if player.getZ then z = tonumber(player:getZ()) or 0 end
    local onlineId = ""
    if player.getOnlineID then onlineId = tostring(player:getOnlineID() or "") end
    local st = state()
    local last = st.last[user] or {}
    return {
        username = user,
        access = accessFor(player),
        steamID = steamIdFor(player),
        onlineID = onlineId,
        x = math.floor(x),
        y = math.floor(y),
        z = math.floor(z),
        inVehicle = info.inVehicle,
        vehicleId = info.vehicleId,
        vehicleScript = info.vehicleScript,
        speed = info.speed,
        tracked = st.tracked[user] == true,
        lastAction = tostring(last.action or ""),
        lastActionAt = tonumber(last.actionAt) or 0,
    }
end

local function onlinePlayers()
    local out = {}
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players or not players.size then return out end
    local count = tonumber(players:size()) or 0
    for i = 0, count - 1 do
        local p = players:get(i)
        if p then out[#out + 1] = snapshot(p) end
    end
    table.sort(out, function(a, b) return tostring(a.username or "") < tostring(b.username or "") end)
    return out
end

function PlayerTracker.findOnline(username)
    username = tostring(username or "")
    if username == "" then return nil end
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players or not players.size then return nil end
    local count = tonumber(players:size()) or 0
    for i = 0, count - 1 do
        local p = players:get(i)
        if p and usernameFor(p) == username then return p end
    end
    return nil
end

function PlayerTracker.buildList(args)
    args = args or {}
    local query = string.lower(tostring(args.query or ""))
    local rows = {}
    local all = onlinePlayers()
    for i = 1, #all do
        local row = all[i]
        local haystack = string.lower(tostring(row.username or "") .. " "
            .. tostring(row.access or "") .. " " .. tostring(row.vehicleScript or ""))
        if query == "" or string.find(haystack, query, 1, true) then
            rows[#rows + 1] = row
        end
    end
    return {
        rows = rows,
        total = #rows,
        query = tostring(args.query or ""),
        tracked = state().tracked,
    }
end

function PlayerTracker.setTracked(username, enabled, actor)
    username = tostring(username or "")
    if username == "" then return false, "Enter a username" end
    local st = state()
    st.tracked[username] = enabled == true or nil
    local actorName = ""
    if actor and actor.getUsername then
        actorName = tostring(actor:getUsername() or "")
    end
    ACC.Persistence.enqueue("debug", "player_track "
        .. "username=" .. username
        .. " enabled=" .. tostring(enabled == true)
        .. " by=" .. tostring(actorName))
    return true, (enabled == true) and ("Tracking " .. username) or ("Stopped tracking " .. username)
end

function PlayerTracker.observeClientCommand(module, command, player)
    local user = usernameFor(player)
    if user == "" then return end
    local st = state()
    if st.tracked[user] ~= true then return end
    if module == ACC.MODULE then return end
    local action = tostring(module or "") .. ":" .. tostring(command or "")
    st.last[user] = {
        action = action,
        actionAt = ACC.Time.nowSeconds(),
    }
    ACC.Persistence.enqueue("debug", "player_action username=" .. user .. " action=" .. action)
end

function PlayerTracker.tick()
    -- No periodic player sampling. Live player rows are built only for admin requests.
end

return PlayerTracker

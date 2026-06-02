require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/Config/AccessLevels"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/ACC_Window"

local ACC = CSRAdminCommandCenter
ACC.UIManager = ACC.UIManager or {}

local Manager = ACC.UIManager

Manager.window = Manager.window or nil

local function localPlayer()
    return getPlayer and getPlayer() or nil
end

local function accessLevel()
    local p = localPlayer()
    if not p or not p.getAccessLevel then return "" end
    return tostring(p:getAccessLevel() or "")
end

function Manager.localCanOpen()
    local sb = ACC.sandbox()
    local access = accessLevel()
    local rank = ACC.AccessLevels.rankFor(access)
    local requiredRank = ACC.AccessLevels.requiredRankFromSandbox()
    if sb.EnableCommandCenter == false then return rank >= requiredRank end
    if rank >= requiredRank then return true end
    if sb.AllowObserverReadOnly == true and ACC.AccessLevels.normalize(access) == "observer" then return true end
    return false
end

local function halo(message, r, g, b)
    local p = localPlayer()
    if p and p.setHaloNote then p:setHaloNote(message, r, g, b, 220) end
end

function Manager.open()
    if Manager.window and Manager.window:getIsVisible() then return end
    if not Manager.localCanOpen() then
        halo("CSR ACC requires command access", 255, 90, 90)
        return
    end

    local sw = getCore and getCore():getScreenWidth() or 1280
    local sh = getCore and getCore():getScreenHeight() or 720
    local w = math.min(980, math.max(760, sw - 120))
    local h = math.min(700, math.max(540, sh - 100))
    local x = math.floor((sw - w) / 2)
    local y = math.floor((sh - h) / 2)

    Manager.window = CSR_ACC_Window:new(x, y, w, h)
    Manager.window:initialise()
    Manager.window:addToUIManager()
    Manager.window:setVisible(true)
    Manager.window:bringToTop()

    ACC.ClientCommands.requestSnapshot()
    ACC.ClientCommands.requestClaims({ page = 1, kind = "all" })
    ACC.ClientCommands.requestPlayers({})
    ACC.ClientCommands.requestJournal({ page = 1 })
    ACC.ClientCommands.requestPadlocks({ page = 1, targetKind = "all" })
    ACC.ClientCommands.requestSettings()
end

function Manager.close()
    if Manager.window then
        Manager.window:removeFromUIManager()
        Manager.window = nil
    end
end

function Manager.toggle()
    if Manager.window and Manager.window:getIsVisible() then
        Manager.close()
    else
        Manager.open()
    end
end

local function coordsForVehicle(row)
    if type(row) ~= "table" then return nil, nil end
    local x = tonumber(row.lastVehicleX) or tonumber(row.x) or 0
    local y = tonumber(row.lastVehicleY) or tonumber(row.y) or 0
    return x, y
end

function Manager.showMapFor(row)
    if type(row) ~= "table" then return end
    ACC.ClientCommands.setSelectedVehicle(row)
    local x, y = coordsForVehicle(row)
    if not x or not y or x == 0 or y == 0 then
        halo("No known map position", 255, 180, 90)
        return
    end
    if ISWorldMap and ISWorldMap.ShowWorldMap then
        ISWorldMap.ShowWorldMap(0, x, y)
    end
    local map = ISWorldMap_instance
    if map and map.mapAPI and map.mapAPI.centerOn then
        map.mapAPI:centerOn(x, y)
    end
end

return Manager

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_MapTab = ISPanel:derive("CSR_ACC_MapTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw

function CSR_ACC_MapTab:initialise()
    ISPanel.initialise(self)
end

local function halo(message, r, g, b)
    local p = getPlayer and getPlayer() or nil
    if p and p.setHaloNote then p:setHaloNote(tostring(message or ""), r or 120, g or 220, b or 160, 220) end
end

local function rowVehicleCoords(row)
    if type(row) ~= "table" then return nil, nil, nil end
    local x = tonumber(row.lastVehicleX) or tonumber(row.x) or 0
    local y = tonumber(row.lastVehicleY) or tonumber(row.y) or 0
    local z = tonumber(row.lastVehicleZ) or tonumber(row.z) or 0
    return x, y, z
end

local function rowPlayerCoords(row)
    if type(row) ~= "table" then return nil, nil, nil end
    return tonumber(row.x) or 0, tonumber(row.y) or 0, tonumber(row.z) or 0
end

local function rowPadlockCoords(row)
    if type(row) ~= "table" then return nil, nil, nil end
    return tonumber(row.x) or 0, tonumber(row.y) or 0, tonumber(row.z) or 0
end

local function openVanillaMapAt(x, y)
    if not x or not y or x == 0 or y == 0 then
        halo("No known map position", 255, 180, 90)
        return
    end
    if ISWorldMap and ISWorldMap.ShowWorldMap then
        ISWorldMap.ShowWorldMap(0, x, y, 18)
    end
    local map = ISWorldMap_instance
    if map and map.mapAPI and map.mapAPI.centerOn then
        map.mapAPI:centerOn(x, y)
    end
end

local function nowSeconds()
    if getTimestampMs then return (tonumber(getTimestampMs()) or 0) / 1000 end
    if os and os.time then return os.time() end
    return 0
end

function CSR_ACC_MapTab:createChildren()
    self.followMode = self.followMode or "vehicle"

    self.openMapBtn = ISButton:new(12, 10, 92, 24, "Open Map", self, CSR_ACC_MapTab.onOpenMap)
    self.openMapBtn:initialise(); self.openMapBtn:instantiate(); Draw.styleButton(self.openMapBtn, true); self:addChild(self.openMapBtn)

    self.vehicleBtn = ISButton:new(112, 10, 106, 24, "Follow Car", self, CSR_ACC_MapTab.onFollowVehicle)
    self.vehicleBtn:initialise(); self.vehicleBtn:instantiate(); Draw.styleButton(self.vehicleBtn, true); self:addChild(self.vehicleBtn)

    self.playerBtn = ISButton:new(226, 10, 122, 24, "Follow Player", self, CSR_ACC_MapTab.onFollowPlayer)
    self.playerBtn:initialise(); self.playerBtn:instantiate(); Draw.styleButton(self.playerBtn); self:addChild(self.playerBtn)

    self.padlockBtn = ISButton:new(356, 10, 108, 24, "Follow Lock", self, CSR_ACC_MapTab.onFollowPadlock)
    self.padlockBtn:initialise(); self.padlockBtn:instantiate(); Draw.styleButton(self.padlockBtn); self:addChild(self.padlockBtn)

    self.refreshBtn = ISButton:new(472, 10, 78, 24, "Refresh", self, CSR_ACC_MapTab.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate(); Draw.styleButton(self.refreshBtn); self:addChild(self.refreshBtn)

    self._mapX = 250
    self._mapY = 48
    self._mapW = self.width - 272
    self._mapH = self.height - 92
    self.mapView = nil
    self._embeddedMapReady = false
end

function CSR_ACC_MapTab:target()
    if self.followMode == "player" then
        local row = ACC.ClientCommands.state.selectedPlayer
        local x, y, z = rowPlayerCoords(row)
        return row, x, y, z, "player"
    end
    if self.followMode == "padlock" then
        local row = ACC.ClientCommands.state.selectedPadlock
        local x, y, z = rowPadlockCoords(row)
        return row, x, y, z, "padlock"
    end
    local row = ACC.ClientCommands.state.selectedVehicle
    local x, y, z = rowVehicleCoords(row)
    return row, x, y, z, "vehicle"
end

function CSR_ACC_MapTab:onOpenMap()
    local _, x, y = self:target()
    openVanillaMapAt(x, y)
end

function CSR_ACC_MapTab:onFollowVehicle()
    if not ACC.ClientCommands.state.selectedVehicle then
        halo("Select a vehicle claim in Claims, then click Track", 255, 180, 90)
        return
    end
    self.followMode = "vehicle"
    Draw.styleButton(self.vehicleBtn, true)
    Draw.styleButton(self.playerBtn, false)
    Draw.styleButton(self.padlockBtn, false)
end

function CSR_ACC_MapTab:onFollowPlayer()
    if not ACC.ClientCommands.state.selectedPlayer then
        halo("Select a player in Players, then click Track", 255, 180, 90)
        return
    end
    self.followMode = "player"
    Draw.styleButton(self.vehicleBtn, false)
    Draw.styleButton(self.playerBtn, true)
    Draw.styleButton(self.padlockBtn, false)
end

function CSR_ACC_MapTab:onFollowPadlock()
    if not ACC.ClientCommands.state.selectedPadlock then
        halo("Select a padlock in Locks, then click Track", 255, 180, 90)
        return
    end
    self.followMode = "padlock"
    Draw.styleButton(self.vehicleBtn, false)
    Draw.styleButton(self.playerBtn, false)
    Draw.styleButton(self.padlockBtn, true)
end

function CSR_ACC_MapTab:onRefresh()
    ACC.ClientCommands.requestPlayers({})
    ACC.ClientCommands.requestClaims({ page = 1, kind = "vehicle" })
    ACC.ClientCommands.requestPadlocks({ page = 1, targetKind = "all", force = true })
end

function CSR_ACC_MapTab:centerEmbeddedMap(x, y)
    return
end

function CSR_ACC_MapTab:drawFallbackTracker(x, y, w, h, tx, ty, kind)
    self:drawRect(x, y, w, h, 0.72, 0.02, 0.01, 0.04)
    self:drawRectBorder(x, y, w, h, 0.85, 0.30, 1.00, 0.18)
    for i = 1, 8 do
        local gx = x + math.floor((w / 9) * i)
        local gy = y + math.floor((h / 9) * i)
        self:drawRect(gx, y, 1, h, 0.18, 0.30, 1.00, 0.18)
        self:drawRect(x, gy, w, 1, 0.18, 0.30, 1.00, 0.18)
    end
    local cx = x + math.floor(w / 2)
    local cy = y + math.floor(h / 2)
    self:drawRect(cx - 10, cy, 20, 1, 0.95, 0.30, 1.00, 0.18)
    self:drawRect(cx, cy - 10, 1, 20, 0.95, 0.30, 1.00, 0.18)
    self:drawRect(cx - 5, cy - 5, 10, 10, 0.95, 0.30, 1.00, 0.18)
    local label = "VEHICLE"
    if kind == "player" then label = "PLAYER" end
    if kind == "padlock" then label = "PADLOCK" end
    Draw.text(self, label, x + 12, y + 12, Draw.colors.good)
    Draw.text(self, "Last known: " .. tostring(math.floor(tonumber(tx) or 0)) .. ", "
        .. tostring(math.floor(tonumber(ty) or 0)), x + 12, y + 30, Draw.colors.text)
    Draw.text(self, "Open Map uses the full vanilla world map at this target.", x + 12, y + h - 28, Draw.colors.muted)
end

function CSR_ACC_MapTab:render()
    ISPanel.render(self)
    local _, x, y, _, kind = self:target()
    self:drawFallbackTracker(self._mapX or 250, self._mapY or 48,
        self._mapW or (self.width - 272), self._mapH or (self.height - 92), x, y, kind)
end

function CSR_ACC_MapTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)

    local row, x, y, z, kind = self:target()
    if kind == "player" then
        local now = nowSeconds()
        if now - (tonumber(self._lastPlayerRefresh) or 0) >= 3 then
            self._lastPlayerRefresh = now
            ACC.ClientCommands.requestPlayers({})
        end
    end
    self:centerEmbeddedMap(x, y)

    local sideX = 12
    local yy = 48
    Draw.glassPanel(self, sideX, yy - 6, 222, self.height - 56)
    Draw.section(self, "Tracker Target", sideX + 8, yy, 202)
    yy = yy + 30
    if not row then
        Draw.textWrapped(self,
            "Select a vehicle in Claims or Vehicles, a player in Players, or a padlock in Locks, then press Track.",
            sideX + 12, yy, 30, 5, Draw.colors.muted)
        return
    end

    if kind == "player" then
        Draw.labelValue(self, "Type", "Player", sideX + 12, yy, Draw.colors.good, 84, 18); yy = yy + 20
        Draw.labelValue(self, "Name", tostring(row.username or ""), sideX + 12, yy, nil, 84, 18); yy = yy + 20
        Draw.labelValue(self, "Access", tostring(row.access or ""), sideX + 12, yy, nil, 84, 18); yy = yy + 20
        Draw.labelValue(self, "Vehicle", tostring(row.vehicleScript or ""), sideX + 12, yy, nil, 84, 18); yy = yy + 20
    elseif kind == "padlock" then
        Draw.labelValue(self, "Type", "Padlock", sideX + 12, yy, Draw.colors.good, 84, 18); yy = yy + 20
        Draw.labelValue(self, "Target", tostring(row.targetKind or ""), sideX + 12, yy, nil, 84, 18); yy = yy + 20
        Draw.labelValue(self, "Owner", tostring(row.padlockOwner or row.claimOwner or ""), sideX + 12, yy, nil, 84, 18); yy = yy + 20
        Draw.labelValue(self, "Object", tostring(row.objectName or row.vehicleScript or ""), sideX + 12, yy, nil, 84, 18); yy = yy + 20
    else
        Draw.labelValue(self, "Type", "Vehicle", sideX + 12, yy, Draw.colors.good, 84, 18); yy = yy + 20
        Draw.labelValue(self, "Claim ID", tostring(row.id or ""), sideX + 12, yy, nil, 84, 18); yy = yy + 20
        Draw.labelValue(self, "Owner", tostring(row.owner or ""), sideX + 12, yy, nil, 84, 18); yy = yy + 20
        Draw.labelValue(self, "Title", tostring(row.title or ""), sideX + 12, yy, nil, 84, 18); yy = yy + 20
    end

    Draw.labelValue(self, "X/Y/Z", tostring(x or 0) .. ", " .. tostring(y or 0) .. ", " .. tostring(z or 0),
        sideX + 12, yy, nil, 84, 20); yy = yy + 28
    Draw.section(self, "Live Mode", sideX + 8, yy, 202)
    yy = yy + 30
    Draw.textWrapped(self,
        self.mapView and "Embedded vanilla minimap view. It recenters on the selected target using the latest known coordinates."
            or "Fallback tracker view. Vanilla embedded map API was not available.",
        sideX + 12, yy, 30, 5, Draw.colors.text)
end

function CSR_ACC_MapTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_MapTab

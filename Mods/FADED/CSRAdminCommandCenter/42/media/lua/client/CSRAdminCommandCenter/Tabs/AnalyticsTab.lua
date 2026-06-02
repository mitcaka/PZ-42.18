require "ISUI/ISPanel"
require "ISUI/ISButton"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_AnalyticsTab = ISPanel:derive("CSR_ACC_AnalyticsTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw

function CSR_ACC_AnalyticsTab:initialise()
    ISPanel.initialise(self)
end

function CSR_ACC_AnalyticsTab:createChildren()
    self.refreshBtn = ISButton:new(12, 10, 92, 24, "Refresh", self, CSR_ACC_AnalyticsTab.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate(); Draw.styleButton(self.refreshBtn); self:addChild(self.refreshBtn)
end

function CSR_ACC_AnalyticsTab:onRefresh()
    ACC.ClientCommands.requestSnapshot()
end

local function drawBar(panel, label, count, maxCount, x, y, w)
    maxCount = math.max(1, tonumber(maxCount) or 1)
    local pct = math.min(1, (tonumber(count) or 0) / maxCount)
    panel:drawRect(x, y + 15, w, 8, 0.28, 0.18, 0.08, 0.34)
    panel:drawRect(x, y + 15, math.floor(w * pct), 8, 0.82, 0.30, 1.00, 0.18)
    panel:drawRectBorder(x, y + 15, w, 8, 0.45, 0.48, 0.16, 0.92)
    Draw.text(panel, tostring(label), x, y, Draw.colors.text)
    Draw.text(panel, tostring(count), x + w + 10, y, Draw.colors.muted)
end

function CSR_ACC_AnalyticsTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)
    local snapshot = ACC.ClientCommands.state.snapshot or {}
    local claims = snapshot.claims or {}
    local y = 48
    Draw.section(self, "Claim Totals", 12, y, self.width - 24)
    y = y + 30
    Draw.labelValue(self, "Total", tostring(claims.total or 0), 16, y); y = y + 20
    Draw.labelValue(self, "Vehicle", tostring(claims.vehicle or 0), 16, y); y = y + 20
    Draw.labelValue(self, "Personal", tostring(claims.personal or 0), 16, y); y = y + 20
    Draw.labelValue(self, "Faction", tostring(claims.faction or 0), 16, y); y = y + 32

    Draw.section(self, "Claims By Owner", 12, y, self.width - 24)
    y = y + 30
    local owners = claims.topOwners or {}
    local maxOwner = owners[1] and owners[1].count or 1
    for i = 1, math.min(8, #owners) do
        drawBar(self, owners[i].key, owners[i].count, maxOwner, 16, y, 260)
        y = y + 28
    end

    local x2 = math.floor(self.width / 2)
    local y2 = 48
    Draw.section(self, "Vehicle Types", x2, y2, self.width - x2 - 16)
    y2 = y2 + 30
    local types = claims.topVehicleScripts or {}
    local maxType = types[1] and types[1].count or 1
    for i = 1, math.min(8, #types) do
        drawBar(self, types[i].key, types[i].count, maxType, x2 + 4, y2, 260)
        y2 = y2 + 28
    end
end

function CSR_ACC_AnalyticsTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_AnalyticsTab

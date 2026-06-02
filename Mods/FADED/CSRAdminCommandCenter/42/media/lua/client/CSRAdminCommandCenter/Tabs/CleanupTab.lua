require "ISUI/ISPanel"
require "ISUI/ISButton"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_CleanupTab = ISPanel:derive("CSR_ACC_CleanupTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw

function CSR_ACC_CleanupTab:initialise()
    ISPanel.initialise(self)
end

function CSR_ACC_CleanupTab:createChildren()
    self.refreshBtn = ISButton:new(12, 10, 92, 24, "Refresh", self, CSR_ACC_CleanupTab.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate(); Draw.styleButton(self.refreshBtn); self:addChild(self.refreshBtn)
end

function CSR_ACC_CleanupTab:onRefresh()
    ACC.ClientCommands.requestCleanup()
end

function CSR_ACC_CleanupTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)
    local status = ACC.ClientCommands.state.cleanupStatus
        or (ACC.ClientCommands.state.snapshot and ACC.ClientCommands.state.snapshot.cleanup)
        or {}
    local cfg = status.config or {}
    local y = 48
    Draw.section(self, "Cleanup Status", 12, y, self.width - 24)
    y = y + 30
    Draw.labelValue(self, "CSR cleanup module", Draw.boolText(status.detected == true), 16, y, Draw.boolColor(status.detected == true)); y = y + 20
    Draw.labelValue(self, "Ground cleanup", Draw.boolText(cfg.groundCleanupEnabled == true), 16, y, Draw.boolColor(cfg.groundCleanupEnabled == true)); y = y + 20
    Draw.labelValue(self, "Cleanup minutes", tostring(cfg.groundCleanupMinutes or ""), 16, y); y = y + 20
    Draw.labelValue(self, "Scan radius", tostring(cfg.groundCleanupScanRadius or ""), 16, y); y = y + 20
    Draw.labelValue(self, "Max Z", tostring(cfg.groundCleanupMaxZ or ""), 16, y); y = y + 20
    Draw.labelValue(self, "Max per scan", tostring(cfg.groundCleanupMaxPerScan or ""), 16, y); y = y + 20
    Draw.labelValue(self, "Cleanup logging", Draw.boolText(cfg.logGroundCleanup == true), 16, y, Draw.boolColor(cfg.logGroundCleanup == true)); y = y + 28

    Draw.section(self, "Item Wipe Scheduler", 12, y, self.width - 24)
    y = y + 30
    Draw.labelValue(self, "Enabled", Draw.boolText(cfg.itemWipeSchedulerEnabled == true), 16, y, Draw.boolColor(cfg.itemWipeSchedulerEnabled == true)); y = y + 20
    Draw.labelValue(self, "Interval minutes", tostring(cfg.itemWipeIntervalMinutes or ""), 16, y); y = y + 20
    Draw.labelValue(self, "Warn minutes", tostring(cfg.itemWipeWarnMinutes or ""), 16, y); y = y + 28

    Draw.section(self, "Control Surface", 12, y, self.width - 24)
    y = y + 30
    Draw.labelValue(self, "Mode", status.readOnly and "Read-only" or "Control", 16, y, status.readOnly and Draw.colors.warn or Draw.colors.good); y = y + 20
    Draw.labelValue(self, "Manual trigger", status.manualTriggerSupported and "Supported" or "Not supported", 16, y, status.manualTriggerSupported and Draw.colors.good or Draw.colors.muted); y = y + 20
    Draw.labelValue(self, "Pause / resume", status.pauseSupported and "Supported" or "Not supported", 16, y, status.pauseSupported and Draw.colors.good or Draw.colors.muted); y = y + 20
    Draw.labelValue(self, "Next run", tostring(status.nextRunText or ""), 16, y, Draw.colors.muted)
end

function CSR_ACC_CleanupTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_CleanupTab

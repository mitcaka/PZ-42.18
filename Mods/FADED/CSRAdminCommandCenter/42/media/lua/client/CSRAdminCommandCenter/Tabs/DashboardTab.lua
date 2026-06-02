require "ISUI/ISPanel"
require "ISUI/ISButton"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_DashboardTab = ISPanel:derive("CSR_ACC_DashboardTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw

function CSR_ACC_DashboardTab:initialise()
    ISPanel.initialise(self)
end

function CSR_ACC_DashboardTab:createChildren()
    self.refreshBtn = ISButton:new(12, 10, 86, 24, "Refresh", self, CSR_ACC_DashboardTab.onRefresh)
    self.refreshBtn:initialise()
    self.refreshBtn:instantiate()
    Draw.styleButton(self.refreshBtn)
    self:addChild(self.refreshBtn)

    self.exportBtn = ISButton:new(106, 10, 86, 24, "Export", self, CSR_ACC_DashboardTab.onExport)
    self.exportBtn:initialise()
    self.exportBtn:instantiate()
    Draw.styleButton(self.exportBtn)
    self:addChild(self.exportBtn)
end

function CSR_ACC_DashboardTab:onRefresh()
    ACC.ClientCommands.requestSnapshot()
end

function CSR_ACC_DashboardTab:onExport()
    ACC.ClientCommands.requestExport()
end

local function moduleText(snapshot, key)
    local modules = snapshot and snapshot.detection and snapshot.detection.modules or {}
    return Draw.boolText(modules[key] == true)
end

local function moduleColor(snapshot, key)
    local modules = snapshot and snapshot.detection and snapshot.detection.modules or {}
    return Draw.boolColor(modules[key] == true)
end

function CSR_ACC_DashboardTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)

    local snapshot = ACC.ClientCommands.state.snapshot
    local x2 = math.floor(self.width / 2)
    local y = 44
    Draw.section(self, "Server", 12, y, x2 - 28)
    y = y + 30

    if not snapshot then
        Draw.text(self, "Waiting for server snapshot...", 16, y, Draw.colors.warn)
        return
    end

    local detected = snapshot.detection and snapshot.detection.detected == true
    Draw.labelValue(self, "CSR detected", Draw.boolText(detected), 16, y, Draw.boolColor(detected)); y = y + 20
    if snapshot.detection and snapshot.detection.testBranchActive then
        Draw.labelValue(self, "Test branch active", "Yes", 16, y, Draw.colors.warn); y = y + 20
    end
    Draw.labelValue(self, "Online players", tostring(snapshot.population or 0), 16, y); y = y + 20
    Draw.labelValue(self, "Access", tostring(snapshot.access and snapshot.access.normalized or ""), 16, y); y = y + 20
    Draw.labelValue(self, "Server time", tostring(snapshot.serverTimeText or ""), 16, y); y = y + 28

    Draw.section(self, "CSR Modules", 12, y, x2 - 28)
    y = y + 30
    Draw.labelValue(self, "Claim registry", moduleText(snapshot, "claimRegistry"), 16, y, moduleColor(snapshot, "claimRegistry")); y = y + 20
    Draw.labelValue(self, "Vehicle claim API", moduleText(snapshot, "vehicleClaim"), 16, y, moduleColor(snapshot, "vehicleClaim")); y = y + 20
    Draw.labelValue(self, "Padlock API", moduleText(snapshot, "padlockServer"), 16, y, moduleColor(snapshot, "padlockServer")); y = y + 20
    Draw.labelValue(self, "Skill journal", moduleText(snapshot, "skillJournal"), 16, y, moduleColor(snapshot, "skillJournal")); y = y + 20
    Draw.labelValue(self, "Claim audit", moduleText(snapshot, "claimAudit"), 16, y, moduleColor(snapshot, "claimAudit")); y = y + 20
    Draw.labelValue(self, "Ground cleanup", moduleText(snapshot, "groundCleanup"), 16, y, moduleColor(snapshot, "groundCleanup")); y = y + 28

    Draw.section(self, "Journal Use", 12, y, self.width - x2 - 28)
    y = y + 30
    local journal = snapshot.journal or {}
    local usage = journal.usage or {}
    local store = journal.store or {}
    Draw.labelValue(self, "Enabled", Draw.boolText(journal.enabled == true), 16, y, Draw.boolColor(journal.enabled == true)); y = y + 20
    Draw.labelValue(self, "Saves", tostring(usage.save or 0), 16, y); y = y + 20
    Draw.labelValue(self, "Recovers", tostring(usage.recover or 0), 16, y); y = y + 20
    Draw.labelValue(self, "Stored snapshots", tostring(store.snapshots or 0), 16, y); y = y + 28

    local y2 = 44
    Draw.section(self, "Claims", x2, y2, self.width - x2 - 16)
    y2 = y2 + 30
    local claims = snapshot.claims or {}
    Draw.labelValue(self, "Total claims", tostring(claims.total or 0), x2 + 4, y2); y2 = y2 + 20
    Draw.labelValue(self, "Vehicle claims", tostring(claims.vehicle or 0), x2 + 4, y2); y2 = y2 + 20
    Draw.labelValue(self, "Personal claims", tostring(claims.personal or 0), x2 + 4, y2); y2 = y2 + 20
    Draw.labelValue(self, "Faction claims", tostring(claims.faction or 0), x2 + 4, y2); y2 = y2 + 28

    Draw.section(self, "Vehicle Authority", x2, y2, self.width - x2 - 16)
    y2 = y2 + 30
    local authority = snapshot.vehicleAuthority or {}
    Draw.labelValue(self, "Snapshot", Draw.boolText(authority.enabled == true), x2 + 4, y2, Draw.boolColor(authority.enabled == true)); y2 = y2 + 20
    Draw.labelValue(self, "Mode", "Passive", x2 + 4, y2); y2 = y2 + 20
    Draw.labelValue(self, "Snapshots", tostring(authority.rows or 0), x2 + 4, y2); y2 = y2 + 20
    Draw.labelValue(self, "Release marks", tostring(authority.released or 0), x2 + 4, y2); y2 = y2 + 28

    Draw.section(self, "Padlocks", x2, y2, self.width - x2 - 16)
    y2 = y2 + 30
    local padlocks = snapshot.padlocks or {}
    Draw.labelValue(self, "Tracked locks", tostring(padlocks.total or 0), x2 + 4, y2); y2 = y2 + 20
    Draw.labelValue(self, "Vehicle locks", tostring(padlocks.vehicle or 0), x2 + 4, y2); y2 = y2 + 20
    Draw.labelValue(self, "Container locks", tostring(padlocks.container or 0), x2 + 4, y2); y2 = y2 + 28

    Draw.section(self, "Cleanup", x2, y2, self.width - x2 - 16)
    y2 = y2 + 30
    local cleanup = snapshot.cleanup or {}
    local cfg = cleanup.config or {}
    Draw.labelValue(self, "Ground cleanup", Draw.boolText(cfg.groundCleanupEnabled == true), x2 + 4, y2, Draw.boolColor(cfg.groundCleanupEnabled == true)); y2 = y2 + 20
    Draw.labelValue(self, "Interval minutes", tostring(cfg.groundCleanupMinutes or ""), x2 + 4, y2); y2 = y2 + 20
    Draw.labelValue(self, "Item wipe scheduler", Draw.boolText(cfg.itemWipeSchedulerEnabled == true), x2 + 4, y2, Draw.boolColor(cfg.itemWipeSchedulerEnabled == true)); y2 = y2 + 28

    Draw.section(self, "Recent CSR Audit", x2, y2, self.width - x2 - 16)
    y2 = y2 + 28
    local audit = snapshot.recentAudit or {}
    for i = 1, math.min(4, #audit) do
        y2 = Draw.textWrapped(self, tostring(audit[i]), x2 + 4, y2, 58, 2, Draw.colors.muted)
    end
end

function CSR_ACC_DashboardTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_DashboardTab

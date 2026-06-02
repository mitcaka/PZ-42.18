require "ISUI/ISPanel"
require "ISUI/ISButton"
require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/ClientCommands"
require "CSRAdminCommandCenter/UI/Components/ACC_Draw"

CSR_ACC_DebugTab = ISPanel:derive("CSR_ACC_DebugTab")

local ACC = CSRAdminCommandCenter
local Draw = ACC.Draw

local OPTIONS = {
    { key = "claims", label = "Claims" },
    { key = "vehicleTracking", label = "Vehicle Tracking" },
    { key = "cleanup", label = "Cleanup" },
    { key = "map", label = "Map" },
    { key = "playerInteraction", label = "Player Interaction" },
    { key = "errorsOnly", label = "Error Only" },
    { key = "verbose", label = "Verbose" },
    { key = "temporarySession", label = "Temporary Session" },
}

function CSR_ACC_DebugTab:initialise()
    ISPanel.initialise(self)
end

function CSR_ACC_DebugTab:createChildren()
    self.buttons = {}
    local x = 12
    local y = 10
    for i = 1, #OPTIONS do
        local opt = OPTIONS[i]
        local btn = ISButton:new(x, y, 168, 24, opt.label, self, CSR_ACC_DebugTab.onToggle)
        btn:initialise()
        btn:instantiate()
        btn.optionKey = opt.key
        btn.optionLabel = opt.label
        Draw.styleButton(btn)
        self:addChild(btn)
        self.buttons[#self.buttons + 1] = btn
        y = y + 30
        if i == 4 then
            x = 192
            y = 10
        end
    end
end

function CSR_ACC_DebugTab:onToggle(button)
    if not button or not button.optionKey then return end
    local st = ACC.ClientCommands.state.debugState
        or (ACC.ClientCommands.state.snapshot and ACC.ClientCommands.state.snapshot.debug)
        or {}
    ACC.ClientCommands.setDebugOption(button.optionKey, st[button.optionKey] ~= true)
end

function CSR_ACC_DebugTab:updateButtons()
    local st = ACC.ClientCommands.state.debugState
        or (ACC.ClientCommands.state.snapshot and ACC.ClientCommands.state.snapshot.debug)
        or {}
    for i = 1, #self.buttons do
        local btn = self.buttons[i]
        local on = st[btn.optionKey] == true
        btn:setTitle((on and "[ON] " or "[OFF] ") .. tostring(btn.optionLabel or btn.optionKey))
        Draw.styleButton(btn, on)
    end
end

function CSR_ACC_DebugTab:prerender()
    ISPanel.prerender(self)
    Draw.background(self, 0, 0, self.width, self.height)
    Draw.neonFrame(self, 0, 0, self.width, self.height)
    self:updateButtons()
    local st = ACC.ClientCommands.state.debugState
        or (ACC.ClientCommands.state.snapshot and ACC.ClientCommands.state.snapshot.debug)
        or {}
    local x = 392
    local y = 48
    Draw.section(self, "Debug State", x, y, self.width - x - 18)
    y = y + 30
    Draw.labelValue(self, "Updated by", tostring(st.updatedBy or ""), x + 4, y); y = y + 20
    Draw.labelValue(self, "Updated at", tostring(st.updatedAt or ""), x + 4, y); y = y + 20
    Draw.labelValue(self, "Session started", tostring(st.sessionStartedAt or ""), x + 4, y); y = y + 28

    Draw.section(self, "Log Policy", x, y, self.width - x - 18)
    y = y + 30
    Draw.labelValue(self, "Verbose", Draw.boolText(st.verbose == true), x + 4, y, Draw.boolColor(st.verbose == true)); y = y + 20
    Draw.labelValue(self, "Error only", Draw.boolText(st.errorsOnly == true), x + 4, y, Draw.boolColor(st.errorsOnly == true)); y = y + 20
    Draw.labelValue(self, "Max entries", tostring(ACC.sandbox().DebugLogMaxEntries or 500), x + 4, y)
end

function CSR_ACC_DebugTab:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    return o
end

return CSR_ACC_DebugTab

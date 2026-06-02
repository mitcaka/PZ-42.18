require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "SurvivorCompanions"

SurvivorsCommandWindow = ISCollapsableWindow:derive("SurvivorsCommandWindow")
SurvivorsCommandWindow.instance = SurvivorsCommandWindow.instance or nil

local LOOT_RUN_LABELS = {
    food = "Food",
    medicine = "Medicine",
    ammo = "Ammo",
    tools = "Tools",
    materials = "Materials",
}

local ROLE_ACTIONS = {
    {id="follow", label="Follow", accent="blue"},
    {id="defend", label="Defend", accent="green"},
    {id="work", label="Work", accent="amber"},
    {id="guard", label="Guard", accent="violet"},
}

local LOOT_ACTIONS = {
    {id="loot:food", label="Food"},
    {id="loot:medicine", label="Medicine"},
    {id="loot:ammo", label="Ammo"},
    {id="loot:tools", label="Tools"},
    {id="loot:materials", label="Materials"},
}

local COMPANION_ACTIONS = {
    {id="stay", label="Hold", accent="amber"},
    {id="goto", label="Go To", accent="blue"},
    {id="group", label="Group", accent="violet"},
    {id="combat", label="Combat", accent="green"},
    {id="loadout", label="Loadout", accent="blue"},
    {id="revive", label="Revive", accent="red"},
}

local FALLBACK_COLORS = {
    panelBg = {a=0.84, r=0.07, g=0.08, b=0.10},
    panelHeader = {a=0.92, r=0.12, g=0.14, b=0.18},
    panelBorder = {a=0.95, r=0.29, g=0.35, b=0.42},
    text = {a=1.0, r=0.94, g=0.96, b=0.98},
    muted = {a=1.0, r=0.67, g=0.73, b=0.80},
    blue = {a=1.0, r=0.34, g=0.66, b=0.96},
    green = {a=1.0, r=0.38, g=0.78, b=0.58},
    amber = {a=1.0, r=0.92, g=0.70, b=0.30},
    red = {a=1.0, r=0.86, g=0.36, b=0.36},
    violet = {a=1.0, r=0.72, g=0.58, b=0.94},
}

local function color(name)
    if CSR_Theme and CSR_Theme.getColor then
        local csrName = name
        if name == "muted" then csrName = "textMuted" end
        if name == "blue" then csrName = "accentBlue" end
        if name == "green" then csrName = "accentGreen" end
        if name == "amber" then csrName = "accentAmber" end
        if name == "red" then csrName = "accentRed" end
        if name == "violet" then csrName = "accentViolet" end
        local c = CSR_Theme.getColor(csrName)
        if c then return c end
    end
    return FALLBACK_COLORS[name] or FALLBACK_COLORS.text
end

local function fallbackScale()
    local core = getCore and getCore() or nil
    local screenH = core and core.getScreenHeight and core:getScreenHeight() or 1080
    local tm = getTextManager and getTextManager() or nil
    local fontHgt = tm and tm:getFontHeight(UIFont.Small) or 14

    local resFactor = screenH / 1080
    if resFactor < 0.85 then resFactor = 0.85 end
    if resFactor > 2.0 then resFactor = 2.0 end

    local fontFactor = fontHgt / 14
    if fontFactor < 0.9 then fontFactor = 0.9 end
    if fontFactor > 1.8 then fontFactor = 1.8 end

    return (fontFactor * 0.65) + (resFactor * 0.35)
end

local function scaleFactor()
    if CSR_Scale and CSR_Scale.factor then
        local ok, value = pcall(CSR_Scale.factor)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return fallbackScale()
end

local function px(value)
    if CSR_Scale and CSR_Scale.px then
        local ok, scaled = pcall(CSR_Scale.px, value)
        if ok and tonumber(scaled) then return tonumber(scaled) end
    end
    return math.floor((value or 0) * scaleFactor() + 0.5)
end

local function smallFont()
    if CSR_Scale and CSR_Scale.font then
        local ok, font = pcall(CSR_Scale.font, 14)
        if ok and font then return font end
    end
    return UIFont.Small
end

local function mediumFont()
    if CSR_Scale and CSR_Scale.font then
        local ok, font = pcall(CSR_Scale.font, 17)
        if ok and font then return font end
    end
    return UIFont.Medium
end

local function screenSize()
    local core = getCore and getCore() or nil
    return core and core.getScreenWidth and core:getScreenWidth() or 1280,
        core and core.getScreenHeight and core:getScreenHeight() or 720
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function titleBarHeightSafe(window)
    if window and window.titleBarHeight then
        local ok, height = pcall(window.titleBarHeight, window)
        if ok and tonumber(height) then return tonumber(height) end
    end
    return 16
end

local function getNowHours()
    local gt = getGameTime and getGameTime() or nil
    if gt and gt.getWorldAgeHours then return gt:getWorldAgeHours() end
    return 0
end

local function formatHours(hours)
    hours = math.max(0, tonumber(hours) or 0)
    local wholeHours = math.floor(hours)
    local minutes = math.floor((hours - wholeHours) * 60 + 0.5)
    if wholeHours > 0 then
        return tostring(wholeHours) .. "h " .. tostring(minutes) .. "m"
    end
    return tostring(minutes) .. "m"
end

local function getBrain(zombie)
    if zombie and BanditBrain and BanditBrain.Get then
        return BanditBrain.Get(zombie)
    end
end

local function getProgramName(brain)
    return brain and brain.program and brain.program.name or "Unknown"
end

local function getJobState(job)
    if type(job) ~= "table" then return nil, false, 0, 0 end
    local now = getNowHours()
    local startedAt = tonumber(job.startedAt) or now
    local returnAt = tonumber(job.returnAt) or startedAt
    local duration = math.max(0.01, returnAt - startedAt)
    local progress = clamp((now - startedAt) / duration, 0, 1)
    local completed = job.status == "completed" or now >= returnAt
    return job, completed, progress, math.max(0, returnAt - now)
end

local function applyButtonStyle(button, accentName, active)
    if not button then return end
    local accent = color(accentName or "blue")
    local enabled = button.enable ~= false
    local base = active and {
        r = math.min(1, accent.r * 0.54),
        g = math.min(1, accent.g * 0.54),
        b = math.min(1, accent.b * 0.54),
        a = 1,
    } or {
        r = enabled and 0.18 or 0.10,
        g = enabled and 0.20 or 0.11,
        b = enabled and 0.24 or 0.13,
        a = 1,
    }

    button.backgroundColor = base
    button.backgroundColorMouseOver = {
        r = math.min(1, base.r + 0.08),
        g = math.min(1, base.g + 0.08),
        b = math.min(1, base.b + 0.08),
        a = 1,
    }
    button.borderColor = {
        r = enabled and (active and accent.r or 0.36) or 0.22,
        g = enabled and (active and accent.g or 0.40) or 0.22,
        b = enabled and (active and accent.b or 0.46) or 0.22,
        a = 1,
    }
end

local function measureText(font, text)
    local tm = getTextManager and getTextManager() or nil
    if tm and tm.MeasureStringX then
        return tm:MeasureStringX(font, text or "")
    end
    return string.len(text or "") * 8
end

local function ellipsize(font, text, maxWidth)
    text = tostring(text or "")
    if measureText(font, text) <= maxWidth then return text end
    local suffix = "..."
    local limit = math.max(1, maxWidth - measureText(font, suffix))
    while string.len(text) > 1 and measureText(font, text) > limit do
        text = string.sub(text, 1, string.len(text) - 1)
    end
    return text .. suffix
end

function SurvivorsCommandWindow:new(x, y, width, height, player, zombie)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.zombie = zombie
    o.title = "Survivor Commands"
    o.resizable = false
    o.buttons = {}
    o.roleButtons = {}
    o.companionButtons = {}
    o.lootButtons = {}
    o.lastScale = 0
    return o
end

function SurvivorsCommandWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self:createChildren()
end

function SurvivorsCommandWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    for _, def in ipairs(ROLE_ACTIONS) do
        self:addActionButton(def.id, def.label, def.accent, self.roleButtons)
    end
    for _, def in ipairs(COMPANION_ACTIONS) do
        self:addActionButton(def.id, def.label, def.accent, self.companionButtons)
    end
    for _, def in ipairs(LOOT_ACTIONS) do
        self:addActionButton(def.id, def.label, "blue", self.lootButtons)
    end

    self.collectButton = self:addActionButton("collect", "Collect", "green", self.lootButtons)
    self.leaveButton = self:addActionButton("leave", "Leave", "red", self.buttons)
    self.doneButton = self:addActionButton("close", "Close", "blue", self.buttons)
    self:layout()
end

function SurvivorsCommandWindow:addActionButton(action, label, accent, group)
    local button = ISButton:new(0, 0, 80, 24, label, self, SurvivorsCommandWindow.onButton)
    button.internal = action
    button.accent = accent or "blue"
    button:initialise()
    button:instantiate()
    self:addChild(button)
    table.insert(group, button)
    if group ~= self.buttons then
        table.insert(self.buttons, button)
    end
    return button
end

function SurvivorsCommandWindow:layout()
    local sw, sh = screenSize()
    local width = math.min(math.max(px(390), px(350)), sw - px(24))
    local lineH = math.max(px(18), (getTextManager() and getTextManager():getFontHeight(smallFont()) or 14) + px(4))
    local titleH = titleBarHeightSafe(self)
    local pad = math.max(8, px(12))
    local gap = math.max(4, px(6))
    local btnH = math.max(22, px(24))
    local innerW = width - (pad * 2)
    local rowW4 = math.floor((innerW - (gap * 3)) / 4)
    local rowW3 = math.floor((innerW - (gap * 2)) / 3)
    local y = titleH + pad + (lineH * 8) + px(62)

    for i, button in ipairs(self.roleButtons) do
        button:setX(pad + (i - 1) * (rowW4 + gap))
        button:setY(y)
        button:setWidth(rowW4)
        button:setHeight(btnH)
    end

    y = y + btnH + gap + lineH + px(4)
    for i = 1, 3 do
        local button = self.companionButtons[i]
        button:setX(pad + (i - 1) * (rowW3 + gap))
        button:setY(y)
        button:setWidth(rowW3)
        button:setHeight(btnH)
    end

    y = y + btnH + gap
    for i = 4, 6 do
        local button = self.companionButtons[i]
        button:setX(pad + (i - 4) * (rowW3 + gap))
        button:setY(y)
        button:setWidth(rowW3)
        button:setHeight(btnH)
    end

    y = y + btnH + gap + lineH + px(4)
    for i = 1, 3 do
        local button = self.lootButtons[i]
        button:setX(pad + (i - 1) * (rowW3 + gap))
        button:setY(y)
        button:setWidth(rowW3)
        button:setHeight(btnH)
    end

    y = y + btnH + gap
    for i = 4, 6 do
        local button = self.lootButtons[i]
        button:setX(pad + (i - 4) * (rowW3 + gap))
        button:setY(y)
        button:setWidth(rowW3)
        button:setHeight(btnH)
    end

    y = y + btnH + gap + lineH + px(4)
    local bottomW = math.floor((innerW - gap) / 2)
    self.leaveButton:setX(pad)
    self.leaveButton:setY(y)
    self.leaveButton:setWidth(bottomW)
    self.leaveButton:setHeight(btnH)

    self.doneButton:setX(pad + bottomW + gap)
    self.doneButton:setY(y)
    self.doneButton:setWidth(bottomW)
    self.doneButton:setHeight(btnH)

    local height = math.min(math.max(y + btnH + pad, px(440)), sh - px(24))
    self:setWidth(width)
    self:setHeight(height)
    self:clampToScreen()
    self.lastScale = scaleFactor()
end

function SurvivorsCommandWindow:clampToScreen()
    local sw, sh = screenSize()
    local margin = px(8)
    self:setX(clamp(self:getX(), margin, math.max(margin, sw - self.width - margin)))
    self:setY(clamp(self:getY(), margin, math.max(margin, sh - self.height - margin)))
end

function SurvivorsCommandWindow:refresh()
    local brain = getBrain(self.zombie)
    if not brain then
        for _, button in ipairs(self.buttons) do
            button.enable = false
            applyButtonStyle(button, button.accent, false)
        end
        if self.doneButton then
            self.doneButton.enable = true
            applyButtonStyle(self.doneButton, self.doneButton.accent, false)
        end
        return
    end

    local programName = getProgramName(brain)
    local hasBase = type(brain.survivorBase) == "table"
    local job, completed = getJobState(brain.survivorLootRun)
    local hasActiveJob = job and not completed
    SurvivorCompanions.NormalizeBrain(brain)
    local isCompanion = SurvivorCompanions.IsDirectCompanion(brain)

    for _, button in ipairs(self.roleButtons) do
        button.enable = not hasActiveJob
        local active = (button.internal == "follow" and programName == "Companion")
            or (button.internal == "defend" and programName == "SurvivorBase" and brain.survivorBase and brain.survivorBase.mode == "defend")
            or (button.internal == "work" and programName == "SurvivorBase" and brain.survivorBase and brain.survivorBase.mode == "work")
            or (button.internal == "guard" and programName == "SurvivorBase" and brain.survivorBase and brain.survivorBase.mode == "guard")
        applyButtonStyle(button, button.accent, active)
    end

    for _, button in ipairs(self.companionButtons) do
        button.enable = isCompanion and not hasActiveJob and not brain.companionDowned
        if button.internal == "revive" then
            button.enable = isCompanion and brain.companionDowned
        end
        if button.internal == "group" then
            button:setTitle("Group: " .. tostring(brain.companionGroup))
        elseif button.internal == "combat" then
            button:setTitle("Combat: " .. tostring(brain.companionCombatMode))
        elseif button.internal == "loadout" then
            button:setTitle("Gear: " .. tostring(brain.companionLoadoutMode))
        end
        applyButtonStyle(button, button.accent, false)
    end

    for i = 1, 5 do
        local button = self.lootButtons[i]
        button.enable = hasBase and not job
        applyButtonStyle(button, button.accent, false)
    end

    self.collectButton.enable = completed == true
    applyButtonStyle(self.collectButton, self.collectButton.accent, completed == true)

    self.leaveButton.enable = not hasActiveJob
    applyButtonStyle(self.leaveButton, self.leaveButton.accent, false)
    self.doneButton.enable = true
    applyButtonStyle(self.doneButton, self.doneButton.accent, false)
end

function SurvivorsCommandWindow:prerender()
    if math.abs((self.lastScale or 0) - scaleFactor()) > 0.01 then
        self:layout()
    end

    self:refresh()
    ISCollapsableWindow.prerender(self)

    local bg = color("panelBg")
    local header = color("panelHeader")
    local border = color("panelBorder")
    local text = color("text")
    local muted = color("muted")
    local green = color("green")
    local amber = color("amber")
    local red = color("red")

    local titleH = titleBarHeightSafe(self)
    local pad = math.max(8, px(12))
    local lineH = math.max(px(18), (getTextManager() and getTextManager():getFontHeight(smallFont()) or 14) + px(4))
    local font = smallFont()
    local med = mediumFont()
    local y = titleH

    self:drawRect(0, titleH, self.width, self.height - titleH, bg.a, bg.r, bg.g, bg.b)
    self:drawRect(0, titleH, self.width, px(30), header.a, header.r, header.g, header.b)
    self:drawRectBorder(0, titleH, self.width, self.height - titleH, border.a, border.r, border.g, border.b)

    local brain = getBrain(self.zombie)
    if not brain then
        self:drawText("Survivor unavailable", pad, y + pad, red.r, red.g, red.b, 1, med)
        return
    end

    local name = ellipsize(med, brain.fullname or "Survivor", self.width - (pad * 2))
    self:drawText(name, pad, y + px(7), text.r, text.g, text.b, 1, med)
    y = y + px(36)

    local programName = getProgramName(brain)
    SurvivorCompanions.NormalizeBrain(brain)
    local base = type(brain.survivorBase) == "table" and brain.survivorBase or nil
    local baseText = base and ((base.mode or "defend") .. " at base " .. tostring(base.baseId or "")) or "No base assigned"
    local stateColor = programName == "SurvivorLootRun" and amber or (base and green or muted)

    self:drawText("Status: " .. tostring(programName), pad, y, stateColor.r, stateColor.g, stateColor.b, 1, font)
    y = y + lineH
    local maxHealth = math.max(0.01, tonumber(brain.companionMaxHealth) or tonumber(brain.health) or 1)
    local liveHealth = self.zombie and self.zombie.getHealth and self.zombie:getHealth() or tonumber(brain.health) or 0
    local healthRatio = clamp(liveHealth / maxHealth, 0, 1)
    local hpColor = healthRatio > 0.55 and green or (healthRatio > 0.25 and amber or red)
    self:drawText(string.format("Health: %d%%", math.floor(healthRatio * 100 + 0.5)), pad, y, hpColor.r, hpColor.g, hpColor.b, 1, font)
    local hpBarX = pad + px(92)
    local hpBarW = math.max(px(80), self.width - hpBarX - pad)
    local hpBarH = math.max(5, px(7))
    self:drawRect(hpBarX, y + px(4), hpBarW, hpBarH, 0.45, 0.18, 0.20, 0.24)
    self:drawRect(hpBarX, y + px(4), math.floor(hpBarW * healthRatio), hpBarH, 0.90, hpColor.r, hpColor.g, hpColor.b)
    self:drawRectBorder(hpBarX, y + px(4), hpBarW, hpBarH, 0.60, border.r, border.g, border.b)
    y = y + lineH
    local medical = brain.companionMedical or {}
    local injury = medical.injury and (" - " .. tostring(medical.injury)) or ""
    self:drawText(ellipsize(font, "Medical: " .. tostring(medical.status or "healthy") .. injury, self.width - (pad * 2)), pad, y, brain.companionDowned and red.r or muted.r, brain.companionDowned and red.g or muted.g, brain.companionDowned and red.b or muted.b, 1, font)
    y = y + lineH
    self:drawText("Group: " .. tostring(brain.companionGroup) .. " | Combat: " .. tostring(brain.companionCombatMode) .. " | Gear: " .. tostring(brain.companionLoadoutMode), pad, y, muted.r, muted.g, muted.b, 1, font)
    y = y + lineH
    self:drawText("Gear priorities: balanced=mixed | ranged=guns | melee=close combat", pad, y, muted.r, muted.g, muted.b, 1, font)
    y = y + lineH
    self:drawText("Skills: melee " .. tostring(SurvivorCompanions.GetSkillLevel(brain, "melee")) .. " | firearms " .. tostring(SurvivorCompanions.GetSkillLevel(brain, "firearms")) .. " | survival " .. tostring(SurvivorCompanions.GetSkillLevel(brain, "survival")), pad, y, muted.r, muted.g, muted.b, 1, font)
    y = y + lineH
    self:drawText(ellipsize(font, "Base: " .. baseText, self.width - (pad * 2)), pad, y, muted.r, muted.g, muted.b, 1, font)
    y = y + lineH

    local job, completed, progress, remaining = getJobState(brain.survivorLootRun)
    if job then
        local label = job.categoryLabel or LOOT_RUN_LABELS[job.category] or job.category or "Supplies"
        local jobText = completed and ("Loot Run: " .. tostring(label) .. " ready") or ("Loot Run: " .. tostring(label) .. " " .. formatHours(remaining))
        self:drawText(ellipsize(font, jobText, self.width - (pad * 2)), pad, y, completed and green.r or amber.r, completed and green.g or amber.g, completed and green.b or amber.b, 1, font)
        y = y + lineH

        local barW = self.width - (pad * 2)
        local barH = math.max(6, px(8))
        self:drawRect(pad, y + px(3), barW, barH, 0.45, 0.18, 0.20, 0.24)
        self:drawRect(pad, y + px(3), math.floor(barW * progress), barH, 0.90, completed and green.r or amber.r, completed and green.g or amber.g, completed and green.b or amber.b)
        self:drawRectBorder(pad, y + px(3), barW, barH, 0.60, border.r, border.g, border.b)
    else
        self:drawText("Loot Run: idle", pad, y, muted.r, muted.g, muted.b, 1, font)
    end

    local roleY = self.roleButtons[1] and (self.roleButtons[1]:getY() - lineH - px(4)) or y
    self:drawText("Orders", pad, roleY, text.r, text.g, text.b, 0.92, font)
    local companionY = self.companionButtons[1] and (self.companionButtons[1]:getY() - lineH - px(4)) or roleY
    self:drawText("Companion Controls", pad, companionY, text.r, text.g, text.b, 0.92, font)
    local lootY = self.lootButtons[1] and (self.lootButtons[1]:getY() - lineH - px(4)) or companionY
    self:drawText("Loot Runs", pad, lootY, text.r, text.g, text.b, 0.92, font)
end

function SurvivorsCommandWindow:onButton(button)
    if not button or not button.internal then return end
    local action = button.internal

    if action == "close" then
        self:close()
        return
    end

    if not self.player or not self.zombie then return end

    if action == "follow" then
        BanditMenu.SwitchProgram(self.player, self.zombie, "Companion")
    elseif action == "stay" then
        BanditMenu.SendCompanionOrder(self.player, self.zombie, "stay", self.zombie:getX(), self.zombie:getY(), self.zombie:getZ())
    elseif action == "goto" then
        BanditMenu.BeginCompanionGoTo(self.player, self.zombie)
    elseif action == "group" then
        BanditMenu.CycleCompanionGroup(self.player, self.zombie)
    elseif action == "combat" then
        BanditMenu.CycleCompanionCombatMode(self.player, self.zombie)
    elseif action == "loadout" then
        BanditMenu.CycleCompanionLoadoutMode(self.player, self.zombie)
    elseif action == "revive" then
        BanditMenu.ReviveCompanion(self.player, self.zombie)
    elseif action == "defend" then
        BanditMenu.AssignBaseRole(self.player, self.zombie, "defend")
    elseif action == "work" then
        BanditMenu.AssignBaseRole(self.player, self.zombie, "work")
    elseif action == "guard" then
        BanditMenu.AssignBaseRole(self.player, self.zombie, "guard")
    elseif action == "leave" then
        BanditMenu.SwitchProgram(self.player, self.zombie, "Looter")
        self:close()
    elseif action == "collect" then
        BanditMenu.CollectLootRun(self.player, self.zombie)
    elseif string.sub(action, 1, 5) == "loot:" then
        BanditMenu.StartLootRun(self.player, self.zombie, string.sub(action, 6))
    end

    self:refresh()
end

function SurvivorsCommandWindow:close()
    SurvivorsCommandWindow.instance = nil
    self:removeFromUIManager()
end

function SurvivorsCommandWindow.show(player, zombie)
    if not player or not zombie then return end

    if SurvivorsCommandWindow.instance then
        SurvivorsCommandWindow.instance:removeFromUIManager()
        SurvivorsCommandWindow.instance = nil
    end

    local sw, sh = screenSize()
    local w = math.min(math.max(px(390), px(350)), sw - px(24))
    local h = math.min(math.max(px(310), px(280)), sh - px(24))
    local x = getMouseX and getMouseX() or math.floor((sw - w) / 2)
    local y = getMouseY and getMouseY() or math.floor((sh - h) / 2)
    x = clamp(x, px(8), math.max(px(8), sw - w - px(8)))
    y = clamp(y, px(8), math.max(px(8), sh - h - px(8)))

    local ui = SurvivorsCommandWindow:new(x, y, w, h, player, zombie)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
    SurvivorsCommandWindow.instance = ui
    return ui
end

function SurvivorsCommandWindow.refreshOpen()
    if SurvivorsCommandWindow.instance then
        SurvivorsCommandWindow.instance:refresh()
    end
end

return SurvivorsCommandWindow

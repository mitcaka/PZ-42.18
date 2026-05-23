--[[
    CSR_RankingsUI.lua

    "Server Rankings" client window.

    Tabs (top row of buttons -- avoids ISTabPanel quirks per CSR convention):
        Current Life | Global | Daily | Weekly | Monthly | Trends | Head to Head

    All visuals routed through CSR_Theme so the panel matches the rest of CSR.
    Graphs are hand-drawn with drawRect + drawText only -- no drawLine (which
    does not exist in PZ).
]]

require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "CSR_Theme"
require "CSR_FeatureFlags"
require "CSR_Rankings_Shared"

CSR_RankingsUI = CSR_RankingsUI or {}
local UI = CSR_RankingsUI

UI.window = nil
UI.lastPayload = nil
UI.activeTab = "current"
UI.sortBy = "zombieKills"
UI.sortDir = -1 -- -1 desc, 1 asc
UI.lastRequestMs = 0

local BG_TEXTURE_PATH = "media/ui/CSR_Rankings/csr_server_rankings_bg.png"
local _bgTexture = nil

local function getTextSafe(key, fallback)
    local s = getText(key)
    if s == nil or s == "" or s == key then return fallback or key end
    return s
end

local function getBgTexture()
    if _bgTexture == nil then
        _bgTexture = getTexture(BG_TEXTURE_PATH) or false
    end
    return _bgTexture or nil
end

-- ---------------------------------------------------------------------
-- Drawing helpers
-- ---------------------------------------------------------------------

local function fill(panel, x, y, w, h, color, alpha)
    local a = alpha or color.a or 1.0
    panel:drawRect(x, y, w, h, a, color.r, color.g, color.b)
end

local function drawText(panel, text, x, y, color, alpha, font)
    local f = font or UIFont.Small
    local a = alpha or color.a or 1.0
    panel:drawText(text or "", x, y, color.r, color.g, color.b, a, f)
end

local function drawTextRight(panel, text, rightX, y, color, alpha, font)
    local f = font or UIFont.Small
    local tm = getTextManager()
    local w = tm:MeasureStringX(f, text or "")
    drawText(panel, text, rightX - w, y, color, alpha, f)
end

-- ---------------------------------------------------------------------
-- Network
-- ---------------------------------------------------------------------

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    return os and os.time and os.time() * 1000 or 0
end

function UI.requestRefresh(focus)
    if not isClient() then
        UI.lastPayload = { rows = {}, schema = CSR_Rankings.SCHEMA_VERSION,
                           updatedAt = "(SP -- no rankings server)", local_only = true }
        return
    end
    local now = nowMs()
    if (now - UI.lastRequestMs) < 5000 then return end
    UI.lastRequestMs = now
    local p = getPlayer()
    if not p then return end
    sendClientCommand(p, "CommonSenseReborn", CSR_Rankings.CMD_REQUEST, {
        focus = focus or (p:getUsername() and tostring(p:getUsername()) or ""),
    })
end

local function onServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    if command ~= CSR_Rankings.CMD_PUSH then return end
    UI.lastPayload = args or {}
    if UI.window and UI.window.refresh then UI.window:refresh() end
end

-- ---------------------------------------------------------------------
-- Sorting / window-stat extraction per tab
-- ---------------------------------------------------------------------

local function getRowStats(row, tabKey)
    if not row then return { kills = 0, deaths = 0, hours = 0, dist = 0, xp = 0 } end
    if tabKey == "daily"   and row.daily   then
        local b = row.daily
        return { kills = b.z, deaths = b.d, hours = b.h, dist = b.dist, xp = b.xp, pvp = b.p }
    end
    if tabKey == "weekly"  and row.weekly  then
        local b = row.weekly
        return { kills = b.z, deaths = b.d, hours = b.h, dist = b.dist, xp = b.xp, pvp = b.p }
    end
    if tabKey == "monthly" and row.monthly then
        local b = row.monthly
        return { kills = b.z, deaths = b.d, hours = b.h, dist = b.dist, xp = b.xp, pvp = b.p }
    end
    -- "current" and "global": both use lifetime totals (current-life isolation
    -- would require client-side filtering of in-progress life; we approximate
    -- "current" as today's bucket since live counters reset on death).
    if tabKey == "current" and row.daily then
        local b = row.daily
        return { kills = b.z, deaths = b.d, hours = b.h, dist = b.dist, xp = b.xp, pvp = b.p }
    end
    return {
        kills = row.zombieKills or 0,
        deaths = row.deaths or 0,
        hours = row.hoursSurvived or 0,
        dist = row.distanceWalked or 0,
        xp = row.xpGained or 0,
        pvp = row.playerKills or 0,
    }
end

local SORT_FIELDS = {
    zombieKills = function(row, tab) return getRowStats(row, tab).kills end,
    deaths      = function(row, tab) return getRowStats(row, tab).deaths end,
    kd          = function(row, tab)
        local s = getRowStats(row, tab)
        return CSR_Rankings.kdRatio(s.kills, s.deaths)
    end,
    hours       = function(row, tab) return getRowStats(row, tab).hours end,
    distance    = function(row, tab) return getRowStats(row, tab).dist end,
    xp          = function(row, tab) return getRowStats(row, tab).xp end,
    streak      = function(row)      return row.bestStreak or 0 end,
    longestLife = function(row)      return row.longestLifeHours or 0 end,
}

local function sortedRows(rows, tab, sortBy, dir)
    local cmp = SORT_FIELDS[sortBy] or SORT_FIELDS.zombieKills
    local copy = {}
    for i = 1, #(rows or {}) do copy[i] = rows[i] end
    table.sort(copy, function(a, b)
        local av = cmp(a, tab) or 0
        local bv = cmp(b, tab) or 0
        if av == bv then return (a.username or "") < (b.username or "") end
        if (dir or -1) < 0 then return av > bv end
        return av < bv
    end)
    return copy
end

-- ---------------------------------------------------------------------
-- Window class
-- ---------------------------------------------------------------------

local Win = ISCollapsableWindow:derive("CSR_RankingsWindow")
UI.Win = Win

local TAB_KEYS  = { "current", "global", "daily", "weekly", "monthly", "trends", "h2h" }
local TAB_LABEL_KEYS = {
    current = "IGUI_CSR_Rankings_Tab_Current",
    global  = "IGUI_CSR_Rankings_Tab_Global",
    daily   = "IGUI_CSR_Rankings_Tab_Daily",
    weekly  = "IGUI_CSR_Rankings_Tab_Weekly",
    monthly = "IGUI_CSR_Rankings_Tab_Monthly",
    trends  = "IGUI_CSR_Rankings_Tab_Trends",
    h2h     = "IGUI_CSR_Rankings_Tab_H2H",
}

local COLS = {
    { key = "rank",     labelKey = "IGUI_CSR_Rankings_Col_Rank",     width = 36,  sortBy = nil },
    { key = "name",     labelKey = "IGUI_CSR_Rankings_Col_Name",     width = 140, sortBy = nil },
    { key = "faction",  labelKey = "IGUI_CSR_Rankings_Col_Faction",  width = 90,  sortBy = nil },
    { key = "kills",    labelKey = "IGUI_CSR_Rankings_Col_Kills",    width = 70,  sortBy = "zombieKills" },
    { key = "pvp",      labelKey = "IGUI_CSR_Rankings_Col_PvP",      width = 50,  sortBy = nil },
    { key = "deaths",   labelKey = "IGUI_CSR_Rankings_Col_Deaths",   width = 60,  sortBy = "deaths" },
    { key = "kd",       labelKey = "IGUI_CSR_Rankings_Col_KD",       width = 60,  sortBy = "kd" },
    { key = "hours",    labelKey = "IGUI_CSR_Rankings_Col_Hours",    width = 70,  sortBy = "hours" },
    { key = "dist",     labelKey = "IGUI_CSR_Rankings_Col_Distance", width = 80,  sortBy = "distance" },
    { key = "xp",       labelKey = "IGUI_CSR_Rankings_Col_XP",       width = 70,  sortBy = "xp" },
    { key = "streak",   labelKey = "IGUI_CSR_Rankings_Col_Streak",   width = 60,  sortBy = "streak" },
}

function Win:initialise()
    ISCollapsableWindow.initialise(self)
end

function Win:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()

    -- Tab buttons row
    local tabY = th + 6
    local tabH = 22
    self.tabButtons = {}
    local tx = 8
    for _, key in ipairs(TAB_KEYS) do
        local label = getTextSafe(TAB_LABEL_KEYS[key], key)
        local btn = ISButton:new(tx, tabY, 86, tabH, label, self,
            function(_, _, k) UI.activeTab = k; self:refresh() end)
        btn.internal = key
        btn.onclickArg = key
        btn:initialise()
        btn:setOnClick(function() UI.activeTab = key; self:refresh() end)
        btn.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.8 }
        self:addChild(btn)
        self.tabButtons[key] = btn
        tx = tx + btn.width + 4
    end

    -- Refresh button (top right, before close)
    local refresh = ISButton:new(self.width - 92, tabY, 80, tabH,
        getTextSafe("IGUI_CSR_Rankings_Refresh", "Refresh"), self,
        function() UI.requestRefresh() end)
    refresh:initialise()
    refresh:setOnClick(function() UI.requestRefresh() end)
    refresh.anchorRight = true
    self:addChild(refresh)
    self.refreshBtn = refresh

    -- Head-to-head text inputs (only created once; toggled visible).
    -- Default text MUST be passed via the constructor -- calling :setText()
    -- before addChild()/instantiate() crashes because self.javaObject is nil
    -- (the Java UITextBox2 is only created during addChild()->instantiate()).
    -- This was the v1.8.16 crash at line 229.
    local h2hY = tabY + tabH + 8
    local meName = getPlayer() and tostring(getPlayer():getUsername() or "") or ""
    self.h2hLabelA = ISTextEntryBox:new(meName, 8, h2hY, 160, 22)
    self.h2hLabelA:initialise()
    self:addChild(self.h2hLabelA)

    self.h2hLabelB = ISTextEntryBox:new("", 180, h2hY, 160, 22)
    self.h2hLabelB:initialise()
    self:addChild(self.h2hLabelB)

    self.h2hCompareBtn = ISButton:new(348, h2hY, 80, 22,
        getTextSafe("IGUI_CSR_Rankings_H2H_Compare", "Compare"), self,
        function() self:refresh() end)
    self.h2hCompareBtn:initialise()
    self.h2hCompareBtn:setOnClick(function() self:refresh() end)
    self:addChild(self.h2hCompareBtn)

    self:applyTabVisibility()
end

function Win:applyTabVisibility()
    local h2h = (UI.activeTab == "h2h")
    if self.h2hLabelA   then self.h2hLabelA:setVisible(h2h) end
    if self.h2hLabelB   then self.h2hLabelB:setVisible(h2h) end
    if self.h2hCompareBtn then self.h2hCompareBtn:setVisible(h2h) end
end

function Win:refresh()
    self:applyTabVisibility()
    if not UI.lastPayload then UI.requestRefresh() end
end

-- ---------------------------------------------------------------------
-- Header column hit detection (sort on click)
-- ---------------------------------------------------------------------

function Win:headerStartY()
    return self:titleBarHeight() + 6 + 22 + 8 + (UI.activeTab == "h2h" and 28 or 0)
end

function Win:bodyStartY()
    return self:headerStartY() + 22
end

function Win:onMouseDown(x, y)
    if UI.activeTab == "trends" or UI.activeTab == "h2h" then
        return ISCollapsableWindow.onMouseDown(self, x, y)
    end
    local hy = self:headerStartY()
    if y >= hy and y < hy + 22 then
        local cx = 8
        for _, col in ipairs(COLS) do
            if col.sortBy and x >= cx and x < cx + col.width then
                if UI.sortBy == col.sortBy then
                    UI.sortDir = -UI.sortDir
                else
                    UI.sortBy = col.sortBy
                    UI.sortDir = -1
                end
                return ISCollapsableWindow.onMouseDown(self, x, y)
            end
            cx = cx + col.width
        end
    end
    -- Row pin: clicking a body row stores it as h2h player B
    local by = self:bodyStartY()
    local rowH = 18
    if y >= by then
        local idx = math.floor((y - by) / rowH) + 1
        local rows = sortedRows((UI.lastPayload and UI.lastPayload.rows) or {},
                                UI.activeTab, UI.sortBy, UI.sortDir)
        if rows[idx] and self.h2hLabelB then
            self.h2hLabelB:setText(rows[idx].username or "")
        end
    end
    return ISCollapsableWindow.onMouseDown(self, x, y)
end

-- ---------------------------------------------------------------------
-- Render dispatch
-- ---------------------------------------------------------------------

function Win:prerender()
    ISCollapsableWindow.prerender(self)
    -- Re-anchor refresh button on resize
    if self.refreshBtn then
        self.refreshBtn:setX(self.width - self.refreshBtn.width - 12)
    end
end

function Win:render()
    -- ISCollapsableWindow draws its own background; we just paint our content
    -- area with the CSR theme colors on top.
    local headerH = self:titleBarHeight()
    local bg     = CSR_Theme.getColor("panelBg")
    local outline = CSR_Theme.getColor("accentViolet") or CSR_Theme.getColor("panelBorder")
    local text   = CSR_Theme.getColor("text")
    local muted  = CSR_Theme.getColor("textMuted")

    -- Re-tint background to our panelBg (kept transparent enough to not fight
    -- vanilla collapsable chrome).
    fill(self, 1, headerH, self.width - 2, self.height - headerH - 2, bg, 0.85)
    self:drawRectBorder(0, 0, self.width, self.height,
        outline.a, outline.r, outline.g, outline.b)
    self:drawRectBorder(1, 1, self.width - 2, self.height - 2,
        0.45, outline.r, outline.g, outline.b)

    local bgTex = getBgTexture()
    if bgTex then
        local maxW = self.width - 32
        local maxH = self.height - headerH - 32
        local tw = bgTex.getWidth and bgTex:getWidth() or maxW
        local th = bgTex.getHeight and bgTex:getHeight() or maxH
        if tonumber(tw) and tonumber(th) and tonumber(tw) > 0 and tonumber(th) > 0 then
            local scale = math.min(maxW / tonumber(tw), maxH / tonumber(th))
            if scale > 1 then scale = 1 end
            local drawW = math.floor(tonumber(tw) * scale)
            local drawH = math.floor(tonumber(th) * scale)
            local drawX = math.floor((self.width - drawW) / 2)
            local drawY = headerH + 16 + math.floor((maxH - drawH) / 2)
            self:drawTextureScaled(bgTex, drawX, drawY, drawW, drawH, 0.12,
                outline.r, outline.g, outline.b)
        end
    end

    -- Status line
    local payload = UI.lastPayload
    local stamp = payload and payload.updatedAt or "(no data yet)"
    drawText(self, "Updated: " .. tostring(stamp),
             self.width - 240, headerH + 4, muted, 0.8, UIFont.Small)

    -- Highlight active tab
    for key, btn in pairs(self.tabButtons or {}) do
        if key == UI.activeTab then
            self:drawRectBorder(btn.x - 2, btn.y - 2, btn.width + 4, btn.height + 4,
                1.0, 0.34, 0.66, 0.96) -- accentBlue
        end
    end

    if payload and payload.denied then
        drawText(self, getTextSafe("IGUI_CSR_Rankings_AdminOnly",
            "Rankings are admin-only on this server."),
            16, headerH + 36, CSR_Theme.getColor("accentRed"), 1.0, UIFont.Medium)
        return
    end

    local rows = (payload and payload.rows) or {}
    if #rows == 0 then
        drawText(self, getTextSafe("IGUI_CSR_Rankings_Empty",
            "No rankings recorded yet."),
            16, headerH + 36, muted, 1.0, UIFont.Medium)
        return
    end

    if UI.activeTab == "trends" then
        self:renderTrends(rows)
    elseif UI.activeTab == "h2h" then
        self:renderHeadToHead(rows)
    else
        self:renderLeaderboard(rows)
    end
end

-- ---------------------------------------------------------------------
-- Leaderboard (Current / Global / Daily / Weekly / Monthly)
-- ---------------------------------------------------------------------

function Win:renderLeaderboard(rows)
    local text   = CSR_Theme.getColor("text")
    local muted  = CSR_Theme.getColor("textMuted")
    local amber  = CSR_Theme.getColor("accentAmber")
    local green  = CSR_Theme.getColor("accentGreen")
    local red    = CSR_Theme.getColor("accentRed")
    local blue   = CSR_Theme.getColor("accentBlue")
    local header = CSR_Theme.getColor("panelHeader")

    -- Column header strip
    local hy = self:headerStartY()
    fill(self, 4, hy, self.width - 8, 22, header, 0.96)
    local cx = 8
    for _, col in ipairs(COLS) do
        local label = getTextSafe(col.labelKey, col.key)
        local arrow = ""
        if col.sortBy and UI.sortBy == col.sortBy then
            arrow = (UI.sortDir < 0) and " v" or " ^"
        end
        local color = col.sortBy and UI.sortBy == col.sortBy and blue or text
        drawText(self, label .. arrow, cx + 4, hy + 3, color, 0.95, UIFont.Small)
        cx = cx + col.width
    end

    local sorted = sortedRows(rows, UI.activeTab, UI.sortBy, UI.sortDir)
    local meName = getPlayer() and tostring(getPlayer():getUsername() or "") or ""

    local by = self:bodyStartY()
    local rowH = 18
    local maxRows = math.floor((self.height - by - 8) / rowH)
    if maxRows > #sorted then maxRows = #sorted end

    for i = 1, maxRows do
        local row = sorted[i]
        local s = getRowStats(row, UI.activeTab)
        local rankColor = text
        local rowAlpha = 0.05
        if i == 1 then rankColor = amber; rowAlpha = 0.18 end
        if i == 2 then rankColor = muted; rowAlpha = 0.14 end
        if i == 3 then rankColor = red;   rowAlpha = 0.10 end

        local y = by + (i - 1) * rowH
        if (i % 2) == 0 then
            fill(self, 4, y, self.width - 8, rowH,
                 CSR_Theme.getColor("panelHeader"), 0.18)
        end

        -- Self row outline
        if row.username == meName then
            self:drawRectBorder(4, y, self.width - 8, rowH,
                blue.a, blue.r, blue.g, blue.b)
        end

        -- Cells
        local cx2 = 8
        local cells = {
            tostring(i),
            row.username or "?",
            row.faction or "",
            CSR_Rankings.formatCompact(s.kills),
            CSR_Rankings.formatCompact(s.pvp or 0),
            CSR_Rankings.formatCompact(s.deaths),
            CSR_Rankings.formatKD(s.kills, s.deaths),
            CSR_Rankings.formatHours(s.hours),
            CSR_Rankings.formatDistance(s.dist),
            CSR_Rankings.formatCompact(s.xp),
            CSR_Rankings.formatCompact(row.bestStreak or 0),
        }
        for ci, col in ipairs(COLS) do
            local txt = cells[ci] or ""
            local color = (ci == 1) and rankColor or text
            drawText(self, txt, cx2 + 4, y + 2, color, 0.95, UIFont.Small)
            cx2 = cx2 + col.width
        end
    end
end

-- ---------------------------------------------------------------------
-- Trends (graphs)
-- ---------------------------------------------------------------------

function Win:renderTrends(rows)
    local text = CSR_Theme.getColor("text")
    local muted = CSR_Theme.getColor("textMuted")
    local green = CSR_Theme.getColor("accentGreen")
    local blue  = CSR_Theme.getColor("accentBlue")
    local header = CSR_Theme.getColor("panelHeader")

    local hy = self:headerStartY()
    drawText(self, getTextSafe("IGUI_CSR_Rankings_Trends_Top5", "Top 5 Zombie Killers"),
             16, hy, text, 1.0, UIFont.Medium)

    -- Top-5 horizontal bars by lifetime zombie kills
    local sorted = sortedRows(rows, "global", "zombieKills", -1)
    local top = {}
    for i = 1, math.min(5, #sorted) do top[i] = sorted[i] end
    local maxKills = 1
    for i = 1, #top do maxKills = math.max(maxKills, top[i].zombieKills or 0) end

    local barAreaX = 16
    local barAreaY = hy + 22
    local barAreaW = self.width - 32
    local rowH = 28
    for i = 1, #top do
        local r = top[i]
        local y = barAreaY + (i - 1) * rowH
        -- Name
        drawText(self, string.format("#%d  %s", i, r.username or "?"),
                 barAreaX, y, text, 0.95, UIFont.Small)
        -- Bar background
        fill(self, barAreaX + 140, y + 2, barAreaW - 220, 18, header, 0.4)
        local ratio = (r.zombieKills or 0) / maxKills
        local fillW = math.max(2, math.floor((barAreaW - 220) * ratio))
        fill(self, barAreaX + 140, y + 2, fillW, 18, green, 0.85)
        -- Number at end
        drawText(self, CSR_Rankings.formatCompact(r.zombieKills or 0),
                 barAreaX + barAreaW - 70, y + 2, text, 1.0, UIFont.Small)
    end

    -- Daily timeline for self (or top1 if no self row)
    local meName = getPlayer() and tostring(getPlayer():getUsername() or "") or ""
    local focus = nil
    for i = 1, #rows do
        if rows[i].username == meName then focus = rows[i]; break end
    end
    if not focus then focus = top[1] end

    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    local buckets = math.max(5, math.floor(tonumber(sb.RankingsHistoryGraphBuckets or 14) or 14))
    local timelineY = barAreaY + #top * rowH + 28
    local timelineLabel = getTextSafe("IGUI_CSR_Rankings_Trends_Timeline",
        "Daily Kills (last %1 days)")
    timelineLabel = (timelineLabel:gsub("%%1", tostring(buckets)))
    drawText(self, timelineLabel, 16, timelineY, text, 1.0, UIFont.Medium)

    if not focus or not focus.history then
        drawText(self, getTextSafe("IGUI_CSR_Rankings_H2H_NoData",
            "No data on file for this player."),
            16, timelineY + 22, muted, 0.9, UIFont.Small)
        return
    end

    -- Build the last N days array (oldest -> newest)
    local series = {}
    local maxV = 1
    for i = buckets - 1, 0, -1 do
        local dk = CSR_Rankings.shiftDateKey(CSR_Rankings.todayKey(), -i)
        local v = (focus.history[dk] and focus.history[dk].z) or 0
        table.insert(series, { dateKey = dk, value = v })
        if v > maxV then maxV = v end
    end

    local chartX = 16
    local chartY = timelineY + 22
    local chartW = self.width - 32
    local chartH = self.height - chartY - 24
    if chartH < 60 then chartH = 60 end

    -- Frame + 4 horizontal grid lines (drawn as thin rects)
    fill(self, chartX, chartY, chartW, chartH, header, 0.35)
    self:drawRectBorder(chartX, chartY, chartW, chartH,
        muted.a, muted.r, muted.g, muted.b)
    for g = 1, 3 do
        local gy = chartY + math.floor(chartH * g / 4)
        fill(self, chartX + 1, gy, chartW - 2, 1, muted, 0.25)
    end

    local n = #series
    if n == 0 then return end
    local barW = math.max(2, math.floor((chartW - 16) / n) - 2)
    for i = 1, n do
        local entry = series[i]
        local h = math.floor((chartH - 18) * (entry.value / maxV))
        local bx = chartX + 8 + (i - 1) * (barW + 2)
        local by = chartY + chartH - 4 - h
        fill(self, bx, by, barW, h, blue, 0.85)
        if (i == 1) or (i == n) or (i == math.floor(n / 2) + 1) then
            local short = string.sub(entry.dateKey, 6) -- MM-DD
            drawText(self, short, bx, chartY + chartH + 2, muted, 0.85, UIFont.Small)
        end
    end
end

-- ---------------------------------------------------------------------
-- Head-to-Head
-- ---------------------------------------------------------------------

local function findRow(rows, name)
    if not name or name == "" then return nil end
    local lower = string.lower(name)
    for i = 1, #rows do
        if string.lower(rows[i].username or "") == lower then return rows[i] end
    end
    return nil
end

function Win:renderHeadToHead(rows)
    local text  = CSR_Theme.getColor("text")
    local muted = CSR_Theme.getColor("textMuted")
    local green = CSR_Theme.getColor("accentGreen")
    local blue  = CSR_Theme.getColor("accentBlue")
    local red   = CSR_Theme.getColor("accentRed")
    local header= CSR_Theme.getColor("panelHeader")

    local hy = self:headerStartY()
    local nameA = self.h2hLabelA and self.h2hLabelA:getInternalText() or ""
    local nameB = self.h2hLabelB and self.h2hLabelB:getInternalText() or ""
    local rowA = findRow(rows, nameA)
    local rowB = findRow(rows, nameB)

    -- Headers
    drawText(self, nameA ~= "" and nameA or getTextSafe("IGUI_CSR_Rankings_H2H_PlayerA", "Player A"),
             16, hy, blue, 1.0, UIFont.Medium)
    drawTextRight(self, nameB ~= "" and nameB or getTextSafe("IGUI_CSR_Rankings_H2H_PlayerB", "Player B"),
             self.width - 16, hy, red, 1.0, UIFont.Medium)
    drawText(self, getText("IGUI_CSR_Rankings_VS"),
             math.floor(self.width / 2) - 8, hy, text, 0.9, UIFont.Medium)

    if not rowA and not rowB then
        drawText(self, getTextSafe("IGUI_CSR_Rankings_H2H_NoData",
            "No data on file for this player."),
            16, hy + 28, muted, 0.95, UIFont.Small)
        return
    end

    local metrics = {
        { label = "Z Kills",  fa = function(r) return r.zombieKills or 0 end, fmt = CSR_Rankings.formatCompact },
        { label = "PvP",      fa = function(r) return r.playerKills or 0 end, fmt = CSR_Rankings.formatCompact },
        { label = "Deaths",   fa = function(r) return r.deaths or 0 end,      fmt = CSR_Rankings.formatCompact, lowerWins = true },
        { label = "K/D",      fa = function(r) return CSR_Rankings.kdRatio(r.zombieKills or 0, r.deaths or 0) end,
                              fmt = function(v) return string.format("%.2f", v) end },
        { label = "Hours",    fa = function(r) return r.hoursSurvived or 0 end, fmt = CSR_Rankings.formatHours },
        { label = "Longest Life", fa = function(r) return r.longestLifeHours or 0 end, fmt = CSR_Rankings.formatHours },
        { label = "Distance", fa = function(r) return r.distanceWalked or 0 end, fmt = CSR_Rankings.formatDistance },
        { label = "XP",       fa = function(r) return r.xpGained or 0 end,    fmt = CSR_Rankings.formatCompact },
        { label = "Best Streak", fa = function(r) return r.bestStreak or 0 end, fmt = CSR_Rankings.formatCompact },
    }

    local rowY = hy + 28
    local rowH = 26
    local midX = math.floor(self.width / 2)

    for i, m in ipairs(metrics) do
        local y = rowY + (i - 1) * rowH
        if (i % 2) == 0 then
            fill(self, 8, y, self.width - 16, rowH, header, 0.18)
        end
        local va = rowA and m.fa(rowA) or 0
        local vb = rowB and m.fa(rowB) or 0
        local aWins, bWins = false, false
        if m.lowerWins then
            if va < vb and rowA then aWins = true elseif vb < va and rowB then bWins = true end
        else
            if va > vb and rowA then aWins = true elseif vb > va and rowB then bWins = true end
        end
        local colorA = aWins and green or muted
        local colorB = bWins and green or muted
        drawText(self, rowA and m.fmt(va) or "-", 16, y + 4, colorA, 1.0, UIFont.Medium)
        drawText(self, m.label, midX - 50, y + 4, text, 0.9, UIFont.Small)
        drawTextRight(self, rowB and m.fmt(vb) or "-", self.width - 16, y + 4, colorB, 1.0, UIFont.Medium)

        -- Mini bar comparison
        local barY = y + rowH - 6
        local maxVal = math.max(va, vb, 1)
        local halfW = midX - 80
        if rowA then
            local lenA = math.max(2, math.floor(halfW * (va / maxVal)))
            fill(self, midX - 60 - lenA, barY, lenA, 4, blue, 0.85)
        end
        if rowB then
            local lenB = math.max(2, math.floor(halfW * (vb / maxVal)))
            fill(self, midX + 60, barY, lenB, 4, red, 0.85)
        end
    end
end

-- ---------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------

function UI.toggle()
    if not CSR_FeatureFlags.isRankingsEnabled() then return end
    if UI.window and UI.window:getIsVisible() then
        UI.window:setVisible(false)
        UI.window:removeFromUIManager()
        UI.window = nil
        return
    end
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local w = math.min(960, screenW - 80)
    local h = math.min(620, screenH - 100)
    local x = math.floor((screenW - w) / 2)
    local y = math.floor((screenH - h) / 2)
    UI.window = Win:new(x, y, w, h)
    UI.window:initialise()
    UI.window:instantiate()
    UI.window:setTitle(getTextSafe("IGUI_CSR_Rankings_Title", "Server Rankings"))
    UI.window:addToUIManager()
    UI.window:setVisible(true)
    UI.requestRefresh()
end

if Events and not CSR_RankingsUI._registered then
    CSR_RankingsUI._registered = true
    if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
end

return CSR_RankingsUI

--[[
    CSR_AdminSandboxDoc.lua

    Admin-only sandbox variable reference panel.

    Lists every CSR sandbox variable with its current effective value plus
    the in-game tooltip text, so server admins can verify what each option
    is set to without leaving the game or scraping config files.

    Triggered from the "Admin" button on the Utility HUD (visible only when
    the local player has Admin / Moderator / GM / Overseer access).
    Read-only -- this panel does not write any sandbox value.
]]

require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"

CSR_AdminSandboxDoc = CSR_AdminSandboxDoc or {}
local UI = CSR_AdminSandboxDoc

local Win = ISCollapsableWindow:derive("CSR_AdminSandboxDocWindow")
UI.Win = Win

local PANEL_W = 720
local PANEL_H = 560
local ROW_H   = 36

-- Cached list of {key, label, value, tooltip}; built lazily on first open.
local cachedRows = nil

local function safeGetText(key, fallback)
    local ok, v = pcall(getText, key)
    if ok and v and v ~= "" and v:sub(1, 9) ~= "IGUI_Sand" and v:sub(1, 8) ~= "Sandbox_" then
        return v
    end
    return fallback or key
end

local function valueAsString(v)
    if v == nil then return "<nil>" end
    if type(v) == "boolean" then return v and "true" or "false" end
    if type(v) == "number"  then
        if v == math.floor(v) then return tostring(math.floor(v)) end
        return string.format("%.3f", v)
    end
    return tostring(v)
end

-- Walk SandboxVars.CommonSenseReborn and produce an alphabetically sorted
-- list of {key, label, valueText, tooltip} rows.  Skips internal/derived
-- entries (those starting with `_`).
local function buildRows()
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or nil
    if not sb then return {} end
    local rows = {}
    for k, v in pairs(sb) do
        if type(k) == "string" and k:sub(1, 1) ~= "_" and type(v) ~= "function" then
            local labelKey   = "Sandbox_" .. k
            local tooltipKey = "Sandbox_" .. k .. "_tooltip"
            local label   = safeGetText(labelKey, k)
            local tooltip = safeGetText(tooltipKey, "(no tooltip provided)")
            table.insert(rows, {
                key      = k,
                label    = label,
                value    = valueAsString(v),
                tooltip  = tooltip,
            })
        end
    end
    table.sort(rows, function(a, b) return a.key < b.key end)
    return rows
end

function Win:new(x, y, w, h)
    local o = ISCollapsableWindow:new(x, y, w, h)
    setmetatable(o, self); self.__index = self
    o:setResizable(true)
    o.title = "CSR Admin: Sandbox Variable Reference"
    o.minimumWidth  = 480
    o.minimumHeight = 360
    o.filterText = ""
    return o
end

function Win:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th  = self:titleBarHeight()
    local pad = 8
    local btnH = 22

    -- Filter input
    self.filterEntry = ISTextEntryBox:new("", pad, th + pad, self.width - pad * 2 - 80 - 6, btnH)
    self.filterEntry:initialise(); self.filterEntry:instantiate()
    self.filterEntry:setText("")
    self.filterEntry.onTextChange = function() Win.onFilterChange(self) end
    self:addChild(self.filterEntry)

    self.refreshBtn = ISButton:new(self.width - pad - 80, th + pad, 80, btnH,
        "Refresh", self, Win.onRefresh)
    self.refreshBtn:initialise(); self.refreshBtn:instantiate()
    self.refreshBtn:setTooltip("Re-read SandboxVars.CommonSenseReborn from the running session.")
    self:addChild(self.refreshBtn)

    -- Hint label
    self.hint = ISLabel:new(pad, th + pad + btnH + 4, 16,
        "Type to filter by variable name. Hover any row for the tooltip.",
        0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.hint:initialise(); self.hint:instantiate()
    self:addChild(self.hint)

    -- Scrolling list
    local listY = th + pad + btnH + 4 + 18
    self.list = ISScrollingListBox:new(pad, listY,
        self.width - pad * 2, self.height - listY - pad)
    self.list:initialise(); self.list:instantiate()
    self.list.itemheight = ROW_H
    self.list.selected = 0
    self.list.joypadParent = self
    self.list.font = UIFont.Small
    self.list.doDrawItem = Win.drawListItem
    self.list.drawBorder = true
    self.list:setOnMouseDownFunction(self, Win.onListMouseDown)
    self:addChild(self.list)

    self:rebuild()
end

function Win:onFilterChange()
    self.filterText = string.lower(self.filterEntry and self.filterEntry:getText() or "")
    self:rebuild()
end

function Win:onRefresh()
    cachedRows = nil
    if self.filterEntry then self.filterEntry:setText("") end
    self.filterText = ""
    self:rebuild()
end

function Win:rebuild()
    if not cachedRows then cachedRows = buildRows() end
    self.list:clear()
    local f = self.filterText or ""
    for _, row in ipairs(cachedRows) do
        if f == "" or string.find(string.lower(row.key), f, 1, true) then
            self.list:addItem(row.key, row)
        end
    end
end

function Win.drawListItem(self, y, item, alt)
    local row = item.item
    if not row then return y + self.itemheight end

    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15)
    elseif alt then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.3, 0.06, 0.06, 0.06)
    end

    self:drawText(row.key,   8,  y + 2,  1, 1, 1, 1, UIFont.Small)
    self:drawText("= " .. row.value, 280, y + 2, 0.6, 1, 0.7, 1, UIFont.Small)
    -- Truncate label/tooltip to one line each
    local label = row.label or ""
    if #label > 80 then label = string.sub(label, 1, 77) .. "..." end
    self:drawText(label, 8, y + 18, 0.85, 0.85, 0.85, 1, UIFont.Small)
    return y + self.itemheight
end

function Win.onListMouseDown(self, x, y, item)
    -- Show tooltip text via halo note for the row clicked.
    if not item or not item.tooltip then return end
    if MainScreen and MainScreen.instance then
        -- nothing; tooltip will be rendered via prerender below
    end
    self.parent.selectedTooltip = item.tooltip
end

function Win:prerender()
    ISCollapsableWindow.prerender(self)
    -- Bottom hint: show selected tooltip if any, wrapped to ~3 lines.
    if self.list and self.list.selected and self.list.items and self.list.items[self.list.selected] then
        local row = self.list.items[self.list.selected].item
        if row and row.tooltip then
            local t = row.tooltip
            -- crude word-wrap: split at every ~90 chars on a space
            local out, line = {}, ""
            for word in string.gmatch(t, "%S+") do
                if #line + #word + 1 > 90 then
                    table.insert(out, line); line = word
                else
                    line = (line == "") and word or (line .. " " .. word)
                end
            end
            if line ~= "" then table.insert(out, line) end
            for i = 1, math.min(3, #out) do
                self:drawText(out[i], 8, self.height - 18 * (4 - i),
                    0.75, 0.85, 0.95, 1, UIFont.Small)
            end
        end
    end
end

function Win:onClose()
    self:setVisible(false)
end

-- Public API ---------------------------------------------------------------

function UI.isLocalAdmin()
    local plr = getPlayer()
    if not plr then return false end
    if not isClient() then return true end -- SP / host: always show
    local lvl = plr.getAccessLevel and tostring(plr:getAccessLevel() or "") or ""
    return (lvl == "Admin" or lvl == "Moderator" or lvl == "GM" or lvl == "Overseer")
end

function UI.toggle()
    if not UI.isLocalAdmin() then return end
    if UI._win and UI._win:isVisible() then
        UI._win:setVisible(false)
        UI._win:removeFromUIManager()
        UI._win = nil
        return
    end
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local x = math.floor((sw - PANEL_W) / 2)
    local y = math.floor((sh - PANEL_H) / 2)
    UI._win = Win:new(x, y, PANEL_W, PANEL_H)
    UI._win:initialise(); UI._win:instantiate()
    UI._win:addToUIManager()
    UI._win:setVisible(true)
end

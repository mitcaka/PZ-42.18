-- FHC_TabTrapping.lua  -- Trap Board (server-authored in MP, local in SP)
require "ISUI/FHC_TabBase"

if isServer() then return end

FHC_TabTrapping = FHC_TabBase:derive("FHC_TabTrapping")
local C = FHC.COLOR
local SB = FHC.SB
local U = FHC.Utils

local SEARCH_RADIUS = 60

function FHC_TabTrapping:createChildren()
    self:addLabel(12, 8, getText("IGUI_FHC_Trapping_Title"), UIFont.Large, C.Ink)
    self.refreshBtn = self:addTextBtn(self:getWidth() - 110, 6, 100, 22,
        getText("IGUI_FHC_Refresh"), self, FHC_TabTrapping.refreshTraps)
    self.rows = {}
    self.awaitingServer = false
    self.requestAt = 0
end

function FHC_TabTrapping:onShow() self:refreshTraps() end

local function trapStateTextFromParts(state, value)
    if state == "caught" then
        return getText("IGUI_FHC_TrapCaught") .. ": " .. tostring(value)
    end
    if state == "baited" then
        return getText("IGUI_FHC_TrapBaited") .. ": " .. tostring(value)
    end
    return getText("IGUI_FHC_TrapEmpty")
end

local function trapStateParts(trap)
    if trap and trap.getModData then
        local md = trap:getModData()
        if md and md.animalType then return "caught", tostring(md.animalType) end
        if md and md.bait then return "baited", tostring(md.bait) end
    end
    return "empty", ""
end

local TRAP_SPRITE_HINTS = {
    "trap", "Trap"
}

local function spriteName(obj)
    local okSprite, sprite = U.tryCall(obj, "getSprite")
    local okName, name = U.tryCall(sprite, "getName")
    return okName and name or nil
end

local function isTrapObj(obj)
    if not obj then return false end
    local name = spriteName(obj)
    if not name then return false end
    for _, h in ipairs(TRAP_SPRITE_HINTS) do
        if string.find(name, h, 1, true) then return true end
    end
    return false
end

local function decorateRows(rows)
    for _, row in ipairs(rows or {}) do
        row.state = trapStateTextFromParts(row.stateKey or row.state, row.stateValue or row.value)
    end
    return rows or {}
end

function FHC_TabTrapping:refreshTraps()
    self.rows = {}
    if not SB.trapBoard() then return end
    local player = self.player
    if not player then return end
    if isClient and isClient() then
        self.awaitingServer = true
        self.requestAt = getTimestampMs and getTimestampMs() or 0
        sendClientCommand(player, FHC.MODULE, FHC.CMD.TrapBoardRequest, { radius = SEARCH_RADIUS })
        if FHC.Client and FHC.Client.trapRows and (FHC.Client.trapRowsAt or 0) >= self.requestAt then
            self.rows = decorateRows(FHC.Client.trapRows)
        end
        return
    end

    local cell = getCell(); if not cell then return end
    local plX, plY, plZ = U.objectPosition(player)
    if not plX then return end
    local r2 = SEARCH_RADIUS * SEARCH_RADIUS
    for sx = math.floor(plX - SEARCH_RADIUS), math.ceil(plX + SEARCH_RADIUS) do
        for sy = math.floor(plY - SEARCH_RADIUS), math.ceil(plY + SEARCH_RADIUS) do
            local dx, dy = sx - plX, sy - plY
            if (dx * dx + dy * dy) <= r2 then
                local okSq, sq = U.tryCall(cell, "getGridSquare", sx, sy, math.floor(plZ))
                if sq then
                    local okObjects, objs = U.tryCall(sq, "getObjects")
                    for i = 0, U.listSize(objs) - 1 do
                        local obj = U.listGet(objs, i)
                        if isTrapObj(obj) then
                            local stateKey, stateValue = trapStateParts(obj)
                            table.insert(self.rows, {
                                x = sx, y = sy, z = plZ,
                                stateKey = stateKey,
                                stateValue = stateValue,
                                state = trapStateTextFromParts(stateKey, stateValue),
                                spr = spriteName(obj) or "trap",
                                dist = math.sqrt(dx * dx + dy * dy),
                            })
                        end
                    end
                end
            end
        end
    end
    table.sort(self.rows, function(a, b) return a.dist < b.dist end)
end

function FHC_TabTrapping:prerender()
    FHC_TabBase.prerender(self)
    if isClient and isClient() and FHC.Client and FHC.Client.trapRows
        and (FHC.Client.trapRowsAt or 0) >= (self.requestAt or 0) then
        self.rows = decorateRows(FHC.Client.trapRows)
        self.awaitingServer = false
    end
    local x, y = 14, 40
    self:drawText(getText("IGUI_FHC_Trapping_Header") .. " (" .. tostring(#self.rows) .. ")",
        x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium)
    y = y + 22
    if self.awaitingServer and #self.rows == 0 then
        self:drawText(getText("IGUI_FHC_Trapping_Loading"), x, y,
            C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
        return
    end
    if #self.rows == 0 then
        self:drawText(getText("IGUI_FHC_Trapping_None"), x, y, C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
        return
    end
    self:drawText(getText("IGUI_FHC_Trapping_Columns"), x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small)
    y = y + 18
    for i = 1, math.min(#self.rows, 18) do
        local row = self.rows[i]
        local line = string.format("  (%d,%d,%d)  %.1ft   %s",
            row.x, row.y, row.z, row.dist, row.state)
        self:drawText(line, x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Small)
        y = y + 16
    end
    if #self.rows > 18 then
        self:drawText(string.format(getText("IGUI_FHC_Trapping_MoreRows"), #self.rows - 18),
            x, y, C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
    end
end

FHC.UI.Tabs.trapping = function(x, y, w, h, player) return FHC_TabTrapping:new(x, y, w, h, player) end

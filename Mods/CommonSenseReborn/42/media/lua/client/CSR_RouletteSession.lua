--[[
    CSR_RouletteSession — client-side controller for the MP Russian Roulette
    session. Adds an inventory option on revolvers to invite nearby players
    into a turn-based session. Hosts the invite popup, the active-session
    HUD, and the trigger-pull action wrapper.

    All randomness lives on the server (CSR_ServerCommands.handleRoulette*).
    Each pull is a server-side roll versus a hidden kill chamber that was
    pre-selected when the session was created. Clients only render the
    outcome the server hands them.
]]--

require "CSR_FeatureFlags"
require "CSR_RouletteData"
require "TimedActions/CSR_RouletteFireAction"

CSR_RouletteSession = CSR_RouletteSession or {}

local activeSession = nil       -- { id, players, turnIndex, round, status }
local pendingInvite = nil       -- popup payload from server
local hudPanel = nil

local function isFeatureOn()
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    return sb.EnableRouletteSession ~= false
end

local function getLocalUsername()
    local p = getPlayer()
    return p and p.getUsername and p:getUsername() or nil
end

-- ─────────────────────────────────────────────────────────────────────
-- Invite popup
-- ─────────────────────────────────────────────────────────────────────

CSR_RouletteInvitePopup = ISPanel:derive("CSR_RouletteInvitePopup")

function CSR_RouletteInvitePopup:initialise()
    ISPanel.initialise(self)
    self.title = ISLabel:new(10, 10, 22, getText("IGUI_CSR_RouletteInviteTitle"), 1, 1, 1, 1, UIFont.Medium, true)
    self.title:initialise(); self:addChild(self.title)
    self.body = ISRichTextPanel:new(10, 40, self.width - 20, 60)
    self.body:initialise(); self.body.background = false
    self.body.text = string.format("<TEXT> %s ", getText("IGUI_CSR_RouletteInviteBody", self.hostName or "?"))
    self.body:paginate()
    self:addChild(self.body)
    self.acceptBtn = ISButton:new(10, self.height - 36, 90, 26, getText("UI_btn_yes"), self, CSR_RouletteInvitePopup.onAccept)
    self.acceptBtn:initialise(); self:addChild(self.acceptBtn)
    self.declineBtn = ISButton:new(self.width - 100, self.height - 36, 90, 26, getText("UI_btn_no"), self, CSR_RouletteInvitePopup.onDecline)
    self.declineBtn:initialise(); self:addChild(self.declineBtn)
end

function CSR_RouletteInvitePopup:onAccept()
    sendClientCommand(getPlayer(), "CommonSenseReborn", "RouletteRespond", {
        sessionId = self.sessionId, accept = true })
    self:setVisible(false); self:removeFromUIManager(); pendingInvite = nil
end

function CSR_RouletteInvitePopup:onDecline()
    sendClientCommand(getPlayer(), "CommonSenseReborn", "RouletteRespond", {
        sessionId = self.sessionId, accept = false })
    self:setVisible(false); self:removeFromUIManager(); pendingInvite = nil
end

function CSR_RouletteInvitePopup:new(sessionId, hostName)
    local w, h = 360, 160
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local o = ISPanel.new(self, (sw - w) / 2, (sh - h) / 2, w, h)
    o.sessionId = sessionId; o.hostName = hostName
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.9 }
    o.borderColor = { r = 0.7, g = 0.7, b = 0.7, a = 1 }
    o.moveWithMouse = true
    return o
end

-- ─────────────────────────────────────────────────────────────────────
-- Active session HUD
-- ─────────────────────────────────────────────────────────────────────

CSR_RouletteHud = ISPanel:derive("CSR_RouletteHud")

function CSR_RouletteHud:initialise()
    ISPanel.initialise(self)
    local pad = 12
    self.title = ISLabel:new(pad, pad, 22, getText("IGUI_CSR_RouletteHudTitle"), 1, 0.35, 0.35, 1, UIFont.Medium, true)
    self.title:initialise(); self:addChild(self.title)
    self.statusLbl = ISLabel:new(pad, pad + 30, 18, "", 1, 1, 1, 1, UIFont.Small, true)
    self.statusLbl:initialise(); self:addChild(self.statusLbl)
    self.playersLbl = ISLabel:new(pad, pad + 56, 18, "", 0.85, 0.85, 0.85, 1, UIFont.Small, true)
    self.playersLbl:initialise(); self:addChild(self.playersLbl)
    local btnY = self.height - 38
    local fireW = self.width - pad * 2 - 90
    self.fireBtn = ISButton:new(pad, btnY, fireW, 26, getText("IGUI_CSR_RoulettePullTrigger"), self, CSR_RouletteHud.onPull)
    self.fireBtn:initialise(); self:addChild(self.fireBtn)
    self.leaveBtn = ISButton:new(pad + fireW + 6, btnY, 84, 26, getText("UI_btn_leave"), self, CSR_RouletteHud.onLeave)
    self.leaveBtn:initialise(); self:addChild(self.leaveBtn)
end

function CSR_RouletteHud:onPull()
    if not activeSession then return end
    sendClientCommand(getPlayer(), "CommonSenseReborn", "RouletteFire", { sessionId = activeSession.id })
    self.fireBtn.enable = false
end

function CSR_RouletteHud:onLeave()
    if not activeSession then return end
    sendClientCommand(getPlayer(), "CommonSenseReborn", "RouletteLeave", { sessionId = activeSession.id })
end

function CSR_RouletteHud:refresh()
    if not activeSession then return end
    local me = getLocalUsername()
    local turnPlayer = activeSession.players[activeSession.turnIndex] or "?"
    local myTurn = (turnPlayer == me)
    self.statusLbl:setName(string.format("%s %d - %s: %s",
        getText("IGUI_CSR_RouletteRound"), activeSession.round or 1,
        getText("IGUI_CSR_RouletteTurn"), turnPlayer))
    self.playersLbl:setName(table.concat(activeSession.players, " | "))
    self.fireBtn.enable = myTurn and activeSession.status == "active"
    if myTurn then
        self.fireBtn.title = getText("IGUI_CSR_RoulettePullTrigger")
    else
        self.fireBtn.title = getText("IGUI_CSR_RouletteWatching")
    end
end

function CSR_RouletteHud:new()
    local w, h = 380, 150
    local sw = getCore():getScreenWidth()
    local o = ISPanel.new(self, (sw - w) / 2, 90, w, h)
    o.backgroundColor = { r = 0.05, g = 0.02, b = 0.02, a = 0.92 }
    o.borderColor = { r = 0.55, g = 0.1, b = 0.1, a = 1 }
    o.moveWithMouse = true
    return o
end

local function showHud()
    if hudPanel then return end
    hudPanel = CSR_RouletteHud:new()
    hudPanel:initialise(); hudPanel:addToUIManager()
end

local function hideHud()
    if hudPanel then
        hudPanel:setVisible(false); hudPanel:removeFromUIManager(); hudPanel = nil
    end
end

-- ─────────────────────────────────────────────────────────────────────
-- Server response handlers
-- ─────────────────────────────────────────────────────────────────────

local function onServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    if command == "RouletteInvite" then
        if pendingInvite then return end
        pendingInvite = args
        local popup = CSR_RouletteInvitePopup:new(args.sessionId, args.hostName)
        popup:initialise(); popup:addToUIManager()
    elseif command == "RouletteUpdate" then
        activeSession = {
            id = args.sessionId,
            players = args.players or {},
            turnIndex = args.turnIndex or 1,
            round = args.round or 1,
            status = args.status or "active",
        }
        showHud()
        if hudPanel then hudPanel:refresh() end
    elseif command == "RouletteOutcome" then
        local me = getLocalUsername()
        if args.firingPlayer == me then
            local playerObj = getPlayer()
            local weapon = playerObj and playerObj.getPrimaryHandItem and playerObj:getPrimaryHandItem() or nil
            if weapon and CSR_RouletteData.isRevolver(weapon) then
                local action = CSR_RouletteFireAction:new(playerObj, weapon, args.killOutcome, args.anim)
                ISTimedActionQueue.add(action)
            end
        end
        if args.message and getPlayer() then
            pcall(function()
                if HaloTextHelper and HaloTextHelper.addText then
                    HaloTextHelper.addText(getPlayer(), args.message, nil)
                end
            end)
        end
    elseif command == "RouletteEnd" then
        activeSession = nil
        hideHud()
    end
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end

-- ─────────────────────────────────────────────────────────────────────
-- Inventory context menu (challenge / start session)
-- ─────────────────────────────────────────────────────────────────────

local function findNearbyOptedPlayers(playerObj)
    local out = {}
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then return out end
    for i = 0, players:size() - 1 do
        local other = players:get(i)
        if other and other ~= playerObj and not other:isDead() then
            local dx = other:getX() - playerObj:getX()
            local dy = other:getY() - playerObj:getY()
            if dx * dx + dy * dy <= CSR_RouletteData.MAX_INVITE_RANGE * CSR_RouletteData.MAX_INVITE_RANGE
                and other:getZ() == playerObj:getZ() then
                out[#out + 1] = other:getUsername()
            end
        end
    end
    return out
end

local function onStartSession(items, player, weapon)
    local playerObj = getSpecificPlayer(player)
    if not playerObj or not weapon then return end
    local invitees = findNearbyOptedPlayers(playerObj)
    if #invitees == 0 then return end
    sendClientCommand(playerObj, "CommonSenseReborn", "RouletteCreate", {
        weaponType = weapon:getFullType(),
        invitees = invitees,
    })
end

function CSR_RouletteSession.addInventoryOptions(player, context, items)
    if not isFeatureOn() then return end
    if not isClient() then return end
    if activeSession then return end
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    local weapon = nil
    for i = 1, #items do
        local entry = items[i]
        local list = entry.items or { entry }
        for j = 1, #list do
            local it = list[j]
            if instanceof(it, "InventoryItem") and CSR_RouletteData.isRevolver(it) then
                weapon = it; break
            end
        end
        if weapon then break end
    end
    if not weapon then return end

    local nearby = findNearbyOptedPlayers(playerObj)
    local opt = context:addOption(getText("ContextMenu_CSR_RouletteStart"), items, onStartSession, player, weapon)
    local tip = ISToolTip:new(); tip:initialise()
    if #nearby == 0 then
        opt.notAvailable = true
        tip.description = getText("Tooltip_CSR_RouletteNoPlayers")
    elseif weapon.getCurrentAmmoCount and weapon:getCurrentAmmoCount() <= 0 then
        opt.notAvailable = true
        tip.description = getText("Tooltip_CSR_RouletteNoRound")
    else
        tip.description = getText("Tooltip_CSR_RouletteInvite", #nearby)
    end
    opt.toolTip = tip
end

if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(CSR_RouletteSession.addInventoryOptions)
end

return CSR_RouletteSession

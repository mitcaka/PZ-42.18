local Config = require("Cat_RPChat/Config")
local ClientConfig = require("Cat_RPChat/ClientConfig")
local Utils = require("Cat_RPChat/Utils")
local NameChangeDialog = require("Cat_RPChat/NameChangeDialog")
local ColorPickerDialog = require("Cat_RPChat/ColorPickerDialog")
local PitchDialog = require("Cat_RPChat/PitchDialog")

local ChatHook = {}

-- Dark flat background override
local orig_prerender = ISChat.prerender
function ISChat:prerender()
    ISChat.instance = self
    self:setDrawFrame(true)
    if not ISChat.focused then
        self.fade:update()
    end
    self:makeFade(self.fade:fraction())

    local alpha = self:calcAlpha(ISChat.minControlOpaque, ISChat.maxGeneralOpaque, self.fade:fraction())
    -- Title bar: dark grey
    self:drawRect(0, 0, self:getWidth(), self:titleBarHeight(), math.max(alpha + 0.3, 1), 0.08, 0.08, 0.08)
    -- Body: flat dark, no banding
    self:drawRect(0, self:titleBarHeight(), self:getWidth(), self:getHeight() - self:titleBarHeight(), alpha, 0.06, 0.06, 0.06)

    if self.servermsg then
        local x = getCore():getScreenWidth() / 2 - self:getX()
        local y = getCore():getScreenHeight() / 4 - self:getY()
        self:drawTextCentre(self.servermsg, x, y, 1, 0.1, 0.1, 1, UIFont.Title)
        self.servermsgTimer = self.servermsgTimer - UIManager.getMillisSinceLastRender()
        if self.servermsgTimer < 0 then
            self.servermsg = nil
            self.servermsgTimer = 0
        end
    end

    -- Render typing dots (TICS-style, inside ISChat prerender)
    if Cat_RPChat_TypingDots then
        local toRemove = {}
        for username, dots in pairs(Cat_RPChat_TypingDots) do
            if dots.dead or not dots.player or dots.player:isDead() then
                table.insert(toRemove, username)
            else
                dots:render()
            end
        end
        for _, username in ipairs(toRemove) do
            Cat_RPChat_TypingDots[username] = nil
        end
    end
end

-- Sticky channel: global for session, ClientConfig for persistence across reconnects
local currentChannel = Cat_RPChat_currentChannel or ClientConfig.getChannel()

-- Show current channel prefix when opening chat
local orig_focus = ISChat.focus
function ISChat:focus()
    orig_focus(self)
    if currentChannel and currentChannel ~= "say" then
        local prefix = "/" .. currentChannel .. " "
        self.textEntry:setText(prefix)
        self.textEntry:setCursorPos(#prefix)
    end
end

-- Typing indicator: patch text entry callback after ISChat is created
local function hookTypingIndicator()
    if not ISChat.instance or not ISChat.instance.textEntry then return end
    local origTextEntryCallback = ISChat.instance.textEntry.onTextChange
    ISChat.instance.textEntry.onTextChange = function()
        if origTextEntryCallback then origTextEntryCallback() end
        if not isClient() then return end
        local text = ISChat.instance.textEntry:getInternalText()
        if not text or #text == 0 then return end

        local cmd = text:match("^(/%S*)")
        if cmd then
            cmd = cmd:lower()
            if cmd == "/name" or cmd == "/color" or cmd == "/pitch" or cmd == "/rpch" or cmd == "/rpchat" then
                return
            end
        end

        local now = Calendar.getInstance():getTimeInMillis()
        Cat_RPChat_lastTypingTime = Cat_RPChat_lastTypingTime or 0
        if now - Cat_RPChat_lastTypingTime < 500 then
            return
        end
        Cat_RPChat_lastTypingTime = now

        sendClientCommand(Config.MOD_NAME, "Typing", {
            author = getPlayer():getUsername(),
        })

        local localPlayer = getPlayer()
        if localPlayer then
            local TypingDots = require("Cat_RPChat/TypingDots")
            Cat_RPChat_TypingDots = Cat_RPChat_TypingDots or {}
            if Cat_RPChat_TypingDots[localPlayer:getUsername()] then
                Cat_RPChat_TypingDots[localPlayer:getUsername()]:refresh()
            else
                Cat_RPChat_TypingDots[localPlayer:getUsername()] = TypingDots:new(localPlayer, 1)
            end
        end
    end
end
Events.OnGameStart.Add(hookTypingIndicator)

-- Command routing
local function getChannelFromCommand(text)
    local cmd = text:match("^(/%S+)")
    if not cmd then return nil, text end
    cmd = cmd:lower()
    local rest = text:sub(#cmd + 1):gsub("^%s*(.-)%s*$", "%1")
    if cmd == "/say" or cmd == "/s" then return "say", rest end
    if cmd == "/all" or cmd == "/g" then return "all", rest end
    if cmd == "/me" then return "me", rest end
    if cmd == "/ooc" or cmd == "/o" then return "ooc", rest end
    if cmd == "/whisper" or cmd == "/w" then return "whisper", rest end
    if cmd == "/yell" or cmd == "/y" then return "yell", rest end
    return nil, text
end

local function addChatLine(text)
    local chat = ISChat.instance
    if not chat then return end
    local panel = chat.chatText
    if not panel or not panel.paginate then
        panel = chat.defaultTab
    end
    if not panel or not panel.paginate then
        panel = chat.tabs and chat.tabs[1]
    end
    if not panel or not panel.paginate then return end

    if not panel.chatTextLines then panel.chatTextLines = {} end
    table.insert(panel.chatTextLines, text .. " <LINE> ")

    if ISChat.maxLine and #panel.chatTextLines > ISChat.maxLine then
        local newLines = {}
        for i, v in ipairs(panel.chatTextLines) do
            if i ~= 1 then
                table.insert(newLines, v)
            end
        end
        panel.chatTextLines = newLines
    end

    panel.text = ""
    for i, v in ipairs(panel.chatTextLines) do
        if i == #panel.chatTextLines then
            v = string.gsub(v, " <LINE> $", "")
        end
        panel.text = panel.text .. v
    end

    local savedFont = panel.font
    local savedDefault = panel.defaultFont
    panel:paginate()
    if savedDefault then
        panel.font = savedDefault
    elseif savedFont then
        panel.font = savedFont
    end
    panel:setYScroll(-10000)
end

local function showHelp()
    local help = {
        "Cat RPChat commands:",
        "/say (/s) <message> - Local chat",
        "/all (/g) <message> - Global chat",
        "/me <message> - Emote",
        "/ooc (/o) <message> - Out of character",
        "/whisper (/w) <message> - Whisper",
        "/yell (/y) <message> - Yell",
        "/name <name> - Set display name",
        "/color <r> <g> <b> - Set name color (0-255)",
        "/pitch <0.5-2.0> - Set voice pitch",
    }
    for _, line in ipairs(help) do
        addChatLine("<RGB:0.8,0.8,1.0>" .. line)
    end
end

-- Dialog callbacks
local function openNameDialog()
    local dialog = NameChangeDialog:new(0, 0, ClientConfig.getDisplayName(), function(name)
        ClientConfig.setDisplayName(name)
        addChatLine("<RGB:0.8,1.0,0.8>Display name set to: " .. name)
    end)
    dialog:initialise()
    dialog:addToUIManager()
    if JoypadState.players[dialog.playerNum + 1] then
        setJoypadFocus(dialog.playerNum, dialog)
    end
end

local function openColorDialog()
    local dialog = ColorPickerDialog:new(0, 0, ClientConfig.getColor(), function(r, g, b)
        ClientConfig.setColor(r, g, b)
        addChatLine("<RGB:0.8,1.0,0.8>Name color updated.")
    end)
    dialog:initialise()
    dialog:addToUIManager()
    if JoypadState.players[dialog.playerNum + 1] then
        setJoypadFocus(dialog.playerNum, dialog)
    end
end

local function openPitchDialog()
    local dialog = PitchDialog:new(0, 0, ClientConfig.getPitch(), function(pitch)
        ClientConfig.setPitch(pitch)
        addChatLine("<RGB:0.8,1.0,0.8>Voice pitch set to: " .. tostring(ClientConfig.getPitch()))
    end)
    dialog:initialise()
    dialog:addToUIManager()
    if JoypadState.players[dialog.playerNum + 1] then
        setJoypadFocus(dialog.playerNum, dialog)
    end
end

local function toggleVoice()
    local enabled = not ClientConfig.isVoiceEnabled()
    ClientConfig.setVoiceEnabled(enabled)
    addChatLine("<RGB:0.8,1.0,0.8>Voice " .. (enabled and "enabled." or "disabled."))
end

-- Gear menu hook
local orig_onGearButtonClick = ISChat.onGearButtonClick
function ISChat:onGearButtonClick()
    if orig_onGearButtonClick then
        orig_onGearButtonClick(self)
    end
    -- Append RPChat options after vanilla gear menu items
    local context = getPlayerContextMenu(0)
    if context then
        context:addOption("--- RPChat ---", nil, nil)
        context:addOption("Change Display Name", nil, openNameDialog)
        context:addOption("Change Name Color", nil, openColorDialog)
        context:addOption("Change Voice Pitch", nil, openPitchDialog)
        context:addOption("Toggle Voice", nil, toggleVoice)
    end
end

local orig_onCommandEntered = ISChat.onCommandEntered
function ISChat:onCommandEntered()
    local text = ISChat.instance.textEntry:getText()
    if not text or #text == 0 then
        if orig_onCommandEntered then orig_onCommandEntered(self) end
        return
    end

    -- Settings commands
    if text:lower():sub(1, 6) == "/name " then
        local name = text:sub(7):gsub("^%s*(.-)%s*$", "%1")
        if #name > 0 then
            ClientConfig.setDisplayName(name)
            addChatLine("<RGB:0.8,1.0,0.8>Display name set to: " .. name)
        end
        ISChat.instance.textEntry:setText("")
        ISChat.instance.textEntry:unfocus()
        return
    elseif text:lower():match("^/color%s*") then
        local rest = text:sub(7):match("^%s*(.-)%s*$")
        if rest and #rest > 0 then
            local r, g, b = rest:match("(%d+)%s+(%d+)%s+(%d+)")
            if r and g and b then
                ClientConfig.setColor(tonumber(r), tonumber(g), tonumber(b))
                addChatLine("<RGB:0.8,1.0,0.8>Name color updated.")
            else
                addChatLine("<RGB:1.0,0.4,0.4>Usage: /color <r> <g> <b> (0-255)")
            end
        else
            addChatLine("<RGB:1.0,0.4,0.4>Usage: /color <r> <g> <b> (0-255)")
        end
        ISChat.instance.textEntry:setText("")
        ISChat.instance.textEntry:unfocus()
        return
    elseif text:lower():match("^/pitch%s*") then
        local rest = text:sub(7):match("^%s*(.-)%s*$")
        local p = tonumber(rest)
        if p then
            ClientConfig.setPitch(p)
            addChatLine("<RGB:0.8,1.0,0.8>Voice pitch set to: " .. tostring(ClientConfig.getPitch()))
        else
            addChatLine("<RGB:1.0,0.4,0.4>Usage: /pitch <0.5-2.0>")
        end
        ISChat.instance.textEntry:setText("")
        ISChat.instance.textEntry:unfocus()
        return
    elseif text:lower():sub(1, 6) == "/rpch" then
        showHelp()
        ISChat.instance.textEntry:setText("")
        ISChat.instance.textEntry:unfocus()
        return
    end

    -- Chat commands
    local channel, message = getChannelFromCommand(text)
    if not channel then
        if text:sub(1, 1) ~= "/" then
            channel = currentChannel
            message = text
        else
            -- Unknown command, let vanilla handle
            if orig_onCommandEntered then orig_onCommandEntered(self) end
            return
        end
    else
        currentChannel = channel
        Cat_RPChat_currentChannel = channel
        ClientConfig.setChannel(channel)
    end

    message = message:gsub("^%s*(.-)%s*$", "%1")
    if #message == 0 then
        ISChat.instance.textEntry:setText("")
        ISChat.instance.textEntry:unfocus()
        return
    end

    -- Send to server via our network layer
    sendClientCommand(Config.MOD_NAME, "ChatMessage", {
        channel = channel,
        text = message,
    })

    -- Local echo for the sender so they see it immediately
    local profile = {
        displayName = ClientConfig.getDisplayName(),
        color = ClientConfig.getColor(),
        pitch = ClientConfig.getPitch(),
    }
    local chConfig = nil
    for _, ch in pairs(Config.CHANNELS) do
        if ch.name == channel then
            chConfig = ch
            break
        end
    end
    if chConfig then
        local dc = chConfig.color
        local nc = profile.color
        local chatBody = Utils.formatChatText(message, dc, Config.EMOTE_COLOR)
        local formatted = ""
        if channel == "me" then
            formatted = Utils.colorTagInline(dc) .. "* " .. profile.displayName .. " " .. chatBody .. " *"
        elseif channel == "ooc" then
            formatted = Utils.colorTagInline(dc) .. "(( " .. profile.displayName .. ": " .. chatBody .. " ))"
        elseif channel == "all" then
            formatted = Utils.colorTagInline(nc) .. profile.displayName .. " (Global): " .. Utils.colorTagWithSpace(dc) .. chatBody
        else
            formatted = Utils.colorTagInline(nc) .. profile.displayName .. " " .. chConfig.prefix .. ": " .. Utils.colorTagWithSpace(dc) .. chatBody
        end
        addChatLine(formatted)
    end

    -- Local bubble + voice
    local player = getPlayer()
    if player and channel ~= "ooc" then
        local _, bubbleText, rawText = Utils.parseEmotes(message, chConfig.color, Config.EMOTE_COLOR)
        local bubbleDisplay = Utils.colorTagWithSpace(chConfig.color) .. Utils.formatChatText(message, chConfig.color, Config.EMOTE_COLOR)
        local bubble = require("Cat_RPChat/Bubble")
        local voice = require("Cat_RPChat/Voice")
        bubble.create(player, bubbleDisplay, channel, profile.pitch)
        if ClientConfig.isVoiceEnabled() then
            voice.play(rawText, player, profile.pitch)
        end
    end

    ISChat.instance.textEntry:setText("")
    ISChat.instance.textEntry:unfocus()

    local localPlayer = getPlayer()
    if localPlayer and Cat_RPChat_TypingDots then
        Cat_RPChat_TypingDots[localPlayer:getUsername()] = nil
    end
end

return ChatHook

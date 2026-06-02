-- =============================================================================
-- Cat Banking System — Credit Card Hacking Mini-Game UI (3 Game Modes)
-- =============================================================================
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"

local MOD_NAME = "Cat_BankingSystem"
local HACK_TERMS = {
    "READ", "WRITE", "SCAN", "AUTH",
    "DECODE", "PARSE", "VERIFY", "INIT",
    "MAIN", "LOOP"
}

local currentHackUI = nil

local function playATMSound(soundName)
    local sm = getSoundManager()
    if sm and sm.PlaySound then
        sm:PlaySound(soundName, false, 1.0)
    end
end

-- =============================================================================
-- Game 1: Fixed Timing Windows
-- =============================================================================
Cat_HackTimingUI = ISPanel:derive("Cat_HackTimingUI")

function Cat_HackTimingUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 0.96 }
    o.borderColor = { r = 0.35, g = 0.35, b = 0.35, a = 1 }
    o.moveWithMouse = true
    o.cardName = ""
    o.cardType = ""
    o.locked = { false, false, false, false }
    o.stopped = { nil, nil, nil, nil }
    o.targets = { 0, 0, 0, 0 }
    o.durations = { 400, 400, 400, 400 }
    o.startTimes = { 0, 0, 0, 0 }
    o.currentTerms = { 0, 0, 0, 0 }
    o.finished = false
    o.processing = false
    o.processTimer = 0
    return o
end

function Cat_HackTimingUI:createChildren()
    ISPanel.createChildren(self)

    local title = ISLabel:new(self.width / 2, 10, 22, "ATM SKIMMER", 0.2, 0.9, 0.4, 1, UIFont.Medium, true)
    title.center = true
    title:initialise()
    self:addChild(title)

    local sub = ISLabel:new(self.width / 2, 35, 16, "LOCK THE TARGET FUNCTIONS", 0.5, 0.5, 0.5, 1, UIFont.Small, true)
    sub.center = true
    sub:initialise()
    self:addChild(sub)

    local colW = 72
    local startX = self.width / 2 - (4 * colW) / 2 + 10
    local centerY = 100

    for i = 1, 4 do
        local btn = ISButton:new(startX + (i - 1) * colW, centerY + 70, 56, 28, "L" .. i, self, self.onLock)
        btn.internal = i
        btn.backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 }
        btn.backgroundColorMouseOver = { r = 0.25, g = 0.45, b = 0.25, a = 1 }
        btn.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
    end

    self.statusLabel = ISLabel:new(self.width / 2, self.height - 55, 18, "Lock when the green term appears", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.statusLabel.center = true
    self.statusLabel:initialise()
    self:addChild(self.statusLabel)

    local closeBtn = ISButton:new(self.width / 2 - 40, self.height - 32, 80, 26, "CLOSE", self, self.onClose)
    closeBtn.backgroundColor = { r = 0.5, g = 0.15, b = 0.15, a = 1 }
    closeBtn:initialise()
    closeBtn:instantiate()
    self:addChild(closeBtn)

    local now = getTimestampMs()
    for i = 1, 4 do
        self.startTimes[i] = now
    end
end

function Cat_HackTimingUI:onLock(button)
    if self.finished or self.processing then return end
    local idx = button.internal
    if self.locked[idx] then return end
    self.locked[idx] = true
    self.stopped[idx] = self.currentTerms[idx]
    playATMSound("Cat_ATMButtonBeep")

    local allLocked = true
    for i = 1, 4 do
        if not self.locked[i] then
            allLocked = false
            break
        end
    end

    if allLocked then
        self.processing = true
        self.processTimer = getTimestampMs()
        self.statusLabel:setName("Decrypting...")
        self.statusLabel.r = 0.2
        self.statusLabel.g = 0.9
        self.statusLabel.b = 0.4
    else
        self.statusLabel:setName("Locked " .. idx .. "/4")
    end
end

function Cat_HackTimingUI:update()
    ISPanel.update(self)
    if self.finished then return end

    if self.processing then
        if getTimestampMs() - self.processTimer > 1000 then
            self.finished = true
            self.processing = false
            sendClientCommand(MOD_NAME, "finishHack", {
                cardName = self.cardName,
                cardType = self.cardType,
                gameType = 1,
                stops = self.stopped,
            })
        end
        return
    end

    local now = getTimestampMs()
    for i = 1, 4 do
        if not self.locked[i] then
            local elapsed = now - self.startTimes[i]
            local cycle = self.durations[i] * 10
            local pos = elapsed % cycle
            self.currentTerms[i] = math.floor(pos / self.durations[i])
        end
    end
end

function Cat_HackTimingUI:render()
    ISPanel.render(self)

    local colW = 72
    local startX = self.width / 2 - (4 * colW) / 2 + 10
    local centerY = 100
    local boxH = 70

    for i = 1, 4 do
        local cx = startX + (i - 1) * colW
        local termIdx = self.currentTerms[i]
        local targetIdx = self.targets[i]
        local text = HACK_TERMS[termIdx + 1]
        local isTarget = (termIdx == targetIdx)
        local isLocked = self.locked[i]
        local stoppedIdx = self.stopped[i]

        -- Box background
        local bgR, bgG, bgB = 0.08, 0.08, 0.08
        if isTarget and not isLocked then
            bgR, bgG, bgB = 0.1, 0.25, 0.1
        end
        self:drawRect(cx, centerY - boxH / 2, colW - 4, boxH, 1, bgR, bgG, bgB)
        self:drawRectBorder(cx, centerY - boxH / 2, colW - 4, boxH, 1, 0.25, 0.25, 0.25)

        -- Term text
        local r, g, b = 0.7, 0.7, 0.7
        if isTarget then
            r, g, b = 0.2, 1.0, 0.4
        end
        if isLocked then
            if stoppedIdx == targetIdx then
                r, g, b = 0.2, 0.9, 0.3
            else
                r, g, b = 0.9, 0.2, 0.2
            end
        end

        local font = UIFont.Medium
        local tw = getTextManager():MeasureStringX(font, text)
        self:drawText(text, cx + (colW - 4) / 2 - tw / 2, centerY - 8, r, g, b, 1, font)

        -- Locked indicator
        if isLocked then
            local status = (stoppedIdx == targetIdx) and "OK" or "FAIL"
            local sr, sg, sb = (stoppedIdx == targetIdx) and 0.2 or 0.9, (stoppedIdx == targetIdx) and 0.9 or 0.2, 0.3
            local stw = getTextManager():MeasureStringX(UIFont.Small, status)
            self:drawText(status, cx + (colW - 4) / 2 - stw / 2, centerY + 22, sr, sg, sb, 1, UIFont.Small)
        end
    end
end

function Cat_HackTimingUI:onClose()
    playATMSound("Cat_ATMErrorBeep")
    self:setVisible(false)
    self:removeFromUIManager()
    currentHackUI = nil
end

-- =============================================================================
-- Game 2: Mastermind
-- =============================================================================
Cat_HackMastermindUI = ISPanel:derive("Cat_HackMastermindUI")

function Cat_HackMastermindUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 0.96 }
    o.borderColor = { r = 0.35, g = 0.35, b = 0.35, a = 1 }
    o.moveWithMouse = true
    o.cardName = ""
    o.cardType = ""
    o.targets = { 0, 0, 0, 0 }
    o.maxAttempts = 6
    o.attemptsUsed = 0
    o.guess = {}
    o.history = {}
    o.lastSubmittedGuess = nil
    o.termStates = {}
    o.termButtons = {}
    o.finished = false
    return o
end

function Cat_HackMastermindUI:createChildren()
    ISPanel.createChildren(self)

    local title = ISLabel:new(self.width / 2, 10, 22, "ATM SKIMMER", 0.2, 0.9, 0.4, 1, UIFont.Medium, true)
    title.center = true
    title:initialise()
    self:addChild(title)

    local sub = ISLabel:new(self.width / 2, 35, 16, "BREAK THE ENCRYPTION KEY", 0.5, 0.5, 0.5, 1, UIFont.Small, true)
    sub.center = true
    sub:initialise()
    self:addChild(sub)

    -- Guess slots (centered)
    self.guessSlots = {}
    local slotW = 58
    local gap = 14
    local totalSlotW = 4 * slotW + 3 * gap
    local slotStartX = (self.width - totalSlotW) / 2
    for i = 1, 4 do
        local slot = ISButton:new(slotStartX + (i - 1) * (slotW + gap), 65, slotW, 30, "?", self, self.onClearSlot)
        slot.internal = i
        slot.backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 1 }
        slot.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
        slot:initialise()
        slot:instantiate()
        self:addChild(slot)
        self.guessSlots[i] = slot
    end

    -- Term grid
    for i = 0, 9 do
        local col = i % 5
        local row = math.floor(i / 5)
        local btn = ISButton:new(30 + col * 65, 115 + row * 36, 58, 30, HACK_TERMS[i + 1], self, self.onPickTerm)
        btn.internal = i
        btn.backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 }
        btn.backgroundColorMouseOver = { r = 0.25, g = 0.25, b = 0.25, a = 1 }
        btn.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
        self.termButtons[i + 1] = btn
    end

    -- Submit button
    local submitBtn = ISButton:new(self.width / 2 - 50, 195, 100, 28, "SUBMIT", self, self.onSubmit)
    submitBtn.backgroundColor = { r = 0.2, g = 0.5, b = 0.2, a = 1 }
    submitBtn:initialise()
    submitBtn:instantiate()
    self:addChild(submitBtn)

    -- History label
    local attemptsText = "Attempts: 0 / " .. tostring(self.maxAttempts or 6)
    self.historyLabel = ISLabel:new(self.width / 2, 235, 16, attemptsText, 0.6, 0.6, 0.6, 1, UIFont.Small, true)
    self.historyLabel.center = true
    self.historyLabel:initialise()
    self:addChild(self.historyLabel)

    -- History rows
    self.historyRows = {}
    for i = 1, 6 do
        local row = ISLabel:new(self.width / 2, 255 + (i - 1) * 18, 16, "", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
        row.center = true
        row:initialise()
        self:addChild(row)
        self.historyRows[i] = row
    end

    self.statusLabel = ISLabel:new(self.width / 2, self.height - 55, 18, "", 1, 1, 1, 1, UIFont.Small, true)
    self.statusLabel.center = true
    self.statusLabel:initialise()
    self:addChild(self.statusLabel)

    local closeBtn = ISButton:new(self.width / 2 - 40, self.height - 32, 80, 26, "CLOSE", self, self.onClose)
    closeBtn.backgroundColor = { r = 0.5, g = 0.15, b = 0.15, a = 1 }
    closeBtn:initialise()
    closeBtn:instantiate()
    self:addChild(closeBtn)
end

function Cat_HackMastermindUI:onPickTerm(button)
    if self.finished then return end
    if #self.guess >= 4 then return end
    playATMSound("Cat_ATMButtonBeep")
    table.insert(self.guess, button.internal)
    self:updateGuessSlots()
end

function Cat_HackMastermindUI:onClearSlot(button)
    if self.finished then return end
    local idx = button.internal
    if idx <= #self.guess then
        playATMSound("Cat_ATMButtonBeep")
        table.remove(self.guess, idx)
        self:updateGuessSlots()
    end
end

function Cat_HackMastermindUI:updateGuessSlots()
    for i = 1, 4 do
        if i <= #self.guess then
            self.guessSlots[i]:setTitle(HACK_TERMS[self.guess[i] + 1])
        else
            self.guessSlots[i]:setTitle("?")
        end
    end
end

function Cat_HackMastermindUI:onSubmit()
    if self.finished then return end
    if #self.guess ~= 4 then
        self.statusLabel:setName("Select 4 functions.")
        return
    end
    playATMSound("Cat_ATMButtonBeep")
    self.lastSubmittedGuess = {}
    for i = 1, #self.guess do
        self.lastSubmittedGuess[i] = self.guess[i]
    end
    sendClientCommand(MOD_NAME, "finishHack", {
        cardName = self.cardName,
        cardType = self.cardType,
        gameType = 2,
        guess = self.guess,
    })
    self.guess = {}
    self:updateGuessSlots()
end

function Cat_HackMastermindUI:addHistory(greens, yellows)
    local guessStr = ""
    for i = 1, 4 do
        guessStr = guessStr .. HACK_TERMS[self.history[#self.history] + 1]:sub(1, 2)
        if i < 4 then guessStr = guessStr .. " " end
    end
    -- Actually we need to store the guess before clearing it
end

function Cat_HackMastermindUI:updateTermButtonColors()
    for i = 1, 10 do
        local btn = self.termButtons[i]
        if btn then
            local state = self.termStates[i - 1]
            if state == "green" then
                btn.backgroundColor = { r = 0.15, g = 0.55, b = 0.15, a = 1 }
                btn.backgroundColorMouseOver = { r = 0.25, g = 0.65, b = 0.25, a = 1 }
                btn.borderColor = { r = 0.3, g = 0.9, b = 0.3, a = 1 }
            elseif state == "yellow" then
                btn.backgroundColor = { r = 0.55, g = 0.5, b = 0.1, a = 1 }
                btn.backgroundColorMouseOver = { r = 0.65, g = 0.6, b = 0.15, a = 1 }
                btn.borderColor = { r = 0.9, g = 0.85, b = 0.2, a = 1 }
            else
                btn.backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 }
                btn.backgroundColorMouseOver = { r = 0.25, g = 0.25, b = 0.25, a = 1 }
                btn.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
            end
        end
    end
end

function Cat_HackMastermindUI:onClose()
    playATMSound("Cat_ATMErrorBeep")
    self:setVisible(false)
    self:removeFromUIManager()
    currentHackUI = nil
end

-- =============================================================================
-- Game 3: Memory Sequence
-- =============================================================================
Cat_HackMemoryUI = ISPanel:derive("Cat_HackMemoryUI")

function Cat_HackMemoryUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 0.96 }
    o.borderColor = { r = 0.35, g = 0.35, b = 0.35, a = 1 }
    o.moveWithMouse = true
    o.cardName = ""
    o.cardType = ""
    o.sequence = {}
    o.displayDuration = 600
    o.phase = "idle"  -- "idle", "watch", "repeat", "done"
    o.watchIndex = 0
    o.watchStart = 0
    o.playerSequence = {}
    o.termButtons = {}
    o.finished = false
    return o
end

function Cat_HackMemoryUI:createChildren()
    ISPanel.createChildren(self)

    local title = ISLabel:new(self.width / 2, 10, 22, "ATM SKIMMER", 0.2, 0.9, 0.4, 1, UIFont.Medium, true)
    title.center = true
    title:initialise()
    self:addChild(title)

    self.phaseLabel = ISLabel:new(self.width / 2, 35, 16, "MEMORY DECRYPTION", 0.5, 0.5, 0.5, 1, UIFont.Small, true)
    self.phaseLabel.center = true
    self.phaseLabel:initialise()
    self:addChild(self.phaseLabel)

    -- Initialize button
    self.initBtn = ISButton:new(self.width / 2 - 60, 100, 120, 32, "INITIALIZE", self, self.onInitialize)
    self.initBtn.backgroundColor = { r = 0.2, g = 0.5, b = 0.2, a = 1 }
    self.initBtn:initialise()
    self.initBtn:instantiate()
    self:addChild(self.initBtn)

    -- Display box for the flashing term (hidden initially)
    self.displayBox = ISLabel:new(self.width / 2, 80, 40, "", 0.2, 1.0, 0.4, 1, UIFont.Large, true)
    self.displayBox.center = true
    self.displayBox:initialise()
    self.displayBox:setVisible(false)
    self:addChild(self.displayBox)

    -- Term grid (hidden initially)
    for i = 0, 9 do
        local col = i % 5
        local row = math.floor(i / 5)
        local btn = ISButton:new(30 + col * 65, 140 + row * 36, 58, 30, HACK_TERMS[i + 1], self, self.onPickTerm)
        btn.internal = i
        btn.backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 }
        btn.backgroundColorMouseOver = { r = 0.25, g = 0.25, b = 0.25, a = 1 }
        btn.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
        btn:initialise()
        btn:instantiate()
        btn:setVisible(false)
        self:addChild(btn)
        self.termButtons[i + 1] = btn
    end

    -- Sequence display
    self.sequenceLabel = ISLabel:new(self.width / 2, 225, 16, "", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.sequenceLabel.center = true
    self.sequenceLabel:initialise()
    self:addChild(self.sequenceLabel)

    self.statusLabel = ISLabel:new(self.width / 2, self.height - 55, 18, "Press INITIALIZE to begin", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.statusLabel.center = true
    self.statusLabel:initialise()
    self:addChild(self.statusLabel)

    local closeBtn = ISButton:new(self.width / 2 - 40, self.height - 32, 80, 26, "CLOSE", self, self.onClose)
    closeBtn.backgroundColor = { r = 0.5, g = 0.15, b = 0.15, a = 1 }
    closeBtn:initialise()
    closeBtn:instantiate()
    self:addChild(closeBtn)
end

function Cat_HackMemoryUI:onInitialize(button)
    if self.phase ~= "idle" then return end
    playATMSound("Cat_ATMButtonBeep")
    self.phase = "watch"
    self.phaseLabel:setName("WATCH THE SEQUENCE")
    self.initBtn:setVisible(false)
    self.displayBox:setVisible(true)
    self.watchStart = getTimestampMs()
end

function Cat_HackMemoryUI:update()
    ISPanel.update(self)
    if self.finished or self.phase ~= "watch" then return end

    local now = getTimestampMs()
    local elapsed = now - self.watchStart
    local idx = math.floor(elapsed / self.displayDuration)

    if idx >= #self.sequence then
        -- Switch to repeat phase
        self.phase = "repeat"
        self.phaseLabel:setName("REPEAT THE SEQUENCE")
        self.displayBox:setName("")
        self.displayBox:setVisible(false)
        for i = 1, 10 do
            self.termButtons[i]:setVisible(true)
        end
        self.sequenceLabel:setName("Sequence length: " .. #self.sequence)
        return
    end

    -- Show current term in sequence
    local termIdx = self.sequence[idx + 1]
    self.displayBox:setName(HACK_TERMS[termIdx + 1])
end

function Cat_HackMemoryUI:onPickTerm(button)
    if self.finished or self.phase ~= "repeat" then return end
    playATMSound("Cat_ATMButtonBeep")
    table.insert(self.playerSequence, button.internal)

    local seqStr = ""
    for i = 1, #self.playerSequence do
        seqStr = seqStr .. HACK_TERMS[self.playerSequence[i] + 1]
        if i < #self.playerSequence then seqStr = seqStr .. " " end
    end
    self.sequenceLabel:setName(seqStr)

    if #self.playerSequence >= #self.sequence then
        self.finished = true
        sendClientCommand(MOD_NAME, "finishHack", {
            cardName = self.cardName,
            cardType = self.cardType,
            gameType = 3,
            sequence = self.playerSequence,
        })
    end
end

function Cat_HackMemoryUI:onClose()
    playATMSound("Cat_ATMErrorBeep")
    self:setVisible(false)
    self:removeFromUIManager()
    currentHackUI = nil
end

-- =============================================================================
-- Router / Launcher
-- =============================================================================
Cat_ATMHackUI = {}

function Cat_ATMHackUI.Open(cardName, cardType)
    sendClientCommand(MOD_NAME, "startHack", {
        cardName = cardName,
        cardType = cardType,
    })
end

-- =============================================================================
-- Server response handling
-- =============================================================================
local function onServerCommand(module, command, args)
    if module ~= MOD_NAME then return end

    if command == "hackStarted" then
        if not args.success then
            -- Show a temporary error panel
            local err = ISPanel:new(getCore():getScreenWidth() / 2 - 125, getCore():getScreenHeight() / 2 - 60, 250, 120)
            err.backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 0.96 }
            err.borderColor = { r = 0.5, g = 0.15, b = 0.15, a = 1 }
            err:initialise()
            err:addToUIManager()

            local lbl = ISLabel:new(125, 30, 18, args.error or "Hack failed.", 1, 0.2, 0.2, 1, UIFont.Small, true)
            lbl.center = true
            lbl:initialise()
            err:addChild(lbl)

            local btn = ISButton:new(85, 70, 80, 26, "OK", err, function(o)
                o:setVisible(false)
                o:removeFromUIManager()
            end)
            btn.backgroundColor = { r = 0.5, g = 0.15, b = 0.15, a = 1 }
            btn:initialise()
            btn:instantiate()
            err:addChild(btn)
            return
        end

        local gameType = args.gameType

        if gameType == 1 then
            if currentHackUI then
                currentHackUI:removeFromUIManager()
                currentHackUI = nil
            end
            local ui = Cat_HackTimingUI:new(getCore():getScreenWidth() / 2 - 160, getCore():getScreenHeight() / 2 - 170, 320, 340)
            ui.cardName = args.cardName or ""
            ui.cardType = args.cardType or ""
            ui.targets = args.targets or { 0, 0, 0, 0 }
            ui.durations = args.durations or { 400, 400, 400, 400 }
            ui:initialise()
            ui:addToUIManager()
            currentHackUI = ui

        elseif gameType == 2 then
            if currentHackUI then
                currentHackUI:removeFromUIManager()
                currentHackUI = nil
            end
            local ui = Cat_HackMastermindUI:new(getCore():getScreenWidth() / 2 - 180, getCore():getScreenHeight() / 2 - 220, 360, 440)
            ui.cardName = args.cardName or ""
            ui.cardType = args.cardType or ""
            ui.maxAttempts = args.maxAttempts or 6
            ui:initialise()
            if ui.historyLabel then
                ui.historyLabel:setName("Attempts: 0 / " .. tostring(ui.maxAttempts or 6))
            end
            ui:addToUIManager()
            currentHackUI = ui

        elseif gameType == 3 then
            if currentHackUI then
                currentHackUI:removeFromUIManager()
                currentHackUI = nil
            end
            local ui = Cat_HackMemoryUI:new(getCore():getScreenWidth() / 2 - 180, getCore():getScreenHeight() / 2 - 200, 360, 400)
            ui.cardName = args.cardName or ""
            ui.cardType = args.cardType or ""
            ui.sequence = args.sequence or {}
            ui.displayDuration = args.displayDuration or 600
            ui:initialise()
            ui:addToUIManager()
            currentHackUI = ui
        end

    elseif command == "hackFeedback" then
        -- Mastermind intermediate feedback
        if currentHackUI and currentHackUI.Type == "Cat_HackMastermindUI" then
            local ui = currentHackUI
            local guessCopy = {}
            if ui.lastSubmittedGuess then
                for i = 1, 4 do
                    guessCopy[i] = ui.lastSubmittedGuess[i]
                end
            end
            table.insert(ui.history, guessCopy)

            local greens = args.greens or 0
            local yellows = args.yellows or 0
            local attemptsUsed = args.attemptsUsed or 0
            local maxAttempts = args.maxAttempts or 6
            local feedback = args.feedback

            ui.attemptsUsed = attemptsUsed
            if ui.historyLabel then
                ui.historyLabel:setName("Attempts: " .. attemptsUsed .. " / " .. maxAttempts)
            end

            -- Update term button colours based on feedback
            if feedback and guessCopy then
                for i = 1, 4 do
                    local termIdx = guessCopy[i]
                    if termIdx then
                        local posFeedback = feedback[i]
                        if posFeedback == "green" then
                            ui.termStates[termIdx] = "green"
                        elseif posFeedback == "yellow" then
                            if ui.termStates[termIdx] ~= "green" then
                                ui.termStates[termIdx] = "yellow"
                            end
                        end
                    end
                end
                ui:updateTermButtonColors()
            end

            -- Build history text
            local rowText = ""
            for i = 1, 4 do
                if guessCopy[i] then
                    rowText = rowText .. HACK_TERMS[guessCopy[i] + 1]:sub(1, 2)
                else
                    rowText = rowText .. "??"
                end
                if i < 4 then rowText = rowText .. "." end
            end
            rowText = rowText .. "  G:" .. greens .. " Y:" .. yellows

            if ui.historyRows[attemptsUsed] then
                ui.historyRows[attemptsUsed]:setName(rowText)
            end

            ui.statusLabel:setName("Greens: " .. greens .. "  Yellows: " .. yellows)
        end

    elseif command == "hackResult" then
        if currentHackUI then
            if currentHackUI.Type == "Cat_HackTimingUI" then
                local ui = currentHackUI
                if args.success then
                    ui.statusLabel:setName(args.message or "Success!")
                    ui.statusLabel.r = 0.2
                    ui.statusLabel.g = 0.9
                    ui.statusLabel.b = 0.4
                else
                    ui.statusLabel:setName(args.error or "Decryption failed.")
                    ui.statusLabel.r = 1
                    ui.statusLabel.g = 0.2
                    ui.statusLabel.b = 0.2
                end
                ui.finished = true

            elseif currentHackUI.Type == "Cat_HackMastermindUI" then
                local ui = currentHackUI
                if args.success then
                    ui.statusLabel:setName(args.message or "Success!")
                    ui.statusLabel.r = 0.2
                    ui.statusLabel.g = 0.9
                    ui.statusLabel.b = 0.4
                else
                    ui.statusLabel:setName(args.error or "Decryption failed.")
                    ui.statusLabel.r = 1
                    ui.statusLabel.g = 0.2
                    ui.statusLabel.b = 0.2
                end
                ui.finished = true

            elseif currentHackUI.Type == "Cat_HackMemoryUI" then
                local ui = currentHackUI
                if args.success then
                    ui.statusLabel:setName(args.message or "Success!")
                    ui.statusLabel.r = 0.2
                    ui.statusLabel.g = 0.9
                    ui.statusLabel.b = 0.4
                else
                    ui.statusLabel:setName(args.error or "Decryption failed.")
                    ui.statusLabel.r = 1
                    ui.statusLabel.g = 0.2
                    ui.statusLabel.b = 0.2
                end
                ui.finished = true
            end
        end
    end
end
Events.OnServerCommand.Add(onServerCommand)

print("[Cat_BankingSystem Client] Hack UI loaded.")

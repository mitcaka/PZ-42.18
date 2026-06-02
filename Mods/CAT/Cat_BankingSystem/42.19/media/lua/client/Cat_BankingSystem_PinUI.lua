-- =============================================================================
-- Cat Banking System — PIN Entry UI
-- =============================================================================
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"

Cat_ATMPinUI = ISPanel:derive("Cat_ATMPinUI")

local MOD_NAME = "Cat_BankingSystem"
local currentPinUI = nil

local function playATMSound(soundName)
    local sm = getSoundManager()
    if sm and sm.PlaySound then
        sm:PlaySound(soundName, false, 1.0)
    end
end

function Cat_ATMPinUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.pin = ""
    o.playerNum = 0
    o.moveWithMouse = true
    o.mode = "bank"       -- "bank" or "creditCard"
    o.cardName = ""
    o.cardType = ""
    return o
end

function Cat_ATMPinUI:createChildren()
    ISPanel.createChildren(self)

    self.titleLabel = ISLabel:new(self.width / 2, 10, 20, "ENTER PIN", 1, 1, 1, 1, UIFont.Medium, true)
    self.titleLabel.center = true
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    self.pinLabel = ISLabel:new(self.width / 2, 45, 30, "", 0, 1, 0, 1, UIFont.Large, true)
    self.pinLabel.center = true
    self.pinLabel:initialise()
    self:addChild(self.pinLabel)

    self.pinDisplayLabel = ISLabel:new(self.width / 2, 78, 16, "", 1, 1, 0.5, 1, UIFont.Small, true)
    self.pinDisplayLabel.center = true
    self.pinDisplayLabel:initialise()
    self:addChild(self.pinDisplayLabel)

    local digits = {
        {1, 1, 1}, {2, 2, 1}, {3, 3, 1},
        {4, 1, 2}, {5, 2, 2}, {6, 3, 2},
        {7, 1, 3}, {8, 2, 3}, {9, 3, 3},
        {0, 2, 4},
    }

    local startX = self.width / 2 - 75
    local startY = 95

    for _, d in ipairs(digits) do
        local num, col, row = d[1], d[2], d[3]
        local btn = ISButton:new(startX + (col - 1) * 55, startY + (row - 1) * 45, 50, 40, tostring(num), self, self.onDigit)
        btn.internal = num
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
    end

    local clearBtn = ISButton:new(startX, startY + 4 * 45, 75, 35, "CLEAR", self, self.onClear)
    clearBtn:initialise()
    clearBtn:instantiate()
    self:addChild(clearBtn)

    local enterBtn = ISButton:new(startX + 80, startY + 4 * 45, 75, 35, "ENTER", self, self.onEnter)
    enterBtn.backgroundColor = { r = 0.2, g = 0.6, b = 0.2, a = 1 }
    enterBtn:initialise()
    enterBtn:instantiate()
    self:addChild(enterBtn)

    local closeBtn = ISButton:new(self.width / 2 - 40, self.height - 35, 80, 28, "CLOSE", self, self.onClose)
    closeBtn.backgroundColor = { r = 0.6, g = 0.2, b = 0.2, a = 1 }
    closeBtn:initialise()
    closeBtn:instantiate()
    self:addChild(closeBtn)
end

function Cat_ATMPinUI:updatePinDisplay()
    local display = ""
    for i = 1, #self.pin do
        display = display .. "*"
    end
    self.pinLabel:setName(display)
end

function Cat_ATMPinUI:onDigit(button)
    if #self.pin < 4 then
        self.pin = self.pin .. tostring(button.internal)
        self:updatePinDisplay()
        playATMSound("Cat_ATMButtonBeep")
    end
end

function Cat_ATMPinUI:onClear()
    self.pin = ""
    self:updatePinDisplay()
    playATMSound("Cat_ATMButtonBeep")
end

function Cat_ATMPinUI:onEnter()
    if #self.pin ~= 4 then return end
    playATMSound("Cat_ATMButtonBeep")
    if self.mode == "creditCard" then
        sendClientCommand(MOD_NAME, "authenticateCreditCard", {
            pin = self.pin,
            cardName = self.cardName,
            cardType = self.cardType,
        })
    else
        sendClientCommand(MOD_NAME, "authenticate", { pin = self.pin })
    end
end

function Cat_ATMPinUI:onClose()
    playATMSound("Cat_ATMErrorBeep")
    self:setVisible(false)
    self:removeFromUIManager()
    currentPinUI = nil
end

function Cat_ATMPinUI:setAccountInfo(hasAccount, pin)
    if self.mode == "creditCard" then
        self.titleLabel:setName("ENTER CARD PIN")
        self.pinDisplayLabel:setName(self.cardName)
        self.pinDisplayLabel.r = 0.8
        self.pinDisplayLabel.g = 0.8
        self.pinDisplayLabel.b = 0.8
        return
    end
    if hasAccount then
        self.titleLabel:setName("ENTER PIN")
        self.pinDisplayLabel:setName("Your PIN: " .. tostring(pin))
        self.pinDisplayLabel.r = 1
        self.pinDisplayLabel.g = 1
        self.pinDisplayLabel.b = 0.5
    else
        self.titleLabel:setName("CREATE PIN")
        self.pinDisplayLabel:setName("First time? Choose any 4 digits.")
        self.pinDisplayLabel.r = 0.6
        self.pinDisplayLabel.g = 0.8
        self.pinDisplayLabel.b = 1
    end
end

function Cat_ATMPinUI.Open(playerNum)
    if currentPinUI then
        currentPinUI:removeFromUIManager()
        currentPinUI = nil
    end

    local ui = Cat_ATMPinUI:new(getCore():getScreenWidth() / 2 - 125, getCore():getScreenHeight() / 2 - 175, 250, 355)
    ui.playerNum = playerNum
    ui.mode = "bank"
    ui:initialise()
    ui:addToUIManager()
    currentPinUI = ui

    -- Ask server whether we already have an account
    sendClientCommand(MOD_NAME, "checkAccount", {})
end

function Cat_ATMPinUI.OpenCreditCard(playerNum, cardName, cardType)
    if currentPinUI then
        currentPinUI:removeFromUIManager()
        currentPinUI = nil
    end

    local ui = Cat_ATMPinUI:new(getCore():getScreenWidth() / 2 - 125, getCore():getScreenHeight() / 2 - 175, 250, 355)
    ui.playerNum = playerNum
    ui.mode = "creditCard"
    ui.cardName = cardName
    ui.cardType = cardType
    ui:initialise()
    ui:addToUIManager()
    currentPinUI = ui

    ui:setAccountInfo(true, "")
end

-- ---------------------------------------------------------------------------
-- Server response handling
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= MOD_NAME then return end

    if command == "accountInfo" then
        if currentPinUI then
            currentPinUI:setAccountInfo(args.hasAccount, args.pin)
        end

    elseif command == "authResult" then
        if args.success then
            if currentPinUI then
                currentPinUI:setVisible(false)
                currentPinUI:removeFromUIManager()
                currentPinUI = nil
            end
            require "Cat_BankingSystem_BankUI"
            if args.mode == "creditCard" then
                Cat_ATMBankUI.OpenCreditCard(args.balance, args.cardName, args.cardType)
            else
                Cat_ATMBankUI.Open(args.balance)
            end
        else
            -- Show error
            playATMSound("Cat_ATMErrorBeep")
            if currentPinUI then
                currentPinUI.pin = ""
                currentPinUI:updatePinDisplay()
                currentPinUI.pinLabel:setName(args.error or "Wrong PIN")
                currentPinUI.pinLabel.r = 1
                currentPinUI.pinLabel.g = 0
                currentPinUI.pinLabel.b = 0
            end
        end
    end
end
Events.OnServerCommand.Add(onServerCommand)

print("[Cat_BankingSystem Client] PIN UI loaded.")

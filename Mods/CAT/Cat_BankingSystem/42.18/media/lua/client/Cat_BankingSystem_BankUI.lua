-- =============================================================================
-- Cat Banking System — Main Bank UI
-- =============================================================================
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"

Cat_ATMBankUI = ISPanel:derive("Cat_ATMBankUI")

local MOD_NAME = "Cat_BankingSystem"
local currentBankUI = nil

local function playATMSound(soundName)
    local sm = getSoundManager()
    if sm and sm.PlaySound then
        sm:PlaySound(soundName, false, 1.0)
    end
end

function Cat_ATMBankUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.balance = 0
    o.moveWithMouse = true
    o.mode = "bank"       -- "bank" or "creditCard"
    o.cardName = ""
    o.cardType = ""
    return o
end

function Cat_ATMBankUI:createChildren()
    ISPanel.createChildren(self)

    local titleText = (self.mode == "creditCard") and "CREDIT CARD" or "BANK ACCOUNT"
    local title = ISLabel:new(self.width / 2, 10, 20, titleText, 1, 1, 1, 1, UIFont.Medium, true)
    title.center = true
    title:initialise()
    self:addChild(title)

    self.balanceLabel = ISLabel:new(self.width / 2, 50, 30, "$0", 0, 1, 0, 1, UIFont.Large, true)
    self.balanceLabel.center = true
    self.balanceLabel:initialise()
    self:addChild(self.balanceLabel)

    local withdrawY = 95
    if self.mode ~= "creditCard" then
        local depositLabel = ISLabel:new(self.width / 2, 85, 20, "Deposit Amount:", 1, 1, 1, 1, UIFont.Small, true)
        depositLabel.center = true
        depositLabel:initialise()
        self:addChild(depositLabel)

        self.depositEntry = ISTextEntryBox:new("", self.width / 2 - 60, 105, 120, 25)
        self.depositEntry:initialise()
        self.depositEntry:instantiate()
        self:addChild(self.depositEntry)

        local depositBtn = ISButton:new(self.width / 2 - 100, 140, 200, 30, "DEPOSIT", self, self.onDeposit)
        depositBtn.backgroundColor = { r = 0.2, g = 0.6, b = 0.2, a = 1 }
        depositBtn:initialise()
        depositBtn:instantiate()
        self:addChild(depositBtn)

        local depositAllBtn = ISButton:new(self.width / 2 - 100, 180, 200, 30, "DEPOSIT ALL CASH", self, self.onDepositAll)
        depositAllBtn.backgroundColor = { r = 0.2, g = 0.5, b = 0.2, a = 1 }
        depositAllBtn:initialise()
        depositAllBtn:instantiate()
        self:addChild(depositAllBtn)

        withdrawY = 225
    else
        local cardNameLabel = ISLabel:new(self.width / 2, 80, 16, self.cardName or "", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
        cardNameLabel.center = true
        cardNameLabel:initialise()
        self:addChild(cardNameLabel)
    end

    local withdrawLabel = ISLabel:new(self.width / 2, withdrawY, 20, "Withdraw Amount:", 1, 1, 1, 1, UIFont.Small, true)
    withdrawLabel.center = true
    withdrawLabel:initialise()
    self:addChild(withdrawLabel)

    self.withdrawEntry = ISTextEntryBox:new("", self.width / 2 - 60, withdrawY + 20, 120, 25)
    self.withdrawEntry:initialise()
    self.withdrawEntry:instantiate()
    self:addChild(self.withdrawEntry)

    local withdrawBtn = ISButton:new(self.width / 2 - 100, withdrawY + 55, 200, 30, "WITHDRAW", self, self.onWithdraw)
    withdrawBtn.backgroundColor = { r = 0.2, g = 0.4, b = 0.6, a = 1 }
    withdrawBtn:initialise()
    withdrawBtn:instantiate()
    self:addChild(withdrawBtn)

    local closeBtn = ISButton:new(self.width / 2 - 40, withdrawY + 100, 80, 28, "CLOSE", self, self.onClose)
    closeBtn.backgroundColor = { r = 0.6, g = 0.2, b = 0.2, a = 1 }
    closeBtn:initialise()
    closeBtn:instantiate()
    self:addChild(closeBtn)

    self.statusLabel = ISLabel:new(self.width / 2, withdrawY + 145, 18, "", 1, 1, 1, 1, UIFont.Small, true)
    self.statusLabel.center = true
    self.statusLabel:initialise()
    self:addChild(self.statusLabel)
end

function Cat_ATMBankUI:setBalance(amount)
    self.balance = amount or 0
    self.balanceLabel:setName("$" .. tostring(self.balance))
end

function Cat_ATMBankUI:onDeposit()
    local text = self.depositEntry:getText()
    local amount = tonumber(text)
    if not amount or amount <= 0 then
        self.statusLabel:setName("Enter a valid amount.")
        playATMSound("Cat_ATMErrorBeep")
        return
    end
    amount = math.floor(amount)
    local player = getSpecificPlayer(0)
    if not player then return end
    local hasMoney = Cat_EconomyUtils.getMoneyCount(player)
    if amount > hasMoney then
        self.statusLabel:setName("Not enough cash.")
        playATMSound("Cat_ATMErrorBeep")
        return
    end
    playATMSound("Cat_ATMButtonBeep")
    sendClientCommand(MOD_NAME, "deposit", { amount = amount })
    self.depositEntry:setText("")
end

function Cat_ATMBankUI:onDepositAll()
    local player = getSpecificPlayer(0)
    if not player then return end
    local amount = Cat_EconomyUtils.getMoneyCount(player)
    if amount <= 0 then
        self.statusLabel:setName("No cash to deposit.")
        playATMSound("Cat_ATMErrorBeep")
        return
    end
    playATMSound("Cat_ATMButtonBeep")
    sendClientCommand(MOD_NAME, "deposit", { amount = amount })
end

function Cat_ATMBankUI:onWithdraw()
    local text = self.withdrawEntry:getText()
    local amount = tonumber(text)
    if not amount or amount <= 0 then
        self.statusLabel:setName("Enter a valid amount.")
        playATMSound("Cat_ATMErrorBeep")
        return
    end
    amount = math.floor(amount)
    if amount > self.balance then
        self.statusLabel:setName("Insufficient funds.")
        playATMSound("Cat_ATMErrorBeep")
        return
    end
    playATMSound("Cat_ATMButtonBeep")
    if self.mode == "creditCard" then
        sendClientCommand(MOD_NAME, "withdrawCreditCard", {
            amount = amount,
            cardName = self.cardName,
            cardType = self.cardType,
        })
    else
        sendClientCommand(MOD_NAME, "withdraw", { amount = amount })
    end
end

function Cat_ATMBankUI:onClose()
    playATMSound("Cat_ATMErrorBeep")
    self:setVisible(false)
    self:removeFromUIManager()
    currentBankUI = nil
end

function Cat_ATMBankUI.Open(balance)
    if currentBankUI then
        currentBankUI:removeFromUIManager()
        currentBankUI = nil
    end

    local ui = Cat_ATMBankUI:new(getCore():getScreenWidth() / 2 - 125, getCore():getScreenHeight() / 2 - 210, 250, 420)
    ui.mode = "bank"
    ui:initialise()
    ui:addToUIManager()
    ui:setBalance(balance)
    currentBankUI = ui
end

function Cat_ATMBankUI.OpenCreditCard(balance, cardName, cardType)
    if currentBankUI then
        currentBankUI:removeFromUIManager()
        currentBankUI = nil
    end

    local ui = Cat_ATMBankUI:new(getCore():getScreenWidth() / 2 - 125, getCore():getScreenHeight() / 2 - 160, 250, 320)
    ui.mode = "creditCard"
    ui.cardName = cardName or ""
    ui.cardType = cardType or ""
    ui:initialise()
    ui:addToUIManager()
    ui:setBalance(balance)
    currentBankUI = ui
end

-- ---------------------------------------------------------------------------
-- Server response handling
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= MOD_NAME then return end

    if command == "transactionResult" or command == "balanceUpdate" then
        if currentBankUI then
            currentBankUI:setBalance(args.balance)
            if args.message then
                currentBankUI.statusLabel:setName(args.message)
            elseif args.error then
                currentBankUI.statusLabel:setName(args.error)
            end
        end
    elseif command == "refreshInventory" then
        local invPage = getPlayerInventory(0)
        if invPage then
            invPage:refreshBackpacks()
        end
    end
end
Events.OnServerCommand.Add(onServerCommand)

print("[Cat_BankingSystem Client] Bank UI loaded.")

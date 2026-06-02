-- =============================================================================
-- Cat Vehicle Claim — Permissions UI
-- =============================================================================
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISTickBox"
require "ISUI/ISComboBox"

Cat_VehicleClaim = Cat_VehicleClaim or {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

Cat_VehicleClaimPermissionsUI = ISPanel:derive("Cat_VehicleClaimPermissionsUI")

function Cat_VehicleClaimPermissionsUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.moveWithMouse = true
    o.vehicleId = nil
    o.claim = nil
    return o
end

function Cat_VehicleClaimPermissionsUI:createChildren()
    ISPanel.createChildren(self)

    local x = UI_BORDER_SPACING + 1
    local y = UI_BORDER_SPACING + 1
    local w = self.width - (UI_BORDER_SPACING + 1) * 2

    -- Title
    self.titleLabel = ISLabel:new(x, y, FONT_HGT_SMALL, "Vehicle Permissions", 1, 1, 1, 1, UIFont.Small, true)
    self.titleLabel:initialise()
    self.titleLabel:instantiate()
    self:addChild(self.titleLabel)
    y = y + FONT_HGT_SMALL + 4

    -- My Vehicles button
    self.myVehiclesBtn = ISButton:new(x, y, w, BUTTON_HGT, "My Vehicles", self, self.onMyVehicles)
    self.myVehiclesBtn:initialise()
    self.myVehiclesBtn:instantiate()
    self:addChild(self.myVehiclesBtn)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    -- Owner
    self.ownerLabel = ISLabel:new(x, y, FONT_HGT_SMALL, "Owner: --", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.ownerLabel:initialise()
    self.ownerLabel:instantiate()
    self:addChild(self.ownerLabel)
    y = y + FONT_HGT_SMALL + UI_BORDER_SPACING

    -- Everyone permissions
    self.everyoneLabel = ISLabel:new(x, y, FONT_HGT_SMALL, "Everyone:", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.everyoneLabel:initialise()
    self.everyoneLabel:instantiate()
    self:addChild(self.everyoneLabel)
    y = y + FONT_HGT_SMALL + 4

    local tickW = 90
    local tickGap = 10
    local tickTotalW = tickW * 3 + tickGap * 2
    local tickStartX = x + math.floor((w - tickTotalW) / 2)

    self.everyonePassengerTick = ISTickBox:new(tickStartX, y, tickW, BUTTON_HGT, "", self, self.onEveryonePermChanged)
    self.everyonePassengerTick:initialise()
    self.everyonePassengerTick:addOption("Passenger")
    self:addChild(self.everyonePassengerTick)

    self.everyoneTrunkTick = ISTickBox:new(tickStartX + tickW + tickGap, y, tickW, BUTTON_HGT, "", self, self.onEveryonePermChanged)
    self.everyoneTrunkTick:initialise()
    self.everyoneTrunkTick:addOption("Trunk")
    self:addChild(self.everyoneTrunkTick)

    self.everyoneMechanicsTick = ISTickBox:new(tickStartX + (tickW + tickGap) * 2, y, tickW, BUTTON_HGT, "", self, self.onEveryonePermChanged)
    self.everyoneMechanicsTick:initialise()
    self.everyoneMechanicsTick:addOption("Mechanics")
    self:addChild(self.everyoneMechanicsTick)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    -- Guest list
    local listHgt = 120
    self.guestList = ISScrollingListBox:new(x, y, w, listHgt)
    self.guestList:initialise()
    self.guestList:instantiate()
    self.guestList:setFont("Small")
    self.guestList.selected = 0
    self.guestList:setOnMouseDownFunction(self, function(target, item)
        target:onSelectGuest()
    end)
    self:addChild(self.guestList)
    y = y + listHgt + UI_BORDER_SPACING

    -- Selected guest permissions
    self.guestPermsLabel = ISLabel:new(x, y, FONT_HGT_SMALL, "Selected Guest:", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.guestPermsLabel:initialise()
    self.guestPermsLabel:instantiate()
    self:addChild(self.guestPermsLabel)
    y = y + FONT_HGT_SMALL + 4

    self.passengerTick = ISTickBox:new(tickStartX, y, tickW, BUTTON_HGT, "", self, self.onGuestPermChanged)
    self.passengerTick:initialise()
    self.passengerTick:addOption("Passenger")
    self:addChild(self.passengerTick)

    self.trunkTick = ISTickBox:new(tickStartX + tickW + tickGap, y, tickW, BUTTON_HGT, "", self, self.onGuestPermChanged)
    self.trunkTick:initialise()
    self.trunkTick:addOption("Trunk")
    self:addChild(self.trunkTick)

    self.mechanicsTick = ISTickBox:new(tickStartX + (tickW + tickGap) * 2, y, tickW, BUTTON_HGT, "", self, self.onGuestPermChanged)
    self.mechanicsTick:initialise()
    self.mechanicsTick:addOption("Mechanics")
    self:addChild(self.mechanicsTick)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    -- Add guest (dropdown of online players)
    self.playerCombo = ISComboBox:new(x, y, w - 80 - 5, BUTTON_HGT, self, nil)
    self.playerCombo:initialise()
    self.playerCombo:instantiate()
    self.playerCombo.noSelectionText = "Select player..."
    self:addChild(self.playerCombo)

    self.addBtn = ISButton:new(x + w - 80, y, 80, BUTTON_HGT, "Add", self, self.onAddGuest)
    self.addBtn:initialise()
    self.addBtn:instantiate()
    self:addChild(self.addBtn)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    -- Remove selected
    self.removeBtn = ISButton:new(x, y, w, BUTTON_HGT, "Remove Selected Guest", self, self.onRemoveGuest)
    self.removeBtn:initialise()
    self.removeBtn:instantiate()
    self:addChild(self.removeBtn)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    -- Transfer ownership
    self.transferBtn = ISButton:new(x, y, w, BUTTON_HGT, "Transfer Ownership", self, self.onTransferClick)
    self.transferBtn:initialise()
    self.transferBtn:instantiate()
    self:addChild(self.transferBtn)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    -- Close
    self.closeBtn = ISButton:new(x, y, w, BUTTON_HGT, "Close", self, self.onClose)
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self:addChild(self.closeBtn)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    self:setHeight(y)
end

function Cat_VehicleClaimPermissionsUI:setVehicle(vehicle)
    self.vehicleId = Cat_VehicleClaim.getVehicleIdentifier(vehicle)
    self:refreshData()
end

function Cat_VehicleClaimPermissionsUI:setVehicleById(vehicleId)
    self.vehicleId = vehicleId
    self:refreshData()
end

function Cat_VehicleClaimPermissionsUI:populatePlayerCombo()
    self.playerCombo:clear()
    self.playerCombo:addOptionWithData("Select player...", nil)

    local players = getOnlinePlayers()
    if not players then return end

    local ownerName = self.claim and self.claim.owner or ""
    local added = false

    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            local username = player:getUsername()
            -- Skip owner and existing guests
            if username ~= ownerName and (not self.claim or not self.claim.guests or not self.claim.guests[username]) then
                self.playerCombo:addOptionWithData(username, username)
                added = true
            end
        end
    end

    if not added then
        self.playerCombo:addOptionWithData("(no eligible players)", nil)
    end
end

function Cat_VehicleClaimPermissionsUI:refreshData()
    self.claim = Cat_VehicleClaim.claims[self.vehicleId]
    if self.claim then
        self.ownerLabel:setName("Owner: " .. tostring(self.claim.owner))
    else
        self.ownerLabel:setName("Owner: --")
    end

    -- Everyone perms
    local everyone = self.claim and self.claim.everyone or {}
    self.everyonePassengerTick:setSelected(1, everyone.passenger == true)
    self.everyoneTrunkTick:setSelected(1, everyone.trunk == true)
    self.everyoneMechanicsTick:setSelected(1, everyone.mechanics == true)

    -- Guest list
    self.guestList:clear()
    if self.claim and self.claim.guests then
        for name, perms in pairs(self.claim.guests) do
            self.guestList:addItem(name, { name = name, perms = perms })
        end
    end
    self:populatePlayerCombo()
    self:onSelectGuest()
end

function Cat_VehicleClaimPermissionsUI:onSelectGuest()
    local item = self.guestList.items[self.guestList.selected]
    if item and item.item then
        local perms = item.item.perms
        self.passengerTick:setSelected(1, perms.passenger == true)
        self.trunkTick:setSelected(1, perms.trunk == true)
        self.mechanicsTick:setSelected(1, perms.mechanics == true)
        self.passengerTick.enable = true
        self.trunkTick.enable = true
        self.mechanicsTick.enable = true
        self.removeBtn:setEnable(true)
        self.guestPermsLabel:setName("Selected Guest: " .. item.item.name)
    else
        self.passengerTick:setSelected(1, false)
        self.trunkTick:setSelected(1, false)
        self.mechanicsTick:setSelected(1, false)
        self.passengerTick.enable = false
        self.trunkTick.enable = false
        self.mechanicsTick.enable = false
        self.removeBtn:setEnable(false)
        self.guestPermsLabel:setName("Selected Guest: --")
    end
end

function Cat_VehicleClaimPermissionsUI:onGuestPermChanged(index, selected)
    local item = self.guestList.items[self.guestList.selected]
    if not item or not item.item then return end
    sendClientCommand("Cat_VehicleClaim", "setGuestPermissions", {
        vehicleId = self.vehicleId,
        guestName = item.item.name,
        perms = {
            passenger = self.passengerTick:isSelected(1),
            trunk = self.trunkTick:isSelected(1),
            mechanics = self.mechanicsTick:isSelected(1),
        },
    })
end

function Cat_VehicleClaimPermissionsUI:onEveryonePermChanged(index, selected)
    sendClientCommand("Cat_VehicleClaim", "setEveryonePermissions", {
        vehicleId = self.vehicleId,
        perms = {
            passenger = self.everyonePassengerTick:isSelected(1),
            trunk = self.everyoneTrunkTick:isSelected(1),
            mechanics = self.everyoneMechanicsTick:isSelected(1),
        },
    })
end

function Cat_VehicleClaimPermissionsUI:onAddGuest()
    local selectedData = self.playerCombo:getOptionData(self.playerCombo.selected)
    if not selectedData then
        HaloTextHelper.addBadText(getSpecificPlayer(0), "Select a player from the list.")
        return
    end
    sendClientCommand("Cat_VehicleClaim", "addGuest", {
        vehicleId = self.vehicleId,
        guestName = selectedData,
    })
    self.playerCombo:setSelected(1)
end

function Cat_VehicleClaimPermissionsUI:onRemoveGuest()
    local item = self.guestList.items[self.guestList.selected]
    if not item or not item.item then return end
    sendClientCommand("Cat_VehicleClaim", "removeGuest", {
        vehicleId = self.vehicleId,
        guestName = item.item.name,
    })
end

function Cat_VehicleClaimPermissionsUI:onTransferClick()
    Cat_VehicleClaim.OpenTransferUIById(self.vehicleId)
end

function Cat_VehicleClaimPermissionsUI:onMyVehicles()
    Cat_VehicleClaim.OpenMyVehiclesUI()
end

function Cat_VehicleClaimPermissionsUI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    Cat_VehicleClaim._permissionsUI = nil
end

function Cat_VehicleClaimPermissionsUI:prerender()
    ISPanel.prerender(self)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

function Cat_VehicleClaim.OpenPermissionsUI(vehicle)
    if Cat_VehicleClaim._permissionsUI then
        Cat_VehicleClaim._permissionsUI:removeFromUIManager()
        Cat_VehicleClaim._permissionsUI = nil
    end
    local ui = Cat_VehicleClaimPermissionsUI:new(100, 100, 350, 420)
    ui:initialise()
    ui:addToUIManager()
    ui:setVehicle(vehicle)
    Cat_VehicleClaim._permissionsUI = ui
end

function Cat_VehicleClaim.OpenPermissionsUIById(vehicleId)
    if Cat_VehicleClaim._permissionsUI then
        Cat_VehicleClaim._permissionsUI:removeFromUIManager()
        Cat_VehicleClaim._permissionsUI = nil
    end
    local ui = Cat_VehicleClaimPermissionsUI:new(100, 100, 350, 420)
    ui:initialise()
    ui:addToUIManager()
    ui:setVehicleById(vehicleId)
    Cat_VehicleClaim._permissionsUI = ui
end

-- ============================================================================
-- Transfer Ownership UI
-- ============================================================================
Cat_VehicleClaimTransferUI = ISPanel:derive("Cat_VehicleClaimTransferUI")

function Cat_VehicleClaimTransferUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.moveWithMouse = true
    o.vehicleId = nil
    return o
end

function Cat_VehicleClaimTransferUI:createChildren()
    ISPanel.createChildren(self)

    local x = UI_BORDER_SPACING + 1
    local y = UI_BORDER_SPACING + 1
    local w = self.width - (UI_BORDER_SPACING + 1) * 2

    self.titleLabel = ISLabel:new(x, y, FONT_HGT_SMALL, "Transfer Ownership", 1, 1, 1, 1, UIFont.Small, true)
    self.titleLabel:initialise()
    self.titleLabel:instantiate()
    self:addChild(self.titleLabel)
    y = y + FONT_HGT_SMALL + UI_BORDER_SPACING

    self.nameEntry = ISTextEntryBox:new("", x, y, w, BUTTON_HGT)
    self.nameEntry:initialise()
    self.nameEntry:instantiate()
    self:addChild(self.nameEntry)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    self.transferBtn = ISButton:new(x, y, w, BUTTON_HGT, "Transfer", self, self.onTransfer)
    self.transferBtn:initialise()
    self.transferBtn:instantiate()
    self:addChild(self.transferBtn)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    self.cancelBtn = ISButton:new(x, y, w, BUTTON_HGT, "Cancel", self, self.onCancel)
    self.cancelBtn:initialise()
    self.cancelBtn:instantiate()
    self:addChild(self.cancelBtn)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    self:setHeight(y)
end

function Cat_VehicleClaimTransferUI:setVehicle(vehicle)
    self.vehicleId = Cat_VehicleClaim.getVehicleIdentifier(vehicle)
end

function Cat_VehicleClaimTransferUI:setVehicleById(vehicleId)
    self.vehicleId = vehicleId
end

function Cat_VehicleClaimTransferUI:onTransfer()
    local name = self.nameEntry:getText()
    if not name or name == "" then
        HaloTextHelper.addBadText(getSpecificPlayer(0), "Enter a valid username.")
        return
    end
    sendClientCommand("Cat_VehicleClaim", "transferOwnership", {
        vehicleId = self.vehicleId,
        newOwner = name,
    })
    self:onCancel()
end

function Cat_VehicleClaimTransferUI:onCancel()
    self:setVisible(false)
    self:removeFromUIManager()
    Cat_VehicleClaim._transferUI = nil
end

function Cat_VehicleClaimTransferUI:prerender()
    ISPanel.prerender(self)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

function Cat_VehicleClaim.OpenTransferUI(vehicle)
    if Cat_VehicleClaim._transferUI then
        Cat_VehicleClaim._transferUI:removeFromUIManager()
        Cat_VehicleClaim._transferUI = nil
    end
    local ui = Cat_VehicleClaimTransferUI:new(100, 100, 300, 180)
    ui:initialise()
    ui:addToUIManager()
    ui:setVehicle(vehicle)
    Cat_VehicleClaim._transferUI = ui
end

function Cat_VehicleClaim.OpenTransferUIById(vehicleId)
    if Cat_VehicleClaim._transferUI then
        Cat_VehicleClaim._transferUI:removeFromUIManager()
        Cat_VehicleClaim._transferUI = nil
    end
    local ui = Cat_VehicleClaimTransferUI:new(100, 100, 300, 180)
    ui:initialise()
    ui:addToUIManager()
    ui:setVehicleById(vehicleId)
    Cat_VehicleClaim._transferUI = ui
end

print("[Cat_VehicleClaim] Permissions UI loaded.")

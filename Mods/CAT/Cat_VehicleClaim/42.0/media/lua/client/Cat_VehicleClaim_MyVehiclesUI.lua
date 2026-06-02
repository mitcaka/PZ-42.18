-- =============================================================================
-- Cat Vehicle Claim — My Vehicles UI (combined vehicle list + permissions)
-- =============================================================================
if isServer() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISScrollingListBox"

Cat_VehicleClaim = Cat_VehicleClaim or {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

Cat_VehicleClaimMyVehiclesUI = ISPanel:derive("Cat_VehicleClaimMyVehiclesUI")

function Cat_VehicleClaimMyVehiclesUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.moveWithMouse = true
    return o
end

function Cat_VehicleClaimMyVehiclesUI:createChildren()
    ISPanel.createChildren(self)

    local pad = UI_BORDER_SPACING + 1
    local listW = 320

    -- Title
    self.titleLabel = ISLabel:new(pad, pad, FONT_HGT_SMALL, "My Claimed Vehicles", 1, 1, 1, 1, UIFont.Small, true)
    self.titleLabel:initialise()
    self.titleLabel:instantiate()
    self:addChild(self.titleLabel)

    -- Vehicle list
    local listY = pad + FONT_HGT_SMALL + UI_BORDER_SPACING
    local listH = self.height - listY - pad - BUTTON_HGT - UI_BORDER_SPACING

    self.vehicleList = ISScrollingListBox:new(pad, listY, listW, listH)
    self.vehicleList:initialise()
    self.vehicleList:instantiate()
    self.vehicleList:setFont("Small")
    self.vehicleList.selected = 0
    self.vehicleList:setOnMouseDownFunction(self, function(target, item)
        target:onSelectVehicle()
    end)
    self:addChild(self.vehicleList)

    -- Permissions panel (embedded existing UI)
    local permX = pad + listW + UI_BORDER_SPACING
    local permY = listY
    local permW = self.width - permX - pad
    local permH = listH

    self.permPanel = Cat_VehicleClaimPermissionsUI:new(permX, permY, permW, permH)
    self.permPanel:initialise()
    self:addChild(self.permPanel)
    -- Hide the close and My Vehicles buttons since the parent panel handles them
    if self.permPanel.closeBtn then
        self.permPanel.closeBtn:setVisible(false)
    end
    if self.permPanel.myVehiclesBtn then
        self.permPanel.myVehiclesBtn:setVisible(false)
    end
    -- Override onClose so it doesn't hide the embedded panel
    self.permPanel.onClose = function(panel)
        -- no-op: parent manages visibility
    end

    -- Close button at the bottom
    self.closeBtn = ISButton:new(pad, self.height - pad - BUTTON_HGT, self.width - pad * 2, BUTTON_HGT, "Close", self, self.onClose)
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self:addChild(self.closeBtn)

    self:refreshData()
end

local function countGuests(guests)
    local n = 0
    if guests then
        for _ in pairs(guests) do n = n + 1 end
    end
    return n
end

local function formatVehicleRow(vehicleId, claim)
    local name = claim.name
    if not name or name == "" then
        name = vehicleId
        if name:sub(1, 4) == "key_" then
            name = "#" .. name:sub(5)
        elseif name:sub(1, 3) == "id_" then
            name = "ID " .. name:sub(4)
        end
    end
    return name
end

function Cat_VehicleClaimMyVehiclesUI:refreshData()
    self.vehicleList:clear()
    local player = getSpecificPlayer(0)
    if not player then return end
    local username = player:getUsername()

    for vehicleId, claim in pairs(Cat_VehicleClaim.claims) do
        if claim and claim.owner == username then
            local text = formatVehicleRow(vehicleId, claim)
            self.vehicleList:addItem(text, { vehicleId = vehicleId, claim = claim })
        end
    end

    if self.vehicleList.selected > #self.vehicleList.items then
        self.vehicleList.selected = #self.vehicleList.items
    end
    self:onSelectVehicle()
end

function Cat_VehicleClaimMyVehiclesUI:onSelectVehicle()
    local item = self.vehicleList.items[self.vehicleList.selected]
    if item and item.item then
        self.permPanel:setVehicleById(item.item.vehicleId)
    else
        self.permPanel:setVehicleById(nil)
    end
end

function Cat_VehicleClaimMyVehiclesUI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    Cat_VehicleClaim._myVehiclesUI = nil
end

function Cat_VehicleClaimMyVehiclesUI:prerender()
    ISPanel.prerender(self)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

function Cat_VehicleClaim.OpenMyVehiclesUI()
    if Cat_VehicleClaim._myVehiclesUI then
        Cat_VehicleClaim._myVehiclesUI:removeFromUIManager()
        Cat_VehicleClaim._myVehiclesUI = nil
    end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local ui = Cat_VehicleClaimMyVehiclesUI:new(sw / 2 - 430, sh / 2 - 280, 860, 560)
    ui:initialise()
    ui:addToUIManager()
    Cat_VehicleClaim._myVehiclesUI = ui
end

print("[Cat_VehicleClaim] My Vehicles UI loaded.")

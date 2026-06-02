-- @author Risky
-- Custom buttons for UI on windows/panels

require "ISUI/ISButton"
require "ISUI/ISPanel"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISUpgradeWeapon"
require "TimedActions/ISRemoveWeaponUpgrade"
require "FWP_UIScale"

local function FWPInspectButtonUIV(value)
    return FWPUIScale and FWPUIScale.value(value) or math.floor((tonumber(value) or 0) + 0.5)
end

function FWPInspectPredicateNotBroken(item)
	return not item:isBroken()
end
function FWPInspectQueueWeaponUpgrade(character, weapon, part)
    if character == nil or weapon == nil or part == nil then
        return
    end

    ISInventoryPaneContextMenu.transferIfNeeded(character, weapon)
    ISInventoryPaneContextMenu.transferIfNeeded(character, part)
    ISInventoryPaneContextMenu.equipWeapon(part, false, false, character:getPlayerNum())

    local screwdriver = character:getInventory():getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, FWPInspectPredicateNotBroken)
    if screwdriver then
        ISInventoryPaneContextMenu.equipWeapon(screwdriver, true, false, character:getPlayerNum())
    end

    ISTimedActionQueue.add(ISUpgradeWeapon:new(character, weapon, part))
end

function FWPInspectQueueWeaponUpgradeRemoval(character, weapon, part)
    if character == nil or weapon == nil or part == nil then
        return
    end

    ISInventoryPaneContextMenu.transferIfNeeded(character, weapon)

    local screwdriver = character:getInventory():getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, FWPInspectPredicateNotBroken)
    if screwdriver then
        ISInventoryPaneContextMenu.equipWeapon(screwdriver, true, false, character:getPlayerNum())
    end

    ISTimedActionQueue.add(ISRemoveWeaponUpgrade:new(character, weapon, part:getPartType()))
end

function FWPInspectTrimText(text, font, maxWidth)
    if text == nil then
        return ""
    end

    text = tostring(text)
    if getTextManager():MeasureStringX(font, text) <= maxWidth then
        return text
    end

    local suffix = "..."
    local suffixWidth = getTextManager():MeasureStringX(font, suffix)
    while string.len(text) > 0 and getTextManager():MeasureStringX(font, text) + suffixWidth > maxWidth do
        text = string.sub(text, 1, -2)
    end

    return text .. suffix
end

FWPInspectAttachmentTooltip = ISPanel:derive("FWPInspectAttachmentTooltip")

function FWPInspectAttachmentTooltip:new(item, state, owner)
    local o = ISPanel:new(0, 0, FWPInspectButtonUIV(360), FWPInspectButtonUIV(174))
    setmetatable(o, self)
    self.__index = self

    o.item = item
    o.owner = owner
    o.state = state
    o.followMouse = true
    o.backgroundColor = {r=0.03, g=0.03, b=0.03, a=0.92}
    o.borderColor = {r=0.8, g=0.8, b=0.8, a=0.8}
    o:setVisible(false)

    return o
end

function FWPInspectAttachmentTooltip:ownerIsVisible()
    if self.owner == nil then
        return false
    end

    if self.owner.getIsVisible then
        local ok, visible = pcall(function()
            return self.owner:getIsVisible()
        end)
        if ok and not visible then
            return false
        end
    end

    local parent = self.owner.parent
    if parent ~= nil and parent.getIsVisible then
        local ok, visible = pcall(function()
            return parent:getIsVisible()
        end)
        if ok and not visible then
            return false
        end
    end

    if self.owner.isMouseOver and not self.owner:isMouseOver() and not self.owner.isJoypadFocused then
        return false
    end

    return true
end

function FWPInspectAttachmentTooltip:prerender()
    if not self:ownerIsVisible() then
        self:setVisible(false)
        return
    end

    if self.followMouse then
        local x = getMouseX() + FWPInspectButtonUIV(24)
        local y = getMouseY() + FWPInspectButtonUIV(24)
        local maxX = getCore():getScreenWidth() - self.width - FWPInspectButtonUIV(4)
        local maxY = getCore():getScreenHeight() - self.height - FWPInspectButtonUIV(4)
        self:setX(math.max(FWPInspectButtonUIV(4), math.min(x, maxX)))
        self:setY(math.max(FWPInspectButtonUIV(4), math.min(y, maxY)))
    end

    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

function FWPInspectCloseAttachmentButtonTooltip(button)
    if button ~= nil and button.toolTip ~= nil then
        button.toolTip:setVisible(false)
        button.toolTip:removeFromUIManager()
        button.toolTip = nil
    end
end

function FWPInspectAttachmentTooltip:render()
    if self.item == nil then
        return
    end

    local texture = self.item:getTexture()
    if texture then
        self:drawTextureScaled(texture, FWPInspectButtonUIV(8), FWPInspectButtonUIV(8), FWPInspectButtonUIV(32), FWPInspectButtonUIV(32), 1.0, 1.0, 1.0, 1.0)
    end

    local name = self.item:getDisplayName()
    local partType = ""
    if self.item.getPartType then
        partType = tostring(self.item:getPartType() or "")
    end

    local status = "Compatible - not in inventory"
    if self.state == "installed" then
        status = "Double-click to detach"
    elseif self.state == "available" then
        status = "Click to attach"
    end

    self:drawText(FWPInspectTrimText(name, UIFont.Small, self.width - FWPInspectButtonUIV(58)), FWPInspectButtonUIV(48), FWPInspectButtonUIV(10), 1.0, 1.0, 1.0, 1.0, UIFont.Small)
    self:drawText("Part: " .. FWPInspectTrimText(partType, UIFont.Small, self.width - FWPInspectButtonUIV(84)), FWPInspectButtonUIV(48), FWPInspectButtonUIV(30), 0.86, 0.86, 0.86, 1.0, UIFont.Small)
    self:drawText(FWPInspectTrimText(status, UIFont.Small, self.width - FWPInspectButtonUIV(58)), FWPInspectButtonUIV(48), FWPInspectButtonUIV(50), 0.7, 0.88, 1.0, 1.0, UIFont.Small)
    if FWPInspectDrawAttachmentStatLines then
        FWPInspectDrawAttachmentStatLines(self, self.item, FWPInspectButtonUIV(48), FWPInspectButtonUIV(72), self.width - FWPInspectButtonUIV(58))
    end
end

FWPInspectActiveAttachmentPane = FWPInspectActiveAttachmentPane or {}

function FWPInspectShowAttachmentPaneForButton(button, joypadFocus)
    if button == nil or button.slotItem ~= nil or button.character == nil then
        return nil
    end

    local playerNum = button.character:getPlayerNum()
    local existing = FWPInspectActiveAttachmentPane[playerNum]
    if existing ~= nil and existing:getIsVisible() and existing.originButton == button then
        if joypadFocus then
            setJoypadFocus(playerNum, existing)
        end
        return existing
    end

    if existing ~= nil and existing:getIsVisible() then
        existing:close()
    end

    local window = FWPInspectWindow[playerNum]
    if window == nil then
        return nil
    end

    local pane = FWPInspectSelectAttachmentPane:new(window:getX() + button:getX() + FWPInspectButtonUIV(43), window:getY() + button:getY() - FWPInspectButtonUIV(3), button.attachmentType, button.character)
    pane.originButton = button
    pane:addToUIManager()
    pane:bringToTop()
    pane:renderInventory()
    if FWPUIScale and FWPUIScale.clampToScreen then
        FWPUIScale.clampToScreen(pane, 8)
    end
    FWPInspectActiveAttachmentPane[playerNum] = pane

    if joypadFocus then
        setJoypadFocus(playerNum, pane)
    end

    return pane
end

FWPInspectAmmoButton = ISButton:derive("FWPInspectAmmoButton")

function FWPInspectAmmoButton:new (x, y, w, h, slotItem, stackAmount)
    local o = {}
    o = ISButton:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.stackAmount = stackAmount

    o.currentTint = ImmutableColor.new(1.0, 1.0, 1.0, 1.0)

    o.borderColor.r = 0.0
    o.borderColor.g = 0.0
    o.borderColor.b = 0.0
    o.borderColor.a = 0.0

    o.backgroundColor.r = 0.5
    o.backgroundColor.g = 0.5
    o.backgroundColor.b = 0.5
    o.backgroundColor.a = 0.3

    o.backgroundColorMouseOver.r = 0.5
    o.backgroundColorMouseOver.g = 0.5
    o.backgroundColorMouseOver.b = 0.5
    o.backgroundColorMouseOver.a = 0.3

    if slotItem then
        o.backgroundColorMouseOver.a = 0.8
        o.toolTip = ISToolTipInv:new(slotItem)
        o.toolTip:setOwner(o)
        o.toolTip:setVisible(false)
        o.toolTip:addToUIManager()

        -- Texture related
        o:setImage(slotItem:getTexture())
        
        local visual = slotItem:getVisual()
        o.tint = nil
        if visual then
            o.tint = visual:getTint(slotItem:getClothingItem())
            o.currentTint = visual:getTint(slotItem:getClothingItem())
        end

        if o.tint ~= nil then
            o:setTextureRGBA(o.tint:getRedFloat(), o.tint:getGreenFloat(), o.tint:getBlueFloat(), 1.0)
        end
        
        o.slotItem = slotItem
    end

    o:bringToTop();

    return o
end

function FWPInspectAmmoButton:render()
    ISButton.render(self)

    if self.slotItem then
        self:drawText(tostring(self.stackAmount), FWPInspectButtonUIV(4), 0, 1.0, 1.0, 1.0, 1.0)

        -- Texture related
        self:setImage(self.slotItem:getTexture())

        if self.currentTint ~= nil then
            self:setTextureRGBA(self.currentTint:getRedFloat(), self.currentTint:getGreenFloat(), self.currentTint:getBlueFloat(), self.currentTint:getAlphaFloat())
        end

        if self:isMouseOver() then
            self.toolTip:setVisible(true)
            self.toolTip:bringToTop()
        else
            self.toolTip:setVisible(false)
        end
    end
end

function FWPInspectAmmoButton:close()
    ISButton.close(self)
    self.toolTip:setVisible(false)
    self.toolTip:removeFromUIManager()
end

-- Attachment Button

FWPInspectAttachmentButton = ISButton:derive("FWPInspectAttachmentButton")

function FWPInspectAttachmentButton:new (x, y, w, h, slotItem, attachingTo, attachmentType, character)
    local o = {}
    o = ISButton:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.currentTint = ImmutableColor.new(1.0, 1.0, 1.0, 1.0)

    o.borderColor.r = 0.0
    o.borderColor.g = 0.0
    o.borderColor.b = 0.0
    o.borderColor.a = 0.0

    o.backgroundColor.r = 0.5
    o.backgroundColor.g = 0.5
    o.backgroundColor.b = 0.5
    o.backgroundColor.a = 0.3

    o.backgroundColorMouseOver.r = 0.5
    o.backgroundColorMouseOver.g = 0.5
    o.backgroundColorMouseOver.b = 0.5
    o.backgroundColorMouseOver.a = 0.8

    o.attachingTo = attachingTo
    o.attachmentType = attachmentType
    o.character = character

    if slotItem then
        o.toolTip = FWPInspectAttachmentTooltip:new(slotItem, "installed", o)
        o.toolTip:addToUIManager()

        -- Texture related
        o:setImage(slotItem:getTexture())
        
        local visual = slotItem:getVisual()
        o.tint = nil
        if visual then
            o.tint = visual:getTint(slotItem:getClothingItem())
            o.currentTint = visual:getTint(slotItem:getClothingItem())
        end

        if o.tint ~= nil then
            o:setTextureRGBA(o.tint:getRedFloat(), o.tint:getGreenFloat(), o.tint:getBlueFloat(), 1.0)
        end
        
        o.slotItem = slotItem
    end

    o:bringToTop();

    -- Joypad
    o.isJoypadFocused = false

    return o
end

function FWPInspectAttachmentButton:render()
    ISButton.render(self)

    if self:isMouseOver() == false then
        if self.isJoypadFocused then
            self.backgroundColor.a = 0.8
            if self.slotItem then
                self.toolTip.followMouse = false
                self.toolTip:setX(FWPInspectButtonUIV(80))
                self.toolTip:setY(FWPInspectButtonUIV(30))
                self.toolTip:setVisible(true)
                self.toolTip:bringToTop()
            end
        else
            self.backgroundColor.a = 0.3
            if self.slotItem then
                self.toolTip.followMouse = false
                self.toolTip:setVisible(false)
            end
        end
    end

    if self.slotItem == nil and self:isMouseOver() then
        FWPInspectShowAttachmentPaneForButton(self, false)
    end

    if self.slotItem then
        -- Texture related
        self:setImage(self.slotItem:getTexture())

        if self.currentTint ~= nil then
            self:setTextureRGBA(self.currentTint:getRedFloat(), self.currentTint:getGreenFloat(), self.currentTint:getBlueFloat(), self.currentTint:getAlphaFloat())
        end

        if not self.isJoypadFocused then
            if self:isMouseOver() then
                self.toolTip.followMouse = true
                self.toolTip:setVisible(true)
                self.toolTip:bringToTop()
            else
                self.toolTip.followMouse = true
                self.toolTip:setVisible(false)
            end
        end
    end
end

function FWPInspectAttachmentButton:onMouseDoubleClick()
    if self.slotItem then
        FWPInspectQueueWeaponUpgradeRemoval(self.character, self.attachingTo, self.slotItem)
    end
end

function FWPInspectAttachmentButton:onMouseUp()
    if self.slotItem == nil then
        FWPInspectShowAttachmentPaneForButton(self, false)
    end
end

function FWPInspectAttachmentButton:joypadConfirm()
    if self.slotItem then
        FWPInspectQueueWeaponUpgradeRemoval(self.character, self.attachingTo, self.slotItem)
    else
        FWPInspectShowAttachmentPaneForButton(self, true)
    end
end

function FWPInspectAttachmentButton:joypadPrompt()
    if self.slotItem then
        return getText('IGUI_FWP_INSPECT_DETACH')
    else
        return getText('IGUI_FWP_INSPECT_ATTACH')
    end
end

function FWPInspectAttachmentButton:close()
    ISButton.close(self)
    FWPInspectCloseAttachmentButtonTooltip(self)
end

-- Add Attachment Button

FWPInspectAddAttachmentButton = ISButton:derive("FWPInspectAddAttachmentButton")

function FWPInspectAddAttachmentButton:new (x, y, w, h, slotItem, attachingTo, enabled, container, character)
    local o = {}
    o = ISButton:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.enabled = enabled
    o.character = character
    o.container = container

    o.borderColor.r = 0.0
    o.borderColor.g = 0.0
    o.borderColor.b = 0.0
    o.borderColor.a = 0.0

    o.backgroundColor.r = 0.5
    o.backgroundColor.g = 0.5
    o.backgroundColor.b = 0.5
    o.backgroundColor.a = 0.3

    o.backgroundColorMouseOver.r = 0.5
    o.backgroundColorMouseOver.g = 0.5
    o.backgroundColorMouseOver.b = 0.5

    if enabled then
        o.backgroundColorMouseOver.a = 0.8
        o.currentTint = ImmutableColor.new(1.0, 1.0, 1.0, 1.0)
    else
        o.backgroundColorMouseOver.a = 0.3
        o.currentTint = ImmutableColor.new(1.0, 1.0, 1.0, 0.3)
    end

    o.attachingTo = attachingTo
    o.isJoypadFocused = false

    if slotItem then
        o.toolTip = FWPInspectAttachmentTooltip:new(slotItem, enabled and "available" or "potential", o)
        o.toolTip:addToUIManager()

        -- Texture related
        o:setImage(slotItem:getTexture())
        
        local visual = slotItem:getVisual()
        o.tint = nil
        if visual then
            o.tint = visual:getTint(slotItem:getClothingItem())
            o.currentTint = visual:getTint(slotItem:getClothingItem())

            if not enabled then
                o.currentTint.a = 0.3
            end
        end

        if o.tint ~= nil then
            if enabled then
                o:setTextureRGBA(o.tint:getRedFloat(), o.tint:getGreenFloat(), o.tint:getBlueFloat(), 1.0)
            else
                o:setTextureRGBA(o.tint:getRedFloat(), o.tint:getGreenFloat(), o.tint:getBlueFloat(), 0.3)
            end
        end
        
        o.slotItem = slotItem
    end

    o:bringToTop();

    return o
end

function FWPInspectAddAttachmentButton:render()
    ISButton.render(self)

    if self:isMouseOver() == false then
        if self.isJoypadFocused then
            self.backgroundColor.a = 0.8
            if self.slotItem then
                self.toolTip.followMouse = false
                self.toolTip:setX(FWPInspectButtonUIV(80))
                self.toolTip:setY(FWPInspectButtonUIV(30))
                self.toolTip:setVisible(true)
                self.toolTip:bringToTop()
            end
        else
            self.backgroundColor.a = 0.3
            if self.slotItem then
                self.toolTip.followMouse = false
                self.toolTip:setVisible(false)
            end
        end
    end

    if self.slotItem then
        -- Texture related
        self:setImage(self.slotItem:getTexture())

        if self.currentTint ~= nil then
            self:setTextureRGBA(self.currentTint:getRedFloat(), self.currentTint:getGreenFloat(), self.currentTint:getBlueFloat(), self.currentTint:getAlphaFloat())
        end

        if not self.isJoypadFocused then
            if self:isMouseOver() then
                self.toolTip.followMouse = true
                self.toolTip:setVisible(true)
                self.toolTip:bringToTop()
            else
                self.toolTip.followMouse = true
                self.toolTip:setVisible(false)
            end
        end
    end
end

function FWPInspectAddAttachmentButton:onMouseDown()
    if self.slotItem and self.enabled then
        local screwdriver = self.character:getInventory():getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, FWPInspectPredicateNotBroken)
        if screwdriver then
            FWPInspectQueueWeaponUpgrade(self.character, self.attachingTo, self.slotItem)
        end
    end
end

function FWPInspectAddAttachmentButton:close()
    ISButton.close(self)
    FWPInspectCloseAttachmentButtonTooltip(self)
end

function FWPInspectAddAttachmentButton:joypadConfirm()
    if self.slotItem and self.enabled then
        local screwdriver = self.character:getInventory():getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, FWPInspectPredicateNotBroken)
        if screwdriver then
            FWPInspectQueueWeaponUpgrade(self.character, self.attachingTo, self.slotItem)
        end
    end
end

function FWPInspectAddAttachmentButton:joypadPrompt()
    if self.slotItem and self.enabled then
        return getText('IGUI_FWP_INSPECT_ATTACH')
    else
        return nil
    end
end

-- Magazine Button

FWPInspectMagazineButton = ISButton:derive("FWPInspectMagazineButton")

function FWPInspectMagazineButton:new (x, y, w, h, slotItem, attachingTo, character)
    local o = {}
    o = ISButton:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.character = character

    o.currentTint = ImmutableColor.new(1.0, 1.0, 1.0, 1.0)

    o.borderColor.r = 0.0
    o.borderColor.g = 0.0
    o.borderColor.b = 0.0
    o.borderColor.a = 0.0

    o.backgroundColor.r = 0.5
    o.backgroundColor.g = 0.5
    o.backgroundColor.b = 0.5
    o.backgroundColor.a = 0.3

    o.backgroundColorMouseOver.r = 0.5
    o.backgroundColorMouseOver.g = 0.5
    o.backgroundColorMouseOver.b = 0.5
    o.backgroundColorMouseOver.a = 0.8

    o.attachingTo = attachingTo

    o.isJoypadFocused = false

    if slotItem then
        o.toolTip = ISToolTipInv:new(slotItem)
        o.toolTip:setOwner(o)
        o.toolTip:setVisible(false)
        o.toolTip:addToUIManager()

        -- Texture related
        o:setImage(slotItem:getTexture())
        
        local visual = slotItem:getVisual()
        o.tint = nil
        if visual then
            o.tint = visual:getTint(slotItem:getClothingItem())
            o.currentTint = visual:getTint(slotItem:getClothingItem())
        end

        if o.tint ~= nil then
            o:setTextureRGBA(o.tint:getRedFloat(), o.tint:getGreenFloat(), o.tint:getBlueFloat(), o.tint:getAlphaFloat())
        end
        
        o.slotItem = slotItem
    end

    o:bringToTop();

    return o
end

function FWPInspectMagazineButton:render()
    ISButton.render(self)

    if self:isMouseOver() == false then
        if self.isJoypadFocused then
            self.backgroundColor.a = 0.8
            if self.slotItem then
                self.toolTip.followMouse = false
                self.toolTip:setX(FWPInspectButtonUIV(80))
                self.toolTip:setY(FWPInspectButtonUIV(30))
                self.toolTip:setVisible(true)
                self.toolTip:bringToTop()
            end
        else
            self.backgroundColor.a = 0.3
            if self.slotItem then
                self.toolTip.followMouse = false
                self.toolTip:setVisible(false)
            end
        end
    end

    if self.slotItem then
        self:drawText(tostring(self.attachingTo:getCurrentAmmoCount()), FWPInspectButtonUIV(4), 0, 1.0, 1.0, 1.0, 1.0)

        -- Texture related
        self:setImage(self.slotItem:getTexture())

        if self.currentTint ~= nil then
            self:setTextureRGBA(self.currentTint:getRedFloat(), self.currentTint:getGreenFloat(), self.currentTint:getBlueFloat(), self.currentTint:getAlphaFloat())
        end

        if not self.isJoypadFocused then
            if self:isMouseOver() then
                self.toolTip.followMouse = true
                self.toolTip:setVisible(true)
                self.toolTip:bringToTop()
            else
                self.toolTip.followMouse = true
                self.toolTip:setVisible(false)
            end
        end
    end
end

function FWPInspectMagazineButton:onMouseDoubleClick()
    if self.slotItem then
        ISTimedActionQueue.add(ISEjectMagazine:new(self.character, self.attachingTo))
    end
end

function FWPInspectMagazineButton:onMouseUp()
    if self.slotItem == nil then
        local pane = FWPInspectSelectMagazinePane:new(FWPInspectWindow[self.character:getPlayerNum()]:getX() + self:getX() + FWPInspectButtonUIV(43), FWPInspectWindow[self.character:getPlayerNum()]:getY() + self:getY() - FWPInspectButtonUIV(3), self.attachingTo, self.character)
        pane:addToUIManager()
        pane:bringToTop()
        pane:renderInventory()
        if FWPUIScale and FWPUIScale.clampToScreen then
            FWPUIScale.clampToScreen(pane, 8)
        end
    end
end

function FWPInspectMagazineButton:close()
    ISButton.close(self)
    self.toolTip:setVisible(false)
    self.toolTip:removeFromUIManager()
end

function FWPInspectMagazineButton:joypadConfirm()
    if self.slotItem then
        ISTimedActionQueue.add(ISEjectMagazine:new(self.character, self.attachingTo))
    else
        local pane = FWPInspectSelectMagazinePane:new(FWPInspectWindow[self.character:getPlayerNum()]:getX() + self:getX() + FWPInspectButtonUIV(43), FWPInspectWindow[self.character:getPlayerNum()]:getY() + self:getY() - FWPInspectButtonUIV(3), self.attachingTo, self.character)
        pane:addToUIManager()
        pane:bringToTop()
        pane:renderInventory()
        if FWPUIScale and FWPUIScale.clampToScreen then
            FWPUIScale.clampToScreen(pane, 8)
        end

        setJoypadFocus(self.character:getPlayerNum(), pane)
    end
end

function FWPInspectMagazineButton:joypadPrompt()
    if self.slotItem then
        return getText('IGUI_FWP_INSPECT_EJECT')
    else
        return getText('IGUI_FWP_INSPECT_ATTACH')
    end
end

-- Add Magazine Button

FWPInspectAddMagazineButton = ISButton:derive("FWPInspectAddMagazineButton")

function FWPInspectAddMagazineButton:new (x, y, w, h, slotItem, attachingTo, origin, container, character)
    local o = {}
    o = ISButton:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.character = character
    o.container = container

    o.borderColor.r = 0.0
    o.borderColor.g = 0.0
    o.borderColor.b = 0.0
    o.borderColor.a = 0.0

    o.backgroundColor.r = 0.5
    o.backgroundColor.g = 0.5
    o.backgroundColor.b = 0.5
    o.backgroundColor.a = 0.3

    o.backgroundColorMouseOver.r = 0.5
    o.backgroundColorMouseOver.g = 0.5
    o.backgroundColorMouseOver.b = 0.5

    o.backgroundColorMouseOver.a = 0.8
    o.currentTint = ImmutableColor.new(1.0, 1.0, 1.0, 1.0)

    o.attachingTo = attachingTo
    o.isJoypadFocused = false
    o.origin = origin

    if slotItem then
        o.toolTip = ISToolTipInv:new(slotItem)
        o.toolTip:initialise()
        o.toolTip:setOwner(o)
        o.toolTip:setVisible(false)
        o.toolTip:addToUIManager()

        -- Texture related
        o:setImage(slotItem:getTexture())

        local visual = slotItem:getVisual()
        o.tint = nil
        if visual then
            o.tint = visual:getTint(slotItem:getClothingItem())
            o.currentTint = visual:getTint(slotItem:getClothingItem())
        end

        if o.tint ~= nil then
            o:setTextureRGBA(o.tint:getRedFloat(), o.tint:getGreenFloat(), o.tint:getBlueFloat(), o.tint:getAlphaFloat())
        end

        o.slotItem = slotItem
    end

    o:bringToTop();

    return o
end

function FWPInspectAddMagazineButton:render()
    ISButton.render(self)

    if self:isMouseOver() == false then
        if self.isJoypadFocused then
            self.backgroundColor.a = 0.8
            if self.slotItem and (self.contextMenu == nil or not self.contextMenu.visibleCheck) then
                self.toolTip.followMouse = false
                self.toolTip:setX(FWPInspectButtonUIV(80))
                self.toolTip:setY(FWPInspectButtonUIV(30))
                self.toolTip:setVisible(true)
                self.toolTip:bringToTop()
            end
        else
            self.backgroundColor.a = 0.5
            if self.slotItem then
                self.toolTip.followMouse = false
                self.toolTip:setVisible(false)
            end
        end
    end

    if self.slotItem then
        self:drawText(tostring(self.slotItem:getCurrentAmmoCount()), FWPInspectButtonUIV(4), 0, 1.0, 1.0, 1.0, 1.0)

        -- Texture related
        self:setImage(self.slotItem:getTexture())

        if self.currentTint ~= nil then
            self:setTextureRGBA(self.currentTint:getRedFloat(), self.currentTint:getGreenFloat(), self.currentTint:getBlueFloat(), self.currentTint:getAlphaFloat())
        end

        if not self.isJoypadFocused then
            if self:isMouseOver() and (self.contextMenu == nil or not self.contextMenu.visibleCheck) then
                self.toolTip.followMouse = true
                self.toolTip:setVisible(true)
                self.toolTip:bringToTop()
            else
                self.toolTip.followMouse = true
                self.toolTip:setVisible(false)
            end
        end
    end
end

function FWPInspectAddMagazineButton:onMouseDown()
    if self.slotItem then
        if (self.container ~= nil) then
            self.container:Remove(self.slotItem)
            self.character:getInventory():AddItem(self.slotItem)
        end

        if FWPInspectPrepareMagazineInsert then
            FWPInspectPrepareMagazineInsert(self.attachingTo, self.slotItem)
        end

        ISTimedActionQueue.add(ISInsertMagazine:new(self.character, self.attachingTo, self.slotItem))
    end
end

function FWPInspectAddMagazineButton:onRightMouseUp(x,y)
    self:doMenu(getMouseX(), getMouseY())
end

function FWPInspectAddMagazineButton:doMenu(x,y)
    local context = ISContextMenu.get(self.character:getPlayerNum(), x, y)
    ISInventoryPaneContextMenu.doMagazineMenu(self.character, self.slotItem, context)
    context.origin = self.origin
    context:bringToTop()
    setJoypadFocus(self.character:getPlayerNum(), context)
end

function FWPInspectAddMagazineButton:close()
    ISButton.close(self)
    self.toolTip:setVisible(false)
    self.toolTip:removeFromUIManager()
end

function FWPInspectAddMagazineButton:joypadConfirm()
    if self.slotItem then
        if FWPInspectPrepareMagazineInsert then
            FWPInspectPrepareMagazineInsert(self.attachingTo, self.slotItem)
        end

        ISTimedActionQueue.add(ISInsertMagazine:new(self.character, self.attachingTo, self.slotItem))
    end
end

function FWPInspectAddMagazineButton:joypadPrompt()
    return getText('IGUI_FWP_INSPECT_ATTACH')
end

function FWPInspectAddMagazineButton:joypadMenu()
    self:doMenu(FWPInspectButtonUIV(80), FWPInspectButtonUIV(130))
end

-- Repair button

FWPInspectRepairButton = ISButton:derive("FWPInspectRepairButton")

function FWPInspectRepairButton:new (x, y, w, h, title, clicktarget, onclick)
    local o = {}
    o = ISButton:new(x, y, w, h, title, clicktarget, onclick)

    setmetatable(o, self)
    self.__index = self

    o.borderColor.r = 0.0
    o.borderColor.g = 0.0
    o.borderColor.b = 0.0
    o.borderColor.a = 0.0

    o.backgroundColor.r = 0.5
    o.backgroundColor.g = 0.5
    o.backgroundColor.b = 0.5
    o.borderColor.a = 0.0;
    o.backgroundColor.a = 0;
    o.backgroundColorMouseOver.a = 0.8;

    o:setImage(getTexture("media/ui/Panel_info_button.png"));

    o.isJoypadFocused = false
    o.onclick = onclick

    return o
end

function FWPInspectRepairButton:render()
    ISButton.render(self)

    if self:isMouseOver() == false then
        if self.isJoypadFocused then
            self.backgroundColor.a = 0.8
        else
            self.backgroundColor.a = 0.0
        end
    end
end

function FWPInspectRepairButton:joypadConfirm()
    self.onclick()
end

function FWPInspectRepairButton:joypadPrompt()
    return getText('IGUI_FWP_INSPECT_REPAIR')
end

-- Weapon work button

FWPInspectWeaponWorkButton = ISButton:derive("FWPInspectWeaponWorkButton")

function FWPInspectWeaponWorkButton:new(x, y, w, h, action, character)
    local o = ISButton:new(x, y, w, h, action and action.label or "")
    setmetatable(o, self)
    self.__index = self

    o.action = action
    o.character = character
    o.isJoypadFocused = false
    o.borderColor.r = 0.15
    o.borderColor.g = 0.15
    o.borderColor.b = 0.15
    o.borderColor.a = 0.7
    o.backgroundColor.r = 0.18
    o.backgroundColor.g = 0.22
    o.backgroundColor.b = 0.20
    o.backgroundColor.a = 0.62
    o.backgroundColorMouseOver.r = 0.30
    o.backgroundColorMouseOver.g = 0.42
    o.backgroundColorMouseOver.b = 0.34
    o.backgroundColorMouseOver.a = 0.9
    o.textColor.r = 0.95
    o.textColor.g = 0.95
    o.textColor.b = 0.95
    o.textColor.a = 1.0

    return o
end

function FWPInspectWeaponWorkButton:render()
    ISButton.render(self)
    if not self:isMouseOver() then
        if self.isJoypadFocused then
            self.backgroundColor.a = 0.9
        else
            self.backgroundColor.a = 0.62
        end
    end
end

function FWPInspectWeaponWorkButton:runAction()
    if self.action and self.action.run then
        self.action.run()
    end
end

function FWPInspectWeaponWorkButton:onMouseUp(x, y)
    self:runAction()
end

function FWPInspectWeaponWorkButton:joypadConfirm()
    self:runAction()
end

function FWPInspectWeaponWorkButton:joypadPrompt()
    return self.action and self.action.label or nil
end

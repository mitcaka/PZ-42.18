-- @author Risky
-- Core file, contains all the event listeners and windows handler

require "ISUI/ISCollapsableWindowJoypad"
require "TimedActions/ISEquipWeaponAction"
require "FWP_Inspect_Stats"
require "FWP_UIScale"

-- Main module
FWPInspectWindow = {}
FWPInspectShowPotentialAttachment = true

FWPInspectUI = ISCollapsableWindowJoypad:derive("FWPInspectUI")

local function FWPInspectUIV(value)
    return FWPUIScale and FWPUIScale.value(value) or math.floor((tonumber(value) or 0) + 0.5)
end

local function FWPInspectUIButtonSize()
    return FWPInspectUIV(40)
end

local function FWPInspectUIGridGap()
    return FWPInspectUIV(41)
end

local function FWPInspectGetWeaponWorkActions(character, weapon)
    if FWPWeaponWorkCollectActions and character and weapon then
        return FWPWeaponWorkCollectActions(character, weapon)
    end
    return {}
end

local function FWPInspectWeaponWorkStatsY(character, weapon)
    local actions = FWPInspectGetWeaponWorkActions(character, weapon)
    local rows = math.ceil(#actions / 2)
    if rows <= 0 then
        return FWPInspectUIV(292), actions
    end
    return FWPInspectUIV(324) + (rows * FWPInspectUIV(30)) + FWPInspectUIV(8), actions
end

local function FWPInspectWeaponWorkStatsYFromActions(actions)
    actions = actions or {}
    local rows = math.ceil(#actions / 2)
    if rows <= 0 then
        return FWPInspectUIV(292)
    end
    return FWPInspectUIV(324) + (rows * FWPInspectUIV(30)) + FWPInspectUIV(8)
end

function FWPInspectUI:new(x, y, width, height, character)
    local o = {}
	o = ISCollapsableWindowJoypad:new(x, y, width, height)

    setmetatable(o, self)
    self.__index = self

    o.panelWidth = 0
    o.panelHeight = 0

    o.currentPrimaryItem = character:getPrimaryHandItem()
    o.itemWeight = character:getInventory():getCapacityWeight()
    o.itemCap = character:getInventory():getItems():size()

    o.weaponCondition = (character:getPrimaryHandItem():getCondition() * 100) / character:getPrimaryHandItem():getConditionMax()

    local weapon = character:getPrimaryHandItem()
    if (weapon:IsWeapon() and weapon:isRanged()) then
        if (weapon:isTwoHandWeapon()) then
            character:setVariable("IsInspectTwoHandedRanged", "true")
        else
            character:setVariable("IsInspectOneHandedRanged", "true")
        end
    end

    -- Hack to get joypad focus on create
    setJoypadFocus(character:getPlayerNum(), o)
    o.elements = {}
    o.currentFocus = 0
    o.character = character
    
    o.elements[0] = o
    o.overrideBPrompt = true

	return o
end

function FWPInspectUI:isValidPrompt()
    return true
end

function FWPInspectUI:update()
    if self and self:getIsVisible() then
        if (self.currentPrimaryItem ~= self.character:getPrimaryHandItem()) then
            self:close()
        end

        if self.itemCap ~= self.character:getInventory():getItems():size() or
                self.itemWeight ~= self.character:getInventory():getCapacityWeight() or
                self.weaponCondition ~= (self.character:getPrimaryHandItem():getCondition() * 100) / self.character:getPrimaryHandItem():getConditionMax() then
            self.itemCap = self.character:getInventory():getItems():size()
            self.itemWeight = self.character:getInventory():getCapacityWeight()
            self.weaponCondition = (self.character:getPrimaryHandItem():getCondition() * 100) / self.character:getPrimaryHandItem():getConditionMax()
            self:renderInventory()
        end
    end
end

function FWPInspectUI:prerender()
    ISCollapsableWindowJoypad.prerender(self)
    local u = FWPInspectUIV

    self:drawRectBorder(0, 0, self.width, self.height, 0.34, 0.62, 0.43, 0.23)
    self:drawRectBorder(u(1), u(1), math.max(1, self.width - u(2)), math.max(1, self.height - u(2)), 0.16, 0.80, 0.62, 0.36)
    self:drawRectBorder(u(2), u(2), math.max(1, self.width - u(4)), math.max(1, self.height - u(4)), 0.08, 0.36, 0.27, 0.16)

    local fwpInspectBg = getTexture("media/textures/fwpInspectWeaponBackground.png")
    if fwpInspectBg then
        local bgY = u(16)
        local bgHeight = math.max(1, self.height - bgY - u(1))
        self:drawTextureScaled(fwpInspectBg, 0, bgY, self.width, bgHeight, 0.62, 1.0, 1.0, 1.0)
        self:drawRect(0, bgY, self.width, bgHeight, 0.28, 0.0, 0.0, 0.0)
    end

    if self.character:getPrimaryHandItem() ~= nil and self.character:getPrimaryHandItem():IsWeapon() then
        local weapon = self.character:getPrimaryHandItem()
        local conditionPerc = (weapon:getCondition() * 100) / weapon:getConditionMax()

        self:drawTextureScaled(weapon:getTexture(), u(20), u(50), u(32), u(32), 1, 1, 1, 1)
        self:drawText(weapon:getDisplayName(), u(65), u(35), 1, 1, 1, 1, UIFont.Medium)

        local conditionText = ""
        if conditionPerc >= 100 and weapon:getHaveBeenRepaired() == 1 then
            conditionText = getText('IGUI_FWP_INSPECT_CONDITION') .. ": " .. getText('IGUI_FWP_INSPECT_PRISTINE')
        elseif conditionPerc <= 100 and conditionPerc > 50 then
            conditionText = getText('IGUI_FWP_INSPECT_CONDITION') .. ": " .. getText('IGUI_FWP_INSPECT_USED')
        elseif conditionPerc < 50 and conditionPerc > 30 then
            conditionText = getText('IGUI_FWP_INSPECT_CONDITION') .. ": " .. getText('IGUI_FWP_INSPECT_DAMAGED')
        else
            conditionText = getText('IGUI_FWP_INSPECT_CONDITION') .. ": " .. getText('IGUI_FWP_INSPECT_BADLY_DAMAGED')
        end
        self:drawText(conditionText, u(65), u(55), 1, 1, 1, 1, UIFont.Small)

        local repairText = ""
        if weapon:getHaveBeenRepaired() == 1 then
            repairText = getText('IGUI_FWP_INSPECT_REPAIR_NONE')
        elseif weapon:getHaveBeenRepaired() > 1 and weapon:getHaveBeenRepaired() < 4 then
            repairText = getText('IGUI_FWP_INSPECT_REPAIR_SLIGHTLY')
        else
            repairText = getText('IGUI_FWP_INSPECT_REPAIR_HEAVILY')
        end
        self:drawText(repairText, u(65), u(70), 1, 1, 1, 1, UIFont.Small)
            
        if weapon:isRanged() then
            local attachTextMeasure = getTextManager():MeasureStringX(UIFont.Medium, getText('IGUI_FWP_INSPECT_ATTACHMENTS'))
            if (self.character:getInventory():getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, FWPInspectPredicateNotBroken)) then
                self:drawText("(", attachTextMeasure + u(25), u(100), 1, 1, 1, 1, UIFont.Medium)
                self:drawTextureScaled(getTexture("Item_Screwdriver"),  attachTextMeasure + u(35), u(103), u(15), u(15), 1.0, 1.0, 1.0, 1.0);
                self:drawText(")", attachTextMeasure + u(55), u(100), 1, 1, 1, 1, UIFont.Medium)
            end

            self:drawText(getText('IGUI_FWP_INSPECT_ATTACHMENTS'), u(20), u(100), 1, 1, 1, 1, UIFont.Medium)

            local canon = getText('IGUI_FWP_INSPECT_NONE')
            local clip = getText('IGUI_FWP_INSPECT_NONE')
            local recoilPad = getText('IGUI_FWP_INSPECT_NONE')
            local scope = getText('IGUI_FWP_INSPECT_NONE')
            local sling = getText('IGUI_FWP_INSPECT_NONE')
            local stock = getText('IGUI_FWP_INSPECT_NONE')

            -- Canon
            if weapon:getWeaponPart("Canon") ~= nil then
                canon = weapon:getWeaponPart("Canon"):getDisplayName()
            end
            self:drawText(canon, u(70), u(137), 1, 1, 1, 1, UIFont.Small)
            self:drawText(getText('IGUI_FWP_INSPECT_CANON'), u(70), u(152), 1, 1, 1, 1, UIFont.Small)

            -- Clip - DISABLE UNTIL THEY INTRODUCE CLIP ATTACHMENT SLOT
            ---if FWPGetWeaponPart(weapon, "Clip") ~= nil then
            ---    clip = FWPGetWeaponPart(weapon, "Clip"):getDisplayName()
            ---end
            if weapon:isContainsClip() then
                local tempContainer = ItemContainer.new("magazine", nil, nil)
                local magazine = tempContainer:AddItem(weapon:getMagazineType())
                tempContainer:clear()
                tempContainer = nil

                clip = magazine:getDisplayName()
            end
            self:drawText(clip, u(70), u(187), 1, 1, 1, 1, UIFont.Small)
            self:drawText(getText('IGUI_FWP_INSPECT_CLIP'), u(70), u(202), 1, 1, 1, 1, UIFont.Small)

            -- Recoil Pad
            if weapon:getWeaponPart("RecoilPad") ~= nil then
                recoilPad = weapon:getWeaponPart("RecoilPad"):getDisplayName()
            end
            self:drawText(recoilPad, u(70), u(237), 1, 1, 1, 1, UIFont.Small)
            self:drawText(getText('IGUI_FWP_INSPECT_RECOIL_PAD'), u(70), u(252), 1, 1, 1, 1, UIFont.Small)

            local canonWidth, clipWidth, recoilPadWidth

            if weapon:getWeaponPart("Canon") ~= nil then canonWidth = getTextManager():MeasureStringX(UIFont.Small, weapon:getWeaponPart("Canon"):getDisplayName()) else canonWidth = 0 end
            --if FWPGetWeaponPart(weapon, "Clip") ~= nil then clipWidth = getTextManager():MeasureStringX(UIFont.Small, FWPGetWeaponPart(weapon, "Clip"):getDisplayName()) else clipWidth = 0 end
            if weapon:isContainsClip() then clipWidth = getTextManager():MeasureStringX(UIFont.Small, clip) else clipWidth = 0 end
            if weapon:getWeaponPart("RecoilPad") ~= nil then recoilPadWidth = getTextManager():MeasureStringX(UIFont.Small, weapon:getWeaponPart("RecoilPad"):getDisplayName()) else recoilPadWidth = 0 end

            local leftWidth = math.max(getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_NONE')),
                                        getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_CANON')),
                                        getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_CLIP')),
                                        getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_RECOIL_PAD')),
                                        canonWidth, clipWidth, recoilPadWidth)

            -- Scope
            if weapon:getWeaponPart("Scope") ~= nil then
                scope = weapon:getWeaponPart("Scope"):getDisplayName()
            end
            self:drawText(scope, leftWidth + u(150), u(137), 1, 1, 1, 1, UIFont.Small)
            self:drawText(getText('IGUI_FWP_INSPECT_SCOPE'), leftWidth + u(150), u(152), 1, 1, 1, 1, UIFont.Small)

            -- Sling
            if weapon:getWeaponPart("Sling") ~= nil then
                sling = weapon:getWeaponPart("Sling"):getDisplayName()
            end
            self:drawText(sling, leftWidth + u(150), u(187), 1, 1, 1, 1, UIFont.Small)
            self:drawText(getText('IGUI_FWP_INSPECT_SLING'), leftWidth + u(150), u(202), 1, 1, 1, 1, UIFont.Small)

            -- Stock
            if weapon:getWeaponPart("Stock") ~= nil then
                stock= weapon:getWeaponPart("Stock"):getDisplayName()
            end
            self:drawText(stock, leftWidth + u(150), u(237), 1, 1, 1, 1, UIFont.Small)
            self:drawText(getText('IGUI_FWP_INSPECT_STOCK'), leftWidth + u(150), u(252), 1, 1, 1, 1, UIFont.Small)

            local workActions = self.weaponWorkActions or FWPInspectGetWeaponWorkActions(self.character, weapon)
            local statsY = FWPInspectWeaponWorkStatsYFromActions(workActions)
            if #workActions > 0 then
                self:drawText(getText('IGUI_FWP_INSPECT_WEAPON_WORK'), u(20), u(292), 1, 1, 1, 1, UIFont.Small)
            end
            if FWPGetWeaponMasteryLabel then
                local masteryText = FWPGetWeaponMasteryLabel(self.character, weapon)
                if masteryText then
                    self:drawText(masteryText, u(65), u(85), 0.72, 0.95, 0.78, 1, UIFont.Small)
                end
            end

            if FWPInspectDrawWeaponVariants then
                local variantHeight = FWPInspectDrawWeaponVariants(self, weapon, u(20), statsY, self.width - u(40))
                if variantHeight ~= nil and variantHeight > 0 then
                    statsY = statsY + variantHeight + u(8)
                end
            end

            if FWPInspectDrawWeaponStats then
                FWPInspectDrawWeaponStats(self, weapon, u(20), statsY, self.width - u(40))
            end
        end
    else
        self:close()
    end
end

function FWPInspectUI:renderInventory()
    self:clearChildren()
    local u = FWPInspectUIV
    local buttonSize = FWPInspectUIButtonSize()

    -- Close button
    local closeButton = ISButton:new(u(3), 0, u(15), u(15), "", self, function(self, button) self:close() end);
	closeButton:initialise();
	closeButton.borderColor.a = 0.0;
	closeButton.backgroundColor.a = 0;
	closeButton.backgroundColorMouseOver.a = 0;
	closeButton:setImage(getTexture("media/ui/Dialog_Titlebar_CloseIcon.png"));
	self:addChild(closeButton);

    if self.character:getPrimaryHandItem() ~= nil and self.character:getPrimaryHandItem():IsWeapon() then
        local weapon = self.character:getPrimaryHandItem()
        local conditionPerc = (weapon:getCondition() * 100) / weapon:getConditionMax()

        local conditionText = ""
        if conditionPerc >= 100 and weapon:getHaveBeenRepaired() == 1 then
            conditionText = getText('IGUI_FWP_INSPECT_CONDITION') .. ": " .. getText('IGUI_FWP_INSPECT_PRISTINE')
        elseif conditionPerc <= 100 and conditionPerc > 50 then
            conditionText = getText('IGUI_FWP_INSPECT_CONDITION') .. ": " .. getText('IGUI_FWP_INSPECT_USED')
        elseif conditionPerc < 50 and conditionPerc > 30 then
            conditionText = getText('IGUI_FWP_INSPECT_CONDITION') .. ": " .. getText('IGUI_FWP_INSPECT_DAMAGED')
        else
            conditionText = getText('IGUI_FWP_INSPECT_CONDITION') .. ": " .. getText('IGUI_FWP_INSPECT_BADLY_DAMAGED')
        end

        local repairText = ""
        if weapon:getHaveBeenRepaired() == 1 then
            repairText = getText('IGUI_FWP_INSPECT_REPAIR_NONE')
        elseif weapon:getHaveBeenRepaired() > 1 and weapon:getHaveBeenRepaired() < 4 then
            repairText = getText('IGUI_FWP_INSPECT_REPAIR_SLIGHTLY')
        else
            repairText = getText('IGUI_FWP_INSPECT_REPAIR_HEAVILY')
        end

        -- Repair icon
        local fixingOk, fixingList = pcall(function()
            return FixingManager.getFixes(weapon)
        end)
        if not fixingOk then
            fixingList = nil
        end
        local repairBtn = nil

        if fixingList ~= nil and not fixingList:isEmpty() and conditionPerc < 100 then
            local x = u(66) + getTextManager():MeasureStringX(UIFont.Small, repairText)
            local y = u(70)
            local _character = self.character
            repairBtn = FWPInspectRepairButton:new(x, y, u(15), u(15), "", self, 
                function(self, button)
                    local context = ISContextMenu.get(_character:getPlayerNum(), FWPInspectWindow[_character:getPlayerNum()].x + x, FWPInspectWindow[_character:getPlayerNum()].y + y)
                    local fixOption = context:addOption(getText("ContextMenu_Repair"), _character:getInventory():getItems(), nil);
                    local subMenuFix = ISContextMenu:getNew(context);
                    context:addSubMenu(fixOption, subMenuFix);
                    ISInventoryPaneContextMenu.buildFixingMenu(weapon, _character:getPlayerNum(), fixingList:get(0), 0, fixOption, subMenuFix)
                    context:addToUIManager()
                    context.origin = FWPInspectWindow[_character:getPlayerNum()]
                    setJoypadFocus(_character:getPlayerNum(), context)
                end
            );
            repairBtn:initialise();
            self:addChild(repairBtn);

            self.elements[1] = repairBtn
            self.downFocus = 1
        end

        self.panelWidth = math.max(getTextManager():MeasureStringX(UIFont.Medium, weapon:getDisplayName()),
                                    getTextManager():MeasureStringX(UIFont.Small, conditionText),
                                    getTextManager():MeasureStringX(UIFont.Small, repairText) + u(17)) + u(100)

        if (weapon:isRanged()) then
            -- Width/Height
            self.panelHeight = u(110)
            self:setHeight(self.panelHeight)

            local itemList = self.character:getInventory():getItems()
            local containerCount = 1
            allContainers = {}
        
            -- Probe containers
            for i=0,itemList:size() - 1,1 do
                if instanceof(itemList:get(i), 'InventoryContainer') and (itemList:get(i):isEquipped()) then
                    table.insert(allContainers, itemList:get(i))
                    containerCount = containerCount + 1
                end
            end

            -- Not an ideal way to get the object loose ammo and box ammo object, but for the time being...
            local tempContainer = ItemContainer.new("ammoCount", nil, nil)
            local okLooseAmmoType, looseAmmoType = pcall(function()
                return FWPGetAmmoItemKey(weapon)
            end)
            if not okLooseAmmoType then
                looseAmmoType = nil
            end
            local okBoxAmmoType, boxAmmoType = pcall(function()
                return weapon:getAmmoBox()
            end)
            if not okBoxAmmoType then
                boxAmmoType = nil
            end

            local function fwpInspectSpawnPreview(itemType)
                if itemType == nil or itemType == "" then
                    return nil
                end
                local ok, result = pcall(function()
                    return tempContainer:SpawnItem(itemType)
                end)
                if ok then
                    return result
                end
                return nil
            end

            local function fwpInspectCountItem(container, itemType)
                if container == nil or itemType == nil or itemType == "" then
                    return 0
                end
                local ok, result = pcall(function()
                    return container:getItemCount(itemType)
                end)
                if ok and tonumber(result) ~= nil then
                    return tonumber(result)
                end
                return 0
            end

            local ammoButtonTypes = {}
            local seenAmmoButtonTypes = {}
            local function fwpInspectAddAmmoButtonType(itemType)
                if itemType == nil or itemType == "" then
                    return
                end
                itemType = tostring(itemType)
                if itemType == "nil" or seenAmmoButtonTypes[itemType] then
                    return
                end
                seenAmmoButtonTypes[itemType] = true
                table.insert(ammoButtonTypes, itemType)
            end

            fwpInspectAddAmmoButtonType(looseAmmoType)
            fwpInspectAddAmmoButtonType(boxAmmoType)

            if looseAmmoType == "Base.ShotgunShells" then
                fwpInspectAddAmmoButtonType("Base.FWP_12gIncendiaryShells")
                fwpInspectAddAmmoButtonType("Base.FWP_12gIncendiaryShellsBox")
            elseif looseAmmoType == "Base.FlameFuel" then
                fwpInspectAddAmmoButtonType("Base.M2A1_Can")
                fwpInspectAddAmmoButtonType("Base.M2A1_Tank")
            end

            local ammoButtonX = u(10)
            local ammoButtonStep = u(55)
            local ammoButtonCount = 0
            for _, ammoType in ipairs(ammoButtonTypes) do
                local ammoPreview = fwpInspectSpawnPreview(ammoType)
                if ammoPreview ~= nil then
                    local ammoCount = fwpInspectCountItem(self.character:getInventory(), ammoType)
                    if (containerCount > 1) then
                        for i=1,containerCount - 1 do
                            ammoCount = ammoCount + fwpInspectCountItem(allContainers[i]:getInventory(), ammoType)
                        end
                    end
                    item = FWPInspectAmmoButton:new(self.panelWidth + ammoButtonX, u(40), u(50), u(50), ammoPreview, ammoCount)
                    item:bringToTop()
                    self:addChild(item)
                    ammoButtonX = ammoButtonX + ammoButtonStep
                    ammoButtonCount = ammoButtonCount + 1
                end
            end

            local ammoButtonPanelWidth = math.max(u(130), u(20) + (ammoButtonCount * ammoButtonStep))

            tempContainer:clear()
            tempContainer = nil

            self.panelWidth = math.max(self.panelWidth + (ammoButtonPanelWidth or u(130)), u(580))
        
            self.panelHeight = self.panelHeight + u(450)

            -- Canon
            canonBtn = FWPInspectAttachmentButton:new(u(20), u(130), buttonSize, buttonSize, weapon:getWeaponPart("Canon"), weapon, "Canon", self.character)
            canonBtn:bringToTop()
            self:addChild(canonBtn)
            self.elements[2] = canonBtn

            -- Clip - DISABLE UNTIL THEY INTRODUCE CLIP ATTACHMENTS
            --item = FWPInspectAttachmentButton:new(20, 180, 40, 40, FWPGetWeaponPart(weapon, "Clip"), weapon, WeaponPart.TYPE_CLIP)
            --item:bringToTop()
            --self:addChild(item)
            local magazine = nil
            if weapon:isContainsClip() then
                local tempContainer = ItemContainer.new("magazine", nil, nil)
                magazine = tempContainer:AddItem(weapon:getMagazineType())
                tempContainer:clear()
                tempContainer = nil
            end
            magazineBtn = FWPInspectMagazineButton:new(u(20), u(180), buttonSize, buttonSize, magazine, weapon, self.character)
            magazineBtn:bringToTop()
            self:addChild(magazineBtn)
            self.elements[3] = magazineBtn

            -- Recoil Pad
            padBtn = FWPInspectAttachmentButton:new(u(20), u(230), buttonSize, buttonSize, weapon:getWeaponPart("RecoilPad"), weapon, "Recoil Pad", self.character)
            padBtn:bringToTop()
            self:addChild(padBtn)
            self.elements[4] = padBtn

            local canonWidth, clipWidth, recoilPadWidth, scopeWidth, slingWidth, stockWidth

            if weapon:getWeaponPart("Canon") ~= nil then canonWidth = getTextManager():MeasureStringX(UIFont.Small, weapon:getWeaponPart("Canon"):getDisplayName()) else canonWidth = 0 end
            --if FWPGetWeaponPart(weapon, "Clip") ~= nil then clipWidth = getTextManager():MeasureStringX(UIFont.Small, FWPGetWeaponPart(weapon, "Clip"):getDisplayName()) else clipWidth = 0 end
            if weapon:isContainsClip() then clipWidth = getTextManager():MeasureStringX(UIFont.Small, magazine:getDisplayName()) else clipWidth = 0 end
            if weapon:getWeaponPart("RecoilPad") ~= nil then recoilPadWidth = getTextManager():MeasureStringX(UIFont.Small, weapon:getWeaponPart("RecoilPad"):getDisplayName()) else recoilPadWidth = 0 end

            local leftWidth = math.max(getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_NONE')),
                                        getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_CANON')),
                                        getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_CLIP')),
                                        getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_RECOIL_PAD')),
                                        canonWidth, clipWidth, recoilPadWidth)

            -- Scope
            scopeBtn = FWPInspectAttachmentButton:new(leftWidth + u(100), u(130), buttonSize, buttonSize, weapon:getWeaponPart("Scope"), weapon, "Scope", self.character)
            scopeBtn:bringToTop()
            self:addChild(scopeBtn)
            self.elements[5] = scopeBtn

            -- Sling
            slingBtn = FWPInspectAttachmentButton:new(leftWidth + u(100), u(180), buttonSize, buttonSize, weapon:getWeaponPart("Sling"), weapon, "Sling", self.character)
            slingBtn:bringToTop()
            self:addChild(slingBtn)
            self.elements[6] = slingBtn

            -- Stock
            stockBtn = FWPInspectAttachmentButton:new(leftWidth + u(100), u(230), buttonSize, buttonSize, weapon:getWeaponPart("Stock"), weapon, "Stock", self.character)
            stockBtn:bringToTop()
            self:addChild(stockBtn)
            self.elements[7] = stockBtn

            local workActions = FWPInspectGetWeaponWorkActions(self.character, weapon)
            self.weaponWorkActions = workActions
            local workFirstFocus = nil
            if #workActions > 0 then
                local workButtonW = u(250)
                local workButtonH = u(24)
                local workGapX = u(8)
                local workGapY = u(6)
                local workStartY = u(314)
                for i, action in ipairs(workActions) do
                    local col = (i - 1) % 2
                    local row = math.floor((i - 1) / 2)
                    local x = u(20) + (col * (workButtonW + workGapX))
                    local y = workStartY + (row * (workButtonH + workGapY))
                    local focusIndex = 7 + i
                    local workBtn = FWPInspectWeaponWorkButton:new(x, y, workButtonW, workButtonH, action, self.character)
                    workBtn:bringToTop()
                    self:addChild(workBtn)
                    self.elements[focusIndex] = workBtn
                    if workFirstFocus == nil then
                        workFirstFocus = focusIndex
                    end
                    if i > 1 then
                        workBtn.upFocus = focusIndex - 1
                        self.elements[focusIndex - 1].downFocus = focusIndex
                    end
                end
                local statsY = FWPInspectWeaponWorkStatsYFromActions(workActions)
                self.panelHeight = self.panelHeight + (statsY - u(292))
                self.panelWidth = math.max(self.panelWidth, u(560))
            end

            if FWPInspectGetWeaponVariantPanelHeight then
                local variantHeight = FWPInspectGetWeaponVariantPanelHeight(weapon, self.panelWidth - u(40))
                if variantHeight ~= nil and variantHeight > 0 then
                    self.panelHeight = self.panelHeight + variantHeight + u(8)
                    self.panelWidth = math.max(self.panelWidth, u(560))
                end
            end

            -- Joypad focus bind
            canonBtn.downFocus = 3
            canonBtn.rightFocus = 5

            magazineBtn.upFocus = 2
            magazineBtn.downFocus = 4
            magazineBtn.rightFocus = 6

            padBtn.upFocus = 3
            padBtn.rightFocus = 7

            scopeBtn.downFocus = 6
            scopeBtn.leftFocus = 2

            slingBtn.upFocus = 5
            slingBtn.downFocus = 7
            slingBtn.leftFocus = 3

            stockBtn.upFocus = 6
            stockBtn.leftFocus = 4
            if workFirstFocus ~= nil then
                padBtn.downFocus = workFirstFocus
                stockBtn.downFocus = workFirstFocus
                self.elements[workFirstFocus].upFocus = 7
            end
            
            if repairBtn == nil then
                self.downFocus = 2
            else
                repairBtn.downFocus = 2
                canonBtn.upFocus = 1
                scopeBtn.upFocus = 1
            end

            -- Measure width
            if weapon:getWeaponPart("Scope") ~= nil then scopeWidth = getTextManager():MeasureStringX(UIFont.Small, weapon:getWeaponPart("Scope"):getDisplayName()) else scopeWidth = 0 end
            if weapon:getWeaponPart("Sling") ~= nil then slingWidth = getTextManager():MeasureStringX(UIFont.Small, weapon:getWeaponPart("Sling"):getDisplayName()) else slingWidth = 0 end
            if weapon:getWeaponPart("Stock") ~= nil then stockWidth = getTextManager():MeasureStringX(UIFont.Small, weapon:getWeaponPart("Stock"):getDisplayName()) else stockWidth = 0 end

            local rightWidth = math.max(getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_NONE')),
                                        getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_SCOPE')),
                                        getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_SLING')),
                                        getTextManager():MeasureStringX(UIFont.Small, getText('IGUI_FWP_INSPECT_STOCK')),
                                        scopeWidth, slingWidth, stockWidth)

            self.panelWidth = math.max(self.panelWidth, leftWidth + rightWidth + u(175))
        else
            self.panelHeight = u(110)
        end

        -- Joypad -------------------------------------------------
        self.elements[self.currentFocus].isJoypadFocused = true
        -----------------------------------------------------------
    end

    self:setWidth(self.panelWidth)
    self:setHeight(self.panelHeight)
    if FWPUIScale and FWPUIScale.clampToScreen then
        FWPUIScale.clampToScreen(self, 8)
    end
end

-- GAMEPAD

function FWPInspectUI:onJoypadDirDown(joypadData)
    local currentCell = self.elements[self.currentFocus]
    if currentCell.downFocus ~= nil then
        self.elements[currentCell.downFocus].isJoypadFocused = true
        currentCell.isJoypadFocused = false
        self.currentFocus = currentCell.downFocus
    end
end

function FWPInspectUI:onJoypadDirUp(joypadData)
    local currentCell = self.elements[self.currentFocus]
    if currentCell.upFocus ~= nil then
        self.elements[currentCell.upFocus].isJoypadFocused = true
        currentCell.isJoypadFocused = false
        self.currentFocus = currentCell.upFocus
    end
end

function FWPInspectUI:onJoypadDirLeft(joypadData)
    local currentCell = self.elements[self.currentFocus]
    if currentCell.leftFocus ~= nil then
        self.elements[currentCell.leftFocus].isJoypadFocused = true
        currentCell.isJoypadFocused = false
        self.currentFocus = currentCell.leftFocus
    end
end

function FWPInspectUI:onJoypadDirRight(joypadData)
    local currentCell = self.elements[self.currentFocus]
    if currentCell.rightFocus ~= nil then
        self.elements[currentCell.rightFocus].isJoypadFocused = true
        currentCell.isJoypadFocused = false
        self.currentFocus = currentCell.rightFocus
    end
end

function FWPInspectUI:onJoypadDown(button)
	if button == Joypad.BButton then
        self:close()
    elseif button == Joypad.AButton and self.currentFocus ~= 0 then
        self.elements[self.currentFocus]:joypadConfirm()
	end
end

function FWPInspectUI:getBPrompt()
    return getText('IGUI_FWP_INSPECT_BACK')
end

function FWPInspectUI:getAPrompt()
    return self.elements[self.currentFocus]:joypadPrompt()
end

function FWPInspectUI:getXPrompt()
    return nil
end

function FWPInspectUI:getYPrompt()
    return nil
end

function FWPInspectUI:joypadPrompt()
    return nil
end

function FWPInspectUI:onGainJoypadFocus(joypadData)
	self.drawJoypadFocus = true
end

function FWPInspectUI:onLoseJoypadFocus(joypadData)
	self.drawJoypadFocus = false
end

-- HELPER FUNCTIONS AND EVENTS

function FWPInspectUI:close()
    self.character:getModData().fwpInspectWindowPos = {self.x, self.y}

    self.character:setVariable("IsInspectOneHandedRanged", "false")
    self.character:setVariable("IsInspectTwoHandedRanged", "false")

    setJoypadFocus(self.character:getPlayerNum(), nil)

    self:setVisible(false)
    FWPInspectWindow[self.character:getPlayerNum()] = nil
end

FWPInspectUI.onMove = function(player)
    if FWPInspectWindow[player:getPlayerNum()] ~= nil and FWPInspectWindow[player:getPlayerNum()]:getIsVisible() then
        FWPInspectWindow[player:getPlayerNum()]:close()
        FWPInspectWindow[player:getPlayerNum()] = nil
    end
end

Events.OnPlayerMove.Add(FWPInspectUI.onMove)

-- Overriding current weapon's radial menu
local ISFirearmRadialMenu_old_fill = ISFirearmRadialMenu.fillMenu
function ISFirearmRadialMenu:fillMenu(submenu)
    local menu = getPlayerRadialMenu(self.playerNum)
    ISFirearmRadialMenu_old_fill(self)

    local riskyTexture = getTexture("media/textures/fwpInspect.png")
    menu:addSlice(getText('IGUI_FWP_INSPECT_INSPECT_WEAPON'), riskyTexture, function() ISTimedActionQueue.add(FWPInspectAction:new(getSpecificPlayer(self.playerNum), 1)) end, self)
    self:display()
end

function ISFirearmRadialMenu:getWeapon()
	local weapon = self.character:getPrimaryHandItem()
	if not weapon then return nil end
	if not instanceof(weapon, "HandWeapon") then return nil end
	return weapon
end

function ISFirearmRadialMenu.checkWeapon(playerObj)
	local weapon = playerObj:getPrimaryHandItem()
	if not weapon then return false end
	if not instanceof(weapon, "HandWeapon") then return false end
	return true
end

-- Inspect specific item in inventory
FWPInspectUI.createInventoryMenuEntry = function(_player, _context, _items)local container = nil
    local resItems = {}
    for i,v in ipairs(_items) do
        if not instanceof(v, "InventoryItem") then
            for _, it in ipairs(v.items) do
                resItems[it] = true
            end
            container = v.items[1]:getContainer()
        else
            resItems[v] = true
            container = v:getContainer()
        end
    end

    local inspectSubMenu = _context:getNew(_context)
    local entryCount = 0

    for v, _ in pairs(resItems) do
        if v:IsWeapon() then
            inspectSubMenu:addOption(v:getName(), v, function() 
                ISTimedActionQueue.add(ISInventoryTransferAction:new(getSpecificPlayer(_player), v, v:getContainer(), getSpecificPlayer(_player):getInventory()))
                ISTimedActionQueue.add(ISEquipWeaponAction:new(getSpecificPlayer(_player), v, 50, true, v:isTwoHandWeapon()));
                ISTimedActionQueue.add(FWPInspectAction:new(getSpecificPlayer(_player), 1));
            end)

            entryCount = entryCount + 1
        end
    end
           
    if entryCount ~= 0 then
        local option = _context:addOption(getText('IGUI_FWP_INSPECT_INSPECT_WEAPON'))
        _context:addSubMenu(option, inspectSubMenu)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(FWPInspectUI.createInventoryMenuEntry)

FWPInspectUI.onAttack = function(_character, _weapon)
    if FWPInspectWindow[_character:getPlayerNum()] ~= nil and FWPInspectWindow[_character:getPlayerNum()]:getIsVisible() then
        FWPInspectWindow[_character:getPlayerNum()]:close()
        FWPInspectWindow[_character:getPlayerNum()] = nil
    end
end

Events.OnWeaponSwing.Add(FWPInspectUI.onAttack)

-- WINDOW POSITION
FWPInspectUI.onGameStart = function()
    if (getSpecificPlayer(0):getModData().fwpInspectWindowPos == nil) then
        getSpecificPlayer(0):getModData().fwpInspectWindowPos = {FWPInspectUIV(100), FWPInspectUIV(100)}
    end
end

Events.OnGameStart.Add(FWPInspectUI.onGameStart)

FWPInspectUI.onCreatePlayer = function(playerIndex, player)
    if (player:getModData().fwpInspectWindowPos == nil) then
        player:getModData().fwpInspectWindowPos = {FWPInspectUIV(100), FWPInspectUIV(100)}
    end
end

Events.OnCreatePlayer.Add(FWPInspectUI.onCreatePlayer)

-- KEYBINDING
FWPInspectUI.initKeyBind = function()
    getTexture("media/textures/fwpInspect.png")
	table.insert(keyBinding, { value = "[OPTION_INSPECT_WEAPON]" } );
	table.insert(keyBinding, { value = "OPTION_INSPECT_CURRENT_WEAPON", key = 39 } );
end
Events.OnGameBoot.Add(FWPInspectUI.initKeyBind);

FWPInspectUI.inspectOnKey = function(_keyPressed)
    if _keyPressed == getCore():getKey("OPTION_INSPECT_CURRENT_WEAPON") then
        local weapon = getSpecificPlayer(0):getPrimaryHandItem()
        if (weapon ~= nil and weapon:IsWeapon()) then
            ISTimedActionQueue.add(FWPInspectAction:new(getSpecificPlayer(0), 1))
        end
    end
end

Events.OnKeyPressed.Add(FWPInspectUI.inspectOnKey)

-- SELECT ATTACHMENT PANE

FWPInspectSelectAttachmentPane = ISPanel:derive("FWPInspectSelectAttachmentPane")

function FWPInspectSelectAttachmentPane:new(x, y, category, character)
    local o = {}
    local buttonSize = FWPInspectUIButtonSize()
    o = ISPanel:new(x, y, buttonSize * 5 + FWPInspectUIV(20), FWPInspectUIV(126));

    setmetatable(o, self)
    self.__index = self
    
    o.category = category
    o.backgroundColor = {r=0, g=0, b=0, a=1};
    o.borderColor = {r=0.9, g=0.9, b=0.9, a=0.7};
    o.origin = FWPInspectWindow[character:getPlayerNum()]

    o.currentPrimaryItem = character:getPrimaryHandItem()
    o.itemWeight = character:getInventory():getCapacityWeight()
    o.itemCap = character:getInventory():getItems():size()
    o.elements = {}
    o.currentFocus = 0
    o.overrideBPrompt = true
    o.character = character

    if (FWPInspectShowPotentialAttachment) then
        o.potentialAttachment = FWPInspectBuildPotentialAttachmentMap()
    end

    return o
end

function FWPInspectSelectAttachmentPane:isValidPrompt()
    return true
end

function FWPInspectSelectAttachmentPane:prerender()
	self:setStencilRect(0,0,self.width, self.height);
    self:drawRect(-self:getXScroll(), -self:getYScroll(), self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
end

function FWPInspectSelectAttachmentPane:render()
    self:clearStencilRect();
	self:drawRectBorder(-self:getXScroll(), -self:getYScroll(), self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
end

function FWPInspectSelectAttachmentPane:createChildren()
    self:addScrollBars(false)
	self:setScrollWithParent(false)
	self:setScrollChildren(true)
end

function FWPInspectSelectAttachmentPane:onMouseWheel(del)
	self:setYScroll(self:getYScroll() - (del * FWPInspectUIV(42)))
	return true;
end

function FWPInspectSelectAttachmentPane:update()
    if self and self:getIsVisible() then
        if (self.currentPrimaryItem ~= self.character:getPrimaryHandItem() or FWPInspectWindow[self.character:getPlayerNum()] == nil) then
            self:close()
        end

        if self.itemCap ~= self.character:getInventory():getItems():size() or
            self.itemWeight ~= self.character:getInventory():getCapacityWeight() then
            self.itemCap = self.character:getInventory():getItems():size()
            self.itemWeight = self.character:getInventory():getCapacityWeight()

            if (#self.elements ~= 0) then
                for i=1,#self.elements do
                    FWPInspectCloseAttachmentButtonTooltip(self.elements[i])
                    self:removeChild(self.elements[i])
                end
            end
            self.elements = {}

            self:renderInventory()
        end
    end
end

function FWPInspectSelectAttachmentPane:renderInventory()
    local weapon = self.character:getPrimaryHandItem()
    if self.character:getPrimaryHandItem() ~= nil and self.character:getPrimaryHandItem():IsWeapon() then
        local weaponParts = {}
        local partCont = {}
        FWPInspectCollectWeaponPartsRecursive(self.character:getInventory(), weaponParts, partCont)

        local alreadyDoneList = {};
        local itemNum = 0
        local rowCount = -1
        for i=1, #weaponParts do
            local part = weaponParts[i];
            local weaponFullType = weapon:getFullType()

            -- For VFE
            if (VFEAttachmentParity ~= nil) then
                for vfepi, vfepv in ipairs(VFEAttachmentParity) do
                    if (vfepv == weapon:getFullType()) then
                        if (vfepi % 2 == 0) then
                            weaponFullType = VFEAttachmentParity[vfepi]
                        else
                            weaponFullType = VFEAttachmentParity[vfepi + 1]
                        end
                    end
                end
            end
            -- **

            if FWPInspectCanAttachPart(self.character, weapon, part, self.category) and not alreadyDoneList[FWPInspectGetPartKey(part)] then
                if FWPInspectPartTypeMatches(part, self.category) then
                    alreadyDoneList[FWPInspectGetPartKey(part)] = true;

                    if (math.fmod(itemNum, 5) == 0) then
                        rowCount = rowCount + 1
                    end

                    local x = FWPInspectUIV(2) + FWPInspectUIGridGap() * math.fmod(itemNum, 5)
                    local y = FWPInspectUIV(2) + FWPInspectUIGridGap() * rowCount

                    if FWPInspectShowPotentialAttachment then
                        self.potentialAttachment[part:getFullType()] = nil
                    end

                    local item = FWPInspectAddAttachmentButton:new(x, y, FWPInspectUIButtonSize(), FWPInspectUIButtonSize(), part, weapon, true, partCont[part:getID()], self.character)

                    -- Joypad only----------------
                    item.joy_x = math.fmod(itemNum, 5)
                    item.joy_y = rowCount
                    ------------------------------

                    table.insert(self.elements, item)
                    item:bringToTop()
                    self:addChild(item)

                    itemNum = itemNum + 1
                end
            end
        end

        if FWPInspectShowPotentialAttachment then
            local tempContainer = ItemContainer.new("potentialAttachment", nil, nil)
            for k,v in pairs(self.potentialAttachment) do
                local potentialPart = nil
                local okPotential, createdPotential = pcall(function() return tempContainer:AddItem(k) end)
                if okPotential then
                    potentialPart = createdPotential
                end
                local weaponFullType = weapon:getFullType()

                -- For VFE
                if (VFEAttachmentParity ~= nil) then
                    for vfepi, vfepv in ipairs(VFEAttachmentParity) do
                        if (vfepv == weapon:getFullType()) then
                            if (vfepi % 2 == 0) then
                                weaponFullType = VFEAttachmentParity[vfepi]
                            else
                                weaponFullType = VFEAttachmentParity[vfepi + 1]
                            end
                        end
                    end
                end
                -- **

                if FWPInspectCanAttachPart(self.character, weapon, potentialPart, self.category) then
                    if (math.fmod(itemNum, 5) == 0) then
                        rowCount = rowCount + 1
                    end

                    local x = FWPInspectUIV(2) + FWPInspectUIGridGap() * math.fmod(itemNum, 5)
                    local y = FWPInspectUIV(2) + FWPInspectUIGridGap() * rowCount

                    local item = FWPInspectAddAttachmentButton:new(x, y, FWPInspectUIButtonSize(), FWPInspectUIButtonSize(), potentialPart, weapon, false, nil, self.character)

                    -- Joypad only----------------
                    item.joy_x = math.fmod(itemNum, 5)
                    item.joy_y = rowCount
                    ------------------------------

                    table.insert(self.elements, item)
                    item:bringToTop()
                    self:addChild(item)

                    itemNum = itemNum + 1
                end

                tempContainer:clear()
            end
            tempContainer = nil
        end

        if (getJoypadFocus(self.character:getPlayerNum()) == self and #self.elements ~= 0) then
            self.elements[1].isJoypadFocused = true
            self.currentFocus = 0
        end

        self:setScrollHeight(FWPInspectUIV(42) * (rowCount + 1))

        if (self:getHeight() >= self:getScrollHeight()) then
            self:setWidth((FWPInspectUIButtonSize() * 5) + FWPInspectUIV(8))
        end
        if FWPUIScale and FWPUIScale.clampToScreen then
            FWPUIScale.clampToScreen(self, 8)
        end
    end
end

function FWPInspectSelectAttachmentPane:close()
    if (#self.elements ~= 0) then
        for i=1,#self.elements do
            FWPInspectCloseAttachmentButtonTooltip(self.elements[i])
        end
    end
    self.elements = {}
    self:setVisible(false)
    if FWPInspectActiveAttachmentPane ~= nil then
        FWPInspectActiveAttachmentPane[self.character:getPlayerNum()] = nil
    end
    setJoypadFocus(self.character:getPlayerNum(), self.origin)
end

function FWPInspectSelectAttachmentPane:onMouseDownOutside(x, y)
    if self:getIsVisible() and not self.vscroll:isMouseOver() then
        self:close()
    end
end

function FWPInspectSelectAttachmentPane:onGainJoypadFocus(joypadData)
	self.drawJoypadFocus = true
end

function FWPInspectSelectAttachmentPane:onLoseJoypadFocus(joypadData)
	self.drawJoypadFocus = false
end

function FWPInspectSelectAttachmentPane:onJoypadDown(button)
	if button == Joypad.BButton then
        self:close()
    elseif button == Joypad.AButton and #self.elements ~= 0 and self.elements[self.currentFocus + 1].enabled then
        self:close()
        self.elements[self.currentFocus + 1]:joypadConfirm()
	end
end

function FWPInspectSelectAttachmentPane:getBPrompt()
    return getText('IGUI_FWP_INSPECT_BACK')
end

function FWPInspectSelectAttachmentPane:getAPrompt()
    if #self.elements ~= 0 then
        return self.elements[self.currentFocus + 1]:joypadPrompt()
    end
end

function FWPInspectSelectAttachmentPane:getXPrompt()
    return nil
end

function FWPInspectSelectAttachmentPane:getYPrompt()
    return nil
end

function FWPInspectSelectAttachmentPane:onJoypadDirDown(joypadData)
    if (#self.elements ~= 0 ) then
        local currentCell = self.elements[self.currentFocus + 1]
        local targetIdx = (((currentCell.joy_y + 1) * 5) + currentCell.joy_x) + 1
        if targetIdx > 0 and targetIdx <= #self.elements then
            self.elements[targetIdx].isJoypadFocused = true
            currentCell.isJoypadFocused = false
            self.currentFocus = targetIdx - 1
            
            if (self.elements[self.currentFocus + 1].joy_y - 2 > 0) then
                self:setYScroll(-(FWPInspectUIGridGap() * (self.elements[self.currentFocus + 1].joy_y - 2)))
            end
        end
    end
end

function FWPInspectSelectAttachmentPane:onJoypadDirUp(joypadData)
    if (#self.elements ~= 0 ) then
        local currentCell = self.elements[self.currentFocus + 1]
        local targetIdx = (((currentCell.joy_y - 1) * 5) + currentCell.joy_x) + 1
        if targetIdx > 0 and targetIdx <= #self.elements then
            self.elements[targetIdx].isJoypadFocused = true
            currentCell.isJoypadFocused = false
            self.currentFocus = targetIdx - 1

            if self.elements[self.currentFocus + 1].joy_y < math.abs(self:getYScroll() / FWPInspectUIGridGap()) then
                self:setYScroll(self:getYScroll() + FWPInspectUIGridGap())
            end
        end
    end
end

function FWPInspectSelectAttachmentPane:onJoypadDirLeft(joypadData)
    if (#self.elements ~= 0 ) then
        local currentCell = self.elements[self.currentFocus + 1]
        local targetIdx = ((currentCell.joy_y * 5) + currentCell.joy_x - 1) + 1
        if targetIdx > 0 and targetIdx <= #self.elements then
            self.elements[targetIdx].isJoypadFocused = true
            currentCell.isJoypadFocused = false
            self.currentFocus = targetIdx - 1

            if self.elements[self.currentFocus + 1].joy_y < math.abs(self:getYScroll() / FWPInspectUIGridGap()) then
                self:setYScroll(self:getYScroll() + FWPInspectUIGridGap())
            end
        end
    end
end

function FWPInspectSelectAttachmentPane:onJoypadDirRight(joypadData)
    if (#self.elements ~= 0 ) then
        local currentCell = self.elements[self.currentFocus + 1]
        local targetIdx = ((currentCell.joy_y * 5) + currentCell.joy_x + 1) + 1
        if targetIdx > 0 and targetIdx <= #self.elements then
            self.elements[targetIdx].isJoypadFocused = true
            currentCell.isJoypadFocused = false
            self.currentFocus = targetIdx - 1
            
            if (self.elements[self.currentFocus + 1].joy_y - 2 > 0) then
                self:setYScroll(-(FWPInspectUIGridGap() * (self.elements[self.currentFocus + 1].joy_y - 2)))
            end
        end
    end
end

-- SELECT MAGAZINE PANE

FWPInspectSelectMagazinePane = ISPanelJoypad:derive("FWPInspectSelectMagazinePane")

function FWPInspectSelectMagazinePane:new(x, y, weapon, character)
    local o = {}
    local buttonSize = FWPInspectUIButtonSize()
    o = ISPanelJoypad:new(x, y, buttonSize * 5 + FWPInspectUIV(20), FWPInspectUIV(126));

    setmetatable(o, self)
    self.__index = self
    
    o.weapon = weapon
    o.backgroundColor = {r=0, g=0, b=0, a=1};
    o.borderColor = {r=0.9, g=0.9, b=0.9, a=0.7};
    o.origin = FWPInspectWindow[character:getPlayerNum()]
    o.character = character
    
    o.currentPrimaryItem = character:getPrimaryHandItem()
    o.itemWeight = character:getInventory():getCapacityWeight()
    o.itemCap = character:getInventory():getItems():size()
    o.elements = {}
    o.currentFocus = 0
    o.overrideBPrompt = true

    return o
end

function FWPInspectSelectMagazinePane:isValidPrompt()
    return true
end

function FWPInspectSelectMagazinePane:prerender()
	self:setStencilRect(0,0,self.width, self.height)
    self:drawRect(-self:getXScroll(), -self:getYScroll(), self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
end

function FWPInspectSelectMagazinePane:render()
    self:clearStencilRect()
	self:drawRectBorder(-self:getXScroll(), -self:getYScroll(), self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

function FWPInspectSelectMagazinePane:createChildren()
    self:addScrollBars(false)
	self:setScrollWithParent(false)
	self:setScrollChildren(true)
end

function FWPInspectSelectMagazinePane:onMouseWheel(del)
	self:setYScroll(self:getYScroll() - (del * FWPInspectUIV(42)))
	return true;
end

function FWPInspectSelectMagazinePane:update()
    if self and self:getIsVisible() then
        if (self.currentPrimaryItem ~= self.character:getPrimaryHandItem() or FWPInspectWindow[self.character:getPlayerNum()] == nil) then
            self:close()
        end

        if self.itemCap ~= self.character:getInventory():getItems():size() or
            self.itemWeight ~= self.character:getInventory():getCapacityWeight() then
            self.itemCap = self.character:getInventory():getItems():size()
            self.itemWeight = self.character:getInventory():getCapacityWeight()

            if (#self.elements ~= 0) then
                for i=1,#self.elements do
                    FWPInspectCloseAttachmentButtonTooltip(self.elements[i])
                    self:removeChild(self.elements[i])
                end
            end
            self.elements = {}

            self:renderInventory()
        end
    end
end

function FWPInspectSelectMagazinePane:renderInventory()
    local weapon = self.weapon
    local magList = {}
    local magCont = {}
    local inventory = self.character:getInventory()
    local magTypes = FWPInspectGetMagazineTypes(self.weapon)
    FWPInspectCollectMagazinesRecursive(inventory, magTypes, magList, magCont, inventory)

    if #magList > 0 then
        local itemNum = 0
        local rowCount = -1
        for i=1, #magList do
            if (math.fmod(itemNum, 5) == 0) then
                rowCount = rowCount + 1
            end

            local x = FWPInspectUIV(2) + FWPInspectUIGridGap() * math.fmod(itemNum, 5)
            local y = FWPInspectUIV(2) + FWPInspectUIGridGap() * rowCount
            local magazine = magList[i]
            local container = nil
            if magazine.getID then
                container = magCont[magazine:getID()]
            end

            local item = FWPInspectAddMagazineButton:new(x, y, FWPInspectUIButtonSize(), FWPInspectUIButtonSize(), magazine, weapon, self, container, self.character)

            -- Joypad only----------------
            item.joy_x = math.fmod(itemNum, 5)
            item.joy_y = rowCount
            ------------------------------

            table.insert(self.elements, item)
            item:bringToTop()
            self:addChild(item)

            itemNum = itemNum + 1
        end

        if (getJoypadFocus(self.character:getPlayerNum()) == self and #self.elements ~= 0 and self.currentFocus < #self.elements) then
            self.elements[self.currentFocus + 1].isJoypadFocused = true
        end

        self:setScrollHeight(FWPInspectUIV(42) * (rowCount + 1))

        if (self:getHeight() >= self:getScrollHeight()) then
            self:setWidth((FWPInspectUIButtonSize() * 5) + FWPInspectUIV(8))
        end
        if FWPUIScale and FWPUIScale.clampToScreen then
            FWPUIScale.clampToScreen(self, 8)
        end
    end
end

function FWPInspectSelectMagazinePane:close()
    self:setVisible(false)
    setJoypadFocus(self.character:getPlayerNum(), self.origin)
end

function FWPInspectSelectMagazinePane:onMouseDownOutside(x, y)
    if self:getIsVisible() and not self.vscroll:isMouseOver() then
        self:close()
    end
end

function FWPInspectSelectMagazinePane:onGainJoypadFocus(joypadData)
	self.drawJoypadFocus = true
end

function FWPInspectSelectMagazinePane:onLoseJoypadFocus(joypadData)
	self.drawJoypadFocus = false
end

function FWPInspectSelectMagazinePane:getBPrompt()
    return getText('IGUI_FWP_INSPECT_BACK')
end

function FWPInspectSelectMagazinePane:getAPrompt()
    if (#self.elements ~= 0) then
        return self.elements[self.currentFocus + 1]:joypadPrompt()
    end
end

function FWPInspectSelectMagazinePane:getXPrompt()
    return getText("IGUI_Controller_Interact")
end

function FWPInspectSelectMagazinePane:getYPrompt()
    return nil
end

function FWPInspectSelectMagazinePane:onJoypadDown(button)
	if button == Joypad.BButton then
        self:close()
    elseif button == Joypad.AButton and #self.elements ~= 0 then
        self:close()
        self.elements[self.currentFocus + 1]:joypadConfirm()
    elseif button == Joypad.XButton and #self.elements ~= 0  then
        self.elements[self.currentFocus + 1]:joypadMenu()
	end
end

function FWPInspectSelectMagazinePane:onJoypadDirDown(joypadData)
    if (#self.elements ~= 0 ) then
        local currentCell = self.elements[self.currentFocus + 1]
        local targetIdx = (((currentCell.joy_y + 1) * 5) + currentCell.joy_x) + 1
        if targetIdx > 0 and targetIdx <= #self.elements then
            self.elements[targetIdx].isJoypadFocused = true
            currentCell.isJoypadFocused = false
            self.currentFocus = targetIdx - 1
            
            if (self.elements[self.currentFocus + 1].joy_y - 2 > 0) then
                self:setYScroll(-(FWPInspectUIGridGap() * (self.elements[self.currentFocus + 1].joy_y - 2)))
            end
        end
    end
end

function FWPInspectSelectMagazinePane:onJoypadDirUp(joypadData)
    if (#self.elements ~= 0 ) then
        local currentCell = self.elements[self.currentFocus + 1]
        local targetIdx = (((currentCell.joy_y - 1) * 5) + currentCell.joy_x) + 1
        if targetIdx > 0 and targetIdx <= #self.elements then
            self.elements[targetIdx].isJoypadFocused = true
            currentCell.isJoypadFocused = false
            self.currentFocus = targetIdx - 1

            if self.elements[self.currentFocus + 1].joy_y < math.abs(self:getYScroll() / FWPInspectUIGridGap()) then
                self:setYScroll(self:getYScroll() + FWPInspectUIGridGap())
            end
        end
    end
end

function FWPInspectSelectMagazinePane:onJoypadDirLeft(joypadData)
    if (#self.elements ~= 0 ) then
        local currentCell = self.elements[self.currentFocus + 1]
        local targetIdx = ((currentCell.joy_y * 5) + currentCell.joy_x - 1) + 1
        if targetIdx > 0 and targetIdx <= #self.elements then
            self.elements[targetIdx].isJoypadFocused = true
            currentCell.isJoypadFocused = false
            self.currentFocus = targetIdx - 1

            if self.elements[self.currentFocus + 1].joy_y < math.abs(self:getYScroll() / FWPInspectUIGridGap()) then
                self:setYScroll(self:getYScroll() + FWPInspectUIGridGap())
            end
        end
    end
end

function FWPInspectSelectMagazinePane:onJoypadDirRight(joypadData)
    if (#self.elements ~= 0 ) then
        local currentCell = self.elements[self.currentFocus + 1]
        local targetIdx = ((currentCell.joy_y * 5) + currentCell.joy_x + 1) + 1
        if targetIdx > 0 and targetIdx <= #self.elements then
            self.elements[targetIdx].isJoypadFocused = true
            currentCell.isJoypadFocused = false
            self.currentFocus = targetIdx - 1
            if (self.elements[self.currentFocus + 1].joy_y - 2 > 0) then
                self:setYScroll(-(FWPInspectUIGridGap() * (self.elements[self.currentFocus + 1].joy_y - 2)))
            end
        end
    end
end

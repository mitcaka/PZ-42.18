-- =============================================================================
-- Cat Safehouse Utilities — Client UI (ISSafehouseUI extension)
-- =============================================================================
if isServer() then return end

Cat_SafehouseUtilities = Cat_SafehouseUtilities or {}
Cat_SafehouseUtilities.statusCache = Cat_SafehouseUtilities.statusCache or {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

-- ---------------------------------------------------------------------------
-- Server response handler
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= "Cat_SafehouseUtilities" then return end

    if command == "statusUpdate" then
        Cat_SafehouseUtilities.statusCache[args.key] = args
    elseif command == "paymentError" then
        local player = getSpecificPlayer(0)
        if player then
            HaloTextHelper.addBadText(player, args.reason or "Payment failed.")
        end
    elseif command == "haloText" then
        local player = getSpecificPlayer(0)
        if player then
            if args.bad then
                HaloTextHelper.addBadText(player, args.text or "")
            else
                HaloTextHelper.addGoodText(player, args.text or "")
            end
        end
    elseif command == "syncBlocked" then
        Cat_SafehouseUtilities.blockedKeys = {}
        if args.keys then
            for _, key in ipairs(args.keys) do
                Cat_SafehouseUtilities.blockedKeys[key] = true
            end
        end
    end
end
Events.OnServerCommand.Add(onServerCommand)

-- ---------------------------------------------------------------------------
-- Request blocked sync on join
-- ---------------------------------------------------------------------------
local function requestSyncOnTick()
    if not getPlayer() then return end
    sendClientCommand("Cat_SafehouseUtilities", "requestBlockedSync", {})
    Events.OnTick.Remove(requestSyncOnTick)
end
Events.OnTick.Add(requestSyncOnTick)

-- ---------------------------------------------------------------------------
-- Payment dialog callbacks
-- ---------------------------------------------------------------------------
local function onPayBankDialog(target, button)
    if button.internal ~= "OK" then return end
    local parent = button.parent
    local periods = tonumber(parent.entry:getText())
    if not periods or periods <= 0 then
        HaloTextHelper.addBadText(getSpecificPlayer(0), "Enter a valid number.")
        return
    end
    local safehouse = parent.safehouse
    if not safehouse then return end
    local key = Cat_SafehouseUtilities.getSafehouseKey(safehouse)
    local rate = Cat_SafehouseUtilities.getCyclePrice()
    local cost = periods * rate

    sendClientCommand("Cat_SafehouseUtilities", "payBank", {
        safehouseKey = key,
        periods = periods,
        cost = cost,
    })
end

-- ---------------------------------------------------------------------------
-- ISSafehouseUI patch
-- ---------------------------------------------------------------------------
local original_initialise = ISSafehouseUI.initialise
function ISSafehouseUI:initialise()
    original_initialise(self)

    if not Cat_SafehouseUtilities.isEnabled() then return end

    local x = UI_BORDER_SPACING + 1
    local y = self.respawn:getBottom() + UI_BORDER_SPACING
    local panelW = self.width - (UI_BORDER_SPACING + 1) * 2

    -- Separator line
    self.catUtilSeparator = ISLabel:new(x, y, 2, string.rep("-", 60), 0.5, 0.5, 0.5, 1, UIFont.Small, true)
    self.catUtilSeparator:initialise()
    self.catUtilSeparator:instantiate()
    self:addChild(self.catUtilSeparator)
    y = y + UI_BORDER_SPACING

    -- Status label
    self.catUtilStatus = ISLabel:new(x, y, FONT_HGT_SMALL, "Utilities: checking...", 1, 1, 1, 1, UIFont.Small, true)
    self.catUtilStatus:initialise()
    self.catUtilStatus:instantiate()
    self:addChild(self.catUtilStatus)
    y = y + FONT_HGT_SMALL + 4

    -- Rate label
    local cycleLabel = Cat_SafehouseUtilities.getCycleLabel()
    local rate = Cat_SafehouseUtilities.getCyclePrice()
    self.catUtilRate = ISLabel:new(x, y, FONT_HGT_SMALL, "Rate: $" .. rate .. " / " .. cycleLabel, 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.catUtilRate:initialise()
    self.catUtilRate:instantiate()
    self:addChild(self.catUtilRate)
    y = y + FONT_HGT_SMALL + 4

    -- Time remaining label
    self.catUtilTime = ISLabel:new(x, y, FONT_HGT_SMALL, "Time remaining: --", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.catUtilTime:initialise()
    self.catUtilTime:instantiate()
    self:addChild(self.catUtilTime)
    y = y + FONT_HGT_SMALL + UI_BORDER_SPACING

    -- Only owner can pay / redeem
    local isOwner = self.safehouse and self.safehouse:getOwner() == self.player:getUsername()
    if isOwner then
        local btnWid = self.releaseSafehouse:getWidth()
        local btnGap = 10

        -- Pay with Bank button
        self.catUtilPayBtn = ISButton:new(x, y, btnWid, BUTTON_HGT, "Pay with Bank", self, ISSafehouseUI.onClickPayBank)
        self.catUtilPayBtn:initialise()
        self.catUtilPayBtn:instantiate()
        self.catUtilPayBtn.borderColor = self.buttonBorderColor
        self:addChild(self.catUtilPayBtn)

        -- Redeem Card button
        self.catUtilCardBtn = ISButton:new(x + btnWid + btnGap, y, btnWid, BUTTON_HGT, "Redeem Card", self, ISSafehouseUI.onClickRedeemCard)
        self.catUtilCardBtn:initialise()
        self.catUtilCardBtn:instantiate()
        self.catUtilCardBtn.borderColor = self.buttonBorderColor
        self:addChild(self.catUtilCardBtn)
        y = y + BUTTON_HGT + UI_BORDER_SPACING
    end

    -- Shift OK and Release buttons down
    self.no:setY(y)
    self.releaseSafehouse:setY(y)
    y = y + BUTTON_HGT + UI_BORDER_SPACING

    self:setHeight(y)

    -- Request current status from server
    local key = Cat_SafehouseUtilities.getSafehouseKey(self.safehouse)
    if key then
        sendClientCommand("Cat_SafehouseUtilities", "requestStatus", { safehouseKey = key })
    end
end

local original_prerender = ISSafehouseUI.prerender
function ISSafehouseUI:prerender()
    original_prerender(self)
    if self.catUtilStatus and self.safehouse then
        local key = Cat_SafehouseUtilities.getSafehouseKey(self.safehouse)
        local status = key and Cat_SafehouseUtilities.statusCache[key]
        if status then
            if status.exempt then
                self.catUtilStatus:setName("Utilities: EXEMPT")
                self.catUtilStatus:setColor(0.3, 0.5, 1.0)
                self.catUtilTime:setName("Time remaining: ∞")
            else
                local now = getGameTime():getWorldAgeHours()
                local hoursLeft = (status.expires or now) - now
                if hoursLeft > 0 then
                    self.catUtilStatus:setName("Utilities: ACTIVE")
                    self.catUtilStatus:setColor(0.3, 1.0, 0.3)
                    self.catUtilTime:setName("Time remaining: " .. Cat_SafehouseUtilities.formatTimeRemaining(hoursLeft))
                else
                    self.catUtilStatus:setName("Utilities: DISCONNECTED")
                    self.catUtilStatus:setColor(1.0, 0.3, 0.3)
                    self.catUtilTime:setName("Time remaining: EXPIRED")
                end
            end
            -- Update rate label if cycle changed
            if self.catUtilRate and status.cycle then
                self.catUtilRate:setName("Rate: $" .. (status.rate or 0) .. " / " .. status.cycle:lower())
            end
        else
            self.catUtilStatus:setName("Utilities: checking...")
            self.catUtilStatus:setColor(1, 1, 1)
        end
    end
end

function ISSafehouseUI:onClickPayBank()
    local rate = Cat_SafehouseUtilities.getCyclePrice()
    if rate == 0 then
        HaloTextHelper.addGoodText(self.player, "Utilities are free on this server.")
        return
    end
    local cycleLabel = Cat_SafehouseUtilities.getCycleLabel()
    local modal = ISTextBox:new(
        self.x + 50, self.y + 50, 280, 180,
        "Pay for how many " .. cycleLabel .. "s? (Rate: $" .. rate .. "/" .. cycleLabel .. ")",
        "1", nil, onPayBankDialog
    )
    modal.safehouse = self.safehouse
    modal:initialise()
    modal:addToUIManager()
end

function ISSafehouseUI:onClickRedeemCard()
    local player = self.player
    if not player then return end
    local inv = player:getInventory()
    local foundCards = {}
    for itemType, _ in pairs(Cat_SafehouseUtilities.CARD_DURATIONS) do
        local card = inv:getFirstTypeRecurse(itemType)
        if card then
            table.insert(foundCards, card)
        end
    end

    if #foundCards == 0 then
        HaloTextHelper.addBadText(player, "No pre-paid utility cards found.")
        return
    end

    -- Redeem the first card found (players can repeat for multiple cards)
    local card = foundCards[1]
    local itemType = card:getFullType()
    local dur = Cat_SafehouseUtilities.getCardDuration(itemType)
    local label = dur .. " hours"
    if dur >= 24 then label = (dur / 24) .. " days" end
    local itemName = card:getDisplayName()
    local msg = "Redeem " .. itemName .. " (" .. label .. ")?"

    local modal = ISModalDialog:new(0, 0, 350, 150, msg, true, self, function(ui, button)
        if button.internal ~= "YES" then return end
        local key = Cat_SafehouseUtilities.getSafehouseKey(ui.safehouse)
        sendClientCommand("Cat_SafehouseUtilities", "redeemCard", {
            safehouseKey = key,
            cardType = itemType,
        })
    end)
    modal:initialise()
    modal:addToUIManager()
    modal.moveWithMouse = true
end

-- ---------------------------------------------------------------------------
-- Block radio/TV toggles in expired safehouses
-- ---------------------------------------------------------------------------
local function hookRadioAction()
    if not ISRadioAction then return end
    local original_ISRadioAction_isValid = ISRadioAction.isValid
    function ISRadioAction:isValid()
        if not original_ISRadioAction_isValid(self) then return false end
        if not Cat_SafehouseUtilities.isEnabled() then return true end
        local sq = self.device and self.device:getSquare()
        if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
            return false
        end
        return true
    end
end

if ISRadioAction then
    hookRadioAction()
else
    Events.OnGameStart.Add(hookRadioAction)
end

-- ---------------------------------------------------------------------------
-- TV / Grid Power UI patch — show "Utilities Disconnected" when blocked
-- ---------------------------------------------------------------------------
local function patchRWMGridPower()
    if not RWMGridPower then return end

    local original_toggleOnOff = RWMGridPower.toggleOnOff
    function RWMGridPower:toggleOnOff()
        if self.device and self.device:getSquare() then
            local sq = self.device:getSquare()
            if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
                local player = self.player or getSpecificPlayer(0)
                if player then
                    HaloTextHelper.addBadText(player, "Utilities disconnected.")
                end
                return
            end
        end
        original_toggleOnOff(self)
    end

    local original_render = RWMGridPower.render
    function RWMGridPower:render()
        if self.device and self.device:getSquare() then
            local sq = self.device:getSquare()
            if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
                ISPanel.render(self)
                local x = self.toggleOnOffButton:getX()+self.toggleOnOffButton:getWidth()+UI_BORDER_SPACING
                local y = (self.height - FONT_HGT_SMALL) / 2
                self:drawText(getText("IGUI_Cat_SafehouseUtilities_UtilitiesDisconnected"), x, y, 1.0, 0.3, 0.3, 1, UIFont.Small)
                return
            end
        end
        original_render(self)
    end
end

if RWMGridPower then
    patchRWMGridPower()
else
    Events.OnGameStart.Add(patchRWMGridPower)
end

-- ---------------------------------------------------------------------------
-- Admin context menu
-- ---------------------------------------------------------------------------
local function isPlayerAdmin(player)
    if not player then return false end
    local access = player:getAccessLevel()
    if access == "admin" or access == "Admin" then return true end
    if access == "moderator" or access == "Moderator" then return true end
    if isAdmin and isAdmin() then return true end
    if isDebugEnabled and isDebugEnabled() then return true end
    return false
end

local function addAdminUtilitiesMenu(playerNum, context, worldObjects)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    if not isPlayerAdmin(player) then return end

    -- Find the safehouse the admin is standing in
    local psq = player:getCurrentSquare()
    if not psq then return end

    local sh = SafeHouse.getSafeHouse(psq)
    if not sh then return end

    local key = Cat_SafehouseUtilities.getSafehouseKey(sh)
    if not key then return end

    local adminMenu = context:getNew(context)
    context:addSubMenu(context:addOption("[Admin] Utilities"), adminMenu)

    -- Add Time submenu
    local addMenu = context:getNew(context)
    adminMenu:addSubMenu(adminMenu:addOption("Add Time"), addMenu)

    local timeOptions = {
        { label = "1 Hour", hours = 1 },
        { label = "12 Hours", hours = 12 },
        { label = "24 Hours", hours = 24 },
        { label = "1 Week", hours = 24 * 7 },
        { label = "1 Month", hours = 24 * 30 },
    }

    for _, opt in ipairs(timeOptions) do
        addMenu:addOption(opt.label, { safehouseKey = key, hours = opt.hours }, function(data)
            sendClientCommand("Cat_SafehouseUtilities", "adminAddTime", data)
        end)
    end

    -- Disconnect Now
    adminMenu:addOption("Disconnect Now", { safehouseKey = key }, function(data)
        sendClientCommand("Cat_SafehouseUtilities", "adminDisconnect", data)
    end)

    -- Toggle Exempt
    adminMenu:addOption("Toggle Exempt", { safehouseKey = key }, function(data)
        sendClientCommand("Cat_SafehouseUtilities", "adminToggleExempt", data)
    end)
end

Events.OnFillWorldObjectContextMenu.Add(addAdminUtilitiesMenu)

-- ---------------------------------------------------------------------------
-- Override context menu for blocked utility sources
-- ---------------------------------------------------------------------------
local blockedFluidCallbacks = {
    [ISWorldObjectContextMenu.onFluidTransfer] = true,
    [ISWorldObjectContextMenu.onFluidInfo] = true,
    [ISWorldObjectContextMenu.onFluidEmpty] = true,
    [ISWorldObjectContextMenu.onDrink] = true,
    [ISWorldObjectContextMenu.onTakeWater] = true,
    [ISWorldObjectContextMenu.onWashYourself] = true,
    [ISWorldObjectContextMenu.onWashClothing] = true,
}

local function showBlockedMessage(playerObj)
    if not playerObj then return end
    local now = getTimestampMs()
    if not Cat_SafehouseUtilities._lastBlockedMsg or (now - Cat_SafehouseUtilities._lastBlockedMsg > 3000) then
        Cat_SafehouseUtilities._lastBlockedMsg = now
        HaloTextHelper.addBadText(playerObj, "Utilities disconnected. Water unavailable.")
    end
end

local function patchBlockedCallback(original)
    return function(...)
        local args = {...}
        local playerObj = nil
        local sq = nil
        -- Try to extract player and square from various callback signatures
        if type(args[1]) == "number" then
            playerObj = getSpecificPlayer(args[1])
        elseif args[1] and args[1].getSquare then
            playerObj = args[1]
        end
        for _, arg in ipairs(args) do
            if arg and arg.getGameEntity then
                local entity = arg:getGameEntity()
                if entity and entity.getSquare then
                    sq = entity:getSquare()
                    break
                end
            elseif arg and arg.getSquare then
                sq = arg:getSquare()
                break
            end
        end
        if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
            showBlockedMessage(playerObj)
            return
        end
        return original(...)
    end
end

ISWorldObjectContextMenu.onFluidTransfer = patchBlockedCallback(ISWorldObjectContextMenu.onFluidTransfer)
ISWorldObjectContextMenu.onFluidInfo = patchBlockedCallback(ISWorldObjectContextMenu.onFluidInfo)
ISWorldObjectContextMenu.onFluidEmpty = patchBlockedCallback(ISWorldObjectContextMenu.onFluidEmpty)
ISWorldObjectContextMenu.onDrink = patchBlockedCallback(ISWorldObjectContextMenu.onDrink)
ISWorldObjectContextMenu.onTakeWater = patchBlockedCallback(ISWorldObjectContextMenu.onTakeWater)
ISWorldObjectContextMenu.onWashYourself = patchBlockedCallback(ISWorldObjectContextMenu.onWashYourself)
ISWorldObjectContextMenu.onWashClothing = patchBlockedCallback(ISWorldObjectContextMenu.onWashClothing)

local original_createMenu = ISWorldObjectContextMenu.createMenu
function ISWorldObjectContextMenu.createMenu(player, worldobjects, x, y, test)
    local result = original_createMenu(player, worldobjects, x, y, test)
    if test or not result then return result end
    if not Cat_SafehouseUtilities.isEnabled() then return result end

    local hasBlockedUtility = false
    for _, obj in ipairs(worldobjects) do
        local sq = obj:getSquare()
        if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
            if obj.getFluidContainer or obj.getLights or obj.getDeviceData or instanceof(obj, "IsoLightSwitch") then
                hasBlockedUtility = true
                break
            end
        end
    end

    if not hasBlockedUtility then return result end

    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = "Utilities disconnected. Pay your bill to restore water and power."

    local warning = result:addOptionOnTop(getText("IGUI_Cat_SafehouseUtilities_UtilitiesDisconnected"), nil, nil)
    warning.notAvailable = true
    warning.toolTip = tooltip

    local function processMenu(menu)
        for _, option in ipairs(menu.options) do
            if not option then break end
            local isUtilityOption = false

            -- Match known Lua callbacks
            if blockedFluidCallbacks[option.onSelect] then
                isUtilityOption = true
            end

            -- Match Lifestyle callbacks (soft compat, no hard dep)
            if not isUtilityOption then
                if (_G.BathContextMenu and option.onSelect == BathContextMenu.onAction)
                    or (_G.ShowerContextMenu and option.onSelect == ShowerContextMenu.onAction)
                    or (_G.ToiletContextMenu and option.onSelect == ToiletContextMenu.onAction) then
                    isUtilityOption = true
                end
            end

            -- Match by translated name (common fluid/water actions)
            if not isUtilityOption then
                local name = option.name
                if name == getText("ContextMenu_Drink")
                    or name == getText("ContextMenu_Fill")
                    or name == getText("ContextMenu_FillAll")
                    or name == getText("ContextMenu_FillOne")
                    or name == getText("ContextMenu_AddFluid")
                    or name == getText("ContextMenu_AddFluidFromItem")
                    or name == getText("ContextMenu_Empty")
                    or name == getText("ContextMenu_WashYourself")
                    or name == getText("ContextMenu_WashClothing")
                    or name == getText("ContextMenu_Wash")
                    or name == getText("ContextMenu_Vehicle_Wash")
                    or name == getText("ContextMenu_WashAllClothing")
                    or name == getText("ContextMenu_WashAllContainer")
                    or name == getText("ContextMenu_WashAllWeapon")
                    or name == getText("ContextMenu_WashAllBandage")
                    or name == getText("ContextMenu_CleanBandageEtc")
                    -- Lifestyle names (EN fallback; callbacks above are primary)
                    or name == "Prepare a Bath"
                    or name == "Prepare a Bubble Bath"
                    or name == "Take a Bath (NO HOT WATER)"
                    or name == "Quick shower"
                    or name == "Quick shower (NO HOT WATER)"
                    or name == "Flush toilet" then
                    isUtilityOption = true
                end
            end

            -- Match B42 FluidContainer parameters
            if not isUtilityOption then
                for j = 1, 10 do
                    local param = option["param" .. j]
                    if param and (type(param) == "userdata" or type(param) == "table") and param.getGameEntity then
                        local ok, entity = pcall(function() return param:getGameEntity() end)
                        if ok and entity and entity.getSquare then
                            local sq = entity:getSquare()
                            if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
                                isUtilityOption = true
                                break
                            end
                        end
                    end
                end
            end

            if isUtilityOption then
                option.name = getText("IGUI_Cat_SafehouseUtilities_UtilitiesDisconnected")
                option.notAvailable = true
                option.toolTip = tooltip
            end

            -- Recurse into submenus
            if option.subOption then
                local subMenu = menu:getSubMenu(option.subOption)
                if subMenu then
                    processMenu(subMenu)
                end
            end
        end
    end

    processMenu(result)
    return result
end

-- ---------------------------------------------------------------------------
-- Soft compatibility: Lifestyle mod (no hard dependency)
-- Intercept Lifestyle timed actions queued directly and show feedback.
-- ---------------------------------------------------------------------------
local function getLifestyleActionSquare(action)
    if not action then return nil end
    if action.Type == "LSUseShower" and action.showerObject then
        return action.showerObject:getSquare()
    elseif action.Type == "LSUseTub" and action.mainTubObj then
        return action.mainTubObj:getSquare()
    elseif action.Type == "LSPrepareBath" and action.bathObject then
        return action.bathObject:getSquare()
    elseif action.Type == "LSFlushToilet" and action.toiletObject then
        return action.toiletObject:getSquare()
    end
    return nil
end

local function blockLifestyleAction(action)
    if not action or not Cat_SafehouseUtilities.isEnabled() then return false end
    local sq = getLifestyleActionSquare(action)
    if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
        if action.character and action.character.getPlayerNum then
            HaloTextHelper.addTextWithArrow(action.character, getText("IGUI_Cat_SafehouseUtilities_UtilitiesDisconnected"), false, 255, 100, 100)
        end
        return true
    end
    return false
end

local original_ISTimedActionQueue_add = ISTimedActionQueue.add
ISTimedActionQueue.add = function(action)
    if blockLifestyleAction(action) then
        return nil
    end
    return original_ISTimedActionQueue_add(action)
end

local original_ISTimedActionQueue_addAfter = ISTimedActionQueue.addAfter
ISTimedActionQueue.addAfter = function(previousAction, action)
    if blockLifestyleAction(action) then
        return nil
    end
    return original_ISTimedActionQueue_addAfter(previousAction, action)
end

print("[Cat_SafehouseUtilities] Client UI loaded.")

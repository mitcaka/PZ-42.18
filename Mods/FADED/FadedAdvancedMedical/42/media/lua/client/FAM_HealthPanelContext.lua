if isServer() then return end

require "FAM_Core"
require "FAM_TriagePanel"
require "TimedActions/ISMedicalCheckAction"
require "TimedActions/FAM_MedicalCheckAction"
require "TimedActions/FAM_ApplyTreatmentAction"
require "TimedActions/FAM_FieldAmputationAction"
require "TimedActions/FAM_FitProstheticAction"
require "TimedActions/FAM_RemoveProstheticAction"

FAMHealthPanelContext = FAMHealthPanelContext or {}
-- Keep FAM standalone except for the vanilla body-part context submenu.
FAMHealthPanelContext.enableHealthPanelContextMenu = true
FAMHealthPanelContext.showFamChartButton = true
FAMHealthPanelContext.preferFamHealthPanel = false
FAMHealthPanelContext.preferFamMedicalCheck = true
FAMHealthPanelContext.openFamAfterMedicalCheck = true
FAMHealthPanelContext.AUTO_OPEN_BLOCK_TICKS = 90
FAMHealthPanelContext.autoOpenBlockTicks = FAMHealthPanelContext.autoOpenBlockTicks or FAMHealthPanelContext.AUTO_OPEN_BLOCK_TICKS
FAMHealthPanelContext.CHART_BUTTON_SIZE = 34
FAMHealthPanelContext.CHART_BUTTON_MARGIN = 8
FAMHealthPanelContext.chartButtonPosition = FAMHealthPanelContext.chartButtonPosition or nil

local function makeTooltip(textKey)
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)
    tooltip.description = getText(textKey)
    return tooltip
end

local function getDoctor(panel)
    if panel and panel.getDoctor then
        return panel:getDoctor()
    end
    return panel and (panel.otherPlayer or panel.character) or nil
end

local function getPatient(panel)
    if panel and panel.getPatient then
        return panel:getPatient()
    end
    return panel and panel.character or nil
end

local function getContextPlayerNum(panel, doctor)
    local character = doctor or (panel and (panel.otherPlayer or panel.character)) or (getPlayer and getPlayer() or nil)
    if character and character.getPlayerNum then
        return character:getPlayerNum()
    end
    return 0
end

local function isHealthCheatMode()
    if ISHealthPanel and ISHealthPanel.cheat == true then
        return true
    end
    if getDebug and getDebug() then
        return true
    end
    if isDebugEnabled and isDebugEnabled() then
        return true
    end
    return false
end

local function canReachFamPatient(target, requester)
    if not target or not requester then
        return false
    end
    if target == requester then
        return true
    end
    if FAM.isMedicalCheat(requester) then
        return true
    end
    if ISHealthPanel
        and ISHealthPanel.IsCharactersInSameCar
        and ISHealthPanel.IsCharactersInSameCar(requester, target) then
        return true
    end
    if luautils and luautils.walkAdj and requester.getCurrentSquare and luautils.walkAdj(target, requester:getCurrentSquare()) then
        return true
    end
    if requester.getX and target.getX then
        local sameLevel = not requester.getZ or not target.getZ or requester:getZ() == target:getZ()
        return sameLevel
            and math.abs(requester:getX() - target:getX()) <= 2
            and math.abs(requester:getY() - target:getY()) <= 2
    end
    return false
end

local function transferToDoctor(doctor, item)
    if not item or item:getContainer() == doctor:getInventory() then
        return nil
    end
    if ISInventoryTransferUtil and ISInventoryTransferUtil.newInventoryTransferAction then
        local action = ISInventoryTransferUtil.newInventoryTransferAction(doctor, item, item:getContainer(), doctor:getInventory())
        ISTimedActionQueue.add(action)
        return action
    end
    return nil
end

local function refreshOpenTriage(doctor, patient)
    if FAM_TriagePanel.instance then
        FAM_TriagePanel.open(doctor, patient)
    end
end

function FAMHealthPanelContext.openFromPanel(panel)
    local doctor = getDoctor(panel)
    local patient = getPatient(panel)
    if doctor and patient then
        FAM_TriagePanel.open(doctor, patient)
    end
end

function FAMHealthPanelContext.openFromMedicalCheck(doctor, patient)
    if not doctor or not patient then
        return
    end
    if FAM_ClientCommands and FAM_ClientCommands.recordClinicalAssessment then
        FAM_ClientCommands.recordClinicalAssessment(doctor, patient)
    else
        FAM.performClinicalAssessment(doctor, patient)
    end
    FAM_TriagePanel.open(doctor, patient)
    if doctor.startReceivingBodyDamageUpdates then
        doctor:startReceivingBodyDamageUpdates(patient)
    end
end

function FAMHealthPanelContext.blockHealthAutoOpen()
    FAMHealthPanelContext.autoOpenBlockTicks = FAMHealthPanelContext.AUTO_OPEN_BLOCK_TICKS
end

function FAMHealthPanelContext.tickHealthAutoOpenBlock()
    local ticks = tonumber(FAMHealthPanelContext.autoOpenBlockTicks) or 0
    if ticks > 0 then
        FAMHealthPanelContext.autoOpenBlockTicks = ticks - 1
    end
end

function FAMHealthPanelContext.canAutoOpenFromHealthPanel(panel)
    if not FAMHealthPanelContext.preferFamHealthPanel then
        return false
    end
    if isHealthCheatMode() then
        return false
    end
    if (tonumber(FAMHealthPanelContext.autoOpenBlockTicks) or 0) > 0 then
        return false
    end
    return getDoctor(panel) ~= nil and getPatient(panel) ~= nil
end

function FAMHealthPanelContext.onFamChartButton(panel, button)
    FAMHealthPanelContext.openFromPanel(panel)
end

local function getPanelDimension(panel, methodName, fieldName)
    if panel and panel[methodName] then
        return panel[methodName](panel)
    end
    return panel and panel[fieldName] or 0
end

function FAMHealthPanelContext.clampChartButtonPosition(panel, x, y)
    local size = FAMHealthPanelContext.CHART_BUTTON_SIZE
    local margin = FAMHealthPanelContext.CHART_BUTTON_MARGIN
    local panelWidth = getPanelDimension(panel, "getWidth", "width")
    local panelHeight = getPanelDimension(panel, "getHeight", "height")
    local maxX = math.max(margin, panelWidth - size - margin)
    local maxY = math.max(margin, panelHeight - size - margin)
    return FAM.clamp(x, margin, maxX), FAM.clamp(y, margin, maxY)
end

function FAMHealthPanelContext.defaultChartButtonPosition(panel)
    local size = FAMHealthPanelContext.CHART_BUTTON_SIZE
    local margin = FAMHealthPanelContext.CHART_BUTTON_MARGIN
    local panelWidth = getPanelDimension(panel, "getWidth", "width")
    local x = panel.fitness and (panel.fitness:getRight() + 8) or math.max(margin, panelWidth - size - margin)
    local y = panel.fitness and panel.fitness:getY() or 11
    return FAMHealthPanelContext.clampChartButtonPosition(panel, x, y)
end

function FAMHealthPanelContext.getChartButtonPosition(panel)
    if FAMHealthPanelContext.chartButtonPosition then
        return FAMHealthPanelContext.clampChartButtonPosition(panel, FAMHealthPanelContext.chartButtonPosition.x, FAMHealthPanelContext.chartButtonPosition.y)
    end
    return FAMHealthPanelContext.defaultChartButtonPosition(panel)
end

function FAMHealthPanelContext.saveChartButtonPosition(panel, button)
    if not panel or not button then
        return
    end
    local x, y = FAMHealthPanelContext.clampChartButtonPosition(panel, button:getX(), button:getY())
    FAMHealthPanelContext.chartButtonPosition = { x = x, y = y }
    button:setX(x)
    button:setY(y)
end

function FAMHealthPanelContext.attachChartButtonDrag(panel, button)
    button.famPanel = panel
    button.famDragging = false
    button.famDragMoved = false

    button.onMouseDown = function(buttonSelf, x, y)
        buttonSelf.famDragging = true
        buttonSelf.famDragMoved = false
        buttonSelf.famDragStartX = buttonSelf:getX()
        buttonSelf.famDragStartY = buttonSelf:getY()
        return true
    end

    local function moveButton(buttonSelf, dx, dy)
        if not buttonSelf.famDragging then
            return false
        end
        local panelRef = buttonSelf.famPanel
        local x, y = FAMHealthPanelContext.clampChartButtonPosition(panelRef, buttonSelf:getX() + dx, buttonSelf:getY() + dy)
        buttonSelf:setX(x)
        buttonSelf:setY(y)
        if math.abs(x - (buttonSelf.famDragStartX or x)) + math.abs(y - (buttonSelf.famDragStartY or y)) > 3 then
            buttonSelf.famDragMoved = true
        end
        FAMHealthPanelContext.chartButtonPosition = { x = x, y = y }
        return true
    end

    button.onMouseMove = function(buttonSelf, dx, dy)
        return moveButton(buttonSelf, dx, dy)
    end

    button.onMouseMoveOutside = function(buttonSelf, dx, dy)
        return moveButton(buttonSelf, dx, dy)
    end

    button.onMouseUp = function(buttonSelf, x, y)
        local moved = buttonSelf.famDragMoved == true
        buttonSelf.famDragging = false
        FAMHealthPanelContext.saveChartButtonPosition(buttonSelf.famPanel, buttonSelf)
        if not moved then
            FAMHealthPanelContext.onFamChartButton(buttonSelf.famPanel, buttonSelf)
        end
        return true
    end

    button.onMouseUpOutside = function(buttonSelf, x, y)
        buttonSelf.famDragging = false
        FAMHealthPanelContext.saveChartButtonPosition(buttonSelf.famPanel, buttonSelf)
        return true
    end
end

function FAMHealthPanelContext.addFamChartButton(panel)
    if not FAMHealthPanelContext.showFamChartButton or not panel or panel.famChartButton then
        return
    end
    local size = FAMHealthPanelContext.CHART_BUTTON_SIZE
    local x, y = FAMHealthPanelContext.getChartButtonPosition(panel)
    panel.famChartButton = ISButton:new(x, y, size, size, "", nil, nil)
    panel.famChartButton.internal = "FAM_CHART"
    panel.famChartButton.anchorTop = false
    panel.famChartButton.anchorBottom = true
    panel.famChartButton:initialise()
    panel.famChartButton:instantiate()
    panel.famChartButton.iconTexture = getTexture("media/ui/FAM/TriageIcon.png")
    panel.famChartButton.joypadTextureWH = 26
    panel.famChartButton.tooltip = getText("IGUI_FAM_OpenPatientChart")
    panel.famChartButton.backgroundColor = { r = 0.02, g = 0.12, b = 0.05, a = 0.82 }
    panel.famChartButton.backgroundColorMouseOver = { r = 0.04, g = 0.24, b = 0.1, a = 0.92 }
    panel.famChartButton.borderColor = { r = 0.1, g = 0.9, b = 0.45, a = 0.9 }
    FAMHealthPanelContext.attachChartButtonDrag(panel, panel.famChartButton)
    panel:addChild(panel.famChartButton)
end

function FAMHealthPanelContext.layoutFamChartButton(panel)
    if not panel or not panel.famChartButton then
        return
    end
    if not FAMHealthPanelContext.showFamChartButton then
        panel.famChartButton:setVisible(false)
        return
    end
    local size = FAMHealthPanelContext.CHART_BUTTON_SIZE
    local x, y = FAMHealthPanelContext.getChartButtonPosition(panel)
    panel.famChartButton:setX(x)
    panel.famChartButton:setY(y)
    panel.famChartButton:setWidth(size)
    panel.famChartButton:setHeight(size)
    panel.famChartButton:setVisible(true)
end

function FAMHealthPanelContext.onApply(args)
    local action = FAM_ApplyTreatmentAction:new(args.doctor, args.patient, args.item, args.bodyPart, args.treatment)
    refreshOpenTriage(args.doctor, args.patient)
    ISTimedActionQueue.add(action)
end

function FAMHealthPanelContext.onFieldAmputation(args)
    local action = FAM_FieldAmputationAction:new(args.doctor, args.patient, args.sawItem, args.bodyPart, args.stitchItem, args.bandageItem)
    refreshOpenTriage(args.doctor, args.patient)
    ISTimedActionQueue.add(action)
end

function FAMHealthPanelContext.onFitProsthetic(args)
    local action = FAM_FitProstheticAction:new(args.doctor, args.patient, args.prostheticItem, args.bodyPart)
    refreshOpenTriage(args.doctor, args.patient)
    ISTimedActionQueue.add(action)
end

function FAMHealthPanelContext.onRemoveProsthetic(args)
    local action = FAM_RemoveProstheticAction:new(args.doctor, args.patient, args.bodyPart)
    refreshOpenTriage(args.doctor, args.patient)
    ISTimedActionQueue.add(action)
end

function FAMHealthPanelContext.onOpenTriage(args)
    FAM_TriagePanel.open(args.doctor, args.patient)
end

function FAMHealthPanelContext.onMedicalCheck(args)
    ISTimedActionQueue.add(FAM_MedicalCheckAction:new(args.doctor, args.patient))
end

local function addTreatmentOption(subMenu, labelKey, doctor, patient, bodyPart, treatment)
    local protocol = FAM.TREATMENTS[treatment]
    local item = FAM.findFirstItem(doctor, protocol.item)
    local valid, reason = FAM.canUseTreatment(doctor, patient, bodyPart, treatment)
    local label = getText(labelKey)

    if item and valid then
        local option = subMenu:addOption(label, {
            doctor = doctor,
            patient = patient,
            item = item,
            bodyPart = bodyPart,
            treatment = treatment,
        }, FAMHealthPanelContext.onApply)
        option.itemForTexture = item
        return
    end

    local option = subMenu:addOption(label, nil)
    option.notAvailable = true
    if not item then
        option.toolTip = makeTooltip("Tooltip_FAM_MissingItem")
    else
        option.toolTip = makeTooltip(reason)
    end
end

local function addFieldAmputationOption(subMenu, doctor, patient, bodyPart)
    local sawItem = FAM.findSurgicalSaw(doctor)
    local valid, reason = FAM.canUseTreatment(doctor, patient, bodyPart, "amputation")
    local option

    if sawItem and valid then
        option = subMenu:addOption(getText("ContextMenu_FAM_FieldAmputation"), {
            doctor = doctor,
            patient = patient,
            sawItem = sawItem,
            bodyPart = bodyPart,
            stitchItem = FAM.findStitchItem(doctor),
            bandageItem = FAM.findBandageItem(doctor),
        }, FAMHealthPanelContext.onFieldAmputation)
        option.itemForTexture = sawItem
        return
    end

    option = subMenu:addOption(getText("ContextMenu_FAM_FieldAmputation"), nil)
    option.notAvailable = true
    if not sawItem then
        option.toolTip = makeTooltip("Tooltip_FAM_MissingSaw")
    else
        option.toolTip = makeTooltip(reason)
    end
end

local function addFitProstheticOption(subMenu, doctor, patient, bodyPart)
    local prostheticItem = FAM.findProsthetic(doctor)
    local valid, reason = FAM.canFitProsthetic(doctor, patient, bodyPart, prostheticItem)
    local option

    if prostheticItem and valid then
        option = subMenu:addOption(getText("ContextMenu_FAM_FitProsthetic"), {
            doctor = doctor,
            patient = patient,
            prostheticItem = prostheticItem,
            bodyPart = bodyPart,
        }, FAMHealthPanelContext.onFitProsthetic)
        option.itemForTexture = prostheticItem
        return
    end

    option = subMenu:addOption(getText("ContextMenu_FAM_FitProsthetic"), nil)
    option.notAvailable = true
    if not prostheticItem then
        option.toolTip = makeTooltip("Tooltip_FAM_MissingProsthetic")
    else
        option.toolTip = makeTooltip(reason)
    end
end

local function addRemoveProstheticOption(subMenu, doctor, patient, bodyPart)
    local valid = FAM.canRemoveProsthetic(doctor, patient, bodyPart)
    if not valid then return end

    subMenu:addOption(getText("ContextMenu_FAM_RemoveProsthetic"), {
        doctor = doctor,
        patient = patient,
        bodyPart = bodyPart,
    }, FAMHealthPanelContext.onRemoveProsthetic)
end

function FAMHealthPanelContext.add(panel, bodyPart, x, y, context)
    if not ISContextMenu then return end
    if not FAMHealthPanelContext.enableHealthPanelContextMenu then return end
    if panel.blockingMessage then return end
    local doctor = getDoctor(panel)
    local patient = getPatient(panel)
    if not doctor or not patient then return end
    if FAM.isSuppressedAmputationPart(patient, bodyPart) then
        local primaryName = FAM.getPrimaryAmputationName(patient, bodyPart)
        local primaryPart = FAM.getBodyPartByName(patient, primaryName)
        if primaryPart then
            bodyPart = primaryPart
        end
    end

    local playerNum = getContextPlayerNum(panel, doctor)
    context = context or ISContextMenu.get(playerNum, x + panel:getAbsoluteX(), y + panel:getAbsoluteY())
    if not context then return end

    local root = context:addOption(getText("ContextMenu_FAM_Triage"), nil)
    root.iconTexture = getTexture("media/ui/FAM/TriageIcon.png")
    local subMenu = context:getNew(context)
    context:addSubMenu(root, subMenu)

    subMenu:addOption(getText("ContextMenu_FAM_OpenTriage"), {
        doctor = doctor,
        patient = patient,
    }, FAMHealthPanelContext.onOpenTriage)

    subMenu:addOption(getText("ContextMenu_FAM_MedicalCheck"), {
        doctor = doctor,
        patient = patient,
    }, FAMHealthPanelContext.onMedicalCheck)

    addTreatmentOption(subMenu, "ContextMenu_FAM_ApplyBurnGel", doctor, patient, bodyPart, "burn")
    addTreatmentOption(subMenu, "ContextMenu_FAM_ApplyHemostatic", doctor, patient, bodyPart, "hemostatic")
    addTreatmentOption(subMenu, "ContextMenu_FAM_ApplyTourniquet", doctor, patient, bodyPart, "tourniquet")
    addTreatmentOption(subMenu, "ContextMenu_FAM_SanitizeExposure", doctor, patient, bodyPart, "sanitation")
    addTreatmentOption(subMenu, "ContextMenu_FAM_ApplyStumpCare", doctor, patient, bodyPart, "stumpcare")
    addTreatmentOption(subMenu, "ContextMenu_FAM_StartIVFluids", doctor, patient, bodyPart, "ivfluids")
    addTreatmentOption(subMenu, "ContextMenu_FAM_AdministerBloodPack", doctor, patient, bodyPart, "bloodpack")
    addTreatmentOption(subMenu, "ContextMenu_FAM_AdministerEpinephrine", doctor, patient, bodyPart, "epinephrine")
    addFieldAmputationOption(subMenu, doctor, patient, bodyPart)
    addFitProstheticOption(subMenu, doctor, patient, bodyPart)
    addRemoveProstheticOption(subMenu, doctor, patient, bodyPart)

    context:setVisible(true)
end

local function canUseFamMedicalCheck(target, requester)
    if not FAMHealthPanelContext.preferFamMedicalCheck then
        return false
    end
    if isHealthCheatMode() then
        return false
    end
    if not target or not requester then
        return false
    end
    return canReachFamPatient(target, requester)
end

function FAMHealthPanelContext.patchHealthPanel()
    if not ISHealthPanel then
        return
    end

    if FAMHealthPanelContext.enableHealthPanelContextMenu and ISHealthPanel.doBodyPartContextMenu and not FAMHealthPanelContext._patched then
        FAMHealthPanelContext._patched = true
        local oldDoBodyPartContextMenu = ISHealthPanel.doBodyPartContextMenu

        function ISHealthPanel:doBodyPartContextMenu(bodyPart, x, y)
            oldDoBodyPartContextMenu(self, bodyPart, x, y)
            local playerNum = getContextPlayerNum(self, getDoctor(self))
            local context = getPlayerContextMenu and getPlayerContextMenu(playerNum) or nil
            FAMHealthPanelContext.add(self, bodyPart, x, y, context)
        end
    end

    if FAMHealthPanelContext.showFamChartButton and ISHealthPanel.createChildren and not FAMHealthPanelContext._createChildrenPatched then
        FAMHealthPanelContext._createChildrenPatched = true
        local oldCreateChildren = ISHealthPanel.createChildren

        function ISHealthPanel:createChildren()
            oldCreateChildren(self)
            FAMHealthPanelContext.addFamChartButton(self)
        end
    end

    if FAMHealthPanelContext.showFamChartButton and ISHealthPanel.render and not FAMHealthPanelContext._renderPatched then
        FAMHealthPanelContext._renderPatched = true
        local oldRender = ISHealthPanel.render

        function ISHealthPanel:render()
            oldRender(self)
            FAMHealthPanelContext.layoutFamChartButton(self)
        end
    end

    if FAMHealthPanelContext.preferFamHealthPanel and ISHealthPanel.setVisible and not FAMHealthPanelContext._setVisiblePatched then
        FAMHealthPanelContext._setVisiblePatched = true
        local oldSetVisible = ISHealthPanel.setVisible

        function ISHealthPanel:setVisible(visible)
            oldSetVisible(self, visible)
            if visible and FAMHealthPanelContext.canAutoOpenFromHealthPanel(self) then
                FAMHealthPanelContext.openFromPanel(self)
            end
        end
    end

    if FAMHealthPanelContext.preferFamMedicalCheck and ISHealthPanel.AcceptedMedicalCheck and not FAMHealthPanelContext._medicalCheckPatched then
        FAMHealthPanelContext._medicalCheckPatched = true
        local oldAcceptedMedicalCheck = ISHealthPanel.AcceptedMedicalCheck

        local newAcceptedMedicalCheck = function(target, requester)
            if canUseFamMedicalCheck(target, requester) then
                ISTimedActionQueue.add(FAM_MedicalCheckAction:new(requester, target))
                return
            end
            oldAcceptedMedicalCheck(target, requester)
        end

        ISHealthPanel.AcceptedMedicalCheck = newAcceptedMedicalCheck

        if Events and Events.AcceptedMedicalCheck and Events.AcceptedMedicalCheck.Remove and Events.AcceptedMedicalCheck.Add then
            Events.AcceptedMedicalCheck.Remove(oldAcceptedMedicalCheck)
            Events.AcceptedMedicalCheck.Add(newAcceptedMedicalCheck)
        end
    end

    if FAMHealthPanelContext.preferFamMedicalCheck
        and ISWorldObjectContextMenu
        and ISWorldObjectContextMenu.onMedicalCheck
        and not FAMHealthPanelContext._worldMedicalCheckPatched then
        FAMHealthPanelContext._worldMedicalCheckPatched = true
        local oldWorldMedicalCheck = ISWorldObjectContextMenu.onMedicalCheck

        ISWorldObjectContextMenu.onMedicalCheck = function(worldobjects, requester, target)
            if canUseFamMedicalCheck(target, requester) then
                ISTimedActionQueue.add(FAM_MedicalCheckAction:new(requester, target))
                return
            end
            oldWorldMedicalCheck(worldobjects, requester, target)
        end
    end

    if (FAMHealthPanelContext.preferFamMedicalCheck or FAMHealthPanelContext.openFamAfterMedicalCheck) and ISMedicalCheckAction and ISMedicalCheckAction.perform and not FAMHealthPanelContext._medicalActionPatched then
        FAMHealthPanelContext._medicalActionPatched = true
        local oldMedicalCheckPerform = ISMedicalCheckAction.perform

        function ISMedicalCheckAction:perform()
            if canUseFamMedicalCheck(self.otherPlayer, self.character) then
                FAMHealthPanelContext.openFromMedicalCheck(self.character, self.otherPlayer)
                ISBaseTimedAction.perform(self)
                return
            end
            oldMedicalCheckPerform(self)
            if FAMHealthPanelContext.openFamAfterMedicalCheck then
                FAMHealthPanelContext.openFromMedicalCheck(self.character, self.otherPlayer)
            end
        end
    end
end

FAMHealthPanelContext.patchHealthPanel()

if Events and Events.OnGameStart and not FAMHealthPanelContext._gameStartPatchRegistered then
    FAMHealthPanelContext._gameStartPatchRegistered = true
    Events.OnGameStart.Add(function()
        FAMHealthPanelContext.blockHealthAutoOpen()
        FAMHealthPanelContext.patchHealthPanel()
    end)
end

if Events and not FAMHealthPanelContext._sessionGuardRegistered then
    FAMHealthPanelContext._sessionGuardRegistered = true
    if Events.OnCreatePlayer then
        Events.OnCreatePlayer.Add(FAMHealthPanelContext.blockHealthAutoOpen)
    end
    if Events.OnConnected then
        Events.OnConnected.Add(FAMHealthPanelContext.blockHealthAutoOpen)
    end
    if Events.OnMainMenuEnter then
        Events.OnMainMenuEnter.Add(FAMHealthPanelContext.blockHealthAutoOpen)
    end
    if Events.OnTick then
        Events.OnTick.Add(FAMHealthPanelContext.tickHealthAutoOpenBlock)
    end
end

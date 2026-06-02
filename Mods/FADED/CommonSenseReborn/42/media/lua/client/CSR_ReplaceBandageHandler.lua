require "CSR_FeatureFlags"
require "CSR_Utils"
require "CSR_DisinfectantUtils"

local _installed = false

local function isDisinfectant(item)
    return CSR_DisinfectantUtils.isDisinfectant(item)
end

local function getBestDisinfectant(items)
    -- Prefer the item with the highest (alcohol_ratio * effective_volume).
    -- For drainable items (rubbing alcohol bottles) volume isn't directly
    -- comparable; we treat their alcoholPower as the score directly.
    -- Net result: vodka/whiskey/rubbingAlcohol still beat cologne/perfume
    -- when both are present.
    local best = nil
    local bestScore = -1
    for _, item in ipairs(items) do
        local score = CSR_DisinfectantUtils.getWoundPriority(item)
        if score > bestScore then
            bestScore = score
            best = item
        end
    end
    return best
end

local function walkContainer(container, callback, visitedContainers, visitedItems)
    if not container or visitedContainers[container] then return end
    visitedContainers[container] = true

    local items = container.getItems and container:getItems() or nil
    if not items then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local id = item and item.getID and item:getID() or nil
        if item and (not id or not visitedItems[id]) then
            if id then visitedItems[id] = true end
            callback(item)
        end

        local subInventory = item and item.getInventory and item:getInventory() or nil
        if subInventory then
            walkContainer(subInventory, callback, visitedContainers, visitedItems)
        end
    end
end

local function findItems(doctor)
    local containers = ISInventoryPaneContextMenu.getContainers(doctor)
    if not containers then return {}, {} end
    local bandagesByType = {}
    local disinfectants = {}
    local visitedContainers = {}
    local visitedItems = {}
    for i = 0, containers:size() - 1 do
        walkContainer(containers:get(i), function(item)
            if item.getBandagePower and item:getBandagePower() and item:getBandagePower() > 0 then
                local ft = item:getFullType()
                if not bandagesByType[ft] then
                    bandagesByType[ft] = item
                end
            end
            if isDisinfectant(item) then
                table.insert(disinfectants, item)
            end
        end, visitedContainers, visitedItems)
    end
    return bandagesByType, disinfectants
end

local function queueAfter(previousAction, action)
    if not action then return previousAction end
    -- ISTimedActionQueue.addAfter silently drops the action when
    -- previousAction is nil or not currently in the queue (indexOf
    -- returns -1).  Fall back to ISTimedActionQueue.add for the first
    -- link in the chain so the action actually gets queued.
    local queued = false
    if previousAction and ISTimedActionQueue.addAfter then
        local q, added = ISTimedActionQueue.addAfter(previousAction, action)
        if added then queued = true end
    end
    if not queued then
        ISTimedActionQueue.add(action)
    end
    return action
end

local function queueTransfer(previousAction, doctor, item)
    if not doctor or not item or not item.getContainer or not doctor.getInventory then
        return previousAction
    end

    local fromContainer = item:getContainer()
    local toContainer = doctor:getInventory()
    if not fromContainer or not toContainer or fromContainer == toContainer then
        return previousAction
    end

    if ISInventoryTransferUtil and ISInventoryTransferUtil.newInventoryTransferAction then
        return queueAfter(previousAction, ISInventoryTransferUtil.newInventoryTransferAction(doctor, item, fromContainer, toContainer))
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
        ISInventoryPaneContextMenu.transferIfNeeded(doctor, item)
    end
    return previousAction
end

local function queueDisinfect(previousAction, doctor, patient, bodyPart, disinfectant)
    if not CSR_DisinfectWoundAction then
        require "TimedActions/CSR_DisinfectWoundAction"
    end
    return queueAfter(previousAction, CSR_DisinfectWoundAction:new(doctor, patient, disinfectant, bodyPart))
end

local function onReplaceBandage(doctor, patient, bodyPart, bandageItem)
    local previous = queueTransfer(nil, doctor, bandageItem)
    previous = queueAfter(previous, ISApplyBandage:new(doctor, patient, nil, bodyPart, false))
    queueAfter(previous, ISApplyBandage:new(doctor, patient, bandageItem, bodyPart, true))
end

local function onDisinfectAndReplace(doctor, patient, bodyPart, bandageItem, disinfectant)
    local previous = queueTransfer(nil, doctor, disinfectant)
    previous = queueTransfer(previous, doctor, bandageItem)
    previous = queueAfter(previous, ISApplyBandage:new(doctor, patient, nil, bodyPart, false))
    previous = queueDisinfect(previous, doctor, patient, bodyPart, disinfectant)
    queueAfter(previous, ISApplyBandage:new(doctor, patient, bandageItem, bodyPart, true))
end

local function onRestaple(doctor, patient, bodyPart)
    if not CSR_RestapleAction then
        require "TimedActions/CSR_RestapleAction"
    end
    local previous = queueAfter(nil, ISApplyBandage:new(doctor, patient, nil, bodyPart, false))
    queueAfter(previous, CSR_RestapleAction:new(doctor, patient, bodyPart))
end

local function onDisinfectAndRestaple(doctor, patient, bodyPart, disinfectant)
    if not CSR_RestapleAction then
        require "TimedActions/CSR_RestapleAction"
    end
    local previous = queueTransfer(nil, doctor, disinfectant)
    previous = queueAfter(previous, ISApplyBandage:new(doctor, patient, nil, bodyPart, false))
    previous = queueDisinfect(previous, doctor, patient, bodyPart, disinfectant)
    queueAfter(previous, CSR_RestapleAction:new(doctor, patient, bodyPart))
end

local function onDisinfectOnly(doctor, patient, bodyPart, disinfectant)
    local previous = queueTransfer(nil, doctor, disinfectant)
    queueDisinfect(previous, doctor, patient, bodyPart, disinfectant)
end

local function onDisinfectAndBandage(doctor, patient, bodyPart, bandageItem, disinfectant)
    local previous = queueTransfer(nil, doctor, disinfectant)
    previous = queueTransfer(previous, doctor, bandageItem)
    previous = queueDisinfect(previous, doctor, patient, bodyPart, disinfectant)
    queueAfter(previous, ISApplyBandage:new(doctor, patient, bandageItem, bodyPart, true))
end

-- A body part is "treatable" by us if it has a wound/injury that benefits
-- from disinfectant: open cuts, scratches, bites, bullets, glass, burns.
local function isTreatableWound(bodyPart)
    if not bodyPart then return false end
    if bodyPart.HasInjury and bodyPart:HasInjury() then return true end
    if bodyPart.bitten and bodyPart:bitten() then return true end
    if bodyPart.isBitten and bodyPart:isBitten() then return true end
    if bodyPart.bleeding and bodyPart:bleeding() then return true end
    if bodyPart.haveBullet and bodyPart:haveBullet() then return true end
    if bodyPart.haveGlass and bodyPart:haveGlass() then return true end
    if bodyPart.getBurnTime and bodyPart:getBurnTime() > 0 then return true end
    if bodyPart.isInfectedWound and bodyPart:isInfectedWound() then return true end
    return false
end

local function installReplaceBandageHandler()
    if _installed then return end
    if not ISHealthPanel or not ISHealthPanel.doBodyPartContextMenu then return end
    _installed = true

    local _origDoBodyPartContextMenu = ISHealthPanel.doBodyPartContextMenu

    function ISHealthPanel:doBodyPartContextMenu(bodyPart, x, y)
        _origDoBodyPartContextMenu(self, bodyPart, x, y)

        if not CSR_FeatureFlags.isEquipmentQoLEnabled() then return end

        local isBandaged = bodyPart:bandaged()
        local isWounded  = isTreatableWound(bodyPart)
        -- Only surface options when there is something to act on: either
        -- an existing bandage to replace, or an open wound to disinfect.
        if not isBandaged and not isWounded then return end

        local doctor = self.otherPlayer or self.character
        local patient = self.character
        local playerNum = self.otherPlayer and self.otherPlayer:getPlayerNum() or self.character:getPlayerNum()
        local context = getPlayerContextMenu(playerNum)
        if not context then return end

        local bandagesByType, disinfectants = findItems(doctor)
        local bestDisinfectant = getBestDisinfectant(disinfectants)
        local isStapled = bodyPart:getBandageType() == "Base.Stapler"
        local hasStapler = CSR_Utils.findStapler(doctor) ~= nil
        local hasStaples = CSR_Utils.findStaples(doctor) ~= nil

        local bandageTypes = {}
        for ft, item in pairs(bandagesByType) do
            table.insert(bandageTypes, { fullType = ft, item = item })
        end
        table.sort(bandageTypes, function(a, b) return a.item:getName() < b.item:getName() end)

        -- Open-wound flow: offer plain disinfect and combined disinfect+bandage
        -- when the body part is NOT yet bandaged. Vanilla already lists
        -- "Bandage" with rags etc., so we only add the disinfect-augmented
        -- variants here.
        if not isBandaged and isWounded and bestDisinfectant then
            local disinfectant = bestDisinfectant
            local disinfectOpt = context:addOption(getText("ContextMenu_CSR_DisinfectWound"), self, function()
                onDisinfectOnly(doctor, patient, bodyPart, disinfectant)
            end)
            disinfectOpt.itemForTexture = bestDisinfectant

            if #bandageTypes > 0 then
                local combinedOpt = context:addOption(getText("ContextMenu_CSR_DisinfectAndBandage"))
                local subMenu = ISContextMenu:getNew(context)
                context:addSubMenu(combinedOpt, subMenu)
                combinedOpt.itemForTexture = bestDisinfectant
                for _, bt in ipairs(bandageTypes) do
                    local bandageItem = bt.item
                    local opt = subMenu:addOption(bandageItem:getName(), self, function()
                        onDisinfectAndBandage(doctor, patient, bodyPart, bandageItem, disinfectant)
                    end)
                    opt.itemForTexture = bandageItem
                end
            end
        end

        -- Bandaged-wound flow: replace / disinfect+replace / re-staple.
        if not isBandaged then return end

        if #bandageTypes > 0 then
            local replaceOpt = context:addOption(getText("ContextMenu_CSR_ReplaceBandage"))
            local subMenu = ISContextMenu:getNew(context)
            context:addSubMenu(replaceOpt, subMenu)
            for _, bt in ipairs(bandageTypes) do
                local bandageItem = bt.item
                local opt = subMenu:addOption(bandageItem:getName(), self, function()
                    onReplaceBandage(doctor, patient, bodyPart, bandageItem)
                end)
                opt.itemForTexture = bandageItem
            end
        end

        if #bandageTypes > 0 and bestDisinfectant then
            local disReplaceOpt = context:addOption(getText("ContextMenu_CSR_DisinfectAndReplace"))
            local subMenu = ISContextMenu:getNew(context)
            context:addSubMenu(disReplaceOpt, subMenu)
            disReplaceOpt.itemForTexture = bestDisinfectant
            for _, bt in ipairs(bandageTypes) do
                local bandageItem = bt.item
                local disinfectant = bestDisinfectant
                local opt = subMenu:addOption(bandageItem:getName(), self, function()
                    onDisinfectAndReplace(doctor, patient, bodyPart, bandageItem, disinfectant)
                end)
                opt.itemForTexture = bandageItem
            end
        end

        if isStapled and hasStapler and hasStaples then
            context:addOption(getText("ContextMenu_CSR_RestapleWound"), self, function()
                onRestaple(doctor, patient, bodyPart)
            end)

            if bestDisinfectant then
                local disinfectant = bestDisinfectant
                local opt = context:addOption(getText("ContextMenu_CSR_DisinfectAndRestaple"), self, function()
                    onDisinfectAndRestaple(doctor, patient, bodyPart, disinfectant)
                end)
                opt.itemForTexture = bestDisinfectant
            end
        end
    end
end

if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(installReplaceBandageHandler) end
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(installReplaceBandageHandler) end
end

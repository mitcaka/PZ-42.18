if isServer() then return end

require "FAM_Core"
require "FAM_ClientCommands"
require "TimedActions/ISInventoryTransferUtil"
require "TimedActions/ISApplyBandage"
require "TimedActions/ISCleanBurn"
require "TimedActions/ISComfreyCataplasm"
require "TimedActions/ISDisinfect"
require "TimedActions/ISGarlicCataplasm"
require "TimedActions/ISPlantainCataplasm"
require "TimedActions/ISRemoveBullet"
require "TimedActions/ISRemoveGlass"
require "TimedActions/ISSplint"
require "TimedActions/ISStitch"
require "TimedActions/FAM_ApplyTreatmentAction"
require "TimedActions/FAM_FieldAmputationAction"
require "TimedActions/FAM_FitProstheticAction"
require "TimedActions/FAM_RemoveProstheticAction"

FAM_TreatmentPlanner = FAM_TreatmentPlanner or {}

local function itemFullType(item)
    if not item then return nil end
    if item.getFullType then return item:getFullType() end
    return item:getModule() .. "." .. item:getType()
end

local function hasItemTag(item, tagName)
    if not item or not item.hasTag or not ItemTag then
        return false
    end

    if ItemTag[tagName] and item:hasTag(ItemTag[tagName]) then
        return true
    end

    if ItemTag.get and ResourceLocation and ResourceLocation.of then
        local tag = ItemTag.get(ResourceLocation.of(tagName))
        return tag ~= nil and item:hasTag(tag) == true
    end

    return false
end

local function scanContainer(container, callback, childContainers)
    if not container or not container.getItems then return end
    local items = container:getItems()
    if not items then return end
    for i = 1, items:size() do
        local item = items:get(i - 1)
        if item and item.IsInventoryContainer and item:IsInventoryContainer() then
            if childContainers then
                table.insert(childContainers, item:getInventory())
            end
        elseif item then
            callback(item)
        end
    end
end

local function forEachInventoryItem(character, callback)
    if not character or not callback then return end
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getContainers then
        local containers = ISInventoryPaneContextMenu.getContainers(character)
        local done = {}
        local childContainers = {}
        if containers then
            for i = 1, containers:size() do
                local container = containers:get(i - 1)
                done[container] = true
                childContainers = {}
                scanContainer(container, callback, childContainers)
                for j = 1, #childContainers do
                    local child = childContainers[j]
                    if not done[child] then
                        done[child] = true
                        scanContainer(child, callback, nil)
                    end
                end
            end
            return
        end
    end

    scanContainer(character:getInventory(), callback, nil)
end

local function findItem(character, predicate)
    local found = nil
    forEachInventoryItem(character, function(item)
        if not found and predicate(item) then
            found = item
        end
    end)
    return found
end

local function findItemType(character, fullType)
    return findItem(character, function(item)
        return itemFullType(item) == fullType
    end)
end

local function findItemByTypes(character, fullTypes)
    if not fullTypes then return nil end
    for i = 1, #fullTypes do
        local item = findItemType(character, fullTypes[i])
        if item then return item end
    end
    return nil
end

local function isInjuredForVanilla(bodyPart)
    return bodyPart and (bodyPart:HasInjury() or bodyPart:stitched() or bodyPart:getSplintFactor() > 0) and not bodyPart:bandaged()
end

local function isDisinfectant(item)
    if not item then return false end
    if item.hasComponent and ComponentType and ComponentType.FluidContainer and item:hasComponent(ComponentType.FluidContainer) then
        local fluidContainer = item:getFluidContainer()
        if fluidContainer and fluidContainer.getAmount and fluidContainer:getAmount() > 0.15 then
            local properties = fluidContainer:getProperties()
            return properties and properties.getAlcohol and (properties:getAlcohol() / fluidContainer:getAmount() + 0.001) >= 0.4
        end
    end
    return item.IsDrainable and item:IsDrainable() and item.getAlcoholPower and item:getAlcoholPower() == 4.0
end

local function isBandage(item)
    return item and item.getBandagePower and item:getBandagePower() > 0
end

local function isBurnCleaner(item)
    return item and item.getBandagePower and item:getBandagePower() >= 2
end

local function isRemoveTool(item)
    if not item then return false end
    local itemType = item:getType()
    return itemType == "Tweezers"
        or itemType == "SutureNeedleHolder"
        or hasItemTag(item, "REMOVE_GLASS")
        or hasItemTag(item, "REMOVE_BULLET")
        or hasItemTag(item, "RemoveGlass")
        or hasItemTag(item, "RemoveBullet")
end

local function queueAfter(previousAction, action)
    if previousAction then
        ISTimedActionQueue.addAfter(previousAction, action)
    else
        ISTimedActionQueue.add(action)
    end
    return action
end

local function transferToDoctor(doctor, item, previousAction)
    if not item or item:getContainer() == doctor:getInventory() then
        return previousAction
    end
    if ISInventoryTransferUtil and ISInventoryTransferUtil.newInventoryTransferAction then
        local action = ISInventoryTransferUtil.newInventoryTransferAction(doctor, item, item:getContainer(), doctor:getInventory())
        return queueAfter(previousAction, action)
    end
    return previousAction
end

local function makeAction(id, category, label, enabled, reason, item, perform)
    return {
        id = id,
        category = category,
        label = label,
        enabled = enabled == true,
        reason = reason,
        item = item,
        perform = perform,
    }
end

local function addBasicActions(actions, doctor, patient, bodyPart)
    if bodyPart:bandaged() then
        table.insert(actions, makeAction("remove_bandage", "basic", getText("ContextMenu_Remove_Bandage"), true, nil, nil, function()
            queueAfter(nil, ISApplyBandage:new(doctor, patient, nil, bodyPart, false))
        end))
    end

    if isInjuredForVanilla(bodyPart) and bodyPart:isNeedBurnWash() then
        local cleaner = findItem(doctor, isBurnCleaner)
        table.insert(actions, makeAction("clean_burn", "basic", getText("ContextMenu_Clean_Burn"), cleaner ~= nil, getText("Tooltip_FAM_MissingItem"), cleaner, function()
            local previous = transferToDoctor(doctor, cleaner, nil)
            queueAfter(previous, ISCleanBurn:new(doctor, patient, cleaner, bodyPart))
        end))
    end

    if isInjuredForVanilla(bodyPart) then
        local bandage = findItem(doctor, isBandage)
        table.insert(actions, makeAction("bandage", "basic", getText("ContextMenu_Bandage"), bandage ~= nil, getText("Tooltip_FAM_MissingItem"), bandage, function()
            local previous = transferToDoctor(doctor, bandage, nil)
            queueAfter(previous, ISApplyBandage:new(doctor, patient, bandage, bodyPart, true))
        end))

        local disinfectant = findItem(doctor, isDisinfectant)
        table.insert(actions, makeAction("disinfect", "basic", getText("ContextMenu_Disinfect"), disinfectant ~= nil, getText("Tooltip_FAM_MissingItem"), disinfectant, function()
            local previous = transferToDoctor(doctor, disinfectant, nil)
            queueAfter(previous, ISDisinfect:new(doctor, patient, disinfectant, bodyPart))
        end))
    end

    if isInjuredForVanilla(bodyPart) and bodyPart:isDeepWounded() and not bodyPart:haveGlass() then
        local suture = findItemType(doctor, "Base.SutureNeedle")
        local needle = suture or findItem(doctor, function(item)
            return item:getType() == "Needle" or hasItemTag(item, "SewingNeedle")
        end)
        local thread = suture or findItem(doctor, function(item)
            return item:getType() == "Thread" or hasItemTag(item, "Thread")
        end)
        local enabled = needle ~= nil and thread ~= nil
        table.insert(actions, makeAction("stitch", "basic", getText("ContextMenu_Stitch"), enabled, getText("Tooltip_FAM_MissingItem"), needle, function()
            local previous = transferToDoctor(doctor, needle, nil)
            if thread ~= needle then
                previous = transferToDoctor(doctor, thread, previous)
            end
            queueAfter(previous, ISStitch:new(doctor, patient, thread, bodyPart, true))
        end))
    end

    if bodyPart:stitched() then
        table.insert(actions, makeAction("remove_stitch", "basic", getText("ContextMenu_Remove_Stitch"), true, nil, nil, function()
            queueAfter(nil, ISStitch:new(doctor, patient, nil, bodyPart, false))
        end))
    end

    if isInjuredForVanilla(bodyPart) and bodyPart:haveGlass() then
        local tool = findItem(doctor, isRemoveTool)
        table.insert(actions, makeAction("remove_glass", "basic", getText("ContextMenu_Remove_Glass"), true, nil, tool, function()
            local previous = transferToDoctor(doctor, tool, nil)
            queueAfter(previous, ISRemoveGlass:new(doctor, patient, bodyPart, tool == nil))
        end))
    end

    if isInjuredForVanilla(bodyPart) and bodyPart:haveBullet() then
        local tool = findItem(doctor, isRemoveTool)
        table.insert(actions, makeAction("remove_bullet", "basic", getText("ContextMenu_Remove_Bullet"), tool ~= nil, getText("Tooltip_FAM_MissingItem"), tool, function()
            local previous = transferToDoctor(doctor, tool, nil)
            queueAfter(previous, ISRemoveBullet:new(doctor, patient, bodyPart))
        end))
    end

    if bodyPart:getSplintFactor() > 0 then
        table.insert(actions, makeAction("remove_splint", "basic", getText("ContextMenu_Remove_Splint"), true, nil, nil, function()
            queueAfter(nil, ISSplint:new(doctor, patient, nil, nil, bodyPart, false))
        end))
    elseif isInjuredForVanilla(bodyPart)
        and bodyPart:getFractureTime() > 0
        and bodyPart:getType() ~= BodyPartType.Head
        and bodyPart:getType() ~= BodyPartType.Torso_Upper
        and bodyPart:getType() ~= BodyPartType.Torso_Lower then
        local splint = findItemType(doctor, "Base.Splint")
        local plank = findItemByTypes(doctor, { "Base.Plank", "Base.TreeBranch2", "Base.WoodenStick2", "Base.TreeBranch", "Base.WoodenStick" })
        local sheet = findItemType(doctor, "Base.RippedSheets")
        local enabled = splint ~= nil or (plank ~= nil and sheet ~= nil)
        table.insert(actions, makeAction("splint", "basic", getText("ContextMenu_Splint"), enabled, getText("Tooltip_FAM_MissingItem"), splint or plank, function()
            if splint then
                local previous = transferToDoctor(doctor, splint, nil)
                queueAfter(previous, ISSplint:new(doctor, patient, nil, splint, bodyPart, true))
            else
                local previous = transferToDoctor(doctor, sheet, nil)
                previous = transferToDoctor(doctor, plank, previous)
                queueAfter(previous, ISSplint:new(doctor, patient, sheet, plank, bodyPart, true))
            end
        end))
    end

    if isInjuredForVanilla(bodyPart)
        and bodyPart:getPlantainFactor() == 0
        and bodyPart:getComfreyFactor() == 0
        and bodyPart:getGarlicFactor() == 0 then
        local plantain = findItemType(doctor, "Base.PlantainCataplasm")
        local comfrey = findItemType(doctor, "Base.ComfreyCataplasm")
        local garlic = findItemType(doctor, "Base.WildGarlicCataplasm")
        if plantain then
            table.insert(actions, makeAction("plantain", "basic", getText("ContextMenu_PlantainCataplasm"), true, nil, plantain, function()
                local previous = transferToDoctor(doctor, plantain, nil)
                queueAfter(previous, ISPlantainCataplasm:new(doctor, patient, plantain, bodyPart))
            end))
        end
        if comfrey then
            table.insert(actions, makeAction("comfrey", "basic", getText("ContextMenu_ComfreyCataplasm"), true, nil, comfrey, function()
                local previous = transferToDoctor(doctor, comfrey, nil)
                queueAfter(previous, ISComfreyCataplasm:new(doctor, patient, comfrey, bodyPart))
            end))
        end
        if garlic then
            table.insert(actions, makeAction("garlic", "basic", getText("ContextMenu_GarlicCataplasm"), true, nil, garlic, function()
                local previous = transferToDoctor(doctor, garlic, nil)
                queueAfter(previous, ISGarlicCataplasm:new(doctor, patient, garlic, bodyPart))
            end))
        end
    end
end

local function addFamTreatment(actions, doctor, patient, bodyPart, treatment, labelKey)
    local protocol = FAM.TREATMENTS[treatment]
    if not protocol then return end
    local item = protocol.item and findItemType(doctor, protocol.item) or nil
    local valid, reason = FAM.canUseTreatment(doctor, patient, bodyPart, treatment)
    local hasItem = protocol.item == nil or item ~= nil
    local qualityKey = FAM.getTreatmentQualityLabelKey(doctor, patient, bodyPart, treatment)
    local label = getText("IGUI_FAM_ActionWithQuality", getText(labelKey), getText(qualityKey))
    table.insert(actions, makeAction("fam_" .. treatment, "fam", label, valid and hasItem, hasItem and getText(reason or "Tooltip_FAM_InvalidTreatment") or getText("Tooltip_FAM_MissingItem"), item, function()
        queueAfter(nil, FAM_ApplyTreatmentAction:new(doctor, patient, item, bodyPart, treatment))
    end))
end

local function addFamActions(actions, doctor, patient, bodyPart)
    addFamTreatment(actions, doctor, patient, bodyPart, "burn", "ContextMenu_FAM_ApplyBurnGel")
    addFamTreatment(actions, doctor, patient, bodyPart, "hemostatic", "ContextMenu_FAM_ApplyHemostatic")
    addFamTreatment(actions, doctor, patient, bodyPart, "tourniquet", "ContextMenu_FAM_ApplyTourniquet")
    addFamTreatment(actions, doctor, patient, bodyPart, "sanitation", "ContextMenu_FAM_SanitizeExposure")
    addFamTreatment(actions, doctor, patient, bodyPart, "stumpcare", "ContextMenu_FAM_ApplyStumpCare")
    addFamTreatment(actions, doctor, patient, bodyPart, "ivfluids", "ContextMenu_FAM_StartIVFluids")
    addFamTreatment(actions, doctor, patient, bodyPart, "bloodpack", "ContextMenu_FAM_AdministerBloodPack")
    addFamTreatment(actions, doctor, patient, bodyPart, "epinephrine", "ContextMenu_FAM_AdministerEpinephrine")

    local sawItem = FAM.findSurgicalSaw(doctor) or findItemByTypes(doctor, FAM.SAW_TYPES)
    local valid, reason = FAM.canUseTreatment(doctor, patient, bodyPart, "amputation")
    table.insert(actions, makeAction("fam_amputation", "fam", getText("ContextMenu_FAM_FieldAmputation"), valid and sawItem ~= nil, sawItem and getText(reason or "Tooltip_FAM_InvalidTreatment") or getText("Tooltip_FAM_MissingSaw"), sawItem, function()
        queueAfter(nil, FAM_FieldAmputationAction:new(doctor, patient, sawItem, bodyPart, FAM.findStitchItem(doctor), FAM.findBandageItem(doctor)))
    end))

    local prostheticItem = findItemByTypes(doctor, FAM.PROSTHETIC_ITEMS)
    local prostheticValid, prostheticReason = FAM.canFitProsthetic(doctor, patient, bodyPart, prostheticItem)
    table.insert(actions, makeAction("fam_prosthetic", "fam", getText("ContextMenu_FAM_FitProsthetic"), prostheticValid and prostheticItem ~= nil, prostheticItem and getText(prostheticReason or "Tooltip_FAM_InvalidTreatment") or getText("Tooltip_FAM_MissingProsthetic"), prostheticItem, function()
        queueAfter(nil, FAM_FitProstheticAction:new(doctor, patient, prostheticItem, bodyPart))
    end))

    local removeValid = FAM.canRemoveProsthetic(doctor, patient, bodyPart)
    if removeValid then
        table.insert(actions, makeAction("fam_remove_prosthetic", "fam", getText("ContextMenu_FAM_RemoveProsthetic"), true, getText("Tooltip_FAM_InvalidTreatment"), nil, function()
            queueAfter(nil, FAM_RemoveProstheticAction:new(doctor, patient, bodyPart))
        end))
    end
end

function FAM_TreatmentPlanner.getActions(doctor, patient, bodyPart)
    local actions = {}
    if not doctor or not patient or not bodyPart then
        return actions
    end
    if FAM.isSuppressedAmputationPart(patient, bodyPart) then
        return actions
    end
    if not FAM.hasAmputation(patient, bodyPart) then
        addBasicActions(actions, doctor, patient, bodyPart)
    end
    addFamActions(actions, doctor, patient, bodyPart)
    local bodyPartName = FAM.getBodyPartName(bodyPart) or "Unknown"
    local savedCandidate = FAM.bodyPartClinicalSeverity(patient, bodyPart) >= 70 or FAM.getConditionLoad(patient) >= 70
    for i = 1, #actions do
        actions[i].doctor = doctor
        actions[i].patient = patient
        actions[i].bodyPartName = bodyPartName
        actions[i].savedCandidate = savedCandidate
    end
    return actions
end

function FAM_TreatmentPlanner.perform(action)
    if not action or not action.enabled or not action.perform then
        return false
    end
    action.perform()
    if action.category == "basic" and FAM_ClientCommands and FAM_ClientCommands.recordProviderOutcome then
        FAM_ClientCommands.recordProviderOutcome(action.doctor, action.patient, {
            action = action.id,
            category = "basic",
            bodyPart = action.bodyPartName,
            injuryFixed = true,
            saved = action.savedCandidate == true,
            advanced = false,
            signature = "basic:" .. tostring(action.id) .. ":" .. FAM.getCharacterKey(action.patient) .. ":" .. tostring(action.bodyPartName) .. ":" .. tostring(math.floor(FAM.getWorldAgeHours() * 10)),
        })
    end
    return true
end

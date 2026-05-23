require "TimedActions/ISBaseTimedAction"
require "CSR_Config"
require "CSR_FeatureFlags"
require "CSR_Utils"

CSR_ToolRepairAction = ISBaseTimedAction:derive("CSR_ToolRepairAction")

local TOOL_REPAIR_AMOUNT = 10

local function removeItem(item)
    local container = item and item.getContainer and item:getContainer() or nil
    if not container then return end
    if container.DoRemoveItem then
        container:DoRemoveItem(item)
    else
        container:Remove(item)
    end
end

local function performLocal(action)
    action.item = CSR_Utils.findInventoryItemById(action.character, action.itemId, action.expectedType) or action.item
    action.torch = CSR_Utils.findInventoryItemById(action.character, action.torchId, action.torchType) or action.torch
    action.scrap = CSR_Utils.findInventoryItemById(action.character, action.scrapId, action.scrapType) or action.scrap
    action.plank = CSR_Utils.findInventoryItemById(action.character, action.plankId, action.plankType) or action.plank
    if not action.item or not action.torch or not action.scrap or not action.plank then
        return
    end
    if not CSR_Utils.isToolRepairTarget(action.item) then
        return
    end
    if not CSR_Utils.consumePropaneTorchUses(action.torch, CSR_Utils.getToolRepairTorchUseCost()) then
        return
    end

    local repairAmount = math.min(TOOL_REPAIR_AMOUNT, action.item:getConditionMax() - action.item:getCondition())
    action.item:setCondition(action.item:getCondition() + repairAmount)
    removeItem(action.scrap)
    removeItem(action.plank)
end

function CSR_ToolRepairAction:new(character, item, torch, scrap, plank)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.torch = torch
    o.scrap = scrap
    o.plank = plank
    o.itemId = item and item.getID and item:getID() or nil
    o.expectedType = item and item.getFullType and item:getFullType() or nil
    o.torchId = torch and torch.getID and torch:getID() or nil
    o.torchType = torch and torch.getFullType and torch:getFullType() or nil
    o.scrapId = scrap and scrap.getID and scrap:getID() or nil
    o.scrapType = scrap and scrap.getFullType and scrap:getFullType() or nil
    o.plankId = plank and plank.getID and plank:getID() or nil
    o.plankType = plank and plank.getFullType and plank:getFullType() or nil
    o.maxTime = CSR_Config.REPAIR_TIME
    o.stopOnWalk = not CSR_FeatureFlags.isWalkingActionsEnabled()
    o.stopOnRun = true
    return o
end

function CSR_ToolRepairAction:isValid()
    self.item = CSR_Utils.findInventoryItemById(self.character, self.itemId, self.expectedType) or self.item
    self.torch = CSR_Utils.findInventoryItemById(self.character, self.torchId, self.torchType) or self.torch
    self.scrap = CSR_Utils.findInventoryItemById(self.character, self.scrapId, self.scrapType) or self.scrap
    self.plank = CSR_Utils.findInventoryItemById(self.character, self.plankId, self.plankType) or self.plank
    return self.item
        and self.torch
        and self.scrap
        and self.plank
        and CSR_Utils.isToolRepairTarget(self.item)
        and CSR_Utils.hasPropaneTorchUses(self.torch, CSR_Utils.getToolRepairTorchUseCost())
end

function CSR_ToolRepairAction:update()
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function CSR_ToolRepairAction:start()
    self.item = CSR_Utils.findInventoryItemById(self.character, self.itemId, self.expectedType) or self.item
    self.torch = CSR_Utils.findInventoryItemById(self.character, self.torchId, self.torchType) or self.torch
    self:setActionAnim("BlowTorch")
    self:setOverrideHandModels(self.torch, self.item)
end

function CSR_ToolRepairAction:perform()
    if isClient() then
        sendClientCommand(self.character, "CommonSenseReborn", "ToolRepair", {
            itemId = self.item:getID(),
            torchId = self.torch:getID(),
            scrapId = self.scrap:getID(),
            plankId = self.plank:getID(),
            requestId = CSR_Utils.makeRequestId(self.character, "ToolRepair")
        })
    else
        performLocal(self)
    end

    ISBaseTimedAction.perform(self)
end

return CSR_ToolRepairAction

-- =============================================================================
-- Cat Safehouse Utilities — Client Blocking (context menus & button prompts)
-- =============================================================================
if isServer() then return end

Cat_SafehouseUtilities = Cat_SafehouseUtilities or {}

-- ---------------------------------------------------------------------------
-- Button prompt callbacks: block execution and show feedback
-- ---------------------------------------------------------------------------
local original_cmdToggleLight = ISButtonPrompt.cmdToggleLight
function ISButtonPrompt:cmdToggleLight(light)
    if light and light:getSquare() and Cat_SafehouseUtilities.checkSquareBlocked(light:getSquare()) then
        HaloTextHelper.addBadText(getSpecificPlayer(self.player), "No power — safehouse bill unpaid.")
        return
    end
    original_cmdToggleLight(self, light)
end

local original_cmdToggleStove = ISButtonPrompt.cmdToggleStove
function ISButtonPrompt:cmdToggleStove(stove)
    if stove and stove:getSquare() and Cat_SafehouseUtilities.checkSquareBlocked(stove:getSquare()) then
        HaloTextHelper.addBadText(getSpecificPlayer(self.player), "No power — safehouse bill unpaid.")
        return
    end
    original_cmdToggleStove(self, stove)
end

-- ---------------------------------------------------------------------------
-- Context menu post-filter: remove water/electricity options in unpaid safehouses
-- ---------------------------------------------------------------------------
local FORBIDDEN_SELECTS = {}
FORBIDDEN_SELECTS[ISWorldObjectContextMenu.onToggleLight] = true
FORBIDDEN_SELECTS[ISWorldObjectContextMenu.onToggleStove] = true
FORBIDDEN_SELECTS[ISWorldObjectContextMenu.onStoveSetting] = true
FORBIDDEN_SELECTS[ISWorldObjectContextMenu.onMicrowaveSetting] = true
FORBIDDEN_SELECTS[ISWorldObjectContextMenu.onToggleClothingWasher] = true
FORBIDDEN_SELECTS[ISWorldObjectContextMenu.onToggleComboWasherDryer] = true
FORBIDDEN_SELECTS[ISWorldObjectContextMenu.onSetComboWasherDryerMode] = true
FORBIDDEN_SELECTS[ISWorldObjectContextMenu.onWashClothing] = true
FORBIDDEN_SELECTS[ISWorldObjectContextMenu.onWashYourself] = true

local function isAnyObjectBlocked(worldobjects)
    if not worldobjects then return false end
    for _, obj in ipairs(worldobjects) do
        if obj and obj.getSquare and obj:getSquare() then
            if Cat_SafehouseUtilities.checkSquareBlocked(obj:getSquare()) then
                return true
            end
        end
    end
    return false
end

local function filterMenuOptions(context)
    if not context or not context.options then return end
    for i = #context.options, 1, -1 do
        local opt = context.options[i]
        if opt then
            if FORBIDDEN_SELECTS[opt.onSelect] then
                table.remove(context.options, i)
            elseif opt.subOption then
                local sub = context:getSubMenu(opt.subOption)
                if sub then filterMenuOptions(sub) end
            end
        end
    end
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if not Cat_SafehouseUtilities.isEnabled() then return end
    if not isAnyObjectBlocked(worldobjects) then return end
    filterMenuOptions(context)
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

print("[Cat_SafehouseUtilities] Client blocking loaded.")

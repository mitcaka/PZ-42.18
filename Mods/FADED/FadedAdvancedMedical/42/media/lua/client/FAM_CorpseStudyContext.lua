if isServer() then return end

require "FAM_Core"
require "FAM_ClientCommands"
require "FAM_TriagePanel"
require "TimedActions/FAM_CorpseStudyAction"
require "TimedActions/ISEquipWeaponAction"

FAM_CorpseStudyContext = FAM_CorpseStudyContext or {}

local function makeTooltip(textKey)
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)
    tooltip.description = getText(textKey)
    return tooltip
end

local function getCorpseFromSquare(square)
    if not square then return nil end
    if square.getStaticMovingObjects then
        local objects = square:getStaticMovingObjects()
        if objects then
            for i = 0, objects:size() - 1 do
                local object = objects:get(i)
                if object and instanceof and instanceof(object, "IsoDeadBody") then
                    return object
                end
            end
        end
    end
    if square.getDeadBodys then
        local bodies = square:getDeadBodys()
        if bodies and bodies:size() > 0 then
            return bodies:get(0)
        end
    end
    return nil
end

local function getCorpseFromContext(worldobjects)
    local fetch = ISWorldObjectContextMenu and ISWorldObjectContextMenu.fetchVars or nil
    if fetch and fetch.body and instanceof and instanceof(fetch.body, "IsoDeadBody") then
        return fetch.body
    end
    if not worldobjects then return nil end
    for _, object in ipairs(worldobjects) do
        if object and instanceof and instanceof(object, "IsoDeadBody") then
            return object
        end
        local square = object and object.getSquare and object:getSquare() or nil
        local body = getCorpseFromSquare(square)
        if body then return body end
    end
    return nil
end

local function transferIfNeeded(character, item)
    if not character or not item then return end
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
        ISInventoryPaneContextMenu.transferIfNeeded(character, item)
    end
end

local function queueStudy(playerNum, body, mode)
    local character = getSpecificPlayer(playerNum)
    if not character or not body or not body.getSquare or not body:getSquare() then return end
    if not luautils.walkAdj(character, body:getSquare()) then return end

    local journal = FAM.findPathologyJournal(character)
    local tool = FAM.findPathologyTool(character)
    transferIfNeeded(character, journal)
    transferIfNeeded(character, tool)
    if tool then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(character, tool, 10, true, false))
    end
    ISTimedActionQueue.add(FAM_CorpseStudyAction:new(character, body, tool, journal, mode))
end

local function openPathologyBoard(playerNum)
    local character = getSpecificPlayer(playerNum)
    if not character then return end
    local panel = FAM_TriagePanel.open(character, character)
    if panel then
        panel.activeTab = "pathology"
        FAM_ClientCommands.requestPathology(character)
        panel:syncTabButtons()
    end
end

local function addStudyOption(subMenu, playerNum, body, modeId, labelKey)
    local character = getSpecificPlayer(playerNum)
    local tool = FAM.findPathologyTool(character)
    local journal = FAM.findPathologyJournal(character)
    local valid, reason = FAM.canStudyCorpse(character, body, modeId, tool, journal)
    local option = subMenu:addOption(getText(labelKey), playerNum, queueStudy, body, modeId)
    if not valid then
        option.notAvailable = true
        option.toolTip = makeTooltip(reason or "Tooltip_FAM_PathologyInvalidMode")
    elseif modeId == "study" then
        option.toolTip = makeTooltip("Tooltip_FAM_PathologyStudy")
    elseif modeId == "sample" then
        option.toolTip = makeTooltip("Tooltip_FAM_PathologySampleAction")
    elseif modeId == "autopsy" then
        option.toolTip = makeTooltip("Tooltip_FAM_PathologyAutopsyAction")
    end
    if tool then
        option.itemForTexture = tool
    elseif journal then
        option.itemForTexture = journal
    end
end

function FAM_CorpseStudyContext.onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if test == true or not context then return end
    local character = getSpecificPlayer(playerNum)
    if not character then return end
    local body = getCorpseFromContext(worldobjects)
    if not body or FAM.getCorpseKind(body) == "animal" then return end

    local root = context:addOption(getText("ContextMenu_FAM_Pathology"), nil)
    root.iconTexture = getTexture("media/ui/FAM/TriageIcon.png")
    local subMenu = context:getNew(context)
    context:addSubMenu(root, subMenu)

    addStudyOption(subMenu, playerNum, body, "study", "ContextMenu_FAM_StudyCorpse")
    addStudyOption(subMenu, playerNum, body, "sample", "ContextMenu_FAM_CollectPathologySample")
    addStudyOption(subMenu, playerNum, body, "autopsy", "ContextMenu_FAM_ClinicalAutopsy")
    subMenu:addOption(getText("ContextMenu_FAM_OpenPathologyBoard"), playerNum, openPathologyBoard)
end

if Events and Events.OnFillWorldObjectContextMenu and not FAM_CorpseStudyContext._registered then
    FAM_CorpseStudyContext._registered = true
    Events.OnFillWorldObjectContextMenu.Add(FAM_CorpseStudyContext.onFillWorldObjectContextMenu)
end

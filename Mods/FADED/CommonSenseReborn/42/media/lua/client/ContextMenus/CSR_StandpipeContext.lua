require "CSR_Standpipe"

local function onToggleStandpipe(playerObj, target, wrench, desiredOpen)
    CSR_Standpipe.prepareAction(playerObj, wrench, target)
    ISTimedActionQueue.add(CSR_StandpipeToggleAction:new(playerObj, target, wrench, desiredOpen))
end

local function onContextMenu(playerIndex, context, worldObjects, test)
    if test or not CSR_Standpipe.isEnabled() then
        return
    end

    if not worldObjects or #worldObjects == 0 then
        return
    end

    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj or playerObj:isDead() then
        return
    end

    if playerObj:getPerkLevel(Perks.Strength) < CSR_Standpipe.getMinimumStrength() then
        return
    end

    local wrench = CSR_Standpipe.findPipeWrench(playerObj)
    if not wrench then
        return
    end

    local standpipe = CSR_Standpipe.findStandpipeFromWorldObjects(worldObjects)
    if not standpipe then
        return
    end

    local desiredOpen = not CSR_Standpipe.isOpen(standpipe)
    local optionText = desiredOpen and "Open Standpipe" or "Close Standpipe"
    local option = context:addOption(optionText, playerObj, onToggleStandpipe, standpipe, wrench, desiredOpen)
    if option and wrench.getIcon then
        option.iconTexture = wrench:getIcon()
    end
end

Events.OnFillWorldObjectContextMenu.Add(onContextMenu)

-- Fix vanilla B42 nil-variable bug in ISWorldObjectContextMenu.onFluidInfo:
-- When entity:getGameEntity() returns an IsoObject, the local `c` (ISFluidContainer
-- wrapper) is never created before being passed to ISFluidPanelAction:new(), causing
-- "ISFluidPanelAction not a valid (ISFluidContainer) container?" errors.
local function patchOnFluidInfo()
    if not ISWorldObjectContextMenu or ISWorldObjectContextMenu.__csr_fluidinfo_patched then
        return
    end
    ISWorldObjectContextMenu.__csr_fluidinfo_patched = true

    ISWorldObjectContextMenu.onFluidInfo = function(player, fluidcontainer)
        local playerObj = getSpecificPlayer(player)
        local entity = fluidcontainer:getGameEntity()
        if instanceof(entity, "IsoObject") then
            if luautils.walkAdjObject(playerObj, entity, true) then
                local c = ISFluidContainer:new(fluidcontainer)
                ISTimedActionQueue.add(ISFluidPanelAction:new(playerObj, c, ISFluidInfoUI))
            end
            return
        end
        local square = entity:getSquare()
        if not square or luautils.walkAdj(playerObj, square) then
            local c = ISFluidContainer:new(fluidcontainer)
            ISTimedActionQueue.add(ISFluidPanelAction:new(playerObj, c, ISFluidInfoUI))
        end
    end
end

Events.OnGameStart.Add(patchOnFluidInfo)

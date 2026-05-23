if isClient() then
    return
end


local CSR_Standpipe = require "CSR_Standpipe"
if not CSR_Standpipe then return end

local PRIORITY = 5

local function onStandpipeLoaded(obj)
    if not CSR_Standpipe.isEnabled() or not CSR_Standpipe.isStandpipeObject(obj) then
        return
    end

    obj = CSR_Standpipe.resolveManagedObject(obj)
    if obj then
        CSR_Standpipe.refreshWaterState(obj)
    end
end

local function onWaterAmountChange(obj, _previousAmount)
    if not CSR_Standpipe.isEnabled() or not CSR_Standpipe.isStandpipeObject(obj) then
        return
    end

    obj = CSR_Standpipe.resolveManagedObject(obj)
    if not obj then
        return
    end

    local modData = CSR_Standpipe.ensureManagedData(obj)
    if modData.CSRStandpipeOpen ~= true then
        return
    end

    modData.CSRStandpipeStoredWater = math.max(0.0, math.min(CSR_Standpipe.getFluidAmount(obj), modData.CSRStandpipeWaterMax or CSR_Standpipe.WATER_MAX))
    modData.CSRStandpipeLiveAmountKnown = true
    CSR_Standpipe.syncObject(obj)
end

MapObjects.OnNewWithSprite(CSR_Standpipe.SPRITE_NAME, onStandpipeLoaded, PRIORITY)
MapObjects.OnLoadWithSprite(CSR_Standpipe.SPRITE_NAME, onStandpipeLoaded, PRIORITY)
Events.OnWaterAmountChange.Add(onWaterAmountChange)

ProjectFadedCarLoot = ProjectFadedCarLoot or {}

local PFC_LOOT = ProjectFadedCarLoot

PFC_LOOT.ITEMS = PFC_LOOT.ITEMS or {
    "ProjectFadedCar.EngineServiceKit",
    "ProjectFadedCar.RadiatorServiceKit",
    "ProjectFadedCar.WaterPumpKit",
    "ProjectFadedCar.OilFilterServiceKit",
    "ProjectFadedCar.OilPanServiceKit",
    "ProjectFadedCar.HeadGasketSet",
    "ProjectFadedCar.CylinderHeadServiceKit",
    "ProjectFadedCar.RotatingAssemblyKit",
    "ProjectFadedCar.SparkPlugSet",
    "ProjectFadedCar.IgnitionServicePack",
    "ProjectFadedCar.DriveBelt",
    "ProjectFadedCar.BeltAndPulleyKit",
    "ProjectFadedCar.AlternatorServiceKit",
    "ProjectFadedCar.StarterServiceKit",
    "ProjectFadedCar.TransmissionServiceKit",
    "ProjectFadedCar.TorqueConverterKit",
    "ProjectFadedCar.BrakeAssistKit",
    "ProjectFadedCar.SteeringPumpKit",
    "ProjectFadedCar.ClimateControlKit",
    "ProjectFadedCar.GloveBoxRepairKit",
    "ProjectFadedCar.FreshMotorOil",
    "ProjectFadedCar.CoolantMix",
    "ProjectFadedCar.TransmissionFluid",
}

local function getScriptItem(fullType)
    local manager = nil
    if ScriptManager and ScriptManager.instance then
        manager = ScriptManager.instance
    elseif getScriptManager then
        manager = getScriptManager()
    end
    if not manager then return nil end

    if manager.getItem then
        local item = manager:getItem(fullType)
        if item then return item end
    end
    if manager.FindItem then
        local item = manager:FindItem(fullType)
        if item then return item end
    end
    return nil
end

function PFC_LOOT.markScriptItems()
    local marked = 0
    for _, fullType in ipairs(PFC_LOOT.ITEMS) do
        local scriptItem = getScriptItem(fullType)
        if scriptItem and scriptItem.setCanSpawnAsLoot then
            scriptItem:setCanSpawnAsLoot(true)
            marked = marked + 1
        end
    end

    PFC_LOOT.marked = marked
    if marked > 0 and PFC_LOOT.loggedMarked ~= marked then
        PFC_LOOT.loggedMarked = marked
        print("[ProjectFadedCar] Marked " .. tostring(marked) .. " loot script items")
    end
end

PFC_LOOT.markScriptItems()

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(PFC_LOOT.markScriptItems)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(PFC_LOOT.markScriptItems)
end

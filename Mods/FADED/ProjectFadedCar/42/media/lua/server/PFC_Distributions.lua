if isClient() then return end

require "Items/Distributions"
require "Items/ProceduralDistributions"
require "Items/SuburbsDistributions"
require "Vehicles/VehicleDistributions"

ProjectFadedCarDistributions = ProjectFadedCarDistributions or {}

local PFC_DIST = ProjectFadedCarDistributions
local LOOT_VERSION = 2

print("[ProjectFadedCar] Loot distribution injector loaded")

local function hasWeightedItem(items, item)
    if type(items) ~= "table" then return false end
    for i = 1, #items, 2 do
        if items[i] == item then return true end
    end
    return false
end

local function addWeightedItem(items, item, weight)
    if type(items) ~= "table" then return false end
    if hasWeightedItem(items, item) then return false end
    table.insert(items, item)
    table.insert(items, weight)
    return true
end

local function ensureProc(bucket, rolls)
    if not ProceduralDistributions or not ProceduralDistributions.list then return nil end
    local dist = ProceduralDistributions.list[bucket]
    if type(dist) ~= "table" then
        dist = { rolls = rolls or 1, items = {} }
        ProceduralDistributions.list[bucket] = dist
    end
    if type(dist.items) ~= "table" then
        dist.items = {}
    end
    return dist
end

local function addProc(bucket, item, weight)
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    local dist = ProceduralDistributions.list[bucket]
    if not dist or type(dist.items) ~= "table" then return end
    addWeightedItem(dist.items, item, weight)
end

local function addMany(buckets, items)
    for _, bucket in ipairs(buckets) do
        for _, entry in ipairs(items) do
            addProc(bucket, entry[1], entry[2])
        end
    end
end

local function addProcBucket(bucket, rolls, items)
    local dist = ensureProc(bucket, rolls)
    if not dist then return end
    for _, entry in ipairs(items) do
        addWeightedItem(dist.items, entry[1], entry[2])
    end
end

local function addVehicle(bucket, item, weight)
    if not VehicleDistributions then return end
    local dist = VehicleDistributions[bucket]
    if not dist or type(dist.items) ~= "table" then return end
    addWeightedItem(dist.items, item, weight)
end

local function addVehicles(buckets, items)
    for _, bucket in ipairs(buckets) do
        for _, entry in ipairs(items) do
            addVehicle(bucket, entry[1], entry[2])
        end
    end
end

local function hasProcEntry(procList, bucket)
    if type(procList) ~= "table" then return false end
    for _, entry in ipairs(procList) do
        if type(entry) == "table" and entry.name == bucket then
            return true
        end
    end
    return false
end

local function addSuburbsProc(roomName, containerName, bucket, min, max, weightChance)
    if type(SuburbsDistributions) ~= "table" then return false end
    local room = SuburbsDistributions[roomName]
    if type(room) ~= "table" then return false end
    local container = room[containerName]
    if type(container) ~= "table" then return false end

    container.procedural = true
    container.procList = container.procList or {}
    if hasProcEntry(container.procList, bucket) then return false end

    local entry = {
        name = bucket,
        min = min or 0,
        max = max or 99,
    }
    if weightChance ~= nil then
        entry.weightChance = weightChance
    end
    table.insert(container.procList, entry)
    return true
end

local function markScriptItems()
    if ProjectFadedCarLoot and ProjectFadedCarLoot.markScriptItems then
        ProjectFadedCarLoot.markScriptItems()
    end
end

function PFC_DIST.addLoot()
    if PFC_DIST.lootVersion == LOOT_VERSION then
        markScriptItems()
        return
    end
    if not ProceduralDistributions or not ProceduralDistributions.list then return end

    local coreKits = {
        { "ProjectFadedCar.EngineServiceKit", 1.2 },
        { "ProjectFadedCar.RadiatorServiceKit", 1.0 },
        { "ProjectFadedCar.WaterPumpKit", 0.8 },
        { "ProjectFadedCar.OilFilterServiceKit", 1.4 },
        { "ProjectFadedCar.OilPanServiceKit", 0.7 },
        { "ProjectFadedCar.HeadGasketSet", 0.6 },
        { "ProjectFadedCar.CylinderHeadServiceKit", 0.4 },
        { "ProjectFadedCar.RotatingAssemblyKit", 0.3 },
        { "ProjectFadedCar.SparkPlugSet", 1.4 },
        { "ProjectFadedCar.IgnitionServicePack", 1.4 },
        { "ProjectFadedCar.DriveBelt", 1.6 },
        { "ProjectFadedCar.BeltAndPulleyKit", 0.9 },
        { "ProjectFadedCar.AlternatorServiceKit", 1.0 },
        { "ProjectFadedCar.StarterServiceKit", 1.0 },
        { "ProjectFadedCar.TransmissionServiceKit", 0.8 },
        { "ProjectFadedCar.TorqueConverterKit", 0.5 },
        { "ProjectFadedCar.BrakeAssistKit", 0.6 },
        { "ProjectFadedCar.SteeringPumpKit", 0.6 },
        { "ProjectFadedCar.ClimateControlKit", 0.5 },
        { "ProjectFadedCar.GloveBoxRepairKit", 0.8 },
    }

    local fluids = {
        { "ProjectFadedCar.FreshMotorOil", 2.4 },
        { "ProjectFadedCar.CoolantMix", 1.8 },
        { "ProjectFadedCar.TransmissionFluid", 1.3 },
    }

    addProcBucket("ProjectFadedCar_ServiceParts", 3, coreKits)
    addProcBucket("ProjectFadedCar_Fluids", 2, fluids)

    addSuburbsProc("mechanic", "cardboardbox", "ProjectFadedCar_ServiceParts", 0, 99, 15)
    addSuburbsProc("mechanic", "counter", "ProjectFadedCar_ServiceParts", 0, 99, 20)
    addSuburbsProc("mechanic", "crate", "ProjectFadedCar_ServiceParts", 0, 99, 20)
    addSuburbsProc("mechanic", "metal_shelves", "ProjectFadedCar_ServiceParts", 0, 99, 25)

    addSuburbsProc("carsupply", "counter", "ProjectFadedCar_ServiceParts", 0, 99, 20)
    addSuburbsProc("carsupply", "counter", "ProjectFadedCar_Fluids", 0, 99, 15)
    addSuburbsProc("carsupply", "crate", "ProjectFadedCar_ServiceParts", 0, 99, 20)
    addSuburbsProc("carsupply", "metal_shelves", "ProjectFadedCar_ServiceParts", 0, 99, 20)
    addSuburbsProc("carsupply", "metal_shelves", "ProjectFadedCar_Fluids", 0, 99, 15)
    addSuburbsProc("carsupply", "shelves", "ProjectFadedCar_ServiceParts", 0, 99, 20)
    addSuburbsProc("carsupply", "shelves", "ProjectFadedCar_Fluids", 0, 99, 15)
    addSuburbsProc("carsupply", "toolcabinet", "ProjectFadedCar_ServiceParts", 0, 99, 15)

    addSuburbsProc("carsupplysport", "shelves", "ProjectFadedCar_ServiceParts", 0, 99, 12)
    addSuburbsProc("carsupplysport", "shelves", "ProjectFadedCar_Fluids", 0, 99, 10)
    addSuburbsProc("carsupplysport", "toolcabinet", "ProjectFadedCar_ServiceParts", 0, 99, 12)

    addSuburbsProc("garage_ranger", "metal_shelves", "ProjectFadedCar_ServiceParts", 0, 99, 12)
    addSuburbsProc("garagestorage", "cardboardbox", "ProjectFadedCar_ServiceParts", 0, 99, 8)
    addSuburbsProc("garagestorage", "counter", "ProjectFadedCar_ServiceParts", 0, 99, 12)
    addSuburbsProc("garagestorage", "crate", "ProjectFadedCar_ServiceParts", 0, 99, 12)

    addMany({ "GarageMechanics", "MechanicShelfTools", "CarSupplyTools" }, coreKits)
    addMany({ "GarageMechanics", "MechanicShelfTools", "CarSupplyGasCans", "CarSupplyTools" }, fluids)

    addMany({ "MechanicShelfElectric" }, {
        { "ProjectFadedCar.IgnitionServicePack", 2.0 },
        { "ProjectFadedCar.SparkPlugSet", 2.0 },
        { "ProjectFadedCar.AlternatorServiceKit", 1.8 },
        { "ProjectFadedCar.StarterServiceKit", 1.8 },
        { "ProjectFadedCar.ClimateControlKit", 0.8 },
        { "ProjectFadedCar.GloveBoxRepairKit", 0.7 },
    })

    addMany({ "CrateMechanics", "CrateTools", "ToolStoreTools" }, coreKits)
    addMany({ "CrateMechanics", "CrateTools", "ToolStoreTools" }, fluids)

    addMany({ "GasStorageMechanics", "GasStorageCombo" }, {
        { "ProjectFadedCar.FreshMotorOil", 2.8 },
        { "ProjectFadedCar.CoolantMix", 2.0 },
        { "ProjectFadedCar.TransmissionFluid", 1.5 },
        { "ProjectFadedCar.DriveBelt", 1.0 },
        { "ProjectFadedCar.BeltAndPulleyKit", 0.6 },
        { "ProjectFadedCar.OilFilterServiceKit", 1.2 },
        { "ProjectFadedCar.SparkPlugSet", 0.9 },
        { "ProjectFadedCar.EngineServiceKit", 0.6 },
    })

    addMany({ "BarnTools", "CrateFarming", "ToolCabinetFarming", "ToolStoreFarming" }, {
        { "ProjectFadedCar.DriveBelt", 0.8 },
        { "ProjectFadedCar.BeltAndPulleyKit", 0.4 },
        { "ProjectFadedCar.FreshMotorOil", 0.8 },
        { "ProjectFadedCar.CoolantMix", 0.6 },
        { "ProjectFadedCar.EngineServiceKit", 0.4 },
        { "ProjectFadedCar.RadiatorServiceKit", 0.3 },
        { "ProjectFadedCar.WaterPumpKit", 0.3 },
        { "ProjectFadedCar.OilFilterServiceKit", 0.5 },
        { "ProjectFadedCar.SparkPlugSet", 0.4 },
    })

    addVehicles({ "MechanicGloveBox", "MechanicTruckBed" }, {
        { "ProjectFadedCar.EngineServiceKit", 0.8 },
        { "ProjectFadedCar.OilFilterServiceKit", 0.9 },
        { "ProjectFadedCar.SparkPlugSet", 0.9 },
        { "ProjectFadedCar.DriveBelt", 0.8 },
        { "ProjectFadedCar.BeltAndPulleyKit", 0.4 },
        { "ProjectFadedCar.FreshMotorOil", 1.2 },
        { "ProjectFadedCar.CoolantMix", 0.8 },
        { "ProjectFadedCar.TransmissionFluid", 0.6 },
        { "ProjectFadedCar.GloveBoxRepairKit", 0.5 },
    })

    addVehicles({ "TrunkStandard", "TrunkHeavy", "GloveBox", "FossoilTruckBed", "FossoilGloveBox" }, {
        { "ProjectFadedCar.FreshMotorOil", 0.4 },
        { "ProjectFadedCar.CoolantMix", 0.25 },
        { "ProjectFadedCar.TransmissionFluid", 0.2 },
        { "ProjectFadedCar.DriveBelt", 0.25 },
        { "ProjectFadedCar.SparkPlugSet", 0.2 },
        { "ProjectFadedCar.OilFilterServiceKit", 0.2 },
        { "ProjectFadedCar.GloveBoxRepairKit", 0.15 },
    })

    PFC_DIST.lootVersion = LOOT_VERSION
    PFC_DIST.done = true
    markScriptItems()
    print("[ProjectFadedCar] Loot distribution injection complete")
end

local function safeAddLoot()
    if PFC_DIST.addLoot then
        PFC_DIST.addLoot()
    end
end

if Events and Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(safeAddLoot)
else
    safeAddLoot()
end

if Events and Events.OnPostDistributionMerge then
    Events.OnPostDistributionMerge.Add(safeAddLoot)
end

if Events and Events.OnInitWorld then
    Events.OnInitWorld.Add(safeAddLoot)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(safeAddLoot)
end

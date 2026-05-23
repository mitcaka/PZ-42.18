require "Items/ProceduralDistributions"

local injected = false

local function addToTable(dist, tableName, itemType, weight)
    local tbl = dist and dist[tableName] or nil
    if not tbl or not tbl.items then return 0 end
    table.insert(tbl.items, itemType)
    table.insert(tbl.items, weight)
    return 1
end

local function addGroup(dist, itemTypes, targets)
    local count = 0
    for _, itemType in ipairs(itemTypes) do
        for _, target in ipairs(targets) do
            count = count + addToTable(dist, target.table, itemType, target.weight)
        end
    end
    return count
end

local function injectSignalToolsDistribution()
    if injected then return end

    local dist = ProceduralDistributions and ProceduralDistributions.list or nil
    if not dist then
        print("[CSR] WARNING: ProceduralDistributions.list not available for signal tools injection")
        return
    end
    injected = true

    local glowsticks = {
        "Base.CSR_GlowstickRed",
        "Base.CSR_GlowstickGreen",
        "Base.CSR_GlowstickBlue",
        "Base.CSR_GlowstickWhite",
        "Base.CSR_GlowstickYellow",
        "Base.CSR_GlowstickPurple",
    }
    local handFlares = {
        "Base.CSR_HandFlareRed",
        "Base.CSR_HandFlareGreen",
        "Base.CSR_HandFlareBlue",
        "Base.CSR_HandFlareWhite",
    }

    local injectedCount = 0
    injectedCount = injectedCount + addGroup(dist, glowsticks, {
        { table = "CampingStoreGear", weight = 2.0 },
        { table = "CampingStoreLighting", weight = 2.4 },
        { table = "CrateSurvivalGear", weight = 1.4 },
        { table = "SurvivalGear", weight = 1.0 },
        { table = "ElectronicStoreLights", weight = 1.2 },
        { table = "ElectronicStoreMisc", weight = 0.8 },
        { table = "CrateElectronics", weight = 0.5 },
        { table = "ArmyStorageElectronics", weight = 0.5 },
        { table = "ToolStoreMisc", weight = 0.6 },
    })
    injectedCount = injectedCount + addGroup(dist, handFlares, {
        { table = "CampingStoreGear", weight = 1.4 },
        { table = "CampingStoreLighting", weight = 1.6 },
        { table = "CrateSurvivalGear", weight = 1.2 },
        { table = "SurvivalGear", weight = 0.8 },
        { table = "ArmyStorageAmmunition", weight = 0.8 },
        { table = "PoliceStorageAmmunition", weight = 0.5 },
        { table = "GunStoreAmmunition", weight = 0.7 },
        { table = "SecurityLockers", weight = 0.5 },
    })
    injectedCount = injectedCount + addGroup(dist, { "Base.CSR_SignalPistol" }, {
        { table = "GunStoreGuns", weight = 1.0 },
        { table = "GunStorePistols", weight = 1.1 },
        { table = "GunStoreShelf", weight = 1.0 },
        { table = "GunStoreCounter", weight = 0.8 },
        { table = "GunStoreDisplayCase", weight = 1.0 },
        { table = "PoliceStorageGuns", weight = 0.8 },
        { table = "ArmyStorageGuns", weight = 0.7 },
        { table = "RangerStorageGuns", weight = 0.6 },
        { table = "PawnShopGuns", weight = 0.5 },
        { table = "PawnShopGunsSpecial", weight = 0.6 },
        { table = "CampingStoreGear", weight = 0.35 },
    })
    injectedCount = injectedCount + addGroup(dist, { "Base.CSR_SignalFlareRoundBox" }, {
        { table = "GunStoreAmmunition", weight = 1.4 },
        { table = "GunStoreMagsAmmo", weight = 1.2 },
        { table = "ArmyStorageAmmunition", weight = 1.0 },
        { table = "PoliceStorageAmmunition", weight = 0.8 },
        { table = "PoliceStorageGuns", weight = 0.5 },
        { table = "SecurityLockers", weight = 0.4 },
    })
    injectedCount = injectedCount + addGroup(dist, { "Base.CSR_SignalFlareRound" }, {
        { table = "GunStoreCounter", weight = 0.8 },
        { table = "GunStoreAmmunition", weight = 1.0 },
        { table = "GunStoreMagsAmmo", weight = 0.8 },
        { table = "ArmyStorageAmmunition", weight = 0.8 },
        { table = "PoliceStorageAmmunition", weight = 0.6 },
        { table = "CampingStoreGear", weight = 0.3 },
    })

    print("[CSR] Signal tools distribution injected into " .. injectedCount .. " loot table entries")
end

if Events and Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(injectSignalToolsDistribution)
elseif Events and Events.OnPostDistributionMerge then
    Events.OnPostDistributionMerge.Add(injectSignalToolsDistribution)
elseif Events and Events.OnInitWorld then
    Events.OnInitWorld.Add(injectSignalToolsDistribution)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(injectSignalToolsDistribution)
end

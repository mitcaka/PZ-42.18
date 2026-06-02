require "CSR_FeatureFlags"
require "Items/ProceduralDistributions"

local ITEM = "Base.CSR_AntibodySyringeEmpty"

local function injectAntibodyDistribution()
    if not CSR_FeatureFlags.isAntibodySystemEnabled() then return end

    local dist = ProceduralDistributions and ProceduralDistributions.list or nil
    if not dist then
        print("[CSR] WARNING: ProceduralDistributions.list not available for antibody syringe injection")
        return
    end

    local targets = {
        { table = "MedicalClinicDrugs", weight = 4 },
        { table = "MedicalStorageDrugs", weight = 4 },
        { table = "HospitalRoomShelves", weight = 3 },
        { table = "BathroomCabinet", weight = 0.5 },
        { table = "CrateMedical", weight = 3 },
        { table = "ArmyStorageMedical", weight = 2 },
        { table = "PoliceStorageMedical", weight = 1 },
        { table = "DoctorTools", weight = 3 },
    }

    local injected = 0
    for _, entry in ipairs(targets) do
        local tbl = dist[entry.table]
        if tbl and tbl.items then
            table.insert(tbl.items, ITEM)
            table.insert(tbl.items, entry.weight)
            injected = injected + 1
        end
    end

    print("[CSR] Antibody syringe distribution injected into " .. injected .. " / " .. #targets .. " loot tables")
end

if Events and Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(injectAntibodyDistribution)
elseif Events and Events.OnPostDistributionMerge then
    Events.OnPostDistributionMerge.Add(injectAntibodyDistribution)
elseif Events and Events.OnInitWorld then
    Events.OnInitWorld.Add(injectAntibodyDistribution)
end

if Events and Events.OnGameStart then
    local done = false
    Events.OnGameStart.Add(function()
        if done then return end
        done = true
        injectAntibodyDistribution()
    end)
end

require "Items/ProceduralDistributions"

local ITEM = "Base.CSR_WeaponizedBrick"

local function injectWeaponizedBrickDistribution()
    local dist = ProceduralDistributions and ProceduralDistributions.list or nil
    if not dist then
        print("[CSR] WARNING: ProceduralDistributions.list not available for weaponized brick injection")
        return
    end

    local targets = {
        { table = "CrateTools", weight = 0.8 },
        { table = "CrateConcrete", weight = 1.0 },
        { table = "CrateGravelBags", weight = 1.0 },
        { table = "GarageTools", weight = 0.4 },
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

    print("[CSR] Weaponized Brick distribution injected into " .. injected .. " / " .. #targets .. " loot tables")
end

if Events and Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(injectWeaponizedBrickDistribution)
elseif Events and Events.OnPostDistributionMerge then
    Events.OnPostDistributionMerge.Add(injectWeaponizedBrickDistribution)
elseif Events and Events.OnInitWorld then
    Events.OnInitWorld.Add(injectWeaponizedBrickDistribution)
end

if Events and Events.OnGameStart then
    local done = false
    Events.OnGameStart.Add(function()
        if done then return end
        done = true
        injectWeaponizedBrickDistribution()
    end)
end

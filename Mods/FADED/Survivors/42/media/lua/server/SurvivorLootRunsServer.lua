require "BanditCompatibility"
require "SurvivorsCSRBridge"

if isClient() then return end

SurvivorLootRuns = SurvivorLootRuns or {}

local CATEGORY_DATA = {
    food = {
        label = "Food",
        duration = {3.5, 6.0},
        rolls = {4, 8},
        items = {
            "Base.TinnedBeans",
            "Base.CannedSoup",
            "Base.CannedCorn",
            "Base.CannedChili",
            "Base.TunaTin",
            "Base.Rice",
            "Base.Pasta",
        },
    },
    medicine = {
        label = "Medicine",
        duration = {4.0, 7.0},
        rolls = {3, 6},
        items = {
            "Base.Bandage",
            "Base.AlcoholWipes",
            "Base.Disinfectant",
            "Base.Pills",
            "Base.PillsBeta",
            "Base.SutureNeedle",
        },
    },
    ammo = {
        label = "Ammo",
        duration = {5.0, 8.0},
        rolls = {2, 5},
        items = {
            "Base.Bullets9mm",
            "Base.ShotgunShells",
            "Base.223Bullets",
            "Base.308Bullets",
            "Base.44Bullets",
        },
    },
    tools = {
        label = "Tools",
        duration = {4.0, 7.0},
        rolls = {3, 6},
        items = {
            "Base.NailsBox",
            "Base.DuctTape",
            "Base.Woodglue",
            "Base.Screwdriver",
            "Base.Hammer",
            "Base.Saw",
        },
    },
    materials = {
        label = "Materials",
        duration = {4.0, 7.5},
        rolls = {4, 8},
        items = {
            "Base.Plank",
            "Base.SheetMetal",
            "Base.ScrewsBox",
            "Base.ElectronicsScrap",
            "Base.ElectricWire",
        },
    },
}

local function nowHours()
    local gt = getGameTime and getGameTime() or nil
    if gt and gt.getWorldAgeHours then return gt:getWorldAgeHours() end
    return 0
end

local function getRuns()
    local gmd = GetBanditModData()
    if not gmd.SurvivorLootRuns then gmd.SurvivorLootRuns = {} end
    return gmd.SurvivorLootRuns
end

local function getBrain(npcId)
    local numericId = tonumber(npcId)
    if not numericId then return nil end
    local cluster = GetBanditClusterData(numericId)
    local brain = cluster and (cluster[numericId] or cluster[tostring(numericId)])
    return brain, cluster, numericId
end

local function syncBrain(npcId, brain, cluster)
    if not npcId or not brain or not cluster then return end
    local numericId = tonumber(npcId) or npcId
    cluster[numericId] = brain
    TransmitBanditCluster(numericId)
end

local function syncItem(item)
    if not item then return end
    if item.transmitModData then item:transmitModData() end
    local container = item.getContainer and item:getContainer() or nil
    if container and sendReplaceItemInContainer then
        sendReplaceItemInContainer(container, item, item)
    elseif sendItemStats then
        sendItemStats(item)
    end
end

local function rollInt(minValue, maxValue)
    minValue = tonumber(minValue) or 0
    maxValue = tonumber(maxValue) or minValue
    if maxValue < minValue then maxValue = minValue end
    return minValue + ZombRand((maxValue - minValue) + 1)
end

local function rollFloat(minValue, maxValue)
    minValue = tonumber(minValue) or 0
    maxValue = tonumber(maxValue) or minValue
    if maxValue < minValue then maxValue = minValue end
    return minValue + ZombRandFloat(0, maxValue - minValue)
end

local function getCategory(category)
    category = tostring(category or "food")
    return category, CATEGORY_DATA[category] or CATEGORY_DATA.food
end

local function createJob(player, brain, category, home)
    local categoryKey, data = getCategory(category)
    local startAt = nowHours()
    local duration = rollFloat(data.duration[1], data.duration[2])
    local npcId = tonumber(brain.id)

    return {
        id = tostring(npcId) .. "-" .. tostring(math.floor(startAt * 1000)),
        npcId = npcId,
        npcName = brain.fullname,
        ownerId = BanditUtils.GetCharacterID(player),
        ownerUsername = player:getUsername(),
        category = categoryKey,
        categoryLabel = data.label,
        status = "active",
        startedAt = startAt,
        returnAt = startAt + duration,
        duration = duration,
        home = home,
        rewards = {},
    }
end

local function rollRewards(category)
    local _, data = getCategory(category)
    local rewards = {}
    local rolls = rollInt(data.rolls[1], data.rolls[2])

    for _ = 1, rolls do
        local itemType = data.items[ZombRand(#data.items) + 1]
        rewards[itemType] = (rewards[itemType] or 0) + 1
    end

    -- Keep failures rare and mild: the survivor returns, but may find little.
    if ZombRand(100) < 12 then
        local kept = {}
        local keepOne = false
        for itemType, count in pairs(rewards) do
            if not keepOne then
                kept[itemType] = math.max(1, math.floor(count / 2))
                keepOne = true
            end
        end
        rewards = kept
    end

    return rewards
end

local function notify(player, command, payload)
    if player and sendServerCommand then
        sendServerCommand(player, "Commands", command, payload or {})
    end
end

function SurvivorLootRuns.Start(player, args)
    if not player or not args or not args.npcId then return false, "invalidArgs" end

    local brain, cluster, numericId = getBrain(args.npcId)
    if not brain then return false, "missingSurvivor" end

    local ownerId = BanditUtils.GetCharacterID(player)
    if brain.master and tonumber(brain.master) ~= tonumber(ownerId) then
        notify(player, "SurvivorLootRunRejected", {npcId=numericId, reason="wrongOwner"})
        return false, "wrongOwner"
    end

    local runs = getRuns()
    local key = tostring(numericId)
    local existing = runs[key]
    if existing and existing.status and existing.status ~= "collected" then
        notify(player, "SurvivorLootRunRejected", {npcId=numericId, reason="alreadyRunning"})
        return false, "alreadyRunning"
    end

    local gmd = GetBanditModData()
    local home = type(brain.survivorBase) == "table" and brain.survivorBase or (gmd.SurvivorBaseAssignments and gmd.SurvivorBaseAssignments[key])
    if type(home) ~= "table" then
        notify(player, "SurvivorLootRunRejected", {npcId=numericId, reason="noBase"})
        return false, "noBase"
    end

    local job = createJob(player, brain, args.category, home)
    runs[key] = job

    brain.master = ownerId
    brain.hostile = false
    brain.hostileP = false
    brain.survivorLootRun = job
    brain.program = {name="SurvivorLootRun", stage="Prepare"}
    brain.tasks = {}
    syncBrain(numericId, brain, cluster)

    if SurvivorsCSRBridge and SurvivorsCSRBridge.notify then
        SurvivorsCSRBridge.notify("LootRunStarted", job)
    end

    TransmitBanditModData()
    notify(player, "SurvivorLootRunStarted", job)
    return true, job
end

local function completeJob(npcId, job)
    if not job or job.status ~= "active" then return end

    job.status = "completed"
    job.completedAt = nowHours()
    job.rewards = rollRewards(job.category)

    local brain, cluster, numericId = getBrain(npcId)
    if brain then
        brain.survivorLootRun = job
        brain.program = {name="SurvivorLootRun", stage="Prepare"}
        brain.tasks = {}
        syncBrain(numericId, brain, cluster)
    end

    if SurvivorsCSRBridge and SurvivorsCSRBridge.notify then
        SurvivorsCSRBridge.notify("LootRunCompleted", job)
    end
    if sendServerCommand then
        sendServerCommand("Commands", "SurvivorLootRunCompleted", job)
    end
end

function SurvivorLootRuns.Resolve()
    local runs = getRuns()
    local now = nowHours()
    local changed = false

    for npcId, job in pairs(runs) do
        if job and job.status == "active" and (tonumber(job.returnAt) or math.huge) <= now then
            completeJob(npcId, job)
            changed = true
        end
    end

    if changed then
        TransmitBanditModData()
    end
end

function SurvivorLootRuns.Collect(player, args)
    if not player or not args or not args.npcId then return false, "invalidArgs" end

    SurvivorLootRuns.Resolve()

    local numericId = tonumber(args.npcId)
    if not numericId then return false, "invalidArgs" end
    local key = tostring(numericId)
    local runs = getRuns()
    local job = runs[key]
    if not job or job.status ~= "completed" then
        notify(player, "SurvivorLootRunRejected", {npcId=numericId, reason="notReady"})
        return false, "notReady"
    end

    local ownerId = BanditUtils.GetCharacterID(player)
    if job.ownerId and tonumber(job.ownerId) ~= tonumber(ownerId) then
        notify(player, "SurvivorLootRunRejected", {npcId=numericId, reason="wrongOwner"})
        return false, "wrongOwner"
    end

    local inv = player:getInventory()
    local delivered = {}
    for itemType, count in pairs(job.rewards or {}) do
        for _ = 1, count do
            local item = BanditCompatibility.InstanceItem(itemType)
            if item then
                inv:AddItem(item)
                syncItem(item)
                delivered[itemType] = (delivered[itemType] or 0) + 1
            end
        end
    end

    runs[key] = nil

    local brain, cluster = getBrain(numericId)
    if brain then
        brain.survivorLootRun = false
        brain.program = brain.survivorBase and {name="SurvivorBase", stage="Prepare"} or {name="Companion", stage="Prepare"}
        brain.tasks = {}
        syncBrain(numericId, brain, cluster)
    end

    local payload = {
        npcId = numericId,
        npcName = job.npcName,
        category = job.category,
        rewards = delivered,
    }

    if SurvivorsCSRBridge and SurvivorsCSRBridge.notify then
        SurvivorsCSRBridge.notify("LootRunCollected", payload)
    end

    TransmitBanditModData()
    notify(player, "SurvivorLootRunCollected", payload)
    return true, payload
end

local function onEveryTenMinutes()
    SurvivorLootRuns.Resolve()
end

Events.EveryTenMinutes.Remove(onEveryTenMinutes)
Events.EveryTenMinutes.Add(onEveryTenMinutes)

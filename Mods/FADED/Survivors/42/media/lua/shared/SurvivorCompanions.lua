SurvivorCompanions = SurvivorCompanions or {}

SurvivorCompanions.Groups = {"None", "Alpha", "Bravo", "Charlie", "Delta"}
SurvivorCompanions.CombatModes = {"defensive", "aggressive", "passive"}
SurvivorCompanions.LoadoutModes = {"balanced", "ranged", "melee"}

local function contains(values, expected)
    for _, value in ipairs(values) do
        if value == expected then return true end
    end
    return false
end

local function syncBrainPart(bandit, brain, values)
    if not bandit or not brain or not Bandit or not Bandit.ForceSyncPart then return end
    values.id = brain.id or BanditUtils.GetCharacterID(bandit)
    Bandit.ForceSyncPart(bandit, values)
end

function SurvivorCompanions.NormalizeBrain(brain)
    if not brain then return nil end

    if type(brain.companionOrder) ~= "table" then
        brain.companionOrder = {mode="follow"}
    end
    if not contains({"follow", "stay", "goto"}, brain.companionOrder.mode) then
        brain.companionOrder.mode = "follow"
    end

    brain.companionGroup = brain.companionGroup or "None"
    if not contains(SurvivorCompanions.Groups, brain.companionGroup) then
        brain.companionGroup = "None"
    end
    brain.companionCombatMode = brain.companionCombatMode or "defensive"
    if not contains(SurvivorCompanions.CombatModes, brain.companionCombatMode) then
        brain.companionCombatMode = "defensive"
    end
    brain.companionLoadoutMode = brain.companionLoadoutMode or "balanced"
    if not contains(SurvivorCompanions.LoadoutModes, brain.companionLoadoutMode) then
        brain.companionLoadoutMode = "balanced"
    end

    if type(brain.companionSkills) ~= "table" then
        brain.companionSkills = {}
    end
    brain.companionSkills.melee = tonumber(brain.companionSkills.melee) or 0
    brain.companionSkills.firearms = tonumber(brain.companionSkills.firearms) or 0
    brain.companionSkills.survival = tonumber(brain.companionSkills.survival) or 0

    if type(brain.companionMedical) ~= "table" then
        brain.companionMedical = {status="healthy", wounds=0}
    end
    brain.companionMedical.status = brain.companionMedical.status or "healthy"
    brain.companionMedical.wounds = tonumber(brain.companionMedical.wounds) or 0
    brain.companionDowned = brain.companionDowned == true
    brain.companionMaxHealth = tonumber(brain.companionMaxHealth) or math.max(1, tonumber(brain.health) or 1)

    return brain
end

function SurvivorCompanions.IsDirectCompanion(brain)
    if not brain or brain.hostile or brain.hostileP then return false end
    if not brain.master or type(brain.survivorBase) == "table" then return false end
    local programName = brain.program and brain.program.name or brain.programFallback
    return programName == "Companion" or programName == "CompanionGuard"
end

function SurvivorCompanions.GetSkillLevel(brain, skill)
    brain = SurvivorCompanions.NormalizeBrain(brain)
    if not brain then return 0 end
    return math.min(10, math.floor((tonumber(brain.companionSkills[skill]) or 0) / 10))
end

function SurvivorCompanions.AddSkillXP(bandit, skill, amount)
    local brain = bandit and BanditBrain.Get(bandit) or nil
    if not SurvivorCompanions.IsDirectCompanion(brain) then return end
    SurvivorCompanions.NormalizeBrain(brain)
    if brain.companionDowned then return end

    brain.companionSkills[skill] = math.max(0, (tonumber(brain.companionSkills[skill]) or 0) + (tonumber(amount) or 0))
    syncBrainPart(bandit, brain, {companionSkills=brain.companionSkills})
end

function SurvivorCompanions.SetLocalOrder(bandit, mode, x, y, z)
    local brain = bandit and BanditBrain.Get(bandit) or nil
    if not SurvivorCompanions.IsDirectCompanion(brain) then return end
    SurvivorCompanions.NormalizeBrain(brain)

    local order = {mode=mode or "follow"}
    if order.mode == "stay" or order.mode == "goto" then
        order.x = tonumber(x) or bandit:getX()
        order.y = tonumber(y) or bandit:getY()
        order.z = tonumber(z) or bandit:getZ()
    end
    brain.companionOrder = order
    brain.tasks = {}
    Bandit.ClearTasks(bandit)
    Bandit.ForceStationary(bandit, false)
    BanditBrain.Update(bandit, brain)
end

function SurvivorCompanions.SetDowned(bandit, injury)
    local brain = bandit and BanditBrain.Get(bandit) or nil
    if not SurvivorCompanions.IsDirectCompanion(brain) then return false end
    SurvivorCompanions.NormalizeBrain(brain)
    if brain.companionDowned then return true end

    brain.companionDowned = true
    brain.companionMedical = {
        status = "downed",
        injury = tostring(injury or "critical wounds"),
        wounds = (tonumber(brain.companionMedical.wounds) or 0) + 1,
    }
    brain.companionOrder = {mode="stay", x=bandit:getX(), y=bandit:getY(), z=bandit:getZ()}
    brain.tasks = {}
    brain.health = 0.18

    Bandit.ClearTasks(bandit)
    Bandit.ForceStationary(bandit, true)
    bandit:setHealth(0.18)
    pcall(function() bandit:setKnockedDown(true) end)
    pcall(function() bandit:knockDown(true) end)
    BanditBrain.Update(bandit, brain)
    syncBrainPart(bandit, brain, {
        companionDowned=true,
        companionMedical=brain.companionMedical,
        companionOrder=brain.companionOrder,
        tasks=brain.tasks,
        health=brain.health,
    })
    return true
end

function SurvivorCompanions.MaintainDowned(bandit, brain)
    if not bandit or not brain then return false end
    SurvivorCompanions.NormalizeBrain(brain)
    if not brain.companionDowned then return false end

    Bandit.ClearTasks(bandit)
    Bandit.ForceStationary(bandit, true)
    bandit:setHealth(math.max(0.18, bandit:getHealth()))
    pcall(function() bandit:setKnockedDown(true) end)
    pcall(function() bandit:knockDown(true) end)
    return true
end

function SurvivorCompanions.UpdateStuck(bandit, brain)
    if not bandit or not SurvivorCompanions.IsDirectCompanion(brain) or brain.companionDowned then return end
    if not Bandit.HasMoveTask(bandit) then
        bandit:getModData().survivorCompanionStuck = nil
        return
    end

    local md = bandit:getModData()
    local tracker = md.survivorCompanionStuck
    if type(tracker) ~= "table" then
        tracker = {x=bandit:getX(), y=bandit:getY(), ticks=0, retries=0}
        md.survivorCompanionStuck = tracker
        return
    end

    tracker.ticks = (tonumber(tracker.ticks) or 0) + 1
    if tracker.ticks < 180 then return end

    local dx = bandit:getX() - (tonumber(tracker.x) or bandit:getX())
    local dy = bandit:getY() - (tonumber(tracker.y) or bandit:getY())
    tracker.x = bandit:getX()
    tracker.y = bandit:getY()
    tracker.ticks = 0

    if (dx * dx) + (dy * dy) >= 0.25 then
        tracker.retries = 0
        return
    end

    tracker.retries = (tonumber(tracker.retries) or 0) + 1
    pcall(function() bandit:getPathFindBehavior2():cancel() end)
    pcall(function() bandit:setPath2(nil) end)
    Bandit.ClearTasks(bandit)

    local order = brain.companionOrder
    if tracker.retries >= 2 and type(order) == "table" and order.mode == "goto" then
        local offsets = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}
        local offset = offsets[((tracker.retries - 2) % #offsets) + 1]
        order.retryX = (tonumber(order.x) or bandit:getX()) + offset[1]
        order.retryY = (tonumber(order.y) or bandit:getY()) + offset[2]
    end
end

return SurvivorCompanions

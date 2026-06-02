ZombiePrograms = ZombiePrograms or {}

ZombiePrograms.RecruitableSurvivor = {}

local APPROACH_RANGE = 70
local WAIT_DISTANCE = 4

local function waitForPlayer(bandit, tasks)
    Bandit.ForceStationary(bandit, true)
    table.insert(tasks, {action="Time", anim="Shrug", time=200})
    return {status=true, next="Main", tasks=tasks}
end

ZombiePrograms.RecruitableSurvivor.Prepare = function(bandit)
    Bandit.ForceStationary(bandit, false)
    return {status=true, next="Main", tasks={}}
end

ZombiePrograms.RecruitableSurvivor.Main = function(bandit)
    local tasks = {}
    local brain = BanditBrain.Get(bandit)
    if not brain or brain.recruitableSeeker ~= true or brain.recruitableSeekerClaimed == true then
        Bandit.SetProgram(bandit, "Looter", {})
        return {status=true, next="Prepare", tasks=tasks}
    end

    Bandit.SetHostile(bandit, false)
    Bandit.SetHostileP(bandit, false)
    Bandit.ForceStationary(bandit, false)

    local playerLocation = BanditUtils.GetClosestPlayerLocation(bandit, {
        hearDist = APPROACH_RANGE,
        levelDiff = 1,
    })
    if not playerLocation.x or playerLocation.dist > APPROACH_RANGE then
        return waitForPlayer(bandit, tasks)
    end

    if playerLocation.dist <= WAIT_DISTANCE then
        return waitForPlayer(bandit, tasks)
    end

    local walkType = playerLocation.dist > 14 and "Run" or "Walk"
    table.insert(tasks, BanditUtils.GetMoveTask(
        0,
        playerLocation.x,
        playerLocation.y,
        playerLocation.z,
        walkType,
        playerLocation.dist,
        true
    ))
    return {status=true, next="Main", tasks=tasks}
end

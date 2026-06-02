ZombiePrograms = ZombiePrograms or {}

ZombiePrograms.SurvivorLootRun = {}

local function getNowHours()
    if getGameTime then
        local gt = getGameTime()
        if gt and gt.getWorldAgeHours then
            return gt:getWorldAgeHours()
        end
    end
    return 0
end

local function getHome(brain, job)
    local home = job and job.home or nil
    if type(home) ~= "table" then
        home = brain and brain.survivorBase or nil
    end
    if type(home) ~= "table" then return nil end

    home.cx = tonumber(home.cx) or (home.x and home.x2 and ((home.x + home.x2) / 2)) or tonumber(home.x)
    home.cy = tonumber(home.cy) or (home.y and home.y2 and ((home.y + home.y2) / 2)) or tonumber(home.y)
    home.cz = tonumber(home.cz) or tonumber(home.z) or 0
    home.radius = tonumber(home.radius) or 45
    return home
end

local function appendIdle(tasks, bandit)
    local subTasks = BanditPrograms.Idle(bandit)
    if subTasks and #subTasks > 0 then
        for _, task in pairs(subTasks) do
            table.insert(tasks, task)
        end
    else
        table.insert(tasks, {action="Time", anim="ShiftWeight", time=200})
    end
end

local function moveTo(tasks, bandit, x, y, z, walkType)
    local dist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), x, y)
    table.insert(tasks, BanditUtils.GetMoveTask(0, x, y, z or 0, walkType or "Walk", dist, false))
    return true
end

ZombiePrograms.SurvivorLootRun.Prepare = function(bandit)
    Bandit.ForceStationary(bandit, false)
    return {status=true, next="Main", tasks={}}
end

ZombiePrograms.SurvivorLootRun.Main = function(bandit)
    local tasks = {}
    local brain = BanditBrain.Get(bandit)
    local job = brain and brain.survivorLootRun or nil

    if type(job) ~= "table" then
        Bandit.SetProgram(bandit, "SurvivorBase", {})
        return {status=true, next="Prepare", tasks=tasks}
    end

    local home = getHome(brain, job)
    if not home or not home.cx or not home.cy then
        Bandit.SetProgram(bandit, "Companion", {})
        return {status=true, next="Prepare", tasks=tasks}
    end

    Bandit.SetHostile(bandit, false)
    Bandit.SetHostileP(bandit, false)

    local status = tostring(job.status or "active")
    local due = (tonumber(job.returnAt) or math.huge) <= getNowHours()
    local bx, by, bz = bandit:getX(), bandit:getY(), bandit:getZ()
    local distHome = BanditUtils.DistTo(bx, by, home.cx, home.cy)

    -- The server resolves the off-map search timer and rolls fresh rewards.
    -- Keep the on-map representative at home so supply runs never pull colonists out of their zone.
    if distHome > 4 or math.abs(bz - home.cz) > 1 then
        Bandit.ForceStationary(bandit, false)
        moveTo(tasks, bandit, home.cx, home.cy, home.cz, distHome > 16 and "Run" or "Walk")
        return {status=true, next="Main", tasks=tasks}
    end

    Bandit.ForceStationary(bandit, true)
    if status == "completed" or due then
        appendIdle(tasks, bandit)
    else
        table.insert(tasks, {action="Time", anim="LootLow", time=250})
    end
    return {status=true, next="Main", tasks=tasks}
end

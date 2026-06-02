ZombiePrograms = ZombiePrograms or {}

ZombiePrograms.SurvivorBase = {}

local GUARD_BOUNDARY_MARGIN = 6

local function getHome(brain)
    if not brain then return nil end
    local home = brain.survivorBase
    if type(home) ~= "table" then return nil end

    home.cx = tonumber(home.cx) or (home.x and home.x2 and ((home.x + home.x2) / 2)) or home.x
    home.cy = tonumber(home.cy) or (home.y and home.y2 and ((home.y + home.y2) / 2)) or home.y
    home.cz = tonumber(home.cz) or tonumber(home.z) or 0
    home.radius = tonumber(home.radius) or 45
    home.mode = home.mode or "defend"
    return home
end

local function appendTasks(tasks, subTasks)
    if not subTasks or #subTasks == 0 then return false end
    for _, task in pairs(subTasks) do
        table.insert(tasks, task)
    end
    return true
end

local function getClosestBaseEnemy(bandit, radius)
    local config = { levelDiff = 1 }
    local closestZombie = BanditUtils.GetClosestZombieLocation(bandit, config)
    local closestBandit = BanditUtils.GetClosestEnemyBanditLocation(bandit, config)
    local closest = closestZombie

    if closestBandit and closestBandit.dist and (not closest or not closest.dist or closestBandit.dist < closest.dist) then
        closest = closestBandit
    end

    if closest and closest.x and closest.dist <= radius then
        return closest
    end
end

local function isSurvivorZoneHome(home)
    return home and (home.source == "survivorZone" or home.zoneId ~= nil)
end

local function isWithinHome(home, x, y, z, margin)
    if not home then return false end
    margin = tonumber(margin) or 0
    if math.abs((tonumber(z) or 0) - (tonumber(home.cz or home.z) or 0)) > 1 then
        return false
    end

    if isSurvivorZoneHome(home) and home.x and home.y and home.x2 and home.y2 then
        return x >= (math.min(home.x, home.x2) - margin)
            and x <= (math.max(home.x, home.x2) + margin)
            and y >= (math.min(home.y, home.y2) - margin)
            and y <= (math.max(home.y, home.y2) + margin)
    end

    return BanditUtils.DistTo(x, y, home.cx, home.cy) <= ((tonumber(home.radius) or 45) + margin)
end

local function moveTo(tasks, bandit, x, y, z, walkType)
    local dist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), x, y)
    table.insert(tasks, BanditUtils.GetMoveTask(0, x, y, z or 0, walkType or "Walk", dist, false))
    return true
end

local function moveToSquare(tasks, bandit, square, walkType)
    if not square then return false end
    local dist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), square:getX() + 0.5, square:getY() + 0.5)
    if dist < 1.1 then return false end
    table.insert(tasks, BanditUtils.GetMoveTask(0, square:getX(), square:getY(), square:getZ(), walkType or "Walk", dist, false))
    return true
end

local function getRoomFreeSquare(bandit)
    local square = bandit and bandit:getSquare() or nil
    local room = square and square:getRoom() or nil
    local roomDef = room and room:getRoomDef() or nil
    if roomDef and roomDef.getFreeSquare then
        return roomDef:getFreeSquare()
    end
end

local function getRandomHomeSquare(home)
    local cell = getCell and getCell() or nil
    if not cell or not home then return nil end

    local x1 = math.floor(tonumber(home.x) or tonumber(home.cx) or 0)
    local y1 = math.floor(tonumber(home.y) or tonumber(home.cy) or 0)
    local x2 = math.floor(tonumber(home.x2) or x1)
    local y2 = math.floor(tonumber(home.y2) or y1)
    local z = math.floor(tonumber(home.cz or home.z) or 0)

    if x2 < x1 then x1, x2 = x2, x1 end
    if y2 < y1 then y1, y2 = y2, y1 end

    for _ = 1, 20 do
        local x = x1 + ZombRand(math.max(1, x2 - x1 + 1))
        local y = y1 + ZombRand(math.max(1, y2 - y1 + 1))
        local square = cell:getGridSquare(x, y, z)
        if square and (not square.isFree or square:isFree(false)) then
            return square
        end
    end
end

local function doCivilianLife(tasks, bandit, home)
    local enemy = getClosestBaseEnemy(bandit, math.max(12, math.floor((home.radius or 30) / 2)))
    if enemy then
        Bandit.ForceStationary(bandit, false)
        moveTo(tasks, bandit, home.cx, home.cy, home.cz, "Run")
        return true
    end

    local square = bandit:getSquare()
    local room = square and square:getRoom() or nil
    if room then
        if ZombRand(7) == 0 then
            local subTasks = BanditPrograms.Self.Wash(bandit)
            if appendTasks(tasks, subTasks) then return true end
        end

        if ZombRand(4) == 0 and moveToSquare(tasks, bandit, getRoomFreeSquare(bandit), "Walk") then
            Bandit.ForceStationary(bandit, false)
            return true
        end

        local roll = ZombRand(6)
        if roll == 0 then
            table.insert(tasks, {action="TimeItem", anim="ReadBook", item="Base.Book", left=true, time=500})
        elseif roll == 1 then
            table.insert(tasks, {action="Sleep", anim="SitRubHands", time=300})
        elseif roll == 2 then
            table.insert(tasks, {action="Time", anim="WaveHi", time=140})
        elseif roll == 3 then
            table.insert(tasks, {action="Time", anim="Yes", time=120})
        else
            appendTasks(tasks, BanditPrograms.Idle(bandit))
        end

        if Bandit.SayLocation and ZombRand(10) == 0 then
            Bandit.SayLocation(bandit, square)
        end
        Bandit.ForceStationary(bandit, true)
        return true
    end

    local homeSquare = getRandomHomeSquare(home)
    if moveToSquare(tasks, bandit, homeSquare, "Walk") then
        Bandit.ForceStationary(bandit, false)
        return true
    end

    Bandit.ForceStationary(bandit, true)
    appendTasks(tasks, BanditPrograms.Idle(bandit))
    return true
end

local function defendBase(tasks, bandit, home)
    local enemy = getClosestBaseEnemy(bandit, math.max(24, home.radius))
    if not enemy then return false end
    if isSurvivorZoneHome(home) and not isWithinHome(home, enemy.x, enemy.y, enemy.z, GUARD_BOUNDARY_MARGIN) then
        return false
    end

    if enemy.dist > 5 then
        local walkType = Bandit.IsOutOfAmmo(bandit) and "Run" or "WalkAim"
        table.insert(tasks, BanditUtils.GetMoveTask(0, enemy.x, enemy.y, enemy.z, walkType, enemy.dist, false))
    else
        table.insert(tasks, {action="FaceLocation", x=enemy.x, y=enemy.y, time=80})
    end
    return true
end

local function doBaseWork(tasks, bandit)
    local subTasks

    if getWorld() and not getWorld():isHydroPowerOn() then
        local generator = BanditPlayerBase.GetGenerator(bandit)
        if generator then
            if generator:getCondition() < 60 then
                subTasks = BanditPrograms.Generator.Repair(bandit, generator)
                if appendTasks(tasks, subTasks) then return true end
            end
            if generator:getFuel() < 40 then
                subTasks = BanditPrograms.Generator.Refuel(bandit, generator)
                if appendTasks(tasks, subTasks) then return true end
            end
        end
    end

    if getClimateManager and not getClimateManager():isRaining() then
        local plant = BanditPlayerBase.GetFarm(bandit)
        if plant and plant.waterNeeded and plant.waterNeeded > 0 and plant.waterLvl < 100 then
            subTasks = BanditPrograms.Farm.Water(bandit, plant)
            if appendTasks(tasks, subTasks) then return true end
        end
    end

    subTasks = BanditPrograms.Misc.ReturnFood(bandit)
    if appendTasks(tasks, subTasks) then return true end

    subTasks = BanditPrograms.Housekeeping.RemoveCorpses(bandit)
    if appendTasks(tasks, subTasks) then return true end

    subTasks = BanditPrograms.Housekeeping.RemoveTrash(bandit)
    if appendTasks(tasks, subTasks) then return true end

    subTasks = BanditPrograms.Housekeeping.CleanBlood(bandit)
    if appendTasks(tasks, subTasks) then return true end

    subTasks = BanditPrograms.Housekeeping.FillGraves(bandit)
    if appendTasks(tasks, subTasks) then return true end

    subTasks = BanditPrograms.Self.Wash(bandit)
    if appendTasks(tasks, subTasks) then return true end

    return false
end

local function getFallbackGuardPost(brain, home)
    if not isSurvivorZoneHome(home) then return nil end
    local x1 = math.floor(math.min(tonumber(home.x) or home.cx, tonumber(home.x2) or home.cx))
    local y1 = math.floor(math.min(tonumber(home.y) or home.cy, tonumber(home.y2) or home.cy))
    local x2 = math.floor(math.max(tonumber(home.x) or home.cx, tonumber(home.x2) or home.cx))
    local y2 = math.floor(math.max(tonumber(home.y) or home.cy, tonumber(home.y2) or home.cy))
    local side = math.abs(tonumber(brain and brain.id) or 0) % 4
    if side == 0 then
        return {x=math.floor((x1 + x2) / 2), y=y1 - 2, z=home.cz}
    elseif side == 1 then
        return {x=x2 + 2, y=math.floor((y1 + y2) / 2), z=home.cz}
    elseif side == 2 then
        return {x=math.floor((x1 + x2) / 2), y=y2 + 2, z=home.cz}
    end
    return {x=x1 - 2, y=math.floor((y1 + y2) / 2), z=home.cz}
end

local function findHomeGuardPost(bandit, brain, home)
    if BanditPost and BanditPost.GetClosestFree then
        local post = BanditPost.GetClosestFree(bandit, "guard", math.max(40, home.radius + 20))
        if post and isWithinHome(home, post.x, post.y, post.z, GUARD_BOUNDARY_MARGIN) then
            return post
        end
    end
    return getFallbackGuardPost(brain, home)
end

ZombiePrograms.SurvivorBase.Prepare = function(bandit)
    local tasks = {}
    Bandit.ForceStationary(bandit, false)
    return {status=true, next="Main", tasks=tasks}
end

ZombiePrograms.SurvivorBase.Main = function(bandit)
    local tasks = {}
    local brain = BanditBrain.Get(bandit)
    local home = getHome(brain)

    if not home or not home.cx or not home.cy then
        Bandit.SetProgram(bandit, "Companion", {})
        return {status=true, next="Prepare", tasks=tasks}
    end

    Bandit.SetHostile(bandit, false)
    Bandit.SetHostileP(bandit, false)

    local mode = home.mode or "defend"
    local bx, by, bz = bandit:getX(), bandit:getY(), bandit:getZ()
    local distHome = BanditUtils.DistTo(bx, by, home.cx, home.cy)

    if mode == "civilian" then
        if not isWithinHome(home, bx, by, bz, isSurvivorZoneHome(home) and 0 or 5) then
            Bandit.ForceStationary(bandit, false)
            moveTo(tasks, bandit, home.cx, home.cy, home.cz, distHome > 18 and "Run" or "Walk")
            return {status=true, next="Main", tasks=tasks}
        end

        doCivilianLife(tasks, bandit, home)
        return {status=true, next="Main", tasks=tasks}
    end

    local guardMargin = isSurvivorZoneHome(home) and GUARD_BOUNDARY_MARGIN or 5
    if not isWithinHome(home, bx, by, bz, guardMargin) then
        Bandit.ForceStationary(bandit, false)
        moveTo(tasks, bandit, home.cx, home.cy, home.cz, distHome > 18 and "Run" or "Walk")
        return {status=true, next="Main", tasks=tasks}
    end

    if defendBase(tasks, bandit, home) then
        Bandit.ForceStationary(bandit, false)
        return {status=true, next="Main", tasks=tasks}
    end

    if mode == "guard" or mode == "defend" then
        local post = findHomeGuardPost(bandit, brain, home)
        if post then
            local distPost = BanditUtils.DistTo(bx, by, post.x, post.y)
            if distPost > 1 then
                Bandit.ForceStationary(bandit, false)
                table.insert(tasks, BanditUtils.GetMoveTask(0, post.x, post.y, post.z, "Walk", distPost, false))
                return {status=true, next="Main", tasks=tasks}
            end
        end

        Bandit.ForceStationary(bandit, true)
        appendTasks(tasks, BanditPrograms.Idle(bandit))
        return {status=true, next="Main", tasks=tasks}
    end

    Bandit.ForceStationary(bandit, false)

    if home.allowChores ~= false and doBaseWork(tasks, bandit) then
        return {status=true, next="Main", tasks=tasks}
    end

    if distHome > 8 then
        moveTo(tasks, bandit, home.cx, home.cy, home.cz, "Walk")
        return {status=true, next="Main", tasks=tasks}
    end

    appendTasks(tasks, BanditPrograms.Idle(bandit))
    return {status=true, next="Main", tasks=tasks}
end

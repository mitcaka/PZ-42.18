ZombiePrograms = ZombiePrograms or {}
require "SurvivorCompanions"

ZombiePrograms.Companion = {}

local function syncVehicleState(bandit, brain, inVehicle)
    if not brain or brain.inVehicle == inVehicle then return end

    brain.inVehicle = inVehicle
    Bandit.ForceSyncPart(bandit, {
        id=brain.id or BanditUtils.GetCharacterID(bandit),
        inVehicle=inVehicle,
    })
end

local function exitCompanionVehicle(bandit, brain, vehicle)
    if not vehicle then return false end

    bandit:setVariable("BanditImmediateAnim", true)
    local ok = pcall(function() vehicle:exit(bandit) end)
    if not ok then return false end

    Bandit.ClearTasks(bandit)
    syncVehicleState(bandit, brain, false)
    pcall(function() bandit:playSound("VehicleDoorClose") end)
    return true
end

local function findPassengerSeat(vehicle)
    for seat=1, 10 do
        local installedOk, installed = pcall(function() return vehicle:isSeatInstalled(seat) end)
        local occupiedOk, occupied = pcall(function() return vehicle:isSeatOccupied(seat) end)
        if installedOk and installed and occupiedOk and not occupied then
            return seat
        end
    end
end

local function manageCompanionVehicle(bandit, brain, master, order, dist)
    if not SurvivorCompanions.IsDirectCompanion(brain) then return false end

    local banditsSandbox = SandboxVars and SandboxVars.Bandits or {}
    local enabled = banditsSandbox.General_EnterVehicles ~= false
    local masterVehicle = master:getVehicle()
    local companionVehicle = bandit:getVehicle()
    local shouldRide = enabled and order.mode == "follow" and masterVehicle ~= nil

    if companionVehicle then
        if shouldRide and companionVehicle == masterVehicle then
            syncVehicleState(bandit, brain, true)
            return true
        end

        exitCompanionVehicle(bandit, brain, companionVehicle)
        return true
    end

    syncVehicleState(bandit, brain, false)
    if not shouldRide or dist > 4 then return false end

    local seat = findPassengerSeat(masterVehicle)
    if not seat then return false end

    local direction = bandit:getForwardDirection()
    local forwardVector = Vector3f.new(direction:getX(), direction:getY(), 0)
    local entered = pcall(function() bandit:enterVehicle(masterVehicle, seat, forwardVector) end)
    if entered then
        syncVehicleState(bandit, brain, true)
        pcall(function() bandit:playSound("VehicleDoorOpen") end)
    end
    return entered
end

ZombiePrograms.Companion.Prepare = function(bandit)
    local tasks = {}

    Bandit.ForceStationary(bandit, false)
  
    return {status=true, next="Main", tasks=tasks}
end

ZombiePrograms.Companion.Main = function(bandit)
    local tasks = {}
    local brain = SurvivorCompanions.NormalizeBrain(BanditBrain.Get(bandit))

    Bandit.ForceStationary(bandit, false)
    if brain and brain.companionDowned then
        Bandit.ForceStationary(bandit, true)
        return {status=true, next="Main", tasks=tasks}
    end
 
    -- If at guardpost, switch to the CompanionGuard program.
    local atGuardpost = BanditPost.At(bandit, "guard")
    if atGuardpost then
        return {status=true, next="Guard", tasks=tasks}
    end
    
    -- Companion logic depends on one of the players who is the master od the companion
    -- if there is no master, there is nothing to do.
    local master = BanditPlayer.GetMasterPlayer(bandit)
    if not master then
        local task = {action="Time", anim="Shrug", time=200}
        table.insert(tasks, task)
        return {status=true, next="Main", tasks=tasks}
    end
    
    -- update walktype
    local walkType = "Walk"
    local endurance = 0.00
    local vehicle = master:getVehicle()
    local dist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), master:getX(), master:getY())

    if master:isSprinting() or dist > 10 then
        walkType = "Run"
        endurance = -0.07
    elseif master:isSneaking() and dist < 12 then
        walkType = "SneakWalk"
        endurance = -0.01
    end

    local outOfAmmo = Bandit.IsOutOfAmmo(bandit)
    if master:isAiming() and not outOfAmmo and dist < 8 then
        walkType = "WalkAim"
        endurance = 0
    end

    local health = bandit:getHealth()
    if health < 0.4 then
        walkType = "Limp"
        endurance = 0
    end 

    local order = brain and brain.companionOrder or {mode="follow"}
    if manageCompanionVehicle(bandit, brain, master, order, dist) then
        return {status=true, next="Main", tasks=tasks}
    end

    if order.mode == "stay" or order.mode == "goto" then
        local tx = tonumber(order.retryX) or tonumber(order.x) or bandit:getX()
        local ty = tonumber(order.retryY) or tonumber(order.y) or bandit:getY()
        local tz = tonumber(order.z) or bandit:getZ()
        local orderDist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), tx, ty)

        if orderDist > 1 or math.abs(tz - bandit:getZ()) >= 1 then
            Bandit.ForceStationary(bandit, false)
            table.insert(tasks, BanditUtils.GetMoveTask(endurance, tx, ty, tz, walkType, orderDist, false))
            return {status=true, next="Main", tasks=tasks}
        end

        if order.mode == "goto" then
            brain.companionOrder = {mode="stay", x=tonumber(order.x) or tx, y=tonumber(order.y) or ty, z=tz}
            Bandit.ForceSyncPart(bandit, {id=brain.id, companionOrder=brain.companionOrder})
        end
        Bandit.ForceStationary(bandit, true)
        return {status=true, next="Main", tasks=BanditPrograms.Idle(bandit)}
    end

    -- If there is a guardpost in the vicinity, take it.
    local guardpost = brain.companionCombatMode ~= "passive" and BanditPost.GetClosestFree(bandit, "guard", 40) or nil
    if guardpost then
        table.insert(tasks, BanditUtils.GetMoveTask(endurance, guardpost.x, guardpost.y, guardpost.z, walkType, dist))
        return {status=true, next="Main", tasks=tasks}
    end

    local masterCombatRange = brain.companionCombatMode == "aggressive" and 30 or 20
    local engageRange = brain.companionCombatMode == "aggressive" and 14 or 8
    if brain.companionCombatMode ~= "passive" and dist < masterCombatRange then
        local closestZombie = BanditUtils.GetClosestZombieLocation(bandit)
        local closestBandit = BanditUtils.GetClosestEnemyBanditLocation(bandit)
        local closestEnemy = closestZombie

        if closestBandit.dist < closestZombie.dist then 
            closestEnemy = closestBandit
        end

        if closestEnemy.dist < engageRange then
            walkType = "WalkAim"
            table.insert(tasks, BanditUtils.GetMoveTask(endurance, closestEnemy.x, closestEnemy.y, closestEnemy.z, walkType, closestEnemy.dist))
            return {status=true, next="Main", tasks=tasks}
        end
    end
    
       --[[
    -- If the player is in the vehicle, the companion should join him.
    -- If the player exits the vehicle, so should the companion.
    if SandboxVars.Bandits.General_EnterVehicles then
        if vehicle then
            if dist < 2.2 then
                local bvehicle = bandit:getVehicle()
                if bvehicle then
                    bandit:changeState(ZombieOnGroundState.instance())
                    return {status=true, next="Main", tasks=tasks}
                else
                    print ("ENTER VEH")
                    local vx = bandit:getForwardDirection():getX()
                    local vy = bandit:getForwardDirection():getY()
                    local forwardVector = Vector3f.new(vx, vy, 0)

                    for seat=1, 10 do
                        if vehicle:isSeatInstalled(seat) and not vehicle:isSeatOccupied(seat) then
                            bandit:enterVehicle(vehicle, seat, forwardVector)
                            bandit:playSound("VehicleDoorOpen")
                            break
                        end
                    end
                end
            end
        else
            local bvehicle = bandit:getVehicle()
            if bvehicle then
                print ("EXIT VEH")
                -- After exiting the vehicle, the companion is in the ongroundstate.
                -- Additionally he is under the car. This is fixed in BanditUpdate loop. 
                bandit:setVariable("BanditImmediateAnim", true)
                bvehicle:exit(bandit)
                bandit:playSound("VehicleDoorClose")
            end
        end
    end

    -- Companions intention is to generally stay with the player
    -- however, if the enemy is close, the companion should engage
    -- but only if player is not too far, kind of a proactive defense.


    
    -- look for guns
    if Bandit.IsOutOfAmmo(bandit) then

        -- deadbodies
        for z=0, 2 do
            for y=-12, 12 do
                for x=-12, 12 do
                    local square = cell:getGridSquare(bandit:getX() + x, bandit:getY() + y, z)
                    if square then
                        local body = square:getDeadBody()
                        if body then

                            -- we found one body, but there my be more bodies on that square and we need to check all
                            local objects = square:getStaticMovingObjects()
                            for i=0, objects:size()-1 do
                                local object = objects:get(i)
                                if instanceof (object, "IsoDeadBody") then
                                    local body = object
                                    container = body:getContainer()
                                    if container and not container:isEmpty() then
                                        local subTasks = BanditPrograms.Container.WeaponLoot(bandit, body, container)
                                        if #subTasks > 0 then
                                            for _, subTask in pairs(subTasks) do
                                                table.insert(tasks, subTask)
                                            end
                                            return {status=true, next="Prepare", tasks=tasks}
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- containers in rooms
        local room = bandit:getSquare():getRoom()
        if room then
            local roomDef = room:getRoomDef()
            for x=roomDef:getX(), roomDef:getX2() do
                for y=roomDef:getY(), roomDef:getY2() do
                    local square = cell:getGridSquare(x, y, roomDef:getZ())
                    if square then
                        local objects = square:getObjects()
                        for i=0, objects:size() - 1 do
                            local object = objects:get(i)
                            local container = object:getContainer()
                            if container and not container:isEmpty() then
                                local subTasks = BanditPrograms.Container.WeaponLoot(bandit, object, container)
                                if #subTasks > 0 then
                                    for _, subTask in pairs(subTasks) do
                                        table.insert(tasks, subTask)
                                    end
                                    return {status=true, next="Prepare", tasks=tasks}
                                end

                                local subTasks = BanditPrograms.Container.Loot(bandit, object, container)
                                if #subTasks > 0 then
                                    for _, subTask in pairs(subTasks) do
                                        table.insert(tasks, subTask)
                                    end
                                    return {status=true, next="Prepare", tasks=tasks}
                                end
                            end
                        end
                    end
                end
            end
        end 
    end

    -- If there is a guardpost in the vicinity, take it.
    local guardpost = BanditPost.GetClosestFree(bandit, "guard", 40)
    if guardpost then
        table.insert(tasks, BanditUtils.GetMoveTask(endurance, guardpost.x, guardpost.y, guardpost.z, walkType, dist, false))
        return {status=true, next="Main", tasks=tasks}
    end

    -- companion fishing
    local gameTime = getGameTime()
    local hour = gameTime:getHour()
    if (hour >= 4 and hour < 6) or (hour >= 18 and hour < 21) then
        local vectors = {}
        table.insert(vectors, {x=0, y=-1}) --12
        table.insert(vectors, {x=1, y=-1}) -- 1.30
        table.insert(vectors, {x=1, y=0}) -- 3
        table.insert(vectors, {x=1, y=1}) -- 4.30
        table.insert(vectors, {x=0, y=1}) -- 6
        table.insert(vectors, {x=-1, y=1}) -- 7.30
        table.insert(vectors, {x=-1, y=0}) -- 9
        table.insert(vectors, {x=-1, y=-1}) -- 10.30
        
        local bx = bandit:getX()
        local by = bandit:getY()
        local wx
        local wy
        local wd = 31
        local wsquare
        for _, vector in pairs(vectors) do
            for i=1, 30 do
                local x = bx + vector.x * i
                local y = by + vector.y * i
                local square = cell:getGridSquare(x, y, 0)
                if square and BanditUtils.IsWater(square) then
                    if i < wd then
                        wx, wy, wd = x, y, i
                        wsquare = square
                        break
                    end
                end
            end
        end

        if wx and wy then
            local asquare = AdjacentFreeTileFinder.Find(wsquare, bandit)
            if asquare then
                local tx = asquare:getX() + 0.5
                local ty = asquare:getY() + 0.5

                local dist = BanditUtils.DistTo(bx, by, tx, ty)
                if dist < 1.0 then
                    print ("should fish")
                    local task = {action="Fishing", time=1000, x=wx, y=wy}
                    table.insert(tasks, task)
                    return {status=true, next="Main", tasks=tasks}
                else
                    table.insert(tasks, BanditUtils.GetMoveTask(endurance, tx, ty, 0, "Run", dist, false))
                    return {status=true, next="Main", tasks=tasks}
                end
            end
        end
    end

    -- companion foraging
    local dls = cm:getDayLightStrength()
    local rain = cm:getRainIntensity()
    local fog = cm:getFogIntensity()
    local zoneData = forageSystem.getForageZoneAt(bandit:getX(), bandit:getY())

    local inZone = false
    local zone = getWorld():getMetaGrid():getZoneAt(bandit:getX(), bandit:getY(), 0)
    if zone then
        local zoneType = zone:getType()
        if zoneType == "Forest" or zoneType == "DeepForest" or zoneType == "Vegitation" or zoneType == "FarmLand" then
            inZone = true
        end
    end

    if false and zoneData and inZone and dls > 0.8 and rain < 0.3 and fog < 0.2 then
        local month = getGameTime():getMonth() + 1
        local timeOfDay = forageSystem.getTimeOfDay() or "isDay"
        local weatherType = forageSystem.getWeatherType() or "isNormal"
        local lootTable = forageSystem.lootTables[zoneData.name][month][timeOfDay][weatherType]
        
        local itemType, catName = forageSystem.pickRandomItemType(lootTable)
        if itemType and catName then
            local item = BanditCompatibility.InstanceItem(itemType)
            if instanceof (item, "Food") then
                local test1 = item:getProteins()
                local test2 = item:getCalories()
                local test3 = item:getCarbohydrates()
                local test4 = item:isSpice()

                print ("found: " .. itemType)
                local task = {action="Drop", anim="Forage", itemType=itemType, time=400}
                table.insert(tasks, task)

                -- local task2 = {action="Single", anim="Eat", time=400}
                -- table.insert(tasks, task2)
                -- local task3 = {action="Single", anim="Eat", time=400}
                -- table.insert(tasks, task3)
                return {status=true, next="Main", tasks=tasks}
            end
        end
    end

    -- companion homebase tasks

    -- companion generator maintenance
    -- FIXME: change to NOT
    if getWorld():isHydroPowerOn() then 
        local generator = BanditPlayerBase.GetGenerator(bandit)
        if generator then
            local condition = generator:getCondition()
            if condition < 60 or (condition <=95 and not generator:isActivated()) then
                local subTasks = BanditPrograms.Generator.Repair(bandit, generator)
                if #subTasks > 0 then
                    for _, subTask in pairs(subTasks) do
                        table.insert(tasks, subTask)
                    end
                    return {status=true, next="Main", tasks=tasks}
                end
            end

            local fuel = generator:getFuel()
            if fuel < 40 then
                local subTasks = BanditPrograms.Generator.Refuel(bandit, generator)
                if #subTasks > 0 then
                    for _, subTask in pairs(subTasks) do
                        table.insert(tasks, subTask)
                    end
                    return {status=true, next="Main", tasks=tasks}
                end
            end
        end
    end

    -- gardening
    -- TODO: remove weed

    -- farming
    if not cm:isRaining() then
        local plant = BanditPlayerBase.GetFarm(bandit)
        if plant and plant.waterNeeded > 0 and plant.waterLvl < 100 then
            local subTasks = BanditPrograms.Farm.Water(bandit, plant)
            if #subTasks > 0 then
                for _, subTask in pairs(subTasks) do
                    table.insert(tasks, subTask)
                end
                return {status=true, next="Main", tasks=tasks}
            end
        end
    end

    -- unload collected food to fridge
    local subTasks
    subTasks = BanditPrograms.Misc.ReturnFood(bandit)
    if #subTasks > 0 then
        for _, subTask in pairs(subTasks) do
            table.insert(tasks, subTask)
        end
        return {status=true, next="Main", tasks=tasks}
    end

    -- self
    subTasks = BanditPrograms.Self.Wash(bandit)
    if #subTasks > 0 then
        for _, subTask in pairs(subTasks) do
            table.insert(tasks, subTask)
        end
        return {status=true, next="Main", tasks=tasks}
    end
    

    -- housekeeping
    subTasks = BanditPrograms.Housekeeping.FillGraves(bandit)
    if #subTasks > 0 then
        for _, subTask in pairs(subTasks) do
            table.insert(tasks, subTask)
        end
        return {status=true, next="Main", tasks=tasks}
    end

    subTasks = BanditPrograms.Housekeeping.RemoveCorpses(bandit)
    if #subTasks > 0 then
        for _, subTask in pairs(subTasks) do
            table.insert(tasks, subTask)
        end
        return {status=true, next="Main", tasks=tasks}
    end

    subTasks = BanditPrograms.Housekeeping.RemoveTrash(bandit)
    if #subTasks > 0 then
        for _, subTask in pairs(subTasks) do
            table.insert(tasks, subTask)
        end
        return {status=true, next="Main", tasks=tasks}
    end

    subTasks = BanditPrograms.Housekeeping.CleanBlood(bandit)
    if #subTasks > 0 then
        for _, subTask in pairs(subTasks) do
            table.insert(tasks, subTask)
        end
        return {status=true, next="Main", tasks=tasks}
    end
--]]

    local dx = master:getX()
    local dy = master:getY()
    local dz = master:getZ()
    local did = BanditUtils.GetCharacterID(master)

    local distTarget = BanditUtils.DistTo(bandit:getX(), bandit:getY(), dx, dy)

    if distTarget > 1 or math.abs(dz - bandit:getZ()) >= 1 then
        --table.insert(tasks, BanditUtils.GetMoveTask(endurance, dx, dy, dz, walkType, distTarget, false))
        table.insert(tasks, BanditUtils.GetMoveTaskTarget(endurance, dx, dy, dz, did, true, walkType, distTarget))
        return {status=true, next="Main", tasks=tasks}
    else

        local subTasks = BanditPrograms.Idle(bandit)
        if #subTasks > 0 then
            for _, subTask in pairs(subTasks) do
                table.insert(tasks, subTask)
            end
            return {status=true, next="Main", tasks=tasks}
        end
    end
    
    return {status=true, next="Main", tasks=tasks}
end

ZombiePrograms.Companion.Guard = function(bandit)
    local tasks = {}

    Bandit.ForceStationary(bandit, true)
    
    -- If at guardpost, switch to the CompanionGuard program.
    local atGuardpost = BanditPost.At(bandit, "guard")
    if not atGuardpost then
        return {status=true, next="Main", tasks=tasks}
    end

    local closestZombie = BanditUtils.GetClosestZombieLocation(bandit)
    local closestBandit = BanditUtils.GetClosestEnemyBanditLocation(bandit)
    local closestEnemy = closestZombie

    if closestBandit.dist < closestZombie.dist then 
        closestEnemy = closestBandit
    end

    if closestEnemy.dist < 24 then
        local task = {action="FaceLocation", anim=anim, x=closestEnemy.x, y=closestEnemy.y, time=100}
        table.insert(tasks, task)
    else
        local subTasks = BanditPrograms.Idle(bandit)
        if #subTasks > 0 then
            for _, subTask in pairs(subTasks) do
                table.insert(tasks, subTask)
            end
        end
    end
    return {status=true, next="Guard", tasks=tasks}
end

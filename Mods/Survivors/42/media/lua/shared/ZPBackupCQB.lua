-- ==============================================================================
-- Название: ZPBackupCQB.lua
-- Описание: AAA-программа CQB (Close Quarters Battle) для зачистки зданий.
-- Функционал: Мелкие шаги, приоритет огнестрела, анти-стак, кинематографичное
--             открытие дверей со стрельбой на упреждение (слепой огонь).
-- ==============================================================================

ZombiePrograms = ZombiePrograms or {}

ZombiePrograms.BackupCQB = {}
ZombiePrograms.BackupCQB.Stages = {}

ZombiePrograms.BackupCQB.Init = function(bandit)
    print("[Bandit BackupCQB] [INIT] CQB Program activated for indoor sweep.")
end

ZombiePrograms.BackupCQB.Prepare = function(bandit)
    local tasks = {}
    local brain = BanditBrain.Get(bandit)
    
    local status, err = pcall(function()
        -- 1. Выход из программы, если мы оказались на улице
        if bandit:getBuilding() == nil then
            print("[Bandit BackupCQB] [EXIT] Bandit went outdoors. Reverting to BackupSearch.")
            Bandit.SetProgram(bandit, "BackupSearch")
            Bandit.SetProgramStage(bandit, "SweepNextNode")
            return
        end
        
        -- 2. Приоритет огнестрельного оружия
        local inv = bandit:getInventory()
        local primary = bandit:getPrimaryHandItem()
        local hasGunInHand = primary and primary:IsWeapon() and primary:isAimedFirearm()
        
        if not hasGunInHand and inv then
            local bestGun = nil
            local items = inv:getItems()
            for i = 0, items:size() - 1 do
                local item = items:get(i)
                if item and item:IsWeapon() and item:isAimedFirearm() and item:getCondition() > 0 then
                    -- Ищем заряженное оружие или хотя бы с патронами
                    bestGun = item
                    if item:getCurrentAmmoCount() > 0 then break end
                end
            end
            
            if bestGun then
                bandit:setPrimaryHandItem(bestGun)
                bandit:setSecondaryHandItem(bestGun)
                print("[Bandit BackupCQB] [WEAPON] Equipped firearm for CQB.")
                if Bandit.SetAim then Bandit.SetAim(bandit, true) end
            end
        end
        
        -- Выдаем небольшую задержку перед началом зачистки
        table.insert(tasks, {action="Time", time=ZombRand(20, 50), lock=true})
    end)
    
    return {status=true, next="SweepNextNode", tasks=tasks}
end

ZombiePrograms.BackupCQB.SweepNextNode = function(bandit)
    local tasks = {}
    local nextStage = "MoveToNode"
    local brain = BanditBrain.Get(bandit)
    
    pcall(function()
        if bandit:getBuilding() == nil then
            Bandit.SetProgram(bandit, "BackupSearch")
            Bandit.SetProgramStage(bandit, "SweepNextNode")
            nextStage = "SweepNextNode"
            return
        end
        
        local cx, cy, cz = bandit:getX(), bandit:getY(), bandit:getZ()
        
        -- 1. СКАНИРОВАНИЕ НА ЗАКРЫТЫЕ ДВЕРИ
        local sq = bandit:getSquare()
        local cell = getCell()
        local foundDoor = nil
        local doorSq = nil
        
        if sq and cell then
            -- Ищем двери в радиусе 1 тайла (по всем 8 направлениям)
            local dx = {0, 1, 0, -1, 1, -1, 1, -1}
            local dy = {-1, 0, 1, 0, -1, -1, 1, 1}
            
            for i=1, 8 do
                local tsq = cell:getGridSquare(math.floor(cx + dx[i]), math.floor(cy + dy[i]), cz)
                if tsq then
                    local objs = tsq:getObjects()
                    for j=0, objs:size()-1 do
                        local obj = objs:get(j)
                        if instanceof(obj, "IsoDoor") and not obj:IsOpen() then
                            foundDoor = obj
                            doorSq = tsq
                            break
                        elseif instanceof(obj, "IsoThumpable") and obj:isDoor() and not obj:IsOpen() then
                            foundDoor = obj
                            doorSq = tsq
                            break
                        end
                    end
                    if foundDoor then break end
                end
            end
        end
        
        if foundDoor and doorSq then
            local dKey = tostring(doorSq:getX()) .. "," .. tostring(doorSq:getY())
            if not brain.cqbIgnoredDoors then brain.cqbIgnoredDoors = {} end
            
            if not brain.cqbIgnoredDoors[dKey] then
                print("[Bandit BackupCQB] [BREACH DETECTED] Closed door found nearby.")
                brain.cqbDoorX = doorSq:getX()
                brain.cqbDoorY = doorSq:getY()
                nextStage = "BreachDoor"
                return
            end
        end
        
        -- 2. CQB ПЕРЕДВИЖЕНИЕ (Мелкие шаги)
        brain.patrolNodes = (brain.patrolNodes or 0) + 1
        
        -- Базовое смещение от ноды к ноде (имитация зачистки углов)
        local baseAngle = ZombRandFloat(0, math.pi * 2)
        local dist = ZombRandFloat(3.0, 7.0) -- [ФИКС] Увеличили дистанцию шага, чтобы не дергались каждую секунду
        
        local targetX = cx + math.cos(baseAngle) * dist
        local targetY = cy + math.sin(baseAngle) * dist
        
        -- АНТИ-СТАК И АНТИ-СТЕНА
        if cell then
            local lineCheck = tostring(LosUtil.lineClear(cell, math.floor(cx), math.floor(cy), cz, math.floor(targetX), math.floor(targetY), cz, false))
            if lineCheck == "Blocked" then
                dist = 0.8
                baseAngle = baseAngle + math.pi/2 -- поворот вдоль стены
                targetX = cx + math.cos(baseAngle) * dist
                targetY = cy + math.sin(baseAngle) * dist
            end
            
            -- Проверка, свободен ли конечный тайл
            local targetSq = cell:getGridSquare(math.floor(targetX), math.floor(targetY), cz)
            if not targetSq or not targetSq:isFree(false) then
                -- Если заблокировано, ищем любой свободный тайл в радиусе 1.5
                for ang = 0, math.pi*2, math.pi/4 do
                    local tx = cx + math.cos(ang) * 1.5
                    local ty = cy + math.sin(ang) * 1.5
                    local ts = cell:getGridSquare(math.floor(tx), math.floor(ty), cz)
                    if ts and ts:isFree(false) then
                        targetX, targetY = tx, ty
                        break
                    end
                end
            end
        end
        
        -- Динамическое смещение, чтобы бандиты не слипались
        local offset = (math.abs(brain.id or 1) % 3) * 0.35
        targetX = targetX + offset
        targetY = targetY + offset
        
        brain.sweepX = targetX
        brain.sweepY = targetY
        brain.sweepZ = cz
        
    end)
    
    return {status=true, next=nextStage, tasks=tasks}
end

ZombiePrograms.BackupCQB.MoveToNode = function(bandit)
    local tasks = {}
    local brain = BanditBrain.Get(bandit)
    
    pcall(function()
        local tx, ty, tz = brain.sweepX, brain.sweepY, brain.sweepZ
        local dist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), tx, ty)
        
        if dist > 0.1 then
            -- CQB Walk: только прицельный или тактический шаг
            local walkType = "WalkAim"
            if ZombRand(100) < 30 then walkType = "Walk" end
            
            if Bandit.SetAim then Bandit.SetAim(bandit, true) end
            
            table.insert(tasks, BanditUtils.GetMoveTask(0.1, tx, ty, tz, walkType, dist, false))
            
            -- [ФИКС] Пауза для осмотра только в 40% случаев, чтобы движение было более плавным и непрерывным
            if ZombRand(100) < 40 then
                table.insert(tasks, {action="Time", anim="RifleAim", time=ZombRand(20, 50), lock=true})
            end
        end
    end)
    
    return {status=true, next="SweepNextNode", tasks=tasks}
end

ZombiePrograms.BackupCQB.BreachDoor = function(bandit)
    local tasks = {}
    
    pcall(function()
        local brain = BanditBrain.Get(bandit)
        local dx, dy = brain.cqbDoorX, brain.cqbDoorY
        local cell = getCell()
        
        if cell and dx and dy then
            local sq = cell:getGridSquare(dx, dy, bandit:getZ())
            local door = nil
            
            if sq then
                local objs = sq:getObjects()
                for i=0, objs:size()-1 do
                    local obj = objs:get(i)
                    if (instanceof(obj, "IsoDoor") or (instanceof(obj, "IsoThumpable") and obj:isDoor())) and not obj:IsOpen() then
                        door = obj
                        break
                    end
                end
            end
            
            if door then
                print("[Bandit BackupCQB] [BREACH] Door found at " .. tostring(dx) .. "," .. tostring(dy) .. ". Executing blind fire sequence!")
                
                -- Подходим к двери в прицеливании
                local distToDoor = BanditUtils.DistTo(bandit:getX(), bandit:getY(), dx, dy)
                if distToDoor > 0.8 then
                    table.insert(tasks, BanditUtils.GetMoveTask(0.1, dx, dy, bandit:getZ(), "WalkAim", distToDoor, false))
                end
                
                -- Поворачиваемся к двери
                bandit:faceLocationF(dx + 0.5, dy + 0.5)
                
                if Bandit.SetAim then Bandit.SetAim(bandit, true) end
                
                -- Пауза-саспенс перед открытием
                table.insert(tasks, {action="Time", anim="RifleAim", time=ZombRand(15, 45), lock=true})
                
                -- Команда открытия двери + огонь на упреждение
                table.insert(tasks, {action="Function", func=function()
                    if door and not door:IsOpen() then
                        door:ToggleDoor(bandit)
                        print("[Bandit BackupCQB] [BREACH] Door kicked open!")
                        
                        -- Добавляем дверь в игнор-лист, чтобы не зацикливаться на ней, если она заперта
                        if not brain.cqbIgnoredDoors then brain.cqbIgnoredDoors = {} end
                        local dKey = tostring(dx) .. "," .. tostring(dy)
                        brain.cqbIgnoredDoors[dKey] = true
                        
                        local weapon = bandit:getPrimaryHandItem()
                        if weapon and weapon:IsWeapon() and weapon:isAimedFirearm() then
                            local ammo = weapon:getCurrentAmmoCount()
                            if ammo > 0 then
                                weapon:setCurrentAmmoCount(ammo - 1)
                                local sound = weapon:getSwingSound() or "PistolShoot"
                                bandit:playSound(sound)
                                if BanditCompatibility and BanditCompatibility.StartMuzzleFlash then 
                                    BanditCompatibility.StartMuzzleFlash(bandit) 
                                end
                                
                                -- Шум выстрела для привлечения зомби
                                addSound(bandit, bandit:getX(), bandit:getY(), bandit:getZ(), 60, 60)
                                print("[Bandit BackupCQB] [BREACH] BLIND FIRE SUPPRESSION!")
                            end
                        end
                    end
                end})
                
                -- Анимация стрельбы / прицеливания после открытия
                table.insert(tasks, {action="Time", anim="AttackRifle", time=15, lock=true})
                table.insert(tasks, {action="Time", anim="RifleAim", time=60, lock=true})
                
                -- Голосовая фраза
                if SandboxVars.Bandits.General_Captions then
                    table.insert(tasks, {action="Function", func=function()
                        local shouts = {"Clear!", "Moving in!", "Check corners!", "Breach!"}
                        bandit:addLineChatElement(shouts[ZombRand(#shouts) + 1], 0.8, 0.8, 0.8)
                    end})
                end
            else
                print("[Bandit BackupCQB] [BREACH CANCELED] Door already open or missing.")
            end
        end
    end)
    
    return {status=true, next="SweepNextNode", tasks=tasks}
end

-- Fallback escape mechanism removed as it falls back to Bandit program inherently.

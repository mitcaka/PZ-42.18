-- ==============================================================================
-- Название: ZPBackupSearch.lua
-- Описание: Кастомная AAA-программа поведения (ИИ) для подкрепления Bandits.
-- Функционал: Заставляет прибывших бандитов экипировать оружие, обыскивать 
--             место смерти товарища, ругаться и использовать продвинутый 
--             слуховой/визуальный радар для прочесывания территории.
--             ВЕРСИЯ 8.5 (ANIMATOR FIX): Заменена невалидная анимация "LookAround",
--             которая ломала движок и "замораживала" модельки бандитов в позе бега.
--             Улучшена синхронизация чата, теперь говорит строго 1 бандит из группы.
-- ==============================================================================

ZombiePrograms = ZombiePrograms or {}

ZombiePrograms.BackupSearch = {}
ZombiePrograms.BackupSearch.Stages = {}

ZombiePrograms.BackupSearch.HiveMind = {}

ZombiePrograms.BackupSearch.Init = function(bandit)
    print("[Bandit BackupSearch] [INIT] Initializing BackupSearch program for a bandit.")
end

-- ==============================================================================
-- ЛОКАЛЬНАЯ ФУНКЦИЯ: Проверка на тактическое отступление
-- ==============================================================================
local function CheckTacticalRetreat(bandit, brain)
    if bandit:getHealth() < 0.4 then
        print("[Bandit BackupSearch] [TACTICAL RETREAT] Bandit ID: " .. tostring(brain.id) .. " has low health (<40%). Initiating tactical retreat!")
        Bandit.Say(bandit, "HIT", true)
        brain.torch = false 
        Bandit.SetProgram(bandit, "Bandit")
        Bandit.SetProgramStage(bandit, "Escape")
        return true
    end
    return false
end

-- ==============================================================================
-- СТАДИЯ 1: Подготовка к бою (Экипировка и Свет)
-- ==============================================================================
ZombiePrograms.BackupSearch.Prepare = function(bandit)
    local tasks = {}
    local nextStage = "Investigate" 
    
    local status, err = pcall(function()
        Bandit.ForceStationary(bandit, false)
        local brain = BanditBrain.Get(bandit)
        
        print("[Bandit BackupSearch] [PREPARE] Bandit ID: " .. tostring(brain.id) .. " equipping weapons and preparing.")
        
        brain.corpseDefended = false
        brain.investigationDone = false
        brain.reachedRadio = false -- Флаг для стадии Investigate
        
        local bestWpn = Bandit.GetBestWeapon(bandit)
        if bestWpn and not bandit:isPrimaryEquipped(bestWpn) then
            print("[Bandit BackupSearch] [PREPARE] Equipping best weapon for ID: " .. tostring(brain.id))
            local stasks = BanditPrograms.Weapon.Switch(bandit, bestWpn)
            for _, t in pairs(stasks) do table.insert(tasks, t) end
        end

        local gameHour = getGameTime():getHour()
        local isNight = (gameHour >= 21 or gameHour <= 6)
        if isNight then
            local inv = bandit:getInventory()
            if inv and inv:getItemCountFromTypeRecurse("Base.HandTorch") > 0 then
                print("[Bandit BackupSearch] [PREPARE] Nighttime detected. Enabling torch for ID: " .. tostring(brain.id))
                brain.torch = true
            end
        end
    end)
    
    if not status then
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPBackupSearch | Stage: Prepare")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(err))
        print("================================================================================")
    end

    return {status=true, next=nextStage, tasks=tasks}
end

-- ==============================================================================
-- СТАДИЯ 2: Расследование сцены убийства (Бег к рации + ЗАЩИТА ТРУПОВ)
-- ==============================================================================
ZombiePrograms.BackupSearch.Investigate = function(bandit)
    local tasks = {}
    local nextStage = "SweepNextNode"
    
    local status, err = pcall(function()
        local brain = BanditBrain.Get(bandit)
        
        if CheckTacticalRetreat(bandit, brain) then
            nextStage = "Escape"
            return
        end

        local bx, by, bz = bandit:getX(), bandit:getY(), bandit:getZ()
        
        -- [ААА-МЕХАНИКА: КИНЕМАТОГРАФИЧНОЕ ПРИБЫТИЕ ОТРЯДА]
        if not brain.reachedRadio and brain.bornCoords then
            -- Динамическое смещение на основе ID, чтобы бандиты не бежали в одну точку и не толкались
            local offsetX = (math.abs(brain.id or 1) % 5) - 2 + (brain.stuckOffsetX or 0)
            local offsetY = (math.abs(brain.id or 2) % 5) - 2 + (brain.stuckOffsetY or 0)
            local rx = brain.bornCoords.x + offsetX
            local ry = brain.bornCoords.y + offsetY
            local rz = brain.bornCoords.z
            local distToRadio = BanditUtils.DistTo(bx, by, rx, ry)

            if distToRadio > 2.5 then
                brain.radioTicks = (brain.radioTicks or 0) + 1
                -- Даем ИИ больше тиков, т.к. кинематографичный подход включает шаги и паузы
                if brain.radioTicks < 400 then
                    local weapon = brain.weapons and brain.weapons.primary
                    local hasFirearm = false
                    if weapon and weapon.name and weapon.bulletsLeft and weapon.bulletsLeft > 0 then
                        local wpnItem = BanditCompatibility.InstanceItem(weapon.name)
                        if wpnItem and wpnItem:isAimedFirearm() then hasFirearm = true end
                    end
                    
                    local walkType = "Run"
                    if hasFirearm then
                        -- Динамическое сближение: от бега к тактическому шагу
                        if distToRadio <= 15 and distToRadio > 6 then
                            walkType = "WalkAim"
                        elseif distToRadio <= 6 then
                            walkType = (ZombRand(100) < 50) and "WalkAim" or "Walk"
                        end
                        
                        -- Кинематографичная тактическая пауза (5% шанс во время перерасчета пути)
                        if distToRadio <= 20 and ZombRand(100) < 5 then
                            if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
                            table.insert(tasks, {action="Time", time=ZombRand(40, 90), lock=true})
                            
                            local hm = ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)]
                            if not hm then hm = {}; ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)] = hm end
                            local currentTime = (getTimestamp() + 0)
                            if not hm.lastSpokeScan or (currentTime - hm.lastSpokeScan > 20) then
                                hm.lastSpokeScan = currentTime
                                if SandboxVars.Bandits.General_Captions and ZombRand(100) < 30 then
                                    bandit:addLineChatElement("Eyes peeled. Move up.", 0.8, 0.8, 0.8)
                                end
                            end
                            nextStage = "Investigate"
                            return
                        end
                    else
                        -- Милишники бегут сломя голову, замедляясь лишь в самом конце
                        walkType = (distToRadio <= 5) and "Walk" or "Run"
                    end

                    local currentTasks = bandit:getModData().tasks
                    if not currentTasks or #currentTasks == 0 or (brain.radioTicks % 50 == 0) then
                        if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
                        
                        -- [ААА-Антизастревание]: Если задач нет, но мы далеко - мы врезались в объект. 
                        -- Даем паузу для прерывания лупа анимации (15 fps баг) и смещаем вектор
                        if (not currentTasks or #currentTasks == 0) and brain.radioTicks > 5 then
                            -- [ФИКС АНТИСТАКА] Если застряли по пути к радио - считаем что дошли
                            brain.reachedRadio = true
                            brain.radioTicks = 0
                            brain.stuckOffsetX = 0
                            brain.stuckOffsetY = 0
                            if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
                            table.insert(tasks, {action="Time", time=ZombRand(20, 60), lock=true})
                            nextStage = "Investigate"
                            return
                        end
                        
                        table.insert(tasks, BanditUtils.GetMoveTask(0, rx, ry, rz, walkType, distToRadio, false))
                    end
                    
                    nextStage = "Investigate"
                    return
                end
            end
            
            -- Добежали или вышло время - переходим к расследованию
            brain.reachedRadio = true
            brain.radioTicks = 0
            brain.stuckOffsetX = 0
            brain.stuckOffsetY = 0
            
            if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
            bandit:setVariable("BanditWalkType", "Walk")
            print("[Bandit BackupSearch] [INVESTIGATE] Bandit ID: " .. tostring(brain.id) .. " reached the radio zone.")
        end

        local cell = getCell()
        local foundDead = false
        local corpseX, corpseY, corpseZ
        
        for y = -6, 6 do
            for x = -6, 6 do
                local sq = cell:getGridSquare(bx + x, by + y, bz)
                if sq and sq:getDeadBody() then
                    local staticObjs = sq:getStaticMovingObjects()
                    if staticObjs then
                        for i=0, staticObjs:size()-1 do
                            local obj = staticObjs:get(i)
                            if instanceof(obj, "IsoDeadBody") then
                                local objMD = obj:getModData()
                                if objMD.isDeadBandit or objMD.is_omni_bandit or objMD.bandit then
                                    foundDead = true
                                    corpseX = sq:getX()
                                    corpseY = sq:getY()
                                    corpseZ = sq:getZ()
                                    print("[Bandit BackupSearch] [INVESTIGATE] Found dead clan member at X:"..corpseX.." Y:"..corpseY)
                                    break
                                end
                            end
                        end
                    end
                end
                if foundDead then break end
            end
            if foundDead then break end
        end

        if foundDead then
            local defiler = nil
            local defilerDist = math.huge
            local defilerIsPlayer = false
            local defilerId = nil

            for id, zLight in pairs(BanditZombie.CacheLightZ) do
                local zInst = BanditZombie.Cache[id]
                if zInst and zInst:isAlive() and math.abs(zLight.z - corpseZ) < 0.5 then
                    if math.abs(zLight.x - corpseX) <= 4.5 and math.abs(zLight.y - corpseY) <= 4.5 then
                        local d = BanditUtils.DistTo(corpseX, corpseY, zLight.x, zLight.y)
                        if d <= 4.5 and d < defilerDist then
                            defilerDist = d
                            defiler = zInst
                            defilerId = id
                            defilerIsPlayer = false
                        end
                    end
                end
            end

            for id, bLight in pairs(BanditZombie.CacheLightB) do
                local bInst = BanditZombie.Cache[id]
                if bInst and bInst:isAlive() and id ~= brain.id and BanditUtils.AreEnemies(brain, bLight.brain) and math.abs(bLight.z - corpseZ) < 0.5 then
                    if math.abs(bLight.x - corpseX) <= 4.5 and math.abs(bLight.y - corpseY) <= 4.5 then
                        local d = BanditUtils.DistTo(corpseX, corpseY, bLight.x, bLight.y)
                        if d <= 4.5 and d < defilerDist then
                            defilerDist = d
                            defiler = bInst
                            defilerId = id
                            defilerIsPlayer = false
                        end
                    end
                end
            end

            if brain.hostile or brain.hostileP then
                local players = BanditPlayer.GetPlayers()
                for i=0, players:size()-1 do
                    local p = players:get(i)
                    if p and p:isAlive() and not BanditPlayer.IsGhost(p) and math.abs(p:getZ() - corpseZ) < 0.5 then
                        if math.abs(p:getX() - corpseX) <= 4.5 and math.abs(p:getY() - corpseY) <= 4.5 then
                            local d = BanditUtils.DistTo(corpseX, corpseY, p:getX(), p:getY())
                            if d <= 4.5 and d < defilerDist then
                                defilerDist = d
                                defiler = p
                                defilerId = BanditUtils.GetCharacterID(p)
                                defilerIsPlayer = true
                            end
                        end
                    end
                end
            end

            if defiler then
                print("[Bandit BackupSearch] [DEFENSE] Defiler spotted near corpse! Defiler ID: " .. tostring(defilerId) .. " (Player: "..tostring(defilerIsPlayer)..")")
                if not brain.corpseDefended then
                    -- [ФИКС ЧАТА] Ограничиваем фразу 1 разом на клан (кулдаун 60 сек)
                    local hm = ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)]
                    if not hm then hm = {}; ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)] = hm end
                    local currentTime = (getTimestamp() + 0)
                    
                    if not hm.lastSpokeDefend or (currentTime - hm.lastSpokeDefend > 60) then
                        hm.lastSpokeDefend = currentTime
                        if SandboxVars.Bandits.General_Captions then
                            bandit:addLineChatElement("Get away from the body, you freaks!", 0.8, 0.1, 0.1)
                        end
                        Bandit.Say(bandit, "BREACH", true) 
                    end
                    brain.corpseDefended = true
                end

                local tx, ty, tz = defiler:getX(), defiler:getY(), defiler:getZ()
                if defiler:isRunning() or defiler:isSprinting() then
                    local fd = defiler:getForwardDirection()
                    fd:setLength(defilerDist)
                    tx = tx + fd:getX()
                    ty = ty + fd:getY()
                end

                local trueDist = BanditUtils.DistTo(bx, by, tx, ty)
                local walkType = Bandit.GetCombatWalktype(bandit, defiler, trueDist)
                
                print("[Bandit BackupSearch] [HIVEMIND] Updating HiveMind with defiler coordinates for Clan " .. tostring((brain.clan or -1)))
                ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)] = {
                    x = tx, y = ty, z = tz,
                    id = defilerId,
                    player = defilerIsPlayer,
                    expire = (getTimestamp() + 0) + 4
                }

                -- Очищаем задачи перед боем для быстрой реакции
                if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
                table.insert(tasks, BanditUtils.GetMoveTaskTarget(0, tx, ty, tz, defilerId, defilerIsPlayer, walkType, trueDist))
                nextStage = "Investigate"
                return
            end

            if not brain.investigationDone then
                print("[Bandit BackupSearch] [INVESTIGATE] Area clear. Mourning the dead and preparing to sweep.")
                
                -- [ФИКС ЧАТА] Гарантируем, что говорит ТОЛЬКО ОДИН бандит из группы (таймаут 60 секунд)
                local hm = ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)]
                if not hm then hm = {}; ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)] = hm end
                local currentTime = (getTimestamp() + 0)
                
                if not hm.lastSpokeDead or (currentTime - hm.lastSpokeDead > 60) then
                    hm.lastSpokeDead = currentTime -- Сразу блокируем возможность говорить для остальных
                    if SandboxVars.Bandits.General_Captions then
                        bandit:addLineChatElement("Damn it, they're dead! Spread out and find the bastards!", 0.8, 0.1, 0.1)
                    end
                    Bandit.Say(bandit, "DEFENDER_SPOTTED", true) 
                end
                
                -- [ФИКС АНИМАЦИИ] Удалили anim="Idle", так как движок распознает это как bumpType и фризит стейт-машину!
                if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
                local mournTime = ZombRand(90, 180) -- Кинематографичная случайная пауза (1.5 - 3 сек)
                table.insert(tasks, {action="Time", time=mournTime, lock=true})
                
                brain.investigationDone = true
                brain.patrolNodes = 0
                brain.bloodTracked = false
                nextStage = "SweepNextNode"
                return
            end
        else
            if not brain.investigationDone then
                print("[Bandit BackupSearch] [INVESTIGATE] No corpses found in area. Initiating sweep.")
                if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
                local waitTime = ZombRand(60, 120)
                table.insert(tasks, {action="Time", time=waitTime, lock=true})
                brain.investigationDone = true
            end
        end

        brain.patrolNodes = 0
        brain.bloodTracked = false
    end)
    
    if not status then
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPBackupSearch | Stage: Investigate")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(err))
        print("================================================================================")
    end

    return {status=true, next=nextStage, tasks=tasks}
end

-- ==============================================================================
-- СТАДИЯ 3: Генерация новой точки прочесывания (Тактическое разделение / Фланги)
-- ==============================================================================
ZombiePrograms.BackupSearch.SweepNextNode = function(bandit)
    local tasks = {}
    local nextStage = "SweepMain"

    local status, err = pcall(function()
        local brain = BanditBrain.Get(bandit)
        
        if CheckTacticalRetreat(bandit, brain) then
            nextStage = "Escape"
            return
        end

        brain.patrolNodes = (brain.patrolNodes or 0) + 1
        brain.sweepTicks = 0 -- СБРОС ТАЙМАУТА ЗАСТРЕВАНИЯ
        print("[Bandit BackupSearch] [SWEEP] Bandit ID: " .. tostring(brain.id) .. " initiating sweep node " .. tostring(brain.patrolNodes))
        
        if brain.patrolNodes > 6 then
            print("[Bandit BackupSearch] [SWEEP] Sweep max nodes reached. Returning to fallback program.")
            brain.torch = false
            local fallback = brain.programFallback or "Bandit"
            Bandit.SetProgram(bandit, fallback)
            nextStage = "Prepare"
            return
        end

        local cx, cy, cz = bandit:getX(), bandit:getY(), bandit:getZ()
        if brain.bornCoords then
            cx, cy, cz = brain.bornCoords.x, brain.bornCoords.y, brain.bornCoords.z
        end
        
        local baseAngle = (brain.patrolNodes * (math.pi / 2))
        local safeID = brain.id or ZombRand(1000)
        local flankMod = math.abs(safeID) % 3
        local angleOffset = 0
        
        if flankMod == 1 then
            angleOffset = -(math.pi / 4)
        elseif flankMod == 2 then
            angleOffset = (math.pi / 4)  
        end
        
        local finalAngle = baseAngle + angleOffset + ZombRandFloat(-0.15, 0.15)
        
        -- [ААА-МЕХАНИКА: Berserker, Pacing (Outdoors)]
        if bandit:getBuilding() ~= nil then
            print("[Bandit BackupSearch] [CQB] Entered building. Switching to CQB program.")
            Bandit.SetProgram(bandit, "BackupCQB")
            Bandit.SetProgramStage(bandit, "Prepare")
            nextStage = "Prepare"
            return
        end
        
        local weapon = brain.weapons and brain.weapons.primary
        local hasFirearm = false
        if weapon and weapon.name and weapon.bulletsLeft and weapon.bulletsLeft > 0 then
            local wpnItem = BanditCompatibility.InstanceItem(weapon.name)
            if wpnItem and wpnItem:isAimedFirearm() then hasFirearm = true end
        end
        
        local dist
        if not hasFirearm then
            -- Berserker: Огромные дистанции забега, чтобы не стояли на месте
            dist = ZombRandFloat(25, 45)
            brain.sweepWalkType = "Run"
            print("[Bandit BackupSearch] [BERSERKER] Melee sweep generated.")
        else
            -- Улица: ААА Широкое прочесывание. Бегут далеко друг от друга.
            dist = (flankMod == 0) and ZombRandFloat(15, 25) or ZombRandFloat(25, 45)
            finalAngle = baseAngle + (angleOffset * 1.5) -- Расширяем угол сектора флангов
            
            -- [ФИКС СТАТТЕРОВ] Кешируем анимацию на весь забег до ноды
            local moveRoll = ZombRand(100)
            if moveRoll < 35 then brain.sweepWalkType = "Walk"
            elseif moveRoll > 85 then brain.sweepWalkType = "Run"
            else brain.sweepWalkType = "WalkAim" end
        end
        
        local targetX = cx + math.cos(finalAngle) * dist
        local targetY = cy + math.sin(finalAngle) * dist
        
        -- [ФИКС ИИ] Ищем безопасный тайл. Защита от зависания в непрогруженных чанках.
        local cell = getCell()
        local foundSafe = false
        if cell then
            for step = 0, math.floor(dist) do
                local testX = cx + math.cos(finalAngle) * (dist - step)
                local testY = cy + math.sin(finalAngle) * (dist - step)
                local sq = cell:getGridSquare(math.floor(testX), math.floor(testY), cz)
                
                if sq and sq:isFree(false) then
                    targetX = testX
                    targetY = testY
                    foundSafe = true
                    break
                end
            end
        end
        
        if not foundSafe then
            -- Если путь заблокирован или чанк не прогружен, бродим рядом, чтобы не стоять столбом
            local fallbackAng = ZombRandFloat(0, math.pi * 2)
            targetX = bandit:getX() + math.cos(fallbackAng) * 5
            targetY = bandit:getY() + math.sin(fallbackAng) * 5
            print("[Bandit BackupSearch] [SWEEP] Chunk unloaded or blocked. Using fallback close node.")
        end
        
        brain.sweepX = targetX
        brain.sweepY = targetY
        brain.sweepZ = cz
        
        print("[Bandit BackupSearch] [SWEEP] Calculated safe sweep coordinates: X:"..math.floor(brain.sweepX).." Y:"..math.floor(brain.sweepY))
    end)
    
    if not status then
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPBackupSearch | Stage: SweepNextNode")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(err))
        print("================================================================================")
    end

    return {status=true, next=nextStage, tasks=tasks}
end

-- ==============================================================================
-- СТАДИЯ 4: Главный цикл зачистки, Кровавый след и Боевой Радар
-- ==============================================================================
ZombiePrograms.BackupSearch.SweepMain = function(bandit)
    local tasks = {}
    local nextStage = "SweepNextNode"

    local status, err = pcall(function()
        local brain = BanditBrain.Get(bandit)
        
        if CheckTacticalRetreat(bandit, brain) then
            nextStage = "Escape"
            return
        end

        local isNight = (getGameTime():getHour() >= 21 or getGameTime():getHour() <= 6)
        local currentTime = (getTimestamp() + 0)
        
        -- УВЕЛИЧЕН РАДИУС СЛУХА ДЛЯ БАНДИТОВ, ЧТОБЫ ОНИ ЛУЧШЕ НАХОДИЛИ ЦЕЛЬ (ОСОБЕННО НОЧЬЮ)
        local config = { mustSee = false, hearDist = 35 }
        local target, enemy = BanditUtils.GetTarget(bandit, config)
        
        -- [ААА-МЕХАНИКА: ОТМЕНА ПРОЧЕСЫВАНИЯ ПОСЛЕ ЛИКВИДАЦИИ ИЛИ ПОТЕРЯ ЦЕЛИ]
        local canSeeEnemy = false
        if target and target.x and target.y and target.z then
            if enemy and bandit:CanSee(enemy) then
                brain.hasEngagedEnemy = true
                canSeeEnemy = true
            end
        end
        
        -- Если бандит был в бою, но вдруг потерял цель из виду (убежал далеко и не виден)
        if brain.hasEngagedEnemy then
            if not canSeeEnemy and (not target or target.dist > 35) then
                print("[Bandit BackupSearch] [COMBAT RESET] Target eliminated or lost. Switching back to deep sweep.")
                if SandboxVars.Bandits.General_Captions then
                    local shouts = {"Where did he go?! Spread out!", "I lost him! Check the perimeter!", "Find that rat!"}
                    bandit:addLineChatElement(BanditUtils.Choice(shouts), 0.8, 0.1, 0.1)
                end
                brain.hasEngagedEnemy = false
                brain.patrolNodes = 0 -- Сбрасываем счетчик нод, чтобы они начали искать по-новой
                nextStage = "SweepNextNode"
                return
            end
        end
        
        if target and target.x and target.y and target.z then
            print("[Bandit BackupSearch] [RADAR] Target visually/audibly acquired! ID: " .. tostring(target.id))
            if brain.torch then brain.torch = false end
            
            local tx, ty, tz = target.x, target.y, target.z
            if enemy and target.fx and target.fy and (enemy:isRunning() or enemy:isSprinting()) then
                tx, ty = target.fx, target.fy
            end

            print("[Bandit BackupSearch] [HIVEMIND] Sharing acquired target to Clan " .. tostring((brain.clan or -1)))
            ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)] = {
                x = tx, y = ty, z = tz,
                id = target.id,
                player = target.player,
                expire = currentTime + 4 
            }
            
            -- [ААА-МЕХАНИКА: ПОДАВЛЕНИЕ ОГНЕМ v2.0 (ПРОДВИНУТАЯ ТАКТИКА И ФЛАНГОВАНИЕ)]
            local canSee = false
            if enemy then canSee = bandit:CanSee(enemy) end
            
            -- Идеальная дистанция для подавления: от 6 до 25 тайлов.
            if target.dist > 6 and target.dist < 25 and enemy then
                local weapon = brain.weapons and brain.weapons.primary
                -- Требуем минимум 4 патрона для очереди, иначе это не подавление, а смех
                if weapon and weapon.name and weapon.bulletsLeft and weapon.bulletsLeft > 4 then
                    local wpnItem = BanditCompatibility.InstanceItem(weapon.name)
                    if wpnItem and wpnItem:isAimedFirearm() then
                        local modes = wpnItem:getFireModePossibilities()
                        local isAuto = false
                        if modes then
                            for i=0, modes:size()-1 do
                                if modes:get(i) == "Auto" then isAuto = true; break end
                            end
                        end
                        
                        -- Шанс зависит от видимости и режима стрельбы
                        local suppChance = isAuto and 40 or 15
                        if canSee then suppChance = isAuto and 20 or 5 end -- Если видим, шанс ниже, но иногда все равно жмем длинной
                        
                        if ZombRand(100) < suppChance then
                            if not brain.suppressCooldown or currentTime > brain.suppressCooldown then
                                -- Динамический кулдаун (10-20 сек), чтобы ИИ не стрелял без умолку, а давал игроку ложное чувство безопасности
                                brain.suppressCooldown = currentTime + ZombRand(10, 20)
                                
                                -- Динамический расчет длины очереди (Burst Size)
                                local burstSize = isAuto and ZombRand(4, 9) or ZombRand(2, 4)
                                if burstSize > weapon.bulletsLeft then burstSize = weapon.bulletsLeft end
                                
                                print("[Bandit BackupSearch] [TACTIC] SUPPRESSIVE FIRE on ID: " .. tostring(target.id) .. " | Burst: " .. tostring(burstSize) .. " | Dist: " .. tostring(math.floor(target.dist)))
                                
                                if SandboxVars.Bandits.General_Captions then
                                    local shouts = {
                                        "Laying down suppressive fire!", 
                                        "Flushing him out!", 
                                        "Shoot through the walls!", 
                                        "Keep him pinned!",
                                        "Covering fire!",
                                        "Light up that cover!"
                                    }
                                    bandit:addLineChatElement(BanditUtils.Choice(shouts), 0.8, 0.1, 0.1)
                                end
                                
                                -- Отправляем сигнал в улей для Флангования (Клещи)
                                ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)].suppressing = {
                                    x = target.x, y = target.y, z = target.z,
                                    sx = bandit:getX(), sy = bandit:getY(), sz = tz, -- Координаты сапрессора (Якорь)
                                    banditId = brain.id,
                                    targetId = target.id,
                                    expire = currentTime + 8
                                }
                                
                                -- 1. Дослать патрон (если нужно)
                                if not weapon.racked then
                                    local stasks = BanditPrograms.Weapon.Rack(bandit, "primary")
                                    if stasks then for _, t in pairs(stasks) do table.insert(tasks, t) end end
                                end
                                
                                -- 2. Прицелиться в координаты укрытия
                                local stasksAim = BanditPrograms.Weapon.Aim(bandit, enemy, "primary")
                                if stasksAim then for _, t in pairs(stasksAim) do table.insert(tasks, t) end end
                                
                                -- 3. Высадить плотную очередь (свой генератор пула задач для подавления)
                                local anim = wpnItem:isTwoHandWeapon() and "AimRifle" or "AimPistol"
                                local firingtime = wpnItem:getRecoilDelay() + math.floor(target.dist ^ 1.1)
                                
                                for i=1, burstSize do
                                    local timeTask = (i == 1) and firingtime or 7 -- первая пуля требует прицеливания, остальные летят спреем
                                    local taskShoot = {action="Shoot", anim=anim, time=timeTask, slot="primary", x=target.x, y=target.y, z=target.z, eid=target.id}
                                    table.insert(tasks, taskShoot)
                                end
                                
                                -- 4. Тактическая пауза для оценки результатов (1-2 сек)
                                table.insert(tasks, {action="Time", time=ZombRand(60, 120), lock=true})
                                nextStage = "SweepMain"
                                return
                            end
                        end
                    end
                end
            end
            
            -- Определяем наличие огнестрела (нужно для флангования и раша)
            local hasFirearm = false
            local weapon = brain.weapons and brain.weapons.primary
            if weapon and weapon.name and weapon.bulletsLeft and weapon.bulletsLeft > 0 then
                local wpnItem = BanditCompatibility.InstanceItem(weapon.name)
                if wpnItem and wpnItem:isAimedFirearm() then hasFirearm = true end
            end
            
            -- [ААА-МЕХАНИКА: ФЛАНГОВАНИЕ (PINCER MANEUVER V-FORMATION)]
            local hm = ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)]
            -- Флангуют только стрелки с патронами (hasFirearm)
            if hasFirearm and hm and hm.suppressing and hm.suppressing.expire > currentTime and hm.suppressing.banditId ~= brain.id then
                local distToTarget = BanditUtils.DistTo(bandit:getX(), bandit:getY(), hm.suppressing.x, hm.suppressing.y)
                
                if distToTarget > 4 and distToTarget < 30 then
                    -- Динамическая глубина фланга: 80% от дистанции между сапрессором и игроком (минимум 8, максимум 25)
                    local supDistToTarget = BanditUtils.DistTo(hm.suppressing.sx, hm.suppressing.sy, hm.suppressing.x, hm.suppressing.y)
                    local flankDepth = math.max(8, math.min(25, supDistToTarget * 0.8))
                    
                    -- Вычисляем линию огня от Сапрессора до Игрока
                    local angleLineOfFire = math.atan2(hm.suppressing.y - hm.suppressing.sy, hm.suppressing.x - hm.suppressing.sx)
                    
                    -- Разделяем отряд: четные ID идут влево, нечетные вправо
                    local flankDir = (math.abs(brain.id or 1) % 2 == 0) and 1 or -1
                    
                    local flankX, flankY
                    local foundClearLOS = false
                    
                    -- Умный поиск линии огня (Smart LOS): постепенно расширяем угол от 45 до 90 градусов
                    for angleOffset = 0.785, 1.57, 0.26 do -- 45°, 60°, 75°, 90°
                        local testAngle = angleLineOfFire + (flankDir * angleOffset)
                        local tx = hm.suppressing.sx + math.cos(testAngle) * flankDepth
                        local ty = hm.suppressing.sy + math.sin(testAngle) * flankDepth
                        
                        -- Проверяем, чиста ли линия огня от точки фланга до игрока
                        if cell then
                            local destSq = cell:getGridSquare(math.floor(tx), math.floor(ty), hm.suppressing.sz or tz)
                            -- Дополнительно проверяем, что на тайле фланга можно стоять (не внутри стены)
                            if destSq and destSq:isFree(false) then
                                local lineCheck = tostring(LosUtil.lineClear(cell, math.floor(tx), math.floor(ty), hm.suppressing.sz or tz, math.floor(hm.suppressing.x), math.floor(hm.suppressing.y), hm.suppressing.z or tz, false))
                                if lineCheck ~= "Blocked" then
                                    flankX, flankY = tx, ty
                                    foundClearLOS = true
                                    break
                                end
                            end
                        end
                    end
                    
                    -- Если чистой линии не нашли (глухой лес/город), просто берем изначальный 45-градусный угол
                    if not foundClearLOS then
                        local flankAngle = angleLineOfFire + (flankDir * 0.785)
                        flankX = hm.suppressing.sx + math.cos(flankAngle) * flankDepth
                        flankY = hm.suppressing.sy + math.sin(flankAngle) * flankDepth
                    end
                    
                    local myDistToFlank = BanditUtils.DistTo(bandit:getX(), bandit:getY(), flankX, flankY)
                    
                    if myDistToFlank < 3 then
                        -- Прибыли на фланг! Останавливаемся, припадаем на колено и открываем перекрестный огонь.
                        if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
                        table.insert(tasks, {action="Time", anim="RifleAim", time=ZombRand(60, 120), lock=true})
                        
                        -- [ПЕРЕКАТЫ / BOUNDING OVERWATCH]
                        -- Берем роль подавляющего на себя, позволяя первому стрелку двигаться вперед
                        hm.suppressing = {
                            x = hm.suppressing.x, y = hm.suppressing.y, z = hm.suppressing.z,
                            sx = bandit:getX(), sy = bandit:getY(), sz = bandit:getZ(),
                            banditId = brain.id,
                            targetId = hm.suppressing.targetId,
                            expire = currentTime + 8
                        }
                        
                        nextStage = "SweepMain"
                        return
                    else
                        -- Спринтуем или крадемся в зависимости от дистанции
                        local currentWalkType = "Sprint"
                        if myDistToFlank < 6 then
                            currentWalkType = "WalkAim" -- Тактический подход перед выходом на огневую
                        end
                        
                        -- Еще не добежали - двигаемся к якорю!
                        if SandboxVars.Bandits.General_Captions and (not hm.lastSpokeFlank or currentTime > hm.lastSpokeFlank + 15) then
                            hm.lastSpokeFlank = currentTime
                            local shouts = {"Flanking!", "Moving around!", "Pin him down, I'm crossing!", "I've got an angle!"}
                            bandit:addLineChatElement(BanditUtils.Choice(shouts), 0.8, 0.1, 0.1)
                        end
                        
                        if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
                        -- Используем обычный GetMoveTask (по координатам), чтобы движок не заставлял бежать к игроку
                        table.insert(tasks, BanditUtils.GetMoveTask(0, flankX, flankY, tz, currentWalkType, myDistToFlank, false))
                        nextStage = "SweepMain"
                        return
                    end
                end
            end
            
            local walkType = Bandit.GetCombatWalktype(bandit, enemy, target.dist)
            
            -- [ААА-МЕХАНИКА: БЕСПРЕРЫВНЫЙ БЕРСЕРК РАШ]
            -- Если милишник видит цель или бежит по радару, он не использует медленные анимации, а чаржит насмерть
            if not hasFirearm then
                walkType = "Run"
                if target.dist > 5 then walkType = "Sprint" end
            end
            
            table.insert(tasks, BanditUtils.GetMoveTaskTarget(0, tx, ty, tz, target.id, target.player, walkType, target.dist))
            nextStage = "SweepMain"
            return
        end
        
        local hm = ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)]
        local exp = hm and type(hm.expire) == "number" and hm.expire or 0
        local cur = type(currentTime) == "number" and currentTime or 0
        
        if hm and exp > cur then
            local sharedData = hm
            local distToShared = BanditUtils.DistTo(bandit:getX(), bandit:getY(), sharedData.x, sharedData.y)
            
            if distToShared < 40 then
                print("[Bandit BackupSearch] [HIVEMIND] Responding to shared coordinates from Clan.")
                if brain.torch then brain.torch = false end
                
                local hm = ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)]
                if not hm.lastSpokeIntercept or (currentTime - hm.lastSpokeIntercept > 20) then
                    hm.lastSpokeIntercept = currentTime
                    if SandboxVars.Bandits.General_Captions and ZombRand(100) < 30 then
                        bandit:addLineChatElement("Moving to intercept!", 0.8, 0.1, 0.1)
                    end
                end
                
                table.insert(tasks, BanditUtils.GetMoveTaskTarget(0, sharedData.x, sharedData.y, sharedData.z, sharedData.id, sharedData.player, "Run", distToShared))
                nextStage = "SweepMain"
                return
            end
        end
        
        if isNight and not brain.torch then
            local inv = bandit:getInventory()
            if inv and inv:getItemCountFromTypeRecurse("Base.HandTorch") > 0 then
                brain.torch = true
            end
        end

        if brain.patrolNodes > 1 and not brain.bloodTracked and ZombRand(100) < 35 then
            local cx, cy, cz = bandit:getX(), bandit:getY(), bandit:getZ()
            local cell = getCell()
            local bloodFound = false
            
            for y = -3, 3 do
                for x = -3, 3 do
                    local sq = cell:getGridSquare(cx + x, cy + y, cz)
                    if sq and sq:haveBlood() then
                        print("[Bandit BackupSearch] [TRACKING] Blood trail found at X:" .. math.floor(cx+x) .. " Y:" .. math.floor(cy+y))
                        brain.sweepX = cx + x
                        brain.sweepY = cy + y
                        brain.bloodTracked = true
                        bloodFound = true
                        
                        local hm = ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)]
                        if not hm then hm = {}; ZombiePrograms.BackupSearch.HiveMind[(brain.clan or -1)] = hm end
                        if not hm.lastSpokeBlood or (currentTime - hm.lastSpokeBlood > 60) then
                            hm.lastSpokeBlood = currentTime
                            if SandboxVars.Bandits.General_Captions then
                                bandit:addLineChatElement("Fresh blood! He's wounded, find him!", 0.8, 0.1, 0.1)
                            end
                            Bandit.Say(bandit, "THIEF_SPOTTED", true)
                        end
                        break
                    end
                end
                if bloodFound then break end
            end
        end
        
        if brain.sweepX and brain.sweepY then
            local dist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), brain.sweepX, brain.sweepY)
            
            brain.sweepTicks = (brain.sweepTicks or 0) + 1
            
            -- Динамический таймаут застревания, зависящий от длины дистанции (чтобы не отменялось на полпути)
            local maxTicks = 150 + math.floor(dist * 15)
            if dist > 1.5 and brain.sweepTicks < maxTicks then
                
                local isIndoors = bandit:getBuilding() ~= nil
                local weapon = brain.weapons and brain.weapons.primary
                local hasFirearm = false
                if weapon and weapon.name and weapon.bulletsLeft and weapon.bulletsLeft > 0 then
                    local wpnItem = BanditCompatibility.InstanceItem(weapon.name)
                    if wpnItem and wpnItem:isAimedFirearm() then hasFirearm = true end
                end
                
                local walkType = "WalkAim"
                if not hasFirearm then
                    -- Berserker: никаких прицеливаний, только агрессивный бег
                    walkType = "Run"
                    if brain.bloodTracked then walkType = "Sprint" end
                elseif isIndoors then
                    -- CQB SWAT: Зашли в дом - стволы подняты, двигаемся медленно, нарезаем углы
                    walkType = "WalkAim"
                else
                    -- Улица: Кешированная плавная анимация без статтеров каждые 50 тиков
                    walkType = brain.sweepWalkType or "WalkAim"
                    if brain.bloodTracked then walkType = "WalkAim" end
                end
                
                local currentTasks = bandit:getModData().tasks
                if not currentTasks or #currentTasks == 0 then
                    if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
                    
                    -- [ААА-Антизастревание]: Если задач нет, но мы не дошли до ноды - мы врезались!
                    -- Смещаем цель на 1.5 тайла в сторону и берем паузу на стабилизацию движка
                    if (not currentTasks or #currentTasks == 0) and brain.sweepTicks > 5 then
                        -- [ФИКС АНТИСТАКА] Вынуждаем сбросить текущую точку и найти новую, чтобы избежать дерганья на месте
                        brain.sweepTicks = 9999
                        table.insert(tasks, {action="Time", time=ZombRand(40, 80), lock=true})
                        nextStage = "SweepMain"
                        return
                    end
                    
                    table.insert(tasks, BanditUtils.GetMoveTask(0, brain.sweepX, brain.sweepY, brain.sweepZ, walkType, dist, false))
                end
                
                nextStage = "SweepMain"
                return
            else
                if brain.sweepTicks >= maxTicks then
                    print("[Bandit BackupSearch] [SWEEP] Bandit ID: " .. tostring(brain.id) .. " got stuck! Advancing to next patrol node.")
                end
                
                brain.bloodTracked = false
                brain.sweepTicks = 0
                
                if Bandit.ClearTasks then Bandit.ClearTasks(bandit) end
                
                local weapon = brain.weapons and brain.weapons.primary
                local hasFirearm = false
                if weapon and weapon.name and weapon.bulletsLeft and weapon.bulletsLeft > 0 then
                    local wpnItem = BanditCompatibility.InstanceItem(weapon.name)
                    if wpnItem and wpnItem:isAimedFirearm() then hasFirearm = true end
                end
                
                -- Милишники не делают тактических пауз "осмотреться", они прут нон-стопом на следующую точку
                if hasFirearm then
                    local pauseTime = ZombRand(40, 150)
                    table.insert(tasks, {action="Time", time=pauseTime, lock=true})
                end
                
                nextStage = "SweepNextNode"
                return
            end
        end
    end)
    
    if not status then
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPBackupSearch | Stage: SweepMain")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(err))
        print("================================================================================")
    end

    return {status=true, next=nextStage, tasks=tasks}
end

-- ==============================================================================
-- Название: ZPSurrender.lua (AAA СИСТЕМА КАЗНИ И ПЛЕНА + МИЛОСЕРДИЕ)
-- Описание: Кастомная программа поведения (ИИ) для сдачи в плен.
-- Функционал: Занижены пороги для теста. Если остался 1 бандит, он сдается.
--             Полный сброс оружия и сумок. Враги подходят, лутают и казнят.
-- НОВОЕ (v8.0): Добавлено контекстное меню "Отпустить бандита". При активации
--             сдавшийся переходит в стадию "Escape" (бегство), агрессия палачей
--             отменяется, бандит убегает без оружия. Полное pcall логирование.
-- ФИКС КРАШЕЙ: Внедрена ААА-система отлова ошибок (Memory Dump Exception).
-- ФИКС (v8.9): Добавлен ГИГАНТСКИЙ пул лута (60+ предметов) для максимального 
--             разнообразия трофеев. Исправлены ключи локализации (IGUI_) для 
--             идеального отображения контекстного меню на RU/EN.
-- ФИКС (v9.0): Устранен фатальный краш Java (Zero length vector) при faceThisObject.
-- ==============================================================================

ZombiePrograms = ZombiePrograms or {}
ZombiePrograms.Surrender = {}
ZombiePrograms.Surrender.Stages = {}

_G.OmniClanDeathTracker = _G.OmniClanDeathTracker or {}
_G.OmniStaggeredDrops = _G.OmniStaggeredDrops or {}

-- ==============================================================================
-- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ: Сброс программы казни для группы
-- ==============================================================================
local function RestoreAggression()
    local status, err = pcall(function()
        print("[Bandit Surrender] [AGGRESSION] Execution complete or aborted. Restoring patrol programs.")
        
        if not BanditZombie or not BanditZombie.CacheLightB then return end
        
        local bList = BanditZombie.CacheLightB
        if bList then
            for id, bLight in pairs(bList) do
                local eBrain = bLight.brain
                if eBrain and (eBrain.isExecutioner or (eBrain.program and eBrain.program.name == "ExecuteSurrendered")) then
                    print("[Bandit Surrender] [AGGRESSION] Resetting AI and restoring hostility for ID: " .. tostring(id))
                    eBrain.isExecutioner = false
                    eBrain.targetSurrendererId = nil
                    
                    if eBrain.storedHostile ~= nil then
                        eBrain.hostile = eBrain.storedHostile
                        eBrain.hostileP = eBrain.storedHostileP
                        eBrain.storedHostile = nil
                        eBrain.storedHostileP = nil
                    end
                    
                    -- ЖЕСТКИЙ СБРОС ЗАДАЧ, чтобы палач не завис в анимации прицеливания (lock=true)
                    eBrain.tasks = {}
                    
                    local enemyInst = BanditZombie.Cache[id]
                    if enemyInst then
                        enemyInst:clearAggroList()
                        enemyInst:setTarget(nil)
                        if Bandit.SetProgram then Bandit.SetProgram(enemyInst, "Bandit") end
                        if BanditBrain.Update then BanditBrain.Update(enemyInst, eBrain) end
                    end
                end
            end
        end
    end)
    
    if not status then 
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Function: RestoreAggression")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(err))
        print("================================================================================")
    end
end

-- ==============================================================================
-- СТАДИЯ 1: КЛИЕНТ - Подготовка
-- ==============================================================================
ZombiePrograms.Surrender.Init = function(bandit)
    print("[Bandit Surrender] [INIT] Surrender program initialized.")
end

ZombiePrograms.Surrender.Prepare = function(bandit)
    print("[Bandit Surrender] [PREPARE] Surrender preparation stage.")
    return {status=true, next="Wait", tasks={}}
end

-- ==============================================================================
-- СТАДИЯ 2: КЛИЕНТ - Покорное ожидание (Руки вверх), Радар Зомби и Палачей
-- ==============================================================================
ZombiePrograms.Surrender.Wait = function(bandit)
    local tasks = {}
    local nextStage = "Wait"
    
    local statusWait, errWait = pcall(function()
        local brain = BanditBrain.Get(bandit)
        if not brain then return end
        
        local closestZombie = BanditUtils.GetClosestZombieLocation(bandit, {mustSee = false, hearDist = 8})
        if closestZombie and closestZombie.dist < 3.5 then
            print("[Bandit Surrender] [ABORT] Zombies detected nearby! Canceling surrender and escaping!")
            if SandboxVars.Bandits.General_Captions then bandit:addLineChatElement("Zombies! I'm out of here!", 0.9, 0.2, 0.2) end
            
            if bandit.getModData then bandit:getModData().isSurrendering = false end
            brain.isSurrendering = false
            Bandit.SetProgram(bandit, "Surrender")
            Bandit.SetProgramStage(bandit, "Escape")
            
            nextStage = "Escape" 
            
            RestoreAggression()
            return
        end

        local bList = BanditZombie.CacheLightB
        if bList then
            local execClan = brain.executionerClan 

            for id, bLight in pairs(bList) do
                local enemyInst = BanditZombie.Cache[id]
                if enemyInst and enemyInst:isAlive() and enemyInst ~= bandit then
                    local eBrain = bLight.brain
                    if eBrain then
                        local isEnemyOrCaptor = false
                        if execClan then
                            isEnemyOrCaptor = (execClan and eBrain.clan == execClan)
                        else
                            isEnemyOrCaptor = BanditUtils.AreEnemies(brain, eBrain)
                        end
                        
                        if isEnemyOrCaptor then
                            local dist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), bLight.x, bLight.y)
                            
                            if dist < 45 and enemyInst:CanSee(bandit) then
                                -- SANDBOX: Включение/Отключение кинематографичной программы казни
                                if SandboxVars.Bandits.Addon_EnableExecution ~= false then
                                    if not execClan then
                                        print("[Bandit Surrender] [FALLBACK EXECUTIONER] ID: " .. tostring(eBrain.id) .. " takes the prisoner.")
                                        enemyInst:clearAggroList()
                                        enemyInst:setTarget(nil)
                                        if Bandit.ClearTasks then Bandit.ClearTasks(enemyInst) end
                                        
                                        execClan = eBrain.clan
                                        brain.executionerClan = execClan
                                        brain.originalClan = brain.clan
                                        brain.clan = execClan
                                        bandit:setVariable("BanditClan", tostring(execClan))
                                        
                                        eBrain.isExecutioner = true
                                        eBrain.targetSurrendererId = brain.id
                                        eBrain.storedHostile = eBrain.hostile
                                        eBrain.storedHostileP = eBrain.hostileP
                                        eBrain.hostile = false
                                        eBrain.hostileP = false
                                        
                                        Bandit.SetProgram(enemyInst, "ExecuteSurrendered")
                                        Bandit.SetProgramStage(enemyInst, "Approach")
                                        if BanditBrain.Update then BanditBrain.Update(enemyInst, eBrain) end
                                    
                                    elseif execClan and eBrain.clan == execClan and not eBrain.isExecutioner then
                                        if not eBrain.program or eBrain.program.name ~= "ExecuteSurrendered" then
                                            print("[Bandit Surrender] [FALLBACK OVERWATCH] ID: " .. tostring(eBrain.id) .. " is holding the perimeter.")
                                            enemyInst:clearAggroList()
                                            enemyInst:setTarget(nil)
                                            if Bandit.ClearTasks then Bandit.ClearTasks(enemyInst) end
                                            
                                            eBrain.targetSurrendererId = brain.id
                                            if eBrain.storedHostile == nil then
                                                eBrain.storedHostile = eBrain.hostile
                                                eBrain.storedHostileP = eBrain.hostileP
                                                eBrain.hostile = false
                                                eBrain.hostileP = false
                                            end
                                            
                                            Bandit.SetProgram(enemyInst, "ExecuteSurrendered")
                                            Bandit.SetProgramStage(enemyInst, "Overwatch")
                                            if BanditBrain.Update then BanditBrain.Update(enemyInst, eBrain) end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        table.insert(tasks, {action="Time", anim="Surrender", time=300, lock=true})
    end)

    if not statusWait then 
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Stage: Wait")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(errWait))
        print("[Bandit Addon] DUMPING LOCAL STATE:")
        print("   - Target Bandit Data: " .. tostring(bandit))
        print("================================================================================")
    end

    return {status=true, next=nextStage, tasks=tasks}
end

-- ==============================================================================
-- СТАДИЯ 3: КЛИЕНТ - Бегство (Милосердие или Зомби)
-- ==============================================================================
ZombiePrograms.Surrender.Escape = function(bandit)
    local tasks = {}
    local nextStage = "Escape"
    
    local statusEsc, errEsc = pcall(function()
        local brain = BanditBrain.Get(bandit)
        if not brain then return end
        
        -- Анти-заикание (Anti-Stutter): Принудительно размораживаем бандита
        if bandit:isUseless() then
            bandit:setUseless(false)
        end
        
        local player = getSpecificPlayer(0)
        if player then
            local bx, by = bandit:getX(), bandit:getY()
            local px, py = player:getX(), player:getY()
            
            -- Вычисляем вектор строго ОТ игрока
            local dx = bx - px
            local dy = by - py
            
            -- Если стоим прямо в одной точке с игроком
            if dx == 0 and dy == 0 then dx = 1; dy = 1 end
            
            local dist = math.sqrt(dx*dx + dy*dy)
            local runDist = 40 -- Бежим очень далеко, чтобы бандит пропал из виду
            
            local targetX = bx + (dx/dist) * runDist
            local targetY = by + (dy/dist) * runDist
            
            table.insert(tasks, BanditUtils.GetMoveTask(0.01, targetX, targetY, bandit:getZ(), "Run", runDist, false))
        else
            -- Если игрока нет (редкий случай), просто бежим в случайном направлении
            local angle = ZombRandFloat(0, math.pi * 2)
            local targetX = bandit:getX() + math.cos(angle) * 40
            local targetY = bandit:getY() + math.sin(angle) * 40
            table.insert(tasks, BanditUtils.GetMoveTask(0.01, targetX, targetY, bandit:getZ(), "Run", 40, false))
        end
    end)
    
    if not statusEsc then 
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Stage: Escape")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(errEsc))
        print("================================================================================")
    end

    return {status=true, next=nextStage, tasks=tasks}
end

-- ==============================================================================
-- НОВАЯ ПРОГРАММА: КАЗНЬ ПЛЕННОГО (Для отряда, захватившего пленника)
-- ==============================================================================
ZombiePrograms.ExecuteSurrendered = {}
ZombiePrograms.ExecuteSurrendered.Stages = {}

ZombiePrograms.ExecuteSurrendered.Init = function(bandit)
end

ZombiePrograms.ExecuteSurrendered.Prepare = function(bandit)
    return {status=true, next="Approach", tasks={}}
end

ZombiePrograms.ExecuteSurrendered.Approach = function(bandit)
    local tasks = {}
    local nextStage = "Approach"
    
    local statusApp, errApp = pcall(function()
        local brain = BanditBrain.Get(bandit)
        local targetID = brain.targetSurrendererId
        local target = targetID and BanditZombie.Cache[targetID]

        if not target or target:getHealth() <= 0 then
            print("[Bandit Surrender] [APPROACH CANCEL] Target missing or dead. Aborting execution.")
            RestoreAggression()
            nextStage = "Prepare"
            return
        elseif not target:getModData().isSurrendering then
            print("[Bandit Surrender] [APPROACH CANCEL] Target released. Aborting execution.")
            RestoreAggression()
            nextStage = "Prepare"
            return
        end

        local dist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), target:getX(), target:getY())
        
        if dist > 1.2 then
            local zDiff = math.abs(bandit:getZ() - target:getZ())
            local isWallTo = false
            if bandit:getSquare() and target:getSquare() then
                isWallTo = bandit:getSquare():isSomethingTo(target:getSquare())
            end
            
            if zDiff >= 1.0 or isWallTo then
                print("[Bandit Surrender] [APPROACH ABORT] Target unreachable (Wall or Z-level). Canceling execution.")
                RestoreAggression()
                nextStage = "Prepare"
                return
            end
            
            -- ФИКС КРАША: Zero vector protection
            if dist > 0.05 then
                bandit:faceThisObject(target)
            end
            
            local task = BanditUtils.GetMoveTask(0, target:getX(), target:getY(), target:getZ(), "Run", dist, false)
            table.insert(tasks, task)
        else
            print("[Bandit Surrender] [APPROACH SUCCESS] Executioner in range. Starting loot phase.")
            nextStage = "Loot"
        end
    end)
    
    if not statusApp then 
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Stage: Executioner Approach")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(errApp))
        print("================================================================================")
    end

    return {status=true, next=nextStage, tasks=tasks}
end

ZombiePrograms.ExecuteSurrendered.Overwatch = function(bandit)
    local tasks = {}
    local nextStage = "Overwatch"

    local statusOW, errOW = pcall(function()
        local brain = BanditBrain.Get(bandit)
        local targetID = brain.targetSurrendererId
        local target = targetID and BanditZombie.Cache[targetID]

        if not target or target:getHealth() <= 0 then
            RestoreAggression()
            nextStage = "Prepare"
            return
        elseif not target:getModData().isSurrendering then
            RestoreAggression()
            nextStage = "Prepare"
            return
        end

        local dist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), target:getX(), target:getY())
        
        -- ФИКС КРАША: Защита нулевого вектора. Поворачиваемся, только если не стоим в одной точке.
        if dist > 0.05 then
            bandit:faceThisObject(target)
        end

        if dist < 4.5 then
            local mrad = math.atan2(bandit:getY() - target:getY(), bandit:getX() - target:getX())
            local nbx = target:getX() + (6.0 * math.cos(mrad))
            local nby = target:getY() + (6.0 * math.sin(mrad))
            local task = BanditUtils.GetMoveTask(0.01, nbx, nby, target:getZ(), "WalkBwdAim", 1.5, false)
            task.backwards = true
            table.insert(tasks, task)
        elseif dist > 7.5 then
            local task = BanditUtils.GetMoveTask(0, target:getX(), target:getY(), target:getZ(), "WalkAim", dist, false)
            table.insert(tasks, task)
        else
            local weapon = bandit:getPrimaryHandItem()
            if weapon and weapon:IsWeapon() and weapon:isAimedFirearm() then
                Bandit.SetAim(bandit, true)
                table.insert(tasks, {action="Time", anim="RifleAim", time=60})
            else
                table.insert(tasks, {action="Time", anim="Idle", time=60})
            end
        end
    end)

    if not statusOW then 
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Stage: Executioner Overwatch")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(errOW))
        print("================================================================================")
    end

    return {status=true, next=nextStage, tasks=tasks}
end

ZombiePrograms.ExecuteSurrendered.Loot = function(bandit)
    local tasks = {}
    
    local statusLoot, errLoot = pcall(function()
        if SandboxVars.Bandits.General_Captions then
            local lines = {"Look at all this gear...", "Mine now, loser.", "Jackpot.", "I'll take these..."}
            bandit:addLineChatElement(lines[ZombRand(#lines) + 1], 0.8, 0.8, 0.8)
        end
        table.insert(tasks, {action="Time", anim="LootLow", time=450, lock=true})
    end)

    if not statusLoot then 
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Stage: Executioner Loot")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(errLoot))
        print("================================================================================")
    end

    return {status=true, next="Execute", tasks=tasks}
end

ZombiePrograms.ExecuteSurrendered.Execute = function(bandit)
    local tasks = {}
    local nextStage = "FinishExecution"
    
    local statusExec, errExec = pcall(function()
        local brain = BanditBrain.Get(bandit)
        local targetID = brain.targetSurrendererId
        local target = targetID and BanditZombie.Cache[targetID]
        
        if target then
            local sq = target:getCurrentSquare()
            if sq then
                local worldObjs = sq:getWorldObjects()
                local inv = bandit:getInventory()
                if worldObjs and inv then
                    local itemsToTake = {}
                    
                    for i = worldObjs:size() - 1, 0, -1 do
                        local wo = worldObjs:get(i)
                        if wo and wo:getItem() then table.insert(itemsToTake, wo) end
                    end
                    
                    local tookSomething = false
                    for _, wo in ipairs(itemsToTake) do
                        if ZombRand(100) < 65 then
                            local item = wo:getItem()
                            if sq.transmitRemoveItemFromSquare then sq:transmitRemoveItemFromSquare(wo) end
                            wo:removeFromSquare()
                            inv:AddItem(item)
                            tookSomething = true
                        end
                    end
                    if tookSomething then bandit:playSound("PutItemInBag") end
                end
            end
        end
        
        if SandboxVars.Bandits.General_Captions then
            local lines = {"Now die.", "No witnesses.", "Say goodnight."}
            bandit:addLineChatElement(lines[ZombRand(#lines) + 1], 0.8, 0.2, 0.2)
        end
        
        if target and target:getHealth() > 0 then
            print("[Bandit Surrender] [EXECUTE] Executing target ID: " .. tostring(targetID))
            
            -- ФИКС КРАША: Защита нулевого вектора
            local execDist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), target:getX(), target:getY())
            if execDist > 0.05 then
                bandit:faceThisObject(target)
            end
            
            local weapon = bandit:getPrimaryHandItem()
            
            if weapon and weapon:IsWeapon() and weapon:isAimedFirearm() then
                local sound = weapon:getSwingSound() or "PistolShoot"
                bandit:playSound(sound)
                if BanditCompatibility and BanditCompatibility.StartMuzzleFlash then BanditCompatibility.StartMuzzleFlash(bandit) end
                table.insert(tasks, {action="Time", anim="AttackRifle", time=50, lock=true})
            else
                bandit:playSound("ZombieBite")
                table.insert(tasks, {action="Time", anim="AttackBat", time=50, lock=true})
            end
            
            target:setHealth(0)
            target:setAttackedBy(bandit)
        end
    end)
    
    if not statusExec then 
        print("================================================================================")
        print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Stage: Execute")
        print("[Bandit Addon] ERROR TRACE: " .. tostring(errExec))
        print("================================================================================")
    end
    return {status=true, next=nextStage, tasks=tasks}
end

ZombiePrograms.ExecuteSurrendered.FinishExecution = function(bandit)
    pcall(function() RestoreAggression() end)
    return {status=true, next="Prepare", tasks={}}
end

-- ==============================================================================
-- СЕРВЕРНЫЙ ТРИГГЕР, ДРОП И ОБРАБОТКА МИЛОСЕРДИЯ (RELEASE BANDIT)
-- ==============================================================================
if isServer() then
    
    local function OnClientCommandSurrenderAddon(module, command, player, args)
        if module == "BanditAddon" and command == "ReleaseBandit" then
            local statusCmd, errCmd = pcall(function()
                local targetID = tonumber(args.id)
                
                print("=====================================================")
                print("[Bandit Surrender] [MERCY] Server received Release for ID: " .. tostring(targetID))
                print("=====================================================")

                -- 1. ОБНОВЛЯЕМ ГЛОБАЛЬНЫЙ КЛАСТЕР (Синхронизация для всех)
                if _G.GetBanditClusterData then
                    local status, gmd = pcall(_G.GetBanditClusterData, targetID)
                    if status and type(gmd) == "table" and gmd[targetID] then
                        local brain = gmd[targetID]
                        brain.isSurrendering = false
                        brain.corpseDefended = false
                        brain.hostile = false
                        brain.hostileP = false
                        
                        -- Используем нашу новую кастомную стадию
                        brain.program.name = "Surrender"
                        brain.program.stage = "Escape"
                        
                        brain.tasks = {} -- ЖЕСТКИЙ СБРОС ЗАДАЧ
                        if _G.TransmitBanditCluster then _G.TransmitBanditCluster(targetID) end
                    end
                end

                -- 2. ПЫТАЕМСЯ ОБНОВИТЬ ЗОМБИ НАПРЯМУЮ, ЕСЛИ СЕРВЕР ЕГО ВИДИТ
                local cell = getCell()
                if cell and cell:getZombieList() then
                    local zList = cell:getZombieList()
                    local targetBandit = nil
                    
                    for i = 0, zList:size() - 1 do
                        local z = zList:get(i)
                        if z and z:getHealth() > 0 then
                            local zId = BanditUtils.GetCharacterID(z)
                            if zId and tostring(zId) == tostring(targetID) then
                                targetBandit = z
                                break
                            end
                        end
                    end

                    if targetBandit then
                        if targetBandit.getModData then 
                            targetBandit:getModData().isSurrendering = false 
                            targetBandit:transmitModData()
                        end
                        
                        local brain = BanditBrain.Get(targetBandit)
                        if brain then
                            brain.isSurrendering = false
                            brain.corpseDefended = false
                            brain.hostile = false
                            brain.hostileP = false
                            
                            -- Направляем в нашу стадию бегства
                            brain.program.name = "Surrender"
                            brain.program.stage = "Escape"
                            
                            -- ЖЕСТКИЙ СБРОС (Игнорируем блокировки)
                            brain.tasks = {}

                            targetBandit:clearAggroList()
                            targetBandit:setTarget(nil)
                            
                            if BanditBrain.Update then BanditBrain.Update(targetBandit, brain) end
                        end
                    else
                        print("[Bandit Surrender] [RELEASE] Target ID " .. tostring(targetID) .. " not in server cell. Relying on Cluster Data Sync.")
                    end

                    -- СБРАСЫВАЕМ ПАЛАЧЕЙ
                    for i = 0, zList:size() - 1 do
                        local enemy = zList:get(i)
                        if enemy and enemy:getHealth() > 0 then
                            local eBrain = BanditBrain.Get(enemy)
                            if eBrain and eBrain.isExecutioner and tostring(eBrain.targetSurrendererId) == tostring(targetID) then
                                print("[Bandit Surrender] [MERCY] Canceling execution order for Executioner ID: " .. tostring(eBrain.id))
                                eBrain.isExecutioner = false
                                eBrain.targetSurrendererId = nil
                                
                                if eBrain.storedHostile ~= nil then
                                    eBrain.hostile = eBrain.storedHostile
                                    eBrain.hostileP = eBrain.storedHostileP
                                    eBrain.storedHostile = nil
                                    eBrain.storedHostileP = nil
                                end
                                
                                eBrain.tasks = {} -- ЖЕСТКИЙ СБРОС
                                
                                enemy:clearAggroList()
                                enemy:setTarget(nil)
                                if Bandit.SetProgram then Bandit.SetProgram(enemy, "Bandit") end
                                if BanditBrain.Update then BanditBrain.Update(enemy, eBrain) end
                                if _G.TransmitBanditCluster then _G.TransmitBanditCluster(eBrain.id) end
                            end
                        end
                    end
                end

                -- 3. ПРИНУДИТЕЛЬНО РАССЫЛАЕМ КЛИЕНТАМ КОМАНДУ АНИМАЦИИ
                sendServerCommand("BanditAddon", "ReleasedVoice", { id = targetID })

            end)
            if not statusCmd then 
                print("================================================================================")
                print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Event: OnClientCommandSurrenderAddon")
                print("[Bandit Addon] ERROR TRACE: " .. tostring(errCmd))
                print("[Bandit Addon] ARGUMENTS: TargetID = " .. tostring(args and args.id))
                print("================================================================================")
            end
        end
    end
    Events.OnClientCommand.Add(OnClientCommandSurrenderAddon)


    local function ProcessStaggeredDrops()
        local statusTick, errTick = pcall(function()
            if not _G.OmniStaggeredDrops or #_G.OmniStaggeredDrops == 0 then return end
            local nowMS = (getTimestampMs() + 0)

            for i = #_G.OmniStaggeredDrops, 1, -1 do
                local task = _G.OmniStaggeredDrops[i]
                for j = #task.drops, 1, -1 do
                    local dropData = task.drops[j]
                    
                    if nowMS >= dropData.dropTime then
                        local cell = getCell()
                        if cell then
                            local zx, zy, zz = task.fallbackX, task.fallbackY, task.fallbackZ
                            local dirX, dirY = 1, 0
                            
                            local liveZ = nil
                            local zList = cell:getZombieList()
                            if zList then
                                for k = 0, zList:size() - 1 do
                                    local z = zList:get(k)
                                    if z and z:getHealth() > 0 then
                                        local zId = BanditUtils.GetZombieID(z)
                                        if zId and zId == task.zombieId then
                                            liveZ = z
                                            break
                                        end
                                    end
                                end
                            end

                            if liveZ then
                                zx, zy, zz = liveZ:getX(), liveZ:getY(), liveZ:getZ()
                                local fd = liveZ:getForwardDirection()
                                dirX, dirY = fd:getX(), fd:getY()
                                
                                task.fallbackX = zx
                                task.fallbackY = zy
                                task.fallbackZ = zz
                            end

                            local baseAngle = math.atan2(dirY, dirX)
                            local spreadAngle = math.pi / 2.0 
                            local startAngle = baseAngle - (spreadAngle / 2.0)
                            local angleStep = dropData.total > 1 and (spreadAngle / (dropData.total - 1)) or 0
                            
                            local itemAngle = startAngle + ((dropData.idx - 1) * angleStep)
                            local itemRadius = 0.65 + ZombRandFloat(-0.05, 0.05) 
                            
                            local absX = zx + (math.cos(itemAngle) * itemRadius)
                            local absY = zy + (math.sin(itemAngle) * itemRadius)

                            local sqX, sqY, sqZ = math.floor(absX), math.floor(absY), math.floor(zz)
                            local sq = cell:getGridSquare(sqX, sqY, sqZ)
                            
                            if not sq then
                                sqX, sqY = math.floor(zx), math.floor(zy)
                                sq = cell:getGridSquare(sqX, sqY, sqZ)
                            end

                            if sq then
                                local offsetX = math.max(0.01, math.min(0.99, absX - sqX))
                                local offsetY = math.max(0.01, math.min(0.99, absY - sqY))

                                local item = instanceItem(dropData.itemType)
                                if item then
                                    if item:IsWeapon() then
                                        item:setCondition(math.max(1, math.floor(item:getConditionMax() * ZombRandFloat(0.3, 1.0))))
                                        if item:isAimedFirearm() then
                                            item:setCurrentAmmoCount(ZombRand(0, item:getMaxAmmo() + 1))
                                            if item.setRoundChambered then item:setRoundChambered(ZombRand(2) == 1) end
                                        end
                                    end

                                    -- SANDBOX: Настройка лута (через шкалу Rarity: 1=Нет, 5=Нормально, 7=Очень много)
                                    if item:IsInventoryContainer() then
                                        local bagInv = item:getInventory()
                                        if bagInv then
                                            local lootAmount = SandboxVars.Bandits.Addon_SurrenderLootAmount
                                            if type(lootAmount) ~= "number" then lootAmount = 5 end
                                            
                                            local minItems, maxItems = 3, 7
                                            local minAmmo, maxAmmo = 1, 4
                                            
                                            if lootAmount <= 2 then     -- None / Insanely Rare
                                                minItems, maxItems = 0, 1
                                                minAmmo, maxAmmo = 0, 0
                                            elseif lootAmount == 3 or lootAmount == 4 then -- Extremely Rare / Rare
                                                minItems, maxItems = 1, 3
                                                minAmmo, maxAmmo = 0, 1
                                            elseif lootAmount == 5 then -- Normal
                                                minItems, maxItems = 3, 7
                                                minAmmo, maxAmmo = 1, 4
                                            elseif lootAmount >= 6 then -- Abundant / Very Abundant
                                                minItems, maxItems = 6, 12
                                                minAmmo, maxAmmo = 3, 8
                                            end

                                            -- Если лут = 1 (Нет), то вообще ничего не спавним
                                            if lootAmount > 1 then
                                                -- МАСШТАБНЫЙ ПУЛ ЛУТА ДЛЯ СДАВШИХСЯ БАНДИТОВ (v8.9)
                                                local lootTable = {
                                                    -- Напитки
                                                    "Base.WaterBottle", "Base.Pop", "Base.Pop2", "Base.Pop3", "Base.BeerCan", 
                                                    "Base.WhiskeyFull", "Base.Wine", "Base.Wine2",
                                                    -- Медицина
                                                    "Base.Bandage", "Base.Bandaid", "Base.Pills", "Base.PillsPainkiller", 
                                                    "Base.PillsVitamins", "Base.PillsSleeping", "Base.PillsBeta",
                                                    "Base.Disinfectant", "Base.AlcoholWipes", "Base.Antibiotics", "Base.SutureNeedle",
                                                    -- Еда (Консервы)
                                                    "Base.TinnedBeans", "Base.CannedCorn", "Base.CannedChili", "Base.TinnedSoup", 
                                                    "Base.CannedMushroomSoup", "Base.CannedPeaches", "Base.CannedPotato2", 
                                                    "Base.CannedSardines", "Base.CannedCornedBeef", "Base.TunaTin", "Base.CannedBolognese",
                                                    -- Еда (Снеки)
                                                    "Base.Crisps", "Base.Crisps2", "Base.Crisps3", "Base.Crisps4", "Base.Chocolate", 
                                                    "Base.Cereal", "Base.BeefJerky", "Base.Peanuts", "Base.GranolaBar", "Base.MintCandy",
                                                    -- Выживание и инструменты
                                                    "Base.Matches", "Base.Lighter", "Base.Battery", "Base.DuctTape", "Base.Twine", 
                                                    "Base.Nails", "Base.ScrewsBox", "Base.Woodglue", "Base.TinOpener", "Base.Screwdriver", 
                                                    "Base.Hammer", "Base.HuntingKnife", "Base.Flashlight", "Base.ElectronicsScrap",
                                                    "Base.ScrapMetal", "Base.ScrapWood",
                                                    -- Разное / Ценности
                                                    "Base.Cigarettes", "Base.Money", "Base.ComicBook", "Base.HottieZ", 
                                                    "Base.VideoGame", "Base.Tissue", "Base.Pen", "Base.Pencil", "Base.Eraser",
                                                    "Base.Ring", "Base.Necklace", "Base.WristWatch_Right_DigitalBlack"
                                                }
                                                
                                                for k = 1, ZombRand(minItems, maxItems + 1) do 
                                                    bagInv:AddItem(lootTable[ZombRand(#lootTable) + 1]) 
                                                end
                                                
                                                if dropData.primaryAmmo then
                                                    for k = 1, ZombRand(minAmmo, maxAmmo + 1) do 
                                                        bagInv:AddItem(dropData.primaryAmmo) 
                                                    end
                                                end
                                            end
                                        end
                                    end

                                    local fractionalZ = zz - sqZ
                                    if sq.AddWorldInventoryItem then
                                        sq:AddWorldInventoryItem(item, offsetX, offsetY, fractionalZ)
                                    elseif sq.addWorldInventoryItem then
                                        sq:addWorldInventoryItem(item, offsetX, offsetY, fractionalZ)
                                    end
                                    
                                    if dropData.isWeapon then sq:playSound("MeleeHitSurface") else sq:playSound("PutItemInBag") end
                                end
                            else
                                print("[Bandit Surrender] [DROP] Chunk unloaded. Dropping item safely to prevent deadlock.")
                            end
                        end
                        table.remove(task.drops, j)
                    end
                end
                
                if #task.drops == 0 then table.remove(_G.OmniStaggeredDrops, i) end
            end
        end)
        if not statusTick then 
            print("================================================================================")
            print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Event: ProcessStaggeredDrops")
            print("[Bandit Addon] ERROR TRACE: " .. tostring(errTick))
            print("================================================================================")
        end
    end
    Events.OnTick.Add(ProcessStaggeredDrops)

    _G.Omni_CheckSurrenderCondition = function(deadBandit, targetClan, killerType)
        local statusTrigger, errTrigger = pcall(function()
            -- SANDBOX: Глобальное отключение сдачи в плен
            if SandboxVars.Bandits.Addon_EnableSurrender == false then return end
            if _G.Bandit and _G.Bandit.IsPeacefulMode and _G.Bandit.IsPeacefulMode() then return end
            
            if not targetClan or targetClan == -1 then return end
            local dX, dY = deadBandit:getX(), deadBandit:getY()
            local dID = BanditUtils.GetZombieID(deadBandit)

            if not _G.OmniClanDeathTracker[targetClan] then _G.OmniClanDeathTracker[targetClan] = { deadCount = 0 } end
            _G.OmniClanDeathTracker[targetClan].deadCount = _G.OmniClanDeathTracker[targetClan].deadCount + 1
            
            if _G.OmniClanDeathTracker[targetClan].deadCount >= 1 then
                local aliveCount = 0
                local lastSurvivor = nil
                local cell = getCell()
                
                if cell and cell:getZombieList() then
                    local zList = cell:getZombieList()
                    for i = 0, zList:size() - 1 do
                        local z = zList:get(i)
                        if z and z:getHealth() > 0.05 then
                            local id = BanditUtils.GetZombieID(z)
                            if id ~= dID then
                                local dist = math.sqrt((z:getX() - dX)^2 + (z:getY() - dY)^2)
                                local bClan = nil
                                
                                if _G.GetBanditClusterData then
                                    local status, gmd = pcall(_G.GetBanditClusterData, id)
                                    if status and type(gmd) == "table" and gmd[id] then bClan = gmd[id].cid or gmd[id].clan end
                                end
                                
                                if (not bClan or bClan == "") and z.getModData then
                                    local bMD = z:getModData()
                                    if bMD then bClan = (bMD.brain and (bMD.brain.cid or bMD.brain.clan)) or bMD.omni_cached_cid or bMD.clan or bMD.Clan end
                                end
                                if (not bClan or bClan == "") and z.getVariableString then bClan = z:getVariableString("BanditClan") end

                                if bClan and tostring(bClan) == tostring(targetClan) and dist < 60 then
                                    aliveCount = aliveCount + 1
                                    lastSurvivor = z
                                end
                            end
                        end
                    end
                end

                if aliveCount == 1 and lastSurvivor then
                    print("[Bandit Surrender] [TRIGGER] Clan " .. tostring(targetClan) .. " has only 1 survivor. Surrendering!")
                    local sID = BanditUtils.GetZombieID(lastSurvivor)
                    
                    local sq = lastSurvivor:getCurrentSquare()
                    if sq and _G.GetBanditClusterData then
                        local status, gmd = pcall(_G.GetBanditClusterData, sID)
                        if status and type(gmd) == "table" and gmd[sID] then
                            local brain = gmd[sID]
                            
                            local wWeps, wBags, wOther = {}, {}, {}

                            if brain.weapons then
                                for _, slot in ipairs({"primary", "secondary"}) do
                                    if brain.weapons[slot] and brain.weapons[slot].name then table.insert(wWeps, brain.weapons[slot].name) end
                                end
                                if type(brain.weapons.melee) == "string" and brain.weapons.melee ~= "Base.BareHands" then table.insert(wWeps, brain.weapons.melee) end
                            end

                            if brain.bag and brain.bag.name then
                                table.insert(wBags, brain.bag.name)
                                brain.bag = nil
                            end
                            
                            if brain.clothing then
                                if brain.clothing.Back then
                                    table.insert(wOther, brain.clothing.Back)
                                    brain.clothing.Back = nil
                                end
                                for k, v in pairs(brain.clothing) do
                                    local vl = string.lower(v)
                                    if vl:find("bag") or vl:find("pack") or vl:find("holster") or vl:find("sling") or vl:find("satchel") or vl:find("duffel") or vl:find("case") or vl:find("pouch") then
                                        table.insert(wOther, v)
                                        brain.clothing[k] = nil
                                    end
                                end
                            end

                            local itemsToDrop = {}
                            for _, v in ipairs(wWeps) do table.insert(itemsToDrop, v) end
                            for _, v in ipairs(wBags) do table.insert(itemsToDrop, v) end
                            for _, v in ipairs(wOther) do table.insert(itemsToDrop, v) end
                            
                            local dropPayload = {}
                            local primaryAmmoForBag = (brain.weapons and brain.weapons.primary and brain.weapons.primary.ammoName) or nil
                            local nowMS = (getTimestampMs() + 0)
                            
                            local dropStartDelayMS = 1600 
                            local dropIntervalMS = 100

                            for idx, itemType in ipairs(itemsToDrop) do
                                table.insert(dropPayload, {
                                    itemType = itemType,
                                    primaryAmmo = primaryAmmoForBag,
                                    isWeapon = (idx <= #wWeps),
                                    idx = idx,
                                    total = #itemsToDrop,
                                    dropTime = nowMS + dropStartDelayMS + ((idx - 1) * dropIntervalMS)
                                })
                            end

                            if #dropPayload > 0 then
                                table.insert(_G.OmniStaggeredDrops, {
                                    zombieId = sID, drops = dropPayload,
                                    fallbackX = lastSurvivor:getX(), fallbackY = lastSurvivor:getY(), fallbackZ = lastSurvivor:getZ()
                                })
                            end

                            local inv = lastSurvivor:getInventory()
                            if inv then inv:clear() end
                            if lastSurvivor.clearItemsToSpawnAtDeath then lastSurvivor:clearItemsToSpawnAtDeath() end

                            brain.weapons = { primary = {bulletsLeft=0, magCount=0}, secondary = {bulletsLeft=0, magCount=0}, melee = "Base.BareHands" }
                            brain.loot = {}
                            brain.isSurrendering = true
                            if _G.TransmitBanditCluster then _G.TransmitBanditCluster(sID) end
                        end
                    end

                    sendServerCommand("BanditAddon", "ForceSurrender", { id = sID })
                end
            end
        end)
        if not statusTrigger then 
            print("================================================================================")
            print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Function: Omni_CheckSurrenderCondition")
            print("[Bandit Addon] ERROR TRACE: " .. tostring(errTrigger))
            print("================================================================================")
        end
    end
end

-- ==============================================================================
-- СЕТЕВОЙ КОД (КЛИЕНТ): Хак Модели и Визуала + Контекстное меню
-- ==============================================================================
if isClient() then
    local function StripGhostBags(z)
        local status, err = pcall(function()
            local hv = z:getHumanVisual()
            if not hv then return end
            local bodyVisuals = hv:getBodyVisuals()
            if not bodyVisuals then return end
            
            local toRemove = {}
            for i = 0, bodyVisuals:size() - 1 do
                local bodyVis = bodyVisuals:get(i)
                if bodyVis then
                    local itemName = bodyVis:getItemType()
                    if itemName then
                        local vl = string.lower(itemName)
                        if vl:find("bag") or vl:find("pack") or vl:find("holster") or vl:find("sling") or vl:find("satchel") or vl:find("duffel") or vl:find("case") or vl:find("pouch") then
                            table.insert(toRemove, itemName)
                        end
                    end
                end
            end
            for _, name in ipairs(toRemove) do hv:removeBodyVisualFromItemType(name) end
        end)
        if not status then print("[Bandit Surrender] [VISUAL STRIP ERROR] " .. tostring(err)) end
    end

    local function LockSurrenderedAI()
        local statusAI, errAI = pcall(function()
            if not BanditBrain or not Bandit then return end 

            local cell = getCell()
            if not cell then return end
            local zList = cell:getZombieList()
            if not zList then return end
            
            for i = 0, zList:size() - 1 do
                local z = zList:get(i)
                if z and z:getHealth() > 0 and z:getVariableBoolean("Bandit") then
                    local md = z:getModData()
                    local brain = BanditBrain.Get(z)
                    if brain then
                        
                        -- ЛОГИКА ДЛЯ СДАЮЩИХСЯ В ПЛЕН
                        if md and md.isSurrendering and brain.isSurrendering then
                            if brain.program.name ~= "Surrender" then
                                brain.program.name = "Surrender"
                                brain.program.stage = "Wait"
                            end
                            
                            brain.bag = nil
                            brain.loot = {}
                            if brain.clothing then
                                brain.clothing.Back = nil
                                for k, v in pairs(brain.clothing) do
                                    local vl = string.lower(v)
                                    if vl:find("bag") or vl:find("pack") or vl:find("holster") or vl:find("sling") or vl:find("satchel") or vl:find("duffel") or vl:find("case") or vl:find("pouch") then
                                        brain.clothing[k] = nil
                                    end
                                end
                            end
                            brain.weapons = { primary = {bulletsLeft=0, magCount=0}, secondary = {bulletsLeft=0, magCount=0}, melee = "Base.BareHands" }
                            
                            if z.getAttachedItems then z:getAttachedItems():clear() end
                            local wornItems = z:getWornItems()
                            if wornItems and wornItems:size() > 0 then
                                for w = wornItems:size() - 1, 0, -1 do
                                    local wornObj = wornItems:get(w)
                                    local wItem = wornObj and wornObj:getItem()
                                    if wItem and (wItem:IsInventoryContainer() or wItem:IsWeapon()) then z:removeWornItem(wItem) end
                                end
                            end
                            
                            z:setPrimaryHandItem(nil)
                            z:setSecondaryHandItem(nil)
                            StripGhostBags(z)

                            local inv = z:getInventory()
                            if inv then inv:clear() end
                            if z.clearItemsToSpawnAtDeath then z:clearItemsToSpawnAtDeath() end

                            -- ФИКС АНИМАЦИИ СБРОСА: Позволяем проиграться анимации LootLow (сброс вещей)
                            if brain.tasks and #brain.tasks > 0 then
                                local t = brain.tasks[1]
                                if t.action ~= "Time" or (t.anim ~= "Surrender" and t.anim ~= "LootLow") then
                                    brain.tasks = {} -- ЖЕСТКИЙ СБРОС, очищаем все кроме нужных анимаций
                                    table.insert(brain.tasks, {action="Time", anim="Surrender", time=300, lock=true})
                                end
                            else
                                brain.tasks = {} -- ЖЕСТКИЙ СБРОС
                                -- Если очередь пуста, мы НЕ добавляем LootLow заново. Только поддерживаем Surrender.
                                table.insert(brain.tasks, {action="Time", anim="Surrender", time=300, lock=true})
                            end

                            if BanditBrain.Update then BanditBrain.Update(z, brain) end
                        end
                        
                        -- ЛОГИКА ДЛЯ ОСВОБОЖДЕННЫХ (БЕГСТВО)
                        if brain.program and brain.program.name == "Surrender" and brain.program.stage == "Escape" then
                            -- ХАК ДВИЖКА (АНТИ-ЗАИКАНИЕ): BanditUpdate.lua делает невраждебных бандитов "бесполезными" (useless) 
                            -- в радиусе 3 тайлов от игрока (ManageSocialDistance). Это вызывает заикание и заморозку.
                            -- Принудительно отключаем эту блокировку, чтобы бегство работало плавно!
                            if z:isUseless() then
                                z:setUseless(false)
                            end
                            z:setVariable("BanditWalkType", "Run")
                        end
                        
                    end
                end
            end
        end)
        
        if not statusAI then 
            print("================================================================================")
            print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Event: LockSurrenderedAI Tick")
            print("[Bandit Addon] ERROR TRACE: " .. tostring(errAI))
            print("================================================================================")
        end
    end
    Events.OnTick.Add(LockSurrenderedAI)

    local function OnFillWorldObjectContextMenuSurrender(player, context, worldobjects, test)
        local playerObj = getSpecificPlayer(player)
        if not playerObj then return end

        local clickedSquare = nil
        for _, v in ipairs(worldobjects) do
            clickedSquare = v:getSquare()
            break
        end
        if not clickedSquare then return end

        local banditsToRelease = {}

        local statusMenu, errMenu = pcall(function()
            for x = -1, 1 do
                for y = -1, 1 do
                    local sq = getCell():getGridSquare(clickedSquare:getX() + x, clickedSquare:getY() + y, clickedSquare:getZ())
                    if sq then
                        local movingObjects = sq:getMovingObjects()
                        for i = 0, movingObjects:size() - 1 do
                            local obj = movingObjects:get(i)
                            if instanceof(obj, "IsoZombie") and obj:getVariableBoolean("Bandit") then
                                local md = obj:getModData()
                                if md.isSurrendering then
                                    table.insert(banditsToRelease, obj)
                                end
                            end
                        end
                    end
                end
            end
        end)
        if not statusMenu then 
            print("================================================================================")
            print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | Event: ContextMenu")
            print("[Bandit Addon] ERROR TRACE: " .. tostring(errMenu))
            print("================================================================================")
        end

        if #banditsToRelease > 0 then
            -- ФИКС ПЕРЕВОДА ИНТЕРФЕЙСА (используем ключи из IG_UI.json)
            local option = context:addOption(getText("IGUI_Bandits_ReleaseBandit") or "Release Survivor")
            local subMenu = ISContextMenu:getNew(context)
            context:addSubMenu(option, subMenu)

            for _, bandit in ipairs(banditsToRelease) do
                local bID = BanditUtils.GetCharacterID(bandit)
                -- Используем локализованное слово Бандит
                local banditLabel = getText("IGUI_Bandits_BanditLabel") or "Survivor"
                
                subMenu:addOption(banditLabel .. " [" .. tostring(bID) .. "]", playerObj, function()
                    local args = { id = bID }
                    sendClientCommand(playerObj, 'BanditAddon', 'ReleaseBandit', args)
                end)
            end
        end
    end
    Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenuSurrender)

    local function OnServerCommandSurrender(module, command, args)
        if module == "BanditAddon" then
            if command == "ForceSurrender" then
                local statusCmd, errCmd = pcall(function()
                    local targetID = args.id
                    local cell = getCell()
                    if not cell then return end
                    
                    local zList = cell:getZombieList()
                    if not zList then return end
                    
                    local victim = nil
                    for i = 0, zList:size() - 1 do
                        local z = zList:get(i)
                        if z and z:getHealth() > 0 then
                            local zId = BanditUtils.GetCharacterID(z)
                            if zId and tostring(zId) == tostring(targetID) then
                                victim = z
                                break
                            end
                        end
                    end
                    
                    if not victim then return end
                    
                    if victim.getModData then victim:getModData().isSurrendering = true end
                    local victimBrain = BanditBrain.Get(victim)
                    if not victimBrain then return end
                    
                    victimBrain.isSurrendering = true
                    victimBrain.bag = nil
                    victimBrain.loot = {}
                    
                    -- МГНОВЕННЫЙ ПЕРЕХВАТ ПАЛАЧЕЙ
                    local execClan = nil
                    local execFound = false
                    local originalClan = victimBrain.clan
                    
                    for i = 0, zList:size() - 1 do
                        local enemy = zList:get(i)
                        if enemy and enemy:getHealth() > 0 and enemy ~= victim and enemy:getVariableBoolean("Bandit") then
                            local eBrain = BanditBrain.Get(enemy)
                            if eBrain then
                                
                                local isEnemy = false
                                if execClan then
                                    isEnemy = (execClan and eBrain.clan == execClan)
                                else
                                    local tempBrain = {clan = originalClan, hostile = victimBrain.hostile, hostileP = victimBrain.hostileP, loyal = false}
                                    isEnemy = BanditUtils.AreEnemies(tempBrain, eBrain)
                                end
                                
                                if isEnemy then
                                    local dist = BanditUtils.DistTo(victim:getX(), victim:getY(), enemy:getX(), enemy:getY())
                                    if dist < 45 and enemy:CanSee(victim) then
                                        
                                        -- SANDBOX: Проверка на включенность казни
                                        if SandboxVars.Bandits.Addon_EnableExecution ~= false then
                                            enemy:clearAggroList()
                                            enemy:setTarget(nil)
                                            if Bandit.ClearTasks then Bandit.ClearTasks(enemy) end
                                            
                                            if not execFound then
                                                execFound = true
                                                execClan = eBrain.clan
                                                
                                                victimBrain.executionerClan = execClan
                                                victimBrain.originalClan = originalClan
                                                victimBrain.clan = execClan
                                                victim:setVariable("BanditClan", tostring(execClan))
                                                
                                                eBrain.isExecutioner = true
                                                eBrain.targetSurrendererId = victimBrain.id
                                                eBrain.storedHostile = eBrain.hostile
                                                eBrain.storedHostileP = eBrain.hostileP
                                                eBrain.hostile = false
                                                eBrain.hostileP = false
                                                
                                                Bandit.SetProgram(enemy, "ExecuteSurrendered")
                                                Bandit.SetProgramStage(enemy, "Approach")
                                                if BanditBrain.Update then BanditBrain.Update(enemy, eBrain) end
                                                print("[Bandit Surrender] [INSTA-INTERCEPT] ID: " .. tostring(eBrain.id) .. " designated as Executioner.")
                                            elseif execClan and eBrain.clan == execClan then
                                                eBrain.targetSurrendererId = victimBrain.id
                                                if eBrain.storedHostile == nil then
                                                    eBrain.storedHostile = eBrain.hostile
                                                    eBrain.storedHostileP = eBrain.hostileP
                                                    eBrain.hostile = false
                                                    eBrain.hostileP = false
                                                end
                                                Bandit.SetProgram(enemy, "ExecuteSurrendered")
                                                Bandit.SetProgramStage(enemy, "Overwatch")
                                                if BanditBrain.Update then BanditBrain.Update(enemy, eBrain) end
                                                print("[Bandit Surrender] [INSTA-INTERCEPT] ID: " .. tostring(eBrain.id) .. " designated as Overwatch.")
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if victimBrain.clothing then
                        victimBrain.clothing.Back = nil
                        for k, v in pairs(victimBrain.clothing) do
                            local vl = string.lower(v)
                            if vl:find("bag") or vl:find("pack") or vl:find("holster") or vl:find("sling") or vl:find("satchel") or vl:find("duffel") or vl:find("case") or vl:find("pouch") then
                                victimBrain.clothing[k] = nil
                            end
                        end
                    end

                    victimBrain.weapons = { primary = {bulletsLeft=0, magCount=0}, secondary = {bulletsLeft=0, magCount=0}, melee = "Base.BareHands" }
                    
                    local hv = victim:getHumanVisual()
                    if hv then hv:setSkinTextureName("Bypass_To_Force_Update") end
                    if Bandit.ApplyVisuals then Bandit.ApplyVisuals(victim, victimBrain) end
                    
                    if victim.getAttachedItems then victim:getAttachedItems():clear() end
                    local wornItems = victim:getWornItems()
                    if wornItems and wornItems:size() > 0 then
                        for w = wornItems:size() - 1, 0, -1 do
                            local wornObj = wornItems:get(w)
                            local wItem = wornObj and wornObj:getItem()
                            if wItem and (wItem:IsInventoryContainer() or wItem:IsWeapon()) then victim:removeWornItem(wItem) end
                        end
                    end
                    StripGhostBags(victim)
                    
                    local inv = victim:getInventory()
                    if inv then inv:clear() end
                    
                    victim:setPrimaryHandItem(nil)
                    victim:setSecondaryHandItem(nil)
                    if victim.resetEquippedHandsModels then victim:resetEquippedHandsModels() end
                    if victim.clearItemsToSpawnAtDeath then victim:clearItemsToSpawnAtDeath() end
                    
                    victim:resetModelNextFrame()
                    victim:resetModel()

                    if Bandit.ClearTasks then Bandit.ClearTasks(victim) end
                    victim:clearAggroList()
                    victim:setTarget(nil)
                    
                    -- ЖЕСТКИЙ СБРОС И ЗАПУСК АНИМАЦИИ СБРОСА ПРЕДМЕТОВ (ЕДИНОРАЗОВО)
                    victimBrain.tasks = {}
                    table.insert(victimBrain.tasks, {action="Time", anim="LootLow", time=120, lock=true})
                    table.insert(victimBrain.tasks, {action="Time", anim="Surrender", time=300, lock=true})
                    
                    if BanditBrain.Update then BanditBrain.Update(victim, victimBrain) end
                    
                    -- Используем нашу программу для контроля
                    victimBrain.program.name = "Surrender"
                    victimBrain.program.stage = "Wait"
                    
                    if SandboxVars.Bandits.General_Captions then
                        victim:addLineChatElement("I GIVE UP! DON'T SHOOT! TAKE EVERYTHING!", 0.9, 0.9, 0.1)
                    end
                    if Bandit.Say then Bandit.Say(victim, "HIT", true) end
                    
                end)
                if not statusCmd then 
                    print("================================================================================")
                    print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | ServerCommand: ForceSurrender")
                    print("[Bandit Addon] ERROR TRACE: " .. tostring(errCmd))
                    print("================================================================================")
                end
            
            elseif command == "ReleasedVoice" then
                local statusRV, errRV = pcall(function()
                    local targetID = tonumber(args.id)
                    local cell = getCell()
                    if not cell then return end
                    local zList = cell:getZombieList()
                    if not zList then return end
                    
                    for i = 0, zList:size() - 1 do
                        local z = zList:get(i)
                        if z and z:getHealth() > 0 then
                            local zId = BanditUtils.GetCharacterID(z)
                            if zId and tostring(zId) == tostring(targetID) then
                                
                                -- ФИКС МИЛОСЕРДИЯ И ЗАВИСШЕЙ АНИМАЦИИ
                                if z.getModData then z:getModData().isSurrendering = false end
                                local brain = BanditBrain.Get(z)
                                if brain then
                                    brain.isSurrendering = false
                                    -- Запускаем НАШУ стадию побега, а не оригинальную
                                    brain.program.name = "Surrender"
                                    brain.program.stage = "Escape"
                                    brain.hostile = false
                                    brain.hostileP = false
                                    
                                    -- ЖЕСТКИЙ СБРОС ЗАДАЧ (уничтожает заблокированные анимации)
                                    brain.tasks = {}
                                    
                                    -- Заставляем бежать
                                    z:setVariable("BanditWalkType", "Run")
                                    z:setWalkType("Run")
                                    
                                    if BanditBrain.Update then BanditBrain.Update(z, brain) end
                                end

                                z:clearAggroList()
                                z:setTarget(nil)
                                
                                -- Мгновенно размораживаем бандита и сбрасываем состояние движка
                                z:setBumpDone(true)
                                if ZombieIdleState then z:changeState(ZombieIdleState.instance()) end

                                if SandboxVars.Bandits.General_Captions then
                                    z:addLineChatElement("I'm out of here! I owe you one!", 0.1, 0.8, 0.1)
                                end
                                if Bandit.Say then Bandit.Say(z, "SPOTTED", true) end
                                break
                            end
                        end
                    end
                    
                    -- Клиентский сброс палачей
                    for i = 0, zList:size() - 1 do
                        local enemy = zList:get(i)
                        if enemy and enemy:getHealth() > 0 then
                            local eBrain = BanditBrain.Get(enemy)
                            if eBrain and eBrain.isExecutioner and tostring(eBrain.targetSurrendererId) == tostring(targetID) then
                                eBrain.isExecutioner = false
                                eBrain.targetSurrendererId = nil
                                if eBrain.storedHostile ~= nil then
                                    eBrain.hostile = eBrain.storedHostile
                                    eBrain.hostileP = eBrain.storedHostileP
                                    eBrain.storedHostile = nil
                                    eBrain.storedHostileP = nil
                                end
                                eBrain.tasks = {}
                                enemy:clearAggroList()
                                enemy:setTarget(nil)
                                if BanditBrain.Update then BanditBrain.Update(enemy, eBrain) end
                            end
                        end
                    end
                    
                end)
                if not statusRV then 
                    print("================================================================================")
                    print("[Bandit Addon] [FATAL EXCEPTION] Module: ZPSurrender | ServerCommand: ReleasedVoice")
                    print("[Bandit Addon] ERROR TRACE: " .. tostring(errRV))
                    print("================================================================================")
                end
            end
        end
    end
    Events.OnServerCommand.Add(OnServerCommandSurrender)
end

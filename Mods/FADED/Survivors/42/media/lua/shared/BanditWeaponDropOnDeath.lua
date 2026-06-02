-- ==============================================================================
-- Название: BanditWeaponDropOnDeath.lua
-- Описание: Аддон для мода Bandits (B42.14.1 MP). Версия 125 (SMART PURGE + MP SYNC).
-- Функционал: Сброс оружия, рации, вызов подкрепления ТОГО ЖЕ КЛАНА.
--             ВЕРСИЯ 125: Исправлен баг "цепной реакции" клонированных раций
--             у призванных волн. Истинный рандом на сервере и фикс невидимых
--             раций в мультиплеере (принудительная выдача Network ID).
-- ИНТЕГРАЦИЯ: Поддержка системы ZPSurrender.lua (Сдача в плен при потере сквада).
-- ВАЖНО:      Этот файл должен лежать в lua/shared/ для работы графики у клиентов!
-- ==============================================================================

-- ==============================================================================
-- КРИТИЧЕСКИЕ ХОТФИКСЫ ДВИЖКА (УБИЙЦА NPE КРАШЕЙ KAHLUA - SHARED БЛОК)
-- ==============================================================================
if not _G.OMNI_INSTANCE_HOOKED then
    local original_instanceItem = _G.instanceItem
    _G.instanceItem = function(itemType)
        if type(itemType) ~= "string" then return original_instanceItem(itemType) end
        local item = original_instanceItem(itemType)
        -- Попытка починить сломанный ID модового оружия (добавляем Base., если модуля нет)
        if not item and not string.find(itemType, "%.") then
            item = original_instanceItem("Base." .. itemType)
        end
        if not item then
            print("=====================================================")
            print("[Bandit Weapon Drop] [CRITICAL HOTFIX]")
            print("Prevented JVM NPE! Replaced missing item: " .. tostring(itemType) .. " with Base.BaseballBat")
            print("=====================================================")
            return original_instanceItem("Base.BaseballBat")
        end
        return item
    end
    _G.OMNI_INSTANCE_HOOKED = true
end

local function ApplyBanditsCoreHotfix()
    local BComp = _G.BanditCompatibility
    if BComp then
        -- 1. Фикс функции AddId
        if type(BComp.AddId) == "function" and not BComp.OMNI_HOTFIX_APPLIED then
            local originalAddId = BComp.AddId
            BComp.AddId = function(a, b, c, ...)
                if a == nil then return end 
                local status, err = pcall(originalAddId, a, b, c, ...)
                if not status then
                    print("=====================================================")
                    print("[Bandit Weapon Drop] [HOTFIX ERROR]")
                    print("BanditCompatibility.AddId failed.")
                    print("Error details: " .. tostring(err))
                    print("=====================================================")
                end
            end
            BComp.OMNI_HOTFIX_APPLIED = true
        end

        -- 2. Фикс функции InstanceItem (Защита от краша ManageCombat -> getMaxRange)
        if type(BComp.InstanceItem) == "function" and not BComp.OMNI_INSTANCE_ITEM_HOOKED then
            local original_BCompInstance = BComp.InstanceItem
            BComp.InstanceItem = function(itemType)
                if type(itemType) ~= "string" then return original_BCompInstance(itemType) end
                local item = original_BCompInstance(itemType)
                if not item and not string.find(itemType, "%.") then
                    item = original_BCompInstance("Base." .. itemType)
                end
                if not item then
                    print("[Bandit Addon] [HOTFIX] BanditCompatibility.InstanceItem returned nil for: " .. tostring(itemType) .. ". Returning Base.BaseballBat fallback.")
                    return original_BCompInstance("Base.BaseballBat")
                end
                return item
            end
            BComp.OMNI_INSTANCE_ITEM_HOOKED = true
        end
    end
end
Events.OnInitGlobalModData.Add(ApplyBanditsCoreHotfix)
ApplyBanditsCoreHotfix()

-- ==============================================================================
-- [V116] ГЛОБАЛЬНЫЙ ПРЕДОХРАНИТЕЛЬ ОТ ZERO-VECTOR CRASH (АНТИ-МАГНИТ ДЛЯ ПЛЕННЫХ)
-- ==============================================================================
-- Перехватывает зомби до того, как оригинальный мод попытается их повернуть к жертве.
local function AntiZeroVectorCrash(zombie)
    if not zombie then return end
    
    -- ОПТИМИЗАЦИЯ: Выполняем дорогой код ТОЛЬКО для бандитов
    local isBandit = zombie:getVariableBoolean("Bandit") or zombie:getVariableString("Bandit") == "true" or zombie:getVariableString("isBandit") == "true"
    if not isBandit then return end
    
    local target = zombie:getTarget()
    if target then
        local zx = zombie:getX()
        local tx = target:getX()
        -- Если X и Y совпадают ИДЕАЛЬНО (до флоата) - это гарантированный вылет Java-движка
        if zx == tx then
            local zy = zombie:getY()
            local ty = target:getY()
            if zy == ty then
                -- Делаем микро-сдвиг (на 1 сантиметр), чтобы вектор направления существовал
                zombie:setX(zx + 0.01)
                zombie:setY(zy + 0.01)
            end
        end
    end
end
Events.OnZombieUpdate.Add(AntiZeroVectorCrash)

-- ==============================================================================
-- SHARED БЛОК (Кэширование урона для Мультиплеера - Работает на Клиенте и Сервере)
-- ==============================================================================

-- ГЛОБАЛЬНЫЙ МЕТОД РАСПОЗНАВАНИЯ СУЩНОСТИ (PLAYER / BANDIT / ZOMBIE)
local function EvaluateEntity(ent)
    if not ent then return "unknown" end
    
    -- [ФИКС V86] Критический обход костыля мода Bandits!
    local statusFake, fakeZ = pcall(function() return getCell():getFakeZombieForHit() end)
    if statusFake and fakeZ and ent == fakeZ then 
        return "unknown" 
    end

    if instanceof(ent, "IsoPlayer") then return "player" end
    if instanceof(ent, "IsoZombie") then
        -- 1. Ванильные переменные
        if ent:getVariableBoolean("Bandit") then return "bandit" end
        if ent:getVariableString("Bandit") == "true" then return "bandit" end
        if ent:getVariableString("isBandit") == "true" then return "bandit" end
        if ent:getVariableString("bBandit") == "true" then return "bandit" end
        
        -- 2. ModData
        local md = ent:getModData()
        if md and (md.is_omni_bandit or md.isBandit or md.bandit or md.Bandit) then return "bandit" end
        
        -- 3. Проверка через Мозги (Brain)
        if _G.BanditBrain and type(_G.BanditBrain.Get) == "function" then
            local status, brain = pcall(_G.BanditBrain.Get, ent)
            if status and type(brain) == "table" and brain.cid then return "bandit" end
        end
        
        -- 4. Проверка через Глобальный Кластер
        local id = ent:getPersistentOutfitID()
        if id and id ~= 0 and _G.GetBanditClusterData then
            local status, gmd = pcall(_G.GetBanditClusterData, id)
            if status and type(gmd) == "table" and gmd[id] then return "bandit" end
        end

        -- 5. Абсолютно точная улика: если сущность держит огнестрел/оружие в руках, это 100% бандит
        local handItem = ent:getPrimaryHandItem()
        if handItem and handItem:IsWeapon() then
            return "bandit"
        end
        
        return "zombie"
    end
    return "unknown"
end

-- КЭШИРОВАНИЕ ДАННЫХ ПРИ УРОНЕ (СИНХРОНИЗАЦИЯ С СЕРВЕРОМ И ТАЙМЕР ЖИЗНИ)
local function CacheAttackerData(victim, attacker)
    if not victim or not instanceof(victim, "IsoZombie") then return end
    if not attacker then return end
    
    local md = victim:getModData()
    if md then
        local kType = EvaluateEntity(attacker)
        if kType ~= "unknown" then
            
            -- Получаем Клан атакующего (если это бандит) для исключения Friendly Fire
            local aClan = -1
            if kType == "bandit" then
                local aMD = attacker:getModData()
                aClan = aMD.omni_cached_cid or aMD.clan or aMD.cid or attacker:getVariableString("BanditClan") or -1
            end

            -- Обновляем кэш и записываем синхронизированное время (WorldAgeHours)
            local currentHours = getGameTime():getWorldAgeHours()
            md.omni_last_attacker_type = kType
            md.omni_last_attacker_clan = tostring(aClan)
            md.omni_last_attacker_time = currentHours
            
            -- СИНХРОНИЗАЦИЯ СЕРВЕРА И КЛИЕНТА (Оптимизация от Network Flooding)
            if isClient() then
                local lastSync = md.omni_last_sync_time or 0
                -- Ограничиваем сетевой флуд: 1 пакет в секунду (через ин-гейм часы)
                -- 1 секунда = (24 / (getMinutesPerDay() * 60)) часов
                local syncCooldownHours = 24 / (getGameTime():getMinutesPerDay() * 60)
                
                if (currentHours - lastSync) > syncCooldownHours then
                    md.omni_last_sync_time = currentHours
                    victim:transmitModData()
                    print("[Bandit Weapon Drop] [CLIENT CACHE] Transmitted attacker: " .. tostring(kType) .. " (Clan: " .. tostring(aClan) .. ") for victim ID: " .. tostring(victim:getPersistentOutfitID()))
                end
            else
                print("[Bandit Weapon Drop] [SERVER CACHE] Saved attacker: " .. tostring(kType) .. " (Clan: " .. tostring(aClan) .. ") for victim ID: " .. tostring(victim:getPersistentOutfitID()))
            end
        end
    end
end

-- Хук на ближний бой и толчки
local function OnHitZombieWrapper(zombie, attacker, bodyPart, weapon)
    -- 1. Сохраняем данные самой жертвы-бандита
    local id = zombie:getPersistentOutfitID()
    if id and id ~= 0 and _G.GetBanditClusterData then
        local status, gmd = pcall(_G.GetBanditClusterData, id)
        if status and type(gmd) == "table" and gmd[id] then
            local md = zombie:getModData()
            if md then
                md.is_omni_bandit = true
                md.omni_cached_cid = gmd[id].cid
                md.omni_cached_program = gmd[id].program and gmd[id].program.name
                
                -- Отправляем сохраненный кластер на сервер, если мы клиент (С защитой от флуда)
                if isClient() then
                    local currentHours = getGameTime():getWorldAgeHours()
                    local lastSync = md.omni_last_cluster_sync_time or 0
                    local syncCooldownHours = 24 / (getGameTime():getMinutesPerDay() * 60)
                    
                    if (currentHours - lastSync) > syncCooldownHours then
                        md.omni_last_cluster_sync_time = currentHours
                        zombie:transmitModData()
                    end
                end
            end
        end
    end
    
    -- 2. Кэшируем тип атакующего на случай смерти
    CacheAttackerData(zombie, attacker)
end
Events.OnHitZombie.Add(OnHitZombieWrapper)

-- Хук на огнестрельное оружие (в мультиплеере срабатывает ТОЛЬКО на клиенте стрелка)
local function OnWeaponHitWrapper(wielder, victim, weapon, damage)
    CacheAttackerData(victim, wielder)
end
Events.OnWeaponHitCharacter.Add(OnWeaponHitWrapper)


-- ==============================================================================
-- СЕРВЕРНАЯ ЧАСТЬ (Генерация, ИИ, Дроп, Логика)
-- ==============================================================================
if isServer() then

    -- Безопасное получение профилей клана
    local function getPopulatedClanData(targetClan)
        local clanProfiles = nil
        local keys = {}
        
        print("[Bandit Weapon Drop] [CLAN DATA] Attempting to fetch profiles for Clan ID: " .. tostring(targetClan))
        local status, err = pcall(function() clanProfiles = _G.BanditCustom.GetFromClan(targetClan) end)
        if not status then 
            print("=====================================================")
            print("[Bandit Weapon Drop] [CLAN ERROR CRITICAL]")
            print("Failed to GetFromClan for ID " .. tostring(targetClan))
            print("Trace: " .. tostring(err)) 
            print("=====================================================")
        end
        
        if type(clanProfiles) == "table" then
            for k in pairs(clanProfiles) do table.insert(keys, k) end
        end
        
        if #keys > 0 then 
            print("[Bandit Weapon Drop] [CLAN DATA] Success. Found " .. tostring(#keys) .. " profiles for Clan " .. tostring(targetClan))
            return targetClan, clanProfiles, keys 
        end
        
        -- Авто-поиск рабочего клана, если текущий пуст
        print("[Bandit Weapon Drop] [CLAN DATA] Clan " .. tostring(targetClan) .. " is empty! Auto-searching for fallback clan...")
        local allClans = nil
        local statusAll, errAll = pcall(function() allClans = _G.BanditCustom.ClanGetAll() end)
        if not statusAll then 
            print("[Bandit Weapon Drop] [CLAN ERROR] Failed to ClanGetAll: " .. tostring(errAll)) 
        end

        if type(allClans) == "table" then
            for tempCid, _ in pairs(allClans) do
                local tempOpts = nil
                local statusTemp, errTemp = pcall(function() tempOpts = _G.BanditCustom.GetFromClan(tempCid) end)
                if not statusTemp then 
                    print("[Bandit Weapon Drop] [CLAN ERROR] Failed to GetFromClan(temp): " .. tostring(errTemp)) 
                end
                
                local tKeys = {}
                if type(tempOpts) == "table" then
                    for k in pairs(tempOpts) do table.insert(tKeys, k) end
                end
                if #tKeys > 0 then
                    print("[Bandit Weapon Drop] [CLAN DATA] Switched empty Clan to working fallback Clan ID: " .. tostring(tempCid))
                    return tempCid, tempOpts, tKeys
                end
            end
        end
        return targetClan, {}, {}
    end

    local OmniSpawnQueue = {}
    local OmniRadioQueue = {} -- Очередь для задержки радиоэфира (Suspense)

    Events.OnTick.Add(function()
        -- 1. ОБРАБОТКА ОЧЕРЕДИ РАДИОЭФИРА (SUSPENSE TIMER)
        if #OmniRadioQueue > 0 then
            for i = #OmniRadioQueue, 1, -1 do
                local rTask = OmniRadioQueue[i]
                rTask.delay = rTask.delay - 1
                
                if rTask.delay <= 0 then
                    print("[Bandit Weapon Drop] [RADIO] Suspense ended. Broadcasting to sector!")
                    
                    -- Рассылаем команду на рендер и звук всем клиентам
                    sendServerCommand("BanditAddon", "RadioCall", {
                        x = rTask.rX,
                        y = rTask.rY,
                        z = rTask.rZ,
                        text = rTask.text,
                        volume = rTask.volume
                    })
                    
                    -- Шум сервера (привлечение зомби)
                    addSound(nil, rTask.rX, rTask.rY, rTask.rZ, 50, 50)

                    -- Если это НЕ отступление, ставим в очередь спавн подкрепления (еще +1.5с задержки)
                    if not rTask.isRetreat then
                        table.insert(OmniSpawnQueue, rTask.spawnTask)
                    else
                        print("[Bandit Weapon Drop] [BACKUP ABORTED] Retreat order given! HQ abandoned the sector. No backup will spawn.")
                    end
                    
                    table.remove(OmniRadioQueue, i)
                end
            end
        end

        -- 2. ОБРАБОТКА ОЧЕРЕДИ СПАВНА
        if #OmniSpawnQueue > 0 then
            for i = #OmniSpawnQueue, 1, -1 do
                local task = OmniSpawnQueue[i]
                task.delay = task.delay - 1
                
                if task.delay <= 0 then
                    print("-----------------------------------------------------")
                    print("[Bandit Weapon Drop] [SPAWN] Executing Backup Spawner")
                    print("Clan: " .. tostring(task.targetClan) .. " | Units: " .. tostring(task.numBandits))
                    print("-----------------------------------------------------")
                    
                    -- Вытягиваем профили и одежду клана
                    local workingClan, clanProfiles, profileKeys = getPopulatedClanData(task.targetClan)
                    task.targetClan = workingClan
                    
                    -- Получаем глобальные данные клана для определения враждебности
                    local clanData = nil
                    local statusClanData, errClanData = pcall(function() clanData = _G.BanditCustom.ClanGet(task.targetClan) end)
                    if not statusClanData then 
                        print("[Bandit Weapon Drop] [SPAWN ERROR] Failed to ClanGet: " .. tostring(errClanData)) 
                    end
                    
                    local isFriendly = clanData and clanData.spawn and clanData.spawn.friendly or false
                    local peacefulMode = _G.Bandit and _G.Bandit.IsPeacefulMode and _G.Bandit.IsPeacefulMode()
                    
                    local outfit = "Naked" .. (1 + ZombRand(101))
                    local bList = addZombiesInOutfit(task.spawnX, task.spawnY, task.spawnZ, task.numBandits, outfit, 50)
                    
                    if bList and bList:size() > 0 then
                        print("[Bandit Weapon Drop] [SPAWN] Entity creation successful. Injecting AI logic...")
                        
                        -- Генерируем громкий звук на месте рации, чтобы подкрепление сразу бежало туда
                        addSound(nil, task.radioX, task.radioY, task.radioZ, 200, 200)

                        for j=0, bList:size()-1 do
                            local newBandit = bList:get(j)
                            if newBandit then
                                local status, err = pcall(function()
                                    -- Получение профиля (одежда, внешность, оружие)
                                    local chosenBid = "default"
                                    local profile = nil
                                    if #profileKeys > 0 then
                                        chosenBid = profileKeys[ZombRand(#profileKeys) + 1]
                                        profile = clanProfiles[chosenBid]
                                        print("[Bandit Weapon Drop] [PROFILE] Selected profile: " .. tostring(chosenBid))
                                    end
                                    
                                    local general = profile and profile.general or {}

                                    -- 1. Инвентарь
                                    local inv = newBandit:getInventory()
                                    if inv then inv:clear() end
                                    
                                    -- 2. Получение Системного ID
                                    local id = newBandit:getPersistentOutfitID()
                                    if not id or id == 0 then id = ZombRand(1000000, 9999999) end
                                    
                                    -- 3. Базовая ModData
                                    local md = newBandit:getModData()
                                    md.id = id
                                    md.banditId = id
                                    md.is_omni_bandit = true -- ГЛОБАЛЬНЫЙ МАРКЕР БАНДИТА
                                    md.isBandit = true
                                    md.bandit = true
                                    md.bBandit = true
                                    md.Bandit = true
                                    md.hostile = (not peacefulMode) and not isFriendly
                                    md.clan = task.targetClan
                                    md.Clan = task.targetClan
                                    md.cid = task.targetClan
                                    md.isDead = false
                                    md.dead = false
                                    md.health = 100
                                    md.action = "Idle"
                                    md.state = "Idle"
                                    
                                    newBandit:setVariable("isBandit", "true")
                                    newBandit:setVariable("BanditClan", tostring(task.targetClan))
                                    newBandit:setVariable("Bandit", "true")
                                    newBandit:setVariable("bBandit", "true")
                                    newBandit:transmitModData()

                                    -- 4. Формирование Идеальных Мозгов
                                    local brain = {}
                                    brain.id = id
                                    brain.inVehicle = false
                                    
                                    -- Имя
                                    brain.fullname = _G.BanditNames and _G.BanditNames.GenerateName(general.female) or "Reinforcement"
                                    brain.born = getGameTime():getWorldAgeHours()
                                    
                                    -- КРИТИЧЕСКИЙ ХАК ДЛЯ ИИ: 
                                    -- Записываем координаты рации как "Дом" (bornCoords) для бандита. 
                                    brain.bornCoords = {x = task.radioX, y = task.radioY, z = task.radioZ}
                                    
                                    brain.stationary = false
                                    brain.sleeping = false
                                    brain.aiming = false
                                    brain.moving = true -- Форсируем движение со старта
                                    brain.endurance = 1.00
                                    brain.speech = 0.00
                                    brain.sound = 0.00
                                    brain.infection = 0
                                    brain.clan = task.targetClan
                                    brain.cid = task.targetClan
                                    brain.bid = chosenBid
                                    
                                    -- Внешность
                                    brain.female = general.female or false
                                    brain.skin = general.skin or 1
                                    brain.hairType = general.hairType or 1
                                    brain.hairColor = general.hairColor or 1
                                    brain.beardType = general.beardType or 1
                                    brain.eatBody = false
                                    
                                    -- Характеристики (Lerp)
                                    local health = general.health or 5
                                    brain.health = _G.BanditUtils and _G.BanditUtils.Lerp(health, 1, 9, 1, 2.6) or 1.5

                                    local accuracyBoost = general.sight or 5
                                    brain.accuracyBoost = _G.BanditUtils and _G.BanditUtils.Lerp(accuracyBoost, 1, 9, -8, 8) or 0

                                    local enduranceBoost = general.endurance or 5
                                    brain.enduranceBoost = _G.BanditUtils and _G.BanditUtils.Lerp(enduranceBoost, 1, 9, 0.25, 1.75) or 1

                                    local strengthBoost = general.strength or 5
                                    brain.strengthBoost = _G.BanditUtils and _G.BanditUtils.Lerp(strengthBoost, 1, 9, 0.25, 1.75) or 1
                                    
                                    -- Опыт
                                    brain.exp = {0, 0, 0}
                                    if general.exp1 and general.exp2 and general.exp3 then
                                        brain.exp = {general.exp1, general.exp2, general.exp3}
                                    end
                                    
                                    -- Оружие
                                    brain.weapons = {}
                                    brain.weapons.melee = "Base.BareHands"
                                    brain.weapons.primary = {bulletsLeft = 0, magCount = 0}
                                    brain.weapons.secondary = {bulletsLeft = 0, magCount = 0}
                                    
                                    if profile and profile.weapons then
                                        if profile.weapons.melee then
                                            brain.weapons.melee = _G.BanditCompatibility and _G.BanditCompatibility.GetLegacyItem(profile.weapons.melee) or profile.weapons.melee
                                        end
                                        
                                        for _, slot in pairs({"primary", "secondary"}) do
                                            if profile.weapons[slot] and profile.ammo and profile.ammo[slot] then
                                                if _G.BanditWeapons and type(_G.BanditWeapons.Make) == "function" then
                                                    brain.weapons[slot] = _G.BanditWeapons.Make(profile.weapons[slot], profile.ammo[slot])
                                                end
                                            end
                                        end
                                    end
                                    
                                    -- Fallback если оружие не сгенерировалось
                                    if not brain.weapons.primary.name then
                                        local wPrimary = profile and profile.weapons and profile.weapons.primary or "Base.BaseballBat"
                                        brain.weapons.primary = {name = wPrimary, type = "nomag", bulletsLeft = 0, ammoSize = 0, ammoCount = 0}
                                    end
                                    
                                    brain.clothing = profile and profile.clothing or {}
                                    brain.tint = profile and profile.tint or {}
                                    brain.bag = profile and profile.bag
                                    
                                    brain.loot = {}
                                    brain.inventory = {}
                                    
                                    -- [ФИКС ИИ] Мы больше НЕ выдаем жесткую задачу GoTo при спавне.
                                    -- ИИ должен сам экипировать оружие (Prepare), а затем побежать на рацию (GoToRadio)
                                    brain.tasks = {}
                                    
                                    brain.rnd = {ZombRand(2), ZombRand(10), ZombRand(100), ZombRand(1000), ZombRand(10000)}
                                    
                                    -- Личность
                                    brain.personality = {}
                                    brain.personality.alcoholic = (ZombRand(50) == 0)
                                    brain.personality.smoker = (ZombRand(4) == 0)
                                    brain.personality.compulsiveCleaner = (ZombRand(90) == 0)
                                    brain.personality.comicsCollector = (ZombRand(80) == 0)
                                    brain.personality.gameCollector = (ZombRand(220) == 0)
                                    brain.personality.hottieCollector = (ZombRand(100) == 0)
                                    brain.personality.toyCollector = (ZombRand(220) == 0)
                                    brain.personality.videoCollector = (ZombRand(220) == 0)
                                    brain.personality.underwearCollector = (ZombRand(150) == 0)
                                    brain.personality.fromPoland = (ZombRand(120) == 0)
                                    
                                    brain.hostile = (not peacefulMode) and not isFriendly
                                    brain.hostileP = brain.hostile
                                    
                                    -- НАЗНАЧЕНИЕ ПРОГРАММ ИИ
                                    brain.program = {name = task.targetProgram, stage = "Prepare"}
                                    brain.programFallback = task.fallbackProgram -- Запоминаем оригинальную программу клана!
                                    
                                    brain.occupation = nil
                                    brain.loyal = false
                                    brain.master = nil
                                    brain.permanent = false
                                    brain.key = nil
                                    
                                    -- Голос
                                    brain.voice = _G.Bandit and _G.Bandit.PickVoice and _G.Bandit.PickVoice(newBandit) or tostring(ZombRand(4) + 1)
                                    print("[Bandit Weapon Drop] [VOICE] Assigned native voice ID: " .. tostring(brain.voice))

                                    -- ПРИМЕНЕНИЕ ВИЗУАЛА НЕМЕДЛЕННО
                                    if _G.Bandit and type(_G.Bandit.ApplyVisuals) == "function" then
                                        _G.Bandit.ApplyVisuals(newBandit, brain)
                                        print("[Bandit Weapon Drop] [VISUALS] Native ApplyVisuals called successfully.")
                                    end

                                    -- ИСПРАВЛЕНИЕ ГОЛЫХ ТРУПОВ
                                    if brain.clothing then
                                        local clothesCount = 0
                                        for loc, cType in pairs(brain.clothing) do
                                            local cItem = instanceItem(cType)
                                            if cItem then
                                                cItem:getModData().preserve = true
                                                newBandit:addItemToSpawnAtDeath(cItem)
                                                if inv then inv:AddItem(cItem) end
                                                clothesCount = clothesCount + 1
                                            end
                                        end
                                        print("[Bandit Weapon Drop] [VISUALS FIX] Injected " .. tostring(clothesCount) .. " real clothing items into corpse drop list.")
                                    end
                                    
                                    -- УДАЛЕНО: Выдача физического оружия в руки здесь. 
                                    -- Это было причиной дюпа. Оригинальный скрипт BanditUpdate.lua сам физически 
                                    -- выдает оружие в задаче Prepare на стороне клиента сразу после спавна.

                                    -- 5. Впрыск в Сетевой Кластер Мода
                                    if _G.GetBanditClusterData and _G.TransmitBanditCluster then
                                        local gmd = _G.GetBanditClusterData(id)
                                        if type(gmd) == "table" then
                                            gmd[id] = brain
                                            _G.TransmitBanditCluster(id)
                                            print("[Bandit Weapon Drop] [CLUSTER] AI injected & transmitted into Network Cluster for ID: " .. tostring(id))
                                        else
                                            print("[Bandit Weapon Drop] [ERROR] Cluster Data is not a table for ID: " .. tostring(id))
                                        end
                                    else
                                        print("[Bandit Weapon Drop] [ERROR] GetBanditClusterData or TransmitBanditCluster not found in Global scope!")
                                    end
                                end)
                                
                                if not status then
                                    print("=====================================================")
                                    print("[Bandit Weapon Drop] [FATAL ERROR DURING SPAWN/INJECTION]")
                                    print("Trace: " .. tostring(err))
                                    print("Bandit Entity Data: " .. tostring(newBandit))
                                    print("=====================================================")
                                end
                            end
                        end
                    else
                        print("[Bandit Weapon Drop] [ERROR] addZombiesInOutfit failed to create entities.")
                    end
                    
                    table.remove(OmniSpawnQueue, i)
                end
            end
        end
    end)

    -- ==============================================================================
    -- ФУНКЦИЯ ВЫЗОВА ПОДКРЕПЛЕНИЯ
    -- ==============================================================================
    local function TriggerBackupProcedure(targetX, targetY, targetZ, targetClan, numBandits, targetProgram, radioAbsX, radioAbsY, radioAbsZ, killerType)
        local SB = SandboxVars.Bandits or {}
        
        -- РАСШИРЕННЫЙ СПИСОК ПОЗЫВНЫХ (ААА ВАРИАТИВНОСТЬ)
        local callsigns = {
            "Charlie", "Bravo-6", "Ghost-Actual", "Viper-2", "Nomad", 
            "Echo-Lead", "Sierra-Actual", "Raven-4", "Outlaw", "Grizzly", 
            "Reaper-3", "Hitman", "Hunter-1", "Shadow-Actual", "Delta-9",
            "Spectre", "Tango", "Wraith", "Whiskey-Actual", "Rogue-1", "Mamba",
            "Alpha-1", "Foxtrot", "Kilo-Two", "Omaha", "Valkyrie",
            "Gargoyle", "Wolverine", "Phoenix", "Spartan", "Jester",
            "Warlock-9", "Paladin", "Overlord", "Goblin", "Wanderer",
            "Ronin", "Banshee", "Chimera", "Thunder", "Strider",
            "Voodoo", "Odin", "Goliath", "Cyclone", "Avalanche",
            "Tombstone", "Widowmaker", "Grim", "Cerberus", "Dragon-Actual",
            "Icarus", "Juggernaut", "Kodiak", "Leviathan", "Maverick",
            "Nightmare", "Omega", "Pegasus", "Quake", "Raptor",
            "Vanguard", "Warden", "X-Ray", "Yankee", "Zulu-Actual"
        }
        
        -- РАСШИРЕННЫЙ СПИСОК ШТАБОВ
        local callers = {
            "Gandalf", "Base", "Papa Bear", "Warlock", "Overlord", 
            "Outpost", "Vanguard", "Command", "Archangel", "Motherboard", "Goliath",
            "HQ", "Control", "Oracle", "Sentinel", "Watchtower", "Nest",
            "Director", "Eye", "Central", "Dispatcher", "Atlas", "Titan"
        }
        
        -- ГЕНЕРАЦИЯ ЭНТРОПИИ (Фикс бага ZombRand в ивентах смерти PZ)
        local entropy = ZombRand(100000) + math.floor(targetX * 13.37) + math.floor(targetY * 7.73)
        local callsign = callsigns[(entropy % #callsigns) + 1]
        local caller = callers[((entropy + 5) % #callers) + 1]

        -- ПРОВЕРКА ПОГОДЫ ЧЕРЕЗ CLIMATE MANAGER
        local isBadWeather = false
        local cm = getClimateManager()
        if cm then
            local fog = cm:getFogIntensity() or 0
            local rain = cm:getRainIntensity() or 0
            local snow = cm:getSnowIntensity() or 0
            if fog > 0.35 or rain > 0.4 or snow > 0.4 then
                isBadWeather = true
                print("[Bandit Weapon Drop] [WEATHER] Bad weather detected! Modifying AI lines and spawn rules.")
            end
        end

        -- ПРОВЕРКА ВРЕМЕНИ СУТОК (НОЧНАЯ ПАРАНОЙЯ)
        local gameHour = getGameTime():getHour()
        local isNight = (gameHour >= 22 or gameHour <= 5)
        if isNight then
            print("[Bandit Weapon Drop] [TIME] Nighttime detected! Modifying AI lines to paranoid mode.")
        end
        
        -- ААА-МЕХАНИКА: ТУМАН ВОЙНЫ / ПАНИКА (Шанс 6%)
        -- Даже если движок точно знает убийцу, бандиты по рации могут не успеть 
        -- разобрать ситуацию в суматохе, проигрывая универсальные (else) реплики потерь.
        if ZombRand(100) < 6 then
            killerType = "unknown"
            print("[Bandit Weapon Drop] [RADIO] Fog of war triggered! Forcing 'unknown' killer lines.")
        end

        -- ВЫБОР РЕПЛИК В ЗАВИСИМОСТИ ОТ ПОГОДЫ, ВРЕМЕНИ И УБИЙЦЫ (ENGLISH)
        local lines = {}
        if isNight then
            if killerType == "zombie" then
                lines = {
                    { t = caller .. " calling " .. callsign .. ". I hear things moving in the dark. Fall back, don't let them drag you into the fucking black!", retreat = true },
                    { t = "[SCREAMS] ...these fuckers are coming out of the dark! Turn on the fucking flashlights! ... [STATIC]", retreat = true },
                    { t = "Base, this is " .. caller .. " ... it's pitch black out here... we're surrounded... [DEAD AIR]", retreat = true },
                    { t = caller .. " here. We lost " .. callsign .. " in the dark. Requesting backup!", retreat = false },
                    { t = "All posts, swarm in the sector, dead in the dark! Converge on " .. callsign .. ", watch your six!", retreat = false },
                    { t = "[GURGLING] ...only darkness... they're everywhere... [STATIC]", retreat = true }
                }
            elseif killerType == "player" then
                lines = {
                    { t = "Fuck, " .. callsign .. " is dead! Fire coming from roughly 130 degrees! That cocksucker is hiding in the dark, spread out, two squads are already en route to your sector!", retreat = false },
                    { t = "Fuck! " .. callsign .. " got dropped! Shots from roughly South-East! This motherfucker is in the dark, group up and fall the fuck back!", retreat = true },
                    { t = caller .. " to all posts! Fucking lone wolf! Check the tree line, he's hiding in the pitch black!", retreat = false },
                    { t = "[GUNFIRE] ...he's blasting from the shadows! Light this fucker up! [WHEEZING] [DEAD AIR]", retreat = true },
                    { t = caller .. " on comms. Some piece of shit dropped " .. callsign .. " in the dark. Sweep every meter, use your lights!", retreat = false },
                    { t = "[HEAVY BREATHING] ...I don't see him... he's like a fucking ghost... [GUNSHOT] [STATIC]", retreat = true }
                }
            elseif killerType == "bandit" then
                lines = {
                    { t = "Muzzle flashes in the dark! " .. callsign .. " is hit! I don't know who the fuck they are, but they're pushing us under the cover of night, nearest squads, requesting backup!", retreat = false },
                    { t = caller .. " to all! " .. callsign .. " got caught in a crossfire! Hostiles under the cover of night! Suppressing fire!", retreat = false },
                    { t = "[CURSING] ...they flanked us in the dark! " .. callsign .. " is dead! Return fire, goddammit!", retreat = false },
                    { t = "[STATIC] ...there's too many of them... shooting from the dark... we're fucked... [DEAD AIR]", retreat = true }
                }
            else
                lines = {
                    { t = caller .. " calling " .. callsign .. ". Do you copy? Can't see shit out here... Respond!", retreat = false },
                    { t = "I can't see a fucking thing in this dark! " .. callsign .. ", if you're alive, give us a damn signal, buddy. I'm not sending men in blind.", retreat = true },
                    { t = caller .. " here. " .. callsign .. " is MIA. Sending a squad to find the body.", retreat = false },
                    { t = "Base, it's too dark. " .. callsign .. "'s signal flatlined. We're falling back before we get picked off.", retreat = true }
                }
            end
        elseif isBadWeather then
            if killerType == "zombie" then
                lines = {
                    { t = caller .. " calling " .. callsign .. ". Can't see shit in this fucking rain. If he's dead, we're out.", retreat = true },
                    { t = "[SCREAMS] ...they're coming out of the fog! I can't see a fucking thing! ... [BONE CRUNCH] [STATIC]", retreat = true },
                    { t = "Base, this is " .. caller .. " ... the rain is blinding... we're surrounded... [DEAD AIR]", retreat = true },
                    { t = caller .. " here. We lost " .. callsign .. " in this shit weather. Requesting assistance, don't let them tear up the gear!", retreat = false },
                    { t = "All posts, converge, visibility is zero. Moving to " .. callsign .. "'s position, shoot anything that groans!", retreat = false },
                    { t = "[GURGLING] ...in the mud... they're everywhere... can't see shit... [STATIC]", retreat = true }
                }
            elseif killerType == "player" then
                lines = {
                    { t = caller .. " to all posts! Fucking lone wolf! Can't see shit in this fucking fog, " .. callsign .. " is down! Find him and slit his throat!", retreat = false },
                    { t = "[GUNFIRE] ...he's shooting from the blind spot! Can't see a damn thing in this rain... [WHEEZING] [DEAD AIR]", retreat = true },
                    { t = caller .. " on comms. Some piece of shit dropped " .. callsign .. " in this fog. Sweep every meter, go blind if you have to, but smoke this scumbag out, fuck!", retreat = false },
                    { t = "Can't see shit! Who the fuck is shooting?! " .. callsign .. " is down! Push forward, find that cocksucker!", retreat = false },
                    { t = "[HEAVY BREATHING] ...I don't see him... total whiteout... he's right here... [GUNSHOT] [STATIC]", retreat = true },
                    { t = caller .. " here. We're getting picked off in this fucking gloom! Dump lead into every shadow!", retreat = false }
                }
            elseif killerType == "bandit" then
                lines = {
                    { t = "Ambush! Those cocksuckers from the [STATIC] clan are pushing us! Can't see a damn thing in this storm, return fire on the muzzle flashes!", retreat = false },
                    { t = caller .. " to all! " .. callsign .. " got caught in a crossfire in this damn fog! Hostiles in sector! Fuck 'em all up!", retreat = false },
                    { t = "[CURSING] ...they pushed right up on us in the rain! " .. callsign .. " is dead! Return fire, goddammit!", retreat = false },
                    { t = "[STATIC] ...another squad, couldn't make out their gear... they're... shooting from the fog... can't see shit... [DEAD AIR]", retreat = true },
                    { t = caller .. " here! Heavy fire from the North-East! Zero visibility, just start chucking grenades at 'em!", retreat = false }
                }
            else
                lines = {
                    { t = caller .. " calling " .. callsign .. ". Do you copy? Comms are absolute shit in this storm... Respond!", retreat = false },
                    { t = "Can't see anything in this shit! " .. callsign .. ", if you're alive, get out yourself. I'm not sending men in blind.", retreat = true },
                    { t = "[STATIC] ... [COUGHING] ...won't make it... leave me in this fucking mud... [STATIC]", retreat = true },
                    { t = caller .. " here. Radar is dead, weather is absolute garbage. " .. callsign .. " is MIA. Sending a squad, find the body.", retreat = false },
                    { t = "Base, zero visibility. " .. callsign .. "'s signal flatlined. We won't find him in this fog, we're falling back.", retreat = true }
                }
            end
        else
            -- NORMAL WEATHER (English)
            if killerType == "zombie" then
                lines = {
                    { t = caller .. " calling " .. callsign .. ", do you read? ...What the fuck is that noise? All squads, fall back immediately.", retreat = true },
                    { t = callsign .. ", this is " .. caller .. ". Jesus, listen to those moans. They got him. Do not approach!", retreat = true },
                    { t = "[GURGLING] ...don't come here... [STATIC] ...they're fucking everywhere... [DEAD AIR]", retreat = true },
                    { t = caller .. " calling " .. callsign .. "... Fuck, we can hear them feeding. Write this grid off.", retreat = true },
                    { t = "[SCREAMS] Get these fuckers off me! [STATIC] ... this is " .. caller .. ". Fall back, we'll send his wife our sincere condolences.", retreat = true },
                    { t = caller .. " here. We lost " .. callsign .. " to the dead. We're clearing the perimeter, send more men.", retreat = false },
                    { t = "Swarm spotted at " .. callsign .. "'s position. Dispatching a hit squad. Kill everything that moves.", retreat = false },
                    { t = callsign .. " is down! I repeat, " .. callsign .. " is down! Send backup to his coordinates immediately!", retreat = false }
                }
            elseif killerType == "player" then
                lines = {
                    { t = caller .. " here. We heard shots! " .. callsign .. " is down! Find the bastard who did this and gut him!", retreat = false },
                    { t = "[COUGHING BLOOD] ...ambush... lone wolf... watch the trees, fuck... [DEAD AIR]", retreat = true },
                    { t = caller .. " calling " .. callsign .. "... Silence. Some local piece of shit dropped him. Sweep everything for hostiles, terminate the son of a bitch!", retreat = false },
                    { t = "[HEAVY BREATHING] ...got me... I'm bleeding out... please requesting evac, please, I feel bad, really really bad, I don't want to die like this... [STATIC]", retreat = true },
                    { t = caller .. " here. " .. callsign .. " is dead. I want this fucking lone wolf's head on a goddamn pike on his grave!", retreat = false },
                    { t = "[GUNFIRE] ...HOSTILE! We got a total fucking clusterfuck here! " .. callsign .. " just got his head blown off! ... [STATIC]", retreat = true },
                    { t = caller .. " to all units! " .. callsign .. " got smoked by some drifter. Find that son of a bitch and skin him alive!", retreat = false },
                    { t = callsign .. " is KIA. Bullet to the chest. We got some fucking ghost hunting us out here!", retreat = true },
                    { t = caller .. " to dispatch. We have a hostile here, this mutt is carving up our guys. Send more men, kill the motherfucker!", retreat = false },
                    { t = "Who the fuck is shooting?! " .. callsign .. " is down! Flank the son of a bitch and blow his brains out!", retreat = false },
                    { t = "[SCREAMING] ...this cocksucker came out of nowhere! ...[GUNSHOT]... [DEAD AIR]", retreat = true },
                    { t = "Base here. Someone just zeroed " .. callsign .. ". Requesting backup, we're gonna gut this prick and hang him by his own intestines.", retreat = false }
                }
            elseif killerType == "bandit" then
                lines = {
                    { t = "What the fuck?! " .. callsign .. " just got smoked by some heavily armed motherfuckers! Kill them all, we're requesting backup to sector B-12, do you copy?", retreat = false },
                    { t = "Ambush! It's a rival gang, those rats just blew " .. callsign .. "'s head off! We won't last long, send the boys!", retreat = false },
                    { t = caller .. " to all units! Local scavs just wiped out " .. callsign .. "'s squad! Fucking kill 'em all, no prisoners!", retreat = false },
                    { t = "[STATIC] ...rivals... bleeding out... fuck... [DEAD AIR]", retreat = true },
                    { t = caller .. " here. We lost " .. callsign .. " to a rival crew. Prepare for a fucking bloodbath.", retreat = false },
                    { t = "Crossfire! " .. callsign .. " is down! Nearest squad, wipe out those scavenger fucks before they loot him!", retreat = false },
                    { t = "They shot him! Those bastards shot him! " .. callsign .. " is dead! Kill 'em all!", retreat = false }
                }
            else
                lines = {
                    { t = caller .. " calling " .. callsign .. ", do you copy? ...Just fucking static. Cross-check the coordinates where we sent the boys, get in touch with someone at least!", retreat = false },
                    { t = callsign .. ", this is " .. caller .. ". ...Silence. Fall back, I'm not risking men for a corpse.", retreat = true },
                    { t = "[DEAD AIR] ..." .. callsign .. "? ...Fuck it. Mark him MIA. Nobody approach, he's a goner anyway.", retreat = true },
                    { t = "[WHEEZING] ...it's over... don't you dare send backup... fucking hell... [STATIC]", retreat = true },
                    { t = caller .. " calling " .. callsign .. ". If you're hearing this, we're abandoning the grid. You're on your own, sorry buddy, times are tough.", retreat = true },
                    { t = "...radio is open but no answer. " .. callsign .. " is fucked. Stay away from that zone.", retreat = true },
                    { t = caller .. " here. " .. callsign .. " is silent. We can't afford a rescue op. Fall the fuck back.", retreat = true },
                    { t = "[RADIO CRACKLE] ...I'm done... tell my... [COUGHS] ...fuck... [SILENCE]", retreat = true },
                    { t = callsign .. ", status! ...Nothing. Just a dead line. Write them off, we're moving out.", retreat = true },
                    { t = caller .. " here. " .. callsign .. "'s signal flatlined. Send an evac team, we need his gear back.", retreat = false },
                    { t = "Command to nearest patrol, we lost comms with " .. callsign .. ". Go find out what the hell happened out there.", retreat = false }
                }
            end
        end
        
        -- ENGLISH PREFIXES
        local prefixes = {
            "[ DEAD AIR ]", "[ NO SIGNAL ]", "[ FREQ 14.2 ]", 
            "[ STATIC ]", "[ FREQ 89.4 ]", "[ SIGNAL LOST ]", 
            "[ ENCRYPTED CH 4 ]", "[ UNKNOWN FREQ ]"
        }
        
        -- Выбор строки и префикса с использованием нашей новой энтропии
        local prefix = prefixes[((entropy + 3) % #prefixes) + 1]
        local selectedLineData = lines[((entropy + 7) % #lines) + 1]
        
        local chatText = prefix .. " " .. selectedLineData.t
        local isRetreat = selectedLineData.retreat
        local finalTargetClan = targetClan
        
        -- =========================================================
        -- ФИКС ИИ: ИНТЕГРАЦИЯ ПРОГРАММ ЗАЧИСТКИ ТЕРРИТОРИИ
        -- =========================================================
        local fallbackProgram = targetProgram
        if fallbackProgram == "Camper" or fallbackProgram == "Defend" or fallbackProgram == "Roadblock" or fallbackProgram == "Companion" then
            -- Если жертва была защитником базы, подкрепление после обыска начнет агрессивно патрулировать (Bandit), а не стоять на месте.
            fallbackProgram = "Bandit"
        end
        -- По умолчанию все дружественные подкрепления начинают с нашей новой программы расследования сцены убийства
        local finalProgram = "BackupSearch"

        -- =========================================================
        -- ПЕРЕХВАТ ЧАСТОТЫ (ВРАЖДЕБНЫЙ КЛАН) - 7% ШАНС
        -- =========================================================
        if not isRetreat and ZombRand(100) < 7 then
            local allClans = nil
            pcall(function() allClans = _G.BanditCustom.ClanGetAll() end)
            if type(allClans) == "table" then
                local enemyClans = {}
                for tempCid, _ in pairs(allClans) do
                    if tostring(tempCid) ~= tostring(targetClan) then
                        table.insert(enemyClans, tempCid)
                    end
                end
                
                if #enemyClans > 0 then
                    finalTargetClan = enemyClans[ZombRand(#enemyClans) + 1]
                    local interceptLines = {}
                    if isNight then
                        interceptLines = {
                            "[UNKNOWN FREQ] You hear those shots in the dark? Those cocksuckers lost a man. Turn on your lights and sweep their loot!",
                            "[UNKNOWN FREQ] Distress signal intercepted. They're getting picked off in the pitch black. Move in and finish the job!"
                        }
                    else
                        interceptLines = {
                            "[UNKNOWN FREQ] You hear that? Those cocksuckers just lost a squad. Reposition to the kill zone, let's take their loot!",
                            "[UNKNOWN FREQ] Distress signal intercepted. They are getting wiped out. Move in and finish the survivors, take everything!"
                        }
                    end
                    chatText = interceptLines[ZombRand(#interceptLines) + 1]
                    isRetreat = false
                    
                    -- Если это враждебный клан (мародеры), они не ищут товарищей. Они переходят сразу в атакующий режим.
                    finalProgram = "Bandit" 
                    fallbackProgram = "Bandit"
                    print("[Bandit Weapon Drop] [INTERCEPT] Enemy clan " .. tostring(finalTargetClan) .. " intercepted the radio!")
                end
            end
        end

        -- Координаты рации (если переданы) или дефолтная точка
        local rX = radioAbsX or targetX
        local rY = radioAbsY or targetY
        local rZ = radioAbsZ or targetZ

        -- =========================================================
        -- ФИКС СПАВНА: ЗАВИСИТ ОТ ПОГОДЫ И ВИДИМОСТИ
        -- =========================================================
        local cell = getCell()
        local spawnX, spawnY, spawnZ = targetX, targetY, targetZ
        local foundSafe = false
        
        -- Если погода плохая - спавним ближе (25-40). Если нормальная - далеко за экраном (40-55)
        local baseDist = isBadWeather and 25 or 40
        
        for attempt = 1, 30 do
            local angle = ZombRandFloat(0, math.pi * 2)
            local dist = baseDist + ZombRand(15) 
            local testX = math.floor(targetX + math.cos(angle) * dist)
            local testY = math.floor(targetY + math.sin(angle) * dist)
            
            if cell then
                local sq = cell:getGridSquare(testX, testY, targetZ)
                if sq and sq:isFree(false) then
                    spawnX = testX
                    spawnY = testY
                    foundSafe = true
                    break
                end
            end
        end
        
        if not foundSafe then
            local angle = ZombRandFloat(0, math.pi * 2)
            local dist = baseDist + 5
            spawnX = math.floor(targetX + math.cos(angle) * dist)
            spawnY = math.floor(targetY + math.sin(angle) * dist)
        end

        -- Вычисляем динамическую громкость (чем больше отряд - тем громче)
        local urgencyVolume = math.min(1.0, 0.6 + (numBandits * 0.1))

        -- ИНТЕГРАЦИЯ SANDBOX: Задержки вызова подкрепления
        -- Здесь используется ZombRand, что абсолютно безопасно, так как функция ProcessBanditDeath
        -- вызывается только на Сервере. Вычисленное значение передается всем клиентам, рассинхрона нет.
        local minNorm = SB.Addon_BackupDelayMin or 6
        local maxNorm = SB.Addon_BackupDelayMax or 25
        if maxNorm < minNorm then maxNorm = minNorm end
        local spawnDelay = (minNorm * 60) + ZombRand((maxNorm - minNorm + 1) * 60)

        if isBadWeather or isNight then
            local minBad = SB.Addon_BackupDelayBadMin or 20
            local maxBad = SB.Addon_BackupDelayBadMax or 50
            if maxBad < minBad then maxBad = minBad end
            spawnDelay = (minBad * 60) + ZombRand((maxBad - minBad + 1) * 60)
            print("[Bandit Weapon Drop] [WEATHER/NIGHT MODIFIER] Backup spawn delayed due to poor visibility.")
        end

        local spawnTask = {
            spawnX = spawnX,
            spawnY = spawnY,
            spawnZ = targetZ,
            radioX = targetX,
            radioY = targetY,
            radioZ = targetZ,
            numBandits = numBandits,
            targetClan = finalTargetClan,
            targetProgram = finalProgram,
            fallbackProgram = fallbackProgram,
            delay = spawnDelay -- Долгое ожидание ПОСЛЕ радиоэфира
        }

        -- САСПЕНС ТАЙМЕР (Быстрое начало вещания по рации)
        local suspenseDelay = 60 + ZombRand(90) 
        if isBadWeather then
            -- В плохую погоду связь хуже, осознают потерю чуть-чуть дольше (доп 1-2 сек)
            suspenseDelay = suspenseDelay + 60 + ZombRand(60)
        end

        table.insert(OmniRadioQueue, {
            delay = suspenseDelay,
            rX = rX,
            rY = rY,
            rZ = rZ,
            text = chatText,
            volume = urgencyVolume,
            isRetreat = isRetreat,
            spawnTask = spawnTask
        })
        
        print("[Bandit Weapon Drop] [SUSPENSE] Radio dropped. Waiting " .. tostring(suspenseDelay) .. " ticks before broadcasting.")
    end

    -- ==============================================================================
    -- ААА СИСТЕМА ДЕТЕКТА УБИЙЦЫ (AAA HEURISTIC ENGINE - IRONCLAD DETECTIVE)
    -- ==============================================================================
    local function AAA_DetermineKiller(victim, targetClan)
        local engineKiller = victim:getAttackedBy()
        local eType = EvaluateEntity(engineKiller)
        local timeNowHours = getGameTime():getWorldAgeHours()
        
        -- 1. СТРОГАЯ ДВИЖКОВАЯ ПРОВЕРКА (ПРОТИВ ФЕЙКОВ)
        if eType == "player" then return "player", "Engine (Direct Player)" end
        if eType == "bandit" then
            local aMD = engineKiller:getModData()
            local aClan = aMD.omni_cached_cid or aMD.clan or aMD.cid or engineKiller:getVariableString("BanditClan")
            if tostring(aClan) ~= tostring(targetClan) then
                return "bandit", "Engine (Direct Enemy Bandit)"
            end
        end
        
        -- 2. ИССЛЕДОВАНИЕ КЭША УРОНА (ИДЕАЛЬНАЯ ПАМЯТЬ СИНХРОНИЗИРОВАННАЯ ЧЕРЕЗ WORLD AGE)
        local md = victim:getModData()
        local cacheType, cacheClan, cacheAge
        if md and md.omni_last_attacker_type and md.omni_last_attacker_time then
            local cacheAgeHours = timeNowHours - md.omni_last_attacker_time
            -- Перевод ин-гейм часов в реальные секунды: 
            -- (Минуты в дне * 60) / 24 = реальных секунд в 1 ин-гейм часе.
            local realSecondsPassed = cacheAgeHours * (getGameTime():getMinutesPerDay() * 60) / 24
            cacheAge = realSecondsPassed
            
            if cacheAge >= 0 and cacheAge <= 15 then -- Оптимальное время (15 сек - покрывает среднее кровотечение)
                cacheType = md.omni_last_attacker_type
                cacheClan = md.omni_last_attacker_clan
                
                -- Игнорируем дружественный огонь по кэшу
                if cacheType ~= "bandit" or tostring(cacheClan) ~= tostring(targetClan) then
                    -- Если кэш супер-свежий (< 2 сек), это 100% гарантия убийства пулей/ударом
                    if cacheAge <= 2 then return cacheType, "Cache (Ultra-Fresh: " .. tostring(math.floor(cacheAge)) .. "s)" end
                else
                    cacheType = nil -- Сбрасываем, если это френдли фаер
                end
            end
        end
        
        -- 3. ААА ЭВРИСТИКА (КРОСС-АНАЛИЗ МЕСТА ПРЕСТУПЛЕНИЯ)
        local scoreZ, scoreP, scoreB = 0, 0, 0
        local vX, vY, vZ = victim:getX(), victim:getY(), victim:getZ()
        local vSq = victim:getSquare()
        local cell = getCell()
        
        -- Сбор улик: кто стоит в упор?
        local isEatenAlive = false 
        
        if vSq and cell then
            -- Анализ Зомби и вражеских Бандитов
            local zList = cell:getZombieList()
            if zList then
                for i = 0, zList:size() - 1 do
                    local z = zList:get(i)
                    if z and z ~= victim and z:isAlive() and math.abs(z:getZ() - vZ) < 0.5 then
                        local dist = math.sqrt((z:getX() - vX)^2 + (z:getY() - vY)^2)
                        local entType = EvaluateEntity(z)
                        
                        if entType == "zombie" then
                            if dist < 1.3 then 
                                isEatenAlive = true 
                                scoreZ = scoreZ + 200 -- Зомби буквально ест его
                            elseif dist < 2.5 then 
                                scoreZ = scoreZ + 50
                            end
                        elseif entType == "bandit" then
                            local bMD = z:getModData()
                            local bClan = bMD.omni_cached_cid or bMD.clan or bMD.cid or z:getVariableString("BanditClan")
                            if tostring(bClan) ~= tostring(targetClan) then
                                local wpn = z:getPrimaryHandItem()
                                local isGun = wpn and wpn:IsWeapon() and wpn:isAimedFirearm()
                                
                                if dist < 1.5 then
                                    scoreB = scoreB + 150 -- Враг добил в упор
                                elseif isGun and dist < 40 and not vSq:isSomethingTo(z:getSquare()) then
                                    scoreB = scoreB + 120 -- Враг-стрелок на прямой линии видимости
                                elseif dist < 20 then
                                    scoreB = scoreB + 40 -- Враг просто рядом
                                end
                            end
                        end
                    end
                end
            end
            
            -- Сканирование Игроков
            local function scorePlayer(p)
                if p and p:isAlive() and math.abs(p:getZ() - vZ) < 2.0 then
                    local dist = math.sqrt((p:getX() - vX)^2 + (p:getY() - vY)^2)
                    local wpn = p:getPrimaryHandItem()
                    local isGun = wpn and wpn:IsWeapon() and wpn:isAimedFirearm()
                    
                    if dist < 1.8 then
                        scoreP = scoreP + 150 -- Игрок добил в упор
                    elseif isGun and dist < 60 and not vSq:isSomethingTo(p:getSquare()) then
                        scoreP = scoreP + 130 -- Игрок-снайпер/стрелок на прямой линии видимости
                    elseif dist < 30 then
                        scoreP = scoreP + 50 -- Игрок просто рядом
                    end
                end
            end

            local players = getOnlinePlayers()
            if players and players:size() > 0 then
                for i = 0, players:size() - 1 do scorePlayer(players:get(i)) end
            else
                local statusP, p = pcall(function() return getSpecificPlayer(0) end)
                if statusP then scorePlayer(p) end
            end
        end
        
        -- 4. ФИНАЛЬНЫЙ ВЕРДИКТ (КРОСС-АНАЛИЗ КЭША И СЦЕНЫ)
        -- Добавляем вес кэша, если он был, но не супер-свежий (от 3 до 15 сек)
        if cacheType then
            if cacheType == "player" then scoreP = scoreP + 300 end
            if cacheType == "bandit" then scoreB = scoreB + 300 end
            if cacheType == "zombie" then scoreZ = scoreZ + 300 end
        end

        local best = math.max(scoreZ, scoreP, scoreB)
        
        if best == 0 then return "unknown", "Heuristic (Ghost Town)" end
        
        -- Абсолютный приоритет: если Зомби в упор (< 1.3 тайла) и нет перевеса от недавних пуль (Кэша)
        if isEatenAlive and cacheType == nil then return "zombie", "Heuristic (Eaten Alive)" end
        
        -- Сравнение очков. Если спорная перестрелка, отдаем приоритет Бандиту (их пули чаще всего теряет движок)
        if scoreB > 0 and scoreB >= scoreP and scoreB > scoreZ then return "bandit", "Heuristic Score (B:"..scoreB.." P:"..scoreP.." Z:"..scoreZ..")" end
        if scoreP > 0 and scoreP > scoreB and scoreP > scoreZ then return "player", "Heuristic Score (P:"..scoreP.." B:"..scoreB.." Z:"..scoreZ..")" end
        if scoreZ > 0 and scoreZ > scoreB and scoreZ > scoreP then return "zombie", "Heuristic Score (Z:"..scoreZ.." P:"..scoreP.." B:"..scoreB..")" end
        
        return "unknown", "Heuristic (Tie Breaker Failed)"
    end

    -- ==============================================================================
    -- ОСНОВНАЯ ФУНКЦИЯ ДРОПА И ПРОВЕРКИ СМЕРТИ
    -- ==============================================================================
    local function ProcessBanditDeath(zombie)
        if not zombie or not instanceof(zombie, "IsoZombie") then return end
        
        -- Захватываем глобальные SandboxVars (Защита от 'nil' значений при сбоях конфигов)
        local SB = SandboxVars.Bandits or {}
        
        -- ==============================================================================
        -- ТРЕХСЛОЙНАЯ ИДЕНТИФИКАЦИЯ БАНДИТОВ (ЖЕРТВЫ)
        -- ==============================================================================
        local isBandit = false
        local targetClan = 1
        local targetProgram = "Bandit"
        local banditID = zombie:getPersistentOutfitID() -- ВАЖНО: Объявляем ID ДО pcall для безопасного логирования

        if _G.BanditBrain and type(_G.BanditBrain.Get) == "function" then
            local status, brain = pcall(_G.BanditBrain.Get, zombie)
            if status and type(brain) == "table" and brain.cid then
                isBandit = true
                targetClan = brain.cid or targetClan
                if brain.program and brain.program.name then targetProgram = brain.program.name end
            end
        end
        
        if not isBandit then
            if banditID and banditID ~= 0 and _G.GetBanditClusterData then
                local status, gmd = pcall(_G.GetBanditClusterData, banditID)
                if status and type(gmd) == "table" and gmd[banditID] then
                    isBandit = true
                    targetClan = gmd[banditID].cid or targetClan
                    if gmd[banditID].program and gmd[banditID].program.name then targetProgram = gmd[banditID].program.name end
                end
            end
        end

        if not isBandit then
            local md = zombie:getModData()
            if md and (md.is_omni_bandit or md.isBandit or md.bandit or md.Bandit) then
                isBandit = true
                targetClan = md.omni_cached_cid or md.clan or md.Clan or md.cid or targetClan
                targetProgram = md.omni_cached_program or (md.program and md.program.name) or targetProgram
            elseif zombie:getVariableBoolean("Bandit") then
                isBandit = true
                local vClan = zombie:getVariableString("BanditClan")
                if vClan then targetClan = tonumber(vClan) or targetClan end
            end
        end
        
        if not isBandit then return end
        -- ==============================================================================

        -- ==============================================================================
        -- ААА СИСТЕМА ДЕТЕКТА УБИЙЦЫ (ВЫЗЫВАЕТСЯ ГЛОБАЛЬНО ДЛЯ ВСЕХ МОДУЛЕЙ)
        -- ==============================================================================
        local killerType, overrideReason = AAA_DetermineKiller(zombie, targetClan)
        print("[Bandit Weapon Drop] [KILL EVALUATION] Victim ID: " .. tostring(banditID) .. " | Killer Type: " .. tostring(killerType) .. " | Source: " .. tostring(overrideReason))

        -- ==============================================================================
        -- ИНТЕГРАЦИЯ СДАЧИ В ПЛЕН (Триггер для ZPSurrender.lua)
        -- ==============================================================================
        if _G.Omni_CheckSurrenderCondition then
            pcall(function()
                _G.Omni_CheckSurrenderCondition(zombie, targetClan, killerType)
            end)
        end

        local inventory = zombie:getInventory()
        if not inventory then return end
        
        local square = zombie:getCurrentSquare()
        if not square then return end

        local targetX = square:getX()
        local targetY = square:getY()
        local targetZ = square:getZ()
        
        -- [ИСПРАВЛЕНИЕ V125] Т.к. скрипт работает СТРОГО на сервере, детерминизм больше не нужен.
        -- Используем чистый рандом сервера, чтобы призванные бандиты, умирающие в одной точке 
        -- (у которых одинаковые координаты и ID=0), не действовали как единый разум и не дублировали рации.
        local radioRoll = ZombRand(100) + 1

        -- ==============================================================================
        -- ВОССТАНОВЛЕННАЯ СИСТЕМА ДРОПА ОРУЖИЯ (С УЧЕТОМ SANDBOX)
        -- ==============================================================================
        print("[Bandit Weapon Drop] Death Event Triggered. Checking Sandbox Settings...")
        print("[Bandit Weapon Drop] Sandbox: Addon_EnableWeaponDrop = " .. tostring(SB.Addon_EnableWeaponDrop))
        print("[Bandit Weapon Drop] Sandbox: Addon_EnableRadioSystem = " .. tostring(SB.Addon_EnableRadioSystem))

        if SB.Addon_EnableWeaponDrop ~= false then
            local weaponsToDrop = {}
            local primary = zombie:getPrimaryHandItem()
            local secondary = zombie:getSecondaryHandItem()

            if primary and primary:IsWeapon() then weaponsToDrop[primary] = "Primary" end
            if secondary and secondary:IsWeapon() and secondary ~= primary then weaponsToDrop[secondary] = "Secondary" end

            -- [FIX] УМНАЯ ПОДМЕНА FAKE-ПИСТОЛЕТА НА РЕАЛЬНОЕ ОРУЖИЕ
            local bBrain = zombie:getModData().brain
            if not bBrain and banditID and _G.GetBanditClusterData then
                local statusGmd, gmd = pcall(_G.GetBanditClusterData, banditID)
                if statusGmd and type(gmd) == "table" and gmd[banditID] then
                    bBrain = gmd[banditID]
                end
            end
            
            local expectedPrimary = bBrain and bBrain.weapons and bBrain.weapons.primary and bBrain.weapons.primary.name
            
            local wpnList = {}
            for wpn, slotName in pairs(weaponsToDrop) do
                table.insert(wpnList, {wpn = wpn, slotName = slotName})
            end
            
            for _, wData in ipairs(wpnList) do
                if wData.slotName == "Primary" and wData.wpn:getFullType() == "Base.BaseballBat" and expectedPrimary and expectedPrimary ~= "Base.BaseballBat" then
                    -- Ищем в инвентаре настоящее оружие (по подстроке для модов)
                    local items = inventory:getItems()
                    local foundRealWeapon = nil
                    for i = 0, items:size() - 1 do
                        local item = items:get(i)
                        if item and item:IsWeapon() then
                            local iType = item:getFullType()
                            if iType == expectedPrimary or string.find(iType, expectedPrimary, 1, true) or string.find(expectedPrimary, iType, 1, true) then
                                foundRealWeapon = item
                                break
                            end
                        end
                    end
                    -- АКТУАЛЬНЫЙ ЗАПРОС: Полностью удаляем фейковую пустышку отовсюду
                    weaponsToDrop[wData.wpn] = nil
                    if wData.slotName == "Primary" then zombie:setPrimaryHandItem(nil) end
                    if wData.slotName == "Secondary" then zombie:setSecondaryHandItem(nil) end
                    inventory:Remove(wData.wpn)

                    local statusSpawn, spawnItems = pcall(function() return zombie:getItemsToSpawnAtDeath() end)
                    if statusSpawn and spawnItems then
                        for i = spawnItems:size() - 1, 0, -1 do
                            local sItem = spawnItems:get(i)
                            if sItem and sItem:getFullType() == wData.wpn:getFullType() then
                                spawnItems:remove(i)
                                break
                            end
                        end
                    end

                    if foundRealWeapon then
                        weaponsToDrop[foundRealWeapon] = "Primary"
                        print("[Bandit Weapon Drop] [SMART SWAP] Deleted fake Base.BaseballBat. Replaced with real weapon: " .. foundRealWeapon:getFullType())
                    else
                        print("[Bandit Weapon Drop] [SMART SWAP] Deleted fake Base.BaseballBat. No real weapon found to drop.")
                    end
                end
            end

            local handsCount = 0
            for k, v in pairs(weaponsToDrop) do handsCount = handsCount + 1 end

            if handsCount == 0 then
                local bestWeapon = nil
                local items = inventory:getItems()
                for i = 0, items:size() - 1 do
                    local item = items:get(i)
                    if item and item:IsWeapon() then
                        local isDummy = (item:getFullType() == "Base.BaseballBat" and expectedPrimary and expectedPrimary ~= "Base.BaseballBat")
                        if not isDummy then
                            if item:isAimedFirearm() then
                                bestWeapon = item
                                break
                            elseif not bestWeapon then
                                bestWeapon = item
                            end
                        end
                    end
                end
                if bestWeapon then weaponsToDrop[bestWeapon] = "InventoryFallback" end
            end

            local finalCount = 0
            for k, v in pairs(weaponsToDrop) do finalCount = finalCount + 1 end

            if finalCount > 0 then
                print("=====================================================")
                print("[Bandit Weapon Drop] [DEATH EVENT]: Bandit death detected.")
                print("Dropping " .. finalCount .. " weapons.")
                print("=====================================================")
                
                for item, slotName in pairs(weaponsToDrop) do
                    local status, err = pcall(function()
                        if slotName == "Primary" then zombie:setPrimaryHandItem(nil) end
                        if slotName == "Secondary" then zombie:setSecondaryHandItem(nil) end
                        
                        if item:IsWeapon() and item.setBloodLevel then item:setBloodLevel(1.0) end
                        inventory:Remove(item)

                        local dropX = ZombRandFloat(0.1, 0.9)
                        local dropY = ZombRandFloat(0.1, 0.9)
                        local dropZ = targetZ - math.floor(targetZ)
                        
                        local worldObj
                        if square.AddWorldInventoryItem then
                            worldObj = square:AddWorldInventoryItem(item, dropX, dropY, dropZ)
                        elseif square.addWorldInventoryItem then
                            worldObj = square:addWorldInventoryItem(item, dropX, dropY, dropZ)
                        end
                        
                        if worldObj then 
                            print("[Bandit Weapon Drop] [SUCCESS]: Weapon " .. tostring(item:getName()) .. " dropped realistically and cinematically.") 
                        end
                        
                        -- Защита от дубликатов в системной очереди
                        if zombie.getItemsToSpawnAtDeath then
                            local statusSpawn, spawnItems = pcall(function() return zombie:getItemsToSpawnAtDeath() end)
                            if statusSpawn and spawnItems then
                                for i = spawnItems:size() - 1, 0, -1 do
                                    local sItem = spawnItems:get(i)
                                    -- [ФИКС ДЮПА] Сравниваем по getFullType(), так как это разные инстансы одного оружия!
                                    if sItem and sItem:getFullType() == item:getFullType() then
                                        spawnItems:remove(i)
                                        break -- Удаляем только одну копию, чтобы не удалить случайно легальное второе оружие
                                    end
                                end
                            end
                        end
                    end)
                    
                    if not status then 
                        print("=====================================================")
                        print("[Bandit Weapon Drop] [ERROR WEAPON DROP]")
                        print("Trace: " .. tostring(err))
                        print("Item Data: " .. tostring(item) .. " | Slot: " .. tostring(slotName))
                        print("=====================================================")
                    end
                end
            end

            -- ФИКСИРУЕМ КАТАСТРОФУ: УМНАЯ ЗАЧИСТКА ИНВЕНТАРЯ ОТ ФАНТОМНОГО ОРУЖИЯ (V119)
            -- 1. Собираем легитимное оружие из профиля бандита
            local validWeapons = {}
            local hasValidProfile = false
            local bBrain = zombie:getModData().brain
            
            if not bBrain and banditID and _G.GetBanditClusterData then
                local statusGmd, gmd = pcall(_G.GetBanditClusterData, banditID)
                if statusGmd and type(gmd) == "table" and gmd[banditID] then
                    bBrain = gmd[banditID]
                end
            end

            if bBrain and bBrain.weapons then
                hasValidProfile = true
                if bBrain.weapons.primary and bBrain.weapons.primary.name then validWeapons[bBrain.weapons.primary.name] = true end
                if bBrain.weapons.secondary and bBrain.weapons.secondary.name then validWeapons[bBrain.weapons.secondary.name] = true end
                if type(bBrain.weapons.melee) == "string" and bBrain.weapons.melee ~= "Base.BareHands" then validWeapons[bBrain.weapons.melee] = true end
            end

            -- Удаляем мусор только если мы точно знаем, какое оружие легитимно
            if hasValidProfile then
                local function isValidWeapon(fullType)
                    if validWeapons[fullType] then return true end
                    for vWpn, _ in pairs(validWeapons) do
                        if string.find(fullType, vWpn, 1, true) or string.find(vWpn, fullType, 1, true) then
                            return true
                        end
                    end
                    return false
                end

                -- Определяем известные ванильные "пустышки", которые мод может спавнить по ошибке
                local knownVanillaTrash = {
                    ["Base.Pistol"] = true, ["Base.VarmintRifle"] = true, ["Base.M14"] = true,
                    ["Base.AssaultRifle"] = true, ["Base.DoubleBarrelShotgun"] = true,
                    ["Base.Shotgun"] = true, ["Base.HuntingRifle"] = true, ["Base.M16"] = true
                }

                -- 2. Удаляем ванильный мусор из инвентаря
                local allItems = inventory:getItems()
                for i = allItems:size() - 1, 0, -1 do
                    local invItem = allItems:get(i)
                    if invItem and invItem:IsWeapon() then
                        local iType = invItem:getFullType()
                        -- Удаляем, если пушки НЕТ в профиле бандита И она является известной ванильной пустышкой
                        if not isValidWeapon(iType) and knownVanillaTrash[iType] then
                            inventory:Remove(invItem)
                        end
                    end
                end

                -- 3. Очищаем системный пул спавна трупа от фейкового оружия
                if zombie.getItemsToSpawnAtDeath then
                    local statusSpawn, spawnItems = pcall(function() return zombie:getItemsToSpawnAtDeath() end)
                    if statusSpawn and spawnItems then
                        for i = spawnItems:size() - 1, 0, -1 do
                            local sItem = spawnItems:get(i)
                            if sItem and sItem:IsWeapon() then
                                local sType = sItem:getFullType()
                                if not isValidWeapon(sType) and knownVanillaTrash[sType] then
                                    spawnItems:remove(i)
                                end
                            end
                        end
                    end
                end
            end
        end

        -- ==========================================
        -- СИСТЕМА ДРОПА РАЦИИ И ВЫЗОВА ПОДКРЕПЛЕНИЯ
        -- ==========================================
        local peacefulMode = _G.Bandit and _G.Bandit.IsPeacefulMode and _G.Bandit.IsPeacefulMode()
        if SB.Addon_EnableRadioSystem ~= false and not peacefulMode then
            local statusBackup, errBackup = pcall(function()
                local hasRadio = false
                local radioItem = nil
                local items = inventory:getItems()
                
                for i = 0, items:size() - 1 do
                    local item = items:get(i)
                    if item and item:getType() and string.find(item:getType(), "WalkieTalkie") then
                        hasRadio = true
                        radioItem = item
                        print("[Bandit Weapon Drop] [RADIO] Bandit already had a radio: " .. tostring(item:getType()))
                        break
                    end
                end

                -- Интеграция Sandbox: Шанс спавна рации
                local dropChanceRaw = SB.Addon_RadioDropChance
                if type(dropChanceRaw) ~= "number" then dropChanceRaw = 15 end
                
                print("[Bandit Weapon Drop] [RADIO ROLL] Server Roll: " .. tostring(radioRoll) .. " | Target chance: <= " .. tostring(dropChanceRaw))
                
                if not hasRadio and radioRoll <= dropChanceRaw then
                    -- Выбираем случайную рацию (от 1 до 5)
                    local radioNum = ZombRand(5) + 1
                    local radioTypeStr = "Radio.WalkieTalkie" .. tostring(radioNum)
                    print("[Bandit Weapon Drop] [RADIO] Chance SUCCESS! Spawning new radio: " .. radioTypeStr)
                    
                    radioItem = instanceItem(radioTypeStr)
                    if radioItem then
                        -- КРИТИЧЕСКИЙ ФИКС (V125): Кладем рацию в инвентарь ДО дропа, чтобы движок выдал ей 
                        -- сетевой ID для синхронизации в MP. Иначе клиенты видят невидимый предмет на земле.
                        inventory:AddItem(radioItem)
                        hasRadio = true
                        
                        local comm = nil
                        if radioItem.getDeviceData then comm = radioItem:getDeviceData() end
                        if comm then 
                            comm:setIsTurnedOn(true) 
                            print("[Bandit Weapon Drop] [RADIO] Radio device successfully turned ON.")
                        end
                    else
                        print("[Bandit Weapon Drop] [ERROR] Failed to instance item: " .. radioTypeStr)
                    end
                else
                    if not hasRadio then
                        print("[Bandit Weapon Drop] [RADIO] Drop chance failed. No reinforcement will be called.")
                    end
                end

                if hasRadio and radioItem then
                    print("=====================================================")
                    print("[Bandit Weapon Drop] [RADIO EVENT]")
                    print("Radio sequence initialized! Initiating reinforcement call.")
                    print("=====================================================")
                    
                    if inventory:contains(radioItem) then inventory:Remove(radioItem) end

                    local dropZ = targetZ - math.floor(targetZ)
                    
                    -- Логичный дроп рации возле самого тела
                    local exactX = zombie:getX() - targetX
                    local exactY = zombie:getY() - targetY

                    -- Рация падает в случайную точку, независимо от оружия
                    local radioAngle = ZombRandFloat(0, math.pi * 2)
                    local radioRadius = ZombRandFloat(0.1, 0.3)
                    
                    local radioOffsetX = exactX + math.cos(radioAngle) * radioRadius
                    local radioOffsetY = exactY + math.sin(radioAngle) * radioRadius
                    
                    radioOffsetX = math.max(0.05, math.min(0.95, radioOffsetX))
                    radioOffsetY = math.max(0.05, math.min(0.95, radioOffsetY))
                    
                    local absRadioX = targetX + radioOffsetX
                    local absRadioY = targetY + radioOffsetY
                    
                    local radioObj
                    if square.AddWorldInventoryItem then
                        radioObj = square:AddWorldInventoryItem(radioItem, radioOffsetX, radioOffsetY, dropZ)
                    elseif square.addWorldInventoryItem then
                        radioObj = square:addWorldInventoryItem(radioItem, radioOffsetX, radioOffsetY, dropZ)
                    end
                    
                    if radioObj then
                        print("[Bandit Weapon Drop] [RADIO] Physical radio item dropped in the world at offsets: X:"..radioOffsetX.." Y:"..radioOffsetY)
                    end
                    
                    -- ИНТЕГРАЦИЯ SANDBOX: Настройка размера подкрепления
                    local numBandits = 2 + math.floor((targetX % 2)) -- Дефолтное старое значение
                    if SB.Addon_BackupSquadSize ~= nil then
                        local parsedSize = tonumber(SB.Addon_BackupSquadSize)
                        if parsedSize then
                            -- Ограничиваем от 1 до 10 бойцов
                            numBandits = math.max(1, math.min(10, parsedSize))
                        end
                    end
                    
                    TriggerBackupProcedure(targetX, targetY, targetZ, targetClan, numBandits, targetProgram, absRadioX, absRadioY, targetZ, killerType)
                end
            end)

            if not statusBackup then 
                print("=====================================================")
                print("[Bandit Weapon Drop] [CRITICAL ERROR BACKUP SYSTEM]")
                print("Trace: " .. tostring(errBackup))
                -- Используем заранее кэшированный banditID, так как локальные переменные в функции OnZombieDead 
                -- могут быть недоступны в обработчике pcall в момент фатального сбоя движка
                print("Zombie/Victim ID: " .. tostring(banditID)) 
                print("=====================================================")
            end
        end
    end

    Events.OnZombieDead.Add(ProcessBanditDeath)


    -- ТЕСТОВАЯ КОМАНДА СЕРВЕРА
    _G.TestBanditBackup = function(playerName, clanId, amount)
        clanId = clanId or 1
        amount = amount or 3
        
        local targetPlayer = nil
        local players = getOnlinePlayers()
        if not players or players:size() == 0 then return false end
        if playerName then
            for i = 0, players:size() - 1 do
                local p = players:get(i)
                if p:getUsername() == playerName then
                    targetPlayer = p
                    break
                end
            end
        else
            targetPlayer = players:get(0)
        end
        
        if not targetPlayer then return false end
        
        local sq = targetPlayer:getCurrentSquare()
        if not sq then return false end
        
        print("[Bandit Weapon Drop] [TEST] Forcing backup procedure for player: " .. targetPlayer:getUsername() .. " with Clan ID: " .. tostring(clanId))
        
        TriggerBackupProcedure(sq:getX(), sq:getY(), sq:getZ(), clanId, amount, "Bandit", sq:getX(), sq:getY(), sq:getZ(), "unknown")
        return true
    end

end -- Конец серверного блока


-- ==============================================================================
-- КЛИЕНТСКАЯ ЧАСТЬ (ГЛОБАЛЬНАЯ КИНЕМАТОГРАФИЧНАЯ ПЕРЕРАБОТКА)
-- ==============================================================================
if isClient() then

    -- Массив для хранения активных сообщений рации в мире
    local activeRadioTexts = {}

    -- Время жизни текста: 1800 тиков (очень долгое чтение, как в субтитрах фильмов)
    local MAX_TEXT_LIFE = 1800
    
    -- Символы для искажения текста (аналог ванильных помех)
    local SCRAMBLE_CHARS = {"~", "-", "*", ".", "z", "k", "x", "#", "%", "?"}

    -- Вспомогательная функция для нарезки длинного текста на компактные строки (Word Wrap)
    local function formatTextIntoLines(rawText, maxCharsPerLine)
        local lines = {}
        local lineLengths = {}
        local totalChars = 0
        local currentLine = ""
        
        for word in string.gmatch(rawText, "%S+") do
            if currentLine == "" then
                currentLine = word
            elseif string.len(currentLine) + 1 + string.len(word) <= maxCharsPerLine then
                currentLine = currentLine .. " " .. word
            else
                table.insert(lines, currentLine)
                table.insert(lineLengths, string.len(currentLine))
                totalChars = totalChars + string.len(currentLine)
                currentLine = word
            end
        end
        
        if currentLine ~= "" then 
            table.insert(lines, currentLine) 
            table.insert(lineLengths, string.len(currentLine))
            totalChars = totalChars + string.len(currentLine)
        end
        
        return lines, lineLengths, totalChars
    end
    
    -- Вспомогательная функция: Детерминированное искажение текста рации на основе дистанции
    local function ScrambleString(text, chance, seedBase)
        if chance <= 0 then return text end
        local result = ""
        local numScrambleChars = #SCRAMBLE_CHARS
        
        for i = 1, #text do
            local char = string.sub(text, i, i)
            -- Пробелы, системные скобки и курсор не искажаем
            if char == " " or char == "_" or char == "[" or char == "]" then
                result = result .. char
            else
                -- Генерируем уникальный, но стабильный сид для каждой буквы
                local charSeed = seedBase + i * 13
                -- Псевдорандом от 0 до 100
                local pseudoRand = (charSeed * 101.31) % 100
                
                if pseudoRand < (chance * 100) then
                    local sIdx = math.floor((charSeed * 17.7) % numScrambleChars) + 1
                    result = result .. SCRAMBLE_CHARS[sIdx]
                else
                    result = result .. char
                end
            end
        end
        return result
    end

    -- Слушатель команд от сервера
    local function OnServerCommand(module, command, args)
        if module ~= "BanditAddon" then return end

        local p = getPlayer()
        if not p then return end

        -- КОМАНДА: Обычный текст рации
        if command == "RadioCall" then
            -- ФИКС: Вычисляем дистанцию ТОЛЬКО здесь, так как в других 
            -- командах (вроде ForceSurrender) нет аргументов args.x и args.y
            local dist = math.sqrt((p:getX() - args.x)^2 + (p:getY() - args.y)^2)
            
            if dist > 35 then return end

            print("[Bandit Weapon Drop] [CLIENT] Rendering Cinematic Radio event at X:" .. tostring(args.x) .. " Y:" .. tostring(args.y))

            -- Создаем надежный эмиттер и проигрываем звук ИНИЦИАЛИЗАЦИИ
            local emitter = nil
            local statusE, errE = pcall(function()
                emitter = getWorld():getFreeEmitter()
                if emitter then 
                    emitter:setPos(args.x, args.y, args.z)
                    -- Звук №1: Щелчок и запуск рации
                    emitter:playSound("OmniRadioInit")
                end
            end)
            if not statusE then print("[Bandit Weapon Drop] [EMITTER ERROR] " .. tostring(errE)) end

            -- ААА-МЕХАНИКА: Свечение диода рации ночью
            local lightSource = nil
            pcall(function()
                local gameHour = getGameTime():getHour()
                local isNight = (gameHour >= 20 or gameHour <= 7)
                if isNight then
                    -- Циановый (бирюзово-синий) светодиод: R=0.1, G=0.8, B=0.8, Radius=1
                    lightSource = IsoLightSource.new(math.floor(args.x), math.floor(args.y), math.floor(args.z), 0.1, 0.8, 0.8, 1, 1)
                    getCell():addLamppost(lightSource)
                    IsoGridSquare.setRecalcLightTime(-1.0)
                end
            end)

            -- Инициализация массива с учетом МНОГОСТРОЧНОСТИ
            local statusInit, errInit = pcall(function()
                -- Максимальная ширина одной строки для субтитров
                local COMPACT_WIDTH_CHARS = 42 
                local formLines, formLengths, formTotalChars = formatTextIntoLines(args.text, COMPACT_WIDTH_CHARS)

                table.insert(activeRadioTexts, {
                    id = ZombRand(100000),         -- Уникальный сид
                    x = args.x,
                    y = args.y,
                    z = args.z,
                    
                    lines = formLines,
                    lineLengths = formLengths,
                    fullLength = formTotalChars,
                    
                    life = MAX_TEXT_LIFE,
                    typeProgress = 0,              
                    randomTypeSpeed = ZombRandFloat(0.15, 0.45), -- Скорость печати для кинематографичности
                    volume = args.volume or 1.0,   -- Сохраняем громкость для постоянного шума
                    
                    emitter = emitter,             -- Привязываем эмиттер
                    lightSource = lightSource,     -- Привязываем источник света (диод)
                    soundTick = 40,                -- Задержка до старта лупа после Init
                    endPlayed = false              -- Флаг для звука окончания
                })
            end)
            
            if not statusInit then 
                print("=====================================================")
                print("[Bandit Weapon Drop] [CLIENT ERROR] Text Array Init Failed!")
                print("Trace: " .. tostring(errInit))
                print("Args provided: " .. tostring(args.text))
                print("=====================================================")
            end
        end
    end
    Events.OnServerCommand.Add(OnServerCommand)

    -- Комфортная громкость статики и Идеальный тайминг (5 Секунд)
    local function UpdateClientLogic()
        if #activeRadioTexts > 0 then
            local p = getPlayer()
            local pSq = p and p:getCurrentSquare() or nil
            local pX = p and p:getX() or 0
            local pY = p and p:getY() or 0

            for i = 1, #activeRadioTexts do
                local rt = activeRadioTexts[i]
                if rt.life > 0 and rt.emitter then
                    local isTyping = rt.typeProgress < rt.fullLength
                    
                    -- Вычисляем дистанцию для затухания звука
                    local dist = math.sqrt((pX - rt.x)^2 + (pY - rt.y)^2)
                    
                    -- Глушение от стен/этажей (Occlusion)
                    local muffl = 1.0
                    local sqX, sqY, sqZ = math.floor(rt.x), math.floor(rt.y), math.floor(rt.z)
                    local statusSq, sq = pcall(function() return getCell():getGridSquare(sqX, sqY, sqZ) end)
                    if statusSq and sq and pSq then
                        if pSq:isOutside() ~= sq:isOutside() then muffl = 0.35 end -- Глушим сильнее через стены
                        if math.abs(pSq:getZ() - sq:getZ()) >= 1 then muffl = muffl * 0.15 end -- Почти полностью глушим через этажи
                    end
                    
                    -- Динамическое экспоненциальное затухание звука от расстояния
                    local distMuffl = 1.0
                    if dist > 2 then
                        -- Звук быстро падает после 2-х клеток, создавая реалистичный спад (Inverse Square Law)
                        distMuffl = math.max(0, 1.0 / (1.0 + (dist - 2) * 0.5))
                    end

                    if isTyping then
                        if rt.soundTick > 0 then
                            rt.soundTick = rt.soundTick - 1
                        else
                            local statusSound, errSound = pcall(function()
                                -- Делаем фоновое шипение тише (0.2), умножаем на преграды и на дистанцию
                                -- Помехи затухают чуть быстрее, чем голос
                                local finalVol = math.min(1.0, (rt.volume * 0.2) * muffl * (distMuffl ^ 1.2))
                                rt.emitter:setVolumeAll(finalVol)
                                
                                rt.emitter:playSound("OmniRadioStaticLoop")
                            end)
                            if not statusSound then print("[Bandit Weapon Drop] [SOUND LOOP ERROR] " .. tostring(errSound)) end
                            
                            -- 290 тиков = ~4.83 секунды (при 60 FPS). 
                            -- Идеально для 5-секундного файла с плавным наслоением (Overlap).
                            rt.soundTick = 290 
                        end
                    else
                        -- Текст допечатался, нужно проиграть звук окончания ОДИН раз
                        if not rt.endPlayed then
                            pcall(function()
                                -- Надежно глушим ТОЛЬКО зацикленный звук помех
                                if rt.emitter:isPlaying("OmniRadioStaticLoop") then
                                    rt.emitter:stopSoundByName("OmniRadioStaticLoop")
                                end
                                
                                -- Делаем финальный писк ГРОМЧЕ (x1.5), чтобы он пробивался через расстояние
                                local finalVol = math.min(1.0, (rt.volume * 1.5) * muffl * distMuffl)
                                
                                -- Запускаем звук окончания напрямую через SoundManager в ту же точку мира!
                                if statusSq and sq then
                                    getSoundManager():PlayWorldSound("OmniRadioEnd", sq, 0, 50, finalVol, false)
                                else
                                    -- Запасной вариант (если чанк не прогружен)
                                    local endEmitter = getWorld():getFreeEmitter()
                                    endEmitter:setPos(rt.x, rt.y, rt.z)
                                    endEmitter:setVolumeAll(finalVol)
                                    endEmitter:playSound("OmniRadioEnd")
                                end
                            end)
                            rt.endPlayed = true
                        end
                    end
                end
            end
        end
    end
    Events.OnTick.Add(UpdateClientLogic)


    -- Рендер 3D текста в мире (УЛЬТРА КИНЕМАТОГРАФИЧНО: ЦВЕТА, ГЛИТЧИ, ТЕЛЕТАЙП И ПОМЕХИ)
    local function RenderRadioText()
        if #activeRadioTexts == 0 then return end
        
        -- Захватываем глобальные SandboxVars с защитой от 'nil' для рендера
        local SB = SandboxVars.Bandits or {}

        local statusRender, errRender = pcall(function()
            local p = getPlayer()
            if not p then return end
            
            local pNumInt = math.floor(p:getPlayerNum() or 0)
            local pX, pY = p:getX(), p:getY()
            
            local font = UIFont.Small
            local tm = getTextManager()
            
            local lineHeight = tm:getFontHeight(font) + 2

            for i = #activeRadioTexts, 1, -1 do
                local rt = activeRadioTexts[i]
                rt.life = rt.life - 1

                if rt.life <= 0 then
                    -- Строгое удаление эмиттера при удалении текста во избежание утечек памяти
                    if rt.emitter then
                        pcall(function() 
                            rt.emitter:stopAll()
                        end)
                    end
                    -- Строгое удаление свечения диода (свет горит пока есть текст)
                    if rt.lightSource then
                        pcall(function()
                            getCell():removeLamppost(rt.lightSource)
                            IsoGridSquare.setRecalcLightTime(-1.0)
                        end)
                    end
                    table.remove(activeRadioTexts, i)
                else
                    -- 1. ДИСТАНЦИЯ, ЗАТУХАНИЕ И ИСКАЖЕНИЕ ТЕКСТА
                    local dist = math.sqrt((pX - rt.x)^2 + (pY - rt.y)^2)
                    local distAlphaMult = 1.0
                    local scrambleChance = 0
                    
                    if dist > 15 then
                        distAlphaMult = math.max(0, 1.0 - ((dist - 15) / 10))
                    end
                    
                    -- Шанс помех в тексте растет от 0% до 100% на дистанции от 4 до 15 тайлов
                    if dist > 4 then
                        scrambleChance = math.min(1.0, (dist - 4) / 11)
                    end

                    if distAlphaMult > 0 then
                        local age = MAX_TEXT_LIFE - rt.life
                        local floatProgress = age / MAX_TEXT_LIFE
                        
                        -- Получаем абсолютные координаты экрана для 3D точки рации
                        local sx = isoToScreenX(pNumInt, rt.x, rt.y, rt.z)
                        local sy = isoToScreenY(pNumInt, rt.x, rt.y, rt.z)

                        -- ==============================================================
                        -- ЛОГИКА АНИМАЦИИ И МНОГОСТРОЧНОГО ТЕЛЕТАЙПА ДЛЯ РАЦИИ
                        -- ==============================================================
                        -- БАЗОВАЯ ПАЛИТРА (Тактический серый/белый дисплей рации)
                        local textR, textG, textB = 0.75, 0.75, 0.75 
                        local alpha = 0.95
                        local isGlitching = false
                        local caStrength = 0
                        local charsRemaining = 0
                        local showCursor = false
                        local linesToDraw = {}

                        -- Сложная логика "запинок" при печати текста
                        local currentStutter = 0
                        if math.sin(age * 0.15 + rt.id) > 0.85 then 
                            currentStutter = 0
                        else
                            local speedMod = 1.0 + (math.sin(age * 0.4) * 0.5)
                            currentStutter = rt.randomTypeSpeed * speedMod
                        end
                        
                        rt.typeProgress = rt.typeProgress + currentStutter
                        charsRemaining = math.max(0, math.min(rt.fullLength, math.floor(rt.typeProgress)))
                        
                        -- Курсор мигает, если текст еще печатается
                        showCursor = (charsRemaining < rt.fullLength) and (math.floor(age / (8 + ZombRand(4))) % 2 == 0)
                        local cursorChar = "_" -- Стандартный нижний курсор консоли

                        -- Раскидываем напечатанные символы по строкам (компактный блок)
                        for lineIdx, lineStr in ipairs(rt.lines) do
                            local lineLen = rt.lineLengths[lineIdx]
                            
                            if charsRemaining >= lineLen then
                                table.insert(linesToDraw, lineStr)
                                charsRemaining = charsRemaining - lineLen
                            elseif charsRemaining > 0 then
                                local partialText = string.sub(lineStr, 1, charsRemaining)
                                if showCursor then 
                                    partialText = partialText .. cursorChar 
                                    showCursor = false 
                                end
                                table.insert(linesToDraw, partialText)
                                charsRemaining = 0
                            else
                                -- Если нужно отрисовать курсор на начале новой, еще не напечатанной строки
                                if showCursor and #linesToDraw > 0 then
                                    linesToDraw[#linesToDraw] = linesToDraw[#linesToDraw] .. cursorChar
                                    showCursor = false
                                end
                                break
                            end
                        end

                        -- Если курсор так и не был отрисован (страховка)
                        if showCursor and #linesToDraw > 0 then
                            linesToDraw[#linesToDraw] = linesToDraw[#linesToDraw] .. cursorChar
                        elseif showCursor then
                            table.insert(linesToDraw, cursorChar)
                        end

                        -- СТАТИЧНАЯ ПОЗИЦИЯ: Поднимаем текст всего на 35 пикселей ровно над предметом, БЕЗ ЗУМА
                        sy = sy - 35

                        local maxBaseAlpha = 0.95
                        alpha = maxBaseAlpha
                        
                        -- Плавное появление и затухание текста
                        if age < 60 then
                            alpha = (age / 60) * maxBaseAlpha
                        elseif rt.life < 300 then
                            alpha = (rt.life / 300) * maxBaseAlpha
                        end
                        alpha = alpha * distAlphaMult

                        local isFresh = floatProgress < 0.20
                        if isFresh then
                            -- Легкое перенасыщение яркости в момент "начала" эфира
                            local intensity = 1.0 - (floatProgress / 0.20)
                            textR = math.min(1.0, textR + (0.25 * intensity))
                            textG = math.min(1.0, textG + (0.25 * intensity))
                            textB = math.min(1.0, textB + (0.25 * intensity))
                        end

                        -- УЛУЧШЕННЫЕ ЖЕСТКИЕ VHS/ЭЛТ ГЛИТЧИ
                        local glitchChance = isFresh and 3 or 35 -- Увеличен шанс глитча
                        if ZombRand(glitchChance) == 0 then
                            isGlitching = true
                            alpha = alpha * ZombRandFloat(0.3, 0.85) -- Более сильное мерцание
                            sx = sx + (ZombRand(11) - 5) -- Тряска по X (от -5 до +5)
                            sy = sy + (ZombRand(5) - 2) -- Тряска по Y (от -2 до +2)
                            caStrength = 3 + ZombRand(5) -- Шире расслоение RGB (от 3 до 7)
                            
                            -- Добавлены цветовые артефакты старой кассеты
                            local colorShift = ZombRand(4)
                            if colorShift == 0 then
                                -- Яркая белая вспышка
                                textR, textG, textB = 1.0, 1.0, 1.0
                            elseif colorShift == 1 then
                                -- Голубоватый (Cyan) артефакт
                                textR, textG, textB = 0.5, 1.0, 1.0
                            elseif colorShift == 2 then
                                -- Пурпурный (Magenta) артефакт
                                textR, textG, textB = 1.0, 0.2, 0.8
                            end
                        end

                        -- ИНТЕГРАЦИЯ SANDBOX: Проверка отрисовки текста рации
                        if SB.Addon_EnableRadioText ~= false then
                            -- ФИНАЛЬНЫЙ РЕНДЕР (ПОСТРОЧНАЯ ОТРИСОВКА БЛОКА С ОБВОДКОЙ)
                            local outlineAlpha = alpha * 0.90
                            local offsets = {
                                {-2,-2}, { 0,-2}, { 2,-2},
                                {-2, 0},         { 2, 0},
                                {-2, 2}, { 0, 2}, { 2, 2}
                            }

                            local totalHeight = #linesToDraw * lineHeight
                            local startY = sy - (totalHeight / 2)

                            for lineIndex, drawStr in ipairs(linesToDraw) do
                                local finalY = startY + (lineIndex - 1) * lineHeight
                                
                                -- ААА-МЕХАНИКА: Искажение текста из-за помех (в зависимости от дистанции)
                                local seedBase = rt.id + lineIndex * 1337
                                local scrambledStr = ScrambleString(drawStr, scrambleChance, seedBase)

                                -- Черная мощная обводка для читаемости на любом фоне
                                for _, off in ipairs(offsets) do
                                    tm:DrawStringCentre(font, sx + off[1], finalY + off[2], scrambledStr, 0.0, 0.0, 0.0, outlineAlpha)
                                end

                                -- Отрисовка хроматической аберрации (расслоение каналов) при глитче
                                if isGlitching and caStrength > 0 then
                                    -- Красный канал сдвинут влево
                                    tm:DrawStringCentre(font, sx - caStrength, finalY, scrambledStr, 1.0, 0.0, 0.0, alpha * 0.8)
                                    -- Циан (Синий+Зеленый) канал сдвинут вправо
                                    tm:DrawStringCentre(font, sx + caStrength, finalY, scrambledStr, 0.0, 1.0, 1.0, alpha * 0.8)
                                end

                                -- Основной текст
                                tm:DrawStringCentre(font, sx, finalY, scrambledStr, textR, textG, textB, alpha)
                            end
                        end
                    end
                end
            end
        end)

        if not statusRender then
            print("=====================================================")
            print("[Bandit Weapon Drop] [CRITICAL RENDER ERROR]")
            print("Failed to draw cinematic world text!")
            print("Error Details Trace: " .. tostring(errRender))
            print("Active Radio Texts Count: " .. tostring(#activeRadioTexts))
            print("Emergency Purge: Resetting Render Array and cleaning Emitters to prevent Kahlua cascading...")
            print("=====================================================")
            
            -- Экстренная чистка эмиттеров при фатальном сбое рендера
            for _, rt in ipairs(activeRadioTexts) do
                if rt.emitter then pcall(function() rt.emitter:stopAll() end) end
                if rt.lightSource then pcall(function() getCell():removeLamppost(rt.lightSource) end) end
            end
            activeRadioTexts = {}
        end
    end
    Events.OnPreUIDraw.Add(RenderRadioText)

end

Events.OnGameStart.Add(function()
    if _G.Bandit and type(_G.Bandit.ApplyVisuals) == "function" and not _G.OMNI_APPLY_VISUALS_HOOKED then
        local original_ApplyVisuals = _G.Bandit.ApplyVisuals
        _G.Bandit.ApplyVisuals = function(bandit, brain)
            original_ApplyVisuals(bandit, brain)
            if not isServer() then
                local itemsToRemove = {}
                local primaryHand = bandit:getPrimaryHandItem()
                local secondaryHand = bandit:getSecondaryHandItem()
                local attachedItems = bandit:getAttachedItems()
                for i = 0, attachedItems:size() - 1 do
                    local attachedModel = attachedItems:get(i)
                    local attachedItem = attachedModel:getItem()
                    if attachedItem then
                        local iType = attachedItem:getFullType()
                        local shouldRemove = false
                        
                        -- ФИКС ДУПЛИКАЦИИ: Если оружие уже в руках, не рисуем его на спине
                        if (primaryHand and primaryHand:getFullType() == iType) or (secondaryHand and secondaryHand:getFullType() == iType) then
                            shouldRemove = true
                        end
                        
                        -- ФИКС ЗАГЛУШКИ: Убираем фейковую биту со спины
                        if iType == "Base.BaseballBat" then
                            local wantedDummy = false
                            if brain.weapons and brain.weapons.primary and brain.weapons.primary.name == "Base.BaseballBat" then wantedDummy = true end
                            if brain.weapons and brain.weapons.secondary and brain.weapons.secondary.name == "Base.BaseballBat" then wantedDummy = true end
                            if not wantedDummy then shouldRemove = true end
                        end
                        
                        if shouldRemove then
                            table.insert(itemsToRemove, attachedItem)
                        end
                    end
                end
                for _, item in ipairs(itemsToRemove) do
                    bandit:removeAttachedItem(item)
                end
                if #itemsToRemove > 0 then
                    bandit:resetModelNextFrame()
                end
            end
        end
        _G.OMNI_APPLY_VISUALS_HOOKED = true
        print("[Bandit Weapon Drop] Hooked Bandit.ApplyVisuals to fix visual duplication and dummy rendering.")
    end

    if _G.Bandit and type(_G.Bandit.SetHands) == "function" and not _G.OMNI_SETHANDS_HOOKED then
        local original_SetHands = _G.Bandit.SetHands
        _G.Bandit.SetHands = function(zombie, itemType)
            local dummyCheck = _G.BanditCompatibility and _G.BanditCompatibility.InstanceItem and _G.BanditCompatibility.InstanceItem(itemType)
            if dummyCheck and dummyCheck:getFullType() == "Base.BaseballBat" and itemType ~= "Base.BaseballBat" then
                 zombie:setPrimaryHandItem(nil)
                 zombie:setVariable("BanditPrimary", "")
                 zombie:setVariable("BanditPrimaryType", "")
                 zombie:resetEquippedHandsModels()
                 return
            end
            original_SetHands(zombie, itemType)
        end
        _G.OMNI_SETHANDS_HOOKED = true
        print("[Bandit Weapon Drop] Hooked Bandit.SetHands to prevent equipping dummy weapons.")
    end
end)

print("[Bandit Weapon Drop] Addon loaded (V125 - SMART RADIO SYNC & TRUE RANDOM).")

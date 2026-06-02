--
-- ********************************
-- *** Zombie Bandits           ***
-- ********************************
-- *** Coded by: Slayer         ***
-- ********************************
--

require "ISUI/SurvivorsCommandWindow"
require "ISUI/SurvivorTradeWindow"
require "SurvivorCompanions"
require "SurvivorCompanionGoTo"

BanditMenu = BanditMenu or {}
local SHOW_PROCEDURE_DEBUG = false

function BanditMenu.BanditTest (player)
    BanditTest.Check()
end

function BanditMenu.TestAction (player, square, zombie)

    local task = {action="Time", anim="TEST", time=400}
    Bandit.AddTask(zombie, task)
end

function BanditMenu.MakeProcedure (player, square)
    local cell = getCell()

    local sx = square:getX() - 10
    local sy = square:getY() - 10
    local sz = square:getZ()

    local w = 60
    local h = 60

    local lines = {}

    table.insert(lines, "require \"MysteryPlacements\"\n")
    table.insert(lines, "\n")
    table.insert(lines, "function ProcMedicalTent (sx, sy, sz)\n")
    
    for x = 0, w do
        for y = 0, h do
            for z = 0, 0 do
                local square = cell:getGridSquare(sx + x, sy + y, sz + z)
                if square then
                    local objects = square:getObjects()

                    for i=0, objects:size()-1 do
                        local object = objects:get(i)
                        if object then

                            local objectType = object:getType()
                            local spriteName = object:getSprite():getName()
                            local spriteProps = object:getSprite():getProperties()

                            local isSolidFloor = spriteProps:has(IsoFlagType.solidfloor)
                            local isAttachedFloor = spriteProps:has(IsoFlagType.attachedFloor)
                            local isExterior = spriteProps:has(IsoFlagType.exterior)
                            local isCanBeRemoved = spriteProps:has(IsoFlagType.canBeRemoved)
                            
                            if spriteName then
                                --[[if isSolidFloor and isExterior and not isAttachedFloor then
                                    --nature floor - skip it
                                    print ("nature floor")
                                elseif objectType == IsoObjectType.tree then
                                    print ("tree")

                                elseif isCanBeRemoved == true then
                                    print ("grass")

                                elseif isSolidFloor or isAttachedFloor then
                                    --floors
                                    table.insert(lines, "\tBanditBasePlacements.IsoObject (\"" .. spriteName .. "\", sx + " .. tostring(x) .. ", sy + " .. tostring(y) .. ", sz + " .. tostring(z) .. ")\n")
                                
                                elseif false and objectType == IsoObjectType.wall then
                                    -- walls 
                                    table.insert(lines, "\tBanditBasePlacements.IsoThumpable (\"" .. spriteName .. "\", sx + " .. tostring(x) .. ", sy + " .. tostring(y) .. ", sz + " .. tostring(z) .. ")\n")
                                ]]
                                if instanceof(object, 'IsoDoor') then
                                    -- door
                                    table.insert(lines, "\tBanditBasePlacements.IsoDoor (\"" .. spriteName .. "\", sx + " .. tostring(x) .. ", sy + " .. tostring(y) .. ", sz + " .. tostring(z) .. ")\n")

                                elseif instanceof(object, 'IsoWindow') then
                                    -- window
                                    table.insert(lines, "\tBanditBasePlacements.IsoWindow (\"" .. spriteName .. "\", sx + " .. tostring(x) .. ", sy + " .. tostring(y) .. ", sz + " .. tostring(z) .. ")\n")

                                else
                                    -- special objects?
                                    table.insert(lines, "\tBanditBasePlacements.IsoObject (\"" .. spriteName .. "\", sx + " .. tostring(x) .. ", sy + " .. tostring(y) .. ", sz + " .. tostring(z) .. ")\n")
                                    
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    local fileWriter = getFileWriter("waitingroom2.txt", true, true)
    table.insert(lines, "end\n\n")

    local output = ""
    for k, v in pairs(lines) do
        output = output .. v
    end
    fileWriter:write(output)
    fileWriter:close()
                            
end

function BanditMenu.ShowBrain (player, square, zombie)
    local id = BanditUtils.GetCharacterID(zombie)

    -- add breakpoint below to see data
    local brain = BanditBrain.Get(zombie)
    local moddata = zombie:getModData()
    
    local isUseless = zombie:isUseless()
    local isBandit = zombie:getVariableBoolean("Bandit")
    local walktype = zombie:getVariableString("zombieWalkType")
    local walktype2 = zombie:getVariableString("BanditWalkType")
    local isBanditTarget = zombie:getVariableString("BanditTarget")
    local primary = zombie:getVariableString("BanditPrimary")
    local primaryType = zombie:getVariableString("BanditPrimaryType")
    local secondary = zombie:getVariableString("BanditSecondary")
    local outfit = zombie:getOutfitName()
    local ans = zombie:getActionStateName()
    local under = zombie:isUnderVehicle()
    local veh = zombie:getVehicle()
    local health = zombie:getHealth()
    local zx = zombie:getX()
    local zy = zombie:getY()
    local hv = zombie:getHumanVisual()
    local bv = hv:getBodyVisuals()
    local moddata = zombie:getModData()
    local target = zombie:getTarget()
    local animator = zombie:getAdvancedAnimator()
    local inventory = zombie:getInventory()
    local ragdoll = zombie:isRagdoll()
    -- local astate = zombie:getAnimationDebug()
    local baseData = BanditPlayerBase.data

    zombie:resetModelNextFrame()
    zombie:resetModel()

end

function BanditMenu.SwitchProgram(player, bandit, program)
    local brain = BanditBrain.Get(bandit)
    if brain then
        local pid = BanditUtils.GetCharacterID(player)
        local npcId = brain.id or BanditUtils.GetCharacterID(bandit)

        brain.master = pid
        brain.hostile = false
        brain.hostileP = false
        if program ~= "SurvivorBase" then
            brain.survivorBase = false
        end
        brain.program = {}
        brain.program.name = program
        brain.program.stage = "Prepare"
        brain.tasks = {}
        SurvivorCompanions.NormalizeBrain(brain)
        if program == "Companion" then
            brain.companionOrder = {mode="follow"}
        end
        BanditBrain.Update(bandit, brain)

        local syncData = {}
        syncData.id = npcId
        syncData.master = brain.master
        syncData.hostile = brain.hostile
        syncData.hostileP = brain.hostileP
        syncData.program = brain.program
        syncData.survivorBase = brain.survivorBase
        syncData.tasks = brain.tasks
        syncData.companionOrder = brain.companionOrder
        Bandit.ForceSyncPart(bandit, syncData)

        if program ~= "SurvivorBase" then
            sendClientCommand(player, 'Commands', 'SurvivorBaseRemove', {npcId=npcId})
        end
    end
end

function BanditMenu.SendCompanionOrder(player, bandit, mode, x, y, z)
    local brain = bandit and BanditBrain.Get(bandit) or nil
    if not SurvivorCompanions.IsDirectCompanion(brain) or brain.companionDowned then return end
    SurvivorCompanions.SetLocalOrder(bandit, mode, x, y, z)
    sendClientCommand(player, "Commands", "CompanionOrder", {
        npcId=brain.id or BanditUtils.GetCharacterID(bandit),
        mode=mode,
        x=x,
        y=y,
        z=z,
    })
end

function BanditMenu.BeginCompanionGoTo(player, bandit)
    SurvivorCompanionGoTo.Start(player, bandit)
end

function BanditMenu.SetCompanionSetting(player, bandit, setting, value)
    local brain = bandit and BanditBrain.Get(bandit) or nil
    if not SurvivorCompanions.IsDirectCompanion(brain) then return end
    SurvivorCompanions.NormalizeBrain(brain)
    brain[setting] = value
    BanditBrain.Update(bandit, brain)

    local args = {npcId=brain.id or BanditUtils.GetCharacterID(bandit)}
    if setting == "companionGroup" then args.group = value end
    if setting == "companionCombatMode" then args.combatMode = value end
    if setting == "companionLoadoutMode" then args.loadoutMode = value end
    sendClientCommand(player, "Commands", "CompanionSettings", args)
end

local function cycleValue(values, current)
    for index, value in ipairs(values) do
        if value == current then
            return values[(index % #values) + 1]
        end
    end
    return values[1]
end

function BanditMenu.CycleCompanionGroup(player, bandit)
    local brain = bandit and SurvivorCompanions.NormalizeBrain(BanditBrain.Get(bandit)) or nil
    if brain then BanditMenu.SetCompanionSetting(player, bandit, "companionGroup", cycleValue(SurvivorCompanions.Groups, brain.companionGroup)) end
end

function BanditMenu.CycleCompanionCombatMode(player, bandit)
    local brain = bandit and SurvivorCompanions.NormalizeBrain(BanditBrain.Get(bandit)) or nil
    if brain then BanditMenu.SetCompanionSetting(player, bandit, "companionCombatMode", cycleValue(SurvivorCompanions.CombatModes, brain.companionCombatMode)) end
end

function BanditMenu.CycleCompanionLoadoutMode(player, bandit)
    local brain = bandit and SurvivorCompanions.NormalizeBrain(BanditBrain.Get(bandit)) or nil
    if brain then BanditMenu.SetCompanionSetting(player, bandit, "companionLoadoutMode", cycleValue(SurvivorCompanions.LoadoutModes, brain.companionLoadoutMode)) end
end

function BanditMenu.ReviveCompanion(player, bandit)
    local brain = bandit and BanditBrain.Get(bandit) or nil
    if not brain then return end
    sendClientCommand(player, "Commands", "CompanionRevive", {npcId=brain.id or BanditUtils.GetCharacterID(bandit)})
end

local function isOwnedCompanion(player, brain)
    return SurvivorCompanions.IsDirectCompanion(brain)
        and tostring(brain.master) == tostring(BanditUtils.GetCharacterID(player))
end

function BanditMenu.SendGroupOrder(player, group, mode, x, y, z)
    if not player or not group then return end
    for npcId, bandit in pairs(BanditZombie.Cache or {}) do
        local brain = bandit and BanditBrain.Get(bandit) or nil
        SurvivorCompanions.NormalizeBrain(brain)
        if isOwnedCompanion(player, brain) and brain.companionGroup == group and not brain.companionDowned then
            SurvivorCompanions.SetLocalOrder(bandit, mode, x, y, z)
        end
    end
    sendClientCommand(player, "Commands", "CompanionGroupOrder", {group=group, mode=mode, x=x, y=y, z=z})
end

function BanditMenu.BeginGroupGoTo(player, group)
    SurvivorCompanionGoTo.Start(player, nil, group)
end

function BanditMenu.SendGroupSettings(player, group, combatMode)
    if not player or not group or not combatMode then return end
    for _, bandit in pairs(BanditZombie.Cache or {}) do
        local brain = bandit and BanditBrain.Get(bandit) or nil
        SurvivorCompanions.NormalizeBrain(brain)
        if isOwnedCompanion(player, brain) and brain.companionGroup == group then
            brain.companionCombatMode = combatMode
            BanditBrain.Update(bandit, brain)
        end
    end
    sendClientCommand(player, "Commands", "CompanionGroupSettings", {group=group, combatMode=combatMode})
end

local function addCompanionGroupMenu(context, player)
    local owned = false
    for _, bandit in pairs(BanditZombie.Cache or {}) do
        if bandit and isOwnedCompanion(player, BanditBrain.Get(bandit)) then
            owned = true
            break
        end
    end
    if not owned then return end

    local groupsOption = context:addOption("Companion Groups")
    local groupsMenu = ISContextMenu:getNew(context)
    context:addSubMenu(groupsOption, groupsMenu)
    for _, group in ipairs(SurvivorCompanions.Groups) do
        local label = group == "None" and "Ungrouped" or ("Group " .. group)
        local groupOption = groupsMenu:addOption(label)
        local groupMenu = ISContextMenu:getNew(context)
        groupsMenu:addSubMenu(groupOption, groupMenu)
        groupMenu:addOption("Follow Player", player, BanditMenu.SendGroupOrder, group, "follow")
        groupMenu:addOption("Hold Current Positions", player, BanditMenu.SendGroupOrder, group, "stay")
        groupMenu:addOption("Choose Go To Tile", player, BanditMenu.BeginGroupGoTo, group)
        groupMenu:addOption("Stand Down - Passive", player, BanditMenu.SendGroupSettings, group, "passive")
        groupMenu:addOption("Defensive Stance", player, BanditMenu.SendGroupSettings, group, "defensive")
        groupMenu:addOption("Aggressive Stance", player, BanditMenu.SendGroupSettings, group, "aggressive")
    end
end

function BanditMenu.BanditFlush(player)
    local args = {a=1}
    sendClientCommand(player, 'Commands', 'BanditFlush', args)
end

function BanditMenu.SpawnClan(player, square, cid, atPlayer)
    local args = {}
    args.cid = cid
    if atPlayer then
        args.x = player:getX()
        args.y = player:getY()
        args.z = player:getZ()
    elseif square then
        args.x = square:getX()
        args.y = square:getY()
        args.z = square:getZ()
    else
        return
    end
    args.program = "Bandit"
    args.size = 6
    -- args.voice = 101
    sendClientCommand(player, 'Spawner', 'Clan', args)
end

local FREE_SURVIVOR_PRESETS = {
    {key="civilians", label="Civilian Group - improvised melee, rare handgun"},
    {key="rangers", label="Ranger Patrol - revolvers, some shotguns"},
    {key="police", label="Police Patrol - pistols, nightsticks, some shotguns"},
    {key="veterans", label="Veteran Patrol - rifles, sidearms, melee backup"},
}

function BanditMenu.SpawnFreeSurvivors(player, square, preset, atPlayer)
    local args = {}
    args.preset = preset or "rangers"
    args.atPlayer = atPlayer == true
    if not args.atPlayer and square then
        args.x = square:getX()
        args.y = square:getY()
        args.z = square:getZ()
    end
    sendClientCommand(player, 'Spawner', 'FreeSurvivors', args)
end

function BanditMenu.SpawnRecruitableSurvivor(player, square, atPlayer)
    local args = {}
    args.atPlayer = atPlayer == true
    if not args.atPlayer and square then
        args.x = square:getX()
        args.y = square:getY()
        args.z = square:getZ()
    end
    sendClientCommand(player, 'Spawner', 'RecruitableSurvivor', args)
end

local function addFreeSurvivorPresetMenu(context, parentMenu, player, square, atPlayer)
    for _, preset in ipairs(FREE_SURVIVOR_PRESETS) do
        parentMenu:addOption(preset.label, player, BanditMenu.SpawnFreeSurvivors, square, preset.key, atPlayer)
    end
end

local function getSortedClans()
    local clans = {}
    for cid, clan in pairs(BanditCustom.ClanGetAll()) do
        table.insert(clans, {cid=cid, clan=clan})
    end
    table.sort(clans, function(a, b)
        return tostring(a.clan.general.name) < tostring(b.clan.general.name)
    end)
    return clans
end

local function addExactClanMenu(parentMenu, player, square, atPlayer)
    for _, entry in ipairs(getSortedClans()) do
        local name = tostring(entry.clan.general.name or "Unnamed Group")
        parentMenu:addOption(name .. " - 6 survivors, original clan gear and behavior", player, BanditMenu.SpawnClan, square, entry.cid, atPlayer)
    end
end

function BanditMenu.OpenCommandWindow(player, bandit)
    if SurvivorsCommandWindow and SurvivorsCommandWindow.show then
        SurvivorsCommandWindow.show(player, bandit)
    end
end

function BanditMenu.OpenTradeWindow(player, bandit)
    if SurvivorTradeWindow and SurvivorTradeWindow.show then
        SurvivorTradeWindow.show(player, bandit)
    end
end

function BanditMenu.RecruitSurvivor(player, bandit)
    local brain = BanditBrain.Get(bandit)
    if not brain or brain.recruitableSeeker ~= true then return end

    local npcId = brain.id or BanditUtils.GetCharacterID(bandit)
    sendClientCommand(player, 'Commands', 'RecruitableSurvivorRecruit', {npcId=npcId})
end

local function getSafehouseBounds(player, square)
    if not SafeHouse or not SafeHouse.isSafeHouse or not square then return nil end

    local username = player.getUsername and player:getUsername() or nil
    local ok, safehouse = pcall(SafeHouse.isSafeHouse, square, username, true)
    if not ok or not safehouse or type(safehouse) == "boolean" then return nil end

    local okX, x = pcall(function() return safehouse:getX() end)
    local okY, y = pcall(function() return safehouse:getY() end)
    local okW, w = pcall(function() return safehouse:getW() end)
    local okH, h = pcall(function() return safehouse:getH() end)
    if okX and okY and okW and okH and x and y and w and h then
        return {
            x = x,
            y = y,
            x2 = x + w,
            y2 = y + h,
            z = square:getZ(),
            source = "safehouse",
        }
    end
end

local function getBuildingBounds(player, square)
    local building = square and square:getBuilding() or player:getBuilding()
    if not building then return nil end

    local buildingDef = building:getDef()
    if not buildingDef then return nil end

    return {
        x = buildingDef:getX(),
        y = buildingDef:getY(),
        x2 = buildingDef:getX2(),
        y2 = buildingDef:getY2(),
        z = square and square:getZ() or math.floor(player:getZ()),
        source = "building",
    }
end

local function getFallbackBounds(player)
    local x = math.floor(player:getX())
    local y = math.floor(player:getY())
    local z = math.floor(player:getZ())

    return {
        x = x - 20,
        y = y - 20,
        x2 = x + 20,
        y2 = y + 20,
        z = z,
        source = "area",
    }
end

local function getPlayerBaseBounds(player)
    local square = player:getSquare()
    return getSafehouseBounds(player, square) or getBuildingBounds(player, square) or getFallbackBounds(player)
end

function BanditMenu.AssignBaseRole(player, bandit, mode)
    local brain = BanditBrain.Get(bandit)
    if not brain then return end

    local bounds = getPlayerBaseBounds(player)
    if not bounds then return end

    local pid = BanditUtils.GetCharacterID(player)
    local npcId = brain.id or BanditUtils.GetCharacterID(bandit)
    local baseId = math.floor(bounds.x) .. "-" .. math.floor(bounds.y)
    local cx = (bounds.x + bounds.x2) / 2
    local cy = (bounds.y + bounds.y2) / 2
    local radius = math.max(35, math.floor(math.max(bounds.x2 - bounds.x, bounds.y2 - bounds.y) / 2) + 20)

    mode = mode or "defend"
    local allowChores = mode == "work"

    local home = {
        npcId = npcId,
        baseId = baseId,
        ownerId = pid,
        ownerUsername = player.getUsername and player:getUsername() or nil,
        mode = mode,
        allowChores = allowChores,
        x = bounds.x,
        y = bounds.y,
        x2 = bounds.x2,
        y2 = bounds.y2,
        z = bounds.z,
        cx = cx,
        cy = cy,
        cz = bounds.z,
        radius = radius,
        source = bounds.source,
    }

    brain.master = pid
    brain.hostile = false
    brain.hostileP = false
    brain.survivorBase = home
    brain.program = {name="SurvivorBase", stage="Prepare"}
    brain.tasks = {}
    BanditBrain.Update(bandit, brain)

    local syncData = {
        id = npcId,
        master = pid,
        hostile = false,
        hostileP = false,
        survivorBase = home,
        program = brain.program,
        tasks = brain.tasks,
    }
    Bandit.ForceSyncPart(bandit, syncData)

    sendClientCommand(player, 'Commands', 'SurvivorBaseAssign', home)

    if BanditPlayerBase and BanditPlayerBase.RegisterBase then
        BanditPlayerBase.RegisterBase(bounds.x, bounds.y, bounds.x2, bounds.y2)
    end

    if mode == "work" then
        bandit:addLineChatElement("I'll work the base.", 0.1, 0.8, 0.1)
    elseif mode == "guard" then
        bandit:addLineChatElement("I'll hold a guard post.", 0.1, 0.8, 0.1)
    else
        bandit:addLineChatElement("I'll defend this base.", 0.1, 0.8, 0.1)
    end
end

local LOOT_RUN_LABELS = {
    food = "Food",
    medicine = "Medicine",
    ammo = "Ammo",
    tools = "Tools",
    materials = "Materials",
}

local LOOT_RUN_ORDER = {"food", "medicine", "ammo", "tools", "materials"}

function BanditMenu.StartLootRun(player, bandit, category)
    local brain = BanditBrain.Get(bandit)
    if not brain then return end

    local npcId = brain.id or BanditUtils.GetCharacterID(bandit)
    category = tostring(category or "food")

    sendClientCommand(player, 'Commands', 'SurvivorLootRunStart', {npcId=npcId, category=category})
    bandit:addLineChatElement("I'll look for " .. string.lower(LOOT_RUN_LABELS[category] or category) .. ".", 0.1, 0.8, 0.1)
end

function BanditMenu.CollectLootRun(player, bandit)
    local brain = BanditBrain.Get(bandit)
    if not brain then return end
    local npcId = brain.id or BanditUtils.GetCharacterID(bandit)
    sendClientCommand(player, 'Commands', 'SurvivorLootRunCollect', {npcId=npcId})
end

local function addLootRunMenu(context, parentMenu, player, zombie, brain)
    if type(brain.survivorBase) ~= "table" then
        return
    end

    local job = brain.survivorLootRun
    if type(job) == "table" then
        local label = job.categoryLabel or LOOT_RUN_LABELS[job.category] or job.category or "Supplies"
        local completed = job.status == "completed"
        if not completed and job.returnAt and getGameTime then
            local gt = getGameTime()
            completed = gt and gt.getWorldAgeHours and (tonumber(job.returnAt) or math.huge) <= gt:getWorldAgeHours()
        end

        if completed then
            parentMenu:addOption("Collect Supply Run Loot", player, BanditMenu.CollectLootRun, zombie)
        else
            local option = parentMenu:addOption("Supply Run In Progress: " .. tostring(label))
            option.notAvailable = true
        end
        return
    end

    local lootOption = parentMenu:addOption("Send Supply Run - returns timed loot")
    local lootMenu = ISContextMenu:getNew(context)
    context:addSubMenu(lootOption, lootMenu)
    for _, category in ipairs(LOOT_RUN_ORDER) do
        lootMenu:addOption(LOOT_RUN_LABELS[category], player, BanditMenu.StartLootRun, zombie, category)
    end
end

function BanditMenu.WorldContextMenuPre(playerID, context, worldobjects, test)
    local world = getWorld()
    local player = getSpecificPlayer(playerID)
    local square = BanditCompatibility.GetClickedSquare()
    if not square then return end

    local zombie = square:getZombie()
    if not zombie then
        local squareS = square:getS()
        if squareS then
            zombie = squareS:getZombie()
            if not zombie then
                local squareW = square:getW()
                if squareW then
                    zombie = squareW:getZombie()
                end
            end
        end
    end

    -- Player options
    if zombie and zombie:getVariableBoolean("Bandit") then
        local brain = BanditBrain.Get(zombie)
        if brain and not (brain.hostile or brain.hostileP) then
            local banditOption = context:addOption(brain.fullname)
            local banditMenu = ISContextMenu:getNew(context)
            context:addSubMenu(banditOption, banditMenu)

            local programName = brain.program and brain.program.name or ""
            if programName == "RecruitableSurvivor" and brain.recruitableSeeker == true then
                banditMenu:addOption("Ask To Join Me", player, BanditMenu.RecruitSurvivor, zombie)
                local seekerInfo = banditMenu:addOption("Armed survivor seeking a group")
                seekerInfo.notAvailable = true
            else
                banditMenu:addOption("Survivor Commands", player, BanditMenu.OpenCommandWindow, zombie)
            end

            if programName == "Looter" then
                banditMenu:addOption("Join Me!", player, BanditMenu.SwitchProgram, zombie, "Companion")
                banditMenu:addOption("Defend This Base", player, BanditMenu.AssignBaseRole, zombie, "defend")
                banditMenu:addOption("Work This Base", player, BanditMenu.AssignBaseRole, zombie, "work")
            elseif programName == "Companion" or programName == "CompanionGuard" or programName == "SurvivorBase" then
                banditMenu:addOption("Follow Me", player, BanditMenu.SwitchProgram, zombie, "Companion")
                if SurvivorCompanions.IsDirectCompanion(brain) then
                    if brain.companionDowned then
                        banditMenu:addOption("Revive Companion - bandage or ripped sheets", player, BanditMenu.ReviveCompanion, zombie)
                    else
                        banditMenu:addOption("Hold Position", player, BanditMenu.SendCompanionOrder, zombie, "stay", zombie:getX(), zombie:getY(), zombie:getZ())
                        banditMenu:addOption("Choose Go To Tile", player, BanditMenu.BeginCompanionGoTo, zombie)
                    end
                end
                banditMenu:addOption("Defend This Base", player, BanditMenu.AssignBaseRole, zombie, "defend")
                banditMenu:addOption("Work This Base", player, BanditMenu.AssignBaseRole, zombie, "work")
                banditMenu:addOption("Guard This Base", player, BanditMenu.AssignBaseRole, zombie, "guard")
                addLootRunMenu(context, banditMenu, player, zombie, brain)
                banditMenu:addOption("Leave Me!", player, BanditMenu.SwitchProgram, zombie, "Looter")
            elseif programName == "SurvivorLootRun" then
                addLootRunMenu(context, banditMenu, player, zombie, brain)
            end

            banditMenu:addOption("Trade Items - direct barter", player, BanditMenu.OpenTradeWindow, zombie)
        end
    end

    addCompanionGroupMenu(context, player)

    -- Debug options
    if isDebugEnabled() then

        context:addOption("[DGB] Tests", player, BanditMenu.BanditTest)
        if SHOW_PROCEDURE_DEBUG then
            context:addOption("[DGB] Make Procedure", player, BanditMenu.MakeProcedure, square)
        end
        context:addOption("[DGB] Remove All Survivors", player, BanditMenu.BanditFlush, square)

        if zombie then
            context:addOption("[DGB] Show Brain", player, BanditMenu.ShowBrain, square, zombie)
        end
    end

    if isDebugEnabled() or isAdmin() then
        BanditCustom.Load()
        local roamingOption = context:addOption("Spawn Roaming Survivors - no colony")
        local roamingMenu = ISContextMenu:getNew(context)
        context:addSubMenu(roamingOption, roamingMenu)

        local playerPositionOption = roamingMenu:addOption("At My Position")
        local playerPositionMenu = ISContextMenu:getNew(context)
        roamingMenu:addSubMenu(playerPositionOption, playerPositionMenu)
        addFreeSurvivorPresetMenu(context, playerPositionMenu, player, square, true)

        local clickedPositionOption = roamingMenu:addOption("At Clicked Tile")
        local clickedPositionMenu = ISContextMenu:getNew(context)
        roamingMenu:addSubMenu(clickedPositionOption, clickedPositionMenu)
        addFreeSurvivorPresetMenu(context, clickedPositionMenu, player, square, false)

        local exactGroupsOption = roamingMenu:addOption("Original Named Groups - clan gear and behavior")
        local exactGroupsMenu = ISContextMenu:getNew(context)
        roamingMenu:addSubMenu(exactGroupsOption, exactGroupsMenu)

        local exactPlayerOption = exactGroupsMenu:addOption("At My Position")
        local exactPlayerMenu = ISContextMenu:getNew(context)
        exactGroupsMenu:addSubMenu(exactPlayerOption, exactPlayerMenu)
        addExactClanMenu(exactPlayerMenu, player, square, true)

        local exactClickedOption = exactGroupsMenu:addOption("At Clicked Tile")
        local exactClickedMenu = ISContextMenu:getNew(context)
        exactGroupsMenu:addSubMenu(exactClickedOption, exactClickedMenu)
        addExactClanMenu(exactClickedMenu, player, square, false)

        roamingMenu:addOption("Recruitable Armed Seeker At My Position", player, BanditMenu.SpawnRecruitableSurvivor, square, true)
        roamingMenu:addOption("Recruitable Armed Seeker At Clicked Tile", player, BanditMenu.SpawnRecruitableSurvivor, square, false)
    end
end

Events.OnPreFillWorldObjectContextMenu.Add(BanditMenu.WorldContextMenuPre)

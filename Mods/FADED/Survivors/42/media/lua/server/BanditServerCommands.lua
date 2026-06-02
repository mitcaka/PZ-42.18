require "SurvivorZones"
require "BanditServerSpawner"
require "SurvivorCompanions"
require "SurvivorTrade"

local getBarricadeAble = function(x, y, z, index)
    local sq = getCell():getGridSquare(x, y, z)
    if sq and index >= 0 and index < sq:getObjects():size() then
        local o = sq:getObjects():get(index)
        if instanceof(o, 'BarricadeAble') then
            return o
        end
    end
    return nil
end

BanditServer = BanditServer or {}
BanditServer.Commands = {}

local function sendSurvivorZoneNotice(player, text)
    if not sendServerCommand then return end
    local payload = {text = tostring(text or "")}
    local ok = pcall(sendServerCommand, player, "Commands", "SurvivorZoneNotice", payload)
    if not ok then
        pcall(sendServerCommand, "Commands", "SurvivorZoneNotice", payload)
    end
end

local function getPlayerId(player)
    if player and BanditUtils and BanditUtils.GetCharacterID then
        return BanditUtils.GetCharacterID(player)
    end
    return nil
end

local function getPlayerName(player)
    if player and player.getUsername then
        return player:getUsername()
    end
    return nil
end

local function sendRecruitableSurvivorNotice(player, text)
    if not sendServerCommand then return end
    local payload = {
        ownerId = getPlayerId(player),
        text = tostring(text or ""),
    }
    local ok = pcall(sendServerCommand, player, "Commands", "RecruitableSurvivorNotice", payload)
    if not ok then
        pcall(sendServerCommand, "Commands", "RecruitableSurvivorNotice", payload)
    end
end

local function getLiveBanditById(npcId)
    local cell = getCell and getCell() or nil
    local zombieList = cell and cell:getZombieList() or nil
    if not zombieList then return nil end

    for i = 0, zombieList:size() - 1 do
        local zombie = zombieList:get(i)
        if zombie and zombie:getHealth() > 0 and zombie:getVariableBoolean("Bandit") then
            local id = BanditUtils.GetCharacterID(zombie)
            if id and tostring(id) == tostring(npcId) then
                return zombie
            end
        end
    end
    return nil
end

local function getClusterBrain(npcId)
    local numericId = tonumber(npcId)
    if not numericId then return nil, nil, nil end
    local cluster = GetBanditClusterData(numericId)
    local key = cluster and (cluster[numericId] and numericId or tostring(numericId)) or nil
    return numericId, cluster, key and cluster[key] or nil
end

local function getInventoryItems(container)
    if not container or not container.getItems then return nil end
    return container:getItems()
end

local function findInventoryItemById(player, itemId)
    if not player or not itemId then return nil end
    local mainInventory = player:getInventory()
    if not mainInventory then return nil end

    local visited = {}
    local function search(inventory)
        if not inventory or visited[inventory] then return nil end
        visited[inventory] = true
        local items = getInventoryItems(inventory)
        if not items then return nil end

        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and item.getID and item:getID() == itemId then return item end
        end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and instanceof(item, "InventoryContainer") then
                local found = search(item:getInventory())
                if found then return found end
            end
        end
    end
    return search(mainInventory)
end

local function removeInventoryItem(player, item)
    local container = item and item.getContainer and item:getContainer() or (player and player:getInventory())
    if not container or not item then return false end
    if container.DoRemoveItem then container:DoRemoveItem(item) else container:Remove(item) end
    if sendRemoveItemFromContainer then sendRemoveItemFromContainer(container, item) end
    return true
end

local function addInventoryItem(container, itemOrType)
    if not container or not itemOrType then return nil end
    local item = container:AddItem(itemOrType)
    if item and sendAddItemToContainer then sendAddItemToContainer(container, item) end
    return item
end

local function getTradableSurvivor(player, npcId)
    local numericId, cluster, brain = getClusterBrain(npcId)
    if not player or not numericId or not cluster or not SurvivorTrade.IsEligibleBrain(brain) then
        return nil, nil, nil, nil, "That survivor is not available for trade."
    end

    local zombie = getLiveBanditById(numericId)
    if not zombie then return nil, nil, nil, nil, "That survivor is no longer nearby." end

    local distance = BanditUtils.DistTo(player:getX(), player:getY(), zombie:getX(), zombie:getY())
    if math.abs(player:getZ() - zombie:getZ()) > 1 or distance > 6 then
        return nil, nil, nil, nil, "Move closer before trading with that survivor."
    end

    return numericId, cluster, brain, zombie, nil
end

local function sendSurvivorTradeSnapshot(player, npcId, brain, message, announce)
    if not sendServerCommand then return end
    local payload = {
        ownerId=getPlayerId(player),
        npcId=npcId,
        npcName=brain and brain.fullname or "Survivor",
        stock=brain and SurvivorTrade.GetStockRows(SurvivorTrade.EnsureStock(brain)) or {},
        message=tostring(message or ""),
        announce=announce == true,
    }
    local ok = pcall(sendServerCommand, player, "Commands", "SurvivorTradeSnapshot", payload)
    if not ok then pcall(sendServerCommand, "Commands", "SurvivorTradeSnapshot", payload) end
end

local function getOwnedCompanionBrain(player, npcId)
    local numericId, cluster, brain = getClusterBrain(npcId)
    if not brain or not SurvivorCompanions.IsDirectCompanion(brain) then return nil end
    if tostring(brain.master) ~= tostring(getPlayerId(player)) then return nil end
    SurvivorCompanions.NormalizeBrain(brain)
    return numericId, cluster, brain
end

local function applyCompanionOrder(brain, mode, x, y, z)
    mode = tostring(mode or "follow")
    if mode ~= "follow" and mode ~= "stay" and mode ~= "goto" then return false end

    local order = {mode=mode}
    if mode == "stay" or mode == "goto" then
        order.x = tonumber(x)
        order.y = tonumber(y)
        order.z = tonumber(z)
        if not order.x or not order.y or not order.z then return false end
    end

    brain.companionOrder = order
    brain.program = {name="Companion", stage="Prepare"}
    brain.programFallback = "Companion"
    brain.tasks = {}
    return true
end

local function findReviveItem(inventory)
    if not inventory or not inventory.getFirstTypeRecurse then return nil end
    for _, itemType in ipairs({"Base.AlcoholBandage", "Base.Bandage", "Base.RippedSheets"}) do
        local ok, item = pcall(function() return inventory:getFirstTypeRecurse(itemType) end)
        if ok and item then return item end
    end
end

local function getZoneFromArgs(args)
    args = args or {}
    if args.zoneId then
        return SurvivorZones.Get(args.zoneId)
    end
    if args.x and args.y then
        return SurvivorZones.GetNearest(tonumber(args.x), tonumber(args.y), tonumber(args.z) or 0, tonumber(args.maxDistance) or 120)
    end
    return nil
end

local function registerSurvivorZoneBase(zone, player)
    if not zone then return end
    local gmd = GetBanditModData()
    if not gmd then return end

    gmd.Bases = gmd.Bases or {}
    gmd.Bases[zone.baseId] = {
        id = zone.baseId,
        x = zone.x1,
        y = zone.y1,
        x2 = zone.x2,
        y2 = zone.y2,
        z = zone.z,
        cx = zone.x,
        cy = zone.y,
        cz = zone.z,
        radius = zone.radius,
        source = "survivorZone",
        survivorZoneId = zone.id,
        ownerId = getPlayerId(player),
        ownerUsername = getPlayerName(player),
    }
end

BanditServer.Commands.SurvivorZoneCreate = function(player, args)
    if not SurvivorZones.IsAdmin(player) then
        sendSurvivorZoneNotice(player, "Only admins can create survivor zones.")
        return
    end

    args = args or {}
    args.createdBy = args.createdBy or getPlayerName(player)
    if not args.x and player then args.x = player:getX() end
    if not args.y and player then args.y = player:getY() end
    if not args.z and player then args.z = player:getZ() end

    local zone = SurvivorZones.Create(args)
    if not zone then
        sendSurvivorZoneNotice(player, "Survivor zone could not be created.")
        return
    end

    registerSurvivorZoneBase(zone, player)

    if zone.autoWalls and SurvivorZoneServer and SurvivorZoneServer.BuildWalls then
        SurvivorZoneServer.BuildWalls(zone)
    end

    SurvivorZones.Transmit()
    sendSurvivorZoneNotice(player, "Survivor zone created: " .. tostring(zone.name))

    if zone.spawnOnCreate then
        if BanditServer.Spawner and BanditServer.Spawner.SurvivorZone then
            BanditServer.Spawner.SurvivorZone(player, {zoneId = zone.id})
        else
            sendSurvivorZoneNotice(player, "Survivor zone created, but the survivor spawner is not loaded.")
        end
    end
end

BanditServer.Commands.SurvivorZoneSpawn = function(player, args)
    if not SurvivorZones.IsAdmin(player) then
        sendSurvivorZoneNotice(player, "Only admins can spawn survivor zones.")
        return
    end

    local zone = getZoneFromArgs(args)
    if not zone then
        sendSurvivorZoneNotice(player, "No nearby survivor zone found.")
        return
    end

    if BanditServer.Spawner and BanditServer.Spawner.SurvivorZone then
        BanditServer.Spawner.SurvivorZone(player, {zoneId = zone.id, role = args and args.role, size = args and args.size})
    else
        sendSurvivorZoneNotice(player, "Survivor zone spawner is not available yet.")
    end
end

BanditServer.Commands.SurvivorZoneClearZombies = function(player, args)
    if not SurvivorZones.IsAdmin(player) then
        sendSurvivorZoneNotice(player, "Only admins can clear survivor zones.")
        return
    end

    local zone = getZoneFromArgs(args)
    if not zone then
        sendSurvivorZoneNotice(player, "No nearby survivor zone found.")
        return
    end

    sendSurvivorZoneNotice(player, "Survivor zones no longer delete zombies.")
end

BanditServer.Commands.SurvivorZoneBuildWalls = function(player, args)
    if not SurvivorZones.IsAdmin(player) then
        sendSurvivorZoneNotice(player, "Only admins can build survivor zone walls.")
        return
    end

    local zone = getZoneFromArgs(args)
    if not zone then
        sendSurvivorZoneNotice(player, "No nearby survivor zone found.")
        return
    end

    if SurvivorZoneServer and SurvivorZoneServer.BuildWalls then
        local built, reason = SurvivorZoneServer.BuildWalls(zone)
        if built then
            sendSurvivorZoneNotice(player, "Survivor zone wall ring built.")
        else
            sendSurvivorZoneNotice(player, reason or "Survivor zone walls could not be built.")
        end
    else
        sendSurvivorZoneNotice(player, "Survivor zone wall builder is not loaded.")
    end
end

BanditServer.Commands.SurvivorZoneToggle = function(player, args)
    if not SurvivorZones.IsAdmin(player) then
        sendSurvivorZoneNotice(player, "Only admins can change survivor zones.")
        return
    end

    local zone = getZoneFromArgs(args)
    if not zone then
        sendSurvivorZoneNotice(player, "No nearby survivor zone found.")
        return
    end

    zone.enabled = not (zone.enabled ~= false)
    zone.updatedAt = getGameTime():getWorldAgeHours()
    SurvivorZones.Set(zone)
    SurvivorZones.Transmit()
    sendSurvivorZoneNotice(player, tostring(zone.name) .. " enabled: " .. tostring(zone.enabled ~= false))
end

BanditServer.Commands.SurvivorZoneDelete = function(player, args)
    if not SurvivorZones.IsAdmin(player) then
        sendSurvivorZoneNotice(player, "Only admins can delete survivor zones.")
        return
    end

    local zone = getZoneFromArgs(args)
    if not zone then
        sendSurvivorZoneNotice(player, "No nearby survivor zone found.")
        return
    end

    SurvivorZones.Remove(zone.id)
    local gmd = GetBanditModData()
    if gmd and gmd.Bases and zone.baseId then
        gmd.Bases[zone.baseId] = nil
    end
    SurvivorZones.Transmit()
    sendSurvivorZoneNotice(player, "Survivor zone deleted: " .. tostring(zone.name))
end

BanditServer.Commands.PostToggle = function(player, args)
    local gmd = GetBanditModData()
    if not (args.x and args.y and args.z) then return end

    local id = args.x .. "-" .. args.y .. "-" .. args.z
    
    if gmd.Posts[id] then
        gmd.Posts[id] = nil
    else
        gmd.Posts[id] = args
    end
    TransmitBanditModData()
end

BanditServer.Commands.PostUpdate = function(player, args)
    local gmd = GetBanditModData()
    if not (args.x and args.y and args.z) then return end

    local id = args.x .. "-" .. args.y .. "-" .. args.z
    gmd.Posts[id] = args
    TransmitBanditModData()
end

BanditServer.Commands.BaseUpdate = function(player, args)
    local gmd = GetBanditModData()
    if not (args.x and args.y) then return end

    local id = args.x .. "-" .. args.y
    gmd.Bases[id] = args
    TransmitBanditModData()
end

BanditServer.Commands.SurvivorBaseAssign = function(player, args)
    local gmd = GetBanditModData()
    if not args or not args.npcId then return end

    if not gmd.SurvivorBaseAssignments then gmd.SurvivorBaseAssignments = {} end
    if not gmd.Bases then gmd.Bases = {} end

    args.ownerId = args.ownerId or BanditUtils.GetCharacterID(player)
    args.ownerUsername = args.ownerUsername or player:getUsername()
    args.updatedAt = getGameTime():getWorldAgeHours()

    local key = tostring(args.npcId)
    gmd.SurvivorBaseAssignments[key] = args

    local numericId = tonumber(args.npcId)
    if numericId then
        local cluster = GetBanditClusterData(numericId)
        local brain = cluster and (cluster[numericId] or cluster[tostring(numericId)])
        if brain then
            brain.master = args.ownerId
            brain.hostile = false
            brain.hostileP = false
            brain.survivorBase = args
            brain.program = {name="SurvivorBase", stage="Prepare"}
            brain.tasks = {}
            cluster[numericId] = brain
            TransmitBanditCluster(numericId)
        end
    end

    if args.baseId and args.x and args.y then
        gmd.Bases[args.baseId] = {
            id = args.baseId,
            x = args.x,
            y = args.y,
            x2 = args.x2,
            y2 = args.y2,
            ownerId = args.ownerId,
            ownerUsername = args.ownerUsername,
        }
    end

    if SurvivorsCSRBridge and SurvivorsCSRBridge.upsertBaseAssignment then
        SurvivorsCSRBridge.upsertBaseAssignment(args)
    end

    TransmitBanditModData()
end

BanditServer.Commands.SurvivorBaseMode = function(player, args)
    local gmd = GetBanditModData()
    if not args or not args.npcId then return end
    if not gmd.SurvivorBaseAssignments then gmd.SurvivorBaseAssignments = {} end

    local key = tostring(args.npcId)
    local entry = gmd.SurvivorBaseAssignments[key]
    if not entry then return end

    local mode = tostring(args.mode or entry.mode or "defend")
    if mode ~= "defend" and mode ~= "work" and mode ~= "guard" then
        mode = "defend"
    end

    entry.mode = mode
    entry.allowChores = mode == "work"
    entry.updatedAt = getGameTime():getWorldAgeHours()
    gmd.SurvivorBaseAssignments[key] = entry

    if SurvivorsCSRBridge and SurvivorsCSRBridge.setBaseMode then
        SurvivorsCSRBridge.setBaseMode(args.npcId, mode)
    end

    TransmitBanditModData()
end

BanditServer.Commands.SurvivorBaseRemove = function(player, args)
    local gmd = GetBanditModData()
    if not args or not args.npcId then return end
    if not gmd.SurvivorBaseAssignments then gmd.SurvivorBaseAssignments = {} end

    local key = tostring(args.npcId)
    gmd.SurvivorBaseAssignments[key] = nil

    local numericId = tonumber(args.npcId)
    if numericId then
        local cluster = GetBanditClusterData(numericId)
        local brain = cluster and (cluster[numericId] or cluster[tostring(numericId)])
        if brain then
            brain.survivorBase = false
            cluster[numericId] = brain
            TransmitBanditCluster(numericId)
        end
    end

    if SurvivorsCSRBridge and SurvivorsCSRBridge.removeBaseAssignment then
        SurvivorsCSRBridge.removeBaseAssignment(args.npcId)
    end

    TransmitBanditModData()
end

BanditServer.Commands.SurvivorLootRunStart = function(player, args)
    if SurvivorLootRuns and SurvivorLootRuns.Start then
        SurvivorLootRuns.Start(player, args)
    end
end

BanditServer.Commands.SurvivorLootRunCollect = function(player, args)
    if SurvivorLootRuns and SurvivorLootRuns.Collect then
        SurvivorLootRuns.Collect(player, args)
    end
end

BanditServer.Commands.SurvivorTradeRequest = function(player, args)
    local numericId, cluster, brain, zombie, reason = getTradableSurvivor(player, args and args.npcId)
    if not brain then
        sendSurvivorTradeSnapshot(player, args and args.npcId, nil, reason, true)
        return
    end

    SurvivorTrade.EnsureStock(brain)
    cluster[numericId] = brain
    BanditBrain.Update(zombie, brain)
    TransmitBanditCluster(numericId)
    sendSurvivorTradeSnapshot(player, numericId, brain, "Select one item from each column.", false)
end

BanditServer.Commands.SurvivorTradeExchange = function(player, args)
    local numericId, cluster, brain, zombie, reason = getTradableSurvivor(player, args and args.npcId)
    if not brain then
        sendSurvivorTradeSnapshot(player, args and args.npcId, nil, reason, true)
        return
    end

    local stock = SurvivorTrade.EnsureStock(brain)
    local stockType = args and tostring(args.stockType or "") or ""
    local stockEntry = stock[stockType]
    if not stockEntry or (tonumber(stockEntry.count) or 0) <= 0 then
        sendSurvivorTradeSnapshot(player, numericId, brain, "That item is no longer available.", true)
        return
    end

    local offerItem = findInventoryItemById(player, args and tonumber(args.offerItemId))
    if not SurvivorTrade.CanOfferItem(player, offerItem) then
        sendSurvivorTradeSnapshot(player, numericId, brain, "That offered item is no longer available for trade.", true)
        return
    end

    local offerValue = SurvivorTrade.GetItemValue(offerItem)
    local requestedValue = math.max(1, math.floor(tonumber(stockEntry.value) or 1))
    if offerValue < requestedValue then
        sendSurvivorTradeSnapshot(player, numericId, brain, "Your offer value is too low for that item.", true)
        return
    end

    local receivedItem = SurvivorTrade.CreateItem(stockType)
    if not receivedItem then
        sendSurvivorTradeSnapshot(player, numericId, brain, "That survivor could not complete the exchange.", true)
        return
    end

    if not removeInventoryItem(player, offerItem) then
        sendSurvivorTradeSnapshot(player, numericId, brain, "Your offered item could not be removed.", true)
        return
    end

    if not addInventoryItem(player:getInventory(), receivedItem) then
        addInventoryItem(player:getInventory(), offerItem)
        sendSurvivorTradeSnapshot(player, numericId, brain, "The exchange failed and your offered item was returned.", true)
        return
    end

    stockEntry.count = math.max(0, math.floor(tonumber(stockEntry.count) or 0) - 1)
    stock[stockType] = stockEntry
    brain.survivorTradeStock = stock
    brain.survivorTradeCount = (tonumber(brain.survivorTradeCount) or 0) + 1
    cluster[numericId] = brain
    BanditBrain.Update(zombie, brain)
    TransmitBanditCluster(numericId)

    local label = tostring(stockEntry.label or stockType)
    sendSurvivorTradeSnapshot(player, numericId, brain, "Trade complete: received " .. label .. ".", true)
end

BanditServer.Commands.RecruitableSurvivorRecruit = function(player, args)
    local numericId = args and tonumber(args.npcId) or nil
    if not player or not numericId then
        sendRecruitableSurvivorNotice(player, "That survivor could not be recruited.")
        return
    end

    local cluster = GetBanditClusterData(numericId)
    local clusterKey = cluster and (cluster[numericId] and numericId or tostring(numericId)) or nil
    local brain = clusterKey and cluster[clusterKey] or nil
    if not brain
            or brain.recruitableSeeker ~= true
            or not brain.program
            or brain.program.name ~= "RecruitableSurvivor" then
        sendRecruitableSurvivorNotice(player, "That survivor is not looking for a companion.")
        return
    end

    if brain.recruitableSeekerClaimed == true or (brain.master ~= nil and brain.master ~= false) then
        sendRecruitableSurvivorNotice(player, "That survivor has already joined someone else.")
        return
    end

    local zombie = getLiveBanditById(numericId)
    if not zombie then
        sendRecruitableSurvivorNotice(player, "That survivor is no longer available.")
        return
    end

    local distance = BanditUtils.DistTo(player:getX(), player:getY(), zombie:getX(), zombie:getY())
    if math.abs(player:getZ() - zombie:getZ()) > 1 or distance > 6 then
        sendRecruitableSurvivorNotice(player, "Move closer before asking that survivor to join you.")
        return
    end

    brain.master = getPlayerId(player)
    brain.hostile = false
    brain.hostileP = false
    brain.recruitableSeekerClaimed = true
    brain.recruitedBy = getPlayerName(player)
    brain.recruitedAt = getGameTime():getWorldAgeHours()
    brain.program = {name="Companion", stage="Prepare"}
    brain.programFallback = "Companion"
    brain.tasks = {}
    SurvivorCompanions.NormalizeBrain(brain)

    cluster[clusterKey] = brain
    BanditBrain.Update(zombie, brain)
    TransmitBanditCluster(numericId)
    sendRecruitableSurvivorNotice(player, tostring(brain.fullname or "The survivor") .. " joined you as a companion.")
end

BanditServer.Commands.CompanionOrder = function(player, args)
    local numericId, cluster, brain = getOwnedCompanionBrain(player, args and args.npcId)
    if not brain or brain.companionDowned then return end
    if not applyCompanionOrder(brain, args.mode, args.x, args.y, args.z) then return end

    local zombie = getLiveBanditById(numericId)
    if zombie then
        SurvivorCompanions.SetLocalOrder(zombie, args.mode, args.x, args.y, args.z)
    end
    cluster[numericId] = brain
    TransmitBanditCluster(numericId)
end

BanditServer.Commands.CompanionSettings = function(player, args)
    local numericId, cluster, brain = getOwnedCompanionBrain(player, args and args.npcId)
    if not brain then return end

    if args.group then brain.companionGroup = tostring(args.group) end
    if args.combatMode then brain.companionCombatMode = tostring(args.combatMode) end
    if args.loadoutMode then brain.companionLoadoutMode = tostring(args.loadoutMode) end
    SurvivorCompanions.NormalizeBrain(brain)

    cluster[numericId] = brain
    TransmitBanditCluster(numericId)
end

BanditServer.Commands.CompanionGroupOrder = function(player, args)
    if not player or not args or not args.group then return end
    local ownerId = getPlayerId(player)
    local group = tostring(args.group)

    for clusterIndex = 0, BanditClusterCount - 1 do
        local cluster = BanditClusters[clusterIndex]
        local changed = false
        for npcId, brain in pairs(cluster) do
            SurvivorCompanions.NormalizeBrain(brain)
            local zombie = getLiveBanditById(npcId)
            local x, y, z = args.x, args.y, args.z
            if args.mode == "stay" and zombie then
                x, y, z = zombie:getX(), zombie:getY(), zombie:getZ()
            end
            if SurvivorCompanions.IsDirectCompanion(brain)
                    and tostring(brain.master) == tostring(ownerId)
                    and tostring(brain.companionGroup) == group
                    and not brain.companionDowned
                    and applyCompanionOrder(brain, args.mode, x, y, z) then
                cluster[npcId] = brain
                if zombie then
                    SurvivorCompanions.SetLocalOrder(zombie, args.mode, x, y, z)
                end
                changed = true
            end
        end
        if changed then TransmitBanditClusterExpicit(clusterIndex) end
    end
end

BanditServer.Commands.CompanionGroupSettings = function(player, args)
    if not player or not args or not args.group or not args.combatMode then return end
    local ownerId = getPlayerId(player)
    local group = tostring(args.group)

    for clusterIndex = 0, BanditClusterCount - 1 do
        local cluster = BanditClusters[clusterIndex]
        local changed = false
        for npcId, brain in pairs(cluster) do
            SurvivorCompanions.NormalizeBrain(brain)
            if SurvivorCompanions.IsDirectCompanion(brain)
                    and tostring(brain.master) == tostring(ownerId)
                    and tostring(brain.companionGroup) == group then
                brain.companionCombatMode = tostring(args.combatMode)
                SurvivorCompanions.NormalizeBrain(brain)
                cluster[npcId] = brain
                changed = true
            end
        end
        if changed then TransmitBanditClusterExpicit(clusterIndex) end
    end
end

BanditServer.Commands.CompanionRevive = function(player, args)
    local numericId, cluster, brain = getOwnedCompanionBrain(player, args and args.npcId)
    if not brain or not brain.companionDowned then return end

    local zombie = getLiveBanditById(numericId)
    if not zombie then return end
    local distance = BanditUtils.DistTo(player:getX(), player:getY(), zombie:getX(), zombie:getY())
    if math.abs(player:getZ() - zombie:getZ()) > 1 or distance > 4 then
        sendRecruitableSurvivorNotice(player, "Move closer before reviving that companion.")
        return
    end

    local inventory = player:getInventory()
    local item = findReviveItem(inventory)
    if not item then
        sendRecruitableSurvivorNotice(player, "Reviving a companion requires a bandage or ripped sheets.")
        return
    end
    inventory:Remove(item)

    brain.companionDowned = false
    brain.companionMedical = {
        status = "recovering",
        injury = brain.companionMedical and brain.companionMedical.injury or "treated wounds",
        wounds = brain.companionMedical and brain.companionMedical.wounds or 1,
    }
    brain.health = tonumber(brain.companionMaxHealth) or 1
    brain.companionOrder = {mode="follow"}
    brain.program = {name="Companion", stage="Prepare"}
    brain.programFallback = "Companion"
    brain.tasks = {}
    brain.companionSkills.survival = brain.companionSkills.survival + 2

    zombie:setHealth(brain.health)
    Bandit.ForceStationary(zombie, false)
    pcall(function() zombie:setKnockedDown(false) end)
    BanditBrain.Update(zombie, brain)
    cluster[numericId] = brain
    TransmitBanditCluster(numericId)
    sendRecruitableSurvivorNotice(player, tostring(brain.fullname or "Your companion") .. " is back on their feet.")
end

BanditServer.Commands.BanditRemove  = function(player, args)
    local id = args.id
    if id then
        local gmd = GetBanditClusterData(id)
        if gmd[id] then
            gmd[id] = nil
            -- print ("[INFO] Bandit removed: " .. id)
        end
        TransmitBanditCluster(id)
    end
end

BanditServer.Commands.BanditFlush  = function(player, args)
    local gmd = GetBanditModData()
    gmd.VisitedBuildings = {}
    gmd.Posts = {}
    gmd.Bases = {}
    TransmitBanditModData()
    print ("[INFO] All bandits removed!!!")
end

BanditServer.Commands.BanditUpdatePart = function(player, args)
    local id = args.id
    if id then
        local gmd = GetBanditClusterData(id)
        if gmd[id] then
            local brain = gmd[id]
            for k, v in pairs(args) do
                brain[k] = v
                -- print ("[INFO] Bandit sync id: " .. id .. " key: " .. k)
            end

            gmd[id] = brain
            TransmitBanditCluster(id)
            --sendServerCommand('Commands', 'UpdateBanditPart', args)
        end
    end
end

BanditServer.Commands.BanditCorpse = function(player, args)

    local cell = getCell()
    local square = cell:getGridSquare(args.x, args.y, args.z)
    local body
    if square then
        local objects = square:getStaticMovingObjects()
        for i=0, objects:size()-1 do
            print ("found static obj")
            local object = objects:get(i)
            if instanceof (object, "IsoDeadBody") then
                print ("found dead body")
                local md = object:getModData()
                if md.brainId == args.id then
                    print ("found the right dead body")
                    body = object
                    break
                end
            end
        end
    end

    if body then
        print ("SERVER FOUND DEAD BANDIT BODY")
        body:sync()
        
    end
end

BanditServer.Commands.Unbarricade = function(player, args)
    local object = getBarricadeAble(args.x, args.y, args.z, args.index)
    if object then
        local barricade = object:getBarricadeOnSameSquare()
        if not barricade then barricade = object:getBarricadeOnOppositeSquare() end
        if barricade then
            if barricade:isMetal() then
                local metal = barricade:removeMetal(nil)
            elseif barricade:isMetalBar() then
                local bar = barricade:removeMetalBar(nil)
            else
                local plank = barricade:removePlank(nil)
                if barricade:getNumPlanks() > 0 then
                    barricade:sendObjectChange(IsoObjectChange.STATE)
                end
            end
        end
    end
end

BanditServer.Commands.Barricade = function(player, args)
    local object = getBarricadeAble(args.x, args.y, args.z, args.index)
    if object then
        local barricade = IsoBarricade.AddBarricadeToObject(object, player)
        if barricade then
            if not barricade:isMetal() and args.isMetal then
                local metal = BanditCompatibility.InstanceItem("Base.SheetMetal")
                metal:setCondition(args.condition)
                barricade:addMetal(nil, metal)
                barricade:transmitCompleteItemToClients()
            elseif not barricade:isMetalBar() and args.isMetalBar then
                local metal = BanditCompatibility.InstanceItem("Base.MetalBar")
                metal:setCondition(args.condition)
                barricade:addMetalBar(nil, metal)
                barricade:transmitCompleteItemToClients()
            elseif barricade:getNumPlanks() < 4 then
                local plank = BanditCompatibility.InstanceItem("Base.Plank")
                plank:setCondition(args.condition)
                barricade:addPlank(nil, plank)
                if barricade:getNumPlanks() == 1 then
                    barricade:transmitCompleteItemToClients()
                else
                    barricade:sendObjectChange(IsoObjectChange.STATE)
                end
            end
        end
    else
        noise('expected BarricadeAble')
    end
end

BanditServer.Commands.OpenDoor = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, args.z)
    if sq and args.index >= 0 and args.index < sq:getObjects():size() then
        local object = sq:getObjects():get(args.index)
        if instanceof(object, "IsoDoor") or (instanceof(object, 'IsoThumpable') and object:isDoor() == true) then
            if not object:IsOpen() then
                object:ToggleDoorSilent()
            end
        end
    end
end

BanditServer.Commands.CloseDoor = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, args.z)
    if sq and args.index >= 0 and args.index < sq:getObjects():size() then
        local object = sq:getObjects():get(args.index)
        if instanceof(object, "IsoDoor") or (instanceof(object, 'IsoThumpable') and object:isDoor() == true) then
            if object:IsOpen() then
                object:ToggleDoorSilent()
            end
        end
    end
end

BanditServer.Commands.LockDoor = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, args.z)
    if sq and args.index >= 0 and args.index < sq:getObjects():size() then
        local object = sq:getObjects():get(args.index)
        if instanceof(object, "IsoDoor") or (instanceof(object, 'IsoThumpable') and object:isDoor() == true) then
            if not object:isLockedByKey() then
                object:setLockedByKey(true)
            end
        end
    end
end

BanditServer.Commands.UnlockDoor = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, args.z)
    if sq and args.index >= 0 and args.index < sq:getObjects():size() then
        local object = sq:getObjects():get(args.index)
        if instanceof(object, "IsoDoor") or (instanceof(object, 'IsoThumpable') and object:isDoor() == true) then
            if object:isLockedByKey() then
                object:setLockedByKey(false)
            end
        end
    end
end

BanditServer.Commands.VehiclePartRemove = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, 0)
    if sq then
        local vehicle = sq:getVehicleContainer()
        if vehicle then
            local vehiclePart = vehicle:getPartById(args.id)
            if vehiclePart then
                vehiclePart:setInventoryItem(nil)
                vehicle:transmitPartItem(vehiclePart)
                vehicle:updatePartStats()
            end
        end
    end
end

BanditServer.Commands.VehiclePartDamage = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, 0)
    if sq then
        local vehicle = sq:getVehicleContainer()
        if vehicle then
            local vehiclePart = vehicle:getPartById(args.id)
            if vehiclePart then
                vehiclePart:damage(args.dmg)

                if vehiclePart:getCondition() <= 0 then
                    vehiclePart:setInventoryItem(nil)
                    vehicle:transmitPartItem(vehiclePart)
                else
                    vehicle:transmitPartCondition(vehiclePart)
                end
                vehicle:updatePartStats()
            end
        end
    end
end

BanditServer.Commands.IncrementBanditKills = function(player, args)
    local gmd = GetBanditModData()
    local id = BanditUtils.GetCharacterID(player)
    if gmd.Kills[id] then
        gmd.Kills[id] = gmd.Kills[id] + 1
    else
        gmd.Kills[id] = 1
    end
    TransmitBanditModData()
end

BanditServer.Commands.ResetBanditKills = function(player, args)
    local gmd = GetBanditModData()
    local id = BanditUtils.GetCharacterID(player)
    if gmd.Kills[id] then
        gmd.Kills[id] = 0
    end
    TransmitBanditModData()
end

BanditServer.Commands.UpdateVisitedBuilding = function(player, args)
    local gmd = GetBanditModData()
    gmd.VisitedBuildings[args.bid] = args.wah
    TransmitBanditModData()
end

BanditServer.Commands.PlayerDamage = function(player, args)
    local bodyDamage = player:getBodyDamage()
    local stats = player:getStats()
    local health = bodyDamage:getOverallBodyHealth()

    if args.healthDrop then
        bodyDamage:ReduceGeneralHealth(args.healthDrop)
    end

    if args.intoxication then
        stats:set(CharacterStat.INTOXICATION, args.intoxication)
    end

    if args.sickness then
        stats:set(CharacterStat.FOOD_SICKNESS, args.sickness)
    end

    if args.bodyPartIndex then
        local bodyPart = bodyDamage:getBodyParts():get(args.bodyPartIndex)
        local bloodBodyPart = BloodBodyPartType.FromIndex(args.bodyPartIndex)
        
        if args.scratched then
            bodyPart:setScratched(true, true)
        end

        if args.cut then
            bodyPart:setCut(true)
        end

        if args.deepWound then
            bodyPart:generateDeepWound()
        end

        if args.bullet then
            bodyPart:setHaveBullet(true, 1)
        end

        if args.blood then
            player:addBlood(bloodBodyPart, false, true, false)
        end

        if args.hole and args.holeAllLayers then
            player:addHole(bloodBodyPart, args.holeAllLayers)
        end
    end
end

local onClientCommand = function(module, command, player, args)
    if module == "Commands" and BanditServer[module] and BanditServer[module][command] then
        local argStr = ""
        for k, v in pairs(args) do
            argStr = argStr .. " " .. k .. "=" .. tostring(v)
        end
        -- print ("received " .. module .. "." .. command .. " "  .. argStr)
        BanditServer[module][command](player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)

-- Soft compatibility bridge for Common Sense Reborn main/test builds.
-- CSR can use this global directly without requiring Survivors as a hard dependency.

SurvivorsCSRBridge = SurvivorsCSRBridge or {}
Survivors = Survivors or {}

local Bridge = SurvivorsCSRBridge

Bridge.VERSION = 1
Bridge.MODULE = "SurvivorsCSRBridge"
Bridge.EVENT = "OnSurvivorsCSRBridgeEvent"
Bridge.CSR_MAIN_ID = "CommonSenseReborn"
Bridge.CSR_TEST_ID = "CommonSenseRebornTest"
Bridge.CAPABILITIES = {
    "status",
    "baseAssignments",
    "survivorSnapshots",
    "baseModeControl",
    "lootRuns",
    "lootRunControl",
    "eventNotifications",
}

Bridge.providers = Bridge.providers or {}
Bridge.lastEvents = Bridge.lastEvents or {}

Survivors.API = Bridge
Survivors.Bridge = Bridge

local function copyArray(list)
    local out = {}
    for i, value in ipairs(list or {}) do
        out[i] = value
    end
    return out
end

local function isModActive(modId)
    if not modId or not getActivatedMods then return false end
    local mods = getActivatedMods()
    return mods and mods:contains(modId) == true
end

local function getNow()
    if getGameTime then
        local gt = getGameTime()
        if gt and gt.getWorldAgeHours then
            return gt:getWorldAgeHours()
        end
    end
    return 0
end

local function ensureGlobalTables()
    if not GetBanditModData then return nil end
    local gmd = GetBanditModData()
    if not gmd then return nil end
    if not gmd.SurvivorBaseAssignments then gmd.SurvivorBaseAssignments = {} end
    if not gmd.SurvivorLootRuns then gmd.SurvivorLootRuns = {} end
    if not gmd.SurvivorBridge then gmd.SurvivorBridge = {} end
    if not gmd.Bases then gmd.Bases = {} end
    return gmd
end

local function sanitizeAssignment(data)
    if type(data) ~= "table" then return nil end
    local npcId = data.npcId or data.id
    if not npcId then return nil end

    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local x2 = tonumber(data.x2)
    local y2 = tonumber(data.y2)
    local cx = tonumber(data.cx) or (x and x2 and ((x + x2) / 2)) or tonumber(data.homeX)
    local cy = tonumber(data.cy) or (y and y2 and ((y + y2) / 2)) or tonumber(data.homeY)
    local z = tonumber(data.z) or tonumber(data.cz) or 0

    local mode = tostring(data.mode or "defend")
    if mode ~= "defend" and mode ~= "work" and mode ~= "guard" then
        mode = "defend"
    end

    return {
        npcId = tonumber(npcId) or npcId,
        baseId = tostring(data.baseId or ((x and y) and (math.floor(x) .. "-" .. math.floor(y)) or "")),
        ownerId = tonumber(data.ownerId) or tonumber(data.playerId),
        ownerUsername = data.ownerUsername or data.username,
        mode = mode,
        x = x,
        y = y,
        x2 = x2,
        y2 = y2,
        z = z,
        cx = cx,
        cy = cy,
        cz = z,
        radius = tonumber(data.radius) or 45,
        allowChores = data.allowChores == true or mode == "work",
        updatedAt = tonumber(data.updatedAt) or getNow(),
    }
end

function Bridge.isModActive(modId)
    return isModActive(modId)
end

function Bridge.getActiveCSRIds()
    local ids = {}
    if isModActive(Bridge.CSR_MAIN_ID) then table.insert(ids, Bridge.CSR_MAIN_ID) end
    if isModActive(Bridge.CSR_TEST_ID) then table.insert(ids, Bridge.CSR_TEST_ID) end
    return ids
end

function Bridge.isCSRActive()
    return #Bridge.getActiveCSRIds() > 0
end

function Bridge.getStatus()
    return {
        ok = true,
        source = "Survivors",
        modId = "Survivors",
        apiVersion = Bridge.VERSION,
        module = Bridge.MODULE,
        event = Bridge.EVENT,
        csrActive = Bridge.isCSRActive(),
        activeCSRIds = Bridge.getActiveCSRIds(),
        capabilities = copyArray(Bridge.CAPABILITIES),
    }
end

function Bridge.registerCSRProvider(providerId, api)
    providerId = tostring(providerId or "CommonSenseReborn")
    if type(api) ~= "table" then return false, "apiTableRequired" end
    Bridge.providers[providerId] = api
    Bridge.emit("CSRProviderRegistered", { providerId = providerId })
    return true, Bridge.getStatus()
end

function Bridge.unregisterCSRProvider(providerId)
    providerId = tostring(providerId or "CommonSenseReborn")
    Bridge.providers[providerId] = nil
    Bridge.emit("CSRProviderUnregistered", { providerId = providerId })
end

function Bridge.emit(eventName, payload)
    eventName = tostring(eventName or "Unknown")
    payload = payload or {}
    payload.source = payload.source or "Survivors"
    payload.apiVersion = payload.apiVersion or Bridge.VERSION
    Bridge.lastEvents[eventName] = payload

    if triggerEvent then
        pcall(triggerEvent, Bridge.EVENT, eventName, payload)
    end

    for providerId, provider in pairs(Bridge.providers) do
        local fn = provider and provider.onSurvivorsEvent
        if type(fn) == "function" then
            pcall(fn, eventName, payload, providerId)
        end
    end
end

function Bridge.notify(eventName, payload)
    Bridge.emit(eventName, payload)
    if isServer and isServer() and sendServerCommand then
        sendServerCommand(Bridge.MODULE, "BridgeEvent", {
            event = eventName,
            payload = payload or {},
        })
    end
end

function Bridge.upsertBaseAssignment(data)
    local entry = sanitizeAssignment(data)
    if not entry then return nil end

    local gmd = ensureGlobalTables()
    if gmd then
        local key = tostring(entry.npcId)
        gmd.SurvivorBaseAssignments[key] = entry
        if entry.baseId ~= "" and entry.x and entry.y then
            gmd.Bases[entry.baseId] = {
                id = entry.baseId,
                x = entry.x,
                y = entry.y,
                x2 = entry.x2,
                y2 = entry.y2,
                ownerId = entry.ownerId,
                ownerUsername = entry.ownerUsername,
            }
        end
        if isServer and isServer() and TransmitBanditModData then
            TransmitBanditModData()
        end
    end

    Bridge.notify("BaseAssignmentChanged", entry)
    return entry
end

function Bridge.removeBaseAssignment(npcId)
    local gmd = ensureGlobalTables()
    if not gmd or not npcId then return false end
    local key = tostring(npcId)
    local old = gmd.SurvivorBaseAssignments[key]
    gmd.SurvivorBaseAssignments[key] = nil
    if isServer and isServer() and TransmitBanditModData then
        TransmitBanditModData()
    end

    local numericId = tonumber(npcId)
    if numericId and GetBanditClusterData then
        local cluster = GetBanditClusterData(numericId)
        local brain = cluster and (cluster[numericId] or cluster[tostring(numericId)])
        if type(brain) == "table" then
            brain.survivorBase = false
            cluster[numericId] = brain
            if TransmitBanditCluster then
                TransmitBanditCluster(numericId)
            end
        end
    end

    Bridge.notify("BaseAssignmentRemoved", { npcId = npcId, old = old })
    return true
end

function Bridge.setBaseMode(npcId, mode)
    local gmd = ensureGlobalTables()
    if not gmd or not npcId then return false end
    local key = tostring(npcId)
    local entry = gmd.SurvivorBaseAssignments[key]
    if not entry then return false end
    entry.mode = mode
    entry.allowChores = mode == "work"
    entry.updatedAt = getNow()
    gmd.SurvivorBaseAssignments[key] = entry
    if isServer and isServer() and TransmitBanditModData then
        TransmitBanditModData()
    end

    local numericId = tonumber(npcId)
    if numericId and GetBanditClusterData then
        local cluster = GetBanditClusterData(numericId)
        local brain = cluster and (cluster[numericId] or cluster[tostring(numericId)])
        if type(brain) == "table" then
            brain.survivorBase = brain.survivorBase or {}
            brain.survivorBase.mode = mode
            brain.survivorBase.allowChores = mode == "work"
            brain.program = {name="SurvivorBase", stage="Prepare"}
            cluster[numericId] = brain
            if TransmitBanditCluster then
                TransmitBanditCluster(numericId)
            end
        end
    end

    Bridge.notify("BaseAssignmentChanged", entry)
    return true
end

function Bridge.getBaseAssignments()
    local gmd = ensureGlobalTables()
    return (gmd and gmd.SurvivorBaseAssignments) or {}
end

function Bridge.getBaseAssignment(npcId)
    if not npcId then return nil end
    local assignments = Bridge.getBaseAssignments()
    return assignments[tostring(npcId)]
end

function Bridge.getLootRuns()
    local gmd = ensureGlobalTables()
    return (gmd and gmd.SurvivorLootRuns) or {}
end

function Bridge.getLootRun(npcId)
    if not npcId then return nil end
    local runs = Bridge.getLootRuns()
    return runs[tostring(npcId)]
end

function Bridge.getSurvivorSnapshot(npcId)
    if not npcId then return nil end

    local assignment = Bridge.getBaseAssignment(npcId)
    local lootRun = Bridge.getLootRun(npcId)
    local brain
    local numericId = tonumber(npcId)
    if numericId and GetBanditClusterData then
        local cluster = GetBanditClusterData(numericId)
        brain = cluster and (cluster[numericId] or cluster[tostring(numericId)])
    end

    local brainView
    if type(brain) == "table" then
        brainView = {
            id = brain.id,
            fullname = brain.fullname,
            master = brain.master,
            hostile = brain.hostile == true,
            hostileP = brain.hostileP == true,
            program = brain.program,
            survivorBase = brain.survivorBase,
            survivorLootRun = brain.survivorLootRun,
        }
    end

    return {
        npcId = npcId,
        assignment = assignment,
        lootRun = lootRun,
        brain = brainView,
    }
end

function Bridge.handleCSRRequest(player, command, args)
    command = tostring(command or "")
    args = args or {}

    if command == "Hello" or command == "GetStatus" then
        return "Status", Bridge.getStatus()
    elseif command == "GetBaseAssignments" then
        return "BaseAssignments", { assignments = Bridge.getBaseAssignments() }
    elseif command == "GetLootRuns" then
        return "LootRuns", { runs = Bridge.getLootRuns() }
    elseif command == "GetLootRun" then
        return "LootRun", {
            npcId = args.npcId,
            run = Bridge.getLootRun(args.npcId),
        }
    elseif command == "GetSurvivorSnapshot" then
        return "SurvivorSnapshot", Bridge.getSurvivorSnapshot(args.npcId)
    elseif command == "SetBaseMode" then
        return "BaseModeResult", {
            npcId = args.npcId,
            ok = Bridge.setBaseMode(args.npcId, args.mode),
            mode = args.mode,
        }
    elseif command == "StartLootRun" then
        if SurvivorLootRuns and SurvivorLootRuns.Start then
            local ok, result = SurvivorLootRuns.Start(player, args)
            return "LootRunStartRequested", {
                npcId = args.npcId,
                category = args.category,
                ok = ok == true,
                result = ok and result or nil,
                error = ok and nil or result,
            }
        end
        return "LootRunStartRequested", {
            npcId = args.npcId,
            category = args.category,
            ok = false,
            error = "lootRunServiceUnavailable",
        }
    elseif command == "CollectLootRun" then
        if SurvivorLootRuns and SurvivorLootRuns.Collect then
            local ok, result = SurvivorLootRuns.Collect(player, args)
            return "LootRunCollectRequested", {
                npcId = args.npcId,
                ok = ok == true,
                result = ok and result or nil,
                error = ok and nil or result,
            }
        end
        return "LootRunCollectRequested", {
            npcId = args.npcId,
            ok = false,
            error = "lootRunServiceUnavailable",
        }
    end

    return "Error", { error = "unknownCommand", command = command }
end

if LuaEventManager and LuaEventManager.AddEvent then
    pcall(LuaEventManager.AddEvent, Bridge.EVENT)
end

Bridge.emit("Ready", Bridge.getStatus())

return Bridge

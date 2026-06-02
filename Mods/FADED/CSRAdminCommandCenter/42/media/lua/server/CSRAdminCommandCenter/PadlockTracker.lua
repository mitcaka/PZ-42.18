require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/AdminAccess"
require "CSRAdminCommandCenter/CSRAdapter"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/Data/Schemas"

local ACC = CSRAdminCommandCenter
ACC.PadlockTracker = ACC.PadlockTracker or {}

local Padlocks = ACC.PadlockTracker
local Keys = ACC.Schemas.Keys

Padlocks.cache = Padlocks.cache or { rows = {}, targets = {}, refreshedAt = 0, scannedTiles = 0 }

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function nowSeconds()
    if getTimestampMs then return (tonumber(getTimestampMs()) or 0) / 1000 end
    if os and os.time then return os.time() end
    return 0
end

local function squareOf(x, y, z)
    if not getCell then return nil end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(x, y, z or 0)
end

local function hasPadlock(obj)
    if not obj or not obj.getModData then return false end
    local md = obj:getModData()
    return md and md.csrPadlocked == 1
end

local function keyTail(value)
    local text = tostring(value or "")
    if string.len(text) <= 4 then return text end
    return string.sub(text, string.len(text) - 3)
end

local function objectName(obj)
    if not obj then return "" end
    local name = ""
    if obj.getName then
        name = tostring(obj:getName() or "")
    end
    if name ~= "" then return name end
    if obj.getObjectName then
        name = tostring(obj:getObjectName() or "")
    end
    if name ~= "" then return name end
    if obj.getSprite then
        local sprite = obj:getSprite()
        if sprite and sprite.getName then name = tostring(sprite:getName() or "") end
    end
    return name ~= "" and name or "World container"
end

local function vehicleScript(vehicle, fallback)
    local name = tostring(fallback or "")
    if not vehicle then return name end
    if vehicle.getScript then
        local script = vehicle:getScript()
        if script and script.getName then name = tostring(script:getName() or name) end
    end
    return name
end

local function findObjectTarget(target)
    if type(target) ~= "table" then return nil end
    local sq = squareOf(tonumber(target.x), tonumber(target.y), tonumber(target.z))
    if not sq or not sq.getObjects then return nil end
    local objs = sq:getObjects()
    if not objs then return nil end
    local wantedIndex = tonumber(target.objectIndex)
    local n = (objs.size and objs:size()) or 0
    if wantedIndex and wantedIndex >= 0 and wantedIndex < n then
        local obj = objs:get(wantedIndex)
        if hasPadlock(obj) then return obj end
    end
    for i = 0, n - 1 do
        local obj = objs:get(i)
        if hasPadlock(obj) then return obj end
    end
    return nil
end

local function csrPadlockRemoveArgs(targetInfo, isVehicle)
    if type(targetInfo) ~= "table" then return nil, "Padlock target not found. Refresh and try again." end
    if isVehicle then
        local vehicleKey = tostring(targetInfo.vehicleKey or "")
        if vehicleKey == "" then return nil, "Vehicle identity key is missing. Refresh and try again." end
        return { vehicleKey = vehicleKey }, ""
    end
    local x = tonumber(targetInfo.x)
    local y = tonumber(targetInfo.y)
    local z = tonumber(targetInfo.z) or 0
    if not x or not y then return nil, "Object coordinates are missing. Refresh and try again." end
    return { x = math.floor(x), y = math.floor(y), z = math.floor(z) }, ""
end

local function resolveTarget(targetKey)
    local target = Padlocks.cache.targets and Padlocks.cache.targets[tostring(targetKey or "")]
    if type(target) ~= "table" then return nil, false, "Padlock target not found. Refresh and try again." end
    if target.isVehicle then
        local vehicleKey = tostring(target.vehicleKey or "")
        if vehicleKey == "" then return nil, true, "Vehicle identity key is missing. Refresh and try again." end

        local vehicle = ACC.VehicleIdentity.findLoadedVehicleByKey(vehicleKey)
        if not vehicle then return nil, true, "Vehicle is not loaded right now" end
        if not ACC.VehicleIdentity.vehicleHasKey(vehicle, vehicleKey) then
            return nil, true, "Vehicle identity no longer matches this claim"
        end
        if not hasPadlock(vehicle) then return nil, true, "Vehicle is no longer padlocked" end
        return vehicle, true, ""
    end
    local obj = findObjectTarget(target)
    if not obj then return nil, false, "World object is not loaded or no longer padlocked" end
    return obj, false, ""
end

local function rowFromPadlockedObject(out, targetKey, obj, md, row, x, y, z, objectIndex, label)
    local claimId = tonumber(md.csrPadlockClaim) or tonumber(row and row.id) or 0
    out[#out + 1] = {
        id = #out + 1,
        targetKey = targetKey,
        targetKind = "container",
        claimId = claimId,
        claimKind = tostring(row and row.kind or ""),
        claimOwner = tostring(row and row.owner or ""),
        claimTitle = tostring(row and row.title or ""),
        padlockOwner = tostring(md.csrPadlockOwner or ""),
        lockType = tostring(md.csrPadlockType or "Base.Padlock"),
        keyTail = keyTail(md.csrPadlockKeyHash),
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        z = tonumber(z) or 0,
        objectIndex = tonumber(objectIndex) or 0,
        objectName = label or objectName(obj),
        loaded = true,
    }
end

local function scanSquare(row, sq, out, targets)
    if not sq or not sq.getObjects then return end
    local objs = sq:getObjects()
    if not objs then return end
    local n = (objs.size and objs:size()) or 0
    for i = 0, n - 1 do
        local obj = objs:get(i)
        if hasPadlock(obj) then
            local md = obj:getModData()
            local x, y, z = 0, 0, 0
            if sq.getX then x = sq:getX() end
            if sq.getY then y = sq:getY() end
            if sq.getZ then z = sq:getZ() end
            local targetKey = "object:" .. tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
                .. ":" .. tostring(i) .. ":" .. tostring(md.csrPadlockClaim or "")
            targets[targetKey] = {
                targetKey = targetKey,
                isVehicle = false,
                x = x,
                y = y,
                z = z,
                objectIndex = i,
            }
            rowFromPadlockedObject(out, targetKey, obj, md, row, x, y, z, i, objectName(obj))
        end
    end
end

local function scanClaimArea(row, out, targets, budget)
    if not row or row.kind == "vehicle" then return budget end
    local x1 = math.floor(tonumber(row.x) or 0)
    local y1 = math.floor(tonumber(row.y) or 0)
    local w = ACC.clampNumber(row.w, 1, 200, 1)
    local h = ACC.clampNumber(row.h, 1, 200, 1)
    local maxZ = ACC.clampNumber(ACC.sandbox().PadlockScanMaxZ, 0, 7, 3)
    for z = 0, maxZ do
        for x = x1, x1 + w - 1 do
            for y = y1, y1 + h - 1 do
                if budget <= 0 then return 0 end
                budget = budget - 1
                local sq = squareOf(x, y, z)
                if sq then scanSquare(row, sq, out, targets) end
            end
        end
    end
    return budget
end

local function scanVehicleClaim(row, out, targets)
    if not row or row.kind ~= "vehicle" then return end

    local vehicle, ident, conflict = ACC.VehicleIdentity.loadedVehicleFor(row, row)
    if conflict ~= "" or not vehicle then return end

    local vehicleKey = ACC.VehicleIdentity.durableKeyForRow(row)
    if vehicleKey == "" then vehicleKey = ACC.VehicleIdentity.durableKeyForRow(ident) end
    if vehicleKey == "" or not ACC.VehicleIdentity.vehicleHasKey(vehicle, vehicleKey) then return end

    if not vehicle or not hasPadlock(vehicle) then return end
    local md = vehicle:getModData()
    local x = tonumber(row.lastVehicleX) or tonumber(row.x) or 0
    local y = tonumber(row.lastVehicleY) or tonumber(row.y) or 0
    local z = tonumber(row.lastVehicleZ) or tonumber(row.z) or 0
    if vehicle.getX then x = math.floor(tonumber(vehicle:getX()) or x) end
    if vehicle.getY then y = math.floor(tonumber(vehicle:getY()) or y) end
    if vehicle.getZ then z = math.floor(tonumber(vehicle:getZ()) or z) end
    local targetKey = "vehicle:" .. vehicleKey
    targets[targetKey] = {
        targetKey = targetKey,
        isVehicle = true,
        vehicleKey = vehicleKey,
    }
    out[#out + 1] = {
        id = #out + 1,
        targetKey = targetKey,
        targetKind = "vehicle",
        claimId = tonumber(row.id) or tonumber(md.csrPadlockClaim) or 0,
        claimKind = "vehicle",
        claimOwner = tostring(row.owner or ""),
        claimTitle = tostring(row.title or ""),
        padlockOwner = tostring(md.csrPadlockOwner or ""),
        lockType = tostring(md.csrPadlockType or "Base.Padlock"),
        keyTail = keyTail(md.csrPadlockKeyHash),
        x = x,
        y = y,
        z = z,
        vehicleKey = vehicleKey,
        vehicleScript = vehicleScript(vehicle, row.vehicleScript),
        objectName = vehicleScript(vehicle, row.vehicleScript),
        loaded = true,
    }
end

function Padlocks.refresh(force)
    local now = nowSeconds()
    if force ~= true and now - (tonumber(Padlocks.cache.refreshedAt) or 0) < 8 then
        return Padlocks.cache
    end

    local rows = ACC.CSRAdapter.getAllClaimRows()
    local out = {}
    local targets = {}
    local sb = ACC.sandbox()
    local budget = ACC.clampNumber(sb.PadlockScanTileCap, 100, 20000, 2500)

    for i = 1, #rows do
        if rows[i].kind == "vehicle" then
            scanVehicleClaim(rows[i], out, targets)
        end
    end

    for i = 1, #rows do
        if rows[i].kind ~= "vehicle" then
            budget = scanClaimArea(rows[i], out, targets, budget)
            if budget <= 0 then break end
        end
    end

    Padlocks.cache = {
        rows = out,
        targets = targets,
        refreshedAt = now,
        scannedTiles = (ACC.clampNumber(sb.PadlockScanTileCap, 100, 20000, 2500) - budget),
    }
    return Padlocks.cache
end

local function rowMatches(row, args)
    if type(row) ~= "table" then return false end
    args = args or {}
    local targetKind = tostring(args.targetKind or "")
    if targetKind ~= "" and targetKind ~= "all" and row.targetKind ~= targetKind then return false end
    local owner = lower(args.owner or "")
    if owner ~= "" then
        local hasOwner = string.find(lower(row.padlockOwner), owner, 1, true)
            or string.find(lower(row.claimOwner), owner, 1, true)
        if not hasOwner then return false end
    end
    local query = lower(args.query or "")
    if query ~= "" then
        local haystack = lower(table.concat({
            row.targetKind or "",
            row.claimId or "",
            row.claimOwner or "",
            row.claimTitle or "",
            row.padlockOwner or "",
            row.objectName or "",
            row.vehicleScript or "",
            row.x or "",
            row.y or "",
        }, " "))
        if not string.find(haystack, query, 1, true) then return false end
    end
    return true
end

function Padlocks.buildPage(args)
    args = args or {}
    local cache = Padlocks.refresh(args.force == true)
    local filtered = {}
    for i = 1, #cache.rows do
        if rowMatches(cache.rows[i], args) then filtered[#filtered + 1] = cache.rows[i] end
    end

    local pageSize = ACC.clampNumber(args.pageSize or ACC.sandbox().MaxRowsPerPage, 10, 200, 50)
    local page = math.max(1, tonumber(args.page) or 1)
    local total = #filtered
    local totalPages = math.max(1, math.ceil(total / pageSize))
    if page > totalPages then page = totalPages end
    local startIndex = ((page - 1) * pageSize) + 1
    local endIndex = math.min(total, startIndex + pageSize - 1)
    local pageRows = {}
    for i = startIndex, endIndex do pageRows[#pageRows + 1] = filtered[i] end

    return {
        rows = pageRows,
        page = page,
        pageSize = pageSize,
        total = total,
        totalPages = totalPages,
        query = tostring(args.query or ""),
        owner = tostring(args.owner or ""),
        targetKind = tostring(args.targetKind or "all"),
        scannedTiles = tonumber(cache.scannedTiles) or 0,
        refreshedAt = tonumber(cache.refreshedAt) or 0,
    }
end

function Padlocks.summary()
    local cache = Padlocks.cache or { rows = {}, scannedTiles = 0 }
    local vehicle = 0
    local container = 0
    for i = 1, #cache.rows do
        if cache.rows[i].targetKind == "vehicle" then vehicle = vehicle + 1 else container = container + 1 end
    end
    return {
        total = #cache.rows,
        vehicle = vehicle,
        container = container,
        scannedTiles = tonumber(cache.scannedTiles) or 0,
    }
end

local function audit(event, claimRow, actor, target, data)
    if CSR_ClaimAudit and CSR_ClaimAudit.log then
        CSR_ClaimAudit.log(event, claimRow or {}, actor, target or "", data or {})
    end
end

function Padlocks.action(player, args)
    args = args or {}
    local action = tostring(args.action or "")
    local targetKey = tostring(args.targetKey or "")
    if targetKey == "" then return false, "Select a padlock first" end

    local targetInfo = Padlocks.cache.targets and Padlocks.cache.targets[targetKey]
    local target, isVehicle, err = resolveTarget(targetKey)
    if not target then return false, err or "Padlock target unavailable" end
    local md = target.getModData and target:getModData() or nil
    if not md or md.csrPadlocked ~= 1 then return false, "Target is no longer padlocked" end

    local claimId = tonumber(md.csrPadlockClaim) or 0
    local claimRow = claimId > 0 and ACC.CSRAdapter.getClaimRowById(claimId) or nil

    if action == "remove" then
        if not CSR_PadlockServer or not CSR_PadlockServer.handleRemove then
            return false, "CSR padlock remove API not detected"
        end
        local removeArgs, why = csrPadlockRemoveArgs(targetInfo, isVehicle)
        if not removeArgs then return false, why or "Padlock target unavailable" end
        CSR_PadlockServer.handleRemove(player, removeArgs)
        ACC.Persistence.enqueue("padlocks", "padlock action=remove_requested target=" .. targetKey
            .. " claimId=" .. tostring(claimId)
            .. " by=" .. tostring(player and ACC.AdminAccess and ACC.AdminAccess.usernameFor(player) or ""))
        Padlocks.refresh(true)
        return true, "CSR padlock remove requested"
    end

    if action == "setOwner" then
        return false, "CSR does not expose a padlock owner rewrite API; no direct ModData edit performed"
    end

    if action == "giveKey" then
        return false, "CSR does not expose a padlock key grant API; no direct key injection performed"
    end

    return false, "Unsupported padlock action"
end

function Padlocks.observe()
    local state = ACC.Persistence.stateTable(Keys.PadlockState)
    state.lastSummary = Padlocks.summary()
end

return Padlocks

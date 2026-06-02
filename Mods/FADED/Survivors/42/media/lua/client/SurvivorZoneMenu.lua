-- Admin right-click tools for survivor zones.

if isServer() then return end

require "SurvivorZones"

SurvivorZoneMenu = SurvivorZoneMenu or {}
if SurvivorZoneMenu.__loaded then return end
SurvivorZoneMenu.__loaded = true

SurvivorZoneMenu.CornerA = nil
SurvivorZoneMenu.CornerB = nil
SurvivorZoneMenu.WorldMarkers = SurvivorZoneMenu.WorldMarkers or {}

local ZONE_MARKER_ICON = "media/ui/defend.png"
local ZONE_MARKER_DURATION = 1800
local ZONE_MARKER_COLOR = {r=0.35, g=0.85, b=1}
local PREVIEW_MARKER_COLOR = {r=1, g=0.85, b=0.25}

local function isZoneAdmin(playerObj)
    return SurvivorZones and SurvivorZones.IsAdmin and SurvivorZones.IsAdmin(playerObj)
end

local function say(playerObj, text)
    if playerObj then
        playerObj:Say(tostring(text))
    end
    print("[Survivors] " .. tostring(text))
end

local function getContextSquare(playerObj, worldObjects)
    if BanditCompatibility and BanditCompatibility.GetClickedSquare then
        local clicked = BanditCompatibility.GetClickedSquare()
        if clicked then return clicked end
    end

    if worldObjects then
        for _, obj in ipairs(worldObjects) do
            if obj and obj.getSquare then
                local sq = obj:getSquare()
                if sq then return sq end
            end
        end
    end

    return playerObj and playerObj:getSquare() or nil
end

local function squareToPoint(square)
    if not square then return nil end
    return {
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
    }
end

local function sendZoneCommand(playerObj, command, args)
    sendClientCommand(playerObj, "Commands", command, args or {})
end

local function setHudMarker(id, x, y, color, desc)
    if not BanditEventMarkerHandler or not BanditEventMarkerHandler.set then return end
    BanditEventMarkerHandler.set("SurvivorZone_" .. tostring(id), ZONE_MARKER_ICON, ZONE_MARKER_DURATION, x, y, color, desc)
end

local function removeWorldMarker(id)
    local marker = SurvivorZoneMenu.WorldMarkers[id]
    if marker and marker.remove then
        marker:remove()
    end
    SurvivorZoneMenu.WorldMarkers[id] = nil
end

local function setWorldMarker(id, x, y, z, radius, color)
    removeWorldMarker(id)
    if not getWorldMarkers or not getCell then return false end
    local worldMarkers = getWorldMarkers()
    local cell = getCell()
    local square = cell and cell:getGridSquare(math.floor(x), math.floor(y), math.floor(z or 0)) or nil
    if not worldMarkers or not worldMarkers.addGridSquareMarker or not square then return false end

    local marker = worldMarkers:addGridSquareMarker(square, color.r, color.g, color.b, true, radius)
    if marker and marker.setScaleCircleTexture then
        marker:setScaleCircleTexture(true)
    end
    SurvivorZoneMenu.WorldMarkers[id] = marker
    return marker ~= nil
end

local function clearBoundaryMarkers(playerObj)
    local ids = {}
    for id, _ in pairs(SurvivorZoneMenu.WorldMarkers) do
        table.insert(ids, id)
    end
    for _, id in ipairs(ids) do
        removeWorldMarker(id)
    end
    say(playerObj, "Cleared survivor zone boundary markers.")
end

local function showBounds(bounds, markerId, label, color)
    if not bounds then return end
    local x1 = math.floor(tonumber(bounds.x1) or 0)
    local y1 = math.floor(tonumber(bounds.y1) or 0)
    local x2 = math.floor(tonumber(bounds.x2) or x1)
    local y2 = math.floor(tonumber(bounds.y2) or y1)
    local z = math.floor(tonumber(bounds.z) or 0)
    if x2 < x1 then x1, x2 = x2, x1 end
    if y2 < y1 then y1, y2 = y2, y1 end
    local cx = math.floor((x1 + x2) / 2)
    local cy = math.floor((y1 + y2) / 2)
    local radius = math.max(1, tonumber(bounds.radius) or math.max(math.floor((x2 - x1) / 2), math.floor((y2 - y1) / 2)))
    color = color or ZONE_MARKER_COLOR
    local points = {
        {"NW", x1, y1}, {"NE", x2, y1}, {"SE", x2, y2}, {"SW", x1, y2},
    }

    local centerId = tostring(markerId) .. "_CENTER"
    if not setWorldMarker(centerId, cx, cy, z, radius + 1, color) then
        setHudMarker(centerId, cx, cy, color, tostring(label))
    end
    for _, point in ipairs(points) do
        setWorldMarker(tostring(markerId) .. "_" .. point[1], point[2], point[3], z, 1, color)
    end
end

local function showRadiusPreview(square, radius, label)
    local p = squareToPoint(square)
    if not p then return end
    showBounds({
        x1 = p.x - radius,
        y1 = p.y - radius,
        x2 = p.x + radius,
        y2 = p.y + radius,
        z = p.z,
        radius = radius,
    }, "PreviewRadius", label or "Zone Preview", PREVIEW_MARKER_COLOR)
end

local function showZoneBoundary(playerObj, zone)
    if not zone then return end
    showBounds(zone, zone.id or zone.name or "Unknown", zone.name or zone.type or "Survivor Zone", ZONE_MARKER_COLOR)
    say(playerObj, "Marked survivor zone boundary: " .. tostring(zone.name or zone.type or zone.id))
end

local function createRadiusZone(playerObj, square, radius, zoneType, guardCap, civilianCap, autoWalls)
    local p = squareToPoint(square)
    if not p then return end

    showRadiusPreview(square, radius, tostring(zoneType or SurvivorZones.Type.Camp) .. " Preview")
    sendZoneCommand(playerObj, "SurvivorZoneCreate", {
        x = p.x,
        y = p.y,
        z = p.z,
        radius = radius,
        zoneType = zoneType or SurvivorZones.Type.Camp,
        populationCap = (tonumber(guardCap) or 2) + (tonumber(civilianCap) or 2),
        guardCap = guardCap,
        civilianCap = civilianCap,
        noZombieSpawn = false,
        clearZombiesOnCreate = false,
        autoWalls = autoWalls == true,
        spawnOnCreate = true,
    })
end

local function setCornerA(playerObj, square)
    SurvivorZoneMenu.CornerA = squareToPoint(square)
    if SurvivorZoneMenu.CornerA then
        if not setWorldMarker("CornerA", SurvivorZoneMenu.CornerA.x, SurvivorZoneMenu.CornerA.y, SurvivorZoneMenu.CornerA.z, 1, PREVIEW_MARKER_COLOR) then
            setHudMarker("CornerA", SurvivorZoneMenu.CornerA.x, SurvivorZoneMenu.CornerA.y, PREVIEW_MARKER_COLOR, "Zone Corner A")
        end
        say(playerObj, "Survivor zone corner A set.")
    end
end

local function setCornerB(playerObj, square)
    SurvivorZoneMenu.CornerB = squareToPoint(square)
    if SurvivorZoneMenu.CornerB then
        if not setWorldMarker("CornerB", SurvivorZoneMenu.CornerB.x, SurvivorZoneMenu.CornerB.y, SurvivorZoneMenu.CornerB.z, 1, PREVIEW_MARKER_COLOR) then
            setHudMarker("CornerB", SurvivorZoneMenu.CornerB.x, SurvivorZoneMenu.CornerB.y, PREVIEW_MARKER_COLOR, "Zone Corner B")
        end
        if SurvivorZoneMenu.CornerA then
            showBounds({
                x1 = SurvivorZoneMenu.CornerA.x,
                y1 = SurvivorZoneMenu.CornerA.y,
                x2 = SurvivorZoneMenu.CornerB.x,
                y2 = SurvivorZoneMenu.CornerB.y,
                z = SurvivorZoneMenu.CornerA.z,
            }, "PreviewCorners", "Corner Zone Preview", PREVIEW_MARKER_COLOR)
        end
        say(playerObj, "Survivor zone corner B set.")
    end
end

local function createRectangleZone(playerObj)
    local a = SurvivorZoneMenu.CornerA
    local b = SurvivorZoneMenu.CornerB
    if not a or not b then
        say(playerObj, "Set both survivor zone corners first.")
        return
    end

    showBounds({x1=a.x, y1=a.y, x2=b.x, y2=b.y, z=a.z}, "PreviewCorners", "Corner Zone Preview", PREVIEW_MARKER_COLOR)
    sendZoneCommand(playerObj, "SurvivorZoneCreate", {
        x1 = a.x,
        y1 = a.y,
        x2 = b.x,
        y2 = b.y,
        z = a.z,
        zoneType = SurvivorZones.Type.Camp,
        populationCap = 5,
        guardCap = 3,
        civilianCap = 2,
        noZombieSpawn = false,
        clearZombiesOnCreate = false,
        spawnOnCreate = true,
    })
end

local function getNearestZone(square, maxDistance)
    if not square or not SurvivorZones then return nil end
    return SurvivorZones.GetNearest(square:getX(), square:getY(), square:getZ(), maxDistance or 120)
end

local function showNearestZoneBoundary(playerObj, square)
    local zone = getNearestZone(square, 120)
    if not zone then
        say(playerObj, "No nearby survivor zone found.")
        return
    end
    showZoneBoundary(playerObj, zone)
end

local function showAllZoneBoundaries(playerObj)
    local zones = SurvivorZones and SurvivorZones.GetAll and SurvivorZones.GetAll() or {}
    local count = 0
    for _, zone in pairs(zones) do
        count = count + 1
        showBounds(zone, zone.id or count, zone.name or zone.type or ("Survivor Zone " .. tostring(count)), ZONE_MARKER_COLOR)
    end
    say(playerObj, "Marked survivor zone boundaries: " .. tostring(count))
end

local function spawnNearestZone(playerObj, square)
    local zone = getNearestZone(square, 120)
    if not zone then
        say(playerObj, "No nearby survivor zone found.")
        return
    end
    showZoneBoundary(playerObj, zone)
    sendZoneCommand(playerObj, "SurvivorZoneSpawn", {zoneId = zone.id})
end

local function spawnNearestZoneRole(playerObj, square, role)
    local zone = getNearestZone(square, 120)
    if not zone then
        say(playerObj, "No nearby survivor zone found.")
        return
    end
    showZoneBoundary(playerObj, zone)
    sendZoneCommand(playerObj, "SurvivorZoneSpawn", {zoneId = zone.id, role = role})
end

local function buildNearestZoneWalls(playerObj, square)
    local zone = getNearestZone(square, 120)
    if not zone then
        say(playerObj, "No nearby survivor zone found.")
        return
    end
    sendZoneCommand(playerObj, "SurvivorZoneBuildWalls", {zoneId = zone.id})
end

local function toggleNearestZone(playerObj, square)
    local zone = getNearestZone(square, 120)
    if not zone then
        say(playerObj, "No nearby survivor zone found.")
        return
    end
    sendZoneCommand(playerObj, "SurvivorZoneToggle", {zoneId = zone.id})
end

local function deleteNearestZone(playerObj, square)
    local zone = getNearestZone(square, 120)
    if not zone then
        say(playerObj, "No nearby survivor zone found.")
        return
    end
    sendZoneCommand(playerObj, "SurvivorZoneDelete", {zoneId = zone.id})
end

local function listZones(playerObj)
    local zones = SurvivorZones and SurvivorZones.GetAll and SurvivorZones.GetAll() or {}
    local count = 0
    for _, zone in pairs(zones) do
        count = count + 1
        print("[Survivors] Zone " .. tostring(count)
            .. ": " .. tostring(zone.name)
            .. " id=" .. tostring(zone.id)
            .. " type=" .. tostring(zone.type)
            .. " enabled=" .. tostring(zone.enabled ~= false)
            .. " bounds=" .. tostring(zone.x1) .. "," .. tostring(zone.y1)
            .. " -> " .. tostring(zone.x2) .. "," .. tostring(zone.y2))
    end
    showAllZoneBoundaries(playerObj)
    say(playerObj, "Survivor zones listed in console and marked visually: " .. tostring(count))
end

local function addSurvivorZoneMenu(playerIndex, context, worldObjects, test)
    if test then return end

    local playerObj = getSpecificPlayer(playerIndex) or getPlayer()
    if not playerObj or not isZoneAdmin(playerObj) then return end

    local square = getContextSquare(playerObj, worldObjects)
    if not square then return end

    local option = context:addOption("Survivor Zone")
    local menu = ISContextMenu:getNew(context)
    context:addSubMenu(option, menu)

    menu:addOption("Set Corner A", playerObj, setCornerA, square)
    menu:addOption("Set Corner B", playerObj, setCornerB, square)
    menu:addOption("Create Zone From Corners", playerObj, createRectangleZone)

    local radiusOption = menu:addOption("Create Radius Zone")
    local radiusMenu = ISContextMenu:getNew(context)
    context:addSubMenu(radiusOption, radiusMenu)
    radiusMenu:addOption("Small Camp (15)", playerObj, createRadiusZone, square, 15, SurvivorZones.Type.Camp, 2, 2, false)
    radiusMenu:addOption("Camp (25)", playerObj, createRadiusZone, square, 25, SurvivorZones.Type.Camp, 2, 3, false)
    radiusMenu:addOption("Safehouse (20)", playerObj, createRadiusZone, square, 20, SurvivorZones.Type.Safehouse, 2, 4, false)
    radiusMenu:addOption("Trading Post (24)", playerObj, createRadiusZone, square, 24, SurvivorZones.Type.TradingPost, 2, 5, false)
    radiusMenu:addOption("Medical Shelter (22)", playerObj, createRadiusZone, square, 22, SurvivorZones.Type.MedicalShelter, 1, 4, false)
    radiusMenu:addOption("Militia Outpost (40)", playerObj, createRadiusZone, square, 40, SurvivorZones.Type.MilitiaOutpost, 5, 1, false)
    radiusMenu:addOption("Walled Camp (18)", playerObj, createRadiusZone, square, 18, SurvivorZones.Type.Camp, 2, 2, true)

    menu:addOption("Show Nearest Zone Boundary", playerObj, showNearestZoneBoundary, square)
    menu:addOption("Show All Zone Boundaries", playerObj, showAllZoneBoundaries)
    menu:addOption("Clear Zone Boundary Markers", playerObj, clearBoundaryMarkers)
    menu:addOption("Spawn Colony Population - profile guards + civilians", playerObj, spawnNearestZone, square)
    menu:addOption("Spawn Colony Guards - zone-profile armed guards", playerObj, spawnNearestZoneRole, square, "guard")
    menu:addOption("Spawn Colony Civilians - zone-profile civilian gear", playerObj, spawnNearestZoneRole, square, "civilian")
    menu:addOption("Build Wall Ring Nearest Zone", playerObj, buildNearestZoneWalls, square)
    menu:addOption("Enable/Disable Nearest Zone", playerObj, toggleNearestZone, square)
    menu:addOption("Delete Nearest Zone", playerObj, deleteNearestZone, square)
    menu:addOption("List Zones", playerObj, listZones)
end

Events.OnPreFillWorldObjectContextMenu.Add(addSurvivorZoneMenu)

require "CSR_FeatureFlags"

--[[
    CSR_HideSense.lua
    Hide in large furniture — closets, dumpsters, fridges, beds.

    Safety mechanism (the part that makes zombies actually leave you alone):
      1. setInvisible + setGhostMode — hides the sprite and disables
         physical collisions / weapon focus from AI.
      2. Vertical teleport to Z = HIDE_Z (default 6) — moves the player
         out of the zombie pathfinding plane entirely. Just being
         invisible is NOT enough on its own: zombies still pathfind to
         the player's last-known X,Y,Z. Vanilla AI checks line-of-sight
         and noise on the player's tile; teleporting up takes the player
         off any walkable Z layer the surrounding zombies are on.
      3. OnTick guard — every frame, if Z drifted (gravity, vanilla
         falling code, vehicle eject, etc.) we re-pin to HIDE_Z. The
         falling state is also explicitly cleared on each pin.
      4. Original Z is stored in modData and restored on un-hide.

    Black screen uses UIManager.FadeOut (same as vanilla sleep) so the
    player doesn't see the sky-high vantage during the hide.
]]

local HIDE_Z = 6
local HIDE_Z_DELTA = 8  -- if originalZ >= HIDE_Z, teleport up by this much instead

local function pickHideZ(originalZ)
    if originalZ and originalZ >= HIDE_Z then
        return originalZ + HIDE_Z_DELTA
    end
    return HIDE_Z
end

local hidingPlayer = nil
local hidingPlayerNum = nil
local hidingCategory = nil
local hidingObject = nil
local hidingX = 0
local hidingY = 0
local hidingZ = 0
local hidingZTarget = nil
local hidingGrace = 0
local GRACE_TICKS = 60
local CONTAINER_CHECK_INTERVAL = 120
local containerCheckTimer = 0

--- Check if an IsoObject has the bed sprite flag.
local function isBedObject(obj)
    if not obj then return false end
    local sprite = obj:getSprite()
    if not sprite then return false end
    local props = sprite:getProperties()
    if not props then return false end
    if type(props.Is) == "function" then
        if props:Is(IsoFlagType.bed) then return true end
    end
    if type(props.get) == "function" then
        if props:get("BedType") then return true end
    end
    return false
end

--- Categorize an IsoObject by sprite flags, container type, or sprite name.
--- Returns "bed", "closet", "fridge", "dumpster", "couch", "table", "crate", "barrel", or nil.
local function categorizeObject(obj)
    if not obj or type(obj.getSprite) ~= "function" then return nil end

    -- Bed detection via sprite property flag
    if isBedObject(obj) then return "bed" end

    -- Get sprite name for pattern checks
    local sprite = obj:getSprite()
    local name = nil
    if sprite and type(sprite.getName) == "function" then
        name = sprite:getName()
    end

    -- Dumpster sprites
    if name then
        if string.find(name, "^trash_01_2[4-9]") then return "dumpster" end
        if string.find(name, "^street_decoration_01_1[6-9]") then return "dumpster" end
    end

    -- Barrel — uncapped via CSR Useful Barrels feature
    if type(obj.getModData) == "function" then
        local md = obj:getModData()
        if md and md.CSR_UB_Uncapped then return "barrel" end
    end

    -- Container-based detection
    if type(obj.getContainerCount) == "function" then
        local count = obj:getContainerCount() or 0
        local maxCap = 0
        local isFridge = false
        local containerType = nil
        for i = 0, count - 1 do
            local c = obj:getContainerByIndex(i)
            if c then
                local t = c:getType()
                if t == "fridge" or t == "freezer" then
                    isFridge = true
                end
                if t then containerType = t end
                local cap = c:getCapacity() or 0
                if cap > maxCap then maxCap = cap end
            end
        end
        if isFridge then return "fridge" end
        -- Closets/wardrobes: specific container types or large capacity in wardrobe-like sprites
        if containerType == "wardrobe" or containerType == "closet" then return "closet" end
        if containerType == "crate" and maxCap >= 40 then return "crate" end
    end

    -- Sprite-based fallbacks for closet-like furniture (wardrobes, clothing racks)
    if name then
        if string.find(name, "^furniture_storage_01_") then return "closet" end
        if string.find(name, "^furniture_clothing_01_") then return "closet" end
        if string.find(name, "refrigeration") then return "fridge" end
        -- Couches/sofas — seating sprites but not chairs
        if string.find(name, "^furniture_seating_01_") then
            -- Sofas are typically multi-tile; single chairs are smaller sprites
            -- Sofas use indices 0-23 in the vanilla sheet, chairs start higher
            local idx = tonumber(string.match(name, "furniture_seating_01_(%d+)"))
            if idx and idx < 24 then return "couch" end
        end
        -- Large tables — only multi-tile tables
        if string.find(name, "^furniture_table_01_") then
            -- Large dining/office tables (sprites 0-15 are large tables in vanilla)
            local idx = tonumber(string.match(name, "furniture_table_01_(%d+)"))
            if idx and idx < 16 then return "table" end
        end
        -- Industrial crates
        if string.find(name, "^industry_crate_") then return "crate" end
    end

    return nil
end

--- Search all objects on a square for a hideable one.
local function findHideableOnSquare(square)
    if not square then return nil, nil end
    local objects = square:getObjects()
    if not objects then return nil, nil end
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and not instanceof(obj, "IsoWorldInventoryObject") then
            local category = categorizeObject(obj)
            if category then return obj, category end
        end
    end
    return nil, nil
end

--- Find a hideable object from worldObjects, falling back to scanning the square.
local function findHideableFromWorldObjects(worldObjects)
    if not worldObjects then return nil, nil end
    for i = 1, #worldObjects do
        local wo = worldObjects[i]
        local category = categorizeObject(wo)
        if category then return wo, category end
        local square = wo and type(wo.getSquare) == "function" and wo:getSquare() or nil
        local obj, cat = findHideableOnSquare(square)
        if obj then return obj, cat end
    end
    return nil, nil
end

-- Z-teleport tick guard: re-pins the player to the hide-Z every frame
-- so vanilla gravity / falling cannot drop them back into the zombie plane.
local function hideTickGuard()
    local p = hidingPlayer
    if not p or p:isDead() then return end
    local targetZ = hidingZTarget or HIDE_Z
    if p:getZ() ~= targetZ then
        p:setZ(targetZ)
    end
    -- Always clear falling state in case vanilla set it during the climb
    pcall(function()
        if type(p.setbFalling) == "function" then p:setbFalling(false) end
        if type(p.setFallTime) == "function" then p:setFallTime(0) end
        if type(p.setLastFallSpeed) == "function" then p:setLastFallSpeed(0) end
    end)
end

-- Invisibility + Z-teleport.
local function setPlayerHidden(player, playerNum, hidden, originalZ)
    pcall(function()
        player:setInvisible(hidden)
        player:setGhostMode(hidden)
    end)

    if hidden then
        local targetZ = pickHideZ(originalZ or player:getZ())
        hidingZTarget = targetZ
        pcall(function()
            player:setZ(targetZ)
            if type(player.setbFalling) == "function" then player:setbFalling(false) end
            if type(player.setFallTime) == "function" then player:setFallTime(0) end
            if type(player.setLastFallSpeed) == "function" then player:setLastFallSpeed(0) end
        end)
        if not _G.__CSR_HideTickGuardOn then
            _G.__CSR_HideTickGuardOn = true
            Events.OnTick.Add(hideTickGuard)
        end
        pcall(function()
            UIManager.setFadeBeforeUI(playerNum, true)
            UIManager.FadeOut(playerNum, 1)
        end)
    else
        -- Always remove the OnTick guard, even if the global flag was lost
        -- (e.g. file reload during a hide session). Removing a non-registered
        -- callback is a safe no-op.
        _G.__CSR_HideTickGuardOn = nil
        pcall(function() Events.OnTick.Remove(hideTickGuard) end)

        -- Clamp Z to the ground square so the player never lands at +6 in
        -- mid-air (which would trigger vanilla fall-to-death). originalZ
        -- defaults to 0 if missing; if the destination square exists, prefer
        -- its actual Z for split-level builds.
        local restoreZ = originalZ or 0
        pcall(function()
            local cell = getCell()
            if cell then
                local sq = cell:getGridSquare(player:getX(), player:getY(), restoreZ)
                if not sq then
                    sq = cell:getGridSquare(player:getX(), player:getY(), 0)
                    if sq then restoreZ = 0 end
                end
            end
        end)
        pcall(function()
            player:setZ(restoreZ)
            if type(player.setbFalling) == "function" then player:setbFalling(false) end
            if type(player.setFallTime) == "function" then player:setFallTime(0) end
            if type(player.setLastFallSpeed) == "function" then player:setLastFallSpeed(0) end
            if type(player.setOnFloor) == "function" then player:setOnFloor(true) end
        end)
        hidingZTarget = nil
        pcall(function()
            UIManager.FadeIn(playerNum, 1)
            UIManager.setFadeBeforeUI(playerNum, false)
        end)
    end
end

local function startHiding(player, category, obj)
    local playerNum = player:getPlayerNum()
    hidingPlayer = player
    hidingPlayerNum = playerNum
    hidingCategory = category
    hidingObject = obj
    hidingX = player:getX()
    hidingY = player:getY()
    hidingZ = player:getZ()  -- captured BEFORE the Z-teleport happens
    hidingGrace = GRACE_TICKS
    containerCheckTimer = 0
    setPlayerHidden(player, playerNum, true, hidingZ)
    player:Say("...")

    -- Persist hiding state to moddata for reconnect survival
    local modData = player:getModData()
    if modData then
        modData.CSRHideSenseActive = true
        modData.CSRHideSenseCategory = category
        modData.CSRHideSenseX = hidingX
        modData.CSRHideSenseY = hidingY
        modData.CSRHideSenseZ = hidingZ
    end
end

local function stopHiding()
    if hidingPlayer then
        setPlayerHidden(hidingPlayer, hidingPlayerNum, false, hidingZ)
        -- Clear persistence
        local modData = hidingPlayer:getModData()
        if modData then
            modData.CSRHideSenseActive = nil
            modData.CSRHideSenseCategory = nil
            modData.CSRHideSenseX = nil
            modData.CSRHideSenseY = nil
            modData.CSRHideSenseZ = nil
        end
    end
    hidingPlayer = nil
    hidingPlayerNum = nil
    hidingCategory = nil
    hidingObject = nil
end

local function isHiding()
    return hidingPlayer ~= nil
end

-- Boredom/sickness while hiding + container fullness check
local function onHidingTick()
    if not isHiding() then return end
    local player = hidingPlayer
    if not player or player:isDead() then
        stopHiding()
        return
    end
    -- Grace period after starting to hide
    if hidingGrace > 0 then
        hidingGrace = hidingGrace - 1
    else
        -- Stop hiding if player walks away from hiding spot or enters vehicle.
        -- NOTE: do not compare current Z against hidingZ here. The player is
        -- intentionally teleported to hidingZTarget while hiding, so a Z
        -- mismatch is the normal state. The OnTick guard pins them in place.
        local dx = math.abs(player:getX() - hidingX)
        local dy = math.abs(player:getY() - hidingY)
        if dx > 0.5 or dy > 0.5 or player:getVehicle() then
            stopHiding()
            return
        end
    end

    -- Periodic container fullness check (someone could fill the container while you're hiding)
    containerCheckTimer = containerCheckTimer + 1
    if containerCheckTimer >= CONTAINER_CHECK_INTERVAL then
        containerCheckTimer = 0
        if hidingCategory ~= "bed" and hidingObject and type(hidingObject.getContainerCount) == "function" then
            local containerCount = hidingObject:getContainerCount() or 0
            if containerCount > 0 then
                local container = hidingObject:getContainerByIndex(0)
                if container then
                    local cap = container:getCapacity() or 0
                    local weight = container:getCapacityWeight() or 0
                    if cap > 0 and weight >= (cap / 1.3) then
                        player:setHaloNote("Too cramped! Forced out.", 255, 140, 60, 200)
                        stopHiding()
                        return
                    end
                end
            end
        end
    end

    -- Apply boredom
    local stats = player:getStats()
    if stats then
        local boredom = stats:get(CharacterStat.BOREDOM) or 0
        stats:set(CharacterStat.BOREDOM, math.min(boredom + 0.0003, 1.0))

        -- Sickness for dumpsters, fridges, crates, and barrels
        if hidingCategory == "dumpster" or hidingCategory == "fridge"
            or hidingCategory == "crate" or hidingCategory == "barrel" then
            local nausea = stats:get(CharacterStat.SICKNESS) or 0
            stats:set(CharacterStat.SICKNESS, math.min(nausea + 0.0001, 0.5))
        end
    end
end

local TOOLTIPS = {
    bed       = getText("Tooltip_CSR_HideBed"),
    closet    = getText("Tooltip_CSR_HideCloset"),
    dumpster  = getText("Tooltip_CSR_HideDumpster"),
    fridge    = getText("Tooltip_CSR_HideFridge"),
    couch     = getText("Tooltip_CSR_HideCouch"),
    table     = getText("Tooltip_CSR_HideTable"),
    crate     = getText("Tooltip_CSR_HideCrate"),
    barrel    = getText("Tooltip_CSR_HideBarrel"),
}

local LABELS = {
    bed      = getText("ContextMenu_CSR_HideUnderBed"),
    closet   = getText("ContextMenu_CSR_HideInCloset"),
    dumpster = getText("ContextMenu_CSR_HideInDumpster"),
    fridge   = getText("ContextMenu_CSR_HideInFridge"),
    couch    = getText("ContextMenu_CSR_HideBehindCouch"),
    table    = getText("ContextMenu_CSR_HideUnderTable"),
    crate    = getText("ContextMenu_CSR_HideInCrate"),
    barrel   = getText("ContextMenu_CSR_HideInBarrel"),
}

-- Context menu
local function onWorldContext(playerNum, context, worldObjects, test)
    if test then return end
    if not CSR_FeatureFlags.isHideInFurnitureEnabled() then return end

    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() then return end
    if player:getVehicle() then return end

    if isHiding() then
        context:addOption(getText("ContextMenu_CSR_StopHiding") or "Stop Hiding", worldObjects, function()
            stopHiding()
        end)
        return
    end

    local obj, category = findHideableFromWorldObjects(worldObjects)
    if not obj then return end

    -- Check container capacity — can't hide if container is too full (skip for beds)
    if category ~= "bed" and type(obj.getContainerCount) == "function" then
        local containerCount = obj:getContainerCount() or 0
        if containerCount > 0 then
            local container = obj:getContainerByIndex(0)
            if container then
                local cap = container:getCapacity() or 0
                local weight = container:getCapacityWeight() or 0
                if cap > 0 and weight >= (cap / 1.7) then
                    local opt = context:addOption(getText("ContextMenu_CSR_HideTooFull"), worldObjects, nil)
                    opt.notAvailable = true
                    local tooltip = ISWorldObjectContextMenu.addToolTip()
                    tooltip.description = getText("Tooltip_CSR_HideTooFull")
                    opt.toolTip = tooltip
                    return
                end
            end
        end
    end

    local label = LABELS[category] or "Hide"
    local opt = context:addOption(label, worldObjects, function()
        startHiding(player, category, obj)
    end)
    local desc = TOOLTIPS[category]
    if desc then
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = desc
        opt.toolTip = tooltip
    end
end

-- Cancel hiding on ESC or movement keys
local function onKeyPressed(key)
    if not isHiding() then return end
    if key == Keyboard.KEY_ESCAPE then
        stopHiding()
        return
    end
    local binds = getCore()
    if binds then
        if key == binds:getKey("Forward") or key == binds:getKey("Backward")
        or key == binds:getKey("Left")    or key == binds:getKey("Right") then
            stopHiding()
        end
    end
end

-- After reconnect/load: if the player was mid-hide we may have been saved
-- at the elevated hide-Z. Teleport back down to the original Z, clear
-- invisibility/ghost, and wipe persistence. The player can re-initiate
-- hiding manually via the context menu \u2014 safer than auto-resuming a
-- partial state across a save round-trip.
local function onGameStart()
    local player = getPlayer()
    if not player then return end
    local modData = player:getModData()
    if not modData or not modData.CSRHideSenseActive then return end

    local origZ = modData.CSRHideSenseZ
    pcall(function()
        player:setInvisible(false)
        player:setGhostMode(false)
    end)
    if origZ then
        pcall(function()
            player:setZ(origZ)
            if type(player.setbFalling) == "function" then player:setbFalling(false) end
            if type(player.setFallTime) == "function" then player:setFallTime(0) end
            if type(player.setLastFallSpeed) == "function" then player:setLastFallSpeed(0) end
        end)
    end
    modData.CSRHideSenseActive = nil
    modData.CSRHideSenseCategory = nil
    modData.CSRHideSenseX = nil
    modData.CSRHideSenseY = nil
    modData.CSRHideSenseZ = nil
end

if not _G.__CSR_HideSense_evRegistered then
    _G.__CSR_HideSense_evRegistered = true
    Events.OnFillWorldObjectContextMenu.Add(onWorldContext)
    Events.OnPlayerUpdate.Add(onHidingTick)
    Events.OnKeyPressed.Add(onKeyPressed)
    Events.OnGameStart.Add(onGameStart)
end

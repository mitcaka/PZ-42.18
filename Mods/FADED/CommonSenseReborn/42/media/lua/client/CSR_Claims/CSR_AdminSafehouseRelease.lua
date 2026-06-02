--[[
    CSR_AdminSafehouseRelease.lua
    -------------------------------------------------------------------------
    Adds an admin-only world right-click entry "Force-Release Safehouse"
    that targets the safehouse covering the right-clicked tile and removes
    it (vanilla SafeHouse.removeSafeHouse) plus any matching CSR registry
    rows. Use case: a tester or troll claims a key building (notice board
    room, garage, warehouse) and stops responding -- admins need a one-click
    way to free it without database surgery.

    Server validation lives in CSR_ClaimServer.handleAdminForceReleaseSafehouse.
    The button only appears when:
      * The local player has admin access level.
      * The right-clicked tile is inside at least one vanilla SafeHouse.
--]]

local function isAdmin(player)
    if not player or not player.getAccessLevel then return false end
    local lvl = player:getAccessLevel()
    return lvl == "admin" or lvl == "Admin"
end

local function tileInsideSafehouse(x, y)
    if not SafeHouse or not SafeHouse.getSafehouseList then return false end
    local list = SafeHouse.getSafehouseList()
    if not list or not list.size then return false end
    for i = 0, list:size() - 1 do
        local sh = list:get(i)
        if sh and sh.getX and sh.getY and sh.getW and sh.getH then
            local sx = sh:getX()
            local sy = sh:getY()
            local sw = sh:getW()
            local shh = sh:getH()
            if x >= sx and x < sx + sw and y >= sy and y < sy + shh then
                return true
            end
        end
    end
    return false
end

local function pickTargetSquare(worldobjects)
    -- Prefer an explicit IsoGridSquare from worldobjects; otherwise fall
    -- back to the player's currently-pointed square via mouse helpers.
    if type(worldobjects) == "table" then
        for _, obj in ipairs(worldobjects) do
            if obj and obj.getSquare then
                local sq = obj:getSquare()
                if sq then return sq end
            elseif obj and obj.getX and obj.getY and obj.getZ then
                return obj
            end
        end
    end
    return nil
end

local function onForceRelease(worldobjects, x, y, z)
    if CSR_ClaimClient and CSR_ClaimClient.requestAdminForceReleaseSafehouse then
        CSR_ClaimClient.requestAdminForceReleaseSafehouse(x, y, z)
    end
end

local function onFillContextMenu(playerNum, context, worldobjects, test)
    if test then return end
    if not context then return end
    local player = getSpecificPlayer and getSpecificPlayer(playerNum) or getPlayer()
    if not isAdmin(player) then return end

    local sq = pickTargetSquare(worldobjects)
    local x, y, z
    if sq then
        x = (sq.getX and sq:getX()) or 0
        y = (sq.getY and sq:getY()) or 0
        z = (sq.getZ and sq:getZ()) or 0
    else
        return
    end
    if not tileInsideSafehouse(x, y) then return end

    local label = (getText and getText("UI_CSR_AdminForceReleaseSafehouse"))
                  or "Admin: Force-Release Safehouse"
    -- Fallback when getText returns the literal key (translation missing).
    if label == "UI_CSR_AdminForceReleaseSafehouse" then
        label = "Admin: Force-Release Safehouse"
    end
    local opt = context:addOption(label, worldobjects, onForceRelease, x, y, z)
    if opt then
        opt.toolTip = ISToolTip:new()
        opt.toolTip:initialise()
        opt.toolTip:setVisible(false)
        opt.toolTip.description =
            "Admin only. Removes the vanilla safehouse covering this tile " ..
            "plus any matching CSR registry rows. Use to recover from " ..
            "stuck claims; cannot be undone."
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillContextMenu)

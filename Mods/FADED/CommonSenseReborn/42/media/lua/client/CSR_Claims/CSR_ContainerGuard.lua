--[[
    CSR_ContainerGuard.lua
    -------------------------------------------------------------------------
    v1.8.36 -- defense-in-depth container + furniture protection for claimed
    safehouses. Wraps vanilla timed actions via monkey-patch so unauthorized
    players are silently blocked at the action layer (with a halo note).

    Hooks installed at OnGameStart (vanilla classes are loaded by then):
      * ISInventoryTransferAction.isValid -- gate take/put on claimed-square
        containers and on padlocked containers.
      * ISMoveablesAction.isValid         -- gate pickup/scrap/rotate of
        furniture sitting on claimed squares.

    Hard rules:
      * MP only. Single-player is left untouched.
      * Original is preserved and chained.
      * Guard logic uses explicit nil/API checks; errors are allowed to surface
        instead of being hidden inside timed-action validation.
      * No nested tables in modData. Padlock state lives on world objects as
        flat keys: csrPadlocked, csrPadlockClaim, csrPadlockKeyHash.
--]]

CSR_ContainerGuard = CSR_ContainerGuard or {}
CSR_ContainerGuard._installed = CSR_ContainerGuard._installed or false

local function _mpOnly()
    return isClient and isClient()
end

local function flagOn()
    if not CSR_FeatureFlags then return false end
    if CSR_FeatureFlags.isClaimContainerProtectEnabled then
        return CSR_FeatureFlags.isClaimContainerProtectEnabled()
    end
    return true
end

local function isPlayer(ch)
    if not ch then return false end
    return instanceof(ch, "IsoPlayer") == true
end

local _lastNotify = 0
local function notify(ch, msg, r, g, b)
    if not ch or not ch.setHaloNote then return end
    local now = (getTimestampMs and getTimestampMs()) or 0
    if now - _lastNotify < 2500 then return end
    _lastNotify = now
    ch:setHaloNote(msg, r or 220, g or 80, b or 80, 250)
end

-- Resolve the IsoGridSquare a container lives on (for ground / world
-- containers). Returns nil for player inventories and bag inventories.
local function squareOfContainer(c)
    if not c then return nil end
    if c.getSourceGrid then
        local sq = c:getSourceGrid()
        if sq then return sq end
    end
    if c.getParent then
        local parent = c:getParent()
        if parent and parent.getSquare then
            return parent:getSquare()
        end
    end
    return nil
end

-- Find the IsoObject whose container matches `c` on the given square.
-- Used to resolve padlock modData on the world object.
local function objectOfContainer(square, c)
    if not square or not c then return nil end
    local objs = square:getObjects()
    if not objs then return nil end
    local n = (objs.size and objs:size()) or 0
    for i = 0, n - 1 do
        local o = objs:get(i)
        if o and o.getContainer then
            local oc = o:getContainer()
            if oc == c then return o end
        end
    end
    return nil
end

local function rowAtSquare(square)
    if not square or not CSR_ClaimClient or not CSR_ClaimClient.getClaimAt then return nil end
    return CSR_ClaimClient.getClaimAt(square:getX(), square:getY())
end

-- Padlock check on a world object. Returns true if blocked.
-- Allowed if: owner of padlock, or holds an item whose modData csrPadlockKeyHash
-- matches, or is admin.
local function isPadlockBlocked(obj, ch)
    if not obj or not ch then return false end
    if not obj.getModData then return false end
    local md = obj:getModData()
    if not md or md.csrPadlocked ~= 1 then return false end
    -- Admin always passes.
    if ch.getAccessLevel then
        local a = ch:getAccessLevel()
        if a and (a == "admin" or a == "Admin") then return false end
    end
    local keyHash = tostring(md.csrPadlockKeyHash or "")
    if keyHash == "" then return false end
    -- Look in primary inventory for any item with matching key hash.
    local inv = ch.getInventory and ch:getInventory() or nil
    if inv and inv.getItems then
        local items = inv:getItems()
        local n = (items.size and items:size()) or 0
        for i = 0, n - 1 do
            local it = items:get(i)
            if it and it.getModData then
                local imd = it:getModData()
                if imd and tostring(imd.csrPadlockKeyHash or "") == keyHash then
                    return false -- has matching key
                end
            end
        end
    end
    return true
end

local function guardTransfer(act)
    if not flagOn() then return true end
    if not act then return true end
    local ch = act.character
    if not isPlayer(ch) then return true end
    local user = ch.getUsername and ch:getUsername() or ""
    if user == "" then return true end
    if not CSR_ClaimPermissions or not CSR_ClaimPermissions.canDo then return true end

    local function checkSide(c, action)
        local sq = squareOfContainer(c)
        if not sq then return true end
        -- Padlock first (applies even if no claim)
        local obj = objectOfContainer(sq, c)
        if obj and isPadlockBlocked(obj, ch) then
            notify(ch, "Padlocked. You don't have a matching key.")
            return false
        end
        local row = rowAtSquare(sq)
        if not row then return true end
        if not CSR_ClaimPermissions.canDo(row, user, action, ch) then
            notify(ch, "This container is claimed.")
            return false
        end
        return true
    end

    if not checkSide(act.srcContainer, "take_from_container") then return false end
    if not checkSide(act.destContainer, "put_in_container") then return false end
    return true
end

local function guardMoveables(act)
    if not flagOn() then return true end
    if not act or not act.character then return true end
    local ch = act.character
    if not isPlayer(ch) then return true end
    local sq = act.square
    if not sq then return true end
    local user = ch.getUsername and ch:getUsername() or ""
    if user == "" then return true end
    -- Padlock check on the targeted moveable object (cannot pickup/scrap a padlocked item)
    if act.moveProps and act.moveProps.object and isPadlockBlocked(act.moveProps.object, ch) then
        notify(ch, "Padlocked. You don't have a matching key.")
        return false
    end
    local row = rowAtSquare(sq)
    if not row then return true end
    if not CSR_ClaimPermissions or not CSR_ClaimPermissions.canDo then return true end
    if not CSR_ClaimPermissions.canDo(row, user, "move_furniture", ch) then
        notify(ch, "This furniture is claimed.")
        return false
    end
    return true
end

local function wrapTransfer()
    if not ISInventoryTransferAction or not ISInventoryTransferAction.isValid then return false end
    if ISInventoryTransferAction._csrCSRGuardWrapped then return true end
    local _orig = ISInventoryTransferAction.isValid
    ISInventoryTransferAction.isValid = function(self)
        local allow = guardTransfer(self)
        if not allow then return false end
        return _orig(self)
    end
    ISInventoryTransferAction._csrCSRGuardWrapped = true
    return true
end

local function wrapMoveables()
    if not ISMoveablesAction or not ISMoveablesAction.isValid then return false end
    if ISMoveablesAction._csrCSRGuardWrapped then return true end
    local _orig = ISMoveablesAction.isValid
    ISMoveablesAction.isValid = function(self)
        local allow = guardMoveables(self)
        if not allow then return false end
        return _orig(self)
    end
    ISMoveablesAction._csrCSRGuardWrapped = true
    return true
end

function CSR_ContainerGuard.install()
    if not _mpOnly() then return end
    if CSR_ContainerGuard._installed then return end
    local a = wrapTransfer()
    local b = wrapMoveables()
    CSR_ContainerGuard._installed = (a or b)
end

if _mpOnly() then
    Events.OnGameStart.Add(CSR_ContainerGuard.install)
end

return CSR_ContainerGuard

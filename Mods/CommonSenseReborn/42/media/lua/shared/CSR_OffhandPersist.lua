--[[
    CSR_OffhandPersist.lua

    Lightweight, passive ledger of the off-hand weapon a player is currently
    using.  The engine clears `getSecondaryHandItem()` for short bursts during
    several legitimate transitions (primary equip, ranged primary swing,
    third-party prone/get-up actions, etc.) which makes the off-hand HUD
    icon flicker out and our own logic see "no off-hand" mid-combat.

    This module gives us:
      * an inventory-backed snapshot of the most recent off-hand the player
        was actually holding
      * a paint-time texture lookup for CSR_OffhandHudOverlay so the icon
        does not vanish during a transient slot clear
      * two narrow restorers (post-equip and post-attack) that re-apply the
        snapshot when the engine has nulled the slot without our consent

    Design notes (deliberate divergences from anything resembling existing
    third-party DW code):
      * No "session id" or context-menu activation -- the snapshot is purely
        observed by polling OnPlayerUpdate.  Players never opt in or out.
      * Eviction is driven by a frame-stamp grace window, not by event
        bookkeeping; the slot can clear for ~3 seconds before we forget.
      * Single-flag re-entrancy guard rather than a refcount; we never call
        ourselves recursively because the only writes happen under explicit
        wrappers.
      * Restoration after a primary attack is reactive (OnPlayerAttackFinished
        only) -- we never proactively null the slot before vanilla swings.
        The HUD overlay is what hides the flicker.
]]

require "CSR_FeatureFlags"

CSR_OffhandPersist = CSR_OffhandPersist or {}

-- ledger keyed by username; works in SP and MP without onlineID lookups
local _book        = {}
local _frame       = 0
-- guard so our own restoring writes don't trigger more restores
local _inFlight    = false
-- 3 seconds at 60fps; long enough to ride out vanilla equip animations
local KEEPALIVE    = 180
-- minimum frames between full inventory verifications, to keep the
-- per-frame overlay path cheap
local INV_CHECK    = 10
-- v1.8.19 Layer-1: per-player suppression frame stamp.  When the user
-- explicitly unequips the sticky off-hand (right-click Unequip, hotbar
-- drag-out, manual Quick Equip swap) we set this so the next ~30 frames
-- of empty-slot observation do NOT trigger a restore.
local _suppressUntil = {}
local SUPPRESS_FRAMES = 30
-- v1.8.19 Layer-1: throttle active OnPlayerUpdate restores so we don't
-- write to the slot every frame.  Vanilla equip animations resolve in
-- 5-10 frames; checking every 4 is a comfortable trade.
local RESTORE_INTERVAL = 4

local function nameKey(player)
    if not player or not player.getUsername then return nil end
    local ok, name = pcall(function() return player:getUsername() end)
    if not ok or not name then return nil end
    return tostring(name)
end

local function isMeleeOrRangedWeapon(item)
    if not item then return false end
    if not item.IsWeapon or not item:IsWeapon() then return false end
    if item.isBroken and item:isBroken() then return false end
    return true
end

-- Off-hand candidates for our overlay/restore: any weapon in the secondary
-- slot that is NOT a 2H mirror (engine writes the same ref into both slots
-- for 2H weapons; we deliberately ignore that).
local function isPlausibleOffhand(player, secondary)
    if not isMeleeOrRangedWeapon(secondary) then return false end
    if player:getPrimaryHandItem() == secondary then return false end
    if secondary.isRequiresEquippedBothHands and secondary:isRequiresEquippedBothHands() then return false end
    if secondary.isTwoHandWeapon and secondary:isTwoHandWeapon() then return false end
    -- v1.8.26 fix: never claim an item that is currently parked on a
    -- hotbar attachment slot (Back, Belt, Holster, etc.) as the offhand.
    -- The engine briefly shows the same ref in both the secondary slot
    -- and a hotbar slot during attach -- without this guard the ledger
    -- locks in a stale snapshot and tryRestoreSlot would later re-grab
    -- the item off the hotbar.
    if secondary.getAttachedSlot and secondary:getAttachedSlot() ~= -1 then
        return false
    end
    return true
end

local function inventoryStillHolds(player, item)
    if not item or not player then return false end
    local inv = player:getInventory()
    if not inv then return false end
    -- B42 Inventory:contains is recursive; covers nested bags too
    if inv.contains and inv:contains(item) then return true end
    return false
end

-- Public read API -----------------------------------------------------------

function CSR_OffhandPersist.entry(player)
    local k = nameKey(player); if not k then return nil end
    return _book[k]
end

function CSR_OffhandPersist.peek(player)
    local e = CSR_OffhandPersist.entry(player)
    return e and e.ref or nil
end

function CSR_OffhandPersist.texture(player)
    local e = CSR_OffhandPersist.entry(player)
    if not e then return nil end
    -- prefer live ref texture (handles cosmetic re-tex) and fall back to
    -- the snapshot we cached on first sight
    if e.ref and e.ref.getTex then
        local ok, tx = pcall(function() return e.ref:getTex() end)
        if ok and tx then return tx end
    end
    return e.txr
end

-- Returns true when the cached entry is still believed to reflect a real
-- off-hand the player is holding (used by the HUD overlay so we don't
-- paint over slots after a legitimate unequip).
function CSR_OffhandPersist.isLive(player)
    local e = CSR_OffhandPersist.entry(player)
    if not e then return false end
    if (_frame - e.stamp) > KEEPALIVE then return false end
    if e.lastInvOK and (_frame - e.lastInvOK) <= INV_CHECK then
        return true
    end
    if inventoryStillHolds(player, e.ref) then
        e.lastInvOK = _frame
        return true
    end
    return false
end

-- Internal write API --------------------------------------------------------

local function record(player, item)
    local k = nameKey(player); if not k then return end
    if not item then return end
    local txr = (item.getTex and item:getTex()) or nil
    local fullType = (item.getFullType and item:getFullType()) or nil
    _book[k] = {
        ref         = item,
        txr         = txr,
        fullType    = fullType,
        stamp       = _frame,
        lastInvOK   = _frame,
    }
end

local function discard(player)
    local k = nameKey(player); if not k then return end
    _book[k] = nil
end

local function suppress(player)
    local k = nameKey(player); if not k then return end
    _suppressUntil[k] = _frame + SUPPRESS_FRAMES
end

local function isSuppressed(player)
    local k = nameKey(player); if not k then return false end
    local u = _suppressUntil[k]
    if not u then return false end
    if _frame >= u then
        _suppressUntil[k] = nil
        return false
    end
    return true
 end

CSR_OffhandPersist._record  = record
CSR_OffhandPersist._discard = discard
CSR_OffhandPersist._suppress = suppress

-- Public: call when the player has *explicitly* told the engine to drop
-- the off-hand (Quick Equip swap, right-click Unequip, etc).  Discards
-- the ledger entry AND suppresses restores for a short window so any
-- residual setSecondaryHandItem(nil) writes don't resurrect via the
-- ledger.
function CSR_OffhandPersist.userIntentClear(player)
    discard(player)
    suppress(player)
end

-- Returns true if the player has any timed action queued. Per the v1.8.19
-- Layer-1 plan, we never restore mid-equip-action -- doing so re-creates
-- the v1.8.11 "belt items unequipping on clothing change" regression by
-- racing the engine's equip pipeline.
local function isPlayerBusyAction(player)
    local ok, q = pcall(function()
        return ISTimedActionQueue and ISTimedActionQueue.getTimedActionQueue
               and ISTimedActionQueue.getTimedActionQueue(player) or nil
    end)
    if ok and q and q.queue and #q.queue > 0 then return true end
    return false
end

-- Try to put the snapshot back into the secondary slot if vanilla just
-- cleared it.  Will only act if all FOUR guards hold simultaneously
-- (Layer-1 plan, step 3):
--   * dual wield is enabled and persistence enabled
--   * we have a snapshot whose item is still in inventory
--   * the slot is currently empty AND primary is not 2H / not the same item
--   * the player is not currently mid-equip / mid-action
--   * we are not in a user-intent suppression window
local function tryRestoreSlot(player, ignoreBusy)
    if _inFlight then return false end
    if not CSR_FeatureFlags.isDualWieldEnabled() then return false end
    if not CSR_FeatureFlags.isOffhandPersistEnabled() then return false end
    if not player or player:isDead() then return false end
    if isSuppressed(player) then return false end

    local e = CSR_OffhandPersist.entry(player)
    if not e or not e.ref then return false end
    if e.ref.isBroken and e.ref:isBroken() then return false end

    -- v1.8.26 fix: if the ledger ref is now attached to a hotbar slot
    -- (Back, Belt, Holster, etc.) the user has consciously parked it
    -- there via right-click "Place on Back/Belt" or hotbar drag.  Vanilla
    -- still reports it via inv:contains(), but pulling it back into the
    -- secondary slot would yank it off the hotbar and looks like a bug
    -- ("my weapon jumped to my offhand"). Discard the ledger and
    -- suppress further restores until the user re-equips it themselves.
    if e.ref.getAttachedSlot and e.ref:getAttachedSlot() ~= -1 then
        discard(player)
        suppress(player)
        return false
    end

    local sec = player:getSecondaryHandItem()
    if sec ~= nil then return false end

    local prim = player:getPrimaryHandItem()
    if prim == e.ref then return false end
    if prim and prim.isRequiresEquippedBothHands and prim:isRequiresEquippedBothHands() then return false end
    if prim and prim.isTwoHandWeapon and prim:isTwoHandWeapon() then return false end

    if not inventoryStillHolds(player, e.ref) then
        discard(player)
        return false
    end

    -- v1.8.19: never write the slot while a TimedAction is running.
    -- Vanilla equip pipelines have a 1-tick window where they sit empty
    -- before vanilla restores.  Writing here re-introduces the v1.8.11
    -- belt-items-on-clothing-change regression class.  The wrap*Perform
    -- callers below pass ignoreBusy=true because they fire AT the known
    -- safe moment immediately after the equip action finishes.
    if not ignoreBusy and isPlayerBusyAction(player) then return false end

    _inFlight = true
    pcall(function() player:setSecondaryHandItem(e.ref) end)
    _inFlight = false
    e.stamp = _frame
    return true
end

CSR_OffhandPersist._tryRestoreSlot = tryRestoreSlot

-- Polling --------------------------------------------------------------------

local function refresh(player)
    if not player or player:isDead() then return end
    _frame = _frame + 1
    if not CSR_FeatureFlags.isDualWieldEnabled() then
        discard(player)
        return
    end

    local sec = player:getSecondaryHandItem()
    if isPlausibleOffhand(player, sec) then
        local e = CSR_OffhandPersist.entry(player)
        if e and e.ref == sec then
            e.stamp     = _frame
            e.lastInvOK = _frame
            -- refresh texture cache in case the live one updated
            if sec.getTex then
                local ok, tx = pcall(function() return sec:getTex() end)
                if ok and tx then e.txr = tx end
            end
        else
            record(player, sec)
        end
        return
    end

    -- Slot is empty/invalid. Decide whether to keep or evict.
    local e = CSR_OffhandPersist.entry(player)
    if not e then return end
    if (_frame - e.stamp) > KEEPALIVE then
        discard(player)
        return
    end
    if not inventoryStillHolds(player, e.ref) then
        discard(player)
        return
    end
    -- v1.8.19 Layer-1 step 3: ACTIVE per-frame re-anchor.  All four guards
    -- live inside tryRestoreSlot().  Throttled to every Nth frame.
    if (_frame % RESTORE_INTERVAL) == 0 then
        tryRestoreSlot(player)
    end
end

-- Wrappers -------------------------------------------------------------------
-- Phase 2 slot continuity: catch the two vanilla code paths that reliably
-- null the secondary while we still want it.

local _wrappedEquip   = false
local _wrappedUnequip = false
local _wrappedAttack  = false
local _eventsBound    = false

local function wrapEquipPerform()
    if _wrappedEquip then return end
    if not ISEquipWeaponAction then return end
    _wrappedEquip = true
    local original = ISEquipWeaponAction.perform
    ISEquipWeaponAction.perform = function(self)
        local player = self and self.character or nil
        local hadBefore = player and player:getSecondaryHandItem() or nil
        original(self)
        if not player then return end
        if not CSR_FeatureFlags.isDualWieldEnabled() then return end
        if not CSR_FeatureFlags.isOffhandPersistEnabled() then return end
        if hadBefore == nil then return end
        if player:getSecondaryHandItem() ~= nil then return end
        -- vanilla cleared the slot during this equip; restore from ledger
        local e = CSR_OffhandPersist.entry(player)
        if not e then
            -- fall back to whatever we observed pre-call
            record(player, hadBefore)
            e = CSR_OffhandPersist.entry(player)
        end
        if e and e.ref == hadBefore then
            tryRestoreSlot(player, true)
        end
    end
end

-- v1.8.19 Layer-1 step 2: when vanilla `ISUnequipAction:perform` runs and
-- the *target item is the same item we have stickied as the off-hand*,
-- the player has chosen to unequip that exact weapon.  Treat as a user
-- intent clear so subsequent setSecondaryHandItem(nil) writes do not
-- resurrect via the ledger.  All other unequip actions (e.g. unequipping
-- the primary while a separate secondary is sticky) leave the ledger
-- alone so the secondary survives the unequip.
local function wrapUnequipPerform()
    if _wrappedUnequip then return end
    if not ISUnequipAction then return end
    _wrappedUnequip = true
    local original = ISUnequipAction.perform
    ISUnequipAction.perform = function(self)
        local player = self and self.character or nil
        local item   = self and self.item or nil
        if player and item then
            local e = CSR_OffhandPersist.entry(player)
            if e and e.ref == item then
                CSR_OffhandPersist.userIntentClear(player)
            end
        end
        return original(self)
    end
end

-- v1.8.26 fix: when the player right-clicks "Place on Back / Belt /
-- Holster / etc." (or drags an item onto a hotbar slot), vanilla queues
-- ISAttachItemHotbar.  If that item happens to be the one the offhand
-- ledger is tracking, the player's intent is "park this on my back",
-- not "keep it as my offhand".  Without this hook, attached items in
-- inventory still pass tryRestoreSlot's `inv:contains()` test and the
-- engine yanks them back into the secondary slot a tick after the
-- attach action completes.  Treat as a userIntentClear so the ledger
-- forgets the item and the suppress window blocks the next restore
-- pass.  (The new attached-slot guard inside tryRestoreSlot is the
-- belt-and-suspenders backstop; this hook is the clean, intent-aware
-- entry point that also covers the OnPlayerAttackFinished restorer.)
local _wrappedAttach = false
local function wrapAttachItemHotbar()
    if _wrappedAttach then return end
    if not ISAttachItemHotbar then return end
    _wrappedAttach = true
    local original = ISAttachItemHotbar.perform
    ISAttachItemHotbar.perform = function(self)
        local player = self and self.character or nil
        local item   = self and self.item or nil
        if player and item then
            local e = CSR_OffhandPersist.entry(player)
            if e and e.ref == item then
                CSR_OffhandPersist.userIntentClear(player)
            end
        end
        return original(self)
    end
end

local function attackFinishedRestore(character, weapon)
    if not character then return end
    if character ~= getPlayer() then return end
    if not CSR_FeatureFlags.isDualWieldEnabled() then return end
    if not CSR_FeatureFlags.isOffhandPersistEnabled() then return end
    if character:getSecondaryHandItem() ~= nil then return end
    tryRestoreSlot(character)
end

-- v1.8.18: the v1.8.17 wrapEquipComplete wrapper that re-applied the
-- sticky off-hand pistol after vanilla nulled it has been removed.
-- Re-applying setSecondaryHandItem inside vanilla's :complete() created a
-- feedback loop with the engine's reciprocal handgun-slot logic that
-- prevented primary pistols from staying equipped at all. The HUD overlay
-- + ledger still keep the icon visible across transient slot clears
-- (clothing change, etc.) for melee dual-wield.

local function bind()
    if not _eventsBound then
        _eventsBound = true
        if Events and Events.OnPlayerUpdate then
            Events.OnPlayerUpdate.Add(refresh)
        end
        if Events and Events.OnPlayerAttackFinished then
            Events.OnPlayerAttackFinished.Add(attackFinishedRestore)
        end
    end
    wrapEquipPerform()
    wrapUnequipPerform()
    wrapAttachItemHotbar()
end

if Events then
    if Events.OnGameStart then
        Events.OnGameStart.Add(function()
            bind()
        end)
    end
    if Events.OnServerStarted then
        Events.OnServerStarted.Add(function()
            bind()
        end)
    end
end

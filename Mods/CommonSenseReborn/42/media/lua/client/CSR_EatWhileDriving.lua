-- CSR_EatWhileDriving.lua
-- Approach B: derive ISEatFoodAction into a vehicle-safe subclass that
-- skips the eat / drink / smoke action animation while the player is
-- locked into a vehicle seat. Hooks ISInventoryPaneContextMenu.eatItem
-- to swap in our subclass when:
--   * sandbox flag EnableEatWhileDriving is on,
--   * player is in a vehicle (any seat is OK; passenger eat works too),
--   * vehicle speed <= EatWhileDrivingMaxSpeed (km/h),
--   * the food's eat type is not a two-handed pot/bowl variant.
--
-- Smoking already works in some vehicles via vanilla canLightSmoke();
-- routing smokables through the same subclass keeps anim suppression
-- consistent so the cigarette doesn't try to play the standing eat anim.
--
-- The subclass is at FILE SCOPE (required for MP server class lookup)
-- and overrides only the parts of ISEatFoodAction:start() that touch
-- character animation / hand model state. Everything else (timer,
-- sound, perform/complete -> character:Eat) stays vanilla.

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISEatFoodAction"
require "CSR_FeatureFlags"

CSR_EatWhileDriving = CSR_EatWhileDriving or {}

-- ─────────────────────────────────────────────────────────────────────
-- TimedAction subclass
-- ─────────────────────────────────────────────────────────────────────
CSR_EatInVehicleAction = ISEatFoodAction:derive("CSR_EatInVehicleAction")

function CSR_EatInVehicleAction:new(character, item, percentage)
    local o = ISEatFoodAction.new(self, character, item, percentage)
    o.csrInVehicle = true
    -- Don't auto-stop on walk -- player isn't walking, vehicle is moving.
    o.stopOnWalk = false
    o.stopOnRun  = false
    return o
end

-- isValid: keep the vanilla "still in inventory" check, but never abort
-- because we're in a vehicle. Vanilla doesn't actually check vehicle in
-- isValid, so this is mostly a passthrough plus a defensive guard.
function CSR_EatInVehicleAction:isValid()
    if not self.character or not self.item then return false end
    return ISEatFoodAction.isValid(self)
end

-- waitToStart: vanilla calls faceThisObject(self.openFlame). The driver
-- is locked to the seat and can't turn, so skip the wait entirely.
function CSR_EatInVehicleAction:waitToStart()
    return false
end

-- start(): we want vanilla's bookkeeping (sound, jobType, jobDelta,
-- consume lighter, EventEating report) but NOT setActionAnim or
-- setOverrideHandModels -- those clash with the seated rig and either
-- silently fail or visually glitch.
--
-- Strategy: stub setActionAnim + setOverrideHandModels for the duration
-- of the parent start() call so the parent runs unmodified but the anim
-- writes are no-ops. Restore afterwards so any later parent code (e.g.
-- complete -> super) is unaffected. This avoids copy-pasting ~80 lines
-- of vanilla start() body and keeps us in sync with future PZ patches.
--
-- IMPORTANT: do NOT pcall vanilla start(). Wrapping a vanilla timed
-- action lifecycle method in pcall has been observed to leave Kahlua's
-- ReturnValues.callFrame null on B42.15+, which silently breaks every
-- subsequent vanilla action in the session (open can, take nail,
-- disassemble, craft). See v1.8.22 hardening notes.
function CSR_EatInVehicleAction:start()
    local origAnim   = self.setActionAnim
    local origModels = self.setOverrideHandModels
    self.setActionAnim          = function(_self, _anim) end
    self.setOverrideHandModels  = function(_self, _a, _b) end
    ISEatFoodAction.start(self)
    self.setActionAnim          = origAnim
    self.setOverrideHandModels  = origModels
end

-- ─────────────────────────────────────────────────────────────────────
-- Eligibility checks
-- ─────────────────────────────────────────────────────────────────────
local TWO_HAND_EAT_TYPES = {
    ["2hand"]      = true,
    ["2handforced"] = true,
    ["2handbowl"]  = true,
    ["Plate"]      = true,
    ["Pot"]        = true,
    ["PotForged"]  = true,
}

local function isTwoHandedFood(item)
    if not item or not item.getEatType then return false end
    local et = item:getEatType()
    if not et or et == "" then return false end
    return TWO_HAND_EAT_TYPES[et] == true
end

-- Returns true if the player can eat-in-vehicle right now, false otherwise.
function CSR_EatWhileDriving.canEatInVehicle(playerObj, item)
    if not (playerObj and item) then return false end
    if not (CSR_FeatureFlags and CSR_FeatureFlags.isEatWhileDrivingEnabled()) then
        return false
    end
    local vehicle = playerObj:getVehicle()
    if not vehicle then return false end
    if isTwoHandedFood(item) then return false end
    local maxKmh = (CSR_FeatureFlags and CSR_FeatureFlags.getEatWhileDrivingMaxSpeed
        and CSR_FeatureFlags.getEatWhileDrivingMaxSpeed()) or 60
    local speed = 0
    if vehicle.getCurrentSpeedKmHour then
        local ok, s = pcall(function() return vehicle:getCurrentSpeedKmHour() end)
        if ok and s then speed = math.abs(s) end
    end
    if speed > maxKmh then return false end
    return true
end

-- ─────────────────────────────────────────────────────────────────────
-- Hook: wrap ISInventoryPaneContextMenu.eatItem to swap action class.
-- ─────────────────────────────────────────────────────────────────────
local _patched = false
local function patchEatItem()
    if _patched then return end
    if not (ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.eatItem) then return end
    if not ISTimedActionQueue then return end

    local origEatItem = ISInventoryPaneContextMenu.eatItem
    local origQueueAdd = ISTimedActionQueue.add

    ISInventoryPaneContextMenu.eatItem = function(item, percentage, player, openingRecipe, eatPercentage)
        local playerObj = getSpecificPlayer(player)
        local canDriveEat = false
        if playerObj and item and playerObj:getVehicle() then
            canDriveEat = CSR_EatWhileDriving.canEatInVehicle(playerObj, item) == true
        end
        if not canDriveEat then
            return origEatItem(item, percentage, player, openingRecipe, eatPercentage)
        end

        -- Driver eat path: temporarily intercept ISTimedActionQueue.add
        -- so that vanilla's eatItem will queue OUR action instead of the
        -- bare ISEatFoodAction. Also let the ISWearClothing call (mask
        -- re-equip) and ISCraftingUI.ReturnItemToContainer pass through
        -- untouched.
        ISTimedActionQueue.add = function(action)
            if action and action.Type == "ISEatFoodAction" and action.character == playerObj then
                local replacement = CSR_EatInVehicleAction:new(action.character, action.item, action.percentage or percentage or 1)
                ISTimedActionQueue.add = origQueueAdd
                return origQueueAdd(replacement)
            end
            ISTimedActionQueue.add = origQueueAdd
            return origQueueAdd(action)
        end

        -- IMPORTANT: do NOT pcall vanilla origEatItem. Wrapping a vanilla
        -- inventory context-menu helper that downstream begins a timed
        -- action in pcall has been observed to corrupt Kahlua's
        -- ReturnValues.callFrame on B42.15+, breaking every subsequent
        -- vanilla action (open can, take nail, disassemble, craft) for
        -- the rest of the session. The queue intercept above restores
        -- ISTimedActionQueue.add the moment it fires, so a partial path
        -- through vanilla still leaves the queue API in a clean state.
        origEatItem(item, percentage, player, openingRecipe, eatPercentage)
        -- Belt-and-suspenders restore in case vanilla never queued an
        -- action at all (e.g. validation aborted before queue.add).
        ISTimedActionQueue.add = origQueueAdd
    end

    _patched = true
end

Events.OnGameStart.Add(patchEatItem)

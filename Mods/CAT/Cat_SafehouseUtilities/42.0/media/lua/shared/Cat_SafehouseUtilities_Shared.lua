-- =============================================================================
-- Cat Safehouse Utilities — Shared (helpers & timed action overrides)
-- =============================================================================

Cat_SafehouseUtilities = Cat_SafehouseUtilities or {}

-- ---------------------------------------------------------------------------
-- Sandbox helpers
-- ---------------------------------------------------------------------------
function Cat_SafehouseUtilities.isEnabled()
    if SandboxVars.Cat_SafehouseUtilities and SandboxVars.Cat_SafehouseUtilities.Enabled ~= nil then
        return SandboxVars.Cat_SafehouseUtilities.Enabled
    end
    return true
end

function Cat_SafehouseUtilities.getGracePeriodHours()
    if SandboxVars.Cat_SafehouseUtilities and SandboxVars.Cat_SafehouseUtilities.GracePeriodHours ~= nil then
        return SandboxVars.Cat_SafehouseUtilities.GracePeriodHours
    end
    return 24
end

-- ---------------------------------------------------------------------------
-- Billing cycle helpers
-- ---------------------------------------------------------------------------
function Cat_SafehouseUtilities.getActiveBillingCycle()
    local sv = SandboxVars.Cat_SafehouseUtilities
    if sv then
        if sv.EnableDailyCharge then return "Day", sv.DailyChargeAmount or 5 end
        if sv.EnableWeeklyCharge then return "Week", sv.WeeklyChargeAmount or 25 end
        if sv.EnableMonthlyCharge then return "Month", sv.MonthlyChargeAmount or 100 end
    end
    -- Fallback to legacy PricePerWeek for backward compatibility
    if sv and sv.PricePerWeek ~= nil then
        return "Week", sv.PricePerWeek
    end
    return "Week", 25
end

function Cat_SafehouseUtilities.getCyclePrice()
    local cycle, price = Cat_SafehouseUtilities.getActiveBillingCycle()
    return price
end

function Cat_SafehouseUtilities.getCycleLabel()
    local cycle = Cat_SafehouseUtilities.getActiveBillingCycle()
    return cycle:lower()
end

function Cat_SafehouseUtilities.getCycleHours()
    local cycle = Cat_SafehouseUtilities.getActiveBillingCycle()
    if cycle == "Day" then return 24 end
    if cycle == "Week" then return 24 * 7 end
    if cycle == "Month" then return 24 * 30 end
    return 24 * 7
end

function Cat_SafehouseUtilities.getPricePerDay()
    local cycle, price = Cat_SafehouseUtilities.getActiveBillingCycle()
    if cycle == "Day" then return price end
    if cycle == "Week" then return price / 7 end
    if cycle == "Month" then return price / 30 end
    return price / 7
end

-- Legacy compatibility
function Cat_SafehouseUtilities.getPricePerWeek()
    return Cat_SafehouseUtilities.getCyclePrice()
end

-- ---------------------------------------------------------------------------
-- Safehouse keying
-- ---------------------------------------------------------------------------
function Cat_SafehouseUtilities.getSafehouseKey(safehouse)
    if not safehouse then return nil end
    return safehouse:getX() .. "," .. safehouse:getY()
end

function Cat_SafehouseUtilities.getSafehouseByKey(key)
    if not key then return nil end
    local list = SafeHouse.getSafehouseList()
    for i = 0, list:size() - 1 do
        local sh = list:get(i)
        if Cat_SafehouseUtilities.getSafehouseKey(sh) == key then
            return sh
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Bounds check
-- ---------------------------------------------------------------------------
function Cat_SafehouseUtilities.isSquareInSafehouse(square, safehouse)
    if not square or not safehouse then return false end
    local x = square:getX()
    local y = square:getY()
    return x >= safehouse:getX() and x <= safehouse:getX2()
       and y >= safehouse:getY() and y <= safehouse:getY2()
end

-- ---------------------------------------------------------------------------
-- Blocked check (client cache vs server authority)
-- ---------------------------------------------------------------------------
Cat_SafehouseUtilities.blockedKeys = Cat_SafehouseUtilities.blockedKeys or {}

function Cat_SafehouseUtilities.checkSquareBlocked(square)
    if not Cat_SafehouseUtilities.isEnabled() then return false end
    if not square then return false end

    local sh = SafeHouse.getSafeHouse(square)
    if not sh then return false end

    local key = Cat_SafehouseUtilities.getSafehouseKey(sh)
    if not key then return false end

    if isServer() then
        local data = ModData.getOrCreate("Cat_SafehouseUtilities")
        local record = data[key]
        if not record then
            -- Never seen before: grace period will be applied by server tick.
            -- Treat as unblocked until first tick runs.
            return false
        end
        if record.exempt then return false end
        local now = getGameTime():getWorldAgeHours()
        return record.expires <= now
    else
        return Cat_SafehouseUtilities.blockedKeys[key] == true
    end
end

-- ---------------------------------------------------------------------------
-- Pre-paid card durations (game hours)
-- ---------------------------------------------------------------------------
Cat_SafehouseUtilities.CARD_DURATIONS = {
    ["Cat_SafehouseUtilities.PrepaidCard_24h"] = 24,
    ["Cat_SafehouseUtilities.PrepaidCard_7d"] = 168,
    ["Cat_SafehouseUtilities.PrepaidCard_30d"] = 720,
}

function Cat_SafehouseUtilities.getCardDuration(itemType)
    return Cat_SafehouseUtilities.CARD_DURATIONS[itemType] or 0
end

-- ---------------------------------------------------------------------------
-- Time formatting
-- ---------------------------------------------------------------------------
function Cat_SafehouseUtilities.formatTimeRemaining(hours)
    if hours <= 0 then return "Expired" end
    local days = math.floor(hours / 24)
    local hrs = math.floor(hours % 24)
    if days > 0 and hrs > 0 then
        return days .. "d " .. hrs .. "h"
    elseif days > 0 then
        return days .. "d"
    else
        return hrs .. "h"
    end
end

-- ---------------------------------------------------------------------------
-- Timed action overrides: water usage
-- ---------------------------------------------------------------------------
local original_ISTakeWater_isValid = ISTakeWaterAction.isValid
function ISTakeWaterAction:isValid()
    if not original_ISTakeWater_isValid(self) then return false end
    if not Cat_SafehouseUtilities.isEnabled() then return true end
    local sq = self.waterObject and self.waterObject:getSquare()
    if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
        return false
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Timed action overrides: electrical appliances
-- ---------------------------------------------------------------------------
local function blockIfUnpaid(original, self)
    if not original(self) then return false end
    if not Cat_SafehouseUtilities.isEnabled() then return true end
    local sq = self.object and self.object:getSquare()
    if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
        return false
    end
    return true
end

local original_ISToggleLightAction_isValid = ISToggleLightAction.isValid
function ISToggleLightAction:isValid()
    return blockIfUnpaid(original_ISToggleLightAction_isValid, self)
end

local original_ISToggleStoveAction_isValid = ISToggleStoveAction.isValid
function ISToggleStoveAction:isValid()
    return blockIfUnpaid(original_ISToggleStoveAction_isValid, self)
end

local original_ISToggleClothingWasher_isValid = ISToggleClothingWasher.isValid
function ISToggleClothingWasher:isValid()
    return blockIfUnpaid(original_ISToggleClothingWasher_isValid, self)
end

local original_ISToggleComboWasherDryer_isValid = ISToggleComboWasherDryer.isValid
function ISToggleComboWasherDryer:isValid()
    return blockIfUnpaid(original_ISToggleComboWasherDryer_isValid, self)
end

local original_ISSetComboWasherDryerMode_isValid = ISSetComboWasherDryerMode.isValid
function ISSetComboWasherDryerMode:isValid()
    return blockIfUnpaid(original_ISSetComboWasherDryerMode_isValid, self)
end

local original_ISToggleClothingDryer_isValid = ISToggleClothingDryer.isValid
function ISToggleClothingDryer:isValid()
    if not original_ISToggleClothingDryer_isValid(self) then return false end
    if not Cat_SafehouseUtilities.isEnabled() then return true end
    local sq = self.object and self.object:getSquare()
    if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
        return false
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Timed action overrides: washing (clothing / self / vehicle)
-- These use ISTakeWaterAction internally, so they are already covered.
-- ISWashYourself, ISWashClothing, ISWashVehicle are separate but also
-- check for a water source square; we will block those in context menus.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Soft compatibility: Lifestyle mod (no hard dependency)
-- Blocks toilet flush, bath prep, bath use, and shower when utilities
-- are disconnected for the safehouse.
-- ---------------------------------------------------------------------------
local LS_PATCHES = {
    LSFlushToilet = function(self) return self.toiletObject and self.toiletObject:getSquare() end,
    LSUseShower   = function(self) return self.showerObject and self.showerObject:getSquare() end,
    LSUseTub      = function(self) return self.mainTubObj and self.mainTubObj:getSquare() end,
    LSPrepareBath = function(self) return self.bathObject and self.bathObject:getSquare() end,
}

local function patchLifestyleClass(cls, squareGetter)
    if not cls or cls._shutilPatched then return end
    local orig = cls.isValid
    if not orig then return end
    cls._shutilPatched = true
    cls.isValid = function(self)
        if not orig(self) then return false end
        if not Cat_SafehouseUtilities.isEnabled() then return true end
        local sq = squareGetter(self)
        if sq and Cat_SafehouseUtilities.checkSquareBlocked(sq) then
            return false
        end
        return true
    end
end

-- Hook ISBaseObject:derive so we catch Lifestyle classes regardless of load order.
local original_ISBaseObject_derive = ISBaseObject.derive
function ISBaseObject:derive(type)
    local cls = original_ISBaseObject_derive(self, type)
    local getter = LS_PATCHES[type]
    if getter then
        patchLifestyleClass(cls, getter)
    end
    return cls
end

-- Also patch any classes that already exist (Lifestyle loaded before us).
for name, getter in pairs(LS_PATCHES) do
    local cls = _G[name]
    if cls then
        patchLifestyleClass(cls, getter)
    end
end

print("[Cat_SafehouseUtilities] Shared utilities loaded.")

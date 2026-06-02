-- =============================================================================
-- Cat Pay Per Fuel — Shared (utilities & timed action overrides)
-- =============================================================================

Cat_PayPerFuel = Cat_PayPerFuel or {}

local JERRY_CAN_LITRES = 10
local PUMP_UNIT_TO_LITRES = JERRY_CAN_LITRES / 8 -- 1.25 litres per pump unit

-- ---------------------------------------------------------------------------
-- Sandbox helpers
-- ---------------------------------------------------------------------------
function Cat_PayPerFuel.getPricePerLitre()
    if SandboxVars.Cat_PayPerFuel and SandboxVars.Cat_PayPerFuel.PricePerLitre ~= nil then
        return SandboxVars.Cat_PayPerFuel.PricePerLitre
    end
    return 2
end

-- ---------------------------------------------------------------------------
-- Cost calculators
-- ---------------------------------------------------------------------------
function Cat_PayPerFuel.calcTakeFuelCost(fuelStation, petrolCan)
    if not fuelStation or not petrolCan then return 0, 0 end
    local pumpCurrent = tonumber(fuelStation:getPipedFuelAmount()) or 0
    local fluidContainer = petrolCan:getFluidContainer()
    local freeCapacity = fluidContainer and fluidContainer:getFreeCapacity() or 0
    local litres = math.min(pumpCurrent, freeCapacity)
    local price = Cat_PayPerFuel.getPricePerLitre()
    local cost = math.ceil(litres * price)
    return litres, cost
end

function Cat_PayPerFuel.calcRefuelCost(fuelStation, part)
    if not fuelStation or not part then return 0, 0 end
    local pumpStart = tonumber(fuelStation:getPipedFuelAmount()) or 0
    local pumpLitresAvail = pumpStart * PUMP_UNIT_TO_LITRES
    local tankStart = part:getContainerContentAmount() or 0
    local tankLitresFree = part:getContainerCapacity() - tankStart
    local litres = math.min(tankLitresFree, pumpLitresAvail)
    local price = Cat_PayPerFuel.getPricePerLitre()
    local cost = math.ceil(litres * price)
    return litres, cost
end

-- ---------------------------------------------------------------------------
-- Approved litres lookup (used to cap timed actions after partial payment)
-- ---------------------------------------------------------------------------
function Cat_PayPerFuel.getApprovedLitres(character, actionType)
    if not character then return nil end
    local username = character:getUsername()
    if isServer() then
        if not Cat_PayPerFuel.sessions then return nil end
        local session = Cat_PayPerFuel.sessions[username]
        if session and (not actionType or session.actionType == actionType) then
            if (getTimestamp() - session.timestamp) > 60 then
                Cat_PayPerFuel.sessions[username] = nil
                return nil
            end
            return session.litres
        end
    else
        if not Cat_PayPerFuel.pending then return nil end
        local pending = Cat_PayPerFuel.pending[username]
        if pending and (not actionType or pending.actionType == actionType) then
            if pending.expiry < getTimestamp() then
                Cat_PayPerFuel.pending[username] = nil
                return nil
            end
            return pending.litres
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Timed action overrides
-- ---------------------------------------------------------------------------
local original_ISTakeFuel_isValid = ISTakeFuel.isValid
function ISTakeFuel:isValid()
    if not original_ISTakeFuel_isValid(self) then return false end
    if Cat_PayPerFuel.getPricePerLitre() == 0 then return true end
    if isServer() then
        return Cat_PayPerFuel and Cat_PayPerFuel.checkServerSession
            and Cat_PayPerFuel.checkServerSession(self.character, self.fuelStation, "take")
    else
        return Cat_PayPerFuel and Cat_PayPerFuel.checkClientPending
            and Cat_PayPerFuel.checkClientPending(self.character, self.fuelStation, "take")
    end
end

local original_ISRefuelFromGasPump_isValid = ISRefuelFromGasPump.isValid
function ISRefuelFromGasPump:isValid()
    if not original_ISRefuelFromGasPump_isValid(self) then return false end
    if Cat_PayPerFuel.getPricePerLitre() == 0 then return true end
    if isServer() then
        return Cat_PayPerFuel and Cat_PayPerFuel.checkServerSession
            and Cat_PayPerFuel.checkServerSession(self.character, self.fuelStation, "refuel")
    else
        return Cat_PayPerFuel and Cat_PayPerFuel.checkClientPending
            and Cat_PayPerFuel.checkClientPending(self.character, self.fuelStation, "refuel")
    end
end

local original_ISTakeFuel_new = ISTakeFuel.new
function ISTakeFuel:new(character, fuelStation, petrolCan)
    local o = original_ISTakeFuel_new(self, character, fuelStation, petrolCan)
    if o and o.amount > 0 then
        local approvedLitres = Cat_PayPerFuel.getApprovedLitres(character, "take")
        if approvedLitres and approvedLitres > 0 then
            local capLitres = math.min(o.amount, approvedLitres)
            if capLitres ~= o.amount then
                o.amount = capLitres
                o.itemTarget = o.itemStart + o.amount
                o.maxTime = o:getDuration()
            end
        end
    end
    return o
end

local original_ISRefuelFromGasPump_getDuration = ISRefuelFromGasPump.getDuration
function ISRefuelFromGasPump:getDuration()
    local duration = original_ISRefuelFromGasPump_getDuration(self)
    if duration > 0 then
        local approvedLitres = Cat_PayPerFuel.getApprovedLitres(self.character, "refuel")
        if approvedLitres and approvedLitres > 0 then
            local currentTakeLitres = self.tankTarget - self.tankStart
            local capLitres = math.min(currentTakeLitres, approvedLitres)
            if capLitres ~= currentTakeLitres then
                self.tankTarget = self.tankStart + capLitres
                self.pumpTarget = self.pumpStart - capLitres / (Vehicles.JerryCanLitres / 8)
                duration = capLitres * 50
            end
        end
    end
    return duration
end

local original_ISTakeFuel_perform = ISTakeFuel.perform
function ISTakeFuel:perform()
    original_ISTakeFuel_perform(self)
    if isServer() and Cat_PayPerFuel and Cat_PayPerFuel.clearServerSession then
        Cat_PayPerFuel.clearServerSession(self.character)
    elseif not isServer() and Cat_PayPerFuel and Cat_PayPerFuel.clearClientPending then
        Cat_PayPerFuel.clearClientPending(self.character)
    end
end

local original_ISRefuelFromGasPump_perform = ISRefuelFromGasPump.perform
function ISRefuelFromGasPump:perform()
    original_ISRefuelFromGasPump_perform(self)
    if isServer() and Cat_PayPerFuel and Cat_PayPerFuel.clearServerSession then
        Cat_PayPerFuel.clearServerSession(self.character)
    elseif not isServer() and Cat_PayPerFuel and Cat_PayPerFuel.clearClientPending then
        Cat_PayPerFuel.clearClientPending(self.character)
    end
end

print("[Cat_PayPerFuel] Shared utilities loaded.")

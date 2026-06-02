-- CSR_EVConvert.lua — Electric Vehicle conversion (client side).
-- Adds a context option on the trunk window to convert a vehicle to electric:
-- consumes batteries + wires + duct tape + a battery charger, then flags the
-- vehicle as csrEV. The fuel level is clamped each tick so vanilla engine
-- logic keeps running, while charge slowly drains (and is restored when
-- parked beside a CarBatteryCharger inside a CSR PowerBar zone).
require "CSR_PowerBar"

local CSR_EVConvert = {}

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

local function isEnabled()
    return sandbox().EnableEVConversion == true
end

local EV_BLUE = { r = 0.20, g = 0.58, b = 1.0, a = 1.0 }

local function isEVVehicle(vehicle)
    local md = vehicle and vehicle.getModData and vehicle:getModData() or nil
    return md and md.csrEV and true or false
end

local function csrText(key, fallback)
    local text = getText and getText(key) or nil
    if not text or text == "" or text == key then return fallback end
    return text
end

local function reqs()
    local sb = sandbox()
    return {
        batteries = math.max(1, math.min(10, tonumber(sb.EVRequiredBatteries) or 4)),
        wires     = math.max(1, math.min(20, tonumber(sb.EVRequiredWires) or 8)),
        ducttape  = 2,
        chargers  = 1,
        mech      = math.max(0, math.min(10, tonumber(sb.EVConvertMechanicsLevel) or 4)),
        elec      = math.max(0, math.min(10, tonumber(sb.EVConvertElectricalLevel) or 4)),
    }
end

-- v1.8.34c: B42.17 hasTag is missing on some InventoryItem subclasses
-- (Clothing, ComboItem, Padlock). The previous predicate called
-- it:hasTag("carbattery") inside getAllEvalRecurse, which threw
-- "No implementation found for function: hasTag" the moment iteration
-- touched one of those types -- breaking the EV Convert panel button
-- for any player carrying a worn item or padlock. Vanilla only ships
-- three concrete carbattery types, so match by fullType set instead.
local CSR_EV_CARBATTERY_TYPES = {
    ["Base.CarBattery1"] = true,
    ["Base.CarBattery2"] = true,
    ["Base.CarBattery3"] = true,
}

local function countInv(inv, ft)
    if not inv then return 0 end
    -- "Base.CarBattery" is a virtual id (vanilla ships CarBattery1/2/3).
    -- Match all three by fullType.
    local matchByCarBattery = (ft == "Base.CarBattery")
    local function matches(it)
        if not it or not it.getFullType then return false end
        local fft = it:getFullType()
        if matchByCarBattery then
            return CSR_EV_CARBATTERY_TYPES[fft] == true
        end
        return fft == ft
    end
    local n = 0
    -- Recurse worn bags: items inside backpacks/satchels count too.
    local items = inv.getAllEvalRecurse and inv:getAllEvalRecurse(matches) or nil
    if items and items.size then
        n = items:size()
    else
        -- Fallback: top-level only.
        local top = inv:getItems()
        for i = 0, top:size() - 1 do
            local it = top:get(i)
            if matches(it) then n = n + 1 end
        end
    end
    return n
end

-- Count an item type across the player's inventory (worn bags recursed) AND
-- every accessible part container on the target vehicle (trunk, glove box,
-- seats, etc). Lets crafting parts sit in the trunk of the vehicle being
-- converted instead of forcing the player to pull them out first.
local function countAvailable(player, vehicle, ft)
    local total = 0
    if player then total = total + countInv(player:getInventory(), ft) end
    if vehicle and vehicle.getPartCount then
        local n = vehicle:getPartCount()
        for i = 0, n - 1 do
            local part = vehicle:getPartByIndex(i)
            local cont = part and part.getItemContainer and part:getItemContainer() or nil
            if cont then total = total + countInv(cont, ft) end
        end
    end
    return total
end

-- ----------------------------------------------------------------------------
-- Conversion confirmation panel (small modal)
-- ----------------------------------------------------------------------------
local CSR_EVConvertPanel = ISCollapsableWindow:derive("CSR_EVConvertPanel")

function CSR_EVConvertPanel:new(x, y, vehicle, playerNum)
    local o = ISCollapsableWindow.new(self, x, y, 460, 320)
    o.title = getText("IGUI_CSR_EVConvertTitle") or "Convert to Electric"
    o.vehicle = vehicle
    o.playerNum = playerNum or 0
    o.resizable = false
    o:setResizable(false)
    return o
end

function CSR_EVConvertPanel:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()
    local r = reqs()

    local lines = {}
    table.insert(lines, getText("IGUI_CSR_EVConvertHeader") or
        "Permanently convert this vehicle to electric. Required parts:")
    table.insert(lines, ("  - %d x Car Battery"):format(r.batteries))
    table.insert(lines, ("  - %d x Electrical Wire"):format(r.wires))
    table.insert(lines, ("  - %d x Duct Tape"):format(r.ducttape))
    table.insert(lines, ("  - %d x Car Battery Charger"):format(r.chargers))
    table.insert(lines, " ")
    -- Build the skill line with plain concat. We previously tried
    -- (getText(...)):format(...) and tostring(getText(...)) +
    -- string.format(...); both silently failed to substitute %d in
    -- the live UI (likely because getText returns a Java-string wrapper
    -- and Lua's format dispatch on it is a no-op). Concat is bulletproof.
    local mechN = tostring(tonumber(r.mech) or 0)
    local elecN = tostring(tonumber(r.elec) or 0)
    table.insert(lines,
        (getText("IGUI_CSR_EVConvertSkillPrefix") or "Requires Mechanics ") ..
        mechN ..
        (getText("IGUI_CSR_EVConvertSkillJoin") or " and Electrical ") ..
        elecN .. ".")
    table.insert(lines, getText("IGUI_CSR_EVConvertChargerHint") or
        "Vehicle must be parked next to an energized Car Battery Charger.")
    table.insert(lines, " ")
    table.insert(lines, getText("IGUI_CSR_EVConvertFooter") or
        "Trunk capacity will be reduced. Charge by parking next to an energized charger.")

    local btnH = 24
    local pad = 12
    local bodyW = self:getWidth() - pad * 2
    local bodyH = self:getHeight() - th - pad * 2 - btnH - pad

    self.body = ISRichTextPanel:new(pad, th + pad, bodyW, bodyH)
    self.body:initialise()
    self.body.background = false
    self.body.autosetheight = false
    self.body.marginTop = 0
    self.body.marginLeft = 0
    self.body.marginRight = 0
    self.body.marginBottom = 0
    self.body.defaultFont = UIFont.Small
    self.body:setAnchorRight(true)
    self.body:setAnchorBottom(true)
    self.body.text = table.concat(lines, " <LINE> ")
    self.body:paginate()
    self:addChild(self.body)

    local btnW = 150
    self.convertBtn = ISButton:new(pad, self:getHeight() - btnH - pad, btnW, btnH,
        getText("IGUI_CSR_EVConvertButton") or "Convert", self, CSR_EVConvertPanel.onConvert)
    self.convertBtn:initialise()
    self:addChild(self.convertBtn)

    self.cancelBtn = ISButton:new(self:getWidth() - btnW - pad, self:getHeight() - btnH - pad, btnW, btnH,
        getText("UI_Cancel") or "Cancel", self, CSR_EVConvertPanel.onCancel)
    self.cancelBtn:initialise()
    self:addChild(self.cancelBtn)
end

function CSR_EVConvertPanel:prerender()
    ISCollapsableWindow.prerender(self)
    if not self._partsChecked then
        self._partsChecked = true
        local p = getSpecificPlayer(self.playerNum)
        local r = reqs()
        local hasParts = p
            and countAvailable(p, self.vehicle, "Base.CarBattery")        >= r.batteries
            and countAvailable(p, self.vehicle, "Base.ElectricWire")      >= r.wires
            and countAvailable(p, self.vehicle, "Base.DuctTape")          >= r.ducttape
            and countAvailable(p, self.vehicle, "Base.CarBatteryCharger") >= r.chargers
        local mechLvl, elecLvl = 0, 0
        if p then
            pcall(function() mechLvl = p:getPerkLevel(Perks.Mechanics) or 0 end)
            pcall(function() elecLvl = p:getPerkLevel(Perks.Electricity) or 0 end)
        end
        local hasSkill = mechLvl >= r.mech and elecLvl >= r.elec
        local nearCharger = false
        local vsq = self.vehicle and self.vehicle.getCurrentSquare and self.vehicle:getCurrentSquare() or nil
        if vsq and CSR_PowerBar and CSR_PowerBar.findEnergizedChargerNear then
            nearCharger = CSR_PowerBar.findEnergizedChargerNear(vsq, 2) ~= nil
        end
        local ok = hasParts and hasSkill and nearCharger
        self.convertBtn.enable = ok and true or false
        if not ok then
            local why = {}
            if not hasParts    then table.insert(why, getText("Tooltip_CSR_EVMissingShort") or "Missing required parts.") end
            if not hasSkill    then
                table.insert(why,
                    (getText("IGUI_CSR_EVConvertSkillPrefix") or "Requires Mechanics ") ..
                    tostring(tonumber(r.mech) or 0) ..
                    (getText("IGUI_CSR_EVConvertSkillJoin") or " and Electrical ") ..
                    tostring(tonumber(r.elec) or 0) .. ".")
            end
            if not nearCharger then table.insert(why, getText("Tooltip_CSR_EVNeedCharger") or "Park next to an energized Car Battery Charger.") end
            self.convertBtn.tooltip = table.concat(why, "\n")
        end
    end
end

function CSR_EVConvertPanel:onConvert()
    local p = getSpecificPlayer(self.playerNum)
    if not p or not self.vehicle then self:close(); return end
    local args = { vehicleId = self.vehicle:getId() }
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", "EVConvert", args)
    elseif CSR_ServerCommands and CSR_ServerCommands.handleEVConvert then
        CSR_ServerCommands.handleEVConvert(p, args)
    end
    self:close()
end

function CSR_EVConvertPanel:onCancel()
    self:close()
end

-- ----------------------------------------------------------------------------
-- Trunk / vehicle context menu hook
-- ----------------------------------------------------------------------------
local function onConvertOption(playerNum, vehicle)
    local p = getSpecificPlayer(playerNum)
    if not p or not vehicle then return end
    local panel = CSR_EVConvertPanel:new(getPlayerScreenWidth(playerNum) / 2 - 230,
                                         getPlayerScreenHeight(playerNum) / 2 - 160,
                                         vehicle, playerNum)
    panel:initialise()
    panel:addToUIManager()
    panel:bringToTop()
end

local function onRevertOption(playerNum, vehicle)
    local p = getSpecificPlayer(playerNum)
    if not p or not vehicle then return end
    local args = { vehicleId = vehicle:getId() }
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", "EVRevert", args)
    elseif CSR_ServerCommands and CSR_ServerCommands.handleEVRevert then
        CSR_ServerCommands.handleEVRevert(p, args)
    end
end

local function findVehicleAt(worldObjects)
    for i = 1, #worldObjects do
        local obj = worldObjects[i]
        local sq = obj and obj.getSquare and obj:getSquare()
        if sq and sq.getVehicleContainer then
            local v = sq:getVehicleContainer()
            if v then return v end
        end
    end
    return nil
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test == true then return true end
    if not isEnabled() then return end

    local v = findVehicleAt(worldObjects)
    if not v then return end

    local p = getSpecificPlayer(playerNum)
    if not p then return end

    local md = v:getModData()
    if md.csrEV then
        local opt = context:addOption(getText("ContextMenu_CSR_EVRevert") or
            "Revert from Electric", playerNum, onRevertOption, v)
        local tip = ISToolTip:new(); tip:initialise(); tip:setVisible(false)
        tip.description = getText("Tooltip_CSR_EVRevert") or
            "Removes the EV conversion. Recovers some parts."
        opt.toolTip = tip
    else
        local opt = context:addOption(getText("ContextMenu_CSR_EVConvert") or
            "Convert to Electric...", playerNum, onConvertOption, v)
        local tip = ISToolTip:new(); tip:initialise(); tip:setVisible(false)
        local r = reqs()
        local needSkillStr =
            (getText("IGUI_CSR_EVConvertSkillPrefix") or "Requires Mechanics ") ..
            tostring(tonumber(r.mech) or 0) ..
            (getText("IGUI_CSR_EVConvertSkillJoin") or " and Electrical ") ..
            tostring(tonumber(r.elec) or 0) .. "."
        tip.description = (getText("Tooltip_CSR_EVConvert") or
            "Convert this vehicle to electric. Opens conversion panel.") ..
            " <LINE> " .. needSkillStr ..
            " <LINE> " .. (getText("Tooltip_CSR_EVNeedCharger") or
            "Park next to an energized Car Battery Charger to convert.")
        opt.toolTip = tip
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

-- ----------------------------------------------------------------------------
-- Fuel clamp + drain.
-- We refill the tank to ~full every player tick on EV vehicles so vanilla
-- engine logic never starves. Drain comes out of csrEVCharge, derived from
-- throttle/speed.
-- ----------------------------------------------------------------------------
local _drainAccum = 0
local function onPlayerUpdate(player)
    if not player then return end
    local v = player:getVehicle()
    if not v then return end
    local md = v:getModData()
    if not md.csrEV then return end

    -- Clamp fuel so the engine never thinks it's empty.
    pcall(function()
        if v.getCurrentFuelAmount and v.setCurrentFuelAmount then
            local cur = v:getCurrentFuelAmount()
            if cur < 0.95 then v:setCurrentFuelAmount(1.0) end
        end
    end)

    -- Drain charge while engine is running. Approximate per-frame.
    local engineOn = false
    pcall(function() engineOn = v:isEngineRunning() end)
    if engineOn then
        local sb = sandbox()
        local drainPerKm = math.max(1, math.min(20, tonumber(sb.EVDrainPerKmAt100Throttle) or 5))
        local speed = 0
        pcall(function() speed = math.abs(v:getCurrentSpeedKmHour() or 0) end)
        -- speed (km/h) * dt (h). dt here ~= 1/60 game-frame; since OnPlayerUpdate
        -- fires at variable rate we use a soft scalar.
        _drainAccum = _drainAccum + (speed * drainPerKm) / 3600.0 -- pct/sec -> pct/frame
        if _drainAccum >= 0.05 then
            local steps = math.floor(_drainAccum / 0.05)
            _drainAccum = _drainAccum - steps * 0.05
            local charge = (tonumber(md.csrEVCharge) or 0) - 0.05 * steps
            if charge < 0 then charge = 0 end
            md.csrEVCharge = charge
            -- When charge is empty, force engine off.
            if charge <= 0 then
                pcall(function()
                    if v.setCurrentFuelAmount then v:setCurrentFuelAmount(0) end
                end)
            end
        end
    end
end
Events.OnPlayerUpdate.Add(onPlayerUpdate)

-- ----------------------------------------------------------------------------
-- Dashboard EV polish:
--   * Tint leftSideFuel / rightSideFuel arrows blue.
--   * Override the fuel gauge needle to follow csrEVCharge (0..100) rather
--     than the clamped gas tank value the engine sees.
--   * Draw "Charge NN%" text under the fuel gauge so players know it's an EV.
-- ----------------------------------------------------------------------------
local function patchDashboard()
    if not ISVehicleDashboard or ISVehicleDashboard.__csr_ev_patched then return end
    ISVehicleDashboard.__csr_ev_patched = true
    local original = ISVehicleDashboard.prerender
    function ISVehicleDashboard:prerender(...)
        local ret = original(self, ...)
        if not self.vehicle then return ret end

        local md = self.vehicle:getModData()
        local isEV = isEVVehicle(self.vehicle)

        -- Side arrow tint
        if self.leftSideFuel and self.leftSideFuel.setColor then
            if isEV then self.leftSideFuel:setColor(0.20, 0.55, 0.95)
            else self.leftSideFuel:setColor(1, 1, 1) end
        end
        if self.rightSideFuel and self.rightSideFuel.setColor then
            if isEV then self.rightSideFuel:setColor(0.20, 0.55, 0.95)
            else self.rightSideFuel:setColor(1, 1, 1) end
        end

        if isEV and self.fuelGauge then
            local charge = tonumber(md.csrEVCharge) or 0
            if charge < 0 then charge = 0 elseif charge > 100 then charge = 100 end
            -- Drive the needle off charge instead of the artificial gas value.
            self.fuelGauge:setValue(charge / 100)

            -- "Charge NN%" label, centered under the gauge.
            local label = (getText("IGUI_CSR_EVChargePct", math.floor(charge + 0.5))) or ("Charge " .. math.floor(charge + 0.5) .. "%")
            local font = UIFont.Small
            local tw = getTextManager():MeasureStringX(font, label)
            local gx = self.fuelGauge:getX() + (self.fuelGauge:getWidth() / 2) - (tw / 2)
            local gy = self.fuelGauge:getY() + self.fuelGauge:getHeight() + 2
            -- Color: green when high, red when low.
            local r, g, b = 0.20, 0.85, 0.45
            if charge < 25 then r, g, b = 0.95, 0.30, 0.25
            elseif charge < 60 then r, g, b = 0.95, 0.80, 0.25 end
            self:drawText(label, gx, gy, r, g, b, 1.0, font)
        end

        return ret
    end
end
Events.OnGameStart.Add(patchDashboard)

-- ----------------------------------------------------------------------------
-- Vehicle mechanic UI tooltip: when hovering GasTank on an EV, swap the
-- vanilla "Gasoline X / Y" line for "Charge NN%". Also rename part title.
-- ----------------------------------------------------------------------------
local function patchMechanicTooltip()
    if not ISVehicleMechanics or ISVehicleMechanics.__csr_ev_patched then return end
    ISVehicleMechanics.__csr_ev_patched = true

    if ISVehicleMechanics.initParts then
        local originalInitParts = ISVehicleMechanics.initParts
        function ISVehicleMechanics:initParts(...)
            local ret = originalInitParts(self, ...)
            if not isEVVehicle(self.vehicle) then return ret end
            local electric = csrText("IGUI_CSR_EVElectric", "Electric")
            local gasCat = getText and getText("IGUI_VehiclePartCatgastank") or "Gas Tank"
            local function renameList(list)
                if not list or not list.items then return end
                for i = 1, #list.items do
                    local entry = list.items[i]
                    local item = entry and entry.item or nil
                    if item then
                        if item.part and item.part.getId and item.part:getId() == "GasTank" then
                            item.name = electric
                        elseif item.cat and (item.name == gasCat or item.name == "Gas Tank") then
                            item.name = electric
                        end
                    end
                end
            end
            renameList(self.listbox)
            renameList(self.bodyworklist)
            return ret
        end
    end

    if ISVehicleMechanics.getConditionRGB then
        local originalConditionRGB = ISVehicleMechanics.getConditionRGB
        function ISVehicleMechanics:getConditionRGB(condition, ...)
            if isEVVehicle(self.vehicle) and (tonumber(condition) or 0) >= 50 then
                return { r = EV_BLUE.r, g = EV_BLUE.g, b = EV_BLUE.b, a = EV_BLUE.a }
            end
            return originalConditionRGB(self, condition, ...)
        end
    end

    local original = ISVehicleMechanics.renderCarOverlayTooltip
    function ISVehicleMechanics:renderCarOverlayTooltip(partProps, part, carType)
        local shown = original(self, partProps, part, carType)
        if not shown or not self.tooltip or not self.tooltip:isVisible() then return shown end
        if not part or part:getId() ~= "GasTank" then return shown end
        local v = self.vehicle
        if not v then return shown end
        local md = v:getModData()
        if not md or not md.csrEV then return shown end

        local charge = tonumber(md.csrEVCharge) or 0
        if charge < 0 then charge = 0 elseif charge > 100 then charge = 100 end
        local pctTxt = string.format("%d%%", math.floor(charge + 0.5))
        self.tooltip:setName(getText("IGUI_CSR_EVPartBattery") or "Battery Pack")
        local cond = part.getCondition and part:getCondition() or 100
        local line = (getText("IGUI_invpanel_Condition") or "Condition") .. ": " .. cond .. "%"
        line = line .. " <LINE> " .. (getText("IGUI_CSR_EVCharge") or "Charge") .. ": " .. pctTxt
        self.tooltip.description = line
        return shown
    end
end
Events.OnGameStart.Add(patchMechanicTooltip)

-- ----------------------------------------------------------------------------
-- Suppress vanilla "Add Gasoline" / refuel context entries on EV vehicles to
-- avoid confusing players who try to refuel an electric car.
-- ----------------------------------------------------------------------------
local function suppressFuelMenu(playerNum, context, worldObjects, test)
    if test == true then return end
    local v = findVehicleAt(worldObjects)
    if not v then return end
    local md = v:getModData()
    if not md.csrEV then return end
    -- Walk options and disable any that look like fuel actions.
    local options = context.options
    if not options then return end
    for i = 1, #options do
        local o = options[i]
        local txt = o and o.name or ""
        if type(txt) == "string" then
            local lower = string.lower(txt)
            if string.find(lower, "gasoline", 1, true)
                or string.find(lower, "fuel", 1, true)
                or string.find(lower, "siphon", 1, true)
                or string.find(lower, "petrol", 1, true)
            then
                o.notAvailable = true
            end
        end
    end
end
Events.OnFillWorldObjectContextMenu.Add(suppressFuelMenu)

-- ----------------------------------------------------------------------------
-- Vehicle radial menu slice: Convert / Revert EV.
-- Uses the vanilla "Item_CarBattery" icon as a placeholder until we ship a
-- dedicated EV slice texture.
-- ----------------------------------------------------------------------------
local function hookEVRadial()
    if not ISVehicleMenu or not ISVehicleMenu.showRadialMenuOutside or ISVehicleMenu.__csr_ev_radial then
        return
    end
    ISVehicleMenu.__csr_ev_radial = true
    local original = ISVehicleMenu.showRadialMenuOutside
    ISVehicleMenu.showRadialMenuOutside = function(playerObj, ...)
        original(playerObj, ...)
        if not isEnabled() then return end
        if not playerObj then return end

        local vehicle = ISVehicleMenu.getVehicleToInteractWith
            and ISVehicleMenu.getVehicleToInteractWith(playerObj) or nil
        if not vehicle then return end

        local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
        if not menu then return end

        local tex = getTexture("Item_CarBattery")
        local md = vehicle:getModData()
        local pn = playerObj:getPlayerNum()

        if md.csrEV then
            local label = getText("ContextMenu_CSR_EVRevert") or "Revert from Electric"
            menu:addSlice(label, tex, function() onRevertOption(pn, vehicle) end)
        else
            local label = getText("ContextMenu_CSR_EVConvert") or "Convert to Electric"
            menu:addSlice(label, tex, function() onConvertOption(pn, vehicle) end)
        end
    end
end
Events.OnGameStart.Add(hookEVRadial)

_G.CSR_EVConvert = CSR_EVConvert
return CSR_EVConvert

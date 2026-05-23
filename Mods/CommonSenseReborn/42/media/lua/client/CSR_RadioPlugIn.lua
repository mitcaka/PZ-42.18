-- CSR_RadioPlugIn.lua — placed-radio mains/cable power baseline.
-- Inspired by the long-standing "plug in your radio" QoL pattern: when the
-- player opens the radio interface on a placed radio (IsoRadio world object),
-- if its tile has electricity (vanilla grid OR a CSR PowerBar cable zone),
-- the radio is silently switched to mains power so it doesn't drain its
-- battery. When power drops, the radio falls back to battery on the next
-- interaction. Inventory walkie-talkies always run on battery.
require "RadioCom/ISRadioWindow"
require "CSR_PowerBar"

local CSR_RadioPlugIn = {}

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

local function isEnabled()
    return sandbox().EnableRadioPlugIn ~= false
end

local function getDeviceData(deviceObject)
    if not deviceObject then return nil end
    if deviceObject.getDeviceData then
        return deviceObject:getDeviceData()
    end
    return nil
end

local function isPlacedRadio(deviceObject)
    -- Inventory radios = instanceof Radio. Placed radios + walkie-talkies
    -- placed in the world = NOT instanceof Radio (they are IsoRadio or
    -- IsoWaveSignal-bearing objects).
    return deviceObject and not instanceof(deviceObject, "Radio")
end

local function squareForDevice(deviceObject, ddata)
    if ddata and ddata.getIsoObject then
        local iso = ddata:getIsoObject()
        if iso and iso.getSquare then return iso:getSquare() end
    end
    if deviceObject and deviceObject.getSquare then
        return deviceObject:getSquare()
    end
    return nil
end

local function setBattery(ddata, useBattery, sq)
    if not ddata or not ddata.setIsBatteryPowered then return end
    ddata:setIsBatteryPowered(useBattery and true or false)
    if isClient() and sq then
        local p = getSpecificPlayer(0) or getPlayer()
        if p then
            sendClientCommand(p, "CommonSenseReborn", "RadioPlugSync", {
                useBattery = useBattery and 1 or 0,
                x = sq:getX(), y = sq:getY(), z = sq:getZ(),
            })
        end
    end
end

function CSR_RadioPlugIn.applyFor(deviceObject)
    if not isEnabled() then return end
    if not deviceObject then return end

    local ddata = getDeviceData(deviceObject)
    if not ddata then return end

    -- Skip TVs and vehicle radios — they have their own power model.
    local isTV = false
    local isVehicle = false
    if ddata.getIsTelevision then isTV = ddata:getIsTelevision() end
    if ddata.isVehicleDevice then isVehicle = ddata:isVehicleDevice() end
    if isTV or isVehicle then return end

    if not isPlacedRadio(deviceObject) then
        -- Carried/inventory walkie or radio — always battery.
        setBattery(ddata, true, nil)
        return
    end

    local sq = squareForDevice(deviceObject, ddata)
    if not sq then return end

    local powered = CSR_PowerBar.isSquarePoweredAny(sq)
    setBattery(ddata, not powered, sq)
end

-- Hook ISRadioWindow.activate so every time the player opens a radio UI we
-- re-evaluate plug-in state. This is light: one square query + one setter.
-- Patch update as well so a portable radio that was already on stays on when
-- the window closes because the item left the hands/back slot.
local function patchRadioWindow()
    if not ISRadioWindow or ISRadioWindow.__csr_plug_patched then return end
    ISRadioWindow.__csr_plug_patched = true

    local original = ISRadioWindow.activate
    function ISRadioWindow.activate(_player, _deviceObject)
        CSR_RadioPlugIn.applyFor(_deviceObject)
        return original(_player, _deviceObject)
    end

    local originalUpdate = ISRadioWindow.update
    function ISRadioWindow:update(...)
        local keepOnData = nil
        if self.deviceType == "InventoryItem"
            and self.deviceData
            and self.deviceData.getIsTurnedOn
            and self.deviceData:getIsTurnedOn()
            and self.deviceData.setIsTurnedOn then
            keepOnData = self.deviceData
        end

        originalUpdate(self, ...)

        if keepOnData and keepOnData.getIsTurnedOn and not keepOnData:getIsTurnedOn() then
            keepOnData:setIsTurnedOn(true)
        end
    end
end

Events.OnGameStart.Add(patchRadioWindow)

_G.CSR_RadioPlugIn = CSR_RadioPlugIn
return CSR_RadioPlugIn

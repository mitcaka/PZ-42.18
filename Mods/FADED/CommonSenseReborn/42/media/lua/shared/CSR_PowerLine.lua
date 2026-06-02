-- CSR_PowerLine.lua  (v1.8.34 — replacement for the old PowerBar registry)
-- Per-tile blue "extension cord" trail painted by walking with a Power Bar.
-- Right-click any powered tile to start a line; walk to lay it; right-click
-- the destination to end it (the Power Bar is consumed and every painted
-- square — including the destination — becomes a permanent powered tile).
--
-- Persistence: flat-key bool on each grid square's ModData. No central
-- registry, no per-tick maintenance, no phantom IsoGenerators.
--
-- Public API:
--   CSR_PowerLine.isPowered(square)         -> bool   (csr-powered OR vanilla)
--   CSR_PowerLine.isPaintedPowered(square)  -> bool   (csr-only)
--   CSR_PowerLine.setPainted(square, bool)
--   CSR_PowerLine.squareKey(square)         -> "x,y,z"
require "CSR_FeatureFlags"
require "CSR_PowerBar"

CSR_PowerLine = CSR_PowerLine or {}

CSR_PowerLine.PAINT_KEY    = "csrPwrLine"     -- transient: laid but not yet finalized
CSR_PowerLine.POWER_KEY    = "csrPwrPowered"  -- permanent: this tile is energized
CSR_PowerLine.DISABLED_KEY = "csrPwrOff"      -- per-tile manual breaker (true = OFF)

local function sb()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

function CSR_PowerLine.isEnabled()
    return sb().EnablePowerLine ~= false
end

function CSR_PowerLine.maxLineLength()
    local v = tonumber(sb().PowerLineMaxLength) or 24
    if v < 4 then v = 4 end
    if v > 64 then v = 64 end
    return math.floor(v)
end

function CSR_PowerLine.squareKey(sq)
    if not sq then return nil end
    return tostring(sq:getX()) .. "," .. tostring(sq:getY()) .. "," .. tostring(sq:getZ())
end

-- Vanilla power on the square: grid/hydro mains or active generator radius.
-- Delegates to CSR_PowerBar.squareHasNativePower so there is a single
-- source-of-truth (see PowerBar for the actual generator scan).
local function squareHasNativePower(sq)
    if not sq then return false end
    if CSR_PowerBar and CSR_PowerBar.squareHasNativePower then
        local ok, has = pcall(CSR_PowerBar.squareHasNativePower, sq)
        if ok then return has == true end
    end
    -- Fallback (PowerBar not loaded yet during early init): minimal
    -- vanilla check. Will be replaced by the real scan once loaded.
    local has = false
    pcall(function() has = sq:haveElectricity() end)
    return has == true
end
CSR_PowerLine.squareHasNativePower = squareHasNativePower

function CSR_PowerLine.isPaintedPowered(sq)
    if not sq or not sq.getModData then return false end
    local md = sq:getModData()
    if not md then return false end
    if md[CSR_PowerLine.POWER_KEY] ~= true then return false end
    -- Manually switched-off wiring counts as not powered (just like a
    -- generator with isActivated() == false). Visual is still drawn,
    -- but downstream consumers (chargers, EV) treat it as cold.
    if md[CSR_PowerLine.DISABLED_KEY] == true then return false end
    return true
end

-- True if a tile is part of our wiring at all (powered, on or off).
function CSR_PowerLine.isWiringTile(sq)
    if not sq or not sq.getModData then return false end
    local md = sq:getModData()
    return md and md[CSR_PowerLine.POWER_KEY] == true
end

-- Manual breaker state per tile.
function CSR_PowerLine.isDisabled(sq)
    if not sq or not sq.getModData then return false end
    local md = sq:getModData()
    return md and md[CSR_PowerLine.DISABLED_KEY] == true
end

function CSR_PowerLine.setDisabled(sq, off)
    if not sq or not sq.getModData then return end
    local md = sq:getModData()
    if off then md[CSR_PowerLine.DISABLED_KEY] = true
    else        md[CSR_PowerLine.DISABLED_KEY] = nil end
end

function CSR_PowerLine.isPowered(sq)
    if not sq then return false end
    if squareHasNativePower(sq) then return true end
    return CSR_PowerLine.isPaintedPowered(sq)
end

-- Mid-trail painted (unfinished line) — visible in blue but not yet powered.
function CSR_PowerLine.isPaintedTrail(sq)
    if not sq or not sq.getModData then return false end
    local md = sq:getModData()
    return md and md[CSR_PowerLine.PAINT_KEY] == true
end

function CSR_PowerLine.setPaintedTrail(sq, painted)
    if not sq or not sq.getModData then return end
    local md = sq:getModData()
    if painted then md[CSR_PowerLine.PAINT_KEY] = true
    else            md[CSR_PowerLine.PAINT_KEY] = nil end
end

function CSR_PowerLine.setPainted(sq, powered)
    if not sq or not sq.getModData then return end
    local md = sq:getModData()
    if powered then
        md[CSR_PowerLine.POWER_KEY] = true
        md[CSR_PowerLine.PAINT_KEY] = nil
    else
        md[CSR_PowerLine.POWER_KEY] = nil
    end
end

return CSR_PowerLine

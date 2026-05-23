-- CSR_FoodExpiryTooltip.lua
--
-- Optional: append two color-coded expiry lines to vanilla item tooltips
-- for any Food item with usable spoilage data. Disabled by default; enable
-- via Sandbox > CSR Interface > "Show food expiry on item tooltips" (or
-- via the in-game CSR player prefs panel).
--
-- The numeric values come from CSR_Utils.getFoodExpiryDays(item), which
-- reads the per-instance offAgeMax and the live FoodRotSpeed / FridgeFactor
-- sandbox settings, so projections track whatever the world is actually
-- doing to the item.

require "ISUI/ISToolTipInv"
require "CSR_Utils"
require "CSR_FeatureFlags"

local original_render = ISToolTipInv.render

local function formatDays(d)
    if type(d) ~= "number" or d <= 0 then return "0" end
    if d < 1 then
        return tostring(math.floor(d * 24 + 0.5)) .. "h"
    end
    if d < 10 then
        return string.format("%.1fd", d)
    end
    return tostring(math.floor(d + 0.5)) .. "d"
end

function ISToolTipInv:render()
    original_render(self)

    if not (CSR_FeatureFlags and CSR_FeatureFlags.isFoodExpiryTooltipEnabled
            and CSR_FeatureFlags.isFoodExpiryTooltipEnabled()) then
        return
    end

    local item = self.item
    if not item then return end

    local exp = CSR_Utils.getFoodExpiryDays(item)
    if not exp then return end
    if exp.isSealed then return end  -- canned/jarred: no useful number

    local line1, r1, g1, b1
    local line2, r2, g2, b2

    if exp.isRotten then
        line1 = "Rotten"
        r1, g1, b1 = 1, 0.2, 0.2
    else
        local roomTxt   = formatDays(exp.roomDays)
        local fridgeTxt = formatDays(exp.fridgeDays)
        line1 = "Fresh: " .. roomTxt .. " (room)"
        if exp.roomDays >= 1 then
            r1, g1, b1 = 0.4, 1.0, 0.4
        else
            r1, g1, b1 = 1.0, 0.85, 0.2
        end
        line2 = "Fridge: " .. fridgeTxt
        r2, g2, b2 = 0.55, 0.8, 1.0
    end

    -- Resolve the tooltip's font safely. Fall back to Small if the inv
    -- tooltip implementation doesn't expose a getter on this build.
    local font = (self.tooltip and self.tooltip.getFont and self.tooltip:getFont()) or UIFont.Small
    local tm = getTextManager()
    local lineH = tm:getFontHeight(font)
    local pad = math.max(4, math.floor(lineH * 0.25))
    local gap = math.max(2, math.floor(lineH * 0.1))

    local lineCount = line2 and 2 or 1
    local origW = self.tooltip:getWidth()
    local maxW  = origW
    local w1 = tm:MeasureStringX(font, line1) + pad * 2
    if w1 > maxW then maxW = w1 end
    if line2 then
        local w2 = tm:MeasureStringX(font, line2) + pad * 2
        if w2 > maxW then maxW = w2 end
    end

    local textH = (lineCount * lineH) + ((lineCount - 1) * gap)
    local appendH = textH + pad * 2
    local curH = self.tooltip:getHeight()

    local br, bg, bb, ba = 0.4, 0.4, 0.4, 1

    -- Pad out the right edge of the existing tooltip so the widened bottom
    -- band doesn't look like a step.
    if maxW > origW then
        self.tooltip:DrawTextureScaledColor(nil, origW - 1, 0, maxW - origW + 1, curH - 2, 0, 0, 0, 0.75)
        self.tooltip:DrawTextureScaledColor(nil, origW - 1, 0, maxW - origW + 1, 1,        br, bg, bb, ba)
        self.tooltip:DrawTextureScaledColor(nil, maxW  - 1, 0, 1,                curH - 2, br, bg, bb, ba)
    end

    -- New band: dark fill + 1px border on left/right/bottom.
    self.tooltip:DrawTextureScaledColor(nil, 0,        curH - 2, maxW, appendH, 0, 0, 0, 0.75)
    self.tooltip:DrawTextureScaledColor(nil, 0,        curH - 2, 1,    appendH, br, bg, bb, ba)
    self.tooltip:DrawTextureScaledColor(nil, maxW - 1, curH - 2, 1,    appendH, br, bg, bb, ba)
    self.tooltip:DrawTextureScaledColor(nil, 0,        curH + appendH - 3, maxW, 1, br, bg, bb, ba)

    local y = curH + pad - 2
    self.tooltip:DrawText(font, line1, 5, y, r1, g1, b1, 1)
    if line2 then
        y = y + lineH + gap
        self.tooltip:DrawText(font, line2, 5, y, r2, g2, b2, 1)
    end

    self.tooltip:setHeight(curH + appendH - 2)
    self.tooltip:setWidth(maxW)
end

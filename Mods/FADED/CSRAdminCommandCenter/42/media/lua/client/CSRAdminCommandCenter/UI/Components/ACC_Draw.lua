require "CSRAdminCommandCenter/ACC_Main"

local ACC = CSRAdminCommandCenter
ACC.Draw = ACC.Draw or {}

local Draw = ACC.Draw

Draw.colors = {
    bg = { r = 0.03, g = 0.03, b = 0.05, a = 0.88 },
    panel = { r = 0.08, g = 0.05, b = 0.13, a = 0.72 },
    border = { r = 0.88, g = 0.18, b = 1.00, a = 0.95 },
    text = { r = 0.90, g = 0.94, b = 0.92, a = 1 },
    muted = { r = 0.68, g = 0.73, b = 0.72, a = 1 },
    good = { r = 0.38, g = 1.00, b = 0.26, a = 1 },
    warn = { r = 0.86, g = 0.64, b = 1.00, a = 1 },
    bad = { r = 1.00, g = 0.34, b = 0.48, a = 1 },
    accent = { r = 0.70, g = 0.28, b = 1.00, a = 1 },
    neon = { r = 0.88, g = 0.18, b = 1.00, a = 1 },
    purple = { r = 0.62, g = 0.10, b = 1.00, a = 1 },
}

Draw.backgroundPath = "media/ui/CSR_ACC_Command_GUI.png"
Draw.backgroundTexture = nil

function Draw.getBackgroundTexture()
    if Draw.backgroundTexture == false then return nil end
    if not Draw.backgroundTexture and getTexture then
        Draw.backgroundTexture = getTexture(Draw.backgroundPath) or false
    end
    if Draw.backgroundTexture == false then return nil end
    return Draw.backgroundTexture
end

function Draw.background(panel, x, y, w, h)
    x = x or 0
    y = y or 0
    w = w or panel.width
    h = h or panel.height
    local tex = Draw.getBackgroundTexture()
    if tex and panel.drawTextureScaled then
        panel:drawTextureScaled(tex, x, y, w, h, 0.74, 1, 1, 1)
    else
        panel:drawRect(x, y, w, h, 0.95, 0.03, 0.03, 0.05)
    end
    panel:drawRect(x, y, w, h, 0.58, 0.01, 0.01, 0.02)
    panel:drawRect(x, y, w, h, 0.18, 0.13, 0.03, 0.26)
end

function Draw.neonFrame(panel, x, y, w, h)
    x = x or 0
    y = y or 0
    w = w or panel.width
    h = h or panel.height
    if w < 8 or h < 8 then return end
    panel:drawRectBorder(x, y, w, h, 0.95, 0.92, 0.18, 1.00)
    panel:drawRectBorder(x + 1, y + 1, w - 2, h - 2, 0.58, 0.46, 0.08, 0.86)
    panel:drawRectBorder(x + 3, y + 3, w - 6, h - 6, 0.88, 0.62, 0.10, 1.00)
    panel:drawRectBorder(x + 4, y + 4, w - 8, h - 8, 0.42, 0.95, 0.46, 1.00)
end

function Draw.glassPanel(panel, x, y, w, h)
    panel:drawRect(x, y, w, h, 0.64, 0.04, 0.03, 0.07)
    panel:drawRectBorder(x, y, w, h, 0.70, 0.30, 1.00, 0.18)
end

function Draw.styleButton(button, active)
    if not button then return end
    button.backgroundColor = { r = 0.04, g = 0.03, b = 0.08, a = 0.82 }
    button.backgroundColorMouseOver = { r = 0.12, g = 0.05, b = 0.18, a = 0.95 }
    button.borderColor = active and { r = 0.30, g = 1.00, b = 0.18, a = 1 }
        or { r = 0.48, g = 0.16, b = 0.92, a = 0.85 }
    button.textColor = { r = 0.90, g = 0.96, b = 0.91, a = 1 }
end

function Draw.styleEntry(entry)
    if not entry then return end
    entry.backgroundColor = { r = 0.02, g = 0.01, b = 0.04, a = 0.82 }
    entry.borderColor = { r = 0.30, g = 1.00, b = 0.18, a = 0.85 }
    entry.textColor = { r = 0.90, g = 0.96, b = 0.91, a = 1 }
    entry.fontColor = entry.textColor
end

function Draw.styleList(list)
    if not list then return end
    list.backgroundColor = { r = 0.02, g = 0.01, b = 0.04, a = 0.58 }
    list.borderColor = { r = 0.30, g = 1.00, b = 0.18, a = 0.65 }
    list.drawBorder = true
end

function Draw.text(panel, text, x, y, color, font)
    color = color or Draw.colors.text
    panel:drawText(tostring(text or ""), x, y, color.r, color.g, color.b, color.a, font or UIFont.Small)
end

function Draw.fitText(text, maxChars)
    local value = tostring(text or "")
    maxChars = tonumber(maxChars) or 0
    if maxChars <= 0 or string.len(value) <= maxChars then return value end
    if maxChars <= 3 then return string.sub(value, 1, maxChars) end
    return string.sub(value, 1, maxChars - 3) .. "..."
end

function Draw.textWrapped(panel, text, x, y, maxChars, maxLines, color, font)
    local value = tostring(text or "")
    local line = ""
    local lines = 0
    maxChars = tonumber(maxChars) or 90
    maxLines = tonumber(maxLines) or 3
    for word in string.gmatch(value, "%S+") do
        if string.len(line) + string.len(word) + 1 > maxChars then
            Draw.text(panel, line, x, y, color or Draw.colors.text, font)
            y = y + 16
            lines = lines + 1
            if lines >= maxLines then return y end
            line = word
        else
            if line == "" then line = word else line = line .. " " .. word end
        end
    end
    if line ~= "" and lines < maxLines then
        Draw.text(panel, line, x, y, color or Draw.colors.text, font)
        y = y + 16
    end
    return y
end

function Draw.labelValue(panel, label, value, x, y, valueColor, labelW, maxValueChars)
    Draw.text(panel, tostring(label or ""), x, y, Draw.colors.muted)
    Draw.text(panel, Draw.fitText(value, maxValueChars or 52), x + (labelW or 170), y, valueColor or Draw.colors.text)
end

function Draw.section(panel, title, x, y, w)
    panel:drawRect(x, y + 24, w or (panel.width - x * 2), 1, 0.82, 0.30, 1.00, 0.18)
    panel:drawRect(x, y + 26, w or (panel.width - x * 2), 1, 0.55, 0.48, 0.16, 0.92)
    Draw.text(panel, title, x, y, Draw.colors.accent, UIFont.Medium)
end

function Draw.boolText(value)
    return value and "Yes" or "No"
end

function Draw.boolColor(value)
    return value and Draw.colors.good or Draw.colors.bad
end

return Draw

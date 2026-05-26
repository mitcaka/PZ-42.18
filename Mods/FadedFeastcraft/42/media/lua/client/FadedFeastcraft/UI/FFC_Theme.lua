FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.Theme = FadedFeastcraft.Theme or {}

local Theme = FadedFeastcraft.Theme

Theme.colors = {
    bg = { r = 0.02, g = 0.025, b = 0.03, a = 0.94 },
    panel = { r = 0.035, g = 0.055, b = 0.065, a = 0.92 },
    panel2 = { r = 0.055, g = 0.075, b = 0.085, a = 0.9 },
    cyan = { r = 0.18, g = 0.82, b = 1.0, a = 1.0 },
    cyanDim = { r = 0.09, g = 0.45, b = 0.6, a = 0.85 },
    text = { r = 0.88, g = 0.96, b = 1.0, a = 1.0 },
    muted = { r = 0.55, g = 0.68, b = 0.74, a = 1.0 },
    good = { r = 0.42, g = 1.0, b = 0.62, a = 1.0 },
    warn = { r = 1.0, g = 0.78, b = 0.24, a = 1.0 },
    bad = { r = 1.0, g = 0.32, b = 0.26, a = 1.0 },
}

function Theme.drawPanel(ui, x, y, w, h, alpha)
    local c = Theme.colors.panel
    ui:drawRect(x, y, w, h, alpha or c.a, c.r, c.g, c.b)
    local b = Theme.colors.cyanDim
    ui:drawRectBorder(x, y, w, h, 0.75, b.r, b.g, b.b)
end

function Theme.drawGlowBorder(ui, x, y, w, h)
    local c = Theme.colors.cyan
    ui:drawRectBorder(x, y, w, h, 0.95, c.r, c.g, c.b)
    ui:drawRectBorder(x - 1, y - 1, w + 2, h + 2, 0.22, c.r, c.g, c.b)
end

return Theme

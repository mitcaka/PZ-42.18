require "ISUI/ISPanel"
require "FadedFeastcraft/UI/FFC_Theme"

FadedFeastcraft = FadedFeastcraft or {}

FFC_CookingStatusPanel = ISPanel:derive("FFC_CookingStatusPanel")

local Theme = FadedFeastcraft.Theme

function FFC_CookingStatusPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.title = "FFC Cooking"
    o.status = "Queued..."
    o.detail = ""
    o.moveWithMouse = true
    return o
end

function FFC_CookingStatusPanel:setStatus(status, detail)
    self.status = tostring(status or self.status or "Queued...")
    self.detail = tostring(detail or self.detail or "")
end

function FFC_CookingStatusPanel:prerender()
    ISPanel.prerender(self)
    Theme.drawPanel(self, 0, 0, self.width, self.height, 0.86)
end

function FFC_CookingStatusPanel:render()
    ISPanel.render(self)
    local cyan = Theme.colors.cyan
    local text = Theme.colors.text
    local muted = Theme.colors.muted
    self:drawText(self.title, 12, 8, cyan.r, cyan.g, cyan.b, 1, UIFont.Small)
    self:drawText(self.status, 12, 29, text.r, text.g, text.b, 1, UIFont.Small)
    if self.detail and self.detail ~= "" then
        self:drawText(self.detail, 12, 50, muted.r, muted.g, muted.b, 1, UIFont.Small)
    end
end

local function statusPosition()
    local w, h = 300, 76
    local x, y = 24, 88
    if getCore then
        x = math.max(16, getCore():getScreenWidth() - w - 28)
        y = 88
    end
    return x, y, w, h
end

function FadedFeastcraft.ShowCookingStatus(context)
    local panel = FadedFeastcraft.CookingStatusPanel
    if not panel then
        local x, y, w, h = statusPosition()
        panel = FFC_CookingStatusPanel:new(x, y, w, h)
        panel:initialise()
        panel:addToUIManager()
        FadedFeastcraft.CookingStatusPanel = panel
    else
        panel:setVisible(true)
        panel:addToUIManager()
    end
    panel:setStatus("Queued...", tostring(context and context.stationName or "Heat Source"))
    if panel.bringToTop then panel:bringToTop() end
    return panel
end

function FadedFeastcraft.UpdateCookingStatus(status, detail)
    local panel = FadedFeastcraft.CookingStatusPanel
    if panel then
        panel:setStatus(status, detail)
        panel:setVisible(true)
    end
end

function FadedFeastcraft.HideCookingStatus()
    local panel = FadedFeastcraft.CookingStatusPanel
    if panel then
        panel:setVisible(false)
        panel:removeFromUIManager()
        FadedFeastcraft.CookingStatusPanel = nil
    end
end

return FFC_CookingStatusPanel

require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISTradingUI"
require "ISUI/ISTradingUIHistorial"
require "ISUI/ISModalDialog"
require "ISUI/ISToolTip"
require "CSR_FeatureFlags"
require "CSR_Theme"

CSR_PlayerTrading = CSR_PlayerTrading or {}

local GOLD = { a = 1.0, r = 0.95, g = 0.72, b = 0.28 }
local GOLD_DIM = { a = 0.9, r = 0.55, g = 0.42, b = 0.18 }
local BG = { a = 0.94, r = 0.055, g = 0.060, b = 0.070 }
local HEADER = { a = 0.98, r = 0.11, g = 0.10, b = 0.08 }
local ROW = { a = 0.22, r = 0.33, g = 0.27, b = 0.14 }
local ROW_ALT = { a = 0.16, r = 0.24, g = 0.22, b = 0.16 }
local BG_TEXTURE_PATH = "media/ui/CSR_PlayerTradeBg.png"
local bgTexture = nil

local function replaceTokens(text, ...)
    local out = tostring(text or "")
    for i = 1, select("#", ...) do
        out = string.gsub(out, "%%" .. tostring(i), tostring(select(i, ...)))
    end
    return out
end

local function txt(key, fallback, ...)
    local s = getText and getText(key, ...) or nil
    if not s or s == "" or tostring(s) == key then
        return replaceTokens(fallback, ...)
    end
    return s
end

local function isMP()
    return isClient and isClient()
end

function CSR_PlayerTrading.isEnabled()
    return isMP()
        and CSR_FeatureFlags
        and CSR_FeatureFlags.isPlayerTradingEnabled
        and CSR_FeatureFlags.isPlayerTradingEnabled()
end

local function displayName(player)
    if not player then return "Player" end
    if player.getDisguisedDisplayName then
        local name = player:getDisguisedDisplayName()
        if name and name ~= "" then return tostring(name) end
    end
    if player.getDisplayName then
        local name = player:getDisplayName()
        if name and name ~= "" then return tostring(name) end
    end
    if player.getUsername then
        local name = player:getUsername()
        if name and name ~= "" then return tostring(name) end
    end
    return "Player"
end

local function tooltip(option, description)
    if not option then return end
    local tip = ISToolTip:new()
    tip:initialise()
    tip:setVisible(false)
    tip.description = description
    option.toolTip = tip
end

local function findTradeOption(context, target)
    if not context then return nil end
    if target and context.getOptionFromName and target.getDisplayName then
        local option = context:getOptionFromName(getText("ContextMenu_Trade", target:getDisplayName()))
        if option then return option end
    end
    local options = context.options
    if type(options) ~= "table" then return nil end
    for _, option in ipairs(options) do
        if option and option.onSelect == ISWorldObjectContextMenu.onTrade then
            return option
        end
    end
    return nil
end

local function say(player, text)
    if player and player.Say then
        player:Say(text)
    end
end

local function styleButton(button, accentName, active)
    if not button then return end
    CSR_Theme.applyButtonStyle(button, accentName or "tradeGold", active ~= false)
end

local function styleList(list)
    if not list then return end
    list.backgroundColor = { a = 0.45, r = 0.04, g = 0.045, b = 0.052 }
    list.borderColor = { a = 0.92, r = GOLD_DIM.r, g = GOLD_DIM.g, b = GOLD_DIM.b }
end

local function getBgTexture()
    if bgTexture == nil then
        bgTexture = getTexture and getTexture(BG_TEXTURE_PATH) or false
    end
    return bgTexture or nil
end

local function styleTradeWindow(ui)
    if not ui then return end
    ui.backgroundColor = { a = BG.a, r = BG.r, g = BG.g, b = BG.b }
    ui.borderColor = { a = 1.0, r = GOLD.r, g = GOLD.g, b = GOLD.b }
    ui.listHeaderColor = { a = 0.35, r = GOLD.r, g = GOLD.g, b = GOLD.b }
    styleList(ui.yourOfferDatas)
    styleList(ui.hisOfferDatas)
    styleButton(ui.infoBtn, "accentSlate", true)
    styleButton(ui.no, "accentRed", true)
    styleButton(ui.remove, "tradeGold", ui.remove and ui.remove.enable)
    styleButton(ui.historic, "accentSlate", true)
    styleButton(ui.acceptDeal, "tradeGold", ui.acceptDeal and ui.acceptDeal.enable)
    if ui.sealOffer then
        ui.sealOffer.borderColor = { a = 1.0, r = GOLD.r, g = GOLD.g, b = GOLD.b }
    end
end

local function drawCentered(panel, text, y, font, color)
    color = color or GOLD
    local width = getTextManager():MeasureStringX(font, text)
    panel:drawText(text, math.floor((panel.width - width) / 2), y, color.r, color.g, color.b, color.a or 1, font)
end

local function drawTradeBackdrop(panel, top)
    local tex = getBgTexture()
    if not tex then return end
    local maxW = panel.width - 24
    local maxH = panel.height - top - 54
    local tw = tex.getWidth and tex:getWidth() or maxW
    local th = tex.getHeight and tex:getHeight() or maxH
    if not tw or not th or tw <= 0 or th <= 0 then return end
    local scale = math.min(maxW / tw, maxH / th)
    if scale > 1 then scale = 1 end
    local drawW = math.floor(tw * scale)
    local drawH = math.floor(th * scale)
    local drawX = math.floor((panel.width - drawW) / 2)
    local drawY = top + math.floor((maxH - drawH) / 2)
    panel:drawTextureScaled(tex, drawX, drawY, drawW, drawH, 0.12, GOLD.r, GOLD.g, GOLD.b)
end

local function patchTradingUI()
    if not ISTradingUI or ISTradingUI.__csr_player_trading_patched then return end
    ISTradingUI.__csr_player_trading_patched = true

    local originalNew = ISTradingUI.new
    ISTradingUI.new = function(self, x, y, width, height, player, otherPlayer)
        local ui = originalNew(self, x, y, width, height, player, otherPlayer)
        ui.csrPlayerTrade = true
        styleTradeWindow(ui)
        return ui
    end

    local originalInitialise = ISTradingUI.initialise
    ISTradingUI.initialise = function(self)
        originalInitialise(self)
        styleTradeWindow(self)
    end

    ISTradingUI.prerender = function(self)
        styleTradeWindow(self)
        self:drawRect(0, 0, self.width, self.height, BG.a, BG.r, BG.g, BG.b)
        drawTradeBackdrop(self, 52)
        self:drawRect(0, 0, self.width, 48, HEADER.a, HEADER.r, HEADER.g, HEADER.b)
        self:drawRect(0, 47, self.width, 1, 0.95, GOLD.r, GOLD.g, GOLD.b)
        self:drawRectBorder(0, 0, self.width, self.height, 1.0, GOLD.r, GOLD.g, GOLD.b)
        self:drawRectBorder(2, 2, self.width - 4, self.height - 4, 0.65, GOLD_DIM.r, GOLD_DIM.g, GOLD_DIM.b)

        drawCentered(self, txt("IGUI_CSR_PlayerTrading_Title", "Player Trading"), 14, UIFont.Medium, GOLD)

        local leftTitle = getText("IGUI_TradingUI_YourOffer")
        local rightTitle = getText("IGUI_TradingUI_HisOffer", displayName(self.otherPlayer))
        self:drawText(leftTitle, self.yourOfferDatas.x, self.yourOfferDatas.y - 32, 0.94, 0.96, 0.98, 1, UIFont.Small)
        self:drawText(rightTitle, self.hisOfferDatas.x, self.hisOfferDatas.y - 32, 0.94, 0.96, 0.98, 1, UIFont.Small)

        local yourItems = getText("IGUI_TradingUI_Items", #self.yourOfferDatas.items, ISTradingUI.MaxItems)
        local theirItems = getText("IGUI_TradingUI_Items", #self.hisOfferDatas.items, ISTradingUI.MaxItems)
        self:drawText(yourItems, self.yourOfferDatas.x, self.yourOfferDatas.y - 18, GOLD.r, GOLD.g, GOLD.b, 0.95, UIFont.Small)
        self:drawText(theirItems, self.hisOfferDatas.x, self.hisOfferDatas.y - 18, GOLD.r, GOLD.g, GOLD.b, 0.95, UIFont.Small)

        if self.otherSealedOffer then
            self:drawText(getText("IGUI_TradingUI_OtherPlayerSealedOffer", displayName(self.otherPlayer)),
                self.sealOffer.x, self.sealOffer.y + self.sealOffer.height + 5,
                0.38, 0.78, 0.58, 1, UIFont.Small)
        end
    end

    ISTradingUI.drawOffer = function(self, y, item, alt)
        local bg = alt and ROW_ALT or ROW
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, bg.a, bg.r, bg.g, bg.b)
        self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, 0.78, GOLD_DIM.r, GOLD_DIM.g, GOLD_DIM.b)

        if self.selected == item.index and not self.parent.sealOffer.selected[1] then
            if self == self.parent.yourOfferDatas then
                self:drawRect(1, y + 1, self:getWidth() - 2, self.itemheight - 3, 0.36, GOLD.r, GOLD.g, GOLD.b)
                self.parent.selectedItem = item
            end
        end

        local invItem = item and item.item or nil
        local tex = invItem and invItem.getTex and invItem:getTex() or nil
        if tex then
            self:drawTextureScaledAspect(tex, 5, y + 2, 18, 18, 1,
                invItem:getR(), invItem:getG(), invItem:getB())
        end
        self:drawText(item.text or "", 28, y + 3, 0.94, 0.96, 0.98, 0.95, self.font)
        return y + self.itemheight
    end

    local originalRender = ISTradingUI.render
    ISTradingUI.render = function(self)
        originalRender(self)
        styleButton(self.remove, "tradeGold", self.remove and self.remove.enable)
        styleButton(self.acceptDeal, "tradeGold", self.acceptDeal and self.acceptDeal.enable)
        self:drawRectBorder(0, 0, self.width, self.height, 1.0, GOLD.r, GOLD.g, GOLD.b)
    end

    local originalOnClick = ISTradingUI.onClick
    ISTradingUI.onClick = function(self, button)
        originalOnClick(self, button)
        if self.infoRichText then
            self.infoRichText.backgroundColor = { a = 0.98, r = BG.r, g = BG.g, b = BG.b }
            self.infoRichText.borderColor = { a = 1.0, r = GOLD.r, g = GOLD.g, b = GOLD.b }
        end
        if self.historicalUI then
            self.historicalUI.backgroundColor = { a = BG.a, r = BG.r, g = BG.g, b = BG.b }
            self.historicalUI.borderColor = { a = 1.0, r = GOLD.r, g = GOLD.g, b = GOLD.b }
            styleButton(self.historicalUI.no, "tradeGold", true)
            styleList(self.historicalUI.list)
        end
    end

    local originalReceive = ISTradingUI.ReceiveTradeRequest
    if Events and Events.RequestTrade and originalReceive then
        Events.RequestTrade.Remove(originalReceive)
    end

    ISTradingUI.ReceiveTradeRequest = function(requester)
        if not CSR_PlayerTrading.isEnabled() then
            if acceptTrading and getPlayer then
                acceptTrading(getPlayer(), requester, false)
            end
            say(getPlayer and getPlayer() or nil, txt("IGUI_CSR_PlayerTrading_Disabled", "Player trading is disabled."))
            return
        end

        local message = txt("IGUI_CSR_PlayerTrading_Request", "%1 wants to trade. Accept?", displayName(requester))
        local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - 190,
            getCore():getScreenHeight() / 2 - 75, 380, 150, message, true, nil, ISTradingUI.onAnswerTradeRequest)
        modal:initialise()
        modal:addToUIManager()
        modal.requester = requester
        modal.moveWithMouse = true
        modal.backgroundColor = { a = 0.96, r = BG.r, g = BG.g, b = BG.b }
        modal.borderColor = { a = 1.0, r = GOLD.r, g = GOLD.g, b = GOLD.b }
        ISTradingUI.tradeQuestionUI = modal
    end

    if Events and Events.RequestTrade then
        Events.RequestTrade.Add(ISTradingUI.ReceiveTradeRequest)
    end
end

local function patchHistoricalUI()
    if not ISTradingUIHistorical or ISTradingUIHistorical.__csr_player_trading_patched then return end
    ISTradingUIHistorical.__csr_player_trading_patched = true

    local originalNew = ISTradingUIHistorical.new
    ISTradingUIHistorical.new = function(self, x, y, width, height, list, otherPlayer)
        local ui = originalNew(self, x, y, width, height, list, otherPlayer)
        ui.backgroundColor = { a = BG.a, r = BG.r, g = BG.g, b = BG.b }
        ui.borderColor = { a = 1.0, r = GOLD.r, g = GOLD.g, b = GOLD.b }
        return ui
    end

    local originalInitialise = ISTradingUIHistorical.initialise
    ISTradingUIHistorical.initialise = function(self)
        originalInitialise(self)
        styleButton(self.no, "tradeGold", true)
        styleList(self.list)
    end

    ISTradingUIHistorical.prerender = function(self)
        self:drawRect(0, 0, self.width, self.height, BG.a, BG.r, BG.g, BG.b)
        self:drawRect(0, 0, self.width, 34, HEADER.a, HEADER.r, HEADER.g, HEADER.b)
        self:drawRectBorder(0, 0, self.width, self.height, 1.0, GOLD.r, GOLD.g, GOLD.b)
        drawCentered(self, getText("IGUI_ISTradingUIHistorical_Title", displayName(self.otherPlayer)), 10, UIFont.Medium, GOLD)
    end

    ISTradingUIHistorical.drawList = function(self, y, item, alt)
        local bg = alt and ROW_ALT or ROW
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, bg.a, bg.r, bg.g, bg.b)
        self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, 0.7, GOLD_DIM.r, GOLD_DIM.g, GOLD_DIM.b)
        local r, g, b = 0.94, 0.96, 0.98
        if item.item.add then
            r, g, b = 0.38, 0.78, 0.58
        elseif item.item.remove then
            r, g, b = 0.86, 0.36, 0.36
        end
        self:drawText(item.item.message or "", 10, y + 3, r, g, b, 0.95, self.font)
        return y + self.itemheight
    end
end

local function patchWorldTrade()
    if not ISWorldObjectContextMenu or ISWorldObjectContextMenu.__csr_player_trading_patched then return end
    ISWorldObjectContextMenu.__csr_player_trading_patched = true

    local originalOnTrade = ISWorldObjectContextMenu.onTrade
    ISWorldObjectContextMenu.onTrade = function(worldobjects, player, otherPlayer)
        if not isMP() then
            say(player, txt("IGUI_CSR_PlayerTrading_MPOnly", "Player trading is multiplayer only."))
            return
        end
        if not CSR_PlayerTrading.isEnabled() then
            say(player, txt("IGUI_CSR_PlayerTrading_Disabled", "Player trading is disabled."))
            return
        end
        return originalOnTrade(worldobjects, player, otherPlayer)
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if test or not context then return end
    local playerObj = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
    local target = clickedPlayer
    if not playerObj or not target or target == playerObj then return end

    local option = findTradeOption(context, target)
    local label = txt("ContextMenu_CSR_PlayerTrading", "Player Trade: %1", displayName(target))

    if option then
        option.name = label
        if not isMP() then
            option.name = txt("ContextMenu_CSR_PlayerTradingMPOnly", "Player Trading (MP only)")
            option.notAvailable = true
            option.onSelect = nil
            tooltip(option, txt("IGUI_CSR_PlayerTrading_MPOnly", "Player trading is multiplayer only."))
        elseif not CSR_PlayerTrading.isEnabled() then
            option.name = txt("ContextMenu_CSR_PlayerTradingDisabled", "Player Trading Disabled")
            option.notAvailable = true
            option.onSelect = nil
            tooltip(option, txt("IGUI_CSR_PlayerTrading_Disabled", "Player trading is disabled."))
        else
            tooltip(option, txt("Tooltip_CSR_PlayerTrading", "Open a secure CSR-themed trade with %1.", displayName(target)))
        end
    elseif CSR_PlayerTrading.isEnabled() then
        option = context:addOption(label, worldobjects, ISWorldObjectContextMenu.onTrade, playerObj, target)
        tooltip(option, txt("Tooltip_CSR_PlayerTrading", "Open a secure CSR-themed trade with %1.", displayName(target)))
    end
end

patchTradingUI()
patchHistoricalUI()
patchWorldTrade()

if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
end

return CSR_PlayerTrading

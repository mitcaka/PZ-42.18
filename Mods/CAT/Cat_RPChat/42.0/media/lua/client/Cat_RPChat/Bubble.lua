local Config = require("Cat_RPChat/Config")
local Utils = require("Cat_RPChat/Utils")

local Bubble = {}
Bubble.active = {}

local function worldToScreen(x, y, z)
    local sx = IsoUtils.XToScreenExact(x, y, z, 0)
    local sy = IsoUtils.YToScreenExact(x, y, z, 0)
    local zoom = getCore():getZoom(getPlayer():getPlayerNum())
    return sx / zoom, sy / zoom
end

local BubbleUI = ISRichTextPanel:derive("Cat_RPChat_Bubble")

function BubbleUI:initialise()
    ISRichTextPanel.initialise(self)
    self.texturesLoaded = false
    self.startTime = Calendar.getInstance():getTimeInMillis()
    self.alpha = self.opacity / 100
    self.fadingProgression = 1
    self:setAlwaysOnTop(true)
    self:setWantKeyEvents(false)
end

function BubbleUI:loadTextures()
    self.texTopLeft = getTexture("media/ui/cat_rpchat/bubble/bubble-top-left.png")
    self.texTop = getTexture("media/ui/cat_rpchat/bubble/bubble-top.png")
    self.texTopRight = getTexture("media/ui/cat_rpchat/bubble/bubble-top-right.png")
    self.texLeft = getTexture("media/ui/cat_rpchat/bubble/bubble-left.png")
    self.texCenter = getTexture("media/ui/cat_rpchat/bubble/bubble-center.png")
    self.texRight = getTexture("media/ui/cat_rpchat/bubble/bubble-right.png")
    self.texBotLeft = getTexture("media/ui/cat_rpchat/bubble/bubble-bot-left.png")
    self.texBot = getTexture("media/ui/cat_rpchat/bubble/bubble-bot.png")
    self.texBotRight = getTexture("media/ui/cat_rpchat/bubble/bubble-bot-right.png")
    self.texArrow = getTexture("media/ui/cat_rpchat/bubble/bubble-arrow.png")

    self.playerModel = UI3DModel:new()
    self.playerModel:setWidth(40)
    self.playerModel:setHeight(80)
    self.playerModel:setCharacter(self.player)
    self.playerModel:setState("idle")
    self.playerModel:setDirection(IsoDirections.SE)
    self.playerModel:setIsometric(false)
    self.playerModel:setAnimate(false)
    self.playerModel:setZoom(17)
    self.playerModel:setYOffset(-0.92)
end

function BubbleUI:prerender()
    -- ISRichTextPanel handles text prerender; we do background in render
end

function BubbleUI:render()
    if self.dead then return end
    if not self.texturesLoaded then
        self:loadTextures()
        self.texturesLoaded = true
    end

    local time = Calendar.getInstance():getTimeInMillis()
    local elapsed = time - self.startTime

    if self.timer - elapsed > 1000 then
        self.alpha = self.opacity / 100
    elseif self.timer - elapsed > 0 then
        local fadingTime = elapsed - (self.timer - 1000)
        self.fadingProgression = (1000 - fadingTime) / 1000
        self.alpha = self.fadingProgression * (self.opacity / 100)
    else
        self.dead = true
        self:removeFromUIManager()
        return
    end

    -- Position above player
    local px, py = worldToScreen(self.player:getX(), self.player:getY(), self.player:getZ())
    local bodyHeight = 129 / (getCore():getZoom(getPlayer():getPlayerNum()))
    local bx = px - self.width / 2
    local by = py - bodyHeight - 21 - self.height

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    bx = math.max(0, math.min(bx, screenW - self.width))
    by = math.max(0, math.min(by, screenH - self.height))

    self:setX(bx)
    self:setY(by)

    local leftW = 10
    local rightW = 10
    local topH = 10
    local botH = 10
    local centerW = self.width - leftW - rightW
    local centerH = self.height - topH - botH
    local centerX = leftW
    local rightX = centerX + centerW
    local centerY = topH
    local botY = centerY + centerH

    self:drawTextureScaled(self.texTopLeft, 0, 0, leftW, topH, self.alpha)
    self:drawTextureScaled(self.texTop, centerX, 0, centerW, topH, self.alpha)
    self:drawTextureScaled(self.texTopRight, rightX, 0, rightW, topH, self.alpha)
    self:drawTextureScaled(self.texLeft, 0, centerY, leftW, centerH, self.alpha)
    self:drawTextureScaled(self.texCenter, centerX, centerY, centerW, centerH, self.alpha)
    self:drawTextureScaled(self.texRight, rightX, centerY, rightW, centerH, self.alpha)
    self:drawTextureScaled(self.texBotLeft, 0, botY, leftW, botH, self.alpha)
    self:drawTextureScaled(self.texBot, centerX, botY, centerW, botH, self.alpha)
    self:drawTextureScaled(self.texBotRight, rightX, botY, rightW, botH, self.alpha)

    if self:getX() > 0 and self:getY() > 0
        and self:getX() + self:getWidth() < screenW
        and self:getY() + self:getHeight() < screenH then
        self:drawTextureScaled(self.texArrow, centerX + centerW / 2 + 5, botY + 4 * botH / 5, 7, 9, self.alpha)
    end

    -- Draw wrapped text via ISRichTextPanel
    ISRichTextPanel.render(self)

    -- 3D Model
    if self.playerModel then
        local modelX = self:getX() + 2
        local modelY = self:getY() + self:getHeight() - 80 - 2
        if modelX < 0 then modelX = 2 end
        if modelY < 0 then modelY = 0 end
        self.playerModel:setX(modelX)
        self.playerModel:setY(modelY)
        self.playerModel:render()
    end
end

function BubbleUI:new(player, text, timer, opacity)
    local o = ISRichTextPanel:new(0, 0, 200, 0)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.text = text
    o.timer = timer
    o.opacity = opacity
    o.dead = false
    o.texturesLoaded = false
    o.defaultFont = UIFont.Medium
    o.font = UIFont.Medium
    o.background = false
    o.autosetheight = false
    o.marginLeft = 50
    o.marginRight = 10
    o.marginTop = 8
    o.marginBottom = 8
    o:initialise()
    o:addToUIManager()
    return o
end

function Bubble.create(player, text, channel, pitch)
    if not player or not text or #text == 0 then return end

    local username = player:getUsername()
    if Bubble.active[username] then
        Bubble.active[username]:removeFromUIManager()
        Bubble.active[username] = nil
    end
    if Cat_RPChat_TypingDots and Cat_RPChat_TypingDots[username] then
        Cat_RPChat_TypingDots[username] = nil
    end

    local tm = getTextManager()
    local maxTextWidth = 200
    local modelWidth = 45
    local wrappedText = Utils.wrapBubbleText(text, UIFont.Medium, maxTextWidth)
    local measureText = wrappedText:gsub("<RGB:[^>]+>", ""):gsub("<LINE>", "")
    local textW = tm:MeasureStringX(UIFont.Medium, measureText)
    local width = math.min(textW + modelWidth + 30, maxTextWidth + modelWidth + 30)

    local ui = BubbleUI:new(player, wrappedText, Config.BUBBLE_TIMER, Config.BUBBLE_OPACITY)
    ui:setWidth(width)
    ui:paginate()
    ui:setHeight(math.max(40, ui:getScrollHeight() + 20))

    Bubble.active[username] = ui
end

local function onTickCleanup()
    for username, bubble in pairs(Bubble.active) do
        if bubble.dead or not bubble.player or bubble.player:isDead() then
            if not bubble.dead then
                bubble:removeFromUIManager()
            end
            Bubble.active[username] = nil
        end
    end
end

Events.OnTick.Add(onTickCleanup)

return Bubble

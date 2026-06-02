local TypingDots = ISUIElement:derive('Cat_RPChat_TypingDots');

function TypingDots:render()
    local typingDots1 = getTexture('media/ui/cat_rpchat/typing-dots/typing-dots-1.png')
    local typingDots2 = getTexture('media/ui/cat_rpchat/typing-dots/typing-dots-2.png')
    local typingDots3 = getTexture('media/ui/cat_rpchat/typing-dots/typing-dots-3.png')

    local time = Calendar.getInstance():getTimeInMillis()
    if time - self.startingTime > self.timer then
        self.dead = true
        return
    end
    local elapsedTime = time - self.lastStepTime
    if elapsedTime >= self.stepTime then
        self.lastStepTime = time
        self.step = (self.step) % 3 + 1
    end
    local texture
    if self.step == 1 then
        texture = typingDots1
    elseif self.step == 2 then
        texture = typingDots2
    else
        texture = typingDots3
    end

    if not self.player or self.player:isDead() then
        self.dead = true
        return
    end

    local sx = IsoUtils.XToScreenExact(self.player:getX(), self.player:getY(), self.player:getZ(), 0)
    local sy = IsoUtils.YToScreenExact(self.player:getX(), self.player:getY(), self.player:getZ(), 0)
    local zoom = getCore():getZoom(getPlayer():getPlayerNum())
    local x = sx / zoom - 10
    local bodyHeight = 129 / zoom
    local y = sy / zoom - bodyHeight - 21 - 6

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    x = math.max(0, math.min(x, screenW - 20))
    y = math.max(0, math.min(y, screenH - 6))

    self:setX(x)
    self:setY(y)
    self:drawTexture(texture, 0, 0, 1)
end

function TypingDots:refresh()
    self.startingTime = Calendar.getInstance():getTimeInMillis()
end

function TypingDots:new(player, timer)
    TypingDots.__index = self
    local sx = IsoUtils.XToScreenExact(player:getX(), player:getY(), player:getZ(), 0)
    local sy = IsoUtils.YToScreenExact(player:getX(), player:getY(), player:getZ(), 0)
    local zoom = getCore():getZoom(getPlayer():getPlayerNum())
    local x = sx / zoom - 10
    local bodyHeight = 129 / zoom
    local y = sy / zoom - bodyHeight - 21 - 6
    if x == nil then
        x, y = 0, 0
    end
    setmetatable(TypingDots, { __index = ISUIElement })
    local o = ISUIElement:new(x, y, 20, 6)
    setmetatable(o, TypingDots)
    local time = Calendar.getInstance():getTimeInMillis()
    o.player = player
    o.startingTime = time
    o.lastStepTime = time
    o.stepTime = 250
    o.step = 1
    o.timer = timer * 1000
    o.dead = false
    o:instantiate()
    print("Cat_RPChat: TypingDots created for " .. player:getUsername())
    return o
end

Cat_RPChat_TypingDots = Cat_RPChat_TypingDots or {}

return TypingDots

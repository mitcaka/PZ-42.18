-- =============================================================================
-- Cat Shop System — Draggable "Browse Shop" button (bypasses safehouse blocks)
-- =============================================================================
if isServer() then return end

require "ISUI/ISButton"

Cat_ShopSystem = Cat_ShopSystem or {}

-- ---------------------------------------------------------------------------
-- Draggable button class
-- ---------------------------------------------------------------------------
local DraggableButton = ISButton:derive("Cat_ShopDraggableButton")

function DraggableButton:onMouseDown(x, y)
    self.dragging = true
    self.dragStartX = self:getX()
    self.dragStartY = self:getY()
    return ISButton.onMouseDown(self, x, y)
end

function DraggableButton:onMouseMove(dx, dy)
    if self.dragging then
        local core = getCore()
        local screenW = core and core:getScreenWidth() or 1920
        local screenH = core and core:getScreenHeight() or 1080
        local newX = math.max(0, math.min(screenW - self.width, self:getX() + dx))
        local newY = math.max(0, math.min(screenH - self.height, self:getY() + dy))
        self:setX(newX)
        self:setY(newY)
    end
end

function DraggableButton:onMouseMoveOutside(dx, dy)
    if self.dragging then
        self:onMouseMove(dx, dy)
    end
end

function DraggableButton:onMouseUp(x, y)
    local wasDrag = false
    if self.dragging then
        self.dragging = false
        local moved = math.abs(self:getX() - self.dragStartX) + math.abs(self:getY() - self.dragStartY)
        wasDrag = moved > 3
        if wasDrag then
            -- Save position to file (client modData doesn't persist across MP logins)
            local writer = getFileWriter("lua/Cat_ShopButtonPos.txt", true, false)
            if writer then
                writer:write(tostring(self:getX()) .. "\n")
                writer:write(tostring(self:getY()) .. "\n")
                writer:close()
            end
        end
    end
    ISButton.onMouseUp(self, x, y)
    if not wasDrag then
        if self._onClick then
            self:_onClick()
        end
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Scan for nearest claimed shop register
-- ---------------------------------------------------------------------------
function Cat_ShopSystem.FindNearestShop(maxDist)
    local player = getSpecificPlayer(0)
    if not player then return nil end

    local psq = player:getCurrentSquare()
    if not psq then return nil end

    local px, py, pz = psq:getX(), psq:getY(), psq:getZ()
    local cell = getCell()
    local bestDist = maxDist or 4
    local best = nil

    for dx = -math.ceil(bestDist), math.ceil(bestDist) do
        for dy = -math.ceil(bestDist), math.ceil(bestDist) do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq then
                for i = 0, sq:getObjects():size() - 1 do
                    local obj = sq:getObjects():get(i)
                    if obj then
                        local modData = obj:getModData()
                        if modData and modData.Cat_ShopId then
                            local dist = psq:DistTo(sq)
                            if dist < bestDist then
                                bestDist = dist
                                best = {
                                    x = sq:getX(),
                                    y = sq:getY(),
                                    z = sq:getZ(),
                                    shopId = modData.Cat_ShopId,
                                    owner = modData.Cat_ShopOwner or "Unknown",
                                    isBuyer = modData.Cat_IsBuyerRegister or modData.Cat_IsBuyer,
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    return best
end

-- ---------------------------------------------------------------------------
-- Button click handler
-- ---------------------------------------------------------------------------
local function onBrowseShopClick()
    local player = getSpecificPlayer(0)
    local shop = Cat_ShopSystem.FindNearestShop(4)
    if shop then
        require "Cat_ShopSystem_00_UI"
        if shop.isBuyer then
            Cat_ShopSystem.OpenSellerUI(shop.x, shop.y, shop.z, shop.shopId)
        else
            Cat_ShopSystem.OpenBuyerUI(shop.x, shop.y, shop.z, shop.owner, shop.shopId)
        end
        sendClientCommand("Cat_ShopSystem", "requestStock", { x = shop.x, y = shop.y, z = shop.z, shopId = shop.shopId })
    else
        if player and player.setHaloNote then
            player:setHaloNote("No shop register nearby.", 255, 100, 100, 1000)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Create / manage the button
-- ---------------------------------------------------------------------------
local function loadSavedPos()
    local reader = getFileReader("lua/Cat_ShopButtonPos.txt", false)
    if reader then
        local x = tonumber(reader:readLine())
        local y = tonumber(reader:readLine())
        reader:close()
        if x and y then
            return x, y
        end
    end
    return nil, nil
end

local function ensureBrowseButton()
    if Cat_ShopSystem.browseBtn then
        return Cat_ShopSystem.browseBtn
    end

    local core = getCore()
    local screenW = core and core:getScreenWidth() or 1920
    local screenH = core and core:getScreenHeight() or 1080
    local w, h = 110, 30

    local savedX, savedY = loadSavedPos()
    local x = savedX or 20
    local y = savedY or (screenH - 180)

    -- Clamp to screen bounds
    x = math.max(0, math.min(screenW - w, x))
    y = math.max(0, math.min(screenH - h, y))

    local btn = DraggableButton:new(x, y, w, h, "Browse Shop", nil, nil)
    btn:initialise()
    btn:instantiate()
    btn.anchorLeft = true
    btn.anchorTop = true
    btn.backgroundColor = { r = 0.15, g = 0.35, b = 0.15, a = 0.95 }
    btn.backgroundColorMouseOver = { r = 0.22, g = 0.48, b = 0.22, a = 1 }
    btn.borderColor = { r = 0.40, g = 0.80, b = 0.40, a = 1 }
    btn:setVisible(true)
    btn._onClick = onBrowseShopClick
    btn.dragging = false
    btn.dragStartX = 0
    btn.dragStartY = 0

    btn:addToUIManager()
    Cat_ShopSystem.browseBtn = btn

    print("[Cat_ShopSystem] Browse button created at " .. x .. "," .. y)
    return btn
end

-- ---------------------------------------------------------------------------
-- Init hooks
-- ---------------------------------------------------------------------------
local function onGameStart()
    ensureBrowseButton()
end

local function onCreatePlayer(playerIndex)
    if playerIndex ~= 0 then return end
    ensureBrowseButton()
end

Events.OnGameStart.Add(onGameStart)
Events.OnCreatePlayer.Add(onCreatePlayer)

print("[Cat_ShopSystem Client] Browse toolbar loaded.")

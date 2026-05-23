
require "CSR_FeatureFlags"
require "CSR_PlayerPrefs"
require "CSR_Theme"
require "CSR_Utils"
require "CSR_Standpipe"
require "CSR_Guide"
require "CSR_NearbyDensityHUD"
require "CSR_Scale"

local HUD_TOGGLE_DEFAULT_KEY    = Keyboard and Keyboard.KEY_DIVIDE  or 181
local DW_TOGGLE_DEFAULT_KEY     = Keyboard and Keyboard.KEY_NUMPAD8 or 72
local LEDGER_TOGGLE_DEFAULT_KEY = Keyboard and Keyboard.KEY_NUMPAD4 or 75
local DENSITY_TOGGLE_DEFAULT_KEY = Keyboard and Keyboard.KEY_NUMPAD0 or 82
local hudOptions     = nil
local hudKeyBind     = nil
local dwKeyBind      = nil
local ledgerKeyBind  = nil
local densityKeyBind = nil
if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.create then
    hudOptions = PZAPI.ModOptions:create("CommonSenseRebornUtilityHud", "Common Sense Reborn - Utility HUD")
    if hudOptions and hudOptions.addKeyBind then
        hudKeyBind     = hudOptions:addKeyBind("utilityHudToggle",  "Toggle Utility HUD",         HUD_TOGGLE_DEFAULT_KEY)
        dwKeyBind      = hudOptions:addKeyBind("dualWieldToggle",   "Toggle Dual Wield",          DW_TOGGLE_DEFAULT_KEY)
        ledgerKeyBind  = hudOptions:addKeyBind("ledgerToggle",      "Toggle Survivor's Ledger",   LEDGER_TOGGLE_DEFAULT_KEY)
        densityKeyBind = hudOptions:addKeyBind("densityHudToggle",  "Toggle Nearby Density HUD",  DENSITY_TOGGLE_DEFAULT_KEY)
    end
end

local function getHudBoundKey()
    if hudKeyBind and hudKeyBind.getValue then
        return hudKeyBind:getValue()
    end
    return HUD_TOGGLE_DEFAULT_KEY
end

local function getDwBoundKey()
    if dwKeyBind and dwKeyBind.getValue then
        return dwKeyBind:getValue()
    end
    return DW_TOGGLE_DEFAULT_KEY
end

local function getLedgerBoundKey()
    if ledgerKeyBind and ledgerKeyBind.getValue then
        return ledgerKeyBind:getValue()
    end
    return LEDGER_TOGGLE_DEFAULT_KEY
end

local function getDensityBoundKey()
    if densityKeyBind and densityKeyBind.getValue then
        return densityKeyBind:getValue()
    end
    return DENSITY_TOGGLE_DEFAULT_KEY
end

local function tr(key, fallback)
    if getText then
        local value = getText(key)
        if value and value ~= key then return value end
    end
    return fallback or key
end

CSR_UtilityHud = {
    panel = nil,
    standpipeState = {
        nearby = false,
        amount = 0,
        nextScanTick = 0,
    },
    -- Item wipe scheduler state (populated by server ItemWipeStatus command)
    itemWipeState = {
        enabled          = false,
        remainingSeconds = nil,   -- seconds remaining at last server update
        serverUpdateTime = 0,     -- os.time() at last server update
        wiping           = false, -- wipe currently in progress
    },
}

local MODDATA_X = "CSRUtilityHudX"
local MODDATA_Y = "CSRUtilityHudY"
local MODDATA_LOCKED = "CSRUtilityHudLocked"
local MODDATA_HIDDEN = "CSRUtilityHudHidden"
local MODDATA_WIDTH = "CSRUtilityHudWidth"
local MODDATA_SCALE = "CSRUtilityHudScale"
local MODDATA_DW = "CSRDualWieldEnabled"
local STATUS_SCAN_TICKS = 90
local BASE_PANEL_WIDTH = 220
local BASE_PANEL_HEIGHT = 128
local BASE_HEADER_HEIGHT = 22
local BASE_BUTTON_HEIGHT = 18
local BASE_LINE_HEIGHT = 16
local BASE_MIN_PANEL_WIDTH = 220
local BASE_MAX_PANEL_WIDTH = 360
local BASE_CONTENT_PADDING = 10
local BASE_BUTTON_GAP = 4
local BASE_SCREEN_MARGIN = 8
local BASE_RESIZE_HANDLE = 10
local HUD_SCALE_OPTIONS = { 0.75, 0.85, 1.0, 1.15, 1.3 }
local hudScale = 1.0

local function clampHudScale(value)
    value = tonumber(value) or 1.0
    if value < 0.65 then return 0.65 end
    if value > 1.5 then return 1.5 end
    return value
end

local function displayScale()
    local factor = CSR_Scale and CSR_Scale.factor and CSR_Scale.factor() or 1.0
    return factor * hudScale
end

local function px(value)
    return math.floor((value or 0) * displayScale() + 0.5)
end

local function screenSize()
    local core = getCore and getCore() or nil
    return core and core:getScreenWidth() or 1280,
        core and core:getScreenHeight() or 720
end

local function headerHeight()
    return math.max(20, px(BASE_HEADER_HEIGHT))
end

local function buttonHeight()
    return math.max(18, px(BASE_BUTTON_HEIGHT))
end

local statusFont

local function lineHeight()
    local tm = getTextManager and getTextManager() or nil
    local fontH = tm and tm:getFontHeight(statusFont()) or px(14)
    return math.max(px(BASE_LINE_HEIGHT), fontH + px(2))
end

local function contentPadding()
    return math.max(6, px(BASE_CONTENT_PADDING))
end

local function buttonGap()
    return math.max(3, px(BASE_BUTTON_GAP))
end

local function screenMargin()
    return math.max(2, px(BASE_SCREEN_MARGIN))
end

local function resizeHandleSize()
    return math.max(8, px(BASE_RESIZE_HANDLE))
end

function statusFont()
    if CSR_Scale and CSR_Scale.font then
        return CSR_Scale.font(14 * hudScale)
    end
    return UIFont.Small
end

local function panelWidthBounds()
    local screenWidth = screenSize()
    local available = math.max(120, screenWidth - (screenMargin() * 2))
    local minWidth = math.min(px(BASE_MIN_PANEL_WIDTH), available)
    local maxWidth = math.min(px(BASE_MAX_PANEL_WIDTH), available)
    if maxWidth < minWidth then
        maxWidth = minWidth
    end
    return minWidth, maxWidth
end

local function clampPanelWidth(width)
    local minWidth, maxWidth = panelWidthBounds()
    return math.floor(math.max(minWidth, math.min(maxWidth, tonumber(width) or minWidth)) + 0.5)
end

local function defaultPanelWidth()
    return clampPanelWidth(px(BASE_PANEL_WIDTH))
end

local function defaultPanelHeight()
    return math.max(px(BASE_PANEL_HEIGHT), headerHeight() + buttonHeight() + (lineHeight() * 4))
end

local function clampPanelToScreen(panel)
    if not panel then
        return
    end

    local screenWidth, screenHeight = screenSize()
    local margin = screenMargin()
    local maxX = math.max(0, screenWidth - (panel.width or 0) - margin)
    local maxY = math.max(0, screenHeight - (panel.height or 0) - margin)
    local minX = math.min(margin, maxX)
    local minY = math.min(margin, maxY)
    local nextX = math.max(minX, math.min(panel:getX(), maxX))
    local nextY = math.max(minY, math.min(panel:getY(), maxY))
    panel:setX(nextX)
    panel:setY(nextY)
end

local function getPlayerSafe()
    return getPlayer and getPlayer() or nil
end

local function getPlayerModData()
    local player = getPlayerSafe()
    return player and player:getModData() or nil
end

local function savePanelState(panel)
    local modData = getPlayerModData()
    if not modData or not panel then
        return
    end

    modData[MODDATA_X] = math.floor(panel:getX())
    modData[MODDATA_Y] = math.floor(panel:getY())
    modData[MODDATA_LOCKED] = panel.locked == true
    modData[MODDATA_SCALE] = hudScale
    if panel.userWidth then
        modData[MODDATA_WIDTH] = panel.userWidth
    end
end

local function defaultX()
    local screenWidth = screenSize()
    return math.max(screenMargin(), screenWidth - defaultPanelWidth() - px(24))
end

local function defaultY()
    return px(84)
end

local function restorePanelState()
    local modData = getPlayerModData()
    if not modData then
        hudScale = 1.0
        return defaultX(), defaultY(), false, nil, hudScale
    end

    hudScale = clampHudScale(modData[MODDATA_SCALE])
    local savedWidth = tonumber(modData[MODDATA_WIDTH]) or nil
    if savedWidth then
        savedWidth = clampPanelWidth(savedWidth)
    end

    return tonumber(modData[MODDATA_X]) or defaultX(),
        tonumber(modData[MODDATA_Y]) or defaultY(),
        modData[MODDATA_LOCKED] == true,
        savedWidth,
        hudScale
end

local function getPlayerCount()
    local data = CSR_PlayerMapTracker and CSR_PlayerMapTracker.playerData or nil
    if type(data) ~= "table" then
        return 0
    end

    return #data
end

local function getZombieDensitySummary()
    local cells = CSR_ZombieDensityOverlay and CSR_ZombieDensityOverlay.cells or nil
    if type(cells) ~= "table" or #cells == 0 then
        return "Zombie Density: --"
    end

    local maxDensity = 0
    local highestAmount = 0
    for i = 1, #cells do
        local cell = cells[i]
        if cell then
            maxDensity = math.max(maxDensity, tonumber(cell.density) or 0)
            highestAmount = math.max(highestAmount, tonumber(cell.amount) or 0)
        end
    end

    local label = "Clear"
    if maxDensity == 1 then
        label = "Low"
    elseif maxDensity == 2 then
        label = "Medium"
    elseif maxDensity >= 3 then
        label = "High"
    end

    return string.format("Zombie Density: %s (%d)", label, highestAmount)
end

local function getFreshnessWarning(player)
    local item = CSR_Utils.findSoonStaleFood and CSR_Utils.findSoonStaleFood(player) or nil
    if not item then
        return nil
    end
    local name = item.getDisplayName and item:getDisplayName() or item:getName() or "Food"
    return "Food: " .. name .. " going stale"
end

local function getDuplicateRepairHint(player)
    if not player then
        return nil
    end

    local inventory = player:getInventory()
    local items = inventory and inventory.getItems and inventory:getItems() or nil
    if not items then
        return nil
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and CSR_Utils.isRepairableItem(item) then
            local _, pct = CSR_Utils.findBetterDuplicate(player, item)
            if pct then
                local name = item.getDisplayName and item:getDisplayName() or item:getName() or "Item"
                return string.format("Repair: %s has better dup (%d%%)", name, pct)
            end
        end
    end

    return nil
end

local _vehKeyCache = { counter = 0, value = nil, cached = false }

local function getVehicleKeyStatus(player)
    if not player then
        return nil
    end

    -- Perf: inventory walk is O(n); throttle to roughly every 30 render
    -- frames (~0.5s at 60fps) instead of firing every frame.
    _vehKeyCache.counter = _vehKeyCache.counter + 1
    if _vehKeyCache.cached and _vehKeyCache.counter < 30 then
        return _vehKeyCache.value
    end
    _vehKeyCache.counter = 0
    _vehKeyCache.cached = true

    local inventory = player:getInventory()
    local items = inventory and inventory.getItems and inventory:getItems() or nil
    if not items then
        _vehKeyCache.value = nil
        return nil
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.getModData then
            local md = item:getModData()
            if md and md.CSR_KeyLabel then
                local v = "Key: " .. tostring(md.CSR_KeyLabel)
                _vehKeyCache.value = v
                return v
            end
        end
    end

    _vehKeyCache.value = nil
    return nil
end

local function scanForNearbyStandpipe(player)
    CSR_UtilityHud.standpipeState.nearby = false
    CSR_UtilityHud.standpipeState.amount = 0

    if not player or not CSR_FeatureFlags.isCityStandpipesEnabled() then
        return
    end

    local square = player:getSquare()
    if not square then
        return
    end

    local cell = getCell and getCell() or nil
    if not cell then
        return
    end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()

    for dx = -2, 2 do
        for dy = -2, 2 do
            local targetSquare = cell:getGridSquare(px + dx, py + dy, pz)
            local standpipe = CSR_Standpipe.getStandpipeObjectOnSquare(targetSquare)
            if standpipe then
                CSR_UtilityHud.standpipeState.nearby = true
                CSR_UtilityHud.standpipeState.amount = math.floor(CSR_Standpipe.getFluidAmount(standpipe) or 0)
                return
            end
        end
    end
end

local function updateStandpipeState()
    if CSR_UtilityHud.standpipeState.nextScanTick > 0 then
        CSR_UtilityHud.standpipeState.nextScanTick = CSR_UtilityHud.standpipeState.nextScanTick - 1
        return
    end

    scanForNearbyStandpipe(getPlayerSafe())
    CSR_UtilityHud.standpipeState.nextScanTick = STATUS_SCAN_TICKS
end

local function getItemWipeCountdown()
    local ws = CSR_UtilityHud.itemWipeState
    if not ws.enabled then return nil end
    if ws.wiping then return "Item Wipe: Running..." end
    if ws.remainingSeconds == nil then return nil end
    -- Interpolate countdown using real elapsed time since last server broadcast
    local elapsed = os.time() - (ws.serverUpdateTime or 0)
    local remaining = math.max(0, ws.remainingSeconds - elapsed)
    local h = math.floor(remaining / 3600)
    local m = math.floor((remaining % 3600) / 60)
    local s = math.floor(remaining % 60)
    if h > 0 then
        return string.format("Item Wipe: %dh %02dm", h, m)
    end
    return string.format("Item Wipe: %dm %02ds", m, s)
end

-- Dirty-cache for status lines: avoid rebuilding/remeasuring every frame
local _statusCache = { lines = {}, width = 0, lastKey = "" }

local function buildStatusKey(player)
    local parts = {}
    if CSR_FeatureFlags.isVisualSoundCuesEnabled() and CSR_SoundCues then
        local p = CSR_SoundCues.isPlayerSourceEnabled and CSR_SoundCues.isPlayerSourceEnabled()
        local z = CSR_SoundCues.isZombieSourceEnabled and CSR_SoundCues.isZombieSourceEnabled()
        local o = CSR_SoundCues.isOtherSourceEnabled and CSR_SoundCues.isOtherSourceEnabled()
        parts[#parts+1] = (p and "1" or "0") .. (z and "1" or "0") .. (o and "1" or "0")
    end
    if CSR_FeatureFlags.isSeatbeltEnabled() and player and player:getVehicle() then
        local enabled = CSR_SeatbeltSystem and CSR_SeatbeltSystem.seatbeltOn
            and CSR_SeatbeltSystem.seatbeltOn[player:getPlayerNum()] == true
        parts[#parts+1] = enabled and "sbon" or "sboff"
    end
    if CSR_FeatureFlags.isPryEnabled() then
        parts[#parts+1] = CSR_Utils.hasCrowbar(player) and "cwr" or "ncw"
    end
    if CSR_FeatureFlags.isPlayerMapTrackingEnabled() then
        parts[#parts+1] = tostring(getPlayerCount())
    end
    if CSR_FeatureFlags.isZombieDensityOverlayEnabled() then
        parts[#parts+1] = getZombieDensitySummary() or ""
    end
    if CSR_FeatureFlags.isCityStandpipesEnabled() then
        parts[#parts+1] = tostring(CSR_UtilityHud.standpipeState.nearby) .. tostring(CSR_UtilityHud.standpipeState.amount)
    end
    parts[#parts+1] = tostring(getFreshnessWarning(player) or "")
    parts[#parts+1] = tostring(getDuplicateRepairHint(player) or "")
    parts[#parts+1] = tostring(getVehicleKeyStatus(player) or "")
    parts[#parts+1] = tostring(getItemWipeCountdown() or "")
    return table.concat(parts, "|")
end

local function getStatusLines(player)
    local lines = {}

    if CSR_FeatureFlags.isVisualSoundCuesEnabled() and CSR_SoundCues then
        local p = CSR_SoundCues.isPlayerSourceEnabled and CSR_SoundCues.isPlayerSourceEnabled()
        local z = CSR_SoundCues.isZombieSourceEnabled and CSR_SoundCues.isZombieSourceEnabled()
        local o = CSR_SoundCues.isOtherSourceEnabled and CSR_SoundCues.isOtherSourceEnabled()
        lines[#lines + 1] = string.format(
            "Sound Filters: %s %s %s",
            p and "P" or "-",
            z and "Z" or "-",
            o and "O" or "-"
        )
    end

    if CSR_FeatureFlags.isSeatbeltEnabled() and player and player:getVehicle() then
        local enabled = CSR_SeatbeltSystem and CSR_SeatbeltSystem.seatbeltOn
            and CSR_SeatbeltSystem.seatbeltOn[player:getPlayerNum()] == true
        lines[#lines + 1] = enabled and "Seatbelt: ON" or "Seatbelt: OFF"
    end

    if CSR_FeatureFlags.isPryEnabled() then
        lines[#lines + 1] = CSR_Utils.hasCrowbar(player) and "Crowbar: Ready" or "Crowbar: Missing"
    end

    if CSR_FeatureFlags.isPlayerMapTrackingEnabled() then
        lines[#lines + 1] = string.format("Tracked Players: %d", getPlayerCount())
    end

    if CSR_FeatureFlags.isZombieDensityOverlayEnabled() then
        lines[#lines + 1] = getZombieDensitySummary()
    end

    if CSR_FeatureFlags.isCityStandpipesEnabled() then
        if CSR_UtilityHud.standpipeState.nearby then
            lines[#lines + 1] = string.format("Standpipe: Nearby (%d)", CSR_UtilityHud.standpipeState.amount)
        else
            lines[#lines + 1] = "Standpipe: None nearby"
        end
    end

    local foodWarning = getFreshnessWarning(player)
    if foodWarning then
        lines[#lines + 1] = foodWarning
    end

    local repairHint = getDuplicateRepairHint(player)
    if repairHint then
        lines[#lines + 1] = repairHint
    end

    local vehicleKey = getVehicleKeyStatus(player)
    if vehicleKey then
        lines[#lines + 1] = vehicleKey
    end

    local wipeCountdown = getItemWipeCountdown()
    if wipeCountdown then
        lines[#lines + 1] = wipeCountdown
    end

    return lines
end

local function measureLines(lines)
    local tm = getTextManager and getTextManager() or nil
    if not tm then
        return defaultPanelWidth()
    end

    local widest = defaultPanelWidth()
    local font = statusFont()
    local padding = contentPadding()
    for i = 1, #lines do
        local text = tostring(lines[i] or "")
        local lineWidth = tm:MeasureStringX(font, text) + (padding * 2)
        widest = math.max(widest, lineWidth)
    end

    return clampPanelWidth(widest)
end

local _fitCache = {}

local function fitLine(text, maxWidth)
    local tm = getTextManager and getTextManager() or nil
    local value = tostring(text or "")
    if not tm or maxWidth <= 0 then
        return value
    end

    local font = statusFont()
    local ck = value .. "\0" .. tostring(font) .. "\0" .. tostring(maxWidth)
    local cached = _fitCache[ck]
    if cached ~= nil then return cached end

    local result
    if tm:MeasureStringX(font, value) <= maxWidth then
        result = value
    else
        local ellipsis = "..."
        local ellipsisWidth = tm:MeasureStringX(font, ellipsis)
        local out = value
        while #out > 0 and (tm:MeasureStringX(font, out) + ellipsisWidth) > maxWidth do
            out = string.sub(out, 1, #out - 1)
        end
        if out == "" then
            result = ellipsis
        else
            result = out .. ellipsis
        end
    end

    _fitCache[ck] = result
    return result
end

local UtilityHudPanel = ISPanel:derive("CSR_UtilityHudPanel")

local function setElementBounds(element, x, y, width, height)
    if not element then
        return
    end

    if element.setX then element:setX(x) else element.x = x end
    if element.setY then element:setY(y) else element.y = y end
    if element.setWidth then element:setWidth(width) else element.width = width end
    if element.setHeight then element:setHeight(height) else element.height = height end
end

local function markHudButton(button, group, baseWidth)
    if not button then
        return
    end

    button.csrHudGroup = group
    button.csrHudBaseWidth = baseWidth or 32
    button.anchorTop = true
    button.anchorLeft = true
    button.anchorRight = false
end

local function appendButton(buttons, button)
    if button then
        buttons[#buttons + 1] = button
    end
end

local function buttonTitle(button)
    if not button then
        return ""
    end
    return tostring(button.title or button.name or "")
end

local function measuredButtonWidth(button, contentWidth)
    local width = px(button.csrHudBaseWidth or 32)
    local tm = getTextManager and getTextManager() or nil
    local title = buttonTitle(button)
    if tm and title ~= "" then
        width = math.max(width, tm:MeasureStringX(UIFont.Small, title) + px(16))
    end
    return math.min(math.max(px(24), width), math.max(px(24), contentWidth))
end

function UtilityHudPanel:initialise()
    ISPanel.initialise(self)
end

function UtilityHudPanel:packButtonGroup(buttons, y)
    if not buttons or #buttons == 0 then
        return y, false
    end

    local padding = contentPadding()
    local gap = buttonGap()
    local rowHeight = buttonHeight()
    local contentWidth = math.max(px(24), self.width - (padding * 2))
    local rightEdge = padding + contentWidth
    local x = padding
    local usedRow = false
    local placedAny = false

    for i = 1, #buttons do
        local button = buttons[i]
        if button then
            local width = measuredButtonWidth(button, contentWidth)
            if usedRow and x + width > rightEdge then
                x = padding
                y = y + rowHeight + gap
                usedRow = false
            end
            setElementBounds(button, x, y, width, rowHeight)
            x = x + width + gap
            usedRow = true
            placedAny = true
        end
    end

    if placedAny then
        return y + rowHeight + gap, true
    end
    return y, false
end

function UtilityHudPanel:layoutChildren()
    local headerH = headerHeight()
    local padding = contentPadding()
    local gap = buttonGap()
    local headerControlH = math.max(16, headerH - px(4))
    local iconSide = math.max(18, math.min(headerControlH, px(24)))

    local lockW = px(54)
    local tm = getTextManager and getTextManager() or nil
    if tm and self.lockButton then
        lockW = math.max(lockW, tm:MeasureStringX(UIFont.Small, buttonTitle(self.lockButton)) + px(16))
    end
    lockW = math.min(lockW, math.max(px(44), self.width - (padding * 2) - ((iconSide + gap) * 2)))

    local x = self.width - padding - lockW
    setElementBounds(self.lockButton, x, px(2), lockW, headerControlH)
    x = x - gap - iconSide
    setElementBounds(self.guideButton, x, px(2), iconSide, headerControlH)
    x = x - gap - iconSide
    setElementBounds(self.prefsButton, x, px(2), iconSide, headerControlH)

    local y = headerH + px(3)
    local primary = {}
    appendButton(primary, self.soundPlayerButton)
    appendButton(primary, self.soundZombieButton)
    appendButton(primary, self.soundOtherButton)
    appendButton(primary, self.dualWieldButton)
    appendButton(primary, self.emergencySwapButton)
    appendButton(primary, self.entryActionsButton)
    appendButton(primary, self.ledgerButton)
    appendButton(primary, self.densityHudButton)
    appendButton(primary, self.claimsButton)
    y = self:packButtonGroup(primary, y)

    local aim = {}
    appendButton(aim, self.aimHpButton)
    appendButton(aim, self.aimAmmoButton)
    appendButton(aim, self.aimZedsButton)
    y = self:packButtonGroup(aim, y)

    local utility = {}
    appendButton(utility, self.skillJournalButton)
    appendButton(utility, self.antibodiesButton)
    appendButton(utility, self.adminDocButton)
    y = self:packButtonGroup(utility, y)

    self.statusTop = y + px(3)

    if self.resizeHandle then
        local resizeSide = resizeHandleSize()
        setElementBounds(self.resizeHandle, self.width - resizeSide, self.height - resizeSide, resizeSide, resizeSide)
    end
end

function UtilityHudPanel:reflowForDisplay()
    local width = clampPanelWidth(self.userWidth or self.width or defaultPanelWidth())
    if self.width ~= width then
        self:setWidth(width)
    end
    self:layoutChildren()
    clampPanelToScreen(self)
    for k in pairs(_fitCache) do _fitCache[k] = nil end
end

function UtilityHudPanel:setHudScale(scale)
    local nextScale = clampHudScale(scale)
    if math.abs((hudScale or 1.0) - nextScale) < 0.001 then return end
    hudScale = nextScale
    self.userWidth = nil
    _statusCache.lastKey = ""
    for k in pairs(_fitCache) do _fitCache[k] = nil end
    self:reflowForDisplay()
    savePanelState(self)
end

function UtilityHudPanel:createChildren()
    ISPanel.createChildren(self)

    local headerH = headerHeight()
    local btnH = buttonHeight()
    local rowStep = btnH + buttonGap()
    local pad = contentPadding()
    local gap = buttonGap()
    local headerY = px(2)
    local headerInset = px(4)
    local smallW = px(32)
    local mediumW = px(48)
    local claimsW = px(52)
    local utilityW = px(60)
    local antibodiesW = px(80)
    local headerIconW = px(18)
    local lockW = px(50)

    self.lockButton = ISButton:new(self.width - px(54), headerY, lockW, headerH - headerInset, self.locked and tr("IGUI_CSR_Util_UnlockBtn", "Unlock") or tr("IGUI_CSR_Util_LockBtn", "Lock"), self, self.onToggleLock)
    self.lockButton:initialise()
    self.lockButton:instantiate()
    self.lockButton.anchorTop = true
    self.lockButton.anchorRight = true
    self:addChild(self.lockButton)
    CSR_Theme.applyButtonStyle(self.lockButton, "accentBlue", false)
    self.lockButton:setTooltip(self.locked and tr("Tooltip_CSR_Util_UnlockBtn", "Unlock Utility HUD movement.") or tr("Tooltip_CSR_Util_LockBtn", "Lock Utility HUD movement."))

    self.guideButton = ISButton:new(self.width - px(76), headerY, headerIconW, headerH - headerInset, "?", self, self.onToggleGuide)
    self.guideButton:initialise()
    self.guideButton:instantiate()
    self.guideButton.anchorTop = true
    self.guideButton.anchorRight = true
    self:addChild(self.guideButton)
    CSR_Theme.applyButtonStyle(self.guideButton, "accentViolet", false)
    self.guideButton:setTooltip(tr("Tooltip_CSR_Util_GuideBtn", "Open the Common Sense Reborn in-game guide."))

    self.prefsButton = ISButton:new(self.width - px(96), headerY, headerIconW, headerH - headerInset, "S", self, self.onTogglePrefs)
    self.prefsButton:initialise()
    self.prefsButton:instantiate()
    self.prefsButton.anchorTop   = true
    self.prefsButton.anchorRight = true
    self:addChild(self.prefsButton)
    CSR_Theme.applyButtonStyle(self.prefsButton, "accentViolet", false)
    self.prefsButton:setTooltip(tr("Tooltip_CSR_Util_SettingsBtn", "Open per-player CSR settings."))

    if CSR_FeatureFlags.isVisualSoundCuesEnabled() and CSR_SoundCues then
        self.soundPlayerButton = ISButton:new(pad, headerH + headerY, smallW, btnH, "P", self, self.onToggleSoundPlayers)
        self.soundPlayerButton:initialise()
        self.soundPlayerButton:instantiate()
        self.soundPlayerButton:setTooltip(tr("Tooltip_CSR_Util_SoundPlayers", "Toggle visual sound cues from players."))
        self:addChild(self.soundPlayerButton)

        self.soundZombieButton = ISButton:new(pad + smallW + gap, headerH + headerY, smallW, btnH, "Z", self, self.onToggleSoundZombies)
        self.soundZombieButton:initialise()
        self.soundZombieButton:instantiate()
        self.soundZombieButton:setTooltip(tr("Tooltip_CSR_Util_SoundZombies", "Toggle visual sound cues from zombies."))
        self:addChild(self.soundZombieButton)

        self.soundOtherButton = ISButton:new(pad + ((smallW + gap) * 2), headerH + headerY, smallW, btnH, "O", self, self.onToggleSoundOthers)
        self.soundOtherButton:initialise()
        self.soundOtherButton:instantiate()
        self.soundOtherButton:setTooltip(tr("Tooltip_CSR_Util_SoundOther", "Toggle visual sound cues from other sources."))
        self:addChild(self.soundOtherButton)

        self:updateSoundButtons()
    end

    if CSR_FeatureFlags.isDualWieldEnabled() or (SandboxVars and SandboxVars.CommonSenseReborn and SandboxVars.CommonSenseReborn.EnableDualWield ~= false) then
        local dwX = self.soundOtherButton and (self.soundOtherButton:getX() + self.soundOtherButton:getWidth() + gap) or pad
        self.dualWieldButton = ISButton:new(dwX, headerH + headerY, smallW, btnH, "DW", self, self.onToggleDualWield)
        self.dualWieldButton:initialise()
        self.dualWieldButton:instantiate()
        self:addChild(self.dualWieldButton)
        self:updateDualWieldButton()

        -- v1.8.1: Emergency Swap toggle (ES). Auto-recovers when the engine
        -- clears the secondary slot and the off-hand weapon is stuck in
        -- inventory with attachedSlot set (the "vanish + unequipable" bug).
        local esX = self.dualWieldButton:getX() + self.dualWieldButton:getWidth() + gap
        self.emergencySwapButton = ISButton:new(esX, headerH + headerY, smallW, btnH, "ES", self, self.onToggleEmergencySwap)
        self.emergencySwapButton:initialise()
        self.emergencySwapButton:instantiate()
        self:addChild(self.emergencySwapButton)
        self:updateEmergencySwapButton()
    end

    -- Entry Actions toggle (pry / lockpick / bolt-cut master switch)
    if SandboxVars and SandboxVars.CommonSenseReborn and SandboxVars.CommonSenseReborn.EnableEntryActions ~= false then
        local eaX = pad
        if self.emergencySwapButton then eaX = self.emergencySwapButton:getX() + self.emergencySwapButton:getWidth() + gap
        elseif self.dualWieldButton then eaX = self.dualWieldButton:getX() + self.dualWieldButton:getWidth() + gap end
        self.entryActionsButton = ISButton:new(eaX, headerH + headerY, smallW, btnH, "EA", self, self.onToggleEntryActions)
        self.entryActionsButton:initialise()
        self.entryActionsButton:instantiate()
        self.entryActionsButton:setTooltip(tr("Tooltip_CSR_Util_EntryActionsOn", "Entry actions: ON (pry / lockpick / bolt-cut)"))
        self:addChild(self.entryActionsButton)
        self:updateEntryActionsButton()
    end

    -- Survivor's Ledger toggle button
    if CSR_FeatureFlags.isSurvivorLedgerEnabled() then
        local ldX = pad
        if self.entryActionsButton then
            ldX = self.entryActionsButton:getX() + self.entryActionsButton:getWidth() + gap
        elseif self.emergencySwapButton then
            ldX = self.emergencySwapButton:getX() + self.emergencySwapButton:getWidth() + gap
        elseif self.dualWieldButton then
            ldX = self.dualWieldButton:getX() + self.dualWieldButton:getWidth() + gap
        end
        self.ledgerButton = ISButton:new(ldX, headerH + headerY, smallW, btnH, "LD", self, self.onToggleLedger)
        self.ledgerButton:initialise()
        self.ledgerButton:instantiate()
        self:addChild(self.ledgerButton)
        self:updateLedgerButton()
    end

    -- Nearby Density HUD show/hide button (mirrors the X-close on the density widget)
    if CSR_FeatureFlags.isZombieDensityOverlayEnabled and CSR_FeatureFlags.isZombieDensityOverlayEnabled() then
        local dhX = pad
        if self.ledgerButton then
            dhX = self.ledgerButton:getX() + self.ledgerButton:getWidth() + gap
        elseif self.entryActionsButton then
            dhX = self.entryActionsButton:getX() + self.entryActionsButton:getWidth() + gap
        elseif self.emergencySwapButton then
            dhX = self.emergencySwapButton:getX() + self.emergencySwapButton:getWidth() + gap
        elseif self.dualWieldButton then
            dhX = self.dualWieldButton:getX() + self.dualWieldButton:getWidth() + gap
        end
        self.densityHudButton = ISButton:new(dhX, headerH + headerY, smallW, btnH, "DH", self, self.onToggleDensityHud)
        self.densityHudButton:initialise()
        self.densityHudButton:instantiate()
        self:addChild(self.densityHudButton)
        self:updateDensityHudButton()
    end

    -- v1.8.2: Claims Manager quick-open button.  Opens the unified panel
    -- (Personal / Faction / Vehicle tabs) on its default tab; users switch
    -- tabs inside the panel.  Hidden behind the same EnableCSRClaimsOverride
    -- feature flag that gates the Claims Manager itself.
    if CSR_FeatureFlags.isCSRClaimsOverrideEnabled and CSR_FeatureFlags.isCSRClaimsOverrideEnabled() then
        local cmX = pad
        if self.densityHudButton then
            cmX = self.densityHudButton:getX() + self.densityHudButton:getWidth() + gap
        elseif self.ledgerButton then
            cmX = self.ledgerButton:getX() + self.ledgerButton:getWidth() + gap
        elseif self.entryActionsButton then
            cmX = self.entryActionsButton:getX() + self.entryActionsButton:getWidth() + gap
        end
        self.claimsButton = ISButton:new(cmX, headerH + headerY, claimsW, btnH,
            getText("IGUI_CSR_Util_ClaimsBtn"), self, self.onOpenClaims)
        self.claimsButton:initialise(); self.claimsButton:instantiate()
        self.claimsButton:setTooltip(getText("Tooltip_CSR_Util_ClaimsBtn"))
        self:addChild(self.claimsButton)

        CSR_Theme.applyButtonStyle(self.claimsButton, "accentSlate", false)
    end

    -- v1.8.17: Skill Journal quick-open button.  Pure-UI snapshot/recover
    -- of perks / recipes / magazines, keyed to Steam ID server-side.
    -- Placed on its own row below the toggle row (and below the aim-cursor
    -- pill row when Weapon HUD Overlay is enabled) so it can never overflow
    -- past the panel border on narrow widths.
    if CSR_FeatureFlags.isSkillJournalEnabled and CSR_FeatureFlags.isSkillJournalEnabled() then
        local sjRowY = headerH + headerY + rowStep
        if CSR_FeatureFlags.isWeaponHudOverlayEnabled and CSR_FeatureFlags.isWeaponHudOverlayEnabled() then
            sjRowY = sjRowY + rowStep
        end
        self.skillJournalButton = ISButton:new(pad, sjRowY, utilityW, btnH,
            getText("IGUI_CSR_Util_JournalBtn"), self, self.onToggleSkillJournal)
        self.skillJournalButton:initialise(); self.skillJournalButton:instantiate()
        self.skillJournalButton:setTooltip(getText("Tooltip_CSR_Util_JournalBtn"))
        self:addChild(self.skillJournalButton)
        if CSR_Theme and CSR_Theme.applyButtonStyle then
            CSR_Theme.applyButtonStyle(self.skillJournalButton, "accentSlate", false)
        end

        -- Antibodies quick-open, immediately to the right of Journal.
        -- (Previously on its own row, which let the "Antibodies" label
        -- collide with the status text below it on narrow widths.)
        if CSR_FeatureFlags.isAntibodySystemEnabled and CSR_FeatureFlags.isAntibodySystemEnabled() then
            self.antibodiesButton = ISButton:new(pad + utilityW + gap, sjRowY, antibodiesW, btnH,
                getText("IGUI_CSR_Antibody_Button"), self, self.onToggleAntibodies)
            self.antibodiesButton:initialise(); self.antibodiesButton:instantiate()
            self.antibodiesButton:setTooltip(getText("IGUI_CSR_Antibody_Title"))
            self:addChild(self.antibodiesButton)
            if CSR_Theme and CSR_Theme.applyButtonStyle then
                CSR_Theme.applyButtonStyle(self.antibodiesButton, "accentRed", false)
            end
        end

        -- v1.8.20: Admin-only Sandbox Variable Reference button.  Sits
        -- immediately to the right of the Journal button and is hidden
        -- entirely for non-admin players (so the Journal row stays the
        -- same width for everyone else).
        if CSR_AdminSandboxDoc and CSR_AdminSandboxDoc.isLocalAdmin and CSR_AdminSandboxDoc.isLocalAdmin() then
            local adminX = pad + utilityW + gap
            if self.antibodiesButton then
                adminX = self.antibodiesButton:getX() + self.antibodiesButton:getWidth() + gap
            end
            self.adminDocButton = ISButton:new(adminX, sjRowY, utilityW, btnH,
                tr("IGUI_CSR_Util_AdminBtn", "Admin"), self, self.onToggleAdminSandboxDoc)
            self.adminDocButton:initialise(); self.adminDocButton:instantiate()
            self.adminDocButton:setTooltip(tr("Tooltip_CSR_Util_AdminBtn", "Admin only: list every CSR sandbox variable with its current value and tooltip. Read-only reference panel."))
            self:addChild(self.adminDocButton)
            if CSR_Theme and CSR_Theme.applyButtonStyle then
                CSR_Theme.applyButtonStyle(self.adminDocButton, "accentRed", false)
            end
        end
    end

    -- (Antibodies button is created above on the Journal row.)

    -- Aim-cursor pill toggles (second toggle row): HP / Ammo / Zeds.
    -- Only shown when the parent Weapon HUD Overlay is enabled.
    if CSR_FeatureFlags.isWeaponHudOverlayEnabled and CSR_FeatureFlags.isWeaponHudOverlayEnabled() then
        local aimRowY = headerH + headerY + rowStep
        local aimX = pad
        -- Per-button widths sized to the actual label length so longer text
        -- ("Ammo", "Zeds") doesn't overflow the next button. Previously every
        -- button was 38px wide which let "Ammo" bleed into "Zeds".
        local hpW   = smallW
        local ammoW = mediumW
        local zedsW = mediumW

        self.aimHpButton = ISButton:new(aimX, aimRowY, hpW, btnH, "HP", self, self.onToggleAimHp)
        self.aimHpButton:initialise()
        self.aimHpButton:instantiate()
        self:addChild(self.aimHpButton)

        local ammoX = aimX + hpW + gap
        self.aimAmmoButton = ISButton:new(ammoX, aimRowY, ammoW, btnH, "Ammo", self, self.onToggleAimAmmo)
        self.aimAmmoButton:initialise()
        self.aimAmmoButton:instantiate()
        self:addChild(self.aimAmmoButton)

        local zedsX = ammoX + ammoW + gap
        self.aimZedsButton = ISButton:new(zedsX, aimRowY, zedsW, btnH, "Zeds", self, self.onToggleAimZeds)
        self.aimZedsButton:initialise()
        self.aimZedsButton:instantiate()
        self:addChild(self.aimZedsButton)

        self:updateAimCursorButtons()
    end

    markHudButton(self.soundPlayerButton, "primary", 32)
    markHudButton(self.soundZombieButton, "primary", 32)
    markHudButton(self.soundOtherButton, "primary", 32)
    markHudButton(self.dualWieldButton, "primary", 32)
    markHudButton(self.emergencySwapButton, "primary", 32)
    markHudButton(self.entryActionsButton, "primary", 32)
    markHudButton(self.ledgerButton, "primary", 32)
    markHudButton(self.densityHudButton, "primary", 32)
    markHudButton(self.claimsButton, "primary", 52)
    markHudButton(self.aimHpButton, "aim", 32)
    markHudButton(self.aimAmmoButton, "aim", 48)
    markHudButton(self.aimZedsButton, "aim", 48)
    markHudButton(self.skillJournalButton, "utility", 60)
    markHudButton(self.antibodiesButton, "utility", 80)
    markHudButton(self.adminDocButton, "utility", 60)

    local resizeSide = resizeHandleSize()
    self.resizeHandle = ISResizeWidget:new(self.width - resizeSide, self.height - resizeSide, resizeSide, resizeSide, self)
    self.resizeHandle:initialise()
    self:addChild(self.resizeHandle)
    self:layoutChildren()
end

function UtilityHudPanel:onResize()
    local w = clampPanelWidth(self.width)
    self.userWidth = w
    self:setWidth(w)
    self:layoutChildren()
    clampPanelToScreen(self)
    savePanelState(self)
end

function UtilityHudPanel:updateSoundButtons()
    if self.soundPlayerButton and CSR_SoundCues then
        CSR_Theme.applyButtonStyle(self.soundPlayerButton, "accentViolet", CSR_SoundCues.isPlayerSourceEnabled())
    end
    if self.soundZombieButton and CSR_SoundCues then
        CSR_Theme.applyButtonStyle(self.soundZombieButton, "accentGreen", CSR_SoundCues.isZombieSourceEnabled())
    end
    if self.soundOtherButton and CSR_SoundCues then
        CSR_Theme.applyButtonStyle(self.soundOtherButton, "accentAmber", CSR_SoundCues.isOtherSourceEnabled())
    end
end

function UtilityHudPanel:onToggleLock()
    self.locked = not self.locked
    local label = self.locked and tr("IGUI_CSR_Util_UnlockBtn", "Unlock") or tr("IGUI_CSR_Util_LockBtn", "Lock")
    if self.lockButton and self.lockButton.setTitle then
        self.lockButton:setTitle(label)
    elseif self.lockButton then
        self.lockButton.title = label
    end
    if self.lockButton then
        self.lockButton:setTooltip(self.locked and tr("Tooltip_CSR_Util_UnlockBtn", "Unlock Utility HUD movement.") or tr("Tooltip_CSR_Util_LockBtn", "Lock Utility HUD movement."))
    end
    CSR_Theme.applyButtonStyle(self.lockButton, self.locked and "accentAmber" or "accentBlue", self.locked)
    self:layoutChildren()
    savePanelState(self)
end

function UtilityHudPanel:onToggleGuide()
    if CSR_Guide and CSR_Guide.toggle then
        CSR_Guide.toggle()
    end
end

function UtilityHudPanel:onToggleSoundPlayers()
    if CSR_SoundCues and CSR_SoundCues.togglePlayerSource then
        CSR_SoundCues.togglePlayerSource()
        self:updateSoundButtons()
    end
end

function UtilityHudPanel:onToggleSoundZombies()
    if CSR_SoundCues and CSR_SoundCues.toggleZombieSource then
        CSR_SoundCues.toggleZombieSource()
        self:updateSoundButtons()
    end
end

function UtilityHudPanel:onToggleSoundOthers()
    if CSR_SoundCues and CSR_SoundCues.toggleOtherSource then
        CSR_SoundCues.toggleOtherSource()
        self:updateSoundButtons()
    end
end

function UtilityHudPanel:onToggleDualWield()
    if CSR_FeatureFlags.isAdminAuthoritative() then return end
    CSR_PlayerPrefs.toggle("DualWield")
    self:updateDualWieldButton()
end

function UtilityHudPanel:onToggleEmergencySwap()
    CSR_PlayerPrefs.toggle("DualWieldEmergencySwap")
    self:updateEmergencySwapButton()
end

function UtilityHudPanel:updateEmergencySwapButton()
    if not self.emergencySwapButton then return end
    local enabled = false
    local pref = CSR_PlayerPrefs and CSR_PlayerPrefs._byKey and CSR_PlayerPrefs._byKey["DualWieldEmergencySwap"]
    if pref then enabled = pref.effectiveFn() == true end
    CSR_Theme.applyButtonStyle(self.emergencySwapButton, enabled and "accentGreen" or "accentRed", enabled)
    self.emergencySwapButton:setTooltip(enabled
        and tr("Tooltip_CSR_Util_EmergencySwapOn", "Dual Wield Emergency Swap: ON\nAuto-recovers stuck off-hand weapons.")
        or  tr("Tooltip_CSR_Util_EmergencySwapOff", "Dual Wield Emergency Swap: OFF"))
end

function UtilityHudPanel:onToggleEntryActions()
    CSR_PlayerPrefs.toggle("EntryActions")
    self:updateEntryActionsButton()
end

function UtilityHudPanel:onToggleLedger()
    CSR_PlayerPrefs.toggle("SurvivorLedger")
    self:updateLedgerButton()
end

function UtilityHudPanel:updateLedgerButton()
    if not self.ledgerButton then return end
    local enabled = false
    local pref = CSR_PlayerPrefs and CSR_PlayerPrefs._byKey and CSR_PlayerPrefs._byKey["SurvivorLedger"]
    if pref and pref.effectiveFn then
        enabled = pref.effectiveFn() == true
    elseif CSR_FeatureFlags and CSR_FeatureFlags.isSurvivorLedgerEnabled then
        enabled = CSR_FeatureFlags.isSurvivorLedgerEnabled() == true
    end
    CSR_Theme.applyButtonStyle(self.ledgerButton, enabled and "accentGreen" or "accentRed", enabled)
    self.ledgerButton:setTooltip(enabled and tr("Tooltip_CSR_Util_LedgerOn", "Survivor's Ledger: ON (Numpad 4)") or tr("Tooltip_CSR_Util_LedgerOff", "Survivor's Ledger: OFF (Numpad 4)"))
end

function UtilityHudPanel:onToggleDensityHud()
    if CSR_NearbyDensityHUD and CSR_NearbyDensityHUD.toggle then
        CSR_NearbyDensityHUD.toggle()
    end
    self:updateDensityHudButton()
end

function UtilityHudPanel:updateDensityHudButton()
    if not self.densityHudButton then return end
    local visible = CSR_NearbyDensityHUD and CSR_NearbyDensityHUD.isVisible and CSR_NearbyDensityHUD.isVisible() or false
    CSR_Theme.applyButtonStyle(self.densityHudButton, visible and "accentGreen" or "accentSlate", visible)
    self.densityHudButton:setTooltip(visible and tr("Tooltip_CSR_Util_DensityShown", "Nearby Density HUD: SHOWN (Numpad 0)") or tr("Tooltip_CSR_Util_DensityHidden", "Nearby Density HUD: HIDDEN (Numpad 0)"))
end

function UtilityHudPanel:updateEntryActionsButton()
    if not self.entryActionsButton then return end
    local enabled = CSR_FeatureFlags.isEntryActionsEnabled()
    CSR_Theme.applyButtonStyle(self.entryActionsButton, enabled and "accentGreen" or "accentRed", enabled)
    self.entryActionsButton:setTooltip(enabled and tr("Tooltip_CSR_Util_EntryActionsOn", "Entry actions: ON (pry / lockpick / bolt-cut)") or tr("Tooltip_CSR_Util_EntryActionsOff", "Entry actions: OFF"))
end

-- v1.8.2: Claims Manager quick-open handlers.  Open the unified panel and
-- jump to the requested tab (Personal / Faction / Vehicle).  Re-clicking the
-- same button closes the panel via CSR_ClaimsManagerPanel.open()'s built-in
-- toggle behavior.
local function csrOpenClaimsTab(tabName)
    if not CSR_ClaimsManagerPanel or not CSR_ClaimsManagerPanel.open then return end
    CSR_ClaimsManagerPanel.open(getPlayer())
    if CSR_ClaimsManagerPanel.instance and CSR_ClaimsManagerPanel.instance.setTab then
        pcall(function() CSR_ClaimsManagerPanel.instance:setTab(tabName) end)
    end
end

function UtilityHudPanel:onOpenClaims()         csrOpenClaimsTab("personal") end
function UtilityHudPanel:onOpenClaimsPersonal() csrOpenClaimsTab("personal") end
function UtilityHudPanel:onOpenClaimsFaction()  csrOpenClaimsTab("faction")  end
function UtilityHudPanel:onOpenClaimsVehicle()  csrOpenClaimsTab("vehicle")  end

function UtilityHudPanel:onToggleSkillJournal()
    if CSR_SkillJournalPanel and CSR_SkillJournalPanel.toggle then
        CSR_SkillJournalPanel.toggle()
    end
end

function UtilityHudPanel:onToggleAdminSandboxDoc()
    if CSR_AdminSandboxDoc and CSR_AdminSandboxDoc.toggle then
        CSR_AdminSandboxDoc.toggle()
    end
end

function UtilityHudPanel:onToggleAntibodies()
    if CSR_AntibodiesEntry and CSR_AntibodiesEntry.open then
        CSR_AntibodiesEntry.open(getPlayer())
    elseif CSR_AntibodiesPanel and CSR_AntibodiesPanel.open then
        CSR_AntibodiesPanel.open(getPlayer(), getPlayer())
    end
end

function UtilityHudPanel:onToggleAimHp()
    CSR_PlayerPrefs.toggle("AimingHealthCursor")
    self:updateAimCursorButtons()
end

function UtilityHudPanel:onToggleAimAmmo()
    CSR_PlayerPrefs.toggle("AimingAmmoCursor")
    self:updateAimCursorButtons()
end

function UtilityHudPanel:onToggleAimZeds()
    CSR_PlayerPrefs.toggle("AimingDensityCursor")
    self:updateAimCursorButtons()
end

function UtilityHudPanel:updateAimCursorButtons()
    if self.aimHpButton then
        local on = CSR_FeatureFlags.isAimingHealthCursorEnabled()
        CSR_Theme.applyButtonStyle(self.aimHpButton, on and "accentGreen" or "accentRed", on)
        self.aimHpButton:setTooltip(on and tr("Tooltip_CSR_Util_AimHpOn", "Aim cursor HP pill: ON") or tr("Tooltip_CSR_Util_AimHpOff", "Aim cursor HP pill: OFF"))
    end
    if self.aimAmmoButton then
        local on = CSR_FeatureFlags.isAimingAmmoCursorEnabled()
        CSR_Theme.applyButtonStyle(self.aimAmmoButton, on and "accentGreen" or "accentRed", on)
        self.aimAmmoButton:setTooltip(on and tr("Tooltip_CSR_Util_AimAmmoOn", "Aim cursor ammo pill: ON") or tr("Tooltip_CSR_Util_AimAmmoOff", "Aim cursor ammo pill: OFF"))
    end
    if self.aimZedsButton then
        local on = CSR_FeatureFlags.isAimingDensityCursorEnabled()
        CSR_Theme.applyButtonStyle(self.aimZedsButton, on and "accentGreen" or "accentRed", on)
        self.aimZedsButton:setTooltip(on and tr("Tooltip_CSR_Util_AimZedsOn", "Aim cursor zombie density pill: ON") or tr("Tooltip_CSR_Util_AimZedsOff", "Aim cursor zombie density pill: OFF"))
    end
end

function UtilityHudPanel:onTogglePrefs()
    if not CSR_PlayerPrefsPanel then return end
    local hud = CSR_UtilityHud.panel
    local ax  = hud and math.max(4, hud:getX() - 294) or 100
    local ay  = hud and hud:getY() or 84
    CSR_PlayerPrefsPanel.toggle(ax, ay)
end

function UtilityHudPanel:updateDualWieldButton()
    if not self.dualWieldButton then return end
    local locked = CSR_FeatureFlags.isAdminAuthoritative()
    local enabled = CSR_FeatureFlags.isDualWieldEnabled()
    if locked then
        self.dualWieldButton:setTitle("DW \187")
        CSR_Theme.applyButtonStyle(self.dualWieldButton, enabled and "accentGreen" or "accentRed", enabled)
        self.dualWieldButton:setTooltip(tr("Tooltip_CSR_Util_DualWieldAdmin", "Dual Wield: admin-controlled"))
    else
        self.dualWieldButton:setTitle("DW")
        CSR_Theme.applyButtonStyle(self.dualWieldButton, enabled and "accentGreen" or "accentRed", enabled)
        self.dualWieldButton:setTooltip(enabled and tr("Tooltip_CSR_Util_DualWieldOn", "Dual Wield: ON (Numpad 8)") or tr("Tooltip_CSR_Util_DualWieldOff", "Dual Wield: OFF (Numpad 8)"))
    end
end

function UtilityHudPanel:onMouseDown(x, y)
    if self.locked or y > headerHeight() then
        return ISPanel.onMouseDown(self, x, y)
    end

    self.dragging = true
    self.dragX = x
    self.dragY = y
    return true
end

function UtilityHudPanel:onMouseMove(dx, dy)
    if self.dragging then
        local mouseX = getMouseX and getMouseX() or self:getX()
        local mouseY = getMouseY and getMouseY() or self:getY()
        self:setX(mouseX - self.dragX)
        self:setY(mouseY - self.dragY)
        clampPanelToScreen(self)
        return true
    end

    return ISPanel.onMouseMove(self, dx, dy)
end

function UtilityHudPanel:onMouseMoveOutside(dx, dy)
    if self.dragging then
        local mouseX = getMouseX and getMouseX() or self:getX()
        local mouseY = getMouseY and getMouseY() or self:getY()
        self:setX(mouseX - self.dragX)
        self:setY(mouseY - self.dragY)
        clampPanelToScreen(self)
        return true
    end

    return ISPanel.onMouseMoveOutside(self, dx, dy)
end

function UtilityHudPanel:onMouseUp(x, y)
    if self.dragging then
        self.dragging = false
        savePanelState(self)
        return true
    end

    return ISPanel.onMouseUp(self, x, y)
end

function UtilityHudPanel:onMouseUpOutside(x, y)
    if self.dragging then
        self.dragging = false
        savePanelState(self)
        return true
    end

    return ISPanel.onMouseUpOutside(self, x, y)
end

function UtilityHudPanel:onRightMouseUp(x, y)
    local context = ISContextMenu.get(0, self:getAbsoluteX() + x, self:getAbsoluteY() + y)
    if not context then return true end

    local scaleSub = ISContextMenu:getNew(context)
    local scaleOpt = context:addOption("Scale", self, nil)
    context:addSubMenu(scaleOpt, scaleSub)

    for i = 1, #HUD_SCALE_OPTIONS do
        local scale = HUD_SCALE_OPTIONS[i]
        local label = string.format("%d%%", math.floor((scale * 100) + 0.5))
        if math.abs((hudScale or 1.0) - scale) < 0.01 then
            label = "[X] " .. label
        else
            label = "[ ] " .. label
        end
        scaleSub:addOption(label, self, function(self_)
            self_:setHudScale(scale)
        end)
    end

    return true
end

function UtilityHudPanel:prerender()
    self._scalePoll = (self._scalePoll or 0) + 1
    if self._scalePoll >= 30 then
        self._scalePoll = 0
        if CSR_Scale and CSR_Scale.refresh then
            CSR_Scale.refresh()
        end
    end

    local factor = displayScale()
    if self._lastScaleFactor ~= factor then
        self._lastScaleFactor = factor
        self:reflowForDisplay()
    end

    ISPanel.prerender(self)
    CSR_Theme.drawPanelChrome(self, "CSR Utility", headerHeight())
end

function UtilityHudPanel:render()
    ISPanel.render(self)

    local player = getPlayerSafe()
    if not player or player:isDead() then
        return
    end

    updateStandpipeState()
    self:updateSoundButtons()
    local cacheKey = buildStatusKey(player)
    if cacheKey ~= _statusCache.lastKey then
        _statusCache.lines = getStatusLines(player)
        _statusCache.width = measureLines(_statusCache.lines)
        _statusCache.lastKey = cacheKey
        -- Invalidate fitLine memo whenever status content changes
        for k in pairs(_fitCache) do _fitCache[k] = nil end
    end
    local lines = _statusCache.lines
    local contentWidth = _statusCache.width
    local targetWidth = self.userWidth and math.max(self.userWidth, contentWidth) or contentWidth
    targetWidth = clampPanelWidth(targetWidth)
    if self.width ~= targetWidth then
        self:setWidth(targetWidth)
        self:layoutChildren()
    end
    if not self.statusTop then
        self:layoutChildren()
    end

    local lineH = lineHeight()
    local padding = contentPadding()
    local statusTop = self.statusTop or (headerHeight() + buttonHeight() + padding)
    local neededHeight = statusTop + px(6) + (#lines * lineH)
    if self.height ~= neededHeight then
        self:setHeight(neededHeight)
        self:layoutChildren()
    end
    clampPanelToScreen(self)

    for i = 1, #lines do
        local text = fitLine(lines[i], self.width - (padding * 2))
        local color = CSR_Theme.statusColor(text)
        self:drawText(text, padding, statusTop + ((i - 1) * lineH), color.r, color.g, color.b, color.a or 1.0, statusFont())
    end
end

local function createPanel()
    if CSR_UtilityHud.panel or not CSR_FeatureFlags.isUtilityHudEnabled() then
        return
    end

    local x, y, locked, savedWidth, savedScale = restorePanelState()
    hudScale = clampHudScale(savedScale)
    local initWidth = savedWidth or defaultPanelWidth()
    local panel = UtilityHudPanel:new(x, y, initWidth, defaultPanelHeight())
    panel.locked = locked
    panel.dragging = false
    panel.userWidth = savedWidth
    panel:initialise()
    panel:instantiate()
    panel.anchorLeft = true
    panel.anchorTop = true
    panel:addToUIManager()
    panel:reflowForDisplay()
    if panel.lockButton then
        panel.lockButton.title = panel.locked and tr("IGUI_CSR_Util_UnlockBtn", "Unlock") or tr("IGUI_CSR_Util_LockBtn", "Lock")
        panel.lockButton:setTooltip(panel.locked and tr("Tooltip_CSR_Util_UnlockBtn", "Unlock Utility HUD movement.") or tr("Tooltip_CSR_Util_LockBtn", "Lock Utility HUD movement."))
        CSR_Theme.applyButtonStyle(panel.lockButton, panel.locked and "accentAmber" or "accentBlue", panel.locked)
    end

    CSR_UtilityHud.panel = panel

    local modData = getPlayerModData()
    if modData and modData[MODDATA_HIDDEN] == true then
        panel:setVisible(false)
    end
end

local function destroyPanel()
    if not CSR_UtilityHud.panel then
        return
    end

    savePanelState(CSR_UtilityHud.panel)
    CSR_UtilityHud.panel:removeFromUIManager()
    CSR_UtilityHud.panel = nil
end

local function ensurePanel()
    if CSR_FeatureFlags.isUtilityHudEnabled() then
        createPanel()
    else
        destroyPanel()
    end
end

local function onGameStart()
    CSR_UtilityHud.standpipeState.nearby = false
    CSR_UtilityHud.standpipeState.amount = 0
    CSR_UtilityHud.standpipeState.nextScanTick = 0

    -- Load all per-player overrides (also migrates legacy DW modData key).
    if CSR_PlayerPrefs then
        CSR_PlayerPrefs.load()
    end

    ensurePanel()
end

local function onCreatePlayer()
    ensurePanel()
end

local function onResolutionChange()
    if not CSR_UtilityHud.panel then
        return
    end

    if CSR_Scale and CSR_Scale.refresh then
        CSR_Scale.refresh()
    end
    CSR_UtilityHud.panel:reflowForDisplay()
    savePanelState(CSR_UtilityHud.panel)
end

local function onKeyPressed(key)
    -- HUD visibility toggle
    if key == getHudBoundKey() and CSR_FeatureFlags.isUtilityHudEnabled() then
        local panel = CSR_UtilityHud.panel
        if panel then
            local visible = panel:getIsVisible()
            panel:setVisible(not visible)
            local modData = getPlayerModData()
            if modData then
                modData[MODDATA_HIDDEN] = visible == true
            end
        end
        return
    end

    -- Dual Wield toggle
    if key == getDwBoundKey() then
        if not CSR_FeatureFlags.isUtilityHudEnabled() then return end
        if CSR_FeatureFlags.isAdminAuthoritative() then return end
        CSR_PlayerPrefs.toggle("DualWield")
        local panel = CSR_UtilityHud.panel
        if panel and panel.updateDualWieldButton then
            panel:updateDualWieldButton()
        end
    end

    -- Survivor's Ledger toggle
    if key == getLedgerBoundKey() then
        if not CSR_FeatureFlags.isSurvivorLedgerEnabled() then return end
        CSR_PlayerPrefs.toggle("SurvivorLedger")
        local panel = CSR_UtilityHud.panel
        if panel and panel.updateLedgerButton then
            panel:updateLedgerButton()
        end
    end

    -- Nearby Density HUD show/hide toggle
    if key == getDensityBoundKey() then
        if not (CSR_FeatureFlags.isZombieDensityOverlayEnabled
                and CSR_FeatureFlags.isZombieDensityOverlayEnabled()) then
            return
        end
        if CSR_NearbyDensityHUD and CSR_NearbyDensityHUD.toggle then
            CSR_NearbyDensityHUD.toggle()
        end
        local panel = CSR_UtilityHud.panel
        if panel and panel.updateDensityHudButton then
            panel:updateDensityHudButton()
        end
    end
end

Events.OnGameStart.Add(onGameStart)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnResolutionChange.Add(onResolutionChange)
if Events.OnKeyPressed then Events.OnKeyPressed.Add(onKeyPressed) end

if CSR_Scale and CSR_Scale.onChange then
    CSR_Scale.onChange(function()
        local panel = CSR_UtilityHud.panel
        if panel and panel.reflowForDisplay then
            panel:reflowForDisplay()
        end
    end)
end

-- Receive item wipe schedule state from the server
local function onServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    if command == "ItemWipeStatus" then
        if not args then return end
        local ws = CSR_UtilityHud.itemWipeState
        ws.enabled          = true
        ws.remainingSeconds = tonumber(args.remainingSeconds) or 0
        ws.serverUpdateTime = os.time()
        ws.wiping           = args.wiping == true
    elseif command == "ItemWipeWarning" then
        if not args then return end
        local secs = tonumber(args.remainingSeconds) or 0
        local h = math.floor(secs / 3600)
        local m = math.floor((secs % 3600) / 60)
        local s = math.floor(secs % 60)
        local timeStr
        if h > 0 then
            timeStr = string.format("%dh %02dm", h, m)
        elseif m > 0 then
            timeStr = string.format("%dm %02ds", m, s)
        else
            timeStr = string.format("%ds", s)
        end
        local msg = string.format("[CSR] Ground item wipe in %s -- pick up loose loot now.", timeStr)
        if processGeneralMessage then
            processGeneralMessage("<RGB:1,0.6,0.2> " .. msg)
        end
        local p = getPlayerSafe()
        if p and p.setHaloNote then
            p:setHaloNote(msg, 255, 170, 50, 220)
        end
    end
end
if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end

return CSR_UtilityHud

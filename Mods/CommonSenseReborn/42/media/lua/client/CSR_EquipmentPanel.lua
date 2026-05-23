-- CSR_EquipmentPanel.lua
-- A side panel that anchors to the inventory window and renders all
-- worn items as overlay slots positioned over a live vanilla 3D
-- character model (ISUI3DModel). Click empty slot → choose item to
-- wear from inventory; click occupied slot → unequip; right-click →
-- full vanilla item context menu.
--
-- Inspired by the equipment-slot layout from the Equipment UI mod
-- (used with permission). The 3D viewport, slot overlay positions,
-- panel host, and click-to-equip flow are CSR's own implementation —
-- the original mod uses a static silhouette PNG and a complex
-- drag-drop system; we substitute the vanilla 3D model and a
-- simplified click-driven flow that still works in MP and split-screen.
require "ISUI/ISCollapsableWindow"
require "ISUI/ISUI3DModel"
require "ISUI/ISPanel"
require "ISUI/ISContextMenu"
require "Hotbar/ISHotbar"
require "CSR_FeatureFlags"
require "CSR_Theme"
require "CSR_Scale"

CSR_EquipmentPanel = CSR_EquipmentPanel or {}

local EQUIPMENT_PANEL_DEFAULT_KEY = Keyboard and Keyboard.KEY_NUMPAD1 or 79
local equipmentPanelKeyBind = nil
if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.create then
    local opts = PZAPI.ModOptions:create("CommonSenseRebornEquipmentPanel", "Common Sense Reborn - Equipment Panel")
    if opts and opts.addKeyBind then
        equipmentPanelKeyBind = opts:addKeyBind("toggleEquipmentPanel", "Toggle Equipment Panel", EQUIPMENT_PANEL_DEFAULT_KEY)
    end
end

local function getEquipmentPanelToggleKey()
    if equipmentPanelKeyBind and equipmentPanelKeyBind.getValue then
        return equipmentPanelKeyBind:getValue()
    end
    return EQUIPMENT_PANEL_DEFAULT_KEY
end

-- ─────────────────────────────────────────────────────
-- Layout / dock helpers
-- ─────────────────────────────────────────────────────
local DOCK_MODE_DOCKED   = "Docked"
local DOCK_MODE_FLOATING = "Floating"
local DOCK_MODE_DISABLED = "Disabled"

local function usesCleanUIEdgeMode()
    return CSR_FeatureFlags
        and CSR_FeatureFlags.isCleanUIActive
        and CSR_FeatureFlags.isCleanUIActive()
end

-- Sandbox enum index → string. Default = Docked.
local function getDockMode()
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or nil
    local v = sb and sb.EquipmentPanelDockMode or 1
    if v == 2 then return DOCK_MODE_FLOATING end
    if v == 3 then return DOCK_MODE_DISABLED end
    return DOCK_MODE_DOCKED
end

local function getLayoutModData(playerObj)
    if not playerObj then return { isDocked = true, isClosed = false } end
    local md = playerObj:getModData()
    md.csrEquipPanelLayout = md.csrEquipPanelLayout or { isDocked = true, isClosed = false }
    if md.csrEquipPanelLayout.isDocked == nil then md.csrEquipPanelLayout.isDocked = true end
    if md.csrEquipPanelLayout.isClosed == nil then md.csrEquipPanelLayout.isClosed = false end
    if md.csrEquipPanelLayout.cleanPinned == nil then md.csrEquipPanelLayout.cleanPinned = false end
    return md.csrEquipPanelLayout
end

local BASE_PANEL_W = 220
local BASE_PANEL_H = 540
local BASE_HEADER_H = 24
local BASE_CONTROLS_H = 24
local BASE_VIEW_PAD = 6
local BASE_SLOT_SIZE = 26
local BASE_EXTRAS_H = 150
local BASE_EXTRA_SLOT = 28
local BASE_HOTBAR_H = 64
local BASE_HOTBAR_SLOT = 28
local BASE_SECTION_GAP = 5
local BASE_EDGE_TAB_W = 30
local BASE_EDGE_TAB_H = 58
local BASE_SCREEN_MARGIN = 4

local function PANEL_W()      return CSR_Scale.px(BASE_PANEL_W) end
local function PANEL_H()      return CSR_Scale.px(BASE_PANEL_H) end
local function HEADER_H()     return CSR_Scale.px(BASE_HEADER_H) end
local function CONTROLS_H()   return CSR_Scale.px(BASE_CONTROLS_H) end
local function VIEW_PAD()     return CSR_Scale.px(BASE_VIEW_PAD) end
local function SLOT_SIZE()    return CSR_Scale.px(BASE_SLOT_SIZE) end
local function EXTRAS_H()     return CSR_Scale.px(BASE_EXTRAS_H) end
local function EXTRA_SLOT()   return CSR_Scale.px(BASE_EXTRA_SLOT) end
local function HOTBAR_H()     return CSR_Scale.px(BASE_HOTBAR_H) end
local function HOTBAR_SLOT()  return CSR_Scale.px(BASE_HOTBAR_SLOT) end
local function SECTION_GAP()  return CSR_Scale.px(BASE_SECTION_GAP) end
local function EDGE_TAB_W()   return CSR_Scale.px(BASE_EDGE_TAB_W) end
local function EDGE_TAB_H()   return CSR_Scale.px(BASE_EDGE_TAB_H) end

local function screenSize()
    local core = getCore and getCore()
    return core and core:getScreenWidth() or 1280,
        core and core:getScreenHeight() or 768
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function clampWindowPos(x, y, w, h)
    local sw, sh = screenSize()
    local margin = CSR_Scale.px(BASE_SCREEN_MARGIN)
    return clamp(math.floor(x or margin), margin, math.max(margin, sw - w - margin)),
        clamp(math.floor(y or margin), margin, math.max(margin, sh - h - margin))
end

local function defaultPanelPos(w, h)
    local sw = screenSize()
    return clampWindowPos(sw - w - CSR_Scale.px(16), CSR_Scale.px(80), w, h)
end

local function savedPanelPos(playerNum, w, h)
    local md = getLayoutModData(getSpecificPlayer(playerNum or 0))
    local x = tonumber(md.x)
    local y = tonumber(md.y)
    if x == nil or y == nil then
        return defaultPanelPos(w, h)
    end
    return clampWindowPos(x, y, w, h)
end

local function setBounds(child, x, y, w, h)
    if not child then return end
    child:setX(x)
    child:setY(y)
    if child.setWidth then child:setWidth(w) else child.width = w end
    if child.setHeight then child:setHeight(h) else child.height = h end
end

local function normalizeLocationName(value)
    local s = string.lower(tostring(value or ""))
    local colon = string.find(s, ":", 1, true)
    if colon then s = string.sub(s, colon + 1) end
    return s
end

local function itemTexture(item)
    if not item then return nil end
    if item.getTex then
        local tex = item:getTex()
        if tex then return tex end
    end
    if item.getTexture then
        return item:getTexture()
    end
    return nil
end

local function itemDisplayName(item)
    if not item then return "" end
    if item.getDisplayName then return item:getDisplayName() end
    if item.getName then return item:getName() end
    return tostring(item)
end

local function itemBodyLocation(item)
    if not item then return nil end
    local loc = item.getBodyLocation and item:getBodyLocation() or nil
    if loc and tostring(loc) ~= "" then return loc end
    if item.canBeEquipped then return item:canBeEquipped() end
    return nil
end

local function itemSignature(item)
    if not item then return "nil" end
    local id = item.getID and item:getID() or nil
    if id then return tostring(id) end
    local fullType = item.getFullType and item:getFullType() or itemDisplayName(item)
    return tostring(fullType) .. ":" .. tostring(item)
end

local function forEachInventoryItem(container, callback, visited)
    if not container or not container.getItems or not callback then return false end
    visited = visited or {}
    if visited[container] then return false end
    visited[container] = true

    local items = container:getItems()
    if not items or not items.size then return false end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            if callback(item) == true then return true end
            local child = item.getInventory and item:getInventory() or nil
            if child and child ~= container then
                if forEachInventoryItem(child, callback, visited) then return true end
            end
        end
    end
    return false
end

local function getDraggedItems()
    if not ISMouseDrag or not ISMouseDrag.dragging then return nil end
    if ISInventoryPane and ISInventoryPane.getActualItems then
        return ISInventoryPane.getActualItems(ISMouseDrag.dragging)
    end
    return ISMouseDrag.dragging
end

local function clearMouseDrag()
    if not ISMouseDrag then return end
    local sourcePane = ISMouseDrag.draggingFocus
    if sourcePane then
        sourcePane.selected = {}
        sourcePane.dragging = nil
        sourcePane.dragStarted = false
        sourcePane.draggingMarquis = false
    end
    ISMouseDrag.draggingFocus = nil
    ISMouseDrag.dragging = nil
end

local function slotAcceptsLocation(slot, location)
    if not slot or not slot.def or not slot.def.locs then return false end
    local loc = normalizeLocationName(location)
    if loc == "" then return false end
    for _, l in ipairs(slot.def.locs) do
        if normalizeLocationName(l) == loc then return true end
    end
    return false
end

local function slotAcceptsWearItem(slot, item)
    return item and slotAcceptsLocation(slot, itemBodyLocation(item))
end

local function saveLayout(panel)
    if not panel then return end
    local md = getLayoutModData(getSpecificPlayer(panel.playerNum or 0))
    md.isDocked = panel.isDocked == true
    md.isClosed = panel.isClosed == true
    md.cleanPinned = panel._cleanPinned == true
    if not panel.isDocked then
        md.x = math.floor(panel:getX())
        md.y = math.floor(panel:getY())
    end
    if panel.edgeTab then
        md.tabY = math.floor(panel.edgeTab:getY())
    end
end

-- Anchor positions are ratios of (viewport width, viewport height).
-- Each slot maps to one or more body locations; the first match wins.
local SLOT_LAYOUT = {
    { id = "head",     x = 0.50, y = 0.08, locs = { "Hat", "FullHat", "FullHelmet", "FullSuitHead" } },
    { id = "mask",     x = 0.50, y = 0.18, locs = { "Mask", "MaskEyes", "MaskFull", "Nose" } },
    { id = "eyes",     x = 0.30, y = 0.16, locs = { "Eyes" } },
    { id = "ears",     x = 0.70, y = 0.16, locs = { "Ears", "EarTop" } },
    { id = "neck",     x = 0.50, y = 0.26, locs = { "Neck", "Scarf" } },
    { id = "tshirt",   x = 0.50, y = 0.36, locs = { "Tshirt", "TankTop", "Underwear" } },
    { id = "shirt",    x = 0.30, y = 0.40, locs = { "Shirt", "ShortSleeveShirt", "Sweater" } },
    { id = "jacket",   x = 0.70, y = 0.40, locs = { "Jacket", "JacketHat", "TorsoExtra", "TorsoExtraVest" } },
    { id = "sling",    x = 0.18, y = 0.34, locs = { "csr:gearsling", "GearSling" } },
    { id = "hands",    x = 0.18, y = 0.50, locs = { "Hands" } },
    { id = "watch",    x = 0.82, y = 0.50, locs = { "LeftWrist", "RightWrist" } },
    { id = "belt",     x = 0.50, y = 0.55, locs = { "Belt", "BeltExtra", "Sheath", "AmmoStrap" } },
    { id = "fanny",    x = 0.72, y = 0.58, locs = { "FannyPackBack", "FannyPackFront", "csr:fannypack", "csr:fannypackback", "csr:fannypackfront" } },
    { id = "pants",    x = 0.50, y = 0.66, locs = { "Pants", "ShortPants", "Skirt", "UnderwearBottom" } },
    { id = "socks",    x = 0.50, y = 0.82, locs = { "Socks" } },
    { id = "shoes",    x = 0.50, y = 0.92, locs = { "Shoes" } },
    { id = "back",     x = 0.85, y = 0.30, locs = { "Back", "BackPack" } },
}

-- ─────────────────────────────────────────────────────
-- 3D model viewport
-- ─────────────────────────────────────────────────────
CSR_EquipmentModelView = ISUI3DModel:derive("CSR_EquipmentModelView")

function CSR_EquipmentModelView:new(x, y, w, h, playerNum)
    local o = ISUI3DModel.new(self, x, y, w, h)
    o.playerNum = playerNum or 0
    o.animateWhilePaused = true
    return o
end

-- Must be called AFTER instantiate() so javaObject exists.
function CSR_EquipmentModelView:bindToPlayer()
    self:refreshCharacter("idle", IsoDirections.S)
end

function CSR_EquipmentModelView:refreshCharacter(pose, direction)
    if not self.javaObject then return end
    local player = getSpecificPlayer(self.playerNum)
    if not player then return end
    local dir = direction
    if not dir and self.getDirection then
        dir = self:getDirection()
    end
    self:setCharacter(player)
    self:setAnimateWhilePaused(true)
    self:setIsometric(false)
    self:setDirection(dir or IsoDirections.S)
    self:setState(pose or "idle")
end

function CSR_EquipmentModelView:setPose(pose)
    if not self.javaObject then return end
    self:setState(pose)
end

-- Allow clicks to fall through to overlay slots above the model.
-- The base ISUI3DModel:onMouseDown enables drag-rotate, which we keep,
-- but we let slot panels override (they're added after, so they are
-- on top of the z-order and receive events first).

-- ─────────────────────────────────────────────────────
-- Slot
-- ─────────────────────────────────────────────────────
CSR_EquipmentSlot = ISPanel:derive("CSR_EquipmentSlot")

function CSR_EquipmentSlot:new(x, y, def, panel)
    local sz = SLOT_SIZE()
    local o = ISPanel.new(self, x, y, sz, sz)
    o.def = def
    o.panel = panel
    o.background = false
    o.item = nil
    return o
end

function CSR_EquipmentSlot:setItem(item)
    self.item = item
end

function CSR_EquipmentSlot:getDraggedWearable()
    local dragging = getDraggedItems()
    if not dragging then return nil end
    for _, item in ipairs(dragging) do
        if slotAcceptsWearItem(self, item) then
            return item
        end
    end
    return nil
end

function CSR_EquipmentSlot:render()
    local theme = CSR_Theme.colors
    local bd = theme.panelBorder
    local bg = theme.panelBg
    local accent = theme.accentViolet
    local hovered = self:isMouseOver()
    local draggedItem = hovered and self:getDraggedWearable() or nil

    -- Cell bg semi-transparent so the model shows through
    self:drawRect(0, 0, self.width, self.height, 0.55, bg.r, bg.g, bg.b)

    if self.item then
        local tex = itemTexture(self.item)
        if tex then
            self:drawTextureScaled(tex, 2, 2, self.width - 4, self.height - 4, 1.0, 1, 1, 1)
        end
        -- Filled border = accent
        self:drawRectBorder(0, 0, self.width, self.height, hovered and 1.0 or 0.85,
            accent.r, accent.g, accent.b)
    else
        -- Empty slot: faint border, label = first body location
        self:drawRectBorder(0, 0, self.width, self.height, hovered and 0.85 or 0.45,
            bd.r, bd.g, bd.b)
        if hovered then
            local tm = getTextManager()
            local label = self.def.locs[1] or self.def.id
            local tw = tm:MeasureStringX(UIFont.Tiny, label)
            self:drawText(label, math.floor((self.width - tw) / 2),
                math.floor((self.height - tm:getFontHeight(UIFont.Tiny)) / 2),
                1, 1, 1, 0.95, UIFont.Tiny)
        end
    end

    if hovered and ISMouseDrag and ISMouseDrag.dragging then
        if draggedItem then
            self:drawRect(0, 0, self.width, self.height, 0.18, 0.35, 0.78, 0.52)
            self:drawRectBorder(0, 0, self.width, self.height, 1.0, 0.35, 0.78, 0.52)
        else
            self:drawRect(0, 0, self.width, self.height, 0.16, 0.95, 0.20, 0.18)
        end
    end
end

function CSR_EquipmentSlot:onMouseDown(x, y)
    self._down = true
    return true
end

function CSR_EquipmentSlot:onMouseUp(x, y)
    if not self._down then return true end
    self._down = false
    local draggedItem = self:getDraggedWearable()
    if draggedItem then
        ISInventoryPaneContextMenu.wearItem(draggedItem, self.panel.playerNum)
        clearMouseDrag()
        if self.panel and self.panel.markDirty then
            self.panel:markDirty(true)
        end
        return true
    end
    if self.item then
        -- Click occupied slot = unequip
        ISInventoryPaneContextMenu.unequipItem(self.item, self.panel.playerNum)
        if self.panel and self.panel.markDirty then
            self.panel:markDirty(true)
        end
    else
        -- Click empty slot = pick a wearable item
        self.panel:openWearMenuForSlot(self, x, y)
    end
    return true
end

function CSR_EquipmentSlot:onMouseUpOutside(x, y)
    self._down = false
end

function CSR_EquipmentSlot:onRightMouseUp(x, y)
    if self.item then
        if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu then
            ISInventoryPaneContextMenu.createMenu(self.panel.playerNum, true, { self.item },
                self:getAbsoluteX() + x, self:getAbsoluteY() + y)
        else
            local context = ISContextMenu.get(self.panel.playerNum,
                self:getAbsoluteX() + x, self:getAbsoluteY() + y)
            if not context then return true end
            context:addOption(getText("ContextMenu_Unequip"), self.item, function(it)
                ISInventoryPaneContextMenu.unequipItem(it, self.panel.playerNum)
            end)
        end
    else
        self.panel:openWearMenuForSlot(self, x, y)
    end
    return true
end

-- ─────────────────────────────────────────────────────
-- Window
-- ─────────────────────────────────────────────────────
CSR_EquipmentHotbarSlot = ISPanel:derive("CSR_EquipmentHotbarSlot")

function CSR_EquipmentHotbarSlot:new(x, y, panel)
    local sz = HOTBAR_SLOT()
    local o = ISPanel.new(self, x, y, sz, sz)
    o.panel = panel
    o.background = false
    o.hotbar = nil
    o.hotbarIndex = nil
    return o
end

function CSR_EquipmentHotbarSlot:setHotbarSlot(hotbar, index)
    self.hotbar = hotbar
    self.hotbarIndex = index
end

function CSR_EquipmentHotbarSlot:getSlot()
    if not self.hotbar or not self.hotbar.availableSlot or not self.hotbarIndex then return nil end
    return self.hotbar.availableSlot[self.hotbarIndex]
end

function CSR_EquipmentHotbarSlot:getItem()
    if not self.hotbar or not self.hotbar.attachedItems or not self.hotbarIndex then return nil end
    return self.hotbar.attachedItems[self.hotbarIndex]
end

function CSR_EquipmentHotbarSlot:getSlotName()
    local slot = self:getSlot()
    if not slot then return "" end
    return getTextOrNull("IGUI_HotbarAttachment_" .. tostring(slot.slotType)) or slot.name or tostring(self.hotbarIndex)
end

function CSR_EquipmentHotbarSlot:getAttachModel(item)
    local slot = self:getSlot()
    local slotDef = slot and slot.def or nil
    if not item or not item.getAttachmentType or not slotDef or not slotDef.attachments then return nil end
    return slotDef.attachments[item:getAttachmentType()]
end

function CSR_EquipmentHotbarSlot:canAttachItem(item)
    local slot = self:getSlot()
    if not item or not slot or not self.hotbar then return false end
    if not slot.def or not slot.def.attachments then return false end
    if item.isBroken and item:isBroken() then return false end
    if not item.getAttachmentType or not item:getAttachmentType() then return false end
    if self.hotbar.canBeAttached then
        return self.hotbar:canBeAttached(slot, item) == true
    end
    return self:getAttachModel(item) ~= nil
end

function CSR_EquipmentHotbarSlot:getDraggedAttachable()
    local dragging = getDraggedItems()
    if not dragging then return nil end
    for _, item in ipairs(dragging) do
        if item ~= self:getItem() and self:canAttachItem(item) then
            return item
        end
    end
    return nil
end

function CSR_EquipmentHotbarSlot:attachItem(item)
    if not item or not self.hotbar or not self.hotbar.attachItem then return false end
    local slot = self:getSlot()
    local slotDef = slot and slot.def or nil
    local model = self:getAttachModel(item)
    if not slotDef or not model then return false end
    self.hotbar:attachItem(item, model, self.hotbarIndex, slotDef, true)
    if self.panel and self.panel.markDirty then
        self.panel:markDirty(false)
    end
    return true
end

function CSR_EquipmentHotbarSlot:render()
    local theme = CSR_Theme.colors
    local bd = theme.panelBorder
    local bg = theme.panelBg
    local accent = theme.accentViolet
    local hovered = self:isMouseOver()
    local draggedItem = hovered and self:getDraggedAttachable() or nil
    local item = self:getItem()
    local slot = self:getSlot()

    self:drawRect(0, 0, self.width, self.height, 0.55, bg.r, bg.g, bg.b)
    self:drawRectBorder(0, 0, self.width, self.height, hovered and 0.9 or 0.45,
        bd.r, bd.g, bd.b)

    if self.hotbarIndex then
        self:drawText(tostring(self.hotbarIndex), CSR_Scale.px(2), CSR_Scale.px(1),
            1, 1, 1, 0.85, UIFont.Tiny)
    end

    if item then
        local tex = itemTexture(item)
        if tex then
            self:drawTextureScaled(tex, CSR_Scale.px(4), CSR_Scale.px(4),
                self.width - CSR_Scale.px(8), self.height - CSR_Scale.px(8),
                1.0, 1, 1, 1)
        end
        self:drawRectBorder(0, 0, self.width, self.height, hovered and 1.0 or 0.85,
            accent.r, accent.g, accent.b)
    elseif slot and slot.texture then
        self:drawTextureScaled(slot.texture, CSR_Scale.px(5), CSR_Scale.px(5),
            self.width - CSR_Scale.px(10), self.height - CSR_Scale.px(10),
            0.28, 1, 1, 1)
    end

    if hovered and ISMouseDrag and ISMouseDrag.dragging then
        if draggedItem then
            self:drawRect(0, 0, self.width, self.height, 0.18, 0.35, 0.78, 0.52)
            self:drawRectBorder(0, 0, self.width, self.height, 1.0, 0.35, 0.78, 0.52)
        else
            self:drawRect(0, 0, self.width, self.height, 0.16, 0.95, 0.20, 0.18)
        end
    end
end

function CSR_EquipmentHotbarSlot:onMouseDown(x, y)
    self._down = true
    return true
end

function CSR_EquipmentHotbarSlot:onMouseUp(x, y)
    if not self._down then return true end
    self._down = false
    local draggedItem = self:getDraggedAttachable()
    if draggedItem and self:attachItem(draggedItem) then
        clearMouseDrag()
        return true
    end

    local item = self:getItem()
    if item and self.hotbar and self.hotbar.activateSlot then
        if not self.hotbar.isAllowedToActivateSlot or self.hotbar:isAllowedToActivateSlot() then
            self.hotbar:activateSlot(self.hotbarIndex)
        end
    elseif self.panel and self.panel.openHotbarAttachMenuForSlot then
        self.panel:openHotbarAttachMenuForSlot(self, x, y)
    end
    return true
end

function CSR_EquipmentHotbarSlot:onMouseUpOutside(x, y)
    self._down = false
end

function CSR_EquipmentHotbarSlot:onRightMouseUp(x, y)
    local item = self:getItem()
    if item and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu then
        ISInventoryPaneContextMenu.createMenu(self.panel.playerNum, true, { item },
            self:getAbsoluteX() + x, self:getAbsoluteY() + y)
    elseif self.panel and self.panel.openHotbarAttachMenuForSlot then
        self.panel:openHotbarAttachMenuForSlot(self, x, y)
    end
    return true
end

CSR_EquipmentPanelWindow = ISCollapsableWindow:derive("CSR_EquipmentPanelWindow")

function CSR_EquipmentPanelWindow:new(playerNum)
    local pw, ph = PANEL_W(), PANEL_H()
    local x, y = savedPanelPos(playerNum or 0, pw, ph)
    local o = ISCollapsableWindow.new(self, x, y, pw, ph)
    o.playerNum = playerNum or 0
    o.title = getText("IGUI_CSR_Equipment_Title") or "Equipment"
    o.resizable = false
    o.slots = {}
    o.hotbarSlots = {}
    o.hotbarSlotPool = {}
    o.refreshTick = 0
    o.use3D = true
    o.pose = "idle"
    o._needsSlotRefresh = true
    o._needsModelRefresh = true
    -- Docked mode = follow the inventory window. Floating = free.
    local mode = getDockMode()
    local md = getLayoutModData(getSpecificPlayer(o.playerNum))
    o.isCleanUIEdgeMode = usesCleanUIEdgeMode()
    if o.isCleanUIEdgeMode or mode == DOCK_MODE_FLOATING then
        o.isDocked = false
    else
        -- Default behaviour: respect saved preference, else dock.
        o.isDocked = md.isDocked ~= false
    end
    o.isClosed = md.isClosed == true
    o._cleanPinned = md.cleanPinned == true
    o._closedForInventorySession = false
    return o
end

function CSR_EquipmentPanelWindow:getLayoutAreas()
    local pad = VIEW_PAD()
    local headerH = HEADER_H()
    local controlsH = CONTROLS_H()
    local viewX = pad
    local viewY = headerH + controlsH + pad
    local viewW = self.width - pad * 2
    local bottomH = EXTRAS_H()
    local hotbarH = HOTBAR_H()
    local gap = SECTION_GAP()
    local extrasH = math.max(EXTRA_SLOT(), bottomH - hotbarH - gap)
    local viewH = self.height - viewY - bottomH - pad * 2

    return {
        pad = pad,
        headerH = headerH,
        controlsH = controlsH,
        viewX = viewX,
        viewY = viewY,
        viewW = viewW,
        viewH = viewH,
        extrasX = pad,
        extrasY = viewY + viewH + pad,
        extrasW = self.width - pad * 2,
        extrasH = extrasH,
        hotbarX = pad,
        hotbarY = viewY + viewH + pad + extrasH + gap,
        hotbarW = self.width - pad * 2,
        hotbarH = hotbarH,
    }
end

function CSR_EquipmentPanelWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local areas = self:getLayoutAreas()
    local pad = areas.pad
    local headerH = areas.headerH
    local controlsH = areas.controlsH
    local slotSz = SLOT_SIZE()

    -- 3D model. Order matters: addChild triggers instantiate, then we
    -- can safely bind the live player character to the viewport.
    self.modelView = CSR_EquipmentModelView:new(areas.viewX, areas.viewY, areas.viewW, areas.viewH, self.playerNum)
    self:addChild(self.modelView)
    self.modelView:bindToPlayer()

    -- Pose dropdown / rotate buttons (top control row)
    local btnY = headerH + CSR_Scale.px(2)
    local btnH = controlsH - CSR_Scale.px(4)
    local btnSide = CSR_Scale.px(22)
    self.btnRotateLeft = ISButton:new(pad, btnY, btnSide, btnH, "<", self, function(_, btn)
        if self.modelView and self.modelView.javaObject then
            local d = self.modelView:getDirection()
            if d then self.modelView:setDirection(IsoDirectionSet.rotate(d, -1)) end
        end
    end)
    self.btnRotateLeft:initialise()
    self:addChild(self.btnRotateLeft)

    self.btnRotateRight = ISButton:new(self.width - pad - btnSide, btnY, btnSide, btnH, ">", self, function(_, btn)
        if self.modelView and self.modelView.javaObject then
            local d = self.modelView:getDirection()
            if d then self.modelView:setDirection(IsoDirectionSet.rotate(d, 1)) end
        end
    end)
    self.btnRotateRight:initialise()
    self:addChild(self.btnRotateRight)

    self.btnPose = ISButton:new(pad + btnSide + CSR_Scale.px(4), btnY,
        self.width - pad * 2 - (btnSide + CSR_Scale.px(4)) * 2, btnH,
        getText("IGUI_CSR_Equipment_PoseIdle"), self, function(_, btn)
            self:cyclePose()
        end)
    self.btnPose:initialise()
    self:addChild(self.btnPose)

    -- Popout / Attach toggle. Placed in the body (below the title
    -- bar) instead of overlapping the bar — clicks inside the title
    -- bar always start a drag in ISCollapsableWindow, which made the
    -- popout look like "the arrow only drags the window".
    local popSide = CSR_Scale.px(16)
    self.btnPopout = ISButton:new(self.width - pad - popSide,
        headerH + CSR_Scale.px(2), popSide, popSide,
        self.isCleanUIEdgeMode and "<" or (self.isDocked and "<" or ">"),
        self, CSR_EquipmentPanelWindow.onPopoutOrAttach)
    self.btnPopout.borderColor = { r = 0.6, g = 0.45, b = 0.95, a = 1 }
    self.btnPopout.backgroundColor = { r = 0, g = 0, b = 0, a = 0.4 }
    self.btnPopout.backgroundColorMouseOver = { r = 0.4, g = 0.3, b = 0.65, a = 0.8 }
    self.btnPopout:initialise()
    self.btnPopout:setAnchorRight(true)
    self.btnPopout:setAnchorLeft(false)
    self.btnPopout:setAnchorTop(true)
    self:addChild(self.btnPopout)

    -- Build slots (overlaid on the 3D viewport)
    for _, def in ipairs(SLOT_LAYOUT) do
        local sx = areas.viewX + math.floor(areas.viewW * def.x - slotSz / 2)
        local sy = areas.viewY + math.floor(areas.viewH * def.y - slotSz / 2)
        local slot = CSR_EquipmentSlot:new(sx, sy, def, self)
        slot:initialise()
        slot:instantiate()
        self:addChild(slot)
        self.slots[def.id] = slot
    end

    -- Extras strip: any worn items whose body location is NOT matched
    -- by one of the silhouette overlay slots (FannyPack, AmmoStrap,
    -- TorsoExtra variants, accessory slots from clothing mods, etc.).
    -- Drawn as a horizontal grid of small boxes below the viewport.
    self.extrasArea = {
        x = areas.extrasX,
        y = areas.extrasY,
        w = areas.extrasW,
        h = areas.extrasH,
    }
    self.hotbarArea = {
        x = areas.hotbarX,
        y = areas.hotbarY,
        w = areas.hotbarW,
        h = areas.hotbarH,
    }
    self.extraSlots = {}
    self.extraSlotPool = {}
    self.hotbarSlots = {}
    self.hotbarSlotPool = {}

    self:refreshSlots()
end

function CSR_EquipmentPanelWindow:reflowForDisplay()
    local pw, ph = PANEL_W(), PANEL_H()
    if self.setWidth then self:setWidth(pw) else self.width = pw end
    if self.setHeight then self:setHeight(ph) else self.height = ph end

    if not self.isDocked then
        local x, y = clampWindowPos(self:getX(), self:getY(), pw, ph)
        self:setX(x)
        self:setY(y)
    end

    local areas = self:getLayoutAreas()
    local pad = areas.pad
    local headerH = areas.headerH
    local controlsH = areas.controlsH
    local slotSz = SLOT_SIZE()

    setBounds(self.modelView, areas.viewX, areas.viewY, areas.viewW, areas.viewH)

    local btnY = headerH + CSR_Scale.px(2)
    local btnH = controlsH - CSR_Scale.px(4)
    local btnSide = CSR_Scale.px(22)
    setBounds(self.btnRotateLeft, pad, btnY, btnSide, btnH)
    setBounds(self.btnRotateRight, self.width - pad - btnSide, btnY, btnSide, btnH)
    setBounds(self.btnPose, pad + btnSide + CSR_Scale.px(4), btnY,
        self.width - pad * 2 - (btnSide + CSR_Scale.px(4)) * 2, btnH)

    local popSide = CSR_Scale.px(16)
    setBounds(self.btnPopout, self.width - pad - popSide,
        headerH + CSR_Scale.px(2), popSide, popSide)
    if self.btnPopout then
        self.btnPopout:setTitle(self.isCleanUIEdgeMode and "<" or (self.isDocked and "<" or ">"))
    end

    for _, def in ipairs(SLOT_LAYOUT) do
        local slot = self.slots and self.slots[def.id]
        if slot then
            local sx = areas.viewX + math.floor(areas.viewW * def.x - slotSz / 2)
            local sy = areas.viewY + math.floor(areas.viewH * def.y - slotSz / 2)
            setBounds(slot, sx, sy, slotSz, slotSz)
        end
    end

    self.extrasArea = {
        x = areas.extrasX,
        y = areas.extrasY,
        w = areas.extrasW,
        h = areas.extrasH,
    }
    self.hotbarArea = {
        x = areas.hotbarX,
        y = areas.hotbarY,
        w = areas.hotbarW,
        h = areas.hotbarH,
    }
    self:refreshSlots()
    if self.edgeTab and self.edgeTab.syncToWindow then
        self.edgeTab:syncToWindow()
    end
end

function CSR_EquipmentPanelWindow:_acquireExtraSlot(idx)
    local slot = self.extraSlots[idx]
    if slot then return slot end
    -- Reuse from pool when possible (worn-item churn shouldn't leak).
    if #self.extraSlotPool > 0 then
        slot = table.remove(self.extraSlotPool)
    else
        slot = CSR_EquipmentSlot:new(0, 0,
            { id = "extra" .. idx, locs = { "" } }, self)
        slot:initialise()
        slot:instantiate()
        self:addChild(slot)
    end
    self.extraSlots[idx] = slot
    return slot
end

function CSR_EquipmentPanelWindow:_releaseExtraSlot(idx)
    local slot = self.extraSlots[idx]
    if not slot then return end
    slot:setVisible(false)
    slot:setItem(nil)
    self.extraSlots[idx] = nil
    table.insert(self.extraSlotPool, slot)
end

function CSR_EquipmentPanelWindow:_acquireHotbarSlot(idx)
    self.hotbarSlots = self.hotbarSlots or {}
    self.hotbarSlotPool = self.hotbarSlotPool or {}
    local slot = self.hotbarSlots[idx]
    if slot then return slot end
    if #self.hotbarSlotPool > 0 then
        slot = table.remove(self.hotbarSlotPool)
    else
        slot = CSR_EquipmentHotbarSlot:new(0, 0, self)
        slot:initialise()
        slot:instantiate()
        self:addChild(slot)
    end
    self.hotbarSlots[idx] = slot
    return slot
end

function CSR_EquipmentPanelWindow:_releaseHotbarSlot(idx)
    local slot = self.hotbarSlots and self.hotbarSlots[idx] or nil
    if not slot then return end
    slot:setVisible(false)
    slot:setHotbarSlot(nil, nil)
    self.hotbarSlots[idx] = nil
    self.hotbarSlotPool = self.hotbarSlotPool or {}
    table.insert(self.hotbarSlotPool, slot)
end

function CSR_EquipmentPanelWindow:cyclePose()
    local poses = { "idle", "aim", "sprint" }
    local idx = 1
    for i, p in ipairs(poses) do if p == self.pose then idx = i; break end end
    idx = (idx % #poses) + 1
    self.pose = poses[idx]
    if self.modelView then self.modelView:setPose(self.pose) end
    if self.btnPose then
        local key = "IGUI_CSR_Equipment_Pose" .. self.pose:sub(1,1):upper() .. self.pose:sub(2)
        self.btnPose:setTitle(getText(key))
    end
end

function CSR_EquipmentPanelWindow:markDirty(refreshModel)
    self._needsSlotRefresh = true
    if refreshModel then
        self._needsModelRefresh = true
    end
end

function CSR_EquipmentPanelWindow:refreshModelView()
    if not self.modelView or not self.modelView.refreshCharacter then return end
    self.modelView:refreshCharacter(self.pose or "idle")
end

function CSR_EquipmentPanelWindow:refreshHotbarSlots()
    local hotbar = getPlayerHotbar and getPlayerHotbar(self.playerNum) or nil
    if not self.hotbarArea or not hotbar or not hotbar.availableSlot then
        for idx, _ in pairs(self.hotbarSlots or {}) do
            self:_releaseHotbarSlot(idx)
        end
        return
    end

    local indices = {}
    for index, slot in pairs(hotbar.availableSlot) do
        if type(index) == "number" and slot then
            indices[#indices + 1] = index
        end
    end
    table.sort(indices)

    local margin = CSR_Scale.px(3)
    local size = HOTBAR_SLOT()
    local cols = math.max(1, math.floor((self.hotbarArea.w + margin) / (size + margin)))
    local rows = math.max(1, math.ceil(#indices / cols))
    local neededH = rows * size + (rows - 1) * margin
    if neededH > self.hotbarArea.h then
        size = math.max(CSR_Scale.px(18), math.floor((self.hotbarArea.h - (rows - 1) * margin) / rows))
        cols = math.max(1, math.floor((self.hotbarArea.w + margin) / (size + margin)))
    end

    for pos, hotbarIndex in ipairs(indices) do
        local col = (pos - 1) % cols
        local row = math.floor((pos - 1) / cols)
        local slot = self:_acquireHotbarSlot(pos)
        slot:setHotbarSlot(hotbar, hotbarIndex)
        slot:setX(self.hotbarArea.x + col * (size + margin))
        slot:setY(self.hotbarArea.y + row * (size + margin))
        slot:setWidth(size)
        slot:setHeight(size)
        slot:setVisible(true)
    end

    for idx, _ in pairs(self.hotbarSlots or {}) do
        if idx > #indices then
            self:_releaseHotbarSlot(idx)
        end
    end
end

function CSR_EquipmentPanelWindow:refreshSlots()
    local player = getSpecificPlayer(self.playerNum)
    if not player then return end
    self._needsSlotRefresh = false
    -- Clear current items
    for _, slot in pairs(self.slots) do slot:setItem(nil) end

    local extras = {}
    local signature = {}
    local worn = player:getWornItems()
    if worn then
        for i = 0, worn:size() - 1 do
            local entry = worn:get(i)
            local item = entry and entry:getItem() or nil
            local loc = entry and entry:getLocation() or nil
            local hidden = item and item.isHidden and item:isHidden() or false
            if item and loc and not hidden then
                local locStr = normalizeLocationName(loc)
                signature[#signature + 1] = locStr .. "=" .. itemSignature(item)
                local placed = false
                for _, def in ipairs(SLOT_LAYOUT) do
                    if slotAcceptsLocation({ def = def }, locStr) then
                        if self.slots[def.id] and not self.slots[def.id].item then
                            self.slots[def.id]:setItem(item)
                            placed = true
                        end
                        break
                    end
                    if placed then break end
                end
                if not placed then
                    extras[#extras + 1] = { item = item, loc = locStr }
                end
            end
        end
    end

    local wornSignature = table.concat(signature, "|")
    if self._needsModelRefresh or self._wornSignature ~= wornSignature then
        self._wornSignature = wornSignature
        self._needsModelRefresh = false
        self:refreshModelView()
    end

    -- Lay out extras grid
    if self.extrasArea then
        local size = EXTRA_SLOT()
        local margin = CSR_Scale.px(3)
        local cols = math.max(1, math.floor((self.extrasArea.w + margin) / (size + margin)))
        local x0 = self.extrasArea.x
        local y0 = self.extrasArea.y
        for i, e in ipairs(extras) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local slot = self:_acquireExtraSlot(i)
            slot.def = { id = "extra" .. i, locs = { e.loc } }
            slot:setX(x0 + col * (size + margin))
            slot:setY(y0 + row * (size + margin))
            slot:setWidth(size)
            slot:setHeight(size)
            slot:setItem(e.item)
            slot:setVisible(true)
        end
        -- Free unused
        for idx, _ in pairs(self.extraSlots) do
            if idx > #extras then self:_releaseExtraSlot(idx) end
        end
    end
    self:refreshHotbarSlots()
end

function CSR_EquipmentPanelWindow:openWearMenuForSlot(slot, mx, my)
    local player = getSpecificPlayer(self.playerNum)
    if not player then return end
    local inv = player:getInventory()
    if not inv then return end

    local context = ISContextMenu.get(self.playerNum,
        slot:getAbsoluteX() + mx, slot:getAbsoluteY() + my)
    if not context then return end

    local found = 0
    forEachInventoryItem(inv, function(item)
        if item and slotAcceptsWearItem(slot, item)
            and (not player.isEquippedClothing or not player:isEquippedClothing(item)) then
            found = found + 1
            local option = context:addOption(itemDisplayName(item), item, function(it)
                ISInventoryPaneContextMenu.wearItem(it, self.playerNum)
                self:markDirty(true)
            end)
            option.itemForTexture = item
        end
        return false
    end)
    if found == 0 then
        local opt = context:addOption(getText("IGUI_CSR_Equipment_NoMatchingItem") or "No matching item", nil, nil)
        opt.notAvailable = true
    end
end

function CSR_EquipmentPanelWindow:openHotbarAttachMenuForSlot(slot, mx, my)
    local player = getSpecificPlayer(self.playerNum)
    if not player or not slot then return end
    local inv = player:getInventory()
    if not inv then return end

    local context = ISContextMenu.get(self.playerNum,
        slot:getAbsoluteX() + mx, slot:getAbsoluteY() + my)
    if not context then return end

    local found = 0
    forEachInventoryItem(inv, function(item)
        local attachedSlot = item and item.getAttachedSlot and item:getAttachedSlot() or -1
        if item and attachedSlot == -1 and slot:canAttachItem(item) then
            local model = slot:getAttachModel(item)
            if model then
                found = found + 1
                local option = context:addOption(itemDisplayName(item), item, function(it)
                    slot:attachItem(it)
                    self:markDirty(false)
                end)
                option.itemForTexture = item
            end
        end
        return false
    end)
    if found == 0 then
        local opt = context:addOption(getText("ContextMenu_NoWeaponsAvailable"), nil, nil)
        opt.notAvailable = true
    end
end

function CSR_EquipmentPanelWindow:prerender()
    self._scalePoll = (self._scalePoll or 0) + 1
    if self._scalePoll >= 30 then
        self._scalePoll = 0
        if CSR_Scale and CSR_Scale.refresh then
            CSR_Scale.refresh()
        end
    end

    local factor = CSR_Scale and CSR_Scale.factor and CSR_Scale.factor() or 1.0
    if self._lastScaleFactor ~= factor then
        self._lastScaleFactor = factor
        self:reflowForDisplay()
    end

    -- Re-dock to the inventory window every frame BEFORE the parent
    -- prerender draws so the panel never appears at its stale layout-
    -- manager position. Mirrors the source mod's docked prerender.
    local invPage = self._linkedInvPage
    if self.isDocked and invPage and invPage:getIsVisible() then
        local pw = self:getWidth()
        local gap = CSR_Scale.px(4)
        -- Inventory window's bag-tab buttons sit on its LEFT exterior
        -- edge. If we dock flush to invPage:getX() the panel covers
        -- that column and swallows left-clicks on every bag tab (right
        -- clicks fall through, which is why the symptom was "I can
        -- right-click but not left-click my worn bags"). Clear the
        -- column width before placing the panel.
        local tabCol = tonumber(invPage.buttonSize) or 0
        if tabCol <= 0 then tabCol = CSR_Scale.px(32) end
        local desiredX = invPage:getX() - tabCol - pw - gap
        if desiredX < 0 then
            -- Not enough room on the left -- dock on the right instead.
            desiredX = invPage:getX() + invPage:getWidth() + gap
        end
        self:setX(desiredX)
        self:setY(invPage:getY())
    end

    ISCollapsableWindow.prerender(self)
    self.refreshTick = self.refreshTick + 1
    if self._needsSlotRefresh or self.refreshTick >= 30 then
        self.refreshTick = 0
        self:refreshSlots()
    end

    -- When docked, mirror the inventory page's visibility every frame.
    -- A manual close/hotkey hide only lasts for the current inventory-open
    -- session; opening inventory again brings the panel back with it.
    if self.isDocked and invPage then
        local invVis = invPage:getIsVisible() and not invPage.isCollapsed
        if not invVis then
            self._closedForInventorySession = false
        end
        local shouldShow = invVis and not self._closedForInventorySession
        if shouldShow ~= self:getIsVisible() then
            self:setVisible(shouldShow)
        end
    end
end

function CSR_EquipmentPanelWindow:onPopoutOrAttach()
    if self.isCleanUIEdgeMode then
        self._cleanPinned = false
        self.isClosed = true
        self:setVisible(false)
        saveLayout(self)
        return
    end

    self.isDocked = not self.isDocked
    if self.btnPopout then
        self.btnPopout:setTitle(self.isDocked and "<" or ">")
    end
    -- Persist preference.
    local md = getLayoutModData(getSpecificPlayer(self.playerNum))
    md.isDocked = self.isDocked
    if not self.isDocked then
        -- Pop out: nudge slightly so the player can see we detached.
        self:setX(math.max(0, self:getX() - CSR_Scale.px(8)))
    end
    saveLayout(self)
end

function CSR_EquipmentPanelWindow:close()
    if self.isCleanUIEdgeMode then
        self._cleanPinned = false
        self.isClosed = true
        self:setVisible(false)
        saveLayout(self)
        return
    end

    if self.isDocked then
        self._closedForInventorySession = true
        self:setVisible(false)
        return
    end
    self.isClosed = true
    local md = getLayoutModData(getSpecificPlayer(self.playerNum))
    md.isClosed = true
    saveLayout(self)
    ISCollapsableWindow.close(self)
end

function CSR_EquipmentPanelWindow:render()
    ISCollapsableWindow.render(self)
end

function CSR_EquipmentPanelWindow:onMouseUp(x, y)
    local ret = nil
    if ISCollapsableWindow.onMouseUp then
        ret = ISCollapsableWindow.onMouseUp(self, x, y)
    end
    if not self.isDocked then
        saveLayout(self)
        if self.edgeTab and self.edgeTab.syncToWindow then
            self.edgeTab:syncToWindow()
        end
    end
    return ret
end

function CSR_EquipmentPanelWindow:onMouseUpOutside(x, y)
    local ret = nil
    if ISCollapsableWindow.onMouseUpOutside then
        ret = ISCollapsableWindow.onMouseUpOutside(self, x, y)
    end
    if not self.isDocked then
        saveLayout(self)
        if self.edgeTab and self.edgeTab.syncToWindow then
            self.edgeTab:syncToWindow()
        end
    end
    return ret
end

-- ─────────────────────────────────────────────────────
-- Lifecycle / hook into inventory page toggle
-- ─────────────────────────────────────────────────────
local showCleanUIEdgePanel = nil

CSR_EquipmentEdgeTab = ISPanel:derive("CSR_EquipmentEdgeTab")

function CSR_EquipmentEdgeTab:new(playerNum)
    local tw, th = EDGE_TAB_W(), EDGE_TAB_H()
    local sw, sh = screenSize()
    local md = getLayoutModData(getSpecificPlayer(playerNum or 0))
    local y = tonumber(md.tabY) or tonumber(md.y) or CSR_Scale.px(80)
    local margin = CSR_Scale.px(BASE_SCREEN_MARGIN)
    y = clamp(y, margin, math.max(margin, sh - th - margin))
    local o = ISPanel.new(self, sw - tw, y, tw, th)
    o.playerNum = playerNum or 0
    o.background = false
    return o
end

function CSR_EquipmentEdgeTab:syncToWindow()
    local tw, th = EDGE_TAB_W(), EDGE_TAB_H()
    local sw, sh = screenSize()
    local margin = CSR_Scale.px(BASE_SCREEN_MARGIN)
    local y = self:getY()
    if self.window then
        y = self.window:getY() + HEADER_H()
    else
        local md = getLayoutModData(getSpecificPlayer(self.playerNum or 0))
        y = tonumber(md.tabY) or tonumber(md.y) or y
    end
    y = clamp(y, margin, math.max(margin, sh - th - margin))
    setBounds(self, sw - tw, y, tw, th)
end

function CSR_EquipmentEdgeTab:prerender()
    ISPanel.prerender(self)
    self:syncToWindow()
    if self:isMouseOver() and showCleanUIEdgePanel then
        showCleanUIEdgePanel(self.playerNum, false)
    end
end

function CSR_EquipmentEdgeTab:render()
    ISPanel.render(self)
    local theme = CSR_Theme.colors
    local bg = theme.panelHeader
    local bd = theme.panelBorder
    local accent = theme.accentViolet
    self:drawRect(0, 0, self.width, self.height, 0.88, bg.r, bg.g, bg.b)
    self:drawRectBorder(0, 0, self.width, self.height, 1.0, accent.r, accent.g, accent.b)
    local mgr = getTextManager()
    local label = "EQ"
    local font = UIFont.Small
    local textW = mgr and mgr:MeasureStringX(font, label) or 16
    local textH = mgr and mgr:getFontHeight(font) or 14
    self:drawText(label, math.floor((self.width - textW) / 2), math.floor((self.height - textH) / 2),
        1, 1, 1, 0.95, font)
    self:drawRectBorder(1, 1, self.width - 2, self.height - 2, 0.7, bd.r, bd.g, bd.b)
end

function CSR_EquipmentEdgeTab:onMouseDown(x, y)
    if showCleanUIEdgePanel then
        showCleanUIEdgePanel(self.playerNum, false)
    end
    return true
end

local windows = {}
local edgeTabs = {}

local function ensureEdgeTab(playerNum)
    local pn = playerNum or 0
    if not usesCleanUIEdgeMode() then return nil end
    if not CSR_FeatureFlags.isEquipmentPanelEnabled() then return nil end
    if getDockMode() == DOCK_MODE_DISABLED then return nil end
    if rawget(_G, "EquipmentUIWindow") then return nil end
    if edgeTabs[pn] then
        edgeTabs[pn].window = windows[pn]
        if windows[pn] then windows[pn].edgeTab = edgeTabs[pn] end
        edgeTabs[pn]:syncToWindow()
        edgeTabs[pn]:setVisible(true)
        return edgeTabs[pn]
    end

    local tab = CSR_EquipmentEdgeTab:new(pn)
    tab:initialise()
    tab:addToUIManager()
    tab.window = windows[pn]
    if windows[pn] then windows[pn].edgeTab = tab end
    edgeTabs[pn] = tab
    tab:setVisible(true)
    return tab
end

local function ensureWindow(playerNum)
    playerNum = playerNum or 0
    if not CSR_FeatureFlags.isEquipmentPanelEnabled() then return nil end
    if getDockMode() == DOCK_MODE_DISABLED then return nil end
    -- Coexist with the original Equipment UI mod (don't double-stack)
    if rawget(_G, "EquipmentUIWindow") then return nil end
    if windows[playerNum] then return windows[playerNum] end
    local w = CSR_EquipmentPanelWindow:new(playerNum)
    w:initialise()
    w:addToUIManager()
    windows[playerNum] = w
    if w.isCleanUIEdgeMode then
        local tab = ensureEdgeTab(playerNum)
        if tab then
            tab.window = w
            w.edgeTab = tab
            tab:syncToWindow()
        end
        w:setVisible(w._cleanPinned and not w.isClosed)
    else
        w:setVisible(false)
    end
    return w
end

local function markWindowDirty(playerNum, refreshModel)
    local w = windows[playerNum or 0]
    if w and w.markDirty then
        w:markDirty(refreshModel == true)
    end
end

local function patchHotbarRefreshForEquipmentPanel()
    if not ISHotbar or not ISHotbar.refresh or ISHotbar.__csr_equipment_panel_refresh then return end
    ISHotbar.__csr_equipment_panel_refresh = true
    local originalRefresh = ISHotbar.refresh

    function ISHotbar:refresh(...)
        local result = originalRefresh(self, ...)
        local pn = self.playerNum
        if pn == nil and self.chr and self.chr.getPlayerNum then
            pn = self.chr:getPlayerNum()
        end
        markWindowDirty(pn or 0, false)
        return result
    end
end

local function linkInventoryPage(playerNum)
    if not getPlayerInventory then return nil end
    local invPage = getPlayerInventory(playerNum or 0)
    if not invPage or invPage.onCharacter == false then return nil end
    local w = ensureWindow(playerNum or 0)
    if w then
        w._linkedInvPage = invPage
    end
    return invPage
end

local function syncDockedPanelToInventory(playerNum)
    if usesCleanUIEdgeMode() then return end
    if getDockMode() ~= DOCK_MODE_DOCKED then return end
    local pn = playerNum or 0
    local w = windows[pn]
    local invPage = (w and w._linkedInvPage) or linkInventoryPage(pn)
    if not invPage then return end
    w = windows[pn] or ensureWindow(pn)
    if not w or not w.isDocked then return end
    local invVisible = invPage:getIsVisible() and not invPage.isCollapsed
    if invVisible then
        w.isClosed = false
        if not w._closedForInventorySession then
            w:setVisible(true)
        end
    else
        w._closedForInventorySession = false
        w:setVisible(false)
    end
end

local function collapseCleanUIEdgePanel(playerNum, persist)
    local pn = playerNum or 0
    local w = windows[pn]
    if not w or not w.isCleanUIEdgeMode then return end
    w._cleanAwayChecks = 0
    w:setVisible(false)
    if persist then
        w._cleanPinned = false
        w.isClosed = true
        saveLayout(w)
    end
    ensureEdgeTab(pn)
end

showCleanUIEdgePanel = function(playerNum, pinned)
    local pn = playerNum or 0
    local w = ensureWindow(pn)
    if not w or not w.isCleanUIEdgeMode then return end
    w._cleanAwayChecks = 0
    w.isClosed = false
    if pinned then
        w._cleanPinned = true
    end
    w:setVisible(true)
    if w.bringToTop then w:bringToTop() end
    local tab = ensureEdgeTab(pn)
    if tab then
        tab.window = w
        w.edgeTab = tab
        tab:syncToWindow()
    end
    if pinned then
        saveLayout(w)
    end
end

function CSR_EquipmentPanel.toggle(playerNum)
    local pn = playerNum or 0
    local w = ensureWindow(pn)
    if not w then return end

    if w.isCleanUIEdgeMode then
        if w:getIsVisible() and w._cleanPinned then
            collapseCleanUIEdgePanel(pn, true)
        elseif w:getIsVisible() then
            w._cleanPinned = true
            w.isClosed = false
            saveLayout(w)
        else
            showCleanUIEdgePanel(pn, true)
        end
        return
    end

    local newVisible = not w:getIsVisible()
    if w.isDocked then
        w._closedForInventorySession = not newVisible
        w.isClosed = false
        w:setVisible(newVisible)
        return
    end
    w:setVisible(newVisible)
    -- Persist player intent so the inventory mirror respects manual closes.
    w.isClosed = not newVisible
    local md = getLayoutModData(getSpecificPlayer(w.playerNum))
    md.isClosed = w.isClosed
    saveLayout(w)
end

--- Show / hide the panel without flipping isClosed (used by hooks).
function CSR_EquipmentPanel.setVisible(playerNum, visible)
    local pn = playerNum or 0
    local w = ensureWindow(pn)
    if not w then return end
    if w.isCleanUIEdgeMode then
        if visible == true then
            showCleanUIEdgePanel(pn, false)
        else
            collapseCleanUIEdgePanel(pn, false)
        end
        return
    end
    w:setVisible(visible == true)
end

function CSR_EquipmentPanel.onPreferenceChanged()
    local enabled = CSR_FeatureFlags.isEquipmentPanelEnabled()
        and getDockMode() ~= DOCK_MODE_DISABLED
    for pn = 0, 3 do
        local w = windows[pn]
        local tab = edgeTabs[pn]
        if not enabled then
            if w then w:setVisible(false) end
            if tab then tab:setVisible(false) end
        elseif getSpecificPlayer and getSpecificPlayer(pn) then
            if usesCleanUIEdgeMode() then
                tab = ensureEdgeTab(pn)
                local md = getLayoutModData(getSpecificPlayer(pn))
                if md.cleanPinned == true and md.isClosed ~= true then
                    showCleanUIEdgePanel(pn, true)
                end
            else
                w = ensureWindow(pn)
            end
            if w and not w.isCleanUIEdgeMode then
                if w.isDocked then
                    syncDockedPanelToInventory(pn)
                elseif not w.isClosed then
                    w:setVisible(true)
                end
            end
        end
    end
end

local function onCreatePlayer(playerNum)
    local pn = playerNum or 0
    if usesCleanUIEdgeMode() then
        ensureEdgeTab(pn)
        local md = getLayoutModData(getSpecificPlayer(pn))
        if md.cleanPinned == true and md.isClosed ~= true then
            showCleanUIEdgePanel(pn, true)
        end
        return
    end
    ensureWindow(pn)
end

local function onPlayerDeath(player)
    if not player then return end
    local pn = player:getPlayerNum() or 0
    local w = windows[pn]
    if w then w:removeFromUIManager(); windows[pn] = nil end
    local tab = edgeTabs[pn]
    if tab then tab:removeFromUIManager(); edgeTabs[pn] = nil end
end

local function onClothingUpdated(player)
    if not player or not player.getPlayerNum then return end
    markWindowDirty(player:getPlayerNum() or 0, true)
end

local dockSyncTick = 0
local cleanEdgeTick = 0
local function updateCleanUIEdgePanels()
    if not usesCleanUIEdgeMode() then
        for _, tab in pairs(edgeTabs) do
            if tab then tab:setVisible(false) end
        end
        return
    end
    if not CSR_FeatureFlags.isEquipmentPanelEnabled() or getDockMode() == DOCK_MODE_DISABLED then
        for _, tab in pairs(edgeTabs) do
            if tab then tab:setVisible(false) end
        end
        for _, w in pairs(windows) do
            if w and w.isCleanUIEdgeMode then w:setVisible(false) end
        end
        return
    end

    for pn = 0, 3 do
        if getSpecificPlayer and getSpecificPlayer(pn) then
            ensureEdgeTab(pn)
        end
    end

    for pn, w in pairs(windows) do
        if w and w.isCleanUIEdgeMode and w:getIsVisible() then
            local overPanel = w.isMouseOver and w:isMouseOver()
            local tab = edgeTabs[pn]
            local overTab = tab and tab.isMouseOver and tab:isMouseOver()
            if w._cleanPinned or overPanel or overTab then
                w._cleanAwayChecks = 0
            else
                w._cleanAwayChecks = (w._cleanAwayChecks or 0) + 1
                if w._cleanAwayChecks >= 3 then
                    collapseCleanUIEdgePanel(pn, false)
                end
            end
        end
    end
end

local function onTick()
    cleanEdgeTick = cleanEdgeTick + 1
    if cleanEdgeTick >= 10 then
        cleanEdgeTick = 0
        updateCleanUIEdgePanels()
    end

    if usesCleanUIEdgeMode() then return end
    dockSyncTick = dockSyncTick + 1
    if dockSyncTick < 10 then return end
    dockSyncTick = 0
    if not CSR_FeatureFlags.isEquipmentPanelEnabled() then return end
    if getDockMode() ~= DOCK_MODE_DOCKED then return end
    for pn = 0, 3 do
        syncDockedPanelToInventory(pn)
    end
end

-- ─────────────────────────────────────────────────────
-- Inventory hooks. The old floating EQ button path was intentionally
-- removed; docked mode now follows the inventory window directly and
-- manual toggling is handled by the rebindable hotkey.
-- ─────────────────────────────────────────────────────
local function patchInventoryPage()
    if usesCleanUIEdgeMode() then return end
    if not ISInventoryPage or ISInventoryPage.__csr_equipment_panel_patched then return end
    ISInventoryPage.__csr_equipment_panel_patched = true
    -- Hook createChildren to capture the per-player ISInventoryPage
    -- reference so the docked panel knows where to anchor.
    local origCreate = ISInventoryPage.createChildren
    ISInventoryPage.createChildren = function(self, ...)
        origCreate(self, ...)
        if self.player == nil then return end
        if self.onCharacter == false then return end
        if not CSR_FeatureFlags.isEquipmentPanelEnabled() then return end
        local w = ensureWindow(self.player)
        if w then
            w._linkedInvPage = self
            syncDockedPanelToInventory(self.player)
        end
    end

    -- Mirror the inventory window's open/closed state. When inventory
    -- opens, show the docked panel with it. When it hides, hide the panel.
    local origSetVisible = ISInventoryPage.setVisible
    ISInventoryPage.setVisible = function(self, visible, ...)
        origSetVisible(self, visible, ...)
        if self.player == nil then return end
        if self.onCharacter == false then return end
        if not CSR_FeatureFlags.isEquipmentPanelEnabled() then return end
        local w = windows[self.player]
        if not w then
            w = ensureWindow(self.player)
        end
        if not w or not w.isDocked then return end
        w._linkedInvPage = self
        if visible then
            w.isClosed = false
            w._closedForInventorySession = false
            w:setVisible(true)
        else
            w._closedForInventorySession = false
            w:setVisible(false)
        end
    end
end

-- Hotkey: Numpad 1 by default, rebindable in Mod Options.
local function onKeyPressed(key)
    if key == nil then return end
    if key == getEquipmentPanelToggleKey() then
        if not CSR_FeatureFlags.isEquipmentPanelEnabled() then return end
        local p = getPlayer()
        if not p then return end
        CSR_EquipmentPanel.toggle(p:getPlayerNum() or 0)
    end
end

local function onResolutionChange()
    if CSR_Scale and CSR_Scale.refresh then
        CSR_Scale.refresh()
    end
    for _, w in pairs(windows) do
        if w and w.reflowForDisplay then
            w:reflowForDisplay()
            saveLayout(w)
        end
    end
    for _, tab in pairs(edgeTabs) do
        if tab and tab.syncToWindow then
            tab:syncToWindow()
        end
    end
end

if Events then
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end
    if Events.OnPlayerDeath then Events.OnPlayerDeath.Add(onPlayerDeath) end
    if Events.OnClothingUpdated then Events.OnClothingUpdated.Add(onClothingUpdated) end
    if Events.OnKeyPressed then Events.OnKeyPressed.Add(onKeyPressed) end
    if Events.OnTick then Events.OnTick.Add(onTick) end
    if Events.OnResolutionChange then Events.OnResolutionChange.Add(onResolutionChange) end
    if Events.OnGameStart then
        Events.OnGameStart.Add(function()
            patchHotbarRefreshForEquipmentPanel()
            patchInventoryPage()
            updateCleanUIEdgePanels()
        end)
    end
end

if CSR_Scale and CSR_Scale.onChange then
    CSR_Scale.onChange(function()
        onResolutionChange()
    end)
end

return CSR_EquipmentPanel

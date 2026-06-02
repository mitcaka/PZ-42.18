-- CSR_MaskHud.lua
-- Standalone single-slot HUD that anchors to the right of the vanilla
-- hotbar and shows the player's gas mask + filter %. Click toggles
-- wear/remove, right-click opens a small context menu (Toggle, Replace
-- Filter, Hide). Hidden entirely when no mask is in inventory or worn.
--
-- Detection rules borrowed (and verified) from MaskToggleUI:
--   body location in { mask, maskeyes, maskfull, nose, scba, scbanotank }
--   plus fullhat / fullsuithead if tagged base:gasmask|respirator(nofilter)
--   plus fallback name match for "mask"/"respirator" + gasmask tags
--
-- Filter % is the standard Drainable API on the with-filter variant.
-- Vanilla auto-swaps to the _nofilter variant when depleted; we render
-- those as a red "NO FILTER" state.
require "CSR_FeatureFlags"
require "CSR_Theme"
require "CSR_Scale"

CSR_MaskHud = CSR_MaskHud or {}

local SLOT_GAP = 8        -- px between vanilla hotbar and our slot
local CACHE_TICKS = 30    -- refresh cached mask resolution roughly twice/sec

local MASK_TAGS = {
    "base:gasmask",
    "base:gasmasknofilter",
    "base:respirator",
    "base:respiratornofilter",
}
local NOFILTER_TAGS = {
    "base:gasmasknofilter",
    "base:respiratornofilter",
}

-- ─────────────────────────────────────────────────────
-- Detection helpers
-- ─────────────────────────────────────────────────────
local function lower(s)
    if s == nil then return "" end
    return string.lower(tostring(s))
end

local function normalizeBodyLocation(bodyLoc)
    if bodyLoc == nil then return "" end
    local s = lower(bodyLoc)
    local colon = string.find(s, ":", 1, true)
    if colon then s = string.sub(s, colon + 1) end
    return s
end

local function hasTag(item, tagName)
    if not item or not ItemTag or not ResourceLocation then return false end
    local ok, tag = pcall(function()
        return ItemTag.get(ResourceLocation.of(tagName))
    end)
    if not ok or not tag then return false end
    local ok2, has = pcall(function() return item:hasTag(tag) end)
    return ok2 and has == true
end

local function hasAnyTag(item, tags)
    for _, t in ipairs(tags) do
        if hasTag(item, t) then return true end
    end
    return false
end

local function isNightVisionItem(item)
    if not item then return false end
    -- Type-name heuristic catches the common naming convention used by
    -- NV framework items (Hat_NightVision_NV_ON / _OFF, etc.).
    local t = lower(item.getType and item:getType())
    if t ~= "" and (string.find(t, "nightvision", 1, true)
                 or string.find(t, "_nv_", 1, true)
                 or string.find(t, "nvgoggle", 1, true)) then
        return true
    end
    -- Legacy NVITEM ItemTag.
    if hasTag(item, "Base.NVITEM") then return true end
    return false
end

local function isMaskItem(item)
    if not item then return false end
    if isNightVisionItem(item) then return false end

    -- Hard exclude: welding masks share BodyLocation=maskfull with gasmasks
    -- but are not respirators.  base:weldingmask tag carries them.
    if hasTag(item, "base:weldingmask") then return false end

    -- Require an explicit gasmask / respirator tag.  BodyLocation alone is
    -- not specific enough (maskfull, mask, scba, etc. are shared with welder
    -- helmets, sleep masks, hockey masks, etc.).
    if hasAnyTag(item, MASK_TAGS) then
        local bodyLoc = normalizeBodyLocation(item:getBodyLocation())
        if bodyLoc == "mask" or bodyLoc == "maskfull" or bodyLoc == "maskeyes"
                or bodyLoc == "nose" or bodyLoc == "scba" or bodyLoc == "scbanotank"
                or bodyLoc == "fullhat" or bodyLoc == "fullsuithead" then
            return true
        end
        -- Tagged but in an unexpected slot: still trust the tag.
        return true
    end
    return false
end

local function isNoFilterMask(item)
    return hasAnyTag(item, NOFILTER_TAGS)
end

local function isFilterCartridge(item)
    if not item then return false end
    if hasTag(item, "base:gasmaskfilter") then return true end
    local t = lower(item.getType and item:getType())
    return t == "gasmaskfilter" or t == "gasmaskfiltercrafted"
end

local function isDrainable(item)
    if not item then return false end
    if instanceof(item, "DrainableComboItem") then return true end
    if item.IsDrainable and item:IsDrainable() then return true end
    return false
end

local function getFilterRatio(item)
    if not item then return nil end
    if not isDrainable(item) then return nil end
    if item.getCurrentUsesFloat then return item:getCurrentUsesFloat() end
    if item.getDelta then return item:getDelta() end
    return nil
end

-- ─────────────────────────────────────────────────────
-- Mask resolution (worn first, else best inventory candidate)
-- ─────────────────────────────────────────────────────
local function findWornMask(player)
    local worn = player:getWornItems()
    if not worn then return nil end
    for i = 0, worn:size() - 1 do
        local entry = worn:get(i)
        local item = entry and entry.getItem and entry:getItem() or nil
        if item and isMaskItem(item) then return item end
    end
    return nil
end

local function findInventoryMask(player)
    local inv = player:getInventory()
    if not inv then return nil end
    local items = inv:getItems()
    if not items then return nil end
    local best = nil
    local bestRatio = -1
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if isMaskItem(item) then
            -- Prefer with-filter variant, then highest filter %
            local nofilter = isNoFilterMask(item)
            local ratio = getFilterRatio(item) or (nofilter and -0.5 or 0)
            if not best
                or (isNoFilterMask(best) and not nofilter)
                or ratio > bestRatio then
                best = item
                bestRatio = ratio
            end
        end
    end
    return best
end

local function findFilterCartridge(player)
    local inv = player:getInventory()
    if not inv then return nil end
    local items = inv:getItems()
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if isFilterCartridge(item) then return item end
    end
    return nil
end

-- ─────────────────────────────────────────────────────
-- Panel
-- ─────────────────────────────────────────────────────
CSR_MaskHudPanel = ISPanel:derive("CSR_MaskHudPanel")

function CSR_MaskHudPanel:new(playerNum)
    local o = ISPanel.new(self, 0, 0, 48, 48)
    o.playerNum = playerNum or 0
    o.background = false
    o.cachedMask = nil
    o.cachedWorn = false
    o.cacheTick = 0
    return o
end

function CSR_MaskHudPanel:initialise()
    ISPanel.initialise(self)
end

function CSR_MaskHudPanel:resolveMask()
    local player = getSpecificPlayer(self.playerNum)
    if not player or player:isDead() then
        self.cachedMask, self.cachedWorn = nil, false
        return
    end
    local worn = findWornMask(player)
    if worn then
        self.cachedMask, self.cachedWorn = worn, true
        return
    end
    local invMask = findInventoryMask(player)
    self.cachedMask, self.cachedWorn = invMask, false
end

function CSR_MaskHudPanel:anchorToHotbar()
    local hotbar = getPlayerHotbar and getPlayerHotbar(self.playerNum) or nil
    if hotbar and hotbar.javaObject and hotbar:getIsVisible() then
        local hx = hotbar:getX()
        local hy = hotbar:getY()
        local hw = hotbar:getWidth()
        local hh = hotbar:getHeight()
        if hh and hh > 0 then
            self:setHeight(hh)
            self:setWidth(hh) -- square to match a hotbar slot
        end
        self:setX(hx + hw + CSR_Scale.px(SLOT_GAP))
        self:setY(hy)
        return true
    end
    -- Fallback: bottom-center, where vanilla hotbar would sit
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    self:setX(sw - CSR_Scale.px(80))
    self:setY(sh - CSR_Scale.px(60))
    return false
end

function CSR_MaskHudPanel:prerender()
    if not CSR_FeatureFlags.isMaskHudEnabled() then
        self:setVisible(false)
        return
    end

    self.cacheTick = self.cacheTick + 1
    if self.cacheTick >= CACHE_TICKS or not self.cachedMask then
        self.cacheTick = 0
        self:resolveMask()
    end

    if not self.cachedMask then
        self:setVisible(false)
        return
    end

    self:setVisible(true)
    self:anchorToHotbar()
end

local function getStateColor(item, worn)
    if isNoFilterMask(item) then
        return CSR_Theme.getColor("accentRed")
    end
    local ratio = getFilterRatio(item)
    if ratio then
        if ratio > 0.50 then return CSR_Theme.getColor("accentGreen") end
        if ratio > 0.25 then return CSR_Theme.getColor("accentAmber") end
        return CSR_Theme.getColor("accentRed")
    end
    -- Cloth mask / non-drainable
    return worn and CSR_Theme.getColor("accentGreen") or CSR_Theme.getColor("panelBorder")
end

function CSR_MaskHudPanel:render()
    local item = self.cachedMask
    if not item then return end

    local w, h = self.width, self.height
    local bg = CSR_Theme.getColor("panelBg")
    local border = CSR_Theme.getColor("panelBorder")
    local stateColor = getStateColor(item, self.cachedWorn)

    -- Slot background (matches a hotbar slot)
    self:drawRect(0, 0, w, h, 0.85, bg.r, bg.g, bg.b)
    self:drawRectBorder(0, 0, w, h, 0.55, border.r, border.g, border.b)

    -- CSR-themed mask silhouette backdrop (subtle, behind the item icon)
    if not CSR_MaskHudPanel._backdropTex then
        CSR_MaskHudPanel._backdropTex = getTexture("media/ui/csr_mask_slot.png")
        CSR_MaskHudPanel._backdropMissing = (CSR_MaskHudPanel._backdropTex == nil)
    end
    local backdrop = CSR_MaskHudPanel._backdropTex
    if backdrop then
        local bpad = 3
        local bAlpha = self.cachedWorn and 0.18 or 0.28
        self:drawTextureScaled(backdrop, bpad, bpad, w - bpad * 2, h - bpad * 2 - 8,
            bAlpha, 1, 1, 1)
    end

    -- Inventory-only state: slightly dimmer
    local iconAlpha = self.cachedWorn and 1.0 or 0.6

    -- Item icon centered
    local tex = item:getTex()
    if tex then
        local pad = 4
        self:drawTextureScaled(tex, pad, pad, w - pad * 2, h - pad * 2 - 8,
            iconAlpha, 1, 1, 1)
    end

    -- Filter bar along bottom (5px tall)
    local barH = 5
    local barY = h - barH - 1
    self:drawRect(1, barY, w - 2, barH, 0.45, 0, 0, 0)
    if isNoFilterMask(item) then
        -- Empty bar + label
        self:drawRectBorder(1, barY, w - 2, barH, 0.85,
            stateColor.r, stateColor.g, stateColor.b)
    else
        local ratio = getFilterRatio(item)
        if ratio then
            local fillW = math.max(1, math.floor((w - 2) * ratio))
            self:drawRect(1, barY, fillW, barH, 0.92,
                stateColor.r, stateColor.g, stateColor.b)
        end
    end

    -- State outline (border tint by filter level)
    self:drawRectBorder(0, 0, w, h, 0.85,
        stateColor.r, stateColor.g, stateColor.b)

    -- "NO FILTER" overlay text
    if isNoFilterMask(item) then
        local font = CSR_Scale.font(11)
        local tm = getTextManager()
        local label = getText("IGUI_CSR_MaskHud_NoFilter")
        local tw = tm:MeasureStringX(font, label)
        local tx = math.floor((w - tw) / 2)
        local ty = math.floor((h - tm:getFontHeight(font)) / 2) - 2
        -- Shadow
        self:drawText(label, tx + 1, ty + 1, 0, 0, 0, 0.85, font)
        self:drawText(label, tx, ty,
            stateColor.r, stateColor.g, stateColor.b, 1.0, font)
    end

    -- Hover: highlight + cursor
    if self:isMouseOver() then
        self:drawRectBorder(0, 0, w, h, 1.0, 1, 1, 1)
        self:renderTooltip()
    end
end

function CSR_MaskHudPanel:renderTooltip()
    local item = self.cachedMask
    if not item then return end
    local lines = {}
    local name = item.getName and item:getName() or "Mask"
    table.insert(lines, name)
    if isNoFilterMask(item) then
        table.insert(lines, getText("IGUI_CSR_MaskHud_NoFilter"))
    else
        local ratio = getFilterRatio(item)
        if ratio then
            local pct = math.floor(ratio * 100 + 0.5)
            table.insert(lines, getText("IGUI_CSR_MaskHud_FilterPct", tostring(pct)))
        end
    end
    table.insert(lines, self.cachedWorn
        and getText("IGUI_CSR_MaskHud_TipUnequip")
        or getText("IGUI_CSR_MaskHud_TipEquip"))
    table.insert(lines, getText("IGUI_CSR_MaskHud_TipReplace"))

    local font = CSR_Scale.font(14)
    local tm = getTextManager()
    local lineH = tm:getFontHeight(font)
    local maxW = 0
    for _, l in ipairs(lines) do
        local mw = tm:MeasureStringX(font, l)
        if mw > maxW then maxW = mw end
    end
    local pad = CSR_Scale.px(6)
    local boxW = maxW + pad * 2
    local boxH = #lines * lineH + pad * 2
    local boxX = self.width + CSR_Scale.px(6)
    local boxY = -boxH - CSR_Scale.px(6)
    if self:getAbsoluteY() + boxY < 0 then boxY = self.height + 6 end

    local bg = CSR_Theme.getColor("panelBg")
    local border = CSR_Theme.getColor("panelBorder")
    self:drawRect(boxX, boxY, boxW, boxH, 0.92, bg.r, bg.g, bg.b)
    self:drawRectBorder(boxX, boxY, boxW, boxH, 0.7, border.r, border.g, border.b)
    for i, l in ipairs(lines) do
        self:drawText(l, boxX + pad, boxY + pad + (i - 1) * lineH,
            1, 1, 1, 1, font)
    end
end

-- ─────────────────────────────────────────────────────
-- Click actions
-- ─────────────────────────────────────────────────────
local function toggleMask(playerNum)
    local player = getSpecificPlayer(playerNum or 0)
    if not player or player:isDead() then return end
    local worn = findWornMask(player)
    if worn then
        ISTimedActionQueue.add(ISUnequipAction:new(player, worn, 50))
        return
    end
    local mask = findInventoryMask(player)
    if mask and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.wearItem then
        ISInventoryPaneContextMenu.wearItem(mask, playerNum or 0)
    end
end

local function replaceFilter(playerNum)
    local player = getSpecificPlayer(playerNum or 0)
    if not player or player:isDead() then return end

    -- Build the recipe handler vanilla provides (RechargeFilters), or fall
    -- back to a simple swap: remove the depleted mask, equip the with-filter
    -- variant if present. We use the swap approach because it doesn't
    -- depend on the player's current crafting UI state and works in MP.
    local worn = findWornMask(player)
    local cartridge = findFilterCartridge(player)
    if not cartridge then
        if HaloTextHelper and HaloTextHelper.addBadText then
            HaloTextHelper.addBadText(player, getText("IGUI_CSR_MaskHud_NoSpareFilter"))
        end
        return
    end

    -- Find the with-filter variant of the worn mask script. The vanilla
    -- script line "WithDrainable = Base.Hat_GasMask" tells us the upgrade
    -- type for a depleted mask.
    local target = worn or findInventoryMask(player)
    if not target then return end
    if not isNoFilterMask(target) then
        if HaloTextHelper and HaloTextHelper.addText then
            HaloTextHelper.addText(player, getText("IGUI_CSR_MaskHud_FilterPct",
                tostring(math.floor((getFilterRatio(target) or 0) * 100 + 0.5))))
        end
        return
    end

    local script = target:getScriptItem()
    local upgradeType = script and script.getReplaceItem and script:getReplaceItem("WithDrainable") or nil
    if not upgradeType then
        -- Try common naming convention as fallback
        local t = target:getType()
        if t and string.find(t, "_nofilter$") then
            upgradeType = "Base." .. string.gsub(t, "_nofilter$", "")
        end
    end
    if not upgradeType then return end

    -- Spawn the upgraded mask, transfer condition, consume cartridge + old mask
    local newItem = player:getInventory():AddItem(upgradeType)
    if not newItem then return end
    if target.getCondition and newItem.setCondition then
        pcall(function() newItem:setCondition(target:getCondition()) end)
    end
    -- Use the filter cartridge fully (consume one)
    if cartridge.Use then pcall(function() cartridge:Use() end) end
    -- Remove the depleted mask
    if worn then
        pcall(function() ISTimedActionQueue.add(ISUnequipAction:new(player, worn, 30)) end)
    end
    pcall(function() player:getInventory():Remove(target) end)
    -- Auto-wear the new one
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.wearItem then
        pcall(function() ISInventoryPaneContextMenu.wearItem(newItem, playerNum or 0) end)
    end
end

function CSR_MaskHudPanel:onMouseDown(x, y)
    self._wasDown = true
    return true
end

function CSR_MaskHudPanel:onMouseUp(x, y)
    if self._wasDown then
        self._wasDown = false
        toggleMask(self.playerNum)
    end
    return true
end

function CSR_MaskHudPanel:onMouseUpOutside(x, y)
    self._wasDown = false
    return true
end

function CSR_MaskHudPanel:onRightMouseUp(x, y)
    local context = ISContextMenu.get(self.playerNum,
        self:getAbsoluteX() + x, self:getAbsoluteY() + y)
    if not context then return end

    context:addOption(getText("IGUI_CSR_MaskHud_Toggle"), self.playerNum, function(pn)
        toggleMask(pn)
    end)

    -- Replace Filter only when we have a depleted mask + cartridge
    local item = self.cachedMask
    if item and isNoFilterMask(item) then
        local opt = context:addOption(getText("IGUI_CSR_MaskHud_ReplaceFilter"),
            self.playerNum, function(pn) replaceFilter(pn) end)
        local player = getSpecificPlayer(self.playerNum)
        if player and not findFilterCartridge(player) then
            opt.notAvailable = true
            local tt = ISInventoryPaneContextMenu.addToolTip and
                ISInventoryPaneContextMenu.addToolTip() or nil
            if tt then
                tt.description = getText("IGUI_CSR_MaskHud_NoSpareFilter")
                opt.toolTip = tt
            end
        end
    end
    return true
end

-- ─────────────────────────────────────────────────────
-- Lifecycle
-- ─────────────────────────────────────────────────────
local panels = {}

local function createForPlayer(playerNum)
    if panels[playerNum] then return end
    if not CSR_FeatureFlags.isMaskHudEnabled() then return end
    local p = CSR_MaskHudPanel:new(playerNum)
    p:initialise()
    p:addToUIManager()
    panels[playerNum] = p
end

local function onCreatePlayer(playerNum)
    createForPlayer(playerNum or 0)
end

local function onPlayerDeath(player)
    if not player then return end
    local pn = player:getPlayerNum() or 0
    local p = panels[pn]
    if p then
        p:removeFromUIManager()
        panels[pn] = nil
    end
end

CSR_MaskHud.toggle = function() toggleMask(0) end

if Events then
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end
    if Events.OnPlayerDeath then Events.OnPlayerDeath.Add(onPlayerDeath) end
end

return CSR_MaskHud

--[[
    CSR_OffhandHudOverlay.lua

    HUD-only paint pass that hides the off-hand-icon flicker when the engine
    momentarily clears the secondary hand slot.  Works in tandem with
    CSR_OffhandPersist (shared) which keeps a frame-stamped ledger of the
    off-hand the player is actually holding.

    Behaviour rules:
      * Only paints when the live secondary slot is empty (or a 2H mirror of
        the primary).  Vanilla rendering handles the "real off-hand visible"
        case unchanged.
      * Only paints when CSR_OffhandPersist still considers the entry live
        (frame-stamp window AND the item is still in the player's inventory).
      * Drawn at slightly reduced alpha so the icon reads as a held-state
        indicator rather than as the literal slot contents -- this keeps the
        affordance honest if the engine cleared the slot for a real reason.
      * No context-menu changes, no right-click overrides.  The vanilla
        right-click on the live slot continues to drive equip / unequip.
]]

require "CSR_FeatureFlags"
require "CSR_OffhandPersist"
require "ISUI/ISEquippedItem"

local _wrapped = false

local function shouldPaint(self)
    if not CSR_FeatureFlags or not CSR_FeatureFlags.isDualWieldEnabled() then return false end
    if not CSR_FeatureFlags.isOffhandHudOverlayEnabled() then return false end
    local chr = self.chr
    if not chr or chr:isDead() then return false end
    local sec  = chr:getSecondaryHandItem()
    local prim = chr:getPrimaryHandItem()
    -- live slot already shows what we'd want to draw
    if sec ~= nil and sec ~= prim then return false end
    if not CSR_OffhandPersist.isLive(chr) then return false end
    return true
end

local function paintGhost(self)
    local hand = self.offHand
    if not hand or hand.width == nil or hand.height == nil then return end
    local tex = CSR_OffhandPersist.texture(self.chr)
    if not tex then return end

    -- Slightly inset and softened so the icon reads as cached state, not as
    -- the literal slot contents.  Footprint is intentionally not pixel-equal
    -- to the vanilla render call.
    local pad   = math.max(2, math.floor(hand.height * 0.08))
    local box   = math.max(8, hand.height - (pad * 2))
    local ox    = hand.x + math.floor((hand.width  - box) / 2)
    local oy    = hand.y + math.floor((hand.height - box) / 2)
    self:drawTextureScaledAspect(tex, ox, oy, box, box, 0.88, 1, 1, 1)
end

local function attach()
    if _wrapped then return end
    if not ISEquippedItem or not ISEquippedItem.render then return end
    _wrapped = true
    local original = ISEquippedItem.render
    ISEquippedItem.render = function(self)
        original(self)
        if shouldPaint(self) then
            local ok, err = pcall(paintGhost, self)
            if not ok and err then
                -- silent: painting failure must never break vanilla HUD
            end
        end
    end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(attach)
end
-- also try immediately in case ISEquippedItem is already loaded
attach()

-- CSR_BarrelCapFix.lua
-- Some third-party barrel mods add a Cap / Uncap option to the
-- world-object context menu, but lose it after the player moves the
-- barrel via Move Furniture (the IsoObject is reconstructed from the
-- staged sprite, and the Lua-side context hook is no longer applied).
--
-- This file always re-adds a Cap / Uncap option to any world object
-- that exposes a FluidContainer component, regardless of which mod
-- originally placed the barrel. It writes the cap state into the
-- IsoObject's modData (flat key, MP-safe) and toggles input/output
-- locks on the fluid container so capped barrels stop accepting rain.
--
-- v1.8.x hardening (May 2026):
-- 1. Sprite-name "barrel" substring is too narrow — moveable barrels
--    from third-party packs (orange/green drum variants, MetalDrum,
--    custom rain-collector mods) often have non-"barrel" sprite names.
--    We now also accept any object whose sprite carries a CustomItem
--    property naming a "Barrel" or "Drum" item, OR any moveable that
--    exposes a FluidContainer with capacity >= 50L.
-- 2. The cap flag was lost when the barrel was picked up via Move
--    Furniture and placed back. modData on the world IsoObject does
--    not survive the pickup→place round trip; the engine reconstructs
--    a fresh IsoObject on placement. We now bridge the flag via the
--    Moveable item's modData (which IS persisted by the engine), by
--    wrapping ISMoveableSpriteProps:pickUpMoveableInternal and
--    :placeMoveableInternal.
require "CSR_FeatureFlags"

CSR_BarrelCapFix = CSR_BarrelCapFix or {}

local CAP_KEY = "csrBarrelCapped"

local function getSpriteName(obj)
    if not obj or obj.getSprite == nil then return nil end
    local sp = obj:getSprite()
    if not sp or sp.getName == nil then return nil end
    local nm = sp:getName()
    if type(nm) ~= "string" then return nil end
    return nm
end

local function getCustomItemName(obj)
    if not obj or obj.getSprite == nil then return nil end
    local sp = obj:getSprite()
    if not sp or sp.getProperties == nil then return nil end
    local props = sp:getProperties()
    if not props then return nil end
    if not props:has("CustomItem") then return nil end
    local val = props:get("CustomItem")
    if type(val) ~= "string" then return nil end
    return val
end

local function looksLikeBarrelName(name)
    if type(name) ~= "string" or name == "" then return false end
    local s = string.lower(name)
    if string.find(s, "barrel", 1, true) then return true end
    if string.find(s, "drum", 1, true) then return true end
    if string.find(s, "metaldrum", 1, true) then return true end
    return false
end

local function fluidContainerCapacity(fc)
    if not fc or fc.getCapacity == nil then return 0 end
    local cap = fc:getCapacity()
    if type(cap) ~= "number" then return 0 end
    return cap
end

local function isBarrelLike(obj)
    if not obj then return false end
    -- Skip dropped inventory items entirely — they fire OnObjectAdded too
    -- but are not world fixtures and have no meaningful FluidContainer.
    if instanceof(obj, "IsoWorldInventoryObject") then return false end
    -- Field-access guard: in Kahlua, reading an absent member on Java
    -- userdata returns nil silently. Calling a method that does not
    -- exist throws "Tried to call nil" — and per the PZ error-handler
    -- guard keeps the event path predictable for vanilla callers.
    -- this frame, breaking whatever vanilla flow triggered the event
    -- (e.g. opening a box of nails -> AddItemToMapPacket).
    if obj.getFluidContainer == nil then return false end
    local fc = obj:getFluidContainer()
    if not fc then return false end
    -- Ignore objects with a container (sinks, washing machines, etc. —
    -- we don't want to cap those even though they're fluid sources).
    if obj.getContainerCount ~= nil then
        local cc = obj:getContainerCount()
        if type(cc) == "number" and cc > 0 then return false end
    end
    -- (1) Sprite name contains "barrel" or "drum".
    local spriteName = getSpriteName(obj)
    if looksLikeBarrelName(spriteName) then return true end
    -- (2) CustomItem sprite property names a barrel/drum-like item.
    if looksLikeBarrelName(getCustomItemName(obj)) then return true end
    -- (3) Heuristic: a Moveable IsoObject with a fluid container of
    --     50L or more capacity is treated as a barrel. This catches
    --     custom rain-collectors and modded drum sprites whose names
    --     give us no signal. Below 50L we conservatively decline so
    --     small jugs/sinks aren't wrapped.
    if instanceof(obj, "IsoObject") and fluidContainerCapacity(fc) >= 50 then
        return true
    end
    return false
end

local function isCapped(obj)
    local md = obj:getModData()
    return md[CAP_KEY] == true
end

local function applyLocksToFC(fc, capped)
    if not fc then return end
    if fc.setInputLocked then fc:setInputLocked(capped) end
    if fc.setOutputLocked then fc:setOutputLocked(capped) end
end

local function sendCapState(playerNum, obj, capped)
    local sq = obj:getSquare()
    if not sq then return end
    local args = {
        x = sq:getX(), y = sq:getY(), z = sq:getZ(),
        spriteName = obj:getSprite() and obj:getSprite():getName() or nil,
        capped = capped,
    }
    if isClient() then
        sendClientCommand(getSpecificPlayer(playerNum), "CommonSenseReborn", "BarrelCap", args)
    else
        -- SP: apply locally
        local md = obj:getModData()
        md[CAP_KEY] = capped
        applyLocksToFC(obj.getFluidContainer and obj:getFluidContainer() or nil, capped)
        if obj.transmitModData then obj:transmitModData() end
    end
end

local function onCapClick(playerNum, worldObj)
    sendCapState(playerNum, worldObj, true)
    if HaloTextHelper and getSpecificPlayer(playerNum) then
        HaloTextHelper.addText(getSpecificPlayer(playerNum),
            getText("IGUI_CSR_BarrelCap_Capped"), HaloTextHelper.getColorWhite())
    end
end

local function onUncapClick(playerNum, worldObj)
    sendCapState(playerNum, worldObj, false)
    if HaloTextHelper and getSpecificPlayer(playerNum) then
        HaloTextHelper.addText(getSpecificPlayer(playerNum),
            getText("IGUI_CSR_BarrelCap_Uncapped"), HaloTextHelper.getColorWhite())
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test then return end
    if not CSR_FeatureFlags.isBarrelCapFixEnabled() then return end

    -- Find first barrel-like object in the click stack.
    local barrel = nil
    for i = 1, #worldObjects do
        local o = worldObjects[i]
        if isBarrelLike(o) then barrel = o; break end
    end
    if not barrel then return end

    -- Don't double-add if another mod already provided cap/uncap.
    -- We scan the existing options' name strings.
    local opts = context and context.options or nil
    if opts then
        for i = 1, #opts do
            local nm = opts[i] and opts[i].name
            if type(nm) == "string" and (string.find(nm, "Cap ", 1, true) or string.find(nm, "Uncap", 1, true)) then
                return
            end
        end
    end

    if isCapped(barrel) then
        context:addOption(getText("IGUI_CSR_BarrelCap_Uncap"), playerNum, onUncapClick, barrel)
    else
        context:addOption(getText("IGUI_CSR_BarrelCap_Cap"), playerNum, onCapClick, barrel)
    end
end

-- After Move Furniture finishes placing a barrel, re-apply the
-- previously stored capped state so the lock survives the move.
--
-- The cap flag travels through the pickup/place round trip via the
-- Moveable item's modData (the engine reconstructs the world IsoObject
-- on placement, dropping its world modData). We hook
-- ISMoveableSpriteProps:pickUpMoveableInternal to copy the world
-- IsoObject's flag onto a transient slot on the player, and
-- :placeMoveableInternal to read it back when the new world IsoObject
-- is created. OnObjectAdded is still hooked as a backstop for any
-- placement path that doesn't go through placeMoveableInternal (e.g.
-- chunk reload of a previously capped barrel that already had its
-- modData written via the server command).
local function onObjectAdded(obj)
    if not obj or not isBarrelLike(obj) then return end
    local md = obj:getModData()
    if md and md[CAP_KEY] == true then
        applyLocksToFC(obj.getFluidContainer and obj:getFluidContainer() or nil, true)
    end
end

-- Pickup: stash the cap flag into a per-player transient slot keyed
-- by the sprite's CustomItem (so different parallel barrel pickups
-- don't collide). We also stash by sprite name as a fallback.
local function stashFlagOnPickup(character, worldObj)
    if not character or not worldObj then return end
    if not isBarrelLike(worldObj) then return end
    local md = worldObj:getModData()
    if not md then return end
    local capped = md[CAP_KEY] == true
    if not character.getModData then return end
    local pmd = character:getModData()
    if not pmd then return end
    pmd._csrBarrelPickup = pmd._csrBarrelPickup or {}
    local custom = getCustomItemName(worldObj) or ""
    local sprite = getSpriteName(worldObj) or ""
    -- last-pickup wins; we only need one in flight per move action
    pmd._csrBarrelPickup.lastCustom = custom
    pmd._csrBarrelPickup.lastSprite = sprite
    pmd._csrBarrelPickup.lastCapped = capped
end

local function consumeFlagOnPlace(character, newObj)
    if not character or not newObj then return end
    if not isBarrelLike(newObj) then return end
    if not character.getModData then return end
    local pmd = character:getModData()
    if not pmd or not pmd._csrBarrelPickup then return end
    local pickup = pmd._csrBarrelPickup
    local custom = getCustomItemName(newObj) or ""
    local sprite = getSpriteName(newObj) or ""
    -- Match by either custom item id or sprite — same barrel just placed.
    local matches = (custom ~= "" and custom == pickup.lastCustom)
                 or (sprite ~= "" and sprite == pickup.lastSprite)
    if not matches then return end
    if pickup.lastCapped == true then
        local md = newObj:getModData()
        if md then
            md[CAP_KEY] = true
            applyLocksToFC(newObj.getFluidContainer and newObj:getFluidContainer() or nil, true)
            if newObj.transmitModData then newObj:transmitModData() end
            -- v1.8.34: client-side modData write doesn't re-apply
            -- the FluidContainer locks on the server-side IsoObject
            -- (since the server creates a fresh object on placement).
            -- Push a real BarrelCap command so the server re-locks
            -- input/output and rain stops filling the moved barrel.
            if isClient() then
                local sq = newObj:getSquare()
                if sq then
                    sendClientCommand(character, "CommonSenseReborn", "BarrelCap", {
                        x = sq:getX(), y = sq:getY(), z = sq:getZ(),
                        spriteName = getSpriteName(newObj),
                        capped = true,
                    })
                end
            end
        end
    end
    -- consume
    pmd._csrBarrelPickup = nil
end

local function installMoveableHooks()
    if CSR_BarrelCapFix._moveableHooked then return end
    if not ISMoveableSpriteProps then return end
    if ISMoveableSpriteProps.pickUpMoveableInternal then
        local _origPick = ISMoveableSpriteProps.pickUpMoveableInternal
        ISMoveableSpriteProps.pickUpMoveableInternal = function(self, _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating)
            -- read flag BEFORE super call (after super, _object may be removed)
            stashFlagOnPickup(_character, _object)
            return _origPick(self, _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating)
        end
    end
    if ISMoveableSpriteProps.placeMoveableInternal then
        local _origPlace = ISMoveableSpriteProps.placeMoveableInternal
        ISMoveableSpriteProps.placeMoveableInternal = function(self, _square, _item, _spriteName)
            local newObj = _origPlace(self, _square, _item, _spriteName)
            -- character on ISMoveableSpriteProps is the actor; some
            -- versions store it as self.character, others rely on the
            -- timed action's character. Fall back to local player.
            local ch = self and self.character or (getSpecificPlayer and getSpecificPlayer(0)) or nil
            consumeFlagOnPlace(ch, newObj)
            return newObj
        end
    end
    CSR_BarrelCapFix._moveableHooked = true
end

if Events then
    if Events.OnFillWorldObjectContextMenu then
        Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
    end
    if Events.OnObjectAdded then
        Events.OnObjectAdded.Add(onObjectAdded)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(installMoveableHooks)
    end
end

return CSR_BarrelCapFix

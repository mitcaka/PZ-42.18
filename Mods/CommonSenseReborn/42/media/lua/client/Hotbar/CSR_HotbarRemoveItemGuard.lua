--[[
    CSR_HotbarRemoveItemGuard.lua

    Vanilla ISHotbar:removeItem(item, false) calls
    chr:removeAttachedItem(item) before clearing the item's attached model
    fields. If the item is already in a nil attached-location state, that
    Java-side cleanup can throw "locationId is null" during refresh().

    A companion guard on ISHotbar:attachItem catches the follow-on edge case:
    after removeItem is intercepted, vanilla refresh() still calls
    attachItem(item, slotDef.attachments[item:getAttachmentType()], ...).
    If getAttachmentType() returns a type absent from the slot's attachments
    map, slot is nil, and chr:setAttachedItem(nil, item) throws. The guard
    treats nil slot identically to vanilla's "null" sentinel.

    Both guards are deliberately narrow: animated paths and valid model
    locations pass through to vanilla unchanged.
]]

local function clearDetachedHotbarItem(hotbar, item)
    if item.setAttachedSlot then item:setAttachedSlot(-1) end
    if item.setAttachedSlotType then item:setAttachedSlotType(nil) end
    if item.setAttachedToModel then item:setAttachedToModel(nil) end

    if hotbar and hotbar.reloadIcons then
        hotbar:reloadIcons()
    end
end

local function patchHotbarRemoveItemForNilAttachGuard()
    if not ISHotbar or not ISHotbar.removeItem or ISHotbar.__csr_remove_item_nil_attach_guard then return end
    ISHotbar.__csr_remove_item_nil_attach_guard = true

    local origRemoveItem = ISHotbar.removeItem

    function ISHotbar:removeItem(item, doAnim)
        if not item then
            return
        end

        if not doAnim and item.getAttachedToModel and item:getAttachedToModel() == nil then
            clearDetachedHotbarItem(self, item)
            return
        end

        return origRemoveItem(self, item, doAnim)
    end
end

local function patchHotbarAttachItemForNilSlot()
    if not ISHotbar or not ISHotbar.attachItem or ISHotbar.__csr_attach_item_nil_slot_guard then return end
    ISHotbar.__csr_attach_item_nil_slot_guard = true

    local origAttachItem = ISHotbar.attachItem

    function ISHotbar:attachItem(item, slot, slotIndex, slotDef, doAnim)
        if not doAnim and slot == nil then
            -- No model string found for this item's attachment type in the
            -- current slot's attachments map. Mirror vanilla's "null" sentinel
            -- path: clean up the item state and bail out without crashing.
            self:removeItem(item, false)
            return
        end
        return origAttachItem(self, item, slot, slotIndex, slotDef, doAnim)
    end
end

local function applyGuards()
    patchHotbarRemoveItemForNilAttachGuard()
    patchHotbarAttachItemForNilSlot()
end

if Events then
    local registered = false
    if Events.OnGameStart then
        Events.OnGameStart.Add(applyGuards)
        registered = true
    end
    if Events.OnCreatePlayer then
        Events.OnCreatePlayer.Add(applyGuards)
        registered = true
    end
    if not registered then
        applyGuards()
    end
else
    applyGuards()
end

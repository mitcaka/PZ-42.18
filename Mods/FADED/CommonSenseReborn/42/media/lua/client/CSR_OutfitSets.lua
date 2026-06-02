-- CSR_OutfitSets.lua  (v1.8.34)
-- Right-click a wardrobe / shelves / locker / dresser etc. and get an
-- "Outfit Sets" submenu. Save the gear you're currently wearing as a
-- named slot, wear a saved slot back later (best-condition match across
-- player + wardrobe + room), or delete a slot.
--
-- Optional categories (Casual / Combat / Work / Sleep / Other) for
-- organising large collections.
--
-- Inspired by Yuki's "Outfit Control" mod (Workshop id 3610760744) — used
-- with permission. Reimplemented from scratch with different match
-- semantics, multi-container scan, categories, and capacity bonus folded
-- into the single feature flag.
require "CSR_FeatureFlags"
require "CSR_OutfitSetsUtil"

local CATEGORIES = { "Casual", "Combat", "Work", "Sleep", "Other" }

local function txt(key, fb)
    if not getText then return fb end
    local s = getText(key)
    if not s or s == key or s == "" then return fb end
    return s
end

local function sendOutfitWardrobeCommand(player, command, obj)
    if not player or not obj or not isClient or not isClient() then return end
    local args = CSR_OutfitSetsUtil.objectCommandArgs(obj)
    if args and sendClientCommand then
        sendClientCommand(player, "CommonSenseReborn", command, args)
    end
end

-- ─────────────────────────────────────────────────────
-- Save / Delete prompts (reuse vanilla ISTextBox + ISModalDialog).
-- ─────────────────────────────────────────────────────
local SaveCtx = {}

function SaveCtx:onSaveClick(button)
    if button.internal ~= "OK" then return end
    local name = button.parent.entry and button.parent.entry:getText() or ""
    if not name or name == "" then return end
    local ok, err = CSR_OutfitSetsUtil.saveOutfit(self.player, name, self.category)
    if not ok then
        if err == "MaxSlots" then
            self.player:Say(txt("IGUI_CSR_OutfitSets_Full", "Outfit slots full."))
        elseif err == "NothingWorn" then
            self.player:Say(txt("IGUI_CSR_OutfitSets_Naked", "I'm not wearing anything to save."))
        end
        return
    end
    if isClient() then
        sendClientCommand(self.player, "CommonSenseReborn", "OutfitSetSave", {
            name = name,
            category = self.category or "",
        })
    end
    self.player:Say(txt("IGUI_CSR_OutfitSets_Saved", "Outfit saved."))
end

local function promptSave(player, category)
    local ctx = setmetatable({ player = player, category = category }, { __index = SaveCtx })
    local modal = ISTextBox:new(
        0, 0, 320, 100,
        txt("IGUI_CSR_OutfitSets_NewName", "Name this outfit"),
        category and (category .. ": ") or "",
        ctx,
        SaveCtx.onSaveClick
    )
    modal:initialise()
    modal:addToUIManager()
    modal.maxChars = 30
end

local DeleteCtx = {}

function DeleteCtx:onConfirm(button)
    if button.internal ~= "YES" then return end
    CSR_OutfitSetsUtil.deleteOutfit(self.player, self.slotName)
    if isClient() then
        sendClientCommand(self.player, "CommonSenseReborn", "OutfitSetDelete", {
            name = self.slotName,
        })
    end
end

local function promptDelete(player, slotName)
    local ctx = setmetatable({ player = player, slotName = slotName },
        { __index = DeleteCtx })
    local w, h = 360, 110
    local prompt = string.format(
        txt("IGUI_CSR_OutfitSets_DeletePrompt", "Delete outfit \"%s\"?"),
        slotName)
    local modal = ISModalDialog:new(
        (getCore():getScreenWidth() / 2) - w / 2,
        (getCore():getScreenHeight() / 2) - h / 2,
        w, h, prompt, true, ctx, DeleteCtx.onConfirm)
    modal:initialise()
    modal:addToUIManager()
    modal:setAlwaysOnTop(true)
end

-- ─────────────────────────────────────────────────────
-- Wear: best-condition match across the search pool.
-- ─────────────────────────────────────────────────────
local function gatherWornAtBodyLocations(player, locSet)
    local out = {}
    local worn = player.getWornItems and player:getWornItems() or nil
    if not worn then return out end
    for i = 0, worn:size() - 1 do
        local entry = worn:get(i)
        local item = entry and entry.getItem and entry:getItem() or nil
        if item then
            local bl = item.getBodyLocation and item:getBodyLocation() or ""
            if bl and bl ~= "" and locSet[bl] then
                out[#out + 1] = item
            end
        end
    end
    return out
end

local function wearOutfit(player, slotName, primaryObj, primaryContainer)
    local outfit = CSR_OutfitSetsUtil.getOutfit(player, slotName)
    if not outfit or not outfit.items or #outfit.items == 0 then return end

    -- Face the wardrobe.
    if primaryObj and primaryObj.getSquare then
        local sq = primaryObj:getSquare()
        if sq then player:facePosition(sq:getX(), sq:getY()) end
    end

    -- Build search pool & body-location set we'll be filling.
    local pool = CSR_OutfitSetsUtil.gatherSearchPool(player, primaryContainer, primaryObj)
    local locSet = {}
    for _, e in ipairs(outfit.items) do if e.bl and e.bl ~= "" then locSet[e.bl] = true end end

    -- Pick best matches first (don't actually queue ops yet).
    local picks = {}
    local missing = {}
    local used = {}
    for _, want in ipairs(outfit.items) do
        local entry = CSR_OutfitSetsUtil.pickBestMatch(pool, want.ft, want.bl, used)
        if entry then
            picks[#picks + 1] = { want = want, entry = entry }
            used[entry.item] = true
        else
            missing[#missing + 1] = want.ft
        end
    end

    -- Unequip currently worn items occupying target body locations
    -- that aren't part of our final pick list. Send them to the
    -- primary container (capacity-aware) or drop them otherwise.
    local toRemove = gatherWornAtBodyLocations(player, locSet)
    local stillWearing = {}
    for _, p in ipairs(picks) do stillWearing[p.entry.item] = true end
    local freeWeight = 9999
    if primaryContainer and primaryContainer.getEffectiveCapacity and primaryContainer.getContentsWeight then
        freeWeight = (tonumber(primaryContainer:getEffectiveCapacity(player)) or 0)
                     - (tonumber(primaryContainer:getContentsWeight()) or 0)
    end
    for _, item in ipairs(toRemove) do
        if not stillWearing[item] then
            ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
            local w = (item.getUnequippedWeight and item:getUnequippedWeight()) or 0
            if primaryContainer and w <= freeWeight and item:getContainer() ~= primaryContainer then
                pcall(function()
                    ISTimedActionQueue.add(
                        ISInventoryTransferUtil.newInventoryTransferAction(
                            player, item, item:getContainer(), primaryContainer))
                end)
                freeWeight = freeWeight - w
            end
        end
    end

    -- Queue wear ops. Pull from non-player containers first via vanilla helper.
    for _, p in ipairs(picks) do
        local it = p.entry.item
        local cont = it:getContainer()
        if cont and cont ~= player:getInventory() then
            pcall(function()
                ISInventoryPaneContextMenu.transferIfNeeded(player, it)
            end)
        end
        ISTimedActionQueue.add(ISWearClothing:new(player, it, 50))
    end

    if #missing > 0 then
        local n = #missing
        player:Say(string.format(
            txt("IGUI_CSR_OutfitSets_MissingN", "Missing %d outfit items."),
            n))
    else
        player:Say(txt("IGUI_CSR_OutfitSets_Wearing", "Changing outfit..."))
    end
end

-- ─────────────────────────────────────────────────────
-- Submenu builders
-- ─────────────────────────────────────────────────────
local function addSaveSubmenu(rootSub, player)
    local saveOpt = rootSub:addOption(txt("IGUI_CSR_OutfitSets_Save", "Save current outfit..."))
    local saveSub = ISContextMenu:getNew(rootSub)
    rootSub:addSubMenu(saveOpt, saveSub)
    saveSub:addOption(txt("IGUI_CSR_OutfitSets_NoCategory", "(no category)"),
        nil, function() promptSave(player, nil) end)
    for _, cat in ipairs(CATEGORIES) do
        saveSub:addOption(cat, nil, function() promptSave(player, cat) end)
    end
end

local function addWearSubmenu(rootSub, player, primaryObj, primaryContainer)
    local outfits = CSR_OutfitSetsUtil.getAllOutfits(player)
    local groups = {}
    local hasAny = false
    for name, data in pairs(outfits) do
        hasAny = true
        local cat = (data and data.category) or ""
        if cat == "" then cat = "_" end
        groups[cat] = groups[cat] or {}
        groups[cat][#groups[cat] + 1] = name
    end
    if not hasAny then return end
    local wearOpt = rootSub:addOption(txt("IGUI_CSR_OutfitSets_Wear", "Wear outfit"))
    local wearSub = ISContextMenu:getNew(rootSub)
    rootSub:addSubMenu(wearOpt, wearSub)
    -- Sort categories: real first, "_" last.
    local catNames = {}
    for k, _ in pairs(groups) do catNames[#catNames + 1] = k end
    table.sort(catNames, function(a, b)
        if a == "_" then return false end
        if b == "_" then return true end
        return a < b
    end)
    for _, cat in ipairs(catNames) do
        local list = groups[cat]
        table.sort(list)
        if cat == "_" then
            for _, slot in ipairs(list) do
                wearSub:addOption(slot, nil, function()
                    wearOutfit(player, slot, primaryObj, primaryContainer)
                end)
            end
        else
            local catOpt = wearSub:addOption(cat)
            local catSub = ISContextMenu:getNew(wearSub)
            wearSub:addSubMenu(catOpt, catSub)
            for _, slot in ipairs(list) do
                catSub:addOption(slot, nil, function()
                    wearOutfit(player, slot, primaryObj, primaryContainer)
                end)
            end
        end
    end
end

local function addDeleteSubmenu(rootSub, player)
    local outfits = CSR_OutfitSetsUtil.getAllOutfits(player)
    local names = {}
    for name, _ in pairs(outfits) do names[#names + 1] = name end
    if #names == 0 then return end
    table.sort(names)
    local delOpt = rootSub:addOption(txt("IGUI_CSR_OutfitSets_Delete", "Delete outfit"))
    local delSub = ISContextMenu:getNew(rootSub)
    rootSub:addSubMenu(delOpt, delSub)
    for _, slot in ipairs(names) do
        delSub:addOption(slot, nil, function() promptDelete(player, slot) end)
    end
end

local function addOutfitWardrobeOption(rootSub, player, primaryObj)
    if not isClient or not isClient() then return end
    if not player or not primaryObj then return end
    if CSR_OutfitSetsUtil.capacityBonusPct() <= 0 then return end
    if not CSR_OutfitSetsUtil.isCapacityWardrobeObject(primaryObj) then return end
    local sq = primaryObj.getSquare and primaryObj:getSquare() or nil
    if not sq then return end
    if not CSR_OutfitSetsUtil.playerHasSafehouseAccess(player, sq) then return end

    if CSR_OutfitSetsUtil.isOutfitWardrobeObject(primaryObj) then
        rootSub:addOption(txt("IGUI_CSR_OutfitWardrobe_Revert", "Revert Outfit Wardrobe"),
            nil, function() sendOutfitWardrobeCommand(player, "OutfitWardrobeRevert", primaryObj) end)
    else
        rootSub:addOption(txt("IGUI_CSR_OutfitWardrobe_Convert", "Convert to Outfit Wardrobe"),
            nil, function() sendOutfitWardrobeCommand(player, "OutfitWardrobeConvert", primaryObj) end)
    end
end

-- Public so the LootWindow handler can reuse the same builder.
function CSR_OutfitSets_buildContext(rootSub, player, primaryObj, primaryContainer)
    addOutfitWardrobeOption(rootSub, player, primaryObj)
    addSaveSubmenu(rootSub, player)
    addWearSubmenu(rootSub, player, primaryObj, primaryContainer)
    addDeleteSubmenu(rootSub, player)
end

-- ─────────────────────────────────────────────────────
-- World-object context menu hook (right-click the wardrobe in the world).
-- ─────────────────────────────────────────────────────
local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if test then return end
    if not CSR_OutfitSetsUtil.isEnabled() then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local primaryObj, primaryContainer
    for i = 1, #worldobjects do
        local o = worldobjects[i]
        if CSR_OutfitSetsUtil.isWardrobeObject(o) then
            primaryObj = o
            primaryContainer = o:getContainer()
            break
        end
    end
    if not primaryObj then
        -- Bag-on-ground in safehouse mode only (per design rule).
        if CSR_OutfitSetsUtil.isSafehouseOnly() then
            for i = 1, #worldobjects do
                local o = worldobjects[i]
                if CSR_OutfitSetsUtil.isBagObject(o) then
                    local item = o:getItem()
                    if item and item.getInventory then
                        primaryObj = o
                        primaryContainer = item:getInventory()
                        break
                    end
                end
            end
        end
    end
    if not primaryObj or not primaryContainer then return end

    if not CSR_OutfitSetsUtil.canUseHere(player, primaryObj) then return end

    local rootOpt = context:addOption(txt("IGUI_CSR_OutfitSets_Root", "Outfit Sets"))
    local rootSub = ISContextMenu:getNew(context)
    context:addSubMenu(rootOpt, rootSub)
    CSR_OutfitSets_buildContext(rootSub, player, primaryObj, primaryContainer)
end

if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
end

local function onServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    if command == "OutfitWardrobeSync" then
        local key = tostring(args and args.key or "")
        if key == "" and args then
            key = CSR_OutfitSetsUtil.objectRegistryKeyFromParts(args.x, args.y, args.z, args.sprite)
        end
        CSR_OutfitSetsUtil.setOutfitWardrobeKey(key, args and args.enabled == true)
        CSR_OutfitSetsUtil.refreshInventoryUI()
    elseif command == "OutfitWardrobeSyncAll" then
        CSR_OutfitSetsUtil.replaceOutfitWardrobeSnapshot(args and args.wardrobes or {})
    end
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end

local function requestOutfitWardrobeSync(playerNum)
    if not isClient or not isClient() then return end
    local player = getSpecificPlayer and getSpecificPlayer(playerNum or 0) or getPlayer and getPlayer() or nil
    if player and sendClientCommand then
        sendClientCommand(player, "CommonSenseReborn", "OutfitWardrobeSyncRequest", {})
    end
end

if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(playerNum) requestOutfitWardrobeSync(playerNum or 0) end)
end

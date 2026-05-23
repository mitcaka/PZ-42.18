require "CSR_FeatureFlags"
require "TimedActions/ISInventoryTransferUtil"

--[[
    CSR_LootBag.lua
    Adds an aggregator tab to the loot panel that gathers items from every
    reachable nearby real container (including nested bags inside loot
    containers). Items in our virtual still carry their real :getContainer()
    reference; nested child-item transfers walk to the reachable outer
    container, then transfer from the real nested source container.

    Also:
      - Pin: keep current tab selected across refreshes (default unbound key).
      - Auto-trunk: when a vehicle trunk first becomes reachable, auto-select
        it instead of the floor.

    Clean-room implementation. No code copied from any other mod.
]]

CSR_LootBag = CSR_LootBag or {}

local CONTAINER_TYPE = "csrLootBag"
local DEFAULT_PIN_KEY = 0  -- 0 = unbound (Keyboard.KEY_NONE)
local LOOT_NESTED_MAX_DEPTH = 4

-- Per-player state
local virtuals          = {}  -- [playerNum] = ItemContainer
local pinOn             = {}  -- [playerNum] = bool
local overrideContainer = {}  -- [playerNum] = ItemContainer
local seenTrunkVehs     = {}  -- [playerNum] = { [vehicleId] = true }
local lastVehSet        = {}  -- [playerNum] = { [vehicleId] = true } -- last refresh's set
local nestedSourceMeta  = {}  -- [playerNum] = { [item] = { chain = {}, parentBag = item } }

local LOOT_BAG_ICON = nil
local function getIcon()
    if LOOT_BAG_ICON == nil then
        LOOT_BAG_ICON = getTexture("media/ui/CSR_LootBag.png") or false
    end
    return LOOT_BAG_ICON or nil
end

-- ─── Mod options (key bind) ─────────────────────────────────────────────────
local options, pinKeyBind = nil, nil
if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.create then
    options = PZAPI.ModOptions:create("CommonSenseRebornLootBag", "Common Sense Reborn - Loot Bag")
    if options and options.addKeyBind then
        pinKeyBind = options:addKeyBind("toggleLootBagPin", "Toggle Loot Tab Pin", DEFAULT_PIN_KEY)
    end
end

local function getPinKey()
    if pinKeyBind and pinKeyBind.getValue then
        local v = pinKeyBind:getValue()
        if type(v) == "number" then return v end
    end
    return DEFAULT_PIN_KEY
end

-- ─── Helpers ────────────────────────────────────────────────────────────────
local function isLootBagEnabled()
    if CSR_FeatureFlags.isLootBagEnabled then
        return CSR_FeatureFlags.isLootBagEnabled()
    end
    return true
end

local function isAutoTrunkEnabled()
    if CSR_FeatureFlags.isLootBagAutoTrunkEnabled then
        return CSR_FeatureFlags.isLootBagAutoTrunkEnabled()
    end
    return true
end

local function isVirtual(c)
    return c and c.getType and c:getType() == CONTAINER_TYPE
end

CSR_LootBag.isVirtualContainer = isVirtual

local function getVirtual(playerNum)
    local v = virtuals[playerNum]
    if v then return v end
    v = ItemContainer.new(CONTAINER_TYPE, nil, nil)
    if v.setExplored then v:setExplored(true) end
    if v.setOnlyAcceptCategory then v:setOnlyAcceptCategory("none") end
    if v.setCapacity then v:setCapacity(0) end
    virtuals[playerNum] = v
    return v
end

CSR_LootBag.getVirtualContainer = getVirtual

local function isFloor(c)
    return c and c.getType and c:getType() == "floor"
end

local function appendVirtualItem(virtualItems, item)
    if virtualItems and virtualItems.add then
        virtualItems:add(item)
        return true
    end
    return false
end

local function copyChain(chain)
    local copied = {}
    if chain then
        for i = 1, #chain do
            copied[i] = chain[i]
        end
    end
    return copied
end

local function getItemDisplayName(item)
    if not item then return "" end
    if item.getName then
        local name = item:getName()
        if name and name ~= "" then return name end
    end
    if item.getDisplayName then
        local name = item:getDisplayName()
        if name and name ~= "" then return name end
    end
    if item.getFullType then
        local name = item:getFullType()
        if name and name ~= "" then return name end
    end
    return "Container"
end

local function chainText(chain)
    if not chain or #chain == 0 then return "" end
    local names = {}
    for i = 1, #chain do
        names[#names + 1] = getItemDisplayName(chain[i])
    end
    return table.concat(names, " > ")
end

local function rememberNestedSource(meta, item, chain, sourceContainer)
    if not meta or not item or not chain or #chain == 0 then return end
    meta[item] = {
        chain = copyChain(chain),
        parentBag = chain[#chain],
        sourceContainer = sourceContainer,
    }
end

local function collectItemsRecursive(container, out, seen, depth, playerObj, skipUnwanted)
    if not container or not container.getItems then return 0 end
    depth = depth or 0
    if depth > LOOT_NESTED_MAX_DEPTH then return 0 end
    seen = seen or {}
    if seen[container] then return 0 end
    seen[container] = true

    local items = container:getItems()
    if not items or not items.size then return 0 end

    local added = 0
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local wanted = true
            if skipUnwanted and playerObj and item.isUnwanted then
                wanted = not item:isUnwanted(playerObj)
            end
            if wanted then
                out[#out + 1] = item
                added = added + 1
            end
            if item.getInventory then
                local nested = item:getInventory()
                if nested then
                    added = added + collectItemsRecursive(nested, out, seen,
                        depth + 1, playerObj, skipUnwanted)
                end
            end
        end
    end
    return added
end

local function collectTopLevelItems(container, out, playerObj, skipUnwanted)
    if not container or not container.getItems then return 0 end
    local items = container:getItems()
    if not items or not items.size then return 0 end

    local added = 0
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local wanted = true
            if skipUnwanted and playerObj and item.isUnwanted then
                wanted = not item:isUnwanted(playerObj)
            end
            if wanted then
                out[#out + 1] = item
                added = added + 1
            end
        end
    end
    return added
end

local function addItemsRecursiveToVirtual(virtual, container, seen, depth, chain, meta, sourceContainer)
    if not virtual or not virtual.getItems then return 0 end
    if not container or not container.getItems then return 0 end
    depth = depth or 0
    if depth > LOOT_NESTED_MAX_DEPTH then return 0 end
    seen = seen or {}
    if seen[container] then return 0 end
    seen[container] = true

    local items = container:getItems()
    if not items or not items.size then return 0 end

    local virtualItems = virtual:getItems()
    local added = 0
    chain = chain or {}
    sourceContainer = sourceContainer or container

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            rememberNestedSource(meta, item, chain, sourceContainer)
            if appendVirtualItem(virtualItems, item) then
                added = added + 1
            end
            if item.getInventory then
                local nested = item:getInventory()
                if nested then
                    local nestedChain = copyChain(chain)
                    nestedChain[#nestedChain + 1] = item
                    added = added + addItemsRecursiveToVirtual(virtual, nested, seen,
                        depth + 1, nestedChain, meta, sourceContainer)
                end
            end
        end
    end
    return added
end

local function isPlayerOwned(c, playerObj)
    if not c or not playerObj then return false end
    local p = c.getParent and c:getParent()
    if not p then
        -- Containers worn or in the player's inventory typically have no parent IsoObject;
        -- check the OUTERMOST container's parent.
        if c.getOutermostContainer then
            local out = c:getOutermostContainer()
            if out and out:getParent() == nil and out:getContainingItem() then
                local containing = out:getContainingItem()
                if containing.getContainer and containing:getContainer() == playerObj:getInventory() then
                    return true
                end
            end
        end
        return false
    end
    return false
end

local function vehiclePartTrunkIdOrNil(c)
    if not c or not c.getVehiclePart then return nil end
    local part = c:getVehiclePart()
    if not part then return nil end
    local id = part.getId and part:getId() or ""
    if id == "TrunkDoor" or id == "TruckBed" or id == "TrailerTrunk" then
        local vehicle = part.getVehicle and part:getVehicle()
        if vehicle and vehicle.getId then
            return vehicle:getId()
        end
    end
    return nil
end

-- ─── Aggregation ────────────────────────────────────────────────────────────
local function aggregateInto(virtual, page, playerObj)
    if not virtual or not page or not page.backpacks then return 0 end
    if virtual.clear then virtual:clear() end
    local playerNum = page.player or 0
    nestedSourceMeta[playerNum] = {}
    local sourceMeta = nestedSourceMeta[playerNum]
    local realCount = 0
    local seen = {}
    for i = 1, #page.backpacks do
        local btn = page.backpacks[i]
        local src = btn and btn.inventory
        if src and not isVirtual(src) and not isFloor(src) then
            -- Only include containers that are NOT player-owned (we are loot-only).
            -- Player-owned tabs already work via vanilla; including them would let
            -- crafting and transfer pickers see duplicate item references.
            local p = src.getParent and src:getParent()
            local isPlayerSide = false
            if not p then
                -- No parent IsoObject = either the player's own inventory or a worn bag.
                -- Both are player-side. Skip.
                isPlayerSide = true
            end
            if not isPlayerSide then
                local added = addItemsRecursiveToVirtual(virtual, src, seen, 0, {}, sourceMeta, src)
                if added > 0 then
                    realCount = realCount + 1
                end
            end
        end
    end
    return realCount
end

-- Count nearby non-virtual non-floor real loot sources.
local function countRealLootSources(page)
    if not page or not page.backpacks then return 0 end
    local n = 0
    local seen = {}
    for i = 1, #page.backpacks do
        local src = page.backpacks[i] and page.backpacks[i].inventory
        if src and not isVirtual(src) and not isFloor(src) then
            local p = src.getParent and src:getParent()
            if p then
                local collected = {}
                if collectItemsRecursive(src, collected, seen, 0, nil, false) > 0 then
                    n = n + 1
                end
            end
        end
    end
    return n
end

local function findVirtualButton(page)
    if not page or not page.backpacks then return nil end
    for i = 1, #page.backpacks do
        local btn = page.backpacks[i]
        if btn and isVirtual(btn.inventory) then return btn end
    end
    return nil
end

local function findButtonForContainer(page, container)
    if not page or not page.backpacks or not container then return nil end
    for i = 1, #page.backpacks do
        local btn = page.backpacks[i]
        if btn and btn.inventory == container then return btn end
    end
    return nil
end

-- ─── Refresh handlers ───────────────────────────────────────────────────────
local function onButtonsAdded(page)
    if page.onCharacter then return end
    if not isLootBagEnabled() then return end
    if not page.backpacks then return end

    local playerNum = page.player or 0
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    local virtual = getVirtual(playerNum)
    -- Aggregate first and use that result as the presence check so nested
    -- containers are only scanned once per refresh.
    if aggregateInto(virtual, page, playerObj) < 1 then return end

    local title = getText("IGUI_CSR_LootBag_TabName") or "Nearby Loot"
    local btn = page:addContainerButton(virtual, getIcon(), title, title)
    if btn then btn._csrLootBag = true end
end

local function trackVehicleSet(page, playerNum)
    -- Record vehicle ids present this refresh; if a NEW trunk vehicle id appears,
    -- auto-select the trunk container.
    local vehSet = {}
    local newTrunkContainer = nil
    if page and page.backpacks then
        for i = 1, #page.backpacks do
            local src = page.backpacks[i] and page.backpacks[i].inventory
            if src then
                local vehId = vehiclePartTrunkIdOrNil(src)
                if vehId then
                    vehSet[vehId] = true
                    seenTrunkVehs[playerNum] = seenTrunkVehs[playerNum] or {}
                    if not seenTrunkVehs[playerNum][vehId] then
                        seenTrunkVehs[playerNum][vehId] = true
                        if newTrunkContainer == nil then
                            newTrunkContainer = src
                        end
                    end
                end
            end
        end
    end
    -- Forget vehicles no longer in range so revisits re-trigger auto-pick.
    local seen = seenTrunkVehs[playerNum]
    if seen then
        for vehId, _ in pairs(seen) do
            if not vehSet[vehId] then seen[vehId] = nil end
        end
    end
    lastVehSet[playerNum] = vehSet
    return newTrunkContainer
end

local function applySelection(page, container)
    if not page or not container then return end
    if page.inventoryPane then
        page.inventoryPane.inventory = container
        page.inventoryPane.lastinventory = container
    end
    page.inventory = container
    page.title = nil
    if page.backpacks then
        for _, b in ipairs(page.backpacks) do
            if b.inventory == container then
                page.selectedButton = b
                if b.setBackgroundRGBA then b:setBackgroundRGBA(0.7, 0.7, 0.7, 1.0) end
                if b.name then page.title = b.name end
            else
                if b.setBackgroundRGBA then b:setBackgroundRGBA(0.0, 0.0, 0.0, 0.0) end
            end
        end
    end
    if page.inventoryPane and page.inventoryPane.refreshContainer then
        page.inventoryPane:refreshContainer()
    end
end

local function onRefreshEnd(page)
    if page.onCharacter then return end
    if not isLootBagEnabled() then return end
    local playerNum = page.player or 0

    -- 1. Pin: keep override pinned across refreshes.
    if pinOn[playerNum] then
        local target = overrideContainer[playerNum]
        if target then
            local btn = findButtonForContainer(page, target)
            if btn then
                applySelection(page, target)
                return
            else
                -- Pinned container no longer present; release the override.
                overrideContainer[playerNum] = nil
            end
        end
    end

    -- 2. Auto-trunk: pick the trunk on first encounter only.
    if isAutoTrunkEnabled() then
        local newTrunk = trackVehicleSet(page, playerNum)
        if newTrunk then
            applySelection(page, newTrunk)
            return
        end
    else
        -- Even if auto-trunk is off, keep the seen-set updated so toggling
        -- the option mid-game does not produce a delayed retro-pin.
        trackVehicleSet(page, playerNum)
    end
end

local function onRefreshContainers(page, stage)
    if stage == "buttonsAdded" then
        onButtonsAdded(page)
    elseif stage == "end" then
        onRefreshEnd(page)
    end
end

-- ─── Pin keybind ────────────────────────────────────────────────────────────
local function togglePin()
    local player = getPlayer and getPlayer()
    if not player then return end
    local playerNum = player:getPlayerNum() or 0

    pinOn[playerNum] = not pinOn[playerNum]
    if pinOn[playerNum] then
        -- Pin the currently displayed container.
        local lootWindow = getPlayerLoot and getPlayerLoot(playerNum)
        if lootWindow and lootWindow.inventory then
            overrideContainer[playerNum] = lootWindow.inventory
        end
        HaloTextHelper.addText(player, getText("IGUI_CSR_LootBag_PinOn") or "Loot tab pinned",
            "", HaloTextHelper.getColorWhite())
    else
        overrideContainer[playerNum] = nil
        HaloTextHelper.addText(player, getText("IGUI_CSR_LootBag_PinOff") or "Loot tab unpinned",
            "", HaloTextHelper.getColorWhite())
    end
    if ISInventoryPage and ISInventoryPage.dirtyUI then ISInventoryPage.dirtyUI() end
end
CSR_LootBag.togglePin = togglePin

local function onKeyPressed(key)
    local pk = getPinKey()
    if pk and pk ~= 0 and key == pk then togglePin() end
end

-- ─── Bulk actions: Loot All / Move To Floor (when virtual selected) ─────────
local queueVirtualTransfers
local filterItemsCarriedBySelectedContainers

local function lootAllFromVirtual(page)
    local playerNum = page.player or 0
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end
    local playerInv = playerObj:getInventory()
    if not playerInv or not page.backpacks then return end

    local seenSrc = {}
    for i = 1, #page.backpacks do
        local src = page.backpacks[i] and page.backpacks[i].inventory
        if src and not seenSrc[src] and not isVirtual(src) and not isFloor(src) then
            seenSrc[src] = true
            local p = src.getParent and src:getParent()
            if p and luautils and luautils.walkToContainer and luautils.walkToContainer(src, playerNum) then
                local items = {}
                collectItemsRecursive(src, items, {}, 0, playerObj, true)
                if #items > 0 and page.inventoryPane and page.inventoryPane.transferItemsByWeight then
                    page.inventoryPane:transferItemsByWeight(items, playerInv)
                end
            end
        end
    end
    if page.inventoryPane then page.inventoryPane.selected = {} end
end

local function moveAllToFloorFromVirtual(page)
    if isGamePaused() then return end
    local playerNum = page.player or 0
    local floorContainer = ISInventoryPage and ISInventoryPage.GetFloorContainer and ISInventoryPage.GetFloorContainer(playerNum)
    if not floorContainer or not page.backpacks then return end

    local items = {}
    local seenSrc = {}
    for i = 1, #page.backpacks do
        local src = page.backpacks[i] and page.backpacks[i].inventory
        if src and not seenSrc[src] and not isVirtual(src) and not isFloor(src) then
            seenSrc[src] = true
            local p = src.getParent and src:getParent()
            if p then
                collectItemsRecursive(src, items, {}, 0, nil, false)
            end
        end
    end
    if #items > 0 then
        if page.inventoryPane then
            queueVirtualTransfers(page.inventoryPane, items, floorContainer)
        elseif ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onMoveItemsTo then
            ISInventoryPaneContextMenu.onMoveItemsTo(filterItemsCarriedBySelectedContainers(items), floorContainer, playerNum)
        end
    end
    if page.inventoryPane then page.inventoryPane.selected = {} end
end

CSR_LootBag.lootAllFromVirtual         = lootAllFromVirtual
CSR_LootBag.moveAllToFloorFromVirtual  = moveAllToFloorFromVirtual

local function isInventoryItem(value)
    if not value then return false end
    if instanceof and instanceof(value, "InventoryItem") then return true end
    return value.getContainer and value.getFullType
end

local function rowPrimaryItem(row)
    if isInventoryItem(row) then return row end
    if type(row) == "table" and row.items then
        for i = 1, #row.items do
            if isInventoryItem(row.items[i]) then
                return row.items[i]
            end
        end
    end
    return nil
end

local function rowContainsItem(row, target)
    if not target then return false end
    if rowPrimaryItem(row) == target then return true end
    if type(row) == "table" and row.items then
        for i = 1, #row.items do
            if row.items[i] == target then return true end
        end
    end
    return false
end

local function rowNestedMeta(row, meta)
    if not meta then return nil end
    local item = rowPrimaryItem(row)
    if item and meta[item] then return meta[item] end
    if type(row) == "table" and row.items then
        for i = 1, #row.items do
            item = row.items[i]
            if item and meta[item] then return meta[item] end
        end
    end
    return nil
end

local function itemNestedMeta(playerNum, item)
    if not item then return nil end
    local meta = nestedSourceMeta[playerNum or 0]
    return meta and meta[item] or nil
end

local function addUniqueActualItem(out, seen, item)
    if not isInventoryItem(item) then return end
    local key = item
    if item.getID then
        local ok, id = pcall(function() return item:getID() end)
        if ok and id ~= nil then key = id end
    end
    if seen[key] then return end
    seen[key] = true
    out[#out + 1] = item
end

local function actualItemsFrom(value)
    local out = {}
    local seen = {}

    if not value then return out end

    if ISInventoryPane and ISInventoryPane.getActualItems then
        local ok, actual = pcall(function() return ISInventoryPane.getActualItems(value) end)
        if ok and actual then
            for _, item in ipairs(actual) do
                addUniqueActualItem(out, seen, item)
            end
            if #out > 0 then return out end
        end
    end

    if isInventoryItem(value) then
        addUniqueActualItem(out, seen, value)
    elseif instanceof and instanceof(value, "ArrayList") then
        local ok, size = pcall(function() return value:size() end)
        if ok and type(size) == "number" then
            for i = 0, size - 1 do
                addUniqueActualItem(out, seen, value:get(i))
            end
        end
    elseif type(value) == "table" then
        local source = value.items or value
        for _, item in ipairs(source) do
            addUniqueActualItem(out, seen, item)
        end
    end

    return out
end

local function listContains(list, value)
    if not list or not value then return false end
    local ok, result = pcall(function() return list:contains(value) end)
    return ok and result == true
end

local function appendContainerUnique(list, container)
    if not list or not container or isVirtual(container) then return end
    if listContains(list, container) then return end
    pcall(function() list:add(container) end)
end

local containerInCharacterInventory

local function appendNestedSourceContainers(list, playerNum, playerObj)
    local meta = nestedSourceMeta[playerNum or 0]
    if not meta then return end

    local seen = {}
    for item, info in pairs(meta) do
        local src = item and item.getContainer and item:getContainer() or nil
        local root = info and info.sourceContainer or nil
        local rootReachable = root and (listContains(list, root)
            or (playerObj and containerInCharacterInventory(root, playerObj)))
        if src and rootReachable and not seen[src] then
            seen[src] = true
            appendContainerUnique(list, src)
        end
    end
end

function containerInCharacterInventory(container, playerObj)
    if not container or not playerObj then return false end
    if container == playerObj:getInventory() then return true end
    if container.isInCharacterInventory then
        local ok, result = pcall(function() return container:isInCharacterInventory(playerObj) end)
        return ok and result == true
    end
    return false
end

local function selectedContainerInventories(items)
    local selected = {}
    for _, item in ipairs(items or {}) do
        if item and item.getInventory then
            local nested = item:getInventory()
            if nested then selected[nested] = true end
        end
    end
    return selected
end

local function isInsideSelectedContainer(item, selectedContainers)
    if not item or not selectedContainers then return false end
    local container = item.getContainer and item:getContainer() or nil
    while container do
        if selectedContainers[container] then return true end
        local parentItem = container.getContainingItem and container:getContainingItem() or nil
        if not parentItem or not parentItem.getContainer then return false end
        container = parentItem:getContainer()
    end
    return false
end

function filterItemsCarriedBySelectedContainers(items)
    local selectedContainers = selectedContainerInventories(items)
    local filtered = {}
    for _, item in ipairs(items or {}) do
        if not isInsideSelectedContainer(item, selectedContainers) then
            filtered[#filtered + 1] = item
        end
    end
    return filtered
end

local function canQueueTransfer(playerObj, item, destContainer)
    if not playerObj or not item or not destContainer then return false end
    local srcContainer = item.getContainer and item:getContainer() or nil
    if not srcContainer or srcContainer == destContainer then return false end
    if destContainer.isInside and destContainer:isInside(item) then return false end
    if item.isFavorite and item:isFavorite() and not containerInCharacterInventory(destContainer, playerObj) then
        return false
    end
    if srcContainer.isRemoveItemAllowed and not srcContainer:isRemoveItemAllowed(item) then
        return false
    end
    if destContainer.isItemAllowed and not destContainer:isItemAllowed(item) then
        return false
    end
    return true
end

local function newTransferAction(playerObj, item, srcContainer, destContainer)
    if ISInventoryTransferUtil and ISInventoryTransferUtil.newInventoryTransferAction then
        return ISInventoryTransferUtil.newInventoryTransferAction(playerObj, item, srcContainer, destContainer)
    end
    if ISInventoryTransferAction then
        return ISInventoryTransferAction:new(playerObj, item, srcContainer, destContainer)
    end
    return nil
end

function queueVirtualTransfers(pane, items, destContainer, nestedOnly)
    if not pane or not destContainer then return false, 0 end

    local playerNum = pane.player or 0
    local playerObj = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
    if not playerObj then return false, 0 end

    local actual = filterItemsCarriedBySelectedContainers(actualItemsFrom(items))
    if #actual == 0 then return false, 0 end

    if pane.sortItemsByTypeAndWeight then
        pcall(function() pane:sortItemsByTypeAndWeight(actual) end)
    end

    local walkedRoots = {}
    local queued = 0
    for _, item in ipairs(actual) do
        local meta = itemNestedMeta(playerNum, item)
        if (not nestedOnly or meta) and canQueueTransfer(playerObj, item, destContainer) then
            local srcContainer = item:getContainer()
            local rootContainer = (meta and meta.sourceContainer) or srcContainer
            if rootContainer and not walkedRoots[rootContainer] then
                if not containerInCharacterInventory(rootContainer, playerObj)
                    and luautils and luautils.walkToContainer
                    and not luautils.walkToContainer(rootContainer, playerNum) then
                    break
                end
                walkedRoots[rootContainer] = true
            end

            local action = newTransferAction(playerObj, item, srcContainer, destContainer)
            if action then
                if meta and rootContainer then
                    action._csrLootBagSelectedContainer = rootContainer
                end
                ISTimedActionQueue.add(action)
                queued = queued + 1
            end
        end
    end

    if queued > 0 then
        pane.selected = {}
        local lootWindow = getPlayerLoot and getPlayerLoot(playerNum) or nil
        if lootWindow and lootWindow.inventoryPane then lootWindow.inventoryPane.selected = {} end
        local invWindow = getPlayerInventory and getPlayerInventory(playerNum) or nil
        if invWindow and invWindow.inventoryPane then invWindow.inventoryPane.selected = {} end
    end

    return queued > 0, queued
end

CSR_LootBag.queueVirtualTransfers = queueVirtualTransfers

local function focusedNestedMeta(pane)
    if not pane or not pane.items then return nil end
    local playerNum = pane.player or 0
    local meta = nestedSourceMeta[playerNum]
    if not meta then return nil end

    local mouseRow = pane.mouseOverOption or 0
    if mouseRow > 0 and pane.items[mouseRow] then
        local hovered = rowNestedMeta(pane.items[mouseRow], meta)
        if hovered then return hovered end
    end

    if pane.selected then
        for key, value in pairs(pane.selected) do
            local row = nil
            if type(key) == "number" and pane.items[key] then
                row = pane.items[key]
            elseif value ~= false then
                row = value
            end
            local selected = rowNestedMeta(row, meta)
            if selected then return selected end
        end
    end
    return nil
end

local function drawVisibleNestedRowMarkers(pane, meta)
    if not pane or not pane.items or not meta then return end
    local itemHgt = pane.itemHgt or 18
    local headerHgt = pane.headerHgt or 0
    local yScroll = 0
    if pane.getYScroll then
        yScroll = pane:getYScroll()
    elseif pane.yScroll then
        yScroll = pane.yScroll
    end

    local paneW = pane.getWidth and pane:getWidth() or pane.width or 0
    local paneH = pane.getHeight and pane:getHeight() or pane.height or 0
    for rowIndex, row in ipairs(pane.items) do
        if rowNestedMeta(row, meta) then
            local y = headerHgt + ((rowIndex - 1) * itemHgt) + yScroll
            if y + itemHgt >= headerHgt and y <= paneH then
                pane:drawRect(1, y, paneW - 2, itemHgt, 0.14, 0.16, 0.62, 0.95)
                pane:drawRect(1, y + 1, 4, math.max(1, itemHgt - 2), 0.95, 0.12, 0.82, 1.0)
                if pane.drawRectBorder then
                    pane:drawRectBorder(1, y, paneW - 2, itemHgt, 0.40, 0.30, 0.92, 1.0)
                end
            end
        end
    end
end

local function drawNestedSourceCue(pane)
    if not pane or not isVirtual(pane.inventory) or not pane.items then return end
    local playerNum = pane.player or 0
    local allMeta = nestedSourceMeta[playerNum]
    drawVisibleNestedRowMarkers(pane, allMeta)

    local meta = focusedNestedMeta(pane)
    if not meta or not meta.parentBag then return end

    local itemHgt = pane.itemHgt or 18
    local headerHgt = pane.headerHgt or 0
    local yScroll = 0
    if pane.getYScroll then
        yScroll = pane:getYScroll()
    elseif pane.yScroll then
        yScroll = pane.yScroll
    end

    local paneW = pane.getWidth and pane:getWidth() or pane.width or 0
    local paneH = pane.getHeight and pane:getHeight() or pane.height or 0
    for rowIndex, row in ipairs(pane.items) do
        if rowContainsItem(row, meta.parentBag) then
            local y = headerHgt + ((rowIndex - 1) * itemHgt) + yScroll
            if y + itemHgt >= headerHgt and y <= paneH then
                pane:drawRect(1, y, paneW - 2, itemHgt, 0.22, 1.0, 0.58, 0.02)
                pane:drawRect(1, y + 1, 4, math.max(1, itemHgt - 2), 0.95, 1.0, 0.62, 0.05)
                if pane.drawRectBorder then
                    pane:drawRectBorder(1, y, paneW - 2, itemHgt, 1.0, 1.0, 0.78, 0.12)
                end
            end
            break
        end
    end

    local path = chainText(meta.chain)
    if path == "" then return end
    local text = getText("IGUI_CSR_LootBag_Inside", path)
    if not text or text == "IGUI_CSR_LootBag_Inside" then
        text = "Inside: " .. path
    end
    local font = UIFont.Small
    local tm = getTextManager and getTextManager()
    local textW = tm and tm:MeasureStringX(font, text) or 180
    local textH = tm and tm:getFontHeight(font) or 12
    local boxW = math.min(textW + 12, math.max(80, paneW - 8))
    local boxH = textH + 6
    local x = 4
    local y = math.max(headerHgt + 2, paneH - boxH - 4)

    pane:drawRect(x, y, boxW, boxH, 0.84, 0.02, 0.02, 0.02)
    if pane.drawRectBorder then
        pane:drawRectBorder(x, y, boxW, boxH, 0.85, 0.95, 0.72, 0.12)
    end
    pane:drawText(text, x + 6, y + 3, 1.0, 0.84, 0.28, 1.0, font)
end

local function clearDragState(targetPane, sourcePane)
    for _, pane in ipairs({ targetPane, sourcePane }) do
        if pane then
            pane.selected = {}
            pane.dragging = nil
            pane.dragStarted = false
            pane.draggingMarquis = false
        end
    end

    local playerNum = (targetPane and targetPane.player) or (sourcePane and sourcePane.player) or 0
    local lootWindow = getPlayerLoot and getPlayerLoot(playerNum) or nil
    if lootWindow and lootWindow.inventoryPane then lootWindow.inventoryPane.selected = {} end
    local invWindow = getPlayerInventory and getPlayerInventory(playerNum) or nil
    if invWindow and invWindow.inventoryPane then invWindow.inventoryPane.selected = {} end

    if ISMouseDrag then
        ISMouseDrag.draggingFocus = nil
        ISMouseDrag.dragging = nil
    end
end

local function getDraggedItems()
    if not ISMouseDrag or not ISMouseDrag.dragging then return nil end
    if ISInventoryPane and ISInventoryPane.getActualItems then
        return ISInventoryPane.getActualItems(ISMouseDrag.dragging)
    end
    return ISMouseDrag.dragging
end

local function blockNestedVirtualDrop(targetPane)
    if not targetPane or not targetPane.inventory or isVirtual(targetPane.inventory) then return false end
    if not ISMouseDrag or not ISMouseDrag.dragging or not ISMouseDrag.draggingFocus then return false end

    local sourcePane = ISMouseDrag.draggingFocus
    if sourcePane == targetPane or not sourcePane.inventory or not isVirtual(sourcePane.inventory) then return false end

    local playerNum = targetPane.player or sourcePane.player or 0
    local playerObj = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
    if not playerObj then return false end

    local dest = targetPane.inventory
    if not containerInCharacterInventory(dest, playerObj) then
        return false
    end
    if targetPane.canPutIn and not targetPane:canPutIn() then
        return false
    end

    local dragged = actualItemsFrom(getDraggedItems())
    if not dragged then return false end

    local hasNested = false
    for _, item in ipairs(dragged) do
        if itemNestedMeta(playerNum, item) then
            hasNested = true
            break
        end
    end
    if not hasNested then return false end

    queueVirtualTransfers(sourcePane, dragged, dest)
    clearDragState(targetPane, sourcePane)
    if ISInventoryPage and ISInventoryPage.dirtyUI then ISInventoryPage.dirtyUI() end
    return true
end

local function blockNestedVirtualActivation(pane)
    if not pane or not pane.inventory or not isVirtual(pane.inventory) then return false end
    local playerNum = pane.player or 0
    local meta = nestedSourceMeta[playerNum]
    if not meta or not pane.items then return false end

    local rowIndex = pane.mouseOverOption or 0
    if rowIndex <= 0 or not pane.items[rowIndex] then return false end
    local row = pane.items[rowIndex]
    if not rowNestedMeta(row, meta) then return false end

    local playerObj = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
    local playerInv = playerObj and playerObj:getInventory() or nil
    if playerInv then
        queueVirtualTransfers(pane, actualItemsFrom(row), playerInv)
    end

    pane.previousMouseUp = nil
    if pane.selected then pane.selected = {} end
    if ISInventoryPage and ISInventoryPage.dirtyUI then ISInventoryPage.dirtyUI() end
    return true
end

-- ─── Vanilla wraps (installed at OnGameStart) ───────────────────────────────
local _wrapsInstalled = false

local function installWraps()
    if _wrapsInstalled then return end
    _wrapsInstalled = true

    -- Orphaned virtual containers have no parent square. Vanilla's
    -- backpack-tab right-click path assumes one exists, so short-circuit
    -- the Nearby Loot tab and route it to CSR's loot filter menu instead.
    if ISInventoryPage
            and not ISInventoryPage.__csrLootBagRightClickGuard
            and type(ISInventoryPage.onBackpackRightMouseDown) == "function" then
        ISInventoryPage.__csrLootBagRightClickGuard = true
        local _origRightClick = ISInventoryPage.onBackpackRightMouseDown
        function ISInventoryPage:onBackpackRightMouseDown(button, ...)
            local inv = button and button.inventory or nil
            if isVirtual(inv) then
                if CSR_LootFilter and CSR_LootFilter.openFilterDropdown then
                    CSR_LootFilter.openFilterDropdown(button)
                end
                return
            end
            return _origRightClick(self, button, ...)
        end
    end

    -- 1. Hide virtual from crafting ingredient picker.
    if ISCraftingUI and ISCraftingUI.getContainers then
        local _orig = ISCraftingUI.getContainers
        ISCraftingUI.getContainers = function(self, ...)
            local r = _orig(self, ...)
            if self and self.containerList and self.playerNum ~= nil then
                local v = virtuals[self.playerNum]
                if v then pcall(function() self.containerList:remove(v) end) end
            end
            return r
        end
    end

    -- 2. Hide virtual from "Move to ..." destination picker.
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getContainers then
        local _orig = ISInventoryPaneContextMenu.getContainers
        ISInventoryPaneContextMenu.getContainers = function(character, ...)
            local list = _orig(character, ...)
            if list and character and character.getPlayerNum then
                appendNestedSourceContainers(list, character:getPlayerNum(), character)
                local v = virtuals[character:getPlayerNum()]
                if v then pcall(function() list:remove(v) end) end
            end
            return list
        end
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
        local _orig = ISInventoryPaneContextMenu.transferIfNeeded
        ISInventoryPaneContextMenu.transferIfNeeded = function(playerObj, item, ...)
            if isInventoryItem(item) then
                local playerNum = playerObj and playerObj.getPlayerNum and playerObj:getPlayerNum() or 0
                if playerObj and playerObj.getInventory and itemNestedMeta(playerNum, item) then
                    queueVirtualTransfers({ player = playerNum, selected = {} }, { item }, playerObj:getInventory())
                    return
                end
            end
            return _orig(playerObj, item, ...)
        end
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onGrabItems then
        local _orig = ISInventoryPaneContextMenu.onGrabItems
        ISInventoryPaneContextMenu.onGrabItems = function(items, player)
            local actual = actualItemsFrom(items)
            for _, item in ipairs(actual) do
                if itemNestedMeta(player, item) then
                    local playerObj = getSpecificPlayer(player)
                    local playerInv = playerObj and playerObj:getInventory() or nil
                    if playerInv then
                        queueVirtualTransfers({ player = player, selected = {} }, items, playerInv)
                    end
                    return
                end
            end
            return _orig(items, player)
        end
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onGrabOneItems then
        local _orig = ISInventoryPaneContextMenu.onGrabOneItems
        ISInventoryPaneContextMenu.onGrabOneItems = function(items, player)
            local playerObj = getSpecificPlayer(player)
            local playerInv = playerObj and playerObj:getInventory() or nil
            if playerInv then
                for _, item in ipairs(actualItemsFrom(items)) do
                    if item:getContainer() ~= playerInv then
                        if itemNestedMeta(player, item) then
                            queueVirtualTransfers({ player = player, selected = {} }, { item }, playerInv)
                            return
                        end
                        break
                    end
                end
            end
            return _orig(items, player)
        end
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onMoveItemsTo then
        local _orig = ISInventoryPaneContextMenu.onMoveItemsTo
        ISInventoryPaneContextMenu.onMoveItemsTo = function(items, dest, player)
            for _, item in ipairs(actualItemsFrom(items)) do
                if itemNestedMeta(player, item) then
                    queueVirtualTransfers({ player = player, selected = {} }, items, dest)
                    return
                end
            end
            return _orig(items, dest, player)
        end
    end

    if ISInventoryTransferAction and ISInventoryTransferAction.startActionAnim then
        local _orig = ISInventoryTransferAction.startActionAnim
        function ISInventoryTransferAction:startActionAnim(...)
            local result = _orig(self, ...)
            if self._csrLootBagSelectedContainer then
                self.selectedContainer = self._csrLootBagSelectedContainer
            end
            return result
        end
    end

    -- 3. Inject TakeAll + MoveToFloor buttons when virtual is the selected tab.
    if ISLootWindowContainerControls and ISLootWindowContainerControls.arrange then
        local _orig = ISLootWindowContainerControls.arrange
        function ISLootWindowContainerControls:arrange()
            _orig(self)
            local lw = self.lootWindow
            local container = lw and lw.inventoryPane and lw.inventoryPane.inventory
            if not isVirtual(container) then return end
            -- Only show bulk buttons when we have real sources to act on.
            local hasRealSources = false
            for i = 1, #lw.backpacks do
                local src = lw.backpacks[i] and lw.backpacks[i].inventory
                if src and not isVirtual(src) and not isFloor(src) then
                    local p = src.getParent and src:getParent()
                    if p then hasRealSources = true break end
                end
            end
            if not hasRealSources then return end

            local FONT_HGT = getTextManager():getFontHeight(UIFont.Small)
            local btnH = 2 + FONT_HGT + 2
            local x = 1
            local y = 1
            for _, ctrl in ipairs(self.controls) do
                if ctrl:getRight() + 10 > x then x = ctrl:getRight() + 10 end
            end

            if not self._csrLootBagTakeAll then
                local b = ISButton:new(x, y, 80, btnH,
                    getText("IGUI_invpage_Loot_all") or "Loot All",
                    self, function() lootAllFromVirtual(lw) end)
                b:initialise()
                if b.setWidthToTitle then b:setWidthToTitle() end
                b.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
                self._csrLootBagTakeAll = b
            end
            self._csrLootBagTakeAll:setX(x)
            self._csrLootBagTakeAll:setY(y)
            self._csrLootBagTakeAll:setVisible(true)
            self:addChild(self._csrLootBagTakeAll)
            table.insert(self.controls, self._csrLootBagTakeAll)
            x = self._csrLootBagTakeAll:getRight() + 10

            if not self._csrLootBagMoveFloor then
                local label = (getTextOrNull and getTextOrNull("ContextMenu_MoveToFloor")) or "Move To Floor"
                local b = ISButton:new(x, y, 110, btnH, label, self,
                    function() moveAllToFloorFromVirtual(lw) end)
                b:initialise()
                if b.setWidthToTitle then b:setWidthToTitle() end
                b.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
                self._csrLootBagMoveFloor = b
            end
            self._csrLootBagMoveFloor:setX(x)
            self._csrLootBagMoveFloor:setY(y)
            self._csrLootBagMoveFloor:setVisible(true)
            self:addChild(self._csrLootBagMoveFloor)
            table.insert(self.controls, self._csrLootBagMoveFloor)

            self:setHeight(math.max(self:getHeight(), y + btnH + 1))
            self:setVisible(true)
        end
    end

    -- 4. Scroll wheel: when virtual is selected, vanilla getCurrentBackpackIndex
    --    returns -1 (virtual is not in backpacks for this lookup pattern).
    --    Resolve via selectedButton so the wheel cycles real tabs instead of
    --    falling through to the camera (which would zoom).
    if ISInventoryPage and ISInventoryPage.onMouseWheel then
        local _orig = ISInventoryPage.onMouseWheel
        function ISInventoryPage:onMouseWheel(del)
            if self.onCharacter or not isLootBagEnabled() then
                return _orig(self, del)
            end
            if not isVirtual(self.inventory) then
                return _orig(self, del)
            end
            -- Mouse must be over the icon column to consume the scroll.
            local overColumn = self:getMouseX() >= (self:getWidth() - self.buttonSize)
            if not overColumn and not self:isCycleContainerKeyDown() then
                return true  -- swallow so camera does not zoom
            end
            -- Resolve current index via selectedButton.
            local currentIndex = -1
            if self.selectedButton and self.backpacks then
                for i = 1, #self.backpacks do
                    if self.backpacks[i] == self.selectedButton then
                        currentIndex = i
                        break
                    end
                end
            end
            local ms = getTimestampMs()
            self.lastMouseWheelMS = self.lastMouseWheelMS or 0
            local wrap = (self.containerButtonPanel.height > self.containerButtonPanel:getScrollHeight())
                or (ms - self.lastMouseWheelMS > 750)
            self.lastMouseWheelMS = ms
            local idx = -1
            if del < 0 then
                idx = self:prevUnlockedContainer(currentIndex, wrap)
            else
                idx = self:nextUnlockedContainer(currentIndex, wrap)
            end
            if idx ~= -1 then
                self:selectContainer(self.backpacks[idx])
            end
            return true
        end
    end

    -- 5. When Nearby Loot is selected, split nested child items onto CSR's
    --    root-walk transfer path and let vanilla handle the direct children.
    if ISInventoryPane and ISInventoryPane.transferItemsByWeight then
        local _orig = ISInventoryPane.transferItemsByWeight
        function ISInventoryPane:transferItemsByWeight(items, container)
            if isVirtual(self.inventory) and type(items) == "table" then
                local playerNum = self.player or 0
                local direct = {}
                local hasNested = false
                for _, item in ipairs(items) do
                    if itemNestedMeta(playerNum, item) then
                        hasNested = true
                    else
                        direct[#direct + 1] = item
                    end
                end
                if hasNested then
                    if #direct > 0 then
                        _orig(self, direct, container)
                    end
                    queueVirtualTransfers(self, items, container, true)
                    if ISInventoryPage and ISInventoryPage.dirtyUI then ISInventoryPage.dirtyUI() end
                    return
                end
            end
            return _orig(self, items, container)
        end
    end

    if ISInventoryPane and ISInventoryPane.onMouseDoubleClick then
        local _orig = ISInventoryPane.onMouseDoubleClick
        function ISInventoryPane:onMouseDoubleClick(x, y)
            if blockNestedVirtualActivation(self) then
                return
            end
            return _orig(self, x, y)
        end
    end

    -- 6. Drag items dropped onto virtual pane => drop on floor at player.
    if ISInventoryPane and ISInventoryPane.onMouseUp then
        local _orig = ISInventoryPane.onMouseUp
        function ISInventoryPane:onMouseUp(x, y)
            if blockNestedVirtualDrop(self) then
                return
            end
            if isVirtual(self.inventory)
                and ISMouseDrag and ISMouseDrag.dragging
                and ISMouseDrag.draggingFocus
                and ISMouseDrag.draggingFocus ~= self
            then
                local playerNum = self.player or 0
                local items = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
                local toDrop = {}
                for _, item in ipairs(items) do
                    if item:getContainer() and not item:isFavorite() then
                        table.insert(toDrop, item)
                    end
                end
                if #toDrop > 0 and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onDropItems then
                    ISInventoryPaneContextMenu.onDropItems(toDrop, playerNum)
                end
                self.selected = {}
                ISMouseDrag.draggingFocus = nil
                ISMouseDrag.dragging = nil
                return
            end
            return _orig(self, x, y)
        end
    end

    -- 7. Shift+click on a tab toggles pin and pins that tab.
    if ISInventoryPage and ISInventoryPage.onBackpackMouseDown then
        local _orig = ISInventoryPage.onBackpackMouseDown
        function ISInventoryPage:onBackpackMouseDown(button, x, y)
            if button and button.inventory and not self.onCharacter and isLootBagEnabled()
                and (isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT))
            then
                local playerNum = self.player or 0
                pinOn[playerNum] = true
                overrideContainer[playerNum] = button.inventory
                local p = getSpecificPlayer(playerNum)
                if p then
                    HaloTextHelper.addText(p,
                        getText("IGUI_CSR_LootBag_PinOn") or "Loot tab pinned",
                        "", HaloTextHelper.getColorWhite())
                end
                if ISInventoryPage.dirtyUI then ISInventoryPage.dirtyUI() end
            end
            return _orig(self, button, x, y)
        end
    end

    -- 8. When hovering/selecting nested Nearby Loot items, mark the source bag row.
    if ISInventoryPane and ISInventoryPane.render then
        local _orig = ISInventoryPane.render
        function ISInventoryPane:render(...)
            local result = _orig(self, ...)
            if isLootBagEnabled() then
                drawNestedSourceCue(self)
            end
            return result
        end
    end
end

-- ─── Event hookup ───────────────────────────────────────────────────────────
if Events then
    if Events.OnRefreshInventoryWindowContainers then
        Events.OnRefreshInventoryWindowContainers.Add(onRefreshContainers)
    end
    if Events.OnKeyPressed then
        Events.OnKeyPressed.Add(onKeyPressed)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(installWraps)
    end
end

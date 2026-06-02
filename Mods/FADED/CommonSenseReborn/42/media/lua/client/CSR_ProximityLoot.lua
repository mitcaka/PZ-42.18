-- CSR_ProximityLoot.lua
-- v1.8.25: Replaced floating "Nearby Loot" window with a virtual container
-- button injected directly into the vanilla Loot window. The "CSR Nearby"
-- tab aggregates every loot container vanilla discovers in the 3x3 grid,
-- so the player can see all nearby items in one merged list. Tab hotkey
-- snaps the loot window to / from this view.
--
-- Pattern based on the OnRefreshInventoryWindowContainers extension point:
-- a virtual ItemContainer is built per-player, populated by addAll() from
-- every real backpack the loot pane already enumerated. The virtual
-- container is hidden from CraftingUI / context-menu transfer dialogs to
-- prevent duplicate listings.

require "CSR_FeatureFlags"
require "CSR_Theme"
require "CSR_LootFilter"

CSR_ProximityLoot = CSR_ProximityLoot or {}

local VIRTUAL_TYPE = "csrProx"
local DEFAULT_KEY = Keyboard and Keyboard.KEY_TAB or 15

-- ─────────────────────────────────────────────────────
-- Mod options: hotkey
-- ─────────────────────────────────────────────────────
local options = nil
local proximityKeyBind = nil
if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.create then
    options = PZAPI.ModOptions:create("CommonSenseRebornProximityLoot", "Common Sense Reborn - Proximity Loot")
    if options and options.addKeyBind then
        proximityKeyBind = options:addKeyBind("showProximityLoot", "Snap Loot Window to Nearby (Toggle)", DEFAULT_KEY)
    end
end

local function getBoundKey()
    if proximityKeyBind and proximityKeyBind.getValue then
        return proximityKeyBind:getValue()
    end
    return DEFAULT_KEY
end

local function getPlayerSafe()
    return getPlayer and getPlayer() or nil
end

-- ─────────────────────────────────────────────────────
-- Virtual container per player
-- ─────────────────────────────────────────────────────
local virtualContainers = {}     -- [playerNum] = ItemContainer
local proximityIcon = nil
local transferInFlight = false

local function getProximityIcon()
    if not proximityIcon then
        proximityIcon = getTexture("media/ui/CSR_ProximityLoot.png")
    end
    return proximityIcon
end

local function getOrCreateVirtualContainer(playerNum)
    local c = virtualContainers[playerNum]
    if c then return c end

    c = ItemContainer.new(VIRTUAL_TYPE, nil, nil)
    if c.setExplored then c:setExplored(true) end
    if c.setCapacity then c:setCapacity(0) end
    virtualContainers[playerNum] = c
    return c
end

function CSR_ProximityLoot.isVirtualContainer(container)
    if not container then return false end
    -- Identity check first: any container we minted is in our per-player table.
    -- This is bulletproof regardless of what getType() returns through Java.
    for _, v in pairs(virtualContainers) do
        if v == container then return true end
    end
    -- Fallback: type-string check for any stray instance not in our table
    -- (e.g. created before a /reloadlua or similar edge case).
    if container.getType then
        local t = container:getType()
        if t == VIRTUAL_TYPE then return true end
    end
    return false
end

local function isLootBagVirtualContainer(container)
    return CSR_LootBag
        and CSR_LootBag.isVirtualContainer
        and CSR_LootBag.isVirtualContainer(container)
end

function CSR_ProximityLoot.isAnyVirtualContainer(container)
    return CSR_ProximityLoot.isVirtualContainer(container)
        or isLootBagVirtualContainer(container)
end

-- ─────────────────────────────────────────────────────
-- Population
-- ─────────────────────────────────────────────────────
local function clearVirtualItems(virt)
    if not virt then return end
    local items = virt:getItems()
    if not items then return end
    -- Java ArrayList: clear() works directly
    if items.clear then items:clear() end
end

local function fillVirtualFromBackpacks(virt, inventoryPage, playerInv)
    if not virt or not inventoryPage or not inventoryPage.backpacks then return 0 end

    local added = 0
    for _, bp in ipairs(inventoryPage.backpacks) do
        local container = bp and bp.inventory or nil
        if container
                and container ~= playerInv
                and container ~= virt
                and not CSR_ProximityLoot.isAnyVirtualContainer(container)
                and container.getItems then
            local items = container:getItems()
            if items then
                -- addAll is the Java ArrayList method - copies references, not items
                virt:getItems():addAll(items)
                added = added + items:size()
            end
        end
    end
    return added
end

-- ─────────────────────────────────────────────────────
-- Container button injection
-- ─────────────────────────────────────────────────────
local function onRefreshContainers(inventoryPage, stage)
    if not CSR_FeatureFlags.isProximityLootHelperEnabled() then return end
    -- Only inject into the loot window (not the player's own inventory)
    if inventoryPage.onCharacter then return end

    local player = getPlayerSafe()
    if not player then return end
    local playerNum = player:getPlayerNum()

    local virt = getOrCreateVirtualContainer(playerNum)

    if stage == "begin" then
        -- About to rebuild the button list. Drop any existing entry for our
        -- virtual container so vanilla's enumeration is clean, then clear
        -- items in preparation for the buttonsAdded re-fill.
        clearVirtualItems(virt)
        return
    end

    if stage ~= "buttonsAdded" then return end

    -- vanilla has now populated inventoryPage.backpacks with every nearby
    -- container (loot from squares, corpses, vehicles, etc). Aggregate.
    local playerInv = player:getInventory()
    fillVirtualFromBackpacks(virt, inventoryPage, playerInv)

    -- Now add our virtual container button.
    -- v1.8.34c: CSR_LootBag also injects a "Nearby Loot" virtual container
    -- into the same loot window. They're functionally redundant, so when
    -- LootBag is the active aggregator we suppress our button (no second
    -- icon) and let LootBag own the loot pane. ProximityLoot's other
    -- features (context-menu actions, Tab snap toggle) stay alive in case
    -- a user disables LootBag via sandbox.
    local lootBagOwnsPane = (CSR_FeatureFlags.isLootBagEnabled and CSR_FeatureFlags.isLootBagEnabled()) == true
    if lootBagOwnsPane then return end
    if inventoryPage.addContainerButton then
        local icon = getProximityIcon()
        inventoryPage:addContainerButton(virt, icon, "CSR Nearby", "All nearby loot")
    end
end

-- ─────────────────────────────────────────────────────
-- Hide virtual container from crafting / transfer menus
-- ─────────────────────────────────────────────────────
-- v1.8.32: drop the probe entirely. Comparison with vanilla container-tab
-- mods (e.g. TwisTonFire - Inventory) showed they just call
-- containerList:remove(virtual) directly with no type probe, because
-- ArrayList.remove(Object) is a well-defined no-op when the object is
-- absent. v1.8.28 used type(v.size)=="function" -- false on Java
-- userdata. v1.8.29 invoked :size() unconditionally -- spammed errors on
-- non-list values. v1.8.30 read v.size as a field first -- but Kahlua's
-- __index on Java userdata returns nil for `v.size` even on real
-- ArrayLists (methods are only callable via colon syntax, not readable
-- as fields), so the probe always failed and the virtual leaked through
-- into HandcraftLogic.setContainers -> ISHandcraftAction.containers ->
-- network packet -> ContainerID.set RuntimeException("SendAction:
-- failed"). Simplest correct path: remove directly from the known
-- container-list fields. If the list shape is wrong, surface it.
local function removeVirtualsFrom(list)
    if not list then return end
    for _, virt in pairs(virtualContainers) do
        if virt then list:remove(virt) end
    end
end

local function filterContainerList(list)
    removeVirtualsFrom(list)
end

local _craftingPatched = false
local function patchCraftingUI()
    if _craftingPatched or not ISCraftingUI then return end
    _craftingPatched = true
    if type(ISCraftingUI.getContainers) == "function" then
        local orig = ISCraftingUI.getContainers
        function ISCraftingUI:getContainers(...)
            local list = orig(self, ...)
            filterContainerList(list)
            return list
        end
    end
end

local _ctxPatched = false
local function patchContextMenu()
    if _ctxPatched or not ISInventoryPaneContextMenu then return end
    _ctxPatched = true
    if type(ISInventoryPaneContextMenu.getContainers) == "function" then
        local orig = ISInventoryPaneContextMenu.getContainers
        ISInventoryPaneContextMenu.getContainers = function(playerObj, ...)
            local list = orig(playerObj, ...)
            filterContainerList(list)
            return list
        end
    end
end

-- v1.8.28 hotfix: a universal scrubber for the same family of failures
-- v1.8.27 only fixed. Any vanilla timed action whose Lua self-table holds
-- a reference to the "CSR Nearby" virtual ItemContainer (most commonly in
-- a self.containers ArrayList built by ISInventoryPaneContextMenu) blows
-- up at LuaTimedActionNew.start -> NetTimedAction.write ->
-- PZNetKahluaTableImpl.save -> ContainerID.set with
-- RuntimeException("SendAction: failed"). The action packet never reaches
-- the server, the action quietly ends, and the user sees "open box of
-- nails / take item / craft / unpack -- nothing happened".
--
-- Confirmed failing call sites in the wild (B42.17, v1.8.27 console.txt):
--   * ISInventoryTransferAction queue chain (open boxes, take items)
--   * ISHandcraftAction via ISEntityUI.HandcraftStart (right-click craft)
--   * ISBuildAction via createBuildAction (already patched in v1.8.27)
--
-- Wrap ISBaseTimedAction:begin (the Lua function on line 88 in vanilla
-- that calls character:StartAction(self) -- the Java entry point that
-- triggers serialization). Walk self's fields, scrub any virtual
-- container hits from ArrayLists, and null any direct field whose value
-- IS the virtual container. No error wrapper around the lifecycle call itself.
local _baseTimedActionPatched = false
local function patchBaseTimedAction()
    if _baseTimedActionPatched or not ISBaseTimedAction then return end
    _baseTimedActionPatched = true
    local origBegin = ISBaseTimedAction.begin
    if type(origBegin) ~= "function" then return end
    -- v1.8.29: previous probe used `type(v.size) == "function"` to detect
    -- ArrayLists, but Kahlua reports Java methods as something other than
    -- "function" -- so this branch was a silent no-op and self.containers
    -- was never scrubbed.
    -- v1.8.32: scrub only the known leaking field names. Vanilla
    -- ISHandcraftAction stores the container list as `self.containers`;
    -- ISBuildAction stores it as `self.item.containers` (handled in
    -- patchBuildAction). Walking ALL userdata fields and probing for
    -- ArrayList shape is unreliable in Kahlua (Java method handles are
    -- not readable as fields and invoking on the wrong object throws).
    -- Targeted name-based filtering matches the pattern used by
    -- comparable container-tab mods and never throws on unrelated
    -- userdata.
    local function scrubSelfFields(self)
        if not self or type(self) ~= "table" then return end
        if self.containers then removeVirtualsFrom(self.containers) end
        if self.item and type(self.item) == "table" and self.item.containers then
            removeVirtualsFrom(self.item.containers)
        end
        -- manualInputs is a Lua table { [idx] = ArrayList }; entries
        -- contain InventoryItems whose parent containers are the REAL
        -- world containers (we never moved items into the virtual), so
        -- those don't need scrubbing.
    end

    function ISBaseTimedAction:begin(...)
        scrubSelfFields(self)
        return origBegin(self, ...)
    end
end

-- v1.8.27 hotfix: vanilla ISBuildAction:start sets self.item.containers to
-- ISInventoryPaneContextMenu.getContainers(...) THEN calls the global Java
-- createBuildAction(char, x, y, z, north, spriteName, item) which serializes
-- item.containers to the network via PZNetKahluaTableImpl. Our virtual
-- "CSR Nearby" ItemContainer has no parent IsoObject / character / vehicle,
-- so ContainerID.set throws RuntimeException("SendAction: failed") -- the
-- packet is dropped, the server never builds the structure, and the client
-- sees the action complete with nothing built. The getContainers() patch
-- above already filters in normal flow, but if any other mod monkey-patches
-- getContainers AFTER us, the filter is bypassed. This wrap intercepts the
-- final Java call and scrubs item.containers as a last line of defense.
local _buildActionPatched = false
local function patchBuildAction()
    if _buildActionPatched then return end
    if type(_G.createBuildAction) ~= "function" then return end
    _buildActionPatched = true
    local origCreateBuildAction = _G.createBuildAction
    _G.createBuildAction = function(character, x, y, z, north, spriteName, item)
        if item and item.containers then
            filterContainerList(item.containers)
        end
        return origCreateBuildAction(character, x, y, z, north, spriteName, item)
    end
end

-- ─────────────────────────────────────────────────────
-- Conditional purple outline (Approach B)
-- Future: full vanilla colour replacement (panelBg, header, border)
-- gated behind a sandbox toggle. For now, only the loot window border
-- turns CSR-violet when the virtual container is selected.
-- ─────────────────────────────────────────────────────
local _outlinePatched = false
local function patchInventoryPagePrerender()
    if _outlinePatched or not ISInventoryPage then return end
    _outlinePatched = true

    local orig = ISInventoryPage.prerender
    function ISInventoryPage:prerender(...)
        local r = orig(self, ...)
        local pane = self.inventoryPane
        local inv = pane and pane.inventory or nil
        if inv and CSR_ProximityLoot.isAnyVirtualContainer(inv) then
            local c = (CSR_Theme and CSR_Theme.colors and CSR_Theme.colors.accentViolet)
                or { r = 0.72, g = 0.58, b = 0.94, a = 1.0 }
            -- Double-stroke for visibility against vanilla beige border
            self:drawRectBorder(0, 0, self.width, self.height, 0.95, c.r, c.g, c.b)
            self:drawRectBorder(1, 1, self.width - 2, self.height - 2, 0.55, c.r, c.g, c.b)
        end
        return r
    end
end

-- Right-click on the csrProx tab opens the loot filter dropdown.
-- Without this wrap, vanilla's onBackpackRightMouseDown crashes with
-- "attempted index: getSquare of non-table: null" because our virtual
-- container has no parent IsoObject (orphan by design). Short-circuiting
-- here both prevents the crash and gives the new tab a useful action.
local _rightClickPatched = false
local function patchInventoryPageRightClick()
    if _rightClickPatched or not ISInventoryPage then return end
    _rightClickPatched = true
    if type(ISInventoryPage.onBackpackRightMouseDown) ~= "function" then return end
    local orig = ISInventoryPage.onBackpackRightMouseDown
    function ISInventoryPage:onBackpackRightMouseDown(button, ...)
        local inv = button and button.inventory or nil
        if inv and CSR_ProximityLoot.isAnyVirtualContainer(inv) then
            if CSR_LootFilter and CSR_LootFilter.openFilterDropdown then
                CSR_LootFilter.openFilterDropdown(button)
            end
            return
        end
        return orig(self, button, ...)
    end
end

-- ─────────────────────────────────────────────────────
-- Hotkey: Tab snaps loot window to / from the virtual container
-- ─────────────────────────────────────────────────────
local function snapToggle()
    if not CSR_FeatureFlags.isProximityLootHelperEnabled() then return end
    local player = getPlayerSafe()
    if not player then return end
    local playerNum = player:getPlayerNum()

    local lootWindow = getPlayerLoot and getPlayerLoot(playerNum) or nil
    if not lootWindow then return end

    -- Find the loot inventoryPage (it owns containerButtonPanel + backpacks)
    local page = lootWindow.inventoryPage or lootWindow
    if not page then return end

    local pane = lootWindow.inventoryPane
    local currentIsVirtual = pane and pane.inventory and CSR_ProximityLoot.isAnyVirtualContainer(pane.inventory)

    local function selectButton(bp)
        if not bp or not bp.inventory then return false end
        if page.selectContainer then
            page:selectContainer(bp)
            return true
        end
        if page.selectButton then
            page:selectButton(bp)
            return true
        end
        if bp.onclick then
            bp.onclick(bp.target or page, bp)
            return true
        end
        if page.setForceSelectedContainer then
            page:setForceSelectedContainer(bp.inventory)
            return true
        end
        return false
    end

    local function findButton(predicate)
        if not page.backpacks then return nil end
        for _, bp in ipairs(page.backpacks) do
            if bp and bp.inventory and predicate(bp) then
                return bp
            end
        end
        return nil
    end

    if currentIsVirtual then
        -- Unsnap: pick the first non-virtual backpack.
        selectButton(findButton(function(bp)
            return not CSR_ProximityLoot.isAnyVirtualContainer(bp.inventory)
        end))
    else
        local lootBagButton = findButton(function(bp)
            return bp._csrLootBag == true or isLootBagVirtualContainer(bp.inventory)
        end)
        if selectButton(lootBagButton) then return end

        local proxButton = findButton(function(bp)
            return CSR_ProximityLoot.isVirtualContainer(bp.inventory)
        end)
        if selectButton(proxButton) then return end

        local virt = virtualContainers[playerNum]
        if virt and page.setForceSelectedContainer then
            page:setForceSelectedContainer(virt)
        end
    end
end

function CSR_ProximityLoot.toggle()
    snapToggle()
end

local function onKeyPressed(key)
    if key == getBoundKey() then
        snapToggle()
    end
end

-- ─────────────────────────────────────────────────────
-- Existing context menu: "Grab Nearby Matching" — unchanged behaviour
-- ─────────────────────────────────────────────────────
local function getDisplayName(fullType)
    local scriptItem = ScriptManager and ScriptManager.instance and ScriptManager.instance:FindItem(fullType) or nil
    if scriptItem and scriptItem.getDisplayName then
        return scriptItem:getDisplayName()
    end
    return fullType
end

local function getActualItems(items)
    if ISInventoryPane and ISInventoryPane.getActualItems then
        return ISInventoryPane.getActualItems(items)
    end
    return items or {}
end

local function getOpenLootContainers(playerNum)
    local lootWindow = getPlayerLoot(playerNum)
    local page = lootWindow and lootWindow.inventoryPane and lootWindow.inventoryPane.inventoryPage or nil
    local buttons = page and page.backpacks or nil
    local containers = {}
    local seen = {}

    if not buttons then return containers end

    for _, button in ipairs(buttons) do
        local container = button and button.inventory or nil
        if container and not seen[container] and not CSR_ProximityLoot.isAnyVirtualContainer(container) then
            seen[container] = true
            table.insert(containers, container)
        end
    end

    return containers
end

local function getRequestedTypes(actualItems)
    local requested = {}
    local firstType = nil
    for _, item in ipairs(actualItems) do
        local fullType = item and item.getFullType and item:getFullType() or nil
        if fullType then
            requested[fullType] = true
            firstType = firstType or fullType
        end
    end
    return requested, firstType
end

local function gatherNearbyMatches(playerNum, selectedItems)
    local playerObj = getSpecificPlayer(playerNum)
    local playerInv = playerObj and playerObj:getInventory() or nil
    if not playerObj or not playerInv then
        return {}, 0, nil
    end

    local actualItems = getActualItems(selectedItems)
    local requestedTypes, firstType = getRequestedTypes(actualItems)
    if not firstType then
        return {}, 0, nil
    end

    local matchesByContainer = {}
    local total = 0

    for _, container in ipairs(getOpenLootContainers(playerNum)) do
        if container ~= playerInv then
            local items = container:getItems()
            local list = {}
            for i = 1, items:size() do
                local item = items:get(i - 1)
                if item and requestedTypes[item:getFullType()] and item:getContainer() ~= playerInv and not isForceDropHeavyItem(item) then
                    table.insert(list, item)
                end
            end
            if #list > 0 then
                matchesByContainer[container] = list
                total = total + #list
            end
        end
    end

    return matchesByContainer, total, firstType
end

local function queueNearbyTransfers(playerNum, matchesByContainer)
    local playerObj = getSpecificPlayer(playerNum)
    local playerInv = playerObj and playerObj:getInventory() or nil
    if not playerObj or not playerInv then return end

    for container, items in pairs(matchesByContainer) do
        if #items > 0 then
            if not luautils.walkToContainer(container, playerNum) then
                return
            end

            table.sort(items, function(a, b)
                local aType = a:getFullType() or ""
                local bType = b:getFullType() or ""
                if aType == bType then
                    return (a:getUnequippedWeight() or 0) <= (b:getUnequippedWeight() or 0)
                end
                return aType < bType
            end)

            for _, item in ipairs(items) do
                if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
                end
            end
        end
    end
end

function CSR_ProximityLoot.addContextOptions(playerNum, context, items)
    if not CSR_FeatureFlags.isProximityLootHelperEnabled() then
        return
    end

    local matchesByContainer, total, firstType = gatherNearbyMatches(playerNum, items)
    if total <= 0 or not firstType then
        return
    end

    local displayName = getDisplayName(firstType)

    local option = context:addOptionOnTop(string.format("Grab Nearby Matching (%d)", total), items, function(_, pn, grouped)
        queueNearbyTransfers(pn, grouped)
    end, playerNum, matchesByContainer)

    option.toolTip = ISInventoryPaneContextMenu.addToolTip and ISInventoryPaneContextMenu.addToolTip() or nil
    if option.toolTip then
        option.toolTip.description = string.format("Transfer all visible nearby %s items from currently open loot sources.", displayName)
    end
end

-- ─────────────────────────────────────────────────────
-- Event wiring
-- ─────────────────────────────────────────────────────
local function onGameStart()
    if not CSR_FeatureFlags.isProximityLootHelperEnabled() then return end
    patchCraftingUI()
    patchContextMenu()
    patchBuildAction()
    patchBaseTimedAction()
    patchInventoryPagePrerender()
    patchInventoryPageRightClick()
end

if Events then
    if Events.OnFillInventoryObjectContextMenu then
        Events.OnFillInventoryObjectContextMenu.Add(CSR_ProximityLoot.addContextOptions)
    end
    if Events.OnKeyPressed then Events.OnKeyPressed.Add(onKeyPressed) end
    if Events.OnGameStart then Events.OnGameStart.Add(onGameStart) end
    if Events.OnRefreshInventoryWindowContainers then
        Events.OnRefreshInventoryWindowContainers.Add(onRefreshContainers)
    end
end

return CSR_ProximityLoot

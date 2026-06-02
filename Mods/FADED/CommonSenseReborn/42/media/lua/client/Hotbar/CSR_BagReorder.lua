require "CSR_FeatureFlags"

--[[
    CSR_BagReorder.lua  (v1.8.37 -- full rebuild)

    Drag-to-reorder bag/container buttons on the character inventory sidebar.

    HISTORY: v1.8.36 and earlier replaced per-button onMouseDown / onMouseUp /
    onMouseMove handlers inside addContainerButton. On B42.18 that pattern
    desynced Java's mouse-capture tracking on the player-side inventory page:
    onMouseDown still fired on the clicked button, but onMouseUp was lost and
    only onMouseUpOutside was dispatched to *sibling* buttons -- so vanilla's
    selectContainer / dropItemsInContainer never ran. Symptom: left-click on
    worn bag tabs did nothing (right-click + drag-drop still worked, because
    those go through different paths). Diagnosis in console.txt: 45 btnDOWN,
    0 btnUP, 188 btnUPOUT, on every player-side click.

    NEW APPROACH (this file):
      * NO per-button onMouseDown / onMouseUp / onMouseMove overrides.
        Vanilla mouse capture is left completely untouched.
      * Drag detection runs from ISInventoryPage:prerender by polling each
        backpack button's vanilla `pressed` flag + current mouse position.
      * When a drag starts, we move the button visually via setY(). When the
        mouse releases (button.pressed flips back to false), we commit the
        new sort priority and refresh. A flag is set so the immediately-
        following vanilla onBackpackClick is swallowed (drag must not also
        select the dragged container).
      * Sort order persisted in player modData keyed by container item ID,
        re-applied after every refreshBackpacks via setY().
]]

local SORT_KEY = "CSR_ContainerSort"
local DRAG_THRESHOLD_PX = 6  -- minimum mouse-Y delta before a press counts as a drag

local function isEnabled()
    return CSR_FeatureFlags
        and CSR_FeatureFlags.isEquipmentQoLEnabled
        and CSR_FeatureFlags.isEquipmentQoLEnabled()
end

local function isButtonValid(inventoryPage, button)
    if not button or not button.getIsVisible then return false end
    local visible = button:getIsVisible()
    if visible == false or visible == nil or visible == 0 then return false end
    local panel = inventoryPage and inventoryPage.containerButtonPanel
    if panel and panel.children and panel.children[button.ID] == nil then return false end
    return true
end

local function stopPageMove(inventoryPage)
    if not inventoryPage then return end
    inventoryPage.moving = false
    if inventoryPage.setCapture then
        inventoryPage:setCapture(false)
    end
end

local function csrShouldOwnReorder(inventoryPage)
    if not isEnabled() then return false end
    if not inventoryPage or not inventoryPage.onCharacter then return false end
    if CSR_FeatureFlags and CSR_FeatureFlags.isCleanUIActive
        and CSR_FeatureFlags.isCleanUIActive() then
        return false
    end
    return true
end

local function getBetterContainersSortPriority(playerObj, container, inventoryPage)
    local reorder = rawget(_G, "Reorder")
    if reorder and type(reorder.getSortPriority) == "function" then
        local ok, priority = pcall(reorder.getSortPriority, playerObj, container, inventoryPage)
        if ok and tonumber(priority) then return tonumber(priority) end
    end

    local betterContainers = rawget(_G, "BetterContainers")
    if betterContainers and type(betterContainers.getSortPriority) == "function" then
        local ok, priority = pcall(betterContainers.getSortPriority, playerObj, container, inventoryPage)
        if ok and tonumber(priority) then return tonumber(priority) end
    end

    return nil
end

local function mirrorBetterContainersSortPriority(playerObj, container, priority)
    local reorder = rawget(_G, "Reorder")
    if reorder and type(reorder.setSortPriority) == "function" then
        pcall(reorder.setSortPriority, playerObj, container, priority, false)
        return
    end

    local betterContainers = rawget(_G, "BetterContainers")
    if betterContainers and type(betterContainers.setSortPriority) == "function" then
        pcall(betterContainers.setSortPriority, playerObj, container, priority, false)
    end
end

-- =========================================================================
-- Patch setup
-- =========================================================================

local function patchBagReorder()
    if not ISInventoryPage or ISInventoryPage.__csr_bag_reorder_patched then return end
    -- CleanUI ships its own ISInventoryPage_DragSort with the same purpose.
    -- Yield to it entirely when present.
    if CSR_FeatureFlags and CSR_FeatureFlags.isCleanUIActive
        and CSR_FeatureFlags.isCleanUIActive() then
        ISInventoryPage.__csr_bag_reorder_patched = true
        return
    end
    ISInventoryPage.__csr_bag_reorder_patched = true

    -- -----------------------------------------------------------------
    -- Sort priority storage (player modData, keyed by container item ID)
    -- -----------------------------------------------------------------
    local function sortKeyFor(playerObj, container)
        if container == playerObj:getInventory() then
            return SORT_KEY .. "_Main"
        end
        local item = container:getContainingItem()
        if item then
            return SORT_KEY .. "_" .. item:getID()
        end
        return nil
    end

    function ISInventoryPage:csrGetContainerSortPriority(container)
        local playerObj = getSpecificPlayer(self.player)
        if not playerObj or not container then return 1000 end
        local key = sortKeyFor(playerObj, container)
        local md = playerObj:getModData()
        local savedPriority = key and tonumber(md[key]) or nil
        if savedPriority then return savedPriority end
        local betterContainersSort = getBetterContainersSortPriority(playerObj, container, self)
        if betterContainersSort then return betterContainersSort end
        -- Fallback: current array position
        for i, button in ipairs(self.backpacks) do
            if button.inventory == container then
                return 1000 + i
            end
        end
        return 1000
    end

    function ISInventoryPage:csrSetContainerSortPriority(container, priority)
        local playerObj = getSpecificPlayer(self.player)
        if not playerObj or not container then return end
        local key = sortKeyFor(playerObj, container)
        if key then playerObj:getModData()[key] = priority end
        mirrorBetterContainersSortPriority(playerObj, container, priority)
    end

    -- -----------------------------------------------------------------
    -- Apply saved sort order via setY() (no swap, each button keeps
    -- its own .inventory ref -- vanilla click handlers stay correct).
    -- -----------------------------------------------------------------
    function ISInventoryPage:csrApplyContainerSort()
        if not csrShouldOwnReorder(self) then return end
        if not self.backpacks or #self.backpacks == 0 then return end

        local list = {}
        for _, button in ipairs(self.backpacks) do
            if isButtonValid(self, button) then
                table.insert(list, {
                    button = button,
                    priority = self:csrGetContainerSortPriority(button.inventory),
                    order = #list + 1,
                })
            end
        end
        if #list == 0 then return end

        table.sort(list, function(a, b)
            if a.priority == b.priority then return a.order < b.order end
            return a.priority < b.priority
        end)

        local btnH = tonumber(list[1].button:getHeight()) or 0
        if btnH <= 0 then return end
        local startY = tonumber(list[1].button:getY()) or 0
        for _, data in ipairs(list) do
            local y = tonumber(data.button:getY()) or startY
            if y < startY then startY = y end
        end

        for index, data in ipairs(list) do
            data.button:setY(startY + (index - 1) * btnH)
        end
    end

    -- -----------------------------------------------------------------
    -- Commit a drag: assign sort priorities based on current Y order
    -- -----------------------------------------------------------------
    function ISInventoryPage:csrCommitDragOrder()
        local list = {}
        for _, button in ipairs(self.backpacks) do
            if isButtonValid(self, button) then
                table.insert(list, { inventory = button.inventory, y = button:getY() })
            end
        end
        table.sort(list, function(a, b) return a.y < b.y end)
        for index, data in ipairs(list) do
            self:csrSetContainerSortPriority(data.inventory, index * 10)
        end
    end

    function ISInventoryPage:csrFinishReorderDrag(suppressClicks)
        local drag = self._csrDrag
        if not drag then return false end

        self._csrDrag = nil
        if not drag.dragging then return false end

        if drag.button then
            if suppressClicks == nil and drag.button.isMouseOver then
                suppressClicks = drag.button:isMouseOver()
            end
            drag.button.pressed = false
        end
        self:csrCommitDragOrder()
        if suppressClicks then
            self._csrSuppressBackpackClicks = 2
        end
        self:refreshBackpacks()
        return true
    end

    local origBackpackMouseDown = ISInventoryPage.onBackpackMouseDown
    function ISInventoryPage:onBackpackMouseDown(button, x, y)
        if origBackpackMouseDown then origBackpackMouseDown(self, button, x, y) end
        if not csrShouldOwnReorder(self) or not isButtonValid(self, button) then return end
        self._csrDrag = {
            button = button,
            startMouseY = tonumber(getMouseY()) or 0,
            startY      = tonumber(button:getY()) or 0,
            dragging    = false,
        }
    end

    local origBackpackMouseUp = ISInventoryPage.onBackpackMouseUp
    function ISInventoryPage:onBackpackMouseUp(x, y)
        local page = self and self.parent and self.parent.parent or nil
        if page and page._csrDrag and page._csrDrag.dragging
            and csrShouldOwnReorder(page) and page:csrFinishReorderDrag(true) then
            self.pressed = false
            return
        end
        return origBackpackMouseUp(self, x, y)
    end

    -- -----------------------------------------------------------------
    -- prerender drag-state machine
    --   * Polls each backpack button for vanilla `pressed` flag.
    --   * When pressed + mouse moved past threshold => dragging.
    --   * Visually moves the dragged button via setY while held.
    --   * On release (pressed cleared by vanilla onMouseUp): commit
    --     reorder, refresh, and suppress the follow-up vanilla click when
    --     the release happened over a bag button.
    -- -----------------------------------------------------------------
    local origPrerender = ISInventoryPage.prerender
    function ISInventoryPage:prerender(...)
        if origPrerender then origPrerender(self, ...) end

        if not csrShouldOwnReorder(self) then
            self._csrDrag = nil
            return
        end
        if not self.backpacks or #self.backpacks == 0 then return end

        local drag = self._csrDrag
        local mouseDown = isMouseButtonDown and isMouseButtonDown(0)

        if not drag then
            -- Look for a newly-pressed button to start tracking
            if not mouseDown then return end
            for _, button in ipairs(self.backpacks) do
                if button.pressed and isButtonValid(self, button) then
                    self._csrDrag = {
                        button = button,
                        startMouseY = tonumber(getMouseY()) or 0,
                        startY      = tonumber(button:getY()) or 0,
                        dragging    = false,
                    }
                    return
                end
            end
            return
        end

        -- We have a tracked press. If the button reference vanished
        -- (refreshBackpacks ran during the press), abort cleanly.
        if not isButtonValid(self, drag.button) or not drag.button.getY then
            self._csrDrag = nil
            return
        end

        if mouseDown then
            -- Keep the inventory window itself from stealing the drag while
            -- the cursor is moving over the container button rail.
            stopPageMove(self)

            -- Still held: check if movement exceeds threshold. Once dragging
            -- starts, keep tracking by global mouse state so release outside
            -- the button/panel is still handled cleanly.
            local curY = tonumber(getMouseY()) or 0
            local delta = curY - drag.startMouseY
            if not drag.dragging and math.abs(delta) > DRAG_THRESHOLD_PX then
                drag.dragging = true
            end
            if drag.dragging then
                -- Move button visually
                local parent = drag.button.getParent and drag.button:getParent() or nil
                local parentAbsY = tonumber(parent and parent.getAbsoluteY and parent:getAbsoluteY()) or 0
                local newY = curY - parentAbsY - drag.button:getHeight() / 2
                if newY < 0 then newY = 0 end
                if parent and parent.getHeight then
                    local maxY = (tonumber(parent:getHeight()) or 0) - (tonumber(drag.button:getHeight()) or 0)
                    if maxY > 0 and newY > maxY then newY = maxY end
                end
                drag.button:setY(newY)
                if drag.button.bringToTop then drag.button:bringToTop() end
            end
            return
        end

        -- Released. This also catches mouse-up outside the original button,
        -- because the global mouse state clears even when button.pressed does not.
        self:csrFinishReorderDrag()
    end

    local origMouseMove = ISInventoryPage.onMouseMove
    function ISInventoryPage:onMouseMove(dx, dy)
        if self._csrDrag and csrShouldOwnReorder(self) then stopPageMove(self) end
        local result = origMouseMove(self, dx, dy)
        if self._csrDrag and csrShouldOwnReorder(self) then stopPageMove(self) end
        return result
    end

    local origMouseMoveOutside = ISInventoryPage.onMouseMoveOutside
    function ISInventoryPage:onMouseMoveOutside(dx, dy)
        if self._csrDrag and csrShouldOwnReorder(self) then stopPageMove(self) end
        local result = origMouseMoveOutside(self, dx, dy)
        if self._csrDrag and csrShouldOwnReorder(self) then stopPageMove(self) end
        return result
    end

    local origMouseUp = ISInventoryPage.onMouseUp
    function ISInventoryPage:onMouseUp(x, y)
        if self._csrDrag and csrShouldOwnReorder(self) and self:csrFinishReorderDrag() then
            return
        end
        return origMouseUp(self, x, y)
    end

    local origMouseUpOutside = ISInventoryPage.onMouseUpOutside
    function ISInventoryPage:onMouseUpOutside(x, y)
        if self._csrDrag and csrShouldOwnReorder(self) and self:csrFinishReorderDrag() then
            return
        end
        return origMouseUpOutside(self, x, y)
    end

    -- -----------------------------------------------------------------
    -- Eat the post-drag click so the dragged container isn't selected.
    -- -----------------------------------------------------------------
    local origBackpackClick = ISInventoryPage.onBackpackClick
    function ISInventoryPage:onBackpackClick(button)
        if self._csrSuppressBackpackClicks then
            self._csrSuppressBackpackClicks = self._csrSuppressBackpackClicks - 1
            if self._csrSuppressBackpackClicks <= 0 then
                self._csrSuppressBackpackClicks = nil
            end
            return
        end
        return origBackpackClick(self, button)
    end

    -- -----------------------------------------------------------------
    -- Hook refreshBackpacks to re-apply saved sort order.
    -- -----------------------------------------------------------------
    local origRefreshBackpacks = ISInventoryPage.refreshBackpacks
    function ISInventoryPage:refreshBackpacks()
        origRefreshBackpacks(self)
        if csrShouldOwnReorder(self) then
            self:csrApplyContainerSort()
        end
    end

    -- -----------------------------------------------------------------
    -- Hook onMouseWheel to preserve custom order during cycle-scrolling.
    -- Vanilla uses self.backpacks array order to step prev/next; without
    -- this re-sort the wheel walks the un-reordered creation sequence.
    -- -----------------------------------------------------------------
    local origMouseWheel = ISInventoryPage.onMouseWheel
    function ISInventoryPage:onMouseWheel(del)
        if not csrShouldOwnReorder(self) then
            return origMouseWheel(self, del)
        end
        local originalOrder = {}
        for index, button in ipairs(self.backpacks) do
            originalOrder[button] = index
        end
        table.sort(self.backpacks, function(a, b) return a:getY() < b:getY() end)
        local result = origMouseWheel(self, del)
        table.sort(self.backpacks, function(a, b)
            return (originalOrder[a] or 0) < (originalOrder[b] or 0)
        end)
        return result
    end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(patchBagReorder)
end

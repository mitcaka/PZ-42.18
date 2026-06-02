-- CSR_PowerBarContext.lua — inventory + world context-menu wiring for
-- the PowerBar cable-extension feature. Place a Base.PowerBar on a
-- powered tile, optionally invest ElectricWires for extra reach, and
-- the resulting Manhattan-distance zone treats radios + chargers as
-- if they were on the grid.
require "CSR_PowerBar"
require "ISUI/ISInventoryPaneContextMenu"

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

local function isEnabled()
    return CSR_PowerBar.isFeatureEnabled()
end

local function countWires(inv)
    if not inv then return 0 end
    local n = 0
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and it:getFullType() == "Base.ElectricWire" then
            n = n + 1
        end
    end
    return n
end

local function findPowerBarItem(inv)
    if not inv then return nil end
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and it:getFullType() == "Base.PowerBar" then
            return it
        end
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- Place PowerBar at player tile
-- ----------------------------------------------------------------------------
local function onPlace(playerNum, item, wires)
    local p = getSpecificPlayer(playerNum)
    if not p then return end
    local sq = p:getCurrentSquare()
    if not sq then return end
    local args = {
        x = sq:getX(), y = sq:getY(), z = sq:getZ(),
        wires = tonumber(wires) or 0,
    }
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", CSR_PowerBar.CMD_PLACE, args)
    elseif CSR_ServerCommands and CSR_ServerCommands.handlePowerBarPlace then
        CSR_ServerCommands.handlePowerBarPlace(p, args)
    end
end

local function onUnplug(playerNum, node)
    local p = getSpecificPlayer(playerNum)
    if not p or not node then return end
    local args = { id = node.id }
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", CSR_PowerBar.CMD_UNPLUG, args)
    elseif CSR_ServerCommands and CSR_ServerCommands.handlePowerBarUnplug then
        CSR_ServerCommands.handlePowerBarUnplug(p, args)
    end
end

local function onAddWire(playerNum, node)
    local p = getSpecificPlayer(playerNum)
    if not p or not node then return end
    local args = { id = node.id }
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", CSR_PowerBar.CMD_ADDWIRE, args)
    elseif CSR_ServerCommands and CSR_ServerCommands.handlePowerBarAddWire then
        CSR_ServerCommands.handlePowerBarAddWire(p, args)
    end
end

-- ----------------------------------------------------------------------------
-- Inventory context: right-click PowerBar item -> "Plug In Here"
-- ----------------------------------------------------------------------------
local function onFillInventoryContextMenu(playerNum, context, items)
    if not isEnabled() then return end
    local p = getSpecificPlayer(playerNum)
    if not p then return end

    -- Find a PowerBar in the selected stack.
    local powerBar = nil
    for i = 1, #items do
        local entry = items[i]
        local it = entry
        if entry.items and entry.items[1] then it = entry.items[1] end
        if it and it.getFullType and it:getFullType() == "Base.PowerBar" then
            powerBar = it
            break
        end
    end
    if not powerBar then return end

    local sq = p:getCurrentSquare()
    local canAnchor = sq and CSR_PowerBar.canPlaceForUser(sq)
    local maxW = CSR_PowerBar.maxWires()
    local haveW = countWires(p:getInventory())
    if haveW > maxW then haveW = maxW end

    local label = getText("ContextMenu_CSR_PowerBarPlugIn") or "Place Power Bar Here"
    local opt   = context:addOption(label, playerNum, onPlace, powerBar, haveW)
    local tip   = ISToolTip:new()
    tip:initialise(); tip:setVisible(false)

    if not canAnchor then
        opt.notAvailable = true
        tip.description = "<RED>" ..
            (getText("Tooltip_CSR_PowerBarNoPlace") or
             "Place next to a building or inside a generator's range.")
    else
        tip.description = (getText("Tooltip_CSR_PowerBarPlugIn") or
            "Place a Power Bar here. Each Electric Wire in your inventory extends cable reach by 1 tile (max %d). Reach: %d tile(s)."):format(maxW, haveW)
    end
    opt.toolTip = tip
end

-- ----------------------------------------------------------------------------
-- World context: right-click placed PowerBar -> "Add Wire" / "Unplug"
-- We piggyback on whatever world object the right-click latched onto by
-- checking if there is an active CSR PowerBar node on the clicked square.
-- ----------------------------------------------------------------------------
local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test == true then return true end
    if not isEnabled() then return end

    local sq = nil
    for i = 1, #worldObjects do
        local obj = worldObjects[i]
        if obj and obj.getSquare then
            sq = obj:getSquare()
            if sq then break end
        end
    end
    if not sq then return end
    local node = CSR_PowerBar.findNodeAtSquare(sq:getX(), sq:getY(), sq:getZ())
    if not node then return end

    local p = getSpecificPlayer(playerNum)
    if not p then return end

    -- Add Wire option.
    local maxW = CSR_PowerBar.maxWires()
    local hasWire = countWires(p:getInventory()) > 0
    local canExtend = node.wires < maxW
    local addLabel = (getText("ContextMenu_CSR_PowerBarAddWire") or "Power Bar: Add Wire (+1 tile reach)")
    local addOpt = context:addOption(addLabel, playerNum, onAddWire, node)
    local addTip = ISToolTip:new(); addTip:initialise(); addTip:setVisible(false)
    if not canExtend then
        addOpt.notAvailable = true
        addTip.description = "<RED>" .. (getText("Tooltip_CSR_PowerBarMaxReach") or
            ("Already at maximum reach (%d)."):format(maxW))
    elseif not hasWire then
        addOpt.notAvailable = true
        addTip.description = "<RED>" .. (getText("Tooltip_CSR_PowerBarNeedWire") or
            "Requires 1 Electric Wire in your inventory.")
    else
        addTip.description = (getText("Tooltip_CSR_PowerBarAddWire") or
            "Reach %d / %d tiles."):format(node.wires, maxW)
    end
    addOpt.toolTip = addTip

    -- Unplug option.
    local unplugLabel = getText("ContextMenu_CSR_PowerBarUnplug") or "Power Bar: Unplug"
    local unplugOpt = context:addOption(unplugLabel, playerNum, onUnplug, node)
    local unplugTip = ISToolTip:new(); unplugTip:initialise(); unplugTip:setVisible(false)
    unplugTip.description = (getText("Tooltip_CSR_PowerBarUnplug") or
        "Recover the Power Bar and ~%d%% of invested wires."):format(CSR_PowerBar.returnPct())
    unplugOpt.toolTip = unplugTip
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryContextMenu)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

-- ----------------------------------------------------------------------------
-- Charger context: right-click a floor-dropped CarBatteryCharger ->
-- "Connect to Power Bar..." submenu (lists in-range bars), or
-- "Disconnect Cable" if already connected.
-- ----------------------------------------------------------------------------
local function findFloorCharger(worldObjects)
    for i = 1, #worldObjects do
        local o = worldObjects[i]
        if o and instanceof(o, "IsoWorldInventoryObject") then
            local item = o.getItem and o:getItem() or nil
            if item and item.getFullType and item:getFullType() == "Base.CarBatteryCharger" then
                return o, o:getSquare()
            end
        end
    end
    return nil, nil
end

local function onCableConnect(playerNum, args)
    local p = getSpecificPlayer(playerNum)
    if not p or not args then return end
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", CSR_PowerBar.CMD_CABLE_CON, args)
    elseif CSR_ServerCommands and CSR_ServerCommands.handlePowerCableConnect then
        CSR_ServerCommands.handlePowerCableConnect(p, args)
    end
end

local function onCableDisconnect(playerNum, args)
    local p = getSpecificPlayer(playerNum)
    if not p or not args then return end
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", CSR_PowerBar.CMD_CABLE_DIS, args)
    elseif CSR_ServerCommands and CSR_ServerCommands.handlePowerCableDisconnect then
        CSR_ServerCommands.handlePowerCableDisconnect(p, args)
    end
end

local function onFillChargerContextMenu(playerNum, context, worldObjects, test)
    if test == true then return true end
    if not isEnabled() then return end
    local _obj, sq = findFloorCharger(worldObjects)
    if not sq then return end
    local p = getSpecificPlayer(playerNum)
    if not p then return end

    local cx, cy, cz = sq:getX(), sq:getY(), sq:getZ()
    local existing = CSR_PowerBar.getChargerConnection(cx, cy, cz)

    if existing then
        local label = getText("ContextMenu_CSR_PowerBarDisconnect") or "EV Charger: Disconnect Cable"
        local opt = context:addOption(label, playerNum,
            onCableDisconnect, { chargerX = cx, chargerY = cy, chargerZ = cz })
        local tip = ISToolTip:new(); tip:initialise(); tip:setVisible(false)
        local energized = CSR_PowerBar.isChargerEnergized(sq)
        local statusKey = energized and "Tooltip_CSR_PowerBarChargerLive" or "Tooltip_CSR_PowerBarChargerDead"
        local statusFallback = energized and "Status: ENERGIZED" or "Status: cable connected, but bar has no power."
        tip.description = (getText(statusKey) or statusFallback) .. " <LINE> " ..
            (getText("Tooltip_CSR_PowerBarDisconnect") or
             "Disconnect this cable. Recovers ~%d%% of the wires used."):format(CSR_PowerBar.returnPct())
        opt.toolTip = tip
        return
    end

    -- Not connected — offer a submenu of in-range bars.
    local bars = CSR_PowerBar.findBarsCovering(sq)
    local rootLabel = getText("ContextMenu_CSR_PowerBarConnect") or "EV Charger: Connect to Power Bar..."
    local rootOpt = context:addOption(rootLabel, playerNum, nil)
    local rootTip = ISToolTip:new(); rootTip:initialise(); rootTip:setVisible(false)

    if #bars == 0 then
        rootOpt.notAvailable = true
        rootTip.description = "<RED>" .. (getText("Tooltip_CSR_PowerBarNoBarsInRange") or
            "No Power Bar within cable reach of this tile. Place a Power Bar nearby and add Electric Wires to extend its reach.")
        rootOpt.toolTip = rootTip
        return
    end

    rootTip.description = getText("Tooltip_CSR_PowerBarConnect") or
        "Connect this charger to a Power Bar. 1 Electric Wire is consumed per tile of distance."
    rootOpt.toolTip = rootTip

    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(rootOpt, sub)

    local haveW = countWires(p:getInventory())
    for i = 1, #bars do
        local entry = bars[i]
        local bar, dist = entry.node, entry.distance
        local labelFmt = getText("ContextMenu_CSR_PowerBarChargerEntry") or
            "Bar at (%d, %d) — %d tile(s) of cable"
        local entryLabel = labelFmt:format(bar.x, bar.y, dist)
        local subOpt = sub:addOption(entryLabel, playerNum, onCableConnect, {
            chargerX = cx, chargerY = cy, chargerZ = cz, barId = bar.id,
        })
        local subTip = ISToolTip:new(); subTip:initialise(); subTip:setVisible(false)
        subTip.description = (getText("Tooltip_CSR_PowerBarConnectEntry") or
            "Run cable to bar at (%d, %d), %d tile(s) away. Reach used: %d / %d."):format(
            bar.x, bar.y, dist, dist, bar.wires or 0)
        subOpt.toolTip = subTip
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillChargerContextMenu)

-- ----------------------------------------------------------------------------
-- Phantom-generator menu suppression: when the player right-clicks a tile
-- that has a CSR phantom IsoGenerator, strip the vanilla "Add Fuel / Toggle /
-- Take Generator / Inspect" options so it doesn't read as a real generator.
-- We identify vanilla options by their onSelect function pointer (locale-proof).
-- ----------------------------------------------------------------------------
local function isPhantomGenOnTile(worldObjects)
    for i = 1, #worldObjects do
        local o = worldObjects[i]
        if o and instanceof(o, "IsoGenerator") then
            local md = nil
            pcall(function() md = o:getModData() end)
            if md and md.csrPhantom then return true end
        end
    end
    -- Also check the underlying square (right-click can land on adjacent obj).
    for i = 1, #worldObjects do
        local o = worldObjects[i]
        if o and o.getSquare then
            local sq = o:getSquare()
            if sq then
                local g = nil
                pcall(function() g = sq:getGenerator() end)
                if g then
                    local md = nil
                    pcall(function() md = g:getModData() end)
                    if md and md.csrPhantom then return true end
                end
            end
        end
    end
    return false
end

local function suppressVanillaGeneratorMenu(playerNum, context, worldObjects, test)
    if test == true then return true end
    if not ISWorldObjectContextMenu then return end
    if not isPhantomGenOnTile(worldObjects) then return end

    local kill = {
        ISWorldObjectContextMenu.onInfoGenerator,
        ISWorldObjectContextMenu.onPlugGenerator,
        ISWorldObjectContextMenu.onActivateGenerator,
        ISWorldObjectContextMenu.onFixGenerator,
        ISWorldObjectContextMenu.onAddFuelGenerator,
        ISWorldObjectContextMenu.onTakeGenerator,
    }
    local function shouldRemove(opt)
        if not opt or not opt.onSelect then return false end
        for k = 1, #kill do
            if opt.onSelect == kill[k] then return true end
        end
        return false
    end

    local opts = context.options
    if not opts then return end
    -- Iterate backwards because we may remove entries.
    for i = #opts, 1, -1 do
        if shouldRemove(opts[i]) then
            table.remove(opts, i)
        end
    end
end

-- Register low-priority (after vanilla) so we can strip what they added.
Events.OnFillWorldObjectContextMenu.Add(suppressVanillaGeneratorMenu)

-- ----------------------------------------------------------------------------
-- Server -> client sync.
-- Whenever the server pushes a fresh full registry, replace local mirror.
-- ----------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= CSR_PowerBar.MOD_NAME then return end
    if command == CSR_PowerBar.CMD_SYNC_PUSH then
        if args and args.nodes then
            CSR_PowerBar.applyFullSync(args.nodes)
        end
        if args and args.chargers then
            CSR_PowerBar.applyChargerSync(args.chargers)
        end
    end
end

-- Request a full sync once we have a player on first tick. Avoids race with
-- the server's OnLoad in MP.
local _syncRequested = false
local function requestSyncOnce()
    if _syncRequested then return end
    if not isClient() then _syncRequested = true; return end
    local p = getSpecificPlayer(0)
    if not p then return end
    _syncRequested = true
    sendClientCommand(p, CSR_PowerBar.MOD_NAME, CSR_PowerBar.CMD_SYNC_REQ, {})
end

Events.OnServerCommand.Add(onServerCommand)
Events.OnPlayerUpdate.Add(function(_) requestSyncOnce() end)

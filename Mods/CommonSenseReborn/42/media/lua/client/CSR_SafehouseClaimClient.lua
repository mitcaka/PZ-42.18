require "CSR_FeatureFlags"
require "CSR_SafehouseClaim"
require "CSR_AA_InteropGuard"

--[[
    CSR_SafehouseClaimClient.lua
    Replaces the vanilla single-safehouse context menu with a multi-claim system.
    - Strips vanilla "Claim Safehouse" / "View Safehouse" / "Release Safehouse" options
    - Adds CSR versions that allow claiming up to MaxSafehouseClaims buildings
    - In MP: sends server commands. In SP: calls SafeHouse.addSafeHouse directly.
]]

CSR_SafehouseClaimClient = CSR_SafehouseClaimClient or {}

local MODULE = "CommonSenseReborn"

-- =============================================
-- NOTIFICATIONS
-- =============================================
local function notify(playerObj, text)
    if not playerObj then return end
    if HaloTextHelper and HaloTextHelper.addTextWithArrow then
        HaloTextHelper.addTextWithArrow(playerObj, text, true, HaloTextHelper.getColorGreen())
    elseif playerObj.Say then
        playerObj:Say(text)
    end
end

local function notifyError(playerObj, text)
    if not playerObj then return end
    if HaloTextHelper and HaloTextHelper.addTextWithArrow then
        HaloTextHelper.addTextWithArrow(playerObj, text, false, HaloTextHelper.getColorRed())
    elseif playerObj.Say then
        playerObj:Say(text)
    end
end

-- =============================================
-- BUILDING DETECTION
-- =============================================
local function getBuildingFromWorldObjects(worldobjects)
    if not worldobjects then return nil end
    for _, wo in ipairs(worldobjects) do
        if wo and wo.getSquare then
            local sq = wo:getSquare()
            if sq and sq:getBuilding() then
                return sq:getBuilding()
            end
        end
    end
    return nil
end

-- =============================================
-- CALLBACKS
-- =============================================
local function onClaimSafehouse(worldobjects, playerObj, args)
    if not playerObj or not args then return end
    local username = playerObj:getUsername()
    local count = CSR_SafehouseClaim.getOwnerCount(username)
    local max = CSR_SafehouseClaim.getMaxClaims()

    if count >= max then
        notifyError(playerObj, "Max safehouses claimed (" .. max .. ")")
        return
    end

    if isClient() then
        sendClientCommand(playerObj, MODULE, "ClaimSafehouse", {
            x = args.x, y = args.y, w = args.w, h = args.h,
            username = username,
        })
    else
        -- SP: create directly
        local existing = CSR_SafehouseClaim.findSafehouseAt(args.x, args.y, args.w, args.h)
        if existing then
            notifyError(playerObj, "Building already claimed")
            return
        end
        local house = SafeHouse.addSafeHouse(args.x, args.y, args.w, args.h, username)
        if house then
            house:setOwner(username)
            house:setTitle(username .. "'s Base " .. tostring(count + 1))
            notify(playerObj, "Safehouse claimed!")
        else
            notifyError(playerObj, "Failed to claim safehouse")
        end
    end
end

local function onReleaseSafehouse(worldobjects, playerObj, args)
    if not playerObj or not args then return end

    if isClient() then
        sendClientCommand(playerObj, MODULE, "ReleaseSafehouse", {
            x = args.x, y = args.y, w = args.w, h = args.h,
            username = playerObj:getUsername(),
        })
    else
        -- SP: remove directly
        local house = CSR_SafehouseClaim.findSafehouseAt(args.x, args.y, args.w, args.h)
        if house and house:getOwner() == playerObj:getUsername() then
            pcall(function() SafeHouse.removeSafeHouse(house) end)
            notify(playerObj, "Safehouse released")
        else
            notifyError(playerObj, "Cannot release this safehouse")
        end
    end
end

local function onViewSafehouse(worldobjects, safehouse, playerNum)
    if not safehouse then return end
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end
    local width = 500 + getCore():getOptionFontSizeReal() * 30
    local safehouseUI = ISSafehouseUI:new(
        (getCore():getScreenWidth() - width) / 2,
        getCore():getScreenHeight() / 2 - 225,
        width, 450, safehouse, playerObj
    )
    safehouseUI:initialise()
    safehouseUI:addToUIManager()
end

-- =============================================
-- STRIP VANILLA OPTIONS
-- =============================================
local function stripVanillaSafehouseOptions(context)
    if not context then return end
    if not context.removeOptionByName then return end
    -- Try translated names
    if getText then
        context:removeOptionByName(getText("ContextMenu_SafehouseClaim"))
        context:removeOptionByName(getText("ContextMenu_ViewSafehouse"))
        context:removeOptionByName(getText("ContextMenu_SafehouseRelease"))
    end
    -- Hardcoded English fallbacks
    context:removeOptionByName("Claim Safehouse")
    context:removeOptionByName("View Safehouse")
    context:removeOptionByName("Release Safehouse")
end

-- =============================================
-- CONTEXT MENU HOOK
-- =============================================
local function addSafehouseContextOptions(playerNum, context, worldobjects, test)
    if not CSR_SafehouseClaim.isEnabled() then return end

    -- Vanilla PZ only exposes safehouse claim/view/release in MP. In SP we
    -- must not add any of these entries (the underlying SafeHouse system
    -- and several of our own server commands are MP-only paths).
    if not isClient() then return end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    -- In MP, respect vanilla server safehouse settings.
    if isClient() then
        local playerSafehouse = true
        local adminSafehouse = false
        local serverOptions = getServerOptions and getServerOptions() or nil
        if serverOptions and serverOptions.getBoolean then
            playerSafehouse = serverOptions:getBoolean("PlayerSafehouse")
            adminSafehouse = serverOptions:getBoolean("AdminSafehouse")
        end

        if not playerSafehouse and not adminSafehouse then return end
        if not playerSafehouse and adminSafehouse then
            local access = playerObj:getAccessLevel()
            if not access or (access ~= "admin" and access ~= "Admin") then return end
        end
    end

    -- Find building from clicked objects or player square
    local building = getBuildingFromWorldObjects(worldobjects)
    if not building then
        local sq = playerObj:getCurrentSquare()
        if sq then building = sq:getBuilding() end
    end
    if not building then return end

    local def = building:getDef()
    if not def then return end

    local x, y, w, h = def:getX(), def:getY(), def:getW(), def:getH()
    local username = playerObj:getUsername()
    local currentCount = CSR_SafehouseClaim.getOwnerCount(username)
    local maxCount = CSR_SafehouseClaim.getMaxClaims()

    -- Check if this building is already a safehouse
    local existingSafehouse = CSR_SafehouseClaim.findSafehouseAt(x, y, w, h)

    if existingSafehouse then
        local owner = existingSafehouse:getOwner()
        local isOwner = owner == username
        local access = playerObj:getAccessLevel()
        local isAdmin = access and (access == "admin" or access == "Admin")

        -- View safehouse option (owner, member, or admin)
        context:addOption(
            "View Safehouse",
            worldobjects,
            onViewSafehouse,
            existingSafehouse,
            playerNum
        )

        -- Release option for owner/admin
        if isOwner or isAdmin then
            context:addOption(
                "Release Safehouse",
                worldobjects,
                onReleaseSafehouse,
                playerObj,
                { x = existingSafehouse:getX(), y = existingSafehouse:getY(),
                  w = existingSafehouse:getW(), h = existingSafehouse:getH() }
            )
        end
    else
        -- Not claimed: show claim option with count
        local label = "Claim Safehouse (" .. tostring(currentCount) .. "/" .. tostring(maxCount) .. ")"
        local option = context:addOption(label, worldobjects, onClaimSafehouse, playerObj,
            { x = x, y = y, w = w, h = h })

        if currentCount >= maxCount then
            option.notAvailable = true
            local tooltip = ISToolTip:new()
            tooltip:setVisible(false)
            tooltip:initialise()
            tooltip.description = "Maximum safehouses reached (" .. tostring(maxCount) .. ")"
            option.toolTip = tooltip
        end
    end
end

-- =============================================
-- CREATEEMENU WRAPPER
-- Wraps ISWorldObjectContextMenu.createMenu to:
-- 1. Strip vanilla safehouse options (added by Java createMenuEntries)
-- 2. Add our own claim/release/view options AFTER Java populates the menu
-- =============================================
local function hookCreateMenu()
    if not ISWorldObjectContextMenu or not ISWorldObjectContextMenu.createMenu then return end
    if ISWorldObjectContextMenu.__csr_safehouse_patched then return end
    ISWorldObjectContextMenu.__csr_safehouse_patched = true

    local original = ISWorldObjectContextMenu.createMenu
    ISWorldObjectContextMenu.createMenu = function(player, worldobjects, x, y, test)
        local result = original(player, worldobjects, x, y, test)
        if test then return result end
        if CSR_AA_InteropGuard and CSR_AA_InteropGuard.isInForeignInteriorCell
                and CSR_AA_InteropGuard.isInForeignInteriorCell(player) then
            return result
        end
        if not CSR_SafehouseClaim.isEnabled() then return result end

        local context = getPlayerContextMenu(player)
        if not context then return result end

        -- Strip Java-generated vanilla safehouse options
        stripVanillaSafehouseOptions(context)

        -- Add our multi-claim options
        addSafehouseContextOptions(player, context, worldobjects, test)

        return result
    end
end

-- =============================================
-- SERVER RESPONSE HANDLER
-- =============================================
local function onServerCommand(module, command, args)
    if module ~= MODULE then return end
    local player = getPlayer()
    if not player then return end

    if command == "SafehouseClaimResult" then
        local msg = args and args.text or ""
        local success = args and args.success
        if success then
            notify(player, msg)
        else
            notifyError(player, msg)
        end
        return
    end

    if command == "SafehouseClaimApproved" then
        -- Server validated our claim; call the vanilla client function so the packet
        -- carries the correct playerIndex (server-side addSafeHouse yields playerIndex:-1).
        if not args then return end
        local x, y = args.x, args.y
        if not x or not y then return end
        local sq = getCell():getGridSquare(x, y, 0)
        if sq then
            sendSafehouseClaim(sq, player, player:getUsername())
            notify(player, "Safehouse claimed!")
        end
        return
    end
end

-- =============================================
-- INIT
-- =============================================
local function init()
    -- Track B (v1.8.0): when the CSR Claims override is enabled,
    -- CSR_ClaimContextMenu owns the right-click claim/release entries and
    -- CSR_ClaimClient owns the result/broadcast wiring. Skip the legacy
    -- vanilla-context hook so we don't double-list claim options.
    if CSR_FeatureFlags and CSR_FeatureFlags.isCSRClaimsOverrideEnabled
        and CSR_FeatureFlags.isCSRClaimsOverrideEnabled() == true then
        return
    end
    hookCreateMenu()
end

if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(init) end
    if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
end

return CSR_SafehouseClaimClient

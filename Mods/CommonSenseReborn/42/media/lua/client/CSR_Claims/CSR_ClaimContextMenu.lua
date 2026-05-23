--[[
    CSR_ClaimContextMenu.lua
    -------------------------------------------------------------------------
    Track B (v1.8.0) -- world-object context menu for CSR-owned claims.

    Replaces (when active) the vanilla "Claim Safehouse" / "View Safehouse" /
    "Release Safehouse" entries AND the legacy CSR_SafehouseClaimClient
    entries with new entries that route through CSR_ClaimClient request
    helpers (which talk to CSR_ClaimServer).

    Activation is gated on `CSR_FeatureFlags.isCSRClaimsOverrideEnabled()`.
    Until Step 10 of Track B introduces that flag the function does not
    exist, so this module is dormant and the legacy paths (vanilla and
    CSR_SafehouseClaimClient) keep working unchanged.

    Hard rules:
      * Kahlua: no goto / ::label::. No :split() on Lua strings.
      * All UI text via getText("IGUI_*") with English fallbacks (the JSON
        keys land in Step 5/Step 10).
      * Wrap every Java numeric return with tonumber(...) or 0.
--]]

require "CSR_FeatureFlags"
require "CSR_Claims/CSR_ClaimClient"
require "CSR_AA_InteropGuard"

CSR_ClaimContextMenu = CSR_ClaimContextMenu or {}

local MODULE = "CommonSenseReborn"

-- =========================================================================
-- Activation gate
-- =========================================================================

local function overrideOn()
    return CSR_FeatureFlags
        and CSR_FeatureFlags.isCSRClaimsOverrideEnabled
        and CSR_FeatureFlags.isCSRClaimsOverrideEnabled() == true
end

-- =========================================================================
-- i18n with English fallback (full key set lands in Translate/EN/UI.json
-- during Step 10).
-- =========================================================================

local function tr(key, fallback)
    if getText then
        local s = getText(key)
        if s and s ~= key then return s end
    end
    return fallback or key
end

-- =========================================================================
-- Notifications
-- =========================================================================

local function notifyOk(playerObj, text)
    if not playerObj then return end
    if HaloTextHelper and HaloTextHelper.addTextWithArrow then
        HaloTextHelper.addTextWithArrow(playerObj, text, true,
            HaloTextHelper.getColorGreen())
    end
end

local function notifyErr(playerObj, text)
    if not playerObj then return end
    if HaloTextHelper and HaloTextHelper.addTextWithArrow then
        HaloTextHelper.addTextWithArrow(playerObj, text, false,
            HaloTextHelper.getColorRed())
    end
end

-- =========================================================================
-- Building detection (matches existing CSR_SafehouseClaimClient pattern)
-- =========================================================================

local function getBuildingFromWorldObjects(worldobjects)
    if not worldobjects then return nil end
    for _, wo in ipairs(worldobjects) do
        if wo and wo.getSquare then
            local sq = wo:getSquare()
            if sq and sq:getBuilding() then return sq:getBuilding() end
        end
    end
    return nil
end

-- =========================================================================
-- Strip vanilla + legacy CSR entries
-- =========================================================================

local function stripExistingEntries(context)
    if not context or not context.removeOptionByName then return end
    local names = {
        tr("ContextMenu_SafehouseClaim",   "Claim Safehouse"),
        tr("ContextMenu_ViewSafehouse",    "View Safehouse"),
        tr("ContextMenu_SafehouseRelease", "Release Safehouse"),
        "Claim Safehouse",
        "View Safehouse",
        "Release Safehouse",
    }
    for i = 1, #names do
        context:removeOptionByName(names[i])
    end
    -- Strip any "Claim Safehouse (n/m)" entries the legacy module added.
    -- removeOptionByName needs an exact match, so iterate and prune.
    if context.options then
        local i = 1
        while i <= #context.options do
            local opt = context.options[i]
            local name = opt and opt.name
            if type(name) == "string" and string.find(name, "^Claim Safehouse %(") then
                table.remove(context.options, i)
            else
                i = i + 1
            end
        end
    end
end

-- =========================================================================
-- Click callbacks
-- =========================================================================

local function onClaim(worldobjects, playerObj, args)
    if not playerObj or not args then return end
    local user = playerObj:getUsername()
    if not user or user == "" then return end

    -- Existing claim guard (registry-side check is authoritative; this is
    -- just a UX short-circuit).
    local existing = CSR_ClaimClient.getClaimAt(args.x + 0.5, args.y + 0.5)
    if existing then
        notifyErr(playerObj,
            tr("IGUI_CSR_AlreadyClaimed", "Building already claimed"))
        return
    end

    CSR_ClaimClient.requestClaim({
        kind        = "personal",
        x           = args.x, y = args.y,
        w           = args.w, h = args.h,
        title       = user .. "'s safehouse",
        factionName = "",
        vehicleId   = "",
    })
end

local function onRelease(worldobjects, playerObj, args)
    if not playerObj or not args or not args.id then return end
    CSR_ClaimClient.requestRelease(args.id)
end

local function onView(worldobjects, safehouse, playerNum)
    if not safehouse then return end
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end
    local width = 500 + (tonumber(getCore():getOptionFontSizeReal()) or 1) * 30
    local ui = ISSafehouseUI:new(
        (tonumber(getCore():getScreenWidth()) or 1024 - width) / 2,
        (tonumber(getCore():getScreenHeight()) or 768) / 2 - 225,
        width, 450, safehouse, playerObj
    )
    ui:initialise()
    ui:addToUIManager()
end

-- =========================================================================
-- Entry assembly
-- =========================================================================

local function addEntries(playerNum, context, worldobjects)
    if not overrideOn() then return end

    -- Vanilla PZ only shows safehouse options in MP, and the CSR Claims
    -- registry is server-side only. Skip SP entirely so we never advertise
    -- a feature that has nowhere to land.
    if not isClient() then return end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    -- MP: respect server's PlayerSafehouse / AdminSafehouse switches.
    if isClient() then
        local playerSafehouse, adminSafehouse = true, false
        local serverOptions = getServerOptions and getServerOptions() or nil
        if serverOptions and serverOptions.getBoolean then
            playerSafehouse = serverOptions:getBoolean("PlayerSafehouse")
            adminSafehouse = serverOptions:getBoolean("AdminSafehouse")
        end
        if not playerSafehouse and not adminSafehouse then return end
        if not playerSafehouse and adminSafehouse then
            local access = playerObj:getAccessLevel()
            if not access or (access ~= "admin" and access ~= "Admin") then
                return
            end
        end
    end

    local building = getBuildingFromWorldObjects(worldobjects)
    if not building then
        local sq = playerObj:getCurrentSquare()
        if sq then building = sq:getBuilding() end
    end
    if not building then return end

    local def = building:getDef()
    if not def then return end

    local x = tonumber(def:getX()) or 0
    local y = tonumber(def:getY()) or 0
    local w = tonumber(def:getW()) or 1
    local h = tonumber(def:getH()) or 1
    local user = playerObj:getUsername() or ""

    -- Strip legacy / vanilla entries before adding our own.
    stripExistingEntries(context)

    local existing = CSR_ClaimClient.getClaimAt(x + 0.5, y + 0.5)
    if existing then
        local owner = existing.owner
        local isOwner = owner == user
        local access = playerObj:getAccessLevel()
        local isAdmin = access and (access == "admin" or access == "Admin")
        local sh = CSR_ClaimClient.getSafehouseForClaim(existing.id)
        if sh then
            context:addOption(
                tr("ContextMenu_ViewSafehouse", "View Safehouse"),
                worldobjects, onView, sh, playerNum)
        end
        if isOwner or isAdmin then
            context:addOption(
                tr("ContextMenu_SafehouseRelease", "Release Safehouse"),
                worldobjects, onRelease, playerObj, { id = existing.id })
        end
    else
        -- Personal claim quota -- read from registry mirror.
        local count = 0
        local mirror = CSR_ClaimClient._claimMirror or {}
        for _, row in pairs(mirror) do
            if row.kind == "personal" and row.owner == user then
                count = count + 1
            end
        end
        local maxClaims = 1
        if SandboxVars and SandboxVars.CommonSenseReborn
            and SandboxVars.CommonSenseReborn.MaxSafehouseClaims then
            maxClaims = tonumber(SandboxVars.CommonSenseReborn.MaxSafehouseClaims)
                or maxClaims
        end

        local label = tr("ContextMenu_SafehouseClaim", "Claim Safehouse")
            .. " (" .. tostring(count) .. "/" .. tostring(maxClaims) .. ")"
        local option = context:addOption(label, worldobjects, onClaim, playerObj,
            { x = x, y = y, w = w, h = h })
        if count >= maxClaims then
            option.notAvailable = true
            local tt = ISToolTip:new()
            tt:setVisible(false)
            tt:initialise()
            tt.description = tr("IGUI_CSR_MaxClaims",
                "Maximum safehouses reached") .. " (" .. tostring(maxClaims) .. ")"
            option.toolTip = tt
        end
    end
end

-- =========================================================================
-- Hook ISWorldObjectContextMenu.createMenu (post-vanilla, post-legacy)
-- =========================================================================

local function hookCreateMenu()
    if not ISWorldObjectContextMenu or not ISWorldObjectContextMenu.createMenu then
        return
    end
    if ISWorldObjectContextMenu.__csr_claimoverride_patched then return end
    ISWorldObjectContextMenu.__csr_claimoverride_patched = true

    local original = ISWorldObjectContextMenu.createMenu
    ISWorldObjectContextMenu.createMenu = function(player, worldobjects, x, y, test)
        -- Vanilla NPE in ISFarmingMenu.getShovel that previously surfaced
        -- here is fixed at the source by CSR_FarmingMenuSafety.lua. We
        -- now call vanilla directly so genuine errors are not masked.
        local result = original(player, worldobjects, x, y, test)
        if test then return result end
        if CSR_AA_InteropGuard and CSR_AA_InteropGuard.isInForeignInteriorCell
                and CSR_AA_InteropGuard.isInForeignInteriorCell(player) then
            return result
        end
        if not overrideOn() then return result end

        local context = getPlayerContextMenu(player)
        if context then addEntries(player, context, worldobjects) end
        return result
    end
end

-- =========================================================================
-- Init
-- =========================================================================

local function init()
    hookCreateMenu()
end

Events.OnGameStart.Add(init)

return CSR_ClaimContextMenu

--[[
    CSR_VanillaSafehouseRouter.lua
    -------------------------------------------------------------------------
    Tier C (v1.8.4) -- when EnableReplaceVanillaSafehouseUI is ON (default),
    the vanilla "Safehouse" / "View Safehouse" right-click context menu
    option opens the unified CSR Claims Manager instead of ISSafehouseUI.

    Implementation:
      * Monkey-patch ISWorldObjectContextMenu.onViewSafeHouse. The vanilla
        Java context menu uses this callback when the user clicks the
        view-safehouse option. Wrapping it gives us the cleanest hook with
        zero string-matching against context-menu labels.
      * The original function is stored in _origOnViewSafeHouse so:
        - the sandbox flag can route to vanilla at runtime
        - other mods that wrap on top of us can chain through
        - the in-window "Open Vanilla UI" button keeps the legacy panel
          reachable

    Hard rules:
      * NEVER mutate vanilla state during the wrap. Only choose a UI to open.
      * Honour the existing isMultipleSafehouseEnabled() umbrella flag --
        if CSR's claim system is fully off, fall through to vanilla.
      * Kahlua: no goto / ::label::. Plain functions only.
--]]

if not ISWorldObjectContextMenu then return end

-- v1.8.16: Wrap is now deferred to OnGameStart. PZ loads files in
-- alphabetical-by-directory order; CSR_Claims/ ran BEFORE ISUI/ which
-- meant `_origOnViewSafeHouse` was always nil at wrap time AND vanilla's
-- subsequent `ISWorldObjectContextMenu.onViewSafeHouse = function(...)`
-- definition silently clobbered our override. Symptom: clicking the
-- safehouse menu always opened ISSafehouseUI even with the flag ON.
-- Wrapping in OnGameStart guarantees vanilla has already populated the
-- field, so our wrap takes effect and the original chain stays intact.

local function isFlagOn()
    if not CSR_FeatureFlags then return false end
    if CSR_FeatureFlags.isMultipleSafehouseEnabled
       and not CSR_FeatureFlags.isMultipleSafehouseEnabled() then
        return false
    end
    if CSR_FeatureFlags.isReplaceVanillaSafehouseUIEnabled then
        return CSR_FeatureFlags.isReplaceVanillaSafehouseUIEnabled()
    end
    return true
end

local function openCsrPanel(playerObj, safehouse)
    if not CSR_ClaimsManagerPanel or not CSR_ClaimsManagerPanel.open then
        return false
    end
    CSR_ClaimsManagerPanel.open(playerObj or getPlayer())
    -- Best-effort: switch to Faction tab when the safehouse is faction-owned.
    if safehouse and CSR_ClaimsManagerPanel.instance then
        local panel = CSR_ClaimsManagerPanel.instance
        if panel.setTab then
            local isFaction = false
            if safehouse.getOwner then
                local owner = safehouse:getOwner() or ""
                if Faction and Faction.getFaction and owner ~= "" then
                    local f = Faction.getFaction(owner)
                    if f then isFaction = true end
                end
            end
            panel:setTab(isFaction and "faction" or "personal")
        end
    end
    return true
end

local _origOnViewSafeHouse = nil
local _origSafehouseUINew  = nil
local _origOnTakeSafeHouse = nil

-- v1.8.16b: intercept ALL three vanilla entry points to ISSafehouseUI:
--   1. ISWorldObjectContextMenu.onViewSafeHouse  (right-click world)
--   2. ISSafehousesList:addToUIManager-time path (admin Safehouses list)
--   3. ISUserPanelUI safehouse tab "modal"       (client UserPanel)
-- Every entry point ultimately calls ISSafehouseUI:new(...) followed by
-- :initialise() and :addToUIManager(). Wrapping :new is the single
-- choke-point that catches ALL three -- when our flag is on we open
-- the CSR Claims Manager and return a no-op stub so the caller's
-- subsequent :initialise() / :addToUIManager() are harmless.

local function makeStubPanel()
    local stub = {}
    stub.initialise        = function() end
    stub.instantiate       = function() end
    stub.addToUIManager    = function() end
    stub.removeFromUIManager = function() end
    stub.setVisible        = function() end
    stub.close             = function() end
    stub.populateList      = function() end
    return stub
end

local function installWrap()
    -- Wrap the world-object context menu entry. Keeps the legacy
    -- "Open Vanilla UI" button reachable via _origOnViewSafeHouse.
    if ISWorldObjectContextMenu and not ISWorldObjectContextMenu.__csr_safehouseRouterWrapped then
        _origOnViewSafeHouse = ISWorldObjectContextMenu.onViewSafeHouse
        if _origOnViewSafeHouse then
            ISWorldObjectContextMenu.__csr_safehouseRouterWrapped = true
            ISWorldObjectContextMenu.onViewSafeHouse = function(worldobjects, safehouse, player)
                if isFlagOn() then
                    local playerObj = nil
                    if type(player) == "number" and getSpecificPlayer then
                        playerObj = getSpecificPlayer(player)
                    elseif type(player) == "userdata" then
                        playerObj = player
                    end
                    if openCsrPanel(playerObj, safehouse) then return end
                end
                if _origOnViewSafeHouse then
                    return _origOnViewSafeHouse(worldobjects, safehouse, player)
                end
            end
        end
    end

    -- Wrap ISSafehouseUI:new so the admin Safehouses list and the
    -- client UserPanel safehouse tab also route through CSR.
    if ISSafehouseUI and not ISSafehouseUI.__csr_safehouseRouterWrapped then
        _origSafehouseUINew = ISSafehouseUI.new
        if _origSafehouseUINew then
            ISSafehouseUI.__csr_safehouseRouterWrapped = true
            ISSafehouseUI.new = function(self, x, y, width, height, safehouse, player)
                if isFlagOn() then
                    if openCsrPanel(player, safehouse) then
                        return makeStubPanel()
                    end
                end
                return _origSafehouseUINew(self, x, y, width, height, safehouse, player)
            end
        end
    end

    -- v1.8.36: wrap vanilla "Take Safehouse" so right-click claim goes
    -- through CSR_ClaimRequest (registry-authoritative) instead of vanilla
    -- sendSafehouseClaim (which only creates a SafeHouse with no CSR row,
    -- so our permission/audit/padlock layer never sees it).
    if ISWorldObjectContextMenu and not ISWorldObjectContextMenu.__csr_takeSafehouseWrapped then
        _origOnTakeSafeHouse = ISWorldObjectContextMenu.onTakeSafeHouse
        if _origOnTakeSafeHouse then
            ISWorldObjectContextMenu.__csr_takeSafehouseWrapped = true
            ISWorldObjectContextMenu.onTakeSafeHouse = function(worldobjects, square, player)
                if isFlagOn() and CSR_ClaimClient and CSR_ClaimClient.requestClaim then
                    local playerObj = nil
                    if type(player) == "number" and getSpecificPlayer then
                        playerObj = getSpecificPlayer(player)
                    elseif type(player) == "userdata" then
                        playerObj = player
                    end
                    local user = playerObj and playerObj.getUsername and playerObj:getUsername() or ""
                    local building = square and square.getBuilding and square:getBuilding() or nil
                    local def = building and building.getDef and building:getDef() or nil
                    if def and user ~= "" then
                        local x, y = def:getX(), def:getY()
                        local w, h = def:getW(), def:getH()
                        -- Short-circuit if a CSR row already covers this footprint
                        local existing = CSR_ClaimClient.getClaimAt
                            and CSR_ClaimClient.getClaimAt(x + 0.5, y + 0.5)
                        if not existing then
                            CSR_ClaimClient.requestClaim({
                                kind        = "personal",
                                x           = x, y = y,
                                w           = w, h = h,
                                title       = user .. "'s safehouse",
                                factionName = "",
                                vehicleId   = "",
                            })
                            return
                        end
                    end
                end
                if _origOnTakeSafeHouse then
                    return _origOnTakeSafeHouse(worldobjects, square, player)
                end
            end
        end
    end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(installWrap)
end
-- Try once at file load too, harmless no-op if vanilla isn't ready yet
installWrap()

-- Public helper consumed by the in-window button in CSR_SafehouseOutline.
CSR_VanillaSafehouseRouter = CSR_VanillaSafehouseRouter or {}
CSR_VanillaSafehouseRouter.openVanillaSafehouseUI = function(safehouse, playerObj)
    if not _origOnViewSafeHouse then return false end
    local pIndex = 0
    if playerObj and playerObj.getPlayerNum then
        pIndex = playerObj:getPlayerNum() or 0
    end
    _origOnViewSafeHouse(nil, safehouse, pIndex)
    return true
end

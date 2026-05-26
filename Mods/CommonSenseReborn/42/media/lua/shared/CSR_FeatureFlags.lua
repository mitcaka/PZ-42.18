CSR_FeatureFlags = {}

local function sandbox()
    return SandboxVars and SandboxVars.CommonSenseReborn or {}
end

function CSR_FeatureFlags.isEntryActionsEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("EntryActions")
        if override ~= nil then return override end
    end
    return sandbox().EnableEntryActions ~= false
end

function CSR_FeatureFlags.isPryEnabled()
    return CSR_FeatureFlags.isEntryActionsEnabled() and sandbox().EnablePrySystem == true
end

function CSR_FeatureFlags.isLockpickEnabled()
    return CSR_FeatureFlags.isEntryActionsEnabled() and sandbox().EnableScrewdriverLockpick ~= false
end

function CSR_FeatureFlags.isAlternateCanOpeningEnabled()
    return sandbox().EnableAlternateCanOpening ~= false
end

function CSR_FeatureFlags.isRepairEnabled()
    return sandbox().EnableRepairExtensions ~= false
end

function CSR_FeatureFlags.isRepairAllClothingEnabled()
    return CSR_FeatureFlags.isRepairEnabled() and sandbox().EnableRepairAllClothing ~= false
end

function CSR_FeatureFlags.isTearAllNearbyClothingEnabled()
    return sandbox().EnableTearAllNearbyClothing ~= false
end

function CSR_FeatureFlags.isEquipmentQoLEnabled()
    return sandbox().EnableEquipmentQoL ~= false
end

function CSR_FeatureFlags.isCorpseIgniteEnabled()
    return sandbox().EnableCorpseIgnite ~= false
end

function CSR_FeatureFlags.isPlayerMapTrackingEnabled()
    return sandbox().EnablePlayerMapTracking ~= false and (sandbox().PlayerMapVisibilityMode or 1) ~= 3
end

function CSR_FeatureFlags.isSeatbeltEnabled()
    return sandbox().EnableSeatbeltProtection ~= false
end

function CSR_FeatureFlags.isWalkingActionsEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("WalkingItemActions")
        if override ~= nil then return override end
    end
    return sandbox().EnableWalkingItemActions ~= false
end

function CSR_FeatureFlags.isVehicleMechanicsQoLEnabled()
    return sandbox().EnableVehicleMechanicsQoL ~= false
end

function CSR_FeatureFlags.isImprovisedHotwireEnabled()
    return sandbox().EnableImprovisedHotwire ~= false
end

function CSR_FeatureFlags.isUnHotwireEnabled()
    return sandbox().EnableUnHotwire ~= false
end

function CSR_FeatureFlags.isVehicleDoorPryEnabled()
    return sandbox().EnableVehicleDoorPry ~= false and CSR_FeatureFlags.isPryEnabled()
end

function CSR_FeatureFlags.isGarageDoorPryEnabled()
    return sandbox().EnableGarageDoorPry ~= false and CSR_FeatureFlags.isPryEnabled()
end

function CSR_FeatureFlags.isSafeDoorPryEnabled()
    return sandbox().EnableSafeDoorPry == true and CSR_FeatureFlags.isPryEnabled()
end

function CSR_FeatureFlags.isWashMenuSplitEnabled()
    return sandbox().EnableWashMenuSplits ~= false
end

function CSR_FeatureFlags.isWashAllEnabled()
    return sandbox().EnableWashAll ~= false
end

function CSR_FeatureFlags.isJarCappingEnabled()
    return sandbox().EnableJarCapping ~= false
end

function CSR_FeatureFlags.isHomeCanningEnabled()
    return sandbox().EnableHomeCanning ~= false
end

function CSR_FeatureFlags.isRouletteSessionEnabled()
    return sandbox().EnableRouletteSession ~= false
end

function CSR_FeatureFlags.isRouletteRealDeathEnabled()
    return sandbox().RouletteRealDeath == true
end

function CSR_FeatureFlags.isDashboardHighlightsEnabled()
    return sandbox().EnableDashboardHighlights ~= false
end

function CSR_FeatureFlags.isPourCanContentsEnabled()
    return sandbox().EnablePourCanContents ~= false
end

function CSR_FeatureFlags.isProximityLootHelperEnabled()
    if sandbox().EnableProximityLootHelper == false then return false end
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("ProximityLootHelper")
        if override ~= nil then return override end
    end
    return true
end

function CSR_FeatureFlags.isZombieDensityOverlayEnabled()
    return sandbox().EnableZombieDensityOverlay ~= false
end

function CSR_FeatureFlags.isCityStandpipesEnabled()
    return sandbox().EnableCityStandpipes ~= false
end

function CSR_FeatureFlags.isUtilityHudEnabled()
    return sandbox().EnableUtilityHud ~= false
end

function CSR_FeatureFlags.isCSRRadialMenuEnabled()
    return sandbox().EnableCSRRadialMenu ~= false
end

function CSR_FeatureFlags.isPlayerTradingEnabled()
    return sandbox().EnablePlayerTrading ~= false
end

function CSR_FeatureFlags.isLootFilterEnabled()
    return sandbox().EnableLootFilter ~= false
end

function CSR_FeatureFlags.isItemInsightTooltipsEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("ItemInsightTooltips")
        if override ~= nil then return override end
    end
    return sandbox().EnableItemInsightTooltips ~= false
end

function CSR_FeatureFlags.isSmartVehicleKeyLabelsEnabled()
    return sandbox().EnableSmartVehicleKeyLabels ~= false
end

function CSR_FeatureFlags.isEatAllStackEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("EatAllStack")
        if override ~= nil then return override end
    end
    return sandbox().EnableEatAllStack ~= false
end

function CSR_FeatureFlags.isMagazineBatchActionsEnabled()
    return sandbox().EnableMagazineBatchActions ~= false
end

function CSR_FeatureFlags.isQuickDeviceToggleEnabled()
    return sandbox().EnableQuickDeviceToggle ~= false
end

function CSR_FeatureFlags.isVisualSoundCuesEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("VisualSoundCues")
        if override ~= nil then return override end
    end
    return sandbox().EnableVisualSoundCues ~= false
end

function CSR_FeatureFlags.isVehicleClockEnabled()
    return sandbox().EnableVehicleClock ~= false
end

function CSR_FeatureFlags.isEatWhileDrivingEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("EatWhileDriving")
        if override ~= nil then return override end
    end
    return sandbox().EnableEatWhileDriving ~= false
end

function CSR_FeatureFlags.getEatWhileDrivingMaxSpeed()
    local v = sandbox().EatWhileDrivingMaxSpeed
    if type(v) ~= "number" then return 60 end
    if v < 0 then return 0 end
    if v > 120 then return 120 end
    return v
end

function CSR_FeatureFlags.isBinksScooperEnabled()
    return sandbox().EnableBinksScooper ~= false
end

function CSR_FeatureFlags.getBinksScooperRadius()
    local v = sandbox().BinksScooperRadius
    if type(v) ~= "number" then return 3 end
    if v < 1 then return 1 end
    if v > 6 then return 6 end
    return v
end

function CSR_FeatureFlags.getBinksScooperMaxPerAction()
    local v = sandbox().BinksScooperMaxPerAction
    if type(v) ~= "number" then return 30 end
    if v < 10 then return 10 end
    if v > 60 then return 60 end
    return v
end

function CSR_FeatureFlags.isSweepTrashEnabled()
    return sandbox().EnableSweepTrash ~= false
end

function CSR_FeatureFlags.isSweepAshesEnabled()
    return sandbox().EnableSweepAshes ~= false
end

function CSR_FeatureFlags.isClipboardEnabled()
    return sandbox().EnableClipboardQoL ~= false
end

function CSR_FeatureFlags.isKnowledgeSharingEnabled()
    return sandbox().EnableKnowledgeSharing ~= false
end

function CSR_FeatureFlags.isQuickSitEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("QuickSit")
        if override ~= nil then return override end
    end
    return sandbox().EnableQuickSit ~= false
end

function CSR_FeatureFlags.isWeaponHudOverlayEnabled()
    if CSR_FeatureFlags.isCleanHotBarActive() then return false end
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("WeaponHudOverlay")
        if override ~= nil then return override end
    end
    return sandbox().EnableWeaponHudOverlay ~= false
end

function CSR_FeatureFlags.isMaskHudEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("MaskHud")
        if override ~= nil then return override end
    end
    return sandbox().EnableMaskHud ~= false
end

function CSR_FeatureFlags.isStatusBarEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("StatusBar")
        if override ~= nil then return override end
    end
    return sandbox().EnableStatusBar ~= false
end

function CSR_FeatureFlags.isEquipmentPanelEnabled()
    if sandbox().EquipmentPanelDockMode == 3 then return false end
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("EquipmentPanel")
        if override ~= nil then return override end
    end
    return sandbox().EnableEquipmentPanel ~= false
end

function CSR_FeatureFlags.isStairVaultGuardEnabled()
    return sandbox().EnableStairVaultGuard ~= false
end

function CSR_FeatureFlags.isBarrelCapFixEnabled()
    return sandbox().EnableBarrelCapFix ~= false
end

function CSR_FeatureFlags.isPerfumeAsDisinfectantEnabled()
    return sandbox().EnablePerfumeAsDisinfectant ~= false
end

function CSR_FeatureFlags.isLighterUsesEnabled()
    return sandbox().EnableLighterUses ~= false
end

function CSR_FeatureFlags.isExtendedBatteryLifeEnabled()
    return sandbox().EnableExtendedBatteryLife ~= false
end

function CSR_FeatureFlags.getBatteryLifeMultiplier()
    local value = tonumber(sandbox().BatteryLifeMultiplier) or 100
    if value < 1 then return 1 end
    if value > 2000 then return 2000 end
    return value
end

function CSR_FeatureFlags.isHydrationSenseEnabled()
    return sandbox().EnableHydrationSense ~= false
end

function CSR_FeatureFlags.getHydrationSenseMode()
    local raw = sandbox().HydrationSenseMode
    local v = tonumber(raw)
    local s = tostring(raw or ""):lower()
    if v == 2 or s == "manual" or s == "2" then return "manual" end
    return "auto"
end

function CSR_FeatureFlags.isDangerousThirstEnabled()
    return sandbox().DangerousThirst == true
end

function CSR_FeatureFlags.isCleanHotBarActive()
    return getActivatedMods and getActivatedMods():contains("CleanHotBar") or false
end

-- CleanUI replaces ISInventoryPage/Pane and ships its own DragSort. CSR
-- hooks that touch the same surface should yield to it.
function CSR_FeatureFlags.isCleanUIActive()
    return getActivatedMods and getActivatedMods():contains("CleanUI") or false
end

-- More Car Features + Spawn Zones Expansion (GamestaMechanic). Ships its
-- own roof climb and hood crafting surface. CSR yields those hard-conflict
-- slices when this is active; weather exposure remains a sandboxed local
-- stat effect and can coexist.
function CSR_FeatureFlags.isWayMoreCarsActive()
    return getActivatedMods and getActivatedMods():contains("WayMoreCars") or false
end

-- Standalone "ClimbableVehicles". Same surface as our roof climb feature.
function CSR_FeatureFlags.isClimbableVehiclesActive()
    return getActivatedMods and getActivatedMods():contains("ClimbableVehicles") or false
end

-- Standalone "VehicleTrunkCraftingSurface". Adds trunk/truckbed/cargo as
-- an any-surface craft anchor via a FindCraftSurface fallback. CSR yields
-- the trunk slice of its unified vehicle craft surface when this loads.
function CSR_FeatureFlags.isVehicleTrunkCraftModActive()
    return getActivatedMods and getActivatedMods():contains("VehicleTrunkCraftingSurface") or false
end

function CSR_FeatureFlags.isRoofClimbEnabled()
    if CSR_FeatureFlags.isWayMoreCarsActive() then return false end
    if CSR_FeatureFlags.isClimbableVehiclesActive() then return false end
    return sandbox().EnableRoofClimb ~= false
end

function CSR_FeatureFlags.isVehicleWeatherExposureEnabled()
    return sandbox().EnableVehicleWeatherExposure == true
end

function CSR_FeatureFlags.isVehicleHoodCraftEnabled()
    if CSR_FeatureFlags.isWayMoreCarsActive() then return false end
    if not CSR_FeatureFlags.isVehicleCraftSurfaceMasterEnabled() then return false end
    return sandbox().EnableVehicleHoodCraft ~= false
end

function CSR_FeatureFlags.isVehicleTrunkCraftEnabled()
    if CSR_FeatureFlags.isWayMoreCarsActive() then return false end
    if CSR_FeatureFlags.isVehicleTrunkCraftModActive() then return false end
    if not CSR_FeatureFlags.isVehicleCraftSurfaceMasterEnabled() then return false end
    return sandbox().EnableVehicleTrunkCraft ~= false
end

function CSR_FeatureFlags.isVehicleCraftSurfaceMasterEnabled()
    return sandbox().EnableVehicleCraftSurfaces ~= false
end

function CSR_FeatureFlags.isVehicleClaimEnabled()
    return sandbox().EnableVehicleClaim ~= false
end

function CSR_FeatureFlags.isLadderClimbEnabled()
    return sandbox().EnableLadderClimb ~= false
end

function CSR_FeatureFlags.isClaimRespawnEnabled()
    return sandbox().EnableClaimRespawn ~= false
end

function CSR_FeatureFlags.isLoginProtectionEnabled()
    return sandbox().EnableLoginProtection ~= false
end

function CSR_FeatureFlags.getLoginProtectionSeconds()
    local value = tonumber(sandbox().LoginProtectionSeconds) or 45
    if value < 1 then return 1 end
    if value > 120 then return 120 end
    return value
end

function CSR_FeatureFlags.isMultipleSafehouseEnabled()
    return sandbox().EnableMultipleSafehouse ~= false
end

function CSR_FeatureFlags.isFireworkEnabled()
    return sandbox().EnableFirework ~= false
end

function CSR_FeatureFlags.isNoticeBoardEnabled()
    return sandbox().EnableNoticeBoard ~= false
end

function CSR_FeatureFlags.isBoltCutterEnabled()
    return sandbox().EnableBoltCutter ~= false and CSR_FeatureFlags.isPryEnabled()
end

function CSR_FeatureFlags.isFenceCuttingEnabled()
    return sandbox().EnableFenceCutting ~= false and CSR_FeatureFlags.isBoltCutterEnabled()
end

function CSR_FeatureFlags.isAdminAuthoritative()
    return sandbox().AdminAuthoritativeControl == true
end

-- Client-local override: nil = use sandbox, true/false = player override.
-- Kept for backward compatibility; CSR_PlayerPrefs is the primary store now.
CSR_FeatureFlags._dualWieldLocalOverride = nil

function CSR_FeatureFlags.isDualWieldEnabled()
    if CSR_FeatureFlags.isAdminAuthoritative() then
        return sandbox().EnableDualWield ~= false
    end
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("DualWield")
        if override ~= nil then return override end
    end
    -- Legacy field fallback (populated by CSR_PlayerPrefs.load() migration)
    if CSR_FeatureFlags._dualWieldLocalOverride ~= nil then
        return CSR_FeatureFlags._dualWieldLocalOverride == true
    end
    return sandbox().EnableDualWield ~= false
end

function CSR_FeatureFlags.toggleDualWieldLocal()
    if CSR_FeatureFlags.isAdminAuthoritative() then return CSR_FeatureFlags.isDualWieldEnabled() end
    local current = CSR_FeatureFlags.isDualWieldEnabled()
    CSR_FeatureFlags._dualWieldLocalOverride = not current
    return not current
end

function CSR_FeatureFlags.isOffhandHudOverlayEnabled()
    if not CSR_FeatureFlags.isDualWieldEnabled() then return false end
    return sandbox().EnableOffhandHudOverlay ~= false
end

function CSR_FeatureFlags.isOffhandPersistEnabled()
    if not CSR_FeatureFlags.isDualWieldEnabled() then return false end
    return sandbox().EnableOffhandPersist ~= false
end

function CSR_FeatureFlags.isAdvancedSoundOptionsEnabled()
    return sandbox().EnableAdvancedSoundOptions ~= false
end

function CSR_FeatureFlags.isSawAllDropToGroundEnabled()
    return sandbox().EnableSawAllDropToGround == true
end

function CSR_FeatureFlags.isTowelDryingEnabled()
    return sandbox().EnableTowelDrying ~= false
end

function CSR_FeatureFlags.isSleepAnywhereEnabled()
    return sandbox().EnableSleepAnywhere ~= false
end

function CSR_FeatureFlags.isDismantleAllWatchesEnabled()
    return sandbox().EnableDismantleAllWatches ~= false
end

function CSR_FeatureFlags.isRainCleanseEnabled()
    return sandbox().EnableRainCleanse ~= false
end

function CSR_FeatureFlags.isRainCleanseExteriorsEnabled()
    return sandbox().EnableRainCleanseExteriors ~= false
end

function CSR_FeatureFlags.isKnoxSyndicateEnabled()
    return sandbox().EnableKnoxSyndicate == true
end

function CSR_FeatureFlags.isKnoxSyndicateBroadcastEnabled()
    return CSR_FeatureFlags.isKnoxSyndicateEnabled()
        and sandbox().EnableKnoxSyndicateBroadcast ~= false
end

function CSR_FeatureFlags.isMassageEnabled()
    return sandbox().EnableMassage ~= false
end

function CSR_FeatureFlags.isHideInFurnitureEnabled()
    return sandbox().EnableHideInFurniture ~= false
end

function CSR_FeatureFlags.isPointBlankEnabled()
    return sandbox().EnablePointBlank ~= false
end

function CSR_FeatureFlags.isVehicleSalvageEnabled()
    return sandbox().EnableVehicleSalvage ~= false
end

-- Track B (v1.8.0): when true, route safehouse / faction / vehicle claims
-- through the CSR_Claims server registry + broadcast pipeline instead of
-- the legacy sendSafehouseClaim() flow. Default true.
function CSR_FeatureFlags.isCSRClaimsOverrideEnabled()
    return sandbox().EnableCSRClaimsOverride ~= false
end

-- v1.8.35 -- claim governance accessors.
function CSR_FeatureFlags.isClaimRaidEnabled()
    return sandbox().ClaimRaidEnabled == true
end

function CSR_FeatureFlags.getClaimRaidStart()
    return tonumber(sandbox().ClaimRaidStart) or 0
end

function CSR_FeatureFlags.getClaimRaidEnd()
    return tonumber(sandbox().ClaimRaidEnd) or 0
end

function CSR_FeatureFlags.isClaimRaidAllowBuild()
    return sandbox().ClaimRaidAllowBuild == true
end

function CSR_FeatureFlags.isClaimRaidAllowLoot()
    return sandbox().ClaimRaidAllowLoot == true
end

function CSR_FeatureFlags.isClaimContainerProtectEnabled()
    return sandbox().ClaimContainerProtect ~= false
end

function CSR_FeatureFlags.isClaimPadlockEnabled()
    return sandbox().ClaimPadlockEnabled ~= false
end

function CSR_FeatureFlags.getClaimPadlockBreakSeconds()
    return tonumber(sandbox().ClaimPadlockBreakSeconds) or 180
end

function CSR_FeatureFlags.isClaimAuditLogEnabled()
    return sandbox().ClaimAuditLog ~= false
end

function CSR_FeatureFlags.isClaimInvitesEnabled()
    return sandbox().EnableClaimInvites ~= false
end

function CSR_FeatureFlags.isClaimExpansionEnabled()
    return sandbox().EnableClaimExpansion ~= false
end

function CSR_FeatureFlags.getClaimExpansionMaxWidth()
    return tonumber(sandbox().ClaimExpansionMaxWidth) or 96
end

function CSR_FeatureFlags.getClaimExpansionMaxHeight()
    return tonumber(sandbox().ClaimExpansionMaxHeight) or 96
end

function CSR_FeatureFlags.getClaimExpansionMaxAddedTiles()
    return tonumber(sandbox().ClaimExpansionMaxAddedTiles) or 1024
end

function CSR_FeatureFlags.getClaimExpansionMoneyPer10Tiles()
    return tonumber(sandbox().ClaimExpansionMoneyPer10Tiles) or 1
end

function CSR_FeatureFlags.getClaimExpansionMaterialsPer10Tiles()
    return tonumber(sandbox().ClaimExpansionMaterialsPer10Tiles) or 2
end

function CSR_FeatureFlags.isClaimExpansionArchitectRequired()
    return sandbox().ClaimExpansionRequireArchitect == true
end

function CSR_FeatureFlags.getClaimInviteCooldownMin()
    return tonumber(sandbox().ClaimInviteCooldownMin) or 1
end

function CSR_FeatureFlags.getClaimDissolveAction()
    -- Sandbox enum: 1 = transfer, 2 = release.
    local v = tonumber(sandbox().ClaimDissolveAction) or 1
    if v == 2 then return "release" end
    return "transfer"
end

function CSR_FeatureFlags.isClaimAdminsInvisible()
    return sandbox().ClaimAdminsInvisible == true
end

function CSR_FeatureFlags.isItemRenameEnabled()
    return sandbox().EnableItemRename ~= false
end

function CSR_FeatureFlags.isVehicleHVACEnabled()
    return sandbox().EnableVehicleHVAC ~= false
end

function CSR_FeatureFlags.isCharacterInfoEnhancementsEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("CharInfoEnhancements")
        if override ~= nil then return override end
    end
    return sandbox().EnableCharacterInfoEnhancements ~= false
end

function CSR_FeatureFlags.isWearableSlotFixEnabled()
    return sandbox().EnableWearableSlotFix ~= false
end

function CSR_FeatureFlags.isClimbWithGeneratorEnabled()
    return sandbox().EnableClimbWithGenerator ~= false
end

function CSR_FeatureFlags.isRoomScannerEnabled()
    return sandbox().EnableRoomScanner ~= false and CSR_FeatureFlags.isClipboardEnabled()
end

function CSR_FeatureFlags.isVehicleRadioEnabled()
    return sandbox().EnableVehicleRadio ~= false
end

function CSR_FeatureFlags.isHideWatermarkEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("HideWatermark")
        if override ~= nil then return override end
    end
    return sandbox().EnableHideWatermark ~= false
end

function CSR_FeatureFlags.isFoodExpiryTooltipEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("FoodExpiryTooltip")
        if override ~= nil then return override end
    end
    return sandbox().EnableFoodExpiryTooltip == true  -- default OFF
end

function CSR_FeatureFlags.isSleepBenefitsEnabled()
    return sandbox().EnableSleepBenefits ~= false
end

function CSR_FeatureFlags.isBagBottomAttachEnabled()
    return sandbox().EnableBagBottomAttach ~= false
end

function CSR_FeatureFlags.isNestedContainersEnabled()
    if sandbox().EnableNestedContainers == false then return false end
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("NestedContainers")
        if override ~= nil then return override end
    end
    return true
end

function CSR_FeatureFlags.isLootBagEnabled()
    if sandbox().EnableLootBag == false then return false end
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("LootBag")
        if override ~= nil then return override end
    end
    return true
end

function CSR_FeatureFlags.isLootBagAutoTrunkEnabled()
    if not CSR_FeatureFlags.isLootBagEnabled() then return false end
    return sandbox().EnableLootBagAutoTrunk ~= false
end

function CSR_FeatureFlags.isToolSetEnabled()
    return sandbox().EnableToolSet ~= false
end

function CSR_FeatureFlags.isMaterialBundlesEnabled()
    return sandbox().EnableMaterialBundles ~= false
end

function CSR_FeatureFlags.isBulletPenetrationEnabled()
    return sandbox().EnableBulletPenetration ~= false
end

function CSR_FeatureFlags.isThrowableItemsEnabled()
    return sandbox().EnableThrowableItems ~= false
end

function CSR_FeatureFlags.isBack2SlotEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("Back2Slot")
        if override ~= nil then return override end
    end
    return sandbox().EnableBack2Slot ~= false
end

function CSR_FeatureFlags.isWarmUpEnabled()
    return sandbox().EnableWarmUp ~= false
end

function CSR_FeatureFlags.isStopDropRollEnabled()
    return sandbox().EnableStopDropRoll ~= false
end

function CSR_FeatureFlags.isConeVisionOutlineEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("ConeVisionOutline")
        if override ~= nil then return override end
    end
    return sandbox().EnableConeVisionOutline ~= false
end

function CSR_FeatureFlags.isExerciseWithGearEnabled()
    return sandbox().EnableExerciseWithGear ~= false
end

function CSR_FeatureFlags.isInfectionResilienceEnabled()
    return sandbox().EnableInfectionResilience ~= false
end

function CSR_FeatureFlags.isAntibodySystemEnabled()
    return CSR_FeatureFlags.isInfectionResilienceEnabled() and sandbox().EnableAntibodySystem ~= false
end

function CSR_FeatureFlags.isUsefulBarrelsEnabled()
    return sandbox().EnableUsefulBarrels ~= false
end

function CSR_FeatureFlags.isClimbWithBagsEnabled()
    return sandbox().EnableClimbWithBags ~= false
end

function CSR_FeatureFlags.isFieldFiltersEnabled()
    return sandbox().EnableFieldFilters ~= false
end

function CSR_FeatureFlags.isTowAssistEnabled()
    return sandbox().EnableTowAssist ~= false
end

function CSR_FeatureFlags.isGeneratorInfoEnabled()
    return sandbox().EnableGeneratorInfo ~= false
end

function CSR_FeatureFlags.isVideoInsertEnabled()
    return sandbox().EnableVideoInsert ~= false
end

function CSR_FeatureFlags.isTVRadialEnabled()
    return sandbox().EnableTVRadial ~= false
end

function CSR_FeatureFlags.isReplaceVanillaSafehouseUIEnabled()
    return sandbox().EnableReplaceVanillaSafehouseUI ~= false
end

function CSR_FeatureFlags.isVehicleClaimEnforcementStrictEnabled()
    return sandbox().EnableVehicleClaimEnforcementStrict ~= false
end

function CSR_FeatureFlags.isRVExitRescueEnabled()
    return sandbox().EnableRVExitRescue ~= false
end

function CSR_FeatureFlags.isAnimatedDufflesEnabled()
    return sandbox().EnableAnimatedDuffles ~= false
end

function CSR_FeatureFlags.isAimingAmmoCursorEnabled()
    if CSR_FeatureFlags.isCleanHotBarActive() then return false end
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("AimingAmmoCursor")
        if override ~= nil then return override end
    end
    return sandbox().EnableAimingAmmoCursor ~= false
end

function CSR_FeatureFlags.isAimingHealthCursorEnabled()
    if CSR_FeatureFlags.isCleanHotBarActive() then return false end
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("AimingHealthCursor")
        if override ~= nil then return override end
    end
    return sandbox().EnableAimingHealthCursor ~= false
end

function CSR_FeatureFlags.isAimingDensityCursorEnabled()
    if CSR_FeatureFlags.isCleanHotBarActive() then return false end
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("AimingDensityCursor")
        if override ~= nil then return override end
    end
    return sandbox().EnableAimingDensityCursor == true
end

function CSR_FeatureFlags.isGearSlingEnabled()
    return sandbox().EnableGearSling ~= false
end

function CSR_FeatureFlags.isRallyPointsEnabled()
    return sandbox().EnableRallyPoints ~= false
end

function CSR_FeatureFlags.isRankingsEnabled()
    return sandbox().EnableRankings ~= false
end

function CSR_FeatureFlags.isRankingsTrackPvP()
    return CSR_FeatureFlags.isRankingsEnabled() and sandbox().RankingsTrackPvP == true
end

function CSR_FeatureFlags.isColoredTogglesEnabled()
    return sandbox().EnableColoredToggles ~= false
end

function CSR_FeatureFlags.isSurvivorBondEnabled()
    return sandbox().EnableSurvivorBond ~= false
end

function CSR_FeatureFlags.isSurvivorLedgerEnabled()
    return sandbox().EnableSurvivorLedger ~= false
end

function CSR_FeatureFlags.isSkillJournalEnabled()
    return sandbox().EnableSkillJournal ~= false
end

function CSR_FeatureFlags.isFactionMemberLimitEnabled()
    return sandbox().EnableFactionMemberLimit ~= false
end

--- Returns the configured faction member cap. Reads from sandbox every call (no cache).
function CSR_FeatureFlags.getMaxFactionMembers()
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    return sb.MaxFactionMembers or 8
end

function CSR_FeatureFlags.isFactionSafehouseEnabled()
    return sandbox().EnableFactionSafehouse ~= false
end

--- Returns the max faction safehouses per faction. Reads from sandbox every call.
function CSR_FeatureFlags.getMaxFactionSafehouses()
    local sb = SandboxVars and SandboxVars.CommonSenseReborn or {}
    return sb.MaxFactionSafehouses or 2
end

-- Reload-radial / seated-reload QoL extensions.
function CSR_FeatureFlags.isFridgeToggleEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("FridgeToggle")
        if override ~= nil then return override end
    end
    return sandbox().EnableFridgeToggle ~= false
end

function CSR_FeatureFlags.isReloadAllMagsEnabled()
    return sandbox().EnableReloadAllMags ~= false
end

function CSR_FeatureFlags.isSpeedReloadEnabled()
    return sandbox().EnableSpeedReload ~= false
end

function CSR_FeatureFlags.isSeatedReloadBonusEnabled()
    return sandbox().EnableSeatedReloadBonus ~= false
end

function CSR_FeatureFlags.isGroundMarkingEnabled()
    if CSR_PlayerPrefs then
        local override = CSR_PlayerPrefs.getOverride("GroundMarking")
        if override ~= nil then return override end
    end
    return sandbox().EnableGroundMarking ~= false
end

function CSR_FeatureFlags.isTrunkSpillageEnabled()
    return sandbox().EnableTrunkSpillage == true
end

function CSR_FeatureFlags.isFireTrailEnabled()
    return sandbox().EnableFireTrail ~= false
end

function CSR_FeatureFlags.isRopeTowEnabled()
    return sandbox().EnableRopeTow ~= false
end

function CSR_FeatureFlags.isCorpseTrunkEnabled()
    return sandbox().EnableCorpseTrunk ~= false
end

function CSR_FeatureFlags.isBathingEnabled()
    return sandbox().EnableBathing ~= false
end

return CSR_FeatureFlags

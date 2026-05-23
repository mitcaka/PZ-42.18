FAM = FAM or {}

FAM.ID = "FadedAdvancedMedical"
FAM.VERSION = "42.18-rebuild-alpha"
FAM.NETWORK_MODULE = "FAM"
FAM.PATIENT_NOTE_MAX_LENGTH = 1200
FAM.PATIENT_RECORD_MAX_ENTRIES = 40
FAM.CLINICAL_RECORD_MAX_ENTRIES = 32
FAM.ANALYTICS_MAX_ROWS = 24
FAM.PROVIDER_STATS_MAX_ROWS = 12
FAM.PATHOLOGY_RECORD_MAX_ENTRIES = 24

FAM.PANDEMIC = {
    RARE_ROLL_PER_10K = 2,
    SPREAD_RADIUS = 7,
    ALERT_PER_ACTIVE_CASE = 16,
    ALERT_PER_TOTAL_CASE = 3,
    QUARANTINE_HOURS = 24,
    TREATMENT_HOURS = 12,
    IMMUNITY_HOURS = 96,
    SUPER_CARRIER_CHANCE = 4,
    CORPSE_VIRUS_EXPOSURE = 62,
    CORPSE_VIRUS_PATHOGEN = 38,
}

FAM.DEFAULT_PANDEMIC_DISEASE = "influenza_like"
FAM.CORPSE_VIRUS_DISEASE = "hollow_veil"

FAM.DISEASES = {
    influenza_like = {
        labelKey = "IGUI_FAM_Disease_InfluenzaLike",
        categoryKey = "IGUI_FAM_DiseaseCategory_Illness",
        contagion = 62,
        severity = 42,
        spreadRadius = 7,
        rareWeight = 34,
        superCarrierChance = 3,
        treatmentKey = "IGUI_FAM_DiseaseTreatment_FluSupport",
        antibioticMultiplier = 0.35,
        fluMultiplier = 1.25,
        sanitationMultiplier = 0.45,
    },
    gastroenteritis = {
        labelKey = "IGUI_FAM_Disease_Gastroenteritis",
        categoryKey = "IGUI_FAM_DiseaseCategory_Illness",
        contagion = 48,
        severity = 38,
        spreadRadius = 5,
        rareWeight = 20,
        superCarrierChance = 2,
        treatmentKey = "IGUI_FAM_DiseaseTreatment_RestFluids",
        antibioticMultiplier = 0.25,
        fluMultiplier = 0.45,
        sanitationMultiplier = 1.1,
    },
    bacterial_wound_fever = {
        labelKey = "IGUI_FAM_Disease_BacterialWoundFever",
        categoryKey = "IGUI_FAM_DiseaseCategory_Disease",
        contagion = 18,
        severity = 68,
        spreadRadius = 3,
        rareWeight = 14,
        superCarrierChance = 1,
        treatmentKey = "IGUI_FAM_DiseaseTreatment_AntibioticsWoundCare",
        antibioticMultiplier = 1.45,
        fluMultiplier = 0.2,
        sanitationMultiplier = 1.25,
        openWoundBonus = 24,
    },
    pneumonia_like = {
        labelKey = "IGUI_FAM_Disease_PneumoniaLike",
        categoryKey = "IGUI_FAM_DiseaseCategory_Disease",
        contagion = 36,
        severity = 72,
        spreadRadius = 5,
        rareWeight = 12,
        superCarrierChance = 2,
        treatmentKey = "IGUI_FAM_DiseaseTreatment_AntibioticsRest",
        antibioticMultiplier = 1.0,
        fluMultiplier = 0.65,
        sanitationMultiplier = 0.35,
    },
    hollow_veil = {
        labelKey = "IGUI_FAM_Disease_HollowVeil",
        categoryKey = "IGUI_FAM_DiseaseCategory_CorpseVirus",
        contagion = 88,
        severity = 76,
        spreadRadius = 9,
        rareWeight = 5,
        superCarrierChance = 6,
        silent = true,
        corpseBorne = true,
        treatmentKey = "IGUI_FAM_DiseaseTreatment_HollowVeil",
        antibioticMultiplier = 1.35,
        fluMultiplier = 0.75,
        sanitationMultiplier = 1.4,
    },
}

FAM.TREATMENTS = {
    burn = {
        item = "FAM.BurnTreatment",
        recipe = "FAM_MakeBurnGel",
        level = 2,
        job = "IGUI_FAM_JobType_ApplyBurnGel",
    },
    hemostatic = {
        item = "FAM.PowderPackHemostatic",
        recipe = "FAM_MakeHemostaticPack",
        level = 4,
        job = "IGUI_FAM_JobType_ApplyHemostatic",
    },
    tourniquet = {
        item = "FAM.Tourniquet",
        recipe = "FAM_MakeTourniquet",
        level = 3,
        job = "IGUI_FAM_JobType_ApplyTourniquet",
    },
    sanitation = {
        item = "FAM.AntisepticWashKit",
        recipe = "FAM_SanitationProtocol",
        level = 3,
        job = "IGUI_FAM_JobType_SanitizeExposure",
    },
    stumpcare = {
        item = "FAM.StumpCareKit",
        recipe = "FAM_StumpCareProtocol",
        level = 6,
        job = "IGUI_FAM_JobType_StumpCare",
    },
    amputation = {
        recipe = "FAM_FieldAmputationProtocol",
        level = 10,
        strictBook = true,
        job = "IGUI_FAM_JobType_FieldAmputation",
    },
    prosthetic = {
        recipe = "FAM_ProstheticFittingProtocol",
        level = 5,
        job = "IGUI_FAM_JobType_FitProsthetic",
    },
    ivfluids = {
        item = "FAM.SalineBag",
        recipe = "FAM_IVFluidProtocol",
        level = 5,
        job = "IGUI_FAM_JobType_IVFluids",
    },
    bloodpack = {
        item = "FAM.FieldBloodPack",
        recipe = "FAM_BloodSupportProtocol",
        level = 8,
        job = "IGUI_FAM_JobType_BloodSupport",
    },
    epinephrine = {
        item = "FAM.EpinephrineInjector",
        recipe = "FAM_EpinephrineProtocol",
        level = 6,
        job = "IGUI_FAM_JobType_Epinephrine",
    },
}

local BODY_SYNC_BANDAGE = 0xc001966b8e
local BODY_SYNC_BURN = 0x380400000
local BODY_SYNC_ALL = 0xFFFFFFFFFFF

FAM.SAW_TYPES = {
    "Base.Saw",
    "Base.GardenSaw",
    "Base.Plank_Saw",
    "Base.SmallSaw",
    "Base.Machete",
    "Base.MacheteForged",
    "Base.Hatchet",
    "Base.HandAxe_Old",
    "Base.HandAxe",
}

FAM.AMPUTATION_ADJACENT = {
    Hand_L = "ForeArm_L",
    Hand_R = "ForeArm_R",
    ForeArm_L = "UpperArm_L",
    ForeArm_R = "UpperArm_R",
    UpperArm_L = "Torso_Upper",
    UpperArm_R = "Torso_Upper",
}

FAM.AMPUTATION_DEPENDENCIES = {
    Hand_L = {},
    Hand_R = {},
    ForeArm_L = { "Hand_L" },
    ForeArm_R = { "Hand_R" },
    UpperArm_L = { "ForeArm_L", "Hand_L" },
    UpperArm_R = { "ForeArm_R", "Hand_R" },
}

FAM.AMPUTATION_BASE_DAMAGE = {
    Hand_L = 52,
    Hand_R = 52,
    ForeArm_L = 72,
    ForeArm_R = 72,
    UpperArm_L = 92,
    UpperArm_R = 92,
}

FAM.CONDITION = {
    BULLET_LODGED_HOURS = 12,
    BULLET_DEEP_HOURS = 36,
    BULLET_CRITICAL_HOURS = 60,
    GANGRENE_SUSPECT = 30,
    GANGRENE_CONFIRMED = 60,
    GANGRENE_CRITICAL = 85,
    CORPSE_SCAN_RADIUS = 7,
    CORPSE_EXPOSURE_SUSPECT = 25,
    PATHOGEN_ELEVATED = 20,
    PATHOGEN_CRITICAL = 70,
    LOCAL_INFECTION_SUSPECT = 18,
    LOCAL_INFECTION_CONFIRMED = 40,
    LOCAL_INFECTION_CRITICAL = 75,
    SEPSIS_SUSPECT = 25,
    SEPSIS_CRITICAL = 70,
}

FAM.BLOOD = {
    MAX_VOLUME = 5000,
    BLEED_BASE_PER_HOUR = 18,
    BLEED_TIME_FACTOR = 1.15,
    NATURAL_RECOVERY_PER_HOUR = 60,
    BLOOD_SUPPORT_RECOVERY_PER_HOUR = 35,
    SALINE_VOLUME = 450,
    BLOOD_PACK_VOLUME = 450,
    BLOOD_PACK_HEALTH = 18,
    LOW_PERCENT = 75,
    CRITICAL_PERCENT = 50,
    COLLAPSE_PERCENT = 35,
}

FAM.SUBSTANCE_SCAN = {
    PREFIXES = { "FAM_", "CSR_", "NnC_", "NC_" },
    ACTIVE_SUFFIXES = { "Hours", "Cooldown", "Timer", "Duration", "Effect", "Power", "Dose", "Active" },
    DISPLAY_KEYS = {
        FAM_SneezeSuppressionHours = "IGUI_FAM_Substance_SneezeSuppression",
        FAM_MorphineCooldown = "IGUI_FAM_Substance_MorphineCooldown",
        FAM_BurnTreatmentCooldown = "IGUI_FAM_Substance_BurnCooldown",
        FAM_AdrenalineCrashHours = "IGUI_FAM_Substance_AdrenalineCrash",
        FAM_EpinephrineCooldown = "IGUI_FAM_Substance_EpinephrineCooldown",
        FAM_EpinephrineCrashHours = "IGUI_FAM_Substance_EpinephrineCrash",
        FAM_CSR_AntibodySupportHours = "IGUI_FAM_Substance_CSRSupport",
        FAM_SanitationHours = "IGUI_FAM_Substance_Sanitation",
        FAM_SalineSupportHours = "IGUI_FAM_Substance_SalineSupport",
        FAM_BloodSupportHours = "IGUI_FAM_Substance_BloodSupport",
        FAM_HollowVeilBlurHours = "IGUI_FAM_Substance_HollowVeilBlur",
        FAM_HollowVeilDeafHours = "IGUI_FAM_Substance_HollowVeilDeaf",
        CSR_IR_Doomed = "IGUI_FAM_Substance_CSRCrisis",
        CSR_IR_Threshold = "IGUI_FAM_Substance_CSRThreshold",
    },
    DISPLAY_NAMES = {
        FAM_SneezeSuppressionHours = "Sneeze suppression",
        FAM_MorphineCooldown = "Morphine cooldown",
        FAM_BurnTreatmentCooldown = "Burn treatment cooldown",
        FAM_AdrenalineCrashHours = "Adrenaline crash",
        FAM_EpinephrineCooldown = "Epinephrine cooldown",
        FAM_EpinephrineCrashHours = "Epinephrine crash",
        FAM_CSR_AntibodySupportHours = "CSR antibody support",
        FAM_SanitationHours = "Sanitation support",
        FAM_SalineSupportHours = "IV saline support",
        FAM_BloodSupportHours = "Blood support",
        FAM_HollowVeilBlurHours = "Hollow Veil visual blur",
        FAM_HollowVeilDeafHours = "Hollow Veil auditory dropout",
        CSR_IR_Doomed = "CSR infection crisis",
        CSR_IR_Threshold = "CSR infection threshold",
    },
    CATEGORIES = {
        FAM_CSR_AntibodySupportHours = "csr",
        CSR_IR_Doomed = "csr",
        CSR_IR_Threshold = "csr",
        FAM_SalineSupportHours = "vascular",
        FAM_BloodSupportHours = "vascular",
        FAM_EpinephrineCooldown = "vascular",
        FAM_EpinephrineCrashHours = "vascular",
        FAM_HollowVeilBlurHours = "pandemic",
        FAM_HollowVeilDeafHours = "pandemic",
    },
    IGNORE_KEYS = {
        FAM_SepsisLoad = true,
        FAM_ShockLoad = true,
        FAM_PathogenLoad = true,
        FAM_CorpseExposureLoad = true,
        FAM_NearbyCorpseCount = true,
        FAM_PandemicLoad = true,
        FAM_PatientNotes = true,
        FAM_PatientAnalytics = true,
        FAM_ProviderStats = true,
        FAM_FluidSupportVolume = true,
        FAM_BloodVolume = true,
        FAM_BloodMaxVolume = true,
        FAM_CSR_AntibodySupportPower = true,
    },
}

FAM.KNOWLEDGE_GROUPS = {
    {
        key = "trauma",
        labelKey = "IGUI_FAM_Knowledge_Trauma",
        treatments = { "burn", "hemostatic", "tourniquet" },
    },
    {
        key = "infection",
        labelKey = "IGUI_FAM_Knowledge_Infection",
        treatments = { "sanitation", "stumpcare" },
    },
    {
        key = "vascular",
        labelKey = "IGUI_FAM_Knowledge_Vascular",
        treatments = { "ivfluids", "bloodpack", "epinephrine" },
    },
    {
        key = "recovery",
        labelKey = "IGUI_FAM_Knowledge_Recovery",
        treatments = { "amputation", "prosthetic" },
    },
}

FAM.MEDICAL_ROLE_BONUS = {
    doctor = { diagnosis = 18, routine = 8, trauma = 10, infection = 12, vascular = 14, training = 8 },
    nurse = { diagnosis = 10, routine = 16, trauma = 8, infection = 12, vascular = 8, training = 6 },
    paramedic = { diagnosis = 8, routine = 10, trauma = 16, infection = 4, vascular = 12, training = 6 },
    pharmacist = { diagnosis = 8, routine = 4, trauma = 2, infection = 10, vascular = 6, substance = 18, training = 6 },
    clinician = { diagnosis = 8, routine = 8, trauma = 8, infection = 8, vascular = 8, training = 4 },
    firstaid = { diagnosis = 4, routine = 5, trauma = 4, infection = 3, vascular = 2, training = 2 },
}

FAM.PROSTHETIC_ITEMS = {
    "FAM.BasicArmProsthesis",
    "FAM.HookArmProsthesis",
}

FAM.PROSTHETIC_ITEM_BY_TYPE = {
    basic = "FAM.BasicArmProsthesis",
    hook = "FAM.HookArmProsthesis",
}

function FAM.isItemFullType(item, fullType)
    return fullType ~= nil and FAM.getItemFullType(item) == fullType
end

function FAM.isItemAnyFullType(item, fullTypes)
    if not item or not fullTypes then return false end
    local fullType = FAM.getItemFullType(item)
    if not fullType then return false end
    for i = 1, #fullTypes do
        if fullType == fullTypes[i] then
            return true
        end
    end
    return false
end

FAM.PATHOLOGY = {
    JOURNAL_TYPES = {
        "FAM.FieldMedicalJournal",
        "CorpseStudyMod.MedicalJournal",
    },
    SAMPLE_ITEM = "FAM.PathologySample",
    STUDY_WINDOW_HOURS = 36,
    TOOL_TYPES = {
        "Base.Scalpel",
        "Base.HuntingKnife",
        "Base.HuntingKnifeForged",
        "Base.MeatCleaver",
        "Base.MeatCleaverForged",
        "Base.KitchenKnife",
        "Base.KitchenKnifeForged",
        "Base.Scissors",
    },
    TOOL_PROFILES = {
        ["Base.Scalpel"] = { tier = 3, label = "Scalpel", wear = 1, risk = 0.55, time = 0.55 },
        ["Base.HuntingKnife"] = { tier = 2, label = "Hunting knife", wear = 2, risk = 0.85, time = 0.78 },
        ["Base.HuntingKnifeForged"] = { tier = 2, label = "Hunting knife", wear = 2, risk = 0.82, time = 0.76 },
        ["Base.MeatCleaver"] = { tier = 2, label = "Cleaver", wear = 2, risk = 0.95, time = 0.72 },
        ["Base.MeatCleaverForged"] = { tier = 2, label = "Cleaver", wear = 2, risk = 0.92, time = 0.7 },
        ["Base.KitchenKnife"] = { tier = 1, label = "Kitchen knife", wear = 3, risk = 1.15, time = 1.0 },
        ["Base.KitchenKnifeForged"] = { tier = 1, label = "Kitchen knife", wear = 3, risk = 1.1, time = 0.95 },
        ["Base.Scissors"] = { tier = 1, label = "Scissors", wear = 2, risk = 1.25, time = 1.12 },
    },
    MODES = {
        study = {
            minLevel = 0,
            baseXp = 10,
            baseRisk = 12,
            minQuality = 25,
            labelKey = "IGUI_FAM_PathologyModeStudy",
            recordKey = "Study",
        },
        sample = {
            minLevel = 3,
            baseXp = 18,
            baseRisk = 22,
            requiresJournal = true,
            requiresTool = true,
            createsSample = true,
            signalChance = 22,
            minQuality = 45,
            labelKey = "IGUI_FAM_PathologyModeSample",
            recordKey = "Sample",
        },
        autopsy = {
            minLevel = 6,
            baseXp = 30,
            baseRisk = 34,
            requiresJournal = true,
            requiresTool = true,
            createsSample = true,
            signalChance = 38,
            advanced = true,
            minQuality = 65,
            labelKey = "IGUI_FAM_PathologyModeAutopsy",
            recordKey = "Autopsy",
        },
    },
}

FAM.MEDICAL_PROFESSIONS = {
    doctor = true,
    nurse = true,
    paramedic = true,
    surgeon = true,
    pharmacist = true,
}

function FAM.clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function FAM.getDoctorLevel(character)
    if not character then return 0 end
    if not character.getPerkLevel or not Perks or not Perks.Doctor then return 0 end
    return tonumber(character:getPerkLevel(Perks.Doctor)) or 0
end

function FAM.isMedicalCheat(character)
    if not character then return false end
    if character.isTimedActionInstant and character:isTimedActionInstant() then return true end
    local accessLevel = character.getAccessLevel and character:getAccessLevel() or nil
    accessLevel = accessLevel and string.lower(tostring(accessLevel)) or nil
    if accessLevel == "admin" or accessLevel == "moderator" or accessLevel == "overseer" or accessLevel == "gm" or accessLevel == "observer" then return true end
    local role = character.getRole and character:getRole() or nil
    return isMultiplayer and isMultiplayer() and role and Capability and Capability.CanMedicalCheat and role.hasCapability and role:hasCapability(Capability.CanMedicalCheat) == true
end

function FAM.getEffectiveDoctorLevel(character)
    if FAM.isMedicalCheat(character) then
        return 10
    end
    return FAM.getDoctorLevel(character)
end

function FAM.getProfessionId(character)
    if not character or not character.getDescriptor then return nil end
    local descriptor = character:getDescriptor()
    if not descriptor or not descriptor.getProfession then return nil end
    return descriptor:getProfession()
end

function FAM.hasAdvancedClinicalAccess(character)
    if not character then return false end
    if FAM.isMedicalCheat(character) then return true end
    if FAM.getDoctorLevel(character) >= 10 then return true end
    local profession = FAM.getProfessionId(character)
    return profession ~= nil and FAM.MEDICAL_PROFESSIONS[string.lower(tostring(profession))] == true
end

function FAM.hasPatientRecordAccess(character)
    if not character then return false end
    if FAM.isMedicalCheat(character) then return true end
    if FAM.getDoctorLevel(character) >= 10 then return true end
    local profession = FAM.getProfessionId(character)
    if not profession then return false end
    profession = string.lower(tostring(profession))
    return profession == "doctor" or profession == "nurse"
end

function FAM.getMedicalRole(character)
    if not character then return "none" end
    if FAM.isMedicalCheat(character) then return "doctor" end
    local profession = FAM.getProfessionId(character)
    profession = profession and string.lower(tostring(profession)) or ""
    if profession == "doctor" or profession == "surgeon" then return "doctor" end
    if profession == "nurse" then return "nurse" end
    if profession == "paramedic" or profession == "emt" or profession == "fireofficer" then return "paramedic" end
    if profession == "pharmacist" then return "pharmacist" end
    local level = FAM.getDoctorLevel(character)
    if level >= 8 then return "clinician" end
    if level >= 3 then return "firstaid" end
    return "none"
end

function FAM.getMedicalRoleBonus(character, domain)
    local role = FAM.getMedicalRole(character)
    local bonuses = FAM.MEDICAL_ROLE_BONUS[role]
    local bonus = bonuses and (tonumber(bonuses[domain]) or 0) or 0
    if FAM.hasTrait(character, "FIRSTAID") or FAM.hasTrait(character, "FORMERSCOUT") then
        bonus = bonus + (domain == "training" and 3 or 2)
    end
    return bonus
end

function FAM.getClinicalCertainty(character, domain)
    local level = FAM.getEffectiveDoctorLevel(character)
    return FAM.clamp(28 + (level * 6) + FAM.getMedicalRoleBonus(character, domain or "diagnosis"), 18, 100)
end

function FAM.hasTrait(character, trait)
    if not character then return false end
    if character.hasTrait and CharacterTrait and CharacterTrait[trait] then
        return character:hasTrait(CharacterTrait[trait])
    end
    if character.HasTrait then
        return character:HasTrait(trait)
    end
    return false
end

function FAM.getStat(character, stat, fallback)
    if not character or not CharacterStat or not CharacterStat[stat] then
        return fallback or 0
    end
    local stats = character:getStats()
    if not stats then return fallback or 0 end
    return stats:get(CharacterStat[stat]) or fallback or 0
end

function FAM.setStat(character, stat, value)
    if not character or not CharacterStat or not CharacterStat[stat] then return end
    local stats = character:getStats()
    if stats then
        stats:set(CharacterStat[stat], value)
    end
end

function FAM.addStat(character, stat, amount)
    if not character or not CharacterStat or not CharacterStat[stat] then return end
    local stats = character:getStats()
    if stats then
        stats:add(CharacterStat[stat], amount)
    end
end

function FAM.removeStat(character, stat, amount)
    if not character or not CharacterStat or not CharacterStat[stat] then return end
    local stats = character:getStats()
    if stats then
        stats:remove(CharacterStat[stat], amount)
    end
end

function FAM.getStatPercent(character, stat, fallback)
    local value = FAM.getStat(character, stat, fallback or 0)
    local max = 100
    if CharacterStat and CharacterStat[stat] and CharacterStat[stat].getMaximumValue then
        max = CharacterStat[stat]:getMaximumValue()
    end
    if max <= 1.5 then
        return FAM.clamp(value * 100, 0, 100)
    end
    return FAM.clamp(value, 0, 100)
end

function FAM.reducePercentStat(character, stat, amount)
    if not character or not CharacterStat or not CharacterStat[stat] then return end
    local max = CharacterStat[stat].getMaximumValue and CharacterStat[stat]:getMaximumValue() or 100
    local reduction = max <= 1.5 and ((amount or 0) / 100) or (amount or 0)
    local current = FAM.getStat(character, stat, 0)
    FAM.setStat(character, stat, math.max(0, current - reduction))
    FAM.syncCharacterStat(character, stat)
end

function FAM.syncCharacterStat(character, stat)
    if not character or not CharacterStat or not CharacterStat[stat] then return end
    if isClient and isClient() and sendPlayerStat and getPlayer and character == getPlayer() then
        sendPlayerStat(character, CharacterStat[stat])
    end
end

function FAM.getBodyDamage(character)
    if not character or not character.getBodyDamage then return nil end
    if isClient and isClient()
        and character.isLocalPlayer
        and not character:isLocalPlayer()
        and character.getBodyDamageRemote then
        return character:getBodyDamageRemote()
    end
    return character:getBodyDamage()
end

function FAM.getBodyDamageValue(character, getter, fallback)
    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage[getter] then
        return bodyDamage[getter](bodyDamage)
    end
    return fallback or 0
end

function FAM.setBodyDamageValue(character, setter, value)
    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage[setter] then
        bodyDamage[setter](bodyDamage, value)
        return true
    end
    return false
end

function FAM.getPoisonLevel(character)
    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage.getPoisonLevel then
        return bodyDamage:getPoisonLevel()
    end
    return FAM.getStatPercent(character, "POISON", 0)
end

function FAM.setPoisonLevel(character, value)
    value = FAM.clamp(value, 0, 100)
    if not FAM.setBodyDamageValue(character, "setPoisonLevel", value) then
        FAM.setStat(character, "POISON", value)
        FAM.syncCharacterStat(character, "POISON")
    end
end

function FAM.addPoisonLevel(character, amount)
    FAM.setPoisonLevel(character, FAM.getPoisonLevel(character) + (amount or 0))
end

function FAM.getSicknessLevel(character)
    local bodyDamage = FAM.getBodyDamage(character)
    local bodySickness = 0
    local foodSickness = 0
    if bodyDamage and bodyDamage.getSicknessLevel then
        bodySickness = tonumber(bodyDamage:getSicknessLevel()) or 0
    end
    if bodyDamage and bodyDamage.getFoodSicknessLevel then
        foodSickness = tonumber(bodyDamage:getFoodSicknessLevel()) or 0
    end
    return math.max(bodySickness, foodSickness, FAM.getStatPercent(character, "SICKNESS", 0), FAM.getStatPercent(character, "FOOD_SICKNESS", 0))
end

function FAM.getCoreTemperature(character)
    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage.getThermoregulator then
        local thermoregulator = bodyDamage:getThermoregulator()
        if thermoregulator and thermoregulator.getCoreTemperature then
            return thermoregulator:getCoreTemperature()
        end
    end
    if character and character.getTemperature then
        return character:getTemperature()
    end
    return nil
end

function FAM.getTemperatureDeviationPercent(character)
    local temperature = FAM.getCoreTemperature(character)
    if not temperature then return 0 end
    return FAM.clamp(math.abs(temperature - 37.0) * 35, 0, 100)
end

function FAM.getMoodleLevel(character, names)
    if not character or not character.getMoodles or not MoodleType then return 0 end
    local moodles = character:getMoodles()
    if not moodles or not moodles.getMoodleLevel then return 0 end
    local maxLevel = 0
    for i = 1, #names do
        local moodleType = MoodleType[names[i]]
        if moodleType ~= nil then
            local ok, level = pcall(function()
                return moodles:getMoodleLevel(moodleType)
            end)
            if ok then
                maxLevel = math.max(maxLevel, tonumber(level) or 0)
            end
        end
    end
    return maxLevel
end

function FAM.getColdExposurePercent(character)
    local moodleLevel = FAM.getMoodleLevel(character, {
        "HYPOTHERMIA",
        "Hypothermia",
        "hypothermia",
        "WINDCHILL",
        "Windchill",
        "windchill",
    })
    local moodleRisk = FAM.clamp(moodleLevel * 25, 0, 100)
    local temperature = FAM.getCoreTemperature(character)
    local temperatureRisk = 0
    if temperature and temperature < 37.0 then
        temperatureRisk = FAM.clamp((37.0 - temperature) * 60, 0, 100)
    end
    return math.max(moodleRisk, temperatureRisk)
end

function FAM.getColdStressPercent(character)
    local coldIllness = math.max(
        FAM.getBodyDamageValue(character, "getColdStrength", 0),
        FAM.getBodyDamageValue(character, "getCatchACold", 0),
        FAM.getMoodleLevel(character, {
            "HASACOLD",
            "HAS_A_COLD",
            "HasACold",
            "hasACold",
        }) * 25
    )
    return FAM.clamp(math.max(coldIllness, FAM.getColdExposurePercent(character)), 0, 100)
end

function FAM.formatTemperature(temperature)
    if not temperature then
        return "?"
    end
    if Temperature and Temperature.getTemperatureString then
        return Temperature.getTemperatureString(temperature)
    end
    return tostring(math.floor((temperature * 10) + 0.5) / 10) .. " C"
end

function FAM.sanitizePatientNote(note)
    local text = tostring(note or "")
    text = string.gsub(text, "\r\n", "\n")
    text = string.gsub(text, "\r", "\n")
    if string.len(text) > FAM.PATIENT_NOTE_MAX_LENGTH then
        text = string.sub(text, 1, FAM.PATIENT_NOTE_MAX_LENGTH)
    end
    return text
end

function FAM.trimNote(note)
    return string.gsub(string.gsub(FAM.sanitizePatientNote(note), "^%s+", ""), "%s+$", "")
end

function FAM.getClinicianName(character)
    if not character then return "Unknown" end
    if character.getUsername then
        local username = character:getUsername()
        if username and username ~= "" then return username end
    end
    if character.getDisplayName then
        return character:getDisplayName()
    end
    return "Unknown"
end

function FAM.getNoteTimestamp()
    local hours = 0
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        hours = tonumber(gameTime:getWorldAgeHours()) or 0
    end
    local day = math.floor(hours / 24) + 1
    local hour = math.floor(hours % 24)
    return "Day " .. tostring(day) .. " " .. string.format("%02d:00", hour)
end

function FAM.getWorldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        return tonumber(gameTime:getWorldAgeHours()) or 0
    end
    return 0
end

function FAM.getPatientOnlineID(patient)
    if patient and patient.getOnlineID then
        local id = tonumber(patient:getOnlineID())
        if id ~= nil and id >= 0 then
            return id
        end
    end
    return nil
end

function FAM.getCharacterKey(character)
    if not character then return "unknown" end
    if character.getOnlineID then
        local onlineID = character:getOnlineID()
        if onlineID ~= nil and tonumber(onlineID) ~= nil and tonumber(onlineID) >= 0 then
            return "online:" .. tostring(onlineID)
        end
    end
    if character.getUsername then
        local username = character:getUsername()
        if username and username ~= "" then
            return "user:" .. tostring(username)
        end
    end
    if character.getDisplayName then
        local displayName = character:getDisplayName()
        if displayName and displayName ~= "" then
            return "name:" .. tostring(displayName)
        end
    end
    return tostring(character)
end

function FAM.getPatientNote(patient)
    if not patient then return "" end
    return FAM.sanitizePatientNote(patient:getModData().FAM_PatientNote)
end

function FAM.getPatientNoteMeta(patient)
    if not patient then
        return nil, nil
    end
    local data = patient:getModData()
    return data.FAM_PatientNoteBy, data.FAM_PatientNoteAt
end

local function cleanPatientRecordEntry(entry)
    if type(entry) ~= "table" then return nil end
    local note = FAM.sanitizePatientNote(entry.note)
    if FAM.trimNote(note) == "" then return nil end
    return {
        note = note,
        author = tostring(entry.author or "Unknown"),
        timestamp = tostring(entry.timestamp or "?"),
        sequence = tonumber(entry.sequence) or 0,
    }
end

function FAM.getPatientNoteRecords(patient)
    if not patient then return {} end
    local data = patient:getModData()
    if type(data.FAM_PatientNoteRecords) ~= "table" then
        data.FAM_PatientNoteRecords = {}
    end
    if #data.FAM_PatientNoteRecords == 0 and not data.FAM_PatientNoteRecordsSeeded and FAM.trimNote(data.FAM_PatientNote) ~= "" then
        data.FAM_PatientNoteRecordsSeeded = true
        data.FAM_PatientNoteSequence = (tonumber(data.FAM_PatientNoteSequence) or 0) + 1
        table.insert(data.FAM_PatientNoteRecords, {
            note = FAM.sanitizePatientNote(data.FAM_PatientNote),
            author = tostring(data.FAM_PatientNoteBy or "Unknown"),
            timestamp = tostring(data.FAM_PatientNoteAt or FAM.getNoteTimestamp()),
            sequence = data.FAM_PatientNoteSequence,
        })
    end
    return data.FAM_PatientNoteRecords
end

function FAM.copyPatientNoteRecords(patient)
    local source = FAM.getPatientNoteRecords(patient)
    local records = {}
    for i = 1, #source do
        local clean = cleanPatientRecordEntry(source[i])
        if clean then
            table.insert(records, clean)
        end
    end
    while #records > FAM.PATIENT_RECORD_MAX_ENTRIES do
        table.remove(records, 1)
    end
    return records
end

function FAM.setPatientNoteRecords(patient, records, skipTransmit)
    if not patient then return false end
    local cleanRecords = {}
    local maxSequence = 0
    if type(records) == "table" then
        for i = 1, #records do
            local clean = cleanPatientRecordEntry(records[i])
            if clean then
                maxSequence = math.max(maxSequence, tonumber(clean.sequence) or 0)
                table.insert(cleanRecords, clean)
            end
        end
    end
    while #cleanRecords > FAM.PATIENT_RECORD_MAX_ENTRIES do
        table.remove(cleanRecords, 1)
    end
    local data = patient:getModData()
    data.FAM_PatientNoteRecords = cleanRecords
    data.FAM_PatientNoteRecordsSeeded = true
    data.FAM_PatientNoteSequence = maxSequence
    if not skipTransmit and patient.transmitModData then
        patient:transmitModData()
    end
    return true
end

function FAM.appendPatientNoteRecord(patient, note, author, timestamp)
    if not patient then return false end
    local clean = FAM.sanitizePatientNote(note)
    if FAM.trimNote(clean) == "" then return false end
    local data = patient:getModData()
    local records = FAM.getPatientNoteRecords(patient)
    local cleanAuthor = tostring(author or "Unknown")
    local cleanTimestamp = tostring(timestamp or FAM.getNoteTimestamp())
    local last = records[#records]
    if last
        and last.note == clean
        and tostring(last.author or "") == cleanAuthor
        and tostring(last.timestamp or "") == cleanTimestamp then
        return false
    end

    data.FAM_PatientNoteSequence = (tonumber(data.FAM_PatientNoteSequence) or 0) + 1
    table.insert(records, {
        note = clean,
        author = cleanAuthor,
        timestamp = cleanTimestamp,
        sequence = data.FAM_PatientNoteSequence,
    })
    while #records > FAM.PATIENT_RECORD_MAX_ENTRIES do
        table.remove(records, 1)
    end
    return true
end

local function cleanClinicalRecord(entry)
    if type(entry) ~= "table" then return nil end
    return {
        key = tostring(entry.key or "clinical"),
        labelKey = tostring(entry.labelKey or "IGUI_FAM_ClinicalEvent_Assessment"),
        valueText = tostring(entry.valueText or ""),
        detailKey = entry.detailKey and tostring(entry.detailKey) or nil,
        severity = FAM.clamp(tonumber(entry.severity) or 0, 0, 100),
        provider = tostring(entry.provider or "Unknown"),
        timestamp = tostring(entry.timestamp or FAM.getNoteTimestamp()),
        sequence = tonumber(entry.sequence) or 0,
        csr = entry.csr == true,
    }
end

function FAM.getClinicalRecords(patient)
    if not patient then return {} end
    local data = patient:getModData()
    if type(data.FAM_ClinicalRecords) ~= "table" then
        data.FAM_ClinicalRecords = {}
    end
    return data.FAM_ClinicalRecords
end

function FAM.copyClinicalRecords(patient)
    local source = FAM.getClinicalRecords(patient)
    local records = {}
    for i = 1, #source do
        local clean = cleanClinicalRecord(source[i])
        if clean then table.insert(records, clean) end
    end
    while #records > FAM.CLINICAL_RECORD_MAX_ENTRIES do
        table.remove(records, 1)
    end
    return records
end

function FAM.setClinicalRecords(patient, records, skipTransmit)
    if not patient then return false end
    local cleanRecords = {}
    local maxSequence = 0
    if type(records) == "table" then
        for i = 1, #records do
            local clean = cleanClinicalRecord(records[i])
            if clean then
                maxSequence = math.max(maxSequence, tonumber(clean.sequence) or 0)
                table.insert(cleanRecords, clean)
            end
        end
    end
    while #cleanRecords > FAM.CLINICAL_RECORD_MAX_ENTRIES do
        table.remove(cleanRecords, 1)
    end
    local data = patient:getModData()
    data.FAM_ClinicalRecords = cleanRecords
    data.FAM_ClinicalRecordSequence = maxSequence
    if not skipTransmit and patient.transmitModData then
        patient:transmitModData()
    end
    return true
end

function FAM.appendClinicalRecord(patient, entry, skipTransmit)
    if not patient or type(entry) ~= "table" then return false end
    local data = patient:getModData()
    data.FAM_ClinicalRecordSequence = (tonumber(data.FAM_ClinicalRecordSequence) or 0) + 1
    entry.sequence = data.FAM_ClinicalRecordSequence
    entry.timestamp = entry.timestamp or FAM.getNoteTimestamp()
    local clean = cleanClinicalRecord(entry)
    if not clean then return false end
    local records = FAM.getClinicalRecords(patient)
    local last = records[#records]
    if last
        and tostring(last.key or "") == clean.key
        and tostring(last.valueText or "") == clean.valueText
        and tostring(last.provider or "") == clean.provider
        and tostring(last.timestamp or "") == clean.timestamp then
        return false
    end
    table.insert(records, clean)
    while #records > FAM.CLINICAL_RECORD_MAX_ENTRIES do
        table.remove(records, 1)
    end
    if not skipTransmit and patient.transmitModData then
        patient:transmitModData()
    end
    return true
end

local function normalizeAnalytics(analytics)
    local clean = {
        counts = {},
        labels = {},
        lastSeen = {},
        lastSignals = {},
        observations = 0,
        updatedAt = nil,
    }
    if type(analytics) ~= "table" then
        return clean
    end
    clean.observations = tonumber(analytics.observations) or 0
    clean.updatedAt = analytics.updatedAt
    if type(analytics.counts) == "table" then
        for key, value in pairs(analytics.counts) do
            clean.counts[tostring(key)] = tonumber(value) or 0
        end
    end
    if type(analytics.labels) == "table" then
        for key, value in pairs(analytics.labels) do
            clean.labels[tostring(key)] = tostring(value or "")
        end
    end
    if type(analytics.lastSeen) == "table" then
        for key, value in pairs(analytics.lastSeen) do
            clean.lastSeen[tostring(key)] = tostring(value or "")
        end
    end
    if type(analytics.lastSignals) == "table" then
        for key, value in pairs(analytics.lastSignals) do
            if value == true then
                clean.lastSignals[tostring(key)] = true
            end
        end
    end
    return clean
end

function FAM.getPatientAnalytics(patient)
    if not patient then return normalizeAnalytics(nil) end
    local data = patient:getModData()
    data.FAM_HealthAnalytics = normalizeAnalytics(data.FAM_HealthAnalytics)
    return data.FAM_HealthAnalytics
end

function FAM.copyPatientAnalytics(patient)
    return normalizeAnalytics(patient and patient:getModData().FAM_HealthAnalytics or nil)
end

function FAM.setPatientAnalytics(patient, analytics, skipTransmit)
    if not patient then return false end
    patient:getModData().FAM_HealthAnalytics = normalizeAnalytics(analytics)
    if not skipTransmit and patient.transmitModData then
        patient:transmitModData()
    end
    return true
end

function FAM.getPatientAnalyticsRows(patient)
    local analytics = FAM.copyPatientAnalytics(patient)
    local rows = {}
    for key, count in pairs(analytics.counts) do
        if count > 0 then
            table.insert(rows, {
                key = key,
                count = count,
                label = analytics.labels[key] or key,
                lastSeen = analytics.lastSeen[key] or "?",
            })
        end
    end
    table.sort(rows, function(a, b)
        if a.count == b.count then
            return a.label < b.label
        end
        return a.count > b.count
    end)
    while #rows > FAM.ANALYTICS_MAX_ROWS do
        table.remove(rows)
    end
    return rows
end

local function normalizeProviderStats(stats)
    local clean = {
        provider = "Unknown",
        treatments = 0,
        injuriesFixed = 0,
        peopleSaved = 0,
        advancedProcedures = 0,
        amputations = 0,
        prosthetics = 0,
        quarantines = 0,
        pandemicCasesTreated = 0,
        pathologyStudies = 0,
        pathologySamples = 0,
        patients = {},
        updatedAt = nil,
    }
    if type(stats) ~= "table" then
        return clean
    end
    clean.provider = tostring(stats.provider or "Unknown")
    clean.treatments = tonumber(stats.treatments) or 0
    clean.injuriesFixed = tonumber(stats.injuriesFixed) or 0
    clean.peopleSaved = tonumber(stats.peopleSaved) or 0
    clean.advancedProcedures = tonumber(stats.advancedProcedures) or 0
    clean.amputations = tonumber(stats.amputations) or 0
    clean.prosthetics = tonumber(stats.prosthetics) or 0
    clean.quarantines = tonumber(stats.quarantines) or 0
    clean.pandemicCasesTreated = tonumber(stats.pandemicCasesTreated) or 0
    clean.pathologyStudies = tonumber(stats.pathologyStudies) or 0
    clean.pathologySamples = tonumber(stats.pathologySamples) or 0
    clean.updatedAt = stats.updatedAt
    if type(stats.patients) == "table" then
        for key, value in pairs(stats.patients) do
            if value == true then
                clean.patients[tostring(key)] = true
            end
        end
    end
    return clean
end

function FAM.getProviderStats(provider)
    if not provider then return normalizeProviderStats(nil) end
    local data = provider:getModData()
    data.FAM_ProviderStats = normalizeProviderStats(data.FAM_ProviderStats)
    data.FAM_ProviderStats.provider = FAM.getClinicianName(provider)
    return data.FAM_ProviderStats
end

function FAM.copyProviderStats(provider)
    local stats = normalizeProviderStats(provider and provider:getModData().FAM_ProviderStats or nil)
    if provider then
        stats.provider = FAM.getClinicianName(provider)
        stats.level = FAM.getDoctorLevel(provider)
    else
        stats.level = tonumber(stats.level) or 0
    end
    local patientCount = 0
    for _, value in pairs(stats.patients) do
        if value == true then
            patientCount = patientCount + 1
        end
    end
    stats.patientCount = patientCount
    stats.score = (stats.peopleSaved * 100)
        + (stats.injuriesFixed * 12)
        + (stats.advancedProcedures * 25)
        + (stats.quarantines * 18)
        + (stats.pandemicCasesTreated * 35)
        + (stats.pathologyStudies * 8)
        + (stats.pathologySamples * 16)
    return stats
end

function FAM.applyProviderOutcome(provider, patient, outcome, skipTransmit)
    if not provider then return false end
    outcome = outcome or {}
    local data = provider:getModData()
    local stats = FAM.getProviderStats(provider)
    local now = FAM.getWorldAgeHours()
    local recent = data.FAM_ProviderRecentOutcomes
    if type(recent) ~= "table" then
        recent = {}
        data.FAM_ProviderRecentOutcomes = recent
    end

    local patientKey = patient and FAM.getCharacterKey(patient) or tostring(outcome.patientKey or "unknown")
    local action = tostring(outcome.action or outcome.actionId or "care")
    local bodyPart = tostring(outcome.bodyPart or "")
    local signature = tostring(outcome.signature or (action .. ":" .. patientKey .. ":" .. bodyPart))
    for key, value in pairs(recent) do
        if now - (tonumber(value) or 0) > 0.25 then
            recent[key] = nil
        end
    end
    if recent[signature] and now - (tonumber(recent[signature]) or 0) < 0.05 then
        return false
    end
    recent[signature] = now

    stats.treatments = stats.treatments + 1
    if outcome.injuryFixed ~= false then
        stats.injuriesFixed = stats.injuriesFixed + 1
    end
    if outcome.saved == true then
        stats.peopleSaved = stats.peopleSaved + 1
    end
    if outcome.advanced == true then
        stats.advancedProcedures = stats.advancedProcedures + 1
    end
    if outcome.amputation == true then
        stats.amputations = stats.amputations + 1
    end
    if outcome.prosthetic == true then
        stats.prosthetics = stats.prosthetics + 1
    end
    if outcome.quarantine == true then
        stats.quarantines = stats.quarantines + 1
    end
    if outcome.pandemic == true then
        stats.pandemicCasesTreated = stats.pandemicCasesTreated + 1
    end
    if outcome.pathology == true then
        stats.pathologyStudies = stats.pathologyStudies + 1
    end
    if outcome.pathologySample == true then
        stats.pathologySamples = stats.pathologySamples + 1
    end
    stats.patients[patientKey] = true
    stats.provider = FAM.getClinicianName(provider)
    stats.updatedAt = FAM.getNoteTimestamp()
    data.FAM_ProviderStats = stats

    if not skipTransmit and provider.transmitModData then
        provider:transmitModData()
    end
    return true
end

function FAM.recordProviderOutcome(provider, patient, outcome)
    if not provider then return false end
    local applied = FAM.applyProviderOutcome(provider, patient, outcome, isClient and isClient())
    if isClient and isClient() and sendClientCommand then
        local payload = {
            patientId = FAM.getPatientOnlineID(patient),
            patientIsSelf = patient ~= nil and provider == patient,
            patientKey = FAM.getCharacterKey(patient),
            action = outcome and outcome.action or nil,
            category = outcome and outcome.category or nil,
            bodyPart = outcome and outcome.bodyPart or nil,
            injuryFixed = not outcome or outcome.injuryFixed ~= false,
            saved = outcome and outcome.saved == true or false,
            advanced = outcome and outcome.advanced == true or false,
            amputation = outcome and outcome.amputation == true or false,
            prosthetic = outcome and outcome.prosthetic == true or false,
            quarantine = outcome and outcome.quarantine == true or false,
            pandemic = outcome and outcome.pandemic == true or false,
            pathology = outcome and outcome.pathology == true or false,
            pathologySample = outcome and outcome.pathologySample == true or false,
            signature = outcome and outcome.signature or nil,
        }
        sendClientCommand(provider, FAM.NETWORK_MODULE, "RecordProviderOutcome", payload)
    end
    return applied
end

local function appendProviderRow(rows, provider)
    if not provider then return end
    table.insert(rows, FAM.copyProviderStats(provider))
end

function FAM.getProviderStatsRows()
    local rows = {}
    if getOnlinePlayers then
        local players = getOnlinePlayers()
        if players then
            for i = 1, players:size() do
                appendProviderRow(rows, players:get(i - 1))
            end
        end
    elseif getNumActivePlayers then
        for i = 0, getNumActivePlayers() - 1 do
            appendProviderRow(rows, getSpecificPlayer(i))
        end
    elseif getPlayer then
        appendProviderRow(rows, getPlayer())
    end
    table.sort(rows, function(a, b)
        if a.score == b.score then
            return tostring(a.provider) < tostring(b.provider)
        end
        return a.score > b.score
    end)
    while #rows > FAM.PROVIDER_STATS_MAX_ROWS do
        table.remove(rows)
    end
    return rows
end

function FAM.setPatientNote(patient, note, author, timestamp, skipTransmit, skipRecord)
    if not patient then return false end
    local clean = FAM.sanitizePatientNote(note)
    local data = patient:getModData()
    local cleanAuthor = author or data.FAM_PatientNoteBy or "Unknown"
    local cleanTimestamp = timestamp or FAM.getNoteTimestamp()
    if FAM.trimNote(clean) == "" then
        data.FAM_PatientNote = nil
    else
        data.FAM_PatientNote = clean
    end
    data.FAM_PatientNoteBy = cleanAuthor
    data.FAM_PatientNoteAt = cleanTimestamp
    if not skipRecord then
        FAM.appendPatientNoteRecord(patient, clean, cleanAuthor, cleanTimestamp)
    end
    if not skipTransmit and patient.transmitModData then
        patient:transmitModData()
    end
    return true
end

function FAM.reduceSicknessLevel(character, amount)
    amount = amount or 0
    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage.getSicknessLevel and bodyDamage.setSicknessLevel then
        bodyDamage:setSicknessLevel(FAM.clamp((tonumber(bodyDamage:getSicknessLevel()) or 0) - amount, 0, 100))
    end
    if bodyDamage and bodyDamage.getFoodSicknessLevel and bodyDamage.setFoodSicknessLevel then
        bodyDamage:setFoodSicknessLevel(FAM.clamp((tonumber(bodyDamage:getFoodSicknessLevel()) or 0) - amount, 0, 100))
    end
    FAM.reducePercentStat(character, "SICKNESS", amount)
    FAM.reducePercentStat(character, "FOOD_SICKNESS", amount)
end

function FAM.addSicknessLevel(character, amount)
    amount = amount or 0
    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage.getSicknessLevel and bodyDamage.setSicknessLevel then
        bodyDamage:setSicknessLevel(FAM.clamp((tonumber(bodyDamage:getSicknessLevel()) or 0) + amount, 0, 100))
    end
    if bodyDamage and bodyDamage.getFoodSicknessLevel and bodyDamage.setFoodSicknessLevel then
        bodyDamage:setFoodSicknessLevel(FAM.clamp((tonumber(bodyDamage:getFoodSicknessLevel()) or 0) + (amount * 0.35), 0, 100))
    end
    FAM.addStat(character, "SICKNESS", amount)
    FAM.addStat(character, "FOOD_SICKNESS", amount * 0.35)
end

function FAM.reduceFakeInfection(character, amount)
    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage.getFakeInfectionLevel and bodyDamage.setFakeInfectionLevel then
        bodyDamage:setFakeInfectionLevel(FAM.clamp(bodyDamage:getFakeInfectionLevel() - amount, 0, 100))
        return
    end

    local value = FAM.clamp(FAM.getStat(character, "ZOMBIE_INFECTION", 0) - amount, 0, 100)
    FAM.setStat(character, "ZOMBIE_INFECTION", value)
    FAM.syncCharacterStat(character, "ZOMBIE_INFECTION")
    if value <= 0 and bodyDamage and bodyDamage.setIsFakeInfected then
        bodyDamage:setIsFakeInfected(false)
    end
end

function FAM.addUnhappiness(character, amount)
    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage.getUnhappynessLevel and bodyDamage.setUnhappynessLevel then
        bodyDamage:setUnhappynessLevel(FAM.clamp(bodyDamage:getUnhappynessLevel() + amount, 0, 100))
        return
    end

    FAM.setStat(character, "UNHAPPINESS", FAM.clamp(FAM.getStat(character, "UNHAPPINESS", 0) + amount, 0, 100))
    FAM.syncCharacterStat(character, "UNHAPPINESS")
end

function FAM.syncPlayerEffects(character)
    if isServer and isServer() and sendPlayerEffects then
        sendPlayerEffects(character)
    end
end

function FAM.syncPlayerStats(character, mask)
    if isServer and isServer() and syncPlayerStats then
        syncPlayerStats(character, mask or 0xFFFFFFFF)
    end
end

function FAM.addDoctorXp(character, amount)
    if not character or not Perks or not Perks.Doctor then return end
    if addXp then
        addXp(character, Perks.Doctor, amount)
    elseif character:getXp() then
        character:getXp():AddXP(Perks.Doctor, amount)
    end
end

function FAM.getItemFullType(item)
    if not item then return nil end
    if item.getFullType then return item:getFullType() end
    if item.getModule and item.getType then return item:getModule() .. "." .. item:getType() end
    return item.getType and item:getType() or nil
end

local function famText(key, fallback)
    if getText then return getText(key) end
    return fallback or key
end

local function cleanPathologyRecord(entry)
    if type(entry) ~= "table" then return nil end
    local mode = tostring(entry.mode or "study")
    local kind = tostring(entry.kind or "corpse")
    return {
        mode = mode,
        kind = kind,
        timestamp = tostring(entry.timestamp or "?"),
        quality = FAM.clamp(tonumber(entry.quality) or 0, 0, 100),
        risk = FAM.clamp(tonumber(entry.risk) or 0, 0, 100),
        xp = math.max(0, tonumber(entry.xp) or 0),
        tool = tostring(entry.tool or famText("IGUI_FAM_PathologyNoTool", "Visual exam")),
        sample = entry.sample == true,
        signal = entry.signal == true,
        location = tostring(entry.location or "?"),
    }
end

function FAM.getPathologyRecords(provider)
    if not provider then return {} end
    local data = provider:getModData()
    if type(data.FAM_PathologyRecords) ~= "table" then
        data.FAM_PathologyRecords = {}
    end
    return data.FAM_PathologyRecords
end

function FAM.copyPathologyRecords(provider)
    local source = FAM.getPathologyRecords(provider)
    local records = {}
    for i = 1, #source do
        local clean = cleanPathologyRecord(source[i])
        if clean then
            table.insert(records, clean)
        end
    end
    while #records > FAM.PATHOLOGY_RECORD_MAX_ENTRIES do
        table.remove(records, 1)
    end
    return records
end

function FAM.setPathologyRecords(provider, records, skipTransmit)
    if not provider then return false end
    local clean = {}
    if type(records) == "table" then
        for i = 1, #records do
            local record = cleanPathologyRecord(records[i])
            if record then table.insert(clean, record) end
        end
    end
    while #clean > FAM.PATHOLOGY_RECORD_MAX_ENTRIES do
        table.remove(clean, 1)
    end
    provider:getModData().FAM_PathologyRecords = clean
    if not skipTransmit and provider.transmitModData then
        provider:transmitModData()
    end
    return true
end

function FAM.appendPathologyRecord(provider, entry)
    if not provider then return false end
    local clean = cleanPathologyRecord(entry)
    if not clean then return false end
    local data = provider:getModData()
    local records = FAM.getPathologyRecords(provider)
    table.insert(records, clean)
    while #records > FAM.PATHOLOGY_RECORD_MAX_ENTRIES do
        table.remove(records, 1)
    end
    data.FAM_PathologyRecords = records
    data.FAM_PathologyStudies = (tonumber(data.FAM_PathologyStudies) or 0) + 1
    if clean.sample then
        data.FAM_PathologySamples = (tonumber(data.FAM_PathologySamples) or 0) + 1
    end
    if clean.signal then
        data.FAM_PathologySignals = (tonumber(data.FAM_PathologySignals) or 0) + 1
    end
    if clean.risk >= 20 then
        data.FAM_PathologyUnsafeStudies = (tonumber(data.FAM_PathologyUnsafeStudies) or 0) + 1
    end
    data.FAM_PathologyUpdatedAt = clean.timestamp
    if provider.transmitModData then
        provider:transmitModData()
    end
    return true
end

function FAM.getPathologySummary(provider)
    local data = provider and provider:getModData() or {}
    return {
        studies = tonumber(data.FAM_PathologyStudies) or #FAM.copyPathologyRecords(provider),
        samples = tonumber(data.FAM_PathologySamples) or 0,
        signals = tonumber(data.FAM_PathologySignals) or 0,
        unsafe = tonumber(data.FAM_PathologyUnsafeStudies) or 0,
        updatedAt = data.FAM_PathologyUpdatedAt,
        exposure = FAM.getCorpseExposureLoad(provider),
        pathogen = FAM.getPathogenLoad(provider),
        journal = FAM.findPathologyJournal(provider) ~= nil,
    }
end

function FAM.pathologyModeLabel(modeId)
    local mode = FAM.PATHOLOGY.MODES[modeId or "study"]
    if mode and mode.labelKey then return famText(mode.labelKey, mode.recordKey) end
    return mode and mode.recordKey or tostring(modeId or "study")
end

function FAM.pathologyKindLabel(kind)
    if kind == "zombie" then return famText("IGUI_FAM_PathologyKindZombie", "Zombie") end
    if kind == "human" then return famText("IGUI_FAM_PathologyKindHuman", "Human") end
    if kind == "skeleton" then return famText("IGUI_FAM_PathologyKindSkeleton", "Skeleton") end
    return famText("IGUI_FAM_PathologyKindCorpse", "Corpse")
end

function FAM.isPathologyJournal(item)
    local fullType = FAM.getItemFullType(item)
    if not fullType then return false end
    for i = 1, #FAM.PATHOLOGY.JOURNAL_TYPES do
        if fullType == FAM.PATHOLOGY.JOURNAL_TYPES[i] then return true end
    end
    return false
end

function FAM.findPathologyJournal(character)
    if not character then return nil end
    return FAM.findFirstAvailableItem(character, FAM.PATHOLOGY.JOURNAL_TYPES)
end

function FAM.getPathologyToolProfile(item)
    local fullType = FAM.getItemFullType(item)
    if fullType and FAM.PATHOLOGY.TOOL_PROFILES[fullType] then
        return FAM.PATHOLOGY.TOOL_PROFILES[fullType]
    end
    if not item or not item.getType then return nil end
    local itemType = tostring(item:getType())
    if string.find(itemType, "Scalpel", 1, true) then
        return { tier = 3, label = "Scalpel", wear = 1, risk = 0.55, time = 0.55 }
    end
    if string.find(itemType, "Knife", 1, true) or string.find(itemType, "Cleaver", 1, true) then
        return { tier = 2, label = "Cutting tool", wear = 2, risk = 0.95, time = 0.82 }
    end
    if string.find(itemType, "Scissors", 1, true) then
        return { tier = 1, label = "Scissors", wear = 2, risk = 1.25, time = 1.12 }
    end
    return nil
end

function FAM.findPathologyTool(character)
    if not character then return nil end
    local primary = character.getPrimaryHandItem and character:getPrimaryHandItem() or nil
    if primary and FAM.getPathologyToolProfile(primary) and not (primary.isBroken and primary:isBroken()) then
        return primary
    end
    local secondary = character.getSecondaryHandItem and character:getSecondaryHandItem() or nil
    if secondary and FAM.getPathologyToolProfile(secondary) and not (secondary.isBroken and secondary:isBroken()) then
        return secondary
    end
    for i = 1, #FAM.PATHOLOGY.TOOL_TYPES do
        local item = FAM.findFirstItem(character, FAM.PATHOLOGY.TOOL_TYPES[i])
        if item and not (item.isBroken and item:isBroken()) then return item end
    end
    return nil
end

function FAM.getCorpseKind(body)
    if not body then return nil end
    if body.isAnimal and body:isAnimal() then return "animal" end
    if body.isZombie and body:isZombie() then return "zombie" end
    if body.isSkeleton and body:isSkeleton() then return "skeleton" end
    return "human"
end

function FAM.getCorpseLocationLabel(body)
    local square = body and body.getSquare and body:getSquare() or nil
    if not square then return "?" end
    return tostring(math.floor(square:getX())) .. "," .. tostring(math.floor(square:getY())) .. "," .. tostring(math.floor(square:getZ()))
end

local function getPathologyProtection(character)
    local protection = 0
    if FAM.findFirstAvailableItem(character, { "FAM.AntisepticWashKit", "Base.AlcoholWipes", "Base.Disinfectant" }) then
        protection = protection + 0.22
    end
    local function hasWorn(location)
        if not character or not character.getWornItem then return false end
        local bodyLocation = location
        if type(location) == "string" and ItemBodyLocation then
            bodyLocation = ItemBodyLocation[location]
        end
        if not bodyLocation then return false end
        local ok, item = pcall(function() return character:getWornItem(bodyLocation) end)
        return ok and item ~= nil
    end
    if hasWorn("HANDS") or hasWorn("HANDS_LEFT") or hasWorn("HANDS_RIGHT") then protection = protection + 0.24 end
    if hasWorn("MASK") or hasWorn("MASK_EYES") or hasWorn("MASK_FULL") or hasWorn("SCBA") or hasWorn("SCBANOTANK") then protection = protection + 0.18 end
    if tonumber(character:getModData().FAM_SanitationHours) and tonumber(character:getModData().FAM_SanitationHours) > 0 then
        protection = protection + 0.16
    end
    return FAM.clamp(protection, 0, 0.72)
end

local function pathologyStudyKey(modeId)
    local mode = FAM.PATHOLOGY.MODES[modeId or "study"] or FAM.PATHOLOGY.MODES.study
    return "FAM_Pathology_" .. tostring(mode.recordKey or modeId or "Study")
end

function FAM.canStudyCorpse(doctor, body, modeId, tool, journal)
    local mode = FAM.PATHOLOGY.MODES[modeId or "study"]
    if not mode then return false, "Tooltip_FAM_PathologyInvalidMode" end
    if not doctor then return false, "Tooltip_FAM_InvalidPatient" end
    if not body or not body.getSquare or not body:getSquare() then return false, "Tooltip_FAM_PathologyNoCorpse" end
    local kind = FAM.getCorpseKind(body)
    if kind == "animal" then return false, "Tooltip_FAM_PathologyAnimalCorpse" end
    if not FAM.isMedicalCheat(doctor) and FAM.getDoctorLevel(doctor) < mode.minLevel then
        return false, "Tooltip_FAM_PathologyLocked"
    end
    if mode.requiresJournal and not journal then
        return false, "Tooltip_FAM_PathologyRequiresJournal"
    end
    if mode.requiresTool and not tool then
        return false, "Tooltip_FAM_PathologyRequiresTool"
    end
    if tool and tool.isBroken and tool:isBroken() then
        return false, "Tooltip_FAM_PathologyToolBroken"
    end
    local bodyData = body.getModData and body:getModData() or nil
    if bodyData and bodyData[pathologyStudyKey(modeId)] then
        return false, "Tooltip_FAM_PathologyAlreadyStudied"
    end
    return true
end

local function damagePathologyTool(tool, amount)
    if not tool or not tool.getCondition or not tool.setCondition then return end
    local current = tonumber(tool:getCondition()) or 0
    tool:setCondition(math.max(0, current - math.max(0, amount or 0)))
    if syncInventoryItem then
        syncInventoryItem(tool)
    end
end

local function addPathologySample(doctor, record)
    if not doctor or not doctor.getInventory then return nil end
    local inventory = doctor:getInventory()
    if not inventory or not inventory.AddItem then return nil end
    local item = inventory:AddItem(FAM.PATHOLOGY.SAMPLE_ITEM)
    if item and item.getModData then
        local data = item:getModData()
        data.FAM_PathologyKind = record.kind
        data.FAM_PathologyQuality = record.quality
        data.FAM_PathologySignal = record.signal == true
        data.FAM_PathologyCollectedAt = record.timestamp
    end
    if item and sendAddItemToContainer then
        sendAddItemToContainer(inventory, item)
    end
    return item
end

local function rollPathologySignal(chance)
    if chance <= 0 then return false end
    if ZombRand then return ZombRand(100) < chance end
    return math.random(0, 99) < chance
end

function FAM.applyCorpseStudy(doctor, body, tool, journal, modeId)
    modeId = modeId or "study"
    journal = journal or FAM.findPathologyJournal(doctor)
    tool = tool or FAM.findPathologyTool(doctor)
    local valid, reason = FAM.canStudyCorpse(doctor, body, modeId, tool, journal)
    if not valid then
        return false, reason
    end

    local mode = FAM.PATHOLOGY.MODES[modeId]
    local toolProfile = FAM.getPathologyToolProfile(tool) or { tier = 0, label = famText("IGUI_FAM_PathologyNoTool", "Visual exam"), wear = 0, risk = 1.35, time = 1.25 }
    local doctorLevel = FAM.getEffectiveDoctorLevel(doctor)
    local kind = FAM.getCorpseKind(body)
    local timestamp = FAM.getNoteTimestamp()
    local quality = FAM.clamp((mode.minQuality or 20) + (doctorLevel * 5) + ((toolProfile.tier or 0) * 10) + (journal and 8 or 0), 0, 100)
    local risk = FAM.clamp((mode.baseRisk or 10) * (toolProfile.risk or 1) * (1 - getPathologyProtection(doctor)), 1, 100)
    local signalChance = (mode.signalChance or 0) + math.floor(quality / 12)
    local signal = rollPathologySignal(signalChance)
    local sample = false

    local data = doctor:getModData()
    data.FAM_CorpseExposureLoad = FAM.clamp((tonumber(data.FAM_CorpseExposureLoad) or 0) + risk, 0, 100)
    data.FAM_PathogenLoad = FAM.clamp((tonumber(data.FAM_PathogenLoad) or 0) + (risk * 0.65), 0, 100)
    if risk >= 24 then
        FAM.addSicknessLevel(doctor, math.max(1, risk * 0.05))
    end

    damagePathologyTool(tool, (toolProfile.wear or 0) + (mode.advanced and 1 or 0))

    local totalStudies = (tonumber(data.FAM_PathologyStudies) or 0) + 1
    local diminishing = totalStudies > 32 and 0.45 or (totalStudies > 18 and 0.65 or (totalStudies > 8 and 0.82 or 1))
    local xp = math.max(3, math.floor(((mode.baseXp or 8) + ((toolProfile.tier or 0) * 2) + (quality / 25)) * diminishing))
    FAM.addDoctorXp(doctor, xp)

    local bodyData = body.getModData and body:getModData() or nil
    if bodyData then
        bodyData[pathologyStudyKey(modeId)] = timestamp
        bodyData.FAM_PathologyLastProvider = FAM.getClinicianName(doctor)
        if body.transmitModData then body:transmitModData() end
    end

    local record = {
        mode = modeId,
        kind = kind,
        timestamp = timestamp,
        quality = quality,
        risk = risk,
        xp = xp,
        tool = toolProfile.label or FAM.getItemFullType(tool) or famText("IGUI_FAM_PathologyNoTool", "Visual exam"),
        sample = false,
        signal = signal,
        location = FAM.getCorpseLocationLabel(body),
    }

    if mode.createsSample then
        sample = addPathologySample(doctor, record) ~= nil
        record.sample = sample
    end

    FAM.appendPathologyRecord(doctor, record)
    FAM.recordProviderOutcome(doctor, nil, {
        action = "pathology_" .. modeId,
        category = "pathology",
        patientKey = "corpse:" .. record.location,
        injuryFixed = false,
        advanced = mode.advanced == true,
        pathology = true,
        pathologySample = sample == true,
        signature = "pathology:" .. tostring(modeId) .. ":" .. record.location .. ":" .. tostring(math.floor(FAM.getWorldAgeHours() * 10)),
    })

    if doctor.transmitModData then
        doctor:transmitModData()
    end
    FAM.syncPlayerEffects(doctor)
    return true, record
end

function FAM.isRecipeKnown(character, recipe)
    if not character or not recipe then return false end
    if character.isRecipeActuallyKnown and character:isRecipeActuallyKnown(recipe) then
        return true
    end
    local known = character.getKnownRecipes and character:getKnownRecipes() or nil
    if known and known.contains and known:contains(recipe) then
        return true
    end
    return false
end

function FAM.knowsProtocol(character, treatment)
    local protocol = FAM.TREATMENTS[treatment]
    if not protocol then return true end
    if protocol.strictBook then
        return FAM.isRecipeKnown(character, protocol.recipe) or FAM.isMedicalCheat(character)
    end
    local level = FAM.getDoctorLevel(character)
    return level >= protocol.level or FAM.isRecipeKnown(character, protocol.recipe) or FAM.isMedicalCheat(character)
end

function FAM.protocolLabel(treatment)
    if treatment == "burn" then return famText("IGUI_FAM_Protocol_Burn", "Burn") end
    if treatment == "hemostatic" then return famText("IGUI_FAM_Protocol_Hemostatic", "Hemostatic") end
    if treatment == "tourniquet" then return famText("IGUI_FAM_Protocol_Tourniquet", "Tourniquet") end
    if treatment == "sanitation" then return famText("IGUI_FAM_Protocol_Sanitation", "Sanitize") end
    if treatment == "stumpcare" then return famText("IGUI_FAM_Protocol_StumpCare", "Stump") end
    if treatment == "amputation" then return famText("IGUI_FAM_Protocol_Amputation", "Amputation") end
    if treatment == "prosthetic" then return famText("IGUI_FAM_Protocol_Prosthetic", "Prosthetic") end
    if treatment == "ivfluids" then return famText("IGUI_FAM_Protocol_IVFluids", "IV Fluids") end
    if treatment == "bloodpack" then return famText("IGUI_FAM_Protocol_BloodSupport", "Blood") end
    if treatment == "epinephrine" then return famText("IGUI_FAM_Protocol_Epinephrine", "Epi") end
    return treatment
end

function FAM.getClinicalKnowledgeRows(character)
    local rows = {}
    for i = 1, #FAM.KNOWLEDGE_GROUPS do
        local group = FAM.KNOWLEDGE_GROUPS[i]
        local known = 0
        for j = 1, #group.treatments do
            if FAM.knowsProtocol(character, group.treatments[j]) then
                known = known + 1
            end
        end
        table.insert(rows, {
            key = group.key,
            labelKey = group.labelKey,
            known = known,
            total = #group.treatments,
            complete = known >= #group.treatments,
        })
    end
    return rows
end

local function getPartType(bodyPart)
    return bodyPart and bodyPart:getType()
end

function FAM.isLimb(bodyPart)
    if not bodyPart or not BodyPartType then return false end
    local partType = getPartType(bodyPart)
    return partType ~= BodyPartType.Head
        and partType ~= BodyPartType.Neck
        and partType ~= BodyPartType.Torso_Upper
        and partType ~= BodyPartType.Torso_Lower
        and partType ~= BodyPartType.Groin
end

function FAM.hasTourniquet(patient, bodyPart)
    if not patient or not bodyPart then return false end
    return patient:getModData()["FAM_Tourniquet_" .. tostring(bodyPart:getIndex())] ~= nil
end

function FAM.getBodyPartName(bodyPart)
    if not bodyPart or not BodyPartType then return nil end
    return BodyPartType.ToString(bodyPart:getType())
end

function FAM.isAmputatableLimb(bodyPart)
    local name = FAM.getBodyPartName(bodyPart)
    return name ~= nil and FAM.AMPUTATION_ADJACENT[name] ~= nil
end

function FAM.hasAmputation(patient, bodyPart)
    if not patient or not bodyPart then return false end
    local name = FAM.getBodyPartName(bodyPart)
    return name ~= nil and patient:getModData()["FAM_Amputated_" .. name] == true
end

function FAM.getBodyPartByName(character, name)
    if not character or not name or not BodyPartType or not BodyPartType[name] then return nil end
    local bodyDamage = FAM.getBodyDamage(character)
    return bodyDamage and bodyDamage:getBodyPart(BodyPartType[name]) or nil
end

function FAM.getPartDataKey(prefix, bodyPart)
    local name = FAM.getBodyPartName(bodyPart)
    if not name then return nil end
    return "FAM_" .. prefix .. "_" .. name
end

function FAM.getPartValue(patient, bodyPart, prefix, fallback)
    if not patient or not bodyPart then return fallback end
    local key = FAM.getPartDataKey(prefix, bodyPart)
    if not key then return fallback end
    local value = patient:getModData()[key]
    if value == nil then return fallback end
    return value
end

function FAM.setPartValue(patient, bodyPart, prefix, value)
    if not patient or not bodyPart then return end
    local key = FAM.getPartDataKey(prefix, bodyPart)
    if key then
        patient:getModData()[key] = value
    end
end

function FAM.clearPartValue(patient, bodyPart, prefix)
    if not patient or not bodyPart then return end
    local key = FAM.getPartDataKey(prefix, bodyPart)
    if key then
        patient:getModData()[key] = nil
    end
end

function FAM.getGangrene(patient, bodyPart)
    return tonumber(FAM.getPartValue(patient, bodyPart, "Gangrene", 0)) or 0
end

function FAM.setGangrene(patient, bodyPart, value)
    value = FAM.clamp(value, 0, 100)
    if value <= 0 then
        FAM.clearPartValue(patient, bodyPart, "Gangrene")
    else
        FAM.setPartValue(patient, bodyPart, "Gangrene", value)
    end
end

function FAM.getBulletHours(patient, bodyPart)
    return tonumber(FAM.getPartValue(patient, bodyPart, "BulletHours", 0)) or 0
end

function FAM.isAmputationIndicated(patient, bodyPart)
    return FAM.getPartValue(patient, bodyPart, "AmputationIndicated", false) == true
end

function FAM.getSideFromLimbName(limbName)
    if not limbName then return nil end
    return string.sub(limbName, -1)
end

function FAM.getPrimaryAmputationName(patient, bodyPart)
    if not patient or not bodyPart then return nil end
    local limbName = FAM.getBodyPartName(bodyPart)
    if not limbName or not FAM.AMPUTATION_ADJACENT[limbName] then return nil end
    local side = FAM.getSideFromLimbName(limbName)
    if side ~= "L" and side ~= "R" then return nil end
    local data = patient:getModData()
    if data["FAM_Amputated_UpperArm_" .. side] then return "UpperArm_" .. side end
    if data["FAM_Amputated_ForeArm_" .. side] then return "ForeArm_" .. side end
    if data["FAM_Amputated_Hand_" .. side] then return "Hand_" .. side end
    return nil
end

function FAM.getPrimaryAmputationKey(patient, bodyPart)
    local name = FAM.getPrimaryAmputationName(patient, bodyPart)
    return name and "FAM_Prosthetic_" .. name or nil
end

function FAM.isPrimaryAmputationPart(patient, bodyPart)
    local name = FAM.getBodyPartName(bodyPart)
    return name ~= nil and FAM.getPrimaryAmputationName(patient, bodyPart) == name
end

function FAM.isSuppressedAmputationPart(patient, bodyPart)
    return FAM.hasAmputation(patient, bodyPart) and not FAM.isPrimaryAmputationPart(patient, bodyPart)
end

function FAM.hasProsthetic(patient, bodyPart)
    if not patient or not bodyPart then return false end
    if not FAM.isPrimaryAmputationPart(patient, bodyPart) then return false end
    local key = FAM.getPrimaryAmputationKey(patient, bodyPart)
    return key ~= nil and patient:getModData()[key] ~= nil
end

function FAM.getFittedProstheticType(patient, bodyPart)
    if not patient or not bodyPart then return nil, nil end
    local primary = FAM.getPrimaryAmputationName(patient, bodyPart)
    if not primary then return nil, nil end
    return patient:getModData()["FAM_Prosthetic_" .. primary], primary
end

function FAM.findProsthetic(character)
    return FAM.findFirstAvailableItem(character, FAM.PROSTHETIC_ITEMS)
end

function FAM.getProstheticType(item)
    if not item then return nil end
    local fullType = FAM.getItemFullType(item)
    if fullType == "FAM.HookArmProsthesis" then return "hook" end
    if fullType == "FAM.BasicArmProsthesis" then return "basic" end
    return nil
end

function FAM.getProstheticItemType(prostheticType)
    return FAM.PROSTHETIC_ITEM_BY_TYPE[prostheticType]
end

FAM.AMPUTATION_VISUAL_ITEM_BASE = "FAM.FAM_Amputation_"
FAM.AMPUTATION_VISUAL_PARTS = { "Hand", "ForeArm", "UpperArm" }
FAM.PROSTHETIC_VISUAL_ITEMS = {
    basic = { L = "FAM.FAM_Prosthetic_Normal_L", R = "FAM.FAM_Prosthetic_Normal_R" },
    hook = { L = "FAM.FAM_Prosthetic_Hook_L", R = "FAM.FAM_Prosthetic_Hook_R" },
}

local function shouldMutateVisualInventory()
    return not (isClient and isClient())
end

local function getInventory(character)
    if not character or not character.getInventory then return nil end
    return character:getInventory()
end

local function setVisualTextureChoice(item, textureChoice)
    if not item or textureChoice == nil or not item.getVisual then return end
    local visual = item:getVisual()
    if visual and visual.setTextureChoice then
        visual:setTextureChoice(textureChoice)
    end
end

local function syncVisualEquipment(character)
    if not character then return end
    if sendEquip then
        sendEquip(character)
    end
    if character.resetModelNextFrame then
        character:resetModelNextFrame()
    end
end

local function removeVisualInventoryItem(character, item)
    if not character or not item then return false end
    local inventory = getInventory(character)
    if character.removeWornItem then
        character:removeWornItem(item)
    end
    if inventory and inventory.Remove then
        inventory:Remove(item)
    end
    if inventory and sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(inventory, item)
    end
    syncVisualEquipment(character)
    return true
end

local function removeVisualItemsByFullType(character, fullType)
    local inventory = getInventory(character)
    if not inventory or not inventory.FindAndReturn or not fullType then return false end

    local removed = false
    for _ = 1, 8 do
        local item = inventory:FindAndReturn(fullType)
        if not item then break end
        removed = removeVisualInventoryItem(character, item) or removed
    end
    return removed
end

function FAM.getAmputationVisualTextureChoice(patient, healed)
    local textureString = ""
    if patient and patient.getHumanVisual then
        local humanVisual = patient:getHumanVisual()
        if humanVisual and humanVisual.getSkinTexture then
            textureString = tostring(humanVisual:getSkinTexture() or "")
        end
    end

    local matchedIndex = tonumber(string.match(textureString, "%d%d")) or 1
    matchedIndex = math.max(1, math.min(5, matchedIndex))
    local isHairy = string.sub(textureString, -1) == "a"

    if isHairy then
        matchedIndex = matchedIndex + 5
    end
    if healed then
        matchedIndex = matchedIndex + (isHairy and 5 or 10)
    end

    return matchedIndex - 1
end

function FAM.equipVisualItem(character, item)
    if not character or not item or not item.getBodyLocation or not character.setWornItem then
        return false
    end
    local bodyLocation = item:getBodyLocation()
    if not bodyLocation then return false end
    character:setWornItem(bodyLocation, item)
    syncVisualEquipment(character)
    return true
end

function FAM.wearExistingVisualItem(character, fullType, textureChoice)
    local inventory = getInventory(character)
    if not inventory or not inventory.FindAndReturn then return false end
    local item = inventory:FindAndReturn(fullType)
    if not item then return false end
    setVisualTextureChoice(item, textureChoice)
    return FAM.equipVisualItem(character, item)
end

local function addAndWearVisualItem(character, fullType, textureChoice)
    local inventory = getInventory(character)
    if not inventory or not inventory.AddItem then return false end

    local item = inventory:AddItem(fullType)
    if not item then return false end
    setVisualTextureChoice(item, textureChoice)
    if sendAddItemToContainer then
        sendAddItemToContainer(inventory, item)
    end

    local equipped = FAM.equipVisualItem(character, item)

    if isServer and isServer() and sendServerCommand then
        sendServerCommand(character, FAM.NETWORK_MODULE, "WearVisualItem", {
            fullType = fullType,
            textureChoice = textureChoice,
            patientId = FAM.getPatientOnlineID(character),
        })
    end

    return equipped
end

function FAM.removeAmputationVisuals(character, side)
    if not character or (side ~= "L" and side ~= "R") then return false end
    if not shouldMutateVisualInventory() then return false end

    local removed = false
    for i = 1, #FAM.AMPUTATION_VISUAL_PARTS do
        local fullType = FAM.AMPUTATION_VISUAL_ITEM_BASE .. FAM.AMPUTATION_VISUAL_PARTS[i] .. "_" .. side
        removed = removeVisualItemsByFullType(character, fullType) or removed
    end
    return removed
end

function FAM.removeProstheticVisuals(character, side)
    if not character or (side ~= "L" and side ~= "R") then return false end
    if not shouldMutateVisualInventory() then return false end

    local removed = false
    for _, bySide in pairs(FAM.PROSTHETIC_VISUAL_ITEMS) do
        removed = removeVisualItemsByFullType(character, bySide[side]) or removed
    end
    return removed
end

function FAM.dropHeldItemsForAmputation(character, limbName)
    local side = FAM.getSideFromLimbName(limbName)
    if not character or (side ~= "L" and side ~= "R") then return false end

    if side == "R" and character.getPrimaryHandItem and character.setPrimaryHandItem then
        local primary = character:getPrimaryHandItem()
        if primary then
            if character.getSecondaryHandItem and character.setSecondaryHandItem and primary == character:getSecondaryHandItem() then
                character:setSecondaryHandItem(nil)
            end
            character:setPrimaryHandItem(nil)
        end
    elseif side == "L" and character.getSecondaryHandItem and character.setSecondaryHandItem then
        local secondary = character:getSecondaryHandItem()
        if secondary then
            if character.getPrimaryHandItem and character.setPrimaryHandItem and secondary == character:getPrimaryHandItem() then
                character:setPrimaryHandItem(nil)
            end
            character:setSecondaryHandItem(nil)
        end
    end

    if sendEquip then
        sendEquip(character)
    end
    return true
end

function FAM.applyAmputationVisual(character, limbName)
    local side = FAM.getSideFromLimbName(limbName)
    if not character or not FAM.AMPUTATION_ADJACENT[limbName] or (side ~= "L" and side ~= "R") then
        return false
    end
    if not shouldMutateVisualInventory() then return false end

    FAM.removeAmputationVisuals(character, side)
    FAM.removeProstheticVisuals(character, side)

    local fullType = FAM.AMPUTATION_VISUAL_ITEM_BASE .. limbName
    local textureChoice = FAM.getAmputationVisualTextureChoice(character, false)
    return addAndWearVisualItem(character, fullType, textureChoice)
end

function FAM.applyProstheticVisual(character, limbName, prostheticType)
    local side = FAM.getSideFromLimbName(limbName)
    if not character or (side ~= "L" and side ~= "R") then return false end
    if not shouldMutateVisualInventory() then return false end

    local bySide = FAM.PROSTHETIC_VISUAL_ITEMS[prostheticType]
    local fullType = bySide and bySide[side] or nil
    if not fullType then return false end

    FAM.removeProstheticVisuals(character, side)
    return addAndWearVisualItem(character, fullType, nil)
end

function FAM.refreshLimbVisuals(character)
    if not character or not shouldMutateVisualInventory() then return false end
    local changed = false
    local data = character:getModData()
    for _, side in ipairs({ "L", "R" }) do
        local primary = nil
        if data["FAM_Amputated_UpperArm_" .. side] then
            primary = "UpperArm_" .. side
        elseif data["FAM_Amputated_ForeArm_" .. side] then
            primary = "ForeArm_" .. side
        elseif data["FAM_Amputated_Hand_" .. side] then
            primary = "Hand_" .. side
        end

        if primary then
            changed = FAM.applyAmputationVisual(character, primary) or changed
            local prostheticType = data["FAM_Prosthetic_" .. primary]
            if prostheticType then
                changed = FAM.applyProstheticVisual(character, primary, prostheticType) or changed
            end
        end
    end
    return changed
end

function FAM.canFitProsthetic(doctor, patient, bodyPart, item)
    if not doctor or not patient or not bodyPart then
        return false, "Tooltip_FAM_InvalidPatient"
    end
    if not FAM.knowsProtocol(doctor, "prosthetic") then
        return false, "Tooltip_FAM_LockedProtocol"
    end
    local primary = FAM.getPrimaryAmputationName(patient, bodyPart)
    if not primary then
        return false, "Tooltip_FAM_ProstheticNeedsAmputation"
    end
    if not FAM.isPrimaryAmputationPart(patient, bodyPart) then
        return false, "Tooltip_FAM_ProstheticNeedsAmputation"
    end
    if FAM.hasProsthetic(patient, bodyPart) then
        return false, "Tooltip_FAM_ProstheticAlreadyFit"
    end
    if (tonumber(patient:getModData()["FAM_StumpRecoveryHours_" .. primary]) or 0) > 0 then
        return false, "Tooltip_FAM_StumpStillRecovering"
    end
    if FAM.getProstheticType(item) == nil then
        return false, "Tooltip_FAM_MissingProsthetic"
    end
    return true
end

function FAM.canRemoveProsthetic(doctor, patient, bodyPart)
    if not doctor or not patient or not bodyPart then
        return false, "Tooltip_FAM_InvalidPatient"
    end
    local prostheticType, primary = FAM.getFittedProstheticType(patient, bodyPart)
    if not primary then
        return false, "Tooltip_FAM_ProstheticNeedsAmputation"
    end
    if not prostheticType then
        return false, "Tooltip_FAM_NoProstheticFit"
    end
    if not FAM.getProstheticItemType(prostheticType) then
        return false, "Tooltip_FAM_NoProstheticFit"
    end
    return true
end

function FAM.canUseTreatment(doctor, patient, bodyPart, treatment)
    if not doctor or not patient or not bodyPart then
        return false, "Tooltip_FAM_InvalidPatient"
    end
    if not FAM.knowsProtocol(doctor, treatment) then
        return false, "Tooltip_FAM_LockedProtocol"
    end
    if FAM.hasAmputation(patient, bodyPart) then
        if treatment == "stumpcare" then
            if not FAM.isPrimaryAmputationPart(patient, bodyPart) then
                return false, "Tooltip_FAM_AmputationAlreadyDone"
            end
        elseif treatment ~= "ivfluids" and treatment ~= "bloodpack" and treatment ~= "epinephrine" then
            return false, "Tooltip_FAM_AmputationAlreadyDone"
        end
    end
    if treatment == "burn" then
        if patient:getModData().FAM_BurnTreatmentCooldown then
            return false, "Tooltip_FAM_BurnCooldown"
        end
        if bodyPart:getBurnTime() <= 0 and not bodyPart:isNeedBurnWash() then
            return false, "Tooltip_FAM_NoBurn"
        end
        return true
    end
    if treatment == "hemostatic" then
        if not bodyPart:bleeding() and bodyPart:getBleedingTime() <= 0 then
            return false, "Tooltip_FAM_NoBleeding"
        end
        return true
    end
    if treatment == "tourniquet" then
        if not FAM.isLimb(bodyPart) then
            return false, "Tooltip_FAM_TourniquetLimbOnly"
        end
        if FAM.hasTourniquet(patient, bodyPart) then
            return false, "Tooltip_FAM_TourniquetAlreadyApplied"
        end
        if not bodyPart:bleeding() and bodyPart:getBleedingTime() <= 0 then
            return false, "Tooltip_FAM_NoBleeding"
        end
        return true
    end
    if treatment == "sanitation" then
        if FAM.getCorpseExposureLoad(patient) <= 0
            and FAM.getPathogenLoad(patient) <= 0
            and FAM.getSicknessLevel(patient) <= 0
            and not FAM.hasOpenContaminationRoute(bodyPart) then
            return false, "Tooltip_FAM_NoExposure"
        end
        return true
    end
    if treatment == "stumpcare" then
        if FAM.getGangrene(patient, bodyPart) <= 0
            and not FAM.hasAmputation(patient, bodyPart)
            and not bodyPart:isInfectedWound()
            and not bodyPart:haveBullet()
            and not bodyPart:haveGlass()
            and bodyPart:getDeepWoundTime() <= 0 then
            return false, "Tooltip_FAM_NoStumpCareNeed"
        end
        return true
    end
    if treatment == "ivfluids" then
        if not FAM.findFirstItem(doctor, "FAM.IVKit") then
            return false, "Tooltip_FAM_MissingIVKit"
        end
        local bloodPercent = FAM.getBloodPercent(patient)
        local shock = tonumber(patient:getModData().FAM_ShockLoad) or 0
        local supportHours = tonumber(patient:getModData().FAM_SalineSupportHours) or 0
        if supportHours > 3 then
            return false, "Tooltip_FAM_IVAlreadyActive"
        end
        if bloodPercent >= 92 and shock < 20 and not FAM.hasActiveBleeding(patient) then
            return false, "Tooltip_FAM_NoIVNeed"
        end
        return true
    end
    if treatment == "bloodpack" then
        if not FAM.findFirstItem(doctor, "FAM.IVKit") then
            return false, "Tooltip_FAM_MissingIVKit"
        end
        local bloodPercent = FAM.getBloodPercent(patient)
        local bodyHealth = FAM.getBodyHealthPercent(patient)
        local shock = tonumber(patient:getModData().FAM_ShockLoad) or 0
        if FAM.hasUncontrolledBleeding(patient) then
            return false, "Tooltip_FAM_ControlBleedingFirst"
        end
        if math.min(bloodPercent, bodyHealth) >= 82 and shock < 35 then
            return false, "Tooltip_FAM_NoBloodNeed"
        end
        return true
    end
    if treatment == "epinephrine" then
        local data = patient:getModData()
        if data.FAM_EpinephrineCooldown then
            return false, "Tooltip_FAM_EpinephrineCooldown"
        end
        local bodyDamage = FAM.getBodyDamage(patient)
        local health = bodyDamage and bodyDamage:getHealth() or 100
        local shock = tonumber(data.FAM_ShockLoad) or 0
        if shock < 35 and health > 55 and FAM.getStat(patient, "FATIGUE", 0) < 0.85 then
            return false, "Tooltip_FAM_NoEpinephrineNeed"
        end
        return true
    end
    if treatment == "amputation" then
        if not FAM.isAmputatableLimb(bodyPart) then
            return false, "Tooltip_FAM_AmputationArmsOnly"
        end
        if FAM.hasAmputation(patient, bodyPart) then
            return false, "Tooltip_FAM_AmputationAlreadyDone"
        end
        return true
    end
    return false, "Tooltip_FAM_InvalidTreatment"
end

function FAM.findFirstItem(character, fullType)
    if not character or not fullType then return nil end
    local inventory = character:getInventory()
    if not inventory then return nil end
    if inventory.getFirstTypeEvalRecurse then
        return inventory:getFirstTypeEvalRecurse(fullType, function(item) return item ~= nil end)
    end
    if inventory.getFirstTypeRecurse then
        return inventory:getFirstTypeRecurse(fullType)
    end
    return inventory:getFirstType(fullType)
end

function FAM.findFirstAvailableItem(character, fullTypes)
    if not fullTypes then return nil end
    for i = 1, #fullTypes do
        local item = FAM.findFirstItem(character, fullTypes[i])
        if item then return item end
    end
    return nil
end

local function findItemByIdInContainer(container, itemId, visited)
    if not container or itemId == nil then return nil end
    visited = visited or {}
    if visited[container] then return nil end
    visited[container] = true

    if container.getItemById then
        local direct = container:getItemById(itemId)
        if direct then return direct end
    end

    local items = container.getItems and container:getItems() or nil
    if not items then return nil end
    for i = 1, items:size() do
        local item = items:get(i - 1)
        if item and item.getID and item:getID() == itemId then
            return item
        end
        if item and item.IsInventoryContainer and item:IsInventoryContainer() and item.getInventory then
            local found = findItemByIdInContainer(item:getInventory(), itemId, visited)
            if found then return found end
        end
    end
    return nil
end

function FAM.findInventoryItemById(character, itemId)
    local id = tonumber(itemId)
    if not character or id == nil or not character.getInventory then return nil end
    return findItemByIdInContainer(character:getInventory(), id, {})
end

function FAM.findHeldItemById(character, itemId)
    local id = tonumber(itemId)
    if not character or id == nil then return nil end
    local primary = character.getPrimaryHandItem and character:getPrimaryHandItem() or nil
    if primary and primary.getID and primary:getID() == id then return primary end
    local secondary = character.getSecondaryHandItem and character:getSecondaryHandItem() or nil
    if secondary and secondary.getID and secondary:getID() == id then return secondary end
    return nil
end

function FAM.findCharacterItemById(character, itemId)
    return FAM.findHeldItemById(character, itemId) or FAM.findInventoryItemById(character, itemId)
end

function FAM.findHeldItemByTypes(character, fullTypes)
    if not character or not fullTypes then return nil end
    local primary = character.getPrimaryHandItem and character:getPrimaryHandItem() or nil
    if FAM.isItemAnyFullType(primary, fullTypes) then return primary end
    local secondary = character.getSecondaryHandItem and character:getSecondaryHandItem() or nil
    if FAM.isItemAnyFullType(secondary, fullTypes) then return secondary end
    return nil
end

function FAM.findHeldOrInventoryItem(character, fullTypes)
    return FAM.findHeldItemByTypes(character, fullTypes) or FAM.findFirstAvailableItem(character, fullTypes)
end

function FAM.findSurgicalSaw(character)
    return FAM.findHeldOrInventoryItem(character, FAM.SAW_TYPES)
end

function FAM.findBandageItem(character)
    return FAM.findFirstAvailableItem(character, {
        "Base.AlcoholBandage",
        "Base.Bandage",
        "Base.RippedSheets",
    })
end

function FAM.findStitchItem(character)
    local suture = FAM.findFirstItem(character, "Base.SutureNeedle")
    if suture then return suture end
    local needle = FAM.findFirstItem(character, "Base.Needle")
    if not needle then return nil end
    return FAM.findFirstItem(character, "Base.Thread")
end

function FAM.consumeTreatmentItem(character, item, useDrainable)
    if not character or not item then return end
    if useDrainable then
        if item.UseAndSync then
            item:UseAndSync()
        else
            item:Use()
        end
        return
    end
    local container = item:getContainer() or character:getInventory()
    if container then
        container:Remove(item)
        if isServer and isServer() and sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(container, item)
        end
    end
end

local function addHemophobicPanic(character, bodyPart)
    if bodyPart and bodyPart:getBleedingTime() > 0 and FAM.hasTrait(character, "HEMOPHOBIC") then
        FAM.addStat(character, "PANIC", 50)
        FAM.syncPlayerStats(character, 0x00000100)
    end
end

function FAM.isCSRAvailable()
    if CSR_FeatureFlags or CSR_InfectionResilience then return true end
    if getActivatedMods then
        local mods = getActivatedMods()
        return mods and mods.contains and mods:contains("CommonSenseReborn")
    end
    return false
end

function FAM.isCSRInfectionResilienceEnabled()
    if CSR_FeatureFlags and CSR_FeatureFlags.isInfectionResilienceEnabled then
        return CSR_FeatureFlags.isInfectionResilienceEnabled()
    end
    return FAM.isCSRAvailable()
end

function FAM.isZVirusVaccineAvailable()
    if getActivatedMods then
        local mods = getActivatedMods()
        return mods and mods.contains and mods:contains("ZVirusVaccine42BETA")
    end
    return false
end

function FAM.isZVirusProfessionAddonAvailable()
    if getActivatedMods then
        local mods = getActivatedMods()
        return mods and mods.contains and mods:contains("ResearchLabInternProfession")
    end
    return false
end

function FAM.getZVirusVaccineStatus(character)
    local status = {
        active = FAM.isZVirusVaccineAvailable(),
        professionAddon = FAM.isZVirusProfessionAddonAvailable(),
        infected = false,
        infectionRate = 0,
        vaccineTime = 0,
        vaccineStrength = 0,
        vaccineRecess = 0,
        vaccineQuality = 0,
        albuminDoses = 0,
    }
    if not character then return status end

    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage.isInfected then
        status.infected = bodyDamage:isInfected() == true
    end
    if bodyDamage and bodyDamage.getInfectionMortalityDuration and bodyDamage.getInfectionTime and character.getHoursSurvived then
        local mortality = tonumber(bodyDamage:getInfectionMortalityDuration()) or 0
        if mortality > 0 then
            local elapsed = (tonumber(character:getHoursSurvived()) or 0) - (tonumber(bodyDamage:getInfectionTime()) or 0)
            status.infectionRate = FAM.clamp((elapsed / mortality) * 100, 0, 100)
        end
    end

    local data = character:getModData()
    status.vaccineTime = math.max(0, tonumber(data.VaccineTime) or 0)
    status.vaccineStrength = math.max(0, tonumber(data.VaccineStrength) or 0)
    status.vaccineRecess = math.max(0, tonumber(data.VaccineRecess) or 0)
    status.vaccineQuality = math.max(0, tonumber(data.VaccineQuality) or 0)
    status.albuminDoses = math.max(0, tonumber(data.AlbuminDoses) or 0)
    return status
end

function FAM.applyCSRSupport(character, source, power, hours)
    if not character or not FAM.isCSRInfectionResilienceEnabled() then return false end
    local data = character:getModData()
    data.FAM_CSR_AntibodySupportPower = math.max(tonumber(data.FAM_CSR_AntibodySupportPower) or 0, power or 1)
    data.FAM_CSR_AntibodySupportHours = math.max(tonumber(data.FAM_CSR_AntibodySupportHours) or 0, hours or 12)
    data.FAM_CSR_AntibodySupportSource = source

    if data.CSR_IR_Doomed then
        data.CSR_IR_Doomed = nil
        data.FAM_CSR_RetryGranted = true
    end
    if data.CSR_IR_Threshold then
        data.CSR_IR_Threshold = math.max(data.CSR_IR_Threshold, 92)
    end
    return true
end

function FAM.getBloodMaxVolume(character)
    if not character then return FAM.BLOOD.MAX_VOLUME end
    return math.max(1, tonumber(character:getModData().FAM_BloodMaxVolume) or FAM.BLOOD.MAX_VOLUME)
end

function FAM.getBloodVolume(character)
    if not character then return FAM.BLOOD.MAX_VOLUME, FAM.BLOOD.MAX_VOLUME end
    local maxVolume = FAM.getBloodMaxVolume(character)
    local volume = tonumber(character:getModData().FAM_BloodVolume) or maxVolume
    return FAM.clamp(volume, 0, maxVolume), maxVolume
end

function FAM.setBloodVolume(character, volume)
    if not character then return end
    local data = character:getModData()
    local maxVolume = FAM.getBloodMaxVolume(character)
    volume = FAM.clamp(volume, 0, maxVolume)
    if volume >= maxVolume then
        data.FAM_BloodVolume = nil
    else
        data.FAM_BloodVolume = volume
    end
end

function FAM.addBloodVolume(character, amount)
    if not character or not amount then return end
    local volume = FAM.getBloodVolume(character)
    FAM.setBloodVolume(character, volume + amount)
end

function FAM.getBloodPercent(character)
    local volume, maxVolume = FAM.getBloodVolume(character)
    return FAM.clamp((volume / maxVolume) * 100, 0, 100)
end

function FAM.getBloodDisplayPercent(character)
    local percent = FAM.getBloodPercent(character)
    if not character then return percent end
    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage.getHealth then
        return math.min(percent, FAM.clamp(bodyDamage:getHealth(), 0, 100))
    end
    return percent
end

function FAM.getFluidSupportHours(character)
    if not character then return 0 end
    local data = character:getModData()
    return math.max(tonumber(data.FAM_SalineSupportHours) or 0, tonumber(data.FAM_BloodSupportHours) or 0)
end

function FAM.getBodyHealthPercent(character)
    local bodyDamage = FAM.getBodyDamage(character)
    if bodyDamage and bodyDamage.getHealth then
        return FAM.clamp(bodyDamage:getHealth(), 0, 100)
    end
    return 100
end

function FAM.isBleedingControlled(patient, bodyPart)
    if not patient or not bodyPart then return false end
    if FAM.hasTourniquet(patient, bodyPart) then return true end
    if bodyPart.bandaged and bodyPart:bandaged() then return true end
    if bodyPart.stitched and bodyPart:stitched() then return true end
    local careQuality = tonumber(FAM.getPartValue(patient, bodyPart, "WoundCareQuality", 0)) or 0
    return careQuality > 0 and not bodyPart:bleeding()
end

local function getPartBloodLoss(patient, bodyPart)
    if not patient or not bodyPart then return 0 end
    if not bodyPart:bleeding() and bodyPart:getBleedingTime() <= 0 then return 0 end
    local loss = FAM.BLOOD.BLEED_BASE_PER_HOUR + (math.min(bodyPart:getBleedingTime(), 80) * FAM.BLOOD.BLEED_TIME_FACTOR)
    if not FAM.isLimb(bodyPart) then
        loss = loss * 1.25
    end
    if FAM.hasTourniquet(patient, bodyPart) then
        loss = loss * 0.15
    elseif FAM.isBleedingControlled(patient, bodyPart) then
        loss = loss * 0.25
    end
    return loss
end

function FAM.getBleedingLossPerHour(character)
    if not character then return 0 end
    local bodyDamage = FAM.getBodyDamage(character)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return 0 end
    local loss = 0
    for i = 1, bodyParts:size() do
        loss = loss + getPartBloodLoss(character, bodyParts:get(i - 1))
    end
    return loss
end

function FAM.hasActiveBleeding(character)
    return FAM.getBleedingLossPerHour(character) > 0
end

function FAM.hasUncontrolledBleeding(character)
    if not character then return false end
    local bodyDamage = FAM.getBodyDamage(character)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return false end
    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        if bodyPart and (bodyPart:bleeding() or bodyPart:getBleedingTime() > 0) and not FAM.isBleedingControlled(character, bodyPart) then
            return true
        end
    end
    return false
end

function FAM.updateBloodReserve(character)
    if not character then return end
    local data = character:getModData()
    local volume = FAM.getBloodVolume(character)
    local loss = FAM.getBleedingLossPerHour(character)
    local salineHours = tonumber(data.FAM_SalineSupportHours) or 0
    local bloodHours = tonumber(data.FAM_BloodSupportHours) or 0

    if loss > 0 then
        if salineHours > 0 then
            loss = loss * 0.85
        end
        volume = volume - loss
    else
        local recovery = FAM.BLOOD.NATURAL_RECOVERY_PER_HOUR
        if bloodHours > 0 then
            recovery = recovery + FAM.BLOOD.BLOOD_SUPPORT_RECOVERY_PER_HOUR
        end
        volume = volume + recovery
    end

    local supportVolume = tonumber(data.FAM_FluidSupportVolume) or 0
    if salineHours > 0 and supportVolume > 0 then
        data.FAM_FluidSupportVolume = math.max(0, supportVolume - 90)
    elseif salineHours <= 0 then
        data.FAM_FluidSupportVolume = nil
    end

    FAM.setBloodVolume(character, volume)
    local percent = FAM.getBloodPercent(character)
    if percent < FAM.BLOOD.LOW_PERCENT then
        local shockPressure = (FAM.BLOOD.LOW_PERCENT - percent) / 10
        if salineHours > 0 or bloodHours > 0 then
            shockPressure = shockPressure * 0.55
        end
        data.FAM_ShockLoad = FAM.clamp((tonumber(data.FAM_ShockLoad) or 0) + shockPressure, 0, 100)
        FAM.addStat(character, "FATIGUE", 0.015 + ((FAM.BLOOD.LOW_PERCENT - percent) / 250))
        FAM.setStat(character, "ENDURANCE", math.min(FAM.getStat(character, "ENDURANCE", 0), math.max(0.08, percent / 100)))
        if percent < FAM.BLOOD.CRITICAL_PERCENT then
            local bodyDamage = FAM.getBodyDamage(character)
            if bodyDamage and bodyDamage.ReduceGeneralHealth then
                bodyDamage:ReduceGeneralHealth((FAM.BLOOD.CRITICAL_PERCENT - percent) / 18)
            end
        end
    elseif salineHours > 0 or bloodHours > 0 then
        FAM.reduceSystemicCondition(character, "FAM_ShockLoad", bloodHours > 0 and 5 or 3)
    end
end

local function startsWith(text, prefix)
    return string.sub(text, 1, string.len(prefix)) == prefix
end

local function endsWith(text, suffix)
    local start = string.len(text) - string.len(suffix) + 1
    return start > 0 and string.sub(text, start) == suffix
end

local function isActiveSubstanceValue(value)
    local valueType = type(value)
    if valueType == "number" then return value > 0 end
    if valueType == "boolean" then return value == true end
    if valueType == "string" then return value ~= "" and value ~= "0" end
    return false
end

local function humanizeSubstanceKey(key)
    local text = tostring(key)
    for i = 1, #FAM.SUBSTANCE_SCAN.PREFIXES do
        local prefix = FAM.SUBSTANCE_SCAN.PREFIXES[i]
        if startsWith(text, prefix) then
            text = string.sub(text, string.len(prefix) + 1)
            break
        end
    end
    text = string.gsub(text, "_", " ")
    text = string.gsub(text, "(%l)(%u)", "%1 %2")
    return text
end

function FAM.isSubstanceModDataKey(key)
    if not key then return false end
    key = tostring(key)
    if FAM.SUBSTANCE_SCAN.IGNORE_KEYS[key] then return false end
    if FAM.SUBSTANCE_SCAN.DISPLAY_KEYS[key] then return true end
    local hasPrefix = false
    for i = 1, #FAM.SUBSTANCE_SCAN.PREFIXES do
        if startsWith(key, FAM.SUBSTANCE_SCAN.PREFIXES[i]) then
            hasPrefix = true
            break
        end
    end
    if not hasPrefix then return false end
    for i = 1, #FAM.SUBSTANCE_SCAN.ACTIVE_SUFFIXES do
        if endsWith(key, FAM.SUBSTANCE_SCAN.ACTIVE_SUFFIXES[i]) then
            return true
        end
    end
    return false
end

function FAM.formatSubstanceValue(key, value)
    if type(value) == "boolean" then return value and "active" or "clear" end
    if type(value) ~= "number" then return tostring(value) end
    if endsWith(tostring(key), "Hours") or endsWith(tostring(key), "Cooldown") or endsWith(tostring(key), "Timer") or endsWith(tostring(key), "Duration") then
        return tostring(math.floor(value)) .. "h"
    end
    if value > 0 and value < 1 then
        return tostring(math.floor(value * 100)) .. "%"
    end
    return tostring(math.floor(value))
end

function FAM.scanSubstances(character)
    local rows = {}
    if not character then return rows end
    local data = character:getModData()
    if not data then return rows end
    for key, value in pairs(data) do
        if FAM.isSubstanceModDataKey(key) and isActiveSubstanceValue(value) then
            table.insert(rows, {
                key = tostring(key),
                labelKey = FAM.SUBSTANCE_SCAN.DISPLAY_KEYS[tostring(key)],
                label = FAM.SUBSTANCE_SCAN.DISPLAY_NAMES[tostring(key)] or humanizeSubstanceKey(key),
                value = value,
                valueText = FAM.formatSubstanceValue(key, value),
                category = FAM.SUBSTANCE_SCAN.CATEGORIES[tostring(key)] or "medication",
            })
        end
    end
    table.sort(rows, function(a, b)
        if a.category == b.category then
            return a.label < b.label
        end
        return a.category < b.category
    end)
    return rows
end

function FAM.getCSRStatus(character)
    local data = character and character:getModData() or {}
    local available = FAM.isCSRAvailable()
        or data.FAM_CSR_AntibodySupportHours ~= nil
        or data.CSR_IR_Doomed ~= nil
        or data.CSR_IR_Threshold ~= nil
    local hours = tonumber(data.FAM_CSR_AntibodySupportHours) or 0
    local power = tonumber(data.FAM_CSR_AntibodySupportPower) or 0
    local threshold = tonumber(data.CSR_IR_Threshold) or nil
    local crisis = data.CSR_IR_Doomed == true
    local retry = data.FAM_CSR_RetryGranted == true
    local statusKey = "IGUI_FAM_CSRStatus_Unavailable"
    local severity = 0

    if crisis then
        statusKey = "IGUI_FAM_CSRStatus_Crisis"
        severity = 100
    elseif hours > 0 then
        statusKey = retry and "IGUI_FAM_CSRStatus_Retry" or "IGUI_FAM_CSRStatus_Active"
        severity = FAM.clamp(35 - (power * 5), 8, 45)
    elseif available then
        statusKey = "IGUI_FAM_CSRStatus_Ready"
        severity = 5
    end

    return {
        available = available == true,
        active = hours > 0,
        crisis = crisis,
        retry = retry,
        hours = hours,
        power = power,
        threshold = threshold,
        statusKey = statusKey,
        severity = severity,
    }
end

function FAM.getLocalInfectionLoad(character)
    if not character then return 0 end
    return tonumber(character:getModData().FAM_LocalInfectionLoad) or 0
end

function FAM.getTreatmentQuality(doctor, patient, bodyPart, treatment)
    local level = FAM.getEffectiveDoctorLevel(doctor)
    local domain = "routine"
    if treatment == "hemostatic" or treatment == "tourniquet" or treatment == "amputation" then
        domain = "trauma"
    elseif treatment == "sanitation" or treatment == "stumpcare" then
        domain = "infection"
    elseif treatment == "ivfluids" or treatment == "bloodpack" or treatment == "epinephrine" then
        domain = "vascular"
    end

    local quality = 34 + (level * 5) + FAM.getMedicalRoleBonus(doctor, domain)
    if FAM.knowsProtocol(doctor, treatment) then
        quality = quality + 8
    end
    local csr = FAM.getCSRStatus(patient)
    if csr.active and (domain == "infection" or domain == "vascular") then
        quality = quality + math.min(10, 3 + csr.power * 2)
    end
    if bodyPart and bodyPart:isInfectedWound() and domain ~= "infection" then
        quality = quality - 8
    end
    return FAM.clamp(quality, 5, 100)
end

local function getQualityLabelKey(quality)
    if quality >= 82 then return "IGUI_FAM_TreatmentQuality_Excellent" end
    if quality >= 62 then return "IGUI_FAM_TreatmentQuality_Good" end
    if quality >= 42 then return "IGUI_FAM_TreatmentQuality_Fair" end
    return "IGUI_FAM_TreatmentQuality_Poor"
end

function FAM.getTreatmentQualityLabelKey(doctor, patient, bodyPart, treatment)
    return getQualityLabelKey(FAM.getTreatmentQuality(doctor, patient, bodyPart, treatment))
end

function FAM.getKnoxSuspicion(patient, doctor)
    if not patient then
        return { value = 0, certainty = 0, labelKey = "IGUI_FAM_Knox_Clear" }
    end
    local bodyDamage = FAM.getBodyDamage(patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    local woundPressure = 0
    if bodyParts then
        for i = 1, bodyParts:size() do
            local bodyPart = bodyParts:get(i - 1)
            if bodyPart:bitten() then
                woundPressure = math.max(woundPressure, 70)
            elseif bodyPart:scratched() or bodyPart:isCut() then
                woundPressure = math.max(woundPressure, 28)
            end
        end
    end
    local symptomPressure = 0
    symptomPressure = symptomPressure + math.min(FAM.getSicknessLevel(patient), 45)
    symptomPressure = symptomPressure + math.min(FAM.getTemperatureDeviationPercent(patient), 35)
    symptomPressure = symptomPressure + math.min(FAM.getStat(patient, "PANIC", 0), 35) * 0.35
    if FAM.getCSRStatus(patient).crisis then
        symptomPressure = symptomPressure + 35
    end
    local value = FAM.clamp((woundPressure * 0.55) + (symptomPressure * 0.8), 0, 100)
    local labelKey = "IGUI_FAM_Knox_Clear"
    if value >= 70 then
        labelKey = "IGUI_FAM_Knox_Critical"
    elseif value >= 40 then
        labelKey = "IGUI_FAM_Knox_Suspected"
    elseif value >= 18 then
        labelKey = "IGUI_FAM_Knox_Watch"
    end
    return {
        value = value,
        certainty = FAM.getClinicalCertainty(doctor, "diagnosis"),
        labelKey = labelKey,
    }
end

function FAM.getClinicalPrognosis(patient, doctor)
    if not patient then
        return { value = 0, labelKey = "IGUI_FAM_Prognosis_Unknown" }
    end
    local bloodDeficit = 100 - FAM.getBloodPercent(patient)
    local sepsis = tonumber(patient:getModData().FAM_SepsisLoad) or 0
    local shock = tonumber(patient:getModData().FAM_ShockLoad) or 0
    local infection = FAM.getLocalInfectionLoad(patient)
    local csr = FAM.getCSRStatus(patient)
    local value = math.max(
        FAM.getConditionLoad(patient),
        bloodDeficit,
        sepsis,
        shock,
        infection,
        FAM.getPandemicLoad(patient),
        FAM.getKnoxSuspicion(patient, doctor).value
    )
    if csr.active and (sepsis >= FAM.CONDITION.SEPSIS_SUSPECT or infection >= FAM.CONDITION.LOCAL_INFECTION_SUSPECT) then
        value = math.max(0, value - math.min(12, 4 + csr.power * 3))
    end
    local labelKey = "IGUI_FAM_Prognosis_Stable"
    if value >= 85 or csr.crisis then
        labelKey = "IGUI_FAM_Prognosis_Crisis"
    elseif value >= 65 then
        labelKey = "IGUI_FAM_Prognosis_Critical"
    elseif value >= 42 then
        labelKey = "IGUI_FAM_Prognosis_Serious"
    elseif value >= 20 then
        labelKey = "IGUI_FAM_Prognosis_Watch"
    end
    return { value = FAM.clamp(value, 0, 100), labelKey = labelKey, csr = csr.active }
end

local function summaryValue(percent)
    return tostring(math.floor(tonumber(percent) or 0)) .. "%"
end

function FAM.getClinicalSummaryRows(patient, doctor)
    local rows = {}
    if not patient then return rows end
    local csr = FAM.getCSRStatus(patient)
    local bloodPercent = FAM.getBloodDisplayPercent(patient)
    local sepsis = tonumber(patient:getModData().FAM_SepsisLoad) or 0
    local shock = tonumber(patient:getModData().FAM_ShockLoad) or 0
    local infection = FAM.getLocalInfectionLoad(patient)
    local knox = FAM.getKnoxSuspicion(patient, doctor)
    local prognosis = FAM.getClinicalPrognosis(patient, doctor)
    local substances = FAM.scanSubstances(patient)
    local pandemicLoad = FAM.getPandemicLoad(patient)
    local diseaseText = FAM.isPandemicInfected(patient) and FAM.getPandemicDiseaseName(patient, doctor) or famText("IGUI_FAM_Disease_Clear", "clear")
    if FAM.isPandemicSuperCarrier(patient) then
        diseaseText = diseaseText .. " " .. famText("IGUI_FAM_Disease_SuperCarrier", "super carrier")
    end

    table.insert(rows, { key = "prognosis", labelKey = "IGUI_FAM_Clinical_Prognosis", valueText = famText(prognosis.labelKey), severity = prognosis.value })
    table.insert(rows, { key = "csr", labelKey = "IGUI_FAM_Clinical_CSR", valueText = famText(csr.statusKey), severity = csr.severity, csr = csr.active or csr.crisis })
    table.insert(rows, { key = "disease", labelKey = "IGUI_FAM_Clinical_Disease", valueText = diseaseText, severity = pandemicLoad })
    table.insert(rows, { key = "blood", labelKey = "IGUI_FAM_Clinical_Blood", valueText = summaryValue(bloodPercent), severity = 100 - bloodPercent })
    table.insert(rows, { key = "shock", labelKey = "IGUI_FAM_Clinical_Shock", valueText = summaryValue(shock), severity = shock })
    table.insert(rows, { key = "sepsis", labelKey = "IGUI_FAM_Clinical_Sepsis", valueText = summaryValue(sepsis), severity = sepsis })
    table.insert(rows, { key = "infection", labelKey = "IGUI_FAM_Clinical_LocalInfection", valueText = summaryValue(infection), severity = infection })
    table.insert(rows, { key = "knox", labelKey = "IGUI_FAM_Clinical_Knox", valueText = famText(knox.labelKey), severity = knox.value })
    table.insert(rows, { key = "substances", labelKey = "IGUI_FAM_Clinical_Substances", valueText = tostring(#substances), severity = math.min(100, #substances * 12) })

    table.sort(rows, function(a, b)
        if a.key == b.key then return false end
        if a.key == "prognosis" then return true end
        if b.key == "prognosis" then return false end
        if a.key == "csr" and (a.csr or b.severity < 20) then return true end
        if b.key == "csr" and (b.csr or a.severity < 20) then return false end
        return a.severity > b.severity
    end)
    return rows
end

function FAM.performClinicalAssessment(doctor, patient)
    if not doctor or not patient then return false end
    local data = patient:getModData()
    local now = FAM.getWorldAgeHours()
    local assessorKey = string.gsub(FAM.getCharacterKey(doctor), "[^%w_]", "_")
    local cooldownKey = "FAM_AssessmentAt_" .. assessorKey
    local last = tonumber(data[cooldownKey]) or -999
    local prognosis = FAM.getClinicalPrognosis(patient, doctor)
    local csr = FAM.getCSRStatus(patient)
    local shouldRecord = now - last >= 1.5 or prognosis.value >= 45 or csr.crisis
    data[cooldownKey] = now

    FAM.updatePatientAnalytics(patient)
    if shouldRecord then
        FAM.appendClinicalRecord(patient, {
            key = "assessment",
            labelKey = "IGUI_FAM_ClinicalEvent_Assessment",
            valueText = famText(prognosis.labelKey),
            severity = prognosis.value,
            provider = FAM.getClinicianName(doctor),
            csr = csr.active or csr.crisis,
        }, true)
        local xp = 2 + math.floor(prognosis.value / 18) + FAM.getMedicalRoleBonus(doctor, "training")
        if doctor ~= patient then xp = xp + 1 end
        FAM.addDoctorXp(doctor, xp)
        FAM.recordProviderOutcome(doctor, patient, {
            action = "clinical_assessment",
            category = "fam",
            bodyPart = "systemic",
            injuryFixed = false,
            saved = prognosis.value >= 70,
            advanced = FAM.hasAdvancedClinicalAccess(doctor),
            signature = "clinical_assessment:" .. FAM.getCharacterKey(patient) .. ":" .. tostring(math.floor(now * 2)),
        })
    end
    if patient.transmitModData then
        patient:transmitModData()
    end
    return true
end

local function isPartInfected(bodyPart)
    if not bodyPart then return false end
    return (bodyPart.IsInfected and bodyPart:IsInfected() == true)
        or (bodyPart.isInfectedWound and bodyPart:isInfectedWound() == true)
        or (bodyPart.bitten and bodyPart:bitten() == true)
end

local function countOtherInfectedParts(patient, skipName)
    local bodyDamage = FAM.getBodyDamage(patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return 0 end
    local count = 0
    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        if FAM.getBodyPartName(bodyPart) ~= skipName and isPartInfected(bodyPart) then
            count = count + 1
        end
    end
    return count
end

local function clearPartInfection(bodyPart)
    if not bodyPart then return end
    if bodyPart.SetBitten then bodyPart:SetBitten(false) end
    if bodyPart.SetInfected then bodyPart:SetInfected(false) end
    if bodyPart.SetFakeInfected then bodyPart:SetFakeInfected(false) end
    if bodyPart.setInfectedWound then bodyPart:setInfectedWound(false) end
    if bodyPart.setWoundInfectionLevel then
        bodyPart:setWoundInfectionLevel(-1)
    end
end

local function tryStopZombieInfection(patient, bodyPart, limbName)
    if not patient or not bodyPart or not CharacterStat or not CharacterStat.ZOMBIE_INFECTION then
        return false
    end
    if not isPartInfected(bodyPart) then return false end
    if countOtherInfectedParts(patient, limbName) > 0 then return false end

    local stats = patient:getStats()
    local infection = stats:get(CharacterStat.ZOMBIE_INFECTION) or 0
    local maxIntervention = FAM.isCSRInfectionResilienceEnabled() and 0.35 or 0.2
    if infection <= 0 or infection > maxIntervention then
        return false
    end

    local bodyDamage = FAM.getBodyDamage(patient)
    stats:set(CharacterStat.ZOMBIE_INFECTION, 0)
    if CharacterStat.ZOMBIE_FEVER then
        stats:set(CharacterStat.ZOMBIE_FEVER, math.max(stats:get(CharacterStat.ZOMBIE_FEVER) or 0, infection * 0.5))
    end
    bodyDamage:setInfected(false)
    if bodyDamage.setIsFakeInfected then bodyDamage:setIsFakeInfected(true) end
    if bodyDamage.setInfectionMortalityDuration then bodyDamage:setInfectionMortalityDuration(-1) end
    if bodyDamage.setInfectionTime then bodyDamage:setInfectionTime(-1) end
    patient:getModData().FAM_AmputationStoppedInfection = true
    return true
end

local function markAmputation(patient, limbName)
    local data = patient:getModData()
    data["FAM_Amputated_" .. limbName] = true
    local dependencies = FAM.AMPUTATION_DEPENDENCIES[limbName] or {}
    for i = 1, #dependencies do
        data["FAM_Amputated_" .. dependencies[i]] = true
    end
    data.FAM_HasAmputation = true
end

local function clearAmputationSourceConditions(patient, bodyPart, limbName)
    FAM.clearPartValue(patient, bodyPart, "Gangrene")
    FAM.clearPartValue(patient, bodyPart, "BulletHours")
    FAM.clearPartValue(patient, bodyPart, "AmputationIndicated")
    patient:getModData()["FAM_StumpRecoveryHours_" .. limbName] = 24
end

local function clearRemovedLimbBodyPart(patient, bodyPart, limbName)
    if not patient or not bodyPart then return end
    local bodyDamage = FAM.getBodyDamage(patient)
    local data = patient:getModData()
    bodyPart:RestoreToFullHealth()
    bodyPart:setBleeding(false)
    bodyPart:setBleedingTime(0)
    bodyPart:setCut(false)
    bodyPart:setCutTime(0)
    bodyPart:setDeepWounded(false)
    bodyPart:setDeepWoundTime(0)
    if bodyPart.setScratched then bodyPart:setScratched(false, true) end
    if bodyPart.setBite then bodyPart:setBite(false) end
    if bodyPart.setBitten then bodyPart:setBitten(false) end
    if bodyPart.setHaveGlass then bodyPart:setHaveGlass(false) end
    if bodyPart.setHaveBullet then bodyPart:setHaveBullet(false, 0) end
    if bodyPart.setFractureTime then bodyPart:setFractureTime(0) end
    if bodyPart.setStitched then bodyPart:setStitched(false) end
    if bodyPart.setSplint then bodyPart:setSplint(false, 0) end
    if bodyDamage and bodyDamage.SetBandaged then
        bodyDamage:SetBandaged(bodyPart:getIndex(), false, 0, false, nil)
    end
    data["FAM_Tourniquet_" .. tostring(bodyPart:getIndex())] = nil
    clearPartInfection(bodyPart)
    FAM.clearPartValue(patient, bodyPart, "Gangrene")
    FAM.clearPartValue(patient, bodyPart, "BulletHours")
    FAM.clearPartValue(patient, bodyPart, "AmputationIndicated")
    FAM.clearPartValue(patient, bodyPart, "StumpCareHours")
    FAM.clearPartValue(patient, bodyPart, "SanitationHours")
    if limbName then
        patient:getModData()["FAM_StumpRecoveryHours_" .. limbName] = 24
    end
end

local function clearRemovedLimbChain(patient, limbName)
    if not patient or not limbName then return end
    local names = { limbName }
    local dependencies = FAM.AMPUTATION_DEPENDENCIES[limbName] or {}
    for i = 1, #dependencies do
        names[#names + 1] = dependencies[i]
    end
    for i = 1, #names do
        clearRemovedLimbBodyPart(patient, FAM.getBodyPartByName(patient, names[i]), names[i])
        if syncBodyPart then
            local part = FAM.getBodyPartByName(patient, names[i])
            if part then syncBodyPart(part, BODY_SYNC_ALL) end
        end
    end
end

local function damageSaw(item)
    if item and item.getCondition and item.setCondition then
        item:setCondition(math.max(0, item:getCondition() - 1))
    end
end

local function useStitchItem(item)
    if item and item.UseAndSync then
        item:UseAndSync()
    elseif item and item.Use then
        item:Use()
    end
end

function FAM.performFieldAmputation(doctor, patient, sawItem, bodyPart, stitchItem, bandageItem)
    local valid = FAM.canUseTreatment(doctor, patient, bodyPart, "amputation")
    if not valid then return false end
    if not FAM.isItemAnyFullType(sawItem, FAM.SAW_TYPES) then return false end

    local preSeverity = FAM.bodyPartClinicalSeverity(patient, bodyPart)
    local preConditionLoad = FAM.getConditionLoad(patient)
    local limbName = FAM.getBodyPartName(bodyPart)
    local adjacentName = FAM.AMPUTATION_ADJACENT[limbName]
    local bodyDamage = FAM.getBodyDamage(patient)
    local adjacent = adjacentName and bodyDamage and bodyDamage:getBodyPart(BodyPartType[adjacentName]) or nil
    local doctorLevel = FAM.getEffectiveDoctorLevel(doctor)
    local stoppedInfection = tryStopZombieInfection(patient, bodyPart, limbName)
    local hadTourniquet = FAM.hasTourniquet(patient, bodyPart)

    markAmputation(patient, limbName)
    clearRemovedLimbChain(patient, limbName)
    clearAmputationSourceConditions(patient, bodyPart, limbName)
    FAM.applyAmputationVisual(patient, limbName)
    FAM.dropHeldItemsForAmputation(patient, limbName)
    if patient.transmitModData then
        patient:transmitModData()
    end

    local baseDamage = FAM.AMPUTATION_BASE_DAMAGE[limbName] or 70
    if hadTourniquet then
        baseDamage = baseDamage * 0.55
    end
    local surgicalDamage = math.max(18, baseDamage - (doctorLevel * 5))
    if adjacent then
        adjacent:AddDamage(surgicalDamage)
        adjacent:setAdditionalPain(adjacent:getAdditionalPain() + surgicalDamage)
        adjacent:setBleeding(true)
        adjacent:setBleedingTime(math.max(8, surgicalDamage * 0.8))
        adjacent:setDeepWounded(true)
        adjacent:setDeepWoundTime(math.max(8, surgicalDamage * 0.5))
        if stitchItem then
            adjacent:setStitched(true)
            adjacent:setStitchTime(((1 + doctorLevel) / 2) * ZombRandFloat(2, 5))
            adjacent:setDeepWoundTime(math.max(0, adjacent:getDeepWoundTime() - 20))
            useStitchItem(stitchItem)
        end
        if bandageItem then
            local life = 2 + doctorLevel + (bandageItem.getBandagePower and bandageItem:getBandagePower() or 1)
            local alcohol = bandageItem.isAlcoholic and bandageItem:isAlcoholic() or false
            if bodyDamage and bodyDamage.SetBandaged then
                bodyDamage:SetBandaged(adjacent:getIndex(), true, life, alcohol, bandageItem:getModule() .. "." .. bandageItem:getType())
            end
            FAM.consumeTreatmentItem(doctor, bandageItem, false)
        end
        if syncBodyPart then
            syncBodyPart(adjacent, BODY_SYNC_ALL)
        end
    end

    FAM.addStat(patient, "PAIN", 80)
    FAM.addStat(patient, "PANIC", 80)
    FAM.addStat(patient, "STRESS", 0.45)
    FAM.setStat(patient, "ENDURANCE", math.min(FAM.getStat(patient, "ENDURANCE", 0), 0.25))
    damageSaw(sawItem)
    FAM.addDoctorXp(doctor, stoppedInfection and 60 or 35)
    FAM.applyCSRSupport(patient, "field_amputation", stoppedInfection and 3 or 2, stoppedInfection and 36 or 18)

    if syncBodyPart then
        syncBodyPart(bodyPart, BODY_SYNC_ALL)
    end
    FAM.syncPlayerEffects(patient)
    FAM.syncPlayerStats(patient)
    FAM.recordProviderOutcome(doctor, patient, {
        action = "field_amputation",
        category = "fam",
        bodyPart = limbName or "Unknown",
        injuryFixed = true,
        saved = stoppedInfection or preSeverity >= 70 or preConditionLoad >= 70,
        advanced = true,
        amputation = true,
        signature = "field_amputation:" .. FAM.getCharacterKey(patient) .. ":" .. tostring(limbName) .. ":" .. tostring(math.floor(FAM.getWorldAgeHours() * 10)),
    })
    return true
end

function FAM.reduceSystemicCondition(patient, key, amount)
    if not patient then return end
    local data = patient:getModData()
    local value = tonumber(data[key]) or 0
    value = math.max(0, value - amount)
    data[key] = value > 0 and value or nil
end

function FAM.reduceAllGangrene(patient, amount)
    if not patient then return end
    local bodyDamage = FAM.getBodyDamage(patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return end
    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        local gangrene = FAM.getGangrene(patient, bodyPart)
        if gangrene > 0 then
            FAM.setGangrene(patient, bodyPart, gangrene - amount)
        end
    end
end

function FAM.performFitProsthetic(doctor, patient, prostheticItem, bodyPart)
    local valid = FAM.canFitProsthetic(doctor, patient, bodyPart, prostheticItem)
    if not valid then return false end

    local primary = FAM.getPrimaryAmputationName(patient, bodyPart)
    local prostheticType = FAM.getProstheticType(prostheticItem)
    local data = patient:getModData()
    data["FAM_Prosthetic_" .. primary] = prostheticType
    data["FAM_ProstheticDurability_" .. primary] = prostheticType == "hook" and 80 or 100
    data["FAM_ProstheticFitHours_" .. primary] = 0
    data["FAM_ProstheticFittedBy_" .. primary] = doctor.getUsername and doctor:getUsername() or "Unknown"
    FAM.applyProstheticVisual(patient, primary, prostheticType)
    if patient.transmitModData then
        patient:transmitModData()
    end

    FAM.consumeTreatmentItem(doctor, prostheticItem, false)
    FAM.addDoctorXp(doctor, 22)
    FAM.reduceSystemicCondition(patient, "FAM_ShockLoad", 6)
    FAM.syncPlayerEffects(patient)
    FAM.recordProviderOutcome(doctor, patient, {
        action = "fit_prosthetic",
        category = "fam",
        bodyPart = primary or "Unknown",
        injuryFixed = true,
        saved = false,
        advanced = true,
        prosthetic = true,
        signature = "fit_prosthetic:" .. FAM.getCharacterKey(patient) .. ":" .. tostring(primary) .. ":" .. tostring(math.floor(FAM.getWorldAgeHours() * 10)),
    })
    return true
end

local function addReturnedProsthetic(doctor, patient, prostheticType)
    local fullType = FAM.getProstheticItemType(prostheticType)
    if not fullType then return nil end

    local recipient = doctor or patient
    local inventory = getInventory(recipient)
    if not inventory or not inventory.AddItem then return nil end

    local item = inventory:AddItem(fullType)
    if item and sendAddItemToContainer then
        sendAddItemToContainer(inventory, item)
    end
    return item
end

function FAM.performRemoveProsthetic(doctor, patient, bodyPart)
    local valid = FAM.canRemoveProsthetic(doctor, patient, bodyPart)
    if not valid then return false end

    local prostheticType, primary = FAM.getFittedProstheticType(patient, bodyPart)
    local returnedItem = addReturnedProsthetic(doctor, patient, prostheticType)
    if not returnedItem then return false end

    local data = patient:getModData()
    data["FAM_Prosthetic_" .. primary] = nil
    data["FAM_ProstheticDurability_" .. primary] = nil
    data["FAM_ProstheticFitHours_" .. primary] = nil
    data["FAM_ProstheticFittedBy_" .. primary] = nil

    if not FAM.applyAmputationVisual(patient, primary) then
        FAM.removeProstheticVisuals(patient, FAM.getSideFromLimbName(primary))
    end
    if patient.transmitModData then
        patient:transmitModData()
    end

    FAM.reduceSystemicCondition(patient, "FAM_ShockLoad", 2)
    FAM.syncPlayerEffects(patient)
    FAM.recordProviderOutcome(doctor, patient, {
        action = "remove_prosthetic",
        category = "fam",
        bodyPart = primary or "Unknown",
        injuryFixed = false,
        saved = false,
        advanced = true,
        prosthetic = true,
        signature = "remove_prosthetic:" .. FAM.getCharacterKey(patient) .. ":" .. tostring(primary) .. ":" .. tostring(math.floor(FAM.getWorldAgeHours() * 10)),
    })
    return true
end

function FAM.getConditionLoad(patient)
    if not patient then return 0 end
    local bodyDamage = FAM.getBodyDamage(patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return 0 end
    local data = patient:getModData()
    local load = (tonumber(data.FAM_SepsisLoad) or 0)
        + (tonumber(data.FAM_ShockLoad) or 0)
        + ((tonumber(data.FAM_LocalInfectionLoad) or 0) * 0.7)
        + ((tonumber(data.FAM_PathogenLoad) or 0) * 0.6)
        + ((tonumber(data.FAM_CorpseExposureLoad) or 0) * 0.35)
        + ((tonumber(data.FAM_PandemicLoad) or 0) * 0.8)
    local bloodDeficit = math.max(0, FAM.BLOOD.LOW_PERCENT - FAM.getBloodPercent(patient))
    load = load + (bloodDeficit * 1.25)
    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        load = load + FAM.getGangrene(patient, bodyPart)
        load = load + math.min(FAM.getBulletHours(patient, bodyPart), FAM.CONDITION.BULLET_CRITICAL_HOURS)
        if FAM.isAmputationIndicated(patient, bodyPart) then
            load = load + 35
        end
    end
    return FAM.clamp(load / 3, 0, 100)
end

function FAM.getCorpseExposureLoad(character)
    if not character then return 0 end
    return tonumber(character:getModData().FAM_CorpseExposureLoad) or 0
end

function FAM.getPathogenLoad(character)
    if not character then return 0 end
    return tonumber(character:getModData().FAM_PathogenLoad) or 0
end

function FAM.getNearbyCorpseCount(character)
    if not character then return 0 end
    return tonumber(character:getModData().FAM_NearbyCorpseCount) or 0
end

function FAM.refreshCorpseExposureDisplay(character)
    if not character then return end
    local count = FAM.countNearbyCorpses(character)
    character:getModData().FAM_NearbyCorpseCount = count > 0 and count or nil
end

local function recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, key, label, active)
    if not active then return end
    activeSignals[key] = true
    analytics.labels[key] = label
    if previousSignals[key] ~= true then
        analytics.counts[key] = (tonumber(analytics.counts[key]) or 0) + 1
        analytics.lastSeen[key] = timestamp
    end
end

function FAM.updatePatientAnalytics(character)
    if not character then return nil end
    local analytics = FAM.getPatientAnalytics(character)
    local previousSignals = analytics.lastSignals or {}
    local activeSignals = {}
    local timestamp = FAM.getNoteTimestamp()
    local sepsis = tonumber(character:getModData().FAM_SepsisLoad) or 0
    local shock = tonumber(character:getModData().FAM_ShockLoad) or 0
    local poison = FAM.getPoisonLevel(character)
    local sickness = FAM.getSicknessLevel(character)
    local cold = FAM.getColdStressPercent(character)
    local corpseExposure = FAM.getCorpseExposureLoad(character)
    local pathogen = FAM.getPathogenLoad(character)
    local temperatureRisk = FAM.getTemperatureDeviationPercent(character)
    local conditionLoad = FAM.getConditionLoad(character)
    local bloodPercent = FAM.getBloodPercent(character)
    local fluidSupport = FAM.getFluidSupportHours(character)
    local localInfection = FAM.getLocalInfectionLoad(character)
    local csr = FAM.getCSRStatus(character)
    local csrSupport = tonumber(character:getModData().FAM_CSR_AntibodySupportHours) or 0

    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:sickness", "Sickness", sickness >= 20)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:toxicity", "Toxicity", poison >= 20)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:cold", "Cold", cold >= 20)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:temperature", "Temperature deviation", temperatureRisk >= 25)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:condition_load", "High FAM load", conditionLoad >= 40)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:blood_low", "Low blood reserve", bloodPercent < FAM.BLOOD.LOW_PERCENT)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:blood_critical", "Critical blood reserve", bloodPercent < FAM.BLOOD.CRITICAL_PERCENT)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:fluid_support", "Vascular support active", fluidSupport > 0)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:csr_support", "CSR antibody support", csrSupport > 0)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:csr_crisis", "CSR crisis", csr.crisis == true)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:corpse_exposure", "Corpse exposure", corpseExposure >= FAM.CONDITION.CORPSE_EXPOSURE_SUSPECT)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:pathogen", "Pathogen load", pathogen >= FAM.CONDITION.PATHOGEN_ELEVATED)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:sepsis", "Sepsis risk", sepsis >= 25)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:sepsis_critical", "Critical sepsis risk", sepsis >= FAM.CONDITION.SEPSIS_CRITICAL)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:shock", "Shock risk", shock >= 25)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:local_infection", "Local infection pressure", localInfection >= FAM.CONDITION.LOCAL_INFECTION_SUSPECT)
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:pandemic", "Pandemic sickness", FAM.isPandemicInfected(character))
    recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "system:pandemic_super_carrier", "Pandemic super carrier", FAM.isPandemicSuperCarrier(character))
    if FAM.isPandemicInfected(character) then
        local diseaseId = FAM.getPandemicDiseaseId(character)
        local profile = FAM.getDiseaseProfile(diseaseId)
        recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "disease:" .. diseaseId, famText(profile.labelKey, diseaseId), true)
    end

    local substances = FAM.scanSubstances(character)
    for i = 1, math.min(#substances, 8) do
        local row = substances[i]
        recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, "substance:" .. row.key, row.label, true)
    end

    local bodyDamage = FAM.getBodyDamage(character)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if bodyParts then
        for i = 1, bodyParts:size() do
            local bodyPart = bodyParts:get(i - 1)
            local partName = FAM.getBodyPartName(bodyPart) or "Unknown"
            local prefix = "part:" .. partName .. ":"
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "bleeding", "Bleeding - " .. partName, bodyPart:bleeding() or bodyPart:getBleedingTime() > 0)
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "burn", "Burn - " .. partName, bodyPart:getBurnTime() > 0)
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "bite", "Bite - " .. partName, bodyPart:bitten())
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "scratch", "Scratch - " .. partName, bodyPart:scratched())
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "laceration", "Laceration - " .. partName, bodyPart:isCut())
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "fracture", "Fracture - " .. partName, bodyPart:getFractureTime() > 0)
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "deep_wound", "Deep wound - " .. partName, bodyPart:getDeepWoundTime() > 0)
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "glass", "Glass - " .. partName, bodyPart:haveGlass())
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "bullet", "Embedded bullet - " .. partName, bodyPart:haveBullet())
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "infected", "Infected wound - " .. partName, bodyPart:isInfectedWound())
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "gangrene", "Gangrene - " .. partName, FAM.getGangrene(character, bodyPart) >= FAM.CONDITION.GANGRENE_SUSPECT)
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "amputation_indicated", "Amputation indicated - " .. partName, FAM.isAmputationIndicated(character, bodyPart))
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "amputation", "Amputation - " .. partName, FAM.hasAmputation(character, bodyPart))
            recordAnalyticsSignal(analytics, previousSignals, activeSignals, timestamp, prefix .. "prosthetic", "Prosthetic - " .. partName, FAM.hasProsthetic(character, bodyPart))
        end
    end

    analytics.lastSignals = activeSignals
    analytics.observations = (tonumber(analytics.observations) or 0) + 1
    analytics.updatedAt = timestamp
    return analytics
end

function FAM.getTriageAlertLevel(character)
    if not character then return 0, nil end
    local level = math.max(
        FAM.getConditionLoad(character),
        FAM.getPoisonLevel(character),
        FAM.getSicknessLevel(character),
        FAM.getColdStressPercent(character),
        FAM.getTemperatureDeviationPercent(character),
        tonumber(character:getModData().FAM_SepsisLoad) or 0,
        tonumber(character:getModData().FAM_ShockLoad) or 0,
        FAM.getLocalInfectionLoad(character),
        FAM.getCorpseExposureLoad(character),
        FAM.getPathogenLoad(character),
        FAM.getPandemicLoad(character)
    )
    local csr = FAM.getCSRStatus(character)
    if csr.crisis then
        level = math.max(level, 75)
    elseif csr.active then
        level = math.max(level, 12)
    end
    if FAM.getLocalInfectionLoad(character) >= FAM.CONDITION.LOCAL_INFECTION_CONFIRMED then
        level = math.max(level, 42)
    end
    if FAM.getCorpseExposureLoad(character) >= FAM.CONDITION.CORPSE_EXPOSURE_SUSPECT then
        level = math.max(level, 25)
    end
    if FAM.getPathogenLoad(character) >= FAM.CONDITION.PATHOGEN_ELEVATED then
        level = math.max(level, 25)
    end
    local bloodPercent = FAM.getBloodPercent(character)
    if bloodPercent < FAM.BLOOD.LOW_PERCENT then
        level = math.max(level, FAM.clamp((FAM.BLOOD.LOW_PERCENT - bloodPercent) * 2.2, 25, 100))
    end
    if FAM.isPandemicInfected(character) then
        level = math.max(level, 55)
    end

    local bodyDamage = FAM.getBodyDamage(character)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if bodyParts then
        for i = 1, bodyParts:size() do
            level = math.max(level, FAM.bodyPartClinicalSeverity(character, bodyParts:get(i - 1)))
        end
    end

    if level >= 70 then
        return 2, "critical"
    end
    if level >= 25 then
        return 1, "warning"
    end
    return 0, nil
end

function FAM.isPandemicInfected(character)
    return character ~= nil and character:getModData().FAM_PandemicInfected == true
end

function FAM.getPandemicLoad(character)
    if not character then return 0 end
    return tonumber(character:getModData().FAM_PandemicLoad) or 0
end

function FAM.getPandemicQuarantineHours(character)
    if not character then return 0 end
    return tonumber(character:getModData().FAM_PandemicQuarantineHours) or 0
end

function FAM.getPandemicTreatedHours(character)
    if not character then return 0 end
    return tonumber(character:getModData().FAM_PandemicTreatedHours) or 0
end

function FAM.getDiseaseProfile(diseaseId)
    return FAM.DISEASES[diseaseId] or FAM.DISEASES[FAM.DEFAULT_PANDEMIC_DISEASE]
end

function FAM.getPandemicDiseaseId(character)
    if not character then return FAM.DEFAULT_PANDEMIC_DISEASE end
    local diseaseId = character:getModData().FAM_PandemicDiseaseId
    if diseaseId and FAM.DISEASES[diseaseId] then
        return diseaseId
    end
    return FAM.DEFAULT_PANDEMIC_DISEASE
end

function FAM.getPandemicDiseaseProfile(character)
    return FAM.getDiseaseProfile(FAM.getPandemicDiseaseId(character))
end

function FAM.getPandemicDiseaseName(character, observer)
    local profile = FAM.getPandemicDiseaseProfile(character)
    if profile and profile.silent
        and FAM.getPandemicLoad(character) < 55
        and not FAM.hasAdvancedClinicalAccess(observer) then
        return famText("IGUI_FAM_Disease_SilentSignal", "untyped viral signal")
    end
    return famText(profile and profile.labelKey, "Unknown pathogen")
end

function FAM.getPandemicTreatmentText(character)
    if not character or not FAM.isPandemicInfected(character) then
        return famText("IGUI_FAM_DiseaseTreatment_None", "No active disease treatment.")
    end
    local profile = FAM.getPandemicDiseaseProfile(character)
    return famText(profile and profile.treatmentKey, "Supportive care, isolation, and monitoring.")
end

function FAM.isPandemicSuperCarrier(character)
    return character ~= nil and character:getModData().FAM_PandemicSuperCarrier == true
end

function FAM.getPandemicContagion(character)
    if not character or not FAM.isPandemicInfected(character) then return 0 end
    local profile = FAM.getPandemicDiseaseProfile(character)
    local multiplier = FAM.isPandemicSuperCarrier(character) and 2.35 or 1
    local quarantine = FAM.getPandemicQuarantineHours(character) > 0 and 0.2 or 1
    return FAM.clamp((tonumber(profile.contagion) or 35) * multiplier * quarantine, 0, 100)
end

function FAM.chooseRarePandemicDisease()
    local total = 0
    for _, profile in pairs(FAM.DISEASES) do
        total = total + (tonumber(profile.rareWeight) or 0)
    end
    if total <= 0 or not ZombRand then
        return FAM.DEFAULT_PANDEMIC_DISEASE
    end
    local roll = ZombRand(total)
    local cursor = 0
    for diseaseId, profile in pairs(FAM.DISEASES) do
        cursor = cursor + (tonumber(profile.rareWeight) or 0)
        if roll < cursor then
            return diseaseId
        end
    end
    return FAM.DEFAULT_PANDEMIC_DISEASE
end

function FAM.startPandemicInfection(character, source, load, diseaseId)
    if not character then return false end
    local data = character:getModData()
    if data.FAM_PandemicImmuneHours and tonumber(data.FAM_PandemicImmuneHours) > 0 then
        return false
    end
    diseaseId = FAM.DISEASES[diseaseId] and diseaseId or FAM.DEFAULT_PANDEMIC_DISEASE
    local profile = FAM.getDiseaseProfile(diseaseId)
    data.FAM_PandemicInfected = true
    data.FAM_PandemicSource = source or data.FAM_PandemicSource or "unknown"
    data.FAM_PandemicDiseaseId = diseaseId
    data.FAM_PandemicLoad = math.max(tonumber(data.FAM_PandemicLoad) or 0, load or 28)
    data.FAM_PandemicCaseStarted = data.FAM_PandemicCaseStarted or FAM.getNoteTimestamp()
    data.FAM_PandemicCaseCount = (tonumber(data.FAM_PandemicCaseCount) or 0) + 1
    local superChance = tonumber(profile.superCarrierChance) or FAM.PANDEMIC.SUPER_CARRIER_CHANCE
    if data.FAM_PandemicSuperCarrier == nil and ZombRand and ZombRand(100) < superChance then
        data.FAM_PandemicSuperCarrier = true
    end
    FAM.addSicknessLevel(character, math.max(3, math.floor((tonumber(profile.severity) or 40) / 10)))
    if character.transmitModData then
        character:transmitModData()
    end
    return true
end

function FAM.reducePandemicLoad(character, amount)
    if not character then return false end
    local data = character:getModData()
    local load = math.max(0, (tonumber(data.FAM_PandemicLoad) or 0) - (amount or 0))
    data.FAM_PandemicLoad = load > 0 and load or nil
    if load <= 0 and data.FAM_PandemicInfected then
        data.FAM_PandemicInfected = nil
        data.FAM_PandemicSource = nil
        data.FAM_PandemicDiseaseId = nil
        data.FAM_PandemicSuperCarrier = nil
        data.FAM_HollowVeilBlurHours = nil
        data.FAM_HollowVeilDeafHours = nil
        data.FAM_PandemicCaseResolved = FAM.getNoteTimestamp()
        data.FAM_PandemicImmuneHours = FAM.PANDEMIC.IMMUNITY_HOURS
    end
    if character.transmitModData then
        character:transmitModData()
    end
    return true
end

function FAM.reducePandemicLoadByTreatment(character, amount, treatmentKind)
    if not character or not FAM.isPandemicInfected(character) then return false end
    local profile = FAM.getPandemicDiseaseProfile(character)
    local key = tostring(treatmentKind or "support") .. "Multiplier"
    local multiplier = tonumber(profile[key]) or 1
    return FAM.reducePandemicLoad(character, math.max(1, math.floor((amount or 0) * multiplier)))
end

function FAM.setPandemicQuarantine(doctor, patient, enabled)
    if not patient then return false end
    local data = patient:getModData()
    if enabled then
        data.FAM_PandemicQuarantineHours = math.max(tonumber(data.FAM_PandemicQuarantineHours) or 0, FAM.PANDEMIC.QUARANTINE_HOURS)
        FAM.recordProviderOutcome(doctor, patient, {
            action = "pandemic_quarantine",
            category = "pandemic",
            injuryFixed = false,
            quarantine = true,
            pandemic = true,
            signature = "pandemic_quarantine:" .. FAM.getCharacterKey(patient) .. ":" .. tostring(math.floor(FAM.getWorldAgeHours())),
        })
    else
        data.FAM_PandemicQuarantineHours = nil
    end
    if patient.transmitModData then
        patient:transmitModData()
    end
    return true
end

function FAM.treatPandemicCase(doctor, patient)
    if not patient or not FAM.isPandemicInfected(patient) then return false end
    if doctor and FAM.getDoctorLevel(doctor) < 4 and not FAM.hasAdvancedClinicalAccess(doctor) then
        return false
    end
    local data = patient:getModData()
    data.FAM_PandemicTreatedHours = math.max(tonumber(data.FAM_PandemicTreatedHours) or 0, FAM.PANDEMIC.TREATMENT_HOURS)
    FAM.reducePandemicLoadByTreatment(patient, 22 + (FAM.getEffectiveDoctorLevel(doctor) * 2), "antibiotic")
    FAM.reduceSicknessLevel(patient, 10 + FAM.getEffectiveDoctorLevel(doctor))
    FAM.recordProviderOutcome(doctor, patient, {
        action = "pandemic_treatment",
        category = "pandemic",
        injuryFixed = true,
        saved = FAM.getPandemicLoad(patient) <= 15,
        pandemic = true,
        advanced = true,
        signature = "pandemic_treatment:" .. FAM.getCharacterKey(patient) .. ":" .. tostring(math.floor(FAM.getWorldAgeHours())),
    })
    return true
end

local function forEachFamPlayer(callback)
    if getOnlinePlayers then
        local players = getOnlinePlayers()
        if players then
            for i = 1, players:size() do
                callback(players:get(i - 1))
            end
            return
        end
    end
    if getNumActivePlayers then
        for i = 0, getNumActivePlayers() - 1 do
            callback(getSpecificPlayer(i))
        end
        return
    end
    if getPlayer then
        callback(getPlayer())
    end
end

local function spreadPandemicFrom(source)
    if not source or not source.getX then return end
    local sourceData = source:getModData()
    local sourceLoad = tonumber(sourceData.FAM_PandemicLoad) or 0
    if sourceLoad <= 0 then return end
    local diseaseId = FAM.getPandemicDiseaseId(source)
    local profile = FAM.getDiseaseProfile(diseaseId)
    local radius = tonumber(profile.spreadRadius) or FAM.PANDEMIC.SPREAD_RADIUS
    local contagion = FAM.getPandemicContagion(source)
    local quarantineMultiplier = (tonumber(sourceData.FAM_PandemicQuarantineHours) or 0) > 0 and 0.2 or 1
    forEachFamPlayer(function(target)
        if target and target ~= source and target.getX and not FAM.isPandemicInfected(target) then
            local sameLevel = not target.getZ or not source.getZ or target:getZ() == source:getZ()
            local dx = math.abs(target:getX() - source:getX())
            local dy = math.abs(target:getY() - source:getY())
            local distance = math.max(dx, dy)
            if sameLevel and distance <= radius then
                local targetData = target:getModData()
                local protected = (tonumber(targetData.FAM_PandemicImmuneHours) or 0) > 0
                    or (tonumber(targetData.FAM_PandemicQuarantineHours) or 0) > 0
                if not protected and ZombRand then
                    local distancePressure = 1 + ((radius - distance) / math.max(1, radius))
                    local woundBonus = profile.openWoundBonus and FAM.getLocalInfectionLoad(target) > 0 and profile.openWoundBonus or 0
                    local chance = math.floor(((sourceLoad / 12) * (contagion / 45) * distancePressure * quarantineMultiplier) + woundBonus)
                    if chance > 0 and ZombRand(100) < chance then
                        FAM.startPandemicInfection(target, FAM.getCharacterKey(source), 24 + math.floor(sourceLoad * 0.25), diseaseId)
                    end
                end
            end
        end
    end)
end

local function pulseTemperature(character, target, strength)
    if not character or not character.getTemperature or not character.setTemperature then return end
    local current = tonumber(character:getTemperature()) or 37
    character:setTemperature(current + ((target - current) * (strength or 0.35)))
end

local function applyHollowVeilSymptoms(character, load)
    local data = character:getModData()
    if load < 18 or not ZombRand then return end
    if load >= 28 and ZombRand(100) < 34 then
        data.FAM_HollowVeilBlurHours = math.max(tonumber(data.FAM_HollowVeilBlurHours) or 0, 1)
    end
    if load >= 36 and ZombRand(100) < 24 then
        data.FAM_HollowVeilDeafHours = math.max(tonumber(data.FAM_HollowVeilDeafHours) or 0, 1)
    end
    if ZombRand(100) < 50 then
        local bodyDamage = FAM.getBodyDamage(character)
        if bodyDamage and bodyDamage.setColdStrength and bodyDamage.getColdStrength then
            bodyDamage:setColdStrength(math.max(tonumber(bodyDamage:getColdStrength()) or 0, 25 + math.floor(load * 0.35)))
        end
        pulseTemperature(character, 35.2, 0.4)
    else
        pulseTemperature(character, 39.6, 0.45)
        FAM.addSicknessLevel(character, 2 + math.floor(load / 35))
    end
    FAM.addStat(character, "PANIC", 10 + math.floor(load / 5))
    FAM.addStat(character, "STRESS", 0.08 + (load / 800))
    FAM.addStat(character, "FATIGUE", 0.03 + (load / 2000))
end

local function applyPandemicDiseaseSymptoms(character, diseaseId, load)
    local profile = FAM.getDiseaseProfile(diseaseId)
    if diseaseId == FAM.CORPSE_VIRUS_DISEASE then
        applyHollowVeilSymptoms(character, load)
        return
    end
    if not ZombRand then return end
    local severity = tonumber(profile.severity) or 40
    if load >= 35 and ZombRand(100) < math.floor(severity / 3) then
        FAM.addSicknessLevel(character, math.max(1, math.floor(severity / 28)))
        FAM.addStat(character, "FATIGUE", math.min(0.12, severity / 900))
    end
    if diseaseId == "influenza_like" and load >= 28 then
        local bodyDamage = FAM.getBodyDamage(character)
        if bodyDamage and bodyDamage.setHasACold and bodyDamage.setColdStrength and ZombRand(100) < 40 then
            bodyDamage:setHasACold(true)
            bodyDamage:setColdStrength(math.max(bodyDamage.getColdStrength and bodyDamage:getColdStrength() or 0, 12 + math.floor(load / 4)))
        end
    elseif diseaseId == "gastroenteritis" and load >= 35 then
        FAM.addPoisonLevel(character, 2 + math.floor(load / 30))
        FAM.addStat(character, "THIRST", 0.04)
    elseif diseaseId == "bacterial_wound_fever" and load >= 30 then
        local data = character:getModData()
        data.FAM_ShockLoad = FAM.clamp((tonumber(data.FAM_ShockLoad) or 0) + 2, 0, 100)
        data.FAM_LocalInfectionLoad = FAM.clamp(FAM.getLocalInfectionLoad(character) + 3, 0, 100)
    end
end

function FAM.updatePandemicForCharacter(character)
    if not character then return end
    if isClient and isClient() then return end
    local data = character:getModData()
    local changed = false
    local counters = {
        "FAM_PandemicQuarantineHours",
        "FAM_PandemicTreatedHours",
        "FAM_PandemicImmuneHours",
    }
    for i = 1, #counters do
        local key = counters[i]
        if tonumber(data[key]) then
            data[key] = tonumber(data[key]) - 1
            if data[key] <= 0 then
                data[key] = nil
            end
            changed = true
        end
    end

    if data.FAM_PandemicInfected then
        local diseaseId = FAM.getPandemicDiseaseId(character)
        local profile = FAM.getDiseaseProfile(diseaseId)
        data.FAM_PandemicDiseaseId = diseaseId
        local load = tonumber(data.FAM_PandemicLoad) or 25
        local treated = (tonumber(data.FAM_PandemicTreatedHours) or 0) > 0
        local quarantined = (tonumber(data.FAM_PandemicQuarantineHours) or 0) > 0
        if treated then
            load = load - math.max(8, math.floor((18 * (tonumber(profile.antibioticMultiplier) or 1))))
        elseif quarantined then
            load = load - 6
        else
            load = load + math.max(3, math.floor((tonumber(profile.severity) or 42) / 10))
        end
        data.FAM_PandemicLoad = FAM.clamp(load, 0, 100)
        FAM.addSicknessLevel(character, data.FAM_PandemicLoad >= 45 and math.max(3, math.floor((tonumber(profile.severity) or 42) / 18)) or 2)
        applyPandemicDiseaseSymptoms(character, diseaseId, data.FAM_PandemicLoad)
        if data.FAM_PandemicLoad <= 0 then
            FAM.reducePandemicLoad(character, 999)
        else
            spreadPandemicFrom(character)
        end
        changed = true
    elseif ZombRand and (tonumber(data.FAM_PandemicImmuneHours) or 0) <= 0 and ZombRand(10000) < FAM.PANDEMIC.RARE_ROLL_PER_10K then
        FAM.startPandemicInfection(character, "rare_event", 30, FAM.chooseRarePandemicDisease())
        changed = true
    end

    if changed and character.transmitModData then
        character:transmitModData()
    end
end

function FAM.getPandemicStatus()
    local status = {
        activeCases = 0,
        quarantined = 0,
        treated = 0,
        totalCases = 0,
        population = 0,
        alert = 0,
        rows = {},
    }
    forEachFamPlayer(function(player)
        if not player then return end
        status.population = status.population + 1
        local data = player:getModData()
        local active = data.FAM_PandemicInfected == true
        local load = tonumber(data.FAM_PandemicLoad) or 0
        local quarantine = tonumber(data.FAM_PandemicQuarantineHours) or 0
        local treated = tonumber(data.FAM_PandemicTreatedHours) or 0
        status.totalCases = status.totalCases + (tonumber(data.FAM_PandemicCaseCount) or 0)
        if active then status.activeCases = status.activeCases + 1 end
        if quarantine > 0 then status.quarantined = status.quarantined + 1 end
        if treated > 0 then status.treated = status.treated + 1 end
        table.insert(status.rows, {
            name = player.getDisplayName and player:getDisplayName() or "?",
            active = active,
            load = load,
            disease = active and FAM.getPandemicDiseaseName(player) or famText("IGUI_FAM_Disease_Clear", "clear"),
            contagion = FAM.getPandemicContagion(player),
            superCarrier = FAM.isPandemicSuperCarrier(player),
            quarantine = quarantine,
            treated = treated,
            cases = tonumber(data.FAM_PandemicCaseCount) or 0,
        })
    end)
    status.alert = FAM.clamp((status.activeCases * FAM.PANDEMIC.ALERT_PER_ACTIVE_CASE) + (status.totalCases * FAM.PANDEMIC.ALERT_PER_TOTAL_CASE), 0, 100)
    table.sort(status.rows, function(a, b)
        if a.active == b.active then
            return a.load > b.load
        end
        return a.active == true
    end)
    return status
end

function FAM.hasOpenContaminationRoute(bodyPart)
    if not bodyPart then return false end
    return bodyPart:bleeding()
        or bodyPart:getDeepWoundTime() > 0
        or bodyPart:getBurnTime() > 0
        or bodyPart:haveGlass()
        or bodyPart:haveBullet()
        or bodyPart:bitten()
        or bodyPart:scratched()
        or bodyPart:isCut()
        or bodyPart:isInfectedWound()
end

function FAM.getCorpseImpactMultiplier()
    local value = SandboxVars and tonumber(SandboxVars.DecayingCorpseHealthImpact) or nil
    if value == 1 then return 0 end
    if value == 2 then return 0.6 end
    if value == 4 then return 1.35 end
    return 1
end

local function getCorpseWeight(body)
    if body and body.isAnimal and body:isAnimal() then
        if body.isAnimalSkeleton and body:isAnimalSkeleton() then return 0 end
        return 0.25
    end
    return 1
end

function FAM.countCorpsesOnSquare(square)
    if not square then return 0 end
    local count = 0
    if square.getDeadBodys then
        local bodies = square:getDeadBodys()
        if bodies then
            for i = 0, bodies:size() - 1 do
                count = count + getCorpseWeight(bodies:get(i))
            end
            return count
        end
    end
    if square.getStaticMovingObjects then
        local objects = square:getStaticMovingObjects()
        if objects then
            for i = 0, objects:size() - 1 do
                local object = objects:get(i)
                if instanceof and instanceof(object, "IsoDeadBody") then
                    count = count + getCorpseWeight(object)
                end
            end
        end
    end
    return count
end

function FAM.countNearbyCorpses(character)
    local square = character and character:getSquare()
    local cell = getCell and getCell() or nil
    if not square or not cell then return 0, 0 end

    local radius = FAM.CONDITION.CORPSE_SCAN_RADIUS
    local baseX = square:getX()
    local baseY = square:getY()
    local z = square:getZ()
    local count = 0
    local weighted = 0

    for x = baseX - radius, baseX + radius do
        for y = baseY - radius, baseY + radius do
            local distance = IsoUtils and IsoUtils.DistanceTo(baseX + 0.5, baseY + 0.5, x + 0.5, y + 0.5) or math.sqrt(((baseX - x) * (baseX - x)) + ((baseY - y) * (baseY - y)))
            if distance <= radius then
                local targetSquare = cell:getGridSquare(x, y, z)
                local squareCount = FAM.countCorpsesOnSquare(targetSquare)
                if squareCount > 0 then
                    count = count + squareCount
                    weighted = weighted + (squareCount * (1 - (distance / (radius + 1)) * 0.45))
                end
            end
        end
    end

    if character.isDraggingCorpse and character:isDraggingCorpse() then
        count = count + 1
        weighted = weighted + 2.5
    end

    return count, weighted
end

function FAM.updateCorpseExposure(character)
    if not character then return end
    local data = character:getModData()
    local impact = FAM.getCorpseImpactMultiplier()
    local count, weighted = FAM.countNearbyCorpses(character)
    local exposure = tonumber(data.FAM_CorpseExposureLoad) or 0
    local pathogen = tonumber(data.FAM_PathogenLoad) or 0
    local sanitationHours = tonumber(data.FAM_SanitationHours) or 0

    if impact <= 0 then
        exposure = math.max(0, exposure - 18)
        pathogen = math.max(0, pathogen - 8)
    elseif weighted > 0 then
        local pressure = FAM.clamp(weighted * 11 * impact, 0, 100)
        if sanitationHours > 0 then
            pressure = pressure * 0.35
        end
        exposure = FAM.clamp(exposure + (pressure * 0.35), 0, 100)
        if exposure >= FAM.CONDITION.CORPSE_EXPOSURE_SUSPECT then
            pathogen = FAM.clamp(pathogen + ((exposure - FAM.CONDITION.CORPSE_EXPOSURE_SUSPECT) / 10), 0, 100)
        end
    else
        exposure = math.max(0, exposure - (sanitationHours > 0 and 18 or 10))
        pathogen = math.max(0, pathogen - (sanitationHours > 0 and 9 or 4))
    end

    data.FAM_NearbyCorpseCount = count > 0 and count or nil
    data.FAM_CorpseExposureLoad = exposure > 0 and exposure or nil
    data.FAM_PathogenLoad = pathogen > 0 and pathogen or nil

    if not (isClient and isClient())
        and impact > 0
        and sanitationHours <= 0
        and not FAM.isPandemicInfected(character)
        and (tonumber(data.FAM_PandemicImmuneHours) or 0) <= 0
        and exposure >= FAM.PANDEMIC.CORPSE_VIRUS_EXPOSURE
        and pathogen >= FAM.PANDEMIC.CORPSE_VIRUS_PATHOGEN
        and ZombRand then
        local chance = 12
            + math.floor(math.max(0, count - 1) * 2)
            + math.floor((exposure - FAM.PANDEMIC.CORPSE_VIRUS_EXPOSURE) / 3)
            + math.floor((pathogen - FAM.PANDEMIC.CORPSE_VIRUS_PATHOGEN) / 4)
        if ZombRand(100) < FAM.clamp(chance, 8, 65) then
            FAM.startPandemicInfection(character, "corpse_exposure", 34 + math.floor(pathogen / 4), FAM.CORPSE_VIRUS_DISEASE)
        end
    end
end

local function getPartRiskIncrement(patient, bodyPart)
    local risk = 0
    local data = patient:getModData()
    local tourniquetKey = "FAM_Tourniquet_" .. tostring(bodyPart:getIndex())
    local bulletHours = FAM.getBulletHours(patient, bodyPart)

    if data[tourniquetKey] == -1 then risk = risk + 8 end
    if bodyPart:isInfectedWound() then risk = risk + 5 end
    if bodyPart.getWoundInfectionLevel and bodyPart:getWoundInfectionLevel() > 10 then risk = risk + 3 end
    if bodyPart:getDeepWoundTime() > 24 then risk = risk + 2 end
    if bodyPart:getBurnTime() > 30 then risk = risk + 2 end
    if bodyPart:haveGlass() then risk = risk + 1 end
    if bulletHours >= FAM.CONDITION.BULLET_DEEP_HOURS then risk = risk + 3 end
    if bulletHours >= FAM.CONDITION.BULLET_CRITICAL_HOURS then risk = risk + 7 end
    if FAM.hasOpenContaminationRoute(bodyPart) and (tonumber(FAM.getPartValue(patient, bodyPart, "SanitationHours", 0)) or 0) <= 0 then
        local pathogen = FAM.getPathogenLoad(patient)
        if pathogen >= FAM.CONDITION.PATHOGEN_ELEVATED then
            risk = risk + ((pathogen - FAM.CONDITION.PATHOGEN_ELEVATED) / 16)
        end
    end
    return risk
end

function FAM.updatePartCondition(patient, bodyPart)
    if not patient or not bodyPart then return end
    local data = patient:getModData()
    local bulletHours = FAM.getBulletHours(patient, bodyPart)

    if bodyPart:haveBullet() then
        bulletHours = bulletHours + 1
        FAM.setPartValue(patient, bodyPart, "BulletHours", bulletHours)
    else
        bulletHours = 0
        FAM.clearPartValue(patient, bodyPart, "BulletHours")
    end

    local risk = getPartRiskIncrement(patient, bodyPart)
    local gangrene = FAM.getGangrene(patient, bodyPart)
    local careHours = tonumber(FAM.getPartValue(patient, bodyPart, "StumpCareHours", 0)) or 0
    local sanitationHours = tonumber(FAM.getPartValue(patient, bodyPart, "SanitationHours", 0)) or 0
    local antibioticPower = tonumber(data.FAM_CSR_AntibodySupportPower) or 0

    if risk > 0 then
        if sanitationHours > 0 then risk = math.max(0, risk - 3) end
        gangrene = gangrene + risk
    else
        local recovery = 1 + antibioticPower
        if bodyPart:bandaged() then recovery = recovery + 1 end
        if bodyPart:stitched() then recovery = recovery + 1 end
        if careHours > 0 then recovery = recovery + 4 end
        if sanitationHours > 0 then recovery = recovery + 2 end
        gangrene = gangrene - recovery
    end
    if antibioticPower > 0 and gangrene > 0 then
        gangrene = gangrene - antibioticPower
    end

    FAM.setGangrene(patient, bodyPart, gangrene)

    local indicatesAmputation = FAM.isAmputatableLimb(bodyPart)
        and (FAM.getGangrene(patient, bodyPart) >= FAM.CONDITION.GANGRENE_CRITICAL or bulletHours >= FAM.CONDITION.BULLET_CRITICAL_HOURS)
    FAM.setPartValue(patient, bodyPart, "AmputationIndicated", indicatesAmputation and true or nil)

    if careHours > 0 then
        careHours = careHours - 1
        if careHours <= 0 then
            FAM.clearPartValue(patient, bodyPart, "StumpCareHours")
        else
            FAM.setPartValue(patient, bodyPart, "StumpCareHours", careHours)
        end
    end

    if sanitationHours > 0 then
        sanitationHours = sanitationHours - 1
        if sanitationHours <= 0 then
            FAM.clearPartValue(patient, bodyPart, "SanitationHours")
        else
            FAM.setPartValue(patient, bodyPart, "SanitationHours", sanitationHours)
        end
    end
end

function FAM.applyWoundCareQuality(patient, bodyPart, quality, hours)
    if not patient or not bodyPart then return end
    quality = FAM.clamp(quality or 0, 0, 100)
    if quality <= 0 then return end
    FAM.setPartValue(patient, bodyPart, "WoundCareQuality", math.max(tonumber(FAM.getPartValue(patient, bodyPart, "WoundCareQuality", 0)) or 0, quality))
    FAM.setPartValue(patient, bodyPart, "WoundCareHours", math.max(tonumber(FAM.getPartValue(patient, bodyPart, "WoundCareHours", 0)) or 0, hours or 8))
end

function FAM.updateWoundInfectionProgression(character)
    if not character then return end
    local bodyDamage = FAM.getBodyDamage(character)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return end
    local data = character:getModData()
    local csrPower = tonumber(data.FAM_CSR_AntibodySupportPower) or 0
    local infectionLoad = tonumber(data.FAM_LocalInfectionLoad) or 0
    local activePressure = 0
    local careRecovery = 0

    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        local openRoute = FAM.hasOpenContaminationRoute(bodyPart)
        local infected = bodyPart:isInfectedWound()
        local woundLevel = bodyPart.getWoundInfectionLevel and math.max(0, tonumber(bodyPart:getWoundInfectionLevel()) or 0) or 0
        local careQuality = tonumber(FAM.getPartValue(character, bodyPart, "WoundCareQuality", 0)) or 0
        local careHours = tonumber(FAM.getPartValue(character, bodyPart, "WoundCareHours", 0)) or 0
        local sanitationHours = tonumber(FAM.getPartValue(character, bodyPart, "SanitationHours", 0)) or 0
        local pressure = 0

        if infected or woundLevel > 0 then
            pressure = pressure + 5 + (woundLevel / 12)
        elseif openRoute and FAM.getPathogenLoad(character) >= FAM.CONDITION.PATHOGEN_ELEVATED then
            pressure = pressure + 2 + ((FAM.getPathogenLoad(character) - FAM.CONDITION.PATHOGEN_ELEVATED) / 18)
        end
        if bodyPart:bitten() then pressure = pressure + 2 end
        if sanitationHours > 0 then pressure = pressure - 4 end
        if careHours > 0 then pressure = pressure - math.min(6, careQuality / 14) end
        if csrPower > 0 then pressure = pressure - (2 + csrPower) end

        pressure = math.max(0, pressure)
        activePressure = activePressure + pressure
        if pressure <= 0 and (careHours > 0 or sanitationHours > 0) then
            careRecovery = math.max(careRecovery, 1 + math.min(2, careQuality / 40) + (sanitationHours > 0 and 1 or 0))
        end

        if careHours > 0 then
            careHours = careHours - 1
            if careHours <= 0 then
                FAM.clearPartValue(character, bodyPart, "WoundCareHours")
            else
                FAM.setPartValue(character, bodyPart, "WoundCareHours", careHours)
            end
        end
        if careQuality > 0 then
            careQuality = math.max(0, careQuality - 8)
            if careQuality <= 0 then
                FAM.clearPartValue(character, bodyPart, "WoundCareQuality")
            else
                FAM.setPartValue(character, bodyPart, "WoundCareQuality", careQuality)
            end
        end
    end

    if activePressure > 0 then
        infectionLoad = FAM.clamp(infectionLoad + math.min(12, activePressure * 0.6), 0, 100)
    elseif infectionLoad > 0 then
        infectionLoad = math.max(0, infectionLoad - (1 + careRecovery + csrPower))
    end

    data.FAM_LocalInfectionLoad = infectionLoad > 0 and infectionLoad or nil
    if infectionLoad >= FAM.CONDITION.LOCAL_INFECTION_CONFIRMED then
        local sepsisGain = (infectionLoad - FAM.CONDITION.LOCAL_INFECTION_CONFIRMED) / (csrPower > 0 and 18 or 12)
        data.FAM_SepsisLoad = FAM.clamp((tonumber(data.FAM_SepsisLoad) or 0) + math.max(0.5, sepsisGain), 0, 100)
        FAM.addStat(character, "FATIGUE", infectionLoad >= FAM.CONDITION.LOCAL_INFECTION_CRITICAL and 0.025 or 0.01)
        if infectionLoad >= FAM.CONDITION.LOCAL_INFECTION_CRITICAL then
            FAM.addStat(character, "PAIN", 3)
        end
    elseif activePressure <= 0 and csrPower > 0 then
        FAM.reduceSystemicCondition(character, "FAM_SepsisLoad", 1 + csrPower)
    end
end

function FAM.recalculateSystemicConditions(character)
    local bodyDamage = FAM.getBodyDamage(character)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return end

    local infectionPressure = 0
    local traumaPressure = 0
    local exposedWounds = 0
    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        local gangrene = FAM.getGangrene(character, bodyPart)
        if gangrene >= FAM.CONDITION.GANGRENE_CONFIRMED then
            infectionPressure = infectionPressure + ((gangrene - FAM.CONDITION.GANGRENE_CONFIRMED) / 3)
        end
        if FAM.getBulletHours(character, bodyPart) >= FAM.CONDITION.BULLET_CRITICAL_HOURS then
            infectionPressure = infectionPressure + 8
        end
        if FAM.hasOpenContaminationRoute(bodyPart) then
            exposedWounds = exposedWounds + 1
        end
        traumaPressure = traumaPressure + (FAM.bodyPartSeverity(bodyPart) / 12)
    end

    local data = character:getModData()
    local antibioticPower = tonumber(data.FAM_CSR_AntibodySupportPower) or 0
    local pathogen = FAM.getPathogenLoad(character)
    if pathogen >= FAM.CONDITION.PATHOGEN_ELEVATED and exposedWounds > 0 then
        infectionPressure = infectionPressure + ((pathogen - FAM.CONDITION.PATHOGEN_ELEVATED) / 7) + exposedWounds
    end

    local sepsis = tonumber(data.FAM_SepsisLoad) or 0
    local shock = tonumber(data.FAM_ShockLoad) or 0
    local bloodPercent = FAM.getBloodPercent(character)
    if bloodPercent < FAM.BLOOD.LOW_PERCENT then
        traumaPressure = traumaPressure + ((FAM.BLOOD.LOW_PERCENT - bloodPercent) / 2)
    end

    if infectionPressure > 0 then
        sepsis = math.min(100, sepsis + math.max(2, infectionPressure / 5))
    else
        sepsis = math.max(0, sepsis - (2 + antibioticPower))
    end

    if traumaPressure > 16 then
        shock = math.min(100, shock + math.max(2, traumaPressure / 6))
    else
        shock = math.max(0, shock - 2)
    end

    data.FAM_SepsisLoad = sepsis > 0 and sepsis or nil
    data.FAM_ShockLoad = shock > 0 and shock or nil
end

function FAM.applyTreatment(doctor, patient, item, bodyPart, treatment)
    local valid = FAM.canUseTreatment(doctor, patient, bodyPart, treatment)
    if not valid then
        return false
    end

    local protocol = FAM.TREATMENTS[treatment]
    if protocol and protocol.item and not FAM.isItemFullType(item, protocol.item) then
        return false
    end

    addHemophobicPanic(doctor, bodyPart)

    local doctorLevel = FAM.getEffectiveDoctorLevel(doctor)
    local data = patient:getModData()
    local preSeverity = FAM.bodyPartClinicalSeverity(patient, bodyPart)
    local preConditionLoad = FAM.getConditionLoad(patient)
    local bodyPartLabel = FAM.getBodyPartName(bodyPart) or "Unknown"
    local treatmentQuality = FAM.getTreatmentQuality(doctor, patient, bodyPart, treatment)
    local treatmentQualityBonus = math.floor(treatmentQuality / 12)
    local treatmentQualityLabelKey = getQualityLabelKey(treatmentQuality)
    local csrStatus = FAM.getCSRStatus(patient)
    local function recordCareOutcome(action, advanced, extra)
        extra = extra or {}
        extra.action = action
        extra.category = advanced and "fam" or "basic"
        extra.bodyPart = bodyPartLabel
        extra.advanced = advanced
        extra.quality = treatmentQuality
        extra.injuryFixed = true
        extra.saved = extra.saved == true or preSeverity >= 70 or preConditionLoad >= 70
        extra.signature = action .. ":" .. FAM.getCharacterKey(patient) .. ":" .. bodyPartLabel .. ":" .. tostring(math.floor(FAM.getWorldAgeHours() * 10))
        FAM.appendClinicalRecord(patient, {
            key = action,
            labelKey = "IGUI_FAM_ClinicalEvent_Treatment",
            valueText = FAM.protocolLabel(treatment) .. " - " .. famText(treatmentQualityLabelKey),
            severity = math.max(preSeverity, preConditionLoad),
            provider = FAM.getClinicianName(doctor),
            csr = csrStatus.active or csrStatus.crisis,
        })
        FAM.recordProviderOutcome(doctor, patient, extra)
    end

    if treatment == "burn" then
        local reduction = 12 + (doctorLevel * 1.5) + treatmentQualityBonus
        bodyPart:setBurnTime(math.max(0, bodyPart:getBurnTime() - reduction))
        bodyPart:setNeedBurnWash(false)
        bodyPart:setAdditionalPain(bodyPart:getAdditionalPain() + math.max(6, 36 - doctorLevel * 3 - math.floor(treatmentQuality / 10)))
        patient:getModData().FAM_BurnTreatmentCooldown = 10
        FAM.applyWoundCareQuality(patient, bodyPart, treatmentQuality, 6 + math.floor(treatmentQuality / 25))
        FAM.consumeTreatmentItem(doctor, item, true)
        FAM.addDoctorXp(doctor, 10)
        if syncBodyPart then
            syncBodyPart(bodyPart, BODY_SYNC_BURN)
        end
        recordCareOutcome("burn", true)
        return true
    end

    if treatment == "hemostatic" then
        bodyPart:setBleedingTime(0)
        bodyPart:setBleeding(false)
        bodyPart:setAdditionalPain(bodyPart:getAdditionalPain() + math.max(8, 32 - doctorLevel * 2 - math.floor(treatmentQuality / 12)))
        FAM.addPoisonLevel(patient, math.max(1, 8 - math.floor(treatmentQuality / 14)))
        FAM.applyWoundCareQuality(patient, bodyPart, treatmentQuality, 8 + math.floor(treatmentQuality / 18))
        FAM.consumeTreatmentItem(doctor, item, false)
        FAM.addDoctorXp(doctor, 12)
        if syncBodyPart then
            syncBodyPart(bodyPart, BODY_SYNC_BANDAGE)
        end
        FAM.syncPlayerEffects(patient)
        recordCareOutcome("hemostatic", true)
        return true
    end

    if treatment == "tourniquet" then
        bodyPart:setBleedingTime(0)
        bodyPart:setBleeding(false)
        bodyPart:setAdditionalPain(bodyPart:getAdditionalPain() + math.max(16, 47 - doctorLevel * 2 - math.floor(treatmentQuality / 16)))
        patient:getModData()["FAM_Tourniquet_" .. tostring(bodyPart:getIndex())] = math.max(3, math.min(6, 3 + math.floor(treatmentQuality / 25)))
        FAM.addStat(patient, "FATIGUE", math.max(0.14, 0.3 - (treatmentQuality / 500)))
        FAM.applyWoundCareQuality(patient, bodyPart, treatmentQuality, 5 + math.floor(treatmentQuality / 20))
        FAM.consumeTreatmentItem(doctor, item, false)
        FAM.addDoctorXp(doctor, 15)
        if syncBodyPart then
            syncBodyPart(bodyPart, BODY_SYNC_BANDAGE)
        end
        FAM.syncPlayerEffects(patient)
        recordCareOutcome("tourniquet", true)
        return true
    end

    if treatment == "sanitation" then
        local exposureReduction = 42 + doctorLevel * 3 + (treatmentQualityBonus * 2)
        local pathogenReduction = 30 + doctorLevel * 2 + treatmentQualityBonus
        local wasPandemic = FAM.isPandemicInfected(patient)
        data.FAM_CorpseExposureLoad = math.max(0, (tonumber(data.FAM_CorpseExposureLoad) or 0) - exposureReduction)
        data.FAM_PathogenLoad = math.max(0, (tonumber(data.FAM_PathogenLoad) or 0) - pathogenReduction)
        if data.FAM_CorpseExposureLoad <= 0 then data.FAM_CorpseExposureLoad = nil end
        if data.FAM_PathogenLoad <= 0 then data.FAM_PathogenLoad = nil end
        data.FAM_LocalInfectionLoad = math.max(0, (tonumber(data.FAM_LocalInfectionLoad) or 0) - (8 + treatmentQualityBonus))
        if data.FAM_LocalInfectionLoad <= 0 then data.FAM_LocalInfectionLoad = nil end
        data.FAM_SanitationHours = math.max(tonumber(data.FAM_SanitationHours) or 0, 10 + doctorLevel + math.floor(treatmentQuality / 25))
        FAM.setPartValue(patient, bodyPart, "SanitationHours", 8 + doctorLevel + math.floor(treatmentQuality / 30))
        FAM.applyWoundCareQuality(patient, bodyPart, treatmentQuality, 10 + math.floor(treatmentQuality / 18))
        FAM.setGangrene(patient, bodyPart, FAM.getGangrene(patient, bodyPart) - (8 + doctorLevel + treatmentQualityBonus))
        FAM.reduceSystemicCondition(patient, "FAM_SepsisLoad", 5 + doctorLevel + treatmentQualityBonus)
        FAM.reduceSicknessLevel(patient, 6 + doctorLevel)
        if wasPandemic then
            FAM.reducePandemicLoadByTreatment(patient, 12 + doctorLevel + math.floor(treatmentQuality / 12), "sanitation")
        end
        FAM.consumeTreatmentItem(doctor, item, false)
        FAM.addDoctorXp(doctor, 10)
        if syncBodyPart then
            syncBodyPart(bodyPart, BODY_SYNC_BANDAGE)
        end
        FAM.syncPlayerEffects(patient)
        recordCareOutcome("sanitation", true, { pandemic = wasPandemic })
        return true
    end

    if treatment == "stumpcare" then
        local reduction = 26 + (doctorLevel * 2) + (treatmentQualityBonus * 2)
        FAM.setGangrene(patient, bodyPart, FAM.getGangrene(patient, bodyPart) - reduction)
        FAM.setPartValue(patient, bodyPart, "StumpCareHours", 18 + math.floor(treatmentQuality / 20))
        FAM.applyWoundCareQuality(patient, bodyPart, treatmentQuality, 14 + math.floor(treatmentQuality / 16))
        local primary = FAM.getPrimaryAmputationName(patient, bodyPart)
        if primary then
            data["FAM_StumpRecoveryHours_" .. primary] = math.max(0, (tonumber(data["FAM_StumpRecoveryHours_" .. primary]) or 0) - (12 + treatmentQualityBonus))
        end
        if bodyPart:isInfectedWound() and not bodyPart:bitten() and bodyPart.setInfectedWound then
            bodyPart:setInfectedWound(false)
        end
        data.FAM_LocalInfectionLoad = math.max(0, (tonumber(data.FAM_LocalInfectionLoad) or 0) - (12 + treatmentQualityBonus))
        if data.FAM_LocalInfectionLoad <= 0 then data.FAM_LocalInfectionLoad = nil end
        FAM.reduceSystemicCondition(patient, "FAM_SepsisLoad", 10 + doctorLevel + treatmentQualityBonus)
        FAM.consumeTreatmentItem(doctor, item, false)
        FAM.addDoctorXp(doctor, 18)
        if syncBodyPart then
            syncBodyPart(bodyPart, BODY_SYNC_BANDAGE)
        end
        FAM.syncPlayerEffects(patient)
        recordCareOutcome("stumpcare", true)
        return true
    end

    if treatment == "ivfluids" then
        local csrPower = tonumber(data.FAM_CSR_AntibodySupportPower) or 0
        local ivKit = FAM.findFirstItem(doctor, "FAM.IVKit")
        data.FAM_SalineSupportHours = math.max(tonumber(data.FAM_SalineSupportHours) or 0, 5 + math.floor(doctorLevel / 2) + math.floor(treatmentQuality / 35))
        data.FAM_FluidSupportVolume = math.max(tonumber(data.FAM_FluidSupportVolume) or 0, FAM.BLOOD.SALINE_VOLUME)
        FAM.reduceSystemicCondition(patient, "FAM_ShockLoad", 12 + doctorLevel + math.floor(treatmentQuality / 10))
        FAM.removeStat(patient, "THIRST", 0.18)
        if csrPower > 0 then
            FAM.reduceSystemicCondition(patient, "FAM_SepsisLoad", 2 + csrPower + math.floor(treatmentQuality / 25))
            data.FAM_PathogenLoad = math.max(0, (tonumber(data.FAM_PathogenLoad) or 0) - (2 + csrPower))
            if data.FAM_PathogenLoad <= 0 then data.FAM_PathogenLoad = nil end
        end
        FAM.consumeTreatmentItem(doctor, item, false)
        FAM.consumeTreatmentItem(doctor, ivKit, false)
        FAM.addDoctorXp(doctor, 12)
        FAM.syncPlayerEffects(patient)
        FAM.syncPlayerStats(patient)
        recordCareOutcome("iv_fluids", true, {
            vascular = true,
            csr = csrPower > 0,
            saved = FAM.getBloodPercent(patient) < FAM.BLOOD.CRITICAL_PERCENT or preConditionLoad >= 55,
        })
        return true
    end

    if treatment == "bloodpack" then
        local beforeBlood = FAM.getBloodPercent(patient)
        local beforeHealth = FAM.getBodyHealthPercent(patient)
        local csrPower = tonumber(data.FAM_CSR_AntibodySupportPower) or 0
        local ivKit = FAM.findFirstItem(doctor, "FAM.IVKit")
        FAM.addBloodVolume(patient, FAM.BLOOD.BLOOD_PACK_VOLUME + (doctorLevel * 20) + (treatmentQualityBonus * 12))
        local bodyDamage = FAM.getBodyDamage(patient)
        if bodyDamage and bodyDamage.AddGeneralHealth and beforeHealth < 100 then
            local restoredHealth = FAM.BLOOD.BLOOD_PACK_HEALTH + math.floor(doctorLevel / 2) + treatmentQualityBonus
            bodyDamage:AddGeneralHealth(math.min(restoredHealth, 100 - beforeHealth))
        end
        data.FAM_BloodSupportHours = math.max(tonumber(data.FAM_BloodSupportHours) or 0, 8 + math.floor(treatmentQuality / 40))
        FAM.reduceSystemicCondition(patient, "FAM_ShockLoad", 18 + doctorLevel + math.floor(treatmentQuality / 8))
        if csrPower > 0 then
            FAM.reduceSystemicCondition(patient, "FAM_SepsisLoad", 3 + csrPower + math.floor(treatmentQuality / 28))
        else
            FAM.addPoisonLevel(patient, 2)
        end
        FAM.consumeTreatmentItem(doctor, item, false)
        FAM.consumeTreatmentItem(doctor, ivKit, false)
        FAM.addDoctorXp(doctor, 22)
        FAM.syncPlayerEffects(patient)
        FAM.syncPlayerStats(patient)
        recordCareOutcome("blood_support", true, {
            vascular = true,
            csr = csrPower > 0,
            saved = beforeBlood < FAM.BLOOD.CRITICAL_PERCENT or beforeHealth < FAM.BLOOD.LOW_PERCENT or preConditionLoad >= 65,
        })
        return true
    end

    if treatment == "epinephrine" then
        FAM.reduceSystemicCondition(patient, "FAM_ShockLoad", 20 + doctorLevel + math.floor(treatmentQuality / 8))
        FAM.setStat(patient, "FATIGUE", math.min(FAM.getStat(patient, "FATIGUE", 0), 0.12))
        FAM.addStat(patient, "ENDURANCE", 0.35)
        FAM.addStat(patient, "PANIC", 35)
        FAM.addStat(patient, "STRESS", 0.18)
        FAM.addPoisonLevel(patient, math.max(4, 9 - math.floor(treatmentQuality / 35)))
        data.FAM_EpinephrineCooldown = 8
        data.FAM_EpinephrineCrashHours = 3
        FAM.consumeTreatmentItem(doctor, item, false)
        FAM.addDoctorXp(doctor, 16)
        FAM.syncPlayerEffects(patient)
        FAM.syncPlayerStats(patient)
        recordCareOutcome("epinephrine", true, {
            vascular = true,
            saved = preConditionLoad >= 60 or (tonumber(data.FAM_ShockLoad) or 0) >= 45,
        })
        return true
    end

    return false
end

local function setColdStrength(character, delta)
    local cold = FAM.getBodyDamageValue(character, "getColdStrength", 0)
    if cold <= delta then
        FAM.setBodyDamageValue(character, "setColdStrength", 0)
        FAM.setBodyDamageValue(character, "setHasACold", false)
        FAM.setBodyDamageValue(character, "setCatchACold", 0)
    else
        FAM.setBodyDamageValue(character, "setColdStrength", cold - delta)
    end
end

local function addPoison(character, amount)
    FAM.addPoisonLevel(character, amount)
end

local function painMeds(character, amount, painEffect)
    if character.PainMeds then
        character:PainMeds(amount)
    end
    if painEffect and character.setPainEffect then
        character:setPainEffect(painEffect)
    end
end

local function betaBlockers(character, amount)
    if character.BetaBlockers then
        character:BetaBlockers(amount)
    end
end

function FAM.applyPill(character, itemType)
    if not character or not itemType then return end
    local drunk = character:getMoodles() and character:getMoodles():getMoodleLevel(MoodleType.DRUNK) > 0

    if itemType == "PillsCommercialPainkillers" then
        painMeds(character, (drunk and 0.15 or 0.45) * 0.5, drunk and 5400 * 4 or nil)
        setColdStrength(character, 5)
        addPoison(character, 5)
    elseif itemType == "PillsPrescriptionPainkillers" then
        painMeds(character, (drunk and 0.15 or 0.45) * 0.9, drunk and 5400 * 6 or nil)
        addPoison(character, 10)
    elseif itemType == "PillsCaffeine" then
        FAM.removeStat(character, "FATIGUE", 0.3)
        addPoison(character, 5)
    elseif itemType == "PillsCommercialAntibiotic" then
        FAM.reduceFakeInfection(character, 25)
        addPoison(character, 15)
        FAM.reduceAllGangrene(character, 4)
        FAM.reduceSystemicCondition(character, "FAM_SepsisLoad", 8)
        if FAM.isPandemicInfected(character) then
            FAM.reducePandemicLoadByTreatment(character, 8, "antibiotic")
        end
        FAM.applyCSRSupport(character, "commercial_antibiotic", 1, 8)
    elseif itemType == "PillsAntiPoisoning" then
        FAM.setPoisonLevel(character, 0)
        if character.setPainEffect then
            local currentPainEffect = character.getPainEffect and character:getPainEffect() or 0
            character:setPainEffect(currentPainEffect + 25)
        end
        FAM.addStat(character, "HUNGER", 0.35)
        FAM.addStat(character, "THIRST", 0.5)
        FAM.addStat(character, "FATIGUE", 0.15)
    elseif itemType == "PillsCommercialSedative" then
        betaBlockers(character, drunk and 0.075 or 0.15)
        FAM.removeStat(character, "STRESS", 0.25)
        FAM.addUnhappiness(character, 5)
        addPoison(character, 5)
        FAM.addStat(character, "FATIGUE", 0.1)
    elseif itemType == "PillsPharmacyPrescription" then
        addPoison(character, 10)
        if ZombRand and ZombRand(100) < 35 then
            FAM.addStat(character, "PANIC", 20)
            FAM.addStat(character, "FATIGUE", 0.1)
        end
    end

    FAM.syncPlayerEffects(character)
end

function FAM.applyInjectable(character, itemType)
    if not character or not itemType then return end

    if itemType == "SyretteHighGradePainkillers" then
        painMeds(character, 0.45 * 1.5, 5400 * 3)
        FAM.setStat(character, "PAIN", 10)
        if character:getModData().FAM_MorphineCooldown then
            addPoison(character, 50)
        else
            addPoison(character, 5)
            character:getModData().FAM_MorphineCooldown = 5
        end
        FAM.addStat(character, "FATIGUE", 0.4)
    elseif itemType == "SyretteAdrenalin" then
        FAM.setStat(character, "FATIGUE", 0)
        FAM.addStat(character, "ENDURANCE", 0.3)
        character:getModData().FAM_AdrenalineCrashHours = 2
        FAM.addStat(character, "PANIC", 50)
        FAM.addStat(character, "STRESS", 0.25)
        addPoison(character, 15)
    elseif itemType == "SyrettePrescriptionAntibiotic" then
        FAM.reduceFakeInfection(character, 50)
        addPoison(character, 15)
        FAM.addStat(character, "FATIGUE", 0.1)
        FAM.reduceAllGangrene(character, 9)
        FAM.reduceSystemicCondition(character, "FAM_SepsisLoad", 18)
        if FAM.isPandemicInfected(character) then
            FAM.reducePandemicLoadByTreatment(character, 18, "antibiotic")
        end
        FAM.applyCSRSupport(character, "antibiotic_syrette", 2, 16)
    elseif itemType == "SyrettePrescriptionSedatives" then
        FAM.setStat(character, "PANIC", 0)
        FAM.setStat(character, "STRESS", 0)
        FAM.addUnhappiness(character, -50)
        FAM.addStat(character, "FATIGUE", 0.5)
        addPoison(character, 15)
    end

    FAM.syncPlayerEffects(character)
end

function FAM.applyFluMedication(character, food)
    if not character then return end
    setColdStrength(character, 20)
    if FAM.isPandemicInfected(character) then
        FAM.reducePandemicLoadByTreatment(character, 10, "flu")
    end
    FAM.addStat(character, "FATIGUE", 0.1)
    addPoison(character, 10)
    FAM.syncPlayerEffects(character)
end

function FAM.applyHotFluMedication(character, food)
    if not character then return end
    local heat = food and food.getHeat and food:getHeat() or 0
    local drunk = character:getMoodles() and character:getMoodles():getMoodleLevel(MoodleType.DRUNK) > 0
    setColdStrength(character, 20)
    if FAM.isPandemicInfected(character) then
        FAM.reducePandemicLoadByTreatment(character, 10, "flu")
    end
    painMeds(character, (drunk and 0.15 or 0.45) * (heat > 1.3 and 0.4 or 0.1))
    FAM.addStat(character, "FATIGUE", 0.1)
    addPoison(character, 10)
    FAM.syncPlayerEffects(character)
end

function FAM.suppressCough(character, syrup)
    if not character then return end
    local bodyDamage = FAM.getBodyDamage(character)
    local minutes = getSandboxOptions():getDayLengthMinutes()
    if bodyDamage and bodyDamage.setNastyColdSneezeTimerMin then
        bodyDamage:setNastyColdSneezeTimerMin((minutes / 4) * 60 * 100)
    end
    character:getModData().FAM_SneezeSuppressionHours = 5
    if syrup then
        FAM.addStat(character, "FATIGUE", 0.05)
        addPoison(character, 5)
    end
    FAM.syncPlayerEffects(character)
end

function FAM.getBodyPartAdditionalPain(bodyPart)
    if not bodyPart or not bodyPart.getAdditionalPain then return 0 end
    return tonumber(bodyPart:getAdditionalPain()) or 0
end

function FAM.getBodyPartStiffness(bodyPart)
    if not bodyPart or not bodyPart.getStiffness then return 0 end
    return tonumber(bodyPart:getStiffness()) or 0
end

function FAM.getBodyPartHealthLoss(bodyPart)
    if not bodyPart or not bodyPart.getHealth then return 0 end
    return FAM.clamp(100 - (tonumber(bodyPart:getHealth()) or 100), 0, 100)
end

function FAM.hasVanillaVisibleBodyPartIssue(bodyPart)
    if not bodyPart then return false end
    return bodyPart:HasInjury()
        or bodyPart:bandaged()
        or bodyPart:stitched()
        or bodyPart:getSplintFactor() > 0
        or FAM.getBodyPartAdditionalPain(bodyPart) > 10
        or FAM.getBodyPartStiffness(bodyPart) > 5
        or FAM.getBodyPartHealthLoss(bodyPart) > 5
end

function FAM.bodyPartSeverity(bodyPart)
    if not bodyPart then return 0 end
    local score = 0
    if bodyPart:bleeding() then score = score + 35 end
    score = score + math.min(bodyPart:getBleedingTime(), 60)
    score = score + math.min(bodyPart:getBurnTime(), 60)
    score = score + math.min(bodyPart:getFractureTime() * 2, 40)
    score = score + math.min(bodyPart:getDeepWoundTime(), 40)
    if bodyPart:isInfectedWound() then score = score + 20 end
    if bodyPart:bitten() then score = score + 40 end
    if bodyPart:scratched() then score = score + 12 end
    if bodyPart:isCut() then score = score + 18 end
    if bodyPart:haveGlass() then score = score + 12 end
    if bodyPart:haveBullet() then score = score + 20 end
    score = score + math.min(FAM.getBodyPartAdditionalPain(bodyPart) * 0.45, 30)
    score = score + math.min(FAM.getBodyPartStiffness(bodyPart) * 0.35, 25)
    score = score + math.min(FAM.getBodyPartHealthLoss(bodyPart), 30)
    return FAM.clamp(score, 0, 100)
end

function FAM.bodyPartClinicalSeverity(patient, bodyPart)
    if patient and bodyPart and FAM.isSuppressedAmputationPart(patient, bodyPart) then
        return 0
    end
    local score = FAM.bodyPartSeverity(bodyPart)
    if patient and bodyPart then
        score = score + (FAM.getGangrene(patient, bodyPart) * 0.8)
        score = score + math.min(FAM.getBulletHours(patient, bodyPart), FAM.CONDITION.BULLET_CRITICAL_HOURS) * 0.5
        if FAM.isAmputationIndicated(patient, bodyPart) then
            score = score + 25
        end
        if FAM.hasProsthetic(patient, bodyPart) then
            score = math.max(0, score - 15)
        end
    end
    return FAM.clamp(score, 0, 100)
end

function FAM.getProcedureRecommendation(patient, bodyPart)
    if FAM.isSuppressedAmputationPart(patient, bodyPart) then
        return getText("IGUI_FAM_ProcedureMonitor")
    end
    if FAM.isAmputationIndicated(patient, bodyPart) then
        return getText("IGUI_FAM_ProcedureAmputate")
    end
    if FAM.getBulletHours(patient, bodyPart) >= FAM.CONDITION.BULLET_DEEP_HOURS then
        return getText("IGUI_FAM_ProcedureRemoveBullet")
    end
    if FAM.getGangrene(patient, bodyPart) >= FAM.CONDITION.GANGRENE_SUSPECT then
        return getText("IGUI_FAM_ProcedureStumpCare")
    end
    if FAM.hasOpenContaminationRoute(bodyPart) and FAM.getPathogenLoad(patient) >= FAM.CONDITION.PATHOGEN_ELEVATED then
        return getText("IGUI_FAM_ProcedureSanitize")
    end
    if FAM.hasAmputation(patient, bodyPart) and not FAM.hasProsthetic(patient, bodyPart) then
        return getText("IGUI_FAM_ProcedureProsthetic")
    end
    return getText("IGUI_FAM_ProcedureMonitor")
end

function FAM.getClinicalRows(patient, advanced)
    local rows = {}
    if not patient then return rows end
    local bodyDamage = FAM.getBodyDamage(patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return rows end

    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        if not FAM.isSuppressedAmputationPart(patient, bodyPart) then
            local severity = FAM.bodyPartClinicalSeverity(patient, bodyPart)
            local gangrene = FAM.getGangrene(patient, bodyPart)
            local bulletHours = FAM.getBulletHours(patient, bodyPart)
            local hasCondition = severity > 0
                or FAM.hasVanillaVisibleBodyPartIssue(bodyPart)
                or gangrene > 0
                or bulletHours > 0
                or FAM.isAmputationIndicated(patient, bodyPart)
                or FAM.hasTourniquet(patient, bodyPart)
                or FAM.hasAmputation(patient, bodyPart)
                or FAM.hasProsthetic(patient, bodyPart)

            if hasCondition then
                local priority = severity
                if bodyPart:HasInjury() then priority = priority + 15 end
                if bodyPart:bandaged() then priority = priority + 10 end
                if bodyPart:stitched() then priority = priority + 6 end
                if bodyPart:getSplintFactor() > 0 then priority = priority + 6 end
                if FAM.hasAmputation(patient, bodyPart) then priority = priority + 30 end
                if FAM.hasTourniquet(patient, bodyPart) then priority = priority + 20 end
                if FAM.hasProsthetic(patient, bodyPart) then priority = priority + 8 end
                table.insert(rows, {
                    part = FAM.getBodyPartName(bodyPart) or "?",
                    index = bodyPart:getIndex(),
                    severity = severity,
                    priority = priority,
                    gangrene = gangrene,
                    bulletHours = bulletHours,
                    summary = FAM.describeBodyPart(patient, bodyPart),
                    recommendation = FAM.getProcedureRecommendation(patient, bodyPart),
                })
            end
        end
    end

    table.sort(rows, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        return tostring(a.part) < tostring(b.part)
    end)
    return rows
end

function FAM.describeBodyPart(patient, bodyPart)
    local tags = {}
    if bodyPart:bleeding() then table.insert(tags, getText("IGUI_FAM_TagBleeding")) end
    if bodyPart:getBurnTime() > 0 then table.insert(tags, getText("IGUI_FAM_TagBurn")) end
    if bodyPart:bitten() then table.insert(tags, getText("IGUI_FAM_TagBite")) end
    if bodyPart:scratched() then table.insert(tags, getText("IGUI_FAM_TagScratch")) end
    if bodyPart:isCut() then table.insert(tags, getText("IGUI_FAM_TagLaceration")) end
    if bodyPart:getFractureTime() > 0 then table.insert(tags, getText("IGUI_FAM_TagFracture")) end
    if bodyPart:getDeepWoundTime() > 0 then table.insert(tags, getText("IGUI_FAM_TagDeepWound")) end
    if bodyPart:haveGlass() then table.insert(tags, getText("IGUI_FAM_TagGlass")) end
    if bodyPart:haveBullet() then table.insert(tags, getText("IGUI_FAM_TagBullet")) end
    if bodyPart:bandaged() then
        if bodyPart.getBandageLife and bodyPart:getBandageLife() <= 0 then
            table.insert(tags, getText("IGUI_health_DirtyBandage"))
        else
            table.insert(tags, getText("IGUI_FAM_TagBandaged"))
        end
    end
    if bodyPart:stitched() then table.insert(tags, getText("IGUI_FAM_TagStitched")) end
    if bodyPart:getSplintFactor() > 0 then table.insert(tags, getText("IGUI_FAM_TagSplinted")) end
    if bodyPart:isInfectedWound() then table.insert(tags, getText("IGUI_FAM_TagInfected")) end
    if FAM.hasTourniquet(patient, bodyPart) then table.insert(tags, getText("IGUI_FAM_TagTourniquet")) end
    if FAM.hasAmputation(patient, bodyPart) then table.insert(tags, getText("IGUI_FAM_TagAmputated")) end
    local pain = FAM.getBodyPartAdditionalPain(bodyPart)
    if pain > 50 then
        table.insert(tags, getText("IGUI_health_HeavyPain"))
    elseif pain > 10 then
        table.insert(tags, getText("IGUI_health_Pain"))
    end
    local stiffness = FAM.getBodyPartStiffness(bodyPart)
    if stiffness >= 20 then
        table.insert(tags, getText("IGUI_health_Stiffness"))
    elseif stiffness > 5 then
        table.insert(tags, getText("IGUI_health_MinorStiffness"))
    end
    if #tags == 0 and FAM.getBodyPartHealthLoss(bodyPart) > 5 then
        table.insert(tags, getText("IGUI_health_Slight_damage"))
    end
    local gangrene = FAM.getGangrene(patient, bodyPart)
    local bulletHours = FAM.getBulletHours(patient, bodyPart)
    if gangrene >= FAM.CONDITION.GANGRENE_CRITICAL then
        table.insert(tags, getText("IGUI_FAM_TagNecrotic"))
    elseif gangrene >= FAM.CONDITION.GANGRENE_CONFIRMED then
        table.insert(tags, getText("IGUI_FAM_TagGangrene"))
    elseif gangrene >= FAM.CONDITION.GANGRENE_SUSPECT then
        table.insert(tags, getText("IGUI_FAM_TagGangreneSuspected"))
    end
    if bulletHours >= FAM.CONDITION.BULLET_CRITICAL_HOURS then
        table.insert(tags, getText("IGUI_FAM_TagBulletCritical"))
    elseif bulletHours >= FAM.CONDITION.BULLET_DEEP_HOURS then
        table.insert(tags, getText("IGUI_FAM_TagBulletDeep"))
    elseif bulletHours >= FAM.CONDITION.BULLET_LODGED_HOURS then
        table.insert(tags, getText("IGUI_FAM_TagBulletLodged"))
    end
    if FAM.isAmputationIndicated(patient, bodyPart) then table.insert(tags, getText("IGUI_FAM_TagAmputationIndicated")) end
    if FAM.hasProsthetic(patient, bodyPart) then table.insert(tags, getText("IGUI_FAM_TagProsthetic")) end
    if (tonumber(FAM.getPartValue(patient, bodyPart, "StumpCareHours", 0)) or 0) > 0 then table.insert(tags, getText("IGUI_FAM_TagStumpCare")) end
    if (tonumber(FAM.getPartValue(patient, bodyPart, "SanitationHours", 0)) or 0) > 0 then table.insert(tags, getText("IGUI_FAM_TagSanitized")) end
    return table.concat(tags, " ")
end

function FAM.tickCharacter(character)
    if not character then return end
    local data = character:getModData()
    local counters = {
        "FAM_SneezeSuppressionHours",
        "FAM_MorphineCooldown",
        "FAM_BurnTreatmentCooldown",
        "FAM_AdrenalineCrashHours",
        "FAM_EpinephrineCooldown",
        "FAM_EpinephrineCrashHours",
        "FAM_CSR_AntibodySupportHours",
        "FAM_SanitationHours",
        "FAM_SalineSupportHours",
        "FAM_BloodSupportHours",
        "FAM_HollowVeilBlurHours",
        "FAM_HollowVeilDeafHours",
    }

    for i = 1, #counters do
        local key = counters[i]
        if data[key] then
            data[key] = data[key] - 1
            if data[key] <= 0 then
                data[key] = nil
                if key == "FAM_SneezeSuppressionHours" then
                    local bodyDamage = FAM.getBodyDamage(character)
                    if bodyDamage and bodyDamage.setNastyColdSneezeTimerMin then bodyDamage:setNastyColdSneezeTimerMin(200) end
                    if bodyDamage and bodyDamage.TriggerSneezeCough then bodyDamage:TriggerSneezeCough() end
                    if bodyDamage and bodyDamage.setSneezeCoughActive then bodyDamage:setSneezeCoughActive(1) end
                elseif key == "FAM_AdrenalineCrashHours" then
                    FAM.setStat(character, "FATIGUE", 1)
                    FAM.addStat(character, "HUNGER", 0.2)
                elseif key == "FAM_EpinephrineCrashHours" then
                    FAM.addStat(character, "FATIGUE", 0.35)
                    FAM.addStat(character, "HUNGER", 0.12)
                    FAM.addStat(character, "THIRST", 0.12)
                elseif key == "FAM_CSR_AntibodySupportHours" then
                    data.FAM_CSR_AntibodySupportPower = nil
                    data.FAM_CSR_AntibodySupportSource = nil
                    data.FAM_CSR_RetryGranted = nil
                elseif key == "FAM_SalineSupportHours" then
                    data.FAM_FluidSupportVolume = nil
                end
            end
        end
    end

    local bodyDamage = FAM.getBodyDamage(character)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return end

    FAM.updateCorpseExposure(character)

    for key, value in pairs(data) do
        if string.find(tostring(key), "^FAM_StumpRecoveryHours_") and tonumber(value) then
            value = value - 1
            data[key] = value > 0 and value or nil
        elseif string.find(tostring(key), "^FAM_ProstheticFitHours_") and tonumber(value) then
            data[key] = value + 1
        end
    end

    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        local key = "FAM_Tourniquet_" .. tostring(bodyPart:getIndex())
        if data[key] and data[key] > 0 then
            data[key] = data[key] - 1
            if data[key] <= 0 then
                data[key] = -1
                bodyPart:setAdditionalPain(bodyPart:getAdditionalPain() + 20)
                if bodyPart.getWoundInfectionLevel and bodyPart.setWoundInfectionLevel then
                    bodyPart:setWoundInfectionLevel(math.max(bodyPart:getWoundInfectionLevel(), 5))
                end
                if syncBodyPart then
                    syncBodyPart(bodyPart, BODY_SYNC_BANDAGE)
                end
            end
        end
        FAM.updatePartCondition(character, bodyPart)
    end
    FAM.updateWoundInfectionProgression(character)
    FAM.updateBloodReserve(character)
    FAM.recalculateSystemicConditions(character)
    FAM.updatePatientAnalytics(character)
    FAM.updatePandemicForCharacter(character)
end

local function onEveryHours()
    if isServer and isServer() and getOnlinePlayers then
        local players = getOnlinePlayers()
        for i = 1, players:size() do
            FAM.tickCharacter(players:get(i - 1))
        end
        return
    end
    if getNumActivePlayers then
        for i = 0, getNumActivePlayers() - 1 do
            FAM.tickCharacter(getSpecificPlayer(i))
        end
        return
    end
    if getPlayer then
        FAM.tickCharacter(getPlayer())
    end
end

local function onCreatePlayer(playerIndex, player)
    if not player and getSpecificPlayer then
        player = getSpecificPlayer(playerIndex)
    end
    FAM.refreshLimbVisuals(player)
end

if Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(onCreatePlayer)
end

Events.EveryHours.Add(onEveryHours)

function OnEat_FAM_SyretteHighGradePainkillers(food, character, percent)
    FAM.applyInjectable(character, "SyretteHighGradePainkillers")
end

function OnEat_FAM_SyretteAdrenalin(food, character, percent)
    FAM.applyInjectable(character, "SyretteAdrenalin")
end

function OnEat_FAM_SyrettePrescriptionAntibiotic(food, character, percent)
    FAM.applyInjectable(character, "SyrettePrescriptionAntibiotic")
end

function OnEat_FAM_SyrettePrescriptionSedatives(food, character, percent)
    FAM.applyInjectable(character, "SyrettePrescriptionSedatives")
end

function OnEat_FAM_BottleFluMedication(food, character, percent)
    FAM.applyFluMedication(character, food)
end

function OnEat_FAM_HotDrinkFluMedication(food, character, percent)
    FAM.applyHotFluMedication(character, food)
end

function OnEat_FAM_BottleCoughSyrup(food, character, percent)
    FAM.suppressCough(character, true)
end

function OnEat_FAM_NasalSpray(food, character, percent)
    FAM.suppressCough(character, false)
end

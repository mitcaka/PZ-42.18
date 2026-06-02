if isClient() then return end

require "FAM_Core"

FAM_ServerCommands = FAM_ServerCommands or {}

local function getPatient(patientId, fallbackPlayer, patientIsSelf)
    local id = tonumber(patientId)
    if id ~= nil and id >= 0 and getPlayerByOnlineID then
        local patient = getPlayerByOnlineID(id)
        if patient then return patient end
        if fallbackPlayer and fallbackPlayer.getOnlineID and tonumber(fallbackPlayer:getOnlineID()) == id then
            return fallbackPlayer
        end
    end
    if fallbackPlayer and patientIsSelf == true and (id == nil or id < 0) then
        return fallbackPlayer
    end
    return nil
end

local function inSameVehicle(doctor, patient)
    return doctor and patient
        and doctor.getVehicle and patient.getVehicle
        and doctor:getVehicle() ~= nil
        and doctor:getVehicle() == patient:getVehicle()
end

local function canWriteNote(doctor, patient)
    if not doctor or not patient then return false end
    if doctor == patient then return true end
    if FAM.isMedicalCheat(doctor) then return true end
    if inSameVehicle(doctor, patient) then return true end
    if doctor.getX and patient.getX then
        local sameLevel = not doctor.getZ or not patient.getZ or doctor:getZ() == patient:getZ()
        return sameLevel
            and math.abs(doctor:getX() - patient:getX()) <= 3
            and math.abs(doctor:getY() - patient:getY()) <= 3
    end
    return false
end

local function canReadRecords(doctor, patient)
    return canWriteNote(doctor, patient) and FAM.hasPatientRecordAccess(doctor)
end

local function buildNotePayload(patient)
    local note = FAM.getPatientNote(patient)
    local updatedBy, updatedAt = FAM.getPatientNoteMeta(patient)
    return {
        patientId = FAM.getPatientOnlineID(patient),
        note = note,
        updatedBy = updatedBy,
        updatedAt = updatedAt,
    }
end

local function sendNote(player, patient)
    if not player or not patient or not sendServerCommand then return end
    sendServerCommand(player, FAM.NETWORK_MODULE, "PatientNoteUpdated", buildNotePayload(patient))
end

local function sendRecords(player, patient)
    if not player or not patient or not sendServerCommand then return end
    local payload = buildNotePayload(patient)
    payload.records = FAM.copyPatientNoteRecords(patient)
    payload.clinicalRecords = FAM.copyClinicalRecords(patient)
    payload.analytics = FAM.copyPatientAnalytics(patient)
    sendServerCommand(player, FAM.NETWORK_MODULE, "PatientRecordsUpdated", payload)
end

local function sendProviderStats(player)
    if not player or not sendServerCommand then return end
    sendServerCommand(player, FAM.NETWORK_MODULE, "ProviderStatsUpdated", {
        rows = FAM.getProviderStatsRows(),
    })
end

local function sendPandemicStatus(player)
    if not player or not sendServerCommand then return end
    sendServerCommand(player, FAM.NETWORK_MODULE, "PandemicStatusUpdated", {
        status = FAM.getPandemicStatus(),
    })
end

local function sendPathology(player)
    if not player or not sendServerCommand then return end
    sendServerCommand(player, FAM.NETWORK_MODULE, "PathologyUpdated", {
        records = FAM.copyPathologyRecords(player),
        summary = FAM.getPathologySummary(player),
    })
end

local function sendPathologyResult(player, success, result)
    if not player or not sendServerCommand then return end
    sendServerCommand(player, FAM.NETWORK_MODULE, "PathologyStudyResult", {
        success = success == true,
        signal = type(result) == "table" and result.signal == true or false,
    })
end

local function bodyPartName(bodyPart)
    if not BodyPartType or not bodyPart then return "Unknown" end
    return BodyPartType.ToString(bodyPart:getType())
end

local function getPulseState(patient)
    if not patient or not patient.isAlive or not patient:isAlive() then return "Death" end
    local bodyDamage = FAM.getBodyDamage(patient)
    if not bodyDamage then return "Fine" end

    local poisoned = bodyDamage.IsPoisoned and bodyDamage:IsPoisoned() == true
    local foodSick = bodyDamage.getFoodSicknessLevel and bodyDamage:getFoodSicknessLevel() or 0
    local sickLevel = bodyDamage.getSicknessLevel and bodyDamage:getSicknessLevel() or 0
    local poisonLoad = FAM.getPoisonLevel and FAM.getPoisonLevel(patient) or 0
    if poisoned or foodSick >= 20 or sickLevel >= 20 or poisonLoad >= 20 then return "Poison" end

    local health = bodyDamage.getHealth and bodyDamage:getHealth() or 100
    if health >= 90 then return "Fine" end
    if health >= 60 then return "Caution" end
    if health >= 30 then return "Critical" end
    if health > 0 then return "Danger" end
    return "Death"
end

local function buildBodyPartRows(patient)
    local rows = {}
    local bodyDamage = FAM.getBodyDamage(patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return rows end

    for i = 1, bodyParts:size() do
        local bodyPart = bodyParts:get(i - 1)
        if bodyPart and not FAM.isSuppressedAmputationPart(patient, bodyPart) then
            local severity = FAM.bodyPartClinicalSeverity(patient, bodyPart)
            local hasCondition = severity > 0
                or FAM.hasVanillaVisibleBodyPartIssue(bodyPart)
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
                rows[#rows + 1] = {
                    index = bodyPart:getIndex(),
                    name = bodyPartName(bodyPart),
                    severity = severity,
                    priority = priority,
                    summary = FAM.describeBodyPart(patient, bodyPart),
                    recommendation = FAM.getProcedureRecommendation(patient, bodyPart),
                }
            end
        end
    end

    table.sort(rows, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        return tostring(a.name) < tostring(b.name)
    end)
    return rows
end

local function buildPatientSnapshot(patient, observer)
    if not patient then return nil end
    local bodyDamage = FAM.getBodyDamage(patient)
    local health = bodyDamage and bodyDamage:getHealth() or 100
    local data = patient:getModData()
    local bloodPercent = FAM.getBloodDisplayPercent(patient)
    local metrics = {
        health = health,
        traumaLoad = FAM.clamp(100 - health, 0, 100),
        poison = FAM.getPoisonLevel(patient),
        cold = FAM.getColdStressPercent(patient),
        sepsis = tonumber(data.FAM_SepsisLoad) or 0,
        shock = tonumber(data.FAM_ShockLoad) or 0,
        conditionLoad = FAM.getConditionLoad(patient),
        pathogen = FAM.getPathogenLoad(patient),
        corpseExposure = FAM.getCorpseExposureLoad(patient),
        corpseCount = FAM.getNearbyCorpseCount(patient),
        sickness = FAM.getSicknessLevel(patient),
        coreTemperature = FAM.getCoreTemperature(patient),
        temperatureRisk = FAM.getTemperatureDeviationPercent(patient),
        sanitationHours = tonumber(data.FAM_SanitationHours) or 0,
        fatigue = FAM.getStat(patient, "FATIGUE", 0) * 100,
        panic = FAM.getStat(patient, "PANIC", 0),
        bloodPercent = bloodPercent,
        bloodDeficit = FAM.clamp(100 - bloodPercent, 0, 100),
        fluidSupport = FAM.getFluidSupportHours(patient),
        pandemicLoad = FAM.getPandemicLoad(patient),
        localInfection = FAM.getLocalInfectionLoad(patient),
        quarantine = FAM.getPandemicQuarantineHours(patient),
        treated = FAM.getPandemicTreatedHours(patient),
    }
    local csr = FAM.getCSRStatus(patient)
    return {
        patientId = FAM.getPatientOnlineID(patient),
        patientKey = FAM.getCharacterKey(patient),
        observerKey = FAM.getCharacterKey(observer),
        displayName = patient.getDisplayName and patient:getDisplayName() or "Unknown",
        worldAge = FAM.getWorldAgeHours(),
        pulseState = getPulseState(patient),
        metrics = metrics,
        csr = {
            available = csr.available == true,
            active = csr.active == true,
            crisis = csr.crisis == true,
            hours = tonumber(csr.hours) or 0,
            severity = tonumber(csr.severity) or 0,
            statusKey = csr.statusKey,
        },
        clinicalSummaryRows = FAM.getClinicalSummaryRows(patient, observer),
        clinicalRows = FAM.getClinicalRows(patient, FAM.hasAdvancedClinicalAccess(observer)),
        bodyPartRows = buildBodyPartRows(patient),
        pandemic = {
            infected = FAM.isPandemicInfected(patient),
            superCarrier = FAM.isPandemicSuperCarrier(patient),
            diseaseName = FAM.getPandemicDiseaseName(patient, observer),
        },
    }
end

local function sendPatientSnapshot(player, patient)
    if not player or not patient or not sendServerCommand then return end
    local snapshot = buildPatientSnapshot(patient, player)
    if snapshot then
        sendServerCommand(player, FAM.NETWORK_MODULE, "PatientSnapshot", snapshot)
    end
end

local function broadcastNote(patient)
    if not getOnlinePlayers then return end
    local players = getOnlinePlayers()
    for i = 1, players:size() do
        sendNote(players:get(i - 1), patient)
    end
end

function FAM_ServerCommands.savePatientNote(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    FAM.setPatientNote(patient, args.note or "", args.updatedBy or FAM.getClinicianName(player), args.updatedAt or FAM.getNoteTimestamp())
    broadcastNote(patient)
    if canReadRecords(player, patient) then
        sendRecords(player, patient)
    end
end

function FAM_ServerCommands.requestPatientNote(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    sendNote(player, patient)
end

function FAM_ServerCommands.requestPatientRecords(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canReadRecords(player, patient) then return end
    sendRecords(player, patient)
end

function FAM_ServerCommands.recordProviderOutcome(player, args)
    if not player or not args then return end
    local patient = getPatient(args.patientId, player, args.patientIsSelf == true)
    FAM.applyProviderOutcome(player, patient, {
        action = args.action,
        category = args.category,
        patientKey = args.patientKey,
        bodyPart = args.bodyPart,
        injuryFixed = args.injuryFixed ~= false,
        saved = args.saved == true,
        advanced = args.advanced == true,
        amputation = args.amputation == true,
        prosthetic = args.prosthetic == true,
        quarantine = args.quarantine == true,
        pandemic = args.pandemic == true,
        pathology = args.pathology == true,
        pathologySample = args.pathologySample == true,
        signature = args.signature,
    })
    sendProviderStats(player)
end

function FAM_ServerCommands.recordClinicalAssessment(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    FAM.performClinicalAssessment(player, patient)
    sendPatientSnapshot(player, patient)
    if canReadRecords(player, patient) then
        sendRecords(player, patient)
    end
    sendProviderStats(player)
end

function FAM_ServerCommands.requestPatientSnapshot(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    sendPatientSnapshot(player, patient)
end

function FAM_ServerCommands.requestProviderStats(player, args)
    sendProviderStats(player)
end

function FAM_ServerCommands.requestPandemicStatus(player, args)
    sendPandemicStatus(player)
end

function FAM_ServerCommands.requestPathology(player, args)
    sendPathology(player)
end

local function isNearPlayer(player, args)
    if not player or not args or args.x == nil or args.y == nil then return false end
    local dx = math.abs((tonumber(args.x) or 0) - player:getX())
    local dy = math.abs((tonumber(args.y) or 0) - player:getY())
    local dz = math.abs((tonumber(args.z) or 0) - player:getZ())
    return dx <= 3 and dy <= 3 and dz <= 1
end

local function getSquareFromArgs(args)
    if not args or args.x == nil or args.y == nil or args.z == nil then return nil end
    if getCell then
        return getCell():getGridSquare(math.floor(tonumber(args.x) or 0), math.floor(tonumber(args.y) or 0), math.floor(tonumber(args.z) or 0))
    end
    return nil
end

local function resolveCorpse(args)
    local square = getSquareFromArgs(args)
    if not square then return nil end
    local fallback = nil
    if square.getStaticMovingObjects then
        local objects = square:getStaticMovingObjects()
        if objects then
            for i = 0, objects:size() - 1 do
                local object = objects:get(i)
                if object and instanceof and instanceof(object, "IsoDeadBody") then
                    if not fallback then fallback = object end
                    if args.corpseIndex ~= nil
                        and object.getStaticMovingObjectIndex
                        and object:getStaticMovingObjectIndex() == tonumber(args.corpseIndex) then
                        return object
                    end
                end
            end
        end
    end
    if not fallback and square.getDeadBodys then
        local bodies = square:getDeadBodys()
        if bodies then
            for i = 0, bodies:size() - 1 do
                local body = bodies:get(i)
                if body then return body end
            end
        end
    end
    return fallback
end

local function findCharacterItemById(player, itemId)
    return FAM.findCharacterItemById(player, itemId)
end

local function getBodyPartByIndex(patient, bodyPartIndex)
    local index = tonumber(bodyPartIndex)
    if not patient or index == nil then return nil end
    local bodyDamage = FAM.getBodyDamage(patient)
    local bodyParts = bodyDamage and bodyDamage:getBodyParts()
    if not bodyParts then return nil end
    if index >= 0 and index < bodyParts:size() then
        return bodyParts:get(index)
    end
    if BodyPartType and BodyPartType.FromIndex and bodyDamage.getBodyPart then
        return bodyDamage:getBodyPart(BodyPartType.FromIndex(index))
    end
    return nil
end

local function clearBodyPartUser(bodyPart)
    if bodyPart and bodyPart.setManipulatingUsername then
        bodyPart:setManipulatingUsername(nil)
    end
end

local function sendCareSync(player, patient)
    sendProviderStats(player)
    sendPandemicStatus(player)
    sendPatientSnapshot(player, patient)
    if patient and player ~= patient then
        sendPatientSnapshot(patient, patient)
    end
    if canReadRecords(player, patient) then
        sendRecords(player, patient)
    end
end

local function sendCareActionResult(player, action, success, reason)
    if not player or not sendServerCommand then return end
    sendServerCommand(player, FAM.NETWORK_MODULE, "CareActionResult", {
        action = action,
        success = success == true,
        reason = reason,
    })
end

function FAM_ServerCommands.sendCareSync(player, patient)
    sendCareSync(player, patient)
end

function FAM_ServerCommands.sendCareActionResult(player, action, success, reason)
    sendCareActionResult(player, action, success, reason)
end

function FAM_ServerCommands.applyTreatment(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    local bodyPart = getBodyPartByIndex(patient, args.bodyPartIndex)
    local item = findCharacterItemById(player, args.itemId)
    local treatment = tostring(args.treatment or "")
    if not bodyPart or treatment == "" then return end
    local result = FAM.applyTreatment(player, patient, item, bodyPart, treatment)
    clearBodyPartUser(bodyPart)
    if result then
        sendCareSync(player, patient)
    end
end

function FAM_ServerCommands.fieldAmputationStarted(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    local bodyPart = getBodyPartByIndex(patient, args.bodyPartIndex)
    if not bodyPart then return end

    local username = bodyPart:manipulatingUsername()
    if username ~= nil and username ~= "" and username ~= player:getUsername() then
        return
    end

    local valid = FAM.canUseTreatment(player, patient, bodyPart, "amputation")
    if not valid then return end

    bodyPart:setManipulatingUsername(player:getUsername())
    bodyPart:setBleeding(true)
    bodyPart:setCut(true)
    bodyPart:setBleedingTime(math.max(bodyPart:getBleedingTime(), FAM.hasTourniquet(patient, bodyPart) and 4 or 14))
    if syncBodyPart then
        syncBodyPart(bodyPart, 0xFFFFFFFFFFF)
    end
end

function FAM_ServerCommands.fieldAmputationStopped(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    local bodyPart = getBodyPartByIndex(patient, args.bodyPartIndex)
    if not bodyPart then return end

    local username = bodyPart:manipulatingUsername()
    if username == nil or username == "" or username == player:getUsername() then
        clearBodyPartUser(bodyPart)
        if syncBodyPart then
            syncBodyPart(bodyPart, 0xFFFFFFFFFFF)
        end
    end
end

function FAM_ServerCommands.fieldAmputation(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then
        sendCareActionResult(player, "FieldAmputation", false, "Tooltip_FAM_InvalidPatient")
        return
    end
    local bodyPart = getBodyPartByIndex(patient, args.bodyPartIndex)
    local sawItem = findCharacterItemById(player, args.sawItemId) or FAM.findSurgicalSaw(player)
    local stitchItem = findCharacterItemById(player, args.stitchItemId) or FAM.findStitchItem(player)
    local bandageItem = findCharacterItemById(player, args.bandageItemId) or FAM.findBandageItem(player)
    if not bodyPart then
        sendCareActionResult(player, "FieldAmputation", false, "Tooltip_FAM_InvalidPatient")
        return
    end
    if FAM.hasAmputation(patient, bodyPart) then
        clearBodyPartUser(bodyPart)
        sendCareSync(player, patient)
        return
    end
    if not FAM.isItemAnyFullType(sawItem, FAM.SAW_TYPES) then
        clearBodyPartUser(bodyPart)
        sendCareActionResult(player, "FieldAmputation", false, "Tooltip_FAM_MissingSaw")
        return
    end
    local valid, reason = FAM.canUseTreatment(player, patient, bodyPart, "amputation")
    if not valid then
        clearBodyPartUser(bodyPart)
        sendCareActionResult(player, "FieldAmputation", false, reason)
        return
    end
    local result = FAM.performFieldAmputation(player, patient, sawItem, bodyPart, stitchItem, bandageItem)
    clearBodyPartUser(bodyPart)
    if result then
        sendCareSync(player, patient)
    else
        sendCareActionResult(player, "FieldAmputation", false, "Tooltip_FAM_InvalidTreatment")
    end
end

function FAM_ServerCommands.fitProsthetic(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    local bodyPart = getBodyPartByIndex(patient, args.bodyPartIndex)
    local prostheticItem = findCharacterItemById(player, args.prostheticItemId)
    if not bodyPart then return end
    local result = FAM.performFitProsthetic(player, patient, prostheticItem, bodyPart)
    clearBodyPartUser(bodyPart)
    if result then
        sendCareSync(player, patient)
    end
end

function FAM_ServerCommands.removeProsthetic(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    local bodyPart = getBodyPartByIndex(patient, args.bodyPartIndex)
    if not bodyPart then return end
    local result = FAM.performRemoveProsthetic(player, patient, bodyPart)
    clearBodyPartUser(bodyPart)
    if result then
        sendCareSync(player, patient)
    end
end

function FAM_ServerCommands.studyCorpse(player, args)
    if not player or not args or not isNearPlayer(player, args) then return end
    local body = resolveCorpse(args)
    if not body then return end
    local tool = findCharacterItemById(player, args.toolId)
    local journal = findCharacterItemById(player, args.journalId) or FAM.findPathologyJournal(player)
    local success, result = FAM.applyCorpseStudy(player, body, tool, journal, tostring(args.mode or "study"))
    sendPathology(player)
    sendProviderStats(player)
    sendPathologyResult(player, success, result)
end

function FAM_ServerCommands.setPandemicQuarantine(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    FAM.setPandemicQuarantine(player, patient, args.enabled == true)
    sendPandemicStatus(player)
    sendProviderStats(player)
end

function FAM_ServerCommands.treatPandemicCase(player, args)
    local patient = args and getPatient(args.patientId, player, args.patientIsSelf == true) or nil
    if not canWriteNote(player, patient) then return end
    FAM.treatPandemicCase(player, patient)
    sendPandemicStatus(player)
    sendProviderStats(player)
end

function FAM_ServerCommands.onClientCommand(module, command, player, args)
    if module ~= FAM.NETWORK_MODULE then return end
    if command == "SavePatientNote" then
        FAM_ServerCommands.savePatientNote(player, args)
    elseif command == "RequestPatientNote" then
        FAM_ServerCommands.requestPatientNote(player, args)
    elseif command == "RequestPatientRecords" then
        FAM_ServerCommands.requestPatientRecords(player, args)
    elseif command == "RecordProviderOutcome" then
        FAM_ServerCommands.recordProviderOutcome(player, args)
    elseif command == "RecordClinicalAssessment" then
        FAM_ServerCommands.recordClinicalAssessment(player, args)
    elseif command == "RequestPatientSnapshot" then
        FAM_ServerCommands.requestPatientSnapshot(player, args)
    elseif command == "RequestProviderStats" then
        FAM_ServerCommands.requestProviderStats(player, args)
    elseif command == "RequestPandemicStatus" then
        FAM_ServerCommands.requestPandemicStatus(player, args)
    elseif command == "RequestPathology" then
        FAM_ServerCommands.requestPathology(player, args)
    elseif command == "StudyCorpse" then
        FAM_ServerCommands.studyCorpse(player, args)
    elseif command == "SetPandemicQuarantine" then
        FAM_ServerCommands.setPandemicQuarantine(player, args)
    elseif command == "TreatPandemicCase" then
        FAM_ServerCommands.treatPandemicCase(player, args)
    elseif command == "ApplyTreatment" then
        FAM_ServerCommands.applyTreatment(player, args)
    elseif command == "FieldAmputationStarted" then
        FAM_ServerCommands.fieldAmputationStarted(player, args)
    elseif command == "FieldAmputationStopped" then
        FAM_ServerCommands.fieldAmputationStopped(player, args)
    elseif command == "FieldAmputation" then
        FAM_ServerCommands.fieldAmputation(player, args)
    elseif command == "FitProsthetic" then
        FAM_ServerCommands.fitProsthetic(player, args)
    elseif command == "RemoveProsthetic" then
        FAM_ServerCommands.removeProsthetic(player, args)
    end
end

if Events and Events.OnClientCommand and not FAM_ServerCommands._registered then
    FAM_ServerCommands._registered = true
    Events.OnClientCommand.Add(FAM_ServerCommands.onClientCommand)
end

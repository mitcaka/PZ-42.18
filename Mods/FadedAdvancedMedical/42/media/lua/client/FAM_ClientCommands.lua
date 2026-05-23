if isServer() then return end

require "FAM_Core"

FAM_ClientCommands = FAM_ClientCommands or {}
FAM_ClientCommands.providerStatsRows = FAM_ClientCommands.providerStatsRows or {}
FAM_ClientCommands.pandemicStatus = FAM_ClientCommands.pandemicStatus or nil
FAM_ClientCommands.pathologyRecords = FAM_ClientCommands.pathologyRecords or {}
FAM_ClientCommands.pathologySummary = FAM_ClientCommands.pathologySummary or nil
FAM_ClientCommands.patientSnapshots = FAM_ClientCommands.patientSnapshots or {}
FAM_ClientCommands.patientSnapshotsByKey = FAM_ClientCommands.patientSnapshotsByKey or {}
FAM_ClientCommands.pendingVisualItems = FAM_ClientCommands.pendingVisualItems or {}

local function findPatientByOnlineID(patientId)
    if patientId == nil then return nil end
    if getPlayerByOnlineID then
        local patient = getPlayerByOnlineID(tonumber(patientId))
        if patient then return patient end
    end
    if getPlayer and getPlayer() and getPlayer().getOnlineID and tonumber(patientId) == getPlayer():getOnlineID() then
        return getPlayer()
    end
    return nil
end

local function buildNoteArgs(patient, note, author, timestamp)
    return {
        patientId = FAM.getPatientOnlineID(patient),
        patientIsSelf = patient ~= nil and getPlayer and patient == getPlayer(),
        note = FAM.sanitizePatientNote(note),
        updatedBy = author,
        updatedAt = timestamp,
    }
end

function FAM_ClientCommands.savePatientNote(doctor, patient, note)
    if not patient then return false end
    local clean = FAM.sanitizePatientNote(note)
    local author = FAM.getClinicianName(doctor)
    local timestamp = FAM.getNoteTimestamp()
    local multiplayer = isClient and isClient()
    FAM.setPatientNote(patient, clean, author, timestamp, multiplayer, multiplayer)

    if multiplayer and sendClientCommand then
        local sender = doctor or getPlayer()
        if sender and patient.getOnlineID then
            sendClientCommand(sender, FAM.NETWORK_MODULE, "SavePatientNote", buildNoteArgs(patient, clean, author, timestamp))
        end
    end
    return true
end

function FAM_ClientCommands.requestPatientNote(doctor, patient)
    if not isClient or not isClient() or not sendClientCommand or not patient then
        return
    end
    local sender = doctor or getPlayer()
    if sender then
        sendClientCommand(sender, FAM.NETWORK_MODULE, "RequestPatientNote", {
            patientId = FAM.getPatientOnlineID(patient),
            patientIsSelf = patient ~= nil and getPlayer and patient == getPlayer(),
        })
    end
end

function FAM_ClientCommands.requestPatientRecords(doctor, patient)
    if not patient then return end
    if not FAM.hasPatientRecordAccess(doctor) then return end
    if not isClient or not isClient() or not sendClientCommand then
        return
    end
    local sender = doctor or getPlayer()
    if sender then
        sendClientCommand(sender, FAM.NETWORK_MODULE, "RequestPatientRecords", {
            patientId = FAM.getPatientOnlineID(patient),
            patientIsSelf = patient ~= nil and getPlayer and patient == getPlayer(),
        })
    end
end

function FAM_ClientCommands.requestPatientSnapshot(doctor, patient)
    if not patient then return end
    if not isClient or not isClient() or not sendClientCommand then
        return
    end
    local sender = doctor or getPlayer()
    if sender then
        sendClientCommand(sender, FAM.NETWORK_MODULE, "RequestPatientSnapshot", {
            patientId = FAM.getPatientOnlineID(patient),
            patientIsSelf = patient ~= nil and getPlayer and patient == getPlayer(),
        })
    end
end

function FAM_ClientCommands.getPatientSnapshot(patient)
    if not patient then return nil end
    local patientId = FAM.getPatientOnlineID(patient)
    if patientId ~= nil then
        local byId = FAM_ClientCommands.patientSnapshots[tostring(patientId)]
        if byId then return byId end
    end
    return FAM_ClientCommands.patientSnapshotsByKey[FAM.getCharacterKey(patient)]
end

function FAM_ClientCommands.recordProviderOutcome(doctor, patient, outcome)
    if not doctor then return false end
    outcome = outcome or {}
    FAM.applyProviderOutcome(doctor, patient, outcome, isClient and isClient())
    if isClient and isClient() and sendClientCommand then
        sendClientCommand(doctor, FAM.NETWORK_MODULE, "RecordProviderOutcome", {
            patientId = FAM.getPatientOnlineID(patient),
            patientIsSelf = patient ~= nil and doctor == patient,
            patientKey = FAM.getCharacterKey(patient),
            action = outcome.action,
            category = outcome.category,
            bodyPart = outcome.bodyPart,
            injuryFixed = outcome.injuryFixed ~= false,
            saved = outcome.saved == true,
            advanced = outcome.advanced == true,
            amputation = outcome.amputation == true,
            prosthetic = outcome.prosthetic == true,
            quarantine = outcome.quarantine == true,
            pandemic = outcome.pandemic == true,
            pathology = outcome.pathology == true,
            pathologySample = outcome.pathologySample == true,
            signature = outcome.signature,
        })
    end
    return true
end

function FAM_ClientCommands.recordClinicalAssessment(doctor, patient)
    if not patient then return false end
    local sender = doctor or getPlayer()
    if isClient and isClient() and sendClientCommand and sender then
        sendClientCommand(sender, FAM.NETWORK_MODULE, "RecordClinicalAssessment", {
            patientId = FAM.getPatientOnlineID(patient),
            patientIsSelf = patient ~= nil and getPlayer and patient == getPlayer(),
        })
        return true
    end
    return FAM.performClinicalAssessment(sender, patient)
end

function FAM_ClientCommands.requestProviderStats(doctor)
    if isClient and isClient() and sendClientCommand then
        local sender = doctor or getPlayer()
        if sender then
            sendClientCommand(sender, FAM.NETWORK_MODULE, "RequestProviderStats", {})
        end
        return
    end
    FAM_ClientCommands.providerStatsRows = FAM.getProviderStatsRows()
end

function FAM_ClientCommands.requestPandemicStatus(doctor)
    if isClient and isClient() and sendClientCommand then
        local sender = doctor or getPlayer()
        if sender then
            sendClientCommand(sender, FAM.NETWORK_MODULE, "RequestPandemicStatus", {})
        end
        return
    end
    FAM_ClientCommands.pandemicStatus = FAM.getPandemicStatus()
end

function FAM_ClientCommands.requestPathology(doctor)
    if isClient and isClient() and sendClientCommand then
        local sender = doctor or getPlayer()
        if sender then
            sendClientCommand(sender, FAM.NETWORK_MODULE, "RequestPathology", {})
        end
        return
    end
    local provider = doctor or getPlayer()
    FAM_ClientCommands.pathologyRecords = FAM.copyPathologyRecords(provider)
    FAM_ClientCommands.pathologySummary = FAM.getPathologySummary(provider)
end

function FAM_ClientCommands.setPandemicQuarantine(doctor, patient, enabled)
    if not patient then return false end
    if isClient and isClient() and sendClientCommand then
        local sender = doctor or getPlayer()
        if sender then
            sendClientCommand(sender, FAM.NETWORK_MODULE, "SetPandemicQuarantine", {
                patientId = FAM.getPatientOnlineID(patient),
                patientIsSelf = patient ~= nil and getPlayer and patient == getPlayer(),
                enabled = enabled == true,
            })
        end
        return true
    end
    return FAM.setPandemicQuarantine(doctor, patient, enabled)
end

function FAM_ClientCommands.treatPandemicCase(doctor, patient)
    if not patient then return false end
    if isClient and isClient() and sendClientCommand then
        local sender = doctor or getPlayer()
        if sender then
            sendClientCommand(sender, FAM.NETWORK_MODULE, "TreatPandemicCase", {
                patientId = FAM.getPatientOnlineID(patient),
                patientIsSelf = patient ~= nil and getPlayer and patient == getPlayer(),
            })
        end
        return true
    end
    return FAM.treatPandemicCase(doctor, patient)
end

function FAM_ClientCommands.applyPatientNote(args)
    if not args then return end
    local patient = findPatientByOnlineID(args.patientId)
    if not patient then return end
    FAM.setPatientNote(patient, args.note or "", args.updatedBy, args.updatedAt, true, true)
    if FAM_TriagePanel and FAM_TriagePanel.instance and FAM_TriagePanel.instance.patient == patient then
        FAM_TriagePanel.instance:syncNoteFromPatient(false)
    end
end

function FAM_ClientCommands.applyPatientRecords(args)
    if not args then return end
    local patient = findPatientByOnlineID(args.patientId)
    if not patient then return end
    FAM.setPatientNote(patient, args.note or "", args.updatedBy, args.updatedAt, true, true)
    FAM.setPatientNoteRecords(patient, args.records or {}, true)
    FAM.setClinicalRecords(patient, args.clinicalRecords or {}, true)
    FAM.setPatientAnalytics(patient, args.analytics or {}, true)
    if FAM_TriagePanel and FAM_TriagePanel.instance and FAM_TriagePanel.instance.patient == patient then
        FAM_TriagePanel.instance:syncNoteFromPatient(false)
    end
    if FAM_PatientRecordsPanel and FAM_PatientRecordsPanel.instance and FAM_PatientRecordsPanel.instance.patient == patient then
        FAM_PatientRecordsPanel.instance:onRecordsUpdated()
    end
end

function FAM_ClientCommands.applyPatientSnapshot(args)
    if not args then return end
    if args.patientId ~= nil then
        FAM_ClientCommands.patientSnapshots[tostring(args.patientId)] = args
    end
    if args.patientKey then
        FAM_ClientCommands.patientSnapshotsByKey[tostring(args.patientKey)] = args
    end
    if FAM_TriagePanel and FAM_TriagePanel.instance then
        local panel = FAM_TriagePanel.instance
        local panelSnapshot = panel.patient and FAM_ClientCommands.getPatientSnapshot(panel.patient) or nil
        if panelSnapshot == args then
            panel.patientSnapshotTick = (panel.patientSnapshotTick or 0) + 1
        end
    end
end

function FAM_ClientCommands.applyProviderStats(args)
    FAM_ClientCommands.providerStatsRows = args and args.rows or FAM.getProviderStatsRows()
    if FAM_TriagePanel and FAM_TriagePanel.instance then
        FAM_TriagePanel.instance.providerStatsTick = (FAM_TriagePanel.instance.providerStatsTick or 0) + 1
    end
end

function FAM_ClientCommands.applyPandemicStatus(args)
    FAM_ClientCommands.pandemicStatus = args and args.status or FAM.getPandemicStatus()
    if FAM_TriagePanel and FAM_TriagePanel.instance then
        FAM_TriagePanel.instance.pandemicStatusTick = (FAM_TriagePanel.instance.pandemicStatusTick or 0) + 1
    end
end

function FAM_ClientCommands.applyPathology(args)
    local provider = getPlayer and getPlayer() or nil
    FAM_ClientCommands.pathologyRecords = args and args.records or FAM.copyPathologyRecords(provider)
    FAM_ClientCommands.pathologySummary = args and args.summary or FAM.getPathologySummary(provider)
    if provider and args and args.records then
        FAM.setPathologyRecords(provider, args.records, true)
    end
    if FAM_TriagePanel and FAM_TriagePanel.instance then
        FAM_TriagePanel.instance.pathologyTick = (FAM_TriagePanel.instance.pathologyTick or 0) + 1
    end
end

function FAM_ClientCommands.applyPathologyResult(args)
    if not args or args.success ~= true then return end
    local player = getPlayer and getPlayer() or nil
    local text = getText(args.signal and "IGUI_FAM_Halo_PathologySignal" or "IGUI_FAM_Halo_PathologyStudy")
    if HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, text, args.signal and HaloTextHelper.getColorRed() or HaloTextHelper.getColorGreen())
    elseif player and player.Say then
        player:Say(text)
    end
end

function FAM_ClientCommands.applyCareActionResult(args)
    if not args or args.success ~= false then return end
    local player = getPlayer and getPlayer() or nil
    local text = getText(args.reason or "Tooltip_FAM_InvalidTreatment")
    if HaloTextHelper and HaloTextHelper.addBadText then
        HaloTextHelper.addBadText(player, text)
    elseif HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, text, HaloTextHelper.getColorRed())
    elseif player and player.Say then
        player:Say(text)
    end
end

local function queueVisualItem(args)
    if not args or not args.fullType then return end
    args._tries = tonumber(args._tries) or 0
    table.insert(FAM_ClientCommands.pendingVisualItems, args)
end

function FAM_ClientCommands.wearVisualItem(args)
    if not args or not args.fullType then return end
    local patient = findPatientByOnlineID(args.patientId) or (getPlayer and getPlayer() or nil)
    if not patient then return end
    if FAM.wearExistingVisualItem(patient, args.fullType, args.textureChoice) then
        return
    end
    queueVisualItem(args)
end

function FAM_ClientCommands.tickVisualItems()
    local pending = FAM_ClientCommands.pendingVisualItems
    if not pending or #pending == 0 then return end

    local remaining = {}
    for i = 1, #pending do
        local args = pending[i]
        local patient = findPatientByOnlineID(args.patientId) or (getPlayer and getPlayer() or nil)
        local worn = patient and FAM.wearExistingVisualItem(patient, args.fullType, args.textureChoice)
        if not worn then
            args._tries = (tonumber(args._tries) or 0) + 1
            if args._tries < 90 then
                remaining[#remaining + 1] = args
            end
        end
    end
    FAM_ClientCommands.pendingVisualItems = remaining
end

function FAM_ClientCommands.onServerCommand(module, command, args)
    if module ~= FAM.NETWORK_MODULE then return end
    if command == "PatientNoteUpdated" then
        FAM_ClientCommands.applyPatientNote(args)
    elseif command == "PatientRecordsUpdated" then
        FAM_ClientCommands.applyPatientRecords(args)
    elseif command == "PatientSnapshot" then
        FAM_ClientCommands.applyPatientSnapshot(args)
    elseif command == "ProviderStatsUpdated" then
        FAM_ClientCommands.applyProviderStats(args)
    elseif command == "PandemicStatusUpdated" then
        FAM_ClientCommands.applyPandemicStatus(args)
    elseif command == "PathologyUpdated" then
        FAM_ClientCommands.applyPathology(args)
    elseif command == "PathologyStudyResult" then
        FAM_ClientCommands.applyPathologyResult(args)
    elseif command == "CareActionResult" then
        FAM_ClientCommands.applyCareActionResult(args)
    elseif command == "WearVisualItem" then
        FAM_ClientCommands.wearVisualItem(args)
    end
end

if Events and Events.OnServerCommand and not FAM_ClientCommands._registered then
    FAM_ClientCommands._registered = true
    Events.OnServerCommand.Add(FAM_ClientCommands.onServerCommand)
end

if Events and Events.OnTick and not FAM_ClientCommands._visualTickRegistered then
    FAM_ClientCommands._visualTickRegistered = true
    Events.OnTick.Add(FAM_ClientCommands.tickVisualItems)
end

require "TimedActions/ISBaseTimedAction"
require "FAM_Core"
require "FAM_ClientCommands"
require "FAM_TriagePanel"

FAM_MedicalCheckAction = ISBaseTimedAction:derive("FAM_MedicalCheckAction")

function FAM_MedicalCheckAction:isValid()
    if not self.character or not self.patient then
        return false
    end
    return FAM.isMedicalCheat(self.character)
        or (self.patientX == self.patient:getX() and self.patientY == self.patient:getY())
        or (not self.character:isDriving() and ISHealthPanel and ISHealthPanel.IsCharactersInSameCar and ISHealthPanel.IsCharactersInSameCar(self.character, self.patient))
end

function FAM_MedicalCheckAction:waitToStart()
    if self.character:isSeatedInVehicle() then
        return false
    end
    self.character:faceThisObject(self.patient)
    return self.character:shouldBeTurning()
end

function FAM_MedicalCheckAction:update()
    self.character:faceThisObject(self.patient)
    if Metabolics and Metabolics.LightDomestic then
        self.character:setMetabolicTarget(Metabolics.LightDomestic)
    end
end

function FAM_MedicalCheckAction:start()
    self:setActionAnim("MedicalCheck")
    if isClient and isClient()
        and self.patient
        and self.character
        and self.character ~= self.patient
        and self.patient.isLocalPlayer
        and not self.patient:isLocalPlayer()
        and self.character.startReceivingBodyDamageUpdates then
        self.character:startReceivingBodyDamageUpdates(self.patient)
    end
end

function FAM_MedicalCheckAction:stop()
    ISBaseTimedAction.stop(self)
end

function FAM_MedicalCheckAction:perform()
    FAM_ClientCommands.recordClinicalAssessment(self.character, self.patient)
    FAM_TriagePanel.open(self.character, self.patient)
    if self.patient and self.character.startReceivingBodyDamageUpdates then
        self.character:startReceivingBodyDamageUpdates(self.patient)
    end
    ISBaseTimedAction.perform(self)
end

function FAM_MedicalCheckAction:new(doctor, patient)
    local o = ISBaseTimedAction.new(self, doctor)
    o.character = doctor
    o.patient = patient
    o.patientX = patient:getX()
    o.patientY = patient:getY()
    o.maxTime = math.max(45, 150 - (FAM.getEffectiveDoctorLevel(doctor) * 7))
    o.forceProgressBar = true
    if doctor:isTimedActionInstant() then
        o.maxTime = 1
    end
    return o
end

require "TimedActions/ISBaseTimedAction"
local CSR_Standpipe = require "CSR_Standpipe"

CSR_StandpipeToggleAction = ISBaseTimedAction:derive("CSR_StandpipeToggleAction")
CSR_StandpipeToggleAction.soundDelay = 4

local ACTION_SOUND = "AnimalFeederAddWater"
local OPEN_SOUND = "MetalPoleGateDoubleOpen"
local CLOSE_SOUND = "MetalPoleGateClose"

local function playTargetSound(target, soundName)
    local square = target and target.getSquare and target:getSquare() or nil
    if square and square.playSound then
        return square:playSound(soundName)
    end
    return nil
end

local function stopSoundHandle(emitter, handle)
    if handle and emitter and emitter.isPlaying and emitter:isPlaying(handle) then
        emitter:stopSound(handle)
    end
end

function CSR_StandpipeToggleAction:getDuration()
    return CSR_Standpipe.calculateDuration(self.character)
end

function CSR_StandpipeToggleAction:isValid()
    if not self.character or self.character:isDead() then
        return false
    end
    if not self.wrench or self.wrench:isBroken() then
        return false
    end
    if not self.target or not self.target:getSquare() then
        return false
    end
    if not CSR_Standpipe.isStandpipeObject(self.target) then
        return false
    end
    return CSR_Standpipe.isOpen(self.target) ~= self.open
end

function CSR_StandpipeToggleAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function CSR_StandpipeToggleAction:update()
    self.character:faceThisObject(self.target)
    self.character:setMetabolicTarget(Metabolics.HeavyWork)
    self:playActionSound()
end

function CSR_StandpipeToggleAction:playActionSound()
    local now = getTimestamp()
    if self.actionSoundTime ~= 0 and (self.actionSoundTime + CSR_StandpipeToggleAction.soundDelay) > now then
        return
    end

    -- Stop previous loop sound before playing a new one
    self:stopActionSound()

    self.actionSoundTime = now
    local emitter = self.character:getEmitter()
    if emitter then
        self.actionSoundHandle = emitter:playSound(ACTION_SOUND)
    end
end

function CSR_StandpipeToggleAction:stopActionSound()
    local emitter = self.character and self.character:getEmitter() or nil
    stopSoundHandle(emitter, self.actionSoundHandle)
    self.actionSoundHandle = nil
    self.actionSoundTime = 0
end

function CSR_StandpipeToggleAction:start()
    self:setActionAnim("Loot")
    self:setOverrideHandModels(self.wrench, nil)
    self.actionSoundTime = 0
    self.actionSoundHandle = nil
    self:playActionSound()
end

function CSR_StandpipeToggleAction:stop()
    self:stopActionSound()
    ISBaseTimedAction.stop(self)
end

function CSR_StandpipeToggleAction:perform()
    self:stopActionSound()
    local success = CSR_Standpipe.applyAction(self.character, self.target, self.wrench, self.open == true)
    if success then
        playTargetSound(self.target, self.open == true and OPEN_SOUND or CLOSE_SOUND)
    end
    ISBaseTimedAction.perform(self)
end

function CSR_StandpipeToggleAction:new(character, target, wrench, open)
    local o = ISBaseTimedAction.new(self, character)
    o.target = target
    o.wrench = wrench
    o.open = open == true
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    o.useProgressBar = true
    o.ignoreHandsWounds = false
    o.completedSuccessfully = false
    o.actionSoundTime = 0
    return o
end

_G[CSR_StandpipeToggleAction.Type] = CSR_StandpipeToggleAction
return CSR_StandpipeToggleAction

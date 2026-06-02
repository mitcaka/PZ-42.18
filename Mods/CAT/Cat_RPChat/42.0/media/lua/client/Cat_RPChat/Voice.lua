local Config = require("Cat_RPChat/Config")
local Utils = require("Cat_RPChat/Utils")

local Voice = {}
Voice.active = {}

local function isPunctuationMark(letter)
    return letter == "," or letter == "." or letter == "!" or letter == "?" or letter == ":"
end

local function createSoundTable(message)
    local isFirstWordLetter = true
    local soundTable = {}
    local time = 0
    local index = 1
    local msgSize = #message
    while index <= msgSize do
        local soundFile = nil
        local firstLetter = message:sub(index, index)
        if firstLetter == " " then
            index = index + 1
            isFirstWordLetter = true
            time = time + 10
        elseif isPunctuationMark(firstLetter) then
            index = index + 1
            isFirstWordLetter = true
            time = time + Config.PHONEME_DURATION
        else
            local nextLetters = message:sub(index)
            local phoneme, len = Utils.getPhoneme(nextLetters)
            if phoneme == nil then
                index = index + 1
                isFirstWordLetter = true
            else
                soundFile = Utils.soundPath(phoneme, isFirstWordLetter)
                isFirstWordLetter = false
                if len == 1 or phoneme == "OO" then
                    local identicalLetters = nextLetters:match("^(" .. phoneme:sub(1, 1) .. "+)")
                    if identicalLetters then
                        index = index + #identicalLetters
                    else
                        index = index + len
                    end
                else
                    index = index + len
                end
            end
        end
        if soundFile then
            table.insert(soundTable, { time = time, sound = soundFile })
            time = time + Config.PHONEME_DURATION
        end
    end
    return soundTable
end

local VoiceInstance = {}
VoiceInstance.__index = VoiceInstance

function VoiceInstance:new(message, object, pitch)
    local o = {}
    setmetatable(o, self)
    o.message = message:upper()
    o.object = object
    o.pitch = pitch or Config.DEFAULT_PITCH
    o.pitchVariation = 0
    o.soundTable = createSoundTable(o.message)
    o.nextIndex = 1
    o.startTime = Calendar.getInstance():getTimeInMillis()
    o.event = nil
    return o
end

function VoiceInstance:subscribe()
    if self.event then return end
    self.event = function()
        self:update()
    end
    Events.OnTick.Add(self.event)
end

function VoiceInstance:unsubscribe()
    if not self.event then return end
    Events.OnTick.Remove(self.event)
    self.event = nil
end

local MAX_PITCH_VARIATION = 0.05
local MIN_PITCH_VARIATION = -0.05

function VoiceInstance:update()
    if self.nextIndex > #self.soundTable then
        self:unsubscribe()
        return
    end
    local currentTime = Calendar.getInstance():getTimeInMillis()
    local soundPlayed = false
    while not soundPlayed and self.nextIndex <= #self.soundTable do
        local nextSound = self.soundTable[self.nextIndex]
        if currentTime - self.startTime < nextSound.time then
            return
        end
        if nextSound.sound then
            local emitter = getWorld():getFreeEmitter()
            local square = getSquare(self.object:getX(), self.object:getY(), self.object:getZ())
            if square then
                local soundId = emitter:playSoundImpl(nextSound.sound, square)
                if soundId then
                    if self.object.getUsername and self.object:getUsername() == getPlayer():getUsername() then
                        emitter:set3D(soundId, false)
                    end
                    local updatePitch = (ZombRand(80) - 40) / 1000
                    self.pitchVariation = math.min(
                        math.max(self.pitchVariation + updatePitch, MIN_PITCH_VARIATION),
                        MAX_PITCH_VARIATION)
                    emitter:setPitch(soundId, self.pitch + self.pitchVariation)
                end
            end
        end
        self.nextIndex = self.nextIndex + 1
        soundPlayed = true
    end
end

function Voice.play(message, object, pitch)
    if not message or #message == 0 then return end
    local instance = VoiceInstance:new(message, object, pitch)
    instance:subscribe()
    table.insert(Voice.active, instance)
end

-- Cleanup finished voices
local function onTickCleanup()
    for i = #Voice.active, 1, -1 do
        local v = Voice.active[i]
        if not v.event then -- unsubscribed/finished
            table.remove(Voice.active, i)
        end
    end
end

Events.OnTick.Add(onTickCleanup)

return Voice

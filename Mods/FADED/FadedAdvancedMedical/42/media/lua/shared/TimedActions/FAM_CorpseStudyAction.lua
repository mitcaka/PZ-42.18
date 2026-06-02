require "TimedActions/ISBaseTimedAction"
require "FAM_Core"

FAM_CorpseStudyAction = ISBaseTimedAction:derive("FAM_CorpseStudyAction")

local function itemId(item)
    return item and item.getID and item:getID() or nil
end

function FAM_CorpseStudyAction:isValid()
    if not self.corpse or not self.corpse.getSquare or not self.corpse:getSquare() then return false end
    if self.tool and self.toolId and self.character:getInventory():getItemById(self.toolId) == nil then return false end
    if self.journal and self.journalId and self.character:getInventory():getItemById(self.journalId) == nil then return false end
    local valid = FAM.canStudyCorpse(self.character, self.corpse, self.mode, self.tool, self.journal)
    return valid
end

function FAM_CorpseStudyAction:waitToStart()
    self.character:faceThisObject(self.corpse)
    return self.character:shouldBeTurning()
end

function FAM_CorpseStudyAction:update()
    self.character:faceThisObject(self.corpse)
    if self.tool and self.tool.setJobDelta then
        self.tool:setJobDelta(self:getJobDelta())
    end
    if self.journal and self.journal.setJobDelta then
        self.journal:setJobDelta(self:getJobDelta())
    end
    if Metabolics and Metabolics.LightDomestic then
        self.character:setMetabolicTarget(Metabolics.LightDomestic)
    end
end

function FAM_CorpseStudyAction:start()
    if self.toolId then
        self.tool = self.character:getInventory():getItemById(self.toolId)
    end
    if self.journalId then
        self.journal = self.character:getInventory():getItemById(self.journalId)
    end
    local jobType = getText("IGUI_FAM_JobType_PathologyStudy")
    if self.tool and self.tool.setJobType then
        self.tool:setJobType(jobType)
        self.tool:setJobDelta(0)
    end
    if self.journal and self.journal.setJobType then
        self.journal:setJobType(jobType)
        self.journal:setJobDelta(0)
    end
    self.character:SetVariable("LootPosition", "Low")
    self:setActionAnim("Loot")
    self:setOverrideHandModels(self.tool, self.journal)
    self.character:reportEvent("EventLootItem")
    pcall(function()
        self.sound = self.character:playSound("ButcheringGatherMeatSmall")
    end)
end

function FAM_CorpseStudyAction:stopSound()
    if self.sound and self.sound ~= 0 and self.character.getEmitter and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
    end
    self.sound = nil
end

function FAM_CorpseStudyAction:stop()
    self:stopSound()
    if self.tool and self.tool.setJobDelta then self.tool:setJobDelta(0) end
    if self.journal and self.journal.setJobDelta then self.journal:setJobDelta(0) end
    ISBaseTimedAction.stop(self)
end

function FAM_CorpseStudyAction:sendStudyCommand()
    if self.sentCommand then return true end
    self.sentCommand = true
    local square = self.corpse and self.corpse.getSquare and self.corpse:getSquare() or nil
    if not square then return false end
    local args = {
        mode = self.mode,
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        corpseIndex = self.corpse.getStaticMovingObjectIndex and self.corpse:getStaticMovingObjectIndex() or -1,
        toolId = itemId(self.tool),
        journalId = itemId(self.journal),
    }
    if isClient and isClient() and sendClientCommand then
        sendClientCommand(self.character, FAM.NETWORK_MODULE, "StudyCorpse", args)
        return true
    end
    if FAM_ServerCommands and FAM_ServerCommands.studyCorpse then
        FAM_ServerCommands.studyCorpse(self.character, args)
        if FAM_ClientCommands and FAM_ClientCommands.requestPathology then
            FAM_ClientCommands.requestPathology(self.character)
        end
        return true
    end
    local success = FAM.applyCorpseStudy(self.character, self.corpse, self.tool, self.journal, self.mode)
    if FAM_ClientCommands and FAM_ClientCommands.requestPathology then
        FAM_ClientCommands.requestPathology(self.character)
    end
    return success == true
end

function FAM_CorpseStudyAction:perform()
    self:stopSound()
    if self.tool and self.tool.setJobDelta then self.tool:setJobDelta(0) end
    if self.journal and self.journal.setJobDelta then self.journal:setJobDelta(0) end
    self:sendStudyCommand()
    ISBaseTimedAction.perform(self)
end

function FAM_CorpseStudyAction:complete()
    return self:sendStudyCommand()
end

function FAM_CorpseStudyAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    local mode = FAM.PATHOLOGY.MODES[self.mode] or FAM.PATHOLOGY.MODES.study
    local toolProfile = FAM.getPathologyToolProfile(self.tool) or { time = 1.25 }
    local base = self.mode == "autopsy" and 620 or (self.mode == "sample" and 360 or 240)
    return math.max(80, (base - (FAM.getEffectiveDoctorLevel(self.character) * 22)) * (toolProfile.time or 1))
end

function FAM_CorpseStudyAction:new(character, corpse, tool, journal, mode)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.corpse = corpse
    o.tool = tool
    o.journal = journal
    o.mode = mode or "study"
    o.toolId = itemId(tool)
    o.journalId = itemId(journal)
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    o.forceProgressBar = true
    return o
end

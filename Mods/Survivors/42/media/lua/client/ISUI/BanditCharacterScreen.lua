local ok = pcall(require, "XpSystem/ISUI/ISCharacterScreen")
if not ok then
    pcall(require, "ISUI/ISCharacterScreen")
end

if not ISCharacterScreen or not ISCharacterScreen.render then
    return
end

if ISCharacterScreen.__SurvivorsKillCounterPatched then
    return
end
ISCharacterScreen.__SurvivorsKillCounterPatched = true

local function getBanditKillCount()
    if not GetBanditModData or not BanditUtils or not getSpecificPlayer then
        return 0
    end

    local player = getSpecificPlayer(0)
    if not player then
        return 0
    end

    local gmd = GetBanditModData()
    if not gmd or not gmd.Kills then
        return 0
    end

    local id = BanditUtils.GetCharacterID(player)
    if gmd.Kills[id] then
        return gmd.Kills[id]
    else
        return 0
    end
end

-- Backup the original render function
local originalRender = ISCharacterScreen.render

-- Override the render function
function ISCharacterScreen:render()
    -- Call the original render function to retain existing behavior
    originalRender(self)

    local banditSandbox = SandboxVars and SandboxVars.Bandits
    if banditSandbox and banditSandbox.General_KillCounter then
        local h = self:getHeight() - 24
        local smallFontHgt = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
        local offset

        local clock = UIManager.getClock()
        if clock and clock:isDateVisible() then
            offset = smallFontHgt 
        else
            offset = 0
        end

        local banditKills = getBanditKillCount()
        self:drawTextRight(getText("IGUI_Bandits_Bandits_Killed"), 115, h + offset, 1, 1, 1, 1, UIFont.Small)
        self:drawText(tostring(banditKills), 115 + 10, h + offset, 1, 1, 1, 0.5, UIFont.Small)

        self:setHeightAndParentHeight(h + offset + 24)
    end
end

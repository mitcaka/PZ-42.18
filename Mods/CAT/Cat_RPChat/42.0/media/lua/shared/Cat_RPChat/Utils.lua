local Utils = {}
local Config = require("Cat_RPChat/Config")

function Utils.colorTag(color)
    return string.format(" <RGB:%.3f,%.3f,%.3f> ", color[1]/255, color[2]/255, color[3]/255)
end

function Utils.colorTagInline(color)
    return string.format("<RGB:%.3f,%.3f,%.3f>", color[1]/255, color[2]/255, color[3]/255)
end

function Utils.colorTagWithSpace(color)
    return string.format("<RGB:%.3f,%.3f,%.3f>", color[1]/255, color[2]/255, color[3]/255) .. "\194\160"
end

function Utils.formatChatText(message, msgColor, emoteColor)
    local result = ""
    local inEmote = false
    local i = 1
    while i <= #message do
        if message:sub(i, i+1) == "**" then
            inEmote = not inEmote
            if inEmote then
                -- Entering emote: switch to emote color, then add **
                result = result .. Utils.colorTagWithSpace(emoteColor) .. "**"
            else
                -- Exiting emote: add **, a separating space, then switch back to msg color
                -- The space prevents ISRichTextPanel from swallowing ** into the tag token
                result = result .. "** " .. Utils.colorTagWithSpace(msgColor)
            end
            i = i + 2
        else
            result = result .. message:sub(i, i)
            i = i + 1
        end
    end
    return result
end

function Utils.stripEmotes(message)
    return message:gsub("%*%*(.-)%*%*", "%1")
end

function Utils.parseEmotes(message, defaultColor, emoteColor)
    local dc = Utils.colorTag(defaultColor)
    local ec = Utils.colorTag(emoteColor)
    local chat = dc
    local bubble = ""
    local inEmote = false
    local i = 1
    while i <= #message do
        if message:sub(i, i+1) == "**" then
            inEmote = not inEmote
            chat = chat .. (inEmote and ec or dc)
            i = i + 2
        else
            local c = message:sub(i, i)
            chat = chat .. c
            bubble = bubble .. c
            i = i + 1
        end
    end
    if inEmote then
        chat = chat .. dc
    end
    local raw = message:gsub("%*", ""):upper()
    return chat, bubble, raw
end

function Utils.getPhoneme(nextLetters)
    local firstLetter = nextLetters:sub(1, 1):upper()
    local phonemes = Config.Phonemes[firstLetter]
    if not phonemes then
        return nil, 1
    end
    for _, phoneme in ipairs(phonemes) do
        if #nextLetters >= #phoneme and nextLetters:sub(1, #phoneme) == phoneme then
            return phoneme, #phoneme
        end
    end
    return nil, 1
end

function Utils.soundPath(phoneme, isFirstWordLetter)
    local filePhoneme
    if phoneme == "K" or phoneme == "Q" then
        filePhoneme = "C"
    elseif phoneme == "Y" and isFirstWordLetter then
        filePhoneme = "YStart"
    else
        filePhoneme = phoneme
    end
    return Config.SOUND_PREFIX .. filePhoneme
end

function Utils.distance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx*dx + dy*dy)
end

function Utils.wrapBubbleText(text, font, maxWidth)
    local tm = getTextManager()
    local result = ""
    local i = 1

    while i <= #text do
        local tagStart, tagEnd = text:find("<RGB:[^>]+>", i)
        if tagStart == i then
            result = result .. text:sub(tagStart, tagEnd)
            i = tagEnd + 1
        else
            local wordEnd = i
            while wordEnd <= #text do
                local nextChar = text:sub(wordEnd, wordEnd)
                if nextChar == " " then
                    break
                end
                if nextChar == "<" then
                    local ts, te = text:find("<RGB:[^>]+>", wordEnd)
                    if ts == wordEnd then
                        break
                    end
                end
                wordEnd = wordEnd + 1
            end

            local word = text:sub(i, wordEnd - 1)
            local wordWidth = tm:MeasureStringX(font, word)

            if wordWidth > maxWidth then
                local chunk = ""
                local chunkWidth = 0
                for j = 1, #word do
                    local char = word:sub(j, j)
                    local charWidth = tm:MeasureStringX(font, char)
                    if chunkWidth + charWidth > maxWidth and #chunk > 0 then
                        result = result .. chunk .. " <LINE> "
                        chunk = char
                        chunkWidth = charWidth
                    else
                        chunk = chunk .. char
                        chunkWidth = chunkWidth + charWidth
                    end
                end
                result = result .. chunk
            else
                result = result .. word
            end

            i = wordEnd
            if i <= #text and text:sub(i, i) == " " then
                result = result .. " "
                i = i + 1
            end
        end
    end

    return result
end

return Utils

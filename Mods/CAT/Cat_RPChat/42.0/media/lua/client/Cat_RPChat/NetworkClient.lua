local Config = require("Cat_RPChat/Config")
local ClientConfig = require("Cat_RPChat/ClientConfig")
local Bubble = require("Cat_RPChat/Bubble")
local Voice = require("Cat_RPChat/Voice")

local NetworkClient = {}

function NetworkClient.addChatLine(text, tabID)
    local chat = ISChat.instance
    if not chat then return end
    local panel = chat.chatText
    if not panel or not panel.paginate then
        panel = chat.defaultTab
    end
    if not panel or not panel.paginate then
        panel = chat.tabs and chat.tabs[1]
    end
    if not panel or not panel.paginate then return end

    if not panel.chatTextLines then panel.chatTextLines = {} end
    table.insert(panel.chatTextLines, text .. " <LINE> ")

    if ISChat.maxLine and #panel.chatTextLines > ISChat.maxLine then
        local newLines = {}
        for i, v in ipairs(panel.chatTextLines) do
            if i ~= 1 then
                table.insert(newLines, v)
            end
        end
        panel.chatTextLines = newLines
    end

    panel.text = ""
    for i, v in ipairs(panel.chatTextLines) do
        if i == #panel.chatTextLines then
            v = string.gsub(v, " <LINE> $", "")
        end
        panel.text = panel.text .. v
    end

    local savedFont = panel.font
    local savedDefault = panel.defaultFont
    panel:paginate()
    if savedDefault then
        panel.font = savedDefault
    elseif savedFont then
        panel.font = savedFont
    end
    panel:setYScroll(-10000)
end

function NetworkClient.onServerCommand(module, command, args)
    if module ~= Config.MOD_NAME then return end
    if command == "ChatMessage" then
        local localPlayer = getPlayer()
        if args.author and localPlayer and args.author == localPlayer:getUsername() then
            return -- already handled locally
        end
        NetworkClient.addChatLine(args.text, args.tabID or 1)
        if args.bubbleText and args.channel ~= "ooc" then
            local player = nil
            if args.author then
                local online = getOnlinePlayers()
                for i = 0, online:size() - 1 do
                    local p = online:get(i)
                    if p:getUsername() == args.author then
                        player = p
                        break
                    end
                end
            end
            if player then
                local display = args.bubbleDisplay or args.bubbleText
                Bubble.create(player, display, args.channel, args.pitch or Config.DEFAULT_PITCH)
                if ClientConfig.isVoiceEnabled() then
                    Voice.play(args.bubbleText:gsub("%*", ""):upper(), player, args.pitch or Config.DEFAULT_PITCH)
                end
            end
        end
    elseif command == "Typing" then
        if not args.author then return end
        local localPlayer = getPlayer()
        if localPlayer and args.author == localPlayer:getUsername() then return end

        local online = getOnlinePlayers()
        local authorObj = nil
        for i = 0, online:size() - 1 do
            local p = online:get(i)
            if p:getUsername() == args.author then
                authorObj = p
                break
            end
        end
        if not authorObj then return end

        local TypingDots = require("Cat_RPChat/TypingDots")
        Cat_RPChat_TypingDots = Cat_RPChat_TypingDots or {}
        if Cat_RPChat_TypingDots[args.author] then
            Cat_RPChat_TypingDots[args.author]:refresh()
        else
            Cat_RPChat_TypingDots[args.author] = TypingDots:new(authorObj, 1)
        end
    end
end

Events.OnServerCommand.Add(NetworkClient.onServerCommand)

return NetworkClient

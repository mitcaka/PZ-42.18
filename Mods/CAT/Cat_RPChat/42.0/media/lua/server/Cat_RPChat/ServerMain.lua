local Config = require("Cat_RPChat/Config")
local Utils = require("Cat_RPChat/Utils")

local ServerMain = {}
ServerMain.profiles = {}

local function getProfilesModData()
    return ModData.getOrCreate("Cat_RPChat_Profiles")
end

function ServerMain.setProfile(player, args)
    local username = player:getUsername()
    local data = getProfilesModData()
    data[username] = {
        displayName = args.displayName or username,
        color = args.color or Config.DEFAULT_NAME_COLOR,
        pitch = args.pitch or Config.DEFAULT_PITCH,
    }
    ModData.add("Cat_RPChat_Profiles", data)
    ServerMain.profiles[username] = data[username]

    -- Broadcast profile update to all online players
    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        sendServerCommand(p, Config.MOD_NAME, "UpdateProfile", {
            username = username,
            displayName = data[username].displayName,
            color = data[username].color,
            pitch = data[username].pitch,
        })
    end
end

function ServerMain.sendAllProfiles(player)
    local data = getProfilesModData()
    for username, profile in pairs(data) do
        sendServerCommand(player, Config.MOD_NAME, "UpdateProfile", {
            username = username,
            displayName = profile.displayName,
            color = profile.color,
            pitch = profile.pitch,
        })
    end
end

function ServerMain.getProfile(username)
    if ServerMain.profiles[username] then
        return ServerMain.profiles[username]
    end
    local data = getProfilesModData()
    if data[username] then
        ServerMain.profiles[username] = data[username]
        return data[username]
    end
    return {
        displayName = username,
        color = Config.DEFAULT_NAME_COLOR,
        pitch = Config.DEFAULT_PITCH,
    }
end

function ServerMain.sendChatToPlayer(player, text, tabID)
    sendServerCommand(player, Config.MOD_NAME, "ChatMessage", {
        text = text,
        tabID = tabID or 1,
    })
end

function ServerMain.broadcastTyping(sender, args)
    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p:getUsername() ~= sender:getUsername() then
            sendServerCommand(p, Config.MOD_NAME, "Typing", {
                author = sender:getUsername(),
            })
        end
    end
end

function ServerMain.broadcastChat(sender, args)
    local channelName = args.channel or "say"
    local channel = nil
    for _, ch in pairs(Config.CHANNELS) do
        if ch.name == channelName then
            channel = ch
            break
        end
    end
    if not channel then return end

    local profile = ServerMain.getProfile(sender:getUsername())
    local text = args.text or ""
    if #text == 0 then return end

    local dc = channel.color
    local nc = profile.color
    local name = profile.displayName
    local chatBody = Utils.formatChatText(text, dc, Config.EMOTE_COLOR)
    local _, bubbleParsed, rawParsed = Utils.parseEmotes(text, dc, Config.EMOTE_COLOR)

    local formatted = ""
    local bubbleText = bubbleParsed

    if channelName == "me" then
        formatted = Utils.colorTagInline(dc) .. "* " .. name .. " " .. chatBody .. " *"
        bubbleText = "* " .. name .. " " .. bubbleParsed .. " *"
    elseif channelName == "ooc" then
        formatted = Utils.colorTagInline(dc) .. "(( " .. name .. ": " .. chatBody .. " ))"
        bubbleText = "(( " .. name .. ": " .. bubbleParsed .. " ))"
    elseif channelName == "all" then
        formatted = Utils.colorTagInline(nc) .. name .. " (Global): " .. Utils.colorTagWithSpace(dc) .. chatBody
        bubbleText = bubbleParsed
    else
        formatted = Utils.colorTagInline(nc) .. name .. " " .. channel.prefix .. ": " .. Utils.colorTagWithSpace(dc) .. chatBody
        bubbleText = bubbleParsed
    end

    local bubbleDisplay = Utils.colorTagWithSpace(dc) .. Utils.formatChatText(text, dc, Config.EMOTE_COLOR)

    local packet = {
        text = formatted,
        bubbleText = bubbleText,
        bubbleDisplay = bubbleDisplay,
        author = sender:getUsername(),
        channel = channelName,
        pitch = profile.pitch,
        x = sender:getX(),
        y = sender:getY(),
        z = sender:getZ(),
        tabID = 1,
    }

    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p:getUsername() == sender:getUsername() then
            -- skip sender, they already have local echo
        else
            local shouldReceive = false
            if channel.range <= 0 then
                shouldReceive = true
            else
                local dist = Utils.distance(sender:getX(), sender:getY(), p:getX(), p:getY())
                if dist <= channel.range then
                    shouldReceive = true
                end
            end
            if shouldReceive then
                sendServerCommand(p, Config.MOD_NAME, "ChatMessage", packet)
            end
        end
    end
end

function ServerMain.onClientCommand(module, command, player, args)
    if module ~= Config.MOD_NAME then return end
    if command == "SetProfile" then
        ServerMain.setProfile(player, args)
    elseif command == "ChatMessage" then
        ServerMain.broadcastChat(player, args)
    elseif command == "Typing" then
        ServerMain.broadcastTyping(player, args)
    elseif command == "RequestProfiles" then
        ServerMain.sendAllProfiles(player)
    end
end

Events.OnClientCommand.Add(ServerMain.onClientCommand)

return ServerMain

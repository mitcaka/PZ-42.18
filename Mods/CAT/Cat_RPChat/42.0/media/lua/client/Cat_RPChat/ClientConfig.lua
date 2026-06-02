local Config = require("Cat_RPChat/Config")

local ClientConfig = {}
ClientConfig.data = {
    displayName = nil,
    color = Config.DEFAULT_NAME_COLOR,
    pitch = Config.DEFAULT_PITCH,
    voiceEnabled = true,
}

local FILE_NAME = "Cat_RPChat_config.txt"

function ClientConfig.load()
    local reader = getFileReader(FILE_NAME, true)
    if not reader then return end
    while true do
        local line = reader:readLine()
        if not line then break end
        local key, value = line:match("^(%w+)=(.*)$")
        if key and value and #value > 0 then
            if key == "displayName" then
                ClientConfig.data.displayName = value
            elseif key == "colorR" then
                ClientConfig.data.color[1] = tonumber(value) or 255
            elseif key == "colorG" then
                ClientConfig.data.color[2] = tonumber(value) or 255
            elseif key == "colorB" then
                ClientConfig.data.color[3] = tonumber(value) or 255
            elseif key == "pitch" then
                ClientConfig.data.pitch = tonumber(value) or Config.DEFAULT_PITCH
            elseif key == "channel" then
                ClientConfig.data.channel = value
            elseif key == "voiceEnabled" then
                ClientConfig.data.voiceEnabled = value == "true"
            end
        end
    end
    reader:close()
end

function ClientConfig.save()
    local writer = getFileWriter(FILE_NAME, true, false)
    if not writer then return end
    writer:write("displayName=" .. (ClientConfig.data.displayName or "") .. "\n")
    writer:write("colorR=" .. (ClientConfig.data.color[1] or 255) .. "\n")
    writer:write("colorG=" .. (ClientConfig.data.color[2] or 255) .. "\n")
    writer:write("colorB=" .. (ClientConfig.data.color[3] or 255) .. "\n")
    writer:write("pitch=" .. (ClientConfig.data.pitch or Config.DEFAULT_PITCH) .. "\n")
    writer:write("channel=" .. (ClientConfig.data.channel or "say") .. "\n")
    writer:write("voiceEnabled=" .. tostring(ClientConfig.data.voiceEnabled) .. "\n")
    writer:close()
end

function ClientConfig.getDisplayName()
    if ClientConfig.data.displayName and #ClientConfig.data.displayName > 0 then
        return ClientConfig.data.displayName
    end
    local player = getPlayer()
    if not player then return "Unknown" end
    return player:getDescriptor():getForename() .. " " .. player:getDescriptor():getSurname()
end

function ClientConfig.getColor()
    return ClientConfig.data.color
end

function ClientConfig.getPitch()
    return ClientConfig.data.pitch
end

function ClientConfig.getChannel()
    return ClientConfig.data.channel or "say"
end

function ClientConfig.setChannel(channel)
    ClientConfig.data.channel = channel
    ClientConfig.save()
end

function ClientConfig.isVoiceEnabled()
    return ClientConfig.data.voiceEnabled ~= false
end

function ClientConfig.setVoiceEnabled(enabled)
    ClientConfig.data.voiceEnabled = enabled == true
    ClientConfig.save()
end

function ClientConfig.setDisplayName(name)
    ClientConfig.data.displayName = name
    ClientConfig.save()
    ClientConfig.sendProfile()
end

function ClientConfig.setColor(r, g, b)
    ClientConfig.data.color = {r, g, b}
    ClientConfig.save()
    ClientConfig.sendProfile()
end

function ClientConfig.setPitch(pitch)
    ClientConfig.data.pitch = math.max(0.5, math.min(2.0, pitch))
    ClientConfig.save()
    ClientConfig.sendProfile()
end

function ClientConfig.sendProfile()
    local player = getPlayer()
    if not player then return end
    sendClientCommand(Config.MOD_NAME, "SetProfile", {
        displayName = ClientConfig.getDisplayName(),
        color = ClientConfig.data.color,
        pitch = ClientConfig.data.pitch,
    })
end

function ClientConfig.onGameStart()
    local reader = getFileReader(FILE_NAME, true)
    local fileExisted = reader ~= nil
    if reader then reader:close() end

    ClientConfig.load()

    if not fileExisted then
        if player and player:getDescriptor():isFemale() then
            ClientConfig.data.pitch = 1.3
            ClientConfig.save()
        end
    end

    -- Network might not be ready immediately; use a tick retry
    local ticks = 0
    local function trySend()
        ticks = ticks + 1
        local player = getPlayer()
        if player and player:getSquare() then
            ClientConfig.sendProfile()
            Events.OnTick.Remove(trySend)
        elseif ticks > 120 then -- ~2 seconds
            Events.OnTick.Remove(trySend)
        end
    end
    Events.OnTick.Add(trySend)
end

Events.OnGameStart.Add(ClientConfig.onGameStart)
Events.OnCreatePlayer.Add(ClientConfig.onGameStart)

return ClientConfig

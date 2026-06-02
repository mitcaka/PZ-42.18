local Config = require("Cat_RPChat/Config")

local NameTag = {}
NameTag.profiles = {}

function NameTag.setProfile(username, profile)
    NameTag.profiles[username] = profile
end

function NameTag.getProfile(username)
    return NameTag.profiles[username] or {
        displayName = username,
        color = Config.DEFAULT_NAME_COLOR,
        pitch = Config.DEFAULT_PITCH,
    }
end

function NameTag.onServerCommand(module, command, args)
    if module ~= Config.MOD_NAME then return end
    if command == "UpdateProfile" then
        NameTag.setProfile(args.username, {
            displayName = args.displayName,
            color = args.color,
            pitch = args.pitch,
        })
    end
end

Events.OnServerCommand.Add(NameTag.onServerCommand)

-- Request all profiles when joining a game
local function requestProfiles()
    local player = getPlayer()
    if player then
        sendClientCommand(Config.MOD_NAME, "RequestProfiles", {})
    end
end

Events.OnGameStart.Add(requestProfiles)

return NameTag

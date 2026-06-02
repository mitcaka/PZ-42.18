ZSClient = {}
ZSClient.Commands = {}

ZSClient.Commands.UpdateVehicle = function(args)
    for i=0, 100 do
        local vehicleList = getCell():getVehicles():toArray()
        for _, vehicle in pairs(vehicleList) do
            if vehicle:getId() == args.id then
                if vehicle:hasLightbar() then 
                    if args.lightbar then
                        vehicle:setLightbarLightsMode(args.lightbar)
                    end
                    if args.siren then
                        vehicle:setLightbarSirenMode(args.siren)
                    end
                end 

                if args.alarm then
                    vehicle:setAlarmed(true)
                    vehicle:triggerAlarm()
                end
                return
            end
        end
    end
end

ZSClient.Commands.UpdateHealth  = function(args)
    local id = args.id
    if id then
        local zombie = BanditZombie.Cache[id]
        if zombie then
            local health = zombie:getHealth()
            print ("CLIENT HEALTH CURRENT: " .. health .. " NEW:" .. args.h)
            if health > args.h then
                zombie:setHealth(args.h)
            end
        end
    end
end

ZSClient.Commands.SendCustomToClients = function(args)
    BanditCustom.banditData = args.banditData
    BanditCustom.clanData = args.clanData
    BanditCustom.Save()
end

ZSClient.Commands.SetMarker  = function(args)
    BanditEventMarkerHandler.set(getRandomUUID(), args.icon, args.time, args.x, args.y, args.color, args.desc)
end

local function getLocalPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

local function playerOwnsPayload(player, args)
    if not player or not args or not args.ownerId or not BanditUtils then return true end
    return tonumber(args.ownerId) == tonumber(BanditUtils.GetCharacterID(player))
end

local function sayToPlayer(args, text)
    local player = getLocalPlayer()
    if player and playerOwnsPayload(player, args) then
        pcall(function() player:Say(text) end)
    end
end

ZSClient.Commands.SurvivorZoneNotice = function(args)
    local text = args and args.text or "Survivor zone updated."
    sayToPlayer(args, tostring(text))
    print("[Survivors] " .. tostring(text))
end

ZSClient.Commands.RecruitableSurvivorNotice = function(args)
    local text = args and args.text or "Recruitable survivor updated."
    sayToPlayer(args, tostring(text))
    print("[Survivors] " .. tostring(text))
end

ZSClient.Commands.SurvivorTradeSnapshot = function(args)
    if not playerOwnsPayload(getLocalPlayer(), args) then return end
    if SurvivorTradeWindow and SurvivorTradeWindow.receiveServerStock then
        SurvivorTradeWindow.receiveServerStock(args)
    end
    if args and args.announce and args.message and args.message ~= "" then
        sayToPlayer(args, tostring(args.message))
    end
end

ZSClient.Commands.SurvivorLootRunStarted = function(args)
    local label = args and (args.categoryLabel or args.category) or "supplies"
    sayToPlayer(args, "Loot run started: " .. tostring(label) .. ".")
    if SurvivorsCommandWindow and SurvivorsCommandWindow.refreshOpen then
        SurvivorsCommandWindow.refreshOpen()
    end
end

ZSClient.Commands.SurvivorLootRunCompleted = function(args)
    local name = args and args.npcName or "A survivor"
    sayToPlayer(args, tostring(name) .. " returned from a loot run.")
    if SurvivorsCommandWindow and SurvivorsCommandWindow.refreshOpen then
        SurvivorsCommandWindow.refreshOpen()
    end
end

ZSClient.Commands.SurvivorLootRunCollected = function(args)
    sayToPlayer(args, "Loot run supplies collected.")
    if SurvivorsCommandWindow and SurvivorsCommandWindow.refreshOpen then
        SurvivorsCommandWindow.refreshOpen()
    end
end

ZSClient.Commands.SurvivorLootRunRejected = function(args)
    local reason = args and tostring(args.reason or "") or ""
    local message = "Loot run unavailable."
    if reason == "alreadyRunning" then
        message = "That survivor is already on a loot run."
    elseif reason == "noBase" then
        message = "Assign that survivor to a base first."
    elseif reason == "notReady" then
        message = "That survivor has not returned yet."
    elseif reason == "wrongOwner" then
        message = "That survivor is assigned to someone else."
    end
    sayToPlayer(args, message)
    if SurvivorsCommandWindow and SurvivorsCommandWindow.refreshOpen then
        SurvivorsCommandWindow.refreshOpen()
    end
end

local onServerCommand = function(module, command, args)
    if ZSClient[module] and ZSClient[module][command] then
        local argStr = ""
        for k, v in pairs(args) do
            argStr = argStr .. " " .. k .. "=" .. tostring(v)
        end
        -- print ("client received " .. module .. "." .. command .. " "  .. argStr)
        ZSClient[module][command](args)
    end
end

Events.OnServerCommand.Add(onServerCommand)

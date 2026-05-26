-- FHC_ClientMain.lua
-- Client entry. Wires the hotkey, the server-command listener and the GUI instance.

require "FHC_Constants"
require "FHC_Utils"
require "FHC_Sandbox"

if isServer() then return end

FHC.Client = FHC.Client or {}
local C = FHC.Client
local U = FHC.Utils
local SB = FHC.SB

-- Latest server-pushed admin data lives here for the GUI to read.
C.adminData = { popCounts = nil, lastCullResult = nil }
C.trapRows = C.trapRows or {}
C.trapRowsAt = C.trapRowsAt or 0
C.lastTrackingResult = C.lastTrackingResult or nil

local function onServerCommand(module, command, args)
    if module ~= FHC.MODULE then return end
    if command == "popReportResult" then
        C.adminData.popCounts = args and args.counts or {}
    elseif command == "popCullResult" then
        C.adminData.lastCullResult = args
    elseif command == FHC.CMD.ApplyScentResult then
        local player = getSpecificPlayer and getSpecificPlayer(0) or (getPlayer and getPlayer() or nil)
        if player and player.Say then
            if args and args.ok then
                player:Say(getText("IGUI_FHC_ScentApplied"))
            else
                player:Say(getText("IGUI_FHC_ScentRejected"))
            end
        end
    elseif command == FHC.CMD.AnimalCallResult then
        local player = getSpecificPlayer and getSpecificPlayer(0) or (getPlayer and getPlayer() or nil)
        if player and args and args.cooldownUntil and args.animal then
            local md = player:getModData()
            local cooldowns = md[FHC.MD.PlayerAnimalCallCooldown]
            if type(cooldowns) ~= "table" then cooldowns = {} end
            cooldowns[args.animal] = args.cooldownUntil
            md[FHC.MD.PlayerAnimalCallCooldown] = cooldowns
        end
        if player and player.Say then
            if args and args.ok then
                U.playAnimalCallSound(player, args.animal)
                local display = FHC.ANIMALS[args.animal] and FHC.ANIMALS[args.animal].display or tostring(args.animal)
                player:Say(string.format(getText("IGUI_FHC_CallUsedFmt"), display))
            elseif args and args.reason == "locked" then
                player:Say(getText("IGUI_FHC_CallLocked"))
            elseif args and args.reason == "cooldown" then
                player:Say(getText("IGUI_FHC_CallCooldown"))
            else
                player:Say(getText("IGUI_FHC_CallRejected"))
            end
        end
    elseif command == FHC.CMD.TrackingScanResult then
        C.lastTrackingResult = args
        if FHC.Scan and FHC.Scan.receiveServerResults then
            FHC.Scan.receiveServerResults(args and args.rows or {}, args and args.radius or 0)
        end
    elseif command == FHC.CMD.TrapBoardResult then
        C.trapRows = args and args.rows or {}
        C.trapRowsAt = getTimestampMs and getTimestampMs() or 0
    end
end
Events.OnServerCommand.Add(onServerCommand)

-- Single GUI instance toggle.
function C.toggleGUI()
    if not SB.guiEnabled() then return end
    if not FHC.UI or not FHC.UI.Main then
        U.warn("UI not loaded")
        return
    end
    FHC.UI.Main.toggle()
end

-- Hotkey: open the GUI. Registered through ISKeyBindings (vanilla key-binding system).
local function onKeyPressed(key)
    if not SB.hotkeyEnabled() then return end
    if key == getCore():getKey("FHC_OpenJournal") then
        C.toggleGUI()
    end
end
Events.OnKeyPressed.Add(onKeyPressed)

-- Register the keybinding row so it appears in Options > Key Bindings.
local function registerKeyBinding()
    local kb = { keyName = "FHC_OpenJournal", key = Keyboard.KEY_H }
    if not getCore():getKey("FHC_OpenJournal") then
        table.insert(keyBinding, { value = "[Faded's Hunters Calling]" })
        table.insert(keyBinding, kb)
    end
end
Events.OnGameBoot.Add(registerKeyBinding)

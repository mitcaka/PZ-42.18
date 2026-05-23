if isServer() then return end

require "keyBinding"
require "FAM_TriagePanel"

FAM_Keybinds = FAM_Keybinds or {}
FAM_Keybinds.OPEN_TRIAGE = "FAM_OPEN_TRIAGE"

local function hasBinding(value)
    if not keyBinding then return false end
    for i = 1, #keyBinding do
        if keyBinding[i] and keyBinding[i].value == value then
            return true
        end
    end
    return false
end

local function registerBinding()
    if not keyBinding or hasBinding(FAM_Keybinds.OPEN_TRIAGE) then
        return
    end
    if not hasBinding("[FAM]") then
        table.insert(keyBinding, { value = "[FAM]" })
    end
    table.insert(keyBinding, {
        value = FAM_Keybinds.OPEN_TRIAGE,
        key = Keyboard.KEY_RCONTROL,
    })
end

local function getLocalPlayer()
    if getSpecificPlayer then
        local player = getSpecificPlayer(0)
        if player then return player end
    end
    return getPlayer and getPlayer() or nil
end

function FAM_Keybinds.toggleTriage()
    if FAM_TriagePanel.instance and FAM_TriagePanel.instance:getIsVisible() then
        FAM_TriagePanel.instance:onClose()
        return
    end

    local player = getLocalPlayer()
    if player then
        FAM_TriagePanel.open(player, player)
    end
end

local function onKeyPressed(key)
    if key ~= getCore():getKey(FAM_Keybinds.OPEN_TRIAGE) then
        return
    end
    FAM_Keybinds.toggleTriage()
end

registerBinding()

if Events and Events.OnKeyPressed and not FAM_Keybinds._registered then
    FAM_Keybinds._registered = true
    Events.OnKeyPressed.Add(onKeyPressed)
end

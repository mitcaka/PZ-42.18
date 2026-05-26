local config = {
    keyBind   = nil,
    checkBox  = nil,
    textEntry = nil,
    multiBox  = nil,
    comboBox  = nil,
    colorPick = nil,
    slider    = nil,
    button    = nil
}

local options = PZAPI.ModOptions:create("Bandits", getText("UI_optionscreen_binding_Bandits"))
options:addTitle("Survivors")
local defaultPostsKey = (Keyboard and Keyboard.KEY_G) or 34
config.keyBind = options:addKeyBind("POSTS", getText("UI_optionscreen_binding_POSTS"), defaultPostsKey, getText("UI_optionscreen_binding_POSTS"))

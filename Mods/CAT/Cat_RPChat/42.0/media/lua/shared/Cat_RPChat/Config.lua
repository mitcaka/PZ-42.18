local Config = {}

Config.MOD_NAME = "Cat_RPChat"
Config.VERSION = "1.0.0"
Config.SOUND_PREFIX = "Cat_RPChat_Voice_"

Config.CHANNELS = {
    SAY     = { name = "say",     range = 30,  color = {255, 255, 255}, prefix = "says" },
    WHISPER = { name = "whisper", range = 3,   color = {249, 43, 251},  prefix = "whispers" },
    YELL    = { name = "yell",    range = 60,  color = {255, 85, 85},   prefix = "yells" },
    ALL     = { name = "all",     range = -1,  color = {230, 230, 50},  prefix = "Says" },
    ME      = { name = "me",      range = 30,  color = {193, 85, 255},  prefix = nil },
    OOC     = { name = "ooc",     range = -1,  color = {150, 150, 150}, prefix = nil },
}

Config.EMOTE_COLOR = {180, 100, 255}
Config.DEFAULT_PITCH = 1.0
Config.DEFAULT_NAME_COLOR = {255, 255, 255}
Config.BUBBLE_TIMER = 5000
Config.BUBBLE_OPACITY = 80
Config.PHONEME_DURATION = 95

Config.Phonemes = {
    A = { "AIR", "AI", "AR", "A" },
    B = { "B" },
    C = { "CH", "C" },
    D = { "D" },
    E = { "ERE", "EE", "ER", "E" },
    F = { "F" },
    G = { "G" },
    H = { "H" },
    I = { "IS", "IR", "I" },
    J = { "J" },
    K = { "K" },
    L = { "L" },
    M = { "M" },
    N = { "NG", "N" },
    O = { "OOR", "OO", "OW", "OY", "O" },
    P = { "P" },
    Q = { "Q" },
    R = { "R" },
    S = { "SH", "S" },
    T = { "TH", "T" },
    U = { "UR", "U" },
    V = { "V" },
    W = { "W" },
    X = { "X " },
    Y = { "Y" },
    Z = { "Z" },
}

Config.Alphabet = { "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z" }

return Config

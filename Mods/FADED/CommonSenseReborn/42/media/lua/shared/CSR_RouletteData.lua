--[[
    CSR_RouletteData — shared constants for the MP Russian Roulette session.

    Kept on the shared layer so both the client UI and the server-only
    handlers in CSR_ServerCommands resolve the same revolver whitelist and
    animation keys without duplicating tables.
]]--

CSR_RouletteData = CSR_RouletteData or {}

CSR_RouletteData.REVOLVER_TYPES = {
    ["Base.Revolver"] = true,
    ["Base.Revolver_Long"] = true,
    ["Base.Revolver_Short"] = true,
}

CSR_RouletteData.ANIM_KEYS = {
    "CSR_Roulette_Handgun",
    "CSR_Roulette_Handgun_02",
    "CSR_Roulette_Handgun_03",
}

CSR_RouletteData.MAX_INVITE_RANGE = 5
CSR_RouletteData.MIN_PLAYERS = 2
CSR_RouletteData.MAX_PLAYERS = 6
CSR_RouletteData.INVITE_TIMEOUT_SECONDS = 30

function CSR_RouletteData.isRevolver(item)
    if not item or not item.getFullType then return false end
    return CSR_RouletteData.REVOLVER_TYPES[item:getFullType()] == true
end

function CSR_RouletteData.pickAnim()
    return CSR_RouletteData.ANIM_KEYS[ZombRand(#CSR_RouletteData.ANIM_KEYS) + 1]
end

return CSR_RouletteData

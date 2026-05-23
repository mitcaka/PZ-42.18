--[[
    CSR_SkillJournal.lua  --  shared constants + helpers.

    Pure-UI skill recovery feature.  Loaded on both client and server.
    No physical item, no recipe, no animation.  Snapshot is keyed to
    Steam ID + per-character slot in server SModData.

    All keys + the global table are prefixed CSR_SkillJournal so the
    feature is removable by deleting four files and the sandbox block.
]]

CSR_SkillJournal = CSR_SkillJournal or {}

CSR_SkillJournal.SCHEMA_VERSION = 3
CSR_SkillJournal.MODDATA_KEY    = "CSR_SkillJournal_v1"
CSR_SkillJournal.MOD_ID         = "CSR_SkillJournal"

-- Network commands (client -> server)
CSR_SkillJournal.CMD_GET     = "SkillJournalGet"
CSR_SkillJournal.CMD_SAVE    = "SkillJournalSave"
CSR_SkillJournal.CMD_RECOVER = "SkillJournalRecover"
CSR_SkillJournal.CMD_ADMIN   = "SkillJournalAdmin"   -- view/wipe/grant

-- Network commands (server -> client)
CSR_SkillJournal.PUSH_STATE  = "SkillJournalState"
CSR_SkillJournal.PUSH_RESULT = "SkillJournalResult"
CSR_SkillJournal.PUSH_BLACKLIST = "SkillJournalBlacklist"

-- Throttling
CSR_SkillJournal.REQUEST_COOLDOWN_MS = 5000

function CSR_SkillJournal.safeNumber(v, d)
    if v == nil then return d or 0 end
    local n = tonumber(v)
    if n == nil then return d or 0 end
    return n
end

function CSR_SkillJournal.safeString(v, d)
    if v == nil or v == "" then return d or "" end
    return tostring(v)
end

-- Stable row key that survives character death.  PZ creates a fresh
-- IsoPlayer object on respawn, so anything stamped into player modData
-- is gone; the only identifiers that persist across the death->respawn
-- transition are SteamID and Username.  Use SteamID::lower(Username)
-- in MP, fall back to Username::Worldname when offline (SteamID empty).
-- This means alt characters under the SAME Steam account AND the SAME
-- in-game username share a row -- acceptable trade-off, since recover-
-- after-death is the primary use case.  Slot-based separation is
-- restored automatically the moment a player picks a different name.
function CSR_SkillJournal.getRowKey(player)
    if not player then return nil end
    local steamId = ""
    if player.getSteamID then
        steamId = tostring(player:getSteamID() or "")
    end
    if steamId == "0" then steamId = "" end

    local userName = ""
    if player.getUsername then
        userName = tostring(player:getUsername() or "")
    end

    local nameKey = string.lower(userName or "")
    local id = steamId
    if id == "" then
        id = userName .. "/" .. tostring(getWorld and getWorld():getWorld() or "?")
    end
    return id .. "::" .. nameKey, steamId, userName
end

-- Build a fresh player row.
function CSR_SkillJournal.newRow(steamId, userName)
    return {
        steamId    = CSR_SkillJournal.safeString(steamId, ""),
        userName   = CSR_SkillJournal.safeString(userName, ""),
        profession = "",   -- locked profession type string; "" = never saved
        perks      = {},   -- [perkType] = { lvl = N, xp = N }
        boosted    = {},   -- [perkType] = traitBoostLvl
        recipes    = {},   -- [recipeName] = true
        knownMedia = {},   -- [mediaId]    = true
        bornTs     = 0,
        lastWrite  = 0,
        lastWriteRealMs = 0,  -- wall-clock ms of last save; gates real-world cooldown
        deaths     = 0,
        pendingPenalty = 0,  -- accumulated unrecovered death levels
        version    = CSR_SkillJournal.SCHEMA_VERSION,
    }
end

-- Resolve the current profession type string for a live player, or "" if
-- unavailable.  Used by the server to lock a journal row to the profession
-- it was first saved under, blocking the die->respec->resave exploit.
function CSR_SkillJournal.getProfession(player)
    if not player or not player.getDescriptor then return "" end
    local d = player:getDescriptor()
    if d and d.getCharacterProfession then
        return tostring(d:getCharacterProfession() or "")
    end
    return ""
end

-- Iterate vanilla perks.  Returns array of { type=string, name=string }.
-- Skips PerkFactory.Perks.None / Strength category container etc.
function CSR_SkillJournal.listPerks()
    local out = {}
    if not PerkFactory or not PerkFactory.PerkList then return out end
    local list = PerkFactory.PerkList
    if not list or not list.size then return out end
    for i = 0, list:size() - 1 do
        local p = list:get(i)
        if p then
            local typeStr = p.getType and tostring(p:getType()) or nil
            local parent  = p.getParent and p:getParent() or nil
            -- skip empty parent / hidden internal perks (None, etc.)
            if typeStr and parent and tostring(parent) ~= "None" and typeStr ~= "None" then
                local name = p.getName and tostring(p:getName()) or typeStr
                table.insert(out, { type = typeStr, name = name })
            end
        end
    end
    return out
end

return CSR_SkillJournal

--[[
    CSR_ClaimInvitesClient.lua
    -------------------------------------------------------------------------
    v1.8.35 -- client side of the invite system. On CSR_ClaimInviteReceived
    pop up a modal Accept/Decline dialog (deduplicated by inviteId). On login
    request the pending list once.

    Hard rule: only active in MP. SP has no invites (single player is the
    sole user).
--]]

require "CSR_Claims/CSR_ClaimClient"

-- MP-only: in SP we still load (so requires don't break) but every public
-- function early-returns if !isClient().
local function _mpOnly()
    return isClient and isClient()
end

CSR_ClaimInvitesClient = CSR_ClaimInvitesClient or {}

local _seen = {}      -- inviteId -> true (dedupe across rapid resends)

local function localPlayer()
    if getSpecificPlayer then return getSpecificPlayer(0) end
    return nil
end

local function showInvitePrompt(args)
    if type(args) ~= "table" or not args.id then return end
    local invId = tonumber(args.id) or 0
    if invId == 0 or _seen[invId] then return end
    _seen[invId] = true

    local title = tostring(args.title or "")
    local kind  = tostring(args.kind or "")
    local from  = tostring(args.fromUser or "")
    local role  = tostring(args.role or "member")
    local label = (kind == "faction" and ("[Faction: " .. tostring(args.factionName or "") .. "] ") or "")
        .. (title ~= "" and title or "(unnamed)")

    local msg = string.format("%s invites you to:\n%s\nRole: %s\n\nAccept?",
        from, label, role)

    local sw = (getCore and getCore():getScreenWidth()) or 800
    local sh = (getCore and getCore():getScreenHeight()) or 600

    local modal = ISModalDialog:new(
        sw / 2 - 175, sh / 2 - 80,
        350, 160, msg, true, nil,
        function(_, btn)
            if not btn then return end
            local p = localPlayer()
            if btn.internal == "YES" then
                if isClient() then
                    sendClientCommand(p, "CommonSenseReborn", "CSR_ClaimInviteAccept", { id = invId })
                end
            else
                if isClient() then
                    sendClientCommand(p, "CommonSenseReborn", "CSR_ClaimInviteDecline", { id = invId })
                end
            end
        end)
    modal:initialise()
    modal:addToUIManager()

    -- Halo cue.
    local p = localPlayer()
    if p and p.setHaloNote then
        p:setHaloNote("Claim invite from " .. from, 200, 220, 40, 220)
    end
end

local function onServerCommand(module, command, args)
    if module ~= "CommonSenseReborn" then return end
    if command == "CSR_ClaimInviteReceived" then
        showInvitePrompt(args or {})
    end
end

if Events and Events.OnServerCommand and _mpOnly() then
    Events.OnServerCommand.Add(onServerCommand)
end

-- Pull pending invites once after entering the world (MP only).
local function onCreatePlayer(playerIndex, player)
    if not isClient() then return end
    if playerIndex ~= 0 then return end
    -- Slight delay to let the bundle hydrate first.
    local fired = false
    local count = 0
    local function tick()
        count = count + 1
        if count < 60 then return end
        if fired then return end
        fired = true
        if Events and Events.OnTick and Events.OnTick.Remove then
            Events.OnTick.Remove(tick)
        end
        local p = localPlayer()
        if p then
            sendClientCommand(p, "CommonSenseReborn", "CSR_ClaimInviteListQuery", {})
        end
    end
    if Events and Events.OnTick then Events.OnTick.Add(tick) end
end

if Events and Events.OnCreatePlayer and _mpOnly() then
    Events.OnCreatePlayer.Add(onCreatePlayer)
end

-- Public: invite a target on a claim.
function CSR_ClaimInvitesClient.invite(claimId, target, role)
    if not _mpOnly() then return end
    local p = localPlayer()
    if not p then return end
    local args = {
        id = tonumber(claimId) or 0,
        target = tostring(target or ""),
        role = tostring(role or "member"),
    }
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", "CSR_ClaimInviteRequest", args)
    elseif CSR_ClaimServer and CSR_ClaimServer.dispatch then
        CSR_ClaimServer.dispatch("CommonSenseReborn", "CSR_ClaimInviteRequest", p, args)
    end
end

function CSR_ClaimInvitesClient.kick(claimId, target)
    if not _mpOnly() then return end
    local p = localPlayer()
    if not p then return end
    local args = {
        id = tonumber(claimId) or 0,
        target = tostring(target or ""),
    }
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", "CSR_ClaimMemberKick", args)
    elseif CSR_ClaimServer and CSR_ClaimServer.dispatch then
        CSR_ClaimServer.dispatch("CommonSenseReborn", "CSR_ClaimMemberKick", p, args)
    end
end

function CSR_ClaimInvitesClient.queryAudit(maxLines)
    if not _mpOnly() then return end
    local p = localPlayer()
    if not p then return end
    local args = { max = tonumber(maxLines) or 50 }
    if isClient() then
        sendClientCommand(p, "CommonSenseReborn", "CSR_ClaimAuditQuery", args)
    elseif CSR_ClaimServer and CSR_ClaimServer.dispatch then
        CSR_ClaimServer.dispatch("CommonSenseReborn", "CSR_ClaimAuditQuery", p, args)
    end
end

return CSR_ClaimInvitesClient

require "CSRAdminCommandCenter/ACC_Main"
require "CSRAdminCommandCenter/Data/Schemas"
require "CSRAdminCommandCenter/Persistence"
require "CSRAdminCommandCenter/Utils/Time"

local ACC = CSRAdminCommandCenter
ACC.DebugHooks = ACC.DebugHooks or {}

local DebugHooks = ACC.DebugHooks
local Keys = ACC.Schemas.Keys

DebugHooks.knownOptions = {
    claims = true,
    vehicleTracking = true,
    cleanup = true,
    map = true,
    playerInteraction = true,
    errorsOnly = true,
    verbose = true,
    temporarySession = true,
}

local function state()
    local st = ACC.Persistence.stateTable(Keys.DebugState)
    if st.initialized ~= true then
        st.initialized = true
        st.claims = false
        st.vehicleTracking = false
        st.cleanup = false
        st.map = false
        st.playerInteraction = false
        st.errorsOnly = true
        st.verbose = false
        st.temporarySession = false
        st.updatedAt = ACC.Time.nowSeconds()
        st.updatedBy = ""
    end
    return st
end

function DebugHooks.getState()
    return ACC.copyFlat(state())
end

function DebugHooks.setOption(playerName, optionKey, enabled)
    optionKey = tostring(optionKey or "")
    if not DebugHooks.knownOptions[optionKey] then
        return false, "Unknown debug option"
    end
    local st = state()
    st[optionKey] = enabled == true
    st.updatedAt = ACC.Time.nowSeconds()
    st.updatedBy = tostring(playerName or "")
    if optionKey == "temporarySession" and enabled == true then
        st.sessionStartedAt = st.updatedAt
    end
    ACC.Persistence.enqueue("debug", "debug_option key=" .. optionKey
        .. " enabled=" .. tostring(enabled == true)
        .. " by=" .. tostring(playerName or ""))
    return true, "Debug option updated"
end

function DebugHooks.log(systemName, line, force)
    local st = state()
    if force ~= true and not st.verbose and not st[systemName] then return end
    ACC.Persistence.enqueue("debug", tostring(systemName or "debug") .. " " .. tostring(line or ""))
end

return DebugHooks


if isServer() then return end

require "BCR_DisplaySettings"
require "BCR_Utils"

BCR_Debug = BCR_Debug or {}

function BCR_Debug.enabled()
    return BCR_DisplaySettings and BCR_DisplaySettings.get and BCR_DisplaySettings.get("DebugLogging") == true
end

function BCR_Debug.log(message)
    if not BCR_Debug.enabled() then return end
    if print then
        print("[Buildcraft Reborn] " .. tostring(message))
    end
end

function BCR_Debug.timing(label, startedAt, extra)
    if not BCR_Debug.enabled() then return end
    local elapsed = BCR_Utils.nowMs() - (startedAt or BCR_Utils.nowMs())
    local suffix = extra and (" " .. tostring(extra)) or ""
    BCR_Debug.log(tostring(label) .. " in " .. tostring(elapsed) .. "ms" .. suffix)
end

return BCR_Debug

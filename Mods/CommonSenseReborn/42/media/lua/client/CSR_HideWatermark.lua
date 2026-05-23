require "CSR_FeatureFlags"
require "ISUI/ISVersionWaterMark"

local originalAddToUIManager = nil
local originalRender = nil
local originalDoMsg = nil
local patched = false

local function isEnabled()
    return CSR_FeatureFlags
        and CSR_FeatureFlags.isHideWatermarkEnabled
        and CSR_FeatureFlags.isHideWatermarkEnabled()
end

local function patchWatermark()
    if patched then return end
    if not WaterMarkUI or not ISVersionWaterMark then return end

    originalAddToUIManager = WaterMarkUI.addToUIManager
    originalRender = WaterMarkUI.render
    originalDoMsg = ISVersionWaterMark.doMsg
    patched = true

    WaterMarkUI.addToUIManager = function(self, ...)
        if isEnabled() then
            return
        end
        if originalAddToUIManager then
            return originalAddToUIManager(self, ...)
        end
    end

    WaterMarkUI.render = function(self, ...)
        if isEnabled() then
            return
        end
        if originalRender then
            return originalRender(self, ...)
        end
    end

    ISVersionWaterMark.doMsg = function(...)
        if isEnabled() then
            return
        end
        if originalDoMsg then
            return originalDoMsg(...)
        end
    end
end

patchWatermark()

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(patchWatermark)
end

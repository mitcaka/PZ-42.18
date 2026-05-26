FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.DistributionSafety = FadedFeastcraft.DistributionSafety or {}

local Safety = FadedFeastcraft.DistributionSafety

local function debug(message)
    if FadedFeastcraft.Utils and FadedFeastcraft.Utils.debug then
        FadedFeastcraft.Utils.debug(message)
    end
end

function Safety.ensureProceduralList(name)
    if not name or not ProceduralDistributions then return nil end
    ProceduralDistributions.list = ProceduralDistributions.list or ProceduralDistributions["list"] or {}
    local list = ProceduralDistributions.list
    local entry = list[name]
    if not entry then
        entry = { rolls = 1, items = {} }
        list[name] = entry
        debug("Created missing procedural distribution: " .. tostring(name))
    end
    entry.items = entry.items or {}
    return entry.items
end

function Safety.installProceduralFallback()
    if not ProceduralDistributions then return end
    ProceduralDistributions.list = ProceduralDistributions.list or ProceduralDistributions["list"] or {}
    local list = ProceduralDistributions.list
    if Safety.fallbackInstalled == true then return end
    local existing = getmetatable(list)
    if existing and existing.__index then
        Safety.fallbackInstalled = true
        return
    end
    setmetatable(list, {
        __index = function(t, key)
            local entry = { rolls = 1, items = {} }
            rawset(t, key, entry)
            debug("Auto-created procedural distribution: " .. tostring(key))
            return entry
        end
    })
    Safety.fallbackInstalled = true
end

function Safety.run(label, fn)
    if type(fn) ~= "function" then return false end
    local ok, err = pcall(fn)
    if not ok then
        debug("Distribution callback failed [" .. tostring(label) .. "]: " .. tostring(err))
        return false
    end
    return true
end

return Safety

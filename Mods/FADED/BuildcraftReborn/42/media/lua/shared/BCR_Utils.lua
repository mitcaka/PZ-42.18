-- Small shared helpers for Buildcraft Reborn.

BCR_Utils = BCR_Utils or {}

function BCR_Utils.tr(key, fallback)
    if getTextOrNull then
        local value = getTextOrNull(key)
        if value and value ~= "" and value ~= key then
            return value
        end
    end
    if getText then
        local value = getText(key)
        if value and value ~= "" and value ~= key then
            return value
        end
    end
    return fallback or key
end

function BCR_Utils.format(template, ...)
    local args = { ... }
    local text = tostring(template or "")
    local function replace(index)
        return tostring(args[tonumber(index) or 0] or "")
    end
    text = string.gsub(text, "%%(%d+)%$s", replace)
    text = string.gsub(text, "%%(%d+)", replace)
    return text
end

function BCR_Utils.safeString(value, fallback)
    if value == nil or value == "" then
        return fallback or ""
    end
    return tostring(value)
end

function BCR_Utils.trim(value)
    local text = BCR_Utils.safeString(value, "")
    return (string.gsub(string.gsub(text, "^%s+", ""), "%s+$", ""))
end

function BCR_Utils.isPlaceholderText(value)
    local text = BCR_Utils.trim(value)
    if text == "" or text == "-" or text == "nil" or text == "null" then return true end
    if string.find(text, "%$%$") then return true end
    if string.match(text, "^%$.*%$$") then return true end
    return false
end

function BCR_Utils.cleanLabel(value, fallback)
    local text = BCR_Utils.trim(value)
    text = string.gsub(text, "^%$+", "")
    text = string.gsub(text, "%$+$", "")
    text = BCR_Utils.trim(text)
    if BCR_Utils.isPlaceholderText(text) then
        return fallback or ""
    end
    return text
end

function BCR_Utils.humanizeToken(value, fallback)
    local text = BCR_Utils.cleanLabel(value, fallback)
    if text == "" then return fallback or "" end

    text = string.gsub(text, "^.+%.", "")
    text = string.gsub(text, "[_%-/]+", " ")
    text = string.gsub(text, "(%u)(%u%l)", "%1 %2")
    text = string.gsub(text, "(%l)(%u)", "%1 %2")
    text = string.gsub(text, "%s+", " ")
    return BCR_Utils.trim(text)
end

function BCR_Utils.displayLabel(value, fallback)
    local text = BCR_Utils.cleanLabel(value, "")
    if text == "" then return fallback or "" end
    return BCR_Utils.humanizeToken(text, fallback)
end

function BCR_Utils.lower(value)
    return string.lower(BCR_Utils.safeString(value))
end

function BCR_Utils.listSize(list)
    if not list then return 0 end
    if list.size then return list:size() end
    return #list
end

function BCR_Utils.listGet(list, index)
    if not list then return nil end
    if list.get then return list:get(index) end
    return list[index + 1]
end

function BCR_Utils.matchesQuery(text, query)
    query = BCR_Utils.lower(query)
    if query == "" then return true end
    text = BCR_Utils.lower(text)
    for term in string.gmatch(query, "%S+") do
        if not string.find(text, term, 1, true) and not BCR_Utils.fuzzyContains(text, term) then
            return false
        end
    end
    return true
end

function BCR_Utils.queryTerms(query)
    local terms = {}
    local text = BCR_Utils.lower(query)
    for term in string.gmatch(text, "%S+") do
        table.insert(terms, term)
    end
    return terms
end

function BCR_Utils.matchesQueryTermsLower(lowerText, terms)
    if not terms or #terms == 0 then return true end
    lowerText = BCR_Utils.safeString(lowerText, "")
    for _, term in ipairs(terms) do
        if not string.find(lowerText, term, 1, true) and not BCR_Utils.fuzzyContains(lowerText, term) then
            return false
        end
    end
    return true
end

function BCR_Utils.fuzzyContains(text, term)
    if term == "" then return true end
    local textIndex = 1
    for i = 1, string.len(term) do
        local needle = string.sub(term, i, i)
        local found = string.find(text, needle, textIndex, true)
        if not found then return false end
        textIndex = found + 1
    end
    return true
end

function BCR_Utils.clampToScreen(x, y, w, h)
    local core = getCore and getCore() or nil
    local sw = core and core:getScreenWidth() or 1280
    local sh = core and core:getScreenHeight() or 768
    local margin = 6
    local maxX = math.max(margin, sw - w - margin)
    local maxY = math.max(margin, sh - h - margin)
    return math.max(margin, math.min(x, maxX)), math.max(margin, math.min(y, maxY))
end

function BCR_Utils.nowMs()
    if getTimestampMs then return getTimestampMs() end
    if getTimestamp then return getTimestamp() * 1000 end
    return 0
end

function BCR_Utils.sortByLabel(a, b)
    local left = BCR_Utils.lower(a and a.label or "")
    local right = BCR_Utils.lower(b and b.label or "")
    return left < right
end

function BCR_Utils.uniqueAppend(values, seen, value)
    value = BCR_Utils.cleanLabel(value, "")
    if value == "" then return end
    local key = BCR_Utils.lower(value)
    if seen[key] then return end
    seen[key] = true
    table.insert(values, value)
end

function BCR_Utils.joinLimited(values, separator, maxVisible, moreTemplate)
    separator = separator or " / "
    maxVisible = maxVisible or #values
    if #values <= maxVisible then
        return table.concat(values, separator)
    end

    local visible = {}
    for i = 1, maxVisible do
        visible[i] = values[i]
    end
    local more = BCR_Utils.format(moreTemplate or "+%1 more", #values - maxVisible)
    table.insert(visible, more)
    return table.concat(visible, separator)
end

return BCR_Utils

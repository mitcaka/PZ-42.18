--[[
    CSR_ItemsListViewerFix.lua
    -------------------------------------------------------------------------
    Vanilla ISItemsListTable:initList (B42.17 admin Item Viewer) calls
    v:getItemType():toString() on every registered item without a nil-guard,
    and so does the per-frame drawDatas at line 477. A single mod item with
    a null Type field crashes the panel on open AND spams "attempted index:
    toString of non-table: null" every frame thereafter.

    Approach: pre-filter the module list to drop only items whose
    getItemType() / getDisplayName() are missing (the two fields vanilla
    dereferences without a guard). Hand the cleaned list to vanilla
    initList unchanged so all of vanilla's combobox / filter / draw logic
    works identically to a clean modlist. DisplayCategory and LootType are
    NOT used here -- vanilla's drawer already nil-guards them at L482/L491.
--]]

if not ISItemsListTable or not ISItemsListTable.initList then return end
if ISItemsListTable._csrInitListPatched then return end
ISItemsListTable._csrInitListPatched = true

local _origInitList = ISItemsListTable.initList

local function safeStr(jstr)
    if jstr == nil then return nil end
    local ok, s = pcall(function() return jstr:toString() end)
    if not ok or s == nil then return nil end
    return s
end

local function safeCall(obj, method)
    if not obj then return nil end
    local ok, val = pcall(function() return obj[method](obj) end)
    if not ok then return nil end
    return val
end

function ISItemsListTable:initList(module)
    local cleaned = {}
    local skipped = 0
    if module then
        for x = 1, #module do
            local v = module[x]
            if v then
                local typeStr = safeStr(safeCall(v, "getItemType"))
                local displayName = safeCall(v, "getDisplayName")
                if typeStr ~= nil and displayName ~= nil then
                    cleaned[#cleaned + 1] = v
                else
                    skipped = skipped + 1
                end
            end
        end
    end
    if skipped > 0 then
        print(string.format("[CSR] Item Viewer: skipped %d item(s) with null Type or DisplayName to prevent admin-panel crash.", skipped))
    end
    return _origInitList(self, cleaned)
end

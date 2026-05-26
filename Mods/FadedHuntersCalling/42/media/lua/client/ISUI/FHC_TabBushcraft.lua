-- FHC_TabBushcraft.lua
-- Hub-only FHC crafting surface. The vanilla craft window is intentionally not used.
require "ISUI/FHC_TabBase"
require "FHC_TimedActions"

if isServer() then return end

FHC_TabBushcraft = FHC_TabBase:derive("FHC_TabBushcraft")
local C = FHC.COLOR
local U = FHC.Utils
local CACHE_MS = 500
local ROW_H = 27
local START_Y = 58
local BUTTON_W = 230
local BUTTON_H = 22

local function labelFor(recipeId)
    local key = "IGUI_FHC_Recipe_" .. tostring(recipeId)
    local label = getText(key)
    if label == key then return tostring(recipeId) end
    return label
end

local function itemKey(item)
    local id = U.itemId(item)
    if id ~= nil then return "id:" .. tostring(id) end
    return item
end

local function displayItemType(fullType)
    if not fullType then return getText("IGUI_FHC_CraftLabel_Item") end
    local scriptItem = nil
    local sm = getScriptManager and getScriptManager() or (ScriptManager and ScriptManager.instance or nil)
    if sm then
        local ok, result = pcall(function() return sm:FindItem(fullType) end)
        if ok then scriptItem = result end
    end
    if scriptItem and scriptItem.getDisplayName then
        return scriptItem:getDisplayName()
    end
    local name = tostring(fullType):gsub("^Base%.", ""):gsub("_", " ")
    name = name:gsub("(%l)(%u)", "%1 %2")
    return name
end

local function isRawMeatList(types)
    if not types or #types < 2 then return false end
    for _, fullType in ipairs(types) do
        if not FHC.RAW_MEAT_SET[fullType] then return false end
    end
    return true
end

local function tagLabel(tags)
    local set = {}
    for _, tag in ipairs(tags or {}) do
        set[tag] = true
    end
    if set["base:hammer"] or set["Hammer"] then return getText("IGUI_FHC_CraftLabel_Hammer") end
    if set["base:saw"] or set["base:smallsaw"] or set["base:crudesaw"] then return getText("IGUI_FHC_CraftLabel_Saw") end
    if set["base:binding"] or set["base:rope"] or set["FadedHuntersCalling:cordage"] or set["Cordage"] then return getText("IGUI_FHC_CraftLabel_Cordage") end
    if set["base:scissors"] then return getText("IGUI_FHC_CraftLabel_KnifeScissors") end
    if set["base:sharpknife"] or set["SharpKnife"] or set["base:meatcleaver"] then return getText("IGUI_FHC_CraftLabel_SharpKnife") end
    return getText("IGUI_FHC_CraftLabel_Item")
end

local function specLabel(spec)
    if not spec then return getText("IGUI_FHC_CraftLabel_Item") end
    if spec.labelKey then return getText(spec.labelKey) end
    if spec.types then
        if isRawMeatList(spec.types) then return getText("IGUI_FHC_CraftLabel_RawMeat") end
        if #spec.types == 1 then return displayItemType(spec.types[1]) end
        local names = {}
        local limit = math.min(#spec.types, 3)
        for i = 1, limit do
            table.insert(names, displayItemType(spec.types[i]))
        end
        if #spec.types > limit then table.insert(names, "...") end
        return string.format(getText("IGUI_FHC_CraftLabel_AnyOfFmt"), table.concat(names, " / "))
    end
    if spec.tags then return tagLabel(spec.tags) end
    return getText("IGUI_FHC_CraftLabel_Item")
end

local function perkLabel(perkName)
    local perk = U.perkByName(perkName)
    if perk and PerkFactory and PerkFactory.getPerkName then
        return PerkFactory.getPerkName(perk) or tostring(perkName)
    end
    return tostring(perkName or "")
end

local function rowText(row)
    local text = string.format(getText("IGUI_FHC_CraftLineFmt"), row.needed, row.label)
    text = text .. " " .. string.format(getText("IGUI_FHC_CraftHaveFmt"), row.have, row.needed)
    if row.spec and row.spec.keep then
        if row.spec.degrade then
            text = text .. " - " .. getText("IGUI_FHC_CraftKeptDegrade")
        else
            text = text .. " - " .. getText("IGUI_FHC_CraftKept")
        end
    end
    return text
end

function FHC_TabBushcraft:createChildren()
    self:addLabel(12, 8, getText("IGUI_FHC_Bushcraft_Title"), UIFont.Large, C.Ink)
    self.recipeButtons = {}
    self.selectedRecipeId = (FHC.HUB_CRAFT_ORDER or {})[1]

    local columnW = math.floor((self:getWidth() - 42) / 2)
    local groups = {
        { order = FHC.HUB_CRAFT_ORDER or {}, col = 0 },
        { order = FHC.HUB_SCENT_CRAFT_ORDER or {}, col = 1 },
    }
    for _, group in ipairs(groups) do
        for index, recipeId in ipairs(group.order) do
            local x = 14 + (group.col * (columnW + 14))
            local y = START_Y + ((index - 1) * ROW_H)
            local btn = self:addTextBtn(x, y, BUTTON_W, BUTTON_H, labelFor(recipeId), self, FHC_TabBushcraft.onCraftPressed)
            btn.internal = recipeId
            btn:setOnMouseOverFunction(FHC_TabBushcraft.onRecipeHover)
            btn:setOnMouseOutFunction(FHC_TabBushcraft.onRecipeHoverOut)
            if btn.setFont then btn:setFont(UIFont.Small) end
            self.recipeButtons[recipeId] = btn
        end
    end
end

function FHC_TabBushcraft:buildRecipeInfo(recipeId)
    local recipe = FHC.HUB_CRAFTS and FHC.HUB_CRAFTS[recipeId]
    local info = {
        recipeId = recipeId,
        title = labelFor(recipeId),
        rows = {},
        blockers = {},
        selected = nil,
        ready = false,
        msg = getText("IGUI_FHC_CraftUnavailable"),
    }
    if not recipe then
        table.insert(info.blockers, getText("IGUI_FHC_CraftUnavailable"))
        return info
    end

    local inv = self.player and self.player:getInventory() or nil
    local used = {}
    local selected = {}
    local allIngredientsReady = true
    for slot, spec in ipairs(recipe.inputs or {}) do
        local needed = tonumber(spec.count) or 1
        local have = 0
        for _ = 1, needed do
            local item = inv and U.findInventoryItemMatching(inv, spec, used) or nil
            if item then
                used[itemKey(item)] = true
                have = have + 1
                table.insert(selected, { slot = slot, id = U.itemId(item), item = item })
            end
        end
        if have < needed then allIngredientsReady = false end
        table.insert(info.rows, {
            label = specLabel(spec),
            needed = needed,
            have = have,
            ok = have >= needed,
            spec = spec,
        })
    end

    if not U.recipeFeatureAllowed(recipe) then
        table.insert(info.blockers, getText("IGUI_FHC_CraftFeatureOff"))
    end
    if recipe.skill and not U.recipeSkillAllowed(self.player, recipe) then
        table.insert(info.blockers, string.format(getText("IGUI_FHC_CraftRequiresSkillFmt"),
            perkLabel(recipe.skill.perk), recipe.skill.level or 0))
    end

    if allIngredientsReady and #info.blockers == 0 then
        info.ready = true
        info.msg = getText("IGUI_FHC_CraftReady")
        info.selected = selected
    elseif #info.blockers > 0 then
        info.msg = info.blockers[1]
    else
        info.msg = getText("IGUI_FHC_CraftMissing")
    end
    return info
end

function FHC_TabBushcraft:recipeState(recipeId, fresh)
    local now = getTimestampMs and getTimestampMs() or 0
    self.recipeStateCache = self.recipeStateCache or {}
    local cached = self.recipeStateCache[recipeId]
    if not fresh and cached and (now - cached.at) < CACHE_MS then
        return cached.ready, cached.msg, cached.selected, cached.info
    end

    local info = self:buildRecipeInfo(recipeId)
    self.recipeStateCache[recipeId] = {
        at = now,
        ready = info.ready,
        msg = info.msg,
        selected = info.selected,
        info = info,
    }
    return info.ready, info.msg, info.selected, info
end

function FHC_TabBushcraft:recipeTooltip(recipeId, info)
    if not info then
        local _, _, _, stateInfo = self:recipeState(recipeId)
        info = stateInfo
    end
    local lines = { info.title, info.msg, getText("IGUI_FHC_CraftRequirements") }
    for _, blocker in ipairs(info.blockers or {}) do
        table.insert(lines, "[!] " .. blocker)
    end
    for _, row in ipairs(info.rows or {}) do
        local mark = row.ok and "[OK]" or "[--]"
        table.insert(lines, mark .. " " .. rowText(row))
    end
    return table.concat(lines, "\n")
end

function FHC_TabBushcraft:onRecipeHover(button)
    self.hoverRecipeId = button and button.internal or nil
end

function FHC_TabBushcraft:onRecipeHoverOut(button)
    if button and self.hoverRecipeId == button.internal then
        self.hoverRecipeId = nil
    end
end

function FHC_TabBushcraft:onCraftPressed(button)
    local recipeId = button and button.internal
    self.selectedRecipeId = recipeId or self.selectedRecipeId
    local ok, _, selected = self:recipeState(recipeId, true)
    if not ok then return end
    ISTimedActionQueue.add(FHC_HubCraftTA:new(self.player, recipeId, selected))
end

function FHC_TabBushcraft:onShow()
    self.recipeStateCache = {}
end

function FHC_TabBushcraft:drawRecipeDetails(recipeId)
    local _, _, _, info = self:recipeState(recipeId)
    local maxRows = math.max(#(FHC.HUB_CRAFT_ORDER or {}), #(FHC.HUB_SCENT_CRAFT_ORDER or {}))
    local panelX = 14
    local panelY = START_Y + (maxRows * ROW_H) + 8
    local panelW = self:getWidth() - 28
    local panelH = self:getHeight() - panelY - 10
    if panelH < 72 then return end

    self:drawRect(panelX, panelY, panelW, panelH, 0.20,
        C.LeatherLight.r, C.LeatherLight.g, C.LeatherLight.b)
    self:drawRectBorder(panelX, panelY, panelW, panelH, 1.0,
        C.LeatherDark.r, C.LeatherDark.g, C.LeatherDark.b)

    local x = panelX + 10
    local y = panelY + 8
    self:drawText(info.title, x, y, C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium)
    local statusColor = info.ready and C.GoodGreen or C.WarnRed
    self:drawText(info.msg, panelX + panelW - 210, y + 2,
        statusColor.r, statusColor.g, statusColor.b, 1, UIFont.Small)
    y = y + 24

    if info.ready then
        self:drawText(getText("IGUI_FHC_CraftClickReady"), x, y,
            C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
    else
        self:drawText(getText("IGUI_FHC_CraftClickMissing"), x, y,
            C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
    end
    y = y + 16

    for _, blocker in ipairs(info.blockers or {}) do
        if y > panelY + panelH - 14 then return end
        self:drawText("[!] " .. blocker, x, y, C.WarnRed.r, C.WarnRed.g, C.WarnRed.b, 1, UIFont.Small)
        y = y + 15
    end

    for _, row in ipairs(info.rows or {}) do
        if y > panelY + panelH - 14 then return end
        local color = row.ok and C.GoodGreen or C.WarnRed
        local mark = row.ok and "[OK] " or "[--] "
        self:drawText(mark .. rowText(row), x, y, color.r, color.g, color.b, 1, UIFont.Small)
        y = y + 15
    end
end

function FHC_TabBushcraft:prerender()
    FHC_TabBase.prerender(self)
    self:drawText(getText("IGUI_FHC_Bushcraft_Header"), 14, 32,
        C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium)
    local columnW = math.floor((self:getWidth() - 42) / 2)
    self:drawText(getText("IGUI_FHC_Bushcraft_ScentsHeader"), 14 + columnW + 14, 32,
        C.Ink.r, C.Ink.g, C.Ink.b, 1, UIFont.Medium)

    local groups = {
        { order = FHC.HUB_CRAFT_ORDER or {}, col = 0 },
        { order = FHC.HUB_SCENT_CRAFT_ORDER or {}, col = 1 },
    }
    for _, group in ipairs(groups) do
        for index, recipeId in ipairs(group.order) do
            local x = 14 + (group.col * (columnW + 14))
            local y = START_Y + ((index - 1) * ROW_H)
            local ready, msg, _, info = self:recipeState(recipeId)
            local btn = self.recipeButtons and self.recipeButtons[recipeId]
            if btn then
                if btn.setEnable then btn:setEnable(true) else btn.enable = true end
                btn.tooltip = self:recipeTooltip(recipeId, info)
                if self.selectedRecipeId == recipeId or self.hoverRecipeId == recipeId then
                    btn.backgroundColor = { r = C.AmberDim.r, g = C.AmberDim.g, b = C.AmberDim.b, a = 1 }
                elseif ready then
                    btn.backgroundColor = { r = C.Leather.r, g = C.Leather.g, b = C.Leather.b, a = 1 }
                else
                    btn.backgroundColor = { r = C.LeatherDark.r, g = C.LeatherDark.g, b = C.LeatherDark.b, a = 1 }
                end
            end
            local color = ready and C.GoodGreen or C.WarnRed
            self:drawText(msg, x + BUTTON_W + 6, y + 4, color.r, color.g, color.b, 1, UIFont.Small)
        end
    end

    local detailRecipe = self.hoverRecipeId or self.selectedRecipeId
    if detailRecipe then
        self:drawRecipeDetails(detailRecipe)
    else
        self:drawText(getText("IGUI_FHC_Bushcraft_DetailsHint"), 14, self:getHeight() - 24,
            C.ParchmentDark.r, C.ParchmentDark.g, C.ParchmentDark.b, 1, UIFont.Small)
    end
end

FHC.UI.Tabs.bushcraft = function(x, y, w, h, player) return FHC_TabBushcraft:new(x, y, w, h, player) end

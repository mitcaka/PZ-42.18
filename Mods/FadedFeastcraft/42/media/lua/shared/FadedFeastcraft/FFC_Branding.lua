FadedFeastcraft = FadedFeastcraft or {}
FadedFeastcraft.Branding = FadedFeastcraft.Branding or {}

local Branding = FadedFeastcraft.Branding

Branding.PUBLIC_NAME = "FFC"
Branding.FULL_NAME = "Faded's Feastcraft"
Branding.CSR_LABEL = "CSR Ecosystem"
Branding.COMPAT_LABEL = Branding.CSR_LABEL

local SOURCE_LABELS = {
    { token = "common sense reborn test", label = Branding.CSR_LABEL },
    { token = "common sense reborn", label = Branding.CSR_LABEL },
    { token = "commonsensereborntest", label = Branding.CSR_LABEL },
    { token = "commonsensereborn_test", label = Branding.CSR_LABEL },
    { token = "commonsensereborn", label = Branding.CSR_LABEL },
    { token = "csr test", label = Branding.CSR_LABEL },
    { token = "csr_test", label = Branding.CSR_LABEL },
    { token = "csrtest", label = Branding.CSR_LABEL },
    { token = "csr", label = Branding.CSR_LABEL },
    { token = "vanilla foods expanded", label = "FFC Expanded Pantry" },
    { token = "vfx", label = "FFC Expanded Pantry" },
    { token = "abuelita linda", label = "FFC Cocina Pantry" },
    { token = "abuelitalinda", label = "FFC Cocina Pantry" },
    { token = "ted food pack", label = "FFC Snack Shelf" },
    { token = "tedfoodpack", label = "FFC Snack Shelf" },
    { token = "snacktime89", label = "FFC Snack Shelf" },
    { token = "more mre", label = "FFC Field Rations" },
    { token = "military food", label = "FFC Field Rations" },
    { token = "mrefood", label = "FFC Field Rations" },
    { token = "mr.", label = "FFC Field Rations" },
    { token = "egnh", label = "FFC Beverage Cellar" },
    { token = "inuman", label = "FFC Beverage Cellar" },
    { token = "advanced drying", label = "FFC Preservation Bench" },
    { token = "advanceddrying42", label = "FFC Preservation Bench" },
    { token = "meatdrying", label = "FFC Preservation Bench" },
    { token = "skb dried food", label = "FFC Dry Storage" },
    { token = "skbdriedfood", label = "FFC Dry Storage" },
    { token = "driedfoodmod", label = "FFC Dry Storage" },
    { token = "pack pantry", label = "FFC Canning Bench" },
    { token = "packpantry", label = "FFC Canning Bench" },
    { token = "extracraft", label = "FFC Canning Bench" },
    { token = "eliaz", label = "FFC Jarred Pantry" },
    { token = "better canning", label = "FFC Jarred Pantry" },
    { token = "merge canned", label = "FFC Can Consolidation" },
    { token = "ar_merge", label = "FFC Can Consolidation" },
    { token = "craftable vanilla", label = "FFC Homestead Recipes" },
    { token = "craftablevanilla", label = "FFC Homestead Recipes" },
    { token = "every missing", label = "FFC Food Visuals" },
    { token = "aemvfsm", label = "FFC Food Visuals" },
    { token = "wild fruits", label = "FFC Foraged Fruit" },
    { token = "mattsimpleaddons", label = "FFC Foraged Fruit" },
    { token = "food expiration", label = "FFC Expiry Toolkit" },
    { token = "nutrition reference", label = "FFC Nutrition Toolkit" },
    { token = "coolerplus", label = "FFC Cold Storage Toolkit" },
    { token = "food allergy", label = "FFC Trait Safety Toolkit" },
    { token = "project zomboid", label = "FFC Vanilla Pantry" },
    { token = "vanilla / detected", label = "FFC Indexed Pantry" },
    { token = "base.", label = "FFC Vanilla Pantry" },
    { token = "fadedfeastcraft", label = "FFC Core" },
}

local TEXT_REPLACEMENTS = {
    { from = "Common Sense Reborn Test", to = "CSR Test" },
    { from = "Common Sense Reborn", to = Branding.CSR_LABEL },
    { from = "Vanilla Foods Expanded", to = "FFC Expanded Pantry" },
    { from = "Abuelita Linda", to = "FFC Cocina Pantry" },
    { from = "Ted Food Pack", to = "FFC Snack Shelf" },
    { from = "SnackTime89", to = "FFC Snack Shelf" },
    { from = "More MRE & Military Food", to = "FFC Field Rations" },
    { from = "EGNH Inuman Alcohol Pack", to = "FFC Beverage Cellar" },
    { from = "Advanced Drying B42", to = "FFC Preservation Bench" },
    { from = "Skb Dried Food", to = "FFC Dry Storage" },
    { from = "Pack Pantry / ExtraCraft", to = "FFC Canning Bench" },
    { from = "Pack Pantry", to = "FFC Canning Bench" },
    { from = "Eliaz Better Canning", to = "FFC Jarred Pantry" },
    { from = "Merge Canned by AR", to = "FFC Can Consolidation" },
    { from = "Craftable Vanilla Food Items", to = "FFC Homestead Recipes" },
    { from = "Every Missing Vanilla Food Static Model", to = "FFC Food Visuals" },
    { from = "Wild Fruits", to = "FFC Foraged Fruit" },
    { from = "Food Expiration Date", to = "FFC Expiry Toolkit" },
    { from = "Nutrition reference mods", to = "FFC Nutrition Toolkit" },
    { from = "CoolerPlus", to = "FFC Cold Storage Toolkit" },
    { from = "Food Allergy Traits", to = "FFC Trait Safety Toolkit" },
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

function Branding.displaySource(value, fallback)
    local raw = tostring(value or "")
    if raw == "" then return fallback or "FFC Integrated Pantry" end
    if raw == "FFC" or string.sub(raw, 1, 4) == "FFC " then return raw end
    local probe = lower(raw)
    for _, entry in ipairs(SOURCE_LABELS) do
        if string.find(probe, entry.token, 1, true) then
            return entry.label
        end
    end
    return fallback or "FFC Integrated Pantry"
end

function Branding.isCSRSource(value)
    local probe = lower(value)
    return Branding.displaySource(value) == Branding.COMPAT_LABEL
        or probe == lower(Branding.COMPAT_LABEL)
        or string.find(probe, "ffc compatibility", 1, true) ~= nil
        or string.find(probe, "common sense reborn", 1, true) ~= nil
        or string.find(probe, "commonsensereborn", 1, true) ~= nil
        or string.find(probe, "csr", 1, true) ~= nil
end

function Branding.scrubText(value)
    local text = tostring(value or "")
    text = string.gsub(text, "[%w_]+%.", "")
    for _, replacement in ipairs(TEXT_REPLACEMENTS) do
        text = string.gsub(text, replacement.from, replacement.to)
    end
    return text
end

function Branding.foodName(value, fallback)
    local text = tostring(value or "")
    if text == "" then return fallback or "" end

    text = string.gsub(text, "^%s*[%w_]+%.", "")
    text = string.gsub(text, "^AEMVFSM[_%-]?", "")
    text = string.gsub(text, "^FFC[_%-]?", "")
    text = string.gsub(text, "^VFX[_%-]?", "")
    text = string.gsub(text, "^ST[_%-]?", "")
    text = string.gsub(text, "_", " ")
    text = string.gsub(text, "%-", " ")
    text = string.gsub(text, "(%u)(%u%l)", "%1 %2")
    text = string.gsub(text, "(%l)(%u)", "%1 %2")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")

    if text == "" then return fallback or "" end
    return text
end

function Branding.libraryLabel(index, pack)
    local label = Branding.displaySource(pack and pack.label or nil, "FFC Integrated Pantry")
    return label .. " " .. tostring(index or "")
end

return Branding

local MOD_DATA = {
    SmallBeltLeft = {
        HandTorchSmall = "BeltTorchLeftVerySmall",
        HandTorchBig = "BeltTorchLeftSmall",
        TorchAngled = "BeltTorchLeftAngled"
    },
    SmallBeltRight = {
        HandTorchSmall = "BeltTorchRightVerySmall",
        HandTorchBig = "BeltTorchRightSmall",
        TorchAngled = "BeltTorchRightAngled"
    },
    WebbingLeft = {
        HandTorchSmall = "WebbingTorchLeftVerySmall",
        HandTorchBig = "WebbingTorchLeftSmall",
        TorchAngled = "WebbingTorchLeftAngled"
    },
    WebbingRight = {
        HandTorchSmall = "WebbingTorchRightVerySmall",
        HandTorchBig = "WebbingTorchRightSmall",
        TorchAngled = "WebbingTorchRightAngled"
    },
    HolsterAnkle = {
        Holster = "Holster Ankle"
    }
}

local BAG_BOTTOM_DATA = {
    BedrollBottom = {
        BigWeapon = "Big Weapon Bottom Bag",
        BigBlade = "Big Blade Bottom Bag",
        Sword = "Big Blade Bottom Bag",
        Racket = "Racket Bottom Bag",
        Shovel = "Shovel Bottom Bag",
        Pan = "Pan Bottom Bag",
        Rifle = "Rifle Bottom Bag",
        Saucepan = "Saucepan Bottom Bag",
    },
    BedrollBottomBig = {
        BigWeapon = "Big Weapon Bottom Bag Big",
        BigBlade = "Big Blade Bottom Bag Big",
        Sword = "Big Blade Bottom Bag Big",
        Racket = "Racket Bottom Bag Big",
        Shovel = "Shovel Bottom Bag Big",
        Pan = "Pan Bottom Bag Big",
        Rifle = "Rifle Bottom Bag Big",
        Saucepan = "Saucepan Bottom Bag Big",
    },
    BedrollBottomALICE = {
        BigWeapon = "Big Weapon Bottom Bag ALICE",
        BigBlade = "Big Blade Bottom Bag ALICE",
        Sword = "Big Blade Bottom Bag ALICE",
        Racket = "Racket Bottom Bag ALICE",
        Shovel = "Shovel Bottom Bag ALICE",
        Pan = "Pan Bottom Bag ALICE",
        Rifle = "Rifle Bottom Bag ALICE",
        Saucepan = "Saucepan Bottom Bag ALICE",
    },
}

local BACKPACK_LEFT_DATA = {
    CSRBackpackLeft = {
        BigWeapon = "Big Weapon Left Bag",
        BigBlade = "Big Blade Left Bag",
        Sword = "Big Blade Left Bag",
        Racket = "Racket Left Bag",
        Shovel = "Shovel Left Bag",
        Pan = "Pan Left Bag",
        Rifle = "Rifle Left Bag",
        Saucepan = "Saucepan Left Bag",
    },
    CSRBackpackLeftBig = {
        BigWeapon = "Big Weapon Left Bag Big",
        BigBlade = "Big Blade Left Bag Big",
        Sword = "Big Blade Left Bag Big",
        Racket = "Racket Left Bag Big",
        Shovel = "Shovel Left Bag Big",
        Pan = "Pan Left Bag Big",
        Rifle = "Rifle Left Bag Big",
        Saucepan = "Saucepan Left Bag Big",
    },
    CSRBackpackLeftALICE = {
        BigWeapon = "Big Weapon Left Bag Big",
        BigBlade = "Big Blade Left Bag Big",
        Sword = "Big Blade Left Bag Big",
        Racket = "Racket Left Bag Big",
        Shovel = "Shovel Left Bag Big",
        Pan = "Pan Left Bag Big",
        Rifle = "Rifle Left Bag Big",
        Saucepan = "Saucepan Left Bag Big",
    },
}

local BACK2_ATTACHMENTS = {
    BigWeapon      = "Rifle On Back",
    BigBlade       = "Blade On Back",
    Rifle          = "Rifle On Back",
    Shovel         = "Shovel Back",
    Racket         = "Racket On Back",
    Sword          = "Blade On Back",
    Guitar         = "Guitar",
    GuitarAcoustic = "Guitar Acoustic",
    Pan            = "Pan On Back",
    Saucepan       = "Saucepan Back",
}

local BACKPACK_LEFT_DEFS = {
    {
        type = "CSRBackpackLeft",
        name = "Bag L",
        animset = "back",
        attachments = BACKPACK_LEFT_DATA.CSRBackpackLeft,
    },
    {
        type = "CSRBackpackLeftBig",
        name = "Bag L+",
        animset = "back",
        attachments = BACKPACK_LEFT_DATA.CSRBackpackLeftBig,
    },
    {
        type = "CSRBackpackLeftALICE",
        name = "Bag L+",
        animset = "back",
        attachments = BACKPACK_LEFT_DATA.CSRBackpackLeftALICE,
    },
}

local function ensureAttachDefinition(def)
    if not ISHotbarAttachDefinition or not def or not def.type then return end
    for _, existing in ipairs(ISHotbarAttachDefinition) do
        if existing.type == def.type then
            return existing
        end
    end
    table.insert(ISHotbarAttachDefinition, def)
    return def
end

-- Register BackSecondary early (at file load time) so vanilla loadPosition()
-- can resolve slots saved with this type. OnGameStart fires AFTER the hotbar
-- constructor runs loadPosition(), which would silently drop unknown slot types
-- and corrupt the saved hotbar layout.
if ISHotbarAttachDefinition then
    local function addBack2IfNeeded()
        if not CSR_FeatureFlags or not CSR_FeatureFlags.isBack2SlotEnabled or not CSR_FeatureFlags.isBack2SlotEnabled() then return end
        for _, def in ipairs(ISHotbarAttachDefinition) do
            if def.type == "BackSecondary" then return end
        end
        table.insert(ISHotbarAttachDefinition, {
            type = "BackSecondary",
            name = getText("IGUI_Hotbar_Back2"),
            animset = "back",
            attachments = BACK2_ATTACHMENTS,
        })
    end
    addBack2IfNeeded()
    for _, def in ipairs(BACKPACK_LEFT_DEFS) do
        ensureAttachDefinition(def)
    end
end

local function applyDefinitions()
    if not ISHotbarAttachDefinition then
        return
    end
    for _, definition in pairs(ISHotbarAttachDefinition) do
        if definition.type and definition.attachments then
            if MOD_DATA[definition.type] then
                for attachType, modelLocation in pairs(MOD_DATA[definition.type]) do
                    definition.attachments[attachType] = modelLocation
                end
            end
            if BAG_BOTTOM_DATA[definition.type] and CSR_FeatureFlags and CSR_FeatureFlags.isBagBottomAttachEnabled and CSR_FeatureFlags.isBagBottomAttachEnabled() then
                for attachType, modelLocation in pairs(BAG_BOTTOM_DATA[definition.type]) do
                    definition.attachments[attachType] = modelLocation
                end
            end
            if BACKPACK_LEFT_DATA[definition.type] then
                for attachType, modelLocation in pairs(BACKPACK_LEFT_DATA[definition.type]) do
                    definition.attachments[attachType] = modelLocation
                end
            end
        end
    end

    for _, def in ipairs(BACKPACK_LEFT_DEFS) do
        ensureAttachDefinition(def)
    end

    -- Back 2 slot: ensure it exists (may already be added above at load time)
    if CSR_FeatureFlags and CSR_FeatureFlags.isBack2SlotEnabled and CSR_FeatureFlags.isBack2SlotEnabled() then
        local back2Exists = false
        for _, def in ipairs(ISHotbarAttachDefinition) do
            if def.type == "BackSecondary" then
                back2Exists = true
                break
            end
        end
        if not back2Exists then
            table.insert(ISHotbarAttachDefinition, {
                type = "BackSecondary",
                name = getText("IGUI_Hotbar_Back2"),
                animset = "back",
                attachments = BACK2_ATTACHMENTS,
            })
        end
    end
end

Events.OnGameStart.Add(applyDefinitions)
Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
    if playerIndex == 0 then
        applyDefinitions()
    end
end)

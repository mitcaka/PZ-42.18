if not ISHotbarAttachDefinition then return end

local function FWPAddSlingSlot(slot)
    for _, existing in ipairs(ISHotbarAttachDefinition) do
        if existing.type == slot.type then
            return
        end
    end
    table.insert(ISHotbarAttachDefinition, slot)
end

FWPAddSlingSlot({
    type = "FWPSling",
    name = "Faded Sling",
    animset = "belt left",
    attachments = {
        Rifle = "FWP SlingRifle",
        BigBlade = "FWP SlingWeapon",
        BigBonk = "FWP SlingWeapon",
        BigWeapon = "FWP SlingWeapon",
        Shovel = "FWP SlingShovel",
    },
})

FWPAddSlingSlot({
    type = "FWPSlingAlt",
    name = "Faded Sling",
    animset = "belt left",
    attachments = {
        Rifle = "FWP SlingRifle2",
        BigBlade = "FWP SlingWeapon2",
        BigBonk = "FWP SlingWeapon2",
        BigWeapon = "FWP SlingWeapon2",
        Shovel = "FWP SlingShovel2",
    },
})

FWPAddSlingSlot({
    type = "FWPSlingAlt2",
    name = "Faded Sling",
    animset = "belt left",
    attachments = {
        Rifle = "FWP SlingRifle3",
        BigBlade = "FWP SlingWeapon3",
        BigBonk = "FWP SlingWeapon3",
        BigWeapon = "FWP SlingWeapon3",
        Shovel = "FWP SlingShovel3",
    },
})

FWPAddSlingSlot({
    type = "FWPSlingBack",
    name = "Faded Sling",
    animset = "back",
    attachments = {
        Rifle = "FWP SlingRifle Back",
        BigBlade = "FWP SlingWeapon Back",
        BigBonk = "FWP SlingWeapon Back",
        BigWeapon = "FWP SlingWeapon Back",
        Shovel = "FWP SlingShovel Back",
    },
})

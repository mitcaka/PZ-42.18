-- Server-side validation for the B42 FWP ammo box context fallback.
if isClient() then return end

local MODULE_NAME = "FWPAmmoBox"
local COMMAND_OPEN = "Open"

local AMMO_BOXES = {
    ["Base.PB68Bag"] = { ammo = "Base.PB68", count = 500, label = "Open Bag of .68 Paintballs" },
    ["Base.BB177Box"] = { ammo = "Base.BB177", count = 500, label = "Open Box of .177 BBs" },
    ["Base.CO2_Cartridge_Box"] = { ammo = "Base.CO2_Cartridge", count = 15, label = "Open Box of CO2 Cartridges" },
    ["Base.Bullets22Box"] = { ammo = "Base.Bullets22", count = 100, label = "Open Box of .22 LR Rounds" },
    ["Base.Bullets57Box"] = { ammo = "Base.Bullets57", count = 50, label = "Open Box of 5.7x28mm Rounds" },
    ["Base.Bullets380Box"] = { ammo = "Base.Bullets380", count = 50, label = "Open Box of .380 Auto Rounds" },
    ["Base.Bullets9mmBox"] = { ammo = "Base.Bullets9mm", count = 50, label = "Open Box of 9x19mm Rounds" },
    ["Base.Bullets38Box"] = { ammo = "Base.Bullets38", count = 50, label = "Open Box of .38 Special Rounds" },
    ["Base.Bullets357Box"] = { ammo = "Base.Bullets357", count = 50, label = "Open Box of .357 Magnum Rounds" },
    ["Base.Bullets45Box"] = { ammo = "Base.Bullets45", count = 50, label = "Open Box of .45 Auto Rounds" },
    ["Base.Bullets45LCBox"] = { ammo = "Base.Bullets45LC", count = 50, label = "Open Box of .45 LC Rounds" },
    ["Base.Bullets44Box"] = { ammo = "Base.Bullets44", count = 50, label = "Open Box of .44 Magnum Rounds" },
    ["Base.Bullets4570Box"] = { ammo = "Base.Bullets4570", count = 20, label = "Open Box of .45-70 Gov Rounds" },
    ["Base.Bullets50MAGBox"] = { ammo = "Base.Bullets50MAG", count = 20, label = "Open Box of .50 Magnum Rounds" },
    ["Base.410gShotgunShellsBox"] = { ammo = "Base.410gShotgunShells", count = 25, label = "Open Box of .410g Shotgun Shells" },
    ["Base.20gShotgunShellsBox"] = { ammo = "Base.20gShotgunShells", count = 25, label = "Open Box of 20g Shotgun Shells" },
    ["Base.ShotgunShellsBox"] = { ammo = "Base.ShotgunShells", count = 25, label = "Open Box of 12g Shotgun Shells" },
    ["Base.FWP_12gIncendiaryShellsBox"] = { ammo = "Base.FWP_12gIncendiaryShells", count = 10, label = "Open Box of 12g Incendiary Shells" },
    ["Base.10gShotgunShellsBox"] = { ammo = "Base.10gShotgunShells", count = 25, label = "Open Box of 10g Shotgun Shells" },
    ["Base.4gShotgunShellsBox"] = { ammo = "Base.4gShotgunShells", count = 10, label = "Open Box of 4g Shotgun Shells" },
    ["Base.223Box"] = { ammo = "Base.223Bullets", count = 20, label = "Open Box of .223 Rem Rounds" },
    ["Base.556Box"] = { ammo = "Base.556Bullets", count = 20, label = "Open Box of 5.56x45mm Rounds" },
    ["Base.545x39Box"] = { ammo = "Base.545x39Bullets", count = 20, label = "Open Box of 5.45x39mm Rounds" },
    ["Base.762x39Box"] = { ammo = "Base.762x39Bullets", count = 20, label = "Open Box of 7.62x39mm Rounds" },
    ["Base.308Box"] = { ammo = "Base.308Bullets", count = 20, label = "Open Box of .308 Win Rounds" },
    ["Base.762x51Box"] = { ammo = "Base.762x51Bullets", count = 20, label = "Open Box of 7.62x51mm NATO Rounds" },
    ["Base.762x54rBox"] = { ammo = "Base.762x54rBullets", count = 20, label = "Open Box of 7.62x54mmR Rounds" },
    ["Base.3006Box"] = { ammo = "Base.3006Bullets", count = 20, label = "Open Box of .30-06 Springfield Rounds" },
    ["Base.50BMGBox"] = { ammo = "Base.50BMGBullets", count = 10, label = "Open Box of .50 BMG Rounds" },
    ["Base.Arrow_Fiberglass_Pack"] = { ammo = "Base.Arrow_Fiberglass", count = 10, label = "Open Pack of Fiberglass Arrows" },
    ["Base.Bolt_Bear_Pack"] = { ammo = "Base.Bolt_Bear", count = 10, label = "Open Pack of Bear Crossbow Bolts" },
}

local function getItemFullType(item)
    if not item then return nil end
    if item.getFullType then
        local fullType = item:getFullType()
        if fullType and tostring(fullType) ~= "" then return tostring(fullType) end
    end
    if item.getModule and item.getType then
        return tostring(item:getModule()) .. "." .. tostring(item:getType())
    end
    return nil
end

local function findInventoryItemById(container, itemId)
    if not (container and itemId) then return nil end
    if container.getItemById then
        local item = container:getItemById(itemId)
        if item then return item end
    end
    if not container.getItems then return nil end
    local items = container:getItems()
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.getID and item:getID() == itemId then
            return item
        end
        if item and item.getInventory then
            local nested = findInventoryItemById(item:getInventory(), itemId)
            if nested then return nested end
        end
    end
    return nil
end

local function openAmmoBox(playerObj, args)
    if not (playerObj and args and args.itemId) then return end
    local inv = playerObj:getInventory()
    local item = findInventoryItemById(inv, args.itemId)
    local fullType = getItemFullType(item)
    local def = fullType and AMMO_BOXES[fullType] or nil
    if not def then return end
    if args.boxType and tostring(args.boxType) ~= fullType then return end

    local container = item.getContainer and item:getContainer() or inv
    if not container then return end
    if container.DoRemoveItem then
        container:DoRemoveItem(item)
    elseif container.Remove then
        container:Remove(item)
    end
    if sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(container, item)
    end

    local created = nil
    if container.AddItems then
        created = container:AddItems(def.ammo, tonumber(def.count) or 0)
    else
        for _ = 1, tonumber(def.count) or 0 do
            container:AddItem(def.ammo)
        end
    end
    if created and sendAddItemsToContainer then
        sendAddItemsToContainer(container, created)
    end
end

local function onClientCommand(module, command, playerObj, args)
    if module == MODULE_NAME and command == COMMAND_OPEN then
        openAmmoBox(playerObj, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)

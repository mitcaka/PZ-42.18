-- B42 context action fallback for FWP ammo boxes.
if isServer() then return end

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

local function normalizeSelectedItems(items)
    local result = {}
    if not items then return result end
    for _, entry in ipairs(items) do
        if type(entry) == "table" and entry.items then
            for _, stackedItem in ipairs(entry.items) do
                result[#result + 1] = stackedItem
            end
        else
            result[#result + 1] = entry
        end
    end
    return result
end

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

local function resolveContainer(playerObj, item)
    local container = item and item.getContainer and item:getContainer() or nil
    local inv = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if container and item and item.getID and container.containsID then
        if container:containsID(item:getID()) then return container end
    elseif container then
        return container
    end
    if inv and item and item.getID and inv.containsID then
        if inv:containsID(item:getID()) then return inv end
    end
    return container or inv
end

local function removeItemFromContainer(container, item)
    if not (container and item) then return false end
    if container.DoRemoveItem then
        container:DoRemoveItem(item)
    elseif container.Remove then
        container:Remove(item)
    end
    if sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(container, item)
    end
    if container.containsID and item.getID then
        return container:containsID(item:getID()) ~= true
    end
    return true
end

local function addItemsToContainer(container, fullType, count)
    if not (container and fullType and count and count > 0) then return nil end
    local created = nil
    if container.AddItems then
        created = container:AddItems(fullType, count)
    else
        for _ = 1, count do
            if container.AddItem then
                container:AddItem(fullType)
            end
        end
    end
    if created and sendAddItemsToContainer then
        sendAddItemsToContainer(container, created)
    end
    return created
end

local function openAmmoBoxLocal(playerObj, item)
    local fullType = getItemFullType(item)
    local def = fullType and AMMO_BOXES[fullType] or nil
    if not def then return false end
    local container = resolveContainer(playerObj, item)
    if not container then return false end
    if not removeItemFromContainer(container, item) then return false end
    addItemsToContainer(container, def.ammo, tonumber(def.count) or 0)
    if playerObj and playerObj.getInventory then
        playerObj:getInventory():setDrawDirty(true)
    end
    return true
end

local function openAmmoBox(playerObj, item)
    if not (playerObj and item) then return end
    if isClient and isClient() and sendClientCommand and item.getID then
        sendClientCommand(playerObj, MODULE_NAME, COMMAND_OPEN, {
            itemId = item:getID(),
            boxType = getItemFullType(item)
        })
        return
    end
    openAmmoBoxLocal(playerObj, item)
end

local function onInventoryContext(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    if not (playerObj and context) then return end
    for _, item in ipairs(normalizeSelectedItems(items)) do
        local def = AMMO_BOXES[getItemFullType(item)]
        if def then
            context:addOption(def.label or "Open Ammo Box", item, function(selectedItem)
                openAmmoBox(playerObj, selectedItem)
            end)
            return
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onInventoryContext)
print("[FWP AMMOBOX] B42 context fallback registered")

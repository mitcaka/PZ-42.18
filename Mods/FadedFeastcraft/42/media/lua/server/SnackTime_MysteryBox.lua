----------------------------------------------------------
-- 🎁 BOÎTES MYSTÈRES — SERVER (Build 42)
----------------------------------------------------------

local Commands = {}

Commands.OpenMysteryBox = function(player, args)
    if not player or not args or not args.boxId then return end

    local md = player:getModData()
    if md.SnackTimeOpening then return end
    md.SnackTimeOpening = true

    local inv = player:getInventory()
    if not inv then
        md.SnackTimeOpening = nil
        return
    end

    local box = inv:getItemWithID(args.boxId)
    if not box then
        md.SnackTimeOpening = nil
        return
    end

    local fullType = box:getFullType()
    local lootCount = 0
    local selectedMenu = nil

    if fullType == "SnackTime89.ST_BoiteMystere" then
        lootCount = 2 + ZombRand(5)

    elseif fullType == "SnackTime89.ST_BoiteMystereM" then
        selectedMenu = SnackTimeMystery.lootPoolM[
            ZombRand(#SnackTimeMystery.lootPoolM) + 1
        ]
        if not selectedMenu then
            md.SnackTimeOpening = nil
            return
        end
        lootCount = #selectedMenu
    else
        md.SnackTimeOpening = nil
        return
    end

    if not inv:hasRoomFor(player, lootCount) then
        player:Say(getText("UI_SnackTime_InventoryFull"))
        md.SnackTimeOpening = nil
        return
    end

    if fullType == "SnackTime89.ST_BoiteMystere" then
        for i = 1, lootCount do
            local loot = SnackTimeMystery.lootPool[
                ZombRand(#SnackTimeMystery.lootPool) + 1
            ]
            if loot then
                local it = inv:AddItem(loot)
                if it then sendAddItemToContainer(inv, it) end
            end
        end
    else
        for _, loot in ipairs(selectedMenu) do
            local it = inv:AddItem(loot)
            if it then sendAddItemToContainer(inv, it) end
        end
    end

    inv:Remove(box)
    sendRemoveItemFromContainer(inv, box)

    md.SnackTimeOpening = nil
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= "SnackTime89" then return end
    local fn = Commands[command]
    if fn then fn(player, args) end
end)

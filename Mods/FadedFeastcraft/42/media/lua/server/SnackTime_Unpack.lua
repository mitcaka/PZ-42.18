----------------------------------------------------------
-- 🍪 SnackTime89 — UNPACK PACKS (SERVER / MP SAFE)
-- Build 42 : FFC server authoritative + debug
----------------------------------------------------------

local Commands = {}

local ST_PACKS = {
    ["SnackTime89.ST_ChupaChups"] = "SnackTime89.ST_Lollipop",
    ["SnackTime89.ST_LUPetitEcolier"] = "SnackTime89.ST_BiscuitEcolier",
    ["SnackTime89.ST_BNChocolat"] = "SnackTime89.ST_BiscuitBNC",
    ["SnackTime89.ST_BNFraise"] = "SnackTime89.ST_BiscuitBNF",
    ["SnackTime89.ST_Oreo"] = "SnackTime89.ST_BiscuitOreo",
    ["SnackTime89.ST_TucNature"] = "SnackTime89.ST_BiscuitTUC",
    ["SnackTime89.ST_TucBacon"] = "SnackTime89.ST_BiscuitTUCB",
    ["SnackTime89.ST_Mikado"] = "SnackTime89.ST_BatonMikado",
    ["SnackTime89.ST_MentosFruit"] = "SnackTime89.ST_MentosCapsF",
    ["SnackTime89.ST_MentosMint"] = "SnackTime89.ST_MentosCaps",
    ["SnackTime89.ST_BenenutsCG"] = "SnackTime89.ST_BenenutsC",
    ["SnackTime89.ST_BenenutsNC"] = "SnackTime89.ST_BenenutsN",
    ["SnackTime89.ST_Bretzels"] = "SnackTime89.ST_BretzelsP",
    ["SnackTime89.ST_HariboCroco"] = "SnackTime89.ST_HariboC",
    ["SnackTime89.ST_HariboCola"] = "SnackTime89.ST_HariboCo",
    ["SnackTime89.ST_HariboOurs"] = "SnackTime89.ST_HariboO",
    ["SnackTime89.ST_HariboTagada"] = "SnackTime89.ST_HariboF",
    ["SnackTime89.ST_HariboSchtroumpfs"] = "SnackTime89.ST_HariboSc",
    ["SnackTime89.ST_HariboDragibus"] = "SnackTime89.ST_HariboD",
    ["SnackTime89.ST_HariboMix"] = "SnackTime89.ST_HariboM",
    ["SnackTime89.ST_Maltesers"] = "SnackTime89.ST_MaltesersB",
    ["SnackTime89.ST_MMs"] = "SnackTime89.ST_MM",
    ["SnackTime89.ST_Skittles"] = "SnackTime89.ST_SkittlesG",
    ["SnackTime89.ST_ChipsahoyO"] = "SnackTime89.ST_ChipsahoyOriginal",
    ["SnackTime89.ST_ChipsahoyC"] = "SnackTime89.ST_ChipsahoyChewy",
}

local function findItemByID(inv, id)
    if not inv or not id then return nil end

    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it:getID() == id then
            return it
        end
    end

    return nil
end

local function getMaxUses(pack)
    if not pack or not pack:IsDrainable() then return 0 end

    local useDelta = pack:getUseDelta()
    if not useDelta or useDelta <= 0 then return 0 end

    return math.floor((1 / useDelta) + 0.5)
end

local function getRemainingUses(pack)
    if not pack or not pack:IsDrainable() then return 0 end

    local maxUses = getMaxUses(pack)
    if maxUses <= 0 then return 0 end

    local md = pack:getModData()
    local uses = tonumber(md.ST_RemainingUses)

    if uses == nil then
        local delta = 1.0

        if pack.getDelta then
            delta = pack:getDelta() or 1.0
        elseif pack.getUsedDelta then
            local usedDelta = pack:getUsedDelta()
            if usedDelta ~= nil then
                delta = 1.0 - usedDelta
            end
        end

        if delta < 0 then delta = 0 end
        if delta > 1 then delta = 1 end

        uses = math.floor((delta / pack:getUseDelta()) + 0.0001)
        md.ST_RemainingUses = uses
    end

    uses = tonumber(md.ST_RemainingUses) or 0

    if uses < 0 then uses = 0 end
    if uses > maxUses then uses = maxUses end

    return uses
end

local function syncPackState(pack, remainingUses)
    if not pack then return end
    if not pack:getContainer() then return end

    local maxUses = getMaxUses(pack)
    if maxUses <= 0 then return end

    local uses = math.max(0, tonumber(remainingUses) or 0)
    if uses > maxUses then uses = maxUses end

    local md = pack:getModData()
    md.ST_RemainingUses = uses

    local newDelta = uses / maxUses
    if newDelta < 0 then newDelta = 0 end
    if newDelta > 1 then newDelta = 1 end

    if pack.setDelta then
        pack:setDelta(newDelta)
    end

    if pack.transmitModData then
        pack:transmitModData()
    end

    sendItemStats(pack)

    local container = pack:getContainer()
    if container and container.requestSync then
        container:requestSync()
    end
end

Commands.Unpack = function(player, args)
    if not player then
        return
    end

    if not args then
        return
    end

    if not args.packId or not args.count then
        return
    end

    local inv = player:getInventory()
    if not inv then
        return
    end

    local pack = findItemByID(inv, args.packId)
    if not pack then
        return
    end

    local resultType = ST_PACKS[pack:getFullType()]
    if not resultType then
        return
    end

    local wanted = tonumber(args.count) or 0
    if wanted <= 0 then
        return
    end

    local remaining = getRemainingUses(pack)

    if remaining <= 0 then
        return
    end

local count = math.min(wanted, remaining)

for i = 1, count do
    if not pack or not pack:getContainer() then
        break
    end

    if pack:IsDrainable() and pack.UseAndSync then
        pack:UseAndSync()
    elseif pack.Use then
        pack:Use()
    end

    local newItem = inv:AddItem(resultType)

    if newItem then
        sendAddItemToContainer(inv, newItem)
    end
end

    local newRemaining = getRemainingUses(pack)

    if newRemaining > 0 then
        syncPackState(pack, newRemaining)
    else
        if pack and pack:getContainer() then
            inv:Remove(pack)
            sendRemoveItemFromContainer(inv, pack)
        end
    end
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= "SnackTime89" then
        return
    end

    local fn = Commands[command]

    if fn then
        fn(player, args)
    else
    end
end)

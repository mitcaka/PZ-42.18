-- Server authority for weapon light and laser charging.
if isClient() then return end

local function sendResult(command, playerObj, args)
    if not sendServerCommand then return end
    args = args or {}
    args.onlineId = playerObj and playerObj.getOnlineID and playerObj:getOnlineID() or nil
    sendServerCommand(FWPWeaponLightCharge.MODULE, command, args)
end

local function onClientCommand(module, command, playerObj, args)
    if module ~= FWPWeaponLightCharge.MODULE or command ~= FWPWeaponLightCharge.COMMAND then return end
    local ok, result = FWPWeaponLightChargeApplyByArgs(playerObj, args)
    if ok then
        sendResult(FWPWeaponLightCharge.CONFIRM, playerObj, result)
    else
        print("[FWP LIGHT CHARGE][server] rejected reason=" .. tostring(result))
        sendResult(FWPWeaponLightCharge.ERROR, playerObj, { reason = tostring(result) })
    end
end

Events.OnClientCommand.Add(onClientCommand)
print("[FWP LIGHT CHARGE] server runtime registered")

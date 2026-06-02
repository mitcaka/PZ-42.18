-- Server authority for runtime weapon-work actions.
if isClient() then return end

local function sendResult(command, playerObj, args)
    if not sendServerCommand then return end
    args = args or {}
    args.onlineId = playerObj and playerObj.getOnlineID and playerObj:getOnlineID() or nil
    sendServerCommand(FWPWeaponWork.MODULE, command, args)
end

local function onClientCommand(module, command, playerObj, args)
    if module ~= FWPWeaponWork.MODULE or command ~= FWPWeaponWork.COMMAND then return end
    local ok, err = FWPWeaponWorkApplyCommand(playerObj, args)
    if ok then
        sendResult(FWPWeaponWork.CONFIRM, playerObj, { op = args and args.op })
    else
        print("[FWP WEAPONWORK][server] rejected op=" .. tostring(args and args.op) .. " reason=" .. tostring(err))
        sendResult(FWPWeaponWork.ERROR, playerObj, { op = args and args.op, reason = tostring(err) })
    end
end

Events.OnClientCommand.Add(onClientCommand)
print("[FWP WEAPONWORK] server runtime registered")

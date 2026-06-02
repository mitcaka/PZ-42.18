Cat_ShopSystem = Cat_ShopSystem or {}

local function applyRegisterWeight()
    local weight = 0.5
    if SandboxVars.Cat_ShopSystem and SandboxVars.Cat_ShopSystem.RegisterWeight ~= nil then
        weight = SandboxVars.Cat_ShopSystem.RegisterWeight
    end

    local items = { "Base.Cat_ShopRegister", "Base.Cat_BuyerRegister" }
    for _, fullType in ipairs(items) do
        local script = ScriptManager.instance and ScriptManager.instance:getItem(fullType)
        if script and script.setActualWeight then
            script:setActualWeight(weight)
        end
    end
end

Events.OnGameStart.Add(applyRegisterWeight)
print("[Cat_ShopSystem] Sandbox weight patch loaded.")

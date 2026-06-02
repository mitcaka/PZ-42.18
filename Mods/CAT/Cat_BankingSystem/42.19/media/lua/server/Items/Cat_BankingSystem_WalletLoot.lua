-- =============================================================================
-- Cat Banking System — Zombie Wallet Loot (Server)
-- Replaces base-game zombie wallet drops with configurable sandbox options.
-- Supports multiple money denominations and optional credit card spawns.
-- =============================================================================

local MOD_TAG = "[Cat_BankingSystem WalletLoot] "

local function log(msg)
    print(MOD_TAG .. tostring(msg))
end

local function safe(fn, fallback)
    local ok, result = pcall(fn)
    if ok then return result end
    return fallback
end

-- Read sandbox option using the getSandboxOptions() API (Cat_Darkness pattern).
local function getSandboxOption(name, default)
    local opts = getSandboxOptions()
    local opt = opts and opts:getOptionByName(name)
    if opt then
        local val = opt:getValue()
        if val ~= nil then return val end
    end
    return default
end

local function getWalletDropChance()
    return tonumber(getSandboxOption("Cat_BankingSystem.WalletDropChance", 15.0)) or 15.0
end

local function getWalletMinMoney()
    return tonumber(getSandboxOption("Cat_BankingSystem.WalletMinMoney", 5)) or 5
end

local function getWalletMaxMoney()
    return tonumber(getSandboxOption("Cat_BankingSystem.WalletMaxMoney", 50)) or 50
end

local function getWalletCreditCardChance()
    return tonumber(getSandboxOption("Cat_BankingSystem.WalletCreditCardChance", 5.0)) or 5.0
end

-- Patch base-game wallet drops out of zombie inventories to prevent duplicates.
local function patchZombieDistributions()
    safe(function()
        local all = SuburbsDistributions and SuburbsDistributions.all
        if not all then return end

        if all.inventoryfemale and all.inventoryfemale.items then
            local items = all.inventoryfemale.items
            for i = 1, #items, 2 do
                if items[i] == "Wallet_Female" then
                    items[i + 1] = 0
                    break
                end
            end
        end

        if all.inventorymale and all.inventorymale.items then
            local items = all.inventorymale.items
            for i = 1, #items, 2 do
                if items[i] == "Wallet_Male" then
                    items[i + 1] = 0
                    break
                end
            end
        end
    end, nil)
end

local function rollMoneyAmount()
    local minAmt = getWalletMinMoney()
    local maxAmt = getWalletMaxMoney()

    if minAmt > maxAmt then
        minAmt, maxAmt = maxAmt, minAmt
    end

    if minAmt == maxAmt then
        return minAmt
    end

    return ZombRand(minAmt, maxAmt + 1)
end

local function getWalletType(zombie)
    return safe(function()
        if zombie:isFemale() then
            return "Base.Wallet_Female"
        end
        return "Base.Wallet_Male"
    end, "Base.Wallet")
end

local function addWalletToZombie(zombie)
    if not zombie then return false end

    return safe(function()
        local inv = zombie:getInventory()
        if not inv then return false end

        local walletType = getWalletType(zombie)
        local wallet = inv:AddItem(walletType)

        if wallet then
            local walletInv = wallet:getInventory()
            if walletInv then
                local amount = rollMoneyAmount()
                if amount > 0 then
                    Cat_EconomyUtils.giveMoneyToContainer(walletInv, amount)
                end

                local ccChance = getWalletCreditCardChance()
                if ccChance > 0 and ZombRandFloat(0.0, 100.0) <= ccChance then
                    walletInv:AddItem("Base.CreditCard")
                end
            end
            return true
        end

        return false
    end, false)
end

local function onZombieDead(zombie)
    -- In multiplayer, only the server should create the corpse loot.
    if isClient and isClient() then return end

    local chance = getWalletDropChance()
    if chance <= 0 then return end

    if ZombRandFloat(0.0, 100.0) <= chance then
        addWalletToZombie(zombie)
    end
end

local function initWalletLoot()
    patchZombieDistributions()
    log("Initialized. DropChance=" .. tostring(getWalletDropChance()) .. "%, Min=$" .. tostring(getWalletMinMoney()) .. ", Max=$" .. tostring(getWalletMaxMoney()) .. ", CreditCardChance=" .. tostring(getWalletCreditCardChance()) .. "%")
end

-- Patch immediately at load time (base game tables are already loaded).
patchZombieDistributions()

Events.OnInitGlobalModData.Add(initWalletLoot)
Events.OnZombieDead.Add(onZombieDead)

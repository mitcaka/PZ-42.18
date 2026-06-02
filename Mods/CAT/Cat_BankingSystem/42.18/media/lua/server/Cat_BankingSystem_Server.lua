-- =============================================================================
-- Cat Banking System — Server
-- =============================================================================
if not isServer() then return end

local MOD_NAME = "Cat_BankingSystem"
local MOD_DATA_KEY = "Cat_BankingData"

-- ---------------------------------------------------------------------------
-- ModData helpers (persistent server-side table)
-- ---------------------------------------------------------------------------
local function getBankingData()
    return ModData.getOrCreate(MOD_DATA_KEY)
end

local function ensureAccountsTable()
    local data = getBankingData()
    if not data.accounts then
        data.accounts = {}
    end
    return data.accounts
end

local function getAccount(username)
    local accounts = ensureAccountsTable()
    return accounts[username]
end

local function setAccount(username, account)
    local accounts = ensureAccountsTable()
    accounts[username] = account
end

-- ---------------------------------------------------------------------------
-- Server commands
-- ---------------------------------------------------------------------------
local function onClientCommand(module, command, player, args)
    if module ~= MOD_NAME then return end

    local username = player:getUsername()
    if not username or username == "" then return end

    if command == "checkAccount" then
        local account = getAccount(username)
        if account then
            sendServerCommand(player, MOD_NAME, "accountInfo", { hasAccount = true, pin = account.pin, balance = account.balance })
        else
            sendServerCommand(player, MOD_NAME, "accountInfo", { hasAccount = false })
        end

    elseif command == "authenticate" then
        local pin = args and args.pin or ""
        local account = getAccount(username)

        if not account then
            -- Create new account with this PIN
            if #pin ~= 4 then
                sendServerCommand(player, MOD_NAME, "authResult", { success = false, error = "PIN must be 4 digits." })
                return
            end
            account = { pin = pin, balance = 0 }
            setAccount(username, account)
            sendServerCommand(player, MOD_NAME, "authResult", { success = true, balance = 0, message = "Account created." })
        else
            if account.pin == pin then
                sendServerCommand(player, MOD_NAME, "authResult", { success = true, balance = account.balance })
            else
                sendServerCommand(player, MOD_NAME, "authResult", { success = false, error = "Incorrect PIN." })
            end
        end

    elseif command == "deposit" then
        local amount = args and args.amount or 0
        if amount <= 0 then
            sendServerCommand(player, MOD_NAME, "transactionResult", { success = false, error = "Invalid amount." })
            return
        end

        local account = getAccount(username)
        if not account then
            sendServerCommand(player, MOD_NAME, "transactionResult", { success = false, balance = 0, error = "No account found." })
            return
        end

        local hasMoney = Cat_EconomyUtils.getMoneyCount(player)
        if hasMoney < amount then
            sendServerCommand(player, MOD_NAME, "transactionResult", { success = false, balance = account.balance, error = "Not enough cash." })
            return
        end

        local removed = Cat_EconomyUtils.removeMoney(player, amount)
        if not removed then
            sendServerCommand(player, MOD_NAME, "transactionResult", { success = false, balance = account.balance, error = "Failed to remove cash." })
            return
        end

        account.balance = account.balance + amount
        setAccount(username, account)
        sendServerCommand(player, MOD_NAME, "transactionResult", { success = true, balance = account.balance, message = "Deposited $" .. amount .. "." })
        sendServerCommand(player, MOD_NAME, "refreshInventory", {})

    elseif command == "withdraw" then
        local amount = args and args.amount or 0
        if amount <= 0 then
            sendServerCommand(player, MOD_NAME, "transactionResult", { success = false, error = "Invalid amount." })
            return
        end

        local account = getAccount(username)
        if not account then
            sendServerCommand(player, MOD_NAME, "transactionResult", { success = false, balance = 0, error = "No account found." })
            return
        end

        if account.balance < amount then
            sendServerCommand(player, MOD_NAME, "transactionResult", { success = false, balance = account.balance, error = "Insufficient funds." })
            return
        end

        account.balance = account.balance - amount
        setAccount(username, account)
        Cat_EconomyUtils.giveMoney(player, amount)
        sendServerCommand(player, MOD_NAME, "transactionResult", { success = true, balance = account.balance, message = "Withdrew $" .. amount .. "." })
        sendServerCommand(player, MOD_NAME, "refreshInventory", {})

    elseif command == "getBalance" then
        local account = getAccount(username)
        if account then
            sendServerCommand(player, MOD_NAME, "balanceUpdate", { balance = account.balance })
        else
            sendServerCommand(player, MOD_NAME, "balanceUpdate", { balance = 0 })
        end
    end
end
Events.OnClientCommand.Add(onClientCommand)

print("[Cat_BankingSystem Server] Loaded.")

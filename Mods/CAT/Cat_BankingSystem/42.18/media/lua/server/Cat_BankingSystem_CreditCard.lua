-- =============================================================================
-- Cat Banking System — Credit Card Hacking & ATM Usage (Server)
-- =============================================================================
if not isServer() then return end

local MOD_NAME = "Cat_BankingSystem"
local MOD_DATA_KEY = "Cat_BankingData"

local CC_TYPES = {
    ["Base.CreditCard"] = true,
    ["Base.CreditCard_Stolen"] = true,
}

local HACK_TERMS = {
    "READ", "WRITE", "SCAN", "AUTH",
    "DECODE", "PARSE", "VERIFY", "INIT",
    "MAIN", "LOOP"
}

-- Active hack sessions: keyed by username
local hackSessions = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function getBankingData()
    return ModData.getOrCreate(MOD_DATA_KEY)
end

local function getCreditCardKey(cardName, cardType)
    local key = tostring(cardName or "Unknown") .. "_" .. tostring(cardType or "Card")
    key = key:gsub("[%s%p]", "_")
    return key
end

local function getOrCreateCreditCardData(cardName, cardType)
    local data = getBankingData()
    if not data.creditCards then
        data.creditCards = {}
    end
    local key = getCreditCardKey(cardName, cardType)
    if not data.creditCards[key] then
        local pin = string.format("%04d", ZombRand(0, 10000))
        local balance = ZombRand(5, 51) * 10  -- $50 to $500 in $10 steps
        data.creditCards[key] = {
            pin = pin,
            balance = balance,
            hackedBy = {},
        }
    end
    return data.creditCards[key]
end

local function hasItemInInventory(player, itemType)
    local inv = player:getInventory()
    if not inv then return false end
    return inv:contains(itemType)
end

local function buildMastermindFeedback(key, guess)
    local greens = 0
    local yellows = 0
    local feedback = {}
    local keySet = {}
    for i = 1, 4 do
        keySet[key[i]] = true
        feedback[i] = "none"
    end
    for i = 1, 4 do
        if guess[i] == key[i] then
            greens = greens + 1
            feedback[i] = "green"
        elseif keySet[guess[i]] then
            yellows = yellows + 1
            feedback[i] = "yellow"
        end
    end
    return greens, yellows, feedback
end

-- ---------------------------------------------------------------------------
-- Client commands
-- ---------------------------------------------------------------------------
local function onClientCommand(module, command, player, args)
    if module ~= MOD_NAME then return end

    local username = player:getUsername() or ""

    if command == "startHack" then
        local cardName = args and args.cardName or ""
        local cardType = args and args.cardType or ""

        if not CC_TYPES[cardType] then
            sendServerCommand(player, MOD_NAME, "hackStarted", { success = false, error = "Invalid card." })
            return
        end
        if not hasItemInInventory(player, cardType) then
            sendServerCommand(player, MOD_NAME, "hackStarted", { success = false, error = "Card not found." })
            return
        end
        if not hasItemInInventory(player, "Base.Cat_CardDecoder") then
            sendServerCommand(player, MOD_NAME, "hackStarted", { success = false, error = "No card decoder." })
            return
        end

        local cardData = getOrCreateCreditCardData(cardName, cardType)
        local skill = player:getPerkLevel(Perks.Electricity)
        local gameType = ZombRand(1, 4)  -- 1 = Timing, 2 = Mastermind, 3 = Memory

        if gameType == 1 then
            -- Timing: lock target terms as they appear
            local targets = {}
            for i = 1, 4 do targets[i] = ZombRand(0, 10) end
            local durations = {}
            local baseDuration = 180  -- ms per term at skill 0
            local bonus = skill * 60
            for i = 1, 4 do
                local d = baseDuration + bonus + ZombRand(-40, 41)
                if d < 130 then d = 130 end
                durations[i] = d
            end
            hackSessions[username] = {
                gameType = 1,
                cardName = cardName,
                cardType = cardType,
                targets = targets,
                durations = durations,
            }
            sendServerCommand(player, MOD_NAME, "hackStarted", {
                success = true,
                gameType = 1,
                cardName = cardName,
                cardType = cardType,
                targets = targets,
                durations = durations,
            })

        elseif gameType == 2 then
            -- Mastermind: guess the 4-function key
            local key = {}
            local pool = {0,1,2,3,4,5,6,7,8,9}
            for i = 1, 4 do
                local idx = ZombRand(1, #pool + 1)
                key[i] = pool[idx]
                table.remove(pool, idx)
            end
            local maxAttempts = 4 + math.floor(skill / 2)  -- 4 to 9
            hackSessions[username] = {
                gameType = 2,
                cardName = cardName,
                cardType = cardType,
                key = key,
                attempts = 0,
                maxAttempts = maxAttempts,
            }
            sendServerCommand(player, MOD_NAME, "hackStarted", {
                success = true,
                gameType = 2,
                cardName = cardName,
                cardType = cardType,
                maxAttempts = maxAttempts,
            })

        else
            -- Memory: watch and repeat a sequence
            local sequenceLength = math.max(4, 8 - math.floor(skill / 2))
            local sequence = {}
            for i = 1, sequenceLength do
                sequence[i] = ZombRand(0, 10)
            end
            local displayDuration = 600 + (skill * 80)  -- ms each term is shown
            hackSessions[username] = {
                gameType = 3,
                cardName = cardName,
                cardType = cardType,
                sequence = sequence,
                displayDuration = displayDuration,
            }
            sendServerCommand(player, MOD_NAME, "hackStarted", {
                success = true,
                gameType = 3,
                cardName = cardName,
                cardType = cardType,
                sequence = sequence,
                displayDuration = displayDuration,
            })
        end

    elseif command == "finishHack" then
        local cardName = args and args.cardName or ""
        local cardType = args and args.cardType or ""
        local gameType = args and args.gameType or 0

        if not CC_TYPES[cardType] then
            sendServerCommand(player, MOD_NAME, "hackResult", { success = false, error = "Invalid card." })
            return
        end
        if not hasItemInInventory(player, cardType) then
            sendServerCommand(player, MOD_NAME, "hackResult", { success = false, error = "Card not found." })
            return
        end
        if not hasItemInInventory(player, "Base.Cat_CardDecoder") then
            sendServerCommand(player, MOD_NAME, "hackResult", { success = false, error = "No card decoder." })
            return
        end

        local session = hackSessions[username]
        if not session then
            sendServerCommand(player, MOD_NAME, "hackResult", { success = false, error = "No active hack session." })
            return
        end

        local cardData = getOrCreateCreditCardData(cardName, cardType)
        if cardData.hackedBy and cardData.hackedBy[username] then
            sendServerCommand(player, MOD_NAME, "hackResult", {
                success = true,
                pin = cardData.pin,
                message = "Already decrypted. PIN: " .. cardData.pin,
            })
            hackSessions[username] = nil
            return
        end

        if gameType == 1 then
            -- Timing validation
            local stops = args.stops
            local allMatch = true
            if not stops or #stops ~= 4 then
                allMatch = false
            else
                for i = 1, 4 do
                    if stops[i] ~= session.targets[i] then
                        allMatch = false
                        break
                    end
                end
            end
            hackSessions[username] = nil
            if allMatch then
                cardData.hackedBy = cardData.hackedBy or {}
                cardData.hackedBy[username] = true
                sendServerCommand(player, MOD_NAME, "hackResult", {
                    success = true,
                    pin = cardData.pin,
                    message = "Decryption successful! PIN: " .. cardData.pin,
                })
            else
                sendServerCommand(player, MOD_NAME, "hackResult", {
                    success = false,
                    error = "Decryption failed. Incorrect sequence.",
                })
            end

        elseif gameType == 2 then
            -- Mastermind validation
            local guess = args.guess
            local correct = false
            if guess and #guess == 4 then
                correct = true
                for i = 1, 4 do
                    if guess[i] ~= session.key[i] then
                        correct = false
                        break
                    end
                end
            end

            if correct then
                hackSessions[username] = nil
                cardData.hackedBy = cardData.hackedBy or {}
                cardData.hackedBy[username] = true
                sendServerCommand(player, MOD_NAME, "hackResult", {
                    success = true,
                    pin = cardData.pin,
                    message = "Decryption successful! PIN: " .. cardData.pin,
                })
            else
                session.attempts = session.attempts + 1
                if session.attempts >= session.maxAttempts then
                    hackSessions[username] = nil
                    sendServerCommand(player, MOD_NAME, "hackResult", {
                        success = false,
                        error = "Decryption failed. Too many incorrect attempts.",
                    })
                else
                    local greens, yellows, feedback = buildMastermindFeedback(session.key, guess or {})
                    sendServerCommand(player, MOD_NAME, "hackFeedback", {
                        success = false,
                        greens = greens,
                        yellows = yellows,
                        feedback = feedback,
                        attemptsUsed = session.attempts,
                        maxAttempts = session.maxAttempts,
                    })
                end
            end

        elseif gameType == 3 then
            -- Memory validation
            local sequence = args.sequence
            local correct = false
            if sequence and #sequence == #session.sequence then
                correct = true
                for i = 1, #session.sequence do
                    if sequence[i] ~= session.sequence[i] then
                        correct = false
                        break
                    end
                end
            end
            hackSessions[username] = nil
            if correct then
                cardData.hackedBy = cardData.hackedBy or {}
                cardData.hackedBy[username] = true
                sendServerCommand(player, MOD_NAME, "hackResult", {
                    success = true,
                    pin = cardData.pin,
                    message = "Decryption successful! PIN: " .. cardData.pin,
                })
            else
                sendServerCommand(player, MOD_NAME, "hackResult", {
                    success = false,
                    error = "Decryption failed. Sequence mismatch.",
                })
            end
        end

    elseif command == "authenticateCreditCard" then
        local cardName = args and args.cardName or ""
        local cardType = args and args.cardType or ""
        local pin = args and args.pin or ""

        if not CC_TYPES[cardType] then
            sendServerCommand(player, MOD_NAME, "authResult", { success = false, error = "Invalid card.", mode = "creditCard" })
            return
        end

        local cardData = getOrCreateCreditCardData(cardName, cardType)
        if cardData.pin == pin then
            sendServerCommand(player, MOD_NAME, "authResult", {
                success = true,
                balance = cardData.balance,
                mode = "creditCard",
                cardName = cardName,
                cardType = cardType,
            })
        else
            sendServerCommand(player, MOD_NAME, "authResult", {
                success = false,
                error = "Incorrect PIN.",
                mode = "creditCard",
            })
        end

    elseif command == "withdrawCreditCard" then
        local cardName = args and args.cardName or ""
        local cardType = args and args.cardType or ""
        local amount = args and args.amount or 0

        if amount <= 0 then
            sendServerCommand(player, MOD_NAME, "transactionResult", { success = false, error = "Invalid amount.", mode = "creditCard" })
            return
        end

        local cardData = getOrCreateCreditCardData(cardName, cardType)
        if cardData.balance < amount then
            sendServerCommand(player, MOD_NAME, "transactionResult", {
                success = false,
                balance = cardData.balance,
                error = "Insufficient funds on card.",
                mode = "creditCard",
            })
            return
        end

        cardData.balance = cardData.balance - amount
        Cat_EconomyUtils.giveMoney(player, amount)
        sendServerCommand(player, MOD_NAME, "transactionResult", {
            success = true,
            balance = cardData.balance,
            message = "Withdrew $" .. amount .. " from card.",
            mode = "creditCard",
        })
        sendServerCommand(player, MOD_NAME, "refreshInventory", {})
    end
end
Events.OnClientCommand.Add(onClientCommand)

print("[Cat_BankingSystem Server] Credit card module loaded.")

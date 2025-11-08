_pendingContactless = {}

AddEventHandler("Businesses:Server:Startup", function()
    exports["sandbox-base"]:RegisterServerCallback("Contactless:Create", function(source, data, cb)
        local char = exports['sandbox-characters']:FetchCharacterSource(source)
        -- Should probably do some better checking here later
        if char and data and data.job and data.terminalId and data.payment and data.payment > 0 and data.payment <= 25000 then
            if Player(source).state.onDuty == data.job then
                if not _pendingContactless[data.terminalId] then
                    local amount = math.floor(data.payment)

                    local jobData = exports['sandbox-jobs']:Get(data.job)
                    local jobBank = exports['sandbox-finance']:AccountsGetOrganization(data.job)

                    _pendingContactless[data.terminalId] = {
                        job = data.job,
                        jobName = jobData.Name,
                        jobAccount = jobBank?.Account,
                        amount = amount,
                        description = data.description,
                        billerSource = source,
                        biller = {
                            First = char:GetData("First"),
                            Last = char:GetData("Last"),
                            SID = char:GetData("SID"),
                        },
                    }

                    GlobalState[string.format("PendingContactless:%s", data.terminalId)] = amount
                    cb(true)
                else
                    cb(false, "There is a payment already pending!")
                end
            else
                cb(false, "Not on Duty")
            end
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback("Contactless:Clear", function(source, data, cb)
        local char = exports['sandbox-characters']:FetchCharacterSource(source)
        if char and data and data.job and data.terminalId then
            if Player(source).state.onDuty == data.job then
                if _pendingContactless[data.terminalId] then
                    _pendingContactless[data.terminalId] = nil
                    GlobalState[string.format("PendingContactless:%s", data.terminalId)] = false
                else
                    cb(false, "No payments pending!")
                end
            else
                cb(false, "Not on Duty")
            end
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback("Contactless:Pay", function(source, data, cb)
        local char = exports['sandbox-characters']:FetchCharacterSource(source)
        if char and data and data.terminalId and _pendingContactless[data.terminalId] and GlobalState[string.format("PendingContactless:%s", data.terminalId)] then
            GlobalState[string.format("PendingContactless:%s", data.terminalId)] = false

            local pData = _pendingContactless[data.terminalId]

            local wSuccess = exports['sandbox-finance']:BalanceCharge(char:GetData("BankAccount"), pData.amount, {
                type = 'bill',
                transactionAccount = pData.jobAccount,
                title = 'Contactless Payment',
                description = string.format('Contactless Payment to %s. Description: %s', pData.jobName,
                    pData.description),
                data = {
                    biller = pData.biller.SID,
                    character = char:GetData("SID"),
                }
            })

            if wSuccess then
                if pData.jobAccount then
                    local success = exports['sandbox-finance']:BalanceDeposit(pData.jobAccount, pData.amount, {
                        type = 'bill',
                        transactionAccount = char:GetData("BankAccount"),
                        title = 'Contactless Payment',
                        description = string.format('Contactless Payment From State ID: %s. Description: %s',
                            char:GetData("SID"), pData.description),
                        data = {
                            biller = pData.biller.SID,
                            character = char:GetData("SID"),
                        }
                    })
                end

                exports['sandbox-phone']:NotificationAdd(pData.billerSource, "Contactless Payment Received",
                    string.format("Received $%s for %s.", math.floor(pData.amount), pData.jobName), os.time(), 8000,
                    "bank", {})
                exports['sandbox-hud']:Notification(pData.billerSource, "success", "Contactless Payment Received")

                exports['sandbox-phone']:NotificationAdd(source, "Contactless Payment Accepted",
                    string.format("Paid $%s to %s", math.floor(pData.amount), pData.jobName), os.time(), 8000, "bank", {})

                exports['sandbox-laptop']:BizWizReceiptsCreate(pData.job, {
                    type = "Contactless Terminal",
                    time = os.time() * 1000,
                    author = pData.biller,
                    workers = {},
                    paymentPaid = pData.amount,
                    notes = pData.description,
                    job = pData.job,
                    customerNumber = "",
                    customerName = string.format("%s %s", char:GetData("First"), char:GetData("Last")),
                })

                _pendingContactless[data.terminalId] = false

                cb(true)
            else
                exports['sandbox-phone']:NotificationAdd(pData.billerSource, "Contactless Payment Failed",
                    string.format("Payment of $%s for %s failed.", math.floor(pData.amount), pData.jobName), os.time(),
                    8000, "bank", {})
                exports['sandbox-hud']:Notification(pData.billerSource, "error", "Contactless Payment Failed")

                exports['sandbox-phone']:NotificationAdd(source, "Contactless Payment Failed",
                    string.format("Payment of $%s to %s just failed. Is your balance sufficient?",
                        math.floor(pData.amount), pData.jobName), os.time(), 8000, "bank", {})

                GlobalState[string.format("PendingContactless:%s", data.terminalId)] = pData.amount

                cb(false)
            end
        else
            cb(false)
        end
    end)
end)

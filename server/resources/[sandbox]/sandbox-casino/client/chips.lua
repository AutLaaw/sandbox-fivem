local priceLevels = { 100, 500, 1000, 5000, 10000, 50000 }

AddEventHandler("Casino:Client:StartChipPurchase", function()
    if not LocalPlayer.state.Character then
        return
    end

    local cash = LocalPlayer.state.Character:GetData("Cash") or 0
    local chips = _currentChips

    local buyMenu = {
        main = {
            label = "Purchase Casino Chips",
            items = {
                {
                    --label = "Current Chip Balance",
                    label = string.format("You Have $%s Worth of Chips", formatNumberToCurrency(math.floor(chips))),
                    --disabled = true,
                },
            },
        }
    }

    if cash >= 100 then
        local buyMax = math.floor(cash / 1000) * 1000

        if buyMax > 10000 then
            table.insert(buyMenu.main.items, {
                label = string.format("Convert All Cash To Chips ($%s)", formatNumberToCurrency(buyMax)),
                description = string.format("Convert $%s into Chips", formatNumberToCurrency(buyMax)),
                event = "Casino:Client:ConfirmChipPurchase",
                data = { amount = buyMax },
            })
        end

        for k, v in ipairs(priceLevels) do
            table.insert(buyMenu.main.items, {
                label = string.format("Buy $%s of Chips", formatNumberToCurrency(v)),
                description = string.format("Convert $%s into Chips", formatNumberToCurrency(v)),
                event = "Casino:Client:ConfirmChipPurchase",
                data = { amount = v },
                disabled = cash < v
            })
        end

        exports['sandbox-hud']:ListMenuShow(buyMenu)
    else
        exports["sandbox-hud"]:Notification("error", "Not Enough Cash - Minimum is $100")
    end
end)

AddEventHandler("Casino:Client:ConfirmChipPurchase", function(data)
    exports["sandbox-base"]:ServerCallback("Casino:BuyChips", data.amount)
    TriggerEvent("Casino:Client:UpdateChips")
end)

AddEventHandler("Casino:Client:StartChipSell", function()
    if not LocalPlayer.state.Character then
        return
    end

    local cash = LocalPlayer.state.Character:GetData("Cash") or 0
    local chips = _currentChips

    local buyMenu = {
        main = {
            label = "Cash Out Casino Chips",
            items = {
                {
                    --label = "Current Chip Balance",
                    label = string.format("You Have $%s Worth of Chips", formatNumberToCurrency(math.floor(chips))),
                    --disabled = true,
                },
            },
        }
    }

    if chips > 0 then
        local sellMax = math.floor(chips)

        table.insert(buyMenu.main.items, {
            label = string.format("Cash Out All Chips ($%s)", formatNumberToCurrency(sellMax)),
            description = string.format("Convert $%s worth of chips into cash", formatNumberToCurrency(sellMax)),
            event = "Casino:Client:ConfirmChipSell",
            data = { amount = sellMax },
        })

        for k, v in ipairs(priceLevels) do
            if chips >= v then
                table.insert(buyMenu.main.items, {
                    label = string.format("Cash Out $%s of Chips", formatNumberToCurrency(v)),
                    description = string.format("Convert $%s worth of chips into cash", formatNumberToCurrency(v)),
                    event = "Casino:Client:ConfirmChipSell",
                    data = { amount = v },
                })
            end
        end

        exports['sandbox-hud']:ListMenuShow(buyMenu)
    else
        exports["sandbox-hud"]:Notification("error", "No Chips to Sell")
    end
end)

AddEventHandler("Casino:Client:ConfirmChipSell", function(data)
    exports["sandbox-base"]:ServerCallback("Casino:SellChips", data.amount)
    TriggerEvent("Casino:Client:UpdateChips")
end)

_CASINO = _CASINO or {}

_CASINO.Chips = {
    Get = function(self)
        local chips = 0
        if LocalPlayer.state.loggedIn and LocalPlayer.state.Character then
            if LocalPlayer.state.Character:GetData("CasinoChips") and LocalPlayer.state.Character:GetData("CasinoChips") > 0 then
                chips = LocalPlayer.state.Character:GetData("CasinoChips")
            end
        end

        return chips
    end,
    Has = function(self, amount)
        if amount > 0 then
            return _currentChips >= amount
        end
        return false
    end
}

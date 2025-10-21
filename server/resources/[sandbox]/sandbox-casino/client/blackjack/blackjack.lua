_BJdealerPeds = {}
_BJcardObjects = {}

_BJclosestChair = -1

_BJsatAtTable = false
_BJsatAtLocalChair = false
_BJlastDealerCard = {}

_blackjackTablesConfig = nil

local _inSittingDownAnimation = false
local _blackjackAwaitingResponse = false

local _blackJackStatebagHandler

AddEventHandler("Casino:Client:Startup", function()
    _blackjackTablesConfig = GlobalState["Casino:BlackjackConfig"]

    for k, v in pairs(_blackjackTables) do
        local maxBet = formatNumberToCurrency(math.floor(_blackjackTablesConfig[k].bet[#_blackjackTablesConfig[k].bet]))
        exports.ox_target:addBoxZone({
            id = "casino-blackjack-" .. k,
            coords = v.polyzone.center,
            size = vector3(v.polyzone.length, v.polyzone.width, 2.0),
            rotation = v.polyzone.options.heading or 0,
            debug = false,
            minZ = v.polyzone.options.minZ,
            maxZ = v.polyzone.options.maxZ,
            options = {
                {
                    icon = "cards",
                    label = _blackjackTablesConfig[k].isVIP and string.format("Join VIP Game ($%s Max Bet)", maxBet) or
                        string.format("Join Game ($%s Max Bet)", maxBet),
                    event = "Casino:Client:JoinBlackjack",
                    onSelect = function()
                        TriggerEvent("Casino:Client:JoinBlackjack", { table = k })
                    end,
                    canInteract = function()
                        return CanJoinBlackjackTable(k) and not _BJsatAtTable and GlobalState["CasinoOpen"]
                    end,
                },
                {
                    icon = "cards",
                    label = "Game Full",
                    canInteract = function()
                        return not CanJoinBlackjackTable(k) and not _BJsatAtTable
                    end,
                },
                {
                    icon = "cards",
                    label = "Leave Game",
                    event = "Casino:Client:LeaveBlackjack",
                    onSelect = function()
                        TriggerEvent("Casino:Client:LeaveBlackjack", { table = k })
                    end,
                    canInteract = function()
                        return _BJsatAtTable and not _inSittingDownAnimation and not _blackjackAwaitingResponse and
                            not GlobalState[string.format("Casino:Blackjack:%s", k)]?.Started
                    end,
                },
                {
                    icon = "play",
                    label = _blackjackTablesConfig[k].isVIP and string.format("Start VIP Game ($%s Max Bet)", maxBet) or
                        string.format("Start Game ($%s Max Bet)", maxBet),
                    event = "Casino:Client:StartBlackjack",
                    onSelect = function()
                        TriggerEvent("Casino:Client:StartBlackjack", { table = k })
                    end,
                    canInteract = function()
                        return _BJsatAtTable and not _inSittingDownAnimation and not _blackjackAwaitingResponse and
                            not GlobalState[string.format("Casino:Blackjack:%s", k)]?.Started and
                            GlobalState["CasinoOpen"]
                    end,
                },
            }
        })
    end

    exports["sandbox-base"]:RegisterClientCallback("Casino:Client:RequestHitStand", function(data, cb)
        local itemList = {
            {
                label = "Stand",
                description = "Be boring and stand at " .. data.currentHand,
                event = "Casino:Client:RecievePromptData",
                data = { state = "stand" }
            },
            {
                label = "Hit",
                description = "You won't do it loser...",
                event = "Casino:Client:RecievePromptData",
                data = { state = "hit" }
            },
        }


        if data.canDouble then
            table.insert(itemList, {
                label = string.format("Double Down ($%s)", formatNumberToCurrency(math.floor(data.currentBet))),
                description = "Double Down!",
                event = "Casino:Client:RecievePromptData",
                data = { state = "double" },
                disabled = data.currentBet > _currentChips
            })
        end

        local res = StartListMenuPrompt({
            main = {
                label = "Blackjack",
                items = itemList,
            }
        }, 19000)

        if res?.success and res?.data?.state then
            cb(true, res.data.state)

            if res.data.state == "stand" then
                DoBlackjackDeclineCardAnimation()
            else
                DoBlackjackRequestCardAnimation()
            end
        elseif res?.timeout then
            cb(false)
            exports["sandbox-hud"]:Notification("error", "Ran Out of Time...")
        else
            cb(false)
        end
    end)
end)

RegisterNetEvent('Characters:Client:Logout')
AddEventHandler('Characters:Client:Logout', function()
    if _BJsatAtTable then
        _BJsatAtTable = false
        _BJsatAtLocalChair = false
        leaveBlackjackSeatForced()
    end
end)

AddEventHandler("Casino:Client:Enter", function()
    loadModel(`s_m_y_casino_01`)
    loadModel(`s_f_y_casino_01`)
    loadAnim("anim_casino_b@amb@casino@games@shared@dealer@")
    loadAnim("anim_casino_b@amb@casino@games@blackjack@player")

    CreateThread(function()
        while _insideCasino do
            Wait(350)
            local closestDist = 1000
            local playerCoords = GetEntityCoords(LocalPlayer.state.ped)

            for i = 0, (_blackjackTablesCount * 4) - 1, 1 do
                local seatCoords = blackjack_func_348(i)
                local dist = #(playerCoords - seatCoords)
                if dist <= closestDist then
                    closestDist = dist
                    _BJclosestChair = i
                end
            end
        end
    end)

    while not _blackjackTablesConfig do
        Wait(100)
    end

    for k, v in pairs(_blackjackTables) do
        local serverData = _blackjackTablesConfig[k]

        local dealer = CreatePed(26, serverData.dealerVariation >= 8 and `s_f_y_casino_01` or `s_m_y_casino_01`,
            v.dealer.coords.x, v.dealer.coords.y, v.dealer.coords.z, v.dealer.heading, false, true)
        SetEntityCanBeDamaged(dealer, 0)
        FreezeEntityPosition(dealer, true)
        SetPedAsEnemy(dealer, 0)
        SetBlockingOfNonTemporaryEvents(dealer, 1)
        SetPedResetFlag(dealer, 249, 1)
        SetPedConfigFlag(dealer, 185, true)
        SetPedConfigFlag(dealer, 108, true)
        SetPedCanEvasiveDive(dealer, 0)
        SetPedCanRagdollFromPlayerImpact(dealer, 0)
        SetPedConfigFlag(dealer, 208, true)
        SetPedSeeingRange(dealer, 0)

        SetBlackjackDealerVariation(dealer, serverData.dealerVariation)

        SetEntityCoordsNoOffset(dealer, v.dealer.coords.x, v.dealer.coords.y, v.dealer.coords.z, 0, 0, 1)
        SetEntityHeading(dealer, v.dealer.heading)

        TaskPlayAnim(dealer, "anim_casino_b@amb@casino@games@shared@dealer@", "idle", 1000.0, -2.0, -1, 2, 1148846080, 0)
        PlayFacialAnim(dealer, "idle_facial", "anim_casino_b@amb@casino@games@shared@dealer@")
        RemoveAnimDict("anim_casino_b@amb@casino@games@shared@dealer@")

        _BJdealerPeds[k] = dealer
    end

    for k, v in pairs(_blackjackTables) do
        local serverData = _blackjackTablesConfig[k]

        local table = GetClosestObjectOfType(v.table.coords.x, v.table.coords.y, v.table.coords.z, 1.0, v.table.prop, 0,
            0, 0)
        while table == 0 do
            Wait(250)
            table = GetClosestObjectOfType(v.table.coords.x, v.table.coords.y, v.table.coords.z, 1.0, v.table.prop, 0, 0,
                0)
        end

        if GetObjectTextureVariation(table) ~= serverData.tableVariation then
            SetObjectTextureVariant(table, serverData.tableVariation)
        end
    end
end)

function CanJoinBlackjackTable(table)
    local bj = GlobalState[string.format("Casino:Blackjack:%s", table)]
    if bj?.Seats then
        for k, v in pairs(bj.Seats) do
            if not v then
                return true
            end
        end
    end
    return false
end

AddEventHandler("Casino:Client:JoinBlackjack", function(_, data)
    local tableId = blackjack_func_368(_BJclosestChair)

    if tableId == data.table then
        exports["sandbox-base"]:ServerCallback("Casino:JoinBlackjack", _BJclosestChair, function(success, table, chair)
            if success then
                _inSittingDownAnimation = true

                _BJsatAtTable = table
                _BJsatAtLocalChair = chair

                LocalPlayer.state.playingCasino = true

                exports['sandbox-animations']:EmotesForceCancel()
                TriggerEvent('ox_inventory:disarm', LocalPlayer.state.ped, true)
                if _blackJackStatebagHandler then
                    RemoveStateBagChangeHandler(_blackJackStatebagHandler)
                    _blackJackStatebagHandler = nil
                end

                goToBlackjackSeat(_BJclosestChair)

                _inSittingDownAnimation = false

                CreateThread(function()
                    while _BJsatAtTable do
                        if shouldForceIdleCardGames then
                            TaskPlayAnim(LocalPlayer.state.ped, "anim_casino_b@amb@casino@games@shared@player@",
                                "idle_cardgames", 1.0, 1.0, -1, 0)
                        end
                        Wait(5)
                    end

                    if _blackJackStatebagHandler then
                        RemoveStateBagChangeHandler(_blackJackStatebagHandler)
                        _blackJackStatebagHandler = nil
                    end

                    exports['sandbox-hud']:InfoOverlayClose()

                    LocalPlayer.state.playingCasino = false
                end)
            else
                if table == "vip" then
                    exports["sandbox-hud"]:Notification("error", "You're Not a VIP Loser")
                else
                    exports["sandbox-hud"]:Notification("error", "Someone Is Sat There")
                end
            end
        end)
    end
end)

AddEventHandler("Casino:Client:StartBlackjack", function(_, data)
    if _BJsatAtTable and data?.table == _BJsatAtTable then
        exports["sandbox-base"]:ServerCallback("Casino:StartBlackjack", {}, function(success)
            if success then

            end
        end)
    end
end)

AddEventHandler("Casino:Client:LeaveBlackjack", function(_, data)
    if _BJsatAtTable and data?.table == _BJsatAtTable then
        exports["sandbox-base"]:ServerCallback("Casino:LeaveBlackjack", {}, function(success)
            if success then
                _BJsatAtTable = false
                _BJsatAtLocalChair = false
                leaveBlackjackSeat()
                exports['sandbox-hud']:InfoOverlayClose()

                LocalPlayer.state.playingCasino = false
            end
        end)
    end
end)

RegisterNetEvent("Casino:Client:BlackjackConfirmBet", function(betAmounts, tableId)
    local dealerPed = getDealerFromTableId(tableId)
    PlayAmbientSpeech1(dealerPed, "MINIGAME_DEALER_PLACE_CHIPS", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR", 1)

    _blackjackAwaitingResponse = true

    local betConfirmMenu = {
        main = {
            label = "Blackjack",
            items = {}
        }
    }

    for k, v in ipairs(betAmounts) do
        table.insert(betConfirmMenu.main.items, {
            label = string.format("Place $%s Bet", formatNumberToCurrency(v)),
            description = "Please confirm to join the next game!",
            event = "Casino:Client:RecievePromptData",
            data = { confirmBet = v }
        })
    end

    local res = StartListMenuPrompt(betConfirmMenu, 15000)

    _blackjackAwaitingResponse = false

    if res?.success and res?.data?.confirmBet and res.data.confirmBet >= 100 then
        exports["sandbox-base"]:ServerCallback("Casino:BetBlackjack", res.data.confirmBet, function(success, gameData)
            if success then
                DoBlackjackPlaceBetAnimation()

                ShowGameStateUI(gameData)

                _blackJackStatebagHandler = AddStateBagChangeHandler(string.format("Casino:Blackjack:%s", tableId), nil,
                    function(bagName, key, value, _unused, replicated)
                        if _insideCasino and _BJsatAtTable then
                            ShowGameStateUI(value)
                        end
                    end)
            end
        end)
    elseif res?.timeout then
        exports["sandbox-hud"]:Notification("error", "Ran Out of Time...")
        exports['sandbox-hud']:InfoOverlayClose()
    else
        exports['sandbox-hud']:InfoOverlayClose()
    end
end)

RegisterNetEvent("Casino:Client:BlackjackSyncChips", function(betAmount, chairId)
    if _insideCasino then
        betBlackjack(betAmount, chairId)
    end
end)

RegisterNetEvent("Casino:Client:BlackjackSyncChipsDoubleDown", function(betAmount, chairId)
    if _insideCasino then
        cleanUpChips(tostring(chairId) .. "chips")
        Wait(100)
        betBlackjack(betAmount, chairId)
    end
end)

RegisterNetEvent("Casino:Client:BlackjackDealInitialCard", function(tableId, chairId, cards, cardIndex, gotCurrentHand)
    if _insideCasino then
        loadAnim("anim_casino_b@amb@casino@games@blackjack@dealer")
        loadAnim("anim_casino_b@amb@casino@games@shared@dealer@")
        loadAnim("anim_casino_b@amb@casino@games@shared@player@")

        local dealerPed = getDealerFromTableId(tableId)
        local cardObj = startDealing(tableId, dealerPed, cards, chairId, cardIndex, gotCurrentHand,
            ((tableId + 1) * 4) - 1)

        if chairId < 0 then
            _BJlastDealerCard[tableId] = cardObj
        end
    end
end)

RegisterNetEvent("Casino:Client:BlackjackDealSingleCard", function(tableId, chairId, card, nextCardCount, gotCurrentHand)
    if _insideCasino then
        local dealerPed = getDealerFromTableId(tableId)
        startSingleDealing(chairId, dealerPed, card, nextCardCount, gotCurrentHand)
    end
end)

RegisterNetEvent("Casino:Client:BlackjackStandOrHit", function(tableId, chairId, nextCardCount, canDouble)
    if _insideCasino then
        local dealerPed = getDealerFromTableId(tableId)
        PlayAmbientSpeech1(dealerPed, "MINIGAME_BJACK_DEALER_ANOTHER_CARD", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR", 1)

        startStandOrHit(dealerPed, tableId, chairId)
    end
end)

RegisterNetEvent("Casino:Client:BlackjackFinishStandOrHitPhase", function(tableId, chairId)
    if _insideCasino then
        local dealerPed = getDealerFromTableId(tableId)
        local chairAnimId = getLocalChairIdFromGlobalChairId(chairId)

        local genderAnimString = ""

        TaskPlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer",
            genderAnimString .. "dealer_focus_player_0" .. chairAnimId .. "_idle_outro", 3.0, 1.0, -1, 2, 0, 0, 0, 0)
        PlayFacialAnim(dealerPed, genderAnimString .. "dealer_focus_player_0" .. chairAnimId .. "_idle_outro_facial",
            "anim_casino_b@amb@casino@games@blackjack@dealer")
    end
end)

RegisterNetEvent("Casino:Client:BlackjackBust", function(tableId, chairId)
    if _insideCasino then
        local dealerPed = getDealerFromTableId(tableId)
        PlayAmbientSpeech1(dealerPed, "MINIGAME_BJACK_DEALER_PLAYER_BUST", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR", 1)
        TaskPlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "reaction_bad", 3.0, 1.0, -1, 2, 0, 0,
            0, 0)
        if tableId == _BJsatAtTable and _BJsatAtLocalChair == chairId then
            DoBlackjackBustAnimation()
        end
    end
end)

RegisterNetEvent("Casino:Client:BlackjackFlipDealerCard", function(tableId, gotCurrentHand)
    if _insideCasino then
        local dealerPed = getDealerFromTableId(tableId)
        flipDealerCard(dealerPed, tableId, gotCurrentHand)
    end
end)

RegisterNetEvent("Casino:Client:BlackjackDealSingleDealerCard",
    function(tableId, nextCard, nextCardCount, gotCurrentHand)
        if _insideCasino then
            local dealerPed = getDealerFromTableId(tableId)
            startSingleDealerDealing(dealerPed, tableId, nextCard, nextCardCount, gotCurrentHand, -1 - tableId)
        end
    end)

RegisterNetEvent("Casino:Client:BlackjackDeclareWin", function(tableId, chairId, isDealerBust)
    if _insideCasino then
        local dealerPed = getDealerFromTableId(tableId)
        TaskPlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "reaction_good", 3.0, 1.0, -1, 2, 0, 0,
            0, 0)

        DoBlackjackWinAnimation()
    end
end)

RegisterNetEvent("Casino:Client:BlackjackDeclarePush", function(tableId, chairId)
    if _insideCasino then
        local dealerPed = getDealerFromTableId(tableId)
        TaskPlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "reaction_impartial", 3.0, 1.0, -1, 2,
            0, 0, 0, 0)

        DoBlackjackPushAnimation()
    end
end)

RegisterNetEvent("Casino:Client:BlackjackDeclareLoss", function(tableId, chairId)
    if _insideCasino then
        local dealerPed = getDealerFromTableId(tableId)
        TaskPlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "reaction_bad", 3.0, 1.0, -1, 2, 0, 0,
            0, 0)

        DoBlackjackLossAnimation()
    end
end)

RegisterNetEvent("Casino:Client:BlackjackGameFinished", function(tableId, playedSeats, isDealerBust, isDealerWinner)
    if _insideCasino then
        local dealerPed = getDealerFromTableId(tableId)

        if isDealerBust then
            PlayAmbientSpeech1(dealerPed, "MINIGAME_DEALER_BUSTS", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR", 1)
        elseif isDealerWinner then
            PlayAmbientSpeech1(dealerPed, "MINIGAME_DEALER_WINS", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR", 1)
        end

        for k, v in pairs(playedSeats) do
            cleanUpChips(v, tableId)
            cleanUpChips(tostring(v) .. "chips", tableId)

            Wait(2500)
        end

        cleanUpChips(-1 - tableId, tableId)

        local startingChair = ((tableId + 1) * 4) - 4
        for i = startingChair, startingChair + 3 do
            for k, v in pairs(_BJcardObjects) do
                if k == i then
                    for k2, v2 in pairs(v) do
                        DeleteEntity(v2)
                    end
                end
            end
        end

        if tableId == _BJsatAtTable then
            exports['sandbox-hud']:InfoOverlayClose()

            if _blackJackStatebagHandler then
                RemoveStateBagChangeHandler(_blackJackStatebagHandler)
                _blackJackStatebagHandler = nil
            end
        end
    end
end)

function CleanupBlackjack()
    for k, v in pairs(_BJdealerPeds) do
        DeletePed(v)
    end

    for k, v in pairs(_BJcardObjects) do
        for k2, v2 in pairs(v) do
            DeleteEntity(v2)
        end
    end

    if _BJsatAtTable then
        leaveBlackjackSeatForced()
    end

    _BJdealerPeds = {}
    _BJcardObjects = {}
end

AddEventHandler("Casino:Client:Exit", function()
    CleanupBlackjack()

    _blackjackAwaitingResponse = false
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        CleanupBlackjack()
    end
end)

function ShowGameStateUI(state)
    if state.Started then
        local dealerHand = CountBlackjackHand(state.DealerCards)
        local stateLabel = "Blackjack"
        local myHand = 0
        local myBalance = math.floor(_currentChips)
        local myBet = 0

        if state.Status == 1 then
            stateLabel = "Initial Dealing"
        elseif state.Status == 2 then
            stateLabel = "Hit or Stand?"
        elseif state.Status == 3 then
            stateLabel = "The Dealer's Play"
        elseif state.Status == 4 then
            stateLabel = "Game Finished"
        end

        for k, v in pairs(state.Seats) do
            if v and v.Joined and v.Source == LocalPlayer.state.ID then
                -- This is me
                myHand = CountBlackjackHand(v.Cards)
                myBet = math.floor(v.Bet)
            end
        end

        local overlay = string.format("Chip Balance: $%s<br>Current Bet: $%s<br><br>", formatNumberToCurrency(myBalance),
            formatNumberToCurrency(myBet))
        overlay = overlay .. string.format("Dealer Hand: %s<br>", dealerHand)
        overlay = overlay .. string.format("My Hand: %s", myHand)

        exports['sandbox-hud']:InfoOverlayShow(stateLabel, overlay)
    else
        exports['sandbox-hud']:InfoOverlayShow("Game Pending Start", "Waiting for all players to confirm their bets.")
    end
end

function CountBlackjackHand(cards)
    local hand = 0
    local numberOfAces = 0

    for k, v in pairs(cards) do
        local nextCard = getCardNumberFromCardId(v)
        if nextCard == 11 then
            numberOfAces = numberOfAces + 1
        else
            hand = hand + nextCard
        end
    end

    for i = 1, numberOfAces do
        if i == 1 then
            if hand + 11 > 21 then
                nextCard = 1
            else
                nextCard = 11
            end
        else
            nextCard = 1
        end
        hand = hand + nextCard
    end
    return hand
end

function getCardNumberFromCardId(cardId)
    if cardId == 1 then
        return 11
    elseif cardId == 2 then
        return 2
    elseif cardId == 3 then
        return 3
    elseif cardId == 4 then
        return 4
    elseif cardId == 5 then
        return 5
    elseif cardId == 6 then
        return 6
    elseif cardId == 7 then
        return 7
    elseif cardId == 8 then
        return 8
    elseif cardId == 9 then
        return 9
    elseif cardId == 10 then
        return 10
    elseif cardId == 11 then
        return 10
    elseif cardId == 12 then
        return 10
    elseif cardId == 13 then
        return 10
    elseif cardId == 14 then
        return 11
    elseif cardId == 15 then
        return 2
    elseif cardId == 16 then
        return 3
    elseif cardId == 17 then
        return 4
    elseif cardId == 18 then
        return 5
    elseif cardId == 19 then
        return 6
    elseif cardId == 20 then
        return 7
    elseif cardId == 21 then
        return 8
    elseif cardId == 22 then
        return 9
    elseif cardId == 23 then
        return 10
    elseif cardId == 24 then
        return 10
    elseif cardId == 25 then
        return 10
    elseif cardId == 26 then
        return 10
    elseif cardId == 27 then
        return 11
    elseif cardId == 28 then
        return 2
    elseif cardId == 29 then
        return 3
    elseif cardId == 30 then
        return 4
    elseif cardId == 31 then
        return 5
    elseif cardId == 32 then
        return 6
    elseif cardId == 33 then
        return 7
    elseif cardId == 34 then
        return 8
    elseif cardId == 35 then
        return 9
    elseif cardId == 36 then
        return 10
    elseif cardId == 37 then
        return 10
    elseif cardId == 38 then
        return 10
    elseif cardId == 39 then
        return 10
    elseif cardId == 40 then
        return 11
    elseif cardId == 41 then
        return 2
    elseif cardId == 42 then
        return 3
    elseif cardId == 43 then
        return 4
    elseif cardId == 44 then
        return 5
    elseif cardId == 45 then
        return 6
    elseif cardId == 46 then
        return 7
    elseif cardId == 47 then
        return 8
    elseif cardId == 48 then
        return 9
    elseif cardId == 49 then
        return 10
    elseif cardId == 50 then
        return 10
    elseif cardId == 51 then
        return 10
    elseif cardId == 52 then
        return 10
    end
end

_rouletteDealerPeds = {}
_BJcardObjects = {}

_BJclosestChair = -1

_rouletteAtTable = false
_BJsatAtLocalChair = false
_BJlastDealerCard = {}

_rouletteTablesConfig = nil

local _inSittingDownAnimation = false
local _blackjackAwaitingResponse = false

local _rouletteStatebagHandler

_rouletteTableData = {}

_rouletteAtTable = nil
_rouletteAtLocalChair = nil
_rouletteForceIdle = true

_rouletteHasChipsPlaced = false

AddEventHandler("Casino:Client:Startup", function()
    _rouletteTablesConfig = GlobalState["Casino:RouletteConfig"]

    CreateModelSwap(1022.197, 60.580, 69.865, 2.0, `vw_prop_casino_blckjack_01b`, `vw_prop_casino_roulette_01b`, 0)
    CreateModelSwap(1029.776, 62.375, 69.865, 2.0, `vw_prop_casino_blckjack_01b`, `vw_prop_casino_roulette_01b`, 0)

    for k, v in pairs(_rouletteTables) do
        local maxBet = formatNumberToCurrency(math.floor(_rouletteTablesConfig[k].maxBet))
        exports.ox_target:addBoxZone({
            id = "casino-roulette-" .. k,
            coords = v.polyzone.center,
            size = vector3(v.polyzone.length, v.polyzone.width, 2.0),
            rotation = v.polyzone.options.heading or 0,
            debug = false,
            minZ = v.polyzone.options.minZ,
            maxZ = v.polyzone.options.maxZ,
            options = {
                {
                    icon = "cards",
                    label = _rouletteTablesConfig[k].isVIP and string.format("Join VIP Game ($%s Max Bet)", maxBet) or
                        string.format("Join Game ($%s Max Bet)", maxBet),
                    onSelect = function()
                        TriggerEvent("Casino:Client:JoinRoulette", { table = k })
                    end,
                    canInteract = function()
                        return CanJoinRouletteTable(k) and not _rouletteAtTable and GlobalState["CasinoOpen"]
                    end,
                },
                {
                    icon = "cards",
                    label = "Game Full",
                    canInteract = function()
                        return not CanJoinRouletteTable(k) and not _rouletteAtTable
                    end,
                },
                {
                    icon = "cards",
                    label = "Leave Game",
                    onSelect = function()
                        TriggerEvent("Casino:Client:LeaveRoulette", { table = k })
                    end,
                    canInteract = function()
                        return _rouletteAtTable and not GlobalState[string.format("Casino:Roulette:%s", k)]?.Started and
                            not _rouletteHasChipsPlaced
                    end,
                },
            }
        })
    end

    exports["sandbox-keybinds"]:Add("casino_camera", "C", "keyboard", "Casino - Change Roulette Camera", function()
        if _rouletteAtTable then
            RouletteChangeCameraMode(_rouletteAtTable)
        end
    end)
end)

RegisterNetEvent('Characters:Client:Logout')
AddEventHandler('Characters:Client:Logout', function()
    if _rouletteAtTable then
        _rouletteAtTable = false
        _BJsatAtLocalChair = false
        leaveBlackjackSeatForced()
    end
end)

AddEventHandler("Casino:Client:Enter", function()
    loadAnim("anim_casino_b@amb@casino@games@roulette@dealer")

    while not _rouletteTablesConfig do
        Wait(100)
    end

    Wait(500)

    for k, v in pairs(_rouletteTables) do
        local serverData = _rouletteTablesConfig[k]

        local pedCoords = GetObjectOffsetFromCoords(v.table.coords.x, v.table.coords.y, v.table.coords.z, v.table
            .heading, 0.0, 0.7, 1.0)
        local dealer = CreatePed(26, serverData.dealerVariation >= 8 and `s_f_y_casino_01` or `s_m_y_casino_01`,
            pedCoords, v.table.heading + 180.0, false, true)
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

        SetEntityCoordsNoOffset(dealer, pedCoords, 0, 0, 1)
        SetEntityHeading(dealer, v.table.heading + 180.0)

        TaskPlayAnim(dealer, "anim_casino_b@amb@casino@games@shared@dealer@", "idle", 1000.0, -2.0, -1, 2, 1148846080, 0)
        PlayFacialAnim(dealer, "idle_facial", "anim_casino_b@amb@casino@games@shared@dealer@")
        RemoveAnimDict("anim_casino_b@amb@casino@games@shared@dealer@")

        _rouletteDealerPeds[k] = dealer
    end

    for k, v in pairs(_rouletteTables) do
        local serverData = _rouletteTablesConfig[k]

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

        _rouletteTableData[k] = {
            id = k,
            coords = v.table.coords,
            heading = v.table.heading,
            object = table,
            hoverObjects = {},
            betObjects = {},
            ballObject = nil,
        }

        RoulettePopulateTableData(k)
    end
end)

function CanJoinRouletteTable(table)
    local bj = GlobalState[string.format("Casino:Roulette:%s", table)]
    if bj?.Seats then
        for k, v in pairs(bj.Seats) do
            if not v then
                return true
            end
        end
    end
    return false
end

AddEventHandler("Casino:Client:JoinRoulette", function(_, data)
    local chairData = GetClosestRouletteChair(data.table)

    if chairData then
        exports["sandbox-base"]:ServerCallback("Casino:JoinRoulette", { table = data.table, chair = chairData.chairId },
            function(success, table, chair)
                if success then
                    _inSittingDownAnimation = true

                    _rouletteAtTable = table
                    _rouletteAtLocalChair = chair

                    LocalPlayer.state.playingCasino = true

                    exports['sandbox-animations']:EmotesForceCancel()
                    TriggerEvent('ox_inventory:disarm', LocalPlayer.state.ped, true)

                    if _rouletteStatebagHandler then
                        RemoveStateBagChangeHandler(_rouletteStatebagHandler)
                        _rouletteStatebagHandler = nil
                    end

                    _rouletteStatebagHandler = AddStateBagChangeHandler(string.format("Casino:Blackjack:%s", tableId),
                        nil, function(bagName, key, value, _unused, replicated)
                            if _insideCasino and _rouletteAtTable then
                                ShowRouletteGameStateUI(value)
                            end
                        end)

                    RouletteSitDownAnim(chairData)

                    _rouletteForceIdle = true

                    RouletteEnableCamera(_rouletteAtTable, true)

                    if _rouletteTableData[_rouletteAtTable].startTime then
                        RouletteBetRenderState(_rouletteAtTable, true)
                        RouletteHoverNumbers(_rouletteAtTable, {})

                        ShowRouletteGameStateUI(GlobalState[string.format("Casino:Roulette:%s", _rouletteAtTable)])
                    end

                    CreateThread(function()
                        while _rouletteAtTable do
                            if _rouletteForceIdle then
                                TaskPlayAnim(LocalPlayer.state.ped, "anim_casino_b@amb@casino@games@shared@player@",
                                    "idle_cardgames", 1.0, 1.0, -1, 0)
                            end
                            Wait(5)
                        end

                        if _rouletteStatebagHandler then
                            RemoveStateBagChangeHandler(_rouletteStatebagHandler)
                            _rouletteStatebagHandler = nil
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
    else
        exports["sandbox-hud"]:Notification("error", "Too Far From Chair")
    end
end)

function LeaveRoulette(skipAnim)
    exports["sandbox-base"]:ServerCallback("Casino:LeaveRoulette", {}, function(success)
        if success then
            if not skipAnim then
                RouletteStandUpAnim(_rouletteAtLocalChair)
            end

            RouletteEnableCamera(_rouletteAtTable, false)
            RouletteBetRenderState(_rouletteAtTable, false)
            RouletteHoverNumbers(_rouletteAtTable, {})

            _rouletteAtTable = false
            _rouletteAtLocalChair = false
            exports['sandbox-hud']:InfoOverlayClose()

            if not skipAnim then
                Wait(3000)
            end

            NetworkStopSynchronisedScene(ROULETTE_SITTING_SCENE)
            ClearPedTasksImmediately(LocalPlayer.state.ped)

            LocalPlayer.state.playingCasino = false
        end
    end)
end

AddEventHandler("Casino:Client:LeaveRoulette", function(_, data)
    if _rouletteAtTable and data?.table == _rouletteAtTable then
        LeaveRoulette(false)
    end
end)

RegisterNetEvent("Casino:Client:RouletteGameStarting", function(tableId)
    if _insideCasino then
        PlayAmbientSpeech1(_rouletteDealerPeds[tableId], "MINIGAME_DEALER_PLACE_CHIPS",
            "SPEECH_PARAMS_FORCE_NORMAL_CLEAR", 1)
        _rouletteTableData[tableId].startTime = GetGameTimer() + 28000

        if tableId == _rouletteAtTable then
            RouletteBetRenderState(tableId, true)
            RouletteHoverNumbers(tableId, {})
            _rouletteHasChipsPlaced = false

            CreateThread(function()
                while _insideCasino and _rouletteAtTable do
                    if _rouletteTableData[_rouletteAtTable] and _rouletteTableData[_rouletteAtTable].startTime then
                        ShowRouletteGameStateUI(GlobalState[string.format("Casino:Roulette:%s", _rouletteAtTable)])
                    else
                        Wait(500)
                        ShowRouletteGameStateUI(GlobalState[string.format("Casino:Roulette:%s", _rouletteAtTable)])
                        break
                    end
                    Wait(1000)
                end
            end)
        end
    end
end)

RegisterNetEvent("Casino:Client:RouletteGameSpinning", function(tableId, spinIndex, win)
    if _insideCasino then
        _rouletteTableData[tableId].startTime = false

        if _rouletteAtTable == tableId then
            RouletteBetRenderState(tableId, false)
            RouletteHoverNumbers(tableId, {})
        end

        RouletteSpin(tableId, spinIndex, win)
    end
end)

RegisterNetEvent("Casino:Client:RouletteUpdateBets", function(tableId, bets)
    if _insideCasino then
        RouletteCreateBetObjects(tableId, bets)
    end
end)

RegisterNetEvent("Casino:Client:RouletteResultAnim", function(bettedAmount, wonAmount)
    if bettedAmount > wonAmount then
        DoRouletteLossAnimation()
    elseif bettedAmount == wonAmount then
        DoRoulettePushAnimation()
    elseif bettedAmount < wonAmount then
        DoRouletteWinAnimation()
    end
end)

function RoulettePlaceChips(betType)
    print("Click", betType)
    local betAmount = GetRouletteBetAmount()

    if betAmount == "leave" then
        LeaveRoulette(false)
        return
    end

    if betAmount then
        exports["sandbox-base"]:ServerCallback("Casino:BetRoulette", {
            amount = betAmount,
            betId = betType,
        }, function(success)
            if success then
                _rouletteHasChipsPlaced = true
                DoRouletteBetAnimation()
            end
        end)
    end
end

function GetRouletteBetAmount()
    local betConfirmMenu = {
        main = {
            label = "Roulette",
            items = {}
        }
    }

    if not _rouletteHasChipsPlaced then
        table.insert(betConfirmMenu.main.items, {
            label = "Leave Roulette",
            event = "Casino:Client:RecievePromptData",
            data = { confirmBet = "leave" }
        })
    end

    local denominations = { 100, 500, 1000, 5000, 10000 }

    if GlobalState[string.format("Casino:Roulette:%s", _rouletteAtTable)]?.HighLimit then
        denominations = { 1000, 5000, 10000, 50000, 100000 }
    end

    local maxBet = math.floor(_rouletteTablesConfig[_rouletteAtTable]?.maxBet or 0)
    if (maxBet % 10000 == 0) and maxBet > denominations[#denominations] then
        table.insert(denominations, maxBet)
    end

    for k, v in ipairs(denominations) do
        table.insert(betConfirmMenu.main.items, {
            label = string.format("Place $%s", formatNumberToCurrency(v)),
            event = "Casino:Client:RecievePromptData",
            data = { confirmBet = v },
        })
    end

    local res = StartListMenuPrompt(betConfirmMenu, 15000)

    if res?.success and res?.data?.confirmBet then
        return res.data.confirmBet
    elseif res?.timeout then
        exports["sandbox-hud"]:Notification("error", "Ran Out of Time...")
    end
    return false
end

function CleanupRoulette()
    for k, v in pairs(_rouletteDealerPeds) do
        DeletePed(v)
    end

    for k, v in pairs(_rouletteTableData) do
        for k2, v2 in ipairs(v.betObjects) do
            if DoesEntityExist(v2.obj) then
                DeleteObject(v2.obj)
            end
        end

        for k2, v2 in ipairs(v.hoverObjects) do
            if DoesEntityExist(v2) then
                DeleteObject(v2)
            end
        end

        if DoesEntityExist(v.ballObject) then
            DeleteObject(v.ballObject)
        end
    end

    if _rouletteAtTable then
        shouldForceIdleCardGames = false

        NetworkStopSynchronisedScene(syncedScene)
        ClearPedTasksImmediately(LocalPlayer.state.ped)

        LeaveRoulette(true)
    end

    _rouletteDealerPeds = {}
    _BJcardObjects = {}
end

AddEventHandler("Casino:Client:Exit", function()
    CleanupRoulette()

    _blackjackAwaitingResponse = false
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        CleanupRoulette()
    end
end)

local rouletteChairs = { 'Chair_Base_01', 'Chair_Base_02', 'Chair_Base_03', 'Chair_Base_04' }
function GetClosestRouletteChair(tableId)
    local tableData = _rouletteTableData[tableId]

    local tableObj = GetRouletteTableObject(tableId)

    if tableData and DoesEntityExist(tableObj) then
        local myPos = GetEntityCoords(LocalPlayer.state.ped)
        local closest = nil
        local closestCoords = nil
        local lastDist = 1000.0
        for k, v in ipairs(rouletteChairs) do
            local chairCoords = GetWorldPositionOfEntityBone(tableObj, GetEntityBoneIndexByName(tableObj, v))
            local dist = #(myPos - chairCoords)

            if dist < lastDist then
                closest = k
                closestCoords = chairCoords
                lastDist = dist
            end
        end

        if closest and lastDist <= 1.8 then
            return {
                position = GetWorldPositionOfEntityBone(tableObj,
                    GetEntityBoneIndexByName(tableObj, rouletteChairs[closest])),
                rotation = GetWorldRotationOfEntityBone(tableObj,
                    GetEntityBoneIndexByName(tableObj, rouletteChairs[closest])),
                chairId = closest
            }
        end
    end
end

function ShowRouletteGameStateUI(state)
    if state.Started then
        exports['sandbox-hud']:InfoOverlayShow("Roulette", "The Wheel is Spinning")
    else
        local myBets = 0
        local myBalance = formatNumberToCurrency(math.floor(_currentChips))
        local maxBet = formatNumberToCurrency(math.floor(_rouletteTablesConfig[state.Id]?.maxBet or 0))
        local showStartTime = ""

        if state.Bets then
            for k, v in ipairs(state.Bets) do
                if v and v.Source == LocalPlayer.state.ID then
                    myBets += v.Amount
                end
            end
        end

        if _rouletteTableData[state.Id] and _rouletteTableData[state.Id].startTime then
            local startsIn = math.ceil((_rouletteTableData[state.Id].startTime - GetGameTimer()) / 1000)

            if startsIn < 0 then
                startsIn = 0
            end

            showStartTime = string.format(" - Starts In %s Seconds", startsIn)
        end

        exports['sandbox-hud']:InfoOverlayShow(string.format("Roulette%s", showStartTime),
            string.format("My Balance: $%s<br><br>Placed Bets: $%s<br>Table Limit: $%s", myBalance,
                formatNumberToCurrency(math.floor(myBets)), maxBet))
    end
end

local isBowling = false
local awaitingBowl = false
local pressedBowl = false

local insideBowlingStart = false
-- CreateThread(function()
--     local center = vector3(728.477, -771.375, 25.446)
--     local points = GetBowlingPinLayout(center)

--     while true do
--         for k, v in ipairs(points) do
--             DrawSphere(v, 0.05, 255, 0, 0, 100)
--         end
--         Wait(5)
--     end
-- end)

-- function DrawSphere(pos, radius, r, g, b, a)
--     DrawMarker(28, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius, radius, radius, r, g, b, a, false, false, 2, nil, nil, false)
-- end

AddEventHandler('Businesses:Client:Startup', function()
    exports['sandbox-polyzone']:CreateBox(
        'bowling_alley',
        _bowlingZone.center,
        _bowlingZone.length,
        _bowlingZone.width,
        _bowlingZone.options,
        {}
    )

    for k, v in pairs(_bowlingAlleys) do
        if v.startZone then
            exports['sandbox-polyzone']:CreateBox(
                'bowling_alley_start_' .. k,
                v.startZone.center,
                v.startZone.length,
                v.startZone.width,
                v.startZone.options,
                {
                    bowling_start = true,
                    bowling_start_id = k
                }
            )
        end

        if v.interactZone then
            exports.ox_target:addBoxZone({
                id = string.format("bowling-lane-%s", k),
                coords = v.interactZone.center,
                size = vector3(v.interactZone.length, v.interactZone.width, 2.0),
                rotation = v.interactZone.options.heading or 0,
                debug = false,
                minZ = v.interactZone.options.minZ,
                maxZ = v.interactZone.options.maxZ,
                options = {
                    {
                        icon = "bowling-ball-pin",
                        label = "Start Game",
                        event = "Bowling:Client:StartGame",
                        canInteract = function()
                            local alley = GlobalState[string.format('Bowling:Alley:%s', k)]
                            return not alley?.active
                        end,
                    },
                    {
                        icon = "bowling-ball-pin",
                        label = "Join Game",
                        event = "Bowling:Client:JoinGame",
                        canInteract = function()
                            local alley = GlobalState[string.format('Bowling:Alley:%s', k)]
                            return alley?.active and #alley.players < 5 and
                                not IsPlayerInBowlingAlley(alley.players, LocalPlayer.state.Character:GetData('SID'))
                        end,
                    },
                    {
                        icon = "bowling-ball-pin",
                        label = "End Game",
                        event = "Bowling:Client:EndGame",
                        canInteract = function()
                            local alley = GlobalState[string.format('Bowling:Alley:%s', k)]
                            return alley?.active and
                                ((IsPlayerInBowlingAlley(alley.players, LocalPlayer.state.Character:GetData('SID')) and alley.finished) or LocalPlayer.state.onDuty == 'bowling')
                        end,
                    },
                }
            })
        end
    end

    exports["sandbox-kbs"]:Add('bowling_aim_right', 'RIGHT', 'keyboard', 'Bowling - Aim Right', function()
        if awaitingBowl then
            local heading = GetEntityHeading(LocalPlayer.state.ped) - 0.7
            if heading >= 50.0 then
                SetEntityHeading(LocalPlayer.state.ped, heading)
            end
        end
    end)

    exports["sandbox-kbs"]:Add('bowling_aim_left', 'LEFT', 'keyboard', 'Bowling - Aim Left', function()
        if awaitingBowl then
            local heading = GetEntityHeading(LocalPlayer.state.ped) + 0.7
            if heading <= 130.0 then
                SetEntityHeading(LocalPlayer.state.ped, heading)
            end
        end
    end)

    exports["sandbox-base"]:RegisterClientCallback('Bowling:DoBowl', function(data, cb)
        local bowlingResults = StartBowlingShit(data)
        cb(bowlingResults)
    end)
end)

AddEventHandler('Keybinds:Client:KeyUp:primary_action', function()
    if awaitingBowl and not pressedBowl then
        pressedBowl = true
    end
end)

function CreateBowlingPins(center, skip)
    local createdPins = {}
    local pinSet = GetBowlingPinLayout(center)

    for k, v in ipairs(pinSet) do
        if not skip or not skip[k] then
            local pin = LoadAndCreateObject('prop_bowling_pin', v)
            local entRotation = GetEntityRotation(v)
            table.insert(createdPins, pin)
        end
    end

    return createdPins
end

function SendBowlingNotification(text, time)
    exports["sandbox-hud"]:NotifCustom(text, time or 5000, 'bowling-ball-pin', {
        alert = {
            background = "#C05097",
        },
        progress = {
            background = "#ffffff",
        },
    })
end

function BowlingBlockers()
    CreateThread(function()
        while isBowling do
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            Wait(0)
        end
    end)
end

function SkillCheckBowler()
    local p = promise.new()
    exports['sandbox-games']:MinigamePlayRoundSkillbar(1.0, 5, {
        onSuccess = function()
            p:resolve(true)
        end,
        onFail = function()
            p:resolve(false)
        end,
    }, {
        animation = false,
    })

    return Citizen.Await(p)
end

function StartBowlingShit(alleyId, isSecondTry, currentPinsDown, currentHitPins)
    isBowling = true
    awaitingBowl = true

    local alleyData = _bowlingAlleys[alleyId]

    BowlingBlockers()

    if isSecondTry then
        SendBowlingNotification('Second Try...')
    end

    local pins = CreateBowlingPins(alleyData.pins, currentHitPins)

    local ball = LoadAndCreateObject('prop_bowling_ball', GetEntityCoords(LocalPlayer.state.ped))
    AttachEntityToEntity(ball, LocalPlayer.state.ped, GetPedBoneIndex(LocalPlayer.state.ped, 57005), 0.19, -0.01, 0.00,
        -99.0, -463.0, 0.0, true, true, false, true, 1, true)

    LoadDict('weapons@projectile@')
    if not IsEntityPlayingAnim(LocalPlayer.state.ped, 'weapons@projectile@', 'aimlive_l', 3) then
        TaskPlayAnim(LocalPlayer.state.ped, 'weapons@projectile@', 'aimlive_l', 8.0, -8.0, -1, 17, 0, false, false, false)
    end

    Wait(1000)

    pressedBowl = false
    exports['sandbox-hud']:ActionShow('bowling',
        '{keybind}bowling_aim_left{/keybind} Aim Left | {keybind}bowling_aim_right{/keybind} Aim Right | {keybind}primary_action{/keybind} Bowl')

    local tm = 0
    while tm < 7500 and not pressedBowl do
        Wait(10)
        tm += 10
    end

    exports['sandbox-hud']:ActionHide('bowling')
    awaitingBowl = false

    local skillCheck = SkillCheckBowler()

    TaskPlayAnim(LocalPlayer.state.ped, 'weapons@projectile@', 'throw_l_fb_stand', 8.0, -8.0, -1, 17, 0.8, false, false,
        false)
    local force = 2.0
    if skillCheck then
        force = math.random(50, 80) + 0.0
        SendBowlingNotification('Power Ball!')
    else
        local weakThrow = math.random(100) <= 50
        if weakThrow then
            force = math.random(2, 4) + 0.0
        else
            force = math.random(9, 20) + 0.0
        end
    end

    Wait(150)
    DetachEntity(ball)

    SetEntityHeading(ball, GetEntityHeading(LocalPlayer.state.ped))
    SetEntityVelocity(ball, GetEntityForwardX(ball) * (20 + (force / 10)), GetEntityForwardY(ball) * (20 + (force / 10)),
        0.0)
    ClearPedTasks(LocalPlayer.state.ped)

    local pinsPitch = true
    local pinsTarget = false
    SetTimeout(4000, function()
        pinsPitch = false
    end)

    while pinsPitch do
        if #(GetEntityCoords(ball) - alleyData.endZone) <= 1.5 then
            CreateThread(function()
                Wait(750)
                for k, v in ipairs(pins) do
                    local entRotation = GetEntityRotation(v)
                    if not (entRotation.x <= 10.0 and entRotation.x >= -10.0 and entRotation.y <= 10.0 and entRotation.y >= -10.0 and entRotation.z <= 10.0 and entRotation.z >= -10.0) then
                        exports["sandbox-sounds"]:PlayLocation(alleyData.endZone, 20.0, "bowling.ogg", 0.3)
                        break
                    end
                end
            end)
            Wait(2500)
            pinsTarget = true
        end
        Wait(100)
    end

    print('Delete Bowling Ball')
    DeleteEntity(ball)

    local hitPins = {}
    local pinsDown = 0

    if pinsTarget then
        for k, v in ipairs(pins) do
            local entRotation = GetEntityRotation(v)
            if not (entRotation.x <= 10.0 and entRotation.x >= -10.0 and entRotation.y <= 10.0 and entRotation.y >= -10.0 and entRotation.z <= 10.0 and entRotation.z >= -10.0) then
                pinsDown = pinsDown + 1
                hitPins[k] = true
            end
        end

        Wait(3000)
    end

    print('Hit Pins: ', pinsDown)

    Wait(2000)

    for k, v in ipairs(pins) do
        DeleteEntity(v)
    end

    if pinsDown >= 10 or isSecondTry then
        isBowling = false
    end

    if pinsDown >= 10 then -- Strike
        SendBowlingNotification('Strike!')
        return {
            first = 10,
            total = 10,
        }
    else
        if not isSecondTry then -- Hasn't Had 2nd Attempt Yet
            return StartBowlingShit(alleyId, true, pinsDown, hitPins)
        else
            return {
                first = currentPinsDown,
                second = pinsDown,
                total = currentPinsDown + pinsDown,
            }
        end
    end
end

local nickNamePromise
function GetBowlingNickName()
    nickNamePromise = promise.new()
    exports['sandbox-hud']:InputShow('Bowling', 'Name', {
        {
            id = 'name',
            type = 'text',
            options = {
                inputProps = {
                    maxLength = 100,
                },
            },
        },
    }, 'Bowling:Client:RecieveInput', {})

    return Citizen.Await(nickNamePromise)
end

AddEventHandler('Bowling:Client:RecieveInput', function(values)
    if nickNamePromise then
        nickNamePromise:resolve(values?.name)
        nickNamePromise = nil
    end
end)

AddEventHandler('Bowling:Client:StartGame', function(alleyId)
    local nickName = GetBowlingNickName()
    if nickName and string.len(nickName) >= 3 then
        exports["sandbox-base"]:ServerCallback('Bowling:StartGame', {
            alleyId = alleyId,
            nickName = nickName,
        }, function(success)
            if success then
                SendBowlingNotification('Starting a Game of Bowling')
            else
                exports["sandbox-hud"]:Notification("error", 'Couldn\'t Start Game', 5000, 'bowling-ball-pin')
            end
        end)
    else
        exports["sandbox-hud"]:Notification("error", 'Please provide a name longer than 2 letters', 5000,
            'bowling-ball-pin')
    end
end)

AddEventHandler('Bowling:Client:JoinGame', function(alleyId)
    local nickName = GetBowlingNickName()
    if nickName and string.len(nickName) >= 3 then
        exports["sandbox-base"]:ServerCallback('Bowling:JoinGame', {
            alleyId = alleyId,
            nickName = nickName,
        }, function(success)
            if success then
                SendBowlingNotification('Joined a Game of Bowling')
            else
                exports["sandbox-hud"]:Notification("error", 'Couldn\'t Join Game', 5000, 'bowling-ball-pin')
            end
        end)
    else
        exports["sandbox-hud"]:Notification("error", 'Please provide a name longer than 2 letters', 5000,
            'bowling-ball-pin')
    end
end)

AddEventHandler('Polyzone:Enter', function(id, testedPoint, insideZones, data)
    if data?.bowling_start then
        insideBowlingStart = data.bowling_start_id
        exports['sandbox-hud']:ActionShow('bowling', '{keybind}primary_action{/keybind} Start Bowling')

        LoadRequestModel('prop_bowling_ball')
        LoadRequestModel('prop_bowling_pin')
    end
end)

AddEventHandler('Polyzone:Exit', function(id, testedPoint, insideZones, data)
    if insideBowlingStart and data?.bowling_start and data.bowling_start_id == insideBowlingStart then
        insideBowlingStart = false
        exports['sandbox-hud']:ActionHide('bowling')
    end
end)

local _actionCD = false

AddEventHandler('Keybinds:Client:KeyUp:primary_action', function()
    if insideBowlingStart and not awaitingBowl then
        local alley = GlobalState[string.format('Bowling:Alley:%s', insideBowlingStart)]
        if alley and not alley.finished and alley.currentPlayer == LocalPlayer.state.Character:GetData('SID') then
            if not _actionCD then
                exports['sandbox-hud']:ActionHide('bowling')
                TriggerServerEvent('Bowling:Server:StartBowling', insideBowlingStart)
                _actionCD = true
                SetTimeout(30000, function()
                    _actionCD = false
                end)
            end
        else
            exports["sandbox-hud"]:Notification("error", 'Not Your Turn', 5000, 'bowling-ball-pin')
        end
    end
end)

AddEventHandler('Bowling:Client:EndGame', function(alleyId)
    exports["sandbox-base"]:ServerCallback('Bowling:EndGame', {
        alleyId = alleyId,
    }, function(success)
        if success then
            SendBowlingNotification('Ended a Game of Bowling')
        else
            exports["sandbox-hud"]:Notification("error", 'Couldn\'t End Game', 5000, 'bowling-ball-pin')
        end
    end)
end)

AddEventHandler('Bowling:Client:ResetAll', function()
    exports["sandbox-base"]:ServerCallback('Bowling:ResetAll', {}, function(success)
        if success then
            SendBowlingNotification('Reset All')
        else
            exports["sandbox-hud"]:Notification("error", 'Couldn\'t Reset', 5000, 'bowling-ball-pin')
        end
    end)
end)

AddEventHandler('Bowling:Client:ClearPins', function()
    exports["sandbox-base"]:ServerCallback('Bowling:ClearPins', {}, function(success)
        if success then
            SendBowlingNotification('Cleared Pins')
        else
            exports["sandbox-hud"]:Notification("error", 'Couldn\'t Clear Pins', 5000, 'bowling-ball-pin')
        end
    end)
end)

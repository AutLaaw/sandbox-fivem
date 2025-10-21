local _satInChair = nil

local SITTING_SCENE = nil
local CREATED_OBJECTS = {}

local _pauseAnim = false

local slotObjects = {}

local _spinningReels = false

local _sessionSpent = 0
local _sessionWinnings = 0

AddEventHandler("Casino:Client:Startup", function()
    for k, v in ipairs(_slotMachineObjects) do
        exports.ox_target:addModel(v, {
            {
                icon = "slot-machine",
                label = "Use Machine",
                event = "Casino:Client:UseSlotMachine",
                distance = 2.0,
                canInteract = function()
                    return not _satInChair and GlobalState["CasinoOpen"]
                end,
            },
            {
                icon = "slot-machine",
                label = "Leave Machine",
                event = "Casino:Client:LeaveSlotMachine",
                distance = 2.0,
                canInteract = function()
                    return _satInChair
                end,
            },
            {
                icon = "play",
                label = "Place $100 Bet",
                onSelect = function()
                    TriggerEvent("Casino:Client:PlaySlotMachine", { bet = 100 })
                end,
                distance = 2.0,
                canInteract = function()
                    return _satInChair and not _spinningReels and GlobalState["CasinoOpen"]
                end,
            },
            {
                icon = "play",
                label = "Place $250 Bet",
                onSelect = function()
                    TriggerEvent("Casino:Client:PlaySlotMachine", { bet = 250 })
                end,
                distance = 2.0,
                canInteract = function()
                    return _satInChair and not _spinningReels and GlobalState["CasinoOpen"]
                end,
            },
            {
                icon = "play",
                label = "Place $500 Bet",
                onSelect = function()
                    TriggerEvent("Casino:Client:PlaySlotMachine", { bet = 500 })
                end,
                distance = 2.0,
                canInteract = function()
                    return _satInChair and not _spinningReels and GlobalState["CasinoOpen"]
                end,
            },
            {
                icon = "play",
                label = "Place $1,000 Bet",
                onSelect = function()
                    TriggerEvent("Casino:Client:PlaySlotMachine", { bet = 1000 })
                end,
                distance = 2.0,
                canInteract = function()
                    return _satInChair and not _spinningReels and GlobalState["CasinoOpen"]
                end,
            },
            {
                icon = "play",
                label = "Place $2,500 Bet",
                onSelect = function()
                    TriggerEvent("Casino:Client:PlaySlotMachine", { bet = 2500 })
                end,
                distance = 2.0,
                canInteract = function()
                    return _satInChair and not _spinningReels and GlobalState["CasinoOpen"]
                end,
            },
        })
    end
end)

AddEventHandler("Casino:Client:UseSlotMachine", function()
    local tableId, tableObj = GetClosestSlotMachine()

    if tableId then
        exports["sandbox-base"]:ServerCallback("Casino:SlotMachineSit", tableId, function(success)
            if success then
                _satInChair = GetChairObjFromTable(tableId, tableObj)
                _sessionSpent = 0
                _sessionWinnings = 0

                LocalPlayer.state.playingCasino = true

                exports['sandbox-animations']:EmotesForceCancel()
                TriggerEvent('ox_inventory:disarm', LocalPlayer.state.ped, true)

                loadAnim("anim_casino_b@amb@casino@games@shared@player@")

                SITTING_SCENE = NetworkCreateSynchronisedScene(_satInChair.position, _satInChair.rotation, 2, 1, 0,
                    1065353216, 0, 1065353216)
                local randomSit = ({ 'sit_enter_left', 'sit_enter_right' })[math.random(1, 2)]
                NetworkAddPedToSynchronisedScene(LocalPlayer.state.ped, SITTING_SCENE,
                    "anim_casino_b@amb@casino@games@shared@player@", randomSit, 2.0, -2.0, 13, 16, 2.0, 0)
                NetworkStartSynchronisedScene(SITTING_SCENE)

                SITTING_SCENE = NetworkConvertSynchronisedSceneToSynchronizedScene(SITTING_SCENE)

                repeat Wait(0) until GetSynchronizedScenePhase(SITTING_SCENE) >= 0.99 or HasAnimEventFired(LocalPlayer.state.ped, 2038294702) or HasAnimEventFired(LocalPlayer.state.ped, -1424880317)

                Wait(300)
                loadAnim("anim_casino_a@amb@casino@games@slots@male")
                FreezeEntityPosition(LocalPlayer.state.ped, true)
                TaskPlayAnim(LocalPlayer.state.ped, "anim_casino_a@amb@casino@games@slots@male", "betidle_idle_a", 2.0,
                    1.0, -1, 0)
                local fuck = GetOffsetFromEntityInWorldCoords(tableObj, 0.0, -0.85, 0.0)
                SetEntityCoords(LocalPlayer.state.ped, fuck.x, fuck.y, _satInChair.position.z - 0.34)

                TaskPlayAnim(LocalPlayer.state.ped, "anim_casino_a@amb@casino@games@slots@male", "betidle_idle_a", 2.0,
                    1.0, -1, 0)

                CreateThread(function()
                    PlaySlotMachineSound("welcome_stinger")
                end)

                ShowSlotStateUI()

                CreateThread(function()
                    while _satInChair do
                        if not _pauseAnim then
                            TaskPlayAnim(LocalPlayer.state.ped, "anim_casino_a@amb@casino@games@slots@male",
                                "betidle_idle_a", 1.0, 1.0, -1, 0)
                        end
                        Wait(5)
                    end
                end)

                SetupSlotMachine()
            else
                exports["sandbox-hud"]:Notification("error", "Seat Taken")
            end
        end)
    else
        exports["sandbox-hud"]:Notification("error", "Not Close Enough to Machine")
    end
end)

function SetupSlotMachine()
    if _satInChair then
        CleanupSlots()

        local tableData = _slotMachines[_satInChair.tableId]
        local tableRotation = GetEntityHeading(_satInChair.tableObj)

        local rot = vector3(0.0, 0.0, tableRotation + 0.0)
        local Offset = GetObjectOffsetFromCoords(_satInChair.tableCoords, GetEntityHeading(_satInChair.tableObj), 0.0,
            -0.5, 0.6)
        local CamOffset = GetObjectOffsetFromCoords(_satInChair.tableCoords, GetEntityHeading(_satInChair.tableObj), 0.0,
            -0.5, 0.6)

        loadModel(tableData.prop1)

        local offset = GetOffsetFromEntityInWorldCoords(_satInChair.tableObj, 0.003, 0.050, 1.1)
        local reel1 = CreateObjectNoOffset(tableData.prop1, offset.x, offset.y, offset.z, false, false, false)

        offset = GetOffsetFromEntityInWorldCoords(_satInChair.tableObj, 0.003 + 0.124, 0.050, 1.1)
        local reel2 = CreateObjectNoOffset(tableData.prop1, offset.x, offset.y, offset.z, false, false)

        offset = GetOffsetFromEntityInWorldCoords(_satInChair.tableObj, 0.003 - 0.12, 0.050, 1.1)
        local reel3 = CreateObjectNoOffset(tableData.prop1, offset.x, offset.y, offset.z, false, false)

        table.insert(slotObjects, { obj = reel3, rot = 90.0 })
        table.insert(slotObjects, { obj = reel1, rot = 0 })
        table.insert(slotObjects, { obj = reel2, rot = 270.0 })

        for k, v in ipairs(slotObjects) do
            SetEntityHeading(v.obj, tableRotation)
            SetEntityCollision(v.obj, false)
            FreezeEntityPosition(v.obj, true)
        end

        UpdateReelRotations()

        StartSpinThread()
    end
end

AddEventHandler("Casino:Client:PlaySlotMachine", function(_, data)
    if _satInChair then
        _pauseAnim = true

        TaskPlayAnim(LocalPlayer.state.ped, "anim_casino_a@amb@casino@games@slots@male", "betidle_press_betmax_a", 3.0,
            11.0, -1, 48, 0, false, false, false)
        Wait(500)
        TaskPlayAnim(LocalPlayer.state.ped, "anim_casino_a@amb@casino@games@slots@male", "pull_spin_a", 3.0, 11.0, -1, 48,
            0, false, false, false)
        PlayEntityAnim(_satInChair.tableObj, "pull_spin_a_slotmachine", "anim_casino_a@amb@casino@games@slots@male",
            1000.0, false, true, true, 0, 136704)

        Wait(1000)

        exports["sandbox-base"]:ServerCallback("Casino:SlotMachinePlay", data,
            function(success, reelRotations, timeOut, sound, wonAmount)
                if success then
                    _sessionSpent += data.bet
                    ShowSlotStateUI()

                    CreateThread(function()
                        PlaySlotMachineSound("spinning")
                    end)

                    _spinningReels = true
                    Wait(timeOut)
                    _spinningReels = false

                    for k, v in ipairs(reelRotations) do
                        slotObjects[k].rot = GetReelRotation(v)
                    end

                    UpdateReelRotations()
                    PlaySlotMachineSound(sound)

                    if wonAmount and wonAmount > 0 then
                        _sessionWinnings += wonAmount
                        ShowSlotStateUI()
                    end
                else

                end
            end)

        Wait(1500)
        _pauseAnim = false
    end
end)

function StartSpinThread()
    CreateThread(function()
        while _satInChair do
            if _spinningReels then
                for k, v in ipairs(slotObjects) do
                    if v.rot >= 360.0 then
                        v.rot = 0.0
                    end

                    v.rot = v.rot + 11.25
                    SetEntityRotation(v.obj, v.rot, 0.0, GetEntityHeading(_satInChair.tableObj), 2, true)
                end
            else
                Wait(250)
            end
            Wait(1)
        end
    end)
end

AddEventHandler("Casino:Client:LeaveSlotMachine", function()
    if _satInChair then
        exports["sandbox-base"]:ServerCallback("Casino:SlotMachineLeave", {}, function(success)
            if success then
                exports['sandbox-hud']:InfoOverlayClose()

                LocalPlayer.state.playingCasino = false

                _pauseAnim = true
                loadAnim("anim_casino_a@amb@casino@games@slots@male")

                FreezeEntityPosition(LocalPlayer.state.ped, false)
                TaskPlayAnim(LocalPlayer.state.ped, "anim_casino_a@amb@casino@games@slots@male", "exit_left", 1.0, 1.0,
                    2500, 0)
                Wait(math.floor(GetAnimDuration("anim_casino_a@amb@casino@games@slots@male", "exit_left") * 800))

                ClearPedTasks(LocalPlayer.state.ped)

                _satInChair = false

                CleanupSlots()
            end
        end)
    end
end)

function GetClosestSlotMachine()
    local myCoords = GetEntityCoords(LocalPlayer.state.ped)
    local lastDist = 1000.0
    local closestTable = nil
    local closestTableObj = nil

    for k, v in ipairs(_slotMachines) do
        local dist = #(myCoords - v.pos)
        if dist < lastDist then
            closestTable = k
            closestTableObj = GetClosestObjectOfType(v.pos.x, v.pos.y, v.pos.z, 0.8, v.prop, 0, 0, 0)

            lastDist = dist
        end
    end

    if lastDist < 2.0 and closestTable and closestTableObj then
        return closestTable, closestTableObj
    else
        return false
    end
end

function GetChairObjFromTable(tableId, tableObj)
    return {
        tableId = tableId,
        tableObj = tableObj,
        tableModel = _slotMachines[tableId].prop,
        tableCoords = GetEntityCoords(tableObj),
        tableOffset = GetObjectOffsetFromCoords(GetEntityCoords(tableObj), GetEntityHeading(tableObj), 0.0, 0.05, 0.0),
        position = GetWorldPositionOfEntityBone(tableObj, GetEntityBoneIndexByName(tableObj, 'Chair_Base_01')),
        rotation = GetWorldRotationOfEntityBone(tableObj, GetEntityBoneIndexByName(tableObj, 'Chair_Base_01')),
        chairId = 1,
    }
end

function PlaySlotMachineSound(sound)
    if _satInChair then
        local soundRef = _slotMachineSounds[_satInChair.tableModel]
        local soundID = GetSoundId()

        PlaySoundFromEntity(soundID, sound, _satInChair.tableObj, soundRef, false, 20, 0)

        while not HasSoundFinished(soundID) do
            Wait(10)
        end

        ReleaseSoundId(soundID)
    end
end

function UpdateReelRotations()
    for k, v in ipairs(slotObjects) do
        SetEntityRotation(v.obj, v.rot, 0.0, GetEntityHeading(_satInChair.tableObj), 2, true)
    end
end

function CleanupSlots()
    for k, v in ipairs(slotObjects) do
        DeleteEntity(v.obj)
    end

    slotObjects = {}
end

AddEventHandler("Casino:Client:Exit", function()
    CleanupSlots()

    LocalPlayer.state.playingCasino = false
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        CleanupSlots()
    end
end)

function GetReelRotation(r)
    return r * 22.5 - 180 + 0.0
end

function ShowSlotStateUI()
    if _satInChair then
        local machineName = _slotMachineNames[_satInChair.tableModel]
        local myBalance = math.floor(_currentChips)

        local overlay = string.format("Chip Balance: $%s<br>Session Spent: $%s<br>Session Winnings: $%s",
            formatNumberToCurrency(myBalance), formatNumberToCurrency(math.floor(_sessionSpent)),
            formatNumberToCurrency(math.floor(_sessionWinnings)))

        exports['sandbox-hud']:InfoOverlayShow(machineName, overlay)
    end
end

local phoneModel = `v_ret_gc_phone`
local _createdPhones = {}

local function HasBizAccess(jobName)
    if not LocalPlayer.state.loggedIn then return false end

    if type(LocalPlayer.state.onDuty) == "string" then
        return LocalPlayer.state.onDuty == jobName
    end

    local jobs = LocalPlayer.state.jobs
    if type(jobs) == "table" and jobs[jobName] then
        return true
    end

    return false
end

function CreateBizPhoneObject(coords, rotation)
    RequestModel(phoneModel)
    while not HasModelLoaded(phoneModel) do
        Wait(1)
    end

    local obj = CreateObject(phoneModel, coords.x, coords.y, coords.z, false, false, false)
    SetEntityCoordsNoOffset(obj, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(obj, rotation.x, rotation.y, rotation.z, 2, true)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)

    while not DoesEntityExist(obj) do
        Wait(1)
    end

    return obj
end

function CreateBizPhones()
    while GlobalState.BizPhones == nil do
        Wait(100)
    end

    for _, v in pairs(GlobalState.BizPhones) do
        local object = CreateBizPhoneObject(v.coords, v.rotation)

        exports.ox_target:addLocalEntity(object, {
            {
                icon = "phone",
                label = "Answer Call",
                onSelect = function()
                    TriggerEvent("Phone:Client:AcceptBizCall", nil, { id = v.id })
                end,
                canInteract = function()
                    local pData = GlobalState[("BizPhone:%s"):format(v.id)]
                    return HasBizAccess(v.job) and pData and pData.state == 1
                end,
            },
            {
                icon = "phone",
                label = "Make Call",
                onSelect = function()
                    TriggerEvent("Phone:Client:MakeBizCall", nil, { id = v.id })
                end,
                canInteract = function()
                    local pData = GlobalState[("BizPhone:%s"):format(v.id)]
                    return HasBizAccess(v.job) and not pData
                end,
            },
            {
                icon = "phone-volume",
                label = "Dialing…",
                onSelect = function()
                    TriggerEvent("Phone:Client:MakeBizCall", { id = v.id })
                end,
                canInteract = function()
                    local pData = GlobalState[("BizPhone:%s"):format(v.id)]
                    return HasBizAccess(v.job) and pData and pData.state > 1 and pData.state ~= 2
                end,
            },
            {
                icon = "phone-volume",
                label = "On Call",
                onSelect = function()
                     local pData = GlobalState[("BizPhone:%s"):format(v.id)]
                    if pData then
                        exports["sandbox-hud"]:Notification("inform", ("On Call: %s"):format(pData.callingStr or "Unknown"))
                    end
                end,
                canInteract = function()
                    local pData = GlobalState[("BizPhone:%s"):format(v.id)]
                    return HasBizAccess(v.job) and pData and pData.state == 2
                end,
            },
            {
                icon = "phone",
                label = "Hang Up",
                onSelect = function()
                    TriggerEvent("Phone:Client:DeclineBizCall", nil, { id = v.id })
                end,
                canInteract = function()
                    local pData = GlobalState[("BizPhone:%s"):format(v.id)]
                    return HasBizAccess(v.job) and pData ~= nil
                end,
            },
            {
                icon = "phone-slash",
                label = "Toggle Mute",
                onSelect = function()
                    TriggerEvent("Phone:Client:MuteBiz", nil, { id = v.id })
                end,
                canInteract = function()
                    return HasBizAccess(v.job)
                end,
            },
        })

        table.insert(_createdPhones, object)
    end
end

function CleanupBizPhones()
    for _, ent in ipairs(_createdPhones) do
        if DoesEntityExist(ent) then
            exports.ox_target:removeLocalEntity(ent)
            DeleteEntity(ent)
        end
    end
    _createdPhones = {}
end

AddEventHandler("Phone:Client:MakeBizCall", function(entityData, data)
    exports['sandbox-hud']:InputShow("Phone Number", "Number to Call", {
        {
            id = "number",
            type = "text",
            options = {
                helperText = "E.g 555-555-5555",
                inputProps = {
                    pattern = "[0-9-]+",
                    minlength = 12,
                    maxlength = 12,
                },
            },
        },
    }, "Phone:Client:MakeBizCallConfirm", data)
end)

AddEventHandler("Phone:Client:MuteBiz", function(entityData, data)
    exports["sandbox-base"]:ServerCallback("Phone:MuteBiz", data.id, function(success, state)
        if success then
            if state then
                exports["sandbox-hud"]:Notification("error", "Muted Phone")
            else
                exports["sandbox-hud"]:Notification("success", "Unmuted Phone")
            end
        else
            exports["sandbox-hud"]:Notification("error", "Unable to Mute Phone")
        end
    end)
end)

AddEventHandler("Phone:Client:MakeBizCallConfirm", function(values, data)
    if values.number and data.id and GlobalState.BizPhones[data.id] then
        exports["sandbox-base"]:ServerCallback("Phone:MakeBizCall", { id = data.id, number = values.number },
            function(success)
                LocalPlayer.state.bizCall = data.id
                local startCoords = GlobalState.BizPhones[data.id].coords

                if success then
                    CreateThread(function()
                        exports['sandbox-animations']:EmotesPlay("phonecall2", true)
                        exports["sandbox-sounds"]:LoopOne("ringing.ogg", 0.1)
                        exports['sandbox-hud']:InfoOverlayShow("Dialing",
                            string.format("Dailing Number: %s", values.number))

                        while LocalPlayer.state.loggedIn and LocalPlayer.state.bizCall do
                            if #(GetEntityCoords(LocalPlayer.state.ped) - startCoords) >= 10.0 then
                                TriggerServerEvent("Phone:Server:ForceEndBizCall")
                            end
                            Wait(500)
                        end

                        exports['sandbox-animations']:EmotesForceCancel()
                        exports["sandbox-sounds"]:StopOne("ringing.ogg")
                        exports['sandbox-hud']:InfoOverlayClose()
                    end)
                else
                    exports["sandbox-hud"]:Notification("error", "Failed to Make Call")
                end
            end)
    end
end)

RegisterNetEvent("Phone:Client:AcceptBizCall", function(number)
    if LocalPlayer.state.bizCall then
        exports['sandbox-hud']:InfoOverlayShow("On Call", string.format("To Number: %s", number))
        exports["sandbox-sounds"]:StopOne("ringing.ogg")
    end
end)

RegisterNetEvent("Phone:Client:Biz:Recieve", function(id, coords, radius)
    if not LocalPlayer.state.loggedIn or GlobalState[("BizPhone:%s:Muted"):format(id)] then return end

    -- Coerce coords into vector3 (handles table or json-string coords)
    if type(coords) == 'string' then
        local ok, decoded = pcall(json.decode, coords)
        if ok and decoded then coords = decoded end
    end
    if type(coords) == 'table' then
        coords = vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    end

    radius = tonumber(radius) or 15.0

    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)

    if #(myCoords - coords) <= 150.0 then
        exports["sandbox-sounds"]:LoopLocation(("bizphones-%s"):format(id), coords, radius, "bizphone.ogg", 0.1)
        SetTimeout(30000, function()
            exports["sandbox-sounds"]:StopDistance(("bizphones-%s"):format(id), "bizphone.ogg")
        end)
    end
    print("BIZ RING coords type:", type(coords), coords)
end)

AddEventHandler("Phone:Client:DeclineBizCall", function(entityData, data)
    exports["sandbox-base"]:ServerCallback("Phone:DeclineBizCall", data.id, function(success)
        if not success then
            exports["sandbox-hud"]:Notification("error", "Failed to Decline Call")
        end
    end)
end)

AddEventHandler("Phone:Client:AcceptBizCall", function(entityData, data)
    if data.id and GlobalState.BizPhones[data.id] then
        exports["sandbox-base"]:ServerCallback("Phone:AcceptBizCall", data.id, function(success, callStr)
            local startCoords = GlobalState.BizPhones[data.id].coords
            LocalPlayer.state.bizCall = data.id

            if success then
                CreateThread(function()
                    exports['sandbox-animations']:EmotesPlay("phonecall2", true)
                    exports['sandbox-hud']:InfoOverlayShow("On Call", string.format("From Number: %s", callStr))
                    while LocalPlayer.state.loggedIn and LocalPlayer.state.bizCall do
                        if #(GetEntityCoords(LocalPlayer.state.ped) - startCoords) >= 10.0 then
                            TriggerServerEvent("Phone:Server:ForceEndBizCall")
                        end
                        Wait(500)
                    end

                    exports['sandbox-animations']:EmotesForceCancel()
                    exports['sandbox-hud']:InfoOverlayClose()
                end)
            else
                exports["sandbox-hud"]:Notification("error", "Failed to Accept Call")
            end
        end)
    end
end)

RegisterNetEvent("Phone:Client:Biz:Answered", function(id)
    exports["sandbox-sounds"]:StopDistance(string.format("bizphones-%s", id), "bizphone.ogg")
end)

RegisterNetEvent("Phone:Client:Biz:End", function(id)
    exports["sandbox-sounds"]:StopDistance(string.format("bizphones-%s", id), "bizphone.ogg")

    if LocalPlayer.state.bizCall and LocalPlayer.state.bizCall == id then
        LocalPlayer.state.bizCall = nil
        exports["sandbox-sounds"]:PlayOne("ended.ogg", 0.15)
    end
end)
if GetConvarInt('ox_target:defaults', 1) ~= 1 then return end

local api = require 'client.api'
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetVehicleDoorLockStatus = GetVehicleDoorLockStatus
local utils = require 'client.utils'

local bones = {
    [0] = 'dside_f',
    [1] = 'pside_f',
    [2] = 'dside_r',
    [3] = 'pside_r'
}

---@param vehicle number
---@param door number
local function toggleDoor(vehicle, door)
    if GetVehicleDoorLockStatus(vehicle) ~= 2 then
        if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
            SetVehicleDoorShut(vehicle, door, false)
        else
            SetVehicleDoorOpen(vehicle, door, false, false)
        end
    end
end

---@param entity number
---@param coords vector3
---@param door number
---@param useOffset boolean?
---@return boolean?
local function canInteractWithDoor(entity, coords, door, useOffset)
    if not GetIsDoorValid(entity, door) or GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, door) or cache.vehicle then return end

    if useOffset then return true end

    local boneName = bones[door]

    if not boneName then return false end

    local boneId = GetEntityBoneIndexByName(entity, 'door_' .. boneName)

    if boneId ~= -1 then
        return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5 or
            #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'seat_' .. boneName))) < 0.72
    end
end

local function onSelectDoor(data, door)
    local entity = data.entity

    if NetworkGetEntityOwner(entity) == cache.playerId then
        return toggleDoor(entity, door)
    end

    TriggerServerEvent('ox_target:toggleEntityDoor', VehToNet(entity), door)
end

RegisterNetEvent('ox_target:toggleEntityDoor', function(netId, door)
    local entity = NetToVeh(netId)
    toggleDoor(entity, door)
end)

Config = {
    BlacklistedCornering = {
        [8] = true,
        [13] = true,
        [14] = true,
        [15] = true,
        [16] = true,
        [18] = true,
        [19] = true,
        [21] = true,
    },
}

api.addGlobalVehicle({
    {
        name = 'ox_target:driverF',
        icon = 'fas fa-car-side',
        label = locale('toggle_front_driver_door'),
        bones = { 'door_dside_f', 'seat_dside_f' },
        distance = 2,
        canInteract = function(entity, distance, coords, name)
            return canInteractWithDoor(entity, coords, 0)
        end,
        onSelect = function(data)
            onSelectDoor(data, 0)
        end
    },
    {
        name = 'ox_target:passengerF',
        icon = 'fas fa-car-side',
        label = locale('toggle_front_passenger_door'),
        bones = { 'door_pside_f', 'seat_pside_f' },
        distance = 2,
        canInteract = function(entity, distance, coords, name)
            return canInteractWithDoor(entity, coords, 1)
        end,
        onSelect = function(data)
            onSelectDoor(data, 1)
        end
    },
    {
        name = 'ox_target:driverR',
        icon = 'fas fa-car-side',
        label = locale('toggle_rear_driver_door'),
        bones = { 'door_dside_r', 'seat_dside_r' },
        distance = 2,
        canInteract = function(entity, distance, coords)
            return canInteractWithDoor(entity, coords, 2)
        end,
        onSelect = function(data)
            onSelectDoor(data, 2)
        end
    },
    {
        name = 'ox_target:passengerR',
        icon = 'fas fa-car-side',
        label = locale('toggle_rear_passenger_door'),
        bones = { 'door_pside_r', 'seat_pside_r' },
        distance = 2,
        canInteract = function(entity, distance, coords)
            return canInteractWithDoor(entity, coords, 3)
        end,
        onSelect = function(data)
            onSelectDoor(data, 3)
        end
    },
    {
        name = 'ox_target:bonnet',
        icon = 'fas fa-car',
        label = locale('toggle_hood'),
        offset = vec3(0.5, 1, 0.5),
        distance = 2,
        canInteract = function(entity, distance, coords)
            return canInteractWithDoor(entity, coords, 4, true)
        end,
        onSelect = function(data)
            onSelectDoor(data, 4)
        end
    },
    {
        name = 'ox_target:trunk',
        icon = 'fas fa-car-rear',
        label = locale('toggle_trunk'),
        offset = vec3(0.5, 0, 0.5),
        distance = 2,
        canInteract = function(entity, distance, coords, name)
            return canInteractWithDoor(entity, coords, 5, true)
        end,
        onSelect = function(data)
            onSelectDoor(data, 5)
        end
    }
})

api.addGlobalPlayer({
    {
        name = "police_search",
        icon = "fas fa-magnifying-glass",
        label = "Search",
        distance = 1.5,
        groups = { "police" },
        reqDuty = true,
        onSelect = function(data)
            data.serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("Police:Client:Search", data)
        end
    },
    {
        name = "police_gsr",
        icon = "fas fa-gun",
        label = "GSR Test",
        distance = 1.5,
        groups = { "police" },
        reqDuty = true,
        onSelect = function(data)
            data.serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("Police:Client:GSR", data)
        end,
    },
    {
        name = "police_bac",
        icon = "fas fa-beer-mug-empty",
        label = "BAC Test",
        distance = 1.5,
        groups = { "police", "ems" },
        reqDuty = true,
        onSelect = function(data)
            data.serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("Police:Client:BAC", data)
        end,
    },
    {
        name = "police_dna_swab",
        icon = "fas fa-dna",
        label = "Take DNA Swab",
        distance = 1.5,
        groups = { "police", "ems" },
        reqDuty = true,
        onSelect = function(data)
            data.serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("Police:Client:DNASwab", data)
        end,
    },
    {
        name = "ems_drug_test",
        icon = "fas fa-capsules",
        label = "Perform Drug Test",
        distance = 1.5,
        groups = { "ems" },
        reqDuty = true,
        onSelect = function(data)
            data.serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("EMS:Client:DrugTest", data)
        end,
    },
    {
        name = "player_rob",
        icon = "fas fa-gun",
        label = "Rob",
        distance = 1.5,
        canInteract = function(entity, distance, coords)
            local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
            if not serverId then
                return false
            end

            local playerState = Player(serverId)
            if not playerState or not playerState.state then
                return false
            end

            local isDead = playerState.state.isDead or false
            local isCuffed = playerState.state.isCuffed or false
            local isHandsUp = IsEntityPlayingAnim(entity, "missminuteman_1ig_2", "handsup_base", 3)

            return not LocalPlayer.state.onDuty and (isDead or isCuffed or isHandsUp)
        end,
        onSelect = function(data)
            data.serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("Robbery:Client:Holdup:Do", data)
        end
    },
    {
        name = "police_cuff",
        icon = "fas fa-link",
        label = "Cuff",
        distance = 1.5,
        canInteract = function(entity, distance, coords)
            local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
            if not serverId then
                return false
            end
            local playerState = Player(serverId)
            if not playerState or not playerState.state then
                return false
            end
            local isCuffed = not playerState.state.isCuffed
            return isCuffed or false
        end,
        onSelect = function(data)
            data.serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("Handcuffs:Client:SoftCuff", data)
        end
    },
    {
        name = "police_uncuff",
        icon = "fas fa-link-slash",
        label = "Uncuff",
        distance = 1.5,
        canInteract = function(entity, distance, coords)
            local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
            if not serverId then
                return false
            end
            local playerState = Player(serverId)
            if not playerState or not playerState.state then
                return false
            end
            local isCuffed = playerState.state.isCuffed
            return isCuffed or false
        end,
        onSelect = function(data)
            data.serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("Handcuffs:Client:Uncuff", data)
        end
    },
    {
        name = "police_remove_mask",
        icon = "fas fa-masks-theater",
        label = "Remove Mask",
        event = "Police:Client:RemoveMask",
        distance = 1.5,
        groups = { "police", "ems" },
        reqDuty = true,
        canInteract = function(entity, distance, coords)
            return GetPedDrawableVariation(entity, 1) ~= -1
        end,
    },
    {
        name = "ems_evaluate",
        icon = "fas fa-suitcase-medical",
        label = "Evaluate",
        distance = 1.5,
        groups = { "ems" },
        reqDuty = true,
        onSelect = function(data)
            data.serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("EMS:Client:Evaluate", data)
        end
    },
    {
        name = "hud_remove_blindfold",
        icon = "fas fa-eye-low-vision",
        label = "Remove Blindfold",
        distance = 1.5,
        canInteract = function(entity, distance, coords)
            local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
            if not serverId then
                return false
            end
            local playerState = Player(serverId)
            if not playerState or not playerState.state then
                return false
            end
            local isBlindfolded = playerState.state.isBlindfolded
            return isBlindfolded or false
        end,
        onSelect = function(data)
            data.serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("HUD:Client:RemoveBlindfold", data)
        end
    },
})

Config.VehicleMenu = {
    {
        icon = "gas-pump",
        isEnabled = function(data, entityData)
            if exports['sandbox-fuel']:CanBeFueled(entityData.entity) then
                return true
            end
            return false
        end,
        textFunc = function(data, entityData)
            if not entityData or not entityData.entity then
                return ""
            end
            local fuelData = exports['sandbox-fuel']:CanBeFueled(entityData.entity)
            if fuelData then
                if fuelData.needsFuel then
                    return string.format("Refuel For $%d", fuelData.cost)
                else
                    return "Fuel Tank Full"
                end
            end
        end,
        event = "Vehicles:Client:StartFueling",
        data = {},
        minDist = 2.0,
    },
    {
        icon = "credit-card",
        isEnabled = function(data, entityData)
            local fuelData = exports['sandbox-fuel']:CanBeFueled(entityData.entity)
            if fuelData and fuelData.needsFuel then
                return true
            end
            return false
        end,
        textFunc = function(data, entityData)
            if not entityData or not entityData.entity then
                return ""
            end
            local fuelData = exports['sandbox-fuel']:CanBeFueled(entityData.entity)
            if fuelData then
                if fuelData.needsFuel then
                    return string.format("Refuel For $%d (Pay by Card)", fuelData.cost)
                else
                    return "Fuel Tank Full"
                end
            end
            return ""
        end,
        onSelect = function(data)
            data.bank = true
            TriggerEvent("Vehicles:Client:StartFueling", data)
        end,
        minDist = 2.0,
    },
    {
        icon = "gas-pump",
        isEnabled = function(data, entityData)
            local hasWeapon, weapon = GetCurrentPedWeapon(LocalPlayer.state.ped)
            if
                hasWeapon
                and weapon == `WEAPON_PETROLCAN`
                and GetVehicleClass(entityData.entity) ~= 13
            then
                return true
            end
            return false
        end,
        text = "Refuel With Petrol Can",
        event = "Vehicles:Client:StartJerryFueling",
        data = {},
        minDist = 2.0,
    },
    {
        icon = "warehouse",
        isEnabled = function(data, entityData)
            if exports['sandbox-vehicles']:CanBeStored(entityData.entity) then
                return true
            end
            return false
        end,
        text = "Store Vehicle",
        event = "Vehicles:Client:StoreVehicle",
        data = {},
        minDist = 4.0,
    },
    -- {
    --     icon = "truck-ramp-box",
    --     isEnabled = function(data, entityData)
    --         local vehState = Entity(entityData.entity).state
    --         return not LocalPlayer.state.isDead
    --             and vehState.VIN ~= nil
    --             and not vehState.wasThermited
    --             and GetEntityHealth(entityData.entity) > 0
    --             and utils.isNearTrunk(entityData.entity, 4.0)
    --     end,
    --     text = "View Trunk",
    --     event = "Inventory:Client:Trunk",
    --     data = {},
    --     minDist = 3.0,
    -- },
    {
        icon = "key",
        text = "Give Keys",
        isEnabled = function(data, entityData)
            local vehEnt = Entity(entityData.entity)
            return exports['sandbox-vehicles']:KeysHas(vehEnt.state.VIN, vehEnt.state.GroupKeys)
        end,
        event = "Vehicles:Client:GiveKeys",
        data = {},
        minDist = 3.0,
    },
    {
        icon = "person-seat",
        isEnabled = function(data, entityData)
            local vehState = Entity(entityData.entity).state
            return not LocalPlayer.state.isDead
                and vehState.VIN ~= nil
                and not vehState.wasThermited
                and GetEntityHealth(entityData.entity) > 0
                and utils.isNearTrunk(entityData.entity, 4.0)
                and LocalPlayer.state.isK9Ped
        end,
        text = "K9 - Get In Vehicle",
        event = "Vehicles:Client:K9GetInNearestSeat",
        data = {},
        minDist = 3.0,
    },
    {
        icon = "trash",
        isEnabled = function(data, entityData)
            return utils.isNearTrunk(entityData.entity, 4.0, true)
        end,
        text = "Toss Garbage",
        event = "Garbage:Client:TossBag",
        model = `trash2`,
        tempjob = "Garbage",
        data = {},
        minDist = 10.0,
        isEnabled = function(data, entityData)
            return LocalPlayer.state.carryingGarbabge and LocalPlayer.state.inGarbagbeZone
        end,
    },
    {
        icon = "capsules",
        text = "Handoff Contraband",
        event = "OxyRun:Client:MakeSale",
        item = "contraband",
        data = {},
        minDist = 3.0,
        isEnabled = function(data, entityData)
            return LocalPlayer.state.oxyJoiner ~= nil
                and LocalPlayer.state.oxyBuyer ~= nil
                and VehToNet(entityData.entity) == LocalPlayer.state.oxyBuyer.veh
        end,
    },
    {
        icon = "lock",
        isEnabled = function(data, entityData)
            local vehState = Entity(entityData.entity).state
            if
                vehState
                and vehState.VIN
                and not vehState.wasThermited
                and exports['sandbox-vehicles']:KeysHas(vehState.VIN)
            then
                return true
            end
            return false
        end,
        text = "Toggle Locks",
        event = "Vehicles:Client:ToggleLocks",
        data = {},
        minDist = 25.0,
    },
    {
        icon = "fas fa-bicycle",
        isEnabled = function(data, entityData)
            return GetVehicleClass(entityData.entity) == 13
        end,
        text = "Pick Up Bike",
        event = "Vehicle:Client:PickupBike",
        data = {},
        minDist = 3.0,
    },
    {
        icon = "truck",
        text = "Request Tow",
        event = "Vehicles:Client:RequestTow",
        data = {},
        minDist = 2.0,
        groups = { "police" },
        reqDuty = true,
        isEnabled = function(data, entityData)
            local vehState = Entity(entityData.entity).state
            if vehState and vehState.towObjective or (GlobalState["Duty:tow"] or 0) == 0 then
                return false
            end
            return true
        end,
    },
    {
        icon = "truck",
        text = "Request Impound",
        event = "Vehicles:Client:RequestImpound",
        data = {},
        minDist = 2.0,
        groups = { "police" },
        reqDuty = true,
        isEnabled = function(data, entityData)
            local vehState = Entity(entityData.entity).state
            if vehState and vehState.towObjective then
                return false
            end
            return true
        end,
    },
    {
        icon = "truck",
        text = "Tow - Impound",
        event = "Tow:Client:RequestImpound",
        data = {},
        minDist = 4.0,
        groups = { "police" },
        reqDuty = true,
        isEnabled = function(data, entityData)
            if entityData.entity and DoesEntityExist(entityData.entity) then
                if exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(entityData.entity), "tow_impound_zone") then
                    return true
                end
            end
            return false
        end,
    },

    {
        icon = "magnifying-glass",
        isEnabled = function(data, entityData)
            return exports['sandbox-vehicles']:HasAccess(entityData.entity)
                and exports['sandbox-vehicles']:UtilsIsCloseToFrontOfVehicle(entityData.entity)
                and (GetVehicleDoorAngleRatio(entityData.entity, 4) >= 0.1)
        end,
        text = "Inspect VIN",
        event = "Vehicles:Client:InspectVIN",
        data = {},
        minDist = 10.0,
    },
    {
        icon = "screwdriver",
        isEnabled = function(data, entityData)
            if DoesEntityExist(entityData.entity) then
                local vehState = Entity(entityData.entity).state
                if vehState.FakePlate then
                    return (
                            (exports['sandbox-vehicles']:HasAccess(entityData.entity, true))
                            or LocalPlayer.state.onDuty == "police" and LocalPlayer.state.inPdStation
                        )
                        and (
                            exports['sandbox-vehicles']:UtilsIsCloseToRearOfVehicle(entityData.entity)
                            or exports['sandbox-vehicles']:UtilsIsCloseToFrontOfVehicle(entityData.entity)
                        )
                end
            end
            return false
        end,
        text = "Remove Plate",
        event = "Vehicles:Client:RemoveFakePlate",
        data = {},
        minDist = 10.0,
    },
    {
        icon = "screwdriver",
        isEnabled = function(data, entityData)
            if DoesEntityExist(entityData.entity) then
                local vehState = Entity(entityData.entity).state
                if vehState.Harness and vehState.Harness > 0 then
                    return exports['sandbox-vehicles']:HasAccess(entityData.entity, true)
                end
            end
            return false
        end,
        text = "Remove Harness",
        event = "Vehicles:Client:RemoveHarness",
        data = {},
        minDist = 10.0,
    },
    {
        icon = "person-seat",
        text = "Seat In Vehicle",
        event = "Escort:Client:PutIn",
        data = {},
        minDist = 4.0,
        isEnabled = function(data, entity)
            if
                LocalPlayer.state.isEscorting == nil
                or LocalPlayer.state.isDead
                or GetVehicleDoorLockStatus(entity.entity) ~= 1
            then
                return false
            else
                local vehmodel = GetEntityModel(entity.entity)
                for i = -1, GetVehicleModelNumberOfSeats(vehmodel) do
                    if GetPedInVehicleSeat(entity.entity, i) == 0 then
                        return true
                    end
                end
                return false
            end
        end,
    },
    {
        icon = "person-seat",
        text = "Unseat From Vehicle",
        event = "Escort:Client:PullOut",
        data = {},
        minDist = 4.0,
        isEnabled = function(data, entity)
            if
                LocalPlayer.state.isEscorting ~= nil
                or LocalPlayer.state.isDead
                or GetVehicleDoorLockStatus(entity.entity) ~= 1
            then
                return false
            else
                local vehmodel = GetEntityModel(entity.entity)
                for i = -1, GetVehicleModelNumberOfSeats(vehmodel) do
                    local p = GetPedInVehicleSeat(entity.entity, i)
                    if p ~= 0 and IsPedAPlayer(p) then
                        return true
                    end
                end
                return false
            end
        end,
    },
    {
        icon = "child",
        text = "Put In Trunk",
        event = "Trunk:Client:PutIn",
        data = {},
        minDist = 4.0,
        isEnabled = function(data, entity)
            return LocalPlayer.state.isEscorting ~= nil
                and not LocalPlayer.state.isDead
                and not LocalPlayer.state.inTrunk
                and utils.isNearTrunk(entity.entity, 4.0, true)
        end,
    },
    {
        icon = "child",
        text = "Pull Out Of Trunk",
        event = "Trunk:Client:PullOut",
        data = {},
        minDist = 4.0,
        isEnabled = function(data, entity)
            local entState = Entity(entity.entity).state
            return LocalPlayer.state.isEscorting == nil
                and not LocalPlayer.state.isDead
                and not LocalPlayer.state.inTrunk
                and utils.isNearTrunk(entity.entity, 4.0, false)
                and entState.trunkOccupied
        end,
    },
    {
        icon = "child",
        text = "Get In Trunk",
        event = "Trunk:Client:GetIn",
        data = {},
        minDist = 4.0,
        jobs = false,
        isEnabled = function(data, entityData)
            local entState = Entity(entityData.entity).state
            return LocalPlayer.state.isEscorting == nil
                and not LocalPlayer.state.isDead
                and not LocalPlayer.state.inTrunk
                and entState.trunkOccupied == nil
                and utils.isNearTrunk(entityData.entity, 4.0, true)
        end,
    },
    -- Mechanic
    {
        icon = "toolbox",
        text = "Regular Body & Engine Repair",
        event = "Mechanic:Client:StartRegularRepair",
        data = {},
        isEnabled = function(data, entityData)
            if
                DoesEntityExist(entityData.entity)
                and (exports['sandbox-vehicles']:UtilsIsCloseToRearOfVehicle(entityData.entity) or exports['sandbox-vehicles']:UtilsIsCloseToFrontOfVehicle(
                    entityData.entity
                ))
                and exports['sandbox-mechanic']:CanAccessVehicleAsMechanic(entityData.entity)
            then
                local engineHealth = GetVehicleEngineHealth(entityData.entity)
                local bodyHealth = GetVehicleBodyHealth(entityData.entity)
                if bodyHealth < 1000 or engineHealth < 900 then
                    return true
                end
            end
            return false
        end,
        minDist = 10.0,
    },
    {
        icon = "car-wrench",
        text = "Run Diagnostics",
        event = "Mechanic:Client:RunDiagnostics",
        data = {},
        isEnabled = function(data, entityData)
            if
                DoesEntityExist(entityData.entity)
                and (exports['sandbox-vehicles']:UtilsIsCloseToRearOfVehicle(entityData.entity) or exports['sandbox-vehicles']:UtilsIsCloseToFrontOfVehicle(
                    entityData.entity
                ))
                and exports['sandbox-mechanic']:CanAccessVehicleAsMechanic(entityData.entity)
            then
                return true
            end
            return false
        end,
        minDist = 10.0,
    },
    {
        icon = "gauge-simple-max",
        text = "Run Performance Diagnostics",
        event = "Mechanic:Client:RunPerformanceDiagnostics",
        data = {},
        isEnabled = function(data, entityData)
            if
                DoesEntityExist(entityData.entity)
                and (exports['sandbox-vehicles']:UtilsIsCloseToRearOfVehicle(entityData.entity) or exports['sandbox-vehicles']:UtilsIsCloseToFrontOfVehicle(
                    entityData.entity
                ))
                and exports['sandbox-mechanic']:CanAccessVehicleAsMechanic(entityData.entity)
            then
                return true
            end
            return false
        end,
        minDist = 10.0,
    },
    {
        icon = "car",
        isEnabled = function(data, entityData)
            if DoesEntityExist(entityData.entity) and (not IsVehicleOnAllWheels(entityData.entity)) then
                return true
            end
            return false
        end,
        text = "Flip Vehicle",
        event = "Vehicles:Client:FlipVehicle",
        data = {},
        minDist = 2.0,
        jobs = false,
    },
    {
        icon = "truck",
        isEnabled = function(data, entityData)
            local veh = entityData.entity
            local vehEnt = Entity(veh)
            if DoesEntityExist(veh) and exports['sandbox-tow']:IsTowTruck(veh) and not vehEnt.state.towingVehicle then
                local rearWheel = GetEntityBoneIndexByName(veh, "wheel_lr")
                local rearWheelCoords = GetWorldPositionOfEntityBone(veh, rearWheel)
                if #(rearWheelCoords - LocalPlayer.state.myPos) <= 3.0 then
                    return true
                end
            end
            return false
        end,
        text = "Tow - Attach Vehicle",
        event = "Vehicles:Client:BeginTow",
        data = {},
        minDist = 2.0,
        jobs = false,
    },
    {
        icon = "truck",
        isEnabled = function(data, entityData)
            local veh = entityData.entity
            local vehEnt = Entity(veh)
            if DoesEntityExist(veh) and exports['sandbox-tow']:IsTowTruck(veh) and vehEnt.state.towingVehicle then
                local rearWheel = GetEntityBoneIndexByName(veh, "wheel_lr")
                local rearWheelCoords = GetWorldPositionOfEntityBone(veh, rearWheel)
                if #(rearWheelCoords - LocalPlayer.state.myPos) <= 3.0 then
                    return true
                end
            end
            return false
        end,
        text = "Tow - Detach Vehicle",
        event = "Vehicles:Client:ReleaseTow",
        data = {},
        minDist = 2.0,
        jobs = false,
    },
    {
        icon = "barcode",
        text = "Run Plate",
        event = "Police:Client:RunPlate",
        data = {},
        minDist = 3.0,
        groups = { "police" },
        reqDuty = true,
    },
    {
        icon = "anchor",
        isEnabled = function(data, entityData)
            if not LocalPlayer.state.isDead and Entity(entityData.entity).state.VIN ~= nil then
                local vehModel = GetEntityModel(entityData.entity)
                if
                    IsThisModelABoat(vehModel)
                    or IsThisModelAJetski(vehModel)
                    or IsThisModelAnAmphibiousCar(vehModel)
                    or IsThisModelAnAmphibiousQuadbike(vehModel)
                then
                    return true
                end
            end
        end,
        text = "Toggle Anchor",
        event = "Vehicles:Client:AnchorBoat",
        data = {},
        minDist = 5.0,
    },
    {
        icon = "car-wrench",
        isEnabled = function(data, entity)
            local entState = Entity(entity.entity).state
            return not LocalPlayer.state.isDead
                and LocalPlayer.state.inChopZone ~= nil
                and LocalPlayer.state.chopping == nil
                and not entState.Owned
        end,
        text = "Start Chopping",
        event = "Laptop:Client:LSUnderground:Chopping:StartChop",
        data = {},
        minDist = 10.0,
    },
    {
        icon = "clothes-hanger",
        isEnabled = function(data, entity)
            local entState = Entity(entity.entity).state
            local rvModels = { [`cararv`] = true, [`guardianrv`] = true, [`sandroamer`] = true, [`sandkingrv`] = true }
            return not LocalPlayer.state.isDead
                and rvModels[GetEntityModel(entity.entity)]
                and exports['sandbox-vehicles']:HasAccess(entity.entity)
        end,
        text = "Open Wardrobe",
        event = "Wardrobe:Client:ShowWardrobe",
        data = {},
        minDist = 2.0,
    },
    {
        icon = "joint",
        isEnabled = function(data, entity)
            return not LocalPlayer.state.cornering
                and not Entity(entity.entity).state.cornering
                and not Config.BlacklistedCornering[GetVehicleClass(entity.entity)]
        end,
        tempjob = "CornerDealing",
        text = "Start Corner Dealing",
        event = "CornerDealing:Client:StartCornering",
        data = {},
        minDist = 2.0,
    },
    {
        icon = "clothes-hanger",
        isEnabled = function(data, entity)
            return LocalPlayer.state.cornering and Entity(entity.entity).state.cornering
        end,
        tempjob = "CornerDealing",
        text = "Stop Corner Dealing",
        event = "CornerDealing:Client:StopCornering",
        data = {},
        minDist = 2.0,
    },
    {
        icon = "hand",
        isEnabled = function(data, entityData)
            return utils.isNearTrunk(entityData.entity, 4.0, true)
        end,
        text = "Grab Loot",
        event = "Robbery:Client:MoneyTruck:GrabLoot",
        model = `stockade`,
        data = {},
        minDist = 10.0,
        isEnabled = function(data, entity)
            local entState = Entity(entity.entity).state
            return not entState.beingLooted
                and entState.wasThermited
                and not entState.wasLooted
                and GetEntityHealth(entity.entity) > 0
        end,
    },
    {
        icon = "car-garage",
        isEnabled = function(data, entityData)
            local inZone = exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(entityData.entity), false,
                "dealerBuyback")
            if inZone then
                return LocalPlayer.state.onDuty == inZone.dealerId
            end
        end,
        text = "Vehicle Buy Back",
        event = "Dealerships:Client:StartBuyback",
        data = {},
        minDist = 5.0,
        permissionKey = "dealership_buyback",
    },
}

for _, menuItem in ipairs(Config.VehicleMenu) do
    if menuItem.icon and (menuItem.text or menuItem.textFunc) and menuItem.event then
        local canInteractFn = nil
        if type(menuItem.canInteract) == "function" then
            canInteractFn = menuItem.canInteract
        elseif type(menuItem.isEnabled) == "function" then
            canInteractFn = function(entity, distance, coords, name)
                local data = { entity = entity, distance = distance, coords = coords, name = name }
                local entityData = { entity = entity }
                return menuItem.isEnabled(data, entityData)
            end
        else
            canInteractFn = function() return true end
        end

        exports.ox_target:addGlobalVehicle({
            name = menuItem.event .. "_" .. (menuItem.icon or "generic"),
            icon = 'fas fa-' .. menuItem.icon,
            label = menuItem.text or (type(menuItem.textFunc) == "function" and menuItem.textFunc(nil, nil) or ""),
            event = menuItem.event,
            data = menuItem.data or {},
            distance = menuItem.minDist or 2.0,
            groups = menuItem.groups or nil,
            reqDuty = menuItem.reqDuty or false,
            reqOffDuty = menuItem.reqOffDuty or false,
            workplace = menuItem.workplace or nil,
            permissionKey = menuItem.permissionKey or nil,
            tempjob = menuItem.tempjob or nil,
            model = menuItem.model or nil,
            canInteract = canInteractFn,
        })
    end
end

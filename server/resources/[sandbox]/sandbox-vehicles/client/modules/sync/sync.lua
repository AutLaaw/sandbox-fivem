SYNC_DRIVING_VEHICLE = false
SYNC_DRIVING_VEHICLE_CLASS = false
SYNC_DRIVING_EMERGENCY_VEHICLE = false
DISABLE_AIR_CONTROL = false
SYNCED_VEHICLES = {}
SYNCED_EMERGENCY_VEHICLES = {}
PLAYER_IS_HOLDING_BIKE = false
PLAYER_BIKE_ENTITY = 0
local vehicleActionRLimits = {}
local noDisableLeanInAir = {
    [8] = true,
    [13] = true,
    [14] = true,
    [15] = true,
    [16] = true,
}

function AddSyncedVehicle(veh)
    if not SYNCED_VEHICLES[veh] then
        local vehClass = GetVehicleClass(veh)
        local data, emergencyData = GetSyncedVehicleStateData(veh, vehClass == 18)

        SYNCED_VEHICLES[veh] = data
        UpdateVehicleIndicatorState(veh, SYNCED_VEHICLES[veh].indicators)
        UpdateVehicleNeonsState(veh, SYNCED_VEHICLES[veh].neonsDisabled)
        if emergencyData then
            SYNCED_EMERGENCY_VEHICLES[veh] = emergencyData

            SetVehicleEmergencySirens(veh, SYNCED_EMERGENCY_VEHICLES[veh].lights, SYNCED_EMERGENCY_VEHICLES[veh].siren)
        end

        local ent = Entity(veh)
        if ent and ent.state and ent.state.ForcedAudio then
            ForceVehicleEngineAudio(veh, ent.state.ForcedAudio)
        end
    end
end

function DestroySyncedVehicle(veh)
    if SYNCED_VEHICLES[veh] then
        SYNCED_VEHICLES[veh] = nil
    end

    if SYNCED_EMERGENCY_VEHICLES[veh] then
        -- Cleanup Siren Sounds
        RemoveVehicleSirenSounds(veh)
        RemoveVehicleAirhornSounds(veh)

        SYNCED_EMERGENCY_VEHICLES[veh] = nil
    end
end

function GetSyncedVehicleStateData(veh, isEmergency)
    local vehEnt = Entity(veh)
    local vEmergencyState = false
    local vState = {
        indicators = false,
        neons = false,
    }

    if vehEnt and vehEnt.state then
        local indicatorState = vehEnt.state.indicators
        if indicatorState ~= nil then
            vState.indicators = indicatorState
        else
            vState.indicators = false
        end

        local neonState = vehEnt.state.neonsDisabled
        vState.neonsDisabled = neonState

        if isEmergency then
            vEmergencyState = {
                lights = false,
                siren = false,
                airhorn = false,
            }

            local lightsState = vehEnt.state.emLights
            if lightsState ~= nil then
                vEmergencyState.lights = lightsState
            end

            local sirenState = vehEnt.state.emSirens
            if sirenState ~= nil then
                vEmergencyState.siren = sirenState
            end
        end
    end

    return vState, vEmergencyState
end

CreateThread(function()
    while true do
        Wait(30000)
        vehicleActionRLimits = {}
    end
end)

function CheckActionRateLimit(elem, amount)
    if not vehicleActionRLimits[elem] then
        vehicleActionRLimits[elem] = 1
    else
        vehicleActionRLimits[elem] = vehicleActionRLimits[elem] + 1
        if vehicleActionRLimits[elem] >= amount then
            return false
        end
    end
    return true
end

AddEventHandler('Vehicles:Client:CharacterLogin', function()
    LAST_SIREN_TYPE = 1
end)

function RunVehicleSyncCleanup()
    for k, v in pairs(SYNCED_VEHICLES) do
        if not DoesEntityExist(k) then
            DestroySyncedVehicle(k)
        end
    end
end

AddEventHandler('Vehicles:Client:CharacterLogout', function()
    SYNC_DRIVING_VEHICLE = false
    SYNC_DRIVING_EMERGENCY_VEHICLE = false
    for k, v in pairs(SYNCED_VEHICLES) do
        DestroySyncedVehicle(k)
    end
end)

AddEventHandler('Vehicles:Client:StartUp', function()
    AddTaskToVehicleThread('air', 1, true, function(veh, class)
        if not noDisableLeanInAir[class] and ((IsEntityInAir(SYNC_DRIVING_VEHICLE) and GetEntityHeightAboveGround(SYNC_DRIVING_VEHICLE) >= 1.8) or GetEntityRoll(SYNC_DRIVING_VEHICLE) < -60 or GetEntityRoll(SYNC_DRIVING_VEHICLE) > 60) then
            DISABLE_AIR_CONTROL = true
        elseif DISABLE_AIR_CONTROL then
            DISABLE_AIR_CONTROL = false
        end
    end)
end)

AddEventHandler('Vehicles:Client:BecameDriver', function(veh, seat, class)
    SYNC_DRIVING_VEHICLE = veh
    SYNC_DRIVING_VEHICLE_CLASS = class
    SYNC_DRIVING_EMERGENCY_VEHICLE = SYNC_DRIVING_VEHICLE_CLASS == 18

    SetAudioFlag("PoliceScannerDisabled", true)

    CreateThread(function()
        while SYNC_DRIVING_VEHICLE do
            local sleep = true
            if DISABLE_AIR_CONTROL then
                -- Why the hell can't disabling stuff be nicer
                DisableControlAction(0, 59, true)
                DisableControlAction(0, 60, true)
                sleep = false
            end

            if SYNC_DRIVING_EMERGENCY_VEHICLE then
                DisableControlAction(0, 80, true)
                DisableControlAction(0, 81, true)
                DisableControlAction(0, 82, true)
                DisableControlAction(0, 85, true)
                DisableControlAction(0, 86, true)
                sleep = false
            end

            Wait(1)
            if sleep then
                Wait(250)
            end
        end
    end)
end)

AddEventHandler('Vehicles:Client:SwitchVehicleSeat', function(veh, seat)
    if seat ~= -1 and SYNC_DRIVING_VEHICLE then
        NoLongerVehicleDriver()
    end
end)

AddEventHandler('Vehicles:Client:ExitVehicle', function()
    NoLongerVehicleDriver()
end)

function NoLongerVehicleDriver()
    if SYNC_DRIVING_EMERGENCY_VEHICLE then
        DoVehicleEmergencyAirhorn(SYNC_DRIVING_VEHICLE, false)
    end
    SYNC_DRIVING_VEHICLE = nil
    SYNC_DRIVING_EMERGENCY_VEHICLE = false
end

RegisterNetEvent("Vehicle:Client:ForceAudio", function(vNet, audio)
    if NetworkDoesEntityExistWithNetworkId(vNet) then
        local veh = NetToVeh(vNet)
        if veh and DoesEntityExist(veh) then
            ForceVehicleEngineAudio(veh, audio)
        end
    end
end)

AddEventHandler("Vehicle:Client:PickupBike", function(entityData)
    if not DoesEntityExist(entityData.entity) then
        return
    end

    exports['sandbox-vehicles']:SyncBikePickup(entityData.entity)
end)

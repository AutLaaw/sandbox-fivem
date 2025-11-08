LAST_VEH_POS = vector3(0, 0, 0)

local lastReplicated = GetGameTimer()

AddEventHandler('Vehicles:Client:StartUp', function()
    AddTaskBeforeVehicleThread('mileage', function(veh, class)
        LAST_VEH_POS = GetEntityCoords(THREAD_VEHICLE)
    end)

    AddTaskToVehicleThread('mileage', 8, false, function(veh, class, engine, inside, onExit)
        if DoesEntityExist(veh) then
            local vehEnt = Entity(veh)
            local currentMileage = vehEnt.state.Mileage
            if type(currentMileage) ~= 'number' then currentMileage = 0 end

            local vehCoords = GetEntityCoords(DAMAGE_VEHICLE)
            local distCovered = #(vehCoords - LAST_VEH_POS)
            if distCovered >= 0.5 then -- Otherwise the vehicle isn't actually moving
                local distCoveredMiles = distCovered / 1609
                local newMileage = exports['sandbox-base']:UtilsRound(currentMileage + distCoveredMiles, 2)

                if (GetGameTimer() - lastReplicated) > 60000 then
                    lastReplicated = GetGameTimer()
                    vehEnt.state:set('Mileage', newMileage, true)
                else
                    vehEnt.state:set('Mileage', newMileage, false)
                end
            end

            if onExit then
                vehEnt.state:set('Mileage', vehEnt.state.Mileage, true)
            end

            LAST_VEH_POS = vehCoords
        end
    end, true)
end)

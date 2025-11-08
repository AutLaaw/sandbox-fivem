local blipsForVehType = {
    [0] = 357,
    [1] = 356,
    [2] = 359,
}

local cachedStorageShit = {}
local _tempVehicles = {}
local tempVehAppearanceData = {}
local tempParkingSpace = nil
local tempCurrentStorageType = false
local tempCurrentStorageId = false
local vehActuallySpawningOne = false
local vehStorageMenuOpen = false

local loadingVehicleStorageVehicle = false

AddEventHandler('Vehicles:Client:StartUp', function()
    if _vehicleStorage then
        for k, v in pairs(_vehicleStorage) do
            local data = {
                veh_storage = true,
                veh_storage_id = k,
            }

            if v.zone and v.zone.type == 'poly' and v.zone.points then
                exports['sandbox-polyzone']:CreatePoly('veh_storage_' .. k, v.zone.points, {
                    minZ = v.zone.minZ,
                    maxZ = v.zone.maxZ,
                    debugPoly = false
                }, data)
            elseif v.zone and v.zone.type == 'box' and v.zone.center and v.zone.length and v.zone.width then
                exports['sandbox-polyzone']:CreateBox('veh_storage_' .. k, v.zone.center, v.zone.length, v.zone.width, {
                    heading = v.zone.heading,
                    minZ = v.zone.minZ,
                    maxZ = v.zone.maxZ,
                    debugPoly = false
                }, data)
            end
        end
    end

    exports['sandbox-hud']:InteractionRegisterMenu("veh_storage", "Open Garage", "warehouse", function()
        OpenVehicleStorage()
        exports['sandbox-hud']:InteractionHide()
    end, function()
        local pedCoords = GetEntityCoords(GLOBAL_PED)
        local inVehicleStorageZone, vehicleStorageZoneId = GetVehicleStorageAtCoords(pedCoords)

        return inVehicleStorageZone or exports['sandbox-properties']:GetNearHouseGarage()
    end)
end)

AddEventHandler('Vehicles:Client:CharacterLogin', function()
    if _vehicleStorage then
        for k, v in pairs(_vehicleStorage) do
            if not v.restricted and not v.hideBlip then
                exports["sandbox-blips"]:Add('veh_storage_' .. k, v.name, v.coords, blipsForVehType[v.vehType], 12, 0.6,
                    false, 10)
            end
        end

        Wait(2500)

        -- Add Restricted Ones After so the Blips Appear With the Restricted Ones at the end of the list
        -- for k, v in pairs(_vehicleStorage) do
        --     if v.restricted then
        --         local charJobs = exports['sandbox-jobs']:GetJobs()

        --         if #charJobs > 0 then
        --             if DoesCharacterPassStorageRestrictions(-1, charJobs, v.restricted) then
        --                 exports["sandbox-blips"]:Add('veh_storage_'.. k, v.name .. ' [Restricted]', v.coords, blipsForVehType[v.vehType], 6, 0.45, false, 10)
        --             end
        --         end
        --     end
        -- end
    end
end)

function GetVehicleStorageAtCoords(coords)
    local insideZone = exports['sandbox-polyzone']:IsCoordsInZone(coords, false, 'veh_storage')
    if insideZone and insideZone.veh_storage and insideZone.veh_storage_id then
        return true, insideZone.veh_storage_id
    end
    return false
end

AddEventHandler('Vehicles:Client:StoreVehicle', function(entityData)
    if entityData and DoesEntityExist(entityData.entity) then
        local vehicleCoords = GetEntityCoords(entityData.entity)
        DetachVehicleFromTrailer(entityData.entity)
        local inVehicleStorageZone, vehicleStorageZoneId = GetVehicleStorageAtCoords(vehicleCoords)
        local vehState = Entity(entityData.entity).state

        if vehState.EmergencyBoat and exports['sandbox-vehicles']:HasAccess(entityData.entity, true) and GetPedInVehicleSeat(entityData.entity) == 0 and GetEntitySpeed(entityData.entity) <= 1 then
            TriggerServerEvent("Vehicles:Server:DeleteEmergencyBoat", VehToNet(entityData.entity))
            return
        end

        if vehState and vehState.VIN and vehState.Owned and GetPedInVehicleSeat(entityData.entity) == 0 and GetEntitySpeed(entityData.entity) <= 1 then
            if inVehicleStorageZone and vehicleStorageZoneId then
                exports["sandbox-base"]:ServerCallback('Vehicles:PutVehicleInStorage', {
                    VIN = vehState.VIN,
                    storageId = vehicleStorageZoneId,
                }, function(success)
                    if success then
                        exports["sandbox-hud"]:Notification("success", 'Stored Vehicle')
                    else
                        exports["sandbox-hud"]:Notification("error", 'Error Storing Vehicle')
                    end
                end)
            else
                local propGarage = exports['sandbox-properties']:GetNearHouseGarage(vehicleCoords)
                if propGarage and propGarage.propertyId then
                    local prop = exports['sandbox-properties']:Get(propGarage.propertyId)
                    if prop and prop.keys ~= nil and prop.keys[LocalPlayer.state.Character:GetData("ID")] ~= nil then
                        exports["sandbox-base"]:ServerCallback('Vehicles:PutVehicleInPropertyStorage', {
                            VIN = vehState.VIN,
                            storageId = propGarage.propertyId,
                        }, function(success, tooFull)
                            if success then
                                exports["sandbox-hud"]:Notification("success", 'Stored Vehicle')
                            else
                                if tooFull then
                                    exports["sandbox-hud"]:Notification("error", 'Error Storing Vehicle - It\'s Full')
                                else
                                    exports["sandbox-hud"]:Notification("error", 'Error Storing Vehicle')
                                end
                            end
                        end)
                    else
                        exports["sandbox-hud"]:Notification("error", 'Don\'t Have Keys to Garage')
                    end
                else
                    exports["sandbox-hud"]:Notification("error", 'Error Storing Vehicle')
                end
            end
        else
            exports["sandbox-hud"]:Notification("error", 'Error Storing Vehicle')
        end
    end
end)

function OpenVehicleStorage()
    local pedCoords = GetEntityCoords(GLOBAL_PED)
    local inVehicleStorageZone, vehicleStorageZoneId = GetVehicleStorageAtCoords(pedCoords)
    if inVehicleStorageZone and vehicleStorageZoneId then
        local myDuty = LocalPlayer.state.onDuty
        local vehStorageData = _vehicleStorage[vehicleStorageZoneId]
        if not vehStorageData or (vehStorageData.restricted and not DoesCharacterPassStorageRestrictions(-1, exports['sandbox-jobs']:GetJobs(), vehStorageData.restricted)) then
            return exports["sandbox-hud"]:Notification("error", 'Invalid Permission To Access This Vehicle Storage')
        end

        if vehStorageData and vehStorageData.spaces then
            local parkingSpace = false
            if vehStorageData.vehType == 0 then
                parkingSpace = GetClosestParkingSpace(pedCoords, vehStorageData.spaces)
            else
                parkingSpace = GetClosestAvailableParkingSpace(pedCoords, vehStorageData.spaces)
            end

            if parkingSpace then
                exports["sandbox-base"]:ServerCallback('Vehicles:GetVehiclesInStorage', vehicleStorageZoneId,
                    function(storedVehicles)
                        if not storedVehicles then
                            exports["sandbox-hud"]:Notification("error", 'Error Fetching Vehicle Storage')
                            return
                        end

                        if #storedVehicles > 0 then
                            cachedStorageShit = {
                                storageType = 1,
                                storageId = vehicleStorageZoneId,
                                storedVehicleData = storedVehicles,
                                parkingSpace = parkingSpace,
                                characterDuty = myDuty
                            }
                            OpenVehicleStorageMenu(1, vehicleStorageZoneId, storedVehicles, parkingSpace, myDuty)
                        else
                            exports["sandbox-hud"]:Notification("error", 'Vehicle Storage Is Empty')
                        end
                    end)
            else
                exports["sandbox-hud"]:Notification("error", 'Could Not Find Parking Space')
            end
        end
    else
        local propertyGarage = exports['sandbox-properties']:GetNearHouseGarage()
        if propertyGarage and propertyGarage.propertyId then
            local coords = vector4(propertyGarage.coords.x, propertyGarage.coords.y, propertyGarage.coords.z,
                propertyGarage.coords.h)

            if IsParkingSpaceFree(coords) then
                exports["sandbox-base"]:ServerCallback('Vehicles:GetVehiclesInPropertyStorage', propertyGarage
                    .propertyId,
                    function(storedVehicles, data, characterId, characters)
                        if not storedVehicles then
                            exports["sandbox-hud"]:Notification("error", 'Error Fetching Vehicle Storage')
                            return
                        end

                        if #storedVehicles > 0 then
                            cachedStorageShit = {
                                storageType = 2,
                                storageId = propertyGarage.propertyId,
                                storedVehicleData = storedVehicles,
                                parkingSpace = coords,
                                characterDuty = LocalPlayer.state.onDuty,
                                maxCount = data.max,
                                currentCount = data.current,
                                characterId = characterId,
                                characters = characters,
                            }
                            OpenVehicleStorageMenu(
                                2,
                                propertyGarage.propertyId,
                                storedVehicles,
                                coords,
                                LocalPlayer.state.onDuty,
                                data.max,
                                data.current,
                                characterId,
                                characters
                            )
                        else
                            exports["sandbox-hud"]:Notification("error", 'Vehicle Storage Is Empty')
                        end
                    end)
            else
                exports["sandbox-hud"]:Notification("error", 'Could Not Find Parking Space')
            end
        end
    end
end

function CleanupTempVehicle()
    for k, v in pairs(_tempVehicles) do
        if DoesEntityExist(v) then
            exports['sandbox-base']:GameVehiclesDelete(v)
            _tempVehicles[k] = nil
        end
    end
end

function EstimateDegenState(degen)
    local partCount = 0
    local total = 0
    if degen and type(degen) == "table" then
        for k, v in pairs(degen) do
            if type(v) == "number" then
                partCount += 1
                total += v
            end
        end

        if partCount > 0 then
            local averageHealth = total / partCount

            if averageHealth >= 90 then
                return "Perfect"
            elseif averageHealth >= 70 then
                return "Good"
            elseif averageHealth >= 50 then
                return "Medium"
            elseif averageHealth >= 30 then
                return "Bad"
            elseif averageHealth >= 15 then
                return "Really Bad"
            else
                return "Falling Apart"
            end
        end
    end

    return "Unknown"
end

function EstimateEngineHealth(engineHealth)
    if type(engineHealth) == "number" then
        if engineHealth >= 950 then
            return "Perfect"
        elseif engineHealth >= 800 then
            return "Good"
        elseif engineHealth >= 600 then
            return "Medium"
        elseif engineHealth >= 400 then
            return "Poor"
        elseif engineHealth >= 1 then
            return "Smoking"
        else
            return "Destroyed"
        end
    end
    return "Unknown"
end

function OpenVehicleStorageMenu(storageType, storageId, storedVehicleData, parkingSpace, characterDuty, maxCount,
                                currentCount, characterId, characters)
    tempCurrentStorageType = storageType
    tempCurrentStorageId = storageId
    tempParkingSpace = parkingSpace
    vehActuallySpawningOne = false

    local personalVehicles = {}
    local fleetVehicles = {}
    local assignedFleetVehicles = {}
    local allFleetVehicles = {}

    local char = LocalPlayer.state.Character
    local hasFleetManagement = false
    
    if char and characterDuty then
        hasFleetManagement = exports['sandbox-jobs']:HasPermissionInJob(characterDuty, 'FLEET_MANAGEMENT')
    end

    for k, v in ipairs(storedVehicleData) do
        if v and v.VIN then
            tempVehAppearanceData[v.VIN] = {
                Vehicle = v.Vehicle,
                RegisteredPlate = v.RegisteredPlate,
                Properties = v.Properties,
            }

            if v.Owner.Type == 0 then
                table.insert(personalVehicles, v)
            elseif v.Owner.Type == 1 then
                local hasGovAssigned = v.GovAssigned and type(v.GovAssigned) == 'table' and #v.GovAssigned > 0
                local isAssignedToPlayer = false
                
                table.insert(allFleetVehicles, v)
                
                if char and hasGovAssigned then
                    for _, assignee in ipairs(v.GovAssigned) do
                        if char:GetData('SID') == assignee.SID then
                            isAssignedToPlayer = true
                            table.insert(assignedFleetVehicles, v)
                            break
                        end
                    end
                end
                
                if not hasGovAssigned then
                    table.insert(fleetVehicles, v)
                end
            end
        end
    end

    local storageName = 'Vehicle Storage'

    if storageType == 1 then
        storageName = _vehicleStorage[storageId].name
    elseif storageType == 2 then
        local prop = exports['sandbox-properties']:Get(storageId)
        if prop and prop.label then
            storageName = prop.label
        end
    end

    local storageMenu = {
        main = {
            label = storageName,
            items = {},
        }
    }

    if storageType == 2 then
        table.insert(storageMenu.main.items, {
            label = 'Property Garage',
            description = string.format('%s/%s Vehicles Stored', currentCount, maxCount),
            submenu = false,
        })
    end

    if storageType == 2 then
        for k, v in ipairs(personalVehicles) do
            if v.Owner and tostring(v.Owner.Id) == tostring(characterId) then
                local description = ''
                if v.RegisteredPlate then
                    description = 'Plate: ' .. v.RegisteredPlate
                else
                    description = 'Type: ' .. (v.Type == 1 and 'Boat' or 'Aircraft')
                end

                table.insert(storageMenu.main.items, {
                    label = v.Make .. ' ' .. v.Model,
                    description = description,
                    event = "Vehicles:Client:Storage:Select",
                    data = { VIN = v.VIN },
                })
            end
        end

        for k, v in ipairs(personalVehicles) do
            if v.Owner and tostring(v.Owner.Id) ~= tostring(characterId) then
                local description = ''
                if v.RegisteredPlate then
                    description = 'Plate: ' .. v.RegisteredPlate
                else
                    description = 'Type: ' .. (v.Type == 1 and 'Boat' or 'Aircraft')
                end

                if not storageMenu[string.format("%s-vehicles", v.Owner.Id)] then
                    local char = characters[v.Owner.Id]

                    if char then
                        storageMenu[string.format("%s-vehicles", v.Owner.Id)] = {
                            label = string.format("%s %s", char.First, char.Last),
                            items = {}
                        }

                        table.insert(storageMenu.main.items, {
                            label = string.format("%s %s", char.First, char.Last),
                            description = string.format("View Vehicles Belonging to State ID %s", v.Owner.Id),
                            submenu = string.format("%s-vehicles", v.Owner.Id),
                        })
                    end
                end

                table.insert(storageMenu[string.format("%s-vehicles", v.Owner.Id)].items, {
                    label = v.Make .. ' ' .. v.Model,
                    description = description,
                    event = "Vehicles:Client:Storage:Select",
                    data = { VIN = v.VIN },
                })
            end
        end
    else
        for k, v in ipairs(personalVehicles) do
            local description = ''
            if v.RegisteredPlate then
                description = 'Plate: ' .. v.RegisteredPlate
            else
                description = 'Type: ' .. (v.Type == 1 and 'Boat' or 'Aircraft')
            end

            table.insert(storageMenu.main.items, {
                label = v.Make .. ' ' .. v.Model,
                description = description,
                event = "Vehicles:Client:Storage:Select",
                data = { VIN = v.VIN },
            })
        end
    end

    if characterDuty and #assignedFleetVehicles > 0 then
        table.insert(storageMenu.main.items, {
            label = 'Assigned Fleet Vehicles',
            description = 'View Fleet Vehicles That Are Assigned to You',
            submenu = 'fleet-assigned',
        })

        storageMenu['fleet-assigned'] = {
            label = 'Assigned Fleet Vehicles',
            items = {}
        }

        for k, v in ipairs(assignedFleetVehicles) do
            local description = ''
            if v.RegisteredPlate then
                description = 'Plate: ' .. v.RegisteredPlate
            else
                description = 'Type: ' .. (v.Type == 1 and 'Boat' or 'Aircraft')
            end
            
            if v.GovAssigned and type(v.GovAssigned) == 'table' and #v.GovAssigned > 0 then
                local assignedNames = {}
                for _, assignee in ipairs(v.GovAssigned) do
                    local name = string.format("%s %s", assignee.First or "", assignee.Last or "")
                    if assignee.Callsign then
                        name = string.format("%s (%s)", name, assignee.Callsign)
                    end
                    table.insert(assignedNames, name)
                end
                description = description .. ' | Assigned: ' .. table.concat(assignedNames, ', ')
            else
                description = description .. ' | Assigned: N/A'
            end

            table.insert(storageMenu['fleet-assigned'].items, {
                label = v.Make .. ' ' .. v.Model,
                description = description,
                event = "Vehicles:Client:Storage:Select",
                data = { VIN = v.VIN },
            })
        end
    end

    if #fleetVehicles > 0 then
        table.insert(storageMenu.main.items, {
            label = 'Fleet Vehicles',
            description = characterDuty and 'View Fleet Vehicles That You Have Access To' or
                'This Requires You to Be On Duty',
            submenu = 'fleet',
            disabled = not characterDuty,
        })

        storageMenu['fleet'] = {
            label = 'Fleet Vehicles',
            items = {}
        }

        for k, v in ipairs(fleetVehicles) do
            local description = ''
            if v.RegisteredPlate then
                description = 'Plate: ' .. v.RegisteredPlate
            else
                description = 'Type: ' .. (v.Type == 1 and 'Boat' or 'Aircraft')
            end
            
            if v.GovAssigned and type(v.GovAssigned) == 'table' and #v.GovAssigned > 0 then
                local assignedNames = {}
                for _, assignee in ipairs(v.GovAssigned) do
                    local name = string.format("%s %s", assignee.First or "", assignee.Last or "")
                    if assignee.Callsign then
                        name = string.format("%s (%s)", name, assignee.Callsign)
                    end
                    table.insert(assignedNames, name)
                end
                description = description .. ' | Assigned: ' .. table.concat(assignedNames, ', ')
            else
                description = description .. ' | Assigned: N/A'
            end

            table.insert(storageMenu.fleet.items, {
                label = v.Make .. ' ' .. v.Model,
                description = description,
                event = "Vehicles:Client:Storage:Select",
                data = { VIN = v.VIN },
            })
        end
    end

    if hasFleetManagement and #allFleetVehicles > 0 then
        table.insert(storageMenu.main.items, {
            label = 'View All Fleet Vehicles',
            description = 'View All Fleet Vehicles (Fleet Management)',
            submenu = 'fleet-all',
        })

        storageMenu['fleet-all'] = {
            label = 'All Fleet Vehicles',
            items = {}
        }

        for k, v in ipairs(allFleetVehicles) do
            local description = ''
            if v.RegisteredPlate then
                description = 'Plate: ' .. v.RegisteredPlate
            else
                description = 'Type: ' .. (v.Type == 1 and 'Boat' or 'Aircraft')
            end
            
            if v.GovAssigned and type(v.GovAssigned) == 'table' and #v.GovAssigned > 0 then
                local assignedNames = {}
                for _, assignee in ipairs(v.GovAssigned) do
                    local name = string.format("%s %s", assignee.First or "", assignee.Last or "")
                    if assignee.Callsign then
                        name = string.format("%s (%s)", name, assignee.Callsign)
                    end
                    table.insert(assignedNames, name)
                end
                description = description .. ' | Assigned: ' .. table.concat(assignedNames, ', ')
            end

            table.insert(storageMenu['fleet-all'].items, {
                label = v.Make .. ' ' .. v.Model,
                description = description,
                event = "Vehicles:Client:Storage:Select",
                data = { VIN = v.VIN, fleetManagement = true },
            })
        end
    end

    vehStorageMenuOpen = true
    exports['sandbox-hud']:ListMenuShow(storageMenu)
end

AddEventHandler("Vehicles:Client:Storage:GoBack", function()
    CleanupTempVehicle()

    if cachedStorageShit then
        OpenVehicleStorageMenu(
            cachedStorageShit.storageType,
            cachedStorageShit.storageId,
            cachedStorageShit.storedVehicleData,
            cachedStorageShit.parkingSpace,
            cachedStorageShit.characterDuty,
            cachedStorageShit.maxCount,
            cachedStorageShit.currentCount,
            cachedStorageShit.characterId,
            cachedStorageShit.characters
        )
    end
end)

AddEventHandler("Vehicles:Client:Storage:Select", function(data)
    CleanupTempVehicle()

    exports["sandbox-base"]:ServerCallback("Vehicles:GetVehiclesInStorageSelect", data, function(vehicle)
        if tempParkingSpace and vehicle then
            loadingVehicleStorageVehicle = true
            
            if not IsModelInCdimage(vehicle.Vehicle) then
                loadingVehicleStorageVehicle = false
            elseif not IsModelAVehicle(vehicle.Vehicle) then
                loadingVehicleStorageVehicle = false
            else
                local spawnTimeout = SetTimeout(5000, function()
                    if loadingVehicleStorageVehicle then
                        loadingVehicleStorageVehicle = false
                    end
                end)

                exports['sandbox-base']:GameVehiclesSpawnLocal(tempParkingSpace.xyz, vehicle.Vehicle, tempParkingSpace.w,
                    function(veh)
                        ClearTimeout(spawnTimeout)
                        
                        if DoesEntityExist(veh) then
                            table.insert(_tempVehicles, veh)

                            FreezeEntityPosition(veh, true)
                            SetEntityAlpha(veh, 155)
                            SetVehicleDoorsLocked(veh, 2)
                            if vehicle.Properties then
                                SetVehicleProperties(veh, vehicle.Properties)
                            end
                            SetEntityCollision(veh, false, true)
                            if vehicle.RegisteredPlate then
                                SetVehicleNumberPlateText(veh, vehicle.RegisteredPlate)
                            end
                        end

                        loadingVehicleStorageVehicle = false
                    end)
            end
        end

        local subMenu = {
            main = {
                label = vehicle.Make .. ' ' .. vehicle.Model,
                headerAction = {
                    event = "Vehicles:Client:Storage:GoBack",
                    icon = "arrow-left",
                }
            }
        }

        local vehItems = {}

        table.insert(vehItems, {
            label = 'Vehicle\'s Identification',
            description = string.format('VIN: %s, Plate: %s', vehicle.VIN, vehicle.RegisteredPlate or 'N/A'),
            event = false,
        })

        if vehicle.Owner.Type == 1 and vehicle.Type ~= 2 then
            table.insert(vehItems, {
                label = 'Vehicle\'s Current State',
                description = string.format('Fuel: %s%%<br>Engine State: %s<br>Average Vehicle Parts State: %s',
                    vehicle.Fuel, EstimateEngineHealth(vehicle.Damage?.Engine), EstimateDegenState(vehicle.DamagedParts)),
                event = false,
            })
        else
            table.insert(vehItems, {
                label = 'Vehicle\'s Current State',
                description = string.format('Fuel: %s%%<br>Engine State: %s', vehicle.Fuel,
                    EstimateEngineHealth(vehicle.Damage?.Engine)),
                event = false,
            })
        end


        if vehicle.Owner.Type == 1 then
            local fleetDesc = string.format('Req. Level: %s, Ownership Type: %s', vehicle.Owner.Level,
                vehicle.Owner.Workplace and string.upper(vehicle.Owner.Workplace) or 'All')
            
            if vehicle.GovAssigned and type(vehicle.GovAssigned) == 'table' and #vehicle.GovAssigned > 0 then
                local assignedNames = {}
                for _, assignee in ipairs(vehicle.GovAssigned) do
                    local name = string.format("%s %s", assignee.First or "", assignee.Last or "")
                    if assignee.Callsign then
                        name = string.format("%s (%s)", name, assignee.Callsign)
                    end
                    table.insert(assignedNames, name)
                end
                fleetDesc = fleetDesc .. '<br>Assigned To: ' .. table.concat(assignedNames, ', ')
            else
                fleetDesc = fleetDesc .. '<br>Assigned To: N/A'
            end
            
            table.insert(vehItems, {
                label = 'Vehicle\'s Fleet Information',
                description = fleetDesc,
                event = false,
            })

            if vehicle.LastDriver and #vehicle.LastDriver > 0 then
                local fhId = vehicle.VIN .. '-fleet-history'
                local vehicleCheck = {}

                local timeNow = GetCloudTimeAsInt() or 0
                for i = #vehicle.LastDriver, 1, -1 do
                    local driver = vehicle.LastDriver[i]
                    local timeString = GetFormattedTimeFromSeconds(timeNow - driver.time)

                    table.insert(vehicleCheck, {
                        label = string.format('Driver SID: %s', driver.char),
                        description = string.format('Returned Vehicle %s Ago', timeString),
                        event = false,
                    })
                end

                subMenu[fhId] = {
                    label = (vehicle.RegisteredPlate or 'Vehicle') .. ' Fleet History',
                    items = vehicleCheck
                }

                table.insert(vehItems, {
                    label = 'Fleet History',
                    description = 'Latest Driver: ' .. (vehicle.LastDriver[#vehicle.LastDriver]?.char or '?'),
                    submenu = fhId,
                })
            end
        end

        local desc = 'Take the Vehicle Out of Storage'
        local disabled = false
        
        local char = LocalPlayer.state.Character
        local characterDuty = LocalPlayer.state.onDuty
        
        local hasFleetManagement = false
        if char and characterDuty then
            hasFleetManagement = exports['sandbox-jobs']:HasPermissionInJob(characterDuty, 'FLEET_MANAGEMENT')
        end

        if vehicle.Owner and vehicle.Owner.Qualification then
            if hasFleetManagement then
                desc = 'Take the Vehicle Out of Storage (Fleet Management)'
                disabled = false
            else
                desc = 'This Vehicle Requires Qualifications'
                disabled = true

                if char and char:GetData('Qualifications') and #char:GetData('Qualifications') > 0 then
                    if hasValue(char:GetData('Qualifications'), vehicle.Owner.Qualification) then
                        disabled = false
                    end
                end
            end
        end

        if not disabled and vehicle.Owner and vehicle.Owner.Type == 1 and vehicle.GovAssigned and type(vehicle.GovAssigned) == 'table' and #vehicle.GovAssigned > 0 then
            if char then
                local isAssignedToPlayer = false
                local charSID = char:GetData('SID')
                
                for _, assignee in ipairs(vehicle.GovAssigned) do
                    if assignee.SID and tostring(assignee.SID) == tostring(charSID) then
                        isAssignedToPlayer = true
                        break
                    end
                end
                
                if not isAssignedToPlayer then
                    if hasFleetManagement then
                        desc = 'Take the Vehicle Out of Storage (Fleet Management Override)'
                        disabled = false
                    else
                        desc = 'This Vehicle is Assigned to Specific Personnel Only'
                        disabled = true
                    end
                end
            end
        end

        table.insert(vehItems, {
            label = 'Retrieve',
            description = desc,
            event = 'Vehicles:Client:Storage:Retrieve',
            disabled = disabled,
            data = { VIN = vehicle.VIN },
        })

        subMenu.main.items = vehItems

        exports['sandbox-hud']:ListMenuShow(subMenu)
    end)
end)

AddEventHandler('Vehicles:Client:Storage:Retrieve', function(data)
    if loadingVehicleStorageVehicle then
        exports["sandbox-hud"]:Notification("error", 'Awaiting Vehicle Load')
        Citizen.SetTimeout(2500, function()
            CleanupTempVehicle()
        end)
        return
    end

    if data.VIN and tempVehAppearanceData[data.VIN] and tempParkingSpace and tempCurrentStorageId then
        vehActuallySpawningOne = true
        exports["sandbox-base"]:ServerCallback('Vehicles:RetrieveVehicleFromStorage', {
            coords = tempParkingSpace.xyz,
            heading = tempParkingSpace.w,
            VIN = data.VIN,
            storageType = tempCurrentStorageType,
            storageId = tempCurrentStorageId,
            fleetManagement = data.fleetManagement or false,
        }, function(success)
            CleanupTempVehicle()
            if success then
                exports["sandbox-hud"]:Notification("info", 'Spawned Vehicle & Received Keys')
            else
                exports["sandbox-hud"]:Notification("error", 'Unable to Retrieve Vehicle')
            end
        end)
    end
end)

AddEventHandler('ListMenu:Close', function()
    if vehStorageMenuOpen then
        vehStorageMenuOpen = false
        tempVehAppearanceData = {}
        if not vehActuallySpawningOne then
            CleanupTempVehicle()
        else
            Citizen.SetTimeout(2500, function()
                CleanupTempVehicle()
            end)
        end
    end

    loadingVehicleStorageVehicle = false
end)

local _taggedVehs = {}

function RegisterCallbacks()
    exports["sandbox-base"]:RegisterServerCallback('Vehicles:GetKeys', function(source, VIN, cb)
        exports['sandbox-vehicles']:KeysAdd(source, VIN)
        cb(true)
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:ToggleLocks', function(source, data, cb)
        local veh = NetworkGetEntityFromNetworkId(data.netId)
        local vehState = Entity(veh).state
        if DoesEntityExist(veh) and vehState.VIN and not vehState.wasThermited then
            local groupKeys = vehState.GroupKeys
            if exports['sandbox-vehicles']:KeysHas(source, vehState.VIN, vehState.GroupKeys) then
                local newState = data.state
                if newState == nil then 
                    newState = not vehState.Locked
                end

                vehState.Locked = newState
                SetVehicleDoorsLocked(veh, vehState.Locked and 2 or 1)
                return cb(true, vehState.Locked)
            end
        end
        cb(false)
    end)

	exports["sandbox-base"]:RegisterServerCallback('Vehicles:Server:VehicleMegaphone', function(source, data, cb)
        TriggerClientEvent("VOIP:Client:Megaphone:Use", source, true)
        cb(true)
    end)
	
    exports["sandbox-base"]:RegisterServerCallback('Vehicles:BreakOpenLock', function(source, data, cb)
        local veh = NetworkGetEntityFromNetworkId(data.netId)
        local vehState = Entity(veh).state
        if DoesEntityExist(veh) and vehState.VIN then
            vehState.Locked = false
            SetVehicleDoorsLocked(veh, vehState.Locked and 2 or 1)
            return cb(true, vehState.Locked)
        end
        cb(false)
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:GetVehiclesInStorage', function(source, storageId, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        local storageData = _vehicleStorage[storageId]
        if not character or not storageData then
            cb(false)
            return
        end

        local charJobs = character:GetData('Jobs') or {}
        local fleetFetch = false

        if type(storageData.restricted) ~= 'table' or DoesCharacterPassStorageRestrictions(source, charJobs, storageData.restricted) then
            local myDuty = Player(source).state.onDuty

            if type(storageData.fleet) == 'table' and myDuty then
                for k, v in ipairs(storageData.fleet) do
                    if v.JobId == myDuty then
                        local jobData = exports['sandbox-jobs']:HasJob(source, v.JobId, v.WorkplaceId)
                        if jobData then
                            local jobPermissions = exports['sandbox-jobs']:GetPermissionsFromJob(source, jobData.Id)
                            if jobPermissions then
                                fleetFetch = {
                                    Id = jobData.Id,
                                    Workplace = (jobData.Workplace and jobData.Workplace.Id or false),
                                    Level = GetAllowedFleetVehicleLevelFromJobPermissions(jobPermissions)
                                }
                            end
                        end
                    end
                end
            end

            local characterId = character:GetData('SID')
            local allVehicles = {}
            local vehiclesProcessed = 0
            local totalQueries = 1
            
            if fleetFetch and fleetFetch.Id then
                totalQueries = 2
            end

            exports['sandbox-vehicles']:OwnedGetAll(storageData.vehType, 0, characterId, function(personalVehicles)
                if personalVehicles then
                    for k, v in ipairs(personalVehicles) do
                        table.insert(allVehicles, v)
                    end
                end
                
                vehiclesProcessed = vehiclesProcessed + 1
                if vehiclesProcessed >= totalQueries then
                    cb(allVehicles)
                end
            end, 1, storageId, true, false, {
                _id = 0,
                VIN = 1,
                Make = 1,
                Model = 1,
                Type = 1,
                Owner = 1,
                RegisteredPlate = 1,
                GovAssigned = 1,
            })

            if fleetFetch and fleetFetch.Id then
                exports['sandbox-vehicles']:OwnedGetAll(storageData.vehType, false, false, function(fleetVehicles)
                    if fleetVehicles then
                        for k, v in ipairs(fleetVehicles) do
                            table.insert(allVehicles, v)
                        end
                    end
                    
                    vehiclesProcessed = vehiclesProcessed + 1
                    if vehiclesProcessed >= totalQueries then
                        cb(allVehicles)
                    end
                end, 1, storageId, true, fleetFetch, {
                    _id = 0,
                    VIN = 1,
                    Make = 1,
                    Model = 1,
                    Type = 1,
                    Owner = 1,
                    RegisteredPlate = 1,
                    GovAssigned = 1,
                })
            end
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:GetVehiclesInStorageSelect', function(source, data, cb)
        if data.VIN then
            exports['sandbox-vehicles']:OwnedGetVIN(data.VIN, cb)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:GetVehiclesInPropertyStorage', function(source, storageId, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        if not character then
            cb(false)
            return
        end

        local property = exports['sandbox-properties']:Get(storageId)
        local maxParking = exports['sandbox-properties']:GetMaxParkingSpaces(storageId)

        if property and property.id and exports['sandbox-properties']:HasKey(property.id, character:GetData("ID")) and maxParking and maxParking > 0 then
            local characterId = character:GetData('SID')
            exports['sandbox-vehicles']:OwnedGetAll(0, false, false, function(vehicles)
                local c = {}
                local charsToFetch = {}

                for k, v in ipairs(vehicles) do
                    if v.Owner and v.Owner.Type == 0 and v.Owner.Id then
                        if not c[v.Owner.Id] then
                            c[v.Owner.Id] = true
                            table.insert(charsToFetch, v.Owner.Id)
                        end
                    end
                end

                local query = "SELECT SID, First, Last, Phone FROM characters WHERE SID IN (" .. table.concat(charsToFetch, ",") .. ")"
                local results = MySQL.query.await(query)
                
                if results and #results > 0 then
                    local dumbStuff = {}
                    for k, v in ipairs(results) do
                        dumbStuff[v.SID] = v
                    end
                
                    cb(vehicles, {
                        current = exports['sandbox-vehicles']:OwnedPropertiesGetCount(storageId),
                        max = maxParking or 0
                    }, characterId, dumbStuff)
                else
                    cb(false)
                end
            end, 2, storageId, true, false, {
                _id = 0,
                VIN = 1,
                Make = 1,
                Model = 1,
                Type = 1,
                Owner = 1,
                RegisteredPlate = 1,
            })
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:RetrieveVehicleFromStorage', function(source, data, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        if not character or not data or not data.VIN or not data.coords or not data.heading then
            cb(false)
            return
        end

        local characterId = character:GetData('SID')

        if exports['sandbox-vehicles']:OwnedGetActive(data.VIN) then
            cb(false)
            return
        end

        exports['sandbox-vehicles']:OwnedGetVIN(data.VIN, function(vehicle)
            if vehicle and vehicle.VIN then
                local isAuthedForVehicle = false
                local extraData = {}
                if vehicle.Owner.Type == 0 and (tostring(vehicle.Owner.Id) == tostring(characterId) or data.storageType == 2) then
                    isAuthedForVehicle = true
                elseif vehicle.Owner.Type == 1 then
                    local onDuty = Player(source).state.onDuty

                    if onDuty and onDuty == vehicle.Owner.Id then
                        local workplace = vehicle.Owner.Workplace
                        if workplace == 0 or workplace == false then
                            workplace = nil
                        end
                        local jobPermissions = exports['sandbox-jobs']:GetPermissionsFromJob(source, vehicle.Owner.Id, workplace)
                        if jobPermissions then
                            local allowedLevel = GetAllowedFleetVehicleLevelFromJobPermissions(jobPermissions)
                            if (allowedLevel >= vehicle.Owner.Level) then
                                isAuthedForVehicle = true

                                if exports['sandbox-police']:IsPdCar(vehicle.Vehicle) or exports['sandbox-police']:IsEMSCar(vehicle.Vehicle) then
                                    local callsign = character:GetData("Callsign")

                                    extraData.callsign = callsign
                                end
                            end
                        end
                    end
                end

                if isAuthedForVehicle and vehicle.Owner.Type == 1 and vehicle.GovAssigned and type(vehicle.GovAssigned) == 'table' and #vehicle.GovAssigned > 0 and not data.fleetManagement then
                    local isAssignedToPlayer = false
                    for _, assignee in ipairs(vehicle.GovAssigned) do
                        if assignee.SID and tostring(assignee.SID) == tostring(characterId) then
                            isAssignedToPlayer = true
                            break
                        end
                    end
                    
                    if not isAssignedToPlayer then
                        isAuthedForVehicle = false
                        exports['sandbox-hud']:Notification(source, "error", 'This vehicle is assigned to specific personnel only')
                    end
                elseif data.fleetManagement then
                    exports['sandbox-hud']:Notification(source, "error", 'Cannot Retrieve Vehicles Via Fleet Management')
                end

                if isAuthedForVehicle then
                    exports['sandbox-vehicles']:OwnedSpawn(source, vehicle.VIN, data.coords, data.heading, function(success, vehicleData, vehicleId)
                        if success then
                            exports['sandbox-vehicles']:KeysAdd(source, vehicle.VIN)

                            if data.storageType == 2 and tostring(vehicle.Owner.Id) ~= tostring(characterId) then
                                exports['sandbox-vehicles']:KeysAddBySID(vehicle.Owner.Id, vehicle.VIN)
                            end
                        end
                        cb(success)
                    end, extraData)
                else
                    cb(false)
                end
            else
                cb(false)
            end
        end)
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:PutVehicleInStorage', function(source, data, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        local storageData = _vehicleStorage[data.storageId]
        if not character or not data or not data.VIN or not data.storageId or not storageData then
            cb(false)
            return
        end

        if storageData.retrievalOnly then
            exports['sandbox-hud']:Notification(source, "error", 'Cannot Store Vehicles Here')
            cb(false)
            return
        end

        local characterId = character:GetData('SID')
        local vehicle = exports['sandbox-vehicles']:OwnedGetActive(data.VIN)

        if not vehicle then
            cb(false)
            return
        end

        local vehicleOwner = vehicle:GetData('Owner')

        local isAuthedForVehicle = false
        if vehicleOwner.Type == 0 and ((not storageData.restricted) or (storageData.restricted and DoesCharacterPassStorageRestrictions(source, character:GetData('Jobs') or {}, storageData.restricted) and tostring(characterId) == tostring(vehicleOwner.Id))) then
            isAuthedForVehicle = true
        elseif vehicleOwner.Type == 1 then
            if storageData.fleet and DoesVehiclePassFleetRestrictions(vehicleOwner, storageData.fleet) then
                local onDuty = Player(source).state.onDuty

                if onDuty and onDuty == vehicleOwner.Id then
                    local workplace = vehicleOwner.Workplace
                    if workplace == 0 or workplace == false then
                        workplace = nil
                    end
                    local jobPermissions = exports['sandbox-jobs']:GetPermissionsFromJob(source, vehicleOwner.Id, workplace)
                    if jobPermissions then
                        local allowedLevel = GetAllowedFleetVehicleLevelFromJobPermissions(jobPermissions)
                        if (allowedLevel >= vehicleOwner.Level) then
                            local t = vehicle:GetData('LastDriver') or {}
                            if #t >= 20 then
                                table.remove(t, 1)
                            end

                            table.insert(t, {
                                time = os.time(),
                                char = characterId,
                            })

                            vehicle:SetData('LastDriver', t)

                            isAuthedForVehicle = true
                        end
                    end
                end
            else
                exports['sandbox-hud']:Notification(source, "error", 'Cannot Store This Vehicle Here')
            end
        end

        if isAuthedForVehicle and vehicle:GetData('Type') == storageData.vehType then
            exports['sandbox-vehicles']:OwnedStore(data.VIN, 1, data.storageId, function(success)
                cb(success)
            end)
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback("Vehicles:Impound:TagVehicle", function(source, data, cb)
        local char = exports['sandbox-characters']:FetchCharacterSource(source)
        local pState = Player(source).state
        if char ~= nil then
            if pState.onDuty == "police" then
                local entState = Entity(NetworkGetEntityFromNetworkId(data.vNet)).state
                if entState ~= nil and entState.VIN ~= nil and _taggedVehs[entState.VIN] == nil then
                    _taggedVehs[entState.VIN] = data
                    cb(true)
                else
                    cb(false)
                end
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:PutVehicleInPropertyStorage', function(source, data, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        if not character or not data or not data.VIN or not data.storageId then
            cb(false)
            return
        end

        local characterId = character:GetData('SID')
        local vehicle = exports['sandbox-vehicles']:OwnedGetActive(data.VIN)

        if not vehicle then
            cb(false)
            return
        end

        local vehicleOwner = vehicle:GetData('Owner')
        if vehicleOwner.Type == 0 and vehicle:GetData('Type') == 0 then
            if exports['sandbox-properties']:HasKeyBySID(data.storageId, vehicleOwner.Id) then
                local property = exports['sandbox-properties']:Get(data.storageId)
                local vehLimit = exports['sandbox-properties']:GetMaxParkingSpaces(data.storageId)
                if not vehLimit then
                    vehLimit = 0
                end

                if exports['sandbox-vehicles']:OwnedPropertiesGetCount(data.storageId, vehicle:GetData('VIN')) < vehLimit then
                    exports['sandbox-vehicles']:OwnedStore(data.VIN, 2, data.storageId, function(success)
                        cb(success)
                    end)
                else
                    cb(false, true)
                end
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:Impound', function(source, data, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        if not character or not data.type or not data.vNet then
            cb(false)
            return
        end

        local veh = NetworkGetEntityFromNetworkId(data.vNet)
        local myDuty = Player(source).state.onDuty

        if DoesEntityExist(veh) and myDuty and exports['sandbox-jobs']:HasPermission(source, _impoundConfig.RequiredPermission) or exports['sandbox-jobs']:HasPermission(source, _impoundConfig.Police.RequiredPermission) then
            local vState = Entity(veh).state
            if vState and vState.VIN and not vState.towObjective then
                local ownedVehicle = exports['sandbox-vehicles']:OwnedGetActive(vState.VIN)
                if ownedVehicle then
                    local impounderData = {
                        SID = character:GetData('SID'),
                        First = character:GetData('First'),
                        Last = character:GetData('Last'),
                        ID = character:GetData('ID'),
                        Police = myDuty == 'police',
                    }

                    if _taggedVehs[vState.VIN] ~= nil then
                        local c = exports['sandbox-characters']:FetchBySID(_taggedVehs[vState.VIN].requester)
                        if c ~= nil then
                            local duty = Player(c:GetData("Source")).state.onDuty
                            impounderData = {
                                SID = c:GetData('SID'),
                                First = c:GetData('First'),
                                Last = c:GetData('Last'),
                                ID = c:GetData('ID'),
                                Police = duty == 'police',
                            }
                        end

                        data = _taggedVehs[vState.VIN]
                    end

                    local impoundData = ParseImpoundData(0, 0, impounderData)
                    if data.type == 'impound' then
                        impoundData = ParseImpoundData(_impoundConfig.RegularFine, 0, impounderData)
                    elseif data.type == 'police' and data.level then
                        local levelData = _impoundConfig.Police.Levels[data.level]
                        if levelData then
                            local policeFine = 0

                            if levelData.Fine.Percent and vState and vState.Value then
                                local fineMultiplier = levelData.Fine.Percent / 100
                                policeFine = math.ceil(vState.Value * fineMultiplier)
                            end
    
                            if policeFine <= levelData.Fine.Min then
                                policeFine = levelData.Fine.Min
                            end
    
                            impoundData = ParseImpoundData(policeFine, levelData.Holding, impounderData)
                        end
                    end

                    if ownedVehicle:GetData('Type') == 0 and ownedVehicle:GetData('Owner').Type == 0 then
                        ownedVehicle:SetData('Storage', impoundData)
                    end
                end

                if myDuty == 'tow' and _taggedVehs[vState.VIN] ~= nil then
                    exports['sandbox-finance']:BalanceDeposit(exports['sandbox-finance']:AccountsGetPersonal(character:GetData("SID")).Account, 800, {
                        type = 'paycheck',
                        title = "PD Tow Fee",
                        description = 'Your Fee For A Vehicle Pickup',
                        data = 800
                    })
                end

                exports['sandbox-vehicles']:Delete(veh, function(success)
                    cb(success)
                end)
            elseif vState and vState.towObjective then
                if myDuty == 'tow' and _taggedVehs[vState.VIN] ~= nil then
                    exports['sandbox-finance']:BalanceDeposit(exports['sandbox-finance']:AccountsGetPersonal(character:GetData("SID")).Account, 800, {
                        type = 'paycheck',
                        title = "PD Tow Fee",
                        description = 'Your Fee For A Vehicle Pickup',
                        data = 800
                    })
                end
                exports['sandbox-vehicles']:Delete(veh, function(success)
                    if success then
                        exports['sandbox-tow']:PayoutPickup(source)
                    end
                    cb(success)
                end)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:GetVehiclesInImpound', function(source, data, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        if not character then
            cb(false)
            return
        end

        local characterId = character:GetData('SID')
        exports['sandbox-vehicles']:OwnedGetAll(0, 0, characterId, function(vehicles)
            for k, v in ipairs(vehicles) do
                if v.Seized then
                    -- TODO: ADD ASSET FEE SEIZURE CHECK HERE
                    if not exports['sandbox-finance']:LoansHasBeenDefaulted("vehicle", v.VIN) then
                        exports['sandbox-vehicles']:OwnedSeize(v.VIN, false)
                        v.Seized = false
                    end
                    Wait(100)
                end
            end
            cb(vehicles, os.time())
        end, 0, 0, false)
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:RetrieveVehicleFromImpound', function(source, data, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        if not character or not data.VIN or not data.coords or not data.heading then
            cb(false)
            return
        end

        local characterId = character:GetData('SID')
        local timeNow = os.time()

        exports['sandbox-vehicles']:OwnedGetVIN(data.VIN, function(vehicle)
            if vehicle and vehicle.VIN and vehicle.Storage.Type == 0 and not vehicle.Seized then
                if vehicle.Owner.Type == 1 and vehicle.GovAssigned and type(vehicle.GovAssigned) == 'table' and #vehicle.GovAssigned > 0 then
                    local isAssignedToPlayer = false
                    for _, assignee in ipairs(vehicle.GovAssigned) do
                        if assignee.SID and tostring(assignee.SID) == tostring(characterId) then
                            isAssignedToPlayer = true
                            break
                        end
                    end
                    
                    if not isAssignedToPlayer then
                        exports['sandbox-hud']:Notification(source, "error", 'This vehicle is assigned to specific personnel only')
                        cb(false)
                        return
                    end
                end

                if vehicle.Storage.Fine and vehicle.Storage.Fine > 0 then
                    if not exports['sandbox-finance']:WalletModify(source, -vehicle.Storage.Fine) then
                        cb(false)
                        return
                    end

                    local f = exports['sandbox-finance']:AccountsGetOrganization("government")
                    exports['sandbox-finance']:BalanceDeposit(f.Account, vehicle.Storage.Fin, false, true)
                end


                if vehicle.Storage.TimeHold and (vehicle.Storage.TimeHold.ExpiresAt - timeNow) > 0 then
                    -- Holding Time Has Not Expired
                    cb(false)
                    return
                end

                exports['sandbox-vehicles']:OwnedSpawn(source, vehicle.VIN, data.coords, data.heading, function(success, vehicleData, vehicleId)
                    if success then
                        local vData = exports['sandbox-vehicles']:OwnedGetActive(vehicle.VIN)
                        vData:SetData('Storage', GetVehicleTypeDefaultStorage(vehicleData.Type))
                        exports['sandbox-vehicles']:KeysAdd(source, vehicle.VIN)
                    end
                    cb(success)
                end)
            else
                cb(false)
            end
        end)
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:CompleteCustoms', function(source, data, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        if not character or type(data.cost) ~= 'number' or type(data.changes) ~= 'table' or not data.vNet then
            cb(false)
            return
        end

        local veh = NetworkGetEntityFromNetworkId(data.vNet)
        local vehState = Entity(veh)
        if DoesEntityExist(veh) and vehState and vehState.state.VIN then
            if exports['sandbox-finance']:WalletModify(source, -math.abs(data.cost)) then
                local vehicleData = exports['sandbox-vehicles']:OwnedGetActive(vehState.state.VIN)
                local newProperties = false
                if vehicleData and vehicleData:GetData('Properties') then
                    local currentProperties = vehicleData:GetData('Properties')

                    if not currentProperties or type(currentProperties) ~= 'table' then
                        currentProperties = {}
                    end
                    if not currentProperties.mods then
                        currentProperties.mods = {}
                    end
                    if not currentProperties.extras then
                        currentProperties.extras = {}
                    end

                    for k, v in pairs(data.changes) do
                        if k == 'mods' then
                            for mod, val in pairs(v) do
                                currentProperties.mods[mod] = val
                            end
                        elseif k == 'extras' then
                            currentProperties.extras = currentProperties.extras or {}
                            for extraId, val in pairs(v) do
                                currentProperties.extras[extraId] = val
                            end
                        else
                            currentProperties[k] = v
                        end
                    end
    
                    newProperties = currentProperties
                    vehicleData:SetData('Properties', currentProperties)
                    vehicleData:SetData('DirtLevel', 0.0)
                    exports['sandbox-vehicles']:OwnedForceSave(vehicleData:GetData('VIN'))

                elseif vehState.state.IsProtected then
                    _savedVehicleProperties[vehState.state.VIN] = data.new
                end
    
                SetVehicleDirtLevel(veh, 0.0)

                local f = exports['sandbox-finance']:AccountsGetOrganization("dgang")
                exports['sandbox-finance']:BalanceDeposit(f.Account, math.abs(data.cost), {
                    type = 'deposit',
                    title = 'Benny\'s',
                    description = string.format("Benny's Vehicle Modifications For %s %s", character:GetData("First"), character:GetData("Last")),
                    data = {},
                }, true)
    
                cb(true, newProperties)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:WheelFitment', function(source, data, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        if not character or not data?.vNet then
            cb(false)
            return
        end

        local veh = NetworkGetEntityFromNetworkId(data.vNet)
        local vehEnt = Entity(veh)
        if DoesEntityExist(veh) and vehEnt?.state?.VIN then
            local vehicleData = exports['sandbox-vehicles']:OwnedGetActive(vehEnt.state.VIN)
            if vehicleData then
                local currentFitmentData = vehicleData:GetData("WheelFitment") or {}
                for k, v in pairs(data.fitment) do
                    currentFitmentData[k] = v
                end

                vehicleData:SetData('WheelFitment', currentFitmentData)
                exports['sandbox-vehicles']:OwnedForceSave(vehicleData:GetData('VIN'))
                vehEnt.state.WheelFitment = currentFitmentData
                TriggerClientEvent('Fitment:Client:Update', -1, data.vNet, currentFitmentData)
            else
                local currentFitmentData = vehEnt.state.WheelFitment or {}
                for k, v in pairs(data.fitment) do
                    currentFitmentData[k] = v
                end

                vehEnt.state.WheelFitment = currentFitmentData
                TriggerClientEvent('Fitment:Client:Update', -1, data.vNet, currentFitmentData)
            end

            cb(true)
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:CompleteRepair', function(source, data, cb)
        local character = exports['sandbox-characters']:FetchCharacterSource(source)
        if not character or type(data.cost) ~= 'number' then
            cb(false)
            return
        end

        if exports['sandbox-finance']:WalletModify(source, -math.abs(data.cost)) then
            local f = exports['sandbox-finance']:AccountsGetOrganization("dgang")
            exports['sandbox-finance']:BalanceDeposit(f.Account, math.abs(data.cost), {
                type = 'deposit',
                title = 'Benny\'s Repair',
                description = string.format("Benny's Vehicle Repair For %s %s", character:GetData("First"), character:GetData("Last")),
                data = {},
            }, true)
            cb(true)
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:CleanVehicle', function(source, data, cb)
        local veh = NetworkGetEntityFromNetworkId(data.vNet)
        local vehState = Entity(veh)
        if DoesEntityExist(veh) and vehState and vehState.state.VIN then
            if not data.bill or (data.bill and exports['sandbox-finance']:WalletModify(source, -100)) then
                local vehicleData = exports['sandbox-vehicles']:OwnedGetActive(vehState.state.VIN)
                if vehicleData then
                    vehicleData:SetData('DirtLevel', 0.0)
                end

                SetVehicleDirtLevel(veh, 0.0)
                return cb(true)
            end
        end
        cb(false)
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:RemoveFakePlate', function(source, data, cb)
        local veh = NetworkGetEntityFromNetworkId(data)
        if veh and DoesEntityExist(veh) then
            local vehState = Entity(veh).state
            if vehState.VIN and vehState.FakePlate then
                local char = exports['sandbox-characters']:FetchCharacterSource(source)
                local vehicle = exports['sandbox-vehicles']:OwnedGetActive(vehState.VIN)
                if char and vehicle and vehicle:GetData('FakePlate') then
                    local fakePlateData = vehicle:GetData('FakePlateData')
                    local originalPlate = vehicle:GetData('RegisteredPlate')

                    SetVehicleNumberPlateText(veh, originalPlate)
                    vehicle:SetData('FakePlate', false)
                    vehicle:SetData('FakePlateData', false)

                    vehState.FakePlate = false

                    exports['sandbox-vehicles']:OwnedForceSave(vehState.VIN)

                    if fakePlateData and fakePlateData.Plate then
                        exports.ox_inventory:AddItem(char:GetData('SID'), 'fakeplates', 1, fakePlateData, 1)
                    end

                    cb(true, originalPlate)
                    return
                end
            end
        end
        cb(false)
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:RemoveHarness', function(source, data, cb)
        local veh = NetworkGetEntityFromNetworkId(data)
        if veh and DoesEntityExist(veh) then
            local vehState = Entity(veh).state
            if vehState.VIN and vehState.Harness and vehState.Harness > 0 then
                vehState.Harness = 0

                cb(true)
                return
            end
        end
        cb(false)
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:Tranfers:CompleteTransfer', function(source, data, cb)
        local SID, VIN in data
        local char = exports['sandbox-characters']:FetchCharacterSource(source)

        if SID and VIN and char then
            local targetChar = exports['sandbox-characters']:FetchBySID(SID)
            local vehicle = exports['sandbox-vehicles']:OwnedGetActive(VIN)
            if targetChar and vehicle and vehicle:GetData('Owner')?.Type == 0 and vehicle:GetData('Owner')?.Id == char:GetData('SID') and source ~= targetChar:GetData('Source') then
                local ped = GetPlayerPed(source)
                local targetPed = GetPlayerPed(targetChar:GetData('Source'))
                if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) <= 10.0 then
                    local ownerHistory = vehicle:GetData('OwnerHistory') or {}
                    local oldOwner = vehicle:GetData('Owner')
                    table.insert(ownerHistory, {
                        Type = oldOwner.Type,
                        Id = oldOwner.Id,
                        First = char:GetData('First'),
                        Last = char:GetData('Last'),
                        Time = os.time(),
                    })

                    vehicle:SetData('Owner', {
                        Type = 0,
                        Id = targetChar:GetData('SID'),
                    })

                    vehicle:SetData('OwnerHistory', ownerHistory)

                    vehicle:SetData('Storage', GetVehicleTypeDefaultStorage(vehicle:GetData('Type')))
                    exports['sandbox-vehicles']:OwnedForceSave(VIN)

                    exports['sandbox-phone']:NotificationAdd(
                        source,
                        "Vehicle Ownership",
                        "A vehicle was just transferred out of your ownership",
                        os.time(),
                        6000,
                        "garage",
                        {}
                    )
                    exports['sandbox-phone']:NotificationAdd(
                        targetChar:GetData('Source'),
                        "Vehicle Ownership",
                        "A vehicle was just transferred into your ownership",
                        os.time(),
                        6000,
                        "garage",
                        {}
                    )

                    exports['sandbox-vehicles']:KeysRemove(source, VIN)
                    exports['sandbox-vehicles']:KeysAdd(targetChar:GetData('Source'), VIN)
                    return
                else
                    exports['sandbox-hud']:Notification(src, "error", 'Cannot Transfer to Someone That Isn\'t Nearby')
                end
            end
        end
        cb(false)
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:RemoveNitrous', function(source, data, cb)
        local char = exports['sandbox-characters']:FetchCharacterSource(source)
        local veh = NetworkGetEntityFromNetworkId(data)
        if char and veh and DoesEntityExist(veh) then
            local vehState = Entity(veh).state
            if vehState.VIN and vehState.Nitrous then
                exports.ox_inventory:AddItem(char:GetData('SID'), 'nitrous', 1, {
                    Nitrous = math.floor(vehState.Nitrous)
                }, 1, nil, nil, nil, nil, nil, nil, nil, true)

                vehState.Nitrous = false

                cb(true)
                return
            end
        end
        cb(false)
    end)

    exports["sandbox-base"]:RegisterServerCallback('Vehicles:GiveKeys', function(source, data, cb)
        local veh = NetworkGetEntityFromNetworkId(data.netId)
        local vehState = Entity(veh).state
        if DoesEntityExist(veh) and vehState.VIN and not vehState.wasThermited then
            local groupKeys = vehState.GroupKeys
            if exports['sandbox-vehicles']:KeysHas(source, vehState.VIN, vehState.GroupKeys) then
                if veh and DoesEntityExist(veh) then
                    local vehEnt = Entity(veh)
                    if
                        vehEnt
                        and vehEnt.state
                        and vehEnt.state.VIN
                        and exports['sandbox-vehicles']:KeysHas(source, vehEnt.state.VIN, false)
                    then
                        for k, v in ipairs(data.sids) do
                            exports['sandbox-vehicles']:KeysAdd(v, vehEnt.state.VIN)
                            exports['sandbox-hud']:Notification("info", v,
                                "You Received Keys to a Vehicle",
                                3000,
                                "key"
                            )
                        end

                        exports['sandbox-hud']:Notification(source, "success",
                            "You Gave Everyone Nearby Keys",
                            3000,
                            "key"
                        )
                    end
                end
            end
        end
        cb(false)
    end)
end
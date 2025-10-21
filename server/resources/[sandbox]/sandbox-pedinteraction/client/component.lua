_characterLoaded, GLOBAL_PED = false, nil

_interactionPeds = {}
_spawnedInteractionPeds = {}

-- AddEventHandler('onClientResourceStart', function(resource)
-- 	if resource == GetCurrentResourceName() then
-- 		Wait(1000)
-- 		exports['sandbox-pedinteraction']:Add('fuck', `a_m_y_soucent_04`, vector3(-810.171, -1311.092, 4.000), 332.419,
-- 			50.0, {
-- 				{ icon = 'boxes-stacked', text = 'F', event = 'F', data = {}, minDist = 2.0, jobs = false },
-- 			})
-- 	end
-- end)

RegisterNetEvent("Characters:Client:Spawn")
AddEventHandler("Characters:Client:Spawn", function()
	_characterLoaded = true

	CreateThread(function()
		while _characterLoaded do
			Wait(1500)
			local pedCoords = GetEntityCoords(PlayerPedId())

			for k, v in pairs(_interactionPeds) do
				if v.enabled then
					local inRange = #(v.coords - pedCoords) <= v.range
					if inRange and not _spawnedInteractionPeds[k] then
						_spawnedInteractionPeds[k] = CreateDumbAssPed(
							v.model,
							v.coords,
							v.heading,
							v.menu,
							v.icon,
							v.scenario,
							v.anim,
							v.component
						)
					elseif not inRange and _spawnedInteractionPeds[k] then
						DeletePed(_spawnedInteractionPeds[k])
						exports.ox_target:removeLocalEntity(_spawnedInteractionPeds[k])
						_spawnedInteractionPeds[k] = nil
					end
				elseif _spawnedInteractionPeds[k] then
					DeletePed(_spawnedInteractionPeds[k])
					exports.ox_target:removeLocalEntity(_spawnedInteractionPeds[k])
					_spawnedInteractionPeds[k] = nil
				end
			end
		end
	end)
end)

RegisterNetEvent("Characters:Client:Logout")
AddEventHandler("Characters:Client:Logout", function()
	_characterLoaded = false

	for k, v in pairs(_spawnedInteractionPeds) do
		DeleteEntity(v)
	end

	_spawnedInteractionPeds = {}
end)

exports("Add", function(id, model, coords, heading, range, menu, icon, scenario, enabled, anim, component)
	if id and model and type(coords) == "vector3" and type(heading) == "number" then
		if enabled == nil then
			enabled = true
		end

		if type(model) == "string" then
			model = GetHashKey(model)
		end

		if not range then
			range = 50.0
		end

		if not IsModelValid(model) or not IsModelAPed(model) then
			exports['sandbox-base']:LoggerError("PedInteraction",
				"Failed to Add Ped ID: " .. id .. " - It's Model is Invalid")
			return
		end

		_interactionPeds[id] = {
			enabled = enabled,
			range = range,
			model = model,
			coords = coords,
			heading = heading,
			icon = icon,
			menu = menu,
			scenario = scenario,
			anim = anim,
			component = component,
		}
	end
end)

exports("Toggle", function(id, enabled)
	if _interactionPeds[id] then
		_interactionPeds[id].enabled = enabled
	end
end)

exports("Remove", function(id)
	if _interactionPeds[id] then
		_interactionPeds[id] = nil
		if _spawnedInteractionPeds[id] then
			DeleteEntity(_spawnedInteractionPeds[id])
			exports.ox_target:removeLocalEntity(_spawnedInteractionPeds[id])
			_spawnedInteractionPeds[id] = nil
		end
	end
end)

exports("GetPed", function(id)
	if _spawnedInteractionPeds[id] then
		return _spawnedInteractionPeds[id]
	end
	return false
end)

function CreateDumbAssPed(model, coords, heading, menu, icon, scenario, anim, component)
	RequestModel(model)
	while not HasModelLoaded(model) do
		Wait(100)
	end

	local ped = CreatePed(5, model, coords.x, coords.y, coords.z, heading, false, false)
	SetEntityAsMissionEntity(ped, true, true)
	FreezeEntityPosition(ped, true)
	SetPedCanRagdoll(ped, false)
	TaskSetBlockingOfNonTemporaryEvents(ped, 1)
	SetBlockingOfNonTemporaryEvents(ped, 1)
	SetPedFleeAttributes(ped, 0, 0)
	SetPedCombatAttributes(ped, 17, 1)
	SetEntityInvincible(ped, true)
	SetPedSeeingRange(ped, 0)
	SetPedDefaultComponentVariation(ped)
	SetModelAsNoLongerNeeded(model)

	if component and type(component) == "table" then
		SetPedComponentVariation(
			ped,
			component.componentId or 0,
			component.drawableId or 0,
			component.texture or 0,
			component.textureId or 0,
			component.paletteId or 0
		)
	end

	if anim and type(anim) == "table" and anim.animDict and anim.anim then
		ClearPedTasks(ped)
		LoadAnim(anim.animDict)
		TaskPlayAnim(
			ped,
			anim.animDict,
			anim.anim,
			anim.blendIn or 8.0,
			anim.blendOut or 8.0,
			anim.duration or -1,
			anim.flag or 1,
			anim.playback or 0,
			anim.lockX or 0,
			anim.lockY or 0,
			anim.lockZ or 0
		)
	elseif scenario and type(scenario) == "string" then
		ClearPedTasks(ped)
		TaskStartScenarioInPlace(ped, scenario, 0, true)
	end

	if menu and #menu > 0 then
		local oxOptions = {}
		for i, option in ipairs(menu) do
			local oxOption = {
				label = option.label or option.text,
				icon = option.icon or "fa-solid fa-shop",
				distance = option.distance or option.minDist or 2.0,
				groups = option.groups or nil,
				permissionKey = option.permissionKey or nil,
				reqDuty = option.reqDuty or false,
				workplace = option.workplace or nil,
				tempjob = option.tempjob or nil,
				rep = option.rep or nil,
				onSelect = function()
					if option.event then
						TriggerEvent(option.event, (option.data or {}))
					else
						option.onSelect()
					end
				end,
				canInteract = option.isEnabled or function()
					return true
				end,
			}

			table.insert(oxOptions, oxOption)
		end

		if #oxOptions > 0 then
			exports.ox_target:addLocalEntity(ped, oxOptions)
		end
	end

	return ped
end

function LoadAnim(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Wait(10)
	end
end

local _intIPL = "gabz_mba_milo_"
local _intCoords = { x = -324.22030000, y = -1968.49300000, z = 20.60336000 }

local _eventNames = {
	basketball = 'Basketball',
	boxing = 'Boxing',
	concert = 'Concert',
	curling = 'Curling',
	derby = 'Derby',
	fameorshame = 'Fame or Shame',
	fashion = 'Fashion',
	football = 'Football',
	icehockey = 'Ice Hockey',
	gokarta = 'Go-Kart A',
	gokartb = 'Go-Kart B',
	trackmaniaa = 'Track Mania A',
	trackmaniab = 'Track Mania B',
	trackmaniac = 'Track Mania C',
	trackmaniad = 'Track Mania D',
	mma = 'MMA',
	none = 'None',
	paintball = 'Paintball',
	rocketleague = 'Rocket League',
	wrestling = 'Wrestling'
}

function SetMBAInterior(entitySet)
	local interior = GetInteriorAtCoords(_intCoords.x, _intCoords.y, _intCoords.z)

	if IsValidInterior(interior) then
		if interior ~= 0 then
			local removeSets, newEntitySet = _EntitySets.Removals.interiors, _EntitySets.Sets[entitySet]
			local removeSigns, newSign = _EntitySets.Removals.signs, _EntitySets.Signs[entitySet]

			for i = 1, #removeSets do
				DeactivateInteriorEntitySet(interior, removeSets[i])
			end

			for i = 1, #removeSigns do
				RemoveIpl(removeSigns[i])
			end

			Wait(100)

			for i = 1, #newEntitySet do
				ActivateInteriorEntitySet(interior, newEntitySet[i])
			end

			if newSign then
				RequestIpl(newSign)
			end

			RefreshInterior(interior)
		end
	end
end

RegisterNetEvent("Characters:Client:Spawn")
AddEventHandler("Characters:Client:Spawn", function()
	while GlobalState["MBA:Interior"] == nil do
		Wait(5)
	end
	-- print('GlobalState["MBA:Interior"]', GlobalState["MBA:Interior"])
	SetMBAInterior(GlobalState["MBA:Interior"])
end)

CreateThread(function()
	if LocalPlayer.state.loggedIn then
		SetMBAInterior(GlobalState["MBA:Interior"])
	end
end)

RegisterNetEvent("Businesses:Client:MBA:InteriorUpdate", function(v)
	if LocalPlayer.state.loggedIn then
		SetMBAInterior(v)
	end
end)

AddEventHandler("Businesses:Client:Startup", function()
	exports.ox_target:addBoxZone({
		id = "mba-event-management",
		coords = vector3(-288.47, -1949.26, 38.05),
		size = vector3(5.0, 1.0, 2.0),
		rotation = 50,
		debug = false,
		minZ = 37.05,
		maxZ = 39.05,
		options = {
			{
				icon = "fas fa-clipboard-check",
				label = "Clock In",
				event = "Businesses:Client:ClockIn",
				groups = { "mba" },
				reqOffDuty = true,
			},
			{
				icon = "fas fa-clipboard",
				label = "Clock Out",
				event = "Businesses:Client:ClockOut",
				groups = { "mba" },
				reqDuty = true,
			},
			{
				icon = "fas fa-wand-magic-sparkles",
				label = "Event Setup",
				event = "Businesses:Client:MBA:StartChangeInterior",
				groups = { "mba" },
				reqDuty = true,
				canInteract = function()
					return LocalPlayer.state.jobPerms and LocalPlayer.state.jobPerms["JOB_SET_MBA"]
				end,
			},
		}
	})
end)

AddEventHandler("Businesses:Client:MBA:StartChangeInterior", function()
	local current = GlobalState["MBA:Interior"]

	local options = {}

	for k, v in pairs(_eventNames) do
		if k ~= current then
			table.insert(options, {
				label = v,
				value = k,
			})
		end
	end

	exports['sandbox-hud']:InputShow(string.format("Change Event Floor - Current: %s", _eventNames[current]),
		"Match Configuration", {
			{
				id = "interior",
				type = "select",
				select = options,
				options = {},
			},
		}, "Businesses:Client:MBA:ChangeInterior", {})
end)

AddEventHandler("Businesses:Client:MBA:ChangeInterior", function(values)
	if values?.interior then
		exports["sandbox-base"]:ServerCallback("MBA:ChangeInterior", values.interior, function(success)
			if success then
				exports["sandbox-hud"]:Notification("success", "Updated")
			else
				exports["sandbox-hud"]:Notification("error", "Failed to Change Event Floor")
			end
		end)
	end
end)

local _joiner = nil
local _working = false
local _state = nil
local _spawned = false
local _drop = nil

local _blip = nil
local _blipArea = nil

local cokePeds = {}

local eventHandlers = {}

local _, relHash = AddRelationshipGroup("COKE_PED")
SetRelationshipBetweenGroups(5, `COKE_PED`, `PLAYER`)
SetRelationshipBetweenGroups(5, `PLAYER`, `COKE_PED`)

local _jobduty = {
	police = true,
	ems = true,
	government = true,
}

local _cokeWeapons = {
	`WEAPON_APPISTOL`,
	`WEAPON_MG`,
	`WEAPON_COMBATMG`,
	`WEAPON_ASSAULTRIFLE`,
	`WEAPON_CARBINERIFLE`,
	`WEAPON_COMPACTRIFLE`,
	`WEAPON_SMG`,
	`WEAPON_SMG_MK2`,
	`WEAPON_ASSAULTSHOTGUN`,
	`WEAPON_SAWNOFFSHOTGUN`,

	--`WEAPON_PUMPSHOTGUN`,
}

local function SetupPeds(peds)
	for k, v in ipairs(peds) do
		while not DoesEntityExist(NetworkGetEntityFromNetworkId(v)) do
			Wait(1)
		end

		local ped = NetworkGetEntityFromNetworkId(v)

		local interior = GetInteriorFromEntity(ped)
		if interior ~= 0 then
			local roomHash = GetRoomKeyFromEntity(ped)
			if roomHash ~= 0 then
				ForceRoomForEntity(ped, interior, roomHash)
			end
		end

		DecorSetBool(ped, "ScriptedPed", true)
		SetEntityAsMissionEntity(ped, 1, 1)

		SetEntityMaxHealth(ped, 2000)
		SetEntityHealth(ped, 2000)
		SetPedArmour(ped, 1000)

		SetPedRelationshipGroupDefaultHash(ped, `COKE_PED`)
		SetPedRelationshipGroupHash(ped, `COKE_PED`)
		SetCanAttackFriendly(ped, false, true)

		TaskTurnPedToFaceEntity(ped, LocalPlayer.state.ped, 1.0)
	end

	for k, v in ipairs(peds) do
		local ped = NetworkGetEntityFromNetworkId(v)

		SetPedCombatAttributes(ped, 5, true)
		SetPedCombatAttributes(ped, 46, true)
		SetPedSeeingRange(ped, 3000.0)
		SetPedHearingRange(ped, 3000.0)
		SetPedAlertness(ped, 3)
		SetPedCombatRange(ped, 2)
		SetPedCombatMovement(ped, 2)
		SetPedCanSwitchWeapon(ped, true)
		SetPedDropsWeaponsWhenDead(ped, false)
		SetPedSuffersCriticalHits(ped, false)
		SetRunSprintMultiplierForPlayer(ped, 1.49)
		TaskCombatHatedTargetsInArea(ped, GetEntityCoords(ped), 200.0, false)
		SetPedAsEnemy(ped, true)
		SetPedRelationshipGroupHash(ped, `HATES_PLAYER`)

		local _, cur = GetCurrentPedWeapon(ped, true)
		SetPedInfiniteAmmo(ped, true, cur)
		SetPedDropsWeaponsWhenDead(ped, false)

		SetEntityInvincible(ped, false)

		TaskGoToEntityWhileAimingAtEntity(ped, PlayerPedId(), PlayerPedId(), 8.0, 1, 0, 15, 1, 1, 1566631136)
		TaskCombatPed(ped, PlayerPedId(), 0, 16)
	end
end

AddEventHandler("Labor:Client:Setup", function()
	exports["sandbox-base"]:RegisterClientCallback("Labor:Coke:GetSpawnCoords", function(data, cb)
		local coords = {}
		for i = 1, math.random(25, 50) do
			local c = vector3(
				data.coords.x + math.random(-math.abs(math.ceil(data.size / 2)), math.ceil(data.size / 2)),
				data.coords.y + math.random(-math.abs(math.ceil(data.size / 2)), math.ceil(data.size / 2)),
				data.coords.z
			)
			local found, gZ = GetGroundZFor_3dCoord(c.x, c.y, 100.0, true)
			table.insert(coords, vector3(c.x, c.y, gZ))
		end
		cb(coords)
	end)

	exports['sandbox-pedinteraction']:Add(
		"CokeSeller",
		`A_M_M_BevHills_02`,
		vector3(GlobalState["CokeRuns"][1], GlobalState["CokeRuns"][2], GlobalState["CokeRuns"][3]),
		GlobalState["CokeRuns"][4],
		100.0,
		{
			{
				icon = "face-tongue-money",
				text = "Let's Have Some Fun ($100,000)",
				event = "Coke:Client:StartWork",
				isEnabled = function()
					return LocalPlayer.state.Character:GetData("TempJob") == nil
						and not _jobduty[LocalPlayer.state.onDuty]
						and not GlobalState["CokeRunActive"]
						and (not GlobalState["CokeRunCD"] or GetCloudTimeAsInt() > GlobalState["CokeRunCD"])
						and not GlobalState["RestartLockdown"]
						and (
							LocalPlayer.state.Character:GetData("CokeCD") == nil
							or GetCloudTimeAsInt() > LocalPlayer.state.Character:GetData("CokeCD")
						)
				end,
			},
			{
				icon = "ban",
				text = "Cancel That, Give Me My Money",
				event = "Coke:Client:Abort",
				isEnabled = function()
					return LocalPlayer.state.Character:GetData("TempJob") == "Coke"
						and _working
						and _state == 0
						and _joiner == GetPlayerServerId(LocalPlayer.state.PlayerID)
				end,
			},
		},
		"block-question",
		false,
		true,
		{
			animDict = "timetable@ron@ig_3_couch",
			anim = "base",
		}
	)
end)

AddEventHandler("Coke:Client:StartWork", function()
	exports["sandbox-base"]:ServerCallback("Coke:StartWork")
end)

AddEventHandler("Coke:Client:Abort", function()
	exports["sandbox-base"]:ServerCallback("Coke:Abort")
end)

RegisterNetEvent("Coke:Client:OnDuty", function(joiner, time)
	_working = true
	_joiner = joiner
	_state = 0

	eventHandlers["receive"] = RegisterNetEvent(string.format("Coke:Client:%s:Receive", joiner), function()
		_state = 1
		_blip = exports["sandbox-blips"]:Add("CokeDrop", "Unknown Contact", { x = 4495.498, y = -4514.340, z = 3.021 },
			306, 2, 1.4)
	end)

	eventHandlers["poly-enter"] = AddEventHandler("Polyzone:Enter", function(id, testedPoint, insideZone, data)
		if id == "cayo_perico" and _state == 1 then
			exports["sandbox-base"]:ServerCallback("Coke:ArriveAtCayo", {}, function() end)
		elseif
			id == "CokeDrop"
			and _state == 3
			and not _spawned
			and _joiner == GetPlayerServerId(LocalPlayer.state.PlayerID)
		then
			exports["sandbox-base"]:ServerCallback("Coke:ArrivedAtPoint", {}, function(peds)
				if peds then
					SetupPeds(peds)
				end
				RegisterHatedTargetsAroundPed(LocalPlayer.state.ped, _drop.size * 8)
			end)
		end
	end)

	eventHandlers["poly-exit"] = AddEventHandler("Polyzone:Exit", function(id, testedPoint, insideZone, data)
		if id == "cayo_perico" then
			if _state == 5 then
				exports["sandbox-base"]:ServerCallback("Coke:LeftCayo", {}, function() end)
			else
			end
		end
	end)

	eventHandlers["cayo-contact"] = RegisterNetEvent(string.format("Coke:Client:%s:GoTo", joiner), function()
		if _state == 1 then
			_state = 2
			exports['sandbox-pedinteraction']:Add(
				"CokeDrop",
				GetHashKey("S_M_M_HairDress_01"),
				vector3(4495.498, -4514.340, 3.021),
				61.210,
				25.0,
				{
					{
						icon = "comment-dots",
						text = "Lets Do This",
						event = "Coke:Client:StartHeist",
						isEnabled = function()
							return LocalPlayer.state.Character:GetData("TempJob") == "Coke" and _state == 2
						end,
					},
				},
				"block-question",
				"WORLD_HUMAN_AA_SMOKE"
			)
		end
	end)

	eventHandlers["cayo-start"] = AddEventHandler("Coke:Client:StartHeist", function()
		exports["sandbox-base"]:ServerCallback("Coke:StartHeist", {}, function() end)
	end)

	eventHandlers["cayo-setup"] = RegisterNetEvent(string.format("Coke:Client:%s:SetupHeist", joiner), function(drop)
		_state = 3
		_drop = drop
		exports["sandbox-blips"]:Remove("CokeDrop")
		_blip = exports["sandbox-blips"]:Add(
			"CokeDrop",
			"Unknown Objective",
			{ x = _drop.coords.x, y = _drop.coords.y, z = _drop.coords.z },
			306,
			2,
			1.4
		)
		_blipArea = AddBlipForRadius(_drop.coords.x, _drop.coords.y, _drop.coords.maxZ, _drop.size + 0.0)
		SetBlipColour(_blipArea, 3)
		SetBlipAlpha(_blipArea, 90)

		exports['sandbox-polyzone']:CreateCircle("CokeDrop", _drop.coords, _drop.size * 2.0, {
			--debugPoly = true
		}, _drop)
	end)

	eventHandlers["cayo-doshit"] = RegisterNetEvent(string.format("Coke:Client:%s:DoShit", joiner), function()
		_spawned = true
		RegisterHatedTargetsAroundPed(LocalPlayer.state.ped, _drop.size * 2)
	end)

	eventHandlers["fetch"] = RegisterNetEvent(string.format("Coke:Client:%s:FetchItems", joiner), function()
		_state = 4
	end)

	eventHandlers["go-back"] = RegisterNetEvent(string.format("Coke:Client:%s:GoBack", joiner), function()
		_state = 5
		exports["sandbox-blips"]:Remove("CokeDrop")
		RemoveBlip(_blipArea)
		exports['sandbox-polyzone']:Remove("CokeDrop")
		_blip = exports["sandbox-blips"]:Add("CokeDrop", "Unknown Contact", { x = 1292.455, y = -3170.885, z = 4.906 },
			306, 2, 1.4)
	end)

	eventHandlers["setup-finish"] = RegisterNetEvent(string.format("Coke:Client:%s:SetupFinish", joiner), function()
		_state = 6
		exports['sandbox-pedinteraction']:Add(
			"CokeDrop",
			GetHashKey("A_M_Y_Beach_01"),
			vector3(1292.455, -3170.885, 4.906),
			140.973,
			25.0,
			{
				{
					icon = "comment-dots",
					text = "I've Done What You Asked",
					event = "Coke:Client:Finish",
					isEnabled = function()
						return LocalPlayer.state.Character:GetData("TempJob") == "Coke" and _state == 6
					end,
				},
			},
			"block-question",
			"WORLD_HUMAN_AA_SMOKE"
		)
	end)

	eventHandlers["finish"] = AddEventHandler("Coke:Client:Finish", function()
		exports["sandbox-base"]:ServerCallback("Coke:Finish", {}, function() end)
	end)
end)

AddEventHandler("Coke:Client:StartJob", function()
	exports["sandbox-base"]:ServerCallback("Coke:StartJob", _joiner, function(state)
		if not state then
			exports["sandbox-hud"]:Notification("error", "Unable To Start Job")
		end
	end)
end)

RegisterNetEvent("Coke:Client:OffDuty", function(time)
	for k, v in pairs(eventHandlers) do
		RemoveEventHandler(v)
	end

	exports['sandbox-pedinteraction']:Remove("CokeDrop")
	exports['sandbox-polyzone']:Remove("CokeDrop")
	exports["sandbox-blips"]:Remove("CokeDrop")
	RemoveBlip(_blipArea)

	_joiner = nil
	_working = false
	_state = nil
	_spawned = false
	eventHandlers = {}
end)

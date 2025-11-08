local _makingItRain = false

local poleDances = {
	{
		anim = "lapdance",
	},
	{
		anim = "lapdance2",
	},
	{
		anim = "lapdance3",
	},
	{
		anim = "lapdance4",
	},
}

local poles = {
	vector3(-1393.7627, -612.0366, 29.7864),
	vector3(-1390.8264, -616.5738, 29.7864),
	vector3(-1387.8630, -621.1016, 29.7864),
}

AddEventHandler("Businesses:Client:Startup", function()
	exports['sandbox-polyzone']:CreateCircle("bh_dancers_1", vector3(-1393.78, -612.28, 30.32), 1.53, {
		name = "bh_dancers_1",
		useZ = false,
		minZ = 29.32,
		maxZ = 32.32,
		--debugPoly=true
	})
	exports['sandbox-polyzone']:CreateCircle("bh_dancers_2", vector3(-1390.82, -616.84, 29.72), 1.55, {
		name = "bh_dancers_2",
		useZ = false,
		minZ = 29.32,
		maxZ = 32.32,
		--debugPoly=true
	})
	exports['sandbox-polyzone']:CreateCircle("bh_dancers_3", vector3(-1387.79, -621.39, 29.72), 1.5, {
		name = "bh_dancers_3",
		useZ = false,
		minZ = 29.32,
		maxZ = 32.32,
		--debugPoly=true
	})

	exports['sandbox-polyzone']:CreateBox("bh_makeitrain", vector3(-1390.89, -616.98, 29.32), 6.0, 16.8, {
		heading = 302,
		--debugPoly=true,
		minZ = 28.32,
		maxZ = 34.32,
	})

	exports['sandbox-hud']:InteractionRegisterMenu("bh_stripper_pole", "Bahama Mamas Dancers", "party-horn", function()
		if
			(
				exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), "bh_dancers_1")
				or exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), "bh_dancers_2")
				or exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), "bh_dancers_3")
			)
			and LocalPlayer.state.onDuty == "bahama"
			and exports['sandbox-jobs']:HasPermissionInJob("bahama", "STRIP_POLE")
		then
			local subMenu = {}

			for k, v in ipairs(poleDances) do
				table.insert(subMenu, {
					icon = "circle-" .. k,
					label = "Dance " .. k,
					action = function()
						TriggerEvent("Businesses:Client:PoleDanceBH", k)
						exports['sandbox-hud']:InteractionHide()
					end,
				})
			end

			exports['sandbox-hud']:InteractionShowMenu(subMenu)
		else
			exports["sandbox-hud"]:Notification("error", "Invalid Permissions")
		end
	end, function()
		return (
			exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), "bh_dancers_1")
			or exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), "bh_dancers_2")
			or exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), "bh_dancers_3")
		) and LocalPlayer.state.onDuty == "bahama"
	end)

	exports['sandbox-hud']:InteractionRegisterMenu("bh_makeitrain", "Make It Rain", "money-bill-1-wave", function()
		if not _makingItRain and exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), "bh_makeitrain") then
			local makeItRain = {
				{
					type = "cash",
					text = "$100 Cash",
					time = math.random(8000, 12000),
				},
				{
					type = "moneyroll",
					text = "Money Rolls",
					time = math.random(8000, 12000),
				},
				{
					type = "moneyband",
					text = "Money Bands",
					time = math.random(8000, 12000),
				},
			}

			local subMenu = {}

			for k, v in ipairs(makeItRain) do
				if v.type == "cash" or exports.ox_inventory:CheckPlayerHasItem(v.type, 1) then
					table.insert(subMenu, {
						icon = "money-bill-1-wave",
						label = v.text,
						action = function()
							local nearestStripper = GetNearbyStripper()
							if nearestStripper then
								MakeItRainBahama(nearestStripper, v.type, v.time)
							end

							exports['sandbox-hud']:InteractionHide()
						end,
					})
				end
			end

			exports['sandbox-hud']:InteractionShowMenu(subMenu)
		end
	end, function()
		return exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), "bh_makeitrain")
			and GetNearbyStripper()
	end)
end)

RegisterNetEvent("Businesses:Client:PoleDanceBH", function(dance)
	local pedCoords = GetEntityCoords(LocalPlayer.state.ped)
	for k, v in ipairs(poles) do
		if #(v - pedCoords) <= 1.5 then
			local cPlayer, dist = exports['sandbox-base']:GamePlayersGetClosestPlayer()

			if dist == -1 or dist > 1.5 then
				local poleDance = poleDances[dance]
				if poleDance then
					-- SetEntityCoords(
					--     PlayerPedId(),
					--     v.x + poleDance.offset.x,
					--     v.y + poleDance.offset.y,
					--     v.z + poleDance.offset.z
					-- )
					-- SetEntityRotation(PlayerPedId(), 0.0, 0.0, 0.0)

					exports['sandbox-animations']:EmotesPlay(poleDance.anim, false, false, false)
				end
			else
				exports["sandbox-hud"]:Notification("error", "Pole Taken")
			end
			return
		end
	end
end)

function MakeItRainBahama(targetSource, cashType, time)
	local targetPlayer = GetPlayerFromServerId(targetSource)
	if targetPlayer == -1 then
		return
	end

	local targetPed = GetPlayerPed(targetPlayer)

	CreateThread(function()
		_makingItRain = true
		exports['sandbox-animations']:EmotesPlay("makeitrain", false, false, false)

		Wait(7500)

		while
			_makingItRain
			and LocalPlayer.state.loggedIn
			and exports['sandbox-animations']:EmotesGet() == "makeitrain"
			and IsDoingStripperDance(Player(targetSource).state.anim)
			and (#(GetEntityCoords(LocalPlayer.state.ped) - GetEntityCoords(targetPed)) <= 5.0)
		do
			local p = promise.new()
			exports["sandbox-base"]:ServerCallback("BH:MakeItRain", {
				target = targetSource,
				type = cashType,
			}, function(success, cd)
				if not success then
					exports["sandbox-hud"]:Notification("error", cd and "Reached Cooldown" or "Error - Ran Out of Money")
					_makingItRain = false
				end

				p:resolve(success)
			end)

			Citizen.Await(p)
			Wait(time)
		end

		_makingItRain = false
		exports['sandbox-animations']:EmotesForceCancel()
	end)
end

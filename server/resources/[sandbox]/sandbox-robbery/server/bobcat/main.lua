_bcInUse = {
	extrDoor = false,
	frontDoor = false,
	securedDoor = false,
	securityDoor = false,
	grabC4 = false,
	useC4 = false,
	loot = {},
	moneyTruckLoot = {},
	frontPc = false,
	securityPc = false,
}
_bcGlobalReset = nil

local _bobcatPeds = {}

local _pedsSpawned = false
local _alerted = false

local _threading = nil
function StartCooldown()
	local timestamp = os.time()
	if _threading ~= nil then
		return
	end
	_threading = timestamp
	CreateThread(function()
		Wait(BC_RESET_TIME)

		if _threading == timestamp then
			ResetBobcat()
		end
	end)
end

function BobcatClearSourceInUse(source)
	for k, v in pairs(_bcInUse) do
		if v == source then
			_bcInUse[k] = nil
		elseif type(v) == "table" then
			for k2, v2 in pairs(v) do
				if v2 == source then
					_bcInUse[k][k2] = nil
				end
			end
		end
	end
end

local function SpawnPeds(source)
	if _pedsSpawned then
		return
	end
	_pedsSpawned = true

	local peds = {}

	for k, v in ipairs(_bobcatPedLocs) do
		local p = CreatePed(5, `s_m_m_armoured_03`, v[1], v[2], v[3], v[4], true, true)
		local w = _bobcatWeapons[math.random(#_bobcatWeapons)]
		Entity(p).state.crimePed = true
		GiveWeaponToPed(p, w, 99999, false, true, true)
		SetCurrentPedWeapon(p, w, true)
		SetPedArmour(p, 600)
		--TaskCombatPed(p, GetPlayerPed(source), 0, 16)

		table.insert(peds, NetworkGetNetworkIdFromEntity(p))
		Wait(3)
	end

	Wait(1000)

	return peds
end

AddEventHandler("Characters:Server:PlayerLoggedOut", BobcatClearSourceInUse)
AddEventHandler("Characters:Server:PlayerDropped", BobcatClearSourceInUse)

AddEventHandler("Robbery:Server:Setup", function()
	StartBobcatThreads()
	GlobalState["Bobcat:LootLocations"] = _bobcatLootLocs

	exports.ox_inventory:RegisterUse("thermite", "BobcatRobbery", function(source, itemData)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		local pState = Player(source).state

		local myPos = GetEntityCoords(GetPlayerPed(source))
		if
			(
				not GlobalState["AntiShitlord"]
				or os.time() > GlobalState["AntiShitlord"]
				or GlobalState["BobcatInProgress"]
			)
			and not GlobalState["Bobcat:Secured"]
			and not GlobalState["Bobcat:ExtrDoor"]
			and #(_bobcatLocations.extrDoor.coords - myPos) <= 3.5
		then
			if GetGameTimer() < BC_SERVER_START_WAIT or (GlobalState["RestartLockdown"] and not GlobalState["BobcatInProgress"]) then
				exports['sandbox-hud']:Notification(source, "error",
					"You Notice The Door Is Barricaded For A Storm, Maybe Check Back Later",
					6000
				)
				return
			elseif (GlobalState["Duty:police"] or 0) < BC_REQUIRED_POLICE and not GlobalState["BobcatInProgress"] then
				exports['sandbox-hud']:Notification(source, "error",
					"Enhanced Security Measures Enabled, Maybe Check Back Later When Things Feel Safer",
					6000
				)
				return
			elseif GlobalState["RobberiesDisabled"] then
				exports['sandbox-hud']:Notification(source, "error",
					"Temporarily Disabled, Please See City Announcements",
					6000
				)
				return
			end

			if not _bcInUse.extrDoor then
				_bcInUse.extrDoor = source
				if exports.ox_inventory:RemoveSlot(itemData.Owner, itemData.Name, 1, itemData.Slot, itemData.invType) then
					exports['sandbox-base']:LoggerInfo("Robbery",
						string.format("%s %s (%s) Started Thermiting Bobcat Exterior Door", char:GetData("First"),
							char:GetData("Last"), char:GetData("SID")))
					exports["sandbox-base"]:ClientCallback(source, "Robbery:Games:Thermite", {
						passes = 1,
						location = _bobcatLocations.extrDoor,
						duration = 11000,
						config = {
							countdown = 3,
							preview = 1500,
							timer = 7500,
							passReduce = 500,
							base = 12,
							cols = 5,
							rows = 5,
							anim = false,
						},
						data = {},
					}, function(success)
						if success then
							exports['sandbox-base']:LoggerInfo("Robbery",
								string.format("%s %s (%s) Successfully Thermited Bobcat Exterior Door",
									char:GetData("First"), char:GetData("Last"), char:GetData("SID")))
							if not GlobalState["AntiShitlord"] or os.time() >= GlobalState["AntiShitlord"] then
								GlobalState["AntiShitlord"] = os.time() + (60 * math.random(10, 15))
							end

							GlobalState["Bobcat:ExtrDoor"] = true
							GlobalState["BobcatInProgress"] = true

							if not _bcGlobalReset then
								_bcGlobalReset = os.time() + BC_RESET_TIME
							end

							exports['ox_doorlock']:SetLock("bobcat_extr", false)
							if not _alerted or os.time() > _alerted then
								exports['sandbox-robbery']:TriggerPDAlert(
									source,
									vector3(879.020, -2263.657, 30.468),
									"10-90",
									"Armed Robbery",
									{
										icon = 586,
										size = 0.9,
										color = 31,
										duration = (60 * 5),
									},
									{
										icon = "shield-quartered",
										details = 'Bobcat Security',
									},
									'bobcat'
								)
								_alerted = os.time() + (60 * 10)
							end
						else
							exports['sandbox-base']:LoggerInfo("Robbery",
								string.format("%s %s (%s) Failed Thermiting Bobcat Exterior Door", char:GetData("First"),
									char:GetData("Last"), char:GetData("SID")))
						end
						_bcInUse.extrDoor = false
					end)
				end
			else
				exports['sandbox-hud']:Notification(source, "error", "Someone Is Already Doing This",
					6000)
			end
		else
			if pState.inBobcat then
				if
					(
						not GlobalState["AntiShitlord"]
						or os.time() > GlobalState["AntiShitlord"]
						or GlobalState["BobcatInProgress"]
					)
					and GlobalState["Bobcat:ExtrDoor"]
					and not GlobalState["Bobcat:FrontDoor"]
					and not GlobalState["Bobcat:Secured"]
					and #(_bobcatLocations.startDoor.coords - myPos) <= 3.5
				then
					if
						GetGameTimer() < BC_SERVER_START_WAIT or (GlobalState["RestartLockdown"] and not GlobalState["BobcatInProgress"])
					then
						exports['sandbox-hud']:Notification(source, "error",
							"You Notice The Door Is Barricaded For A Storm, Maybe Check Back Later",
							6000
						)
						return
					elseif (GlobalState["Duty:police"] or 0) < BC_REQUIRED_POLICE and not GlobalState["BobcatInProgress"] then
						exports['sandbox-hud']:Notification(source, "error",
							"Enhanced Security Measures Enabled, Maybe Check Back Later When Things Feel Safer",
							6000
						)
						return
					elseif GlobalState["RobberiesDisabled"] then
						exports['sandbox-hud']:Notification(source, "error",
							"Temporarily Disabled, Please See City Announcements",
							6000
						)
						return
					end

					if not _bcInUse.frontDoor then
						_bcInUse.frontDoor = source
						if exports.ox_inventory:RemoveSlot(itemData.Owner, itemData.Name, 1, itemData.Slot, itemData.invType) then
							exports['sandbox-base']:LoggerInfo("Robbery",
								string.format("%s %s (%s) Started Thermiting Bobcat Interior Door", char:GetData("First"),
									char:GetData("Last"), char:GetData("SID")))
							exports["sandbox-base"]:ClientCallback(source, "Robbery:Games:Thermite", {
								passes = 1,
								location = _bobcatLocations.startDoor,
								duration = 11000,
								config = {
									countdown = 3,
									preview = 1500,
									timer = 7500,
									passReduce = 500,
									base = 12,
									cols = 5,
									rows = 5,
									anim = false,
								},
								data = {},
							}, function(success)
								if success then
									exports['sandbox-base']:LoggerInfo("Robbery",
										string.format(
											"%s %s (%s) Successfully Thermited Bobcat Interior Door at coords:(%s)",
											char:GetData("First"), char:GetData("Last"), char:GetData("SID"),
											json.encode(GetEntityCoords(GetPlayerPed(source)))), {
											console = true,
											file = true,
											database = true,
											discord = {
												embed = true,
											},
										})
									if not GlobalState["AntiShitlord"] or os.time() >= GlobalState["AntiShitlord"] then
										GlobalState["AntiShitlord"] = os.time() + (60 * math.random(10, 15))
									end

									GlobalState["Bobcat:FrontDoor"] = true
									GlobalState["BobcatInProgress"] = true

									if not _bcGlobalReset then
										_bcGlobalReset = os.time() + BC_RESET_TIME
									end

									exports['ox_doorlock']:SetLock("bobcat_front", false)
									if not _alerted or os.time() > _alerted then
										exports['sandbox-robbery']:TriggerPDAlert(
											source,
											vector3(879.020, -2263.657, 30.468),
											"10-90",
											"Armed Robbery",
											{
												icon = 586,
												size = 0.9,
												color = 31,
												duration = (60 * 5),
											},
											{
												icon = "shield-quartered",
												details = 'Bobcat Security',
											},
											'bobcat'
										)
										_alerted = os.time() + (60 * 10)
									end
								else
									exports['sandbox-base']:LoggerInfo("Robbery",
										string.format("%s %s (%s) Failed Thermiting Bobcat Interior Door",
											char:GetData("First"), char:GetData("Last"), char:GetData("SID")))
								end
								_bcInUse.frontDoor = false
							end)
						end
					else
						exports['sandbox-hud']:Notification(source, "error",
							"Someone Is Already Doing This", 6000)
					end
				end
			else
				exports["sandbox-base"]:ClientCallback(source, "Robbery:Moneytruck:CheckForTruck", {},
					function(type, vNet)
						if type ~= nil then
							local ent = NetworkGetEntityFromNetworkId(vNet)
							local entState = Entity(ent).state

							if
								GetGameTimer() < BCT_SERVER_START_WAIT or (GlobalState["RestartLockdown"] and not entState.robberyInProgress)
							then
								exports['sandbox-hud']:Notification(source, "error",
									"You Notice The Door Is Barricaded For A Storm, Maybe Check Back Later",
									6000
								)
								return
							elseif (GlobalState["Duty:police"] or 0) < BCT_REQUIRED_POLICE and not entState.robberyInProgress then
								exports['sandbox-hud']:Notification(source, "error",
									"Enhanced Security Measures Enabled, Maybe Check Back Later When Things Feel Safer",
									6000
								)
								return
							elseif GlobalState["RobberiesDisabled"] then
								exports['sandbox-hud']:Notification(source, "error",
									"Temporarily Disabled, Please See City Announcements",
									6000
								)
								return
							end

							if not entState.robberyInProgress then
								entState.robberyInProgress = source
								if not entState.wasThermited then
									if
										exports.ox_inventory:RemoveSlot(
											itemData.Owner,
											itemData.Name,
											1,
											itemData.Slot,
											itemData.invType
										)
									then
										exports['sandbox-base']:LoggerInfo("Robbery",
											string.format("%s %s (%s) Started Thermiting Moneytruck at Coords: (%s)",
												char:GetData("First"), char:GetData("Last"), char:GetData("SID"),
												json.encode(GetEntityCoords(GetPlayerPed(source)))), {
												console = true,
												file = true,
												database = true,
												discord = {
													embed = true,
												},
											})
										exports["sandbox-base"]:ClientCallback(source, "Robbery:Moneytruck:Thermite:Door",
											{
												vNet = vNet,
												passes = 1,
												location = _bobcatLocations.startDoor,
												duration = 3000,
												config = {
													countdown = 3,
													preview = 2000,
													timer = 7500,
													passReduce = 500,
													base = 9,
													cols = 5,
													rows = 5,
													anim = false,
												},
												data = {},
											}, function(success, coords)
												if success then
													exports['sandbox-base']:LoggerInfo("Robbery",
														string.format(
															"%s %s (%s) Successfully Thermited Moneytruck at Coords: (%s)",
															char:GetData("First"), char:GetData("Last"),
															char:GetData("SID"),
															json.encode(GetEntityCoords(GetPlayerPed(source)))), {
															console = true,
															file = true,
															database = true,
															discord = {
																embed = true,
															},
														})
													local peds = {}

													SetVehicleDoorsLocked(ent, 3)
													FreezeEntityPosition(ent, 1)

													local amount = 8
													if type == 2 then
														amount = 12
													end

													for i = 1, amount do
														local model = `S_M_M_Security_01`
														if type == 2 then
															model = `s_m_m_armoured_03`
														end

														local p = CreatePed(5, model, coords.x + math.random(-1.0, 1.0),
															coords.y + math.random(-1.0, 1.0), coords.z,
															math.random(360) * 1.0,
															true, true)
														local w = _bobcatWeapons[math.random(#_bobcatWeapons)]
														Entity(p).state.crimePed = true
														GiveWeaponToPed(p, w, 99999, false, true)
														SetCurrentPedWeapon(p, w, true)
														SetPedArmour(p, type == 2 and 1000 or 500)

														while not DoesEntityExist(p) do
															Wait(1)
														end

														table.insert(peds, NetworkGetNetworkIdFromEntity(p))
													end

													Wait(300)

													Entity(ent).state.wasThermited = true

													exports['sandbox-robbery']:TriggerPDAlert(
														source,
														GetEntityCoords(ent),
														"10-90",
														"Armored Truck Robbery",
														{
															icon = 477,
															size = 0.9,
															color = 50,
															duration = (60 * 5),
														},
														{
															icon = "truck-field",
															details = type == 2 and 'Bobcat Security' or 'Gruppe 6',
														}
													)

													exports["sandbox-base"]:ClientCallback(
														source,
														"Robbery:Bobcat:SetupPeds",
														{
															peds = peds,
															isBobcat = false,
															skipLeaveVeh = true
														},
														function() end
													)
												else
													exports['sandbox-base']:LoggerInfo("Robbery",
														string.format(
															"%s %s (%s) Failed Thermiting Moneytruck at Coords: (%s)",
															char:GetData("First"), char:GetData("Last"),
															char:GetData("SID"),
															json.encode(GetEntityCoords(GetPlayerPed(source)))), {
															console = true,
															file = true,
															database = true,
															discord = {
																embed = true,
															},
														})
												end
												entState.robberyInProgress = false
											end)
									end
								else
									exports['sandbox-hud']:Notification(source, "error",
										"This Truck Has Already Been Hit",
										6000)
								end
							else
								exports['sandbox-hud']:Notification(source, "error",
									"Someone Is Already Doing This", 6000)
							end
						end
					end)
			end
		end
	end)

	exports.ox_inventory:RegisterUse("bobcat_charge", "BobcatRobbery", function(source, itemData)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		local pState = Player(source).state

		if pState.inBobcat then
			if
				(
					not GlobalState["AntiShitlord"]
					or os.time() >= GlobalState["AntiShitlord"]
					or GlobalState["BobcatInProgress"]
				)
				and GlobalState["Bobcat:ExtrDoor"]
				and GlobalState["Bobcat:FrontDoor"]
				and GlobalState["Bobcat:SecuredDoor"]
				and GlobalState["BobcatC4"]
				and not GlobalState["Bobcat:Secured"]
			then
				local myPos = GetEntityCoords(GetPlayerPed(source))
				if #(_bobcatLocations.vaultDoor.coords - myPos) <= 3.5 then
					if GetGameTimer() < BC_SERVER_START_WAIT or (GlobalState["RestartLockdown"] and not GlobalState["BobcatInProgress"]) then
						exports['sandbox-hud']:Notification(source, "error",
							"You Notice The Door Is Barricaded For A Storm, Maybe Check Back Later",
							6000
						)
						return
					elseif (GlobalState["Duty:police"] or 0) < BC_REQUIRED_POLICE and not GlobalState["BobcatInProgress"] then
						exports['sandbox-hud']:Notification(source, "error",
							"Enhanced Security Measures Enabled, Maybe Check Back Later When Things Feel Safer",
							6000
						)
						return
					elseif GlobalState["RobberiesDisabled"] then
						exports['sandbox-hud']:Notification(source, "error",
							"Temporarily Disabled, Please See City Announcements",
							6000
						)
						return
					end

					if not _bcInUse.useC4 then
						_bcInUse.useC4 = source
						if exports.ox_inventory:RemoveSlot(itemData.Owner, itemData.Name, 1, itemData.Slot, itemData.invType) then
							exports['sandbox-base']:LoggerInfo("Robbery",
								string.format("%s %s (%s) Started Breaching Bobcat Vault", char:GetData("First"),
									char:GetData("Last"), char:GetData("SID")))
							exports["sandbox-base"]:ClientCallback(source, "Robbery:Games:Aim", {
								location = {
									coords = vector3(890.41, -2285.601, 30.467),
									heading = 93.374,
								},
								duration = 11000,
								config = {
									countdown = 3,
									limit = 15750,
									timer = 500,
									startSize = 20,
									maxSize = 75,
									growthRate = 20,
									accuracy = 75,
									isMoving = false,
									anim = false,
								},
								data = {},
							}, function(success, data)
								GlobalState["BobcatInProgress"] = true

								if success then
									exports['sandbox-base']:LoggerInfo("Robbery",
										string.format("%s %s (%s) Successfully Breached Bobcat Vault",
											char:GetData("First"), char:GetData("Last"), char:GetData("SID")))
									GlobalState["Bobcat:VaultDoor"] = true
									TriggerClientEvent("Robbery:Client:Bobcat:UpdateIPL", -1, true)

									if not _bcGlobalReset then
										_bcGlobalReset = os.time() + BC_RESET_TIME
									end
								else
									exports['sandbox-base']:LoggerInfo("Robbery",
										string.format("%s %s (%s) Failed Breaching Bobcat Vault", char:GetData("First"),
											char:GetData("Last"), char:GetData("SID")))
									GlobalState["Bobcat:VaultDoor"] = false
									GlobalState["BobcatC4"] = false
								end
								_bcInUse.useC4 = false
							end)
						end
					else
						exports['sandbox-hud']:Notification(source, "error",
							"Someone Else Is Already Doing A Thing",
							6000
						)
					end
				end
			end
		end
	end)

	exports.ox_inventory:RegisterUse("blue_laptop", "BobcatRobbery", function(source, slot, itemData)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		local pState = Player(source).state

		if pState.inBobcat then
			local ped = GetPlayerPed(source)
			local myCoords = GetEntityCoords(ped)

			if
				(
					not GlobalState["AntiShitlord"]
					or os.time() >= GlobalState["AntiShitlord"]
					or GlobalState["BobcatInProgress"]
				)
				and GlobalState["Bobcat:ExtrDoor"]
				and GlobalState["Bobcat:FrontDoor"]
				and not GlobalState["Bobcat:Secured"]
			then
				if #(_bobcatLocations.securedDoor.coords - myCoords) <= 1.5 then
					if GetGameTimer() < BC_SERVER_START_WAIT or (GlobalState["RestartLockdown"] and not GlobalState["BobcatInProgress"]) then
						exports['sandbox-hud']:Notification(source, "error",
							"You Notice The Door Is Barricaded For A Storm, Maybe Check Back Later",
							6000
						)
						return
					elseif (GlobalState["Duty:police"] or 0) < BC_REQUIRED_POLICE and not GlobalState["BobcatInProgress"] then
						exports['sandbox-hud']:Notification(source, "error",
							"Enhanced Security Measures Enabled, Maybe Check Back Later When Things Feel Safer",
							6000
						)
						return
					elseif GlobalState["RobberiesDisabled"] then
						exports['sandbox-hud']:Notification(source, "error",
							"Temporarily Disabled, Please See City Announcements",
							6000
						)
						return
					end

					if not _bcInUse.securedDoor then
						_bcInUse.securedDoor = source
						exports['sandbox-base']:LoggerInfo("Robbery",
							string.format("%s %s (%s) Started Hacking Bobcat Doors", char:GetData("First"),
								char:GetData("Last"), char:GetData("SID")))
						exports["sandbox-base"]:ClientCallback(source, "Robbery:Games:Laptop", {
							location = {
								coords = vector3(883.116, -2267.680, 30.468),
								heading = 178.302
							},
							config = {
								countdown = 3,
								timer = { 1700, 2400 },
								limit = 20000,
								difficulty = 4,
								chances = 6,
								isShuffled = false,
								anim = false,
							},
							data = {},
						}, function(success, data)
							if success then
								exports['sandbox-base']:LoggerInfo("Robbery",
									string.format("%s %s (%s) Successfully Hacked Bobcat Doors", char:GetData("First"),
										char:GetData("Last"), char:GetData("SID")))
								GlobalState["Bobcat:SecuredDoor"] = true
								GlobalState["BobcatInProgress"] = true

								_bobcatPeds = SpawnPeds(source)
								exports["sandbox-base"]:ClientCallback(source, "Robbery:Bobcat:SetupPeds", {
									peds = _bobcatPeds,
									isBobcat = true,
									skipLeaveVeh = true,
								}, function() end)
								exports['ox_doorlock']:SetLock("bobcat_inner", false)
								exports['sandbox-hud']:Notification(source, "success",
									"Doorlock Disengaged", 6000)
								exports.ox_inventory:RemoveSlot(slot.Owner, slot.Name, 1, slot.Slot, 1)

								if not _bcGlobalReset then
									_bcGlobalReset = os.time() + BC_RESET_TIME
								end
							else
								exports['sandbox-base']:LoggerInfo("Robbery",
									string.format("%s %s (%s) Failed Hacking Bobcat Doors", char:GetData("First"),
										char:GetData("Last"), char:GetData("SID")))
								exports['ox_doorlock']:SetLock("bobcat_inner", true)
								exports['sandbox-status']:Add(source, "PLAYER_STRESS", 6)

								local newValue = slot.CreateDate - math.ceil(itemData.durability / 4)
								if (os.time() - itemData.durability >= newValue) then
									exports.ox_inventory:RemoveId(char:GetData("SID"), 1, slot)
								else
									exports.ox_inventory:SetItemCreateDate(
										slot.id,
										newValue
									)
								end
							end
							_bcInUse.securedDoor = false
						end)
					else
						exports['sandbox-hud']:Notification(source, "error",
							"Someone Else Is Already Doing A Thing",
							6000
						)
					end
				end
			else
				exports['sandbox-hud']:Notification(source, "error",
					"Temporary Emergency Systems Enabled, Check Beck In A Bit",
					6000
				)
			end
		end
	end)

	exports.ox_inventory:RegisterUse("gps_tracker", "BobcatRobbery", function(source, slot, itemData)
		if _truckSpawnEnabled then
			if #_moneyTruckSpawns == 0 then
				_moneyTruckSpawns = table.copy(_spawnHoldingShit)
			end

			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			if char ~= nil then
				local pState = Player(source).state

				exports['sandbox-hud']:Notification(source, "info",
					"Locating Truck...",
					6000
				)

				local m = `stockade`
				local netId = SpawnBobcatTruck(m)

				if not netId then
					exports['sandbox-hud']:Notification(source, "error",
						"Unable To Locate A Truck",
						6000
					)
				else
					exports['sandbox-base']:LoggerInfo("Robbery",
						string.format("%s %s (%s) Used Money Truck GPS Tracker", char:GetData("First"),
							char:GetData("Last"), char:GetData("SID")))
					exports["sandbox-base"]:ClientCallback(source, "Robbery:MoneyTruck:MarkTruck", netId, function(r)
						if r then
							exports.ox_inventory:RemoveSlot(slot.Owner, slot.Name, 1, slot.Slot, 1)
							exports['sandbox-hud']:Notification(source, "success",
								"A Truck Has Been Marked On Your GPS",
								6000
							)
						end
					end)
				end
			end
		else
			exports['sandbox-hud']:Notification(source, "error",
				"No Trucks Currently Available, Try Again Later",
				6000
			)
		end
	end)

	exports.ox_inventory:RegisterUse("fleeca_tracker", "BobcatRobbery", function(source, slot, itemData)
		if _truckSpawnEnabled then
			if #_moneyTruckSpawns == 0 then
				_moneyTruckSpawns = table.copy(_spawnHoldingShit)
			end

			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			if char ~= nil then
				local pState = Player(source).state

				exports['sandbox-hud']:Notification(source, "info",
					"Locating Truck...",
					6000
				)

				local netId = SpawnBobcatTruck(`stockade`)

				if not netId then
					exports['sandbox-hud']:Notification(source, "error",
						"Unable To Locate A Truck",
						6000
					)
				else
					exports['sandbox-base']:LoggerInfo("Robbery",
						string.format("%s %s (%s) Used Fleeca Money Truck GPS Tracker", char:GetData("First"),
							char:GetData("Last"), char:GetData("SID")))
					exports["sandbox-base"]:ClientCallback(source, "Robbery:MoneyTruck:MarkTruck", netId, function(r)
						if r then
							exports.ox_inventory:RemoveSlot(slot.Owner, slot.Name, 1, slot.Slot, 1)
							exports['sandbox-hud']:Notification(source, "success",
								"A Truck Has Been Marked On Your GPS",
								6000
							)
						end
					end)
				end
			end
		else
			exports['sandbox-hud']:Notification(source, "error",
				"No Trucks Currently Available, Try Again Later",
				6000
			)
		end
	end)

	exports.ox_inventory:RegisterUse("bobcat_tracker", "BobcatRobbery", function(source, slot, itemData)
		if _truckSpawnEnabled then
			if #_moneyTruckSpawns == 0 then
				_moneyTruckSpawns = table.copy(_spawnHoldingShit)
			end

			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			if char ~= nil then
				local pState = Player(source).state

				exports['sandbox-hud']:Notification(source, "info",
					"Locating Truck...",
					6000
				)

				local netId = SpawnBobcatTruck(`stockade`)

				if not netId then
					exports['sandbox-hud']:Notification(source, "error",
						"Unable To Locate A Truck",
						6000
					)
				else
					exports['sandbox-base']:LoggerInfo("Robbery",
						string.format("%s %s (%s) Used Bobcat Money Truck GPS Tracker", char:GetData("First"),
							char:GetData("Last"), char:GetData("SID")))
					exports["sandbox-base"]:ClientCallback(source, "Robbery:MoneyTruck:MarkTruck", netId, function(r)
						if r then
							exports.ox_inventory:RemoveSlot(slot.Owner, slot.Name, 1, slot.Slot, 1)
							exports['sandbox-hud']:Notification(source, "success",
								"A Truck Has Been Marked On Your GPS",
								6000
							)
						end
					end)
				end
			end
		else
			exports['sandbox-hud']:Notification(source, "error",
				"No Trucks Currently Available, Try Again Later",
				6000
			)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:Bobcat:PickupC4", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local pState = Player(source).state

			if pState.inBobcat then
				if
					(
						not GlobalState["AntiShitlord"]
						or os.time() > GlobalState["AntiShitlord"]
						or GlobalState["BobcatInProgress"]
					)
					and not GlobalState["BobcatC4"]
					and GlobalState["Bobcat:ExtrDoor"]
					and GlobalState["Bobcat:FrontDoor"]
					and GlobalState["Bobcat:SecuredDoor"]
					and not GlobalState["Bobcat:Secured"]
				then
					if GetGameTimer() < BC_SERVER_START_WAIT or (GlobalState["RestartLockdown"] and not GlobalState["BobcatInProgress"]) then
						exports['sandbox-hud']:Notification(source, "error",
							"You Notice The Door Is Barricaded For A Storm, Maybe Check Back Later",
							6000
						)
						return
					elseif (GlobalState["Duty:police"] or 0) < BC_REQUIRED_POLICE and not GlobalState["BobcatInProgress"] then
						exports['sandbox-hud']:Notification(source, "error",
							"Enhanced Security Measures Enabled, Maybe Check Back Later When Things Feel Safer",
							6000
						)
						return
					elseif GlobalState["RobberiesDisabled"] then
						exports['sandbox-hud']:Notification(source, "error",
							"Temporarily Disabled, Please See City Announcements",
							6000
						)
						return
					end

					if not _bcInUse.grabC4 then
						_bcInUse.grabC4 = source
						if exports.ox_inventory:AddItem(char:GetData("SID"), "bobcat_charge", 1, {}, 1) then
							GlobalState["BobcatC4"] = char:GetData("SID")
							GlobalState["BobcatInProgress"] = true

							if not _bcGlobalReset then
								_bcGlobalReset = os.time() + BC_RESET_TIME
							end
						end
						_bcInUse.grabC4 = false
					else
						exports['sandbox-hud']:Notification(source, "error",
							"Someone Else Is Already Doing A Thing",
							6000
						)
					end
				end
			end
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:DoThermiteFx", function(source, data, cb)
		TriggerClientEvent("Robbery:Client:ThermiteFx", -1, data.delay or 13000, data.netId)
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:DoBombFx", function(source, data, cb)
		TriggerClientEvent("Robbery:Client:BombFx", source, data)
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:DoDetCordFx", function(source, data, cb)
		TriggerClientEvent("Robbery:Client:DetCordFx", -1, data)
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:DoDetCordFx", function(source, data, cb)
		TriggerClientEvent("Robbery:Client:DetCordFx", -1, data)
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:Bobcat:CheckLoot", function(source, data, cb)
		local pState = Player(source).state

		if
			pState.inBobcat
			and (not GlobalState["AntiShitlord"] or os.time() > GlobalState["AntiShitlord"] or GlobalState["BobcatInProgress"])
			and GlobalState["Bobcat:ExtrDoor"]
			and GlobalState["Bobcat:FrontDoor"]
			and GlobalState["Bobcat:SecuredDoor"]
			and GlobalState["Bobcat:VaultDoor"]
			and not GlobalState["Bobcat:Secured"]
			and not GlobalState[string.format("Bobcat:Loot:%s", data.id)]
			and _bobcatLootLocs[data.id] ~= nil
		then
			if not _bcInUse.loot[data.id] then
				GlobalState[string.format("Bobcat:Loot:%s", data.id)] = true
				_bcInUse.loot[data.id] = source
				cb(true)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:Bobcat:CancelLoot", function(source, data, cb)
		local pState = Player(source).state

		if
			pState.inBobcat
			and (not GlobalState["AntiShitlord"] or os.time() > GlobalState["AntiShitlord"] or GlobalState["BobcatInProgress"])
			and GlobalState["Bobcat:ExtrDoor"]
			and GlobalState["Bobcat:FrontDoor"]
			and GlobalState["Bobcat:SecuredDoor"]
			and GlobalState["Bobcat:VaultDoor"]
			and _bobcatLootLocs[data.id] ~= nil
		then
			if _bcInUse.loot[data.id] == source then
				GlobalState[string.format("Bobcat:Loot:%s", data.id)] = false
				_bcInUse.loot[data.id] = false
				cb(true)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:Bobcat:Loot", function(source, data, cb)
		local pState = Player(source).state

		if
			pState.inBobcat
			and (not GlobalState["AntiShitlord"] or os.time() > GlobalState["AntiShitlord"] or GlobalState["BobcatInProgress"])
			and GlobalState["Bobcat:ExtrDoor"]
			and GlobalState["Bobcat:FrontDoor"]
			and GlobalState["Bobcat:SecuredDoor"]
			and GlobalState["Bobcat:VaultDoor"]
			and not GlobalState["Bobcat:Secured"]
			and _bobcatLootLocs[data.id] ~= nil
		then
			if _bcInUse.loot[data.id] == source then
				local actualData = _bobcatLootLocs[data.id]
				if actualData.data.type == data.type then
					local char = exports['sandbox-characters']:FetchCharacterSource(source)
					if char ~= nil then
						local sid = char:GetData("SID")
						exports['sandbox-base']:LoggerInfo("Robbery",
							string.format("%s %s (%s) Looted Bobcat Loot Crate #%s", char:GetData("First"),
								char:GetData("Last"), sid, data.id))

						for i = 1, actualData.data.amount do
							exports.ox_inventory:LootCustomWeightedSetWithCount(_bobcatLootTable[data.type], sid,
								1)
						end
						if math.random(100) <= actualData.data.bonus then
							exports.ox_inventory:LootCustomWeightedSetWithCount(_bobcatLootTable[data.type], sid,
								1)
						end

						-- Only give schematic in 1 box
						if data.id == 1 then
							local t = deepcopy(_bobcatSchems)
							local schem = math.random(#t)
							while #t > 0 and exports.ox_inventory:CraftingSchematicsHasAny(sid, t[schem]) do
								table.remove(t, schem)
								if #t > 0 then
									schem = math.random(#t)
								else
									schem = 0
								end
							end

							if t[schem] ~= nil then
								exports.ox_inventory:AddItem(sid, t[schem], 1, {}, 1)
							else
								t = deepcopy(_bobcatC2Schems)
								schem = math.random(#t)
								while #t > 0 and exports.ox_inventory:CraftingSchematicsHasAny(sid, t[schem]) do
									table.remove(t, schem)
									if #t > 0 then
										schem = math.random(#t)
									else
										schem = 0
									end
								end

								if t[schem] ~= nil then
									exports.ox_inventory:AddItem(sid, t[schem], 1, {}, 1)
								else
									if not exports.ox_inventory:CraftingSchematicsHasAny(sid, "schematic_grapple_gun") then
										exports.ox_inventory:AddItem(sid, "schematic_grapple_gun", 1, {}, 1)
									else
										exports.ox_inventory:AddItem(sid,
											_bobcatCombined[math.random(#_bobcatCombined)], 1, {}, 1)
									end
								end
							end
						elseif data.id == 4 then
							local t = deepcopy(_bobcatAttchSchems)
							local schem = math.random(#t)
							while #t > 0 and exports.ox_inventory:CraftingSchematicsHasAny(sid, t[schem]) do
								table.remove(t, schem)
								schem = math.random(#t)
							end

							if t[schem] ~= nil then
								exports.ox_inventory:AddItem(sid, t[schem], 1, {}, 1)
							else
								exports.ox_inventory:AddItem(sid,
									_bobcatAttchSchems[math.random(#_bobcatAttchSchems)], 1, {}, 1)
							end
						end

						if not _bcGlobalReset then
							_bcGlobalReset = os.time() + BC_RESET_TIME
						end

						_bcInUse.loot[data.id] = false
					else
						_bcInUse.loot[data.id] = false
						cb(false)
					end
				else
					GlobalState[string.format("Bobcat:Loot:%s", data.id)] = true
					_bcInUse.loot[data.id] = false
					-- Not a very smart person trying to cheat :)
					cb(false)
				end
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:Bobcat:Secure", function(source, data, cb)
		local pState = Player(source).state
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			if pState.onDuty == "police" then
				exports['sandbox-base']:LoggerInfo("Robbery",
					string.format("%s %s (%s) Secured Bobcat Security", char:GetData("First"), char:GetData("Last"),
						char:GetData("SID")))
				SecureBobcat()
				exports['sandbox-hud']:Notification(source, "success", "Building Secure", 6000)
			end
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:Bobcat:CheckFrontPC", function(source, data, cb)
		if not _bcInUse.frontPc and not GlobalState["Bobcat:PCHacked"] then
			_bcInUse.frontPc = source
			cb({
				passes = 3,
				config = {
					preview = 3,
					timer = 1500,
					limit = 15000,
					difficulty = 4,
					difficulty2 = 2,
					anim = {
						anim = "type",
					},
				},
				data = {},
			})
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Robbery:Bobcat:FrontPCResults", function(source, data, cb)
		if _bcInUse.frontPc == source and not GlobalState["Bobcat:PCHacked"] then
			if data?.state then
				local char = exports['sandbox-characters']:FetchCharacterSource(source)
				if char ~= nil then
					if exports.ox_inventory:AddItem(char:GetData("SID"), "bobcat_tracker", 1, {}, 1) then
						_bcInUse.frontPc = false
						GlobalState["Bobcat:PCHacked"] = true
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
		else
			cb(false)
		end
	end)

	-- exports["sandbox-base"]:RegisterServerCallback("Robbery:Bobcat:CheckSecurityPC", function(source, data, cb)
	-- 	if not _bcInUse.securityPc and not GlobalState["Bobcat:SecurityPCHacked"] then
	-- 		_bcInUse.securityPc = source
	-- 		cb({
	-- 			passes = 3,
	-- 			config = {
	-- 				preview = 3,
	-- 				timer = 1500,
	-- 				limit = 15000,
	-- 				difficulty = 4,
	-- 				difficulty2 = 2,
	-- 				anim = {
	-- 					anim = "type",
	-- 				},
	-- 			},
	-- 			data = {},
	-- 		})
	-- 	else
	-- 		cb(false)
	-- 	end
	-- end)

	-- exports["sandbox-base"]:RegisterServerCallback("Robbery:Bobcat:SecurityPCResults", function(source, data, cb)
	-- 	if _bcInUse.frontPc == source and not GlobalState["Bobcat:SecurityPCHacked"] then
	-- 		if data then
	-- 			local plyr = exports['sandbox-base']:FetchSource(source)
	-- 			if plyr ~= nil then
	-- 				local char = plyr:GetData("Character")
	-- 				if char ~= nil then
	-- 					if exports.ox_inventory:AddItem(char:GetData("SID"), "moneytruck_map", 1, {}, 1) then
	-- 						_bcInUse.securityPc = false
	-- 						GlobalState["Bobcat:SecurityPCHacked"] = true
	-- 					end
	-- 				else
	-- 					cb(false)
	-- 				end
	-- 			else
	-- 				cb(false)
	-- 			end
	-- 		else
	-- 			cb(false)
	-- 		end
	-- 	else
	-- 		cb(false)
	-- 	end
	-- end)
end)

AddEventHandler("Characters:Server:PlayerLoggedOut", RemoveC4)
AddEventHandler("Characters:Server:PlayerDropped", RemoveC4)

function SecureBobcat()
	exports['ox_doorlock']:SetLock("bobcat_inner", true)
	GlobalState["Bobcat:SecuredDoor"] = false
	GlobalState["BobcatInProgress"] = false
	GlobalState["Bobcat:Secured"] = true

	if not _bcGlobalReset then
		_bcGlobalReset = os.time() + BC_RESET_TIME
	end

	exports['ox_doorlock']:SetLock("bobcat_front", true)
	exports['ox_doorlock']:SetLock("bobcat_inner", true)

	for k, v in ipairs(_bobcatPeds) do
		local ent = NetworkGetEntityFromNetworkId(v)
		if ent ~= 0 then
			DeleteEntity(ent)
		end
	end
	_bobcatPeds = {}
	_pedsSpawned = false

	for k, v in pairs(_bcInUse) do
		if k ~= 'loot' then
			_bcInUse[v] = false
		else
			for k2, v2 in pairs(v) do
				_bcInUse[k][k2] = false
			end
		end
	end
end

function ResetBobcat()
	exports['ox_doorlock']:SetLock("bobcat_extr", true)
	exports['ox_doorlock']:SetLock("bobcat_front", true)
	exports['ox_doorlock']:SetLock("bobcat_inner", true)

	GlobalState["Bobcat:ExtrDoor"] = false
	GlobalState["Bobcat:FrontDoor"] = false
	GlobalState["Bobcat:SecuredDoor"] = false
	GlobalState["Bobcat:VaultDoor"] = false

	for k, v in ipairs(_bobcatLootLocs) do
		GlobalState[string.format("Bobcat:Loot:%s", v.data.id)] = false
	end

	GlobalState["Bobcat:Secured"] = false
	GlobalState["BobcatInProgress"] = false

	for k, v in ipairs(_bobcatPeds) do
		local ent = NetworkGetEntityFromNetworkId(v)
		if ent ~= 0 then
			DeleteEntity(ent)
		end
	end
	_bobcatPeds = {}
	_pedsSpawned = false
	_bcGlobalReset = nil

	TriggerClientEvent("Robbery:Client:Bobcat:UpdateIPL", -1, false)
end

function RemoveC4(source, cData)
	if cData ~= nil then
		exports.ox_inventory:RemoveAll(cData.SID, 1, "bobcat_charge")
		if GlobalState["BobcatC4"] == cData.SID then
			GlobalState["BobcatC4"] = false
		end
		return true
	end
end

-- -- TODO: OPTIMIZE THIS CODE.

-- -- This variable will store a small table for each player that just contains the vehicle entity and
-- -- the ped.
-- local plyStates = {}
-- local spawned = false
-- local debug = false

-- -- This event handler just sets the spawned variable to true, as it is used further down to allow
-- -- the player checks thread to run.
-- AddEventHandler("Characters:Client:Spawn", function()
-- 	Wait(500)
-- 	if not spawned then
-- 		spawned = true
-- 	end
-- end)

-- CreateThread(function()
-- 	Wait(500)
-- 	if debug then
-- 		spawned = true
-- 	end
-- end)

-- -- This function manages the check that runs on each player, it checks if the vehicle is stopped
-- -- and the vehicle's engine is running, then sets a decorator on the vehicle entity.
-- function ManagePlayerChecks()
-- 	-- Get all of the ids for the currently active players
-- 	local ids = GetActivePlayers()

-- 	-- Iterate through all of the ids
-- 	for k, v in pairs(ids) do
-- 		-- Create a player table in the plyStates table if one doesn't exist
-- 		if not plyStates[k] then
-- 			plyStates[k] = {}
-- 		end

-- 		-- Here we get the player's ped, you might think we should just grab the ped once and cache
-- 		-- it in the table, but there are chances that the player's ped would change such as with
-- 		-- multiple character systems. If it were cached, we would need to get the ped again anyway
-- 		-- to check if it had changed.
-- 		plyStates[k].ped = GetPlayerPed(v)

-- 		-- Check that the actual ped exists and isn't dead
-- 		if DoesEntityExist(plyStates[k].ped) and not IsEntityDead(plyStates[k].ped) then
-- 			-- Get the vehicle the ped is in
-- 			local veh = GetVehiclePedIsIn(plyStates[k].ped, false)

-- 			-- Make sure the player is in the drivers seat
-- 			if GetPedInVehicleSeat(veh, -1) then
-- 				--[[ Get the boolean state of whether to show the brake lights.
--                         - The engine of the vehicle is on
--                         - The entity speed is less than 0.1
--                         - The handbrake is not on ]]
-- 				local state = GetIsVehicleEngineRunning(veh)
-- 					and GetEntitySpeed(veh) < 0.1
-- 					and (not GetVehicleHandbrake(veh))

-- 				-- Set the decorator on the vehicle
-- 				DecorSetBool(veh, "brakeLights", state)

-- 				-- Store the vehicle entity in the table
-- 				plyStates[k].veh = veh
-- 			end
-- 		end
-- 	end
-- end

-- -- This function iterates through all of the vehicles and activates the brakr lights
-- function DisplayBrakeLights()
-- 	-- Iterate through the plyStates table
-- 	for k, v in pairs(plyStates) do
-- 		-- Check the vehicle actually exists and the current ped is the driver
-- 		if DoesEntityExist(v.veh) and GetPedInVehicleSeat(v.veh, -1) == v.ped then
-- 			-- Get the decorator value we set previously on the vehicle
-- 			local displayLights = DecorGetBool(v.veh, "brakeLights")

-- 			-- Activate the brake lights!
-- 			if displayLights then
-- 				SetVehicleBrakeLights(v.veh, true)
-- 			end
-- 		end
-- 	end
-- end

-- -- This thread is responsible for running the check function, it also only runs 2 times
-- -- a second to reduce native invocation.
-- CreateThread(function()
-- 	-- Here we wait until the player has actually spawned, if we don't then the decorator
-- 	-- bugs out and doesn't register.
-- 	while not spawned do
-- 		Wait(100)
-- 	end

-- 	-- Register the custom decorator for the brake lights
-- 	DecorRegister("brakeLights", 2)

-- 	while true do
-- 		ManagePlayerChecks()

-- 		Wait(500)
-- 	end
-- end)

-- -- This thread is responsible for displaying the brake lights
-- CreateThread(function()
-- 	while true do
-- 		DisplayBrakeLights()

-- 		Wait(0)
-- 	end
-- end)
-- pepega

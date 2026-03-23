local _sounds = {}

RegisterNUICallback("SoundEnd", function(data, cb)
	exports['sandbox-base']:LoggerTrace("Sounds", ("^2Stopping Sound %s For ID %s^7"):format(data.file, data.source))
	if _sounds[data.source] ~= nil and _sounds[data.source][data.file] ~= nil then
		_sounds[data.source][data.file] = nil
	end
end)

local function toVec3(v)
    if not v then return nil end

    -- if someone sent coords as json string
    if type(v) == 'string' then
        local ok, decoded = pcall(json.decode, v)
        if ok and decoded then
            v = decoded
        end
    end

    -- if someone sent coords as table {x=..., y=..., z=...}
    if type(v) == 'table' then
        local x, y, z = v.x, v.y, v.z
        if x and y and z then
            return vector3(tonumber(x) or 0.0, tonumber(y) or 0.0, tonumber(z) or 0.0)
        end
    end

    -- if already a vector3, just return it
    return v
end

exports("PlayOne", function(soundFile, soundVolume)
	exports['sandbox-base']:LoggerTrace("Sounds", ("^2Playing Sound %s On Client Only^7"):format(soundFile))
	_sounds[LocalPlayer.state.ID] = _sounds[LocalPlayer.state.ID] or {}
	_sounds[LocalPlayer.state.ID][soundFile] = {
		file = soundFile,
		volume = soundVolume,
	}
	SendNUIMessage({
		action = "playSound",
		source = LocalPlayer.state.ID,
		file = soundFile,
		volume = soundVolume,
	})
end)

exports("PlayDistance", function(maxDistance, soundFile, soundVolume)
	exports["sandbox-base"]:ServerCallback("Sounds:Play:Distance", {
		maxDistance = maxDistance,
		soundFile = soundFile,
		soundVolume = soundVolume,
	})
end)

exports("PlayLocation", function(location, maxDistance, soundFile, soundVolume)
	exports["sandbox-base"]:ServerCallback("Sounds:Play:Location", {
		location = location,
		maxDistance = maxDistance,
		soundFile = soundFile,
		soundVolume = soundVolume,
	})
end)

exports("LoopOne", function(soundFile, soundVolume)
	exports['sandbox-base']:LoggerTrace("Sounds", ("^2Looping Sound %s On Client Only^7"):format(soundFile))
	_sounds[LocalPlayer.state.ID] = _sounds[LocalPlayer.state.ID] or {}
	_sounds[LocalPlayer.state.ID][soundFile] = {
		file = soundFile,
		volume = soundVolume,
		distance = maxDistance,
	}
	SendNUIMessage({
		action = "loopSound",
		source = LocalPlayer.state.ID,
		file = soundFile,
		volume = soundVolume,
	})
end)

exports("LoopDistance", function(maxDistance, soundFile, soundVolume)
	exports["sandbox-base"]:ServerCallback("Sounds:Loop:Distance", {
		maxDistance = maxDistance,
		soundFile = soundFile,
		soundVolume = soundVolume,
	})
end)

exports("LoopLocation", function(a, b, c, d, e)
    local key, location, maxDistance, soundFile, soundVolume

    -- LoopLocation(key, location, maxDistance, file, vol)
    if type(a) == "string" then
        key = a
        location = b
        maxDistance = c
        soundFile = d
        soundVolume = e
    else
        -- LoopLocation(location, maxDistance, file, vol)
        key = nil
        location = a
        maxDistance = b
        soundFile = c
        soundVolume = d
    end

    local loc = toVec3(location)
    if not loc then return end

    exports["sandbox-base"]:ServerCallback("Sounds:Loop:Location", {
        playerNetId = key, -- ✅ use key
        location = { x = loc.x, y = loc.y, z = loc.z },
        maxDistance = tonumber(maxDistance) or 0.0,
        soundFile = soundFile,
        soundVolume = tonumber(soundVolume) or 0.0,
    })
end)

exports("StopOne", function(soundFile)
	exports['sandbox-base']:LoggerTrace("Sounds", ("^2Stopping Sound %s On Client^7"):format(soundFile))
	if _sounds[LocalPlayer.state.ID] ~= nil and _sounds[LocalPlayer.state.ID][soundFile] ~= nil then
		_sounds[LocalPlayer.state.ID][soundFile] = nil
		SendNUIMessage({
			action = "stopSound",
			source = LocalPlayer.state.ID,
			file = soundFile,
		})
	end
end)

exports("StopDistance", function(pNet, soundFile)
    exports["sandbox-base"]:ServerCallback("Sounds:Stop:Distance", {
        playerNetId = pNet,
        soundFile = soundFile,
    })
end)

exports("StopLocation", function(pNet, soundFile)
    exports["sandbox-base"]:ServerCallback("Sounds:Stop:Distance", {
        playerNetId = pNet,
        soundFile = soundFile,
    })
end)

exports("FadeOne", function(soundFile)
	exports['sandbox-base']:LoggerTrace("Sounds", ("^2Stopping Sound %s On Client^7"):format(soundFile))
	if _sounds[LocalPlayer.state.ID] ~= nil and _sounds[LocalPlayer.state.ID][soundFile] ~= nil then
		_sounds[LocalPlayer.state.ID][soundFile] = nil
		SendNUIMessage({
			action = "fadeSound",
			source = LocalPlayer.state.ID,
			file = soundFile,
		})
	end
end)

function DoPlayDistance(playerNetId, maxDistance, soundFile, soundVolume)
	playerNetId = tonumber(playerNetId)
	exports['sandbox-base']:LoggerTrace(
		("^2Playing Sound %s Once Per Request From %s For Distance %s^7"):format(
			soundFile,
			playerNetId,
			maxDistance
		)
	)

	local pPed = PlayerPedId()
	local isFromMe = false
	local tPlayer = GetPlayerFromServerId(playerNetId)
	local tPed = GetPlayerPed(tPlayer)

	if playerNetId == LocalPlayer.state.ID then
		isFromMe = true
		tPed = LocalPlayer.state.ped
	end

	local distIs = #(GetEntityCoords(pPed) - GetEntityCoords(tPed))
	local vol = soundVolume * (1.0 - (distIs / maxDistance))
	if isFromMe then
		vol = soundVolume
	elseif
		(tPed ~= 0 and distIs > maxDistance)
		or (tPed == 0)
		or not LocalPlayer.state.loggedIn
		or (tPlayer == -1)
	then
		vol = 0
	end

	_sounds[playerNetId] = _sounds[playerNetId] or {}
	_sounds[playerNetId][soundFile] = {
		file = soundFile,
		volume = soundVolume,
		distance = maxDistance,
	}
	SendNUIMessage({
		action = "playSound",
		source = playerNetId,
		file = soundFile,
		volume = vol,
	})

	CreateThread(function()
		while _sounds[playerNetId] ~= nil and _sounds[playerNetId][soundFile] ~= nil do
			tPlayer = GetPlayerFromServerId(playerNetId)
			tPed = GetPlayerPed(tPlayer)

			local distIs = #(GetEntityCoords(pPed) - GetEntityCoords(tPed))
			vol = soundVolume * (1.0 - (distIs / maxDistance))

			if isFromMe then
				vol = soundVolume
			elseif
				(tPed ~= 0 and distIs > maxDistance)
				or (tPed == 0)
				or not LocalPlayer.state.loggedIn
				or (tPlayer == -1)
			then
				vol = 0
			end

			SendNUIMessage({
				action = "updateVol",
				source = playerNetId,
				file = soundFile,
				volume = vol,
			})
			Wait(100)
		end
	end)
end

function DoPlayLocation(playerNetId, location, maxDistance, soundFile, soundVolume)
	exports['sandbox-base']:LoggerTrace(
		("^2Playing Sound %s Once Per Request From %s at location %s For Distance %s^7"):format(
			soundFile,
			playerNetId,
			json.encode(location),
			maxDistance
		)
	)
	local distIs = #(
		vector3(LocalPlayer.state.myPos.x, LocalPlayer.state.myPos.y, LocalPlayer.state.myPos.z)
		- vector3(location.x, location.y, location.z)
	)
	local vol = soundVolume * (1.0 - (distIs / maxDistance))
	if distIs > maxDistance then
		vol = 0
	end
	_sounds[playerNetId] = _sounds[playerNetId] or {}
	_sounds[playerNetId][soundFile] = {
		file = soundFile,
		volume = soundVolume,
		distance = maxDistance,
	}
	SendNUIMessage({
		action = "playSound",
		source = playerNetId,
		file = soundFile,
		volume = vol,
	})

	CreateThread(function()
		while _sounds[playerNetId] ~= nil and _sounds[playerNetId][soundFile] ~= nil do
			local distIs = #(
				vector3(LocalPlayer.state.myPos.x, LocalPlayer.state.myPos.y, LocalPlayer.state.myPos.z)
				- vector3(location.x, location.y, location.z)
			)
			vol = soundVolume * (1.0 - (distIs / maxDistance))
			if distIs > maxDistance then
				vol = 0
			end
			SendNUIMessage({
				action = "updateVol",
				source = playerNetId,
				file = soundFile,
				volume = vol,
			})
			Wait(100)
		end
	end)
end

function DoLoopDistance(playerNetId, maxDistance, soundFile, soundVolume)
	exports['sandbox-base']:LoggerTrace(
		("^2Looping Sound %s Per Request From %s For Distance %s^7"):format(soundFile, playerNetId, maxDistance)
	)

	local isFromMe = false
	local pPed = PlayerPedId()

	local tPlayer = GetPlayerFromServerId(playerNetId)
	local tPed = GetPlayerPed(tPlayer)

	if playerNetId == LocalPlayer.state.ID then
		isFromMe = true
		tPed = LocalPlayer.state.ped
	end

	local distIs = #(GetEntityCoords(pPed) - GetEntityCoords(tPed))
	local vol = soundVolume * (1.0 - (distIs / maxDistance))
	if isFromMe then
		vol = soundVolume
	elseif
		(tPed ~= 0 and distIs > maxDistance)
		or tPed == 0
		or not LocalPlayer.state.loggedIn
		or (tPlayer == -1)
	then
		vol = 0
	end

	_sounds[playerNetId] = _sounds[playerNetId] or {}
	_sounds[playerNetId][soundFile] = {
		file = soundFile,
		volume = soundVolume,
		distance = maxDistance,
	}
	SendNUIMessage({
		action = "loopSound",
		source = playerNetId,
		file = soundFile,
		volume = vol,
	})

	CreateThread(function()
		while _sounds[playerNetId] ~= nil and _sounds[playerNetId][soundFile] ~= nil do
			tPlayer = GetPlayerFromServerId(playerNetId)
			tPed = GetPlayerPed(tPlayer)

			local distIs = #(GetEntityCoords(pPed) - GetEntityCoords(tPed))
			vol = soundVolume * (1.0 - (distIs / maxDistance))

			if isFromMe then
				vol = soundVolume
			elseif
				(tPed ~= 0 and distIs > maxDistance)
				or tPed == 0
				or not LocalPlayer.state.loggedIn
				or (tPlayer == -1)
			then
				vol = 0
			end

			SendNUIMessage({
				action = "updateVol",
				source = playerNetId,
				file = soundFile,
				volume = vol,
			})
			Wait(100)
		end
	end)
end

function DoLoopLocation(playerNetId, location, maxDistance, soundFile, soundVolume)
    location = toVec3(location)
    maxDistance = tonumber(maxDistance) or 0.0
    soundVolume = tonumber(soundVolume) or 0.0

    if not location then return end

    exports['sandbox-base']:LoggerTrace(
        ("^2Looping Sound %s Per Request From %s at location %s For Distance %s^7"):format(
            soundFile,
            playerNetId,
            json.encode(location),
            maxDistance
        )
    )

    local ped = PlayerPedId()
    local distIs = #(GetEntityCoords(ped) - location)
    local vol = soundVolume * (1.0 - (distIs / maxDistance))
    if distIs > maxDistance then vol = 0 end

    _sounds[playerNetId] = _sounds[playerNetId] or {}
    _sounds[playerNetId][soundFile] = { file = soundFile, volume = soundVolume, distance = maxDistance }

    SendNUIMessage({ action = "loopSound", source = playerNetId, file = soundFile, volume = vol })

    CreateThread(function()
        while _sounds[playerNetId] and _sounds[playerNetId][soundFile] do
            local distIs2 = #(GetEntityCoords(PlayerPedId()) - location)
            local vol2 = soundVolume * (1.0 - (distIs2 / maxDistance))
            if distIs2 > maxDistance or not LocalPlayer.state.loggedIn then vol2 = 0 end

            SendNUIMessage({ action = "updateVol", source = playerNetId, file = soundFile, volume = vol2 })
            Wait(100)
        end
    end)
end

function DoStopDistance(playerNetId, soundFile)
	exports['sandbox-base']:LoggerTrace("Sounds",
		("^2Stopping Sound %s Per Request From %s^7"):format(soundFile, playerNetId))
	if _sounds[playerNetId] ~= nil and _sounds[playerNetId][soundFile] ~= nil then
		_sounds[playerNetId][soundFile] = nil
		SendNUIMessage({
			action = "stopSound",
			source = playerNetId,
			file = soundFile,
		})
	end
end

RegisterNetEvent("Sounds:Client:DoLoopLocation", function(playerNetId, location, maxDistance, soundFile, soundVolume)
    -- convert location to vector3
    if type(location) == 'string' then
        local ok, decoded = pcall(json.decode, location)
        if ok and decoded then location = decoded end
    end
    if type(location) == 'table' then
        location = vector3(tonumber(location.x) or 0.0, tonumber(location.y) or 0.0, tonumber(location.z) or 0.0)
    end

    DoLoopLocation(playerNetId, location, tonumber(maxDistance) or 0.0, soundFile, tonumber(soundVolume) or 0.0)
end)

RegisterNetEvent("Sounds:Client:Play:One", function(playerNetId, soundFile, soundVolume)
	DoPlayDistance(playerNetId, soundFile, soundVolume)
end)

RegisterNetEvent("Sounds:Client:Play:Distance", function(playerNetId, maxDistance, soundFile, soundVolume)
	DoPlayDistance(playerNetId, maxDistance, soundFile, soundVolume)
end)

RegisterNetEvent("Sounds:Client:Play:Location", function(playerNetId, location, maxDistance, soundFile, soundVolume)
	DoPlayLocation(playerNetId, location, maxDistance, soundFile, soundVolume)
end)

RegisterNetEvent("Sounds:Client:Loop:One", function(soundFile, soundVolume)
	exports['sandbox-base']:LoggerTrace("Sounds", ("^2Looping Sound %s On Client Only^7"):format(soundFile))
	_sounds[LocalPlayer.state.ID] = _sounds[LocalPlayer.state.ID] or {}
	_sounds[LocalPlayer.state.ID][soundFile] = {
		file = soundFile,
		volume = soundVolume,
		distance = maxDistance,
	}
	SendNUIMessage({
		action = "loopSound",
		source = LocalPlayer.state.ID,
		file = soundFile,
		volume = soundVolume,
	})
end)

RegisterNetEvent("Sounds:Client:Loop:Distance", function(playerNetId, maxDistance, soundFile, soundVolume)
	DoLoopDistance(playerNetId, maxDistance, soundFile, soundVolume)
end)

RegisterNetEvent("Sounds:Client:Loop:Location", function(playerNetId, location, maxDistance, soundFile, soundVolume)
	DoLoopLocation(playerNetId, location, maxDistance, soundFile, soundVolume)
end)

RegisterNetEvent("Sounds:Client:Stop:One", function(soundFile)
	exports['sandbox-base']:LoggerTrace("Sounds", ("^2Stopping Sound %s On Client^7"):format(soundFile))
	if _sounds[LocalPlayer.state.ID] ~= nil and _sounds[LocalPlayer.state.ID][soundFile] ~= nil then
		_sounds[LocalPlayer.state.ID][soundFile] = nil
		SendNUIMessage({
			action = "stopSound",
			source = LocalPlayer.state.ID,
			file = soundFile,
		})
	end
end)

RegisterNetEvent("Sounds:Client:Stop:Distance", function(playerNetId, soundFile)
	DoStopDistance(playerNetId, soundFile)
end)

RegisterNetEvent("Sounds:Client:Stop:All", function(playerNetId, soundFile)
	if _sounds[playerNetId] ~= nil then
		for k, v in pairs(_sounds[playerNetId]) do
			DoStopDistance(playerNetId, v)
		end
		_sounds[playerNetId] = nil
	end
end)

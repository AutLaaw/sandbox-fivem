_pickups = {}

local _jobcheck = {
	police = true,
	ems = true,
	government = true,
}

local _queues = {
	{
		id = "green_dongle",
		state = "DONGLE_GREEN",
		name = "Green Laptop",
		result = "green_laptop",
		wait = 60,
		first = 30,
		limited = false,
	},
	{
		id = "blue_dongle",
		state = "DONGLE_BLUE",
		name = "Blue Laptop",
		result = "blue_laptop",
		wait = 60,
		first = 0,
		limited = true,
	},
	{
		id = "red_dongle",
		state = "DONGLE_RED",
		name = "Red Laptop",
		result = "red_laptop",
		wait = 60,
		first = 15,
		limited = true,
	},
	{
		id = "purple_dongle",
		state = "DONGLE_PURPLE",
		name = "Purple Laptop",
		result = "purple_laptop",
		wait = 90,
		first = 45,
		limited = true,
	},
	{
		id = "yellow_dongle",
		state = "DONGLE_YELLOW",
		name = "Yellow Laptop",
		result = "yellow_laptop",
		wait = 90,
		first = 30,
		limited = true,
	},
}

local _received = {}

function HasPickup(sid, receiving)
	if _pickups[sid] ~= nil then
		for k, v in ipairs(_pickups[sid]) do
			if v.receiving == receiving then
				return true
			end
		end
		return false
	else
		return false
	end
end

local _awarded = {}
function SetupQueues()
	CreateThread(function()
		for k, v in ipairs(_queues) do
			_received[v.id] = {}

			exports['sandbox-base']:TasksRegister(v.id, v.wait, function(data)
				-- Don't Do Queue Stuff If Restart Lockdown Has Started
				if GlobalState["RestartLockdown"] or (data.limited and _awarded[data.id]) then
					return
				end

				local sources = GetPlayers()

				local char = nil
				while char == nil and #sources > 0 do
					local index = math.random(#sources)
					local src = tonumber(sources[index])

					char = exports['sandbox-characters']:FetchCharacterSource(src)
					if char ~= nil then
						local pState = Player(src).state

						if not _jobcheck[pState.onDuty] then
							local states = char:GetData("States") or {}
							if
								_received[v.id][char:GetData("SID")]
								or not hasValue(states, data.state)
								or HasPickup(char:GetData("SID"), data.receiving)
							then
								char = nil
							else
								_received[v.id][char:GetData("SID")] = true
								_pickups[char:GetData("SID")] = _pickups[char:GetData("SID")] or {}
							end
						else
							char = nil
						end
					end

					if char == nil then
						table.remove(sources, index)
					end
				end

				if char ~= nil then
					exports['sandbox-base']:LoggerInfo(
						"Robbery Queue",
						string.format(
							"%s %s (%s) Was Chosen For ^3%s^7",
							char:GetData("First"),
							char:GetData("Last"),
							char:GetData("SID"),
							v.name
						)
					)

					exports['sandbox-phone']:EmailSend(
						char:GetData("Source"),
						"unknown@sandboxrp.gg",
						os.time(),
						string.format("You Were Chosen For A %s", v.name),
						string.format(
							[[
							Hello %s<br /><br />
							Congratulations, you were chosen to receive a %s. Please head to Digital Den in the Boring Shopping Mall before tsunami to pick up your item.
						]],
							char:GetData("First"),
							v.name
						)
					)

					table.insert(_pickups[char:GetData("SID")], {
						giving = data.id,
						receiving = data.result,
					})
					_awarded[data.id] = true
				else
					exports['sandbox-base']:LoggerInfo("Robbery Queue",
						string.format("No Eligible Player Found For ^3%s^7", v.name))
				end
			end, v, (v.wait - v.first))
		end
	end)
end

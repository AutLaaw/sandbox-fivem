local _groups = {}
local _invites = {}

local _groupData = {}
local _groupsOnline = {}
local _channelCounts = {}

AddEventHandler("Characters:Server:PlayerLoggedOut", function(source, cData)
	if _groups[cData.SID] ~= nil then
		for k, v in ipairs(_groups[cData.SID]) do
			_groupsOnline[v.id] = _groupsOnline[v.id] or {}
			_groupsOnline[v.id][source] = nil
		end

		_groups[cData.SID] = nil
	end
end)

AddEventHandler("Characters:Server:PlayerDropped", function(source, cData)
	if _groups[cData.SID] ~= nil then
		for k, v in ipairs(_groups[cData.SID]) do
			_groupsOnline[v.id] = _groupsOnline[v.id] or {}
			_groupsOnline[v.id][source] = nil
		end

		_groups[cData.SID] = nil
	end
end)

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	exports['sandbox-base']:MiddlewareAdd("Characters:Spawning", function(source)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		local alias = char:GetData("Alias")
		if alias.irc then
			alias.irc = nil
			char:SetData("Alias", alias)
		end
	end, 1)

	exports['sandbox-base']:MiddlewareAdd("Characters:Spawning", function(source)
		local sid = exports['sandbox-characters']:FetchCharacterSource(source):GetData("SID")
		_groups[sid] = MySQL.query.await(
			"SELECT g.id, g.label, g.icon, g.owner, cg.joined_date, (SELECT UNIX_TIMESTAMP(MAX(m.timestamp)) AS timestamp FROM chatter_messages m WHERE m.group = cg.chatty_group) as last_message FROM character_chatter_groups cg INNER JOIN chatter_groups g ON g.id = cg.chatty_group WHERE cg.sid = ?",
			{
				sid,
			}
		) or {}

		for k, v in ipairs(_groups[sid]) do
			_groupsOnline[v.id] = _groupsOnline[v.id] or {}
			_groupsOnline[v.id][source] = sid

			if not _groupData[v.id] then
				_groupData[v.id] = {
					label = v.label,
					icon = v.icon,
				}
			end
		end

		TriggerLatentClientEvent("Phone:Client:Chatter:SetGroups", source, 50000, _groups[sid])
		TriggerLatentClientEvent("Phone:Client:Chatter:SetInvites", source, 50000, _invites[sid])
	end)
end)

AddEventHandler("Phone:Server:RegisterCallbacks", function()
	exports["sandbox-base"]:RegisterServerCallback("Phone:Chatter:GetMessageCount", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local sid = char:GetData("SID")
			if _groups[sid] ~= nil then
				local joined = false
				for k, v in ipairs(_groups[sid]) do
					if v.id == data then
						joined = v.joined_date
						break
					end
				end

				if joined then
					local c = MySQL.scalar.await(
						"SELECT COUNT(id) as count FROM chatter_messages m WHERE m.group = ? AND m.timestamp >= FROM_UNIXTIME(?)",
						{
							data,
							math.ceil(joined) / 1000,
						}
					)
					cb(c)
				else
					cb(0)
				end
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Phone:Chatter:LoadMessages", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local sid = char:GetData("SID")
			if _groups[sid] ~= nil then
				local joined = false
				for k, v in ipairs(_groups[sid]) do
					if v.id == data.channel then
						joined = v.joined_date
						break
					end
				end

				if joined then
					local msg = MySQL.rawExecute.await(
						"SELECT m.id, m.message, UNIX_TIMESTAMP(m.timestamp) as timestamp, m.author FROM chatter_messages m WHERE m.group = ? AND m.timestamp >= FROM_UNIXTIME(?) ORDER BY timestamp DESC LIMIT 25 OFFSET ?",
						{
							data.channel,
							math.ceil(joined) / 1000,
							data.offset,
						}
					)

					cb(msg)
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

	exports["sandbox-base"]:RegisterServerCallback("Phone:Chatter:SendMessage", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local sid = char:GetData("SID")
			if _groups[sid] ~= nil then
				local inGroup = false
				for k, v in ipairs(_groups[sid]) do
					if v.id == data.channel then
						inGroup = true
						break
					end
				end

				if inGroup then
					local timestamp = os.time()

					local id = MySQL.insert.await(
						"INSERT INTO chatter_messages (`group`, `author`, `message`) VALUES(?, ?, ?)",
						{
							data.channel,
							sid,
							data.message,
						}
					)

					_groupData[data.channel].last_message = timestamp

					if _groupsOnline[data.channel] ~= nil then
						for k, v in pairs(_groupsOnline[data.channel]) do
							if k ~= source then
								TriggerClientEvent("Phone:Client:Chatter:Notify", k, {
									group = data.channel,
									author = sid,
									message = data.message,
									timestamp = timestamp,
								}, _groupData[data.channel])
							end
						end
					end

					cb(id ~= nil)
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

	exports["sandbox-base"]:RegisterServerCallback("Phone:Chatter:CreateGroup", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local sid = char:GetData("SID")
			local ts = os.time()

			local gId = MySQL.query.await("INSERT INTO chatter_groups (label, owner) VALUES(?, ?)", {
				data.label,
				sid,
			})

			MySQL.query.await("INSERT INTO character_chatter_groups (sid, chatty_group) VALUES(?, ?)", {
				sid,
				gId.insertId,
			})

			_groups[sid] = _groups[sid] or {}
			table.insert(_groups[sid], {
				id = gId.insertId,
				label = data.label,
				icon = nil,
				owner = sid,
				joined_date = ts,
				last_message = nil,
			})
			_groupsOnline[gId.insertId] = {
				[source] = sid,
			}
			_groupData[gId.insertId] = {
				id = gId.insertId,
				label = data.label,
				icon = nil,
			}

			cb({
				id = gId.insertId,
				create_date = ts,
			})
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Phone:Chatter:LeaveGroup", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local sid = char:GetData("SID")
			MySQL.query.await("DELETE FROM character_chatter_groups WHERE sid = ? AND chatty_group = ?", {
				char:GetData("SID"),
				data,
			})

			if _groupsOnline[data] ~= nil then
				_groupsOnline[data][source] = nil
			end

			if _groups[sid] ~= nil then
				for k, v in ipairs(_groups[sid]) do
					if v.id == data then
						table.remove(_groups[sid], k)
						break
					end
				end
			end

			cb(data)
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Phone:Chatter:DeleteGroup", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local sid = char:GetData("SID")

			if _groups[sid] then
				local inGroup = false
				for k, v in ipairs(_groups[sid]) do
					if v.id == data then
						inGroup = v
						break
					end
				end

				if inGroup then
					if inGroup.owner and inGroup.owner == sid then
						local queries = {}

						table.insert(queries, {
							query = "DELETE FROM character_chatter_groups WHERE chatty_group = ?",
							values = {
								data,
							},
						})
						table.insert(queries, {
							query = "DELETE FROM chatter_messages WHERE `group` = ?",
							values = {
								data,
							},
						})
						table.insert(queries, {
							query = "DELETE FROM chatter_groups WHERE id = ?",
							values = {
								data,
							},
						})

						MySQL.transaction(queries)

						if _groupsOnline[data] ~= nil then
							for k, v in pairs(_groupsOnline[data]) do
								if k ~= source then
									TriggerClientEvent("Phone:Client:Chatter:GroupDeleted", k, data)
								end
							end
							_groupsOnline[data] = nil
						end

						for k, v in pairs(_groups) do
							for k2, v2 in ipairs(v) do
								if v2.id == data then
									table.remove(_groups[k], k2)
									break
								end
							end
						end

						_groupData[data] = nil

						cb(data)
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

	exports["sandbox-base"]:RegisterServerCallback("Chatter:Invite:Send", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local sid = char:GetData("SID")

			if tonumber(data.sid) ~= sid then
				if _groups[sid] then
					local inGroup = false
					for k, v in ipairs(_groups[sid]) do
						if v.id == data.channel then
							inGroup = v
							break
						end
					end

					if inGroup then
						local tChar = exports['sandbox-characters']:FetchBySID(tonumber(data.sid))
						if tChar ~= nil then
							local tsid = tChar:GetData("SID")
							local tInGroup = false
							if _groups[tsid] then
								for k, v in ipairs(_groups[tsid]) do
									if v.id == data.channel then
										tInGroup = v
										break
									end
								end
							end

							if not tInGroup then
								_invites[tsid] = _invites[tsid] or {}
								_invites[tsid][data.channel] = {
									sender = sid,
									group = data.channel,
									label = _groupData[data.channel].label,
									icon = _groupData[data.channel].icon,
									timestamp = os.time(),
								}

								TriggerClientEvent(
									"Phone:Client:Chatter:ReceiveInvite",
									tChar:GetData("Source"),
									_invites[tsid][data.channel]
								)

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
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Chatter:Invite:Accept", function(source, data, cb)
		local invite = tonumber(data)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local sid = char:GetData("SID")

			_invites[sid] = _invites[sid] or {}

			if _invites[sid][invite] ~= nil then
				MySQL.insert("INSERT INTO character_chatter_groups (sid, chatty_group) VALUES(?, ?)", {
					sid,
					invite,
				})

				_groups[sid] = _groups[sid] or {}

				local tmp = {
					id = invite,
					label = _groupData[invite].label,
					icon = _groupData[invite].icon,
					owner = _groupData[invite].owner,
					joined_date = os.time(),
					last_message = nil,
				}

				table.insert(_groups[sid], tmp)

				_groupsOnline[invite] = _groupsOnline[invite] or {}
				_groupsOnline[invite][source] = sid

				_invites[sid][invite] = nil

				cb(tmp)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Chatter:Invite:Decline", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local sid = char:GetData("SID")
			_invites[sid] = _invites[sid] or {}
			if _invites[sid][data] ~= nil then
				_invites[sid][data] = nil
				cb(true)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Chatter:UpdateGroup", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local sid = char:GetData("SID")

			if _groups[sid] then
				local inGroup = false
				for k, v in ipairs(_groups[sid]) do
					if v.id == data.channel then
						inGroup = v
						break
					end
				end

				if inGroup and inGroup.owner == sid then
					MySQL.query.await("UPDATE chatter_groups SET label = ?, icon = ? WHERE id = ?", {
						data.data.label,
						data.data.icon,
						data.channel,
					})

					_groupData[data.channel] = {
						id = data.channel,
						label = data.data.label,
						icon = data.data.label,
					}

					for k, v in pairs(_groupsOnline[data.channel]) do
						if _groups[v] ~= nil then
							for k2, v2 in ipairs(_groups[v]) do
								if v2.id == data.channel then
									v2.label = data.data.label
									v2.icon = data.data.icon
								end
							end

							TriggerClientEvent("Phone:Client:Chatter:UpdateGroup", k, {
								id = data.channel,
								label = data.data.label,
								icon = data.data.icon,
							})
						end
					end

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
end)

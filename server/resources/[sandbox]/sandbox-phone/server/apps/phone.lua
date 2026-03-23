local _calls = {}
local _bizCallHandlers = {} -- The people who answered the business call

local function normalizePhoneNumber(num)
    if not num then return nil end
    -- keep it consistent with your generator/format (you use ###-###-####)
    return tostring(num)
end

local function getBizIdFromNumber(number)
    number = normalizePhoneNumber(number)
    return number and _bizPhoneNumbersCheck[number] or nil
end

exports("CallEnd", function(source, business)
	if business then
		if _bizPhones[business] and _bizPhones[business].call then
			local caller = _bizPhones[business].call.caller
			local duration = false
			if _bizPhones[business].call.handler then
				duration = math.ceil(os.time() - _bizPhones[business].call.start)
			end

			if caller ~= nil and _calls[caller] ~= nil then
				exports['sandbox-base']:LoggerTrace("Phone",
					string.format("%s Ending Call With %s", business, caller))
				_calls[caller].data.duration = duration or -1
				TriggerClientEvent("Phone:Client:Phone:EndCall", caller)
				TriggerClientEvent(
					"Phone:Client:AddData",
					caller,
					"calls",
					_calls[caller].data
				)
				exports['sandbox-phone']:CallCreateRecord(_calls[caller].data)
				exports['sandbox-phone']:NotificationRemoveById(caller, "PHONE_CALL")
				exports["sandbox-voip"]:SetCall(caller, 0)
				_calls[caller] = nil
			else
				exports['sandbox-base']:LoggerTrace(
					"Phone",
					string.format("%s Ending Call With Second Client Not Registered In A Call", business)
				)
			end

			if _bizPhones[business].call.handler then
				exports["sandbox-voip"]:SetCall(_bizPhones[business].call.handler, 0)

				_bizCallHandlers[_bizPhones[business].call.handler] = nil
			end

			_bizPhones[business].call = false
			GlobalState[string.format("BizPhone:%s", business)] = nil
			TriggerClientEvent("Phone:Client:Biz:End", -1, business)
		end
	else
		if _calls[source] ~= nil then
			if _calls[source].state == 2 then
				_calls[source].data.duration = math.ceil(os.time() - _calls[source].start)
			else
				_calls[source].data.duration = -1
			end

			exports['sandbox-phone']:CallCreateRecord(_calls[source].data)

			TriggerClientEvent("Phone:Client:Phone:EndCall", source)
			TriggerClientEvent("Phone:Client:AddData", source, "calls", _calls[source].data)

			exports['sandbox-phone']:NotificationRemoveById(source, "PHONE_CALL")
			exports["sandbox-voip"]:SetCall(source, 0)

			if _calls[source].isBiz then
				if _bizPhones[_calls[source].isBiz].call and _bizPhones[_calls[source].isBiz].call.handler then
					exports["sandbox-voip"]:SetCall(_bizPhones[_calls[source].isBiz].call.handler, 0)

					_bizCallHandlers[_bizPhones[_calls[source].isBiz].call.handler] = nil
				end

				_bizPhones[_calls[source].isBiz].call = false
				GlobalState[string.format("BizPhone:%s", _calls[source].isBiz)] = nil
				TriggerClientEvent("Phone:Client:Biz:End", -1, _calls[source].isBiz)
			else
				if _calls[source].target ~= nil and _calls[_calls[source].target] ~= nil then
					exports['sandbox-base']:LoggerTrace("Phone",
						string.format("%s Ending Call With %s", source, _calls[source].target))
					_calls[_calls[source].target].data.duration = _calls[source].data.duration or -1
					TriggerClientEvent("Phone:Client:Phone:EndCall", _calls[source].target)
					TriggerClientEvent(
						"Phone:Client:AddData",
						_calls[source].target,
						"calls",
						_calls[_calls[source].target].data
					)
					exports['sandbox-phone']:CallCreateRecord(_calls[_calls[source].target].data)
					exports['sandbox-phone']:NotificationRemoveById(_calls[source].target, "PHONE_CALL")
					exports["sandbox-voip"]:SetCall(_calls[source].target, 0)
					_calls[_calls[source].target] = nil
				else
					exports['sandbox-base']:LoggerTrace(
						"Phone",
						string.format("%s Ending Call With Second Client Not Registered In A Call", source)
					)
				end
			end

			_calls[source] = nil
		end
	end
end)

exports("CallCreateRecord", function(record)
	MySQL.insert(
		"INSERT INTO character_calls (owner, number, method, duration, anonymous, decryptable, limited, unread) VALUES(?, ?, ?, ?, ?, ?, ?, ?)",
		{
			record.owner,
			record.number,
			record.method,
			record.duration,
			record.anonymous or false,
			record.decryptable or false,
			record.limited or false,
			record.unread or false,
		}
	)
end)

exports("CallDecrypt", function(owner, number)
	MySQL.update("UPDATE character_calls SET anonymous = ? WHERE owner = ? AND number = ? AND decryptable = ?", {
		false,
		owner,
		number,
		true,
	})
end)

exports("CallRead", function(owner)
	MySQL.update("UPDATE character_calls SET unread = ? WHERE owner = ? AND unread = ?", {
		false,
		owner,
		true,
	})
end)

AddEventHandler("Characters:Server:PlayerLoggedOut", function(source, cData)
	if _calls[source] ~= nil then
		exports['sandbox-phone']:CallEnd(source)
	end

	if _bizCallHandlers[source] ~= nil then
		exports['sandbox-phone']:CallEnd(-1, _bizCallHandlers[source])
	end
end)

AddEventHandler("Characters:Server:PlayerDropped", function(source, cData)
	if _calls[source] ~= nil then
		exports['sandbox-phone']:CallEnd(source)
	end

	if _bizCallHandlers[source] ~= nil then
		exports['sandbox-phone']:CallEnd(-1, _bizCallHandlers[source])
	end
end)

RegisterNetEvent("Phone:Server:ForceEndBizCall", function()
	local src = source
	if _bizCallHandlers[source] ~= nil then
		exports['sandbox-phone']:CallEnd(-1, _bizCallHandlers[source])
	end
end)

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	exports['sandbox-base']:MiddlewareAdd("Phone:Spawning", function(source, char)
		local t = MySQL.query.await(
			"SELECT id, owner, number, UNIX_TIMESTAMP(time) as time, method, duration, anonymous, limited, unread FROM character_calls WHERE owner = ? ORDER BY time DESC LIMIT 100",
			{
				char:GetData("Phone"),
			}
		)

		return {
			{
				type = "calls",
				data = t,
			},
		}
	end)
end)

AddEventHandler("Phone:Server:RegisterCallbacks", function()
	exports["sandbox-base"]:RegisterServerCallback("Phone:Phone:CreateCall", function(src, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(src)
		if _calls[src] == nil and char:GetData("Phone") ~= data.number then
			local callingContact = exports['sandbox-phone']:ContactsIsContact(char:GetData("SID"), data.number)
			local callingStr = data.number
			if callingContact and not data.limited then
				callingStr = callingContact.name
			end

			_calls[src] = {
				id = char:GetData("Source"),
				owner = char:GetData("Phone"),
				number = data.number,
				duration = -1,
				start = os.time(),
				callingStr = callingStr,
				data = {
					owner = char:GetData("Phone"),
					number = data.number,
					time = os.time(),
					duration = -1,
					method = true,
					limited = false, --data.limited,
					anonymous = false, --data.isAnon,
					decryptable = hasValue(char:GetData("States") or {}, "ADV_VPN"),
					unread = false,
				},
			}
			exports['sandbox-phone']:NotificationAddWithId(src, "PHONE_CALL", "Dialing", callingStr, os.time(), -1,
				"phone", {
					cancel = "Phone:Nui:Phone:EndCall",
				}, nil)

			local isBusiness = _bizPhoneNumbersCheck[data.number]
			if isBusiness and _bizPhones[isBusiness] then
				local bizData = _bizPhones[isBusiness]
				-- Caller
				local callerData = {
					owner = char:GetData("Phone"),
					number = data.number,
					time = os.time(),
					duration = -1,
					method = true,
					limited = data.limited,
					anonymous = data.isAnon,
					unread = false,
				}

				if bizData.call then -- Already Busy
					exports['sandbox-phone']:CallCreateRecord(callerData)

					exports['sandbox-phone']:NotificationAdd(
						src,
						"Number Busy",
						"The Number You Dialed Is Busy",
						os.time(),
						6000,
						"phone"
					)

					cb(false)
					exports['sandbox-phone']:CallEnd(src)
				else
					_calls[src].isBiz = isBusiness

					local destStr = char:GetData("Phone")
					if data.limited then
						destStr = "Unknown Number"
					end

					_bizPhones[isBusiness].call = {
						outgoing = false,
						caller = char:GetData("Source"),
						number = char:GetData("Phone"),
						callingStr = destStr,
						start = os.time(),
						handler = false,
					}

					GlobalState[string.format("BizPhone:%s", isBusiness)] = {
						state = 1,
						number = char:GetData("Phone"),
						callingStr = destStr,
					}

					cb(true)
					TriggerClientEvent("Phone:Client:Biz:Recieve", -1, isBusiness, _bizPhones[isBusiness].coords,
						_bizPhones[isBusiness].radius or 15.0)

					CreateThread(function()
						local timeThen = os.time()
						Wait(30000)

						if _bizPhones[isBusiness].call and _bizPhones[isBusiness].call.start == timeThen and not _bizPhones[isBusiness].call.handler then
							exports['sandbox-phone']:CallCreateRecord(callerData)

							exports['sandbox-phone']:NotificationAdd(
								src,
								"Number Unavailable",
								"The Number You Dialed Is Unavailable",
								os.time(),
								6000,
								"phone"
							)
							exports['sandbox-phone']:CallEnd(src)
						end
					end)
				end
				return
			end

			local target = exports['sandbox-characters']:FetchCharacterData("Phone", data.number)
			if target ~= nil and ((function()
					local phoneItem = exports.ox_inventory:getUtilitySlotItem(target:GetData("Source"), 8)
					return phoneItem ~= nil and phoneItem.metadata.durability > 0
				end)()) then
				if _calls[target:GetData("Source")] == nil then
					cb(true)

					exports['sandbox-base']:LoggerTrace("Phone",
						string.format("%s Starting Call With %s", src, target:GetData("Source")))

					_calls[src].target = target:GetData("Source")

					local destContact = exports['sandbox-phone']:ContactsIsContact(target:GetData("SID"),
						char:GetData("Phone"))
					local destStr = char:GetData("Phone")
					if destContact then
						destStr = destContact.name
					end

					if data.limited then
						destStr = "Unknown Number"
					end

					_calls[target:GetData("Source")] = {
						id = target:GetData("Source"),
						owner = target:GetData("Phone"),
						number = char:GetData("Phone"),
						duration = -1,
						start = os.time(),
						target = char:GetData("Source"),
						callingStr = destStr,
						data = {
							owner = data.number,
							number = char:GetData("Phone"),
							time = os.time(),
							duration = 0,
							method = false,
							limited = data.limited,
							anonymous = data.isAnon,
							decryptable = hasValue(target:GetData("States") or {}, "ADV_VPN"),
							unread = false,
						},
					}

					exports['sandbox-phone']:NotificationAddWithId(
						target:GetData("Source"),
						"PHONE_CALL",
						"Incoming Call",
						destStr,
						os.time(),
						-1,
						"phone",
						{
							accept = "Phone:Nui:Phone:AcceptCall",
							cancel = "Phone:Nui:Phone:EndCall",
						}
					)

					TriggerClientEvent(
						"Phone:Client:Phone:RecieveCall",
						target:GetData("Source"),
						char:GetData("Source"),
						char:GetData("Phone"),
						data.limited
					)
				else
					exports['sandbox-base']:LoggerTrace(
						"Phone",
						string.format(
							"%s Starting Call With Number %s Which Is Already On A Call",
							src,
							data.number
						)
					)

					-- Caller
					local callerData = {
						owner = char:GetData("Phone"),
						number = data.number,
						time = os.time(),
						duration = -1,
						method = true,
						limited = data.limited,
						anonymous = data.isAnon,
						unread = false,
					}
					exports['sandbox-phone']:CallCreateRecord(callerData)
					exports['sandbox-phone']:NotificationAdd(
						src,
						"Number Busy",
						"The Number You Dialed Is Busy",
						os.time(),
						6000,
						"phone"
					)

					-- Recipient
					local recipData = {
						owner = data.number,
						number = char:GetData("Phone"),
						time = os.time(),
						duration = -1,
						method = false,
						limited = data.limited,
						anonymous = data.isAnon,
						unread = true,
					}
					exports['sandbox-phone']:CallCreateRecord(recipData)
					TriggerClientEvent("Phone:Client:AddData", target:GetData("Source"), "calls", recipData)
					exports['sandbox-phone']:NotificationAdd(
						target:GetData("Source"),
						"Missed Call",
						"You Missed A Call",
						os.time(),
						6000,
						"phone"
					)

					cb(false)
					exports['sandbox-phone']:CallEnd(src)
				end
			else
				exports['sandbox-base']:LoggerTrace(
					"Phone",
					string.format("%s Starting Call With Number %s Which Is Not Online", src, data.number)
				)
				exports['sandbox-phone']:CallCreateRecord({
					owner = data.number,
					number = char:GetData("Phone"),
					time = os.time(),
					duration = -1,
					method = false,
					limited = data.limited,
					anonymous = data.isAnon,
					decryptable = false,
					unread = true,
				})
				cb(true)
				return
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Phone:Phone:AcceptCall", function(src, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(src)

		if _calls[src] ~= nil then
			if _calls[src].isBiz and _bizPhones[_calls[src].isBiz].call then
				_calls[src].state = 2
				TriggerClientEvent("Phone:Client:Phone:AcceptCall", src, _calls[src].number)

				local bizCallerSource = _bizPhones[_calls[src].isBiz].call.handler
				TriggerClientEvent("Phone:Client:Phone:AcceptBizCall", bizCallerSource,
					_bizPhones[_calls[src].isBiz].call.number)
				local cid = src

				exports['sandbox-base']:LoggerTrace(
					"Phone",
					string.format("%s Accepted Call With %s, Setting To Call Channel %s", src, _calls[src].isBiz, cid)
				)

				local t = GlobalState[string.format("BizPhone:%s", _calls[src].isBiz)]
				t.state = 2
				GlobalState[string.format("BizPhone:%s", _calls[src].isBiz)] = t

				exports['sandbox-phone']:NotificationAddWithId(
					src,
					"PHONE_CALL",
					"On Call",
					_calls[src].callingStr,
					os.time(),
					-1,
					"phone",
					{
						cancel = "Phone:Nui:Phone:EndCall",
					}
				)

				exports["sandbox-voip"]:SetCall(src, cid)
				exports["sandbox-voip"]:SetCall(bizCallerSource, cid)
			elseif _calls[src].target ~= nil and _calls[_calls[src].target] ~= nil then
				_calls[src].state = 2
				_calls[_calls[src].target].state = 2

				TriggerClientEvent("Phone:Client:Phone:AcceptCall", src, _calls[src].number)
				TriggerClientEvent("Phone:Client:Phone:AcceptCall", _calls[src].target, _calls[_calls[src].target]
					.number)

				local cid = src
				if not _calls[src].data.method then
					cid = _calls[src].target
				end

				exports['sandbox-base']:LoggerTrace(
					"Phone",
					string.format("%s Accepted Call With %s, Setting To Call Channel %s", src, _calls[src].target, cid)
				)

				exports['sandbox-phone']:NotificationAddWithId(
					src,
					"PHONE_CALL",
					"On Call",
					_calls[src].callingStr,
					os.time(),
					-1,
					"phone",
					{
						cancel = "Phone:Nui:Phone:EndCall",
					}
				)

				exports['sandbox-phone']:NotificationAddWithId(
					_calls[src].target,
					"PHONE_CALL",
					"On Call",
					_calls[_calls[src].target].callingStr,
					os.time(),
					-1,
					"phone",
					{
						cancel = "Phone:Nui:Phone:EndCall",
					}
				)

				exports["sandbox-voip"]:SetCall(src, cid)
				exports["sandbox-voip"]:SetCall(_calls[src].target, cid)
			end
		else
			exports['sandbox-base']:LoggerTrace(
				"Phone",
				string.format("%s Attempted Accepting A Call But Server Didn't Have One Registered", source)
			)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Phone:Phone:EndCall", function(src, data, cb)
		exports['sandbox-phone']:CallEnd(src)
	end)

	exports["sandbox-base"]:RegisterServerCallback("Phone:Phone:ReadCalls", function(src, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(src)
		if char ~= nil then
			exports['sandbox-phone']:CallRead(char:GetData("Phone"))
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Phone:MuteBiz", function(source, id, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil and id and _bizPhones[id] and exports['sandbox-jobs']:HasJob(source, _bizPhones[id].job) then
			if GlobalState[string.format("BizPhone:%s:Muted", id)] then
				MySQL.query.await("UPDATE business_phones SET muted = ? WHERE id = ?", { false, id })
				GlobalState[string.format("BizPhone:%s:Muted", id)] = false
				cb(true, false)
			else
				MySQL.query.await("UPDATE business_phones SET muted = ? WHERE id = ?", { true, id })
				GlobalState[string.format("BizPhone:%s:Muted", id)] = true
				cb(true, true)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Phone:DeclineBizCall", function(source, id, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil and id and _bizPhones[id] and _bizPhones[id].call and exports['sandbox-jobs']:HasJob(source, _bizPhones[id].job) then
			exports['sandbox-phone']:CallEnd(-1, id)
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Phone:AcceptBizCall", function(source, id, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil and not _calls[source] and id and _bizPhones[id] and _bizPhones[id].call and not _bizPhones[id].call.outgoing and exports['sandbox-jobs']:HasJob(source, _bizPhones[id].job) then
			if not _bizPhones[id].call.handler then
				_bizPhones[id].call.handler = source
				_bizCallHandlers[source] = id

				local targetSource = _bizPhones[id].call.caller
				local cid = targetSource

				_calls[targetSource].state = 2

				TriggerClientEvent("Phone:Client:Phone:AcceptCall", targetSource, _calls[targetSource].number)
				TriggerClientEvent("Phone:Client:Biz:Answered", -1, id)

				exports['sandbox-base']:LoggerTrace(
					"Phone",
					string.format("%s Accepted Call With %s, Setting To Call Channel %s", id, targetSource, cid)
				)

				local t = GlobalState[string.format("BizPhone:%s", id)]
				t.state = 2
				GlobalState[string.format("BizPhone:%s", id)] = t

				exports['sandbox-phone']:NotificationAddWithId(
					targetSource,
					"PHONE_CALL",
					"On Call",
					_calls[targetSource].callingStr,
					os.time(),
					-1,
					"phone",
					{
						cancel = "Phone:Nui:Phone:EndCall",
					}
				)

				exports["sandbox-voip"]:SetCall(source, cid)
				exports["sandbox-voip"]:SetCall(targetSource, cid)

				cb(true, _bizPhones[id].call.callingStr)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Phone:MakeBizCall", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil and data and data.id and data.number and _bizPhones[data.id] and not _bizPhones[data.id].call and exports['sandbox-jobs']:HasJob(source, _bizPhones[data.id].job) and data.number ~= char:GetData("Phone") then
			local target = exports['sandbox-characters']:FetchCharacterData("Phone", data.number)
			if target ~= nil and ((function()
					local phoneItem = exports.ox_inventory:getUtilitySlotItem(target:GetData("Source"), 8)
					return phoneItem ~= nil and phoneItem.metadata.durability > 0
				end)()) then
				if _calls[target:GetData("Source")] == nil then
					cb(true)

					_bizPhones[data.id].call = {
						outgoing = true,
						caller = target:GetData("Source"),
						number = target:GetData("Phone"),
						start = os.time(),
						handler = source,
					}
					_bizCallHandlers[source] = data.id

					GlobalState[string.format("BizPhone:%s", data.id)] = {
						state = 3,
						number = target:GetData("Phone"),
						callingStr = target:GetData("Phone"),
					}

					exports['sandbox-base']:LoggerTrace("Phone",
						string.format("%s Starting Call With %s", data.id, target:GetData("Source")))

					local destContact = exports['sandbox-phone']:ContactsIsContact(target:GetData("SID"),
						_bizPhones[data.id].number)
					local destStr = _bizPhones[data.id].number
					if destContact then
						destStr = destContact.name
					end

					_calls[target:GetData("Source")] = {
						id = target:GetData("Source"),
						owner = target:GetData("Phone"),
						number = _bizPhones[data.id].number,
						duration = -1,
						start = os.time(),
						target = char:GetData("Source"),
						callingStr = destStr,
						isBiz = data.id,
						data = {
							owner = data.number,
							number = _bizPhones[data.id].number,
							time = os.time(),
							duration = 0,
							method = false,
							limited = false,
							anonymous = false,
							unread = false,
						},
					}

					exports['sandbox-phone']:NotificationAddWithId(
						target:GetData("Source"),
						"PHONE_CALL",
						"Incoming Call",
						destStr,
						os.time(),
						-1,
						"phone",
						{
							accept = "Phone:Nui:Phone:AcceptCall",
							cancel = "Phone:Nui:Phone:EndCall",
						}
					)

					TriggerClientEvent(
						"Phone:Client:Phone:RecieveCall",
						target:GetData("Source"),
						char:GetData("Source"),
						_bizPhones[data.id].number,
						false
					)
				else
					exports['sandbox-base']:LoggerTrace(
						"Phone",
						string.format(
							"%s Starting Call With Number %s Which Is Already On A Call",
							data.id,
							data.number
						)
					)

					-- Recipient
					local recipData = {
						owner = data.number,
						number = _bizPhones[data.id].number,
						time = os.time(),
						duration = -1,
						method = false,
						limited = data.limited,
						anonymous = data.isAnon,
						unread = true,
					}
					exports['sandbox-phone']:CallCreateRecord(recipData)
					TriggerClientEvent("Phone:Client:AddData", target:GetData("Source"), "calls", recipData)
					exports['sandbox-phone']:NotificationAdd(
						target:GetData("Source"),
						"Missed Call",
						"You Missed A Call",
						os.time(),
						6000,
						"phone"
					)

					cb(false, true)
					exports['sandbox-phone']:CallEnd(src)
				end
			else
				exports['sandbox-base']:LoggerTrace(
					"Phone",
					string.format("%s Starting Call With Number %s Which Is Not Online", data.id, data.number)
				)
				exports['sandbox-phone']:CallCreateRecord({
					owner = data.number,
					number = char:GetData("Phone"),
					time = os.time(),
					duration = -1,
					method = false,
					limited = false,
					anonymous = false,
					decryptable = false,
					unread = true,
				})
				cb(false, true)
				return
			end
		else
			cb(false)
		end
	end)
end)
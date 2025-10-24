_openCd = false -- Prevents spamm open/close
_settings = {}
_loggedIn = false

local _payphones = {
	`p_phonebox_02_s`,
	`p_phonebox_01b_s`,
	`prop_phonebox_01a`,
	`prop_phonebox_01b`,
	`prop_phonebox_01c`,
	`prop_phonebox_02`,
	`prop_phonebox_03`,
	`prop_phonebox_04`,
	`ch_chint02_phonebox001`,
	`sf_prop_sf_phonebox_01b_s`,
	`sf_prop_sf_phonebox_01b_straight`,
}

local _ignoreEvents = {
	"Health",
	"HP",
	"Armor",
	"Status",
	"Damage",
	"Wardrobe",
	"Animations",
	"Ped",
	"PhoneSettings",
}

AddEventHandler('onClientResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Wait(1000)
		exports["sandbox-kbs"]:Add("phone_toggle", "M", "keyboard", "Phone - Open/Close", function()
			TogglePhone()
		end)

		--exports["sandbox-kbs"]:Add("phone_ansend", "", "keyboard", "Phone - Accept/End Call", function()
		--	if _call ~= nil then
		--		if _call.state == 1 then
		--			exports['sandbox-phone']:CallAccept()
		--		else
		--			exports['sandbox-phone']:CallEnd()
		--		end
		--	end
		--end)

		exports["sandbox-kbs"]:Add("phone_answer", "", "keyboard", "Phone - Accept Call", function()
			if _call ~= nil then
				if _call.state == 1 then
					exports['sandbox-phone']:CallAccept()
				end
			end
		end)

		exports["sandbox-kbs"]:Add("phone_end", "", "keyboard", "Phone - End Call", function()
			if _call ~= nil then
				exports['sandbox-phone']:CallEnd()
			end
		end)

		exports["sandbox-kbs"]:Add("phone_mute", "", "keyboard", "Phone - Mute/Unmute Sound", function()
			if _settings.volume > 0 then
				_settings.volume = 0
				exports["sandbox-sounds"]:PlayOne("mute.ogg", 0.1)
			else
				_settings.volume = 100
				exports["sandbox-sounds"]:PlayOne("unmute.ogg", 0.1)
			end
			exports["sandbox-base"]:ServerCallback("Phone:Settings:Update", {
				type = "volume",
				val = _settings.volume,
			})

			-- Send this manually since we're blocking PhoneSettings
			-- updates bcuz react rerendering makes me want to cry
			SendNUIMessage({
				type = "UPDATE_DATA",
				data = {
					type = "player",
					id = "PhoneSettings",
					key = "volume",
					data = _settings.volume,
				},
			})
		end)

		for k, v in ipairs(_payphones) do
			exports.ox_target:addModel(v, {
				{
					icon = "fas fa-phone-volume",
					label = "Use Payphone",
					event = "Phone:Client:Payphone",
					distance = 2.0,
					canInteract = function()
						return not exports['sandbox-phone']:IsOpen() and
							not exports['sandbox-phone']:CallStatus()
					end,
				},
			})
		end
	end
end)

AddEventHandler("Phone:Client:Payphone", function(entity, data)
	if entity.entity ~= nil then
		exports['sandbox-phone']:OpenPayphone()
	end
end)

AddEventHandler("Characters:Client:Updated", function(key)
	if hasValue(_ignoreEvents, key) then
		return
	end

	_settings = LocalPlayer.state.Character:GetData("PhoneSettings")
	exports['sandbox-phone']:DataSet("player", LocalPlayer.state.Character:GetData())

	if
		key == "States"
		and LocalPlayer.state.phoneOpen
		and (function()
			local phoneItem = exports.ox_inventory:getUtilitySlotItem(8)
			return phoneItem == nil or phoneItem.metadata.durability <= 0
		end)()
	then
		exports['sandbox-phone']:Close(true)
	end
end)

RegisterNetEvent("Job:Client:DutyChanged", function(state)
	exports['sandbox-phone']:DataSet("onDuty", state)
end)

RegisterNetEvent("UI:Client:Reset", function(manual)
	SetNuiFocus(false, false)
	SendNUIMessage({
		type = "UI_RESET",
		data = {},
	})

	if manual then
		TriggerServerEvent("Phone:Server:UIReset")
		if LocalPlayer.state.phoneOpen then
			exports['sandbox-phone']:Close()
		end
	end
end)

AddEventHandler("UI:Client:Close", function(context)
	if context ~= "phone" then
		exports['sandbox-phone']:Close()
	end
end)

AddEventHandler("Ped:Client:Died", function()
	if LocalPlayer.state.phoneOpen then
		exports['sandbox-phone']:Close()
	end
end)

RegisterNetEvent("Phone:Client:SetApps", function(apps)
	PHONE_APPS = apps
	SendNUIMessage({
		type = "SET_APPS",
		data = apps,
	})
end)

local shareTypes = {
	documents = "A document was shared with you",
	contacts = "Contact details were shared with you",
}

RegisterNetEvent("Phone:Client:ReceiveShare", function(share, time)
	exports['sandbox-phone']:NotificationAdd("Received QuickShare", shareTypes[share.type], time, 7500, {
		color = "#18191e",
		label = "Share",
		icon = "share-nodes",
	}, {
		view = "USE_SHARE",
	}, nil)
	exports['sandbox-phone']:ReceiveShare(share)
end)

AddEventHandler("Characters:Client:Spawn", function()
	_loggedIn = true

	if LocalPlayer.state.Character then
		local settings = LocalPlayer.state.Character:GetData("PhoneSettings")
		if settings then
			exports['sandbox-phone']:SetExpanded(settings.Expanded)
		end
	end

	CreateThread(function()
		while _loggedIn do
			SendNUIMessage({
				type = "SET_TIME",
				data = GlobalState["Sync:Time"],
			})
			Wait(15000)
		end
	end)

	CreateBizPhones()
end)

RegisterNetEvent("Characters:Client:Logout", function()
	_loggedIn = false

	CleanupBizPhones()
	playsound()
end)

function hasValue(tbl, value)
	for k, v in ipairs(tbl or {}) do
		if v == value or (type(v) == "table" and hasValue(v, value)) then
			return true
		end
	end
	return false
end

function hasPhone(cb)
	cb(true)
end

function IsInCall()
	return false
end

function TogglePhone()
	if not _loggedIn then
		return
	end
	if not _openCd then
		if not exports['sandbox-hud']:IsDisabled() then
			local phoneItem = exports.ox_inventory:getUtilitySlotItem(8)
			if (phoneItem ~= nil and phoneItem.metadata.durability > 0) then
				exports['sandbox-phone']:Open()
			else
				exports["sandbox-hud"]:Notification("error", "You Don't Have a Phone", 2000)
				LocalPlayer.state.phoneOpen = false
			end
		else
			exports['sandbox-phone']:Close()
		end

		if not IsPedInAnyVehicle(PlayerPedId(), true) then
			DisplayRadar(LocalPlayer.state.phoneOpen or hasValue(LocalPlayer.state.Character:GetData("States"), "GPS"))
		end
	end
end

exports('TogglePhone', TogglePhone)

AddEventHandler("Phone:Client:OpenLimited", function()
	exports['sandbox-phone']:OpenLimited()
end)

AddEventHandler("Ped:Client:Died", function()
	exports['sandbox-phone']:Close(true)
end)

RegisterNUICallback("CDExpired", function(data, cb)
	cb("OK")
	_openCd = false
end)

RegisterNUICallback("Home", function(data, cb)
	cb("OK")
	exports["sandbox-base"]:ServerCallback("Phone:Apps:Home", data)
end)

RegisterNUICallback("Dock", function(data, cb)
	cb("OK")
	exports["sandbox-base"]:ServerCallback("Phone:Apps:Dock", data)
end)

RegisterNUICallback("Reorder", function(data, cb)
	cb("OK")
	exports["sandbox-base"]:ServerCallback("Phone:Apps:Reorder", data)
end)

RegisterNUICallback("UpdateAlias", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Phone:UpdateAlias", data, cb)
end)

RegisterNUICallback("UpdateProfile", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Phone:UpdateProfile", data, cb)
end)

RegisterNetEvent("Phone:Client:RestorePosition", function(data)
	SendNUIMessage({
		type = "SET_POSITION",
		data = data,
	})
end)

RegisterNUICallback("Phone:SavePosition", function(data, cb)
	cb("OK")
	exports["sandbox-base"]:ServerCallback("Phone:SavePosition", data)
end)

RegisterNUICallback("AcceptPopup", function(data, cb)
	cb("OK")
	if data.data ~= nil and data.data.server then
		TriggerServerEvent(data.event, data.data)
	else
		TriggerEvent(data.event, data.data)
	end
end)

RegisterNUICallback("CancelPopup", function(data, cb)
	cb("OK")
	if data.data ~= nil and data.data.server then
		TriggerServerEvent(data.event, data.data)
	else
		TriggerEvent(data.event, data.data)
	end
end)

RegisterNUICallback("SaveShare", function(data, cb)
	if data.type == "contacts" then
		exports["sandbox-base"]:ServerCallback("Phone:Contacts:Create", data.data, function(nId)
			cb(nId)
			if nId then
				exports['sandbox-phone']:DataAdd("contacts", {
					id = nId,
					name = data.data.name,
					number = data.data.number,
					color = data.data.color,
					favorite = false,
				})
			end
		end)
	elseif data.type == "documents" then
		exports["sandbox-base"]:ServerCallback("Phone:Documents:RecieveShare", data.data, function(success)
			cb(success)
			if success then
				if success.update then
					exports['sandbox-phone']:DataUpdate("myDocuments", success.id, success)
				else
					exports['sandbox-phone']:DataAdd("myDocuments", success)
				end
			end
		end)
	else
		cb(false)
	end
end)

RegisterNUICallback("ShareMyContact", function(data, cb)
	cb(true)
	exports["sandbox-base"]:ServerCallback("Phone:ShareMyContact", {})
end)

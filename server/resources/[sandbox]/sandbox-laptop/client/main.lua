_openCd = false -- Prevents spamm open/close
_settings = {}
_loggedIn = false

local _ignoreEvents = {
	"Health",
	"HP",
	"Armor",
	"Status",
	"Damage",
	"Wardrobe",
	"Animations",
	"Ped",
}

AddEventHandler('onClientResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Wait(1000)
		exports["sandbox-kbs"]:Add("laptop_open", "", "keyboard", "Laptop - Open", function()
			OpenLaptop()
		end)

		RegisterBoostingCallbacks()
	end
end)

function OpenLaptop()
	if
		_loggedIn
		and not exports['sandbox-hud']:IsDisabled()
		and not exports['sandbox-jail']:IsJailed()
		and not (exports.ox_inventory:Search('count', 'laptop') == 0)
		and not LocalPlayer.state.laptopOpen
	then
		exports['sandbox-laptop']:Open()
	end
end

RegisterNetEvent("Laptop:Client:Open", OpenLaptop)

AddEventHandler("Inventory:Client:ItemsLoaded", function()
	exports['sandbox-laptop']:SetData("items", exports.ox_inventory:ItemsGetData())
end)

AddEventHandler("Characters:Client:Updated", function()
	_settings = LocalPlayer.state.Character:GetData("LaptopSettings")
	exports['sandbox-laptop']:SetData("player", LocalPlayer.state.Character:GetData())

	if LocalPlayer.state.laptopOpen and (exports.ox_inventory:Search('count', 'laptop') == 0) then
		exports['sandbox-laptop']:Close(true)
	end
end)

AddEventHandler("Ped:Client:Died", function()
	exports['sandbox-laptop']:Close(true)
end)

RegisterNetEvent("Job:Client:DutyChanged", function(state)
	exports['sandbox-laptop']:SetData("onDuty", state)
end)

RegisterNetEvent("UI:Client:Reset", function(manual)
	SetNuiFocus(false, false)
	SendNUIMessage({
		type = "UI_RESET",
		data = {},
	})

	if manual then
		TriggerServerEvent("Laptop:Server:UIReset")
		if LocalPlayer.state.tabletOpen then
			exports['sandbox-laptop']:Close()
		end
	end
end)

AddEventHandler("UI:Client:Close", function(context)
	if context == "laptop" then
		exports['sandbox-laptop']:Close()
	end
end)

AddEventHandler("Ped:Client:Died", function()
	if LocalPlayer.state.laptopOpen then
		exports['sandbox-laptop']:Close()
	end
end)

RegisterNetEvent("Laptop:Client:SetApps", function(apps)
	LAPTOP_APPS = apps
	SendNUIMessage({
		type = "SET_APPS",
		data = apps,
	})
end)

AddEventHandler("Characters:Client:Spawn", function()
	_loggedIn = true

	CreateThread(function()
		while _loggedIn do
			SendNUIMessage({
				type = "SET_TIME",
				data = GlobalState["Sync:Time"],
			})
			Wait(15000)
		end
	end)
end)

RegisterNetEvent("Characters:Client:Logout", function()
	_loggedIn = false
end)

function hasValue(tbl, value)
	for k, v in ipairs(tbl or {}) do
		if v == value or (type(v) == "table" and hasValue(v, value)) then
			return true
		end
	end
	return false
end

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

RegisterNUICallback("CDExpired", function(data, cb)
	cb("OK")
	_openCd = false
end)

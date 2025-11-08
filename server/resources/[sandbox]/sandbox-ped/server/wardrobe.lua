AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Wait(1000)
		RegisterWardrobeCallbacks()
		RegisterWardrobeMiddleware()
		RegisterChatCommands()
	end
end)

function RegisterChatCommands()
	exports["sandbox-chat"]:RegisterAdminCommand("wardrobe", function(source, args, rawCommand)
		TriggerClientEvent("Wardrobe:Client:ShowWardrobe", source)
	end, {
		help = "Test Notification",
	})
	exports["sandbox-chat"]:RegisterAdminCommand("ped", function(source, args, rawCommand)
		local char
		local shopType = 0
		if args[1] and tonumber(args[1]) >= 0 then
			shopType = tonumber(args[1])
		end

		if args[2] and tonumber(args[2]) >= 1 then
			char = exports['sandbox-characters']:FetchBySID(args[2])
		else
			char = exports['sandbox-characters']:FetchCharacterSource(source)
		end

		if char ~= nil then
			exports['sandbox-hud']:Notification(source, "info",
				string.format("Ped Menu is given to State ID: %s", char:GetData("SID")),
				2000
			)
			TriggerClientEvent("Peds:Customization:Client:AdminAbuse", char:GetData("Source"), shopType)
		else
			exports['sandbox-hud']:Notification(source, "error", "Player is not online.", 2000)
		end
	end, {
		help = "Show Ped Menu for Player",
		params = {
			{
				name = "Shop Type (optional)",
				help = "0 = Clothing (default), 1 = Surgery, 2 = Barber, 3 = Tattoo",
			},
			{
				name = "State ID (optional)",
				help = "Player you want to give a menu too",
			},
		},
	})
end

function RegisterWardrobeMiddleware()
	exports['sandbox-base']:MiddlewareAdd("Characters:Creating", function(source, cData)
		return { {
			Wardrobe = {},
		} }
	end)
end

function RegisterWardrobeCallbacks()
	exports["sandbox-base"]:RegisterServerCallback("Wardrobe:GetAll", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		local wardrobe = char:GetData("Wardrobe") or {}

		local wr = {}

		for k, v in ipairs(wardrobe) do
			table.insert(wr, {
				label = v.label,
			})
		end

		cb(wr)
	end)

	exports["sandbox-base"]:RegisterServerCallback("Wardrobe:Save", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)

		if char ~= nil then
			local ped = char:GetData("Ped")
			local wardrobe = char:GetData("Wardrobe") or {}

			local outfit = {
				label = data.name,
				data = ped.customization,
			}
			table.insert(wardrobe, outfit)
			char:SetData("Wardrobe", wardrobe)
			cb(true)
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Wardrobe:SaveExisting", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)

		if char ~= nil then
			local ped = char:GetData("Ped")
			local wardrobe = char:GetData("Wardrobe") or {}

			if wardrobe[data] ~= nil then
				wardrobe[data].data = ped.customization
				char:SetData("Wardrobe", wardrobe)
				cb(true)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Wardrobe:Equip", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local outfit = char:GetData("Wardrobe")[tonumber(data)]
			if outfit ~= nil then
				exports['sandbox-ped']:ApplyOutfit(source, outfit)
				cb(true)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Wardrobe:Delete", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			local wardrobe = char:GetData("Wardrobe") or {}
			table.remove(wardrobe, data)
			char:SetData("Wardrobe", wardrobe)
			cb(true)
		else
			cb(false)
		end
	end)
end

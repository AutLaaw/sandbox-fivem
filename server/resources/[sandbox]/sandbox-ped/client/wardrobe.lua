AddEventHandler("Wardrobe:Client:SaveNew", function(data)
	exports['sandbox-hud']:InputShow("Outfit Name", "Outfit Name", {
		{
			id = "name",
			type = "text",
			options = {
				inputProps = {
					maxLength = 24,
				},
			},
		},
	}, "Wardrobe:Client:DoSave", data)
end)

AddEventHandler("Wardrobe:Client:SaveExisting", function(data)
	exports["sandbox-base"]:ServerCallback("Wardrobe:SaveExisting", data.index, function(state)
		if state then
			exports["sandbox-hud"]:Notification("success", "Outfit Saved")
			exports['sandbox-ped']:WardrobeShow()
		else
			exports["sandbox-hud"]:Notification("error", "Unable to Save Outfit")
		end
	end)
end)

AddEventHandler("Wardrobe:Client:DoSave", function(values, data)
	exports["sandbox-base"]:ServerCallback("Wardrobe:Save", {
		index = data,
		name = values.name,
	}, function(state)
		if state then
			exports["sandbox-hud"]:Notification("success", "Outfit Saved")
			exports['sandbox-ped']:WardrobeShow()
		else
			exports["sandbox-hud"]:Notification("error", "Unable to Save Outfit")
		end
	end)
end)

AddEventHandler("Wardrobe:Client:Delete", function(data)
	exports['sandbox-hud']:ConfirmShow(string.format("Delete %s?", data.label), {
		yes = "Wardrobe:Client:Delete:Yes",
		no = "Wardrobe:Client:Delete:No",
	}, "", data.index)
end)

AddEventHandler("Wardrobe:Client:Delete:Yes", function(data)
	exports["sandbox-base"]:ServerCallback("Wardrobe:Delete", data, function(s)
		if s then
			exports["sandbox-hud"]:Notification("success", "Outfit Deleted")
			exports['sandbox-ped']:WardrobeShow()
		end
	end)
end)

AddEventHandler("Wardrobe:Client:Equip", function(data)
	exports["sandbox-base"]:ServerCallback("Wardrobe:Equip", data.index, function(state)
		if state then
			exports["sandbox-sounds"]:PlayOne("outfit_change.ogg", 0.3)
			exports["sandbox-hud"]:Notification("success", "Outfit Equipped")
		else
			exports["sandbox-hud"]:Notification("error", "Unable to Equip Outfit")
		end
	end)
end)

RegisterNetEvent("Wardrobe:Client:ShowWardrobe", function(eventRoutine)
	exports['sandbox-ped']:WardrobeShow()
end)

exports("WardrobeShow", function()
	exports["sandbox-base"]:ServerCallback("Wardrobe:GetAll", {}, function(data)
		local items = {}
		for k, v in pairs(data) do
			if v.label ~= nil then
				table.insert(items, {
					label = v.label,
					description = string.format("Outfit #%s", k),
					actions = {
						{
							icon = "floppy-disks",
							event = "Wardrobe:Client:SaveExisting",
						},
						{
							icon = "shirt",
							event = "Wardrobe:Client:Equip",
						},
						{
							icon = "x",
							event = "Wardrobe:Client:Delete",
						},
					},
					data = {
						index = k,
						label = v.label,
					},
				})
			end
		end

		table.insert(items, {
			label = "Save New Outfit",
			event = "Wardrobe:Client:SaveNew",
		})

		exports['sandbox-hud']:ListMenuShow({
			main = {
				label = "Wardrobe",
				items = items,
			},
		})
	end)
end)

exports("WardrobeClose", function()
	SetNuiFocus(false, false)
	SendNUIMessage({
		type = "CLOSE_LIST_MENU",
	})
end)

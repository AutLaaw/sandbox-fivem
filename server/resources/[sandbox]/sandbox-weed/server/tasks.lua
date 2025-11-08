local _run = false


AddEventHandler("Core:Server:ForceSave", function()
	local docs = {}
	for k, v in pairs(_plants) do
		if v and v.plant then
			table.insert(docs, v.plant)
		end
	end
	if #docs > 0 then
		exports['sandbox-base']:LoggerInfo("Weed", string.format("Saving ^2%s^7 Plants", #docs))
		local queries = {}
		for _, plant in ipairs(docs) do
			table.insert(queries, {
				query =
				'INSERT INTO weed (id, is_male, x, y, z, growth, output, material, planted, water, fertilizer_type, fertilizer_value, fertilizer_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE is_male=VALUES(is_male), x=VALUES(x), y=VALUES(y), z=VALUES(z), growth=VALUES(growth), output=VALUES(output), material=VALUES(material), planted=VALUES(planted), water=VALUES(water), fertilizer_type=VALUES(fertilizer_type), fertilizer_value=VALUES(fertilizer_value), fertilizer_time=VALUES(fertilizer_time)',
				values = {
					plant._id,
					plant.isMale and 1 or 0,
					plant.location.x, plant.location.y, plant.location.z,
					plant.growth, plant.output, plant.material, plant.planted, plant.water,
					plant.fertilizer and plant.fertilizer.type or nil,
					plant.fertilizer and plant.fertilizer.value or nil,
					plant.fertilizer and plant.fertilizer.time or nil
				}
			})
		end
		MySQL.transaction(queries)
	end
end)

function RegisterTasks()
	if _run then return end
	_run = true

	CreateThread(function()
		while true do
			Wait((1000 * 60) * 10)
			local docs = {}
			for k, v in pairs(_plants) do
				if v and v.plant then
					table.insert(docs, v.plant)
				end
			end
			if #docs > 0 then
				exports['sandbox-base']:LoggerInfo("Weed", string.format("Saving ^2%s^7 Plants", #docs))
				local queries = {}
				for _, plant in ipairs(docs) do
					table.insert(queries, {
						query =
						'INSERT INTO weed (id, is_male, x, y, z, growth, output, material, planted, water, fertilizer_type, fertilizer_value, fertilizer_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE is_male=VALUES(is_male), x=VALUES(x), y=VALUES(y), z=VALUES(z), growth=VALUES(growth), output=VALUES(output), material=VALUES(material), planted=VALUES(planted), water=VALUES(water), fertilizer_type=VALUES(fertilizer_type), fertilizer_value=VALUES(fertilizer_value), fertilizer_time=VALUES(fertilizer_time)',
						values = {
							plant._id,
							plant.isMale and 1 or 0,
							plant.location.x, plant.location.y, plant.location.z,
							plant.growth, plant.output, plant.material, plant.planted, plant.water,
							plant.fertilizer and plant.fertilizer.type or nil,
							plant.fertilizer and plant.fertilizer.value or nil,
							plant.fertilizer and plant.fertilizer.time or nil
						}
					})
				end
				MySQL.transaction(queries)
			end
		end
	end)

	CreateThread(function()
		while true do
			Wait((1000 * 60) * 10)
			exports['sandbox-base']:LoggerTrace("Weed", "Growing Plants")
			local updatingStuff = {}

			for k, v in pairs(_plants) do
				if (os.time() - v.plant.planted) >= Config.Lifetime then
					exports['sandbox-base']:LoggerTrace("Weed",
						"Deleting Weed Plant Because Someone Didn't Harvest It")
					exports['sandbox-weed']:PlantingDelete(k)
				else
					if v.plant.growth < 100 then
						local mat = Materials[v.plant.material]
						if mat ~= nil then
							local gt = GroundTypes[mat.groundType]
							if gt ~= nil then
								local phosphorus = gt.phosphorus
								if v.plant.fertilizer ~= nil and v.plant.fertilizer.type == "phosphorus" then
									phosphorus = phosphorus + v.plant.fertilizer.value
								end
								v.plant.growth = v.plant.growth + (1 + phosphorus)
								if v.stage ~= getStageByPct(v.plant.growth) then
									local res = exports['sandbox-weed']:PlantingSet(k, true, true)
									if res then
										table.insert(updatingStuff, res)
									end
								end
							else
								exports['sandbox-weed']:PlantingDelete(k)
							end
						else
							exports['sandbox-weed']:PlantingDelete(k)
						end
					end
				end
			end

			if #updatingStuff > 0 then
				TriggerLatentClientEvent("Weed:Client:Objects:UpdateMany", -1, 30000, updatingStuff)
			end
		end
	end)

	CreateThread(function()
		while true do
			Wait((1000 * 60) * 20)
			exports['sandbox-base']:LoggerTrace("Weed", "Increasing Plant Outputs")
			for k, v in pairs(_plants) do
				if v.plant.growth < 100 then
					local mat = Materials[v.plant.material]
					if mat ~= nil then
						local gt = GroundTypes[mat.groundType]
						if gt ~= nil then
							local nitrogen = gt.nitrogen
							if v.plant.fertilizer ~= nil and v.plant.fertilizer.type == "nitrogen" then
								nitrogen = nitrogen + v.plant.fertilizer.value
							end
							v.plant.output = (v.plant.output or 0) + (1 * (1 + nitrogen))
						end
					end
				end
			end
		end
	end)

	CreateThread(function()
		while true do
			Wait((1000 * 60) * 10)
			exports['sandbox-base']:LoggerTrace("Weed", "Degrading Water")
			for k, v in pairs(_plants) do
				if v.plant.water > -25 then
					local mat = Materials[v.plant.material]
					if mat ~= nil then
						local gt = GroundTypes[mat.groundType]
						if gt ~= nil then
							local potassium = gt.potassium
							if v.plant.fertilizer ~= nil and v.plant.fertilizer.type == "potassium" then
								potassium = potassium + v.plant.fertilizer.value
							end

							v.plant.water = v.plant.water - ((1.0 * (1.0 + (1.0 - potassium))) - gt.water)
						else
							exports['sandbox-weed']:PlantingDelete(k)
						end
					else
						exports['sandbox-weed']:PlantingDelete(k)
					end
				else
					exports['sandbox-base']:LoggerTrace("Weed",
						"Deleting Weed Plant Because Someone Didn't Water It")
					exports['sandbox-weed']:PlantingDelete(k)
				end
			end
		end
	end)

	CreateThread(function()
		while true do
			Wait((1000 * 60) * 1)
			exports['sandbox-base']:LoggerTrace("Weed", "Ticking Down Fertilizer")
			for k, v in pairs(_plants) do
				if v.plant.fertilizer ~= nil then
					if v.plant.fertilizer.time > 0 then
						v.plant.fertilizer.time = v.plant.fertilizer.time - 1
					else
						v.plant.fertilizer = nil
					end
				end
			end
		end
	end)
end

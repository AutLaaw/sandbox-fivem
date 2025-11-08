_damagedLimbs = {}
_deadPerson = {}

function table.copy(t)
	local u = {}
	for k, v in pairs(t) do
		u[k] = v
	end
	return setmetatable(u, getmetatable(t))
end

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Wait(1000)
		RegisterChatCommands()

		exports['sandbox-base']:MiddlewareAdd("Characters:Spawning", function(source)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			if char ~= nil then
				local sid = char:GetData("SID")
				if _deadPerson[sid] ~= nil then
					local pState = Player(source).state
					pState.isDead = true
					pState.deadData = _deadPerson[sid].deadData
					pState.isDeadTime = _deadPerson[sid].isDeadTime
					pState.releaseTime = _deadPerson[sid].releaseTime

					Wait(100)
				end

				if char:GetData("Damage") ~= nil then
					char:SetData("Damage", nil)
				end
				_damagedLimbs[char:GetData("SID")] = _damagedLimbs[char:GetData("SID")] or {}
			end
		end, 2)

		exports["sandbox-base"]:RegisterServerCallback("Damage:GetLimbDamage", function(source, data, cb)
			if data == nil or source == nil then
				cb({})
				return
			end
			local char = exports['sandbox-characters']:FetchCharacterSource(data)
			if char ~= nil then
				local damage = exports['sandbox-damage']:GetLimbDamage(char:GetData("SID"))

				local menuData = {}

				local reductions = char:GetData("HPReductions") or 0
				if reductions > 0 then
					if reductions > 1 then
						table.insert(menuData, {
							label = "Signs of Trauma",
							description = "Signs of multiple major traumas (Health Reduced)",
						})
					else
						table.insert(menuData, {
							label = "Sign of Trauma",
							description = "Sign of major trauma (Health Reduced)",
						})
					end
				end

				for k, v in pairs(damage) do
					local descStr = ""

					local data = {}
					for k2, v2 in pairs(v) do
						if v2 > 0 then
							table.insert(data, string.format("%s %s", v2, Config.DamageTypeLabels[k2]))
						end
					end

					if #data > 0 then
						table.insert(menuData, {
							label = Config.BoneLabels[k],
							description = table.concat(data, ", "),
						})
					end
				end

				if #menuData == 0 then
					table.insert(menuData, {
						label = "No Observed Injuries",
					})
				end

				cb(menuData)
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Damage:SyncReductions", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			if char ~= nil then
				char:SetData("HPReductions", data)
			end
		end)
	end
end)

exports("GetLimbDamage", function(sid)
	return _damagedLimbs[sid]
end)

exports("ResetLimbDamage", function(sid)
	_damagedLimbs[sid] = {}
end)

exports("EffectsPainkiller", function(source, tier)
	exports["sandbox-base"]:ClientCallback(source, "Damage:ApplyPainkiller", 225 * (tier or 1))
end)

exports("EffectsAdrenaline", function(source, tier)
	exports["sandbox-base"]:ClientCallback(source, "Damage:ApplyAdrenaline", 75 * (tier or 1))
end)

AddEventHandler("Characters:Server:PlayerLoggedOut", function(source, cData)
	SetPlayerInvincible(source, false)
	Player(source).state.isGodmode = false
end)

RegisterNetEvent("Ped:Server:Died", function()
	local src = source
	local char = exports['sandbox-characters']:FetchCharacterSource(src)
	if char ~= nil then
		local pState = Player(src).state
		_deadPerson[char:GetData("SID")] = {
			deadData = pState.deadData,
			isDeadTime = pState.isDeadTime,
			releaseTime = pState.releaseTime,
		}
	end
end)

RegisterNetEvent("Damage:Server:StoreHealth", function(hp, armor)
	local src = source
	local char = exports['sandbox-characters']:FetchCharacterSource(src)
	if char ~= nil then
		char:SetData("HP", hp)
		char:SetData("Armor", armor)
	end
end)

RegisterNetEvent("Damage:Server:BoneDamage", function(damageData)
	local src = source
	local char = exports['sandbox-characters']:FetchCharacterSource(src)
	if char ~= nil then
		local sid = char:GetData("SID")
		for k, v in ipairs(damageData) do
			if Config.Bones[v.bone] ~= "NONE" then
				if _damagedLimbs[sid][Config.Bones[v.bone]] == nil then
					_damagedLimbs[sid][Config.Bones[v.bone]] = {}
					for k2, v2 in ipairs(Config.DamageTypes) do
						_damagedLimbs[sid][Config.Bones[v.bone]][v2] = 0
					end
				end
				local dmgType = Config.ClassDamageTypes[Config.WeaponClassBindings[v.hash]]
				if dmgType ~= nil then
					_damagedLimbs[sid][Config.Bones[v.bone]][dmgType] += 1
				end
			end
		end
	end
end)

RegisterNetEvent("Damage:Server:Revived", function(wasMinor, wasFieldTreatment)
	local src = source
	local char = exports['sandbox-characters']:FetchCharacterSource(src)
	if char ~= nil then
		_deadPerson[char:GetData("SID")] = nil
		if not wasMinor and not wasFieldTreatment then
			exports['sandbox-base']:LoggerTrace(
				"Damage",
				string.format(
					"%s %s (%s) Was Revived (Not Minor and Not Field Treatment)",
					char:GetData("First"),
					char:GetData("Last"),
					char:GetData("SID")
				)
			)
			exports['sandbox-damage']:ResetLimbDamage(char:GetData("SID"))
		else
			if wasMinor then
				exports['sandbox-base']:LoggerTrace(
					"Damage",
					string.format(
						"%s %s (%s) Was Revived (Minor Injury)",
						char:GetData("First"),
						char:GetData("Last"),
						char:GetData("SID")
					)
				)
			else
				exports['sandbox-base']:LoggerTrace(
					"Damage",
					string.format(
						"%s %s (%s) Was Revived (Field Treatment)",
						char:GetData("First"),
						char:GetData("Last"),
						char:GetData("SID")
					)
				)
			end
		end
	end
end)

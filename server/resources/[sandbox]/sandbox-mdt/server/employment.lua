AddEventHandler("MDT:Server:RegisterCallbacks", function()
	exports["sandbox-base"]:RegisterServerCallback("MDT:Hire", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)

		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'MDT_HIRE',
			'PD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		if char and data.SID and data.WorkplaceId and data.GradeId and (hasPerms or isSystemAdmin) then
			local added = exports['sandbox-jobs']:GiveJob(data.SID, data.JobId, data.WorkplaceId, data.GradeId, true)
			cb(added)

			if added then
				local currentHistory = MySQL.single.await('SELECT MDTHistory FROM characters WHERE SID = ?', { data.SID })
				local history = currentHistory and json.decode(currentHistory.MDTHistory) or {}

				table.insert(history, {
					Time = (os.time() * 1000),
					Char = char:GetData("SID"),
					Log = string.format(
						"%s Hired Them To %s",
						char:GetData("First") .. " " .. char:GetData("Last"),
						json.encode(data)
					),
				})

				MySQL.update.await('UPDATE characters SET MDTHistory = ? WHERE SID = ?', {
					json.encode(history),
					data.SID
				})
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("MDT:Fire", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)

		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'MDT_FIRE',
			'PD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		if char and data and data.SID and (hasPerms or isSystemAdmin) then
			local charData = exports['sandbox-mdt']:PeopleView(data.SID)
			if charData then
				local canRemove = false
				if isSystemAdmin then
					canRemove = true
				else
					local plyrJob = exports['sandbox-jobs']:HasJob(source, loggedInJob)
					for k, v in ipairs(charData.Jobs) do
						if v.Id == data.JobId then
							if plyrJob.Grade.Level > v.Grade.Level then
								canRemove = true
							end
							break
						end
					end
				end

				if canRemove then
					local removed = exports['sandbox-jobs']:RemoveJob(data.SID, data.JobId)
					cb(removed)

					if removed then
						local currentHistory = MySQL.single.await('SELECT MDTHistory FROM characters WHERE SID = ?',
							{ data.SID })
						local history = currentHistory and json.decode(currentHistory.MDTHistory) or {}

						table.insert(history, {
							Time = (os.time() * 1000),
							Char = char:GetData("SID"),
							Log = string.format(
								"%s Fired Them From Job %s",
								char:GetData("First") .. " " .. char:GetData("Last"),
								data.JobId
							),
						})

						local updateQuery = 'UPDATE characters SET MDTHistory = ?'
						local updateParams = { json.encode(history) }

						-- Add callsign update if needed
						if (data.JobId == "police" or data.JobId == "ems" or data.JobId == "prison") then
							updateQuery = updateQuery .. ', Callsign = NULL'
						end

						updateQuery = updateQuery .. ' WHERE SID = ?'
						table.insert(updateParams, data.SID)

						MySQL.update.await(updateQuery, updateParams, function(success, results)
							if success then
								if (data.JobId == "police" or data.JobId == "ems") then
									local char = exports['sandbox-characters']:FetchBySID(data.SID)
									if char then
										char:SetData("Callsign", false)
									end
								end
							end
						end)
					end
				else
					cb(false)
				end
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("MDT:ManageEmployment", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)

		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'MDT_FIRE',
			'PD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		local newJobData = exports['sandbox-jobs']:DoesExist(data.data.Id, data.data.Workplace.Id, data.data.Grade.Id)

		if char and data and data.SID and (hasPerms or isSystemAdmin) and newJobData then
			local charData = exports['sandbox-mdt']:PeopleView(data.SID)
			if charData then
				local canDoIt = false
				if isSystemAdmin then
					canDoIt = true
				else
					local plyrJob = exports['sandbox-jobs']:HasJob(source, loggedInJob)
					for k, v in ipairs(charData.Jobs) do
						if v.Id == data.JobId then
							if plyrJob.Grade.Level > v.Grade.Level and plyrJob.Grade.Level > newJobData.Grade.Level then
								canDoIt = true
							end
							break
						end
					end
				end

				if canDoIt then
					local updated = exports['sandbox-jobs']:GiveJob(data.SID, newJobData.Id, newJobData.Workplace.Id,
						newJobData.Grade.Id)

					cb(updated)

					if updated then
						local currentHistory = MySQL.single.await('SELECT MDTHistory FROM characters WHERE SID = ?',
							{ data.SID })
						local history = currentHistory and json.decode(currentHistory.MDTHistory) or {}

						table.insert(history, {
							Time = (os.time() * 1000),
							Char = char:GetData("SID"),
							Log = string.format(
								"%s Promoted Them To %s",
								char:GetData("First") .. " " .. char:GetData("Last"),
								json.encode(newJobData)
							),
						})

						MySQL.update.await('UPDATE characters SET MDTHistory = ? WHERE SID = ?', {
							json.encode(history),
							data.SID
						})
					end
				else
					cb(false)
				end
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("MDT:Update:jobPermissions", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'PD_HIGH_COMMAND',
			'SAFD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		local targetData = exports['sandbox-jobs']:DoesExist(data.JobId, data.WorkplaceId, data.GradeId)

		if char and data and data.UpdatedPermissions and (hasPerms or isSystemAdmin) and targetData then
			local plyrJob = exports['sandbox-jobs']:HasJob(source, loggedInJob)
			if isSystemAdmin or (plyrJob and plyrJob.Grade.Level > targetData.Grade.Level) then
				cb(
					exports['sandbox-jobs']:ManagementGradesEdit(data.JobId, data.WorkplaceId, data.GradeId, {
						Permissions = data.UpdatedPermissions,
					})
				)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("MDT:Suspend", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)

		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'MDT_FIRE',
			'PD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		if char and data and data.SID and (hasPerms or isSystemAdmin) then
			local charData = exports['sandbox-mdt']:PeopleView(data.SID)
			if charData then
				local canRemove = false
				if isSystemAdmin then
					canRemove = true
				else
					local plyrJob = exports['sandbox-jobs']:HasJob(source, loggedInJob)
					for k, v in ipairs(charData.Jobs) do
						if v.Id == data.JobId then
							if plyrJob.Grade.Level > v.Grade.Level then
								canRemove = true
							end
							break
						end
					end
				end

				if canRemove and data.Length and type(data.Length) == "number" and data.Length > 0 and data.Length < 99 then
					local suspendData = {
						Actioned = {
							First = char:GetData("First"),
							Last = char:GetData("Last"),
							SID = char:GetData("SID"),
							Callsign = char:GetData("Callsign")
						},
						Length = data.Length,
						Expires = os.time() + (60 * 60 * 24 * data.Length),
					}

					local currentData = MySQL.single.await(
						'SELECT MDTHistory, MDTSuspension FROM characters WHERE SID = ?', { data.SID })
					local history = currentData and json.decode(currentData.MDTHistory) or {}
					local suspension = currentData and json.decode(currentData.MDTSuspension) or {}

					table.insert(history, {
						Time = (os.time() * 1000),
						Char = char:GetData("SID"),
						Log = string.format(
							"%s Suspended Them From Job %s for %s Days",
							char:GetData("First") .. " " .. char:GetData("Last"),
							data.JobId,
							data.Length
						),
					})

					suspension[data.JobId] = suspendData

					MySQL.update.await('UPDATE characters SET MDTHistory = ?, MDTSuspension = ? WHERE SID = ?', {
						json.encode(history),
						json.encode(suspension),
						data.SID
					}, function(success, results)
						if success then
							local char = exports['sandbox-characters']:FetchBySID(data.SID)
							if char then
								char:SetData("MDTSuspension", suspension)
								exports['sandbox-jobs']:DutyOff(char:GetData("Source"), data.JobId)
							end

							cb(true)
						else
							cb(false)
						end
					end)
				else
					cb(false)
				end
			end
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("MDT:Unsuspend", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)

		local isSystemAdmin = char:GetData('MDTSystemAdmin')
		local hasPerms, loggedInJob = CheckMDTPermissions(source, {
			'MDT_FIRE',
			'PD_HIGH_COMMAND',
			'DOC_HIGH_COMMAND',
		}, data.JobId)

		if char and data and data.SID and (hasPerms or isSystemAdmin) then
			local charData = exports['sandbox-mdt']:PeopleView(data.SID)
			if charData then
				local canRemove = false
				if isSystemAdmin then
					canRemove = true
				else
					local plyrJob = exports['sandbox-jobs']:HasJob(source, loggedInJob)
					for k, v in ipairs(charData.Jobs) do
						if v.Id == data.JobId then
							if plyrJob.Grade.Level > v.Grade.Level then
								canRemove = true
							end
							break
						end
					end
				end

				if canRemove then
					local currentData = MySQL.single.await(
						'SELECT MDTHistory, MDTSuspension FROM characters WHERE SID = ?', { data.SID })
					local history = currentData and json.decode(currentData.MDTHistory) or {}
					local suspension = currentData and json.decode(currentData.MDTSuspension) or {}

					table.insert(history, {
						Time = (os.time() * 1000),
						Char = char:GetData("SID"),
						Log = string.format(
							"%s Revoked Suspension From Job %s",
							char:GetData("First") .. " " .. char:GetData("Last"),
							data.JobId
						),
					})

					suspension[data.JobId] = nil

					MySQL.update.await('UPDATE characters SET MDTHistory = ?, MDTSuspension = ? WHERE SID = ?', {
						json.encode(history),
						json.encode(suspension),
						data.SID
					}, function(success, results)
						if success then
							local char = exports['sandbox-characters']:FetchBySID(data.SID)
							if char then
								char:SetData("MDTSuspension", suspension)
							end

							cb(true)
						else
							cb(false)
						end
					end)
				else
					cb(false)
				end
			end
		else
			cb(false)
		end
	end)
end)

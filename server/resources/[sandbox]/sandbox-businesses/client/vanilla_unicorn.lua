local _makingItRain = false

local poleDances = {
    {
        anim = 'vanilla_unicorn_1',
        offset = {
            x = 0.05,
            y = 0.28,
            z = 0.0,
        },
    },
    {
        anim = 'vanilla_unicorn_2',
        offset = {
            x = 0.02,
            y = 0.26,
            z = 0.0,
        },
    },
    {
        anim = 'vanilla_unicorn_3',
        offset = {
            x = 0.02,
            y = 0.27,
            z = 0.0,
        },
    },
}

local poles = {
    vector3(108.77, -1289.29, 29.15),
    vector3(102.22, -1290.15, 29.15),
    vector3(104.77, -1294.47, 29.15),
}

AddEventHandler('Businesses:Client:Startup', function()
    exports['sandbox-polyzone']:CreatePoly('vu_dancers', {
        vector2(110.14764404297, -1288.5469970703),
        vector2(109.54054260254, -1287.9322509766),
        vector2(108.68753814697, -1287.7067871094),
        vector2(107.8295135498, -1287.9362792969),
        vector2(104.40329742432, -1289.8876953125),
        vector2(103.48906707764, -1288.9411621094),
        vector2(102.3109664917, -1288.6119384766),
        vector2(101.24118804932, -1288.8521728516),
        vector2(99.687141418457, -1289.7570800781),
        vector2(103.85342407227, -1296.9898681641),
        vector2(105.42902374268, -1296.0789794922),
        vector2(106.14443969727, -1295.3077392578),
        vector2(106.42623901367, -1294.5275878906),
        vector2(106.38809967041, -1293.484375),
        vector2(106.094871521, -1292.8369140625),
        vector2(109.8875579834, -1290.5808105469),
        vector2(110.29723358154, -1289.8250732422),
        vector2(110.36149597168, -1289.2088623047)
	}, {
		--debugPoly=true,
        minZ = 27.260225296021,
        maxZ = 30.55025100708
	})

    exports['sandbox-polyzone']:CreatePoly('vu_makeitrain', {
        vector2(104.21175384521, -1297.1346435547),
        vector2(104.99973297119, -1298.6086425781),
        vector2(113.97306060791, -1293.412109375),
        vector2(113.52625274658, -1286.7082519531),
        vector2(107.37281799316, -1281.9864501953),
        vector2(98.141731262207, -1287.2725830078),
        vector2(99.483924865723, -1289.4855957031),
        vector2(101.45595550537, -1288.3804931641),
        vector2(103.17757415771, -1288.3211669922),
        vector2(104.57252502441, -1289.3887939453),
        vector2(108.11382293701, -1287.3522949219),
        vector2(109.26777648926, -1287.4691162109),
        vector2(109.87437438965, -1287.6860351562),
        vector2(110.42655944824, -1288.3610839844),
        vector2(110.77745819092, -1289.4063720703),
        vector2(109.9483795166, -1291.0191650391),
        vector2(106.52938842773, -1292.9887695312),
        vector2(106.81593322754, -1294.2302246094),
        vector2(106.53350830078, -1295.4333496094),
        vector2(105.7345199585, -1296.3322753906)
	}, {
		--debugPoly=true,
        minZ = 26.260225296021,
        maxZ = 28.55025100708
	})

    exports['sandbox-hud']:InteractionRegisterMenu("vu_stripper_pole", "Vanilla Unicorn Dancers", "party-horn", function()
        if exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), 'vu_dancers') and LocalPlayer.state.onDuty == 'unicorn' and exports['sandbox-jobs']:HasPermissionInJob('unicorn', 'STRIP_POLE') then
            local subMenu = {}

            for k, v in ipairs(poleDances) do
                table.insert(subMenu, {
                    icon = 'circle-' .. k,
                    label = 'Dance '.. k,
                    action = function()
                        TriggerEvent('Businesses:Client:PoleDance', k)
                        exports['sandbox-hud']:InteractionHide()
                    end,
                })
            end

            exports['sandbox-hud']:InteractionShowMenu(subMenu)
        else
            exports["sandbox-hud"]:Notification("error", 'Invalid Permissions')
        end
    end, function()
        return exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), 'vu_dancers') and LocalPlayer.state.onDuty == 'unicorn'
    end)

    exports['sandbox-hud']:InteractionRegisterMenu("vu_makeitrain", 'Make It Rain', "money-bill-1-wave", function()
        if not _makingItRain and exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), 'vu_makeitrain') then
            local makeItRain = {
                {
                    type = 'cash',
                    text = '$100 Cash',
                    time = math.random(8000, 12000),
                },
                {
                    type = 'moneyroll',
                    text = 'Money Rolls',
                    time = math.random(8000, 12000),
                },
                {
                    type = 'moneyband',
                    text = 'Money Bands',
                    time = math.random(8000, 12000),
                }
            }

            local subMenu = {}

            for k, v in ipairs(makeItRain) do
                if v.type == 'cash' or exports.ox_inventory:CheckPlayerHasItem(v.type, 1) then
                    table.insert(subMenu, {
                        icon = 'money-bill-1-wave',
                        label = v.text,
                        action = function()
                            local nearestStripper = GetNearbyStripper()
                            if nearestStripper then
                                MakeItRain(nearestStripper, v.type, v.time)
                            end

                            exports['sandbox-hud']:InteractionHide()
                        end,
                    })
                end
            end

            exports['sandbox-hud']:InteractionShowMenu(subMenu)
        end
    end, function()
        return exports['sandbox-polyzone']:IsCoordsInZone(GetEntityCoords(LocalPlayer.state.ped), 'vu_makeitrain') and GetNearbyStripper()
    end)
end)

RegisterNetEvent('Businesses:Client:PoleDance', function(dance)
    local pedCoords = GetEntityCoords(LocalPlayer.state.ped)
    for k, v in ipairs(poles) do
        if #(v - pedCoords) <= 1.5 then
            local cPlayer, dist = exports['sandbox-base']:GamePlayersGetClosestPlayer()

            if dist == -1 or dist > 1.5 then
                local poleDance = poleDances[dance]
                if poleDance then
                    SetEntityCoords(
                        PlayerPedId(),
                        v.x + poleDance.offset.x,
                        v.y + poleDance.offset.y,
                        v.z + poleDance.offset.z
                    )
                    SetEntityRotation(PlayerPedId(), 0.0, 0.0, 0.0)

                    exports['sandbox-animations']:EmotesPlay(poleDance.anim, false, false, false)
                end
            else
                exports["sandbox-hud"]:Notification("error", 'Pole Taken')
            end
            return
        end
    end
end)

function MakeItRain(targetSource, cashType, time)
    local targetPlayer = GetPlayerFromServerId(targetSource)
    if targetPlayer == -1 then return end

    local targetPed = GetPlayerPed(targetPlayer)

    CreateThread(function()
        _makingItRain = true
        exports['sandbox-animations']:EmotesPlay('makeitrain', false, false, false)

        Wait(7500)

        while 
            _makingItRain
            and LocalPlayer.state.loggedIn
            and exports['sandbox-animations']:EmotesGet() == 'makeitrain'
            and IsDoingStripperDance(Player(targetSource).state.anim)
            and (#(GetEntityCoords(LocalPlayer.state.ped) - GetEntityCoords(targetPed)) <= 5.0)
        do
            local p = promise.new()
            exports["sandbox-base"]:ServerCallback('VU:MakeItRain', {
                target = targetSource,
                type = cashType,
            }, function(success, cd)
                if not success then
                    exports["sandbox-hud"]:Notification("error", cd and 'Reached Cooldown' or 'Error - Ran Out of Money')
                    _makingItRain = false
                end

                p:resolve(success)
            end)

            Citizen.Await(p)
            Wait(time)
        end

        _makingItRain = false
        exports['sandbox-animations']:EmotesForceCancel()
    end)
end

local stripperAnims = {
	.vanilla_unicorn_1,
	.vanilla_unicorn_2,
	.vanilla_unicorn_3,
    .lapdance,
    .lapdance2,
    .lapdance3,
    .lapdance4,
}

function IsDoingStripperDance(anim)
    return anim and stripperAnims[anim]
end

function GetNearbyStripper()
    local myCoords = GetEntityCoords(LocalPlayer.state.ped)
    local closest, lastDist = nil, 1000.0

    for k, v in ipairs(GetActivePlayers()) do
        local dist = #(myCoords - GetEntityCoords(GetPlayerPed(v)))
        if v ~= LocalPlayer.state.PlayerID and dist <= 5.0 then
            local pSrc = GetPlayerServerId(v)
            local pAnim = Player(pSrc).state.anim
            if IsDoingStripperDance(pAnim) then
                if (not closest) or (dist < lastDist) then
                    closest = pSrc
                    lastDist = dist
                end
            end
        end
    end

    return closest
end
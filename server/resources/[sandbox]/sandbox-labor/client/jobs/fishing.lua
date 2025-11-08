local _joiner = nil
local _working = false
local _blip = nil
local _state = nil
local eventHandlers = {}

--[[ Water Types

    1 - The Alamo Sea
    2 - Zancudo River
    3 - Raton Canyon River
    4 - The Dirty Ocean (The Docks, Marina Etc)
    5 - The Ocean
    6 - The Deep Ocean
]]

local fishingRodProp = `prop_fishing_rod_01`

local fishingRodObj = false
local _isFishing = false
local _nextBite = 0
local _fishingTool = "rod"

local fishingStores = {
    {
        coords = vector3(-3272.512, 965.255, 7.347),
        heading = 356.960,
    },
    {
        coords = vector3(3844.895, 4465.122, 1.670),
        heading = 175.644,
    },
    {
        coords = vector3(-1510.558, 1501.126, 114.247),
        heading = 167.951,
    }
}

local basicFish = {
    'fishing_chub',
    'fishing_grasscarp',
    'fishing_kelp',
    'fishing_bass',
    'fishing_rockfish',
}

AddEventHandler("Labor:Client:Setup", function()
    exports['sandbox-polyzone']:CreatePoly("fishing_river_zancudo", {
        vector2(156.34146118164, 3416.5373535156),
        vector2(128.61988830566, 3429.1630859375),
        vector2(-4.1847929954529, 3131.1550292969),
        vector2(-385.41110229492, 3030.3640136719),
        vector2(-521.85919189453, 2940.4206542969),
        vector2(-611.39587402344, 2999.7316894531),
        vector2(-817.06158447266, 2846.4541015625),
        vector2(-1063.9602050781, 2857.0825195312),
        vector2(-1417.333984375, 2681.095703125),
        vector2(-1550.1071777344, 2669.7517089844),
        vector2(-1688.5454101562, 2620.5500488281),
        vector2(-1702.6722412109, 2608.5964355469),
        vector2(-1689.6525878906, 2533.6672363281),
        vector2(-1472.0501708984, 2259.0534667969),
        vector2(-1653.7375488281, 2087.4855957031),
        vector2(-1642.7261962891, 2067.1545410156),
        vector2(-1583.6302490234, 2108.45703125),
        vector2(-1507.2590332031, 2198.5747070312),
        vector2(-1452.6403808594, 2224.5710449219),
        vector2(-1473.6901855469, 2045.4519042969),
        vector2(-1489.3684082031, 1975.9553222656),
        vector2(-1587.6931152344, 1665.5855712891),
        vector2(-1574.2586669922, 1460.9252929688),
        vector2(-1522.4880371094, 1449.9332275391),
        vector2(-1476.4245605469, 1604.8458251953),
        vector2(-1506.4636230469, 1717.5865478516),
        vector2(-1423.5811767578, 1912.7875976562),
        vector2(-1388.8189697266, 1999.134765625),
        vector2(-1429.7462158203, 2089.4140625),
        vector2(-1400.3134765625, 2172.4377441406),
        vector2(-1478.5788574219, 2549.68359375),
        vector2(-1220.4794921875, 2624.7009277344),
        vector2(-1112.3740234375, 2743.3962402344),
        vector2(-861.7783203125, 2732.9248046875),
        vector2(-522.68151855469, 2848.3520507812),
        vector2(-433.59475708008, 2905.1740722656),
        vector2(-208.30116271973, 2946.1721191406),
        vector2(-43.203388214111, 3078.1962890625),
        vector2(101.15602111816, 3113.7119140625)
    }, {}, { fishing_river = 2 })

    exports['sandbox-polyzone']:CreatePoly("fishing_river_raton", {
        vector2(-181.28651428223, 4224.3120117188),
        --vector2(-449.234, 4569.082),
        vector2(-140.56726074219, 4259.6186523438),
        vector2(-232.58000183105, 4393.7534179688),
        vector2(-388.110, 4547.980),
        vector2(-917.07281494141, 4554.1264648438),
        vector2(-1490.05078125, 4463.3549804688),
        vector2(-1786.0909423828, 4612.9130859375),
        vector2(-1820.4611816406, 4549.798828125),
        vector2(-1776.2188720703, 4472.4409179688),
        vector2(-1629.1462402344, 4404.3071289062),
        vector2(-1557.6005859375, 4319.873046875),
        vector2(-1391.895, 4300.429),
        vector2(-1171.4047851562, 4359.2016601562),
        vector2(-1024.1809082031, 4360.072265625),
        vector2(-942.97369384766, 4354.1171875),
        vector2(-859.63757324219, 4398.9892578125),
        vector2(-688.00384521484, 4388.7587890625),
        vector2(-425.33764648438, 4378.6943359375),
        vector2(-352.85482788086, 4384.9453125),
        vector2(-279.20379638672, 4260.0610351562),
    }, {}, { fishing_river = 3 })

    exports['sandbox-polyzone']:CreatePoly("fishing_ocean_shitty1", {
        vector2(-1837.213, -965.995),
        vector2(-1276.9390869141, -1926.0460205078),
        vector2(-688.33306884766, -2526.37109375),
        vector2(-812.68292236328, -2742.4184570312),
        vector2(-921.12255859375, -3129.5651855469),
        vector2(-734.62750244141, -3236.4594726562),
        vector2(110.29835510254, -3236.3835449219),
        vector2(295.42697143555, -3339.5454101562),
        vector2(502.4069519043, -3390.35546875),
        vector2(1309.744140625, -3458.7744140625),
        vector2(1387.8170166016, -2711.8740234375),
        vector2(708.54425048828, -1641.7926025391),
        vector2(-735.48138427734, -1294.2583007812),
        vector2(-1663.170, -794.495),
    }, {}, {
        fishing_shitty_ocean_water = true,
    })

    exports['sandbox-polyzone']:CreateCircle("fishing_ocean_shitty2", vector3(-2216.9, 2559.83, 66.16), 519.25, {}, {
        fishing_shitty_ocean_water = true,
    })

    exports['sandbox-polyzone']:CreateCircle("fishing_ocean_shitty3", vector3(-1796.15, -1182.05, 13.01), 95, {}, {
        fishing_shitty_ocean_water = true,
    })

    exports['sandbox-polyzone']:CreateCircle("fishing_ocean_shitty4", vector3(-3374.96, 968.46, 8.29), 69.0, {}, {
        fishing_shitty_ocean_water = true,
    })

    exports['sandbox-polyzone']:CreatePoly("fishing_deep_ocean_water", {
        vector2(-1010.61, -4428.79),
        vector2(-2950.00, -3386.36),
        vector2(-3046.97, -1956.06),
        vector2(-3871.21, -719.70),
        vector2(-4234.85, 880.30),
        vector2(-3992.42, 2674.24),
        vector2(-3362.12, 4540.91),
        vector2(-2368.18, 6092.42),
        vector2(-1131.82, 6843.94),
        vector2(-307.58, 7886.36),
        vector2(-28.79, 8128.79),
        vector2(498.48, 8122.73),
        vector2(940.91, 7904.55),
        vector2(1534.85, 7613.64),
        vector2(2686.36, 7540.91),
        vector2(3462.12, 7140.91),
        vector2(4068.18, 6546.97),
        vector2(4146.97, 5625.76),
        vector2(4407.58, 4965.15),
        vector2(4759.09, 4231.82),
        vector2(4746.97, 3431.82),
        vector2(4340.91, 2722.73),
        vector2(3977.27, 1898.48),
        vector2(3874.24, 1025.76),
        vector2(3916.67, 419.70),
        vector2(3801.52, -695.45),
        vector2(3559.09, -2356.06),
        vector2(2940.91, -3125.76),
        vector2(2031.82, -3756.06),
        vector2(1256.06, -4095.45)
    }, {})

    local shopData = {
        {
            icon = "cart-shopping",
            text = "Shop",
            onSelect = function()
                TriggerEvent("Fishing:Client:OpenShop", { type = "FishingSupplies" })
            end,
            isEnabled = function()
                return exports['sandbox-characters']:RepGetLevel("Fishing") < 3
            end,
        },
        {
            icon = "cart-shopping",
            text = "Advanced Shop",
            onSelect = function()
                TriggerEvent("Fishing:Client:OpenShop", { type = "FishingSuppliesAdvanced" })
            end,
            rep = {
                id = "Fishing",
                level = 3,
            },
        },
    }

    Wait(2000)

    for k, v in ipairs(basicFish) do
        local fishData = exports.ox_inventory:ItemsGetData(v)

        if fishData then
            table.insert(shopData, {
                icon = "sack-dollar",
                text = string.format("Sell %s ($%s)", fishData.label, fishData.price),
                onSelect = function()
                    TriggerEvent("Fishing:Client:Sell", v)
                end,
                --rep = { id = "Hunting", level = 0 },
            })
        end
    end

    for k, v in ipairs(fishingStores) do
        exports['sandbox-pedinteraction']:Add(string.format("FishingJob%s", k), `a_m_m_hillbilly_01`, v.coords, v
            .heading, 25.0, shopData,
            "fishing-rod")
    end
end)

-- Returns if they can fish and what zone they are in
function CanFishHere()
    local offsetCoords = GetOffsetFromEntityInWorldCoords(LocalPlayer.state.ped, 0.0, 1.5, 0.75)
    local result, hittingCoord = TestProbeAgainstAllWater(offsetCoords.x, offsetCoords.y, offsetCoords.z + 1.0,
        offsetCoords.x, offsetCoords.y, offsetCoords.z - 35.0, 19)
    if result == 1 then
        local result2, height = GetWaterHeightNoWaves(hittingCoord.x, hittingCoord.y, hittingCoord.z)
        if result2 then
            if height <= 0.5 then
                if exports['sandbox-polyzone']:IsCoordsInZone(offsetCoords, false, "fishing_shitty_ocean_water") then
                    return 4
                elseif exports['sandbox-polyzone']:IsCoordsInZone(offsetCoords, "fishing_deep_ocean_water") then
                    return 5
                else
                    return 6
                end
            elseif height >= 28.0 and height <= 32.0 then
                return 1
            end
        else
            local inRiverZone = exports['sandbox-polyzone']:IsCoordsInZone(offsetCoords, false, "fishing_river")
            if inRiverZone and inRiverZone.fishing_river then
                return inRiverZone.fishing_river
            end
        end
    end
    return false
end

RegisterNetEvent("Fishing:Client:StartFishing", function(toolUsed)
    local fishingZone = CanFishHere()
    local fishingLocation = GetEntityCoords(LocalPlayer.state.ped)

    if _isFishing then
        exports["sandbox-hud"]:Notification("error", "Already Fishing")
        return
    end

    if not fishingZone then
        exports["sandbox-hud"]:Notification("error", "Cannot Fish Here")
        return
    end

    if LocalPlayer.state.doingAction then
        exports["sandbox-hud"]:Notification("error", "Already Doing Something")
        return
    end

    if toolUsed == "net" and not IsNearBoat() then
        exports["sandbox-hud"]:Notification("error", "Have to Use a Fishing Net on a Boat")
        return
    end

    _isFishing = true

    StartFishingControlBlockers()

    if toolUsed == "rod" then
        StartFishingAnimation()
    else
        StartFishingNetAnimation()
    end

    if fishingZone == 4 or fishingZone == 5 then
        exports["sandbox-hud"]:Notification("info",
            string.format("Fishing - Press %s to Stop. Maybe you could try some deeper water for better fish!",
                exports["sandbox-kbs"]:GetKey("cancel_action")),
            -1,
            "fishing-rod",
            nil,
            "fishing-info-notif")
    else
        exports["sandbox-hud"]:Notification("info",
            string.format("Fishing - Press %s to Stop", exports["sandbox-kbs"]:GetKey("cancel_action")),
            -1,
            "fishing-rod",
            nil,
            "fishing-info-notif")
    end

    local tick = 0
    if _nextBite <= 0 or (_fishingTool ~= toolUsed) then
        _nextBite = GenerateNextFishTime(fishingZone, toolUsed)
    end

    _fishingTool = toolUsed

    while _isFishing
        and LocalPlayer.state.loggedIn
        and CanFishHere() == fishingZone
        and #(fishingLocation - GetEntityCoords(LocalPlayer.state.ped)) <= 20.0
        and not IsPedSwimming(LocalPlayer.state.ped) do
        tick += 1

        if tick >= _nextBite then
            DoFishBite(fishingZone, toolUsed)
            _nextBite = GenerateNextFishTime(fishingZone, toolUsed)
            tick = 0
        end

        Wait(500)
    end

    _isFishing = false
    exports["sandbox-hud"]:Notification("remove", nil, nil, nil, nil, "fishing-info-notif")
end)

function DoFishBite(zone, toolUsed)
    if toolUsed == "rod" then
        DoFishingCatchingAnimation(toolUsed)
    else
        -- I Don't Know
    end

    local difficultyWeights = {
        { 50, 1 },
        { 35, 2 },
        { 15, 3 },
        { 3,  4 },
    }

    -- Ultra Deep Areas (Whales)
    if zone >= 7 and toolUsed == "net" then
        difficultyWeights = {
            { 10, 1 },
            { 15, 2 },
            { 15, 3 },
            { 30, 4 },
            { 20, 5 },
            { 10, 6 },
        }
    elseif zone >= 5 then
        difficultyWeights = {
            { 10, 1 },
            { 20, 2 },
            { 30, 3 },
            { 15, 4 },
        }

        if toolUsed == "net" then
            table.insert(difficultyWeights, { 10, 5 })
        end
    end

    local maxDiff = exports['sandbox-base']:UtilsWeightedRandom(difficultyWeights)

    for i = 1, maxDiff, 1 do
        if not DoFishingSkillbar(1.0 + (0.2 * maxDiff), 13 - maxDiff) then
            return false
        end

        Wait(100)
    end

    exports["sandbox-base"]:ServerCallback("Fishing:Catch", {
        zone = zone,
        toolUsed = toolUsed,
        difficulty = maxDiff,
    }, function(success, stopFishing)
        if not success and not stopFishing then
            exports["sandbox-hud"]:Notification("warning", "The Fish Got Away...", 5000, "fishing-rod")
        end

        if stopFishing then
            print("Stopping the Fishing")
            _isFishing = false
        end
    end)

    return true
end

function DoFishingSkillbar(timeLength, area)
    local p = promise.new()
    exports['sandbox-games']:MinigamePlayRoundSkillbar(timeLength, area, {
        onSuccess = function()
            p:resolve(true)
        end,
        onFail = function()
            p:resolve(false)
        end,
    }, {
        animation = false,
    })

    return Citizen.Await(p)
end

function HasCorrectBaitForZone(zone)
    local requiredBait = _fishingZoneBasicBait[zone]
    if requiredBait and exports.ox_inventory:CheckPlayerHasItem(requiredBait, 1) then
        return true
    end
    return false
end

function GenerateNextFishTime(zone, toolUsed)
    local correctBait = HasCorrectBaitForZone(zone)

    local minTime = 40 -- Seconds

    if not correctBait then
        minTime += 30
    end

    if zone == 4 or zone == 5 then -- Add more time for these
        minTime += 60
    elseif zone > 6 then
        minTime += 30
    end

    if toolUsed == "net" then
        -- Net Takes Longer But You get More Fishies
        minTime += 100
    end

    return math.random(minTime, minTime + 30)
end

RegisterNetEvent("Fishing:Client:OnDuty", function(joiner, time)
    _joiner = joiner
    DeleteWaypoint()
    SetNewWaypoint(fishingStores[1].coords.x, fishingStores[1].coords.y)
    _blip = exports["sandbox-blips"]:Add("FishingStart", "Shop Owner",
        { x = fishingStores[1].coords.x, y = fishingStores[1].coords.y, z = fishingStores[1].coords.z }, 480, 2, 1.4)

    eventHandlers["startup"] = RegisterNetEvent(string.format("Fishing:Client:%s:Startup", joiner), function()
        _working = true
        _state = 1

        if _blip ~= nil then
            exports["sandbox-blips"]:Remove("FishingStart")
            RemoveBlip(_blip)
        end
    end)

    eventHandlers["finish"] = RegisterNetEvent(string.format("Fishing:Client:%s:Finish", joiner), function()
        _state = 2
        if _blip ~= nil then
            exports["sandbox-blips"]:Remove("FishingStart")
            RemoveBlip(_blip)
        end
        _blip = exports["sandbox-blips"]:Add("FishingStart", "Shop Owner",
            { x = fishingStores[1].coords.x, y = fishingStores[1].coords.y, z = fishingStores[1].coords.z }, 480, 2, 1.4)
    end)

    eventHandlers["end"] = RegisterNetEvent(string.format("Fishing:Client:%s:FinishJob", joiner), function()
        _state = 3
    end)
end)

RegisterNetEvent("Fishing:Client:OffDuty", function(time)
    for k, v in pairs(eventHandlers) do
        RemoveEventHandler(v)
    end

    if _blip ~= nil then
        exports["sandbox-blips"]:Remove("FishingStart")
        RemoveBlip(_blip)
    end

    eventHandlers = {}
    _joiner = nil
    _state = nil
    _working = false
    _blip = nil
end)

AddEventHandler("Fishing:Client:OpenShop", function(data)
    exports.ox_inventory:openInventory("shop", { type = data.type })
end)

AddEventHandler("Fishing:Client:Sell", function(data)
    exports["sandbox-base"]:ServerCallback("Fishing:Sell", data)
end)


AddEventHandler("Keybinds:Client:KeyUp:cancel_action", function()
    if _isFishing then
        _isFishing = false
    end
end)

function IsNearBoat()
    local coords = GetEntityCoords(LocalPlayer.state.ped)
    local poolVehicles = GetGamePool('CVehicle')
    local lastDist = 10.0
    local lastVeh = false

    for k, v in ipairs(poolVehicles) do
        if DoesEntityExist(v) and GetVehicleClass(v) == 14 then
            local dist = #(coords - GetEntityCoords(v))
            if dist <= lastDist then
                lastDist = dist
                lastVeh = v
            end
        end
    end

    return lastVeh
end

function StartFishingAnimation()
    LoadAnim("amb@world_human_stand_fishing@base")
    LoadAnim("amb@world_human_stand_fishing@idle_a")
    if not HasModelLoaded(fishingRodProp) then
        LoadPropDict(fishingRodProp)
    end

    fishingRodObj = CreateObject(fishingRodProp, GetEntityCoords(LocalPlayer.state.ped), true, true, true)
    AttachEntityToEntity(fishingRodObj, LocalPlayer.state.ped, GetPedBoneIndex(LocalPlayer.state.ped, 60309), 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    CreateThread(function()
        while _isFishing and LocalPlayer.state.loggedIn do
            if not IsEntityPlayingAnim(LocalPlayer.state.ped, "amb@world_human_stand_fishing@base", "base", 3) and not IsEntityPlayingAnim(LocalPlayer.state.ped, "amb@world_human_stand_fishing@idle_a", "idle_c", 3) then
                TaskPlayAnim(LocalPlayer.state.ped, "amb@world_human_stand_fishing@base", "base", 3.0, 3.0, -1, 49, 0,
                    false, false, false)
            end
            Wait(250)
        end

        StopAnimTask(LocalPlayer.state.ped, "amb@world_human_stand_fishing@base", "base", 3.0)
        StopAnimTask(LocalPlayer.state.ped, "amb@world_human_stand_fishing@idle_a", "idle_c", 3.0)
        DeleteEntity(fishingRodObj)
    end)
end

function DoFishingCatchingAnimation()
    CreateThread(function()
        TaskPlayAnim(LocalPlayer.state.ped, "amb@world_human_stand_fishing@idle_a", "idle_c", 3.0, 3.0, -1, 49, 0, false,
            false, false)
        StopAnimTask(LocalPlayer.state.ped, "amb@world_human_stand_fishing@base", "base", 3.0)
        Wait(5000)

        if _isFishing then
            TaskPlayAnim(LocalPlayer.state.ped, "amb@world_human_stand_fishing@base", "base", 3.0, 3.0, -1, 49, 0, false,
                false, false)
            StopAnimTask(LocalPlayer.state.ped, "amb@world_human_stand_fishing@idle_a", "idle_c", 3.0)
        end
    end)
end

function StartFishingNetAnimation()
    LoadAnim("amb@world_human_bum_wash@male@low@idle_a")

    CreateThread(function()
        while _isFishing and LocalPlayer.state.loggedIn do
            if not IsEntityPlayingAnim(LocalPlayer.state.ped, "amb@world_human_bum_wash@male@low@idle_a", "idle_a", 3) then
                TaskPlayAnim(LocalPlayer.state.ped, "amb@world_human_bum_wash@male@low@idle_a", "idle_a", 3.0, 3.0, -1,
                    49, 0, false, false, false)
            end
            Wait(250)
        end

        StopAnimTask(LocalPlayer.state.ped, "amb@world_human_bum_wash@male@low@idle_a", "idle_a", 3.0)
    end)
end

-- function DoFishingNetCatchingAnimation()
    -- TODO
-- end

function StartFishingControlBlockers()
    CreateThread(function()
        while _isFishing do
            DisablePlayerFiring(PlayerId(), true) -- Disable weapon firing
            DisableControlAction(0, 24, true)     -- disable attack
            DisableControlAction(0, 25, true)     -- disable aim
            DisableControlAction(1, 37, true)     -- disable weapon select
            DisableControlAction(0, 47, true)     -- disable weapon
            DisableControlAction(0, 58, true)     -- disable weapon
            DisableControlAction(0, 140, true)    -- disable melee
            DisableControlAction(0, 141, true)    -- disable melee
            DisableControlAction(0, 142, true)    -- disable melee
            DisableControlAction(0, 143, true)    -- disable melee
            DisableControlAction(0, 263, true)    -- disable melee
            DisableControlAction(0, 264, true)    -- disable melee
            DisableControlAction(0, 257, true)    -- disable melee

            Wait(1)
        end
    end)
end

function LoadAnim(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(10)
    end
end

function LoadPropDict(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(10)
    end
end

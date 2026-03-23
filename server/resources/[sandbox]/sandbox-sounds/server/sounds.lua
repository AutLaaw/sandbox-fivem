AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        RegisterCallbacks()
    end
end)

exports("PlayOne", function(clientNetId, soundFile, soundVolume)
    TriggerClientEvent("Sounds:Client:Play:One", clientNetId, soundFile, soundVolume)
end)

exports("PlayDistance", function(clientNetId, maxDistance, soundFile, soundVolume)
    TriggerClientEvent("Sounds:Client:Play:Distance", -1, clientNetId, maxDistance, soundFile, soundVolume)
end)

exports("PlayLocation", function(clientNetId, location, maxDistance, soundFile, soundVolume)
    TriggerClientEvent(
        "Sounds:Client:Play:Location",
        -1,
        clientNetId,
        location,
        maxDistance,
        soundFile,
        soundVolume
    )
end)

exports("PlayAll", function(clientNetId, soundFile, soundVolume)
    TriggerClientEvent("Sounds:Client:Play:One", -1, clientNetId, soundFile, soundVolume)
end)

exports("PlayJob", function(clientNetId, soundFile, job, soundVolume)
    for _, src in ipairs(GetPlayers()) do
        local duty = Player(src).state.onDuty
        if duty and job[duty] then
            TriggerClientEvent(
                "Sounds:Client:Play:One",
                src,
                clientNetId,
                soundFile,
                soundVolume
            )
        end
    end
end)

exports("LoopOne", function(clientNetId, soundFile, soundVolume)
    TriggerClientEvent("Sounds:Client:Loop:One", clientNetId, soundFile, soundVolume)
end)

exports("LoopDistance", function(clientNetId, maxDistance, soundFile, soundVolume)
    TriggerClientEvent("Sounds:Client:Loop:Distance", -1, clientNetId, maxDistance, soundFile, soundVolume)
end)

exports("LoopLocation", function(clientNetId, location, maxDistance, soundFile, soundVolume)
    TriggerClientEvent(
        "Sounds:Client:Loop:Location",
        -1,
        clientNetId,
        location,
        maxDistance,
        soundFile,
        soundVolume
    )
end)

exports("StopOne", function(clientNetId, soundFile)
    TriggerClientEvent("Sounds:Client:Stop:One", clientNetId, soundFile)
end)

exports("StopDistance", function(clientNetId, soundFile)
    TriggerClientEvent("Sounds:Client:Stop:Distance", -1, clientNetId, soundFile)
end)

exports("StopLocation", function(clientNetId, soundFile)
    TriggerClientEvent("Sounds:Client:Stop:Distance", -1, clientNetId, soundFile)
end)

function RegisterCallbacks()

    exports["sandbox-base"]:RegisterServerCallback("Sounds:Play:Distance", function(source, data, cb)
        exports["sandbox-sounds"]:PlayDistance(
            source,
            data.maxDistance,
            data.soundFile,
            data.soundVolume
        )
        cb(true)
    end)

    exports["sandbox-base"]:RegisterServerCallback("Sounds:Play:Location", function(source, data, cb)
        exports["sandbox-sounds"]:PlayLocation(
            source,
            data.location,
            data.maxDistance,
            data.soundFile,
            data.soundVolume
        )
        cb(true)
    end)

    exports["sandbox-base"]:RegisterServerCallback("Sounds:Loop:Distance", function(source, data, cb)
        exports["sandbox-sounds"]:LoopDistance(
            source,
            data.maxDistance,
            data.soundFile,
            data.soundVolume
        )
        cb(true)
    end)

    exports["sandbox-base"]:RegisterServerCallback("Sounds:Loop:Location", function(source, data, cb)
        -- normalize location payload
        local loc = data.location
        if type(loc) == "vector3" then
            loc = { x = loc.x, y = loc.y, z = loc.z }
        end

        TriggerClientEvent(
            "Sounds:Client:DoLoopLocation",
            -1,
            data.playerNetId or source,
            loc,
            data.maxDistance,
            data.soundFile,
            data.soundVolume
        )

        cb(true)
    end)

    exports["sandbox-base"]:RegisterServerCallback("Sounds:Stop:Distance", function(source, data, cb)
        local key = data.playerNetId or source
        TriggerClientEvent("Sounds:Client:Stop:Distance", -1, key, data.soundFile)
        cb(true)
    end)
end

AddEventHandler("Characters:Server:PlayerLoggedOut", function(source)
    TriggerClientEvent("Sounds:Client:Stop:All", -1, source)
end)

AddEventHandler("Characters:Server:PlayerDropped", function(source)
    TriggerClientEvent("Sounds:Client:Stop:All", -1, source)
end)

AddEventHandler("Sounds:Server:Play:One", function(soundFile, soundVolume)
    exports["sandbox-sounds"]:PlayOne(source, soundFile, soundVolume)
end)

AddEventHandler("Sounds:Server:Play:Distance", function(playerNetId, maxDistance, soundFile, soundVolume)
    exports["sandbox-sounds"]:PlayDistance(playerNetId, maxDistance, soundFile, soundVolume)
end)

AddEventHandler("Sounds:Server:Play:All", function(playerNetId, soundFile, soundVolume)
    exports["sandbox-sounds"]:PlayAll(playerNetId, soundFile, soundVolume)
end)

AddEventHandler("Sounds:Server:Play:Job", function(playerNetId, soundFile, job, soundVolume)
    exports["sandbox-sounds"]:PlayJob(playerNetId, soundFile, job, soundVolume)
end)

AddEventHandler("Sounds:Server:Loop:One", function(soundFile, soundVolume)
    exports["sandbox-sounds"]:LoopOne(source, soundFile, soundVolume)
end)

AddEventHandler("Sounds:Server:Loop:Distance", function(playerNetId, maxDistance, soundFile, soundVolume)
    exports["sandbox-sounds"]:LoopDistance(playerNetId, maxDistance, soundFile, soundVolume)
end)

AddEventHandler("Sounds:Server:Stop:One", function(soundFile)
    exports["sandbox-sounds"]:StopOne(source, soundFile)
end)

AddEventHandler("Sounds:Server:Stop:Distance", function(playerNetId, soundFile)
    exports["sandbox-sounds"]:StopDistance(playerNetId, soundFile)
end)

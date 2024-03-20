--[[

              |------------------------------------|
              |            سكربت الحركات          |
              |   https://discord.gg/PWnxxHcpbr    |
              | -----------------------------------|
              

 █████╗ ██████╗  █████╗ ██████╗    █████╗  █████╗ ██████╗ ███████╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗  ██╔══██╗██╔══██╗██╔══██╗██╔════╝
███████║██████╔╝███████║██████╦╝  ██║  ╚═╝██║  ██║██████╔╝█████╗
██╔══██║██╔══██╗██╔══██║██╔══██╗  ██║  ██╗██║  ██║██╔══██╗██╔══╝
██║  ██║██║  ██║██║  ██║██████╦╝  ╚█████╔╝╚█████╔╝██║  ██║███████╗
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝    ╚════╝  ╚════╝ ╚═╝  ╚═╝╚══════╝

]]

Play = {}


local function checkSex()
    local pedModel = GetEntityModel(PlayerPedId())
    for i = 1, #Config.malePeds do
        if pedModel == GetHashKey(Config.malePeds[i]) then
            return 'male'
        end
    end
    return 'female'
end


local function notify(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(0, 1)
end

Play.Animation = function(dance, particle, prop, p)
    if dance then
        if Config.animActive then
            Load.Cancel()
        end
        Load.Dict(dance.dict)
        if prop then
            Play.Prop(prop)
        end

        if particle then
            local nearbyPlayers = {}
            local players = GetActivePlayers()
            if #players > 1 then
                for i = 1, #players do
                    nearbyPlayers[i] = GetPlayerServerId(players[i])
                end
                Config.ptfxOwner = true
                TriggerServerEvent('sqq-anims:syncParticles', particle, nearbyPlayers)
            else
                Play.Ptfx(PlayerPedId(), particle)
            end
        end

        local loop = Config.animDuration
        local move = 1
        if Config.animLoop and not Config.animDisableLoop then
            loop = -1
        else
            if dance.duration then
                SetTimeout(dance.duration, function() Load.Cancel() end)
            else
                SetTimeout(Config.animDuration, function() Load.Cancel() end)
            end
        end
        if Config.animMovement and not Config.animDisableMovement then
            move = 51
        end
        TaskPlayAnim(PlayerPedId(), dance.dict, dance.anim, 1.5, 1.5, loop, move, 0, false, false, false)
        RemoveAnimDict(dance.dict)
        Config.animActive = true
        if p then
            p:resolve({passed = true})
        end
        return
    end
    p:reject({passed = false})
end


Play.Scene = function(scene, p)
    if scene then
        local sex = checkSex()
        if not scene.sex == 'both' and not (sex == scene.sex) then
            Play.Notification('info', 'Sex does not allow this animation')
        else
            if scene.sex == 'position' then
                local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0 - 0.5, -0.5);
                TaskStartScenarioAtPosition(PlayerPedId(), scene.scene, coords.x, coords.y, coords.z, GetEntityHeading(PlayerPedId()), 0, 1, false)
            else
                TaskStartScenarioInPlace(PlayerPedId(), scene.scene, 0, true)
            end
            Config.sceneActive = true
            p:resolve({passed = true})
            return
        end
    end
    p:reject({passed = false})
end


Play.Expression = function(expression, p)
    if expression then
        SetFacialIdleAnimOverride(PlayerPedId(), expression.expressions, 0)
        p:resolve({passed = true})
        return
    end
    p:reject({passed = false})
end

Play.Walk = function(walks, p)
    if walks then
        Load.Walk(walks.style)
        SetPedMovementClipset(PlayerPedId(), walks.style, Config.walkingTransition)
        RemoveAnimSet(walks.style)
        SetResourceKvp('savedWalk', walks.style)
        p:resolve({passed = true})
        return
    end
    p:reject({passed = false})
end

Play.Prop = function(props)
    if props then
        if props.prop then
            Load.Model(props.prop)
            Load.PropCreation(PlayerPedId(), props.prop, props.propBone, props.propPlacement)
        end
        if props.propTwo then
            Load.Model(props.propTwo)
            Load.PropCreation(PlayerPedId(), props.propTwo, props.propTwoBone, props.propTwoPlacement)
        end
    end
end

Play.Ptfx = function(ped, particles)
    if particles then
        Load.Ptfx(particles.asset)
        UseParticleFxAssetNextCall(particles.asset)
        local attachedProp
        for _, v in pairs(GetGamePool('CObject')) do
            if IsEntityAttachedToEntity(ped, v) then
                attachedProp = v
                break
            end
        end
        if not attachedProp and not Config.ptfxEntitiesTwo[NetworkGetEntityOwner(ped)] and not Config.ptfxOwner and ped == PlayerPedId() then
            attachedProp = Config.propsEntities[1] or Config.propsEntities[2]
        end
        Load.PtfxCreation(ped, attachedProp or nil, particles.name, particles.asset, particles.placement, particles.rgb)
    end
end


Play.Shared = function(shared, p)
    if shared then
        local closePed = Load.GetPlayer()
        if closePed then
            local targetId = NetworkGetEntityOwner(closePed)
            Play.Notification('info', 'Request sent to ' .. GetPlayerName(targetId))
            TriggerServerEvent('sqq-anims:awaitConfirmation', GetPlayerServerId(targetId), shared)
            p:resolve({passed = true, shared = true})
        end
    end
    p:resolve({passed = false, nearby = true})
end


Play.Notification = function(type, message)
    if Config.useTnotify then
        exports['t-notify']:Alert({
            style  =  type or 'info',
            message  =  message or 'Something went wrong...'
        })
    else
        notify(message)
    end
end

RegisterNetEvent('sqq-anims:requestShared', function(shared, targetId, owner)
    if type(shared) == "table" and targetId then
        if Config.animActive or Config.sceneActive then
            Load.Cancel()
        end
        Wait(350)

        local targetPlayer = Load.GetPlayer()
        if targetPlayer then
            SetTimeout(shared[4] or 3000, function() Config.sharedActive = false end)
            Config.sharedActive = true
            local ped = PlayerPedId()
            if not owner then
                local targetHeading = GetEntityHeading(targetPlayer)
                local targetCoords = GetOffsetFromEntityInWorldCoords(targetPlayer, 0.0, shared[3] + 0.0, 0.0)

                SetEntityHeading(ped, targetHeading - 180.1)
                SetEntityCoordsNoOffset(ped, targetCoords.x, targetCoords.y, targetCoords.z, 0)
            end

            Load.Dict(shared[1])
            TaskPlayAnim(PlayerPedId(), shared[1], shared[2], 2.0, 2.0, shared[4] or 3000, 1, 0, false, false, false)
            RemoveAnimDict(shared[1])
        end
    end
end)

RegisterNetEvent('sqq-anims:awaitConfirmation', function(target, shared)
    if not Config.sharedActive then
        Load.Confirmation(target, shared)
    else
        TriggerServerEvent('sqq-anims:resolveAnimation', target, shared, false)
    end
end)

RegisterNetEvent('sqq-anims:notify', function(type, message)
    Play.Notification(type, message)
end)

exports('Play', function()
    return Play
end)

RegisterNetEvent('sqq-anims:syncPlayerParticles', function(syncPlayer, particle)
    local mainPed = GetPlayerPed(GetPlayerFromServerId(syncPlayer))
    if mainPed > 0 and type(particle) == "table" then
        Play.Ptfx(mainPed, particle)
    end
end)

RegisterNetEvent('sqq-anims:syncRemoval', function(syncPlayer)
    local targetParticles = Config.ptfxEntitiesTwo[tonumber(syncPlayer)]
    if targetParticles then
        StopParticleFxLooped(targetParticles, false)
        Config.ptfxEntitiesTwo[syncPlayer] = nil
    end
end)

--[[

              |------------------------------------|
              |            سكربت الحركات          |
              |   https://discord.gg/PWnxxHcpbr    |
              | -----------------------------------|
              

 █████╗ ██████╗  █████╗ ██████╗    █████╗  █████╗ ██████╗ ███████╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗  ██╔══██╗██╔══██╗██╔══██╗██╔════╝
███████║██████╔╝███████║██████╦╝  ██║  ╚═╝██║  ██║██████╔╝█████╗
██╔══██║██╔══██╗██╔══██║██╔══██╗  ██║  ██╗██║  ██║██╔══██╗██╔══╝
██║  ██║██║  ██║██║  ██║██████╦╝  ╚█████╔╝╚█████╔╝██║  ██║███████╗
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝    ╚════╝  ╚════╝ ╚═╝  ╚═╝╚══════╝

]]
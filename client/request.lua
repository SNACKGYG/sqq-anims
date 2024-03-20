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
local insert = table.insert

Load = {}

Load.Dict = function(dict)
    local timeout = false
    SetTimeout(5000, function() timeout = true end)

    repeat
        RequestAnimDict(dict)
        Wait(50)
    until HasAnimDictLoaded(dict) or timeout
end


Load.Model = function(model)
    local timeout = false
    SetTimeout(5000, function() timeout = true end)

    local hashModel = GetHashKey(model)
    repeat
        RequestModel(hashModel)
        Wait(50)
    until HasModelLoaded(hashModel) or timeout
end

Load.Walk = function(walk)
    local timeout = false
    SetTimeout(5000, function() timeout = true end)

    repeat
        RequestAnimSet(walk)
        Wait(50)
    until HasAnimSetLoaded(walk) or timeout
end

Load.Ptfx = function(asset)
    local timeout = false
    SetTimeout(5000, function() timeout = true end)

    repeat
        RequestNamedPtfxAsset(asset)
        Wait(50)
    until HasNamedPtfxAssetLoaded(asset) or timeout
end

Load.PtfxCreation = function(ped, prop, name, asset, placement, rgb)
    local ptfxSpawn = ped
    if prop then
        ptfxSpawn = prop
    end
    local newPtfx = StartNetworkedParticleFxLoopedOnEntityBone(name, ptfxSpawn, placement[1] + 0.0, placement[2] + 0.0, placement[3] + 0.0, placement[4] + 0.0, placement[5] + 0.0, placement[6] + 0.0, GetEntityBoneIndexByName(name, "VFX"), placement[7] + 0.0, 0, 0, 0, 1065353216, 1065353216, 1065353216, 0)
    if newPtfx then
        SetParticleFxLoopedColour(newPtfx, rgb[1] + 0.0, rgb[2] + 0.0, rgb[3] + 0.0)
        if ped == PlayerPedId() then
            insert(Config.ptfxEntities, newPtfx)
        else
            Config.ptfxEntitiesTwo[GetPlayerServerId(NetworkGetEntityOwner(ped))] = newPtfx
        end
        Config.ptfxActive = true
    end
    RemoveNamedPtfxAsset(asset)
end

Load.PtfxRemoval = function()
    if Config.ptfxEntities then
        for _, v in pairs(Config.ptfxEntities) do
            StopParticleFxLooped(v, false)
        end
        Config.ptfxEntities = {}
    end
end

Load.PropCreation = function(ped, prop, bone, placement)
    local coords = GetEntityCoords(ped)
    local newProp = CreateObject(GetHashKey(prop), coords.x, coords.y, coords.z + 0.2, true, true, true)
    if newProp then
        AttachEntityToEntity(newProp, ped, GetPedBoneIndex(ped, bone), placement[1] + 0.0, placement[2] + 0.0, placement[3] + 0.0, placement[4] + 0.0, placement[5] + 0.0, placement[6] + 0.0, true, true, false, true, 1, true)
        insert(Config.propsEntities, newProp)
        Config.propActive = true
    end
    SetModelAsNoLongerNeeded(prop)
end

Load.PropRemoval = function(type)
    if type == 'global' then
        if not Config.propActive then
            for _, v in pairs(GetGamePool('CObject')) do
                if IsEntityAttachedToEntity(PlayerPedId(), v) then
                    SetEntityAsMissionEntity(v, true, true)
                    DeleteObject(v)
                end
            end
        else
            Play.Notification('info', 'Prevented real prop deletion...')
        end
    else
        if Config.propActive then
            for _, v in pairs(Config.propsEntities) do
                DeleteObject(v)
            end
            Config.propsEntities = {}
            Config.propActive = false
        end
    end
end

Load.GetPlayer = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.3, 0.0)
    local rayHandle = StartShapeTestCapsule(coords.x, coords.y, coords.z, offset.x, offset.y, offset.z, 3.0, 12, ped, 7)
    local _, hit, _, _, pedResult = GetShapeTestResult(rayHandle)

    if hit and pedResult ~= 0 and IsPedAPlayer(pedResult) then
        if not IsEntityDead(pedResult) then
            return pedResult
        end
    end
    return false
end

Load.Confirmation = function(target, shared)
    Play.Notification('info', '[E] Accept Request\n[L] Deny Request')
    local hasResolved = false
    SetTimeout(10000, function()
        if not hasResolved then
            hasResolved = true
            TriggerServerEvent('sqq-anims:resolveAnimation', target, shared, false)
        end
    end)

    CreateThread(function()
        while not hasResolved do
            if IsControlJustPressed(0, Config.acceptKey) then
                if not hasResolved then
                    if Config.animActive or Config.sceneActive then
                        Load.Cancel()
                    end
                    TriggerServerEvent('sqq-anims:resolveAnimation', target, shared, true)
                    hasResolved = true
                end
            elseif IsControlJustPressed(0, Config.denyKey) then
                if not hasResolved then
                    TriggerServerEvent('sqq-anims:resolveAnimation', target, shared, false)
                    hasResolved = true
                end
            end
            Wait(5)
        end
    end)
end

Load.Cancel = function()
    if Config.animDisableMovement then
        Config.animDisableMovement = false
    end
    if Config.animDisableLoop then
        Config.animDisableLoop = false
    end

    if Config.animActive then
        ClearPedTasks(PlayerPedId())
        Config.animActive = false
    elseif Config.sceneActive then
        if Config.sceneForcedEnd then
            ClearPedTasksImmediately(PlayerPedId())
        else
            ClearPedTasks(PlayerPedId())
        end
        Config.sceneActive = false
    end

    if Config.propActive then
        Load.PropRemoval()
       Config.propActive = false
    end
    if Config.ptfxActive then
        if Config.ptfxOwner then
            TriggerServerEvent('sqq-anims:syncRemoval')
            Config.ptfxOwner = false
        end
        Load.PtfxRemoval()
        Config.ptfxActive = false
    end
end

exports('Load', function()
    return Load
end)

CreateThread(function()
    TriggerEvent('chat:addSuggestions', {
        {name = '/' .. Config.commandNameEmote, help = Config.commandNameSuggestion, params = {{name = Config.commandNameas2, help = Config.commandNameas,}}},
        {name = '/' .. Config.commandName, help = Config.commandSuggestion, params = {}}
    })
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
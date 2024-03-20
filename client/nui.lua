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

local function animType(data, p)
    if data then
        if data.disableMovement then
            Config.animDisableMovement = true
        end
        if data.disableLoop then
            Config.animDisableLoop = true
        end
        if data.dance then
            Play.Animation(data.dance, data.particle, data.prop, p)
        elseif data.scene then
            Play.Scene(data.scene, p)
        elseif data.expression then
            Play.Expression(data.expression, p)
        elseif data.walk then
            Play.Walk(data.walk, p)
        elseif data.shared then
            Play.Shared(data.shared, p)
        end
    end
end

local function enableCancel()
    CreateThread(function()
        while Config.animActive or Config.sceneActive do
            if IsControlJustPressed(0, Config.cancelKey) then
                Load.Cancel()
                break
            end
            Wait(10)
        end
    end)
end

local function findEmote(emoteName)
    if emoteName then
        local name = emoteName:upper()
        SendNUIMessage({action = 'findEmote', name = name})
    end
end

local function getWalkingStyle(cb)
    local savedWalk = GetResourceKvpString('savedWalk')
    if savedWalk then
        if cb then
            return cb(savedWalk)
        end
        return savedWalk
    end
    if cb then
        return cb(nil)
    end
    return nil
end

RegisterNUICallback('changeCfg', function(data, cb)
    if data then
        if data.type == 'movement' then
            Config.animMovement = not data.state
        elseif data.type == 'loop' then
            Config.animLoop = not data.state
        elseif data.type == 'settings' then
            Config.animDuration = tonumber(data.duration) or Config.animDuration
            Config.cancelKey = tonumber(data.cancel) or Config.cancelKey
            Config.defaultEmote = data.emote or Config.defaultEmote
            Config.defaultEmoteKey = tonumber(data.key) or Config.defaultEmoteKey
        end
    end
    cb({})
end)

RegisterNUICallback('cancelAnimation', function(_, cb)
    Load.Cancel()
    cb({})
end)

RegisterNUICallback('removeProps', function(_, cb)
    Load.PropRemoval('global')
    cb({})
end)

RegisterNUICallback('exitPanel', function(_, cb)
    if Config.panelStatus then
        Config.panelStatus = false
        SetNuiFocus(false, false)
        TriggerScreenblurFadeOut(3000)
        SendNUIMessage({action = 'panelStatus', panelStatus = Config.panelStatus})
    end
    cb({})
end)

RegisterNUICallback('sendNotification', function(data, cb)
    if data then
        Play.Notification(data.type, data.message)
    end
    cb({})
end)

RegisterNUICallback('fetchStorage', function(data, cb)
    if data then
        for _, v in pairs(data) do
            if v == 'loop' then
                Config.animLoop = true
            elseif v == 'movement' then
                Config.animMovement = true
            end
        end
        local savedWalk = GetResourceKvpString('savedWalk')
        if savedWalk then -- as SNACK#1953
            local p = promise.new()
            Wait(Config.waitBeforeWalk)
            Play.Walk({style = savedWalk}, p)
            local result = Citizen.Await(p)
            if result.passed then
                Play.Notification('info', 'Set old walk style back.')
            end
        end
    end
    cb({})
end)

RegisterNUICallback('beginAnimation', function(data, cb)
    Load.Cancel()
    local animState = promise.new()
    animType(data, animState)
    local result = Citizen.Await(animState)
    if result.passed then
        if not result.shared then
            enableCancel()
        end
        cb({e = true})
        return
    end
    if result.nearby then cb({e = 'nearby'}) return end
    cb({e = false})
end)

--#as
Citizen.CreateThread(function()
    while true do
      Citizen.Wait(0)
      if IsControlJustPressed(0, Config.keyAS) then    
        Config.panelStatus = not Config.panelStatus
          SetNuiFocus(true, true)
          TriggerScreenblurFadeIn(3000)
          SendNUIMessage({action = 'panelStatus',panelStatus = Config.panelStatus})    
      end
  
     end
  end)

RegisterCommand(Config.commandNameEmote, function(_, args)
    if args and args[1] then
        return findEmote(args[1])
    end
    Play.Notification('info', 'No emote name set...')
end)

RegisterCommand(Config.defaultCommand, function()
    if Config.defaultEmote then
        findEmote(Config.defaultEmote)
    end
end)

if Config.defaultEmoteUseKey then
    CreateThread(function()
        while Config.defaultEmoteKey do
            if IsControlJustPressed(0, Config.defaultEmoteKey) then
                findEmote(Config.defaultEmote)
            end
            Wait(5)
        end
    end)
end

if Config.keyActive then
    RegisterKeyMapping(Config.commandName, Config.keySuggestion, 'keyboard', Config.keyLetter)
end

AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() == name then
        Load.Cancel()
    end
end)

AddEventHandler('sqq-anims:updateCfg', function(_cfg, result)
    if GetCurrentResourceName() == GetInvokingResource() then
        CancelEvent()
        return print('Cannot use this event from the same resource!')
    end
    if type(_cfg) ~= "table" then
        print(GetInvokingResource() .. ' tried to update anims cfg but it was not a table')
        CancelEvent()
        return
    end
    local oldCfg = cfg
    for k, v in pairs(_cfg) do
        if cfg[k] and v then
            cfg[k] = v
        end
    end
    print(GetInvokingResource() .. ' updated anims Config!')
    if result then
        print('Old:' .. json.encode(oldCfg) .. '\nNew: ' .. json.encode(cfg))
    end
end)

exports('PlayEmote', findEmote)
exports('GetWalkingStyle', getWalkingStyle)


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
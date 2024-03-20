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

local currentlyPlaying = {}

RegisterNetEvent('sqq-anims:resolveAnimation', function(target, shared, accepted)
    local playerId <const> = source
    if type(shared) ~= "table" and tonumber(playerId) ~= tonumber(target) then
        return false
    end
    if playerId and target then
        if accepted then
            TriggerClientEvent('sqq-anims:requestShared', target, shared.first, target, true)
            TriggerClientEvent('sqq-anims:requestShared', playerId, shared.second, tonumber(playerId))
        else
            TriggerClientEvent('sqq-anims:notify', target, 'info', 'Player denied your request...')
            TriggerClientEvent('sqq-anims:notify', playerId, 'info', 'Request denied')
        end
    end
end)
--as
RegisterNetEvent('sqq-anims:awaitConfirmation', function(target, shared)
    local playerId <const> = source
    if playerId > 0 then
        if target and type(shared) == "table" then
            TriggerClientEvent('sqq-anims:awaitConfirmation', target, playerId, shared)
        end
    end
end)

RegisterNetEvent('sqq-anims:syncParticles', function(particles, nearbyPlayers)
    local playerId <const> = source
    if type(particles) ~= "table" or type(nearbyPlayers) ~= "table" then
        error('Table was not successful')
    end
    if playerId > 0 then
        for i = 1, #nearbyPlayers do
            TriggerClientEvent('sqq-anims:syncPlayerParticles', nearbyPlayers[i], playerId, particles)
        end
        currentlyPlaying[playerId] = nearbyPlayers
    end
end)

RegisterNetEvent('sqq-anims:syncRemoval', function()
    local playerId <const> = source
    if playerId > 0 then
        local nearbyPlayers = currentlyPlaying[playerId]
        if nearbyPlayers then
            for i = 1, #nearbyPlayers do
                TriggerClientEvent('sqq-anims:syncRemoval', nearbyPlayers[i], playerId)
            end
            currentlyPlaying[playerId] = nil
        end
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
-- Cutscene multiplayer synchronization
local activeCutscenes = {} -- {[src] = {name, startTime, viewers}}

function PlayCutsceneForPlayer(src, cutsceneName, syncWithNearby)
    local cutscene = exports['ll-core']:GetCutscene(cutsceneName)
    
    if not cutscene then
        NotifyPlayer(src, "Cutscene nem található: " .. cutsceneName, "error")
        return false
    end
    
    TriggerClientEvent(LL.Events.Cutscene.Play, src, cutscene)
    
    activeCutscenes[src] = {
        name = cutsceneName,
        startTime = GetGameTimer(),
        viewers = {src}
    }
    
    -- Sync with nearby players
    if syncWithNearby and LL.Cutscenes.MultiplayerSync then
        local playerPed = GetPlayerPed(src)
        local playerCoords = GetEntityCoords(playerPed)
        
        local nearbyPlayers = exports['ll-core']:GetPlayersInRadius(playerCoords, LL.Cutscenes.SyncRadius)
        
        for _, nearbyPlayer in ipairs(nearbyPlayers) do
            if nearbyPlayer.source ~= src then
                TriggerClientEvent(LL.Events.Cutscene.Play, nearbyPlayer.source, cutscene)
                table.insert(activeCutscenes[src].viewers, nearbyPlayer.source)
            end
        end
    end
    
    LL.Log("Cutscene started: " .. cutsceneName .. " for player " .. src, "info")
    
    return true
end

function StopCutsceneForPlayer(src)
    if not activeCutscenes[src] then return end
    
    local viewers = activeCutscenes[src].viewers
    
    for _, viewer in ipairs(viewers) do
        TriggerClientEvent(LL.Events.Cutscene.Stop, viewer)
    end
    
    LL.Log("Cutscene stopped for player " .. src, "info")
    
    activeCutscenes[src] = nil
end

function GetPlayerActiveCutscene(src)
    return activeCutscenes[src]
end

function IsPlayerInCutscene(src)
    return activeCutscenes[src] ~= nil
end

RegisterNetEvent(LL.Events.Cutscene.Play, function(cutsceneName)
    local src = source
    PlayCutsceneForPlayer(src, cutsceneName, true)
end)

RegisterNetEvent(LL.Events.Cutscene.Stop, function()
    local src = source
    StopCutsceneForPlayer(src)
end)

RegisterCommand('playcutscene', function(source, args)
    if #args < 1 then
        NotifyPlayer(source, "Használat: /playcutscene [név]", "error")
        return
    end
    
    local cutsceneName = args[1]
    PlayCutsceneForPlayer(source, cutsceneName, true)
end, false)

RegisterCommand('stopcutscene', function(source, args)
    StopCutsceneForPlayer(source)
end, false)

AddEventHandler('playerDropped', function()
    local src = source
    if activeCutscenes[src] then
        StopCutsceneForPlayer(src)
    end
end)

AddEventHandler('ll-cutscene:ended', function()
    local src = source
    if activeCutscenes[src] then
        activeCutscenes[src] = nil
    end
end)

exports('PlayCutsceneForPlayer', PlayCutsceneForPlayer)
exports('StopCutsceneForPlayer', StopCutsceneForPlayer)
exports('GetPlayerActiveCutscene', GetPlayerActiveCutscene)
exports('IsPlayerInCutscene', IsPlayerInCutscene)
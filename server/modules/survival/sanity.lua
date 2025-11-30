-- Server-side sanity management
RegisterNetEvent(LL.Events.Survival.UpdateSanity, function(sanity)
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET sanity = ?, updated_at = NOW() WHERE player_id = ?', {
        sanity,
        playerData.id
    })
    
    if LL.Core.Debug then
        LL.Log("Player " .. playerData.name .. " sanity updated to " .. string.format("%.2f", sanity), "info")
    end
end)

RegisterNetEvent('ll-survival:resetOnDeath', function()
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET sanity = ? WHERE player_id = ?', {
        LL.Survival.Sanity.StartValue,
        playerData.id
    })
    
    LL.Log("Player " .. playerData.name .. " sanity reset on death", "info")
end)

exports('GetPlayerSanity', function(src)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return 0 end
    
    local result = MySQL.query.await('SELECT sanity FROM ' .. LL.Database.Tables.PlayerSurvival .. ' WHERE player_id = ?', {playerData.id})
    
    if result and #result > 0 then
        return result[1].sanity
    end
    
    return 0
end)

exports('SetPlayerSanity', function(src, sanity)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return false end
    
    sanity = LL.Clamp(sanity, 0, 100)
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET sanity = ? WHERE player_id = ?', {
        sanity,
        playerData.id
    })
    
    TriggerClientEvent(LL.Events.Survival.UpdateSanity, src, sanity)
    
    return true
end)

exports('AddPlayerSanity', function(src, amount)
    local current = exports['ll-core']:GetPlayerSanity(src)
    return exports['ll-core']:SetPlayerSanity(src, current + amount)
end)

exports('ReducePlayerSanity', function(src, amount)
    local current = exports['ll-core']:GetPlayerSanity(src)
    return exports['ll-core']:SetPlayerSanity(src, current - amount)
end)
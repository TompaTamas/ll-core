-- Server-side thirst management
RegisterNetEvent(LL.Events.Survival.UpdateThirst, function(thirst)
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET thirst = ?, updated_at = NOW() WHERE player_id = ?', {
        thirst,
        playerData.id
    })
    
    if LL.Core.Debug then
        LL.Log("Player " .. playerData.name .. " thirst updated to " .. string.format("%.2f", thirst), "info")
    end
end)

RegisterNetEvent(LL.Events.Survival.CheckDeath, function(reason)
    local src = source
    
    if reason == 'thirst' then
        LL.Log("Player " .. GetPlayerName(src) .. " died from dehydration", "warning")
        TriggerClientEvent('ll-death:handle', src)
    end
end)

RegisterNetEvent('ll-survival:resetOnDeath', function()
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET thirst = ? WHERE player_id = ?', {
        LL.Survival.Thirst.StartValue,
        playerData.id
    })
    
    LL.Log("Player " .. playerData.name .. " thirst reset on death", "info")
end)

exports('GetPlayerThirst', function(src)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return 0 end
    
    local result = MySQL.query.await('SELECT thirst FROM ' .. LL.Database.Tables.PlayerSurvival .. ' WHERE player_id = ?', {playerData.id})
    
    if result and #result > 0 then
        return result[1].thirst
    end
    
    return 0
end)

exports('SetPlayerThirst', function(src, thirst)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return false end
    
    thirst = LL.Clamp(thirst, 0, 100)
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET thirst = ? WHERE player_id = ?', {
        thirst,
        playerData.id
    })
    
    TriggerClientEvent(LL.Events.Survival.UpdateThirst, src, thirst)
    
    return true
end)

exports('AddPlayerThirst', function(src, amount)
    local current = exports['ll-core']:GetPlayerThirst(src)
    return exports['ll-core']:SetPlayerThirst(src, current + amount)
end)
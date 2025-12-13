-- Server-side radiation management
RegisterNetEvent(LL.Events.Survival.UpdateRadiation, function(radiation)
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET radiation = ?, updated_at = NOW() WHERE player_id = ?', {
        radiation,
        playerData.id
    })
    
    if radiation >= LL.Survival.Radiation.DeathLevel then
        LL.Log("Player " .. playerData.name .. " died from radiation poisoning", "warning")
        TriggerClientEvent('ll-death:handle', src)
    end
    
    if LL.Core.Debug then
        LL.Log("Player " .. playerData.name .. " radiation updated to " .. string.format("%.2f", radiation), "info")
    end
end)

RegisterNetEvent('ll-survival:resetOnDeath', function()
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET radiation = ? WHERE player_id = ?', {
        LL.Survival.Radiation.StartValue,
        playerData.id
    })
    
    LL.Log("Player " .. playerData.name .. " radiation reset on death", "info")
end)

exports('GetPlayerRadiation', function(src)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return 0 end
    
    local result = MySQL.query.await('SELECT radiation FROM ' .. LL.Database.Tables.PlayerSurvival .. ' WHERE player_id = ?', {playerData.id})
    
    if result and #result > 0 then
        return result[1].radiation
    end
    
    return 0
end)

exports('SetPlayerRadiation', function(src, radiation)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return false end
    
    radiation = LL.Clamp(radiation, 0, LL.Survival.Radiation.MaxValue)
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET radiation = ? WHERE player_id = ?', {
        radiation,
        playerData.id
    })
    
    TriggerClientEvent(LL.Events.Survival.UpdateRadiation, src, radiation)
    
    return true
end)

exports('AddPlayerRadiation', function(src, amount)
    local current = exports['ll-core']:GetPlayerRadiation(src)
    return exports['ll-core']:SetPlayerRadiation(src, current + amount)
end)

exports('ReducePlayerRadiation', function(src, amount)
    local current = exports['ll-core']:GetPlayerRadiation(src)
    return exports['ll-core']:SetPlayerRadiation(src, current - amount)
end)
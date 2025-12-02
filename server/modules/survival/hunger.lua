-- Server-side hunger management
RegisterNetEvent(LL.Events.Survival.UpdateHunger, function(hunger)
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET hunger = ?, updated_at = NOW() WHERE player_id = ?', {
        hunger,
        playerData.id
    })
    
    if LL.Core.Debug then
        LL.Log("Player " .. playerData.name .. " hunger updated to " .. string.format("%.2f", hunger), "info")
    end
end)

RegisterNetEvent(LL.Events.Survival.SyncStats, function(statType, value)
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    if statType == 'hunger' then
        MySQL.query('SELECT hunger FROM ' .. LL.Database.Tables.PlayerSurvival .. ' WHERE player_id = ?', {playerData.id}, function(result)
            if result and #result > 0 then
                local dbHunger = result[1].hunger
                TriggerClientEvent(LL.Events.Survival.UpdateHunger, src, dbHunger - value)
            end
        end)
    end
end)

RegisterNetEvent(LL.Events.Survival.CheckDeath, function(reason)
    local src = source
    
    if reason == 'hunger' then
        LL.Log("Player " .. GetPlayerName(src) .. " died from starvation", "warning")
        TriggerClientEvent('ll-death:handle', src)
    end
end)

RegisterNetEvent('ll-survival:resetOnDeath', function()
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET hunger = ? WHERE player_id = ?', {
        LL.Survival.Hunger.StartValue,
        playerData.id
    })
    
    LL.Log("Player " .. playerData.name .. " hunger reset on death", "info")
end)

exports('GetPlayerHunger', function(src)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return 0 end
    
    local result = MySQL.query.await('SELECT hunger FROM ' .. LL.Database.Tables.PlayerSurvival .. ' WHERE player_id = ?', {playerData.id})
    
    if result and #result > 0 then
        return result[1].hunger
    end
    
    return 0
end)

exports('SetPlayerHunger', function(src, hunger)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return false end
    
    hunger = LL.Clamp(hunger, 0, 100)
    
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET hunger = ? WHERE player_id = ?', {
        hunger,
        playerData.id
    })
    
    TriggerClientEvent(LL.Events.Survival.UpdateHunger, src, hunger)
    
    return true
end)

exports('AddPlayerHunger', function(src, amount)
    local current = exports['ll-core']:GetPlayerHunger(src)
    return exports['ll-core']:SetPlayerHunger(src, current + amount)
end)
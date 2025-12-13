-- Player state management
function GetPlayerDataById(playerId)
    local result = MySQL.query.await('SELECT * FROM ' .. LL.Database.Tables.Players .. ' WHERE id = ?', {playerId})
    
    if result and #result > 0 then
        return result[1]
    end
    
    return nil
end

function GetPlayerDataByIdentifier(identifier)
    local result = MySQL.query.await('SELECT * FROM ' .. LL.Database.Tables.Players .. ' WHERE identifier = ?', {identifier})
    
    if result and #result > 0 then
        return result[1]
    end
    
    return nil
end

function UpdatePlayerData(playerId, data)
    local updates = {}
    local values = {}
    
    for key, value in pairs(data) do
        table.insert(updates, key .. " = ?")
        table.insert(values, value)
    end
    
    table.insert(values, playerId)
    
    local query = 'UPDATE ' .. LL.Database.Tables.Players .. ' SET ' .. table.concat(updates, ', ') .. ' WHERE id = ?'
    
    MySQL.update(query, values)
end

function UpdatePlayerLastLogin(playerId)
    MySQL.update('UPDATE ' .. LL.Database.Tables.Players .. ' SET last_login = NOW() WHERE id = ?', {playerId})
end

function GetPlayerName(playerId)
    local result = MySQL.single.await('SELECT name FROM ' .. LL.Database.Tables.Players .. ' WHERE id = ?', {playerId})
    
    if result then
        return result.name
    end
    
    return nil
end

function SetPlayerName(playerId, name)
    MySQL.update('UPDATE ' .. LL.Database.Tables.Players .. ' SET name = ? WHERE id = ?', {name, playerId})
end

function GetAllPlayers()
    local result = MySQL.query.await('SELECT * FROM ' .. LL.Database.Tables.Players, {})
    return result or {}
end

function GetOnlinePlayersCount()
    return #GetPlayers()
end

function PlayerExists(identifier)
    local result = MySQL.single.await('SELECT id FROM ' .. LL.Database.Tables.Players .. ' WHERE identifier = ?', {identifier})
    return result ~= nil
end

function DeletePlayer(playerId)
    MySQL.update('DELETE FROM ' .. LL.Database.Tables.Players .. ' WHERE id = ?', {playerId})
end

exports('GetPlayerDataById', GetPlayerDataById)
exports('GetPlayerDataByIdentifier', GetPlayerDataByIdentifier)
exports('UpdatePlayerData', UpdatePlayerData)
exports('UpdatePlayerLastLogin', UpdatePlayerLastLogin)
exports('GetPlayerName', GetPlayerName)
exports('SetPlayerName', SetPlayerName)
exports('GetAllPlayers', GetAllPlayers)
exports('GetOnlinePlayersCount', GetOnlinePlayersCount)
exports('PlayerExists', PlayerExists)
exports('DeletePlayer', DeletePlayer)
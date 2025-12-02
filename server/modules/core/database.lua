-- Database helper functions
function ExecuteQuery(query, params)
    return MySQL.query.await(query, params or {})
end

function ExecuteInsert(query, params)
    return MySQL.insert.await(query, params or {})
end

function ExecuteUpdate(query, params)
    return MySQL.update.await(query, params or {})
end

function ExecuteSingle(query, params)
    return MySQL.single.await(query, params or {})
end

-- Player survival stats
function GetPlayerSurvivalStats(playerId)
    local result = MySQL.query.await(
        'SELECT * FROM ' .. LL.Database.Tables.PlayerSurvival .. ' WHERE player_id = ?',
        {playerId}
    )
    
    if result and #result > 0 then
        return result[1]
    end
    
    return nil
end

function UpdatePlayerSurvivalStats(playerId, stats)
    local updates = {}
    local values = {}
    
    for key, value in pairs(stats) do
        table.insert(updates, key .. " = ?")
        table.insert(values, value)
    end
    
    table.insert(values, playerId)
    
    local query = 'UPDATE ' .. LL.Database.Tables.PlayerSurvival .. ' SET ' .. table.concat(updates, ', ') .. ' WHERE player_id = ?'
    
    MySQL.update(query, values)
end

function CreatePlayerSurvivalRecord(playerId)
    MySQL.insert('INSERT INTO ' .. LL.Database.Tables.PlayerSurvival .. ' (player_id) VALUES (?)', {playerId})
end

-- Player missions
function GetPlayerMissions(playerId)
    local result = MySQL.query.await(
        'SELECT * FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ?',
        {playerId}
    )
    
    return result or {}
end

function GetPlayerMission(playerId, missionId)
    local result = MySQL.single.await(
        'SELECT * FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ? AND mission_id = ?',
        {playerId, missionId}
    )
    
    return result
end

function CreatePlayerMission(playerId, missionId, progress)
    local progressJson = LL.JsonEncode(progress or {})
    
    MySQL.insert(
        'INSERT INTO ' .. LL.Database.Tables.PlayerMissions .. ' (player_id, mission_id, progress) VALUES (?, ?, ?)',
        {playerId, missionId, progressJson}
    )
end

function UpdatePlayerMissionProgress(playerId, missionId, progress)
    local progressJson = LL.JsonEncode(progress)
    
    MySQL.update(
        'UPDATE ' .. LL.Database.Tables.PlayerMissions .. ' SET progress = ?, updated_at = NOW() WHERE player_id = ? AND mission_id = ?',
        {progressJson, playerId, missionId}
    )
end

function CompleteMission(playerId, missionId)
    MySQL.update(
        'UPDATE ' .. LL.Database.Tables.PlayerMissions .. ' SET completed = TRUE, completed_at = NOW() WHERE player_id = ? AND mission_id = ?',
        {playerId, missionId}
    )
end

function DeletePlayerMission(playerId, missionId)
    MySQL.update(
        'DELETE FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ? AND mission_id = ?',
        {playerId, missionId}
    )
end

-- Cutscenes
function GetAllCutscenes()
    local result = MySQL.query.await(
        'SELECT * FROM ' .. LL.Database.Tables.Cutscenes,
        {}
    )
    
    return result or {}
end

function GetCutsceneByName(name)
    local result = MySQL.single.await(
        'SELECT * FROM ' .. LL.Database.Tables.Cutscenes .. ' WHERE name = ?',
        {name}
    )
    
    return result
end

function CreateCutscene(name, data, createdBy)
    MySQL.insert(
        'INSERT INTO ' .. LL.Database.Tables.Cutscenes .. ' (name, data, created_by) VALUES (?, ?, ?)',
        {name, data, createdBy}
    )
end

function UpdateCutscene(name, data)
    MySQL.update(
        'UPDATE ' .. LL.Database.Tables.Cutscenes .. ' SET data = ?, updated_at = NOW() WHERE name = ?',
        {data, name}
    )
end

function DeleteCutscene(name)
    MySQL.update(
        'DELETE FROM ' .. LL.Database.Tables.Cutscenes .. ' WHERE name = ?',
        {name}
    )
end

-- Batch operations
function BatchInsert(table, columns, values)
    if #values == 0 then return end
    
    local placeholders = {}
    local flatValues = {}
    
    for _, row in ipairs(values) do
        local rowPlaceholders = {}
        for _, value in ipairs(row) do
            table.insert(rowPlaceholders, '?')
            table.insert(flatValues, value)
        end
        table.insert(placeholders, '(' .. table.concat(rowPlaceholders, ', ') .. ')')
    end
    
    local query = string.format(
        'INSERT INTO %s (%s) VALUES %s',
        table,
        table.concat(columns, ', '),
        table.concat(placeholders, ', ')
    )
    
    MySQL.insert(query, flatValues)
end

function BatchUpdate(table, updates, where)
    if #updates == 0 then return end
    
    local setClauses = {}
    local values = {}
    
    for column, value in pairs(updates) do
        table.insert(setClauses, column .. ' = ?')
        table.insert(values, value)
    end
    
    -- Add WHERE clause values
    for _, value in ipairs(where.values or {}) do
        table.insert(values, value)
    end
    
    local query = string.format(
        'UPDATE %s SET %s WHERE %s',
        table,
        table.concat(setClauses, ', '),
        where.clause or '1=1'
    )
    
    MySQL.update(query, values)
end

-- Transaction support
function BeginTransaction()
    MySQL.query('START TRANSACTION', {})
end

function CommitTransaction()
    MySQL.query('COMMIT', {})
end

function RollbackTransaction()
    MySQL.query('ROLLBACK', {})
end

-- Exports
exports('ExecuteQuery', ExecuteQuery)
exports('ExecuteInsert', ExecuteInsert)
exports('ExecuteUpdate', ExecuteUpdate)
exports('ExecuteSingle', ExecuteSingle)
exports('GetPlayerSurvivalStats', GetPlayerSurvivalStats)
exports('UpdatePlayerSurvivalStats', UpdatePlayerSurvivalStats)
exports('CreatePlayerSurvivalRecord', CreatePlayerSurvivalRecord)
exports('GetPlayerMissions', GetPlayerMissions)
exports('GetPlayerMission', GetPlayerMission)
exports('CreatePlayerMission', CreatePlayerMission)
exports('UpdatePlayerMissionProgress', UpdatePlayerMissionProgress)
exports('CompleteMission', CompleteMission)
exports('DeletePlayerMission', DeletePlayerMission)
exports('GetAllCutscenes', GetAllCutscenes)
exports('GetCutsceneByName', GetCutsceneByName)
exports('CreateCutscene', CreateCutscene)
exports('UpdateCutscene', UpdateCutscene)
exports('DeleteCutscene', DeleteCutscene)
exports('BatchInsert', BatchInsert)
exports('BatchUpdate', BatchUpdate)
exports('BeginTransaction', BeginTransaction)
exports('CommitTransaction', CommitTransaction)
exports('RollbackTransaction', RollbackTransaction)
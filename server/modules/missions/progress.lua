-- Mission progress tracking and persistence
local playerMissionProgress = {}

function LoadPlayerMissionProgress(src)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return end
    
    MySQL.query('SELECT * FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ?', {
        playerData.id
    }, function(result)
        if result then
            playerMissionProgress[src] = {}
            
            for _, mission in ipairs(result) do
                playerMissionProgress[src][mission.mission_id] = {
                    progress = LL.JsonDecode(mission.progress) or {},
                    completed = mission.completed == 1 or mission.completed == true,
                    completedAt = mission.completed_at,
                    updatedAt = mission.updated_at
                }
            end
            
            LL.Log("Loaded mission progress for " .. playerData.name .. " (" .. #result .. " missions)", "info")
        end
    end)
end

function SavePlayerMissionProgress(src, missionId, progress)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return end
    
    if not playerMissionProgress[src] then
        playerMissionProgress[src] = {}
    end
    
    playerMissionProgress[src][missionId] = {
        progress = progress,
        completed = false
    }
    
    local progressJson = LL.JsonEncode(progress)
    
    -- Check if mission record exists
    MySQL.query('SELECT id FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ? AND mission_id = ?', {
        playerData.id,
        missionId
    }, function(result)
        if result and #result > 0 then
            -- Update existing
            MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerMissions .. ' SET progress = ?, updated_at = NOW() WHERE player_id = ? AND mission_id = ?', {
                progressJson,
                playerData.id,
                missionId
            })
        else
            -- Insert new
            MySQL.insert('INSERT INTO ' .. LL.Database.Tables.PlayerMissions .. ' (player_id, mission_id, progress) VALUES (?, ?, ?)', {
                playerData.id,
                missionId,
                progressJson
            })
        end
    end)
    
    if LL.Core.Debug then
        LL.Log("Saved mission progress for " .. playerData.name .. " - Mission: " .. missionId, "info")
    end
end

function GetPlayerMissionProgress(src, missionId)
    if playerMissionProgress[src] and playerMissionProgress[src][missionId] then
        return playerMissionProgress[src][missionId]
    end
    
    -- Try to load from database if not in cache
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return nil end
    
    local result = MySQL.single.await('SELECT * FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ? AND mission_id = ?', {
        playerData.id,
        missionId
    })
    
    if result then
        local progress = {
            progress = LL.JsonDecode(result.progress) or {},
            completed = result.completed == 1 or result.completed == true,
            completedAt = result.completed_at
        }
        
        if not playerMissionProgress[src] then
            playerMissionProgress[src] = {}
        end
        playerMissionProgress[src][missionId] = progress
        
        return progress
    end
    
    return nil
end

function IsMissionCompleted(src, missionId)
    local progress = GetPlayerMissionProgress(src, missionId)
    if progress then
        return progress.completed
    end
    return false
end

function GetCompletedMissions(src)
    if not playerMissionProgress[src] then return {} end
    
    local completed = {}
    for missionId, data in pairs(playerMissionProgress[src]) do
        if data.completed then
            table.insert(completed, missionId)
        end
    end
    
    return completed
end

function GetInProgressMissions(src)
    if not playerMissionProgress[src] then return {} end
    
    local inProgress = {}
    for missionId, data in pairs(playerMissionProgress[src]) do
        if not data.completed then
            table.insert(inProgress, {
                missionId = missionId,
                progress = data.progress
            })
        end
    end
    
    return inProgress
end

function ResetMissionProgress(src, missionId)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return false end
    
    if playerMissionProgress[src] then
        playerMissionProgress[src][missionId] = nil
    end
    
    MySQL.update('DELETE FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ? AND mission_id = ?', {
        playerData.id,
        missionId
    })
    
    LL.Log("Reset mission progress for " .. playerData.name .. ": " .. missionId, "info")
    return true
end

function ResetAllMissionProgress(src)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return false end
    
    playerMissionProgress[src] = {}
    
    MySQL.update('DELETE FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ?', {
        playerData.id
    })
    
    LL.Log("Reset ALL mission progress for " .. playerData.name, "warning")
    return true
end

function GetMissionCompletionPercentage(src, missionId)
    local progress = GetPlayerMissionProgress(src, missionId)
    if not progress then return 0 end
    
    local mission = exports['ll-core']:GetMissionById(missionId)
    if not mission or not mission.objectives then return 0 end
    
    local completedCount = 0
    local totalObjectives = #mission.objectives
    
    for i = 1, totalObjectives do
        if progress.progress[tostring(i)] then
            completedCount = completedCount + 1
        end
    end
    
    return (completedCount / totalObjectives) * 100
end

function GetPlayerMissionStats(src)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return nil end
    
    local result = MySQL.query.await('SELECT * FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ?', {
        playerData.id
    })
    
    local stats = {
        total = #result or 0,
        completed = 0,
        inProgress = 0,
        failed = 0
    }
    
    if result then
        for _, mission in ipairs(result) do
            if mission.completed == 1 or mission.completed == true then
                stats.completed = stats.completed + 1
            else
                stats.inProgress = stats.inProgress + 1
            end
        end
    end
    
    return stats
end

-- Events
RegisterNetEvent('ll-mission:loadProgress', function()
    local src = source
    LoadPlayerMissionProgress(src)
end)

RegisterNetEvent('ll-mission:saveProgress', function(missionId, progress)
    local src = source
    SavePlayerMissionProgress(src, missionId, progress)
end)

-- Player disconnect - cleanup cache
AddEventHandler('playerDropped', function()
    local src = source
    if playerMissionProgress[src] then
        playerMissionProgress[src] = nil
        LL.Log("Cleared mission progress cache for player " .. src, "info")
    end
end)

-- Auto-save loop (backup)
if LL.Missions.SaveProgress and LL.Missions.AutoSaveInterval then
    CreateThread(function()
        while true do
            Wait(LL.Missions.AutoSaveInterval)
            
            local count = 0
            for src, missions in pairs(playerMissionProgress) do
                for missionId, data in pairs(missions) do
                    if not data.completed then
                        SavePlayerMissionProgress(src, missionId, data.progress)
                        count = count + 1
                    end
                end
            end
            
            if count > 0 then
                LL.Log("Auto-saved " .. count .. " mission progress entries", "info")
            end
        end
    end)
end

-- Commands
RegisterCommand('missionstats', function(source, args)
    if source == 0 then return end
    
    local stats = GetPlayerMissionStats(source)
    
    if stats then
        LL.Log("=== Mission Stats for Player " .. source .. " ===", "info")
        LL.Log("Total Missions: " .. stats.total, "info")
        LL.Log("Completed: " .. stats.completed, "info")
        LL.Log("In Progress: " .. stats.inProgress, "info")
        
        exports['ll-core']:NotifyPlayer(source, "Nézd meg a konzolt!", "info")
    end
end, false)

RegisterCommand('resetmission', function(source, args)
    if source == 0 or not exports['ll-core']:IsPlayerAdmin(source) then return end
    
    if #args < 2 then
        exports['ll-core']:NotifyPlayer(source, "Használat: /resetmission [player_id] [mission_id]", "error")
        return
    end
    
    local targetId = tonumber(args[1])
    local missionId = args[2]
    
    if not targetId or not GetPlayerName(targetId) then
        exports['ll-core']:NotifyPlayer(source, "Érvénytelen játékos ID!", "error")
        return
    end
    
    if ResetMissionProgress(targetId, missionId) then
        exports['ll-core']:NotifyPlayer(source, "Küldetés progress resetelve!", "success")
        exports['ll-core']:NotifyPlayer(targetId, "A(z) " .. missionId .. " küldetésed resetelve lett!", "warning")
    else
        exports['ll-core']:NotifyPlayer(source, "Hiba történt!", "error")
    end
end, false)

-- Exports
exports('LoadPlayerMissionProgress', LoadPlayerMissionProgress)
exports('SavePlayerMissionProgress', SavePlayerMissionProgress)
exports('GetPlayerMissionProgress', GetPlayerMissionProgress)
exports('IsMissionCompleted', IsMissionCompleted)
exports('GetCompletedMissions', GetCompletedMissions)
exports('GetInProgressMissions', GetInProgressMissions)
exports('ResetMissionProgress', ResetMissionProgress)
exports('ResetAllMissionProgress', ResetAllMissionProgress)
exports('GetMissionCompletionPercentage', GetMissionCompletionPercentage)
exports('GetPlayerMissionStats', GetPlayerMissionStats)
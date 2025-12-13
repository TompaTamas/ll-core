-- Server-side mission manager
local serverMissions = {}

RegisterNetEvent(LL.Events.Mission.LoadMissions, function()
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    MySQL.query('SELECT * FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ?', {playerData.id}, function(result)
        local playerMissions = result or {}
        
        local availableMissions = {}
        for _, mission in ipairs(serverMissions) do
            local alreadyCompleted = false
            
            for _, pm in ipairs(playerMissions) do
                if pm.mission_id == mission.id and pm.completed then
                    alreadyCompleted = true
                    break
                end
            end
            
            if not alreadyCompleted then
                -- Check requirements
                local meetsRequirements = true
                
                if mission.requirements and mission.requirements.previousMissions then
                    for _, requiredMission in ipairs(mission.requirements.previousMissions) do
                        local found = false
                        for _, pm in ipairs(playerMissions) do
                            if pm.mission_id == requiredMission and pm.completed then
                                found = true
                                break
                            end
                        end
                        if not found then
                            meetsRequirements = false
                            break
                        end
                    end
                end
                
                if meetsRequirements then
                    table.insert(availableMissions, mission)
                end
            end
        end
        
        TriggerClientEvent(LL.Events.Mission.LoadMissions, src, availableMissions)
        LL.Log("Sent " .. #availableMissions .. " available missions to " .. playerData.name, "info")
    end)
end)

RegisterNetEvent('ll-mission:sendMissions', function(missions)
    local src = source
    
    if not missions or type(missions) ~= "table" then return end
    
    serverMissions = missions
    LL.Log("Received " .. #missions .. " missions from client " .. src, "success")
    
    for _, mission in ipairs(missions) do
        if mission.id and mission.name then
            LL.Log("  → " .. mission.name .. " (ID: " .. mission.id .. ")", "info")
        end
    end
end)

RegisterNetEvent(LL.Events.Mission.Start, function(missionId)
    local src = source
    exports['ll-core']:StartMissionForPlayer(src, missionId)
end)

RegisterNetEvent(LL.Events.Mission.UpdateObjective, function(missionId, objectiveIndex)
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    MySQL.query('SELECT progress FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ? AND mission_id = ?', {
        playerData.id,
        missionId
    }, function(result)
        if result and #result > 0 then
            local progress = LL.JsonDecode(result[1].progress) or {}
            progress[tostring(objectiveIndex)] = true
            
            MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerMissions .. ' SET progress = ?, updated_at = NOW() WHERE player_id = ? AND mission_id = ?', {
                LL.JsonEncode(progress),
                playerData.id,
                missionId
            })
            
            LL.Log("Mission " .. missionId .. " objective " .. objectiveIndex .. " completed by " .. playerData.name, "success")
        end
    end)
end)

RegisterNetEvent(LL.Events.Mission.Complete, function(missionId)
    local src = source
    exports['ll-core']:CompleteMissionForPlayer(src, missionId)
end)

RegisterNetEvent(LL.Events.Mission.Fail, function(missionId, reason)
    local src = source
    exports['ll-core']:FailMissionForPlayer(src, missionId, reason)
end)

RegisterNetEvent(LL.Events.Mission.TriggerActivated, function(triggerId, missionId)
    local src = source
    LL.Log("Mission trigger activated: " .. triggerId .. " for mission: " .. missionId .. " by player " .. src, "info")
end)

exports('GetMissionById', function(missionId)
    for _, mission in ipairs(serverMissions) do
        if mission.id == missionId then
            return mission
        end
    end
    return nil
end)

exports('GetAllMissions', function()
    return serverMissions
end)

exports('GetPlayerMissions', function(src)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return {} end
    
    local result = MySQL.query.await('SELECT * FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ?', {playerData.id})
    
    return result or {}
end)

RegisterCommand('reloadmissions', function(source, args)
    if source == 0 or exports['ll-core']:IsPlayerAdmin(source) then
        serverMissions = {}
        TriggerClientEvent('ll-mission:requestMissions', -1)
        
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, "Missions reload requested", "success")
        else
            LL.Log("Missions reload requested", "info")
        end
    end
end, false)

RegisterCommand('listmissions', function(source, args)
    if source == 0 or exports['ll-core']:IsPlayerAdmin(source) then
        LL.Log("=== Loaded Missions ===", "info")
        for i, mission in ipairs(serverMissions) do
            LL.Log(i .. ". " .. mission.name .. " (ID: " .. mission.id .. ")", "info")
        end
        LL.Log("Total: " .. #serverMissions .. " missions", "info")
        
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, "Check console for missions list", "info")
        end
    end
end, false)
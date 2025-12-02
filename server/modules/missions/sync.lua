-- Mission multiplayer synchronization
local activeMissions = {} -- {[src] = {missionId, startTime, state, data}}

function StartMissionForPlayer(src, missionId)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then 
        LL.Log("Cannot start mission - player data not found for " .. src, "error")
        return false 
    end
    
    local mission = exports['ll-core']:GetMissionById(missionId)
    if not mission then
        LL.Log("Mission not found: " .. missionId, "error")
        exports['ll-core']:NotifyPlayer(src, "Küldetés nem található!", "error")
        return false
    end
    
    -- Check if already in mission
    if activeMissions[src] then
        LL.Log("Player " .. playerData.name .. " already has an active mission", "warning")
        exports['ll-core']:NotifyPlayer(src, "Már van aktív küldetésed!", "warning")
        return false
    end
    
    -- Check if already completed
    if exports['ll-core']:IsMissionCompleted(src, missionId) then
        LL.Log("Player " .. playerData.name .. " already completed mission: " .. missionId, "warning")
        exports['ll-core']:NotifyPlayer(src, "Ez a küldetés már teljesítve van!", "warning")
        return false
    end
    
    -- Check requirements
    if mission.requirements then
        if mission.requirements.level then
            -- Add level check here if you have level system
        end
        
        if mission.requirements.previousMissions then
            local completedMissions = exports['ll-core']:GetCompletedMissions(src)
            for _, requiredMission in ipairs(mission.requirements.previousMissions) do
                local found = false
                for _, completed in ipairs(completedMissions) do
                    if completed == requiredMission then
                        found = true
                        break
                    end
                end
                if not found then
                    exports['ll-core']:NotifyPlayer(src, "Nem teljesítetted az előfeltételeket!", "error")
                    return false
                end
            end
        end
    end
    
    -- Create or update mission record in database
    local playerMission = exports['ll-core']:GetPlayerMissionProgress(src, missionId)
    
    if not playerMission then
        -- Create new mission record
        exports['ll-core']:SavePlayerMissionProgress(src, missionId, {})
    end
    
    -- Set as active mission
    activeMissions[src] = {
        missionId = missionId,
        startTime = os.time(),
        state = "active",
        data = mission
    }
    
    -- Send to client
    TriggerClientEvent(LL.Events.Mission.Start, src, mission)
    
    if LL.Missions.Notifications.MissionStart then
        exports['ll-core']:NotifyPlayer(src, "Küldetés elkezdve: " .. mission.name, "info")
    end
    
    LL.Log("Mission started for " .. playerData.name .. ": " .. mission.name .. " (ID: " .. missionId .. ")", "success")
    
    -- Play cutscene if specified
    if mission.cutscenes and mission.cutscenes.onStart then
        local cutscene = exports['ll-core']:GetCutsceneByName(mission.cutscenes.onStart)
        if cutscene then
            Wait(1000) -- Small delay before cutscene
            TriggerClientEvent(LL.Events.Cutscene.Play, src, cutscene)
            LL.Log("Playing start cutscene: " .. mission.cutscenes.onStart, "info")
        end
    end
    
    -- Trigger callback if exists
    if mission.onStart then
        mission.onStart()
    end
    
    return true
end

function CompleteMissionForPlayer(src, missionId)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return false end
    
    if not activeMissions[src] or activeMissions[src].missionId ~= missionId then
        LL.Log("Player " .. playerData.name .. " tried to complete inactive mission: " .. missionId, "warning")
        return false
    end
    
    local mission = activeMissions[src].data
    
    -- Update database - mark as completed
    MySQL.update('UPDATE ' .. LL.Database.Tables.PlayerMissions .. ' SET completed = TRUE, completed_at = NOW() WHERE player_id = ? AND mission_id = ?', {
        playerData.id,
        missionId
    })
    
    -- Give rewards
    if mission and mission.rewards then
        GivePlayerRewards(src, mission.rewards, mission.name)
    end
    
    -- Clear active mission
    activeMissions[src] = nil
    
    if LL.Missions.Notifications.MissionComplete then
        exports['ll-core']:NotifyPlayer(src, "Küldetés teljesítve: " .. (mission.name or missionId), "success")
    end
    
    LL.Log("Mission completed by " .. playerData.name .. ": " .. missionId, "success")
    
    -- Trigger callback
    if mission and mission.onComplete then
        mission.onComplete()
    end
    
    -- Play cutscene if specified
    if mission.cutscenes and mission.cutscenes.onComplete then
        local cutscene = exports['ll-core']:GetCutsceneByName(mission.cutscenes.onComplete)
        if cutscene then
            Wait(1000) -- Small delay before cutscene
            TriggerClientEvent(LL.Events.Cutscene.Play, src, cutscene)
            LL.Log("Playing completion cutscene: " .. mission.cutscenes.onComplete, "info")
        end
    end
    
    -- Trigger server event for other scripts
    TriggerEvent('ll-mission:playerCompletedMission', src, missionId)
    
    return true
end

function FailMissionForPlayer(src, missionId, reason)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return false end
    
    local mission = nil
    
    if activeMissions[src] and activeMissions[src].missionId == missionId then
        mission = activeMissions[src].data
        activeMissions[src] = nil
    end
    
    -- Delete mission record from database
    MySQL.update('DELETE FROM ' .. LL.Database.Tables.PlayerMissions .. ' WHERE player_id = ? AND mission_id = ? AND completed = FALSE', {
        playerData.id,
        missionId
    })
    
    -- Notify client
    TriggerClientEvent(LL.Events.Mission.Fail, src, reason or "Küldetés sikertelen")
    exports['ll-core']:NotifyPlayer(src, "Küldetés sikertelen" .. (reason and (": " .. reason) or ""), "error")
    
    LL.Log("Mission failed by " .. playerData.name .. ": " .. missionId .. (reason and (" (Reason: " .. reason .. ")") or ""), "warning")
    
    -- Play cutscene if specified
    if mission and mission.cutscenes and mission.cutscenes.onFail then
        local cutscene = exports['ll-core']:GetCutsceneByName(mission.cutscenes.onFail)
        if cutscene then
            Wait(1000) -- Small delay before cutscene
            TriggerClientEvent(LL.Events.Cutscene.Play, src, cutscene)
            LL.Log("Playing fail cutscene: " .. mission.cutscenes.onFail, "info")
        end
    end
    
    -- Trigger callback
    if mission and mission.onFail then
        mission.onFail()
    end
    
    return true
end

function GivePlayerRewards(src, rewards, missionName)
    if not rewards or #rewards == 0 then return end
    
    for _, reward in ipairs(rewards) do
        if reward.type == LL.Missions.RewardTypes.MONEY then
            -- Framework specific money give
            -- ESX: xPlayer.addMoney(reward.amount)
            -- QBCore: Player.Functions.AddMoney('cash', reward.amount)
            exports['ll-core']:NotifyPlayer(src, "Jutalom: $" .. reward.amount, "success")
            LL.Log("Player " .. src .. " received $" .. reward.amount .. " from mission: " .. missionName, "info")
            
        elseif reward.type == LL.Missions.RewardTypes.ITEM then
            -- Framework specific item give
            -- ESX: xPlayer.addInventoryItem(reward.item, reward.amount)
            -- QBCore: Player.Functions.AddItem(reward.item, reward.amount)
            exports['ll-core']:NotifyPlayer(src, "Jutalom: " .. reward.item .. " x" .. (reward.amount or 1), "success")
            LL.Log("Player " .. src .. " received " .. reward.item .. " x" .. (reward.amount or 1) .. " from mission: " .. missionName, "info")
            
        elseif reward.type == LL.Missions.RewardTypes.XP then
            -- Add XP if you have XP system
            exports['ll-core']:NotifyPlayer(src, "Jutalom: " .. reward.amount .. " XP", "success")
            LL.Log("Player " .. src .. " received " .. reward.amount .. " XP from mission: " .. missionName, "info")
            
        elseif reward.type == LL.Missions.RewardTypes.UNLOCK then
            exports['ll-core']:NotifyPlayer(src, "Új küldetés feloldva!", "success")
            LL.Log("Player " .. src .. " unlocked mission: " .. reward.missionId, "info")
        end
    end
    
    -- Trigger event for custom reward handling
    TriggerEvent('ll-mission:rewardsGiven', src, rewards, missionName)
end

function GetPlayerActiveMission(src)
    return activeMissions[src]
end

function IsPlayerInMission(src)
    return activeMissions[src] ~= nil
end

function GetActiveMissionsCount()
    local count = 0
    for _ in pairs(activeMissions) do
        count = count + 1
    end
    return count
end

function GetAllActiveMissions()
    return activeMissions
end

function CancelMissionForPlayer(src, reason)
    if not activeMissions[src] then return false end
    
    local missionId = activeMissions[src].missionId
    return FailMissionForPlayer(src, missionId, reason or "Küldetés megszakítva")
end

-- Events
RegisterNetEvent(LL.Events.Mission.Start, function(missionId)
    local src = source
    StartMissionForPlayer(src, missionId)
end)

RegisterNetEvent(LL.Events.Mission.Complete, function(missionId)
    local src = source
    CompleteMissionForPlayer(src, missionId)
end)

RegisterNetEvent(LL.Events.Mission.Fail, function(missionId, reason)
    local src = source
    FailMissionForPlayer(src, missionId, reason)
end)

-- Player disconnect - cleanup
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    if activeMissions[src] then
        local playerData = exports['ll-core']:GetPlayerData(src)
        local missionId = activeMissions[src].missionId
        
        LL.Log("Player " .. (playerData and playerData.name or src) .. " disconnected during mission: " .. missionId, "warning")
        
        -- Save progress before cleanup
        -- Progress is already saved in database, just cleanup memory
        activeMissions[src] = nil
    end
end)

-- Commands
RegisterCommand('activemissions', function(source, args)
    if source == 0 or exports['ll-core']:IsPlayerAdmin(source) then
        local count = GetActiveMissionsCount()
        
        LL.Log("=== Active Missions ===", "info")
        LL.Log("Total active: " .. count, "info")
        
        for src, mission in pairs(activeMissions) do
            local playerData = exports['ll-core']:GetPlayerData(src)
            if playerData then
                LL.Log("Player: " .. playerData.name .. " - Mission: " .. mission.missionId, "info")
            end
        end
        
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, "Aktív küldetések: " .. count, "info")
        end
    end
end, false)

RegisterCommand('forcecomplete', function(source, args)
    if source == 0 or not exports['ll-core']:IsPlayerAdmin(source) then return end
    
    if #args < 1 then
        exports['ll-core']:NotifyPlayer(source, "Használat: /forcecomplete [player_id]", "error")
        return
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId or not GetPlayerName(targetId) then
        exports['ll-core']:NotifyPlayer(source, "Érvénytelen játékos ID!", "error")
        return
    end
    
    if not activeMissions[targetId] then
        exports['ll-core']:NotifyPlayer(source, "A játékosnak nincs aktív küldetése!", "error")
        return
    end
    
    local missionId = activeMissions[targetId].missionId
    
    if CompleteMissionForPlayer(targetId, missionId) then
        exports['ll-core']:NotifyPlayer(source, "Küldetés force complete: " .. missionId, "success")
    else
        exports['ll-core']:NotifyPlayer(source, "Hiba történt!", "error")
    end
end, false)

-- Exports
exports('StartMissionForPlayer', StartMissionForPlayer)
exports('CompleteMissionForPlayer', CompleteMissionForPlayer)
exports('FailMissionForPlayer', FailMissionForPlayer)
exports('GetPlayerActiveMission', GetPlayerActiveMission)
exports('IsPlayerInMission', IsPlayerInMission)
exports('GetActiveMissionsCount', GetActiveMissionsCount)
exports('GetAllActiveMissions', GetAllActiveMissions)
exports('CancelMissionForPlayer', CancelMissionForPlayer)
exports('GivePlayerRewards', GivePlayerRewards)
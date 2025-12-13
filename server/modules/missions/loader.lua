-- Server-side mission loader
local loadedMissions = {}

function LoadMissionsFromFiles()
    local resourceName = GetCurrentResourceName()
    local missionCount = 0
    
    LL.Log("Loading missions from files...", "info")
    
    -- Mivel a szerver nem tud közvetlenül fájlokat olvasni a missions mappából,
    -- a client fogja betölteni és elküldeni nekünk
    return loadedMissions
end

RegisterNetEvent('ll-mission:sendMissions', function(missions)
    local src = source
    
    if not missions or type(missions) ~= "table" then 
        LL.Log("Invalid missions data received from client " .. src, "error")
        return 
    end
    
    -- Validate missions before accepting
    local validMissions = {}
    for _, mission in ipairs(missions) do
        if ValidateMissionStructure(mission) then
            table.insert(validMissions, mission)
        else
            LL.Log("Invalid mission structure received: " .. (mission.id or "unknown"), "error")
        end
    end
    
    loadedMissions = validMissions
    LL.Log("Received and validated " .. #validMissions .. " missions from client", "success")
    
    -- Log mission details
    for _, mission in ipairs(validMissions) do
        if mission.id and mission.name then
            LL.Log("  → " .. mission.name .. " (ID: " .. mission.id .. ")", "info")
            if mission.objectives then
                LL.Log("    Objectives: " .. #mission.objectives, "info")
            end
            if mission.npcs then
                LL.Log("    NPCs: " .. #mission.npcs, "info")
            end
        end
    end
end)

function ValidateMissionStructure(mission)
    -- Check required fields
    if not mission.id then
        LL.Log("Mission missing 'id' field", "error")
        return false
    end
    
    if not mission.name then
        LL.Log("Mission '" .. mission.id .. "' missing 'name' field", "error")
        return false
    end
    
    if not mission.objectives or type(mission.objectives) ~= "table" or #mission.objectives == 0 then
        LL.Log("Mission '" .. mission.id .. "' missing valid 'objectives'", "error")
        return false
    end
    
    -- Validate each objective
    for i, objective in ipairs(mission.objectives) do
        if not objective.type then
            LL.Log("Objective " .. i .. " missing 'type' in mission: " .. mission.id, "error")
            return false
        end
    end
    
    return true
end

function GetMissionById(missionId)
    for _, mission in ipairs(loadedMissions) do
        if mission.id == missionId then
            return mission
        end
    end
    return nil
end

function GetAllMissions()
    return loadedMissions
end

function GetAvailableMissionsForPlayer(src)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return {} end
    
    -- Get completed missions
    local completedMissions = exports['ll-core']:GetCompletedMissions(src)
    local available = {}
    
    for _, mission in ipairs(loadedMissions) do
        local alreadyCompleted = false
        
        -- Check if mission is completed
        for _, completedId in ipairs(completedMissions) do
            if completedId == mission.id then
                alreadyCompleted = true
                break
            end
        end
        
        if not alreadyCompleted then
            -- Check requirements
            local meetsRequirements = true
            
            if mission.requirements then
                -- Check level requirement
                if mission.requirements.level then
                    -- Add level check here if you have level system
                end
                
                -- Check previous missions
                if mission.requirements.previousMissions then
                    for _, requiredMission in ipairs(mission.requirements.previousMissions) do
                        local found = false
                        for _, completedId in ipairs(completedMissions) do
                            if completedId == requiredMission then
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
            end
            
            if meetsRequirements then
                table.insert(available, mission)
            end
        end
    end
    
    return available
end

function ReloadMissions()
    loadedMissions = {}
    TriggerClientEvent('ll-mission:requestMissions', -1)
    LL.Log("Mission reload requested from all clients", "info")
end

-- Commands
RegisterCommand('reloadmissions', function(source, args)
    if source == 0 or exports['ll-core']:IsPlayerAdmin(source) then
        ReloadMissions()
        
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, "Küldetések újratöltése folyamatban...", "success")
        else
            LL.Log("Missions reload initiated", "info")
        end
    else
        exports['ll-core']:NotifyPlayer(source, "Nincs jogosultságod ehhez!", "error")
    end
end, false)

RegisterCommand('listmissions', function(source, args)
    if source == 0 or exports['ll-core']:IsPlayerAdmin(source) then
        LL.Log("=== Betöltött Küldetések ===", "info")
        
        if #loadedMissions == 0 then
            LL.Log("Nincsenek betöltött küldetések!", "warning")
        else
            for i, mission in ipairs(loadedMissions) do
                LL.Log(i .. ". " .. mission.name .. " (ID: " .. mission.id .. ")", "info")
                if mission.description then
                    LL.Log("   Leírás: " .. mission.description, "info")
                end
                LL.Log("   Objektívák: " .. #mission.objectives, "info")
                if mission.npcs then
                    LL.Log("   NPC-k: " .. #mission.npcs, "info")
                end
            end
            LL.Log("Összesen: " .. #loadedMissions .. " küldetés", "success")
        end
        
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, "Nézd meg a konzolt a listához!", "info")
        end
    else
        exports['ll-core']:NotifyPlayer(source, "Nincs jogosultságod ehhez!", "error")
    end
end, false)

RegisterCommand('missioninfo', function(source, args)
    if source == 0 or exports['ll-core']:IsPlayerAdmin(source) then
        if #args < 1 then
            if source > 0 then
                exports['ll-core']:NotifyPlayer(source, "Használat: /missioninfo [mission_id]", "error")
            else
                LL.Log("Usage: missioninfo [mission_id]", "error")
            end
            return
        end
        
        local missionId = args[1]
        local mission = GetMissionById(missionId)
        
        if not mission then
            LL.Log("Küldetés nem található: " .. missionId, "error")
            if source > 0 then
                exports['ll-core']:NotifyPlayer(source, "Küldetés nem található!", "error")
            end
            return
        end
        
        LL.Log("=== Küldetés Információ ===", "info")
        LL.Log("ID: " .. mission.id, "info")
        LL.Log("Név: " .. mission.name, "info")
        if mission.description then
            LL.Log("Leírás: " .. mission.description, "info")
        end
        LL.Log("Objektívák száma: " .. #mission.objectives, "info")
        
        for i, obj in ipairs(mission.objectives) do
            LL.Log("  " .. i .. ". " .. obj.type .. " - " .. (obj.label or "Nincs címke"), "info")
        end
        
        if mission.npcs then
            LL.Log("NPC-k száma: " .. #mission.npcs, "info")
        end
        
        if mission.rewards then
            LL.Log("Jutalmak:", "info")
            for _, reward in ipairs(mission.rewards) do
                LL.Log("  - " .. reward.type .. ": " .. (reward.amount or reward.item or "N/A"), "info")
            end
        end
        
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, "Nézd meg a konzolt!", "info")
        end
    else
        exports['ll-core']:NotifyPlayer(source, "Nincs jogosultságod ehhez!", "error")
    end
end, false)

-- Exports
exports('LoadMissionsFromFiles', LoadMissionsFromFiles)
exports('GetMissionById', GetMissionById)
exports('GetAllMissions', GetAllMissions)
exports('GetAvailableMissionsForPlayer', GetAvailableMissionsForPlayer)
exports('ReloadMissions', ReloadMissions)
exports('ValidateMissionStructure', ValidateMissionStructure)
-- Client-side mission loader from external files
local loadedMissions = {}
local loadAttempts = 0
local maxLoadAttempts = 3

function LoadExternalMissions()
    if not LL.Missions.AutoLoad then return {} end
    
    loadedMissions = {}
    local resourceName = GetCurrentResourceName()
    
    LL.Log("Loading external missions from missions/ folder...", "info")
    
    -- Get all mission files from resource metadata
    local numFiles = GetNumResourceMetadata(resourceName, 'file')
    local missionCount = 0
    local errorCount = 0
    
    for i = 0, numFiles - 1 do
        local file = GetResourceMetadata(resourceName, 'file', i)
        
        -- Check if file is in missions folder and is a .lua file
        if file and string.find(file, LL.Missions.MissionsFolder) and string.find(file, '.lua') then
            local missionFile = string.gsub(file, LL.Missions.MissionsFolder, '')
            missionFile = string.gsub(missionFile, '.lua', '')
            
            -- Skip README
            if not string.find(missionFile, 'README') then
                -- Load the file content
                local success, missionData = pcall(function()
                    return LoadResourceFile(resourceName, file)
                end)
                
                if success and missionData then
                    -- Try to execute the Lua code
                    local func, loadError = load(missionData, '@' .. file)
                    
                    if func then
                        local executeSuccess, mission = pcall(func)
                        
                        if executeSuccess and mission and type(mission) == "table" then
                            -- Validate mission structure
                            if ValidateMission(mission, missionFile) then
                                table.insert(loadedMissions, mission)
                                missionCount = missionCount + 1
                                LL.Log("✓ Loaded mission: " .. (mission.name or missionFile) .. " (ID: " .. mission.id .. ")", "success")
                            else
                                errorCount = errorCount + 1
                                LL.Log("✗ Invalid mission structure: " .. missionFile, "error")
                            end
                        else
                            errorCount = errorCount + 1
                            LL.Log("✗ Mission execution error in " .. missionFile .. ": " .. tostring(mission), "error")
                        end
                    else
                        errorCount = errorCount + 1
                        LL.Log("✗ Mission load error in " .. missionFile .. ": " .. tostring(loadError), "error")
                    end
                else
                    errorCount = errorCount + 1
                    LL.Log("✗ Failed to read mission file: " .. file, "error")
                end
            end
        end
    end
    
    LL.Log("Mission loading complete: " .. missionCount .. " loaded, " .. errorCount .. " errors", missionCount > 0 and "success" or "warning")
    
    return loadedMissions
end

function ValidateMission(mission, filename)
    -- Check required fields
    if not mission.id then
        LL.Log("Mission missing 'id' field: " .. filename, "error")
        return false
    end
    
    if not mission.name then
        LL.Log("Mission missing 'name' field: " .. mission.id, "error")
        return false
    end
    
    if not mission.objectives or type(mission.objectives) ~= "table" or #mission.objectives == 0 then
        LL.Log("Mission missing valid 'objectives': " .. mission.id, "error")
        return false
    end
    
    -- Validate objectives
    for i, objective in ipairs(mission.objectives) do
        if not objective.type then
            LL.Log("Objective " .. i .. " missing 'type' in mission: " .. mission.id, "error")
            return false
        end
        
        -- Check objective-specific requirements
        if objective.type == LL.Missions.ObjectiveTypes.GOTO then
            if not objective.coords then
                LL.Log("GOTO objective missing 'coords' in mission: " .. mission.id, "error")
                return false
            end
        elseif objective.type == LL.Missions.ObjectiveTypes.TALK then
            if not objective.npcIndex then
                LL.Log("TALK objective missing 'npcIndex' in mission: " .. mission.id, "error")
                return false
            end
        end
    end
    
    -- Validate NPCs if present
    if mission.npcs and type(mission.npcs) == "table" then
        for i, npc in ipairs(mission.npcs) do
            if not npc.coords then
                LL.Log("NPC " .. i .. " missing 'coords' in mission: " .. mission.id, "error")
                return false
            end
        end
    end
    
    return true
end

function GetLoadedMissions()
    return loadedMissions
end

function GetMissionById(missionId)
    for _, mission in ipairs(loadedMissions) do
        if mission.id == missionId then
            return mission
        end
    end
    return nil
end

function ReloadMissions()
    LL.Log("Reloading missions...", "info")
    loadedMissions = {}
    loadAttempts = 0
    
    Wait(100)
    
    LoadExternalMissions()
    
    -- Send to server
    if #loadedMissions > 0 then
        TriggerServerEvent('ll-mission:sendMissions', loadedMissions)
    end
end

-- Auto-load missions on resource start
CreateThread(function()
    Wait(2000) -- Wait for resource to fully load
    
    LoadExternalMissions()
    
    -- Retry if no missions loaded (sometimes files aren't ready)
    if #loadedMissions == 0 and loadAttempts < maxLoadAttempts then
        loadAttempts = loadAttempts + 1
        LL.Log("No missions loaded, retrying... (Attempt " .. loadAttempts .. "/" .. maxLoadAttempts .. ")", "warning")
        Wait(2000)
        LoadExternalMissions()
    end
    
    -- Send loaded missions to server
    if #loadedMissions > 0 then
        TriggerServerEvent('ll-mission:sendMissions', loadedMissions)
        LL.Log("Sent " .. #loadedMissions .. " missions to server", "info")
    else
        LL.Log("No missions to send to server. Check missions/ folder", "warning")
    end
end)

-- Server request for missions
RegisterNetEvent('ll-mission:requestMissions', function()
    Wait(100)
    LoadExternalMissions()
    
    if #loadedMissions > 0 then
        TriggerServerEvent('ll-mission:sendMissions', loadedMissions)
    end
end)

-- Debug command
RegisterCommand('debugmissions', function()
    LL.Log("=== Loaded Missions Debug ===", "info")
    LL.Log("Total missions: " .. #loadedMissions, "info")
    
    for i, mission in ipairs(loadedMissions) do
        LL.Log(i .. ". " .. mission.name .. " (ID: " .. mission.id .. ")", "info")
        LL.Log("   Objectives: " .. #mission.objectives, "info")
        if mission.npcs then
            LL.Log("   NPCs: " .. #mission.npcs, "info")
        end
    end
end, false)

-- Exports
exports('GetLoadedMissions', GetLoadedMissions)
exports('GetMissionById', GetMissionById)
exports('ReloadMissions', ReloadMissions)
exports('LoadExternalMissions', LoadExternalMissions)
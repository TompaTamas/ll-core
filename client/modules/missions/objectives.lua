-- Mission objectives handler
local activeObjectives = {}
local objectiveMarkers = {}

function InitializeObjective(objectiveId, objectiveData)
    activeObjectives[objectiveId] = {
        data = objectiveData,
        progress = 0,
        completed = false,
        startTime = GetGameTimer()
    }
    
    if objectiveData.blip then
        CreateObjectiveBlip(objectiveId, objectiveData)
    end
    
    if LL.Missions.Markers.Enabled and objectiveData.coords then
        CreateObjectiveMarker(objectiveId, objectiveData)
    end
end

function CreateObjectiveBlip(objectiveId, objectiveData)
    if not objectiveData.coords or not objectiveData.blip then return end
    
    local blip = AddBlipForCoord(objectiveData.coords.x, objectiveData.coords.y, objectiveData.coords.z)
    SetBlipSprite(blip, objectiveData.blip.sprite or 1)
    SetBlipColour(blip, objectiveData.blip.color or 5)
    SetBlipScale(blip, objectiveData.blip.scale or 1.0)
    SetBlipAsShortRange(blip, true)
    
    if objectiveData.label then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(objectiveData.label)
        EndTextCommandSetBlipName(blip)
    end
    
    if activeObjectives[objectiveId] then
        activeObjectives[objectiveId].blip = blip
    end
end

function CreateObjectiveMarker(objectiveId, objectiveData)
    objectiveMarkers[objectiveId] = {
        coords = objectiveData.coords,
        radius = objectiveData.radius or LL.Missions.Markers.InteractDistance,
        active = true
    }
    
    CreateThread(function()
        while objectiveMarkers[objectiveId] and objectiveMarkers[objectiveId].active do
            Wait(0)
            
            local marker = objectiveMarkers[objectiveId]
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - marker.coords)
            
            if distance <= LL.Missions.Markers.DrawDistance then
                DrawMarker(
                    LL.Missions.Markers.Type,
                    marker.coords.x, marker.coords.y, marker.coords.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    LL.Missions.Markers.Size.x, LL.Missions.Markers.Size.y, LL.Missions.Markers.Size.z,
                    LL.Missions.Markers.Color.r, LL.Missions.Markers.Color.g, LL.Missions.Markers.Color.b, LL.Missions.Markers.Color.a,
                    LL.Missions.Markers.BobUpAndDown,
                    true,
                    2,
                    LL.Missions.Markers.Rotate,
                    nil, nil, false
                )
            end
        end
    end)
end

function UpdateObjectiveProgress(objectiveId, progress)
    if not activeObjectives[objectiveId] then return end
    
    activeObjectives[objectiveId].progress = progress
    
    local objective = activeObjectives[objectiveId].data
    local target = objective.target or 1
    
    if progress >= target then
        CompleteObjectiveById(objectiveId)
    end
end

function CompleteObjectiveById(objectiveId)
    if not activeObjectives[objectiveId] then return end
    
    activeObjectives[objectiveId].completed = true
    
    if activeObjectives[objectiveId].blip then
        RemoveBlip(activeObjectives[objectiveId].blip)
    end
    
    if objectiveMarkers[objectiveId] then
        objectiveMarkers[objectiveId].active = false
        objectiveMarkers[objectiveId] = nil
    end
    
    if LL.Missions.Notifications.ObjectiveUpdate then
        TriggerEvent('ll-notify:show', 'Célkitűzés teljesítve!', 'success')
    end
end

function RemoveObjective(objectiveId)
    if activeObjectives[objectiveId] then
        if activeObjectives[objectiveId].blip then
            RemoveBlip(activeObjectives[objectiveId].blip)
        end
        
        activeObjectives[objectiveId] = nil
    end
    
    if objectiveMarkers[objectiveId] then
        objectiveMarkers[objectiveId].active = false
        objectiveMarkers[objectiveId] = nil
    end
end

function GetObjectiveProgress(objectiveId)
    if activeObjectives[objectiveId] then
        return activeObjectives[objectiveId].progress
    end
    return 0
end

function IsObjectiveCompleted(objectiveId)
    if activeObjectives[objectiveId] then
        return activeObjectives[objectiveId].completed
    end
    return false
end

exports('InitializeObjective', InitializeObjective)
exports('UpdateObjectiveProgress', UpdateObjectiveProgress)
exports('CompleteObjective', CompleteObjectiveById)
exports('RemoveObjective', RemoveObjective)
exports('GetObjectiveProgress', GetObjectiveProgress)
exports('IsObjectiveCompleted', IsObjectiveCompleted)
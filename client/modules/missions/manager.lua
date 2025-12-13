local activeMission = nil
local availableMissions = {}
local missionProgress = {}
local missionNPCs = {}

RegisterNetEvent(LL.Events.Mission.LoadMissions, function(missions)
    availableMissions = missions
    LL.Log("Loaded " .. #missions .. " missions", "success")
end)

RegisterNetEvent(LL.Events.Mission.Start, function(missionData)
    if activeMission then
        LL.Log("Already in active mission", "warning")
        return
    end
    
    activeMission = missionData
    missionProgress = {
        objectives = {},
        startTime = GetGameTimer(),
        completed = false
    }
    
    for i, objective in ipairs(missionData.objectives) do
        missionProgress.objectives[i] = {
            completed = false,
            progress = 0,
            target = objective.target or 1
        }
    end
    
    LL.Log("Mission started: " .. missionData.name, "info")
    TriggerEvent('ll-notify:show', 'Küldetés: ' .. missionData.name, 'info')
    
    if missionData.npcs then
        SpawnMissionNPCs(missionData.npcs)
    end
    
    if missionData.onStart then
        missionData.onStart()
    end
    
    StartMissionLoop()
end)

function StartMissionLoop()
    CreateThread(function()
        while activeMission do
            Wait(100)
            
            CheckMissionObjectives()
            
            if AllObjectivesCompleted() then
                CompleteMission()
                break
            end
        end
    end)
end

function CheckMissionObjectives()
    if not activeMission then return end
    
    for i, objective in ipairs(activeMission.objectives) do
        if not missionProgress.objectives[i].completed then
            local objType = objective.type
            
            if objType == LL.Missions.ObjectiveTypes.GOTO then
                CheckGotoObjective(i, objective)
            elseif objType == LL.Missions.ObjectiveTypes.TALK then
                CheckTalkObjective(i, objective)
            elseif objType == LL.Missions.ObjectiveTypes.CUSTOM then
                if objective.checkFunction then
                    objective.checkFunction(i, objective)
                end
            end
        end
    end
end

function CheckGotoObjective(index, objective)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = LL.GetDistance(playerCoords, objective.coords)
    
    if distance <= (objective.radius or 3.0) then
        CompleteObjective(index)
    end
end

function CheckTalkObjective(index, objective)
    if not objective.npcHandle then return end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local npcCoords = GetEntityCoords(objective.npcHandle)
    local distance = LL.GetDistance(playerCoords, npcCoords)
    
    if distance <= 2.0 then
        DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, "[E] Beszélj")
        
        if IsControlJustReleased(0, 38) then
            if objective.dialog then
                TriggerEvent('ll-notify:show', objective.dialog, 'info')
            end
            CompleteObjective(index)
        end
    end
end

function CompleteObjective(index)
    if not missionProgress.objectives[index] then return end
    
    missionProgress.objectives[index].completed = true
    missionProgress.objectives[index].progress = missionProgress.objectives[index].target
    
    TriggerServerEvent(LL.Events.Mission.UpdateObjective, activeMission.id, index)
    TriggerEvent('ll-notify:show', 'Célkitűzés teljesítve!', 'success')
    
    if activeMission.objectives[index].onComplete then
        activeMission.objectives[index].onComplete()
    end
end

function AllObjectivesCompleted()
    for _, progress in pairs(missionProgress.objectives) do
        if not progress.completed then
            return false
        end
    end
    return true
end

function CompleteMission()
    if not activeMission then return end
    
    LL.Log("Mission completed: " .. activeMission.name, "success")
    TriggerEvent('ll-notify:show', 'Küldetés teljesítve: ' .. activeMission.name, 'success')
    
    if activeMission.onComplete then
        activeMission.onComplete()
    end
    
    if activeMission.rewards then
        GiveRewards(activeMission.rewards)
    end
    
    TriggerServerEvent(LL.Events.Mission.Complete, activeMission.id)
    
    CleanupMission()
end

function GiveRewards(rewards)
    for _, reward in ipairs(rewards) do
        if reward.type == LL.Missions.RewardTypes.MONEY then
            TriggerEvent('ll-notify:show', 'Jutalom: $' .. reward.amount, 'success')
        elseif reward.type == LL.Missions.RewardTypes.ITEM then
            TriggerEvent('ll-notify:show', 'Jutalom: ' .. reward.item .. ' x' .. reward.amount, 'success')
        end
    end
end

function SpawnMissionNPCs(npcs)
    for i, npcData in ipairs(npcs) do
        local model = GetHashKey(npcData.model or LL.Missions.NPCClothing.DefaultMaleModel)
        
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(100) end
        
        local npc = CreatePed(4, model, npcData.coords.x, npcData.coords.y, npcData.coords.z, npcData.heading or 0.0, false, true)
        SetEntityAsMissionEntity(npc, true, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        FreezeEntityPosition(npc, true)
        
        if npcData.clothing then
            ApplyNPCClothing(npc, npcData.clothing)
        end
        
        if npcData.animation then
            PlayNPCAnimation(npc, npcData.animation)
        end
        
        table.insert(missionNPCs, npc)
        
        if npcData.isObjectiveNPC then
            for j, obj in ipairs(activeMission.objectives) do
                if obj.npcIndex == i then
                    activeMission.objectives[j].npcHandle = npc
                end
            end
        end
    end
end

function ApplyNPCClothing(ped, clothing)
    if not LL.Missions.NPCClothing.EnableCustomClothing then return end
    
    if clothing.components then
        for componentId, data in pairs(clothing.components) do
            SetPedComponentVariation(ped, componentId, data.drawable, data.texture, 0)
        end
    end
    
    if clothing.props then
        for propId, data in pairs(clothing.props) do
            SetPedPropIndex(ped, propId, data.drawable, data.texture, true)
        end
    end
end

function PlayNPCAnimation(ped, animData)
    RequestAnimDict(animData.dict)
    while not HasAnimDictLoaded(animData.dict) do Wait(100) end
    
    TaskPlayAnim(ped, animData.dict, animData.name, 8.0, -8.0, -1, animData.flag or 1, 0, false, false, false)
end

function CleanupMission()
    for _, npc in ipairs(missionNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    
    missionNPCs = {}
    activeMission = nil
    missionProgress = {}
end

RegisterNetEvent(LL.Events.Mission.Fail, function(reason)
    if not activeMission then return end
    
    LL.Log("Mission failed: " .. (reason or "Unknown"), "error")
    TriggerEvent('ll-notify:show', 'Küldetés sikertelen: ' .. (reason or ""), 'error')
    
    if activeMission.onFail then
        activeMission.onFail()
    end
    
    CleanupMission()
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

exports('GetActiveMission', function()
    return activeMission
end)

exports('GetMissionProgress', function()
    return missionProgress
end)

exports('StartMission', function(missionId)
    TriggerServerEvent(LL.Events.Mission.Start, missionId)
end)
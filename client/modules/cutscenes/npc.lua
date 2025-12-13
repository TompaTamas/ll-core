-- Cutscene NPC Management
local cutsceneNPCs = {}
local npcAnimations = {}

function SpawnCutsceneNPC(npcData)
    local model = GetHashKey(npcData.model)
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    
    local coords = npcData.coords or vector3(0, 0, 0)
    local heading = npcData.heading or 0.0
    
    local npc = CreatePed(4, model, coords.x, coords.y, coords.z, heading, false, true)
    SetEntityAsMissionEntity(npc, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedCanRagdoll(npc, false)
    SetEntityInvincible(npc, true)
    
    -- Apply clothing if provided
    if npcData.clothing then
        ApplyNPCClothing(npc, npcData.clothing)
    end
    
    -- Apply props if provided
    if npcData.props then
        ApplyNPCProps(npc, npcData.props)
    end
    
    -- Play initial animation if provided
    if npcData.animation then
        PlayNPCAnimation(npc, npcData.animation)
    end
    
    -- Store NPC reference
    table.insert(cutsceneNPCs, {
        entity = npc,
        data = npcData
    })
    
    LL.Log("Cutscene NPC spawned: " .. (npcData.name or "Unknown"), "success")
    
    return npc
end

function ApplyNPCClothing(ped, clothing)
    if not LL.Cutscenes.NPCs.EnableClothing then return end
    
    -- Apply components
    if clothing.components then
        for componentId, data in pairs(clothing.components) do
            local id = tonumber(componentId)
            if id then
                SetPedComponentVariation(ped, id, data.drawable or 0, data.texture or 0, 0)
            end
        end
    end
end

function ApplyNPCProps(ped, props)
    if not LL.Cutscenes.NPCs.EnableClothing then return end
    
    if props then
        for propId, data in pairs(props) do
            local id = tonumber(propId)
            if id then
                if data.drawable >= 0 then
                    SetPedPropIndex(ped, id, data.drawable or 0, data.texture or 0, true)
                else
                    ClearPedProp(ped, id)
                end
            end
        end
    end
end

function PlayNPCAnimation(ped, animData)
    local dict = animData.dict
    local name = animData.name
    local flags = animData.flags or 1
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(100) end
    
    TaskPlayAnim(ped, dict, name, 8.0, -8.0, -1, flags, 0, false, false, false)
    
    -- Store animation reference
    npcAnimations[ped] = {
        dict = dict,
        name = name,
        flags = flags
    }
    
    LL.Log("NPC animation started: " .. dict .. " - " .. name, "info")
end

function StopNPCAnimation(ped)
    if npcAnimations[ped] then
        local anim = npcAnimations[ped]
        StopAnimTask(ped, anim.dict, anim.name, 1.0)
        npcAnimations[ped] = nil
    end
end

function MoveNPCToPosition(ped, coords, speed)
    speed = speed or 1.0
    
    TaskGoToCoordAnyMeans(ped, coords.x, coords.y, coords.z, speed, 0, false, 786603, 0xbf800000)
end

function SetNPCHeading(ped, heading)
    SetEntityHeading(ped, heading)
end

function FreezeNPC(ped, freeze)
    FreezeEntityPosition(ped, freeze)
end

function SetNPCInvisible(ped, invisible)
    SetEntityVisible(ped, not invisible, false)
end

function DeleteCutsceneNPC(ped)
    if DoesEntityExist(ped) then
        StopNPCAnimation(ped)
        DeleteEntity(ped)
        
        -- Remove from storage
        for i, npcData in ipairs(cutsceneNPCs) do
            if npcData.entity == ped then
                table.remove(cutsceneNPCs, i)
                break
            end
        end
        
        LL.Log("Cutscene NPC deleted", "info")
    end
end

function CleanupAllCutsceneNPCs()
    for _, npcData in ipairs(cutsceneNPCs) do
        if DoesEntityExist(npcData.entity) then
            DeleteEntity(npcData.entity)
        end
    end
    
    cutsceneNPCs = {}
    npcAnimations = {}
    
    LL.Log("All cutscene NPCs cleaned up", "info")
end

function GetCutsceneNPCByIndex(index)
    if cutsceneNPCs[index] then
        return cutsceneNPCs[index].entity
    end
    return nil
end

function GetAllCutsceneNPCs()
    return cutsceneNPCs
end

-- NPC Interaction during cutscene
function PlayNPCScenario(ped, scenario)
    TaskStartScenarioInPlace(ped, scenario, 0, true)
end

function StopNPCScenario(ped)
    ClearPedTasks(ped)
end

-- NPC Look At
function MakeNPCLookAt(ped, coords, duration)
    duration = duration or -1
    TaskLookAtCoord(ped, coords.x, coords.y, coords.z, duration, 0, 2)
end

function MakeNPCLookAtEntity(ped, entity, duration)
    duration = duration or -1
    TaskLookAtEntity(ped, entity, duration, 0, 2)
end

function StopNPCLookAt(ped)
    TaskClearLookAt(ped)
end

-- NPC Expressions
function SetNPCFacialExpression(ped, expression)
    SetFacialIdleAnimOverride(ped, expression, 0)
end

function ClearNPCFacialExpression(ped)
    ClearFacialIdleAnimOverride(ped)
end

-- Exports
exports('SpawnCutsceneNPC', SpawnCutsceneNPC)
exports('DeleteCutsceneNPC', DeleteCutsceneNPC)
exports('CleanupAllCutsceneNPCs', CleanupAllCutsceneNPCs)
exports('PlayNPCAnimation', PlayNPCAnimation)
exports('StopNPCAnimation', StopNPCAnimation)
exports('MoveNPCToPosition', MoveNPCToPosition)
exports('SetNPCHeading', SetNPCHeading)
exports('FreezeNPC', FreezeNPC)
exports('SetNPCInvisible', SetNPCInvisible)
exports('GetCutsceneNPCByIndex', GetCutsceneNPCByIndex)
exports('GetAllCutsceneNPCs', GetAllCutsceneNPCs)
exports('PlayNPCScenario', PlayNPCScenario)
exports('MakeNPCLookAt', MakeNPCLookAt)
exports('MakeNPCLookAtEntity', MakeNPCLookAtEntity)
exports('SetNPCFacialExpression', SetNPCFacialExpression)
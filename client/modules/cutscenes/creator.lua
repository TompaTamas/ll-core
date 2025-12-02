-- Cutscene creator with NUI communication - FIXED
local creatorOpen = false
local previewCam = nil
local previewNPCs = {}
local currentCutsceneData = {
    name = "",
    duration = 30000,
    timeline = {},
    npcs = {},
    audio = {}
}

-- Command registration
if LL.Cutscenes.Creator.Command then
    RegisterCommand(LL.Cutscenes.Creator.Command, function()
        if LL.Cutscenes.Creator.AdminOnly then
            -- Admin check here if needed
        end
        OpenCreator()
    end, false)
end

if LL.Cutscenes.Creator.Keybind then
    RegisterKeyMapping(LL.Cutscenes.Creator.Command, 'Open Cutscene Creator', 'keyboard', LL.Cutscenes.Creator.Keybind)
end

function OpenCreator()
    if creatorOpen then 
        LL.Log("Creator already open", "warning")
        return 
    end
    
    creatorOpen = true
    
    -- Disable controls
    CreateThread(function()
        while creatorOpen do
            Wait(0)
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
        end
    end)
    
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    
    -- Get current resource name
    local currentResource = GetCurrentResourceName()
    
    SendNUIMessage({
        action = "openCreator",
        resourceName = currentResource, -- Send resource name to NUI
        data = {
            cutscene = currentCutsceneData,
            config = {
                components = LL.Cutscenes.NPCs.ClothingComponents,
                props = LL.Cutscenes.NPCs.Props,
                animations = LL.Cutscenes.NPCs.Animations
            }
        }
    })
    
    LL.Log("Cutscene creator opened (Resource: " .. currentResource .. ")", "success")
end

function CloseCreator()
    if not creatorOpen then return end
    
    creatorOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = "closeCreator"
    })
    
    CleanupPreview()
    
    LL.Log("Cutscene creator closed", "info")
end

-- NUI Callbacks
RegisterNUICallback('closeCreator', function(data, cb)
    CloseCreator()
    cb({status = 'ok'})
end)

RegisterNUICallback('addKeyframe', function(data, cb)
    local success, result = pcall(function()
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local camFov = GetGameplayCamFov()
        
        return {
            time = data.time or (#currentCutsceneData.timeline * 1000),
            camera = {
                x = camCoords.x,
                y = camCoords.y,
                z = camCoords.z,
                rx = camRot.x,
                ry = camRot.y,
                rz = camRot.z,
                fov = camFov
            }
        }
    end)
    
    if success and result then
        table.insert(currentCutsceneData.timeline, result)
        LL.Log("Keyframe added at " .. result.time .. "ms", "success")
        
        cb({
            success = true,
            keyframe = result
        })
    else
        LL.Log("Failed to add keyframe: " .. tostring(result), "error")
        cb({
            success = false,
            error = "Failed to capture camera data: " .. tostring(result)
        })
    end
end)

RegisterNUICallback('addNPC', function(data, cb)
    LL.Log("addNPC callback received: " .. tostring(data.model), "info")
    
    local success, result = pcall(function()
        local playerPed = PlayerPedId()
        
        if not DoesEntityExist(playerPed) then
            error("Player ped doesn't exist")
        end
        
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        
        LL.Log("Player coords: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z, "info")
        
        local npcData = {
            model = data.model or LL.Cutscenes.NPCs.DefaultModel,
            coords = {
                x = coords.x,
                y = coords.y,
                z = coords.z
            },
            heading = heading,
            clothing = {
                components = {},
                props = {}
            },
            animation = nil
        }
        
        -- Add to list
        table.insert(currentCutsceneData.npcs, npcData)
        local npcId = #currentCutsceneData.npcs
        
        LL.Log("NPC data created: " .. npcData.model .. " at index " .. npcId, "success")
        
        -- Spawn preview in separate thread to avoid blocking
        CreateThread(function()
            local spawnSuccess = SpawnPreviewNPC(npcId, npcData)
            if not spawnSuccess then
                LL.Log("Warning: Preview NPC spawn failed, but NPC added to data", "warning")
            end
        end)
        
        return {
            success = true,
            npcId = npcId,
            npc = npcData
        }
    end)
    
    if success and result then
        LL.Log("addNPC callback success", "success")
        cb(result)
    else
        LL.Log("addNPC callback failed: " .. tostring(result), "error")
        cb({
            success = false,
            error = tostring(result)
        })
    end
end)

RegisterNUICallback('updateNPCClothing', function(data, cb)
    local npcId = tonumber(data.npcId)
    local clothing = data.clothing
    
    LL.Log("updateNPCClothing for NPC: " .. tostring(npcId), "info")
    
    if not npcId or not currentCutsceneData.npcs[npcId] then
        LL.Log("Invalid NPC ID: " .. tostring(npcId), "error")
        cb({success = false, error = "NPC not found"})
        return
    end
    
    local success = pcall(function()
        -- Update data first
        currentCutsceneData.npcs[npcId].clothing = clothing
        
        -- Then update preview if exists
        local npc = previewNPCs[npcId]
        if npc and DoesEntityExist(npc) then
            -- Apply components
            if clothing.components then
                for componentId, componentData in pairs(clothing.components) do
                    local id = tonumber(componentId)
                    local drawable = tonumber(componentData.drawable) or 0
                    local texture = tonumber(componentData.texture) or 0
                    
                    SetPedComponentVariation(npc, id, drawable, texture, 0)
                end
            end
            
            -- Apply props
            if clothing.props then
                for propId, propData in pairs(clothing.props) do
                    local id = tonumber(propId)
                    local drawable = tonumber(propData.drawable)
                    local texture = tonumber(propData.texture) or 0
                    
                    if drawable and drawable >= 0 then
                        SetPedPropIndex(npc, id, drawable, texture, true)
                    else
                        ClearPedProp(npc, id)
                    end
                end
            end
            
            LL.Log("NPC " .. npcId .. " clothing updated successfully", "success")
        else
            LL.Log("NPC " .. npcId .. " preview not found, data updated only", "warning")
        end
    end)
    
    if success then
        cb({success = true})
    else
        LL.Log("Failed to update NPC clothing", "error")
        cb({success = false, error = "Update failed"})
    end
end)

RegisterNUICallback('removeNPC', function(data, cb)
    local npcId = tonumber(data.npcId)
    
    LL.Log("removeNPC: " .. tostring(npcId), "info")
    
    if not npcId then
        cb({success = false, error = "Invalid NPC ID"})
        return
    end
    
    local success = pcall(function()
        -- Delete entity if exists
        if previewNPCs[npcId] and DoesEntityExist(previewNPCs[npcId]) then
            DeleteEntity(previewNPCs[npcId])
            LL.Log("Deleted preview NPC entity", "info")
        end
        
        -- Remove from data
        table.remove(currentCutsceneData.npcs, npcId)
        
        -- Rebuild preview NPCs table with correct indices
        local newPreviewNPCs = {}
        for i, npcData in ipairs(currentCutsceneData.npcs) do
            if previewNPCs[i] then
                newPreviewNPCs[i] = previewNPCs[i]
            end
        end
        previewNPCs = newPreviewNPCs
        
        LL.Log("NPC " .. npcId .. " removed successfully", "success")
    end)
    
    if success then
        cb({success = true})
    else
        LL.Log("Failed to remove NPC", "error")
        cb({success = false, error = "Remove failed"})
    end
end)

RegisterNUICallback('previewCutscene', function(data, cb)
    LL.Log("Preview cutscene requested", "info")
    
    -- Temporarily close NUI
    SetNuiFocus(false, false)
    
    -- Update data
    currentCutsceneData = data
    
    -- Play cutscene
    TriggerEvent(LL.Events.Cutscene.Play, currentCutsceneData)
    
    -- Reopen NUI after cutscene
    SetTimeout(2000, function()
        if creatorOpen then
            SetNuiFocus(true, true)
        end
    end)
    
    cb({status = 'ok'})
end)

RegisterNUICallback('saveCutscene', function(data, cb)
    local name = data.name
    local duration = tonumber(data.duration)
    local cutsceneData = data.cutsceneData
    
    LL.Log("Save cutscene: " .. tostring(name), "info")
    
    if not name or name == "" then
        LL.Log("Save failed: No name provided", "error")
        cb({success = false, error = "Nincs név megadva!"})
        return
    end
    
    -- Update current data
    currentCutsceneData = cutsceneData or currentCutsceneData
    currentCutsceneData.name = name
    currentCutsceneData.duration = duration or 30000
    
    -- Send to server
    TriggerServerEvent(LL.Events.Cutscene.Save, name, currentCutsceneData.duration, currentCutsceneData)
    
    LL.Log("Cutscene save requested: " .. name, "info")
    
    Wait(500)
    
    cb({success = true})
end)

RegisterNUICallback('loadCutscene', function(data, cb)
    local name = data.name
    
    LL.Log("Load cutscene: " .. tostring(name), "info")
    
    if not name or name == "" then
        cb({success = false, error = "Nincs név megadva!"})
        return
    end
    
    TriggerServerEvent(LL.Events.Cutscene.Load, name)
    
    cb({status = 'ok'})
end)

-- Load event from server
RegisterNetEvent(LL.Events.Cutscene.Load, function(cutsceneData)
    if not cutsceneData then
        LL.Log("Received empty cutscene data", "error")
        return
    end
    
    currentCutsceneData = cutsceneData
    
    -- Update NUI
    SendNUIMessage({
        action = "updateCutscene",
        data = cutsceneData
    })
    
    -- Cleanup old NPCs
    CleanupPreview()
    
    -- Spawn new NPCs
    for i, npcData in ipairs(cutsceneData.npcs or {}) do
        CreateThread(function()
            SpawnPreviewNPC(i, npcData)
        end)
    end
    
    LL.Log("Cutscene loaded: " .. (cutsceneData.name or "Unnamed"), "success")
end)

function SpawnPreviewNPC(id, npcData)
    -- Validate data
    if not npcData or not npcData.coords then
        LL.Log("Invalid NPC data for ID " .. id, "error")
        return false
    end
    
    local modelName = npcData.model or LL.Cutscenes.NPCs.DefaultModel
    local model = GetHashKey(modelName)
    
    LL.Log("Spawning preview NPC: " .. modelName .. " (hash: " .. model .. ")", "info")
    
    -- Request model with timeout
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(model) then
        LL.Log("Failed to load model: " .. tostring(modelName), "error")
        return false
    end
    
    -- Create ped
    local npc = CreatePed(4, model, npcData.coords.x, npcData.coords.y, npcData.coords.z, npcData.heading or 0.0, false, true)
    
    if not DoesEntityExist(npc) then
        LL.Log("Failed to create NPC entity", "error")
        SetModelAsNoLongerNeeded(model)
        return false
    end
    
    SetEntityAsMissionEntity(npc, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    
    -- Apply clothing
    if npcData.clothing then
        if npcData.clothing.components then
            for componentId, componentData in pairs(npcData.clothing.components) do
                local id = tonumber(componentId)
                local drawable = tonumber(componentData.drawable) or 0
                local texture = tonumber(componentData.texture) or 0
                SetPedComponentVariation(npc, id, drawable, texture, 0)
            end
        end
        
        if npcData.clothing.props then
            for propId, propData in pairs(npcData.clothing.props) do
                local id = tonumber(propId)
                local drawable = tonumber(propData.drawable)
                local texture = tonumber(propData.texture) or 0
                
                if drawable and drawable >= 0 then
                    SetPedPropIndex(npc, id, drawable, texture, true)
                else
                    ClearPedProp(npc, id)
                end
            end
        end
    end
    
    -- Apply animation
    if npcData.animation and npcData.animation.dict then
        RequestAnimDict(npcData.animation.dict)
        local animTimeout = 0
        while not HasAnimDictLoaded(npcData.animation.dict) and animTimeout < 50 do
            Wait(50)
            animTimeout = animTimeout + 1
        end
        
        if HasAnimDictLoaded(npcData.animation.dict) then
            TaskPlayAnim(npc, npcData.animation.dict, npcData.animation.name, 8.0, -8.0, -1, npcData.animation.flag or 1, 0, false, false, false)
        end
    end
    
    previewNPCs[id] = npc
    SetModelAsNoLongerNeeded(model)
    
    LL.Log("Preview NPC spawned successfully: ID " .. id, "success")
    return true
end

function CleanupPreview()
    LL.Log("Cleaning up preview NPCs", "info")
    
    for id, npc in pairs(previewNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    previewNPCs = {}
end

-- Events
RegisterNetEvent(LL.Events.Cutscene.OpenCreator, function()
    OpenCreator()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    CleanupPreview()
    
    if creatorOpen then
        CloseCreator()
    end
end)

-- ESC key to close
CreateThread(function()
    while true do
        Wait(0)
        
        if creatorOpen and IsControlJustReleased(0, 322) then -- ESC
            CloseCreator()
        end
    end
end)

-- Exports
exports('OpenCreator', OpenCreator)
exports('CloseCreator', CloseCreator)
exports('IsCreatorOpen', function() return creatorOpen end)
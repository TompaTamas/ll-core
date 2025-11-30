-- Cutscene creator with NUI communication
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
    
    SendNUIMessage({
        action = "openCreator",
        data = {
            cutscene = currentCutsceneData,
            config = {
                components = LL.Cutscenes.NPCs.ClothingComponents,
                props = LL.Cutscenes.NPCs.Props,
                animations = LL.Cutscenes.NPCs.Animations
            }
        }
    })
    
    LL.Log("Cutscene creator opened", "success")
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
    local success, keyframe = pcall(function()
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        
        return {
            time = data.time or (#currentCutsceneData.timeline * 1000),
            camera = {
                x = camCoords.x,
                y = camCoords.y,
                z = camCoords.z,
                rx = camRot.x,
                ry = camRot.y,
                rz = camRot.z,
                fov = GetGameplayCamFov()
            }
        }
    end)
    
    if success and keyframe then
        table.insert(currentCutsceneData.timeline, keyframe)
        LL.Log("Keyframe added at " .. keyframe.time .. "ms", "success")
        
        cb({
            success = true,
            keyframe = keyframe
        })
    else
        LL.Log("Failed to add keyframe: " .. tostring(keyframe), "error")
        cb({
            success = false,
            error = "Failed to capture camera data"
        })
    end
end)

RegisterNUICallback('addNPC', function(data, cb)
    local success, result = pcall(function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        
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
        
        -- Spawn preview
        SpawnPreviewNPC(npcId, npcData)
        
        LL.Log("NPC added: " .. npcData.model .. " at index " .. npcId, "success")
        
        return {
            success = true,
            npcId = npcId,
            npc = npcData
        }
    end)
    
    if success and result then
        cb(result)
    else
        LL.Log("Failed to add NPC: " .. tostring(result), "error")
        cb({
            success = false,
            error = tostring(result)
        })
    end
end)

RegisterNUICallback('updateNPCClothing', function(data, cb)
    local npcId = tonumber(data.npcId)
    local clothing = data.clothing
    
    if not npcId or not currentCutsceneData.npcs[npcId] then
        LL.Log("Invalid NPC ID: " .. tostring(npcId), "error")
        cb({success = false, error = "NPC not found"})
        return
    end
    
    local success = pcall(function()
        currentCutsceneData.npcs[npcId].clothing = clothing
        
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
                    local drawable = tonumber(propData.drawable) or -1
                    local texture = tonumber(propData.texture) or 0
                    
                    if drawable >= 0 then
                        SetPedPropIndex(npc, id, drawable, texture, true)
                    else
                        ClearPedProp(npc, id)
                    end
                end
            end
            
            LL.Log("NPC " .. npcId .. " clothing updated", "success")
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
    
    if not npcId then
        cb({success = false, error = "Invalid NPC ID"})
        return
    end
    
    local success = pcall(function()
        -- Delete entity
        if previewNPCs[npcId] and DoesEntityExist(previewNPCs[npcId]) then
            DeleteEntity(previewNPCs[npcId])
        end
        
        -- Remove from list
        table.remove(currentCutsceneData.npcs, npcId)
        
        -- Rebuild preview NPCs table
        local newPreviewNPCs = {}
        for i, npcData in ipairs(currentCutsceneData.npcs) do
            if previewNPCs[i] then
                newPreviewNPCs[i] = previewNPCs[i]
            end
        end
        previewNPCs = newPreviewNPCs
        
        LL.Log("NPC " .. npcId .. " removed", "success")
    end)
    
    if success then
        cb({success = true})
    else
        cb({success = false, error = "Remove failed"})
    end
end)

RegisterNUICallback('previewCutscene', function(data, cb)
    -- Temporarily close NUI
    SetNuiFocus(false, false)
    
    -- Update data
    currentCutsceneData = data
    
    -- Play cutscene
    TriggerEvent(LL.Events.Cutscene.Play, currentCutsceneData)
    
    LL.Log("Preview started", "info")
    
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
    
    if not name or name == "" then
        cb({success = false, error = "Nincs név megadva!"})
        return
    end
    
    TriggerServerEvent(LL.Events.Cutscene.Load, name)
    
    LL.Log("Cutscene load requested: " .. name, "info")
    
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
    for i, npcData in ipairs(cutsceneData.npcs) do
        SpawnPreviewNPC(i, npcData)
    end
    
    LL.Log("Cutscene loaded: " .. (cutsceneData.name or "Unnamed"), "success")
end)

function SpawnPreviewNPC(id, npcData)
    -- Validate data
    if not npcData or not npcData.coords then
        LL.Log("Invalid NPC data for ID " .. id, "error")
        return
    end
    
    local model = GetHashKey(npcData.model or LL.Cutscenes.NPCs.DefaultModel)
    
    -- Request model
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(model) then
        LL.Log("Failed to load model: " .. tostring(npcData.model), "error")
        return
    end
    
    -- Create ped
    local npc = CreatePed(4, model, npcData.coords.x, npcData.coords.y, npcData.coords.z, npcData.heading or 0.0, false, true)
    
    if not DoesEntityExist(npc) then
        LL.Log("Failed to create NPC entity", "error")
        return
    end
    
    SetEntityAsMissionEntity(npc, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    
    -- Apply clothing
    if npcData.clothing then
        if npcData.clothing.components then
            for componentId, data in pairs(npcData.clothing.components) do
                local id = tonumber(componentId)
                local drawable = tonumber(data.drawable) or 0
                local texture = tonumber(data.texture) or 0
                SetPedComponentVariation(npc, id, drawable, texture, 0)
            end
        end
        
        if npcData.clothing.props then
            for propId, data in pairs(npcData.clothing.props) do
                local id = tonumber(propId)
                local drawable = tonumber(data.drawable) or -1
                local texture = tonumber(data.texture) or 0
                
                if drawable >= 0 then
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
    
    LL.Log("Preview NPC spawned: " .. id, "success")
end

function CleanupPreview()
    for id, npc in pairs(previewNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    previewNPCs = {}
    
    LL.Log("Preview NPCs cleaned up", "info")
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
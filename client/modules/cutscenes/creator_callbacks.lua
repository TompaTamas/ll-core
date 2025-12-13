-- Cutscene Creator - NUI Callbacks and Helper Functions - FIXED

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    ToggleUI()
    cb({success = true})
end)

RegisterNUICallback('spawnActor', function(data, cb)
    SpawnActor(data.name, data.model)
    SetNuiFocus(false, false)
    cb({success = true})
end)

RegisterNUICallback('spawnProp', function(data, cb)
    SpawnProp(data.name, data.model)
    SetNuiFocus(false, false)
    cb({success = true})
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    SpawnVehicle(data.name, data.model)
    SetNuiFocus(false, false)
    cb({success = true})
end)

RegisterNUICallback('contextMenuAction', function(data, cb)
    if data.actionIndex and contextMenuActions[data.actionIndex + 1] then
        contextMenuActions[data.actionIndex + 1]()
    end
    SetNuiFocus(false, false)
    cb({success = true})
end)

RegisterNUICallback('saveCutscene', function(data, cb)
    local success = SaveCutscene(data.name)
    cb({success = success})
end)

RegisterNUICallback('loadCutscene', function(data, cb)
    local success = LoadCutscene(data.name)
    cb({success = success})
end)

RegisterNUICallback('deleteCutscene', function(data, cb)
    local success = DeleteCutscene(data.name)
    cb({success = success})
end)

RegisterNUICallback('updateVec4', function(data, cb)
    local type = data.type
    local index = data.index
    local x, y, z, w = tonumber(data.x), tonumber(data.y), tonumber(data.z), tonumber(data.w)
    
    local entity
    if type == 'actor' then
        if currentCutscene.tracks.actors[index] then
            entity = currentCutscene.tracks.actors[index].entity
        end
    elseif type == 'prop' then
        if currentCutscene.tracks.props[index] then
            entity = currentCutscene.tracks.props[index].entity
        end
    elseif type == 'vehicle' then
        if currentCutscene.tracks.vehicles[index] then
            entity = currentCutscene.tracks.vehicles[index].entity
        end
    end
    
    if entity and DoesEntityExist(entity) then
        SetEntityCoords(entity, x, y, z, false, false, false, false)
        SetEntityHeading(entity, w)
        ShowHelpNotification("~g~Position Updated~w~\n" .. string.format("%.2f, %.2f, %.2f, %.2f", x, y, z, w))
    end
    
    SetNuiFocus(false, false)
    cb({success = true})
end)

RegisterNUICallback('updateOutfit', function(data, cb)
    local index = data.index
    if not currentCutscene.tracks.actors[index] then 
        cb({success = false})
        return 
    end
    
    local actor = currentCutscene.tracks.actors[index]
    
    if DoesEntityExist(actor.entity) then
        -- Apply components
        if data.components then
            for id, comp in pairs(data.components) do
                local componentId = tonumber(id)
                if componentId then
                    SetPedComponentVariation(actor.entity, componentId, tonumber(comp.drawable) or 0, tonumber(comp.texture) or 0, 0)
                end
            end
        end
        
        -- Apply props
        if data.props then
            for id, prop in pairs(data.props) do
                local propId = tonumber(id)
                if propId then
                    if tonumber(prop.drawable) >= 0 then
                        SetPedPropIndex(actor.entity, propId, tonumber(prop.drawable), tonumber(prop.texture) or 0, true)
                    else
                        ClearPedProp(actor.entity, propId)
                    end
                end
            end
        end
        
        actor.outfit = {components = data.components, props = data.props}
        ShowHelpNotification("~g~Outfit Updated")
    end
    
    SetNuiFocus(false, false)
    cb({success = true})
end)

RegisterNUICallback('setAnimation', function(data, cb)
    local index = data.index
    if not currentCutscene.tracks.actors[index] then 
        cb({success = false})
        return 
    end
    
    local actor = currentCutscene.tracks.actors[index]
    
    if DoesEntityExist(actor.entity) then
        local dict = data.dict
        local anim = data.anim
        local flags = tonumber(data.flags) or 1
        
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 100 do 
            Wait(50)
            timeout = timeout + 1
        end
        
        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(actor.entity, dict, anim, 8.0, -8.0, -1, flags, 0, false, false, false)
            actor.animation = {dict = dict, name = anim, flags = flags}
            ShowHelpNotification("~g~Animation Set~w~\n" .. dict .. " - " .. anim)
        else
            ShowHelpNotification("~r~Failed to load animation")
        end
    end
    
    SetNuiFocus(false, false)
    cb({success = true})
end)

RegisterNUICallback('updateVehicleMods', function(data, cb)
    local index = data.index
    if not currentCutscene.tracks.vehicles[index] then 
        cb({success = false})
        return 
    end
    
    local veh = currentCutscene.tracks.vehicles[index]
    
    if DoesEntityExist(veh.entity) then
        SetVehicleModKit(veh.entity, 0)
        
        for modType, modValue in pairs(data.mods) do
            SetVehicleMod(veh.entity, tonumber(modType), tonumber(modValue), false)
        end
        
        veh.mods = data.mods
        ShowHelpNotification("~g~Vehicle Mods Updated")
    end
    
    SetNuiFocus(false, false)
    cb({success = true})
end)

RegisterNUICallback('updateVehicleColors', function(data, cb)
    local index = data.index
    if not currentCutscene.tracks.vehicles[index] then 
        cb({success = false})
        return 
    end
    
    local veh = currentCutscene.tracks.vehicles[index]
    
    if DoesEntityExist(veh.entity) then
        SetVehicleColours(veh.entity, tonumber(data.primary), tonumber(data.secondary))
        veh.colors = {primary = tonumber(data.primary), secondary = tonumber(data.secondary)}
        ShowHelpNotification("~g~Vehicle Colors Updated")
    end
    
    SetNuiFocus(false, false)
    cb({success = true})
end)

RegisterNUICallback('testPlay', function(data, cb)
    if currentCutscene.name and currentCutscene.name ~= "" then
        TestPlayCutscene()
    end
    cb({success = true})
end)

RegisterNUICallback('clearScene', function(data, cb)
    CleanupSceneEntities()
    currentCutscene = {
        name = "",
        duration = 30000,
        loop = false,
        timeScale = 1.0,
        startDelay = 0,
        freezeTime = false,
        freezeWeather = false,
        tracks = {
            camera = {},
            actors = {},
            props = {},
            vehicles = {},
            audio = {}
        }
    }
    ShowHelpNotification("~g~Scene Cleared")
    cb({success = true})
end)

RegisterNUICallback('exportCutscene', function(data, cb)
    ExportCutsceneToFile(data.name)
    cb({success = true})
end)

-- Spawn Functions
function SpawnActor(name, model)
    local modelHash = GetHashKey(model)
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do 
        Wait(50)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        ShowHelpNotification("~r~Failed to load actor model")
        LL.Log("Failed to load model: " .. model, "error")
        return
    end
    
    local ped = CreatePed(4, modelHash, freecamCoords.x, freecamCoords.y, freecamCoords.z, 0.0, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, false)
    
    local actor = {
        id = #currentCutscene.tracks.actors + 1,
        name = name,
        model = model,
        entity = ped,
        position = vector4(freecamCoords.x, freecamCoords.y, freecamCoords.z, 0.0),
        keyframes = {},
        outfit = {components = {}, props = {}},
        animation = nil,
        waypoints = {}
    }
    
    table.insert(currentCutscene.tracks.actors, actor)
    table.insert(sceneEntities, ped)
    
    LL.Log("Actor spawned: " .. name, "success")
    ShowHelpNotification("~g~Actor Spawned~w~\n" .. name)
    
    -- Update UI
    SendNUIMessage({
        action = "entitySpawned",
        entityType = "actor",
        count = #currentCutscene.tracks.actors
    })
end

function SpawnProp(name, model)
    local modelHash = GetHashKey(model)
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do 
        Wait(50)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        ShowHelpNotification("~r~Failed to load prop model")
        LL.Log("Failed to load model: " .. model, "error")
        return
    end
    
    local prop = CreateObject(modelHash, freecamCoords.x, freecamCoords.y, freecamCoords.z, false, false, false)
    SetEntityAsMissionEntity(prop, true, true)
    FreezeEntityPosition(prop, false)
    
    local propData = {
        id = #currentCutscene.tracks.props + 1,
        name = name,
        model = model,
        entity = prop,
        position = vector4(freecamCoords.x, freecamCoords.y, freecamCoords.z, 0.0),
        keyframes = {}
    }
    
    table.insert(currentCutscene.tracks.props, propData)
    table.insert(sceneEntities, prop)
    
    LL.Log("Prop spawned: " .. name, "success")
    ShowHelpNotification("~g~Prop Spawned~w~\n" .. name)
    
    SendNUIMessage({
        action = "entitySpawned",
        entityType = "prop",
        count = #currentCutscene.tracks.props
    })
end

function SpawnVehicle(name, model)
    local modelHash = GetHashKey(model)
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do 
        Wait(50)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        ShowHelpNotification("~r~Failed to load vehicle model")
        LL.Log("Failed to load model: " .. model, "error")
        return
    end
    
    -- Find ground Z
    local groundZ = freecamCoords.z
    local found, zCoord = GetGroundZFor_3dCoord(freecamCoords.x, freecamCoords.y, freecamCoords.z + 100.0, 0)
    if found then
        groundZ = zCoord + 1.0
    end
    
    local veh = CreateVehicle(modelHash, freecamCoords.x, freecamCoords.y, groundZ, 0.0, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleDoorsLocked(veh, 1)
    FreezeEntityPosition(veh, false)
    
    local vehData = {
        id = #currentCutscene.tracks.vehicles + 1,
        name = name,
        model = model,
        entity = veh,
        position = vector4(freecamCoords.x, freecamCoords.y, groundZ, 0.0),
        mods = {},
        colors = {primary = 0, secondary = 0},
        keyframes = {}
    }
    
    table.insert(currentCutscene.tracks.vehicles, vehData)
    table.insert(sceneEntities, veh)
    
    LL.Log("Vehicle spawned: " .. name, "success")
    ShowHelpNotification("~g~Vehicle Spawned~w~\n" .. name)
    
    SendNUIMessage({
        action = "entitySpawned",
        entityType = "vehicle",
        count = #currentCutscene.tracks.vehicles
    })
end

-- Save/Load/Delete Functions
function SaveCutscene(name)
    if not name or name == "" then
        ShowHelpNotification("~r~Error~w~\nPlease enter a cutscene name")
        return false
    end
    
    currentCutscene.name = name
    
    -- Create save data
    local saveData = {}
    for k, v in pairs(currentCutscene) do
        saveData[k] = v
    end
    
    -- Deep copy tracks
    saveData.tracks = {
        camera = {},
        actors = {},
        props = {},
        vehicles = {},
        audio = {}
    }
    
    -- Copy camera keyframes
    for _, kf in ipairs(currentCutscene.tracks.camera) do
        table.insert(saveData.tracks.camera, kf)
    end
    
    -- Remove entity references and store positions
    for _, actor in ipairs(currentCutscene.tracks.actors) do
        local actorCopy = {}
        for k, v in pairs(actor) do
            if k ~= "entity" then
                actorCopy[k] = v
            end
        end
        
        if DoesEntityExist(actor.entity) then
            local coords = GetEntityCoords(actor.entity)
            local heading = GetEntityHeading(actor.entity)
            actorCopy.position = {x = coords.x, y = coords.y, z = coords.z, w = heading}
        end
        
        table.insert(saveData.tracks.actors, actorCopy)
    end
    
    for _, prop in ipairs(currentCutscene.tracks.props) do
        local propCopy = {}
        for k, v in pairs(prop) do
            if k ~= "entity" then
                propCopy[k] = v
            end
        end
        
        if DoesEntityExist(prop.entity) then
            local coords = GetEntityCoords(prop.entity)
            local rot = GetEntityRotation(prop.entity, 2)
            propCopy.position = {x = coords.x, y = coords.y, z = coords.z, w = rot.z}
        end
        
        table.insert(saveData.tracks.props, propCopy)
    end
    
    for _, veh in ipairs(currentCutscene.tracks.vehicles) do
        local vehCopy = {}
        for k, v in pairs(veh) do
            if k ~= "entity" then
                vehCopy[k] = v
            end
        end
        
        if DoesEntityExist(veh.entity) then
            local coords = GetEntityCoords(veh.entity)
            local heading = GetEntityHeading(veh.entity)
            vehCopy.position = {x = coords.x, y = coords.y, z = coords.z, w = heading}
        end
        
        table.insert(saveData.tracks.vehicles, vehCopy)
    end
    
    -- Check if exists
    local existingIndex = nil
    for i, saved in ipairs(savedCutscenes) do
        if saved.name == name then
            existingIndex = i
            break
        end
    end
    
    if existingIndex then
        savedCutscenes[existingIndex] = saveData
    else
        table.insert(savedCutscenes, saveData)
    end
    
    -- Save to file
    local success, jsonData = pcall(json.encode, savedCutscenes)
    if success then
        SaveResourceFile(GetCurrentResourceName(), "cutscenes/saved_cutscenes.json", jsonData, -1)
        
        -- Also send to server for backup
        TriggerServerEvent(LL.Events.Cutscene.Save, name, currentCutscene.duration, saveData)
        
        SendNUIMessage({
            action = "cutsceneSaved",
            savedCutscenes = savedCutscenes
        })
        
        ShowHelpNotification("~g~Cutscene Saved~w~\n" .. name)
        LL.Log("Cutscene saved: " .. name, "success")
        return true
    else
        ShowHelpNotification("~r~Failed to save cutscene")
        LL.Log("JSON encode error: " .. tostring(jsonData), "error")
        return false
    end
end

function LoadCutscene(name)
    for _, saved in ipairs(savedCutscenes) do
        if saved.name == name then
            CleanupSceneEntities()
            
            -- Deep copy
            currentCutscene = {
                name = saved.name,
                duration = saved.duration,
                loop = saved.loop,
                timeScale = saved.timeScale,
                startDelay = saved.startDelay,
                freezeTime = saved.freezeTime,
                freezeWeather = saved.freezeWeather,
                tracks = {
                    camera = {},
                    actors = {},
                    props = {},
                    vehicles = {},
                    audio = {}
                }
            }
            
            -- Copy camera keyframes
            for _, kf in ipairs(saved.tracks.camera) do
                table.insert(currentCutscene.tracks.camera, kf)
            end
            
            -- Respawn actors
            for _, actor in ipairs(saved.tracks.actors) do
                local modelHash = GetHashKey(actor.model)
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do Wait(50) end
                
                local pos = actor.position
                local ped = CreatePed(4, modelHash, pos.x, pos.y, pos.z, pos.w or 0.0, false, true)
                SetEntityAsMissionEntity(ped, true, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                SetEntityInvincible(ped, true)
                
                local actorCopy = {}
                for k, v in pairs(actor) do
                    actorCopy[k] = v
                end
                actorCopy.entity = ped
                
                table.insert(currentCutscene.tracks.actors, actorCopy)
                table.insert(sceneEntities, ped)
            end
            
            -- Respawn props
            for _, prop in ipairs(saved.tracks.props) do
                local modelHash = GetHashKey(prop.model)
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do Wait(50) end
                
                local pos = prop.position
                local obj = CreateObject(modelHash, pos.x, pos.y, pos.z, false, false, false)
                SetEntityAsMissionEntity(obj, true, true)
                SetEntityRotation(obj, 0, 0, pos.w or 0.0, 2, true)
                
                local propCopy = {}
                for k, v in pairs(prop) do
                    propCopy[k] = v
                end
                propCopy.entity = obj
                
                table.insert(currentCutscene.tracks.props, propCopy)
                table.insert(sceneEntities, obj)
            end
            
            -- Respawn vehicles
            for _, veh in ipairs(saved.tracks.vehicles) do
                local modelHash = GetHashKey(veh.model)
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do Wait(50) end
                
                local pos = veh.position
                local vehicle = CreateVehicle(modelHash, pos.x, pos.y, pos.z, pos.w or 0.0, true, false)
                SetEntityAsMissionEntity(vehicle, true, true)
                SetVehicleOnGroundProperly(vehicle)
                
                local vehCopy = {}
                for k, v in pairs(veh) do
                    vehCopy[k] = v
                end
                vehCopy.entity = vehicle
                
                table.insert(currentCutscene.tracks.vehicles, vehCopy)
                table.insert(sceneEntities, vehicle)
            end
            
            SendNUIMessage({
                action = "cutsceneLoaded",
                cutscene = currentCutscene
            })
            
            ShowHelpNotification("~g~Cutscene Loaded~w~\n" .. name)
            LL.Log("Cutscene loaded: " .. name, "success")
            return true
        end
    end
    
    ShowHelpNotification("~r~Error~w~\nCutscene not found")
    LL.Log("Cutscene not found: " .. name, "error")
    return false
end

function DeleteCutscene(name)
    for i, saved in ipairs(savedCutscenes) do
        if saved.name == name then
            table.remove(savedCutscenes, i)
            
            local success, jsonData = pcall(json.encode, savedCutscenes)
            if success then
                SaveResourceFile(GetCurrentResourceName(), "cutscenes/saved_cutscenes.json", jsonData, -1)
            end
            
            SendNUIMessage({
                action = "cutsceneDeleted",
                savedCutscenes = savedCutscenes
            })
            
            ShowHelpNotification("~g~Cutscene Deleted~w~\n" .. name)
            LL.Log("Cutscene deleted: " .. name, "success")
            return true
        end
    end
    return false
end

function DeleteSelectedEntity()
    if not selectedEntity or not selectedType or not selectedIndex then return end
    
    if selectedType == 'actor' then
        local actor = currentCutscene.tracks.actors[selectedIndex]
        if actor and DoesEntityExist(actor.entity) then
            DeleteEntity(actor.entity)
        end
        table.remove(currentCutscene.tracks.actors, selectedIndex)
        LL.Log("Actor deleted", "info")
    elseif selectedType == 'prop' then
        local prop = currentCutscene.tracks.props[selectedIndex]
        if prop and DoesEntityExist(prop.entity) then
            DeleteEntity(prop.entity)
        end
        table.remove(currentCutscene.tracks.props, selectedIndex)
        LL.Log("Prop deleted", "info")
    elseif selectedType == 'vehicle' then
        local veh = currentCutscene.tracks.vehicles[selectedIndex]
        if veh and DoesEntityExist(veh.entity) then
            DeleteEntity(veh.entity)
        end
        table.remove(currentCutscene.tracks.vehicles, selectedIndex)
        LL.Log("Vehicle deleted", "info")
    end
    
    CleanupSelection()
    ShowHelpNotification("~r~Entity Deleted")
end

function CleanupSceneEntities()
    for _, entity in ipairs(sceneEntities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    sceneEntities = {}
    
    currentCutscene.tracks.actors = {}
    currentCutscene.tracks.props = {}
    currentCutscene.tracks.vehicles = {}
end

function TestPlayCutscene()
    ShowHelpNotification("~g~Test Play~w~\nPlaying cutscene...")
    
    -- Temporarily exit creator mode
    local wasActive = creatorActive
    if wasActive then
        ExitCreator()
    end
    
    Wait(500)
    
    -- Play cutscene
    TriggerEvent(LL.Events.Cutscene.Play, currentCutscene)
    
    -- Return to creator after cutscene
    Wait(currentCutscene.duration + 1000)
    if wasActive then
        EnterCreator()
    end
end

function ExportCutsceneToFile(name)
    ShowHelpNotification("~g~Export~w~\nCheck server console for JSON")
    local success, jsonData = pcall(json.encode, currentCutscene)
    if success then
        LL.Log("=== CUTSCENE EXPORT: " .. name .. " ===", "info")
        LL.Log(jsonData, "info")
        LL.Log("=== END EXPORT ===", "info")
    end
end
-- Cutscene Creator - NUI Callbacks and Helper Functions

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    ToggleUI()
    cb('ok')
end)

RegisterNUICallback('spawnActor', function(data, cb)
    SpawnActor(data.name, data.model)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('spawnProp', function(data, cb)
    SpawnProp(data.name, data.model)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    SpawnVehicle(data.name, data.model)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('contextMenuAction', function(data, cb)
    if data.actionIndex and contextMenuActions[data.actionIndex] then
        contextMenuActions[data.actionIndex]()
    end
    SetNuiFocus(false, false)
    cb('ok')
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
        entity = currentCutscene.tracks.actors[index].entity
    elseif type == 'prop' then
        entity = currentCutscene.tracks.props[index].entity
    elseif type == 'vehicle' then
        entity = currentCutscene.tracks.vehicles[index].entity
    end
    
    if DoesEntityExist(entity) then
        SetEntityCoords(entity, x, y, z, false, false, false, false)
        SetEntityHeading(entity, w)
        ShowHelpNotification("~g~Position Updated~w~\n" .. string.format("%.2f, %.2f, %.2f, %.2f", x, y, z, w))
    end
    
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('updateOutfit', function(data, cb)
    local index = data.index
    local actor = currentCutscene.tracks.actors[index]
    
    if DoesEntityExist(actor.entity) then
        -- Apply components
        if data.components then
            for id, comp in pairs(data.components) do
                SetPedComponentVariation(actor.entity, tonumber(id), tonumber(comp.drawable), tonumber(comp.texture), 0)
            end
        end
        
        -- Apply props
        if data.props then
            for id, prop in pairs(data.props) do
                if tonumber(prop.drawable) >= 0 then
                    SetPedPropIndex(actor.entity, tonumber(id), tonumber(prop.drawable), tonumber(prop.texture), true)
                else
                    ClearPedProp(actor.entity, tonumber(id))
                end
            end
        end
        
        actor.outfit = {components = data.components, props = data.props}
        ShowHelpNotification("~g~Outfit Updated")
    end
    
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('setAnimation', function(data, cb)
    local index = data.index
    local actor = currentCutscene.tracks.actors[index]
    
    if DoesEntityExist(actor.entity) then
        local dict = data.dict
        local anim = data.anim
        local flags = tonumber(data.flags) or 1
        
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(50) end
        
        TaskPlayAnim(actor.entity, dict, anim, 8.0, -8.0, -1, flags, 0, false, false, false)
        
        actor.animation = {dict = dict, name = anim, flags = flags}
        ShowHelpNotification("~g~Animation Set~w~\n" .. dict .. " - " .. anim)
    end
    
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('updateVehicleMods', function(data, cb)
    local index = data.index
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
    cb('ok')
end)

RegisterNUICallback('updateVehicleColors', function(data, cb)
    local index = data.index
    local veh = currentCutscene.tracks.vehicles[index]
    
    if DoesEntityExist(veh.entity) then
        SetVehicleColours(veh.entity, tonumber(data.primary), tonumber(data.secondary))
        veh.colors = {primary = tonumber(data.primary), secondary = tonumber(data.secondary)}
        ShowHelpNotification("~g~Vehicle Colors Updated")
    end
    
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('testPlay', function(data, cb)
    if currentCutscene.name and currentCutscene.name ~= "" then
        TestPlayCutscene()
    end
    cb('ok')
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
    cb('ok')
end)

RegisterNUICallback('exportCutscene', function(data, cb)
    ExportCutsceneToFile(data.name)
    cb('ok')
end)

-- Spawn Functions
function SpawnActor(name, model)
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do Wait(50) end
    
    local ped = CreatePed(4, GetHashKey(model), freecamCoords.x, freecamCoords.y, freecamCoords.z, 0.0, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    
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
end

function SpawnProp(name, model)
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do Wait(50) end
    
    local prop = CreateObject(GetHashKey(model), freecamCoords.x, freecamCoords.y, freecamCoords.z, false, false, false)
    SetEntityAsMissionEntity(prop, true, true)
    
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
end

function SpawnVehicle(name, model)
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do Wait(50) end
    
    local veh = CreateVehicle(GetHashKey(model), freecamCoords.x, freecamCoords.y, freecamCoords.z, 0.0, false, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleEngineOn(veh, false, true, true)
    
    local vehData = {
        id = #currentCutscene.tracks.vehicles + 1,
        name = name,
        model = model,
        entity = veh,
        position = vector4(freecamCoords.x, freecamCoords.y, freecamCoords.z, 0.0),
        mods = {},
        colors = {primary = 0, secondary = 0},
        keyframes = {}
    }
    
    table.insert(currentCutscene.tracks.vehicles, vehData)
    table.insert(sceneEntities, veh)
    
    LL.Log("Vehicle spawned: " .. name, "success")
end

-- Save/Load/Delete Functions
function SaveCutscene(name)
    if not name or name == "" then
        ShowHelpNotification("~r~Error~w~\nPlease enter a cutscene name")
        return false
    end
    
    currentCutscene.name = name
    
    -- Create save data
    local saveData = LL.DeepCopy(currentCutscene)
    
    -- Remove entity references and store positions
    for _, actor in ipairs(saveData.tracks.actors) do
        if DoesEntityExist(actor.entity) then
            local coords = GetEntityCoords(actor.entity)
            local heading = GetEntityHeading(actor.entity)
            actor.position = vector4(coords.x, coords.y, coords.z, heading)
        end
        actor.entity = nil
    end
    
    for _, prop in ipairs(saveData.tracks.props) do
        if DoesEntityExist(prop.entity) then
            local coords = GetEntityCoords(prop.entity)
            local rot = GetEntityRotation(prop.entity, 2)
            prop.position = vector4(coords.x, coords.y, coords.z, rot.z)
        end
        prop.entity = nil
    end
    
    for _, veh in ipairs(saveData.tracks.vehicles) do
        if DoesEntityExist(veh.entity) then
            local coords = GetEntityCoords(veh.entity)
            local heading = GetEntityHeading(veh.entity)
            veh.position = vector4(coords.x, coords.y, coords.z, heading)
        end
        veh.entity = nil
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
    local json = json.encode(savedCutscenes)
    SaveResourceFile(GetCurrentResourceName(), LL.Cutscenes.SavedCutscenesFile, json, -1)
    
    -- Also send to server for backup
    TriggerServerEvent(LL.Events.Cutscene.Save, name, currentCutscene.duration, saveData)
    
    SendNUIMessage({
        action = "cutsceneSaved",
        savedCutscenes = savedCutscenes
    })
    
    ShowHelpNotification("~g~Cutscene Saved~w~\n" .. name)
    LL.Log("Cutscene saved: " .. name, "success")
    return true
end

function LoadCutscene(name)
    for _, saved in ipairs(savedCutscenes) do
        if saved.name == name then
            CleanupSceneEntities()
            currentCutscene = LL.DeepCopy(saved)
            
            -- Respawn entities
            for _, actor in ipairs(currentCutscene.tracks.actors) do
                RequestModel(GetHashKey(actor.model))
                while not HasModelLoaded(GetHashKey(actor.model)) do Wait(50) end
                
                local ped = CreatePed(4, GetHashKey(actor.model), actor.position.x, actor.position.y, actor.position.z, actor.position.w, false, true)
                SetEntityAsMissionEntity(ped, true, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                SetEntityInvincible(ped, true)
                actor.entity = ped
                table.insert(sceneEntities, ped)
            end
            
            for _, prop in ipairs(currentCutscene.tracks.props) do
                RequestModel(GetHashKey(prop.model))
                while not HasModelLoaded(GetHashKey(prop.model)) do Wait(50) end
                
                local obj = CreateObject(GetHashKey(prop.model), prop.position.x, prop.position.y, prop.position.z, false, false, false)
                SetEntityAsMissionEntity(obj, true, true)
                SetEntityRotation(obj, 0, 0, prop.position.w, 2, true)
                prop.entity = obj
                table.insert(sceneEntities, obj)
            end
            
            for _, veh in ipairs(currentCutscene.tracks.vehicles) do
                RequestModel(GetHashKey(veh.model))
                while not HasModelLoaded(GetHashKey(veh.model)) do Wait(50) end
                
                local vehicle = CreateVehicle(GetHashKey(veh.model), veh.position.x, veh.position.y, veh.position.z, veh.position.w, false, false)
                SetEntityAsMissionEntity(vehicle, true, true)
                veh.entity = vehicle
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
            
            local json = json.encode(savedCutscenes)
            SaveResourceFile(GetCurrentResourceName(), LL.Cutscenes.SavedCutscenesFile, json, -1)
            
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
        if DoesEntityExist(actor.entity) then
            DeleteEntity(actor.entity)
        end
        table.remove(currentCutscene.tracks.actors, selectedIndex)
        LL.Log("Actor deleted", "info")
    elseif selectedType == 'prop' then
        local prop = currentCutscene.tracks.props[selectedIndex]
        if DoesEntityExist(prop.entity) then
            DeleteEntity(prop.entity)
        end
        table.remove(currentCutscene.tracks.props, selectedIndex)
        LL.Log("Prop deleted", "info")
    elseif selectedType == 'vehicle' then
        local veh = currentCutscene.tracks.vehicles[selectedIndex]
        if DoesEntityExist(veh.entity) then
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
end

function TestPlayCutscene()
    ShowHelpNotification("~g~Test Play~w~\nPlaying cutscene...")
    
    -- Temporarily exit creator mode
    local wasActive = creatorActive
    if wasActive then
        ExitCreator()
    end
    
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
    LL.Log("=== CUTSCENE EXPORT: " .. name .. " ===", "info")
    LL.Log(json.encode(currentCutscene, {indent = true}), "info")
    LL.Log("=== END EXPORT ===", "info")
end

-- Helper Functions
function RaycastFromCursor()
    local camCoord = GetCamCoord(freecamCam)
    local camRot = GetCamRot(freecamCam, 2)
    local direction = RotationToDirection(camRot)
    local destination = vector3(
        camCoord.x + direction.x * 1000.0,
        camCoord.y + direction.y * 1000.0,
        camCoord.z + direction.z * 1000.0
    )
    
    local rayHandle = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0)
    local _, hit, coords, _, entity = GetShapeTestResult(rayHandle)
    
    return hit, coords, entity
end

function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        math.rad(rotation.x),
        math.rad(rotation.y),
        math.rad(rotation.z)
    )
    
    return vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
end

function Draw3DText(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    
    if onScreen then
        SetTextScale(scale or 0.35, scale or 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function DrawEntityBox(entity, r, g, b)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    local coords = GetEntityCoords(entity)
    
    -- Simple bounding box visualization
    local corners = {
        vector3(min.x, min.y, min.z),
        vector3(max.x, min.y, min.z),
        vector3(max.x, max.y, min.z),
        vector3(min.x, max.y, min.z),
        vector3(min.x, min.y, max.z),
        vector3(max.x, min.y, max.z),
        vector3(max.x, max.y, max.z),
        vector3(min.x, max.y, max.z)
    }
    
    for i = 1, #corners do
        local worldCoords = GetOffsetFromEntityInWorldCoords(entity, corners[i].x, corners[i].y, corners[i].z)
        DrawMarker(28, worldCoords.x, worldCoords.y, worldCoords.z, 0, 0, 0, 0, 0, 0, 0.1, 0.1, 0.1, r, g, b, 200, false, false, 2, false, nil, nil, false)
    end
end

function ShowHelpNotification(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if creatorActive then
        ExitCreator()
    end
    
    CleanupSceneEntities()
end)
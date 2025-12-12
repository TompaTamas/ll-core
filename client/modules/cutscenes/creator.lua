-- Story Mode Quality Cutscene Creator - In-Game Editor
local creatorActive = false
local freecamActive = false
local freecamCam = nil
local freecamCoords = vector3(0, 0, 0)
local freecamRot = vector3(0, 0, 0)
local freecamFov = 50.0
local freecamSpeed = 0.5

local uiVisible = false
local mouseControlEnabled = false
local selectedEntity = nil
local selectedType = nil -- 'actor', 'prop', 'vehicle', 'camera'
local selectedIndex = nil

local currentCutscene = {
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

local savedCutscenes = {}
local sceneEntities = {}
local isPlaying = false
local playbackTime = 0

-- Load saved cutscenes
CreateThread(function()
    Wait(2000)
    local stored = LoadResourceFile(GetCurrentResourceName(), "cutscenes/saved_cutscenes.json")
    if stored and stored ~= "" then
        local decoded = json.decode(stored)
        if decoded then
            savedCutscenes = decoded
            LL.Log("Loaded " .. #savedCutscenes .. " saved cutscenes", "info")
        end
    end
end)

-- Commands
RegisterCommand('cutscenecreator', function()
    if creatorActive then
        ExitCreator()
    else
        EnterCreator()
    end
end, false)

RegisterKeyMapping('cutscenecreator', 'Toggle Cutscene Creator', 'keyboard', 'F9')

-- Toggle UI (F4)
RegisterCommand('+togglecreatorui', function()
    if creatorActive then
        ToggleUI()
    end
end, false)
RegisterCommand('-togglecreatorui', function() end, false)
RegisterKeyMapping('+togglecreatorui', 'Toggle Creator UI', 'keyboard', 'F4')

-- Toggle Mouse (M)
RegisterCommand('+togglemouse', function()
    if creatorActive and not uiVisible then
        ToggleMouse()
    end
end, false)
RegisterCommand('-togglemouse', function() end, false)
RegisterKeyMapping('+togglemouse', 'Toggle Mouse Selection', 'keyboard', 'M')

-- Add Camera Keyframe (E)
RegisterCommand('+addcamkey', function()
    if creatorActive and freecamActive and not mouseControlEnabled then
        AddCameraKeyframe()
    end
end, false)
RegisterCommand('-addcamkey', function() end, false)
RegisterKeyMapping('+addcamkey', 'Add Camera Keyframe', 'keyboard', 'E')

-- Delete Selected (DELETE)
RegisterCommand('deleteselected', function()
    if creatorActive and selectedEntity then
        DeleteSelectedEntity()
    end
end, false)
RegisterKeyMapping('deleteselected', 'Delete Selected', 'keyboard', 'DELETE')

function EnterCreator()
    creatorActive = true
    EnableFreecam()
    
    -- Show minimal UI
    uiVisible = true
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "enterCreator",
        data = {
            cutscene = currentCutscene,
            savedCutscenes = savedCutscenes
        }
    })
    
    -- Controls loop
    CreateThread(function()
        while creatorActive do
            Wait(0)
            
            if not uiVisible and not mouseControlEnabled then
                DisableControlAction(0, 24, true) -- Attack
                DisableControlAction(0, 25, true) -- Aim
                DisableControlAction(0, 140, true) -- Melee Light
                DisableControlAction(0, 141, true) -- Melee Heavy
                DisableControlAction(0, 142, true) -- Melee Alternate
            end
        end
    end)
    
    LL.Log("Cutscene Creator activated - F4: Toggle UI, M: Mouse Mode", "success")
    ShowHelpNotification("~b~Cutscene Creator~w~\n~g~F4~w~: Toggle UI | ~g~M~w~: Mouse Mode | ~g~E~w~: Add Camera Keyframe")
end

function ExitCreator()
    creatorActive = false
    uiVisible = false
    mouseControlEnabled = false
    DisableFreecam()
    CleanupSelection()
    
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "exitCreator" })
    
    LL.Log("Cutscene Creator deactivated", "info")
end

function ToggleUI()
    uiVisible = not uiVisible
    
    if uiVisible then
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "showUI",
            data = {
                cutscene = currentCutscene,
                savedCutscenes = savedCutscenes
            }
        })
        
        -- Disable freecam movement when UI is open
        if mouseControlEnabled then
            mouseControlEnabled = false
        end
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "hideUI" })
    end
end

function ToggleMouse()
    if uiVisible then return end
    
    mouseControlEnabled = not mouseControlEnabled
    
    if mouseControlEnabled then
        SetNuiFocus(false, false)
        ShowHelpNotification("~g~Mouse Selection Mode~w~\nLeft Click: Select Entity\nRight Click: Context Menu\nM: Exit Mouse Mode")
        
        CreateThread(function()
            while mouseControlEnabled and creatorActive do
                Wait(0)
                
                -- Draw cursor
                ShowCursorThisFrame()
                
                -- Left click - Select
                if IsDisabledControlJustPressed(0, 24) then -- Left Click
                    SelectEntityUnderCursor()
                end
                
                -- Right click - Context menu
                if IsDisabledControlJustPressed(0, 25) then -- Right Click
                    if selectedEntity then
                        ShowContextMenu()
                    else
                        ShowMainContextMenu()
                    end
                end
            end
        end)
    else
        SetNuiFocus(false, false)
        CleanupSelection()
    end
end

-- Freecam System
function EnableFreecam()
    if freecamActive then return end
    
    freecamActive = true
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    freecamCoords = coords
    freecamRot = vector3(0, 0, heading)
    
    freecamCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(freecamCam, coords.x, coords.y, coords.z)
    SetCamRot(freecamCam, freecamRot.x, freecamRot.y, freecamRot.z, 2)
    SetCamFov(freecamCam, freecamFov)
    SetCamActive(freecamCam, true)
    RenderScriptCams(true, true, 500, true, true)
    
    FreezeEntityPosition(playerPed, true)
    SetEntityVisible(playerPed, false, false)
    
    -- Freecam movement thread
    CreateThread(function()
        while freecamActive do
            Wait(0)
            
            -- Only move if UI is closed and mouse is not active
            if not uiVisible and not mouseControlEnabled then
                -- Movement
                local forward = IsControlPressed(0, 32) -- W
                local backward = IsControlPressed(0, 33) -- S
                local left = IsControlPressed(0, 34) -- A
                local right = IsControlPressed(0, 35) -- D
                local up = IsControlPressed(0, 44) -- Q
                local down = IsControlPressed(0, 46) -- E (only when not adding keyframe)
                
                -- Speed
                local sprint = IsControlPressed(0, 21) -- Shift
                local currentSpeed = sprint and (freecamSpeed * 3) or freecamSpeed
                
                -- Mouse look
                local mouseX = GetDisabledControlNormal(0, 1) * 5.0
                local mouseY = GetDisabledControlNormal(0, 2) * 5.0
                
                freecamRot = vector3(
                    math.max(-89.0, math.min(89.0, freecamRot.x - mouseY)),
                    freecamRot.y,
                    freecamRot.z - mouseX
                )
                
                -- Calculate movement
                local radZ = math.rad(freecamRot.z)
                local radX = math.rad(freecamRot.x)
                
                local moveX, moveY, moveZ = 0, 0, 0
                
                if forward then
                    moveX = moveX + (-math.sin(radZ) * math.cos(radX) * currentSpeed)
                    moveY = moveY + (math.cos(radZ) * math.cos(radX) * currentSpeed)
                    moveZ = moveZ + (math.sin(radX) * currentSpeed)
                end
                if backward then
                    moveX = moveX - (-math.sin(radZ) * math.cos(radX) * currentSpeed)
                    moveY = moveY - (math.cos(radZ) * math.cos(radX) * currentSpeed)
                    moveZ = moveZ - (math.sin(radX) * currentSpeed)
                end
                if left then
                    moveX = moveX + (math.cos(radZ) * currentSpeed)
                    moveY = moveY + (math.sin(radZ) * currentSpeed)
                end
                if right then
                    moveX = moveX - (math.cos(radZ) * currentSpeed)
                    moveY = moveY - (math.sin(radZ) * currentSpeed)
                end
                if up then moveZ = moveZ + currentSpeed end
                if down then moveZ = moveZ - currentSpeed end
                
                freecamCoords = vector3(
                    freecamCoords.x + moveX,
                    freecamCoords.y + moveY,
                    freecamCoords.z + moveZ
                )
                
                SetCamCoord(freecamCam, freecamCoords.x, freecamCoords.y, freecamCoords.z)
                SetCamRot(freecamCam, freecamRot.x, freecamRot.y, freecamRot.z, 2)
            end
            
            -- Always update UI position
            SendNUIMessage({
                action = "updateFreecamPos",
                coords = {x = freecamCoords.x, y = freecamCoords.y, z = freecamCoords.z},
                rot = {x = freecamRot.x, y = freecamRot.y, z = freecamRot.z},
                fov = freecamFov
            })
        end
    end)
    
    -- Draw entities thread
    CreateThread(function()
        while creatorActive do
            Wait(0)
            
            -- Draw all scene entities with labels
            for i, data in ipairs(currentCutscene.tracks.actors) do
                if DoesEntityExist(data.entity) then
                    local coords = GetEntityCoords(data.entity)
                    DrawMarker(28, coords.x, coords.y, coords.z + 1.2, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 0, 150, 255, 100, false, false, 2, false, nil, nil, false)
                    Draw3DText(coords.x, coords.y, coords.z + 1.5, data.name or "Actor " .. i, 0.3)
                    
                    if selectedEntity == data.entity then
                        DrawEntityBox(data.entity, 0, 255, 0)
                    end
                end
            end
            
            for i, data in ipairs(currentCutscene.tracks.props) do
                if DoesEntityExist(data.entity) then
                    local coords = GetEntityCoords(data.entity)
                    DrawMarker(28, coords.x, coords.y, coords.z + 0.5, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, 255, 200, 0, 100, false, false, 2, false, nil, nil, false)
                    Draw3DText(coords.x, coords.y, coords.z + 0.8, data.name or "Prop " .. i, 0.25)
                    
                    if selectedEntity == data.entity then
                        DrawEntityBox(data.entity, 255, 200, 0)
                    end
                end
            end
            
            for i, data in ipairs(currentCutscene.tracks.vehicles) do
                if DoesEntityExist(data.entity) then
                    local coords = GetEntityCoords(data.entity)
                    DrawMarker(28, coords.x, coords.y, coords.z + 1.5, 0, 0, 0, 0, 0, 0, 0.4, 0.4, 0.4, 255, 0, 255, 100, false, false, 2, false, nil, nil, false)
                    Draw3DText(coords.x, coords.y, coords.z + 2.0, data.name or "Vehicle " .. i, 0.3)
                    
                    if selectedEntity == data.entity then
                        DrawEntityBox(data.entity, 255, 0, 255)
                    end
                end
            end
            
            -- Draw camera keyframes
            for i, kf in ipairs(currentCutscene.tracks.camera) do
                DrawMarker(28, kf.position.x, kf.position.y, kf.position.z, 0, 0, 0, 0, 0, 0, 0.25, 0.25, 0.25, 255, 50, 50, 150, false, false, 2, false, nil, nil, false)
                Draw3DText(kf.position.x, kf.position.y, kf.position.z + 0.3, "Cam " .. i, 0.2)
            end
        end
    end)
end

function DisableFreecam()
    if not freecamActive then return end
    
    freecamActive = false
    
    if freecamCam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(freecamCam, false)
        freecamCam = nil
    end
    
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    SetEntityVisible(playerPed, true, false)
end

-- Entity Selection
function SelectEntityUnderCursor()
    local hit, coords, entity = RaycastFromCursor()
    
    if hit and DoesEntityExist(entity) then
        -- Check if it's one of our entities
        for i, data in ipairs(currentCutscene.tracks.actors) do
            if data.entity == entity then
                selectedEntity = entity
                selectedType = 'actor'
                selectedIndex = i
                LL.Log("Selected: " .. (data.name or "Actor " .. i), "info")
                ShowHelpNotification("~g~Selected: ~w~" .. (data.name or "Actor " .. i) .. "\n~y~Right Click~w~ for options")
                return
            end
        end
        
        for i, data in ipairs(currentCutscene.tracks.props) do
            if data.entity == entity then
                selectedEntity = entity
                selectedType = 'prop'
                selectedIndex = i
                LL.Log("Selected: " .. (data.name or "Prop " .. i), "info")
                ShowHelpNotification("~g~Selected: ~w~" .. (data.name or "Prop " .. i))
                return
            end
        end
        
        for i, data in ipairs(currentCutscene.tracks.vehicles) do
            if data.entity == entity then
                selectedEntity = entity
                selectedType = 'vehicle'
                selectedIndex = i
                LL.Log("Selected: " .. (data.name or "Vehicle " .. i), "info")
                ShowHelpNotification("~g~Selected: ~w~" .. (data.name or "Vehicle " .. i))
                return
            end
        end
    end
end

function CleanupSelection()
    selectedEntity = nil
    selectedType = nil
    selectedIndex = nil
end

-- Context Menus
function ShowMainContextMenu()
    local options = {
        {label = "Add Actor", action = function() OpenSpawnMenu('actor') end},
        {label = "Add Prop", action = function() OpenSpawnMenu('prop') end},
        {label = "Add Vehicle", action = function() OpenSpawnMenu('vehicle') end},
        {label = "Add Audio Track", action = function() OpenAudioMenu() end},
        {label = "Cancel", action = function() end}
    }
    
    OpenContextMenu(options)
end

function ShowContextMenu()
    if not selectedEntity or not selectedType then return end
    
    local options = {}
    
    if selectedType == 'actor' then
        local data = currentCutscene.tracks.actors[selectedIndex]
        table.insert(options, {label = "Edit Position (Vec4)", action = function() OpenVec4Editor(selectedType, selectedIndex) end})
        table.insert(options, {label = "Edit Outfit", action = function() OpenOutfitEditor(selectedIndex) end})
        table.insert(options, {label = "Set Animation", action = function() OpenAnimationMenu(selectedIndex) end})
        table.insert(options, {label = "Add Waypoint", action = function() AddActorWaypoint(selectedIndex) end})
        table.insert(options, {label = "Add Keyframe Here", action = function() AddActorKeyframeAtCurrent(selectedIndex) end})
        table.insert(options, {label = "Delete Actor", action = function() DeleteSelectedEntity() end})
    elseif selectedType == 'prop' then
        table.insert(options, {label = "Edit Position (Vec4)", action = function() OpenVec4Editor(selectedType, selectedIndex) end})
        table.insert(options, {label = "Add Keyframe Here", action = function() AddPropKeyframeAtCurrent(selectedIndex) end})
        table.insert(options, {label = "Delete Prop", action = function() DeleteSelectedEntity() end})
    elseif selectedType == 'vehicle' then
        table.insert(options, {label = "Edit Position (Vec4)", action = function() OpenVec4Editor(selectedType, selectedIndex) end})
        table.insert(options, {label = "Edit Mods", action = function() OpenVehicleModMenu(selectedIndex) end})
        table.insert(options, {label = "Set Colors", action = function() OpenVehicleColorMenu(selectedIndex) end})
        table.insert(options, {label = "Delete Vehicle", action = function() DeleteSelectedEntity() end})
    end
    
    table.insert(options, {label = "Cancel", action = function() end})
    
    OpenContextMenu(options)
end

function OpenContextMenu(options)
    -- Send to NUI for rendering
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showContextMenu",
        options = options
    })
end

-- Add Camera Keyframe
function AddCameraKeyframe()
    local keyframe = {
        time = playbackTime,
        position = {x = freecamCoords.x, y = freecamCoords.y, z = freecamCoords.z},
        rotation = {x = freecamRot.x, y = freecamRot.y, z = freecamRot.z},
        fov = freecamFov,
        dofStrength = 0.0,
        dofRange = {near = 0.0, far = 100.0},
        shake = {type = "none", amount = 0.0},
        easing = "linear"
    }
    
    table.insert(currentCutscene.tracks.camera, keyframe)
    
    SendNUIMessage({
        action = "keyframeAdded",
        track = "camera",
        keyframe = keyframe
    })
    
    ShowHelpNotification("~g~Camera Keyframe Added~w~\nPosition: " .. string.format("%.1f, %.1f, %.1f", freecamCoords.x, freecamCoords.y, freecamCoords.z))
    LL.Log("Camera keyframe added at " .. playbackTime .. "ms", "success")
end

-- Spawn Menus
function OpenSpawnMenu(type)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showSpawnMenu",
        spawnType = type
    })
end

function OpenAudioMenu()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showAudioMenu"
    })
end

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
    -- Execute the stored action
    if data.actionIndex and contextMenuActions[data.actionIndex] then
        contextMenuActions[data.actionIndex]()
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('saveCutscene', function(data, cb)
    SaveCutscene(data.name)
    cb({success = true})
end)

RegisterNUICallback('loadCutscene', function(data, cb)
    LoadCutscene(data.name)
    cb({success = true})
end)

RegisterNUICallback('deleteCutscene', function(data, cb)
    DeleteCutscene(data.name)
    cb({success = true})
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

-- Save/Load
function SaveCutscene(name)
    if not name or name == "" then
        return false
    end
    
    currentCutscene.name = name
    
    -- Create save data
    local saveData = LL.DeepCopy(currentCutscene)
    
    -- Remove entity references and add positions
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
    SaveResourceFile(GetCurrentResourceName(), "cutscenes/saved_cutscenes.json", json, -1)
    
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
    
    LL.Log("Cutscene not found: " .. name, "error")
    return false
end

function DeleteCutscene(name)
    for i, saved in ipairs(savedCutscenes) do
        if saved.name == name then
            table.remove(savedCutscenes, i)
            
            local json = json.encode(savedCutscenes)
            SaveResourceFile(GetCurrentResourceName(), "cutscenes/saved_cutscenes.json", json, -1)
            
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

-- Vec4 Editor
function OpenVec4Editor(type, index)
    local entity, data
    
    if type == 'actor' then
        data = currentCutscene.tracks.actors[index]
        entity = data.entity
    elseif type == 'prop' then
        data = currentCutscene.tracks.props[index]
        entity = data.entity
    elseif type == 'vehicle' then
        data = currentCutscene.tracks.vehicles[index]
        entity = data.entity
    end
    
    if not DoesEntityExist(entity) then return end
    
    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showVec4Editor",
        data = {
            type = type,
            index = index,
            x = coords.x,
            y = coords.y,
            z = coords.z,
            w = heading
        }
    })
end

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

-- Outfit Editor
function OpenOutfitEditor(index)
    local actor = currentCutscene.tracks.actors[index]
    if not DoesEntityExist(actor.entity) then return end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showOutfitEditor",
        index = index,
        outfit = actor.outfit
    })
end

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

-- Animation Menu
function OpenAnimationMenu(index)
    local actor = currentCutscene.tracks.actors[index]
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showAnimationMenu",
        index = index,
        animation = actor.animation
    })
end

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

-- Vehicle Mods
function OpenVehicleModMenu(index)
    local veh = currentCutscene.tracks.vehicles[index]
    if not DoesEntityExist(veh.entity) then return end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showVehicleModMenu",
        index = index,
        mods = veh.mods or {}
    })
end

RegisterNUICallback('updateVehicleMods', function(data, cb)
    local index = data.index
    local veh = currentCutscene.tracks.vehicles[index]
    
    if DoesEntityExist(veh.entity) then
        for modType, modValue in pairs(data.mods) do
            SetVehicleMod(veh.entity, tonumber(modType), tonumber(modValue), false)
        end
        
        veh.mods = data.mods
        ShowHelpNotification("~g~Vehicle Mods Updated")
    end
    
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Vehicle Colors
function OpenVehicleColorMenu(index)
    local veh = currentCutscene.tracks.vehicles[index]
    if not DoesEntityExist(veh.entity) then return end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showVehicleColorMenu",
        index = index,
        colors = veh.colors or {primary = 0, secondary = 0}
    })
end

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

-- Actor Waypoints
function AddActorWaypoint(index)
    local actor = currentCutscene.tracks.actors[index]
    
    local waypoint = {
        position = vector3(freecamCoords.x, freecamCoords.y, freecamCoords.z),
        time = playbackTime
    }
    
    if not actor.waypoints then
        actor.waypoints = {}
    end
    
    table.insert(actor.waypoints, waypoint)
    ShowHelpNotification("~g~Waypoint Added~w~\nActor will walk here during playback")
    LL.Log("Waypoint added for actor " .. (actor.name or index), "info")
end

-- Keyframes
function AddActorKeyframeAtCurrent(index)
    local actor = currentCutscene.tracks.actors[index]
    if not DoesEntityExist(actor.entity) then return end
    
    local coords = GetEntityCoords(actor.entity)
    local rot = GetEntityRotation(actor.entity, 2)
    
    local keyframe = {
        time = playbackTime,
        position = {x = coords.x, y = coords.y, z = coords.z},
        rotation = {x = rot.x, y = rot.y, z = rot.z},
        animation = actor.animation
    }
    
    table.insert(actor.keyframes, keyframe)
    ShowHelpNotification("~g~Actor Keyframe Added")
    LL.Log("Actor keyframe added at " .. playbackTime .. "ms", "success")
end

function AddPropKeyframeAtCurrent(index)
    local prop = currentCutscene.tracks.props[index]
    if not DoesEntityExist(prop.entity) then return end
    
    local coords = GetEntityCoords(prop.entity)
    local rot = GetEntityRotation(prop.entity, 2)
    
    local keyframe = {
        time = playbackTime,
        position = {x = coords.x, y = coords.y, z = coords.z},
        rotation = {x = rot.x, y = rot.y, z = rot.z}
    }
    
    table.insert(prop.keyframes, keyframe)
    ShowHelpNotification("~g~Prop Keyframe Added")
    LL.Log("Prop keyframe added at " .. playbackTime .. "ms", "success")
end

-- Helper Functions
function RaycastFromCursor()
    local cursorX, cursorY = GetNuiCursorPosition()
    local screenWidth, screenHeight = GetActiveScreenResolution()
    
    local screenX = cursorX / screenWidth
    local screenY = cursorY / screenHeight
    
    local camCoord = GetCamCoord(freecamCam)
    local camRot = GetCamRot(freecamCam, 2)
    local camFwd = RotationToDirection(camRot)
    
    local camRight = vector3(
        math.cos(math.rad(camRot.z + 90)),
        math.sin(math.rad(camRot.z + 90)),
        0
    )
    local camUp = vector3(0, 0, 1)
    
    local fov = GetCamFov(freecamCam)
    local aspectRatio = screenWidth / screenHeight
    local fovRad = math.rad(fov)
    
    local viewHeight = math.tan(fovRad / 2)
    local viewWidth = viewHeight * aspectRatio
    
    local offsetX = (screenX - 0.5) * 2 * viewWidth
    local offsetY = (screenY - 0.5) * 2 * viewHeight
    
    local direction = camFwd + (camRight * offsetX) - (camUp * offsetY)
    direction = direction / #direction * 1000
    
    local destination = camCoord + direction
    
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
    local rot = GetEntityRotation(entity, 2)
    
    -- Draw bounding box
    DrawBox(coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, 
            math.abs(min.x) + max.x, math.abs(min.y) + max.y, math.abs(min.z) + max.z,
            r, g, b, 150)
end

function ShowHelpNotification(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if creatorActive then
        ExitCreator()
    end
    
    CleanupSceneEntities()
end)

-- Store context menu actions globally for NUI callback
contextMenuActions = {}
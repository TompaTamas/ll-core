-- Story Mode Quality Cutscene Creator - FIXED VERSION

-- GLOBAL változók (hogy a callbacks.lua is lássa őket)
creatorActive = false
freecamActive = false
freecamCam = nil
freecamCoords = vector3(0, 0, 0)
freecamRot = vector3(0, 0, 0)
freecamFov = 50.0
freecamSpeed = 0.5

uiVisible = false
mouseControlEnabled = false
selectedEntity = nil
selectedType = nil
selectedIndex = nil

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

savedCutscenes = {}
sceneEntities = {}
isPlaying = false
playbackTime = 0
contextMenuActions = {}

-- Load saved cutscenes from file
CreateThread(function()
    Wait(2000)
    local resourceName = GetCurrentResourceName()
    
    -- Ellenőrzés hogy létezik-e a fájl
    local stored = LoadResourceFile(resourceName, "cutscenes/saved_cutscenes.json")
    
    if stored and stored ~= "" and stored ~= "null" then
        local success, decoded = pcall(json.decode, stored)
        if success and decoded then
            savedCutscenes = decoded
            LL.Log("Loaded " .. #savedCutscenes .. " saved cutscenes", "info")
        else
            LL.Log("Failed to decode saved cutscenes, starting fresh", "warning")
            savedCutscenes = {}
        end
    else
        LL.Log("No saved cutscenes found, starting fresh", "info")
        savedCutscenes = {}
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
    if creatorActive and freecamActive and not mouseControlEnabled and not uiVisible then
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

-- Main Functions
function EnterCreator()
    creatorActive = true
    EnableFreecam()
    
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
    
    LL.Log("Cutscene Creator activated - F4: Toggle UI, M: Mouse Mode, E: Add Keyframe", "success")
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
                
                ShowCursorThisFrame()
                
                if IsDisabledControlJustPressed(0, 24) then
                    SelectEntityUnderCursor()
                end
                
                if IsDisabledControlJustPressed(0, 25) then
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
            
            if not uiVisible and not mouseControlEnabled then
                -- Movement
                local forward = IsControlPressed(0, 32) -- W
                local backward = IsControlPressed(0, 33) -- S
                local left = IsControlPressed(0, 34) -- A
                local right = IsControlPressed(0, 35) -- D
                local up = IsControlPressed(0, 44) -- Q
                local down = IsControlPressed(0, 46) -- E
                
                local sprint = IsControlPressed(0, 21) -- Shift
                local currentSpeed = sprint and (freecamSpeed * 3) or freecamSpeed
                
                local mouseX = GetDisabledControlNormal(0, 1) * 5.0
                local mouseY = GetDisabledControlNormal(0, 2) * 5.0
                
                freecamRot = vector3(
                    math.max(-89.0, math.min(89.0, freecamRot.x - mouseY)),
                    freecamRot.y,
                    freecamRot.z - mouseX
                )
                
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
    local hit, coords, entity = RaycastFromScreen()
    
    if hit and DoesEntityExist(entity) then
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
    contextMenuActions = {
        function() OpenSpawnMenu('actor') end,
        function() OpenSpawnMenu('prop') end,
        function() OpenSpawnMenu('vehicle') end,
        function() end
    }
    
    local options = {
        {label = "Add Actor"},
        {label = "Add Prop"},
        {label = "Add Vehicle"},
        {label = "Cancel"}
    }
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showContextMenu",
        options = options
    })
end

function ShowContextMenu()
    if not selectedEntity or not selectedType then return end
    
    contextMenuActions = {}
    local options = {}
    
    if selectedType == 'actor' then
        table.insert(contextMenuActions, function() OpenVec4Editor(selectedType, selectedIndex) end)
        table.insert(options, {label = "Edit Position"})
        
        table.insert(contextMenuActions, function() OpenOutfitEditor(selectedIndex) end)
        table.insert(options, {label = "Edit Outfit"})
        
        table.insert(contextMenuActions, function() OpenAnimationMenu(selectedIndex) end)
        table.insert(options, {label = "Set Animation"})
        
        table.insert(contextMenuActions, function() DeleteSelectedEntity() end)
        table.insert(options, {label = "Delete Actor"})
        
    elseif selectedType == 'prop' then
        table.insert(contextMenuActions, function() OpenVec4Editor(selectedType, selectedIndex) end)
        table.insert(options, {label = "Edit Position"})
        
        table.insert(contextMenuActions, function() DeleteSelectedEntity() end)
        table.insert(options, {label = "Delete Prop"})
        
    elseif selectedType == 'vehicle' then
        table.insert(contextMenuActions, function() OpenVec4Editor(selectedType, selectedIndex) end)
        table.insert(options, {label = "Edit Position"})
        
        table.insert(contextMenuActions, function() OpenVehicleModMenu(selectedIndex) end)
        table.insert(options, {label = "Edit Mods"})
        
        table.insert(contextMenuActions, function() OpenVehicleColorMenu(selectedIndex) end)
        table.insert(options, {label = "Set Colors"})
        
        table.insert(contextMenuActions, function() DeleteSelectedEntity() end)
        table.insert(options, {label = "Delete Vehicle"})
    end
    
    table.insert(contextMenuActions, function() end)
    table.insert(options, {label = "Cancel"})
    
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

-- Spawn Menu Functions
function OpenSpawnMenu(type)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showSpawnMenu",
        spawnType = type
    })
end

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

function OpenAnimationMenu(index)
    local actor = currentCutscene.tracks.actors[index]
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showAnimationMenu",
        index = index,
        animation = actor.animation
    })
end

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

-- Helper Functions
function RaycastFromScreen()
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

function DeleteSelectedEntity()
    -- Ez a callbacks.lua-ban van implementálva
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if creatorActive then
        ExitCreator()
    end
    
    for _, entity in ipairs(sceneEntities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
end)
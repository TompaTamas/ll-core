-- Client-side helper functions

-- Screen to world coordinate conversion
function ScreenToWorld(screenCoord)
    local camRot = GetGameplayCamRot(2)
    local camPos = GetGameplayCamCoord()
    
    local direction = RotationToDirection(camRot)
    local vect3 = vector3(
        camPos.x + direction.x * 10.0,
        camPos.y + direction.y * 10.0,
        camPos.z + direction.z * 10.0
    )
    
    local _, hit, coords = GetShapeTestResult(
        StartShapeTestRay(camPos.x, camPos.y, camPos.z, vect3.x, vect3.y, vect3.z, -1, PlayerPedId(), 0)
    )
    
    return hit, coords
end

function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    
    return vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
end

-- Get closest player
function GetClosestPlayer(radius)
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, player in ipairs(players) do
        local target = GetPlayerPed(player)
        
        if target ~= playerPed then
            local targetCoords = GetEntityCoords(target)
            local distance = #(playerCoords - targetCoords)
            
            if closestDistance == -1 or distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end
    
    if closestDistance ~= -1 and closestDistance <= radius then
        return closestPlayer, closestDistance
    else
        return nil, nil
    end
end

-- Get players in radius
function GetPlayersInRadius(coords, radius)
    local players = {}
    local playerPed = PlayerPedId()
    
    for _, player in ipairs(GetActivePlayers()) do
        local target = GetPlayerPed(player)
        
        if target ~= playerPed then
            local targetCoords = GetEntityCoords(target)
            local distance = #(coords - targetCoords)
            
            if distance <= radius then
                table.insert(players, {
                    player = player,
                    ped = target,
                    coords = targetCoords,
                    distance = distance
                })
            end
        end
    end
    
    return players
end

-- Request model with timeout
function RequestModelWithTimeout(model, timeout)
    timeout = timeout or 5000
    local startTime = GetGameTimer()
    
    if type(model) == "string" then
        model = GetHashKey(model)
    end
    
    RequestModel(model)
    
    while not HasModelLoaded(model) do
        Wait(100)
        
        if GetGameTimer() - startTime > timeout then
            LL.Log("Model request timeout: " .. tostring(model), "error")
            return false
        end
    end
    
    return true
end

-- Request anim dict with timeout
function RequestAnimDictWithTimeout(dict, timeout)
    timeout = timeout or 5000
    local startTime = GetGameTimer()
    
    RequestAnimDict(dict)
    
    while not HasAnimDictLoaded(dict) do
        Wait(100)
        
        if GetGameTimer() - startTime > timeout then
            LL.Log("Anim dict request timeout: " .. tostring(dict), "error")
            return false
        end
    end
    
    return true
end

-- Request texture dict with timeout
function RequestTextureDictWithTimeout(dict, timeout)
    timeout = timeout or 5000
    local startTime = GetGameTimer()
    
    RequestStreamedTextureDict(dict, false)
    
    while not HasStreamedTextureDictLoaded(dict) do
        Wait(100)
        
        if GetGameTimer() - startTime > timeout then
            LL.Log("Texture dict request timeout: " .. tostring(dict), "error")
            return false
        end
    end
    
    return true
end

-- Draw marker with custom parameters
function DrawMarkerEx(markerData)
    DrawMarker(
        markerData.type or 1,
        markerData.coords.x, markerData.coords.y, markerData.coords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        markerData.scale and markerData.scale.x or 1.0,
        markerData.scale and markerData.scale.y or 1.0,
        markerData.scale and markerData.scale.z or 1.0,
        markerData.color and markerData.color.r or 255,
        markerData.color and markerData.color.g or 255,
        markerData.color and markerData.color.b or 255,
        markerData.color and markerData.color.a or 100,
        markerData.bobUpAndDown or false,
        markerData.faceCamera ~= false,
        2,
        markerData.rotate or false,
        nil, nil, false
    )
end

-- Draw 3D text
function DrawText3D(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoord()
    local distance = #(camCoords - vector3(x, y, z))
    
    if onScreen then
        scale = scale or 0.35
        local fov = (1 / GetGameplayCamFov()) * 100
        local adjustedScale = (scale / distance) * 2 * fov
        
        SetTextScale(0.0 * adjustedScale, adjustedScale)
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

-- Check if ped is swimming
function IsPedSwimming(ped)
    return IsPedSwimming(ped) or IsPedSwimmingUnderWater(ped)
end

-- Check if ped is in vehicle
function IsPedInAnyVehicleSafe(ped)
    return IsPedInAnyVehicle(ped, false)
end

-- Get vehicle in direction
function GetVehicleInDirection(coordFrom, coordTo)
    local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, PlayerPedId(), 0)
    local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
    return vehicle
end

-- Get vehicle player is looking at
function GetVehicleInFrontOfPlayer()
    local playerPed = PlayerPedId()
    local coordA = GetEntityCoords(playerPed, true)
    local coordB = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
    
    return GetVehicleInDirection(coordA, coordB)
end

-- Get ground Z coordinate
function GetGroundZ(x, y)
    local _, z = GetGroundZFor_3dCoord(x, y, 1000.0, 0)
    return z
end

-- Teleport with fade
function TeleportWithFade(coords, heading)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, false)
    
    if heading then
        SetEntityHeading(playerPed, heading)
    end
    
    Wait(500)
    DoScreenFadeIn(500)
end

-- Play animation
function PlayAnimation(ped, dict, anim, duration, flag)
    RequestAnimDictWithTimeout(dict)
    
    duration = duration or -1
    flag = flag or 1
    
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, duration, flag, 0, false, false, false)
end

-- Stop animation
function StopAnimation(ped, dict, anim)
    StopAnimTask(ped, dict, anim, 1.0)
end

-- Check if animation is playing
function IsPlayingAnimation(ped, dict, anim)
    return IsEntityPlayingAnim(ped, dict, anim, 3)
end

-- Get heading between coords
function GetHeadingBetweenCoords(coord1, coord2)
    local dx = coord2.x - coord1.x
    local dy = coord2.y - coord1.y
    local heading = math.deg(math.atan2(dy, dx))
    return (heading + 360) % 360
end

-- Raycast from screen center
function RaycastFromScreen()
    local camCoord = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
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

-- Show notification
function ShowNotification(message, type)
    TriggerEvent('ll-notify:show', message, type or 'info')
end

-- Show help text
function ShowHelpText(message)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- Create blip
function CreateBlipEx(coords, sprite, color, scale, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite or 1)
    SetBlipColour(blip, color or 1)
    SetBlipScale(blip, scale or 1.0)
    SetBlipAsShortRange(blip, true)
    
    if label then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(label)
        EndTextCommandSetBlipName(blip)
    end
    
    return blip
end

-- Exports
exports('ScreenToWorld', ScreenToWorld)
exports('RotationToDirection', RotationToDirection)
exports('GetClosestPlayer', GetClosestPlayer)
exports('GetPlayersInRadius', GetPlayersInRadius)
exports('RequestModelWithTimeout', RequestModelWithTimeout)
exports('RequestAnimDictWithTimeout', RequestAnimDictWithTimeout)
exports('RequestTextureDictWithTimeout', RequestTextureDictWithTimeout)
exports('DrawMarkerEx', DrawMarkerEx)
exports('DrawText3D', DrawText3D)
exports('IsPedSwimming', IsPedSwimming)
exports('IsPedInAnyVehicleSafe', IsPedInAnyVehicleSafe)
exports('GetVehicleInDirection', GetVehicleInDirection)
exports('GetVehicleInFrontOfPlayer', GetVehicleInFrontOfPlayer)
exports('GetGroundZ', GetGroundZ)
exports('TeleportWithFade', TeleportWithFade)
exports('PlayAnimation', PlayAnimation)
exports('StopAnimation', StopAnimation)
exports('IsPlayingAnimation', IsPlayingAnimation)
exports('GetHeadingBetweenCoords', GetHeadingBetweenCoords)
exports('RaycastFromScreen', RaycastFromScreen)
exports('ShowNotification', ShowNotification)
exports('ShowHelpText', ShowHelpText)
exports('CreateBlipEx', CreateBlipEx)
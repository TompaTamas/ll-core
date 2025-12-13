-- Advanced Vehicle Controls for Cutscenes

-- Vehicle door management
local vehicleDoorStates = {}

function OpenVehicleDoor(vehicle, doorIndex, loose, instant)
    if not DoesEntityExist(vehicle) then return end
    
    doorIndex = doorIndex or 0 -- 0=Front Left, 1=Front Right, 2=Rear Left, 3=Rear Right, 4=Hood, 5=Trunk
    loose = loose or false
    instant = instant or false
    
    SetVehicleDoorOpen(vehicle, doorIndex, loose, instant)
    
    if not vehicleDoorStates[vehicle] then
        vehicleDoorStates[vehicle] = {}
    end
    vehicleDoorStates[vehicle][doorIndex] = true
    
    LL.Log("Vehicle door " .. doorIndex .. " opened", "info")
end

function CloseVehicleDoor(vehicle, doorIndex, instant)
    if not DoesEntityExist(vehicle) then return end
    
    doorIndex = doorIndex or 0
    instant = instant or false
    
    SetVehicleDoorShut(vehicle, doorIndex, instant)
    
    if vehicleDoorStates[vehicle] then
        vehicleDoorStates[vehicle][doorIndex] = false
    end
    
    LL.Log("Vehicle door " .. doorIndex .. " closed", "info")
end

function ToggleVehicleDoor(vehicle, doorIndex, loose, instant)
    if not DoesEntityExist(vehicle) then return end
    
    doorIndex = doorIndex or 0
    
    local isOpen = false
    if vehicleDoorStates[vehicle] and vehicleDoorStates[vehicle][doorIndex] then
        isOpen = true
    end
    
    if isOpen then
        CloseVehicleDoor(vehicle, doorIndex, instant)
    else
        OpenVehicleDoor(vehicle, doorIndex, loose, instant)
    end
end

function OpenAllVehicleDoors(vehicle, loose, instant)
    if not DoesEntityExist(vehicle) then return end
    
    for i = 0, 5 do
        OpenVehicleDoor(vehicle, i, loose, instant)
    end
end

function CloseAllVehicleDoors(vehicle, instant)
    if not DoesEntityExist(vehicle) then return end
    
    for i = 0, 5 do
        CloseVehicleDoor(vehicle, i, instant)
    end
end

function BreakOffVehicleDoor(vehicle, doorIndex)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleDoorBroken(vehicle, doorIndex, true)
    LL.Log("Vehicle door " .. doorIndex .. " broken off", "info")
end

-- Vehicle lights
function SetVehicleLightsState(vehicle, state)
    if not DoesEntityExist(vehicle) then return end
    
    -- 0 = default, 1 = off, 2 = on
    SetVehicleLights(vehicle, state)
    LL.Log("Vehicle lights set to: " .. state, "info")
end

function FlashVehicleLights(vehicle, duration)
    if not DoesEntityExist(vehicle) then return end
    
    duration = duration or 2000
    
    CreateThread(function()
        local startTime = GetGameTimer()
        local state = true
        
        while GetGameTimer() - startTime < duration do
            SetVehicleLights(vehicle, state and 2 or 1)
            state = not state
            Wait(500)
        end
        
        SetVehicleLights(vehicle, 0)
    end)
end

-- Vehicle engine
function SetVehicleEngineState(vehicle, state, instant, disableAutoStart)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleEngineOn(vehicle, state, instant or false, disableAutoStart or true)
    LL.Log("Vehicle engine: " .. (state and "ON" or "OFF"), "info")
end

-- Vehicle siren
function SetVehicleSirenState(vehicle, state)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleSiren(vehicle, state)
    
    if state then
        SetVehicleHasMutedSirens(vehicle, false)
    end
    
    LL.Log("Vehicle siren: " .. (state and "ON" or "OFF"), "info")
end

-- Vehicle horn
function SoundVehicleHorn(vehicle, duration)
    if not DoesEntityExist(vehicle) then return end
    
    duration = duration or 1000
    
    StartVehicleHorn(vehicle, duration, GetHashKey("HELDDOWN"), false)
    LL.Log("Vehicle horn sounded for " .. duration .. "ms", "info")
end

-- Vehicle indicator (turn signals)
function SetVehicleIndicators(vehicle, leftOn, rightOn)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleIndicatorLights(vehicle, 0, leftOn) -- Left
    SetVehicleIndicatorLights(vehicle, 1, rightOn) -- Right
end

-- Vehicle window
function SmashVehicleWindow(vehicle, windowIndex)
    if not DoesEntityExist(vehicle) then return end
    
    -- 0=Front Left, 1=Front Right, 2=Rear Left, 3=Rear Right
    SmashVehicleWindow(vehicle, windowIndex)
    LL.Log("Vehicle window " .. windowIndex .. " smashed", "info")
end

function RollDownVehicleWindow(vehicle, windowIndex)
    if not DoesEntityExist(vehicle) then return end
    
    RollDownWindow(vehicle, windowIndex)
end

function RollUpVehicleWindow(vehicle, windowIndex)
    if not DoesEntityExist(vehicle) then return end
    
    RollUpWindow(vehicle, windowIndex)
end

-- Vehicle plate
function SetVehiclePlateText(vehicle, text)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleNumberPlateText(vehicle, text)
    LL.Log("Vehicle plate set to: " .. text, "info")
end

-- Vehicle dirt level
function SetVehicleDirtLevel(vehicle, level)
    if not DoesEntityExist(vehicle) then return end
    
    level = math.max(0.0, math.min(15.0, level))
    SetVehicleDirtLevel(vehicle, level)
end

function WashVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    WashDecalsFromVehicle(vehicle, 1.0)
    SetVehicleDirtLevel(vehicle, 0.0)
    LL.Log("Vehicle washed", "info")
end

-- Vehicle damage
function SetVehicleBodyHealth(vehicle, health)
    if not DoesEntityExist(vehicle) then return end
    
    health = math.max(0.0, math.min(1000.0, health))
    SetVehicleBodyHealth(vehicle, health)
end

function SetVehicleEngineHealth(vehicle, health)
    if not DoesEntityExist(vehicle) then return end
    
    health = math.max(-4000.0, math.min(1000.0, health))
    SetVehicleEngineHealth(vehicle, health)
end

function SetVehicleDeformationFixed(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleDeformationFixed(vehicle)
    SetVehicleFixed(vehicle)
    LL.Log("Vehicle deformation fixed", "info")
end

function ExplodeVehicle(vehicle, isAudible, isInvisible)
    if not DoesEntityExist(vehicle) then return end
    
    ExplodeVehicle(vehicle, isAudible ~= false, isInvisible or false)
    LL.Log("Vehicle exploded", "warning")
end

-- Vehicle smoke/fire
function SetVehicleOnFire(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    local coords = GetEntityCoords(vehicle)
    StartScriptFire(coords.x, coords.y, coords.z, 25, true)
end

-- Vehicle extras (accessories)
function ToggleVehicleExtra(vehicle, extraId, enable)
    if not DoesEntityExist(vehicle) then return end
    
    if DoesExtraExist(vehicle, extraId) then
        SetVehicleExtra(vehicle, extraId, not enable)
        LL.Log("Vehicle extra " .. extraId .. " " .. (enable and "enabled" or "disabled"), "info")
    end
end

-- Vehicle livery
function SetVehicleLivery(vehicle, liveryIndex)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleLivery(vehicle, liveryIndex)
    LL.Log("Vehicle livery set to: " .. liveryIndex, "info")
end

-- Vehicle wheel type
function SetVehicleWheelType(vehicle, wheelType)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleWheelType(vehicle, wheelType)
end

-- Vehicle neon lights
function SetVehicleNeonEnabled(vehicle, left, right, front, rear)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleNeonLightEnabled(vehicle, 0, left)   -- Left
    SetVehicleNeonLightEnabled(vehicle, 1, right)  -- Right
    SetVehicleNeonLightEnabled(vehicle, 2, front)  -- Front
    SetVehicleNeonLightEnabled(vehicle, 3, rear)   -- Rear
end

function SetVehicleNeonColor(vehicle, r, g, b)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleNeonLightsColour(vehicle, r, g, b)
end

-- Vehicle xenon (headlight color)
function SetVehicleXenonColor(vehicle, colorIndex)
    if not DoesEntityExist(vehicle) then return end
    
    ToggleVehicleMod(vehicle, 22, true) -- Enable xenon
    SetVehicleXenonLightsColour(vehicle, colorIndex)
end

-- Vehicle convertible roof
function SetVehicleConvertibleRoof(vehicle, state)
    if not DoesEntityExist(vehicle) then return end
    
    -- 0 = raise, 1 = lower, 2 = raised, 3 = lowered
    if state then
        LowerConvertibleRoof(vehicle, true)
    else
        RaiseConvertibleRoof(vehicle, true)
    end
end

-- Animated vehicle movement
function DriveVehicleToCoord(vehicle, coords, speed, style)
    if not DoesEntityExist(vehicle) then return end
    
    speed = speed or 10.0
    style = style or 786603 -- Normal driving
    
    TaskVehicleDriveToCoordLongrange(vehicle, coords.x, coords.y, coords.z, speed, style, 5.0)
end

-- Vehicle teleport
function TeleportVehicle(vehicle, coords, heading)
    if not DoesEntityExist(vehicle) then return end
    
    SetEntityCoords(vehicle, coords.x, coords.y, coords.z, false, false, false, false)
    if heading then
        SetEntityHeading(vehicle, heading)
    end
    SetVehicleOnGroundProperly(vehicle)
end

-- Cleanup
function CleanupVehicleDoorStates()
    vehicleDoorStates = {}
end

-- Exports
exports('OpenVehicleDoor', OpenVehicleDoor)
exports('CloseVehicleDoor', CloseVehicleDoor)
exports('ToggleVehicleDoor', ToggleVehicleDoor)
exports('OpenAllVehicleDoors', OpenAllVehicleDoors)
exports('CloseAllVehicleDoors', CloseAllVehicleDoors)
exports('BreakOffVehicleDoor', BreakOffVehicleDoor)

exports('SetVehicleLightsState', SetVehicleLightsState)
exports('FlashVehicleLights', FlashVehicleLights)
exports('SetVehicleEngineState', SetVehicleEngineState)
exports('SetVehicleSirenState', SetVehicleSirenState)
exports('SoundVehicleHorn', SoundVehicleHorn)
exports('SetVehicleIndicators', SetVehicleIndicators)

exports('SmashVehicleWindow', SmashVehicleWindow)
exports('RollDownVehicleWindow', RollDownVehicleWindow)
exports('RollUpVehicleWindow', RollUpVehicleWindow)

exports('SetVehiclePlateText', SetVehiclePlateText)
exports('SetVehicleDirtLevel', SetVehicleDirtLevel)
exports('WashVehicle', WashVehicle)

exports('SetVehicleBodyHealth', SetVehicleBodyHealth)
exports('SetVehicleEngineHealth', SetVehicleEngineHealth)
exports('SetVehicleDeformationFixed', SetVehicleDeformationFixed)
exports('ExplodeVehicle', ExplodeVehicle)
exports('SetVehicleOnFire', SetVehicleOnFire)

exports('ToggleVehicleExtra', ToggleVehicleExtra)
exports('SetVehicleLivery', SetVehicleLivery)
exports('SetVehicleWheelType', SetVehicleWheelType)

exports('SetVehicleNeonEnabled', SetVehicleNeonEnabled)
exports('SetVehicleNeonColor', SetVehicleNeonColor)
exports('SetVehicleXenonColor', SetVehicleXenonColor)
exports('SetVehicleConvertibleRoof', SetVehicleConvertibleRoof)

exports('DriveVehicleToCoord', DriveVehicleToCoord)
exports('TeleportVehicle', TeleportVehicle)
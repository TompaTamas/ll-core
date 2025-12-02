-- Camera movement and interpolation for cutscenes
local currentCam = nil
local isCamActive = false
local defaultCam = nil

function CreateCutsceneCamera(coords, rotation, fov)
    if currentCam then
        DestroyCam(currentCam, false)
    end
    
    coords = coords or GetGameplayCamCoord()
    rotation = rotation or GetGameplayCamRot(2)
    fov = fov or LL.Cutscenes.Camera.DefaultFOV
    
    currentCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(currentCam, coords.x, coords.y, coords.z)
    SetCamRot(currentCam, rotation.x, rotation.y, rotation.z, 2)
    SetCamFov(currentCam, fov)
    
    LL.Log("Cutscene camera created", "info")
    
    return currentCam
end

function ActivateCutsceneCamera(instant)
    if not currentCam then 
        LL.Log("No camera to activate", "error")
        return 
    end
    
    local transitionTime = instant and 0 or 1000
    RenderScriptCams(true, not instant, transitionTime, true, true)
    isCamActive = true
    
    LL.Log("Camera activated", "info")
end

function DeactivateCutsceneCamera(instant)
    if not currentCam then return end
    
    local transitionTime = instant and 0 or 1000
    RenderScriptCams(false, not instant, transitionTime, true, true)
    
    if currentCam then
        DestroyCam(currentCam, false)
        currentCam = nil
    end
    
    isCamActive = false
    
    LL.Log("Camera deactivated", "info")
end

function SetCameraPosition(coords, instant)
    if not currentCam then return end
    
    if instant then
        SetCamCoord(currentCam, coords.x, coords.y, coords.z)
    else
        -- Smooth interpolation
        local duration = LL.Cutscenes.Camera.TransitionSpeed * 1000
        SetCamActiveWithInterp(currentCam, currentCam, duration, 1, 1)
        SetCamCoord(currentCam, coords.x, coords.y, coords.z)
    end
end

function SetCameraRotation(rotation, instant)
    if not currentCam then return end
    
    if instant then
        SetCamRot(currentCam, rotation.x, rotation.y, rotation.z, 2)
    else
        local duration = LL.Cutscenes.Camera.TransitionSpeed * 1000
        SetCamActiveWithInterp(currentCam, currentCam, duration, 1, 1)
        SetCamRot(currentCam, rotation.x, rotation.y, rotation.z, 2)
    end
end

function SetCameraFOV(fov, instant)
    if not currentCam then return end
    
    fov = LL.Clamp(fov, LL.Cutscenes.Camera.MinFOV, LL.Cutscenes.Camera.MaxFOV)
    
    if instant then
        SetCamFov(currentCam, fov)
    else
        -- Smooth FOV transition
        CreateThread(function()
            local currentFOV = GetCamFov(currentCam)
            local step = (fov - currentFOV) / 30
            
            for i = 1, 30 do
                currentFOV = currentFOV + step
                SetCamFov(currentCam, currentFOV)
                Wait(16) -- ~60fps
            end
            
            SetCamFov(currentCam, fov)
        end)
    end
end

function InterpolateCameraToPosition(coords, rotation, fov, duration)
    if not currentCam then return end
    
    duration = duration or (LL.Cutscenes.Camera.TransitionSpeed * 1000)
    
    -- Smooth interpolation
    if LL.Cutscenes.Camera.SmoothTransition then
        local startCoords = GetCamCoord(currentCam)
        local startRot = GetCamRot(currentCam, 2)
        local startFOV = GetCamFov(currentCam)
        
        local startTime = GetGameTimer()
        local endTime = startTime + duration
        
        CreateThread(function()
            while GetGameTimer() < endTime do
                local progress = (GetGameTimer() - startTime) / duration
                progress = EaseInOutQuad(progress)
                
                -- Interpolate position
                local newX = Lerp(startCoords.x, coords.x, progress)
                local newY = Lerp(startCoords.y, coords.y, progress)
                local newZ = Lerp(startCoords.z, coords.z, progress)
                SetCamCoord(currentCam, newX, newY, newZ)
                
                -- Interpolate rotation
                local newRX = Lerp(startRot.x, rotation.x, progress)
                local newRY = Lerp(startRot.y, rotation.y, progress)
                local newRZ = Lerp(startRot.z, rotation.z, progress)
                SetCamRot(currentCam, newRX, newRY, newRZ, 2)
                
                -- Interpolate FOV
                if fov then
                    local newFOV = Lerp(startFOV, fov, progress)
                    SetCamFov(currentCam, newFOV)
                end
                
                Wait(0)
            end
            
            -- Set final values
            SetCamCoord(currentCam, coords.x, coords.y, coords.z)
            SetCamRot(currentCam, rotation.x, rotation.y, rotation.z, 2)
            if fov then SetCamFov(currentCam, fov) end
        end)
    else
        -- Instant transition
        SetCamCoord(currentCam, coords.x, coords.y, coords.z)
        SetCamRot(currentCam, rotation.x, rotation.y, rotation.z, 2)
        if fov then SetCamFov(currentCam, fov) end
    end
end

function ShakeCamera(intensity, duration)
    if not currentCam then return end
    
    intensity = intensity or LL.Cutscenes.Camera.ShakeIntensity.Medium
    
    ShakeScriptGlobal("HAND_SHAKE", intensity)
    
    if duration then
        SetTimeout(duration, function()
            StopScriptGlobalShaking(false)
        end)
    end
end

function StopCameraShake()
    StopScriptGlobalShaking(false)
end

function PointCameraAtEntity(entity, offsetX, offsetY, offsetZ)
    if not currentCam then return end
    if not DoesEntityExist(entity) then return end
    
    offsetX = offsetX or 0.0
    offsetY = offsetY or 0.0
    offsetZ = offsetZ or 0.0
    
    PointCamAtEntity(currentCam, entity, offsetX, offsetY, offsetZ, true)
end

function PointCameraAtCoord(coords)
    if not currentCam then return end
    
    PointCamAtCoord(currentCam, coords.x, coords.y, coords.z)
end

function AttachCameraToEntity(entity, offsetX, offsetY, offsetZ)
    if not currentCam then return end
    if not DoesEntityExist(entity) then return end
    
    AttachCamToEntity(currentCam, entity, offsetX, offsetY, offsetZ, true)
end

function DetachCamera()
    if not currentCam then return end
    
    DetachCam(currentCam)
end

-- Easing functions
function Lerp(start, finish, progress)
    return start + (finish - start) * progress
end

function EaseInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

function EaseInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        return (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
    end
end

-- Camera effects
function ApplyCameraEffect(effect)
    if not currentCam then return end
    
    local effects = {
        blur = "DrugsMichaelAliensFight",
        drunk = "Drunk",
        death = "DeathFailOut",
        stoned = "DrugsTrevorClownsFight"
    }
    
    local effectName = effects[effect] or effect
    StartScreenEffect(effectName, 0, true)
end

function RemoveCameraEffect(effect)
    local effects = {
        blur = "DrugsMichaelAliensFight",
        drunk = "Drunk",
        death = "DeathFailOut",
        stoned = "DrugsTrevorClownsFight"
    }
    
    local effectName = effects[effect] or effect
    StopScreenEffect(effectName)
end

function RemoveAllCameraEffects()
    StopAllScreenEffects()
end

-- Exports
exports('CreateCutsceneCamera', CreateCutsceneCamera)
exports('ActivateCutsceneCamera', ActivateCutsceneCamera)
exports('DeactivateCutsceneCamera', DeactivateCutsceneCamera)
exports('SetCameraPosition', SetCameraPosition)
exports('SetCameraRotation', SetCameraRotation)
exports('SetCameraFOV', SetCameraFOV)
exports('InterpolateCameraToPosition', InterpolateCameraToPosition)
exports('ShakeCamera', ShakeCamera)
exports('StopCameraShake', StopCameraShake)
exports('PointCameraAtEntity', PointCameraAtEntity)
exports('PointCameraAtCoord', PointCameraAtCoord)
exports('AttachCameraToEntity', AttachCameraToEntity)
exports('DetachCamera', DetachCamera)
exports('ApplyCameraEffect', ApplyCameraEffect)
exports('RemoveCameraEffect', RemoveCameraEffect)
exports('RemoveAllCameraEffects', RemoveAllCameraEffects)
exports('GetCurrentCamera', function() return currentCam end)
exports('IsCameraActive', function() return isCamActive end)
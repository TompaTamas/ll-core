-- Cutscene Utility Functions

-- Interpolation Functions
function LerpVector3(a, b, t)
    return vector3(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t
    )
end

function LerpFloat(a, b, t)
    return a + (b - a) * t
end

-- Easing Functions
function EaseLinear(t)
    return t
end

function EaseInQuad(t)
    return t * t
end

function EaseOutQuad(t)
    return t * (2 - t)
end

function EaseInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

function EaseInCubic(t)
    return t * t * t
end

function EaseOutCubic(t)
    local f = t - 1
    return f * f * f + 1
end

function EaseInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        local f = (2 * t) - 2
        return 0.5 * f * f * f + 1
    end
end

function EaseInQuart(t)
    return t * t * t * t
end

function EaseOutQuart(t)
    local f = t - 1
    return -(f * f * f * f - 1)
end

function EaseInOutQuart(t)
    if t < 0.5 then
        return 8 * t * t * t * t
    else
        local f = t - 1
        return -8 * f * f * f * f + 1
    end
end

function EaseInExpo(t)
    if t == 0 then
        return 0
    end
    return math.pow(2, 10 * (t - 1))
end

function EaseOutExpo(t)
    if t == 1 then
        return 1
    end
    return -math.pow(2, -10 * t) + 1
end

function EaseInOutExpo(t)
    if t == 0 or t == 1 then
        return t
    end
    
    if t < 0.5 then
        return 0.5 * math.pow(2, (20 * t) - 10)
    else
        return -0.5 * math.pow(2, (-20 * t) + 10) + 1
    end
end

-- Apply easing based on name
function ApplyEasing(t, easingType)
    easingType = easingType or "linear"
    
    if easingType == "linear" then
        return EaseLinear(t)
    elseif easingType == "easeIn" or easingType == "easeInQuad" then
        return EaseInQuad(t)
    elseif easingType == "easeOut" or easingType == "easeOutQuad" then
        return EaseOutQuad(t)
    elseif easingType == "easeInOut" or easingType == "easeInOutQuad" then
        return EaseInOutQuad(t)
    elseif easingType == "easeInCubic" then
        return EaseInCubic(t)
    elseif easingType == "easeOutCubic" then
        return EaseOutCubic(t)
    elseif easingType == "easeInOutCubic" then
        return EaseInOutCubic(t)
    elseif easingType == "easeInQuart" then
        return EaseInQuart(t)
    elseif easingType == "easeOutQuart" then
        return EaseOutQuart(t)
    elseif easingType == "easeInOutQuart" then
        return EaseInOutQuart(t)
    elseif easingType == "easeInExpo" then
        return EaseInExpo(t)
    elseif easingType == "easeOutExpo" then
        return EaseOutExpo(t)
    elseif easingType == "easeInOutExpo" then
        return EaseInOutExpo(t)
    else
        return EaseLinear(t)
    end
end

-- Camera Shake Presets
function GetCameraShakePreset(shakeType)
    local presets = {
        none = {name = "HAND_SHAKE", intensity = 0.0},
        light = {name = "HAND_SHAKE", intensity = 0.1},
        medium = {name = "HAND_SHAKE", intensity = 0.3},
        heavy = {name = "VIBRATE_SHAKE", intensity = 0.5},
        explosion = {name = "LARGE_EXPLOSION_SHAKE", intensity = 1.0},
        earthquake = {name = "ROAD_VIBRATION_SHAKE", intensity = 0.8},
        drunk = {name = "DRUNK_SHAKE", intensity = 0.5}
    }
    
    return presets[shakeType] or presets.none
end

-- Cutscene Validation
function ValidateCutsceneData(cutsceneData)
    if not cutsceneData then
        LL.Log("Cutscene data is nil", "error")
        return false
    end
    
    if not cutsceneData.name or cutsceneData.name == "" then
        LL.Log("Cutscene missing name", "error")
        return false
    end
    
    if not cutsceneData.duration or cutsceneData.duration <= 0 then
        LL.Log("Cutscene missing valid duration", "error")
        return false
    end
    
    if not cutsceneData.tracks then
        LL.Log("Cutscene missing tracks", "error")
        return false
    end
    
    return true
end

-- Format Time
function FormatTime(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    local ms = milliseconds % 1000
    
    return string.format("%02d:%02d.%03d", minutes, seconds, ms)
end

-- Get Keyframe at Time
function GetKeyframeAtTime(timeline, time)
    if not timeline or #timeline == 0 then
        return nil
    end
    
    local closestKeyframe = nil
    local closestDistance = math.huge
    
    for _, keyframe in ipairs(timeline) do
        local distance = math.abs(keyframe.time - time)
        if distance < closestDistance then
            closestDistance = distance
            closestKeyframe = keyframe
        end
    end
    
    return closestKeyframe
end

-- Get Next Keyframe
function GetNextKeyframe(timeline, currentTime)
    if not timeline or #timeline == 0 then
        return nil
    end
    
    for _, keyframe in ipairs(timeline) do
        if keyframe.time > currentTime then
            return keyframe
        end
    end
    
    return nil
end

-- Get Previous Keyframe
function GetPreviousKeyframe(timeline, currentTime)
    if not timeline or #timeline == 0 then
        return nil
    end
    
    local prevKeyframe = nil
    
    for _, keyframe in ipairs(timeline) do
        if keyframe.time < currentTime then
            prevKeyframe = keyframe
        else
            break
        end
    end
    
    return prevKeyframe
end

-- Interpolate Between Keyframes
function InterpolateKeyframes(prevKeyframe, nextKeyframe, progress, easingType)
    if not prevKeyframe or not nextKeyframe then
        return prevKeyframe or nextKeyframe
    end
    
    local t = ApplyEasing(progress, easingType)
    
    local result = {}
    
    -- Interpolate position
    if prevKeyframe.position and nextKeyframe.position then
        result.position = LerpVector3(
            vector3(prevKeyframe.position.x, prevKeyframe.position.y, prevKeyframe.position.z),
            vector3(nextKeyframe.position.x, nextKeyframe.position.y, nextKeyframe.position.z),
            t
        )
    end
    
    -- Interpolate rotation
    if prevKeyframe.rotation and nextKeyframe.rotation then
        result.rotation = vector3(
            LerpFloat(prevKeyframe.rotation.x, nextKeyframe.rotation.x, t),
            LerpFloat(prevKeyframe.rotation.y, nextKeyframe.rotation.y, t),
            LerpFloat(prevKeyframe.rotation.z, nextKeyframe.rotation.z, t)
        )
    end
    
    -- Interpolate FOV
    if prevKeyframe.fov and nextKeyframe.fov then
        result.fov = LerpFloat(prevKeyframe.fov, nextKeyframe.fov, t)
    end
    
    return result
end

-- Distance Calculation
function GetDistance3D(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    local dz = pos2.z - pos1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Sort Timeline by Time
function SortTimelineByTime(timeline)
    if not timeline or #timeline == 0 then
        return timeline
    end
    
    table.sort(timeline, function(a, b)
        return (a.time or 0) < (b.time or 0)
    end)
    
    return timeline
end

-- Clone Object
function CloneObject(obj)
    if type(obj) ~= 'table' then
        return obj
    end
    
    local clone = {}
    for k, v in pairs(obj) do
        clone[k] = CloneObject(v)
    end
    
    return clone
end

-- Get Model Dimensions
function GetEntityBoundingBox(entity)
    if not DoesEntityExist(entity) then
        return nil, nil
    end
    
    local min, max = GetModelDimensions(GetEntityModel(entity))
    return min, max
end

-- Check if Entity is in Camera View
function IsEntityInCameraView(entity, camera)
    if not DoesEntityExist(entity) or not DoesCamExist(camera) then
        return false
    end
    
    local entityCoords = GetEntityCoords(entity)
    local camCoords = GetCamCoord(camera)
    local camRot = GetCamRot(camera, 2)
    
    -- Simple frustum check
    local distance = #(entityCoords - camCoords)
    if distance > 100.0 then
        return false
    end
    
    return true
end

-- Sanitize String for Filename
function SanitizeFilename(str)
    if not str then return "unnamed" end
    
    -- Remove invalid characters
    str = str:gsub("[^%w%s-_]", "")
    -- Replace spaces with underscores
    str = str:gsub("%s+", "_")
    -- Limit length
    if #str > 50 then
        str = str:sub(1, 50)
    end
    
    return str
end

-- Generate Unique ID
function GenerateUniqueID()
    return string.format("%d_%d", os.time(), math.random(1000, 9999))
end

-- Round Number
function RoundNumber(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Clamp Value
function ClampValue(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Check if Table is Empty
function IsTableEmpty(tbl)
    if not tbl then return true end
    return next(tbl) == nil
end

-- Merge Tables
function MergeTables(t1, t2)
    local result = CloneObject(t1)
    
    for k, v in pairs(t2) do
        result[k] = v
    end
    
    return result
end

-- Get Table Length
function GetTableLength(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Exports
exports('LerpVector3', LerpVector3)
exports('LerpFloat', LerpFloat)
exports('ApplyEasing', ApplyEasing)
exports('GetCameraShakePreset', GetCameraShakePreset)
exports('ValidateCutsceneData', ValidateCutsceneData)
exports('FormatTime', FormatTime)
exports('GetKeyframeAtTime', GetKeyframeAtTime)
exports('GetNextKeyframe', GetNextKeyframe)
exports('GetPreviousKeyframe', GetPreviousKeyframe)
exports('InterpolateKeyframes', InterpolateKeyframes)
exports('GetDistance3D', GetDistance3D)
exports('SortTimelineByTime', SortTimelineByTime)
exports('CloneObject', CloneObject)
exports('SanitizeFilename', SanitizeFilename)
exports('GenerateUniqueID', GenerateUniqueID)
exports('RoundNumber', RoundNumber)
exports('ClampValue', ClampValue)
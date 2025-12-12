-- Timeline synchronization and management
local currentTimeline = nil
local timelineStartTime = 0
local isTimelinePlaying = false

function StartTimeline(timeline, duration)
    currentTimeline = timeline
    timelineStartTime = GetGameTimer()
    isTimelinePlaying = true
    
    LL.Log("Timeline started with " .. #timeline .. " keyframes", "info")
end

function StopTimeline()
    currentTimeline = nil
    timelineStartTime = 0
    isTimelinePlaying = false
    
    LL.Log("Timeline stopped", "info")
end

function GetTimelineProgress()
    if not isTimelinePlaying then return 0 end
    
    return GetGameTimer() - timelineStartTime
end

function GetCurrentKeyframe()
    if not currentTimeline or not isTimelinePlaying then return nil end
    
    local elapsed = GetTimelineProgress()
    local currentKeyframe = nil
    
    for i, keyframe in ipairs(currentTimeline) do
        if keyframe.time <= elapsed then
            currentKeyframe = keyframe
        else
            break
        end
    end
    
    return currentKeyframe
end

function GetNextKeyframe()
    if not currentTimeline or not isTimelinePlaying then return nil end
    
    local elapsed = GetTimelineProgress()
    
    for i, keyframe in ipairs(currentTimeline) do
        if keyframe.time > elapsed then
            return keyframe
        end
    end
    
    return nil
end

function IsTimelineComplete(duration)
    if not isTimelinePlaying then return true end
    
    return GetTimelineProgress() >= duration
end

exports('StartTimeline', StartTimeline)
exports('StopTimeline', StopTimeline)
exports('GetTimelineProgress', GetTimelineProgress)
exports('GetCurrentKeyframe', GetCurrentKeyframe)
exports('GetNextKeyframe', GetNextKeyframe)
exports('IsTimelineComplete', IsTimelineComplete)
exports('IsTimelinePlaying', function() return isTimelinePlaying end)
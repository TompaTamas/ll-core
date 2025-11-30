local isPlaying = false
local currentCutscene = nil
local cutsceneCam = nil
local cutsceneNPCs = {}
local startTime = 0

RegisterNetEvent(LL.Events.Cutscene.Play, function(cutsceneData)
    if isPlaying then
        LL.Log("Cutscene already playing", "warning")
        return
    end
    
    currentCutscene = cutsceneData
    isPlaying = true
    
    LL.Log("Playing cutscene: " .. (cutsceneData.name or "Unknown"), "info")
    
    StartCutscene()
end)

function StartCutscene()
    local playerPed = PlayerPedId()
    
    if LL.Cutscenes.Playback.FadeInDuration > 0 then
        DoScreenFadeOut(LL.Cutscenes.Playback.FadeInDuration)
        Wait(LL.Cutscenes.Playback.FadeInDuration)
    end
    
    FreezeEntityPosition(playerPed, true)
    SetEntityVisible(playerPed, false, false)
    SetEntityCollision(playerPed, false, false)
    
    if currentCutscene.npcs then
        SpawnCutsceneNPCs(currentCutscene.npcs)
    end
    
    SetupCutsceneCamera()
    
    if LL.Cutscenes.Playback.Letterbox then
        ShowLetterbox(true)
    end
    
    if LL.Cutscenes.Playback.FadeInDuration > 0 then
        DoScreenFadeIn(LL.Cutscenes.Playback.FadeInDuration)
    end
    
    startTime = GetGameTimer()
    PlayCutsceneTimeline()
end

function SetupCutsceneCamera()
    local firstKeyframe = currentCutscene.timeline[1]
    if not firstKeyframe then return end
    
    cutsceneCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    
    local camData = firstKeyframe.camera
    SetCamCoord(cutsceneCam, camData.x, camData.y, camData.z)
    SetCamRot(cutsceneCam, camData.rx, camData.ry, camData.rz, 2)
    SetCamFov(cutsceneCam, camData.fov or LL.Cutscenes.Camera.DefaultFOV)
    
    RenderScriptCams(true, false, 0, true, true)
end

function PlayCutsceneTimeline()
    CreateThread(function()
        local timeline = currentCutscene.timeline
        local duration = currentCutscene.duration or 30000
        
        for i = 1, #timeline do
            if not isPlaying then break end
            
            local keyframe = timeline[i]
            local nextKeyframe = timeline[i + 1]
            
            local keyframeTime = keyframe.time or ((i - 1) / #timeline) * duration
            local nextTime = nextKeyframe and (nextKeyframe.time or (i / #timeline) * duration) or duration
            local transitionDuration = nextTime - keyframeTime
            
            Wait(keyframeTime - (GetGameTimer() - startTime))
            
            if keyframe.camera and nextKeyframe and nextKeyframe.camera then
                local nextCam = nextKeyframe.camera
                
                if LL.Cutscenes.Camera.SmoothTransition then
                    SetCamActiveWithInterp(cutsceneCam, cutsceneCam, transitionDuration, 1, 1)
                end
                
                SetCamCoord(cutsceneCam, nextCam.x, nextCam.y, nextCam.z)
                SetCamRot(cutsceneCam, nextCam.rx, nextCam.ry, nextCam.rz, 2)
                SetCamFov(cutsceneCam, nextCam.fov or LL.Cutscenes.Camera.DefaultFOV)
            end
            
            if keyframe.audio then
                PlayCutsceneAudio(keyframe.audio)
            end
            
            if keyframe.npcActions then
                HandleNPCActions(keyframe.npcActions)
            end
        end
        
        Wait(1000)
        StopCutscene()
    end)
end

function SpawnCutsceneNPCs(npcs)
    for i, npcData in ipairs(npcs) do
        local model = GetHashKey(npcData.model or LL.Cutscenes.NPCs.DefaultModel)
        
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(100) end
        
        local npc = CreatePed(4, model, npcData.coords.x, npcData.coords.y, npcData.coords.z, npcData.heading or 0.0, false, true)
        SetEntityAsMissionEntity(npc, true, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        
        if npcData.clothing then
            ApplyCutsceneNPCClothing(npc, npcData.clothing)
        end
        
        if npcData.animation then
            PlayCutsceneNPCAnimation(npc, npcData.animation)
        end
        
        cutsceneNPCs[i] = npc
    end
end

function ApplyCutsceneNPCClothing(ped, clothing)
    if not LL.Cutscenes.NPCs.EnableClothing then return end
    
    if clothing.components then
        for componentId, data in pairs(clothing.components) do
            SetPedComponentVariation(ped, componentId, data.drawable, data.texture, 0)
        end
    end
    
    if clothing.props then
        for propId, data in pairs(clothing.props) do
            SetPedPropIndex(ped, propId, data.drawable, data.texture, true)
        end
    end
end

function PlayCutsceneNPCAnimation(ped, animData)
    RequestAnimDict(animData.dict)
    while not HasAnimDictLoaded(animData.dict) do Wait(100) end
    
    TaskPlayAnim(ped, animData.dict, animData.name, 8.0, -8.0, -1, animData.flag or 1, 0, false, false, false)
end

function HandleNPCActions(actions)
    for npcIndex, action in pairs(actions) do
        local npc = cutsceneNPCs[npcIndex]
        if DoesEntityExist(npc) then
            if action.type == "move" then
                TaskGoToCoordAnyMeans(npc, action.coords.x, action.coords.y, action.coords.z, 1.0, 0, false, 786603, 0xbf800000)
            elseif action.type == "animation" then
                PlayCutsceneNPCAnimation(npc, action.animation)
            elseif action.type == "heading" then
                SetEntityHeading(npc, action.heading)
            end
        end
    end
end

function ShowLetterbox(show)
    if show then
        RequestStreamedTextureDict("timerbars", false)
        while not HasStreamedTextureDictLoaded("timerbars") do Wait(100) end
    end
    
    CreateThread(function()
        while isPlaying and show do
            Wait(0)
            DrawRect(0.5, LL.Cutscenes.Playback.LetterboxHeight / 2, 1.0, LL.Cutscenes.Playback.LetterboxHeight, 0, 0, 0, 255)
            DrawRect(0.5, 1.0 - (LL.Cutscenes.Playback.LetterboxHeight / 2), 1.0, LL.Cutscenes.Playback.LetterboxHeight, 0, 0, 0, 255)
        end
    end)
end

function StopCutscene()
    LL.Log("Cutscene ended", "info")
    
    if LL.Cutscenes.Playback.FadeOutDuration > 0 then
        DoScreenFadeOut(LL.Cutscenes.Playback.FadeOutDuration)
        Wait(LL.Cutscenes.Playback.FadeOutDuration)
    end
    
    if cutsceneCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cutsceneCam, false)
        cutsceneCam = nil
    end
    
    for _, npc in pairs(cutsceneNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    cutsceneNPCs = {}
    
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    SetEntityVisible(playerPed, true, false)
    SetEntityCollision(playerPed, true, true)
    
    if LL.Cutscenes.Playback.FadeOutDuration > 0 then
        DoScreenFadeIn(LL.Cutscenes.Playback.FadeOutDuration)
    end
    
    isPlaying = false
    currentCutscene = nil
    startTime = 0
    
    TriggerEvent('ll-cutscene:ended')
end

RegisterNetEvent(LL.Events.Cutscene.Stop, function()
    if isPlaying then
        StopCutscene()
    end
end)

exports('IsPlayingCutscene', function()
    return isPlaying
end)

exports('StopCutscene', function()
    TriggerEvent(LL.Events.Cutscene.Stop)
end)
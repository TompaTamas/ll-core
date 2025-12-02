local currentAudio = nil
local audioVolume = LL.Cutscenes.Audio.Volume

function PlayCutsceneAudio(audioData)
    if not LL.Cutscenes.Audio.EnableVoicelines then return end
    
    if currentAudio then
        StopCutsceneAudio()
    end
    
    local audioFile = audioData.file
    local volume = audioData.volume or audioVolume
    local is3D = audioData.is3D or false
    local coords = audioData.coords or nil
    
    if is3D and coords and LL.Cutscenes.Audio.Enable3DAudio then
        Play3DAudio(audioFile, coords, volume)
    else
        Play2DAudio(audioFile, volume)
    end
    
    currentAudio = audioFile
    
    if audioData.duration then
        SetTimeout(audioData.duration, function()
            StopCutsceneAudio()
        end)
    end
end

function Play2DAudio(file, volume)
    SendNUIMessage({
        action = "playAudio",
        file = LL.Cutscenes.AudioFolder .. file,
        volume = volume,
        is3D = false
    })
end

function Play3DAudio(file, coords, volume)
    CreateThread(function()
        local playerPed = PlayerPedId()
        
        while currentAudio do
            Wait(100)
            
            local playerCoords = GetEntityCoords(playerPed)
            local distance = LL.GetDistance(playerCoords, coords)
            
            if distance <= LL.Cutscenes.Audio.MaxDistance then
                local adjustedVolume = volume * (1 - (distance / LL.Cutscenes.Audio.MaxDistance))
                
                SendNUIMessage({
                    action = "updateVolume",
                    volume = adjustedVolume
                })
            else
                SendNUIMessage({
                    action = "updateVolume",
                    volume = 0
                })
            end
        end
    end)
    
    Play2DAudio(file, volume)
end

function StopCutsceneAudio()
    if not currentAudio then return end
    
    SendNUIMessage({
        action = "stopAudio"
    })
    
    currentAudio = nil
end

RegisterNetEvent('ll-cutscene:playAudio', function(audioData)
    PlayCutsceneAudio(audioData)
end)

RegisterNetEvent('ll-cutscene:stopAudio', function()
    StopCutsceneAudio()
end)

exports('PlayAudio', function(file, volume, is3D, coords)
    PlayCutsceneAudio({
        file = file,
        volume = volume,
        is3D = is3D,
        coords = coords
    })
end)

exports('StopAudio', function()
    StopCutsceneAudio()
end)

exports('SetAudioVolume', function(volume)
    audioVolume = LL.Clamp(volume, 0, 1)
    
    SendNUIMessage({
        action = "updateVolume",
        volume = audioVolume
    })
end)
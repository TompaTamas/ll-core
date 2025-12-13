local sanity = LL.Survival.Sanity.StartValue
local lastUpdate = GetGameTimer()
local hallucinationPeds = {}
local audioHandle = nil

RegisterNetEvent('ll-survival:start', function()
    if not LL.Survival.Sanity.Enabled then return end
    
    TriggerServerEvent(LL.Events.Survival.SyncStats, 'sanity', sanity)
    
    CreateThread(function()
        while true do
            Wait(LL.Survival.UpdateInterval)
            UpdateSanity()
        end
    end)
    
    CreateThread(function()
        while true do
            Wait(1000)
            ApplySanityEffects()
        end
    end)
end)

function UpdateSanity()
    local currentTime = GetGameTimer()
    local timePassed = (currentTime - lastUpdate) / 60000
    local decreaseRate = LL.Survival.Sanity.DecreaseRate
    
    local hour = GetClockHours()
    if hour >= 22 or hour <= 6 then
        decreaseRate = decreaseRate * LL.Survival.Sanity.NightDecreaseMultiplier
    end
    
    local nearbyPlayers = GetNearbyPlayers(LL.Survival.Sanity.CheckRadius)
    if #nearbyPlayers < LL.Survival.Sanity.MinPlayers then
        decreaseRate = decreaseRate * LL.Survival.Sanity.AloneDecreaseMultiplier
    end
    
    sanity = sanity - (decreaseRate * timePassed)
    sanity = LL.Clamp(sanity, 0, 100)
    
    lastUpdate = currentTime
    TriggerServerEvent(LL.Events.Survival.UpdateSanity, sanity)
end

function GetNearbyPlayers(radius)
    local players = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = LL.GetDistance(playerCoords, targetCoords)
            
            if distance <= radius then
                table.insert(players, player)
            end
        end
    end
    
    return players
end

function ApplySanityEffects()
    local playerPed = PlayerPedId()
    
    for level, effects in pairs(LL.Survival.Sanity.Effects) do
        if sanity <= level then
            
            if effects.screenEffect then
                StartScreenEffect(effects.screenEffect, 0, true)
            end
            
            if effects.shakeCam then
                ShakeGameplayCam("DRUNK_SHAKE", effects.shakeCam)
            end
            
            if effects.audio and not audioHandle then
                PlaySoundFrontend(-1, "Crash", effects.audio, true)
                audioHandle = true
            elseif not effects.audio and audioHandle then
                StopSound(-1)
                audioHandle = nil
            end
            
            if effects.hallucinations then
                SpawnHallucination()
            else
                ClearHallucinations()
            end
            
            break
        end
    end
    
    if sanity > 60 then
        StopAllScreenEffects()
        StopGameplayCamShaking(true)
        if audioHandle then
            StopSound(-1)
            audioHandle = nil
        end
        ClearHallucinations()
    end
end

function SpawnHallucination()
    if #hallucinationPeds >= 3 then return end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local randomOffset = vector3(
        math.random(-20, 20),
        math.random(-20, 20),
        0
    )
    local spawnCoords = playerCoords + randomOffset
    
    local pedModels = {`a_m_y_hipster_01`, `a_f_y_hipster_01`, `a_m_y_business_01`}
    local model = pedModels[math.random(#pedModels)]
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    
    local ped = CreatePed(4, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, false, true)
    SetEntityAlpha(ped, 150, false)
    TaskWanderStandard(ped, 10.0, 10)
    
    table.insert(hallucinationPeds, ped)
    
    SetTimeout(10000, function()
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
            for i, p in ipairs(hallucinationPeds) do
                if p == ped then
                    table.remove(hallucinationPeds, i)
                    break
                end
            end
        end
    end)
end

function ClearHallucinations()
    for _, ped in ipairs(hallucinationPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    hallucinationPeds = {}
end

RegisterNetEvent('ll-survival:resetOnDeath', function()
    sanity = LL.Survival.Sanity.StartValue
    lastUpdate = GetGameTimer()
    StopAllScreenEffects()
    StopGameplayCamShaking(true)
    if audioHandle then
        StopSound(-1)
        audioHandle = nil
    end
    ClearHallucinations()
end)

exports('GetSanity', function()
    return sanity
end)

exports('SetSanity', function(value)
    sanity = LL.Clamp(value, 0, 100)
    TriggerServerEvent(LL.Events.Survival.UpdateSanity, sanity)
end)

exports('AddSanity', function(amount)
    sanity = LL.Clamp(sanity + amount, 0, 100)
    TriggerServerEvent(LL.Events.Survival.UpdateSanity, sanity)
end)
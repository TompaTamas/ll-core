local thirst = LL.Survival.Thirst.StartValue
local lastUpdate = GetGameTimer()
local activeEffects = {}

RegisterNetEvent('ll-survival:start', function()
    if not LL.Survival.Thirst.Enabled then return end
    
    TriggerServerEvent(LL.Events.Survival.SyncStats, 'thirst', thirst)
    
    CreateThread(function()
        while true do
            Wait(LL.Survival.UpdateInterval)
            UpdateThirst()
        end
    end)
    
    CreateThread(function()
        while true do
            Wait(1000)
            ApplyThirstEffects()
        end
    end)
end)

function UpdateThirst()
    local currentTime = GetGameTimer()
    local timePassed = (currentTime - lastUpdate) / 60000
    
    thirst = thirst - (LL.Survival.Thirst.DecreaseRate * timePassed)
    thirst = LL.Clamp(thirst, 0, 100)
    
    lastUpdate = currentTime
    TriggerServerEvent(LL.Events.Survival.UpdateThirst, thirst)
    
    if thirst <= LL.Survival.Thirst.DeathLevel then
        TriggerServerEvent(LL.Events.Survival.CheckDeath, 'thirst')
    end
end

function ApplyThirstEffects()
    local playerPed = PlayerPedId()
    activeEffects = {}
    
    for level, effects in pairs(LL.Survival.Thirst.Effects) do
        if thirst <= level then
            activeEffects = effects
            
            if effects.health then
                local currentHealth = GetEntityHealth(playerPed)
                local newHealth = currentHealth + effects.health
                if newHealth > 0 then
                    SetEntityHealth(playerPed, newHealth)
                end
            end
            
            if effects.stamina then
                SetPlayerStamina(PlayerId(), effects.stamina * 100)
            end
            
            if effects.speed then
                SetPedMoveRateOverride(playerPed, effects.speed)
            end
            
            if effects.blur then
                SetTimecycleModifier("drug_drive_blend01")
                SetTimecycleModifierStrength(0.5)
            else
                ClearTimecycleModifier()
            end
            
            break
        end
    end
end

RegisterNetEvent(LL.Events.Survival.UpdateThirst, function(amount)
    thirst = LL.Clamp(thirst + amount, 0, 100)
    TriggerServerEvent(LL.Events.Survival.UpdateThirst, thirst)
end)

RegisterNetEvent('ll-survival:resetOnDeath', function()
    thirst = LL.Survival.Thirst.StartValue
    lastUpdate = GetGameTimer()
    activeEffects = {}
    ClearTimecycleModifier()
end)

exports('GetThirst', function()
    return thirst
end)

exports('SetThirst', function(value)
    thirst = LL.Clamp(value, 0, 100)
    TriggerServerEvent(LL.Events.Survival.UpdateThirst, thirst)
end)

exports('AddThirst', function(amount)
    TriggerEvent(LL.Events.Survival.UpdateThirst, amount)
end)
local hunger = LL.Survival.Hunger.StartValue
local lastUpdate = GetGameTimer()
local activeEffects = {}

-- Éhség rendszer start
RegisterNetEvent('ll-survival:start', function()
    if not LL.Survival.Hunger.Enabled then return end
    
    -- Szerver sync
    TriggerServerEvent(LL.Events.Survival.SyncStats, 'hunger', hunger)
    
    -- Update loop
    CreateThread(function()
        while true do
            Wait(LL.Survival.UpdateInterval)
            UpdateHunger()
        end
    end)
    
    -- Effect loop
    CreateThread(function()
        while true do
            Wait(1000)
            ApplyHungerEffects()
        end
    end)
end)

-- Éhség frissítés
function UpdateHunger()
    local currentTime = GetGameTimer()
    local timePassed = (currentTime - lastUpdate) / 60000 -- Perc
    
    -- Éhség csökkentés
    hunger = hunger - (LL.Survival.Hunger.DecreaseRate * timePassed)
    hunger = LL.Clamp(hunger, 0, 100)
    
    lastUpdate = currentTime
    
    -- Szerver sync
    TriggerServerEvent(LL.Events.Survival.UpdateHunger, hunger)
    
    -- Death check
    if hunger <= LL.Survival.Hunger.DeathLevel then
        TriggerServerEvent(LL.Events.Survival.CheckDeath, 'hunger')
    end
end

-- Effektek alkalmazása
function ApplyHungerEffects()
    local playerPed = PlayerPedId()
    activeEffects = {}
    
    -- Végig nézni az effekt szinteket
    for level, effects in pairs(LL.Survival.Hunger.Effects) do
        if hunger <= level then
            activeEffects = effects
            
            -- Health csökkentés
            if effects.health then
                local currentHealth = GetEntityHealth(playerPed)
                local newHealth = currentHealth + effects.health
                if newHealth > 0 then
                    SetEntityHealth(playerPed, newHealth)
                end
            end
            
            -- Stamina csökkentés
            if effects.stamina then
                SetPlayerStamina(PlayerId(), effects.stamina * 100)
            end
            
            -- Blur effect
            if effects.blur then
                SetTimecycleModifier("drug_drive_blend01")
                SetTimecycleModifierStrength(0.3)
            else
                ClearTimecycleModifier()
            end
            
            break -- Csak a legalacsonyabb effekt
        end
    end
end

-- Éhség növelés (evésnél)
RegisterNetEvent(LL.Events.Survival.UpdateHunger, function(amount)
    hunger = LL.Clamp(hunger + amount, 0, 100)
    TriggerServerEvent(LL.Events.Survival.UpdateHunger, hunger)
end)

-- Reset death után
RegisterNetEvent('ll-survival:resetOnDeath', function()
    hunger = LL.Survival.Hunger.StartValue
    lastUpdate = GetGameTimer()
    activeEffects = {}
    ClearTimecycleModifier()
end)

-- Export
exports('GetHunger', function()
    return hunger
end)

exports('SetHunger', function(value)
    hunger = LL.Clamp(value, 0, 100)
    TriggerServerEvent(LL.Events.Survival.UpdateHunger, hunger)
end)

exports('AddHunger', function(amount)
    TriggerEvent(LL.Events.Survival.UpdateHunger, amount)
end)
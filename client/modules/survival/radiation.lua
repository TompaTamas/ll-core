-- Radiation system with zones and effects
local radiation = LL.Survival.Radiation.StartValue
local lastUpdate = GetGameTimer()
local inRadZone = false
local currentZone = nil
local activeEffects = {}
local activeScreenEffect = nil

RegisterNetEvent('ll-survival:start', function()
    if not LL.Survival.Radiation.Enabled then return end
    
    LL.Log("Radiation system started", "info")
    
    TriggerServerEvent(LL.Events.Survival.SyncStats, 'radiation', radiation)
    
    -- Main update loop
    CreateThread(function()
        while true do
            Wait(LL.Survival.UpdateInterval)
            UpdateRadiation()
        end
    end)
    
    -- Zone check loop
    CreateThread(function()
        while true do
            Wait(5000) -- Check every 5 seconds
            CheckRadiationZones()
        end
    end)
    
    -- Effects loop
    CreateThread(function()
        while true do
            Wait(1000)
            ApplyRadiationEffects()
        end
    end)
    
    -- Draw zone warnings
    CreateThread(function()
        while true do
            Wait(0)
            
            if inRadZone and currentZone then
                -- Draw warning text
                SetTextFont(4)
                SetTextScale(0.5, 0.5)
                SetTextColour(255, 50, 50, 255)
                SetTextDropshadow(1, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 255)
                SetTextEntry("STRING")
                AddTextComponentString("⚠ RADIOAKTÍV ZÓNA ⚠\n" .. currentZone.label)
                DrawText(0.5, 0.85)
                
                -- Draw radiation bar
                DrawRadiationBar()
            else
                Wait(500)
            end
        end
    end)
end)

function CheckRadiationZones()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    inRadZone = false
    currentZone = nil
    local closestDistance = 99999
    
    -- Check all radiation zones
    for _, zone in ipairs(LL.Survival.Radiation.Zones) do
        local distance = #(playerCoords - zone.coords)
        
        if distance <= zone.radius then
            -- Player is in a radiation zone
            if distance < closestDistance then
                inRadZone = true
                currentZone = zone
                closestDistance = distance
            end
        end
    end
    
    -- Debug
    if LL.Core.Debug and inRadZone then
        LL.Log("In radiation zone: " .. currentZone.label .. " (Distance: " .. math.floor(closestDistance) .. "m)", "warning")
    end
end

function UpdateRadiation()
    local currentTime = GetGameTimer()
    local timePassed = (currentTime - lastUpdate) / 60000 -- Convert to minutes
    
    if inRadZone and currentZone then
        -- Increase radiation based on zone
        local increase = currentZone.increaseRate * timePassed
        radiation = math.min(radiation + increase, LL.Survival.Radiation.MaxValue)
        
        if LL.Core.Debug then
            LL.Log("Radiation increased by " .. string.format("%.2f", increase) .. " (Total: " .. string.format("%.2f", radiation) .. ")", "warning")
        end
    else
        -- Natural decrease when not in zone
        local decrease = LL.Survival.Radiation.NaturalDecreaseRate * timePassed
        radiation = math.max(radiation - decrease, 0)
    end
    
    lastUpdate = currentTime
    
    -- Sync with server
    TriggerServerEvent(LL.Events.Survival.UpdateRadiation, radiation)
    
    -- Check death
    if radiation >= LL.Survival.Radiation.DeathLevel then
        LL.Log("Player died from radiation poisoning", "error")
        TriggerServerEvent(LL.Events.Survival.CheckDeath, 'radiation')
    end
end

function ApplyRadiationEffects()
    local playerPed = PlayerPedId()
    
    -- Clear previous effects
    if activeScreenEffect and radiation < GetEffectThreshold(activeScreenEffect) then
        StopScreenEffect(activeScreenEffect)
        activeScreenEffect = nil
    end
    
    -- Apply new effects based on radiation level
    for level, effects in pairs(LL.Survival.Radiation.Effects) do
        if radiation >= level then
            activeEffects = effects
            
            -- Health damage
            if effects.health then
                local currentHealth = GetEntityHealth(playerPed)
                local damage = math.abs(effects.health)
                local newHealth = currentHealth - damage
                
                if newHealth > 100 then -- Minimum health
                    SetEntityHealth(playerPed, math.floor(newHealth))
                end
            end
            
            -- Screen effect
            if effects.screenEffect then
                if activeScreenEffect ~= effects.screenEffect then
                    if activeScreenEffect then
                        StopScreenEffect(activeScreenEffect)
                    end
                    StartScreenEffect(effects.screenEffect, 0, true)
                    activeScreenEffect = effects.screenEffect
                end
            end
            
            -- Blur effect
            if effects.blur then
                SetTimecycleModifier("drug_drive_blend02")
                SetTimecycleModifierStrength(0.7)
            else
                ClearTimecycleModifier()
            end
            
            -- Don't check lower levels
            break
        end
    end
    
    -- Clear effects if radiation is low
    if radiation < 25 then
        if activeScreenEffect then
            StopScreenEffect(activeScreenEffect)
            activeScreenEffect = nil
        end
        ClearTimecycleModifier()
    end
end

function GetEffectThreshold(effectName)
    for level, effects in pairs(LL.Survival.Radiation.Effects) do
        if effects.screenEffect == effectName then
            return level
        end
    end
    return 0
end

function DrawRadiationBar()
    local barWidth = 0.2
    local barHeight = 0.015
    local x = 0.5
    local y = 0.92
    
    -- Background
    DrawRect(x, y, barWidth, barHeight, 0, 0, 0, 150)
    
    -- Radiation bar (red to yellow gradient)
    local percentage = radiation / LL.Survival.Radiation.MaxValue
    local r = 255
    local g = math.floor(255 * (1 - percentage))
    local b = 0
    
    DrawRect(x - (barWidth / 2) + (barWidth * percentage / 2), y, barWidth * percentage, barHeight - 0.002, r, g, b, 200)
    
    -- Text
    SetTextFont(4)
    SetTextScale(0.3, 0.3)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    AddTextComponentString(string.format("Sugárzás: %.0f%%", percentage * 100))
    DrawText(x, y - 0.02)
end

-- Reset on death
RegisterNetEvent('ll-survival:resetOnDeath', function()
    radiation = LL.Survival.Radiation.StartValue
    lastUpdate = GetGameTimer()
    inRadZone = false
    currentZone = nil
    activeEffects = {}
    
    if activeScreenEffect then
        StopScreenEffect(activeScreenEffect)
        activeScreenEffect = nil
    end
    
    ClearTimecycleModifier()
    
    LL.Log("Radiation reset on death", "info")
end)

-- Anti-radiation medicine (can be called from inventory)
RegisterNetEvent('ll-survival:reduceRadiation', function(amount)
    radiation = math.max(radiation - amount, 0)
    TriggerServerEvent(LL.Events.Survival.UpdateRadiation, radiation)
    TriggerEvent('ll-notify:show', 'Sugárzás csökkent: -' .. amount, 'success')
    
    LL.Log("Radiation reduced by " .. amount, "info")
end)

-- Debug command
RegisterCommand('radinfo', function()
    if LL.Core.Debug then
        print("=== Radiation Debug ===")
        print("Current Radiation: " .. string.format("%.2f", radiation))
        print("In Rad Zone: " .. tostring(inRadZone))
        if currentZone then
            print("Current Zone: " .. currentZone.label)
            print("Zone Increase Rate: " .. currentZone.increaseRate)
        end
        print("Active Screen Effect: " .. tostring(activeScreenEffect))
    end
end, false)

-- Exports
exports('GetRadiation', function()
    return radiation
end)

exports('SetRadiation', function(value)
    radiation = LL.Clamp(value, 0, LL.Survival.Radiation.MaxValue)
    TriggerServerEvent(LL.Events.Survival.UpdateRadiation, radiation)
end)

exports('AddRadiation', function(amount)
    radiation = LL.Clamp(radiation + amount, 0, LL.Survival.Radiation.MaxValue)
    TriggerServerEvent(LL.Events.Survival.UpdateRadiation, radiation)
end)

exports('ReduceRadiation', function(amount)
    TriggerEvent('ll-survival:reduceRadiation', amount)
end)

exports('IsInRadZone', function()
    return inRadZone
end)

exports('GetCurrentZone', function()
    return currentZone
end)
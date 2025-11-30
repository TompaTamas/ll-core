local isDead = false
local deathTime = 0

-- Halál kezelés
RegisterNetEvent('ll-death:handle', function()
    if isDead then return end
    
    isDead = true
    deathTime = GetGameTimer()
    local playerPed = PlayerPedId()
    
    LL.Log("Player died", "warning")
    
    -- Screen fade
    DoScreenFadeOut(LL.Game.DeathFadeTime)
    Wait(LL.Game.DeathFadeTime)
    
    -- Ragdoll
    SetPedToRagdoll(playerPed, 1000, 1000, 0, 0, 0, 0)
    
    -- Kamera effekt
    SetEntityHealth(playerPed, 0)
    
    -- Respawn időzítő
    CreateThread(function()
        local respawnTime = LL.Game.RespawnTime
        
        while isDead do
            Wait(1000)
            local elapsed = GetGameTimer() - deathTime
            local remaining = math.ceil((respawnTime - elapsed) / 1000)
            
            if remaining <= 0 then
                RespawnPlayer()
                break
            end
            
            -- Notify: Respawn: X másodperc
            TriggerEvent('ll-notify:show', 'Respawn: ' .. remaining .. ' másodperc', 'error')
        end
    end)
    
    -- Controls disable
    CreateThread(function()
        while isDead do
            Wait(0)
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
        end
    end)
end)

-- Respawn function
function RespawnPlayer()
    local playerPed = PlayerPedId()
    
    -- Health visszaállítás
    SetEntityHealth(playerPed, 200)
    ClearPedBloodDamage(playerPed)
    
    -- Spawn event trigger
    TriggerEvent(LL.Events.Core.PlayerSpawn)
    TriggerServerEvent(LL.Events.Core.PlayerSpawn)
    
    -- Survival reset
    TriggerServerEvent('ll-survival:resetOnDeath')
    
    -- Screen fade in
    DoScreenFadeIn(LL.Spawn.FadeInTime)
    
    isDead = false
    deathTime = 0
    
    LL.Log("Player respawned", "success")
end

-- Export
exports('IsDead', function()
    return isDead
end)

exports('ForceRespawn', function()
    if isDead then
        RespawnPlayer()
    end
end)
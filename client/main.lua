-- Client oldali változók
local playerLoaded = false
local playerData = {}

-- Player loaded event
RegisterNetEvent(LL.Events.Core.PlayerLoaded, function(data)
    playerLoaded = true
    playerData = data
    LL.Log("Player loaded: " .. GetPlayerName(PlayerId()), "success")
    
    -- Spawn kezelés
    TriggerEvent(LL.Events.Core.PlayerSpawn)
    
    -- Survival rendszer indítás
    if LL.Survival.Hunger.Enabled or LL.Survival.Thirst.Enabled or 
       LL.Survival.Radiation.Enabled or LL.Survival.Sanity.Enabled then
        TriggerEvent("ll-survival:start")
    end
    
    -- Mission rendszer indítás
    if LL.Missions.Enabled then
        TriggerServerEvent(LL.Events.Mission.LoadMissions)
    end
end)

-- Player unload
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if playerLoaded then
        TriggerServerEvent(LL.Events.Core.PlayerUnload)
        playerLoaded = false
    end
end)

-- Player spawn handler
RegisterNetEvent(LL.Events.Core.PlayerSpawn, function()
    local playerPed = PlayerPedId()
    
    -- Screen fade
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Spawn koordináták beállítása
    local spawn = LL.Spawn.DefaultLocation
    SetEntityCoords(playerPed, spawn.x, spawn.y, spawn.z, false, false, false, false)
    SetEntityHeading(playerPed, spawn.w)
    
    -- Health/armor reset
    SetEntityHealth(playerPed, 200)
    SetPedArmour(playerPed, 0)
    
    -- Screen fade in
    Wait(500)
    DoScreenFadeIn(LL.Spawn.FadeInTime)
    
    LL.Log("Player spawned", "info")
end)

-- Player death handler
CreateThread(function()
    while true do
        Wait(1000)
        
        if playerLoaded then
            local playerPed = PlayerPedId()
            
            if IsEntityDead(playerPed) then
                TriggerServerEvent(LL.Events.Core.PlayerDeath)
                TriggerEvent("ll-death:handle")
            end
        end
    end
end)

-- Export függvények
exports('IsPlayerLoaded', function()
    return playerLoaded
end)

exports('GetPlayerData', function()
    return playerData
end)

-- Player connect
CreateThread(function()
    Wait(1000)
    TriggerServerEvent('ll-core:playerReady')
end)
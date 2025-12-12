-- GTA natív funkciók felülírása
CreateThread(function()
    while true do
        Wait(0)
        
        -- Radar kikapcsolása
        if LL.Game.DisableRadar then
            DisplayRadar(false)
        end
        
        -- Health bar kikapcsolása
        if LL.Game.DisableHealthBar then
            HideHudComponentThisFrame(3) -- Health
        end
        
        -- Armor bar kikapcsolása
        if LL.Game.DisableArmorBar then
            HideHudComponentThisFrame(4) -- Armour
        end
        
        -- Money display kikapcsolása
        if LL.Game.DisableMoneyDisplay then
            HideHudComponentThisFrame(8) -- Cash
            HideHudComponentThisFrame(9) -- MP Cash
        end
        
        -- További HUD elemek elrejtése
        HideHudComponentThisFrame(6) -- Vehicle name
        HideHudComponentThisFrame(7) -- Area name
        HideHudComponentThisFrame(19) -- Weapon wheel stats
    end
end)

-- Weapon wheel megtartása (ha engedélyezve)
if LL.Game.KeepWeaponWheel then
    CreateThread(function()
        while true do
            Wait(0)
            -- Weapon wheel enabled marad
            DisplayHud(true)
        end
    end)
end

-- Alapértelmezett game elemek módosítása
CreateThread(function()
    -- Wanted level kikapcsolása
    SetMaxWantedLevel(0)
    
    -- Police spawn kikapcsolása
    for i = 1, 15 do
        EnableDispatchService(i, false)
    end
    
    -- Természetes ped spawn kikapcsolása (opcionális)
    SetPedDensityMultiplierThisFrame(0.0)
    SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
    
    -- Járműforgalom kikapcsolása (opcionális)
    SetVehicleDensityMultiplierThisFrame(0.0)
    SetRandomVehicleDensityMultiplierThisFrame(0.0)
    SetParkedVehicleDensityMultiplierThisFrame(0.0)
end)

-- Death respawn automatizmus kikapcsolása
CreateThread(function()
    while true do
        Wait(0)
        
        local playerPed = PlayerPedId()
        
        if IsEntityDead(playerPed) then
            -- Megakadályozza a default respawn-t
            SetPlayerInvincible(PlayerId(), true)
            SetEntityHealth(playerPed, 200)
        end
    end
end)
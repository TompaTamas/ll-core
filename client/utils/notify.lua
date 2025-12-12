-- Egyszerű notify rendszer HUD nélkül
RegisterNetEvent('ll-notify:show', function(message, type, duration)
    local msgType = type or 'info'
    local msgDuration = duration or 5000
    
    -- Console log
    LL.Log(message, msgType)
    
    -- GTA native notification
    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    DrawNotification(false, true)
    
    -- Opcionális: BeginTextCommandThefeedPost is használható
end)

exports('Notify', function(message, type, duration)
    TriggerEvent('ll-notify:show', message, type, duration)
end)
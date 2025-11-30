-- Mission trigger system - detects when mission conditions are met
local activeTriggers = {}
local triggeredIds = {}

function RegisterMissionTrigger(triggerId, triggerData)
    if activeTriggers[triggerId] then
        LL.Log("Trigger already registered: " .. triggerId, "warning")
        return
    end
    
    activeTriggers[triggerId] = {
        type = triggerData.type,
        data = triggerData.data,
        missionId = triggerData.missionId,
        callback = triggerData.callback,
        active = true,
        oneTime = triggerData.oneTime ~= false -- Default true
    }
    
    LL.Log("Mission trigger registered: " .. triggerId .. " (Type: " .. triggerData.type .. ")", "info")
    
    -- Start appropriate trigger loop based on type
    if triggerData.type == LL.Missions.TriggerTypes.LOCATION then
        StartLocationTrigger(triggerId, triggerData)
    elseif triggerData.type == LL.Missions.TriggerTypes.TIME then
        StartTimeTrigger(triggerId, triggerData)
    end
end

function StartLocationTrigger(triggerId, triggerData)
    CreateThread(function()
        while activeTriggers[triggerId] and activeTriggers[triggerId].active do
            Wait(500)
            
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - triggerData.data.coords)
            
            if distance <= triggerData.data.radius then
                LL.Log("Location trigger activated: " .. triggerId, "info")
                
                -- Execute callback
                if activeTriggers[triggerId].callback then
                    activeTriggers[triggerId].callback()
                end
                
                -- Notify server
                TriggerServerEvent(LL.Events.Mission.TriggerActivated, triggerId, triggerData.missionId)
                
                -- Deactivate if one-time
                if activeTriggers[triggerId].oneTime then
                    activeTriggers[triggerId].active = false
                    table.insert(triggeredIds, triggerId)
                end
            end
        end
    end)
end

function StartTimeTrigger(triggerId, triggerData)
    CreateThread(function()
        local startTime = GetGameTimer()
        local targetTime = triggerData.data.milliseconds
        
        while activeTriggers[triggerId] and activeTriggers[triggerId].active do
            Wait(1000)
            
            local elapsed = GetGameTimer() - startTime
            
            if elapsed >= targetTime then
                LL.Log("Time trigger activated: " .. triggerId, "info")
                
                -- Execute callback
                if activeTriggers[triggerId].callback then
                    activeTriggers[triggerId].callback()
                end
                
                -- Notify server
                TriggerServerEvent(LL.Events.Mission.TriggerActivated, triggerId, triggerData.missionId)
                
                -- Deactivate
                activeTriggers[triggerId].active = false
                table.insert(triggeredIds, triggerId)
                break
            end
        end
    end)
end

function RegisterInteractTrigger(triggerId, triggerData)
    if activeTriggers[triggerId] then
        LL.Log("Trigger already registered: " .. triggerId, "warning")
        return
    end
    
    activeTriggers[triggerId] = {
        type = LL.Missions.TriggerTypes.INTERACT,
        data = triggerData.data,
        missionId = triggerData.missionId,
        callback = triggerData.callback,
        active = true,
        oneTime = triggerData.oneTime ~= false
    }
    
    -- Register interaction point
    exports['ll-core']:RegisterInteraction(triggerId, {
        coords = triggerData.data.coords,
        radius = triggerData.data.radius or 2.0,
        label = triggerData.data.label or "[E] Interact",
        onInteract = function()
            if activeTriggers[triggerId] and activeTriggers[triggerId].active then
                LL.Log("Interact trigger activated: " .. triggerId, "info")
                
                -- Execute callback
                if activeTriggers[triggerId].callback then
                    activeTriggers[triggerId].callback()
                end
                
                -- Notify server
                TriggerServerEvent(LL.Events.Mission.TriggerActivated, triggerId, triggerData.missionId)
                
                -- Deactivate if one-time
                if activeTriggers[triggerId].oneTime then
                    activeTriggers[triggerId].active = false
                    exports['ll-core']:RemoveInteraction(triggerId)
                    table.insert(triggeredIds, triggerId)
                end
            end
        end
    })
    
    LL.Log("Interact trigger registered: " .. triggerId, "info")
end

function RegisterItemTrigger(triggerId, triggerData)
    if activeTriggers[triggerId] then
        LL.Log("Trigger already registered: " .. triggerId, "warning")
        return
    end
    
    activeTriggers[triggerId] = {
        type = LL.Missions.TriggerTypes.ITEM,
        data = triggerData.data,
        missionId = triggerData.missionId,
        callback = triggerData.callback,
        active = true,
        oneTime = triggerData.oneTime ~= false
    }
    
    LL.Log("Item trigger registered: " .. triggerId .. " (Item: " .. triggerData.data.item .. ")", "info")
end

function RegisterEventTrigger(triggerId, triggerData)
    if activeTriggers[triggerId] then
        LL.Log("Trigger already registered: " .. triggerId, "warning")
        return
    end
    
    activeTriggers[triggerId] = {
        type = LL.Missions.TriggerTypes.EVENT,
        data = triggerData.data,
        missionId = triggerData.missionId,
        callback = triggerData.callback,
        active = true,
        oneTime = triggerData.oneTime ~= false
    }
    
    -- Register event handler
    RegisterNetEvent(triggerData.data.eventName, function(...)
        if activeTriggers[triggerId] and activeTriggers[triggerId].active then
            LL.Log("Event trigger activated: " .. triggerId, "info")
            
            -- Execute callback with event data
            if activeTriggers[triggerId].callback then
                activeTriggers[triggerId].callback(...)
            end
            
            -- Notify server
            TriggerServerEvent(LL.Events.Mission.TriggerActivated, triggerId, triggerData.missionId)
            
            -- Deactivate if one-time
            if activeTriggers[triggerId].oneTime then
                activeTriggers[triggerId].active = false
                table.insert(triggeredIds, triggerId)
            end
        end
    end)
    
    LL.Log("Event trigger registered: " .. triggerId .. " (Event: " .. triggerData.data.eventName .. ")", "info")
end

function TriggerItemUsed(itemName)
    for triggerId, trigger in pairs(activeTriggers) do
        if trigger.active and trigger.type == LL.Missions.TriggerTypes.ITEM then
            if trigger.data.item == itemName then
                LL.Log("Item trigger activated: " .. triggerId, "info")
                
                -- Execute callback
                if trigger.callback then
                    trigger.callback()
                end
                
                -- Notify server
                TriggerServerEvent(LL.Events.Mission.TriggerActivated, triggerId, trigger.missionId)
                
                -- Deactivate if one-time
                if trigger.oneTime then
                    trigger.active = false
                    table.insert(triggeredIds, triggerId)
                end
            end
        end
    end
end

function RemoveMissionTrigger(triggerId)
    if activeTriggers[triggerId] then
        activeTriggers[triggerId].active = false
        
        -- Remove interaction if exists
        if activeTriggers[triggerId].type == LL.Missions.TriggerTypes.INTERACT then
            exports['ll-core']:RemoveInteraction(triggerId)
        end
        
        activeTriggers[triggerId] = nil
        LL.Log("Trigger removed: " .. triggerId, "info")
    end
end

function RemoveAllMissionTriggers(missionId)
    local removed = 0
    
    for triggerId, trigger in pairs(activeTriggers) do
        if trigger.missionId == missionId then
            RemoveMissionTrigger(triggerId)
            removed = removed + 1
        end
    end
    
    if removed > 0 then
        LL.Log("Removed " .. removed .. " triggers for mission: " .. missionId, "info")
    end
end

function IsTriggerActive(triggerId)
    return activeTriggers[triggerId] and activeTriggers[triggerId].active
end

function GetActiveTriggers()
    local active = {}
    
    for triggerId, trigger in pairs(activeTriggers) do
        if trigger.active then
            table.insert(active, {
                id = triggerId,
                type = trigger.type,
                missionId = trigger.missionId
            })
        end
    end
    
    return active
end

function ResetTrigger(triggerId)
    if activeTriggers[triggerId] then
        activeTriggers[triggerId].active = true
        
        -- Remove from triggered list
        for i, id in ipairs(triggeredIds) do
            if id == triggerId then
                table.remove(triggeredIds, i)
                break
            end
        end
        
        LL.Log("Trigger reset: " .. triggerId, "info")
    end
end

-- Event for item use (external scripts can trigger this)
RegisterNetEvent('ll-mission:itemUsed', function(itemName)
    TriggerItemUsed(itemName)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Remove all interact triggers
    for triggerId, trigger in pairs(activeTriggers) do
        if trigger.type == LL.Missions.TriggerTypes.INTERACT then
            exports['ll-core']:RemoveInteraction(triggerId)
        end
    end
end)

-- Exports
exports('RegisterMissionTrigger', RegisterMissionTrigger)
exports('RegisterInteractTrigger', RegisterInteractTrigger)
exports('RegisterItemTrigger', RegisterItemTrigger)
exports('RegisterEventTrigger', RegisterEventTrigger)
exports('RemoveMissionTrigger', RemoveMissionTrigger)
exports('RemoveAllMissionTriggers', RemoveAllMissionTriggers)
exports('IsTriggerActive', IsTriggerActive)
exports('GetActiveTriggers', GetActiveTriggers)
exports('ResetTrigger', ResetTrigger)
exports('TriggerItemUsed', TriggerItemUsed)
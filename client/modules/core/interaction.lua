-- Basic interaction system
local interactions = {}
local nearestInteraction = nil
local isInteracting = false

function RegisterInteraction(id, data)
    interactions[id] = {
        coords = data.coords,
        radius = data.radius or 2.0,
        label = data.label or "[E] Interact",
        key = data.key or 38, -- E key
        onInteract = data.onInteract,
        onEnter = data.onEnter,
        onExit = data.onExit,
        enabled = true,
        distance = nil,
        marker = data.marker or nil
    }
    
    LL.Log("Interaction registered: " .. id, "info")
end

function RemoveInteraction(id)
    if interactions[id] then
        interactions[id] = nil
        LL.Log("Interaction removed: " .. id, "info")
    end
end

function DisableInteraction(id)
    if interactions[id] then
        interactions[id].enabled = false
    end
end

function EnableInteraction(id)
    if interactions[id] then
        interactions[id].enabled = true
    end
end

-- Main interaction thread
CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local foundNearby = false
        
        nearestInteraction = nil
        local nearestDistance = 999999
        
        for id, interaction in pairs(interactions) do
            if interaction.enabled then
                local distance = #(playerCoords - interaction.coords)
                interaction.distance = distance
                
                if distance <= interaction.radius then
                    foundNearby = true
                    
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestInteraction = {id = id, data = interaction}
                    end
                end
            end
        end
        
        if foundNearby then
            sleep = 0
        end
        
        Wait(sleep)
    end
end)

-- Draw and interact thread
CreateThread(function()
    while true do
        Wait(0)
        
        if nearestInteraction and not isInteracting then
            local interaction = nearestInteraction.data
            
            -- Draw 3D text
            DrawText3DInteraction(
                interaction.coords.x,
                interaction.coords.y,
                interaction.coords.z,
                interaction.label
            )
            
            -- Draw marker if specified
            if interaction.marker then
                DrawMarker(
                    interaction.marker.type or 1,
                    interaction.coords.x,
                    interaction.coords.y,
                    interaction.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    interaction.marker.scale or vector3(1.0, 1.0, 1.0),
                    interaction.marker.color and interaction.marker.color.r or 255,
                    interaction.marker.color and interaction.marker.color.g or 255,
                    interaction.marker.color and interaction.marker.color.b or 0,
                    interaction.marker.color and interaction.marker.color.a or 150,
                    false, true, 2, false, nil, nil, false
                )
            end
            
            -- Check for key press
            if IsControlJustReleased(0, interaction.key) then
                isInteracting = true
                
                if interaction.onInteract then
                    interaction.onInteract(nearestInteraction.id)
                end
                
                Wait(500) -- Cooldown
                isInteracting = false
            end
        else
            Wait(500)
        end
    end
end)

function DrawText3DInteraction(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoord()
    local distance = #(camCoords - vector3(x, y, z))
    
    if onScreen then
        local scale = (1 / distance) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov
        
        SetTextScale(0.0 * scale, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function GetNearestInteraction()
    return nearestInteraction
end

function IsNearInteraction()
    return nearestInteraction ~= nil
end

-- Exports
exports('RegisterInteraction', RegisterInteraction)
exports('RemoveInteraction', RemoveInteraction)
exports('DisableInteraction', DisableInteraction)
exports('EnableInteraction', EnableInteraction)
exports('GetNearestInteraction', GetNearestInteraction)
exports('IsNearInteraction', IsNearInteraction)
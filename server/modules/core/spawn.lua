-- Server-side spawn management
local spawnPoints = {
    LL.Spawn.DefaultLocation
}

function AddSpawnPoint(coords, heading)
    if type(coords) == "vector3" then
        coords = vector4(coords.x, coords.y, coords.z, heading or 0.0)
    end
    
    table.insert(spawnPoints, coords)
    LL.Log("Spawn point added: " .. tostring(coords), "info")
end

function RemoveSpawnPoint(index)
    if spawnPoints[index] then
        table.remove(spawnPoints, index)
        LL.Log("Spawn point removed at index: " .. index, "info")
    end
end

function GetSpawnPoints()
    return spawnPoints
end

function GetRandomSpawnPoint()
    if #spawnPoints == 0 then
        return LL.Spawn.DefaultLocation
    end
    
    return spawnPoints[math.random(#spawnPoints)]
end

function SetPlayerSpawnPoint(src, coords, heading)
    if type(coords) == "vector3" then
        coords = vector4(coords.x, coords.y, coords.z, heading or 0.0)
    end
    
    TriggerClientEvent('ll-spawn:setSpawn', src, coords)
end

RegisterCommand('setspawn', function(source, args)
    if source == 0 then -- Console
        if #args >= 3 then
            local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
            local heading = tonumber(args[4]) or 0.0
            
            LL.Spawn.DefaultLocation = vector4(x, y, z, heading)
            LL.Log("Default spawn point set to: " .. tostring(LL.Spawn.DefaultLocation), "success")
        else
            LL.Log("Usage: setspawn [x] [y] [z] [heading]", "warning")
        end
    elseif IsPlayerAdmin(source) then
        local playerPed = GetPlayerPed(source)
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        
        LL.Spawn.DefaultLocation = vector4(coords.x, coords.y, coords.z, heading)
        NotifyPlayer(source, "Spawn point beállítva", "success")
        LL.Log("Spawn point set by " .. GetPlayerName(source), "info")
    end
end, false)

exports('AddSpawnPoint', AddSpawnPoint)
exports('RemoveSpawnPoint', RemoveSpawnPoint)
exports('GetSpawnPoints', GetSpawnPoints)
exports('GetRandomSpawnPoint', GetRandomSpawnPoint)
exports('SetPlayerSpawnPoint', SetPlayerSpawnPoint)
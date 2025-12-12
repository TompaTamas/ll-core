-- Spawn management
local spawnPoints = {}

function SetSpawnPoint(coords, heading)
    if type(coords) == "vector3" then
        coords = vector4(coords.x, coords.y, coords.z, heading or 0.0)
    end
    
    LL.Spawn.DefaultLocation = coords
    LL.Log("Spawn point set: " .. tostring(coords), "info")
end

function GetSpawnPoint()
    return LL.Spawn.DefaultLocation
end

RegisterNetEvent('ll-spawn:setSpawn', function(coords, heading)
    SetSpawnPoint(coords, heading)
end)

exports('SetSpawnPoint', SetSpawnPoint)
exports('GetSpawnPoint', GetSpawnPoint)
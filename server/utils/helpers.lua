-- Server-side helper functions

-- Get all players
function GetPlayers()
    local players = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        table.insert(players, tonumber(playerId))
    end
    
    return players
end

-- Get player by identifier
function GetPlayerByIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local playerIdentifier = GetPlayerIdentifierByType(playerId, 'license')
        
        if playerIdentifier == identifier then
            return playerId
        end
    end
    
    return nil
end

-- Check if player is admin (placeholder - framework dependent)
function IsPlayerAdmin(src)
    if not LL.Admins.Enabled then return false end
    
    -- Framework integration here
    -- Example: return IsPlayerAceAllowed(src, "ll-core.admin")
    
    return false
end

-- Send notification to player
function NotifyPlayer(src, message, type, duration)
    TriggerClientEvent('ll-notify:show', src, message, type, duration)
end

-- Send notification to all players
function NotifyAll(message, type, duration)
    TriggerClientEvent('ll-notify:show', -1, message, type, duration)
end

-- Get players in radius (server-side)
function GetPlayersInRadius(coords, radius)
    local players = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(coords - playerCoords)
        
        if distance <= radius then
            table.insert(players, {
                source = playerId,
                coords = playerCoords,
                distance = distance
            })
        end
    end
    
    return players
end

-- Generate unique ID
function GenerateUniqueId(prefix)
    prefix = prefix or "ll"
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    
    return string.format("%s_%d_%d", prefix, timestamp, random)
end

-- Table contains value
function TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Merge tables
function MergeTables(t1, t2)
    local result = {}
    
    for k, v in pairs(t1) do
        result[k] = v
    end
    
    for k, v in pairs(t2) do
        result[k] = v
    end
    
    return result
end

exports('GetPlayers', GetPlayers)
exports('GetPlayerByIdentifier', GetPlayerByIdentifier)
exports('IsPlayerAdmin', IsPlayerAdmin)
exports('NotifyPlayer', NotifyPlayer)
exports('NotifyAll', NotifyAll)
exports('GetPlayersInRadius', GetPlayersInRadius)
exports('GenerateUniqueId', GenerateUniqueId)
exports('TableContains', TableContains)
exports('MergeTables', MergeTables)
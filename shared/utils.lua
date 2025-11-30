-- Debug log
function LL.Log(message, type)
    if not LL.Core.Debug then return end
    local prefix = "^7[LL-Core]^0"
    local color = "^7"
    
    if type == "error" then
        color = "^1"
    elseif type == "success" then
        color = "^2"
    elseif type == "warning" then
        color = "^3"
    elseif type == "info" then
        color = "^5"
    end
    
    print(prefix .. color .. " " .. message .. "^0")
end

-- Távolság számítás
function LL.GetDistance(coords1, coords2)
    if type(coords1) == "table" then
        coords1 = vector3(coords1.x or 0, coords1.y or 0, coords1.z or 0)
    end
    if type(coords2) == "table" then
        coords2 = vector3(coords2.x or 0, coords2.y or 0, coords2.z or 0)
    end
    return #(coords1 - coords2)
end

-- Tábla másolás
function LL.DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for k, v in next, original, nil do
            copy[LL.DeepCopy(k)] = LL.DeepCopy(v)
        end
        setmetatable(copy, LL.DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- Round number
function LL.Round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Clamp érték
function LL.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- JSON parse safe
function LL.JsonDecode(str)
    local success, result = pcall(json.decode, str)
    if success then
        return result
    else
        LL.Log("JSON decode error: " .. tostring(result), "error")
        return nil
    end
end

-- JSON encode safe
function LL.JsonEncode(data)
    local success, result = pcall(json.encode, data)
    if success then
        return result
    else
        LL.Log("JSON encode error: " .. tostring(result), "error")
        return nil
    end
end
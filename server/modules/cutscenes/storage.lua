-- Cutscene storage - saves to both database and files
local cutscenesFolder = "cutscenes/"

-- Ensure cutscenes folder exists (check on startup)
CreateThread(function()
    Wait(1000)
    LL.Log("Cutscene storage initialized", "info")
end)

RegisterNetEvent(LL.Events.Cutscene.Save, function(name, duration, cutsceneData)
    local src = source
    local playerData = exports['ll-core']:GetPlayerData(src)
    
    if not playerData then return end
    
    -- Validate cutscene data
    if not name or name == "" then
        TriggerClientEvent('ll-notify:show', src, 'Hiba: Nincs név megadva!', 'error')
        return
    end
    
    -- Create complete cutscene object
    local cutscene = cutsceneData or {}
    cutscene.name = name
    cutscene.duration = duration or 30000
    
    local jsonData = LL.JsonEncode(cutscene)
    
    if not jsonData then
        TriggerClientEvent('ll-notify:show', src, 'Hiba: JSON encode sikertelen!', 'error')
        LL.Log("Failed to encode cutscene JSON: " .. name, "error")
        return
    end
    
    -- Save to file
    local fileName = cutscenesFolder .. name .. ".json"
    local success = SaveResourceFile(GetCurrentResourceName(), fileName, jsonData, -1)
    
    if success then
        LL.Log("Cutscene saved to file: " .. fileName, "success")
        TriggerClientEvent('ll-notify:show', src, 'Cutscene mentve fájlba: ' .. name, 'success')
    else
        LL.Log("Failed to save cutscene to file: " .. fileName, "error")
        TriggerClientEvent('ll-notify:show', src, 'Fájlba mentés sikertelen!', 'error')
    end
    
    -- Also save to database for backup
    MySQL.query('SELECT id FROM ' .. LL.Database.Tables.Cutscenes .. ' WHERE name = ?', {name}, function(result)
        if result and #result > 0 then
            -- Update existing
            MySQL.update('UPDATE ' .. LL.Database.Tables.Cutscenes .. ' SET data = ?, updated_at = NOW() WHERE name = ?', {
                jsonData,
                name
            }, function(affectedRows)
                if affectedRows > 0 then
                    LL.Log("Cutscene updated in database: " .. name, "info")
                end
            end)
        else
            -- Insert new
            MySQL.insert('INSERT INTO ' .. LL.Database.Tables.Cutscenes .. ' (name, data, created_by) VALUES (?, ?, ?)', {
                name,
                jsonData,
                playerData.id
            }, function(insertId)
                if insertId then
                    LL.Log("Cutscene created in database: " .. name, "info")
                end
            end)
        end
    end)
end)

RegisterNetEvent(LL.Events.Cutscene.Load, function(name)
    local src = source
    
    if not name or name == "" then
        TriggerClientEvent('ll-notify:show', src, 'Hiba: Nincs név megadva!', 'error')
        return
    end
    
    -- Try to load from file first
    local fileName = cutscenesFolder .. name .. ".json"
    local fileData = LoadResourceFile(GetCurrentResourceName(), fileName)
    
    if fileData then
        local cutsceneData = LL.JsonDecode(fileData)
        
        if cutsceneData then
            TriggerClientEvent(LL.Events.Cutscene.Load, src, cutsceneData)
            LL.Log("Cutscene loaded from file: " .. name, "info")
            TriggerClientEvent('ll-notify:show', src, 'Cutscene betöltve: ' .. name, 'success')
            return
        else
            LL.Log("Failed to decode cutscene JSON from file: " .. fileName, "error")
        end
    end
    
    -- Fallback to database
    MySQL.query('SELECT data FROM ' .. LL.Database.Tables.Cutscenes .. ' WHERE name = ?', {name}, function(result)
        if result and #result > 0 then
            local cutsceneData = LL.JsonDecode(result[1].data)
            
            if cutsceneData then
                TriggerClientEvent(LL.Events.Cutscene.Load, src, cutsceneData)
                LL.Log("Cutscene loaded from database: " .. name, "info")
                TriggerClientEvent('ll-notify:show', src, 'Cutscene betöltve adatbázisból: ' .. name, 'success')
            else
                TriggerClientEvent('ll-notify:show', src, 'Hiba a cutscene betöltésekor!', 'error')
            end
        else
            TriggerClientEvent('ll-notify:show', src, 'Cutscene nem található: ' .. name, 'error')
            LL.Log("Cutscene not found: " .. name, "warning")
        end
    end)
end)

function GetCutsceneByName(name)
    -- Try file first
    local fileName = cutscenesFolder .. name .. ".json"
    local fileData = LoadResourceFile(GetCurrentResourceName(), fileName)
    
    if fileData then
        local cutsceneData = LL.JsonDecode(fileData)
        if cutsceneData then
            return cutsceneData
        end
    end
    
    -- Fallback to database
    local result = MySQL.single.await('SELECT data FROM ' .. LL.Database.Tables.Cutscenes .. ' WHERE name = ?', {name})
    
    if result then
        return LL.JsonDecode(result.data)
    end
    
    return nil
end

function GetAllCutsceneNames()
    local cutscenes = {}
    
    -- Get from database
    local result = MySQL.query.await('SELECT name, created_at FROM ' .. LL.Database.Tables.Cutscenes, {})
    
    if result then
        for _, cutscene in ipairs(result) do
            table.insert(cutscenes, {
                name = cutscene.name,
                source = "database",
                created = cutscene.created_at
            })
        end
    end
    
    return cutscenes
end

function DeleteCutscene(name)
    -- Delete file
    local fileName = cutscenesFolder .. name .. ".json"
    local fileData = LoadResourceFile(GetCurrentResourceName(), fileName)
    
    if fileData then
        SaveResourceFile(GetCurrentResourceName(), fileName, "", -1)
        LL.Log("Cutscene file deleted: " .. fileName, "info")
    end
    
    -- Delete from database
    MySQL.update('DELETE FROM ' .. LL.Database.Tables.Cutscenes .. ' WHERE name = ?', {name})
    LL.Log("Cutscene deleted from database: " .. name, "info")
    
    return true
end

-- Commands
RegisterCommand('playcutscene', function(source, args)
    if #args < 1 then
        exports['ll-core']:NotifyPlayer(source, 'Használat: /playcutscene [név]', 'error')
        return
    end
    
    local cutsceneName = args[1]
    local cutscene = GetCutsceneByName(cutsceneName)
    
    if cutscene then
        TriggerClientEvent(LL.Events.Cutscene.Play, source, cutscene)
        LL.Log("Playing cutscene for player " .. source .. ": " .. cutsceneName, "info")
    else
        exports['ll-core']:NotifyPlayer(source, 'Cutscene nem található: ' .. cutsceneName, 'error')
    end
end, false)

RegisterCommand('listcutscenes', function(source)
    local cutscenes = GetAllCutsceneNames()
    
    if #cutscenes > 0 then
        LL.Log("=== Elérhető Cutscene-ek ===", "info")
        for i, cutscene in ipairs(cutscenes) do
            LL.Log(i .. ". " .. cutscene.name .. " (" .. cutscene.source .. ")", "info")
        end
        LL.Log("Összesen: " .. #cutscenes, "info")
        
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, 'Elérhető cutscene-ek: ' .. #cutscenes .. ' - Nézd meg a konzolt!', 'info')
        end
    else
        local msg = 'Nincsenek cutscene-ek!'
        LL.Log(msg, "warning")
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, msg, 'warning')
        end
    end
end, false)

RegisterCommand('deletecutscene', function(source, args)
    if source > 0 and not exports['ll-core']:IsPlayerAdmin(source) then
        exports['ll-core']:NotifyPlayer(source, 'Nincs jogosultságod!', 'error')
        return
    end
    
    if #args < 1 then
        local msg = 'Használat: /deletecutscene [név]'
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, msg, 'error')
        else
            LL.Log(msg, "error")
        end
        return
    end
    
    local name = args[1]
    
    if DeleteCutscene(name) then
        local msg = 'Cutscene törölve: ' .. name
        LL.Log(msg, "success")
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, msg, 'success')
        end
    else
        local msg = 'Hiba történt a törlés során!'
        LL.Log(msg, "error")
        if source > 0 then
            exports['ll-core']:NotifyPlayer(source, msg, 'error')
        end
    end
end, false)

-- Exports
exports('GetCutscene', GetCutsceneByName)
exports('GetCutsceneByName', GetCutsceneByName)
exports('GetAllCutscenes', GetAllCutsceneNames)
exports('GetAllCutsceneNames', GetAllCutsceneNames)
exports('DeleteCutscene', DeleteCutscene)
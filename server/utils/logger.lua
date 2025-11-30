-- Server-side logging utility
local logFile = "ll-core.log"

function WriteLog(message, level)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logLevel = level or "INFO"
    local logMessage = string.format("[%s] [%s] %s", timestamp, logLevel, message)
    
    if LL.Core.Debug then
        print(logMessage)
    end
    
    -- Fájlba írás (opcionális)
    -- SaveResourceFile(GetCurrentResourceName(), logFile, logMessage .. "\n", -1)
end

function LogPlayerAction(src, action, details)
    local playerData = exports['ll-core']:GetPlayerData(src)
    if not playerData then return end
    
    local message = string.format("Player [%s] %s: %s", playerData.name, action, details or "")
    WriteLog(message, "PLAYER")
end

exports('WriteLog', WriteLog)
exports('LogPlayerAction', LogPlayerAction)
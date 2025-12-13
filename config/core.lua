-- Core configuration file
-- Ez a fájl tartalmazza az alap rendszer beállításokat

-- Már létezik a shared/config.lua-ban az LL tábla inicializálása
-- Itt csak kiegészítjük további core beállításokkal

-- Admin rendszer (opcionális - framework integrációhoz)
LL.Admins = {
    Enabled = false,
    Groups = {
        ["superadmin"] = true,
        ["admin"] = true
    }
}

-- Command beállítások
LL.Commands = {
    Prefix = "/",
    RestrictedCommands = {
        "cutscenecreator"
    }
}

-- Performance beállítások
LL.Performance = {
    EntityCleanupInterval = 300000, -- 5 perc
    MaxSpawnedNPCs = 50,
    MaxSpawnedVehicles = 20,
    OptimizeDrawDistance = true
}

-- Notification beállítások
LL.Notifications = {
    Position = "top-right", -- top-right, top-left, bottom-right, bottom-left
    Duration = 5000,
    MaxVisible = 3
}

-- Debug beállítások
if LL.Core.Debug then
    print("^2[LL-Core] Debug mode enabled^0")
    print("^3[LL-Core] Configuration loaded^0")
end
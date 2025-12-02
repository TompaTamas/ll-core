LL = {}
LL.Core = {
    Name = "ll-core",
    Version = "1.0.0",
    Debug = true
}

-- Alap játék beállítások
LL.Game = {
    DisableRadar = true,
    DisableHealthBar = true,
    DisableArmorBar = true,
    DisableMoneyDisplay = true,
    KeepWeaponWheel = true,
    RespawnTime = 5000, -- ms
    DeathFadeTime = 3000 -- ms
}

-- Spawn beállítások
LL.Spawn = {
    DefaultLocation = vector4(-1035.71, -2731.87, 13.75, 0.0),
    FadeInTime = 2000
}

-- Adatbázis táblák
LL.Database = {
    Tables = {
        Players = "ll_players",
        PlayerSurvival = "ll_player_survival",
        PlayerMissions = "ll_player_missions",
        Cutscenes = "ll_cutscenes",
        CutsceneNPCs = "ll_cutscene_npcs"
    }
}
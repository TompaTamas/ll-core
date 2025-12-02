LL.Events = {
    -- Core Events
    Core = {
        PlayerLoaded = "ll-core:playerLoaded",
        PlayerUnload = "ll-core:playerUnload",
        PlayerSpawn = "ll-core:playerSpawn",
        PlayerDeath = "ll-core:playerDeath"
    },
    
    -- Survival Events
    Survival = {
        UpdateHunger = "ll-survival:updateHunger",
        UpdateThirst = "ll-survival:updateThirst",
        UpdateRadiation = "ll-survival:updateRadiation",
        UpdateSanity = "ll-survival:updateSanity",
        SyncStats = "ll-survival:syncStats",
        CheckDeath = "ll-survival:checkDeath"
    },
    
    -- Mission Events
    Mission = {
        Start = "ll-mission:start",
        Complete = "ll-mission:complete",
        Fail = "ll-mission:fail",
        UpdateObjective = "ll-mission:updateObjective",
        TriggerActivated = "ll-mission:triggerActivated",
        LoadMissions = "ll-mission:loadMissions",
        SyncProgress = "ll-mission:syncProgress"
    },
    
    -- Cutscene Events
    Cutscene = {
        Play = "ll-cutscene:play",
        Stop = "ll-cutscene:stop",
        OpenCreator = "ll-cutscene:openCreator",
        CloseCreator = "ll-cutscene:closeCreator",
        Save = "ll-cutscene:save",
        Load = "ll-cutscene:load",
        SyncNPC = "ll-cutscene:syncNPC",
        UpdateTimeline = "ll-cutscene:updateTimeline"
    }
}
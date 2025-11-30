LL.Cutscenes = {
    -- Cutscene rendszer beállítások
    Enabled = true,
    CutscenesFolder = "cutscenes/", -- JSON fájlok helye
    AudioFolder = "audio/voicelines/", -- Hang fájlok
    
    -- Creator UI
    Creator = {
        Enabled = true,
        Command = "cutscenecreator", -- Megnyitó parancs
        AdminOnly = true, -- Csak admin használhatja
        Keybind = nil -- vagy pl: "F7"
    },
    
    -- Kamera beállítások
    Camera = {
        DefaultFOV = 50.0,
        MinFOV = 10.0,
        MaxFOV = 130.0,
        SmoothTransition = true,
        TransitionSpeed = 2.0, -- Másodperc
        ShakeIntensity = {
            Low = 0.1,
            Medium = 0.3,
            High = 0.5
        }
    },
    
    -- Timeline
    Timeline = {
        MinDuration = 1.0, -- Minimum másodperc
        MaxDuration = 600.0, -- Maximum 10 perc
        Framerate = 30, -- Keyframe-ek száma másodpercenként
        AutoSave = true,
        AutoSaveInterval = 30000 -- 30 másodperc
    },
    
    -- NPC beállítások cutscene-ekhez
    NPCs = {
        MaxNPCs = 10, -- Max NPC egy cutscene-ben
        EnableClothing = true,
        DefaultModel = "a_m_y_business_01",
        AllowCustomClothes = true, -- Szerver ruhái használhatók
        -- Ruházat rendszer (ugyanaz mint missions)
        ClothingComponents = {
            [0] = "Face",
            [1] = "Mask",
            [2] = "Hair",
            [3] = "Torso",
            [4] = "Legs",
            [5] = "Bag",
            [6] = "Shoes",
            [7] = "Accessories",
            [8] = "Undershirt",
            [9] = "Body Armor",
            [10] = "Decals",
            [11] = "Tops"
        },
        Props = {
            [0] = "Hats",
            [1] = "Glasses",
            [2] = "Ears",
            [6] = "Watches",
            [7] = "Bracelets"
        },
        -- Animációk
        Animations = {
            "WORLD_HUMAN_SMOKING",
            "WORLD_HUMAN_DRINKING",
            "WORLD_HUMAN_STAND_MOBILE",
            "WORLD_HUMAN_AA_COFFEE",
            "WORLD_HUMAN_LEANING"
            -- További animációk...
        }
    },
    
    -- Audio
    Audio = {
        EnableVoicelines = true,
        SupportedFormats = {".ogg", ".mp3"},
        Volume = 0.5, -- 0.0 - 1.0
        Enable3DAudio = true,
        MaxDistance = 50.0, -- 3D audio max távolság
        FadeIn = 0.5, -- Másodperc
        FadeOut = 0.5
    },
    
    -- Playback
    Playback = {
        HideHUD = true,
        HideRadar = true,
        DisableControls = true,
        FadeInDuration = 1000, -- ms
        FadeOutDuration = 1000,
        Letterbox = true, -- Fekete sávok fent/lent
        LetterboxHeight = 0.15 -- Screen százalék
    },
    
    -- Export formátum
    ExportFormat = {
        Version = "1.0",
        Compression = false, -- JSON minify
        IncludeMetadata = true
    },
    
    -- Sync
    MultiplayerSync = true, -- Többjátékos sync support
    SyncRadius = 100.0 -- Cutscene látható távolság
}
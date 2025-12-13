LL.Missions = {
    -- Küldetés rendszer beállítások
    Enabled = true,
    MissionsFolder = "missions/", -- Külső lua fájlok helye
    AutoLoad = true, -- Auto load minden .lua fájl
    
    -- Trigger típusok
    TriggerTypes = {
        LOCATION = "location", -- Hely alapú
        INTERACT = "interact", -- NPC/object interakció
        ITEM = "item", -- Item használat
        EVENT = "event", -- Custom event
        TIME = "time" -- Időalapú
    },
    
    -- Objective típusok
    ObjectiveTypes = {
        GOTO = "goto", -- Menj egy helyre
        KILL = "kill", -- Ölj meg X db ellenséget
        COLLECT = "collect", -- Gyűjts össze X db itemet
        TALK = "talk", -- Beszélj valakivel
        DELIVER = "deliver", -- Szállíts le valamit
        SURVIVE = "survive", -- Élj túl X ideig
        CUSTOM = "custom" -- Egyedi logic
    },
    
    -- NPC ruházat rendszer
    NPCClothing = {
        EnableCustomClothing = true,
        AllowPlayerClothes = true, -- Játékos ruhái használhatók
        DefaultMaleModel = "mp_m_freemode_01",
        DefaultFemaleModel = "mp_f_freemode_01",
        -- Ruházat komponensek (DrawableID, TextureID)
        Components = {
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
        }
    },
    
    -- Marker beállítások
    Markers = {
        Enabled = true,
        Type = 1, -- Marker típus
        Size = vector3(1.0, 1.0, 1.0),
        Color = {r = 255, g = 255, b = 0, a = 150},
        BobUpAndDown = false,
        Rotate = false,
        DrawDistance = 50.0,
        InteractDistance = 2.0
    },
    
    -- Notification beállítások
    Notifications = {
        Enabled = true,
        MissionStart = true,
        MissionComplete = true,
        ObjectiveUpdate = true,
        Duration = 5000 -- ms
    },
    
    -- Reward típusok
    RewardTypes = {
        MONEY = "money",
        ITEM = "item",
        XP = "xp",
        UNLOCK = "unlock" -- Új küldetés feloldás
    },
    
    -- Progress mentés
    SaveProgress = true,
    AutoSaveInterval = 120000 -- 2 perc
}
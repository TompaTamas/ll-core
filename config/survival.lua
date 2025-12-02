LL.Survival = {
    -- Éhség rendszer
    Hunger = {
        Enabled = true,
        StartValue = 100,
        DecreaseRate = 0.1, -- Percenként
        CriticalLevel = 20,
        DeathLevel = 0,
        Effects = {
            [30] = { -- 30% alatt
                health = -0.5, -- HP csökkenés percenként
                stamina = 0.7 -- Stamina 70%-ra csökken
            },
            [10] = { -- 10% alatt
                health = -1.5,
                stamina = 0.4,
                blur = true -- Képernyő elhomályosítás
            }
        }
    },
    
    -- Szomjúság rendszer
    Thirst = {
        Enabled = true,
        StartValue = 100,
        DecreaseRate = 0.15, -- Gyorsabb mint éhség
        CriticalLevel = 20,
        DeathLevel = 0,
        Effects = {
            [30] = {
                health = -0.7,
                stamina = 0.6,
                speed = 0.9 -- Lassabb mozgás
            },
            [10] = {
                health = -2.0,
                stamina = 0.3,
                speed = 0.7,
                blur = true
            }
        }
    },
    
    -- Radioaktivitás
    Radiation = {
        Enabled = true,
        StartValue = 0,
        MaxValue = 100,
        NaturalDecreaseRate = 0.5, -- Percenként, ha nincs zónában
        DeathLevel = 100,
        Zones = {
            {
                coords = vector3(0.0, 0.0, 0.0),
                radius = 100.0,
                increaseRate = 1.0, -- Percenként
                label = "Radioaktív zóna"
            }
            -- További zónák hozzáadhatók
        },
        Effects = {
            [25] = {
                health = -0.3,
                screenEffect = "MinigameEndNeutral" -- Screen effect
            },
            [50] = {
                health = -0.8,
                screenEffect = "DrugsMichaelAliensFight"
            },
            [75] = {
                health = -1.5,
                screenEffect = "DrugsMichaelAliensFight",
                blur = true
            }
        }
    },
    
    -- Elme állapot (Sanity)
    Sanity = {
        Enabled = true,
        StartValue = 100,
        DecreaseRate = 0.05, -- Lassú csökkenés
        NightDecreaseMultiplier = 2.0, -- Éjszaka gyorsabb
        AloneDecreaseMultiplier = 1.5, -- Ha nincs közelben játékos
        MinPlayers = 1, -- Min játékos szám körülötted
        CheckRadius = 50.0, -- Távolság ellenőrzés
        Effects = {
            [60] = {
                screenEffect = "ChopVision",
                shakeCam = 0.1
            },
            [40] = {
                screenEffect = "DrugsDrivingIn",
                shakeCam = 0.3,
                audio = "HELI_CRASH_SOUNDSET" -- Audio loop
            },
            [20] = {
                screenEffect = "DrugsMichaelAliensFight",
                shakeCam = 0.5,
                audio = "HELI_CRASH_SOUNDSET",
                hallucinations = true -- NPC/object hallucináció
            }
        }
    },
    
    -- Update időzítés
    UpdateInterval = 60000, -- 60 mp (1 perc)
    SyncInterval = 30000 -- Szerver sync 30 mp-enként
}
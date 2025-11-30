return {
    id = "example_mission_1",
    name = "Első Küldetés",
    description = "Menj el a megjelölt helyre és beszélj az NPC-vel. Cutscene játszódik le a végén!",
    
    -- Mission beállítások
    requirements = {
        level = 1,
        previousMissions = {}
    },
    
    -- NPCs
    npcs = {
        {
            model = "a_m_y_business_01",
            coords = vector3(-1035.71, -2731.87, 13.75),
            heading = 180.0,
            isObjectiveNPC = true,
            
            -- NPC ruházat (szerver ruhái használhatók)
            clothing = {
                components = {
                    [3] = {drawable = 1, texture = 0}, -- Torso
                    [4] = {drawable = 10, texture = 0}, -- Legs
                    [6] = {drawable = 10, texture = 0}, -- Shoes
                    [8] = {drawable = 15, texture = 0}, -- Undershirt
                    [11] = {drawable = 13, texture = 0} -- Tops
                },
                props = {
                    [0] = {drawable = 0, texture = 0}, -- Hat
                    [1] = {drawable = 5, texture = 0}  -- Glasses
                }
            },
            
            -- Animáció
            animation = {
                dict = "amb@world_human_stand_mobile@male@text@base",
                name = "base",
                flag = 1
            }
        }
    },
    
    -- Objectives
    objectives = {
        {
            type = "goto",
            label = "Menj a megjelölt helyre",
            coords = vector3(-1030.0, -2730.0, 13.75),
            radius = 5.0,
            blip = {
                sprite = 1,
                color = 5,
                scale = 1.0
            }
        },
        {
            type = "talk",
            label = "Beszélj az NPC-vel",
            npcIndex = 1, -- Az első NPC
            dialog = "Szia! Köszönöm, hogy eljöttél. Most nézd meg ezt a cutscene-t!"
        }
    },
    
    -- Rewards
    rewards = {
        {
            type = "money",
            amount = 500
        },
        {
            type = "xp",
            amount = 100
        }
    },
    
    -- Cutscene integration
    cutscenes = {
        onStart = nil, -- Cutscene név amit küldetés kezdéskor lejátszik (opcionális)
        onComplete = "example_cutscene", -- Cutscene név amit küldetés végeztével lejátszik
        onFail = nil -- Cutscene név amit küldetés bukásakor lejátszik (opcionális)
    },
    
    -- Callbacks
    onStart = function()
        print("Mission started!")
        -- Ha van onStart cutscene
        -- TriggerServerEvent('ll-mission:playCutscene', 'intro_cutscene')
    end,
    
    onComplete = function()
        print("Mission completed!")
        -- Cutscene automatikusan lejátszódik ha meg van adva
    end,
    
    onFail = function()
        print("Mission failed!")
    end
}
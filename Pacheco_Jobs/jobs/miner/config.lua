ConfigMiner = ConfigMiner or {} 

-- ==========================================
-- DEFINIÇÕES DE MINERAÇÃO (PICKAXE)
-- ==========================================
ConfigMiner.Model = "prop_rock_4_c" 
ConfigMiner.MiningTime = 5000 

ConfigMiner.Rewards = {
    xpPerHit = 100,         
    jobName = "miner"      
}

ConfigMiner.Locations = {
    vector3(2972.2788, 2787.8596, 39.7051),
    vector3(2973.6855, 2779.9092, 38.6819),
    vector3(2966.3850, 2776.9851, 38.9572),
    vector3(2958.9524, 2781.7141, 40.5874),
    vector3(2952.2561, 2793.4246, 40.7899),
}

ConfigMiner.Washing = {
    ItemBruto = "stone",
    ItemLavado = "washed_stone",
    BatchSize = 2,
    TimePerBatch = 10000,
    Stations = {
        vector4(-1406.4170, 2005.6992, 60.0455, 67.2737),
        vector4(-1404.9733, 2005.5402, 60.2590, 344.0033),
        vector4(-1402.6097, 2005.5385, 60.5769, 221.3296),
        vector4(-1404.0645, 2005.5878, 60.3738, 49.6840),
    },
    Marker = {
        id = 1,
        color = {r = 0, g = 162, b = 255, a = 0},
        size = {x = 1.5, y = 1.5, z = 0.5}
    }
}

ConfigMiner.Smelting = {
    ItemNecessario = "washed_stone", 
    QuantidadeNecessaria = 1,        
    Stations = {
        vector4(1110.1259, -2008.0105, 31.0567, 235.6536) 
    },
    Marker = {
        id = 1,
        color = {r = 255, g = 60, b = 0, a = 100}, 
        size = {x = 1.2, y = 1.2, z = 0.5}
    }
}

ConfigMiner.Selling = {
    Station = vector3(-621.0365, -228.4622, 38.0570), 
    
    Marker = {
        id = 29, 
        color = {r = 0, g = 255, b = 100, a = 150}, 
        size = {x = 1.0, y = 1.0, z = 1.0}
    },

    Items = {
        { name = 'copper',  label = 'Cobre',    price = 200 },
        { name = 'iron',    label = 'Ferro',    price = 400 },
        { name = 'silver',  label = 'Prata',    price = 600 }, -- Novo
        { name = 'gold',    label = 'Ouro',     price = 1000 },
        { name = 'diamond', label = 'Diamante', price = 2000 },
        { name = 'metal',   label = 'Metal Raro', price = 3500 } -- Novo
    }
}

ConfigMiner.UI = {
    JobTitle = "MINEIRO",
    JobSubtitle = "Apanhar Calhaus vai ser o teu main Job",
    RoleName = "Mineiro",
    BrandIcon = "fas fa-gem",
    
    Levels = {
        [1] = 0,       
        [2] = 1000,      
        [3] = 10000,  
        [4] = 50000,
        [5] = 150000,
        [6] = 500000  
    },

    Stat1 = { label = "Rocks Mined", icon = "fas fa-mountain" },
    Stat2 = { label = "Ores Processed", icon = "fas fa-box" },
    Stat3 = { label = "Gems Cut", icon = "fas fa-gem" },

    Tools = {
        { id = 1, name = "Picareta de Iniciação", price = 500, level = 1, item = "picareta", img = "nui://ox_inventory/web/images/picareta.png", desc = "5 Pancadas | 2 Pedras" },
        { id = 2, name = "Picareta Reforçada", price = 2500, level = 2, item = "picareta_2", img = "nui://ox_inventory/web/images/picareta_2.png", desc = "4 Pancadas | 2 Pedras" },
        { id = 3, name = "Picareta Industrial", price = 7500, level = 3, item = "picareta_3", img = "nui://ox_inventory/web/images/picareta_3.png", desc = "3 Pancadas | 2 Pedras" },
        { id = 4, name = "Martelo Elétrico", price = 20000, level = 4, item = "martelo_eletrico", img = "nui://ox_inventory/web/images/martelo_eletrico.png", desc = "2 Pancadas | 3 Pedras" },
        { id = 5, name = "Perfuradora Hidráulica", price = 50000, level = 5, item = "perfuradora", img = "nui://ox_inventory/web/images/perfuradora.png", desc = "2 Pancadas | 3 Pedras Fast" },
        { id = 6, name = "Picareta Mestra (OP)", price = 150000, level = 6, item = "picareta_mestra", img = "nui://ox_inventory/web/images/picareta_mestra.png", desc = "1 Pancada | 4 Pedras" }
    },

    Tasks = {
        { id = "miner_task_1", title = "Primeira Jornada", desc = "Minera as tuas primeiras 50 rochas.", goal = 50, type = "items", rewardXP = 200, rewardMoney = 500 },
        { id = "miner_task_2", title = "Braços de Aço", desc = "Minera 500 rochas.", goal = 500, type = "items", rewardXP = 1500, rewardMoney = 2500 },
        { id = "miner_task_3", title = "O Destruidor de Montanhas", desc = "Parte 2000 pedras.", goal = 2000, type = "items", rewardXP = 5000, rewardMoney = 10000 },
        { id = "miner_task_4", title = "Operário Focado", desc = "Completa 100 tarefas.", goal = 100, type = "tasks", rewardXP = 1000, rewardMoney = 3000 },
        { id = "miner_task_5", title = "Mestre das Profundezas", desc = "Minera 5000 rochas.", goal = 5000, type = "items", rewardXP = 15000, rewardMoney = 50000 },
        { id = "miner_task_6", title = "Lenda da Mineração", desc = "Minera 10000 rochas.", goal = 10000, type = "items", rewardXP = 50000, rewardMoney = 200000 }
    },

    Vehicles = {
        { name = "Sadler de Trabalho", model = "sadler", level = 1, price = 0, img = "img/miner/sadler.png" },
        { name = "Bison Mineiro", model = "bison", level = 2, price = 5000, img = "img/miner/bison.png" },
        { name = "Rubble Pesado", model = "rubble", level = 3, price = 15000, img = "img/miner/rubble.png" }
    }
}
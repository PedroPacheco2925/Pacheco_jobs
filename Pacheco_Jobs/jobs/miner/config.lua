ConfigMiner = {}

-- UI Settings (Aparência do Tablet)
ConfigMiner.UI = {
    JobTitle = "MINEIRO",
    JobSubtitle = "Apanhar Calhaus vai ser o teu main Job",
    RoleName = "Mineiro",
    BrandIcon = "fas fa-gem",
    
    Stat1 = { label = "Rocks Mined", icon = "fas fa-mountain" },
    Stat2 = { label = "Ores Processed", icon = "fas fa-box" },
    Stat3 = { label = "Gems Cut", icon = "fas fa-gem" },

    -- LOJA DE FERRAMENTAS (TOOLS)
    Tools = {
        { id = 1, name = "Picareta de Iniciação", price = 500, level = 1, item = "picareta_1", img = "https://cdn-icons-png.flaticon.com/512/2382/2382631.png", desc = "Ferramenta básica." },
        { id = 2, name = "Picareta Reforçada", price = 2500, level = 5, item = "picareta_2", img = "https://cdn-icons-png.flaticon.com/512/2382/2382631.png", desc = "Feita de aço." },
        { id = 3, name = "Picareta Industrial", price = 7500, level = 15, item = "picareta_3", img = "https://cdn-icons-png.flaticon.com/512/2382/2382631.png", desc = "Ponta de diamante." },
        { id = 4, name = "Martelo Elétrico", price = 20000, level = 30, item = "martelo_eletrico", img = "https://cdn-icons-png.flaticon.com/512/4243/4243301.png", desc = "Tecnologia de ponta." }
    },

    Tasks = {
        { id = "miner_task_1", title = "Primeira Jornada", desc = "Minera as tuas primeiras 50 rochas.", goal = 50, type = "items", rewardXP = 200, rewardMoney = 500 },
        { id = "miner_task_2", title = "Braços de Aço", desc = "Minera 500 rochas.", goal = 500, type = "items", rewardXP = 1500, rewardMoney = 2500 },
        { id = "miner_task_3", title = "O Destruidor de Montanhas", desc = "Parte 2000 pedras.", goal = 2000, type = "items", rewardXP = 5000, rewardMoney = 10000 },
        { id = "miner_task_4", title = "Operário Focado", desc = "Completa 100 tarefas.", goal = 100, type = "tasks", rewardXP = 1000, rewardMoney = 3000 }
    },

    -- GARAGEM (VEHICLES) - LINKS IMgur (Muito estáveis)
    Vehicles = {
        { 
            name = "Sadler de Trabalho", 
            model = "sadler", 
            level = 1, 
            price = 0, 
            img = "img/miner/sadler.png" 
        },
        { 
            name = "Bison Mineiro", 
            model = "bison", 
            level = 10, 
            price = 5000, 
            img = "img/miner/bison.png" 
        },
        { 
            name = "Rubble Pesado", 
            model = "rubble", 
            level = 25, 
            price = 15000, 
            img = "img/miner/rubble.png" 
        }
    }
}
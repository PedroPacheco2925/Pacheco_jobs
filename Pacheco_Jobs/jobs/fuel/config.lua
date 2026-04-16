ConfigFuel = {}
ConfigFuel.TruckModel = "phantom"
ConfigFuel.TrailerModel = "tanker"

ConfigFuel.VehicleSpawn = vector4(2733.0171, 1410.7804, 24.0317, 218.8217)
ConfigFuel.LoadLocation = vector3(2755.0100, 1366.0310, 24.5240) 
ConfigFuel.DeleteLocation = vector3(2733.0, 1410.7, 24.0)

-- ==========================================
-- SISTEMA DE PROGRESSÃO (OS 4 NÍVEIS)
-- ==========================================
ConfigFuel.Upgrades = {
    [1] = { capacity = 5000,   duration = 20000, rewardMult = 1.0 }, -- Lvl 1: 5k Litros | 20 Segundos | Lucro Normal
    [2] = { capacity = 20000,  duration = 15000, rewardMult = 1.0 }, -- Lvl 2: 20k Litros | 15 Segundos | Lucro Normal
    [3] = { capacity = 50000,  duration = 10000, rewardMult = 1.5 }, -- Lvl 3: 50k Litros | 10 Segundos | +50% Lucro
    [4] = { capacity = 100000, duration = 5000,  rewardMult = 2.0 }  -- Lvl 4: 100k Litros | 5 Segundos | Dobro do Lucro
}

ConfigFuel.GiantTanks = {
    model = "prop_gas_tank_02a", 
    coords = {
        vector4(2756.4363, 1362.2666, 24.5240, 89.0988),
        vector4(2756.4363, 1370.2666, 24.5240, 89.0988),
        vector4(299.8272, -1245.6025, 28.9536, 91.3384),
        vector4(-704.2218, -935.1902, 19.2119, 90.1627),
        vector4(1177.8168, -311.5482, 68.8736, 190.5333),
        vector4(1203.2611, 2641.8728, 37.4308, 228.3483),
        vector4(2700.8894, 3278.7246, 55.4560, 61.7464),
        vector4(203.4108, 6618.6440, 31.2308, 92.2754)
    }
}

ConfigFuel.DeliveryPoints = {
    { gas_station_name = "LTD Davis (Grove St)", liters_to_deposit = 2500, reward = 1500, coords = vector3(299.7328, -1249.7601, 29.4312) },
    { gas_station_name = "LTD Little Seoul", liters_to_deposit = 2500, reward = 1800, coords = vector3(-704.3403, -939.3323, 19.2119) },
    { gas_station_name = "LTD Mirror Park", liters_to_deposit = 2500, reward = 2000, coords = vector3(1181.9331, -310.8818, 69.1927) },
    { gas_station_name = "Bomba Sandy Shores", liters_to_deposit = 2500, reward = 2500, coords = vector3(1206.1716, 2644.7854, 37.8518) },
    { gas_station_name = "Bomba Harmony (Route 68)", liters_to_deposit = 2500, reward = 2800, coords = vector3(2698.6868, 3275.2112, 55.4448) },
    { gas_station_name = "Xero Paleto Bay", liters_to_deposit = 2500, reward = 3500, coords = vector3(203.2115, 6614.5645, 31.6483) }
}

ConfigFuel.UI = {
    JobTitle = "PETROGAL",
    JobSubtitle = "Distribuição de Combustíveis",
    RoleName = "Camionista",
    BrandIcon = "fas fa-truck-moving",
    Levels = { [1] = 0, [2] = 5000, [3] = 15000, [4] = 50000},
    Stat1 = { label = "Litros Entregues", icon = "fas fa-gas-pump" },
    Stat2 = { label = "Viagens Feitas", icon = "fas fa-route" },
    Stat3 = { label = "Lucro Gerado", icon = "fas fa-wallet" },
    Tools = {
        { id = 1, name = "Cartão Prata", price = 0, level = 1, item = "cartao_gasolina_prata", img = "nui://ox_inventory/web/images/cartao_gasolina_prata.png", desc = "5.000L | 20s" },
        { id = 2, name = "Cartão Ouro", price = 5000, level = 2, item = "cartao_gasolina_ouro", img = "nui://ox_inventory/web/images/cartao_gasolina_ouro.png", desc = "20.000L | 15s" },
        { id = 3, name = "Cartão Diamante", price = 15000, level = 3, item = "cartao_gasolina_diamante", img = "nui://ox_inventory/web/images/cartao_gasolina_diamante.png", desc = "50.000L | 10s | +50% Lucro" },
        { id = 4, name = "Cartão Black", price = 50000, level = 4, item = "cartao_gasolina_black", img = "nui://ox_inventory/web/images/cartao_gasolina_black.png", desc = "100.000L | 5s | +100% Lucro" },
    },
    Vehicles = {
        { name = "Phantom Cisterna", model = "phantom", level = 1, price = 0, img = "img/fuel/phantom.png" },
    },
    Tasks = {
        { id = "fuel_task_1", title = "Estagiário", desc = "Entrega 10.000 Litros.", goal = 10000, type = "items", rewardXP = 500, rewardMoney = 1000 },
    }
}
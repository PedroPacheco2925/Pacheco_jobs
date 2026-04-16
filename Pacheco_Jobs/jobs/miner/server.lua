local ESX = exports["es_extended"]:getSharedObject()
local comprasCooldown = {}

-- ==========================================
-- 1. RECOMPENSA DA MINERAÇÃO (LOG: Miner_apanha)
-- ==========================================
RegisterNetEvent('pacheco_jobs:miner:receberRecompensa')
AddEventHandler('pacheco_jobs:miner:receberRecompensa', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local rewards = ConfigMiner.Rewards
    local levelTable = ConfigMiner.UI.Levels 

    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        local itemAmount = 2 
        
        -- Lógica de picaretas (Baseado no inventário)
        if exports.ox_inventory:Search(src, 'count', 'picareta_mestra') > 0 then itemAmount = 4
        elseif exports.ox_inventory:Search(src, 'count', 'perfuradora') > 0 or exports.ox_inventory:Search(src, 'count', 'martelo_eletrico') > 0 then itemAmount = 3 end

        xPlayer.addInventoryItem('stone', itemAmount)

        -- LOG PACHECO: Mineração
        exports.pacheco_logs:SendLog('Miner_apanha', '⛏️ Mineração', ("**%s** (ID: %s) extraiu **%sx Pedra Bruta**"):format(xPlayer.getName(), identifier, itemAmount), 5763719)

        MySQL.query('SELECT skill_points, level FROM pacheco_jobs_stats WHERE identifier = ? AND job_name = "miner"', {identifier}, function(result)
            if result and result[1] then
                local currentXP = result[1].skill_points or 0
                local currentLevel = result[1].level or 1
                local newXP = currentXP + rewards.xpPerHit
                local newLevel = 1 
                for lvl = 1, 6 do if levelTable[lvl] and newXP >= levelTable[lvl] then newLevel = lvl end end
                
                local leveledUp = (newLevel > currentLevel)
                MySQL.update('UPDATE pacheco_jobs_stats SET total_items = total_items + ?, skill_points = ?, level = ? WHERE identifier = ? AND job_name = "miner"', 
                {itemAmount, newXP, newLevel, identifier}, function()
                    TriggerClientEvent('esx:showNotification', src, "Extraíste ~g~" .. itemAmount .. "x Pedra~s~ e ganhaste ~b~" .. rewards.xpPerHit .. " XP~s~.")
                    if leveledUp then
                        TriggerClientEvent('esx:showNotification', src, "~y~LEVEL UP!~s~ Agora és ~b~Nível " .. newLevel)
                        TriggerClientEvent('PlaySoundFrontend', src, "Challenge_Unlocked", "DLC_VW_Casino_Interior_Sounds", 1)
                    end
                end)
            end
        end)
    end
end)

-- ==========================================
-- 2. PROCESSO DE LAVAGEM (LOG: Miner_limpeza)
-- ==========================================
RegisterServerEvent('pacheco_jobs:miner:lavarPedra')
AddEventHandler('pacheco_jobs:miner:lavarPedra', function(quantity)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or xPlayer.getInventoryItem("stone").count < quantity then return end

    local rewardAmount = math.floor(quantity / 2) 
    xPlayer.removeInventoryItem("stone", quantity)
    xPlayer.addInventoryItem("washed_stone", rewardAmount)
    
    -- LOG PACHECO: Lavagem
    exports.pacheco_logs:SendLog('Miner_limpeza', '💧 Lavagem', ("**%s** lavou %sx brutas e recebeu %sx lavadas"):format(xPlayer.getName(), quantity, rewardAmount), 3447003)

    MySQL.update('UPDATE pacheco_jobs_stats SET processed_items = processed_items + ? WHERE identifier = ? AND job_name = "miner"', 
    {rewardAmount, xPlayer.getIdentifier()})
end)

-- ==========================================
-- 3. FUNDIÇÃO (LOG: Miner_fundição)
-- ==========================================
RegisterServerEvent('pacheco_jobs:miner:fundirPedra')
AddEventHandler('pacheco_jobs:miner:fundirPedra', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or xPlayer.getInventoryItem("washed_stone").count < 1 then return end

    xPlayer.removeInventoryItem("washed_stone", 1)
    local chance = math.random(1, 100)
    local wonItem, qty, label = "copper", 2, "Cobre"

    if chance <= 35 then wonItem, qty, label = "copper", 3, "Cobre"
    elseif chance <= 60 then wonItem, qty, label = "iron", 2, "Ferro"
    elseif chance <= 75 then wonItem, qty, label = "silver", 2, "Prata"
    elseif chance <= 88 then wonItem, qty, label = "gold", 1, "Ouro"
    elseif chance <= 96 then wonItem, qty, label = "diamond", 1, "Diamante"
    else wonItem, qty, label = "metal", 1, "Metal Raro" end

    xPlayer.addInventoryItem(wonItem, qty)
    
    -- LOG PACHECO: Fundição
    exports.pacheco_logs:SendLog('Miner_fundição', '🔥 Fundição', ("**%s** obteve %sx %s"):format(xPlayer.getName(), qty, label), 15105570)
    
    -- Atualizar JSON smelted_counts
    MySQL.query('SELECT smelted_counts FROM pacheco_jobs_stats WHERE identifier = ? AND job_name = "miner"', {xPlayer.getIdentifier()}, function(result)
        local counts = {}
        if result and result[1] and result[1].smelted_counts then
            local data = result[1].smelted_counts
            counts = (type(data) == "string" and json.decode(data) or data) or {}
        end
        counts[wonItem] = (counts[wonItem] or 0) + qty
        MySQL.update('UPDATE pacheco_jobs_stats SET smelted_counts = ? WHERE identifier = ? AND job_name = "miner"', {json.encode(counts), xPlayer.getIdentifier()})
    end)

    TriggerClientEvent('esx:showNotification', src, "🔥 Obtiveste ~y~" .. qty .. "x " .. label)
end)

-- ==========================================
-- 4. PROCESSO DE VENDA (LOG: Miner_venda)
-- ==========================================
RegisterServerEvent('pacheco_jobs:miner:venderItem')
AddEventHandler('pacheco_jobs:miner:venderItem', function(itemName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or amount <= 0 then return end

    local price = 0
    local label = itemName
    for _, item in ipairs(ConfigMiner.Selling.Items) do if item.name == itemName then price = item.price label = item.label break end end
    
    if xPlayer.getInventoryItem(itemName).count >= amount then
        local total = amount * price
        xPlayer.removeInventoryItem(itemName, amount)
        xPlayer.addMoney(total) 

        -- LOG PACHECO: Venda
        exports.pacheco_logs:SendLog('Miner_venda', '💰 Venda', ("**%s** vendeu %sx %s por $%s"):format(xPlayer.getName(), amount, label, total), 3066993)

        -- Atualizar JSON sold_counts e lucro
        MySQL.query('SELECT sold_counts FROM pacheco_jobs_stats WHERE identifier = ? AND job_name = "miner"', {xPlayer.getIdentifier()}, function(result)
            local sold = {}
            if result and result[1] and result[1].sold_counts then
                local data = result[1].sold_counts
                sold = (type(data) == "string" and json.decode(data) or data) or {}
            end
            sold[itemName] = (sold[itemName] or 0) + amount
            MySQL.update('UPDATE pacheco_jobs_stats SET total_money_earned = total_money_earned + ?, sold_counts = ? WHERE identifier = ? AND job_name = "miner"', {total, json.encode(sold), xPlayer.getIdentifier()})
        end)
    end
end)

-- ==========================================
-- 5. COMPRA NO TABLET (COOLDOWN UNIFICADO)
-- ==========================================
RegisterNetEvent("pacheco_jobs:server:buyTool")
AddEventHandler("pacheco_jobs:server:buyTool", function(itemName, price)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if comprasCooldown[src] and (GetGameTimer() - comprasCooldown[src] < 2000) then return end
    comprasCooldown[src] = GetGameTimer()

    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
        xPlayer.addInventoryItem(itemName, 1)
        TriggerClientEvent('esx:showNotification', src, "~g~Compraste ~y~" .. itemName .. "~w~ por ~g~$" .. price)
    else
        TriggerClientEvent('esx:showNotification', src, "~r~Dinheiro insuficiente.")
    end
end)

-- ==========================================
-- 6. PROTEÇÃO OX INVENTORY (LOG: Miner_ferramentas)
-- ==========================================
local protected = { picareta = true, picareta_2 = true, picareta_3 = true, martelo_eletrico = true, perfuradora = true, picareta_mestra = true }
exports.ox_inventory:registerHook('swapItems', function(payload)
    if payload.fromInventory == payload.toInventory then return true end
    local src = payload.source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        exports.pacheco_logs:SendLog('Ferramentas_Trabalho', '🚫 Troca', ("**%s** tentou passar ferramenta: **%s**"):format(xPlayer.getName(), payload.item.name), 15158332)
    end
    TriggerClientEvent('esx:showNotification', src, "~r~Equipamento propriedade da empresa!")
    return false 
end, { itemFilter = protected })
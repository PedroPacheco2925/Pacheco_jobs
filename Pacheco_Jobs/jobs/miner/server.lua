local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- RECOMPENSA DA MINERAÇÃO (COM XP)
-- ==========================================
RegisterNetEvent('pacheco_jobs:miner:receberRecompensa')
AddEventHandler('pacheco_jobs:miner:receberRecompensa', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local rewards = ConfigMiner.Rewards
    local levelTable = ConfigMiner.UI.Levels 

    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        xPlayer.addInventoryItem('stone', rewards.itemAmount)

        MySQL.query('SELECT skill_points, level FROM pacheco_jobs_stats WHERE identifier = ? AND job_name = ?', {identifier, rewards.jobName}, function(result)
            if result and result[1] then
                local currentXP = result[1].skill_points
                local currentLevel = result[1].level
                local newXP = currentXP + rewards.xpPerHit
                local newLevel = 1 
                local leveledUp = false

                local levelsSorted = {1, 2, 3, 4}
                for _, lvl in ipairs(levelsSorted) do
                    if newXP >= levelTable[lvl] then newLevel = lvl end
                end
                if newLevel > currentLevel then leveledUp = true end

                MySQL.update('UPDATE pacheco_jobs_stats SET total_items = total_items + ?, skill_points = ?, level = ? WHERE identifier = ? AND job_name = ?', 
                {rewards.itemAmount, newXP, newLevel, identifier, rewards.jobName}, function()
                    TriggerClientEvent('esx:showNotification', src, "Extraíste ~g~" .. rewards.itemAmount .. "x Pedra~s~ e ganhaste ~b~" .. rewards.xpPerHit .. " XP~s~.")
                    if leveledUp then
                        TriggerClientEvent('esx:showNotification', src, "~y~LEVEL UP!~s~ Agora és ~b~Nível " .. newLevel .. "~s~.")
                        TriggerClientEvent('PlaySoundFrontend', src, "Challenge_Unlocked", "DLC_VW_Casino_Interior_Sounds", 1)
                    end
                end)
            end
        end)
    end
end)

-- ==========================================
-- PROCESSO DE LAVAGEM (TIRA 2 SUJAS -> DÁ 1 LIMPA)
-- ==========================================
RegisterServerEvent('pacheco_jobs:miner:lavarPedra')
AddEventHandler('pacheco_jobs:miner:lavarPedra', function(quantity)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local itemSujo = "stone" 
    local itemLavado = "washed_stone"

    if xPlayer.getInventoryItem(itemSujo).count >= quantity then
        local rewardAmount = math.floor(quantity / 2) 
        xPlayer.removeInventoryItem(itemSujo, quantity)
        xPlayer.addInventoryItem(itemLavado, rewardAmount)
        
        TriggerClientEvent('esx:showNotification', src, "Lavaste ~b~" .. quantity .. " pedras sujas~s~ e obtiveste ~g~" .. rewardAmount .. " limpa~s~.")
        MySQL.update('UPDATE pacheco_jobs_stats SET processed_items = processed_items + ? WHERE identifier = ? AND job_name = ?', {rewardAmount, xPlayer.getIdentifier(), "miner"})
    else
        TriggerClientEvent('esx:showNotification', src, "~r~Não tens pedras suficientes para o par!")
    end
end)

-- ==========================================
-- PROCESSO DE FUNDIÇÃO (PROBABILIDADES)
-- ==========================================
RegisterServerEvent('pacheco_jobs:miner:fundirPedra')
AddEventHandler('pacheco_jobs:miner:fundirPedra', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local itemGasto = ConfigMiner.Smelting.ItemNecessario
    local qtyNecessaria = ConfigMiner.Smelting.QuantidadeNecessaria

    if xPlayer.getInventoryItem(itemGasto).count >= qtyNecessaria then
        xPlayer.removeInventoryItem(itemGasto, qtyNecessaria)

        local chance = math.random(1, 100)
        local wonItem, amountToGive, notifyName = "", 0, ""

        if chance <= 45 then 
            wonItem, amountToGive, notifyName = "copper", 3, "Cobre"
        elseif chance <= 75 then 
            wonItem, amountToGive, notifyName = "iron", 2, "Ferro"
        elseif chance <= 95 then 
            wonItem, amountToGive, notifyName = "gold", 1, "Ouro"
        else 
            wonItem, amountToGive, notifyName = "diamond", 1, "Diamante"
        end

        xPlayer.addInventoryItem(wonItem, amountToGive)
        MySQL.update('UPDATE pacheco_jobs_stats SET gems_cut = gems_cut + ? WHERE identifier = ? AND job_name = ?', {1, xPlayer.getIdentifier(), "miner"})

        if wonItem == "diamond" then
            TriggerClientEvent('esx:showNotification', src, "🔥 BINGO! Obtiveste ~b~" .. amountToGive .. "x " .. notifyName .. "~s~!")
        else
            TriggerClientEvent('esx:showNotification', src, "🔥 Obtiveste ~y~" .. amountToGive .. "x " .. notifyName .. "~s~.")
        end
    else
        TriggerClientEvent('esx:showNotification', src, "~r~Erro: Não tens pedras limpas.")
    end
end)

-- ==========================================
-- PROCESSO DE VENDA (LOJA)
-- ==========================================
RegisterServerEvent('pacheco_jobs:miner:venderItem')
AddEventHandler('pacheco_jobs:miner:venderItem', function(itemName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if amount == nil or amount <= 0 then return end

    -- Procurar preço na config
    local itemConfig = nil
    for _, item in ipairs(ConfigMiner.Selling.Items) do
        if item.name == itemName then 
            itemConfig = item 
            break 
        end
    end

    if not itemConfig then return end

    local playerItem = xPlayer.getInventoryItem(itemName)
    
    if playerItem and playerItem.count >= amount then
        local totalGanhos = amount * itemConfig.price

        -- Tira o item e dá o dinheiro (Usa 'money' para dinheiro vivo ou 'bank' para banco)
        xPlayer.removeInventoryItem(itemName, amount)
        xPlayer.addMoney(totalGanhos) 

        TriggerClientEvent('esx:showNotification', src, "Vendeste ~y~" .. amount .. "x " .. itemConfig.label .. "~s~ por ~g~$" .. totalGanhos .. "~s~.")
    else
        TriggerClientEvent('esx:showNotification', src, "~r~Não tens essa quantidade de " .. itemConfig.label .. "!")
    end
end)

-- ==========================================
-- BLOQUEIO DE TRANSFERÊNCIA (OX INVENTORY)
-- ==========================================
local protectedItems = { picareta = true, picareta_2 = true, picareta_3 = true, martelo_eletrico = true }
exports.ox_inventory:registerHook('swapItems', function(payload)
    if payload.fromInventory == payload.toInventory then return true end
    TriggerClientEvent('esx:showNotification', payload.source, "~r~Este equipamento é propriedade da empresa!")
    return false 
end, { itemFilter = protectedItems })
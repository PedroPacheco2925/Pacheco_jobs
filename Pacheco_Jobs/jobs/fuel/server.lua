local ESX = exports["es_extended"]:getSharedObject()

-- PAGAMENTO E LOGS
RegisterServerEvent('pacheco_jobs:fuel:receberPagamento')
AddEventHandler('pacheco_jobs:fuel:receberPagamento', function(stationName, reward, liters)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    xPlayer.addMoney(reward)
    exports.pacheco_logs:SendLog('Fuel_Entrega', '⛽ Camionista', ("**%s** entregou **%sL** na **%s** por **$%s**"):format(xPlayer.getName(), liters, stationName, reward), 3447003)

    local identifier = xPlayer.getIdentifier()
    MySQL.query('SELECT sold_counts, skill_points FROM pacheco_jobs_stats WHERE identifier = ? AND job_name = "fuel_driver"', {identifier}, function(result)
        if result and result[1] then
            local sold = (type(result[1].sold_counts) == "string" and json.decode(result[1].sold_counts) or result[1].sold_counts) or {}
            sold[stationName] = (sold[stationName] or 0) + liters
            local newXP = (result[1].skill_points or 0) + 300

            MySQL.update([[
                UPDATE pacheco_jobs_stats 
                SET total_items = total_items + ?, processed_items = processed_items + 1, total_money_earned = total_money_earned + ?, skill_points = ?, sold_counts = ? 
                WHERE identifier = ? AND job_name = "fuel_driver"
            ]], {liters, reward, newXP, json.encode(sold), identifier})
        end
    end)
end)

-- CALLBACK PARA O TABLET (XP E NÍVEL DA BD)
ESX.RegisterServerCallback('pacheco_jobs:getServerData', function(source, cb, jobName)
    if jobName ~= 'fuel_driver' then return end
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.query('SELECT * FROM pacheco_jobs_stats WHERE identifier = ? AND job_name = "fuel_driver"', {xPlayer.getIdentifier()}, function(result)
        if result and result[1] then
            local s = result[1]
            cb({ name = xPlayer.getName(), level = s.level or 1, skillsPoints = s.skill_points or 0, totalItems = s.total_items or 0, processed_items = s.processed_items or 0, gems_cut = s.total_money_earned or 0, claimedTasks = json.decode(s.claimed_tasks or "[]") })
        else
            MySQL.insert('INSERT INTO pacheco_jobs_stats (identifier, job_name) VALUES (?, "fuel_driver")', {xPlayer.getIdentifier()})
            cb({ name = xPlayer.getName(), level = 1, skillsPoints = 0, totalItems = 0, processed_items = 0, gems_cut = 0, claimedTasks = {} })
        end
    end)
end)

-- ==========================================
-- NOVO: CALLBACK PARA LER OS CARTÕES DO INVENTÁRIO
-- ==========================================
ESX.RegisterServerCallback('pacheco_jobs:fuel:checkCards', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(1) return end

    local userLevel = 1 -- Por defeito é o nível 1 (Prata)

    -- Verifica do melhor (4) para o pior (1)
    if xPlayer.getInventoryItem('cartao_gasolina_black') and xPlayer.getInventoryItem('cartao_gasolina_black').count > 0 then
        userLevel = 4
    elseif xPlayer.getInventoryItem('cartao_gasolina_diamante') and xPlayer.getInventoryItem('cartao_gasolina_diamante').count > 0 then
        userLevel = 3
    elseif xPlayer.getInventoryItem('cartao_gasolina_ouro') and xPlayer.getInventoryItem('cartao_gasolina_ouro').count > 0 then
        userLevel = 2
    elseif xPlayer.getInventoryItem('cartao_gasolina_prata') and xPlayer.getInventoryItem('cartao_gasolina_prata').count > 0 then
        userLevel = 1
    end

    cb(userLevel)
end)
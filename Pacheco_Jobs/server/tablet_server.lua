local ESX = exports["es_extended"]:getSharedObject()

-- Dashboard Data
ESX.RegisterServerCallback('pacheco_jobs:getServerData', function(source, cb, jobName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end
    local identifier = xPlayer.getIdentifier()

    MySQL.query('SELECT * FROM pacheco_jobs_stats WHERE identifier = ? AND job_name = ?', {identifier, jobName}, function(result)
        if result and result[1] then
            local stats = result[1]
            local claimed = stats.claimed_tasks and json.decode(stats.claimed_tasks) or {}
            cb({
                name = xPlayer.getName(),
                level = stats.level or 1,
                skillsPoints = stats.skill_points or 0,
                totalItems = stats.total_items or 0,
                totalTasks = stats.total_tasks or 0,
                claimedTasks = claimed
            })
        else cb(nil) end
    end)
end)

-- Leaderboard
ESX.RegisterServerCallback('pacheco_jobs:getLeaderboard', function(source, cb, jobName)
    MySQL.query([[
        SELECT s.total_items, s.level, u.firstname, u.lastname 
        FROM pacheco_jobs_stats s 
        LEFT JOIN users u ON s.identifier = u.identifier 
        WHERE s.job_name = ? 
        ORDER BY s.total_items DESC LIMIT 10
    ]], {jobName}, function(results)
        local leaderboard = {}
        for i=1, #results do
            local name = (results[i].firstname and results[i].lastname) and (results[i].firstname .. " " .. results[i].lastname) or "Desconhecido"
            table.insert(leaderboard, { name = name, stat = results[i].total_items or 0, level = results[i].level or 1 })
        end
        cb(leaderboard)
    end)
end)

-- Compras e Recompensas
RegisterNetEvent("pacheco_jobs:server:buyTool")
AddEventHandler("pacheco_jobs:server:buyTool", function(itemName, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
        xPlayer.addInventoryItem(itemName, 1)
        TriggerClientEvent('esx:showNotification', source, "~g~Compraste ~y~" .. itemName .. "~w~ por ~g~$" .. price)
    else
        TriggerClientEvent('esx:showNotification', source, "~r~Dinheiro insuficiente.")
    end
end)

RegisterNetEvent("pacheco_jobs:server:claimTask")
AddEventHandler("pacheco_jobs:server:claimTask", function(taskId, jobName, xpReward, moneyReward)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.getIdentifier()

    MySQL.query('SELECT claimed_tasks FROM pacheco_jobs_stats WHERE identifier = ? AND job_name = ?', {identifier, jobName}, function(result)
        if result and result[1] then
            local claimed = result[1].claimed_tasks and json.decode(result[1].claimed_tasks) or {}
            for _, id in pairs(claimed) do if id == taskId then return end end -- Anti-exploit

            table.insert(claimed, taskId)
            MySQL.update('UPDATE pacheco_jobs_stats SET claimed_tasks = ? WHERE identifier = ? AND job_name = ?', {json.encode(claimed), identifier, jobName})
            xPlayer.addMoney(moneyReward)
            TriggerClientEvent('esx:showNotification', src, "~y~Recompensa:~g~ $" .. moneyReward .. " ~w~e ~b~" .. xpReward .. " XP!")
        end
    end)
end)
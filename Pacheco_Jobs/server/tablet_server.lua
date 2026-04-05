local ESX = exports["es_extended"]:getSharedObject()

-- Dashboard Data
ESX.RegisterServerCallback('pacheco_jobs:getServerData', function(source, cb, jobName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end
    local identifier = xPlayer.getIdentifier()

    MySQL.query('SELECT * FROM pacheco_jobs_stats WHERE identifier = ? AND job_name = ?', {identifier, jobName}, function(result)
        if result and result[1] then
            local stats = result[1]
            cb({
                name = xPlayer.getName(),
                level = stats.level or 1,
                skillsPoints = stats.skill_points or 0,
                totalItems = stats.total_items or 0,
                totalTasks = stats.total_tasks or 0,
                totalEarned = 0, xp = 0
            })
        else cb(nil) end
    end)
end)

-- Leaderboard Data (CORRIGIDO)
ESX.RegisterServerCallback('pacheco_jobs:getLeaderboard', function(source, cb, jobName)
    print("^3[SERVER]^7 Pedido de Leaderboard recebido para: " .. tostring(jobName))
    
    MySQL.query([[
        SELECT 
            s.total_items, 
            s.level, 
            u.firstname, 
            u.lastname 
        FROM pacheco_jobs_stats s 
        LEFT JOIN users u ON s.identifier = u.identifier 
        WHERE s.job_name = ? 
        ORDER BY s.total_items DESC 
        LIMIT 10
    ]], {jobName}, function(results)
        local leaderboard = {}
        
        if results and #results > 0 then
            for i=1, #results do
                local name = "Desconhecido"
                if results[i].firstname and results[i].lastname then
                    name = results[i].firstname .. " " .. results[i].lastname
                end
                
                table.insert(leaderboard, {
                    name = name,
                    stat = results[i].total_items or 0,
                    level = results[i].level or 1
                })
            end
            print("^2[SERVER]^7 A enviar " .. #leaderboard .. " resultados para o cliente.")
            cb(leaderboard)
        else
            print("^1[SERVER]^7 Nenhuns dados encontrados para " .. tostring(jobName))
            cb({}) 
        end
    end)
end)
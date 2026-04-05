local ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('pacheco_jobs:server:assinouContrato')
AddEventHandler('pacheco_jobs:server:assinouContrato', function(jobId, jobLabel)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if jobId == 'unemployed' then
        xPlayer.setJob('unemployed', 0)
        xPlayer.showNotification("~y~Agora estás desempregado.")
        return
    end

    if ESX.DoesJobExist(jobId, 0) then
        xPlayer.setJob(jobId, 0)
        xPlayer.showNotification("~g~Contrato assinado:~w~ Agora és ~y~" .. jobLabel)
        
        local identifier = xPlayer.getIdentifier()
        MySQL.insert([[
            INSERT IGNORE INTO pacheco_jobs_stats 
            (identifier, job_name, level, skill_points, total_items, total_tasks) 
            VALUES (?, ?, 1, 0, 0, 0)
        ]], {identifier, jobId})
    else
        xPlayer.showNotification("~r~Erro:~w~ Job inválido.")
    end
end)
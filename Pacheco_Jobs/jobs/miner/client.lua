RegisterNetEvent('pacheco_jobs:client:requestTabletOpen')
AddEventHandler('pacheco_jobs:client:requestTabletOpen', function(jobName)
    
    if jobName == 'miner' then
        print("^2[JOB MINEIRO]^7 A enviar dados dinâmicos da UI para a Base...")
        
        -- Enviamos a tabela inteira do ConfigMiner.UI!
        TriggerEvent('pacheco_jobs:client:forceOpenTablet', 'miner', ConfigMiner.UI)
    end

end)
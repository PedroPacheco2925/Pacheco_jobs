local ESX = exports["es_extended"]:getSharedObject()
local tabletAberto = false

-- Loop do Marcador e Tecla E
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        for job, info in pairs(Config.TabletLocations) do
            local dist = #(coords - info.coords)
            if dist < 10.0 then
                sleep = 0
                DrawMarker(2, info.coords.x, info.coords.y, info.coords.z, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 0, 123, 255, 150, false, true, 2, false, nil, nil, false)
                if dist < info.distanceToOpen and not tabletAberto then
                    ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para abrir o Tablet")
                    if IsControlJustReleased(0, 38) then
                        -- Envia para o ficheiro do job específico abrir
                        TriggerEvent('pacheco_jobs:client:requestTabletOpen', job)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Evento que abre a UI
RegisterNetEvent('pacheco_jobs:client:forceOpenTablet')
AddEventHandler('pacheco_jobs:client:forceOpenTablet', function(jobName, jobConfig)
    ESX.TriggerServerCallback('pacheco_jobs:getServerData', function(dbData)
        if dbData then
            tabletAberto = true
            SetNuiFocus(true, true)
            
            SendNUIMessage({
                action = "openTablet",
                data = dbData,
                config = jobConfig,
                jobName = jobName
            })
        else
            ESX.ShowNotification("~r~Erro:~w~ Não tens contrato ativo.")
        end
    end, jobName)
end)

-- Callbacks NUI
RegisterNUICallback("close", function(data, cb)
    tabletAberto = false
    SetNuiFocus(false, false)
    cb("ok")
end)

-- CALLBACK DA LEADERBOARD (O QUE ESTAVA A FALHAR)
RegisterNUICallback("getLeaderboard", function(data, cb)
    print("^2[CLIENT]^7 A pedir ranking para o job: " .. tostring(data.job))
    ESX.TriggerServerCallback('pacheco_jobs:getLeaderboard', function(results)
        print("^2[CLIENT]^7 Recebi " .. #results .. " jogadores do servidor.")
        cb(results)
    end, data.job)
end)

RegisterNUICallback("selectJob", function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('pacheco_jobs:server:assinouContrato', data.jobId, data.jobLabel)
    cb("ok")
end)

RegisterNUICallback("closeJobCenter", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("claimTask", function(data, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return cb("error") end

    -- Dá o dinheiro da recompensa ao jogador
    if data.money and data.money > 0 then
        xPlayer.addMoney(data.money) -- ou addAccountMoney('bank', data.money)
    end

    -- INFO: Como o teu sistema de XP ainda não me foi mostrado onde é guardado,
    -- por agora vou apenas enviar uma notificação. Depois terás de ligar isto à tua DB de Stats.
    TriggerClientEvent('esx:showNotification', src, "~y~[CONQUISTA]~w~ Recebeste ~g~$" .. data.money .. "~w~ e ~b~" .. data.xp .. " XP~w~!")
    
    cb("ok")
end)
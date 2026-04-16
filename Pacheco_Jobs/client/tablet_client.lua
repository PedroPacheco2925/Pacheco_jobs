local ESX = exports["es_extended"]:getSharedObject()
local tabletAberto = false

-- ==========================================
-- 1. BLIPS E MARCADORES DOS TABLETS
-- ==========================================
CreateThread(function()
    -- Criar os Blips dos Tablets no Mapa
    if Config.TabletLocations then
        for job, info in pairs(Config.TabletLocations) do
            if info.blip and info.blip.enabled then
                local blip = AddBlipForCoord(info.coords)
                SetBlipSprite(blip, info.blip.sprite)
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, info.blip.scale)
                SetBlipColour(blip, info.blip.color)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(info.blip.label)
                EndTextCommandSetBlipName(blip)
            end
        end
    end

    -- Loop do Marcador 3D no chão para os Tablets
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        if Config.TabletLocations then
            for job, info in pairs(Config.TabletLocations) do
                local dist = #(coords - info.coords)
                if dist < 10.0 then
                    sleep = 0
                    DrawMarker(2, info.coords.x, info.coords.y, info.coords.z, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 0, 123, 255, 150, false, true, 2, false, nil, nil, false)
                    
                    if dist < info.distanceToOpen and not tabletAberto then
                        ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para abrir o Tablet")
                        if IsControlJustReleased(0, 38) then
                            -- Chama o script do job específico para validar e abrir
                            TriggerEvent('pacheco_jobs:client:requestTabletOpen', job)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ==========================================
-- 2. ABRIR UI E CALLBACKS (HTML)
-- ==========================================

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

RegisterNUICallback("close", function(data, cb)
    tabletAberto = false
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("getLeaderboard", function(data, cb)
    ESX.TriggerServerCallback('pacheco_jobs:getLeaderboard', function(results) cb(results) end, data.job)
end)

RegisterNUICallback("buyTool", function(data, cb)
    TriggerServerEvent("pacheco_jobs:server:buyTool", data.item, data.price)
    cb("ok")
end)

RegisterNUICallback("claimTask", function(data, cb)
    TriggerServerEvent("pacheco_jobs:server:claimTask", data.taskId, data.jobName, data.xp, data.money)
    cb("ok")
end)

RegisterNUICallback("spawnVehicle", function(data, cb)
    tabletAberto = false
    SetNuiFocus(false, false)

    -- SEGURANÇA: Verificamos o emprego diretamente pelo ESX em vez de confiar no NUI/HTML
    local playerData = ESX.GetPlayerData()
    local myJob = nil
    if playerData and playerData.job then
        myJob = playerData.job.name
    end

    -- Se for o camionista, chamamos a função especial que criámos no script do camionista
    if myJob == 'fuel_driver' then
        TriggerEvent('pacheco_jobs:fuel:spawnEspecial')
    else
        -- Spawn básico para os outros jobs (Mineiro, etc.)
        local model = data.model
        local playerPed = PlayerPedId()
        local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
        local heading = GetEntityHeading(playerPed)

        ESX.Game.SpawnVehicle(model, coords, heading, function(vehicle)
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
            ESX.ShowNotification("~g~Veículo retirado com sucesso!")
        end)
    end
    
    cb("ok")
end)
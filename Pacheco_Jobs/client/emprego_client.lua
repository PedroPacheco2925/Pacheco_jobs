local ESX = exports["es_extended"]:getSharedObject()
local menuAberto = false

-- ==========================================
-- 1. BLIP E MARCADOR DO CENTRO DE EMPREGO
-- ==========================================
CreateThread(function()
    -- Criar o Blip no Mapa (City Hall)
    if Config.JobCenter and Config.JobCenter.blip and Config.JobCenter.blip.enabled then
        local blip = AddBlipForCoord(Config.JobCenter.coords)
        SetBlipSprite(blip, Config.JobCenter.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.JobCenter.blip.scale)
        SetBlipColour(blip, Config.JobCenter.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.JobCenter.blip.label)
        EndTextCommandSetBlipName(blip)
    end

    -- Loop do Marcador e Tecla E
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        if Config.JobCenter and Config.JobCenter.coords then
            local dist = #(coords - Config.JobCenter.coords)
            if dist < 10.0 then
                sleep = 0
                -- Marcador Cilindro no chão
                DrawMarker(1, Config.JobCenter.coords.x, Config.JobCenter.coords.y, Config.JobCenter.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0.5, 255, 165, 0, 150, false, false, 2, false, nil, nil, false)
                
                if dist < Config.JobCenter.distanceToOpen and not menuAberto then
                    ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para ver os Empregos")
                    if IsControlJustReleased(0, 38) then -- Tecla E
                        TriggerEvent('pacheco_jobs:client:openJobCenter')
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ==========================================
-- 2. EVENTO PARA ABRIR A UI
-- ==========================================
RegisterNetEvent('pacheco_jobs:client:openJobCenter')
AddEventHandler('pacheco_jobs:client:openJobCenter', function()
    if not menuAberto then
        menuAberto = true
        SetNuiFocus(true, true)
        
        -- DEBUG: Se isto aparecer no F8, o Lua enviou bem
        print("^2[JOBS]^7 A abrir Centro de Emprego com " .. #Config.AvailableJobs .. " trabalhos.")
        
        SendNUIMessage({
            action = "openJobCenter",
            jobs = Config.AvailableJobs
        })
    end
end)

-- Callbacks para fechar
RegisterNUICallback("closeJobCenter", function(data, cb)
    menuAberto = false
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("selectJob", function(data, cb)
    menuAberto = false
    SetNuiFocus(false, false)
    TriggerServerEvent('pacheco_jobs:server:assinouContrato', data.jobId, data.jobLabel)
    cb("ok")
end)
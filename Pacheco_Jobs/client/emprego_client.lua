-- client/emprego_client.lua

local ESX = exports["es_extended"]:getSharedObject()

-- 1. Criar o Blip do Centro de Emprego
CreateThread(function()
    if Config.JobCenter and Config.JobCenter.blip.enabled then
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
end)

-- 2. Loop para detetar o jogador perto do Centro de Emprego
CreateThread(function()
    while true do
        local sleep = 1000
        if Config.JobCenter then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - Config.JobCenter.coords)

            if dist < 10.0 then
                sleep = 0
                -- Marcador no chão
                DrawMarker(29, Config.JobCenter.coords.x, Config.JobCenter.coords.y, Config.JobCenter.coords.z, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 50, 150, 250, 150, false, true, 2, false, nil, nil, false)

                if dist < Config.JobCenter.distanceToOpen then
                    ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para abrir o Painel de Empregos")
                    
                    if IsControlJustReleased(0, 38) then
                        -- APENAS ABRE A NOSSA NUI (TABLET NOVO)
                        AbrirTabletEmpregos()
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- 3. Função para abrir o nosso Tablet de Empregos
function AbrirTabletEmpregos()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openJobCenter",
        jobs = Config.AvailableJobs
    })
end

-- =========================================
-- CALLBACKS (LIGAÇÃO JS -> LUA)
-- =========================================

-- Fecha a NUI quando clicas em Close ou ESC
RegisterNUICallback("closeJobCenter", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Quando escolhes um job no nosso Tablet
RegisterNUICallback("selectJob", function(data, cb)
    SetNuiFocus(false, false)
    -- Envia para o servidor mudar o teu job e criar a linha na DB
    TriggerServerEvent('pacheco_jobs:server:assinouContrato', data.jobId, data.jobLabel)
    cb("ok")
end)

-- Callback genérico de fechar (usado pelo tablet normal também)
RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)
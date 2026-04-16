local ESX = exports["es_extended"]:getSharedObject()
local PlayerJob = {}
local camiaoAtual, cisternaAtual = nil, nil
local cargaNaCisterna = 0
local pontoEntregaAtivo, blipEntrega = nil, nil
local uiAberta = false
local blipCarga, blipGaragem = nil, nil

-- Variáveis de Progressão
local pLevel = 1
local maxCapacidade = 5000
local tempoOperacao = 20000
local multiplicadorLucro = 1.0

-- Variáveis do Sistema de Mangueira
local propMangueira = nil
local ropeId = nil 
local faseEntrega = 0 

-- ==========================================
-- 1. SINCRONIZAÇÃO DE EMPREGO E BLIP
-- ==========================================
function GerirBlipRefinaria()
    if PlayerJob and PlayerJob.name == 'fuel_driver' then
        if not blipCarga then
            blipCarga = AddBlipForCoord(ConfigFuel.LoadLocation.x, ConfigFuel.LoadLocation.y, ConfigFuel.LoadLocation.z)
            SetBlipSprite(blipCarga, 361) 
            SetBlipDisplay(blipCarga, 4)
            SetBlipScale(blipCarga, 0.8)
            SetBlipColour(blipCarga, 5) 
            SetBlipAsShortRange(blipCarga, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Refinaria (Carregamento)")
            EndTextCommandSetBlipName(blipCarga)
        end
        if not blipGaragem then
            blipGaragem = AddBlipForCoord(ConfigFuel.DeleteLocation.x, ConfigFuel.DeleteLocation.y, ConfigFuel.DeleteLocation.z)
            SetBlipSprite(blipGaragem, 357) 
            SetBlipDisplay(blipGaragem, 4)
            SetBlipScale(blipGaragem, 0.8)
            SetBlipColour(blipGaragem, 1) 
            SetBlipAsShortRange(blipGaragem, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Guardar Camião")
            EndTextCommandSetBlipName(blipGaragem)
        end
    else
        if blipCarga then
            RemoveBlip(blipCarga)
            blipCarga = nil
        end
        if blipGaragem then
            RemoveBlip(blipGaragem)
            blipGaragem = nil
        end
    end
end

CreateThread(function()
    while ESX.GetPlayerData().job == nil do Wait(100) end
    PlayerJob = ESX.GetPlayerData().job
    GerirBlipRefinaria()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job) 
    PlayerJob = job 
    GerirBlipRefinaria()
end)

-- ==========================================
-- 2. LIGAÇÃO AO TABLET
-- ==========================================
RegisterNetEvent('pacheco_jobs:client:requestTabletOpen')
AddEventHandler('pacheco_jobs:client:requestTabletOpen', function(job)
    if job == 'fuel_driver' and PlayerJob and PlayerJob.name == 'fuel_driver' then
        TriggerEvent('pacheco_jobs:client:forceOpenTablet', 'fuel_driver', ConfigFuel.UI)
    end
end)

RegisterNetEvent('pacheco_jobs:fuel:spawnEspecial')
AddEventHandler('pacheco_jobs:fuel:spawnEspecial', function()
    RetirarConjunto()
end)

-- ==========================================
-- 3. SISTEMA DE INTERFACE
-- ==========================================
function AtualizarUI()
    local litrosParaMostrar = math.max(0, math.floor(cargaNaCisterna))
    lib.showTextUI('⛽ Cisterna: ' .. litrosParaMostrar .. ' / '.. maxCapacidade ..' L', {
        position = 'top-center',
        style = {
            borderRadius = 5,
            backgroundColor = '#1a1b26',
            color = '#e0af68',
            fontSize = '18px',
            fontWeight = 'bold'
        }
    })
end

-- ==========================================
-- 4. FASES DA MANGUEIRA E GUARDAR
-- ==========================================
function ResetarMangueira()
    faseEntrega = 0
    if propMangueira then DeleteEntity(propMangueira); propMangueira = nil end
    if ropeId then DeleteRope(ropeId); ropeId = nil end
end

function GuardarConjunto()
    if camiaoAtual and DoesEntityExist(camiaoAtual) then
        DeleteEntity(camiaoAtual)
    end
    if cisternaAtual and DoesEntityExist(cisternaAtual) then
        DeleteEntity(cisternaAtual)
    end
    
    if blipEntrega then 
        RemoveBlip(blipEntrega) 
        blipEntrega = nil 
    end
    
    ResetarMangueira()
    cargaNaCisterna = 0
    pontoEntregaAtivo = nil
    camiaoAtual = nil
    cisternaAtual = nil
    
    ESX.ShowNotification("~g~Serviço finalizado! Veículo guardado e rota cancelada.")
end

function Passo1_PegarTraseira()
    local ped = PlayerPedId()
    local model = GetHashKey("prop_cs_fuel_nozle")
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    
    propMangueira = CreateObject(model, 0, 0, 0, true, true, false)
    AttachEntityToEntity(propMangueira, ped, GetPedBoneIndex(ped, 28422), 0.05, 0.05, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do Wait(10) end
    
    local posTraseira = GetOffsetFromEntityInWorldCoords(cisternaAtual, 0.0, -5.8, -1.0)
    local posProp = GetEntityCoords(propMangueira)
    
    ropeId = AddRope(posTraseira.x, posTraseira.y, posTraseira.z, 0.0, 0.0, 0.0, #(posTraseira - posProp), 3, 30.0, 1.0, 0, false, false, false, 5.0, false, 0)
    AttachEntitiesToRope(ropeId, cisternaAtual, propMangueira, posTraseira.x, posTraseira.y, posTraseira.z, posProp.x, posProp.y, posProp.z, 30.0, false, false, nil, nil)
    
    faseEntrega = 1
    ESX.ShowNotification("~y~[1/4] Mangueira puxada! ~w~Leva-a e liga na bomba.")
end

function Passo2_LigarBomba()
    local ped = PlayerPedId()
    if propMangueira then 
        DetachEntity(propMangueira, true, true)
        local posAtual = GetEntityCoords(ped)
        local forward = GetEntityForwardVector(ped)
        SetEntityCoords(propMangueira, posAtual.x + (forward.x * 0.5), posAtual.y + (forward.y * 0.5), posAtual.z - 0.9)
        PlaceObjectOnGroundProperly(propMangueira)
        FreezeEntityPosition(propMangueira, true)
    end
    faseEntrega = 2
    ESX.ShowNotification("~y~[2/4] Mangueira ligada! ~w~Vai ao painel lateral da cisterna iniciar a descarga.")
end

function Passo3_DescarregarPainel()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
    
    local litrosADescarregar = math.min(cargaNaCisterna, pontoEntregaAtivo.liters_to_deposit)
    local aDescarregar = true
    local cargaInicial = cargaNaCisterna 
    
    CreateThread(function()
        local decremento = litrosADescarregar / (tempoOperacao / 100) 
        while aDescarregar do
            if cargaNaCisterna > (cargaInicial - litrosADescarregar) then
                cargaNaCisterna = cargaNaCisterna - decremento
                AtualizarUI()
            end
            Wait(100)
        end
    end)
    
    if lib.progressCircle({ 
        duration = tempoOperacao, 
        label = 'A descarregar ' .. litrosADescarregar .. 'L...', 
        canCancel = true, 
        disable = { move = true, combat = true } 
    }) then
        aDescarregar = false
        cargaNaCisterna = cargaInicial - litrosADescarregar
        AtualizarUI()
        
        local lucroFinal = math.floor(pontoEntregaAtivo.reward * multiplicadorLucro)
        TriggerServerEvent('pacheco_jobs:fuel:receberPagamento', pontoEntregaAtivo.gas_station_name, lucroFinal, litrosADescarregar)
        
        faseEntrega = 3
        ESX.ShowNotification("~g~[3/4] Descarga concluída. ~w~Vai à bomba recolher a mangueira!")
    else
        aDescarregar = false
        cargaNaCisterna = cargaInicial
        AtualizarUI()
        ESX.ShowNotification("~r~Descarga cancelada a meio! Tenta novamente.")
    end
    
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
end

function Passo4_PegarBomba()
    local ped = PlayerPedId()
    if propMangueira then 
        FreezeEntityPosition(propMangueira, false)
        AttachEntityToEntity(propMangueira, ped, GetPedBoneIndex(ped, 28422), 0.05, 0.05, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    end
    faseEntrega = 4
    ESX.ShowNotification("~y~[4/4] Mangueira recolhida. ~w~Guarda-a na traseira do camião.")
end

function Passo5_GuardarTraseira()
    ResetarMangueira() 
    
    if cargaNaCisterna > 0 then
        local bombaAnterior = pontoEntregaAtivo.gas_station_name
        repeat
            pontoEntregaAtivo = ConfigFuel.DeliveryPoints[math.random(1, #ConfigFuel.DeliveryPoints)]
        until pontoEntregaAtivo.gas_station_name ~= bombaAnterior or #ConfigFuel.DeliveryPoints == 1

        if blipEntrega then RemoveBlip(blipEntrega) end
        blipEntrega = AddBlipForCoord(pontoEntregaAtivo.coords)
        SetBlipSprite(blipEntrega, 1); SetBlipColour(blipEntrega, 5); SetBlipRoute(blipEntrega, true)
        
        ESX.ShowNotification("~g~Tudo arrumado! ~w~Segue para o próximo destino: ~y~" .. pontoEntregaAtivo.gas_station_name)
    else
        if blipEntrega then RemoveBlip(blipEntrega) end
        pontoEntregaAtivo = nil
        ESX.ShowNotification("~r~Cisterna vazia! ~w~Regressa à refinaria para reabastecer.")
    end
end

-- ==========================================
-- 5. FUNÇÕES BASE (SPAWN E CARREGAMENTO)
-- ==========================================
function RetirarConjunto()
    if camiaoAtual and DoesEntityExist(camiaoAtual) then return ESX.ShowNotification("~r~Já tens um veículo fora!") end
    
    ESX.TriggerServerCallback('pacheco_jobs:fuel:checkCards', function(cardLevel)
        pLevel = cardLevel
        
        local upgrade = ConfigFuel.Upgrades[pLevel]
        maxCapacidade = upgrade.capacity
        tempoOperacao = upgrade.duration
        multiplicadorLucro = upgrade.rewardMult
        
        local mTruck, mTrailer = GetHashKey(ConfigFuel.TruckModel), GetHashKey(ConfigFuel.TrailerModel)
        RequestModel(mTruck) RequestModel(mTrailer)
        while not HasModelLoaded(mTruck) or not HasModelLoaded(mTrailer) do Wait(10) end

        camiaoAtual = CreateVehicle(mTruck, ConfigFuel.VehicleSpawn.x, ConfigFuel.VehicleSpawn.y, ConfigFuel.VehicleSpawn.z, ConfigFuel.VehicleSpawn.w, true, false)
        SetVehicleEnginePowerMultiplier(camiaoAtual, 40.0)
        
        local trailerPos = GetOffsetFromEntityInWorldCoords(camiaoAtual, 0.0, -10.0, 0.0)
        cisternaAtual = CreateVehicle(mTrailer, trailerPos.x, trailerPos.y, trailerPos.z, ConfigFuel.VehicleSpawn.w, true, false)
        
        Wait(500)
        AttachVehicleToTrailer(camiaoAtual, cisternaAtual, 1.1)
        
        cargaNaCisterna = 0
        ResetarMangueira()
        TaskWarpPedIntoVehicle(PlayerPedId(), camiaoAtual, -1)
        
        local nomesCartoes = {"Prata", "Ouro", "Diamante", "Black"}
        ESX.ShowNotification("~g~Leitura Válida: ~y~Cartão " .. nomesCartoes[pLevel] .. "~g~.\nVai carregar a cisterna!")
    end)
end

function IniciarCarga()
    if not camiaoAtual or not IsVehicleAttachedToTrailer(camiaoAtual) then return ESX.ShowNotification("~r~Falta a cisterna!") end
    
    local aEncher = true
    
    CreateThread(function()
        local incremento = maxCapacidade / (tempoOperacao / 100) 
        while aEncher do
            if cargaNaCisterna < maxCapacidade then
                cargaNaCisterna = cargaNaCisterna + incremento
                AtualizarUI()
            end
            Wait(100)
        end
    end)

    if lib.progressCircle({ 
        duration = tempoOperacao, 
        label = 'A bombar ' .. maxCapacidade .. 'L...', 
        canCancel = true, 
        disable = { move = true, car = true } 
    }) then
        aEncher = false
        cargaNaCisterna = maxCapacidade
        AtualizarUI()
        
        pontoEntregaAtivo = ConfigFuel.DeliveryPoints[math.random(1, #ConfigFuel.DeliveryPoints)]
        if blipEntrega then RemoveBlip(blipEntrega) end
        blipEntrega = AddBlipForCoord(pontoEntregaAtivo.coords)
        SetBlipSprite(blipEntrega, 1); SetBlipColour(blipEntrega, 5); SetBlipRoute(blipEntrega, true)
        
        ESX.ShowNotification("~y~Cisterna Cheia! Rota marcada para: " .. pontoEntregaAtivo.gas_station_name)
    else
        aEncher = false
        cargaNaCisterna = 0 
        AtualizarUI()
        ESX.ShowNotification("~r~Carregamento abortado!")
    end
end

-- ==========================================
-- 6. LOOP PRINCIPAL
-- ==========================================
CreateThread(function()
    local lPos = vector3(ConfigFuel.LoadLocation.x, ConfigFuel.LoadLocation.y, ConfigFuel.LoadLocation.z)
    local gPos = vector3(ConfigFuel.DeleteLocation.x, ConfigFuel.DeleteLocation.y, ConfigFuel.DeleteLocation.z)

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        
        if PlayerJob and PlayerJob.name == 'fuel_driver' then
            local pCoords = GetEntityCoords(ped)
            local noCarro = IsPedInAnyVehicle(ped, false)
            
            if faseEntrega > 0 then
                sleep = 0
                DisableControlAction(0, 23, true) 
                if noCarro then
                    TaskLeaveAnyVehicle(ped, 0, 0)
                    ESX.ShowNotification("~r~Guarda a mangueira primeiro antes de conduzires!")
                end
            end
            
            if faseEntrega == 1 or faseEntrega == 4 then
                sleep = 0
                DisableControlAction(0, 21, true) 
                DisableControlAction(0, 22, true) 
            end
            
            local veiculoAtual = GetVehiclePedIsIn(ped, false)
            if veiculoAtual ~= 0 and GetEntityModel(veiculoAtual) == GetHashKey(ConfigFuel.TruckModel) then
                if not uiAberta then AtualizarUI(); uiAberta = true end
                camiaoAtual = veiculoAtual
                local _, reboque = GetVehicleTrailerVehicle(camiaoAtual)
                if reboque ~= 0 then cisternaAtual = reboque end
            elseif uiAberta then
                lib.hideTextUI(); uiAberta = false
            end
            
            if faseEntrega > 0 and (not cisternaAtual or not DoesEntityExist(cisternaAtual)) then
                ResetarMangueira()
            end

            -- PONTO DE GUARDAR
            if camiaoAtual and #(pCoords - gPos) < 20.0 then
                sleep = 0
                DrawMarker(1, gPos.x, gPos.y, gPos.z - 1.0, 0,0,0,0,0,0, 4.0, 4.0, 1.0, 255, 0, 0, 100, false, false, 2, false)
                if #(pCoords - gPos) < 4.0 and noCarro then
                    ESX.ShowHelpNotification("~INPUT_CONTEXT~ Guardar Camião")
                    if IsControlJustReleased(0, 38) then GuardarConjunto() end
                end
            end

            -- REFINARIA: Carregar Cisterna
            if faseEntrega == 0 and cargaNaCisterna <= 0 then
                if #(pCoords - lPos) < 20.0 then
                    sleep = 0
                    DrawMarker(43, lPos.x, lPos.y, lPos.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 89.0, 8.0, 4.0, 1.0, 255, 150, 0, 100, false, false, 2, false)
                    
                    if #(pCoords - lPos) < 4.0 and noCarro then
                        ESX.ShowHelpNotification("~INPUT_CONTEXT~ Encher Cisterna (".. maxCapacidade .."L)")
                        if IsControlJustReleased(0, 38) then IniciarCarga() end
                    end
                end
            end

            -- ENTREGAS: Rotina
            if pontoEntregaAtivo and cisternaAtual and DoesEntityExist(cisternaAtual) then
                local posTraseira = GetOffsetFromEntityInWorldCoords(cisternaAtual, 0.0, -5.8, -1.0)
                local posPainel   = GetOffsetFromEntityInWorldCoords(cisternaAtual, -1.5, 0.0, -1.0)
                local posBomba    = vector3(pontoEntregaAtivo.coords.x, pontoEntregaAtivo.coords.y, pontoEntregaAtivo.coords.z)
                
                if faseEntrega == 0 and not noCarro then
                    if #(pCoords - posTraseira) < 20.0 then
                        sleep = 0
                        DrawMarker(20, posTraseira.x, posTraseira.y, posTraseira.z + 0.5, 0,0,0, 180.0,0,0, 0.5, 0.5, 0.5, 255, 165, 0, 200, true, true, 2, false)
                        DrawMarker(1, posTraseira.x, posTraseira.y, posTraseira.z - 0.5, 0,0,0, 0,0,0, 1.0, 1.0, 0.2, 255, 165, 0, 100, false, false, 2, false)
                        if #(pCoords - posTraseira) < 2.0 then
                            ESX.ShowHelpNotification("~INPUT_CONTEXT~ Puxar Mangueira")
                            if IsControlJustReleased(0, 38) then Passo1_PegarTraseira() end
                        end
                    end
                end

                if faseEntrega == 1 then
                    if #(pCoords - posBomba) < 20.0 then
                        sleep = 0
                        DrawMarker(1, posBomba.x, posBomba.y, posBomba.z - 1.0, 0,0,0,0,0,0, 3.0, 3.0, 1.0, 255, 0, 0, 150, false, false, 2, false)
                        if #(pCoords - posBomba) < 3.0 then
                            ESX.ShowHelpNotification("~INPUT_CONTEXT~ Ligar à Bomba")
                            if IsControlJustReleased(0, 38) then Passo2_LigarBomba() end
                        end
                    end
                end
                
                if faseEntrega == 2 then
                    if #(pCoords - posPainel) < 20.0 then
                        sleep = 0
                        DrawMarker(20, posPainel.x, posPainel.y, posPainel.z + 0.5, 0,0,0, 180.0,0,0, 0.4, 0.4, 0.4, 0, 150, 255, 200, true, true, 2, false)
                        DrawMarker(1, posPainel.x, posPainel.y, posPainel.z - 0.5, 0,0,0, 0,0,0, 1.0, 1.0, 0.2, 0, 150, 255, 100, false, false, 2, false)
                        if #(pCoords - posPainel) < 2.0 then
                            ESX.ShowHelpNotification("~INPUT_CONTEXT~ Iniciar Descarga")
                            if IsControlJustReleased(0, 38) then Passo3_DescarregarPainel() end
                        end
                    end
                end
                
                if faseEntrega == 3 then
                    if #(pCoords - posBomba) < 20.0 then
                        sleep = 0
                        DrawMarker(1, posBomba.x, posBomba.y, posBomba.z - 1.0, 0,0,0,0,0,0, 3.0, 3.0, 1.0, 255, 165, 0, 150, false, false, 2, false)
                        if #(pCoords - posBomba) < 3.0 then
                            ESX.ShowHelpNotification("~INPUT_CONTEXT~ Recolher Mangueira")
                            if IsControlJustReleased(0, 38) then Passo4_PegarBomba() end
                        end
                    end
                end
                
                if faseEntrega == 4 then
                    if #(pCoords - posTraseira) < 20.0 then
                        sleep = 0
                        DrawMarker(20, posTraseira.x, posTraseira.y, posTraseira.z + 0.5, 0,0,0, 180.0,0,0, 0.5, 0.5, 0.5, 0, 255, 0, 200, true, true, 2, false)
                        DrawMarker(1, posTraseira.x, posTraseira.y, posTraseira.z - 0.5, 0,0,0, 0,0,0, 1.0, 1.0, 0.2, 0, 255, 0, 100, false, false, 2, false)
                        if #(pCoords - posTraseira) < 2.0 then
                            ESX.ShowHelpNotification("~INPUT_CONTEXT~ Guardar Mangueira")
                            if IsControlJustReleased(0, 38) then Passo5_GuardarTraseira() end
                        end
                    end
                end

            end
        end
        Wait(sleep)
    end
end)

-- ==========================================
-- 7. SPAWN DOS TANQUES GIGANTES NA REFINARIA
-- ==========================================
CreateThread(function()
    if ConfigFuel.GiantTanks and ConfigFuel.GiantTanks.coords then
        local model = GetHashKey(ConfigFuel.GiantTanks.model)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end
        for i, coord in ipairs(ConfigFuel.GiantTanks.coords) do
            local tankObj = CreateObject(model, coord.x, coord.y, coord.z - 1.0, false, false, false)
            SetEntityHeading(tankObj, coord.w)
            FreezeEntityPosition(tankObj, true)
        end
    end
end)
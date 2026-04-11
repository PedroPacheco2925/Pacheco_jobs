local ESX = exports["es_extended"]:getSharedObject()
local spawnedRocks = {}
local minerando = false
local lavando = false
local fundindo = false
local PlayerJob = {}
local idRochaAtual = nil
local currentMiningProp = nil 
local waterParticle = nil

-- ==========================================
-- COORDENADAS DOS BLIPS (MAPA)
-- ==========================================
local blipLavagem = vector3(-1406.4170, 2005.6992, 60.0455)
local blipFundicao = vector3(1110.1259, -2008.0105, 31.0567)
local blipmina = vector3(2962.6348, 2784.0952, 39.8470)
local blipjoalharia = vector3(-620.8892, -228.6283, 38.0571)

-- ==========================================
-- GESTÃO DE EMPREGO E BLIP
-- ==========================================
CreateThread(function()
    while ESX.GetPlayerData().job == nil do Wait(100) end
    PlayerJob = ESX.GetPlayerData().job
    UpdateJobBlips()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerJob = job
    UpdateJobBlips()
end)

local activeBlips = {}
function UpdateJobBlips()
    for _, blip in pairs(activeBlips) do if DoesBlipExist(blip) then RemoveBlip(blip) end end
    activeBlips = {} 

    if PlayerJob and PlayerJob.name == 'miner' then
        -- Blip Mina
        local bmin = AddBlipForCoord(blipmina.x, blipmina.y, blipmina.z)
        SetBlipSprite(bmin, 527) 
        SetBlipDisplay(bmin, 4)
        SetBlipScale(bmin, 0.8)  
        SetBlipColour(bmin, 1)   
        SetBlipAsShortRange(bmin, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Mina")
        EndTextCommandSetBlipName(bmin)
        table.insert(activeBlips, bmin)

        -- Blip Lavagem
        local bLav = AddBlipForCoord(blipLavagem.x, blipLavagem.y, blipLavagem.z)
        SetBlipSprite(bLav, 527) 
        SetBlipDisplay(bLav, 4)
        SetBlipScale(bLav, 0.8)  
        SetBlipColour(bLav, 3)   
        SetBlipAsShortRange(bLav, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Lavagem de Pedras")
        EndTextCommandSetBlipName(bLav)
        table.insert(activeBlips, bLav)

        -- Blip Fundição
        local bFun = AddBlipForCoord(blipFundicao.x, blipFundicao.y, blipFundicao.z)
        SetBlipSprite(bFun, 527) 
        SetBlipDisplay(bFun, 4)
        SetBlipScale(bFun, 0.8)  
        SetBlipColour(bFun, 1)   
        SetBlipAsShortRange(bFun, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Fundição de Minérios")
        EndTextCommandSetBlipName(bFun)
        table.insert(activeBlips, bFun)

        -- Blip Joalharia
        local bjoa = AddBlipForCoord(blipjoalharia.x, blipjoalharia.y, blipjoalharia.z)
        SetBlipSprite(bjoa, 409) 
        SetBlipDisplay(bjoa, 4)
        SetBlipScale(bjoa, 0.8)  
        SetBlipColour(bjoa, 4)   
        SetBlipAsShortRange(bjoa, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Venda de Minérios")
        EndTextCommandSetBlipName(bjoa)
        table.insert(activeBlips, bjoa)
    end
end

-- ==========================================
-- FUNÇÃO PARAR TUDO (GLOBAL F6)
-- ==========================================
local function PararTudo(mostrarAviso)
    if not minerando and not lavando and not fundindo then return end

    if minerando then SendNUIMessage({ action = "stopMiningGame" }) end
    if fundindo then SendNUIMessage({ action = "stopSmeltingGame" }) end

    if minerando or fundindo then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if lavando then
        pcall(function() 
            if lib.progressActive() then lib.cancelProgress() end
        end)
    end

    minerando, lavando, fundindo = false, false, false
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    
    if currentMiningProp and DoesEntityExist(currentMiningProp) then
        DeleteEntity(currentMiningProp)
        currentMiningProp = nil
    end
    
    if waterParticle then
        StopParticleFxLooped(waterParticle, 0)
        waterParticle = nil
    end

    if mostrarAviso then ESX.ShowNotification("~r~Ação cancelada (F6).") end
end

-- ==========================================
-- FUNÇÕES AUXILIARES
-- ==========================================
local function LoadAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function SpawnToolInHand(ped, modelHash, isHammer)
    if currentMiningProp and DoesEntityExist(currentMiningProp) then DeleteEntity(currentMiningProp) end
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(10) end
    local coords = GetEntityCoords(ped)
    currentMiningProp = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, true)
    local boneIndex = GetPedBoneIndex(ped, 57005)
    local x, y, z, rx, ry, rz = 0.09, -0.01, 0.0, -80.0, 0.0, 0.0
    if isHammer then
        boneIndex = GetPedBoneIndex(ped, 28422)
        x, y, z, rx, ry, rz = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    end
    AttachEntityToEntity(currentMiningProp, ped, boneIndex, x, y, z, rx, ry, rz, true, true, false, true, 1, true)
end

-- ==========================================
-- LOOP DE SPAWN E INTERAÇÃO (FIXED)
-- ==========================================
CreateThread(function()
    local rockHash = GetHashKey(ConfigMiner.Model or "prop_rock_4_c")
    while true do
        local sleep = 1000
        local pCoords = GetEntityCoords(PlayerPedId())
        
        -- Verificamos se o jogador tem o job
        if PlayerJob and PlayerJob.name == 'miner' and not minerando and not lavando and not fundindo then
            
            -- 1. Rochas (Mineração)
            for k, v in pairs(ConfigMiner.Locations) do
                local dist = #(pCoords - v)
                if dist < 50.0 and not spawnedRocks[k] then
                    local obj = CreateObject(rockHash, v.x, v.y, v.z, false, false, false)
                    PlaceObjectOnGroundProperly(obj)
                    FreezeEntityPosition(obj, true)
                    spawnedRocks[k] = obj
                end
                if dist < 2.5 and spawnedRocks[k] then
                    sleep = 0
                    DrawMarker(2, v.x, v.y, v.z + 1.5, 0,0,0,0,180.0,0, 0.3,0.3,0.3, 0,86,179,150, true,true,2,false)
                    if dist < 1.5 then
                        ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para extrair")
                        if IsControlJustReleased(0, 38) then ComecarMinigame(k, spawnedRocks[k]) end
                    end
                end
            end
            
            -- 2. Lavagem
            for _, loc in pairs(ConfigMiner.Washing.Stations) do
                local dist = #(pCoords - vector3(loc.x, loc.y, loc.z))
                if dist < 5.0 then
                    sleep = 0
                    local m = ConfigMiner.Washing.Marker
                    DrawMarker(m.id, loc.x, loc.y, loc.z - 0.2, 0,0,0,0,0,0, m.size.x, m.size.y, m.size.z, m.color.r, m.color.g, m.color.b, m.color.a, false,false,2,false)
                    if dist < 1.5 then
                        ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para lavar pedras")
                        if IsControlJustReleased(0, 38) then OpenWashingUI() end
                    end
                end
            end

            -- 3. Fundição
            for _, loc in pairs(ConfigMiner.Smelting.Stations) do
                local dist = #(pCoords - vector3(loc.x, loc.y, loc.z))
                if dist < 5.0 then
                    sleep = 0
                    local m = ConfigMiner.Smelting.Marker
                    DrawMarker(m.id, loc.x, loc.y, loc.z - 0.2, 0,0,0,0,0,0, m.size.x, m.size.y, m.size.z, m.color.r, m.color.g, m.color.b, m.color.a, false,false,2,false)
                    if dist < 1.5 then
                        ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para fundir minérios")
                        if IsControlJustReleased(0, 38) then OpenSmeltingUI() end
                    end
                end
            end

            -- 4. Venda (Joalharia)
            local distVenda = #(pCoords - blipjoalharia)
            if distVenda < 5.0 then
                sleep = 0
                -- Desenha um marcador verde de venda
                DrawMarker(29, blipjoalharia.x, blipjoalharia.y, blipjoalharia.z, 0,0,0,0,0,0, 1.0, 1.0, 1.0, 0, 255, 100, 150, false,false,2,false)
                if distVenda < 1.5 then
                    ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para ~g~Vender Minérios")
                    if IsControlJustReleased(0, 38) then OpenShopUI() end
                end
            end
            
        end
        Wait(sleep)
    end
end)

-- ==========================================
-- LÓGICA MINERAÇÃO
-- ==========================================
function ComecarMinigame(id, obj)
    if minerando then return end
    local hitPower = 0
    local hasTool = false
    local tools = {{item='martelo_eletrico', power=100}, {item='picareta_3', power=50}, {item='picareta_2', power=25}, {item='picareta', power=20}}

    for _, tool in ipairs(tools) do
        if exports.ox_inventory:Search('count', tool.item) > 0 then
            hitPower, hasTool = tool.power, true
            break
        end
    end

    if not hasTool then return ESX.ShowNotification("~r~Não tens nenhuma picareta :)") end

    minerando = true
    idRochaAtual = id 
    TaskTurnPedToFaceEntity(PlayerPedId(), obj, 1000)
    Wait(1000)
    if not minerando then return end 

    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ action = "startMiningGame", hitPower = hitPower })
end

RegisterNUICallback('playStrikeAnim', function(data, cb)
    local ped = PlayerPedId()
    local isHammer = exports.ox_inventory:Search('count', 'martelo_eletrico') > 0
    local toolModel = isHammer and "prop_tool_jackham" or "prop_tool_pickaxe"
    local animDict = isHammer and "amb@world_human_const_drill@idle_a" or "melee@large_wpn@streamed_core"
    local animName = isHammer and "idle_a" or "ground_attack_on_spot"

    LoadAnim(animDict)
    SpawnToolInHand(ped, GetHashKey(toolModel), isHammer)
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, 900, 49, 0, false, false, false)
    cb('ok')
end)

RegisterNUICallback('playFailAnim', function(data, cb)
    LoadAnim("gestures@m@standing@casual")
    if currentMiningProp then DeleteEntity(currentMiningProp) currentMiningProp = nil end
    TaskPlayAnim(PlayerPedId(), "gestures@m@standing@casual", "gesture_damn", 8.0, -8.0, 1000, 49, 0, false, false, false)
    cb('ok')
end)

RegisterNUICallback('minigameResult', function(data, cb)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    minerando = false
    ClearPedTasks(PlayerPedId())
    if currentMiningProp then DeleteEntity(currentMiningProp) currentMiningProp = nil end
    if data.success then TriggerServerEvent('pacheco_jobs:miner:receberRecompensa') end
    cb('ok')
end)

-- ==========================================
-- LÓGICA LAVAGEM
-- ==========================================
function OpenWashingUI()
    local count = exports.ox_inventory:Search('count', ConfigMiner.Washing.ItemBruto)
    if count < 2 then return ESX.ShowNotification("~r~Precisas de pelo menos 2 pedras sujas!") end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openWashing", count = count, batchSize = 2, batchTime = ConfigMiner.Washing.TimePerBatch })
end

RegisterNUICallback('startWashingProcess', function(data, cb)
    local ped = PlayerPedId()
    local total = tonumber(data.quantity) or 2
    SetNuiFocus(false, false)
    lavando = true

    CreateThread(function()
        LoadAnim("pickup_object")
        TaskPlayAnim(ped, "pickup_object", "pickup_low", 8.0, -8.0, 1500, 0, 0, false, false, false)
        Wait(1500)
        if not lavando then return end

        LoadAnim("amb@world_human_bum_wash@male@high@idle_a")
        TaskPlayAnim(ped, "amb@world_human_bum_wash@male@high@idle_a", "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)
        
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do Wait(10) end
        UseParticleFxAssetNextCall("core")
        waterParticle = StartParticleFxLoopedOnEntityBone("water_splash_ped_move", ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, GetPedBoneIndex(ped, 57005), 1.0, false, false, false)

        local remaining = total
        while remaining >= 2 and lavando do
            local success = lib.progressCircle({
                duration = ConfigMiner.Washing.TimePerBatch,
                label = "A lavar pedras... [F6] Cancelar",
                position = 'bottom',
                canCancel = true,
                disable = { move = true, car = true, combat = true }
            })

            if success then
                TriggerServerEvent('pacheco_jobs:miner:lavarPedra', 2)
                remaining = remaining - 2
            else
                lavando = false
                break
            end
        end
        PararTudo(false)
    end)
    cb('ok')
end)

RegisterNUICallback('closeWashingUI', function(data, cb) SetNuiFocus(false, false) cb('ok') end)

-- ==========================================
-- LÓGICA FUNDIÇÃO
-- ==========================================
function OpenSmeltingUI()
    local itemNecessario = ConfigMiner.Smelting.ItemNecessario
    local requiredCount = ConfigMiner.Smelting.QuantidadeNecessaria
    
    if exports.ox_inventory:Search('count', itemNecessario) >= requiredCount then
        fundindo = true
        SetNuiFocus(true, false)
        SetNuiFocusKeepInput(true)
        SendNUIMessage({ action = "startSmeltingGame" })
        
        local ped = PlayerPedId()
        LoadAnim("mini@repair")
        TaskPlayAnim(ped, "mini@repair", "fixing_a_ped", 8.0, -8.0, -1, 1, 0, false, false, false)
    else
        ESX.ShowNotification("~r~Não tens " .. requiredCount .. "x pedras limpas para fundir!")
    end
end

RegisterNUICallback('smeltingResult', function(data, cb)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    fundindo = false
    ClearPedTasks(PlayerPedId())
    
    if data.success then 
        TriggerServerEvent('pacheco_jobs:miner:fundirPedra') 
    else
        ESX.ShowNotification("~r~Falhaste a fundição.")
    end
    cb('ok')
end)

-- ==========================================
-- LÓGICA DE VENDA (SHOP)
-- ==========================================
function OpenShopUI()
    local inventoryData = {}
    for _, item in ipairs(ConfigMiner.Selling.Items) do
        local amount = exports.ox_inventory:Search('count', item.name) or 0
        table.insert(inventoryData, {
            name = item.name,
            label = item.label,
            price = item.price,
            count = amount
        })
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openShop",
        items = inventoryData
    })
end

RegisterNUICallback('closeShop', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('sellItem', function(data, cb)
    TriggerServerEvent('pacheco_jobs:miner:venderItem', data.itemName, tonumber(data.amount))
    SetTimeout(500, function() OpenShopUI() end) 
    cb('ok')
end)

-- ==========================================
-- LOOP DE TECLAS E CANCELAMENTO F6
-- ==========================================
CreateThread(function()
    while true do
        local sleep = 1000
        if minerando or lavando or fundindo then
            sleep = 0
            DisableControlAction(0, 22, true) 
            DisableControlAction(0, 24, true) 
            DisableControlAction(0, 30, true) 
            DisableControlAction(0, 31, true) 
            
            if IsDisabledControlJustReleased(0, 167) or IsControlJustReleased(0, 167) then 
                PararTudo(true)
            end
        end
        Wait(sleep)
    end
end)
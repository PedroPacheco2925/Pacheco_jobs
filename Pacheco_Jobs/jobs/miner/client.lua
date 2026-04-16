local ESX = exports["es_extended"]:getSharedObject()
local spawnedRocks = {}
local minerando, lavando, fundindo = false, false, false
local PlayerJob = {}
local currentMiningProp = nil 
local waterParticle = nil
local activeBlips = {}

-- ==========================================
-- 1. GESTÃO DE EMPREGO E TABLET
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

RegisterNetEvent('pacheco_jobs:client:requestTabletOpen')
AddEventHandler('pacheco_jobs:client:requestTabletOpen', function(job)
    if job == 'miner' and PlayerJob.name == 'miner' then
        TriggerEvent('pacheco_jobs:client:forceOpenTablet', 'miner', ConfigMiner.UI)
    end
end)

-- ==========================================
-- 2. FUNÇÕES AUXILIARES
-- ==========================================
local function LoadAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function PararTudo()
    local ped = PlayerPedId()
    minerando, lavando, fundindo = false, false, false
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    if currentMiningProp then DeleteEntity(currentMiningProp) currentMiningProp = nil end
    if waterParticle then StopParticleFxLooped(waterParticle, 0) waterParticle = nil end
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

-- ==========================================
-- 3. LOOP DE BLOQUEIO E CONTROLO
-- ==========================================
CreateThread(function()
    while true do
        local sleep = 1000
        if minerando or lavando or fundindo then
            sleep = 0
            DisableControlAction(0, 22, true) -- Bloquear Salto (Space)
            DisableControlAction(0, 24, true) -- Bloquear Ataque (Mouse1)
            DisableControlAction(0, 30, true) -- Bloquear Movimento
            DisableControlAction(0, 31, true)
            
            if IsDisabledControlJustReleased(0, 167) or IsControlJustReleased(0, 167) then 
                PararTudo() 
                ESX.ShowNotification("~r~Ação cancelada.")
            end
        end
        Wait(sleep)
    end
end)

-- ==========================================
-- 4. LOOP DE SPAWN E INTERAÇÃO
-- ==========================================
CreateThread(function()
    local rockHash = GetHashKey(ConfigMiner.Model or "prop_rock_4_c")
    while true do
        local sleep = 1000
        local pCoords = GetEntityCoords(PlayerPedId())
        if PlayerJob and PlayerJob.name == 'miner' then
            for k, v in pairs(ConfigMiner.Locations) do
                local dist = #(pCoords - v)
                if dist < 50.0 and not spawnedRocks[k] then
                    RequestModel(rockHash)
                    while not HasModelLoaded(rockHash) do Wait(1) end
                    local obj = CreateObject(rockHash, v.x, v.y, v.z, false, false, false)
                    PlaceObjectOnGroundProperly(obj)
                    FreezeEntityPosition(obj, true)
                    spawnedRocks[k] = obj
                elseif dist > 50.0 and spawnedRocks[k] then
                    DeleteEntity(spawnedRocks[k])
                    spawnedRocks[k] = nil
                end
                if dist < 2.0 and not minerando and not lavando and not fundindo then
                    sleep = 0; ESX.ShowHelpNotification("~INPUT_CONTEXT~ Extrair Rocha")
                    if IsControlJustReleased(0, 38) then ComecarMinigame(k, v) end
                end
            end
            for _, loc in pairs(ConfigMiner.Washing.Stations) do
                if #(pCoords - vector3(loc.x, loc.y, loc.z)) < 1.5 and not lavando then
                    sleep = 0; ESX.ShowHelpNotification("~INPUT_CONTEXT~ Lavar Pedras")
                    if IsControlJustReleased(0, 38) then OpenWashingUI() end
                end
            end
            if #(pCoords - vector3(1110.1259, -2008.0105, 31.0567)) < 1.5 and not fundindo then
                sleep = 0; ESX.ShowHelpNotification("~INPUT_CONTEXT~ Fundir Minérios")
                if IsControlJustReleased(0, 38) then OpenSmeltingUI() end
            end
            if #(pCoords - ConfigMiner.Selling.Station) < 1.5 then
                sleep = 0; ESX.ShowHelpNotification("~INPUT_CONTEXT~ ~g~Vender Minérios")
                if IsControlJustReleased(0, 38) then OpenShopUI() end
            end
        end
        Wait(sleep)
    end
end)

-- ==========================================
-- 5. LÓGICA MINERAÇÃO (FIX ANIMAÇÃO COMPLETA)
-- ==========================================
function ComecarMinigame(id, coords)
    local hitPower = 0
    local tools = { {item='picareta_mestra', power=100}, {item='perfuradora', power=51}, {item='martelo_eletrico', power=50}, {item='picareta_3', power=34}, {item='picareta_2', power=26}, {item='picareta', power=21} }
    local selected = nil
    for _, t in ipairs(tools) do if exports.ox_inventory:Search('count', t.item) > 0 then hitPower = t.power selected = t.item break end end
    if hitPower == 0 then return ESX.ShowNotification("~r~Não tens picareta!") end

    minerando = true
    local ped = PlayerPedId()
    TaskTurnPedToFaceCoord(ped, coords.x, coords.y, coords.z, 1000)
    Wait(1000)
    FreezeEntityPosition(ped, true)

    local isHammer = (selected == 'martelo_eletrico' or selected == 'perfuradora')
    local model = isHammer and "prop_tool_jackham" or "prop_tool_pickaxe"
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do Wait(1) end
    currentMiningProp = CreateObject(GetHashKey(model), GetEntityCoords(ped), true, true, true)
    AttachEntityToEntity(currentMiningProp, ped, GetPedBoneIndex(ped, isHammer and 28422 or 57005), 0.09, -0.01, 0.0, -80.0, 0.0, 0.0, true, true, false, true, 1, true)

    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ action = "startMiningGame", hitPower = hitPower })
end

RegisterNUICallback('playStrikeAnim', function(data, cb)
    local ped = PlayerPedId()
    local isHammer = exports.ox_inventory:Search('count', 'martelo_eletrico') > 0 or exports.ox_inventory:Search('count', 'perfuradora') > 0
    local dict = isHammer and "amb@world_human_const_drill@idle_a" or "melee@large_wpn@streamed_core"
    local anim = isHammer and "idle_a" or "ground_attack_on_spot"
    
    LoadAnim(dict)
    -- Tempo aumentado para 1500ms para permitir que a picareta complete o arco e bata no chão
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, 1500, 47, 0, false, false, false)
    cb('ok')
end)

RegisterNUICallback('minigameResult', function(data, cb)
    if data.success then TriggerServerEvent('pacheco_jobs:miner:receberRecompensa') end
    PararTudo()
    cb('ok')
end)

-- ==========================================
-- 6. LÓGICA LAVAGEM EM LOOP (DE 2 EM 2)
-- ==========================================
function OpenWashingUI()
    local count = exports.ox_inventory:Search('count', ConfigMiner.Washing.ItemBruto)
    if count < 2 then return ESX.ShowNotification("~r~Precisas de pelo menos 2 pedras sujas!") end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openWashing", count = count, batchSize = 2, batchTime = ConfigMiner.Washing.TimePerBatch })
end

RegisterNUICallback('startWashingProcess', function(data, cb)
    local ped = PlayerPedId()
    local totalToWash = tonumber(data.quantity) or 0
    if totalToWash < 2 then return end
    
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

        local totalBatches = math.floor(totalToWash / 2)
        for i = 1, totalBatches do
            if not lavando then break end
            local success = lib.progressCircle({
                duration = ConfigMiner.Washing.TimePerBatch,
                label = ("A lavar (%d/%d)..."):format(i, totalBatches),
                position = 'bottom',
                canCancel = true,
                disable = { move = true, car = true, combat = true }
            })
            if success then
                TriggerServerEvent('pacheco_jobs:miner:lavarPedra', 2)
            else
                break
            end
        end
        PararTudo()
    end)
    cb('ok')
end)

-- ==========================================
-- 7. FUNDIÇÃO, VENDA E BLIPS
-- ==========================================
function OpenSmeltingUI()
    if exports.ox_inventory:Search('count', 'washed_stone') >= 1 then
        fundindo = true; SetNuiFocus(true, false)
        SendNUIMessage({ action = "startSmeltingGame" })
        LoadAnim("mini@repair"); TaskPlayAnim(PlayerPedId(), "mini@repair", "fixing_a_ped", 8.0, -8.0, -1, 1, 0, false, false, false)
    else ESX.ShowNotification("Não tens pedras limpas!") end
end

RegisterNUICallback('smeltingResult', function(data, cb)
    if data.success then TriggerServerEvent('pacheco_jobs:miner:fundirPedra') end
    PararTudo(); cb('ok')
end)

function OpenShopUI()
    local inv = {}
    for _, item in ipairs(ConfigMiner.Selling.Items) do
        table.insert(inv, { name = item.name, label = item.label, price = item.price, count = exports.ox_inventory:Search('count', item.name) })
    end
    SetNuiFocus(true, true); SendNUIMessage({ action = "openShop", items = inv })
end

RegisterNUICallback('sellItem', function(data, cb)
    TriggerServerEvent('pacheco_jobs:miner:venderItem', data.itemName, tonumber(data.amount))
    SetTimeout(500, function() OpenShopUI() end); cb('ok')
end)

function UpdateJobBlips()
    for _, b in pairs(activeBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    activeBlips = {}
    if PlayerJob and PlayerJob.name == 'miner' then
        local blipsData = {
            {c = vector3(2962.6348, 2784.0952, 39.8470), label = "Mina", sprite = 527, color = 1},
            {c = vector3(-1406.4170, 2005.6992, 60.0455), label = "Lavagem de Pedras", sprite = 527, color = 3},
            {c = vector3(1110.1259, -2008.0105, 31.0567), label = "Fundição de Minérios", sprite = 527, color = 1},
            {c = vector3(-621.0365, -228.4622, 38.0570), label = "Venda de Minérios", sprite = 409, color = 4}
        }
        for _, info in ipairs(blipsData) do
            local b = AddBlipForCoord(info.c)
            SetBlipSprite(b, info.sprite); SetBlipScale(b, 0.8); SetBlipColour(b, info.color); SetBlipAsShortRange(b, true); BeginTextCommandSetBlipName("STRING"); AddTextComponentString(info.label); EndTextCommandSetBlipName(b); table.insert(activeBlips, b)
        end
    end
end

RegisterNUICallback('closeShop', function(data, cb) SetNuiFocus(false, false); cb('ok') end)
RegisterNUICallback('closeWashingUI', function(data, cb) SetNuiFocus(false, false); cb('ok') end)
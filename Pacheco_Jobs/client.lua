local tabletOpen = false

CreateThread(function()
    while true do
        local sleep = 1000
        local pCoords = GetEntityCoords(PlayerPedId())
        local dist = #(pCoords - Config.TabletPos)

        if dist < 10.0 then
            sleep = 0
            DrawMarker(23, Config.TabletPos.x, Config.TabletPos.y, Config.TabletPos.z - 0.95, 0,0,0, 0,0,0, 1.0,1.0,1.0, 163, 230, 53, 100, false, true, 2, false)
            
            if dist < 1.5 then
                ESX.ShowHelpNotification("Pressiona ~INPUT_CONTEXT~ para abrir o ~y~Tablet de Mineiro~s~.")
                if IsControlJustReleased(0, 38) then
                    OpenMiningTablet()
                end
            end
        end
        Wait(sleep)
    end
end)

function OpenMiningTablet()
    tabletOpen = true
    SetNuiFocus(true, true)
    
    -- Enviamos dados fictícios para teste, na próxima fase buscamos do Server/DB
    SendNUIMessage({
        action = "openTablet",
        data = {
            name = "IVAN WAYNE",
            level = 1,
            xp = 100,
            rocksMined = 3,
            totalEarned = 502,
            oresProcessed = 0,
            gemsCut = 0,
            skillsPoints = 0
        }
    })
end

RegisterNUICallback('close', function(data, cb)
    tabletOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)
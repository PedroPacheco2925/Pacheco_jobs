local tabletAberto = false

-- Função para abrir o tablet
function AbrirTablet()
    if not tabletAberto then
        tabletAberto = true
        SetNuiFocus(true, true) -- Dá foco ao rato e ao teclado na UI
        
        -- Aqui simulamos os dados do jogador. 
        -- Mais tarde, estes dados devem vir da base de dados/servidor.
        SendNUIMessage({
            action = "openTablet",
            data = {
                name = "Pedro Pacheco",
                totalEarned = 15420,
                rocksMined = 342,
                oresProcessed = 156,
                gemsCut = 45,
                xp = 4500,
                skillsPoints = 12,
                level = 5
            }
        })
    end
end

-- Comando para testar o tablet no jogo
RegisterCommand("tablet", function()
    AbrirTablet()
end, false)

-- Callback para fechar o tablet (chamado pelo teu script.js)
RegisterNUICallback("close", function(data, cb)
    tabletAberto = false
    SetNuiFocus(false, false) -- Remove o foco da UI
    cb("ok") -- Retorna ao JS que correu tudo bem
end)
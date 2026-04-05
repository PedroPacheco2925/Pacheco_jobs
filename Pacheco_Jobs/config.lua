Config = {}

-- config.lua (Adiciona isto no fundo do ficheiro)

Config.JobCenter = {
    coords = vector3(253.2177, 2844.6707, 43.5731), -- Coordenadas do Centro de Emprego (City Hall)
    distanceToOpen = 2.0,
    blip = {
        enabled = true,
        sprite = 407,
        color = 3,
        scale = 0.8,
        label = "Centro de Emprego"
    }
}

-- Lista de trabalhos disponíveis no Centro de Emprego
Config.AvailableJobs = {
    { job = 'miner', label = 'Mineiro', description = 'Extrai pedras e corta gemas preciosas.' },
    -- Podes adicionar mais no futuro:
    -- { job = 'lumberjack', label = 'Lenhador', description = 'Corta árvores e vende madeira.' }
}

-- Locais onde o jogador pode ir para abrir o tablet e gerir o respetivo trabalho
Config.TabletLocations = {
    ['miner'] = {
        coords = vector3(256.45, 2845.89, 43.45), -- Substitui pelas coords reais do teu blip do mineiro
        distanceToOpen = 2.0,
        blip = {
            enabled = true,
            sprite = 318,
            color = 5,
            scale = 0.8,
            label = "Tablet: Mineiro"
        }
    }
}
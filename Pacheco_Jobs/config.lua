Config = {}

-- config.lua (Adiciona isto no fundo do ficheiro)

Config.JobCenter = {
    coords = vector3(2567.7944, 2717.0730, 42.8049), -- Coordenadas do Centro de Emprego (City Hall)
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
        coords = vector3(2569.2944, 2719.9731, 42.9366), -- Substitui pelas coords reais do teu blip do mineiro
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
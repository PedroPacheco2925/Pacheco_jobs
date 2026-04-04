Config = {}

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
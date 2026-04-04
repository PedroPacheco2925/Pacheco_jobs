RegisterNetEvent('realrp_mineracao:giveReward')
AddEventHandler('realrp_mineracao:giveReward', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    -- Utilização direta do ox_inventory como pediste
    local item = 'stone'
    local amount = 1

    -- Verifica se o jogador consegue carregar (limite de peso do ox_inventory)
    if exports.ox_inventory:CanCarryItem(_source, item, amount) then
        exports.ox_inventory:AddItem(_source, item, amount)
        TriggerClientEvent('esx:showNotification', _source, "Extraíste ~g~" .. amount .. "x Pedra~s~!")
    else
        TriggerClientEvent('esx:showNotification', _source, "~r~Não tens espaço na mochila para guardar a pedra!")
    end
end)
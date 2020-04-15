function buyStock(stock, amount)
    amount = tonumber(amount)
    if(amount > 0 and amount)then
        TriggerServerEvent("es_stockmarket:buyStock", stock, amount)
    end
end

function sellStock(stock, amount)
    amount = tonumber(amount)
    if(amount > 0 and amount)then
        TriggerServerEvent("es_stockmarket:sellStock", stock, amount)
    end
end

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'close'
    })    
end)

RegisterNUICallback('buy', function(data, cb)
    buyStock(data.stock, data.amount)
end)

RegisterNUICallback('sell', function(data, cb)
    sellStock(data.stock, data.amount)
end)

function enableMenu()
    TriggerServerEvent("es_stockmarket:updateStocks")

    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'open'
    })
end

RegisterNetEvent("es_stockmarket:updateStocks")
AddEventHandler("es_stockmarket:updateStocks", function(stocks)
    SendNUIMessage({
        type = 'update',
        stocks = json.encode(stocks)
    })
end)

RegisterNetEvent("es_stockmarket:setClientToUpdate")
AddEventHandler("es_stockmarket:setClientToUpdate", function()
    TriggerServerEvent("es_stockmarket:updateStocks")
end)

function disableMenu()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'close'
    })
end

--SetEntityCoords(PlayerPedId(), 1701.8, 2583.18, -69.26505)

RegisterCommand('updatestocks', function(source, args)
    TriggerServerEvent("es_stockmarket:updateStocks")
end, false)

RegisterCommand('openstocks', function(source, args)
    enableMenu()
end, false)

RegisterCommand('closestocks', function(source, args)
    disableMenu()
end, false)

RegisterCommand('bstock', function(source, args)
    buyStock(args[1], args[2])
end, false)

RegisterCommand('sstock', function(source, args)
    sellStock(args[1], args[2])
end, false)
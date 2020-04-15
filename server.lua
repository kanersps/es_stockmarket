local ready = false

stocks = {}

local config = {
    pricingTimer = GetConvarInt("es_stockmarket_pricingTimer", 30000),
    minRandom = GetConvarInt("es_stockmarket_minRandom", 2),
    maxRandom = GetConvarInt("es_stockmarket_maxRandom", 20),
    divider = GetConvarInt("es_stockmarket_divider", 10),
    lowestBasePercent = GetConvarInt("es_stockmarket_divider", 70),
    highestBacePercent = GetConvarInt("es_stockmarket_divider", 200),
}

-- Randomize pricing based on baseWorth
Citizen.CreateThread(function()
    while true do
        math.randomseed(os.time())

        for i=1,#stocks do
            if(stocks[i].worth == 0)then
                stocks[i].worth = math.ceil(stocks[i].baseWorth * (math.random(config.minRandom, config.maxRandom) / config.divider))
            else
                stocks[i].worth = math.ceil(stocks[i].worth * (math.random(config.minRandom, config.maxRandom) / config.divider))

                if(stocks[i].worth < ((stocks[i].baseWorth / 100) * config.lowestBasePercent))then
                    stocks[i].worth = math.ceil((stocks[i].baseWorth / 100) * config.lowestBasePercent)
                end

                if(stocks[i].worth > ((stocks[i].baseWorth / 100) * config.highestBacePercent))then
                    stocks[i].worth = math.ceil((stocks[i].baseWorth / 100) * config.highestBacePercent)
                end
            end
        end

        TriggerClientEvent("es_stockmarket:setClientToUpdate", -1)
        Citizen.Wait(config.pricingTimer)
    end
end)

AddEventHandler("es_stockmarket:addStock", function(abr, name, baseWorth)
    table.insert(stocks, {abr = abr, name = name, worth = 0, baseWorth = baseWorth})
end)

TriggerEvent("es_stockmarket:addStock", "GOO", "Googol", 150)

RegisterServerEvent("es_stockmarket:updateStocks")
AddEventHandler("es_stockmarket:updateStocks", function()
    local _source = source
    local user = exports.essentialmode:getPlayerFromId(_source)

    local _stocks = stocks

    for i=1,#_stocks do
        _stocks[i].owned = 0
    end

    MySQL.Async.fetchAll('SELECT * FROM es_stockmarket WHERE owner=@owner', {['@owner'] = user.getIdentifier()}, function(ostocks)
        for j=1,#ostocks do
            for i=1,#_stocks do
                if(_stocks[i].abr == ostocks[i].stock)then
                    _stocks[i].owned = ostocks[i].amount
                end
            end
        end

        TriggerClientEvent("es_stockmarket:updateStocks", _source, _stocks)
    end)
end)

RegisterServerEvent('es_stockmarket:buyStock')
AddEventHandler('es_stockmarket:buyStock', function(stock, amount)
    local _source = source
    local user = exports.essentialmode:getPlayerFromId(source)
    
    if(not user)then
        return
    end

    if(not ready)then
        return
    end

    local _stock = {}

    for i=1,#stocks do
        if stocks[i].abr == stock then
            _stock = stocks[i]
            break
        end
    end

    
    if(_stock.abr)then
        if(user.getMoney() >= (_stock.worth * amount))then
            local _stocks = stocks

            user.removeMoney(_stock.worth * amount)
            MySQL.Async.fetchAll('SELECT * FROM es_stockmarket WHERE owner=@owner', {['@owner'] = user.getIdentifier()}, function(ostocks)
                local done = false
                local newOwned = 0

                for j=1,#ostocks do
                    for i=1,#_stocks do
                        if(_stocks[i].abr == ostocks[i].stock)then
                            _stocks[i].owned = ostocks[i].amount + amount
                            newOwned = _stocks[i].owned
                            done = true
                        end
                    end
                end
        
                if(done)then
                    MySQL.Async.execute("UPDATE es_stockmarket SET amount=@amount WHERE owner=@owner AND stock=@stock", {['@stock'] = _stock.abr, ['@owner'] = user.getIdentifier(), ['@amount'] = newOwned}, function()
                        TriggerClientEvent("es_stockmarket:updateStocks", _source, _stocks)
                    end)
                else
                    MySQL.Async.execute("INSERT INTO es_stockmarket(stock, owner, amount) VALUES (@stock, @owner, @amount)", {['@stock'] = _stock.abr, ['@owner'] = user.getIdentifier(), ['@amount'] = amount}, function()
                        TriggerClientEvent("es_stockmarket:updateStocks", _source, _stocks)
                    end)
                end
            end)
        end
    else
        print("[es_stockmarket] Unknowk stock " .. tostring(stock))
    end
end)

RegisterServerEvent('es_stockmarket:sellStock')
AddEventHandler('es_stockmarket:sellStock', function(stock, amount)
    local _source = source
    local user = exports.essentialmode:getPlayerFromId(source)
    
    if(not user)then
        return
    end

    if(not ready)then
        return
    end

    local _stock = {}

    for i=1,#stocks do
        if stocks[i].abr == stock then
            _stock = stocks[i]
            break
        end
    end

    
    if(_stock.abr)then
        local _stocks = stocks

        MySQL.Async.fetchAll('SELECT * FROM es_stockmarket WHERE owner=@owner', {['@owner'] = user.getIdentifier()}, function(ostocks)
            local done = false
            local sold = 0
            local newOwned = 0

            for j=1,#ostocks do
                for i=1,#_stocks do
                    if(_stocks[i].abr == ostocks[i].stock)then
                        if(ostocks[i].amount >= amount)then
                            _stocks[i].owned = ostocks[i].amount - amount
                            newOwned = _stocks[i].owned
                            sold = amount
                            done = true
                        end

                        break
                    end
                end
            end
        
            if(done)then
                user.addMoney(sold * _stock.worth)
                MySQL.Async.execute("UPDATE es_stockmarket SET amount=@amount WHERE owner=@owner AND stock=@stock", {['@stock'] = _stock.abr, ['@owner'] = user.getIdentifier(), ['@amount'] = newOwned}, function()
                    TriggerClientEvent("es_stockmarket:updateStocks", _source, _stocks)
                end)
            end
        end)
    else
        print("[es_stockmarket] Unknowk stock " .. tostring(stock))
    end
end)

MySQL.ready(function ()
    ready = true
    print("[es_stockmarket] Ready to accept queries!")
end)
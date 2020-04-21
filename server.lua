local ready = false

stocks = {}

local config = {
    pricingTimer = GetConvarInt("es_stockmarket_pricingTimer", 30000),
    minRandom = GetConvarInt("es_stockmarket_minRandom", 2),
    maxRandom = GetConvarInt("es_stockmarket_maxRandom", 20),
    divider = GetConvarInt("es_stockmarket_divider", 10),
    lowestBasePercent = GetConvarInt("es_stockmarket_lowestBasePercent", 70),
    highestBacePercent = GetConvarInt("es_stockmarket_highestBasePercent", 200),
    addDefault = GetConvarInt("es_stockmarket_addDefault", 1),
    maxStocks = GetConvarInt("es_stockmarket_maxStocks", 99999999),
}

local userStockCache = {}

function shallowCopy(target, source)
    for k,v in pairs(source) do
        target[k] = v
    end
end

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

if(config.addDefault)then
    TriggerEvent("es_stockmarket:addStock", "GOO", "Googol", 150)
    TriggerEvent("es_stockmarket:addStock", "FLC", "Fleeca", 130)
    TriggerEvent("es_stockmarket:addStock", "BON", "Bong", 140)
end

RegisterServerEvent("es_stockmarket:updateStocks")
AddEventHandler("es_stockmarket:updateStocks", function()
    local _source = source
    local user = exports.essentialmode:getPlayerFromId(_source)

    if(user)then
        userStockCache[user.getIdentifier()] = {}

        shallowCopy(userStockCache[user.getIdentifier()], stocks)

        for i=1,#userStockCache[user.getIdentifier()] do
        userStockCache[user.getIdentifier()][i].owned = 0
        end

        MySQL.Async.fetchAll('SELECT * FROM es_stockmarket WHERE owner=@owner', {['@owner'] = user.getIdentifier()}, function(ostocks)
            for j=1,#ostocks do
                for i=1,#userStockCache[user.getIdentifier()] do
                    if(userStockCache[user.getIdentifier()] and ostocks[j].stock)then
                        if(userStockCache[user.getIdentifier()][i].abr == ostocks[j].stock)then
                            userStockCache[user.getIdentifier()][i].owned = ostocks[j].amount
                        end
                    end
                end
            end

            TriggerClientEvent("es_stockmarket:updateStocks", _source, userStockCache[user.getIdentifier()])
        end)
    end
end)

RegisterServerEvent('es_stockmarket:buyStock')
AddEventHandler('es_stockmarket:buyStock', function(stock, amount, test)
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
            user.removeMoney(_stock.worth * amount)
            MySQL.Async.fetchAll('SELECT * FROM es_stockmarket WHERE owner=@owner', {['@owner'] = user.getIdentifier()}, function(ostocks)
                local done = false
                local newOwned = 0

                userStockCache[user.getIdentifier()] = {}

                for k,v in pairs(stocks)do
                    userStockCache[user.getIdentifier()][k] = v
                    userStockCache[user.getIdentifier()][k].owned = 0
                end

                for j=1,#ostocks do
                    for i=1,#userStockCache[user.getIdentifier()] do
                        if(userStockCache[user.getIdentifier()][i] and ostocks[j])then
                            if(userStockCache[user.getIdentifier()][i].abr == ostocks[j].stock)then
                                userStockCache[user.getIdentifier()][i].owned = ostocks[j].amount
                            end
                            
                            if(userStockCache[user.getIdentifier()][i].abr == ostocks[j].stock and ostocks[j].stock == stock)then
                                if(config.maxStocks < (ostocks[j].amount + amount))then
                                    newOwned = ostocks[j].amount
                                    done = true
                                    user.addMoney(_stock.worth * amount)
                                else
                                    userStockCache[user.getIdentifier()][i].owned = ostocks[j].amount + amount
                                    newOwned = userStockCache[user.getIdentifier()][i].owned
                                    done = true
                                end
                            end
                        end
                    end
                end
        
                if(done)then
                    MySQL.Async.execute("UPDATE es_stockmarket SET amount=@amount WHERE owner=@owner AND stock=@stock", {['@stock'] = _stock.abr, ['@owner'] = user.getIdentifier(), ['@amount'] = newOwned}, function()
                        TriggerClientEvent("es_stockmarket:setClientToUpdate", _source)
                        --TriggerClientEvent("es_stockmarket:updateStocks", _source, userStockCache[user.getIdentifier()])
                    end)
                else
                    MySQL.Async.execute("INSERT INTO es_stockmarket(stock, owner, amount) VALUES (@stock, @owner, @amount)", {['@stock'] = _stock.abr, ['@owner'] = user.getIdentifier(), ['@amount'] = amount}, function()
                        TriggerClientEvent("es_stockmarket:setClientToUpdate", _source)
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
        MySQL.Async.fetchAll('SELECT * FROM es_stockmarket WHERE owner=@owner', {['@owner'] = user.getIdentifier()}, function(ostocks)
            local done = false
            local sold = 0
            local newOwned = 0

            userStockCache[user.getIdentifier()] = {}

            shallowCopy(userStockCache[user.getIdentifier()], stocks)
        
            for i=1,#userStockCache[user.getIdentifier()] do
               userStockCache[user.getIdentifier()][i].owned = 0
            end

            for j=1,#ostocks do
                for i=1,#userStockCache[user.getIdentifier()] do
                    if(userStockCache[user.getIdentifier()][i] and ostocks[j].stock)then
                        if(userStockCache[user.getIdentifier()][i].abr == ostocks[j].stock and stock == ostocks[j].stock) then
                            if(ostocks[j].amount >= amount)then
                                userStockCache[user.getIdentifier()][i].owned = ostocks[j].amount - amount
                                newOwned = userStockCache[user.getIdentifier()][i].owned
                                sold = amount
                                done = true
                            end

                            break
                        end
                    end
                end
            end
        
            if(done)then
                MySQL.Async.execute("UPDATE es_stockmarket SET amount=@amount WHERE owner=@owner AND stock=@stock", {['@stock'] = _stock.abr, ['@owner'] = user.getIdentifier(), ['@amount'] = newOwned}, function()
                    user.addMoney(sold * _stock.worth)
                    TriggerClientEvent("es_stockmarket:setClientToUpdate", _source)
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
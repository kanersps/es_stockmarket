# es_stockmarket
Adds a full featured stock trading app to your FiveM server. It fully intergrates with EssentialMode! :)

There’s also an API so you can add your own stocks to the app.

## Installation
- Download latest release
- Make sure EssentialMode is up and running
- Import es_stockmarket.sql into your database
- Add ensure es_stockmarket to your configuration file for startup
- Start your server :slight_smile:

Ingame type /openstocks to open the window, you can intergrate this with anything of your choosing.

## Developer information

To add a stock you can use the following event in your script:

`TriggerEvent("es_stockmarket:addStock", "Abbreviation", "Full name", baseWorth)`

Parameter 1 and 2 are strings, the third is an integer what the “base” value is for the stock.
Server owner information

There are config options that are available for your configuration file. These are the following:

```
-- Time in MS to update the stock market prices
set es_stockmarket_pricingTimer 30000

-- The lowest possible randomizer
set es_stockmarket_minRandom 2

-- The highest possible randomizer
set es_stockmarket_maxRandom 20

-- The divider that is used to calculate the new prices
set es_stockmarket_divider 10

-- The lowest possible percentage of the base worth that the value of a stock can be
set es_stockmarket_lowestBasePercent 70

-- The highest possible percentage of the base worth that the value of a stock can be
set es_stockmarket_highestBasePercent 200
```

Screenshots

![](https://i.kanersps.pw/tgA1DUnuDuiWRlf)

(optional)
# Rent a server with EssentialMode pre-installed!
Go to https://zap-hosting.com/EssentialMode and use code `kanersps-a-2529` for 10% off on all products for life! They will even install EssentialMode for you!

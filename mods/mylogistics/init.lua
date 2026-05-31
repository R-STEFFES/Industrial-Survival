-- Global zugängliche Funktionen für deine Logistik-Mod
mylogistics = {}

function mylogistics.register_machine_as_consumer(pos, power_demand)
    -- Funktion wird später von deinen Maschinen aufgerufen
    -- Erlaubt es, Energie aus dem Kabelnetzwerk zu ziehen
end

-- Lade die einzelnen Module (Reihenfolge ist wichtig)
local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath .. "/fluiduct.lua")
dofile(modpath .. "/itemduct.lua")
dofile(modpath .. "/energyduct.lua")
dofile(modpath .. "/recipes.lua")


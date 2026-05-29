-- =======================================================================
-- STI MACHINES - INITIALISIERUNG & KERN-LOGIK
-- =======================================================================

-- 1. Globale Mod-Tabelle definieren
sti_machines = {}

-- Hilfsfunktion: Prüft, ob ein Gegenstand als Brennstoff gilt (z.B. Kohle)
local function get_fuel_time(itemstack)
    local fuel, tipped = minetest.get_craft_result({method = "fuel", width = 1, items = {itemstack}})
    if fuel and fuel.time and fuel.time > 0 then
        return fuel.time
    end
    return 0
end


-- =======================================================================
-- 2. EXTERNE MASCHINEN-DATEIEN LADEN
-- =======================================================================

local modpath = minetest.get_modpath("sti_machines")

-- Lädt den Kohle-Generator, die Batterie und den elektrischen Ofen
-- In der init.lua unter "3. EXTERNE MASCHINEN-DATEIEN LADEN" einfügen:
dofile(modpath .. "/pump.lua")
dofile(modpath .. "/generator.lua")
dofile(modpath .. "/battery.lua")
dofile(modpath .. "/electric_furnace.lua")

minetest.log("action", "[sti_machines] Mod erfolgreich geladen! (Pumpe, Generator, Batterie, E-Ofen)")

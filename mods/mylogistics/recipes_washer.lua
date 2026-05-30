-- =======================================================================
-- STI MACHINES - REZEPTE FÜR GOLDWASCHANLAGE
-- =======================================================================

sti_machines = sti_machines or {}
sti_machines.washer_recipes = {}

-- Hilfsfunktion zum einfachen Hinzufügen von Rezepten
local function register_washer_recipe(input_item, guaranteed_output, extra_drops)
    sti_machines.washer_recipes[input_item] = {
        output = guaranteed_output,
        drops = extra_drops or {}
    }
end

-- =======================================================================
-- REZEPT-DEFINITIONEN
-- =======================================================================

-- Gelber Lehm: Gibt immer sauberen gelben Lehm + 0.01% Chance auf Gold
register_washer_recipe("sti_core:clay_raw_yellow", "sti_core:clay_clean_yellow", {
    { item = "sti_core:nugget_gold", chance = 0.0001 } -- 0.01%
})

-- Grüner Lehm: Gibt immer sauberen grünen Lehm + Chancen auf Kupfer/Nickel
register_washer_recipe("sti_core:clay_raw_green", "sti_core:clay_clean_green", {
    { item = "sti_core:nugget_copper", chance = 0.05 },  -- 5%
    { item = "sti_core:nugget_nickel", chance = 0.005 }  -- 0.5%
})

-- Roter Lehm: Gibt immer sauberen roten Lehm + Chancen auf Eisen/Aluminium
register_washer_recipe("sti_core:clay_raw_red", "sti_core:clay_clean_red", {
    { item = "sti_core:nugget_iron",     chance = 0.08 }, -- 8%
    { item = "sti_core:nugget_aluminum", chance = 0.02 } -- 2%
})

-- Kompatibilität für Standard-Blöcke (Alte Funktionalität beibehalten)
register_washer_recipe("default:dirt", "default:clay_lump", {
    { item = "default:sand",            chance = 0.40 }, -- 40%
    { item = "default:gravel",          chance = 0.20 }, -- 20%
    { item = "sti_core:nugget_iron",    chance = 0.02 }, -- 2%
    { item = "sti_core:nugget_silver",  chance = 0.005 } -- 0.5%
})

register_washer_recipe("default:sand", "default:gravel", {
    { item = "sti_core:nugget_gold",    chance = 0.001 } -- 0.1%
})

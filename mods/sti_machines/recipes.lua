-- sti_machines/recipes.lua
-- Rezepte für alle Maschinen unter Verwendung von sti_core Materialien.

-------------------------------------------------------------------------------
-- 1. ENERGIE-ERZEUGUNG & SPEICHERUNG
-------------------------------------------------------------------------------

-- Kohle-Generator
minetest.register_craft({
    output = "sti_machines:generator",
    recipe = {
        {"sti_core:ingot_iron", "sti_core:ingot_iron",     "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "default:furnace",         "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "sti_core:ingot_copper",   "sti_core:ingot_iron"},
    }
})

-- Akku (Batterie)
minetest.register_craft({
    output = "sti_machines:battery",
    recipe = {
        {"sti_core:ingot_iron",   "sti_core:ingot_gold",   "sti_core:ingot_iron"},
        {"sti_core:ingot_copper", "sti_core:ingot_tin",    "sti_core:ingot_copper"},
        {"sti_core:ingot_iron",   "sti_core:ingot_gold",   "sti_core:ingot_iron"},
    }
})

-- Ladestation
minetest.register_craft({
    output = "sti_machines:charging_station",
    recipe = {
        {"sti_core:ingot_gold", "default:glass",         "sti_core:ingot_gold"},
        {"sti_core:ingot_iron", "sti_core:ingot_copper", "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "sti_core:ingot_iron",   "sti_core:ingot_iron"},
    }
})

-------------------------------------------------------------------------------
-- 2. VERARBEITUNGSMASCHINEN
-------------------------------------------------------------------------------

-- Pulverizer (Erzverdoppler)
minetest.register_craft({
    output = "sti_machines:pulverizer",
    recipe = {
        {"sti_core:ingot_iron",   "default:flint",         "sti_core:ingot_iron"},
        {"sti_core:ingot_copper", "sti_core:ingot_tin",    "sti_core:ingot_copper"},
        {"sti_core:ingot_iron",   "sti_core:block_copper", "sti_core:ingot_iron"},
    }
})

-- Elektrischer Ofen
minetest.register_craft({
    output = "sti_machines:electric_furnace",
    recipe = {
        {"sti_core:ingot_iron",   "sti_core:ingot_copper", "sti_core:ingot_iron"},
        {"sti_core:ingot_copper", "default:furnace",       "sti_core:ingot_copper"},
        {"sti_core:ingot_iron",   "sti_core:ingot_copper", "sti_core:ingot_iron"},
    }
})

-- Autocrafter
minetest.register_craft({
    output = "sti_machines:autocrafter",
    recipe = {
        {"sti_core:ingot_gold", "default:chest",         "sti_core:ingot_gold"},
        {"sti_core:ingot_iron", "default:workbench",     "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "sti_core:ingot_copper", "sti_core:ingot_iron"},
    }
})

-------------------------------------------------------------------------------
-- 3. FLÜSSIGKEITEN & SPEZIALMASCHINEN
-------------------------------------------------------------------------------

-- Dampfpumpe
minetest.register_craft({
    output = "sti_machines:steam_pump",
    recipe = {
        {"sti_core:ingot_iron", "bucket:bucket_empty",   "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "sti_core:ingot_copper", "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "sti_core:ingot_iron",   "sti_core:ingot_iron"},
    }
})

-- Liquid Workbench
minetest.register_craft({
    output = "sti_machines:liquid_workbench",
    recipe = {
        {"sti_core:ingot_iron", "bucket:bucket_empty",   "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "default:workbench",     "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "sti_core:ingot_iron",   "sti_core:ingot_iron"},
    }
})

-- Goldwaschanlage
minetest.register_craft({
    output = "sti_machines:gold_washer",
    recipe = {
        {"sti_core:ingot_iron", "default:gravel",        "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "bucket:bucket_empty",   "sti_core:ingot_iron"},
        {"sti_core:ingot_copper", "sti_core:ingot_tin",  "sti_core:ingot_copper"},
    }
})

-- Fluid Filler (Abfüller)
minetest.register_craft({
    output = "sti_machines:fluid_filler",
    recipe = {
        {"sti_core:ingot_iron", "default:glass",         "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "bucket:bucket_empty",   "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "sti_core:ingot_copper", "sti_core:ingot_iron"},
    }
})

-- Quary
minetest.register_craft({
    output = "sti_machines:quarry",
    recipe = {
        {"sti_core:ingot_iron", "default:chest",         "sti_core:ingot_iron"},
        {"sti_core:pick_tungsten", "bucket:bucket_empty",   "sti_core:pick_tungsten"},
        {"sti_core:block_magnesium", "sti_core:block_copper", "sti_core:block_magnesium"},
    }
})

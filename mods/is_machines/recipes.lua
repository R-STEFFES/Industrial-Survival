-- is_machines/recipes.lua
-- Rezepte für alle Maschinen unter Verwendung von is_core Materialien.

-------------------------------------------------------------------------------
-- 1. ENERGIE-ERZEUGUNG & SPEICHERUNG
-------------------------------------------------------------------------------

-- Kohle-Generator
minetest.register_craft({
    output = "is_machines:generator",
    recipe = {
        {"is_core:ingot_iron", "is_core:ingot_iron",     "is_core:ingot_iron"},
        {"is_core:ingot_iron", "default:furnace",         "is_core:ingot_iron"},
        {"is_core:ingot_iron", "is_core:ingot_copper",   "is_core:ingot_iron"},
    }
})

-- Akku (Batterie)
minetest.register_craft({
    output = "is_machines:battery",
    recipe = {
        {"is_core:ingot_iron",   "is_core:ingot_gold",   "is_core:ingot_iron"},
        {"is_core:ingot_copper", "is_core:ingot_tin",    "is_core:ingot_copper"},
        {"is_core:ingot_iron",   "is_core:ingot_gold",   "is_core:ingot_iron"},
    }
})

-- Ladestation
minetest.register_craft({
    output = "is_machines:charging_station",
    recipe = {
        {"is_core:ingot_gold", "default:glass",         "is_core:ingot_gold"},
        {"is_core:ingot_iron", "is_core:ingot_copper", "is_core:ingot_iron"},
        {"is_core:ingot_iron", "is_core:ingot_iron",   "is_core:ingot_iron"},
    }
})

-------------------------------------------------------------------------------
-- 2. VERARBEITUNGSMASCHINEN
-------------------------------------------------------------------------------

-- Pulverizer (Erzverdoppler)
minetest.register_craft({
    output = "is_machines:pulverizer",
    recipe = {
        {"is_core:ingot_iron",   "default:flint",         "is_core:ingot_iron"},
        {"is_core:ingot_copper", "is_core:ingot_tin",    "is_core:ingot_copper"},
        {"is_core:ingot_iron",   "is_core:block_copper", "is_core:ingot_iron"},
    }
})

-- Elektrischer Ofen
minetest.register_craft({
    output = "is_machines:electric_furnace",
    recipe = {
        {"is_core:ingot_iron",   "is_core:ingot_copper", "is_core:ingot_iron"},
        {"is_core:ingot_copper", "default:furnace",       "is_core:ingot_copper"},
        {"is_core:ingot_iron",   "is_core:ingot_copper", "is_core:ingot_iron"},
    }
})

-- Autocrafter
minetest.register_craft({
    output = "is_machines:autocrafter",
    recipe = {
        {"is_core:ingot_gold", "default:chest",         "is_core:ingot_gold"},
        {"is_core:ingot_iron", "default:workbench",     "is_core:ingot_iron"},
        {"is_core:ingot_iron", "is_core:ingot_copper", "is_core:ingot_iron"},
    }
})

-------------------------------------------------------------------------------
-- 3. FLÜSSIGKEITEN & SPEZIALMASCHINEN
-------------------------------------------------------------------------------

-- Dampfpumpe
minetest.register_craft({
    output = "is_machines:steam_pump",
    recipe = {
        {"is_core:ingot_iron", "bucket:bucket_empty",   "is_core:ingot_iron"},
        {"is_core:ingot_iron", "is_core:ingot_copper", "is_core:ingot_iron"},
        {"is_core:ingot_iron", "is_core:ingot_iron",   "is_core:ingot_iron"},
    }
})

-- Liquid Workbench
minetest.register_craft({
    output = "is_machines:liquid_workbench",
    recipe = {
        {"is_core:ingot_iron", "bucket:bucket_empty",   "is_core:ingot_iron"},
        {"is_core:ingot_iron", "default:workbench",     "is_core:ingot_iron"},
        {"is_core:ingot_iron", "is_core:ingot_iron",   "is_core:ingot_iron"},
    }
})

-- Goldwaschanlage
minetest.register_craft({
    output = "is_machines:gold_washer",
    recipe = {
        {"is_core:ingot_iron", "default:gravel",        "is_core:ingot_iron"},
        {"is_core:ingot_iron", "bucket:bucket_empty",   "is_core:ingot_iron"},
        {"is_core:ingot_copper", "is_core:ingot_tin",  "is_core:ingot_copper"},
    }
})

-- Fluid Filler (Abfüller)
minetest.register_craft({
    output = "is_machines:fluid_filler",
    recipe = {
        {"is_core:ingot_iron", "default:glass",         "is_core:ingot_iron"},
        {"is_core:ingot_iron", "bucket:bucket_empty",   "is_core:ingot_iron"},
        {"is_core:ingot_iron", "is_core:ingot_copper", "is_core:ingot_iron"},
    }
})

-- Quary
minetest.register_craft({
    output = "is_machines:quarry",
    recipe = {
        {"is_core:ingot_iron", "default:chest",         "is_core:ingot_iron"},
        {"is_core:pick_tungsten", "bucket:bucket_empty",   "is_core:pick_tungsten"},
        {"is_core:block_magnesium", "is_core:block_copper", "is_core:block_magnesium"},
    }
})

-- Quary
minetest.register_craft({
    output = "is_machines:upgrade_range",
    recipe = {
        {"is_core:block_magnesium", "is_core:ingot_tin", "is_core:block_magnesium"},
        {"is_core:block_titanium", "is_core:block_titanium", "is_core:block_titanium"},
        {"is_core:block_magnesium", "is_core:block_aluminum", "is_core:block_magnesium"},
    }
})


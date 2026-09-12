-- mylogistics/recipes.lua
-- Diese Datei definiert die Crafting-Rezepte für My Logistics unter Verwendung von is_core Materialien.

-------------------------------------------------------------------------------
-- 1. FLUIDUCTS (Flüssigkeitsrohre)
-------------------------------------------------------------------------------

-- Standard Fluiduct (Eisen)
minetest.register_craft({
    output = "is_mylogistics:fluiduct 6",
    recipe = {
        {"is_core:ingot_iron", "is_core:ingot_iron", "is_core:ingot_iron"},
        {"", "", ""},
        {"is_core:ingot_iron", "is_core:ingot_iron", "is_core:ingot_iron"},
    }
})

-- Fluiduct mit Glas (Eisen + Glas)
minetest.register_craft({
    output = "is_mylogistics:fluiduct_glass 6",
    recipe = {
        {"is_core:ingot_iron", "is_core:ingot_iron", "is_core:ingot_iron"},
        {"default:glass", "default:glass", "default:glass"},
        {"is_core:ingot_iron", "is_core:ingot_iron", "is_core:ingot_iron"},
    }
})

-------------------------------------------------------------------------------
-- 2. ITEMDUCTS (Gegenstandstransport)
-------------------------------------------------------------------------------

-- Standard Itemduct (Zinn/Tin - falls nicht vorhanden, Eisen als Fallback)
minetest.register_craft({
    output = "is_mylogistics:itemduct 6",
    recipe = {
        {"is_core:ingot_tin", "is_core:ingot_tin", "is_core:ingot_tin"},
        {"", "", ""},
        {"is_core:ingot_tin", "is_core:ingot_tin", "is_core:ingot_tin"},
    }
})

-- Itemduct Transparent (Zinn + Glas)
minetest.register_craft({
    output = "is_mylogistics:itemduct_transparent 6",
    recipe = {
        {"is_core:ingot_tin", "is_core:ingot_tin", "is_core:ingot_tin"},
        {"default:glass", "default:glass", "default:glass"},
        {"is_core:ingot_tin", "is_core:ingot_tin", "is_core:ingot_tin"},
    }
})

-------------------------------------------------------------------------------
-- 3. ENERGIEKABEL
-------------------------------------------------------------------------------

-- Stromkabel (Kupfer)
minetest.register_craft({
    output = "is_mylogistics:cable 6",
    recipe = {
        {"", "", ""},
        {"is_core:ingot_copper", "is_core:ingot_copper", "is_core:ingot_copper"},
        {"", "", ""},
    }
})

-------------------------------------------------------------------------------
-- 4. UPGRADES (Servos & Filter)
-------------------------------------------------------------------------------

-- Servo (Extraktion) - Nutzt Kupfer-Nuggets für die Mechanik
minetest.register_craft({
    output = "is_mylogistics:servo",
    recipe = {
        {"", "is_core:nugget_copper", ""},
        {"is_core:nugget_copper", "is_core:ingot_iron", "is_core:nugget_copper"},
        {"", "is_core:nugget_copper", ""},
    }
})

-- Filter - Nutzt Gold-Nuggets für Präzision
minetest.register_craft({
    output = "is_mylogistics:filter",
    recipe = {
        {"", "is_core:nugget_gold", ""},
        {"is_core:nugget_gold", "is_core:ingot_iron", "is_core:nugget_gold"},
        {"", "is_core:nugget_gold", ""},
    }
})

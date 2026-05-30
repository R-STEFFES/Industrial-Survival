-- mylogistics/recipes.lua
-- Diese Datei definiert die Crafting-Rezepte für My Logistics unter Verwendung von sti_core Materialien.

-------------------------------------------------------------------------------
-- 1. FLUIDUCTS (Flüssigkeitsrohre)
-------------------------------------------------------------------------------

-- Standard Fluiduct (Eisen)
minetest.register_craft({
    output = "mylogistics:fluiduct 6",
    recipe = {
        {"sti_core:ingot_iron", "sti_core:ingot_iron", "sti_core:ingot_iron"},
        {"", "", ""},
        {"sti_core:ingot_iron", "sti_core:ingot_iron", "sti_core:ingot_iron"},
    }
})

-- Fluiduct mit Glas (Eisen + Glas)
minetest.register_craft({
    output = "mylogistics:fluiduct_glass 6",
    recipe = {
        {"sti_core:ingot_iron", "sti_core:ingot_iron", "sti_core:ingot_iron"},
        {"default:glass", "default:glass", "default:glass"},
        {"sti_core:ingot_iron", "sti_core:ingot_iron", "sti_core:ingot_iron"},
    }
})

-------------------------------------------------------------------------------
-- 2. ITEMDUCTS (Gegenstandstransport)
-------------------------------------------------------------------------------

-- Standard Itemduct (Zinn/Tin - falls nicht vorhanden, Eisen als Fallback)
minetest.register_craft({
    output = "mylogistics:itemduct 6",
    recipe = {
        {"sti_core:ingot_tin", "sti_core:ingot_tin", "sti_core:ingot_tin"},
        {"", "", ""},
        {"sti_core:ingot_tin", "sti_core:ingot_tin", "sti_core:ingot_tin"},
    }
})

-- Itemduct Transparent (Zinn + Glas)
minetest.register_craft({
    output = "mylogistics:itemduct_transparent 6",
    recipe = {
        {"sti_core:ingot_tin", "sti_core:ingot_tin", "sti_core:ingot_tin"},
        {"default:glass", "default:glass", "default:glass"},
        {"sti_core:ingot_tin", "sti_core:ingot_tin", "sti_core:ingot_tin"},
    }
})

-------------------------------------------------------------------------------
-- 3. ENERGIEKABEL
-------------------------------------------------------------------------------

-- Stromkabel (Kupfer)
minetest.register_craft({
    output = "mylogistics:cable 6",
    recipe = {
        {"", "", ""},
        {"sti_core:ingot_copper", "sti_core:ingot_copper", "sti_core:ingot_copper"},
        {"", "", ""},
    }
})

-------------------------------------------------------------------------------
-- 4. UPGRADES (Servos & Filter)
-------------------------------------------------------------------------------

-- Servo (Extraktion) - Nutzt Kupfer-Nuggets für die Mechanik
minetest.register_craft({
    output = "mylogistics:servo",
    recipe = {
        {"", "sti_core:nugget_copper", ""},
        {"sti_core:nugget_copper", "sti_core:ingot_iron", "sti_core:nugget_copper"},
        {"", "sti_core:nugget_copper", ""},
    }
})

-- Filter - Nutzt Gold-Nuggets für Präzision
minetest.register_craft({
    output = "mylogistics:filter",
    recipe = {
        {"", "sti_core:nugget_gold", ""},
        {"sti_core:nugget_gold", "sti_core:ingot_iron", "sti_core:nugget_gold"},
        {"", "sti_core:nugget_gold", ""},
    }
})

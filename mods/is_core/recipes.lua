-- is_core/recipes.lua

for _, elem in ipairs(elements) do
    -- NEU: 9 Nuggets direkt zu einem Barren (Ingot) craften
    minetest.register_craft({
        output = "is_core:ingot_" .. elem.name,
        recipe = {
            {"is_core:nugget_" .. elem.name, "is_core:nugget_" .. elem.name, "is_core:nugget_" .. elem.name},
            {"is_core:nugget_" .. elem.name, "is_core:nugget_" .. elem.name, "is_core:nugget_" .. elem.name},
            {"is_core:nugget_" .. elem.name, "is_core:nugget_" .. elem.name, "is_core:nugget_" .. elem.name}
        }
    })

    minetest.register_craft({
        output = "is_core:block_" .. elem.name,
        recipe = {
            {"is_core:ingot_" .. elem.name, "is_core:ingot_" .. elem.name, "is_core:ingot_" .. elem.name},
            {"is_core:ingot_" .. elem.name, "is_core:ingot_" .. elem.name, "is_core:ingot_" .. elem.name},
            {"is_core:ingot_" .. elem.name, "is_core:ingot_" .. elem.name, "is_core:ingot_" .. elem.name}
        }
    })

    -- Schmelzen: Klumpen -> Ingot (Beibehalten als Notlösung, falls kein Pulverizer da ist)
    minetest.register_craft({
        type = "cooking",
        output = "is_core:ingot_" .. elem.name,
        recipe = "is_core:lump_" .. elem.name,
        cooktime = 7 -- Etwas langsamer, da Pulverisieren effizienter sein soll
    })

    -- Schmelzen: Staub (Powder) -> Ingot
    minetest.register_craft({
        type = "cooking",
        output = "is_core:ingot_" .. elem.name,
        recipe = "is_core:powder_" .. elem.name,
        cooktime = 4
    })
end
-------------------------------------------------------------------------------
-- TON- UND ZIEGEL-REZEPTE (NEU)
-------------------------------------------------------------------------------

local clay_colors = { "brown", "yellow", "red", "grey" }

for _, color in ipairs(clay_colors) do
    -- 1. Ofen: Jede Farbe Raw Clay -> Default Tonziegel (deine Notlösung/Standard)
    minetest.register_craft({
        type = "cooking",
        output = "default:clay_brick",
        recipe = "is_core:clay_raw_" .. color,
        cooktime = 3,
    })

    -- 2. Crafting: Raw Clay reinigen (z.B. mit einem Sieb oder einfach 1:1, hier als Platzhalter 1:1)
    -- Tipp: Wenn du einen Pulverizer/Sifter baust, kannst du das später dorthin verlegen.
    minetest.register_craft({
        output = "is_core:clay_clean_" .. color,
        recipe = {
            {"is_core:clay_raw_" .. color},
        }
    })

    -- 3. Ofen: Clean Clay -> Farbige Clean Clay Bricks (Items)
    minetest.register_craft({
        type = "cooking",
        output = "is_core:brick_clean_" .. color,
        recipe = "is_core:clay_clean_" .. color,
        cooktime = 4,
    })

    -- 4. Crafting: 4x Farbige Bricks (2x2) -> Farbiger Ziegelblock
    minetest.register_craft({
        output = "is_core:brick_block_" .. color,
        recipe = {
            {"is_core:brick_clean_" .. color, "is_core:brick_clean_" .. color},
            {"is_core:brick_clean_" .. color, "is_core:brick_clean_" .. color},
        }
    })
end

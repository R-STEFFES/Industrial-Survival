-- sti_core/recipes.lua

for _, elem in ipairs(elements) do
    -- NEU: 9 Nuggets direkt zu einem Barren (Ingot) craften
    minetest.register_craft({
        output = "sti_core:ingot_" .. elem.name,
        recipe = {
            {"sti_core:nugget_" .. elem.name, "sti_core:nugget_" .. elem.name, "sti_core:nugget_" .. elem.name},
            {"sti_core:nugget_" .. elem.name, "sti_core:nugget_" .. elem.name, "sti_core:nugget_" .. elem.name},
            {"sti_core:nugget_" .. elem.name, "sti_core:nugget_" .. elem.name, "sti_core:nugget_" .. elem.name}
        }
    })

    minetest.register_craft({
        output = "sti_core:block_" .. elem.name,
        recipe = {
            {"sti_core:ingot_" .. elem.name, "sti_core:ingot_" .. elem.name, "sti_core:ingot_" .. elem.name},
            {"sti_core:ingot_" .. elem.name, "sti_core:ingot_" .. elem.name, "sti_core:ingot_" .. elem.name},
            {"sti_core:ingot_" .. elem.name, "sti_core:ingot_" .. elem.name, "sti_core:ingot_" .. elem.name}
        }
    })

    -- Schmelzen: Klumpen -> Ingot (Beibehalten als Notlösung, falls kein Pulverizer da ist)
    minetest.register_craft({
        type = "cooking",
        output = "sti_core:ingot_" .. elem.name,
        recipe = "sti_core:lump_" .. elem.name,
        cooktime = 7 -- Etwas langsamer, da Pulverisieren effizienter sein soll
    })

    -- Schmelzen: Staub (Powder) -> Ingot
    minetest.register_craft({
        type = "cooking",
        output = "sti_core:ingot_" .. elem.name,
        recipe = "sti_core:powder_" .. elem.name,
        cooktime = 4
    })
end

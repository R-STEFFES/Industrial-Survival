-- sti_core/init.lua
sti_core = {}

-------------------------------------------------------------------------------
-- 1. EXTERNE DATEN UND MATERIALIEN LADEN
-------------------------------------------------------------------------------
local modpath = minetest.get_modpath("sti_core")

dofile(modpath .. "/materials.lua")
dofile(modpath .. "/elements.lua")

local densities = {
    [1] = {suffix = "sparse", desc = "Geringe Dichte", yield = 1, texture = "sti_core_ore_sparse.png"},
    [2] = {suffix = "medium", desc = "Mittlere Dichte", yield = 3, texture = "sti_core_ore_medium.png"},
    [3] = {suffix = "dense",  desc = "Hohe Dichte",      yield = 5, texture = "sti_core_ore_dense.png"},
}

-------------------------------------------------------------------------------
-- 2. VERARBEITUNGS-ITEMS (ERZE)
-------------------------------------------------------------------------------
for _, elem in ipairs(elements) do
    local items = {"nugget", "powder", "lump", "ingot"}
    for _, item in ipairs(items) do
        minetest.register_craftitem("sti_core:" .. item .. "_" .. elem.name, {
            description = elem.desc .. "-" .. item,
            inventory_image = "sti_core_" .. item .. ".png^[multiply:" .. elem.color,
        })
    end

    minetest.register_node("sti_core:block_" .. elem.name, {
        description = elem.desc .. "-Block",
        tiles = {"sti_core_block.png^[multiply:" .. elem.color},
        groups = {cracky = 2, stone = 1},
        sounds = default.node_sound_stone_defaults(),
    })
end

-- Rezepte laden (Erze, Metalle und die neuen Ton-Rezepte)
dofile(modpath .. "/recipes.lua")

-------------------------------------------------------------------------------
-- 3. BASIS-BLÖCKE & ERZ-MATRIX GENERIEREN
-------------------------------------------------------------------------------
for _, mat in ipairs(sti_core.base_materials) do
    local mat_sounds = (mat.type == "dirt") and default.node_sound_dirt_defaults() or default.node_sound_stone_defaults()

    -- Basis-Node registrieren
    minetest.register_node("sti_core:" .. mat.name, {
        description = mat.desc,
        tiles = {mat.texture},
        groups = mat.group,
        sounds = mat_sounds,
    })

    -- Erz-Varianten (Overlay-Technik)
    for _, elem in ipairs(elements) do
        for _, d_data in ipairs(densities) do

            minetest.register_node("sti_core:" .. mat.name .. "_with_" .. elem.name .. "_" .. d_data.suffix, {
                description = mat.desc .. " mit " .. elem.desc .. " (" .. d_data.desc .. ")",
                tiles = {mat.texture},
                overlay_tiles = {d_data.texture .. "^[multiply:" .. elem.color},
                groups = mat.group,
                sounds = mat_sounds,
                drop = {
                    max_items = d_data.yield,
                    items = {{items = {"sti_core:lump_" .. elem.name .. " " .. d_data.yield}}}
                }
            })
        end
    end
end

-------------------------------------------------------------------------------
-- 4. DROP-OVERRIDES FÜR FARBIGEN LEHM
-------------------------------------------------------------------------------
-- Erst nach der Registrierung der Basis-Knoten können wir deren Drop-Verhalten überschreiben
minetest.override_item("sti_core:loam_brown",  { drop = "sti_core:clay_raw_brown 4" })
minetest.override_item("sti_core:loam_yellow", { drop = "sti_core:clay_raw_yellow 4" })
minetest.override_item("sti_core:loam_red",    { drop = "sti_core:clay_raw_red 4" })
minetest.override_item("sti_core:loam_grey",   { drop = "sti_core:clay_raw_grey 4" })

-------------------------------------------------------------------------------
-- 5. TOOLS & ARMOR
-------------------------------------------------------------------------------
dofile(modpath .. "/tools_armor.lua")

print("[sti_core] Erzmatrix und Materialsystem erfolgreich geladen!")

-- sti_core/init.lua
sti_core = {}

-------------------------------------------------------------------------------
-- 1. DATEN-TABELLEN DEFINIEREN
-------------------------------------------------------------------------------

local base_materials = {
    {name = "stone",         desc = "Stein",           type = "stone", group = {cracky = 3, stone = 1}, texture = "default_stone.png"},
    {name = "limestone",     desc = "Kalkstein",       type = "stone", group = {cracky = 3, stone = 1}, texture = "sti_core_limestone.png"},
    {name = "basalt",        desc = "Basalt",          type = "stone", group = {cracky = 2, stone = 1}, texture = "sti_core_basalt.png"},
    {name = "granite",       desc = "Granit",          type = "stone", group = {cracky = 2, stone = 1}, texture = "sti_core_granite.png"},
    {name = "peat",          desc = "Torf",            type = "dirt",  group = {crumbly = 3},           texture = "sti_core_peat.png"},
    {name = "gravel_coarse", desc = "Schotter",        type = "dirt",  group = {crumbly = 2},           texture = "sti_core_gravel_coarse.png"},
    {name = "gravel",        desc = "Kies",            type = "dirt",  group = {crumbly = 2},           texture = "default_gravel.png"},
    {name = "sand",          desc = "Sand",            type = "dirt",  group = {crumbly = 3, sand = 1}, texture = "default_sand.png"},
    {name = "loamy_sand",    desc = "Lehmsand-Gemisch", type = "dirt", group = {crumbly = 3},           texture = "sti_core_loamy_sand.png"},
    {name = "silt",          desc = "Schluff",         type = "dirt",  group = {crumbly = 3},           texture = "sti_core_silt.png"},
    {name = "clay",          desc = "Ton",             type = "dirt",  group = {crumbly = 3},           texture = "default_clay.png"},
    {name = "loam_brown",    desc = "Brauner Lehm",    type = "dirt", group = {crumbly = 3}, texture = "sti_core_loam.png^[multiply:#8b5a2b"},
    {name = "loam_yellow",   desc = "Gelber Lehm",     type = "dirt", group = {crumbly = 3}, texture = "sti_core_loam.png^[multiply:#cd9b1d"},
    {name = "loam_red",      desc = "Roter Lehm",      type = "dirt", group = {crumbly = 3}, texture = "sti_core_loam.png^[multiply:#a0522d"},
    {name = "loam_grey",     desc = "Grauer Lehm",     type = "dirt", group = {crumbly = 3}, texture = "sti_core_loam.png^[multiply:#708090"},
}

dofile(minetest.get_modpath("sti_core") .. "/elements.lua")

local densities = {
    [1] = {suffix = "sparse", desc = "Geringe Dichte", yield = 1, texture = "sti_core_ore_sparse.png"},
    [2] = {suffix = "medium", desc = "Mittlere Dichte", yield = 3, texture = "sti_core_ore_medium.png"},
    [3] = {suffix = "dense",  desc = "Hohe Dichte",      yield = 5, texture = "sti_core_ore_dense.png"},
}

-------------------------------------------------------------------------------
-- 2. VERARBEITUNGS-ITEMS
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
dofile(minetest.get_modpath("sti_core") .. "/recipes.lua")
-------------------------------------------------------------------------------
-- 3. BASIS-BLÖCKE & ERZ-MATRIX
-------------------------------------------------------------------------------
for _, mat in ipairs(base_materials) do
    local mat_sounds = (mat.type == "dirt") and default.node_sound_dirt_defaults() or default.node_sound_stone_defaults()

    -- Basis-Node
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

                -- HINTERGRUND: Der Stein (bleibt immer original)
                tiles = {mat.texture},

                -- OVERLAY: Nur das Erz-PNG bekommt den Multiply-Filter
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
dofile(minetest.get_modpath("sti_core") .. "/tools_armor.lua")
print("[sti_core] Erzmatrix erfolgreich mit Overlay-Technik generiert!")

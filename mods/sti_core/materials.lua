-- sti_core/materials.lua

-------------------------------------------------------------------------------
-- 1. BASIS-MATERIALIEN DEFINIEREN
-------------------------------------------------------------------------------
sti_core.base_materials = {
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

-------------------------------------------------------------------------------
-- 2. ERWEITERTE TON- UND LEHMANPASSUNGEN (ITEMS & BLÖCKE)
-------------------------------------------------------------------------------
local clay_colors = {
    {name = "brown",  desc = "Brauner",  color = "#8b5a2b"},
    {name = "yellow", desc = "Gelber",   color = "#cd9b1d"},
    {name = "red",    desc = "Roter",    color = "#a0522d"},
    {name = "grey",   desc = "Grauer",   color = "#708090"},
}

for _, c in ipairs(clay_colors) do
    -- Roher Ton (Drop beim Abbauen)
    minetest.register_craftitem("sti_core:clay_raw_" .. c.name, {
        description = c.desc .. " roher Ton",
        inventory_image = "sti_core_clay_raw.png^[multiply:" .. c.color,
    })

    -- Gereinigter Ton
    minetest.register_craftitem("sti_core:clay_clean_" .. c.name, {
        description = c.desc .. " gereinigter Ton",
        inventory_image = "sti_core_clay_clean.png^[multiply:" .. c.color,
    })

    -- Einzelner Ziegel (Item)
    minetest.register_craftitem("sti_core:brick_clean_" .. c.name, {
        description = c.desc .. " Tonziegel",
        inventory_image = "sti_core_brick.png^[multiply:" .. c.color,
    })

    -- Ziegelblock (Node)
    minetest.register_node("sti_core:brick_block_" .. c.name, {
        description = c.desc .. " Ziegelblock",
        tiles = {"sti_core_brick_block.png^[multiply:" .. c.color},
        groups = {cracky = 3, stone = 1},
        sounds = default.node_sound_stone_defaults(),
    })
end

-- Rohes Torfstück (Drop beim Abbauen & Brennstoff)
minetest.register_craftitem("sti_core:peat_piece", {
    description = "Torfstück",
    inventory_image = "sti_core_peat_lump.png",
})

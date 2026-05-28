-- sti_core/init.lua

sti_core = {}

-------------------------------------------------------------------------------
-- 1. DATEN-TABELLEN DEFINIEREN
-------------------------------------------------------------------------------

-- Alle Gesteins- und Bodentypen (Die Trägermedien für Erze)
local base_materials = {
    -- Kategorie: Festgestein (cracky)
    {name = "stone",     desc = "Stein",       type = "stone",  group = {cracky = 3, stone = 1}, texture = "default_stone.png"},
    {name = "limestone", desc = "Kalkstein",   type = "stone",  group = {cracky = 3, stone = 1}, texture = "sti_core_limestone.png"},
    {name = "basalt",    desc = "Basalt",      type = "stone",  group = {cracky = 2, stone = 1}, texture = "sti_core_basalt.png"},
    {name = "granite",   desc = "Granit",      type = "stone",  group = {cracky = 2, stone = 1}, texture = "sti_core_granite.png"},

    -- Kategorie: Lockergestein / Böden (crumbly)
    {name = "peat",      desc = "Torf",        type = "dirt",   group = {crumbly = 3},           texture = "sti_core_peat.png"},
    {name = "gravel_coarse", desc = "Schotter", type = "dirt",   group = {crumbly = 2},           texture = "sti_core_gravel_coarse.png"},
    {name = "gravel",    desc = "Kies",        type = "dirt",   group = {crumbly = 2},           texture = "default_gravel.png"},
    {name = "sand",      desc = "Sand",        type = "dirt",   group = {crumbly = 3, sand = 1}, texture = "default_sand.png"},
    {name = "loamy_sand", desc = "Lehmsand-Gemisch", type = "dirt", group = {crumbly = 3},       texture = "sti_core_loamy_sand.png"},
    {name = "silt",      desc = "Schluff",     type = "dirt",   group = {crumbly = 3},           texture = "sti_core_silt.png"},
    {name = "clay",      desc = "Ton",         type = "dirt",   group = {crumbly = 3},           texture = "default_clay.png"},

    -- Lehmvarianten (Farben aus der Natur)
    {name = "loam_brown",  desc = "Brauner Lehm",  type = "dirt", group = {crumbly = 3}, texture = "sti_core_loam.png^[multiply:#8b5a2b"},
    {name = "loam_yellow", desc = "Gelber Lehm",   type = "dirt", group = {crumbly = 3}, texture = "sti_core_loam.png^[multiply:#cd9b1d"},
    {name = "loam_red",    desc = "Roter Lehm",    type = "dirt", group = {crumbly = 3}, texture = "sti_core_loam.png^[multiply:#a0522d"},
    {name = "loam_grey",   desc = "Grauer Lehm",   type = "dirt", group = {crumbly = 3}, texture = "sti_core_loam.png^[multiply:#708090"},
}

-- Alle Erze / Elemente
local elements = {
    {name = "gold",      desc = "Gold",      color = "#ffd700"},
    {name = "silver",    desc = "Silber",    color = "#e5e5e5"},
    {name = "platinum",  desc = "Platin",    color = "#e5e4e2"},
    {name = "iron",      desc = "Eisen",     color = "#8b4513"},
    {name = "copper",    desc = "Kupfer",    color = "#d2691e"},
    {name = "aluminum",  desc = "Aluminium", color = "#b2beb5"},
    {name = "titanium",  desc = "Titan",     color = "#708090"},
    {name = "nickel",    desc = "Nickel",    color = "#aca79e"},
    {name = "zinc",      desc = "Zink",      color = "#bac4c8"},
    {name = "lead",      desc = "Blei",      color = "#4f5d65"},
    {name = "tin",       desc = "Zinn",      color = "#ebebeb"},
    {name = "lithium",   desc = "Lithium",   color = "#e0e0e0"},
    {name = "tungsten",  desc = "Wolfram",   color = "#3d4246"},
    {name = "sulfur",    desc = "Schwefel",  color = "#e6e6fa"},
    {name = "silicon",   desc = "Silizium",  color = "#555555"},
    {name = "carbon",    desc = "Kohlenstoff", color = "#222222"},
    {name = "uranium",   desc = "Uran",      color = "#39ff14"},
    {name = "thorium",   desc = "Thorium",   color = "#4a5d4e"},
}

-- Erz-Dichten Definition
local densities = {
    [1] = {suffix = "sparse", desc = "Geringe Dichte", yield = 1, texture = "sti_core_ore_sparse.png"},
    [2] = {suffix = "medium", desc = "Mittlere Dichte", yield = 3, texture = "sti_core_ore_medium.png"},
    [3] = {suffix = "dense",  desc = "Hohe Dichte",    yield = 6, texture = "sti_core_ore_dense.png"},
}

-------------------------------------------------------------------------------
-- 2. VERARBEITUNGS-ITEMS REGISTRIEREN (Lump, Ingot, Nugget, Powder)
-------------------------------------------------------------------------------
for _, elem in ipairs(elements) do
    -- Nugget
    minetest.register_craftitem("sti_core:nugget_" .. elem.name, {
        description = elem.desc .. "-Nugget",
        inventory_image = "sti_core_nugget.png^[multiply:" .. elem.color,
    })

    -- Powder
    minetest.register_craftitem("sti_core:powder_" .. elem.name, {
        description = elem.desc .. "-Pulver",
        inventory_image = "sti_core_powder.png^[multiply:" .. elem.color,
    })

    -- Normaler Brocken (Lump)
    minetest.register_craftitem("sti_core:lump_" .. elem.name, {
        description = elem.desc .. "-Brocken",
        inventory_image = "sti_core_lump.png^[multiply:" .. elem.color,
    })

    -- Barren (Ingot)
    minetest.register_craftitem("sti_core:ingot_" .. elem.name, {
        description = elem.desc .. "-Barren",
        inventory_image = "sti_core_ingot.png^[multiply:" .. elem.color,
    })

    -- Kompakter Metallblock
    minetest.register_node("sti_core:block_" .. elem.name, {
        description = elem.desc .. "-Block",
        tiles = {"sti_core_block.png^[multiply:" .. elem.color},
        is_ground_content = false,
        groups = {cracky = 2, stone = 1},
        sounds = default.node_sound_stone_defaults(),
    })

    ---------------------------------------------------------------------------
    -- CRAFTING REZEPTE
    ---------------------------------------------------------------------------
    minetest.register_craft({
        output = "sti_core:lump_" .. elem.name,
        recipe = {
            {"sti_core:nugget_"..elem.name, "sti_core:nugget_"..elem.name, "sti_core:nugget_"..elem.name},
            {"sti_core:nugget_"..elem.name, "sti_core:nugget_"..elem.name, "sti_core:nugget_"..elem.name},
            {"sti_core:nugget_"..elem.name, "sti_core:nugget_"..elem.name, "sti_core:nugget_"..elem.name},
        }
    })

    minetest.register_craft({
        output = "sti_core:nugget_" .. elem.name .. " 9",
        recipe = {{"sti_core:lump_" .. elem.name}}
    })

    minetest.register_craft({
        type = "cooking",
        output = "sti_core:ingot_" .. elem.name,
        recipe = "sti_core:lump_" .. elem.name,
        cooktime = 5
    })

    minetest.register_craft({
        type = "cooking",
        output = "sti_core:ingot_" .. elem.name,
        recipe = "sti_core:powder_" .. elem.name,
        cooktime = 4
    })
end

-------------------------------------------------------------------------------
-- 3. BASIS-BLÖCKE & ERZ-MATRIX REGISTRIEREN (Dichte 0 bis 3)
-------------------------------------------------------------------------------
for _, mat in ipairs(base_materials) do

    local mat_sounds = default.node_sound_stone_defaults()
    if mat.type == "dirt" then
        mat_sounds = default.node_sound_dirt_defaults()
    end

    -- DICHTE 0: Der normale Basis-Block ohne Erz
    minetest.register_node("sti_core:" .. mat.name, {
        description = mat.desc,
        tiles = {mat.texture},
        groups = mat.group,
        sounds = mat_sounds,
    })

    -- DICHTE 1 bis 3: Generiere für JEDES Material JEDES Erz in DREI Dichten
    for _, elem in ipairs(elements) do
        for d_num, d_data in ipairs(densities) do

            local node_name = "sti_core:" .. mat.name .. "_with_" .. elem.name .. "_" .. d_data.suffix
            local node_desc = mat.desc .. " mit " .. elem.desc .. " (" .. d_data.desc .. ")"

            -- ULTIMATIVE LÖSUNG: [combine zwingt Luanti, eine neue Leinwand (16x16 Pixel) zu erstellen.
            -- Erst wird das Basis-Material bei Position 0,0 gezeichnet.
            -- Dann wird das Erz-Template bei Position 0,0 darübergezeichnet – ABER modifiziert mit dem multiply-Filter.
            -- Da der Filter hinter dem Doppelpunkt des zweiten Bildes steht, bleibt er dort gefangen!
            local final_texture = "[combine:16x16:0,0=" .. mat.texture .. ":0,0=" .. d_data.texture .. "^[multiply:" .. elem.color

            minetest.register_node(node_name, {
                description = node_desc,
                tiles = {final_texture},
                groups = mat.group,
                sounds = mat_sounds,
                drop = {
                    max_items = d_data.yield,
                    items = {
                        {
                            items = {"sti_core:nugget_" .. elem.name .. " " .. d_data.yield},
                            rarity = 1,
                        }
                    }
                }
            })
        end
    end
end

print("[sti_core] Gewaltige Erzmatrix und Gesteinsarten erfolgreich generiert!")

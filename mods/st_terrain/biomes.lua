-- st_terrain/biomes.lua
-- Biom-Definitionen für st_terrain
-- Nutzt sti_core-Materialien als Oberflächen- und Füllmaterial.
-- Nur für nicht-v6 Mapgen relevant.

local mg_name = minetest.get_mapgen_setting("mg_name")
if mg_name == "v6" then
    minetest.log("action", "[st_terrain] v6-Mapgen: Biome werden übersprungen (v6 nutzt eigene Biome).")
    return
end

-------------------------------------------------------------------------------
-- HILFSFUNKTION: Fallback auf default-Node falls vorhanden
-------------------------------------------------------------------------------
local function node_or_fallback(preferred, fallback)
    if minetest.registered_nodes[preferred] then
        return preferred
    end
    return fallback
end

local grass   = node_or_fallback("default:dirt_with_grass",   "sti_core:loam_brown")
local dirt    = node_or_fallback("default:dirt",              "sti_core:loam_brown")
local snow_d  = node_or_fallback("default:dirt_with_snow",    "sti_core:loam_grey")
local snowb   = node_or_fallback("default:snowblock",         "sti_core:gravel")
local ice     = node_or_fallback("default:ice",               "sti_core:stone")
local drydirt = node_or_fallback("default:dry_dirt_with_dry_grass", "sti_core:loam_red")
local dess    = node_or_fallback("default:desert_stone",      "sti_core:stone")

-------------------------------------------------------------------------------
-- GEMÄSSIGTE / FEUCHTE ZONEN
-------------------------------------------------------------------------------

-- Grasland (Mitteleuropäisch standard)
minetest.register_biome({
    name           = "st_grassland",
    node_top       = grass,
    depth_top      = 1,
    node_filler    = dirt,
    depth_filler   = 3,
    node_stone     = "sti_core:stone",
    y_max          = 120,
    y_min          = 4,
    heat_point     = 50,
    humidity_point = 50,
})

-- Laubwald (Etwas feuchter und wärmer als Grasland)
minetest.register_biome({
    name           = "st_deciduous_forest",
    node_top       = grass,
    depth_top      = 1,
    node_filler    = dirt,
    depth_filler   = 4,
    node_stone     = "sti_core:stone",
    y_max          = 90,
    y_min          = 3,
    heat_point     = 60,
    humidity_point = 68,
})

-- Sumpf / Bruchwald (Sehr feucht, tief gelegen)
minetest.register_biome({
    name           = "st_swamp",
    node_top       = "sti_core:silt",
    depth_top      = 2,
    node_filler    = "sti_core:loam_grey",
    depth_filler   = 4,
    node_stone     = "sti_core:limestone",
    y_max          = 5,
    y_min          = -1,
    heat_point     = 58,
    humidity_point = 85,
})

-------------------------------------------------------------------------------
-- KALTE / ARKTISCHE ZONEN
-------------------------------------------------------------------------------

-- Taiga / Nadelwald (Kalt, mäßig feucht)
minetest.register_biome({
    name           = "st_taiga",
    node_top       = "default:dirt_with_coniferous_litter",
    depth_top      = 1,
    node_filler    = dirt,
    depth_filler   = 3,
    node_stone     = "sti_core:stone",
    y_max          = 250,
    y_min          = 8,
    heat_point     = 30,
    humidity_point = 55,
})

-- Verschneites Grasland
minetest.register_biome({
    name           = "st_snowy_grassland",
    node_top       = snow_d,
    depth_top      = 1,
    node_filler    = dirt,
    depth_filler   = 2,
    node_stone     = "sti_core:stone",
    y_max          = 400,
    y_min          = 20,
    heat_point     = 20,
    humidity_point = 45,
})

-- Tundra (Sehr kalt, trocken, Permafrost)
minetest.register_biome({
    name           = "st_tundra",
    node_top       = "sti_core:loam_grey",
    depth_top      = 1,
    node_filler    = "sti_core:gravel",
    depth_filler   = 4,
    node_stone     = "sti_core:granite",
    y_max          = 1000,
    y_min          = 15,
    heat_point     = 10,
    humidity_point = 25,
})

-- Alpine Zone (Hochgebirge, nackter Fels und Geröll)
minetest.register_biome({
    name           = "st_alpine",
    node_top       = "sti_core:gravel",
    depth_top      = 2,
    node_filler    = "sti_core:stone",
    depth_filler   = 5,
    node_stone     = "sti_core:granite",
    y_max          = 31000,
    y_min          = 120,
    heat_point     = 25,
    humidity_point = 40,
})

-------------------------------------------------------------------------------
-- WARME / TROCKENE / TROPISCHE ZONEN
-------------------------------------------------------------------------------

-- Savanne (Heiß, wechselfeucht, Laterit-Böden)
minetest.register_biome({
    name           = "st_savanna",
    node_top       = drydirt,
    depth_top      = 1,
    node_filler    = "sti_core:loam_red",
    depth_filler   = 4,
    node_stone     = "sti_core:stone",
    y_max          = 150,
    y_min          = 5,
    heat_point     = 75,
    humidity_point = 35,
})

-- Tropischer Regenwald (Sehr heiß, sehr feucht)
minetest.register_biome({
    name           = "st_rainforest",
    node_top       = "default:dirt_with_rainforest_litter",
    depth_top      = 1,
    node_filler    = "sti_core:loam_brown",
    depth_filler   = 5,
    node_stone     = "sti_core:basalt",
    y_max          = 100,
    y_min          = 2,
    heat_point     = 85,
    humidity_point = 85,
})

-- Sandwüste (Heiß, extrem trocken)
minetest.register_biome({
    name           = "st_desert",
    node_top       = "sti_core:sand",
    depth_top      = 3,
    node_filler    = "sti_core:sand",
    depth_filler   = 4,
    node_stone     = dess,
    y_max          = 1000,
    y_min          = 3,
    heat_point     = 85,
    humidity_point = 10,
})

-- Felswüste / Badlands (Heiß, trocken, nackter Ton/Kalkstein)
minetest.register_biome({
    name           = "st_rocky_desert",
    node_top       = "sti_core:loam_red",
    depth_top      = 1,
    node_filler    = "sti_core:sandstone",
    depth_filler   = 6,
    node_stone     = "sti_core:limestone",
    y_max          = 1200,
    y_min          = 10,
    heat_point     = 90,
    humidity_point = 5,
})

-------------------------------------------------------------------------------
-- KÜSTEN / GEWÄSSER
-------------------------------------------------------------------------------

-- Strand (Sand, Kies darunter, Stein darunter)
minetest.register_biome({
    name           = "st_beach",
    node_top       = "sti_core:sand",
    depth_top      = 2,
    node_filler    = "sti_core:gravel",
    depth_filler   = 2,
    node_stone     = "sti_core:stone",
    y_max          = 4,
    y_min          = -5,
    heat_point     = 48,
    humidity_point = 48,
})

-- Schlickwatt (Silt/Schluff an Küste)
minetest.register_biome({
    name           = "st_mudflat",
    node_top       = "sti_core:silt",
    depth_top      = 2,
    node_filler    = "sti_core:loam_grey",
    depth_filler   = 3,
    node_stone     = "sti_core:limestone",
    y_max          = 1,
    y_min          = -8,
    heat_point     = 52,
    humidity_point = 70,
})

-- Unterwasser / Ozean-Boden (Kies und Sand)
minetest.register_biome({
    name           = "st_ocean",
    node_top       = "sti_core:sand",
    depth_top      = 2,
    node_filler    = "sti_core:gravel",
    depth_filler   = 5,
    node_stone     = "sti_core:basalt",
    y_max          = -4,
    y_min          = -31000,
    heat_point     = 50,
    humidity_point = 50,
})

-------------------------------------------------------------------------------
-- EXPORT FÜR DEN CUSTOM MAPGEN
-------------------------------------------------------------------------------
st_terrain = st_terrain or {}
st_terrain.biome_list = {
    "st_grassland", "st_deciduous_forest", "st_swamp", "st_taiga",
    "st_snowy_grassland", "st_tundra", "st_alpine", "st_savanna",
    "st_rainforest", "st_desert", "st_rocky_desert", "st_beach",
    "st_mudflat", "st_ocean"
}

minetest.log("action", "[st_terrain] " .. tostring(#st_terrain.biome_list) .. " Biome erfolgreich für Engine und Mapgen bereitgestellt.")

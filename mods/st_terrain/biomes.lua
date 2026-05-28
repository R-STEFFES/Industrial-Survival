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
local dess    = node_or_fallback("default:desert_stone",      "sti_core:limestone")

-------------------------------------------------------------------------------
-- GEMÄSSIGTE ZONE
-------------------------------------------------------------------------------

-- Tiefland-Grasland (fruchtbarer Lehmboden)
minetest.register_biome({
    name           = "st_grassland",
    node_top       = grass,
    depth_top      = 1,
    node_filler    = dirt,
    depth_filler   = 3,
    node_stone     = "sti_core:stone",
    node_water_top = node_or_fallback("default:water_source", "air"),
    y_max          = 80,
    y_min          = 5,
    heat_point     = 50,
    humidity_point = 50,
})

-- Laubwald (brauner Lehmboden, organisch reich)
minetest.register_biome({
    name           = "st_deciduous_forest",
    node_top       = grass,
    depth_top      = 1,
    node_filler    = "sti_core:loam_brown",
    depth_filler   = 4,
    node_stone     = "sti_core:stone",
    node_water_top = node_or_fallback("default:water_source", "air"),
    y_max          = 120,
    y_min          = 5,
    heat_point     = 60,
    humidity_point = 68,
})

-- Sumpf / Feuchtgebiet (Torf oben, dann Lehm)
minetest.register_biome({
    name           = "st_swamp",
    node_top       = "sti_core:peat",
    depth_top      = 2,
    node_filler    = "sti_core:loam_grey",
    depth_filler   = 5,
    node_stone     = "sti_core:limestone",
    node_water_top = node_or_fallback("default:water_source", "air"),
    y_max          = 3,
    y_min          = -3,
    heat_point     = 55,
    humidity_point = 85,
})

-------------------------------------------------------------------------------
-- KALTE / ALPINE ZONE
-------------------------------------------------------------------------------

-- Nadelwald / Taiga (sandig-lehmiger Boden)
minetest.register_biome({
    name           = "st_taiga",
    node_top       = snow_d,
    depth_top      = 1,
    node_filler    = "sti_core:loam_grey",
    depth_filler   = 3,
    node_stone     = "sti_core:granite",
    node_water_top = node_or_fallback("default:water_source", "air"),
    node_river_water = node_or_fallback("default:river_water_source", "air"),
    y_max          = 160,
    y_min          = 5,
    heat_point     = 25,
    humidity_point = 60,
})

-- Schneebedecktes Grasland
minetest.register_biome({
    name           = "st_snowy_grassland",
    node_top       = snowb,
    depth_top      = 1,
    node_filler    = "sti_core:loam_grey",
    depth_filler   = 3,
    node_stone     = "sti_core:stone",
    y_max          = 100,
    y_min          = 5,
    heat_point     = 20,
    humidity_point = 40,
})

-- Tundra (Permafrost-Analogon: grauer Lehm, kaum Vegetation)
minetest.register_biome({
    name           = "st_tundra",
    node_top       = "sti_core:gravel_coarse",
    depth_top      = 1,
    node_filler    = "sti_core:loam_grey",
    depth_filler   = 2,
    node_stone     = "sti_core:granite",
    y_max          = 80,
    y_min          = 2,
    heat_point     = 5,
    humidity_point = 30,
})

-- Hochgebirge / Alpine (Granit an Oberfläche, kaum Boden)
minetest.register_biome({
    name           = "st_alpine",
    node_top       = "sti_core:granite",
    depth_top      = 1,
    node_filler    = "sti_core:gravel_coarse",
    depth_filler   = 2,
    node_stone     = "sti_core:granite",
    y_max          = 31000,
    y_min          = 150,
    heat_point     = 15,
    humidity_point = 40,
})

-------------------------------------------------------------------------------
-- WARME / TROCKENE ZONE
-------------------------------------------------------------------------------

-- Savanne (roter Lehm, trocken)
minetest.register_biome({
    name           = "st_savanna",
    node_top       = drydirt,
    depth_top      = 1,
    node_filler    = "sti_core:loam_red",
    depth_filler   = 4,
    node_stone     = "sti_core:stone",
    y_max          = 100,
    y_min          = 2,
    heat_point     = 75,
    humidity_point = 30,
})

-- Regenwald (sehr fruchtbarer Boden, gelber Lehm unter Oberfläche)
minetest.register_biome({
    name           = "st_rainforest",
    node_top       = grass,
    depth_top      = 1,
    node_filler    = "sti_core:loam_yellow",
    depth_filler   = 5,
    node_stone     = "sti_core:stone",
    y_max          = 120,
    y_min          = 2,
    heat_point     = 85,
    humidity_point = 90,
})

-- Wüste (Sand oben, Kalkstein unten)
minetest.register_biome({
    name           = "st_desert",
    node_top       = "sti_core:sand",
    depth_top      = 3,
    node_filler    = "sti_core:gravel",
    depth_filler   = 3,
    node_stone     = "sti_core:limestone",
    y_max          = 100,
    y_min          = 2,
    heat_point     = 95,
    humidity_point = 10,
})

-- Sandstein-Wüste (Kalkstein direkt an Oberfläche, Schotterfüllung)
minetest.register_biome({
    name           = "st_rocky_desert",
    node_top       = "sti_core:limestone",
    depth_top      = 1,
    node_filler    = "sti_core:gravel_coarse",
    depth_filler   = 3,
    node_stone     = "sti_core:limestone",
    y_max          = 100,
    y_min          = 2,
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
    depth_filler   = 3,
    node_stone     = "sti_core:basalt",  -- ozeanische Kruste = Basalt
    y_max          = -5,
    y_min          = -31000,
    heat_point     = 50,
    humidity_point = 50,
})

minetest.log("action", "[st_terrain] " ..
    tostring(#minetest.registered_biomes or 0) .. " Biome registriert.")

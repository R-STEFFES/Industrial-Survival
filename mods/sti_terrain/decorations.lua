-- st_terrain/decorations.lua
-- Oberflächendekorationen
-- Felsbrocken, Gesteinsaufschlüsse, Rohstofflinsen an der Oberfläche.
-- Gibt der Welt geologische Oberflächendetails.

local mg_name = minetest.get_mapgen_setting("mg_name")
if mg_name == "v6" then
    minetest.log("action", "[st_terrain] v6-Mapgen: Biom-Dekorationen übersprungen.")
    return
end

-------------------------------------------------------------------------------
-- HILFSFUNKTION: Einzelnen Felsbrocken registrieren
-------------------------------------------------------------------------------
local function register_boulder(node, place_on, biomes, fill_ratio, y_max, y_min, seed_offset)
    minetest.register_decoration({
        deco_type  = "simple",
        place_on   = place_on,
        sidelen    = 16,
        noise_params = {
            offset   = -0.004,
            scale    = 0.01,
            spread   = {x = 100, y = 100, z = 100},
            seed     = 5000 + (seed_offset or 0),
            octaves  = 3,
            persist  = 0.7,
        },
        biomes     = biomes,
        y_max      = y_max or 31000,
        y_min      = y_min or 1,
        decoration = node,
        param2     = 0,
    })
end

-------------------------------------------------------------------------------
-- KALKSTEIN-AUFSCHLÜSSE
-- Typisch in Tälern, Hügeln, wo Sedimentgestein erodiert ist.
-------------------------------------------------------------------------------
register_boulder(
    "sti_core:limestone",
    {"default:dirt_with_grass","sti_core:loam_brown","sti_core:gravel_coarse"},
    {"st_grassland","st_deciduous_forest","st_beach"},
    nil, 120, 1, 100
)

-------------------------------------------------------------------------------
-- GRANIT-AUFSCHLÜSSE
-- Typisch im Hochgebirge / erodierten Schildgebieten.
-------------------------------------------------------------------------------
register_boulder(
    "sti_core:granite",
    {"sti_core:granite","sti_core:gravel_coarse","default:dirt_with_grass"},
    {"st_alpine","st_taiga","st_tundra","st_snowy_grassland"},
    nil, 31000, 60, 200
)

-- Einzelne Granitbrocken auch im Tiefland (Findlinge / glazial)
register_boulder(
    "sti_core:granite",
    {"default:dirt_with_grass","sti_core:loam_brown","sti_core:gravel"},
    {"st_grassland","st_taiga","st_snowy_grassland"},
    nil, 100, 1, 201
)

-------------------------------------------------------------------------------
-- BASALT-AUFSCHLÜSSE
-- Typisch in Vulkangebieten, auf Lavafeldern.
-------------------------------------------------------------------------------
register_boulder(
    "sti_core:basalt",
    {"default:dirt_with_grass","sti_core:loam_red","sti_core:stone"},
    {"st_savanna","st_rainforest"},
    nil, 200, 1, 300
)

-------------------------------------------------------------------------------
-- SCHOTTER-FELDER
-- Ausgedehnte Schotter-Dekorationen in Flussnähe / Gebirgsvorland.
-------------------------------------------------------------------------------
minetest.register_decoration({
    deco_type  = "simple",
    place_on   = {"sti_core:gravel","sti_core:gravel_coarse","sti_core:sand"},
    sidelen    = 8,
    fill_ratio = 0.05,
    biomes     = {"st_beach","st_alpine","st_tundra"},
    y_max      = 40,
    y_min      = -2,
    decoration = "sti_core:gravel_coarse",
})

-------------------------------------------------------------------------------
-- KIESBÄNKE (im Flussbett / Strand)
-------------------------------------------------------------------------------
minetest.register_decoration({
    deco_type  = "simple",
    place_on   = {"sti_core:sand","sti_core:silt"},
    sidelen    = 4,
    fill_ratio = 0.04,
    biomes     = {"st_beach","st_mudflat"},
    y_max      = 2,
    y_min      = -3,
    decoration = "sti_core:gravel",
})

-------------------------------------------------------------------------------
-- TORF-LINSEN AN DER OBERFLÄCHE (Mooraugen)
-------------------------------------------------------------------------------
minetest.register_decoration({
    deco_type  = "simple",
    place_on   = {"sti_core:loam_grey","sti_core:loam_brown","default:dirt"},
    sidelen    = 16,
    noise_params = {
        offset   = -0.3,
        scale    = 0.7,
        spread   = {x = 60, y = 60, z = 60},
        seed     = 7771,
        octaves  = 2,
        persist  = 0.6,
    },
    biomes     = {"st_swamp","st_taiga","st_deciduous_forest"},
    y_max      = 4,
    y_min      = 1,
    decoration = "sti_core:peat",
    place_offset_y = -1,
    flags = "force_placement",
})

-------------------------------------------------------------------------------
-- TON-LINSEN AN SEENUFERN / FLACHKÜSTEN
-------------------------------------------------------------------------------
minetest.register_decoration({
    deco_type  = "simple",
    place_on   = {"sti_core:silt","sti_core:loam_grey"},
    sidelen    = 4,
    fill_ratio = 0.06,
    biomes     = {"st_mudflat","st_swamp"},
    y_max      = 1,
    y_min      = -2,
    decoration = "sti_core:clay",
    place_offset_y = -1,
    flags = "force_placement",
})

-------------------------------------------------------------------------------
-- GERÖLL-STREUUNG im Hochgebirge (Alpine Zone)
-- Kleine Steinblöcke auf Granitoberfläche
-------------------------------------------------------------------------------
minetest.register_decoration({
    deco_type  = "simple",
    place_on   = {"sti_core:granite","sti_core:gravel_coarse"},
    sidelen    = 4,
    fill_ratio = 0.08,
    biomes     = {"st_alpine","st_tundra"},
    y_max      = 31000,
    y_min      = 120,
    decoration = {
        "sti_core:granite",
        "sti_core:stone",
        "sti_core:gravel_coarse",
    },
})

minetest.log("action", "[st_terrain] Dekorationen registriert.")

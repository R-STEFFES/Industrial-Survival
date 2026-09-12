-- st_terrain/geology.lua
-- Geologische Gesteinsschichten
--
-- SCHICHTMODELL (von oben nach unten):
--
--   y > 0      Lockersedimente: Torf, Lehm, Kies, Sand, Schluff, Ton
--   y 0..-30   Übergang Lockergestein → Festgestein, Lehmlinsen
--   y -20..-80  Obere Kalksteinbank (Sedimentgestein)
--   y -80..-200 Untere Kalksteinbank + erste Basalt-Intrusionen
--  y -80..-400 Granit-Körper beginnen (plutonisches Gestein)
--   y -200..-600 Basalt dominiert (ozeanische/vulkanische Kruste)
--   y < -400   Granit-Batholithen (tiefstes kontinentales Gestein)
--
-- REIHENFOLGE: Stratum zuerst, dann Blob.
-- Blob-Registrierungen überschreiben Stratum-Füllungen lokal.

-------------------------------------------------------------------------------
-- STRATUM: KALKSTEIN-BÄNKE (horizontale Sedimentschichten)
-------------------------------------------------------------------------------

-- Obere Kalksteinbank: y -20 bis -80, variiert per Noise
minetest.register_ore({
    ore_type          = "stratum",
    ore               = "sti_core:limestone",
    wherein           = {"sti_core:stone"},
    clust_scarcity    = 1,
    y_max             = -20,
    y_min             = -80,
    noise_params      = {
        offset  = -50,
        scale   = 25,
        spread  = {x = 256, y = 256, z = 256},
        seed    = 11100,
        octaves = 2,
    },
    stratum_thickness = 14,
})

-- Mittlere Kalksteinbank: y -100 bis -200
minetest.register_ore({
    ore_type          = "stratum",
    ore               = "sti_core:limestone",
    wherein           = {"sti_core:stone"},
    clust_scarcity    = 1,
    y_max             = -100,
    y_min             = -200,
    noise_params      = {
        offset  = -150,
        scale   = 40,
        spread  = {x = 256, y = 256, z = 256},
        seed    = 11200,
        octaves = 2,
    },
    stratum_thickness = 20,
})

-- Tiefe Kalksteinlinse: y -250 bis -350 (verkarstete Tiefzone)
minetest.register_ore({
    ore_type          = "stratum",
    ore               = "sti_core:limestone",
    wherein           = {"sti_core:stone"},
    clust_scarcity    = 1,
    y_max             = -250,
    y_min             = -350,
    noise_params      = {
        offset  = -300,
        scale   = 45,
        spread  = {x = 300, y = 300, z = 300},
        seed    = 11300,
        octaves = 2,
    },
    stratum_thickness = 10,
})

-------------------------------------------------------------------------------
-- BLOB: LOCKERSEDIMENTE (nahe Oberfläche, y +30 bis -80)
-------------------------------------------------------------------------------

-- Torf: Feuchtgebiete / Wälder, sehr oberflächennah
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:peat",
    wherein         = {"sti_core:stone"},
    clust_scarcity  = 14 * 14 * 14,
    clust_size      = 6,
    y_max           = 5,
    y_min           = -10,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.3, spread={x=8,y=8,z=8},
                       seed=9821, octaves=1, persist=0.0},
    biomes = {"st_swamp","st_deciduous_forest","st_taiga","st_rainforest"},
})

-- Schotter (grob): Flusstal / Schotterfelder
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:gravel_coarse",
    wherein         = {"sti_core:stone","sti_core:limestone"},
    clust_scarcity  = 12 * 12 * 12,
    clust_size      = 7,
    y_max           = 20,
    y_min           = -40,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.25, spread={x=9,y=9,z=9},
                       seed=3345, octaves=1, persist=0.0},
})

-- Kies (fein): häufig in Sedimenten
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:gravel",
    wherein         = {"sti_core:stone","sti_core:limestone"},
    clust_scarcity  = 10 * 10 * 10,
    clust_size      = 6,
    y_max           = 30,
    y_min           = -60,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.2, spread={x=7,y=7,z=7},
                       seed=766, octaves=1, persist=0.0},
})

-- Sand-Linsen (Aquifer-Analoga)
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:sand",
    wherein         = {"sti_core:stone","sti_core:limestone"},
    clust_scarcity  = 13 * 13 * 13,
    clust_size      = 5,
    y_max           = 10,
    y_min           = -30,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.2, spread={x=6,y=6,z=6},
                       seed=2316, octaves=1, persist=0.0},
})

-- Silt/Schluff: feinkörnige Flussablagerungen
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:silt",
    wherein         = {"sti_core:stone","sti_core:limestone"},
    clust_scarcity  = 15 * 15 * 15,
    clust_size      = 5,
    y_max           = 5,
    y_min           = -20,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.2, spread={x=5,y=5,z=5},
                       seed=4421, octaves=1, persist=0.0},
})

-- Lehmsand-Gemisch: Übergangsböden
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:loamy_sand",
    wherein         = {"sti_core:stone"},
    clust_scarcity  = 14 * 14 * 14,
    clust_size      = 6,
    y_max           = 15,
    y_min           = -25,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.2, spread={x=7,y=7,z=7},
                       seed=17676, octaves=1, persist=0.0},
})

-- Ton: reine Tonfraktion, nass und fein
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:clay",
    wherein         = {"sti_core:stone","sti_core:limestone"},
    clust_scarcity  = 15 * 15 * 15,
    clust_size      = 6,
    y_max           = 0,
    y_min           = -30,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.2, spread={x=5,y=5,z=5},
                       seed=-316, octaves=1, persist=0.0},
})

-------------------------------------------------------------------------------
-- BLOB: LEHM-VARIANTEN (nach Eisenoxid-Gehalt und Klima, y -5 bis -80)
-------------------------------------------------------------------------------

-- Brauner Lehm: eisenreicher Lehm, allgemein häufig
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:loam_brown",
    wherein         = {"sti_core:stone","sti_core:limestone"},
    clust_scarcity  = 11 * 11 * 11,
    clust_size      = 8,
    y_max           = 0,
    y_min           = -80,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.25, spread={x=10,y=10,z=10},
                       seed=8855, octaves=1, persist=0.0},
})

-- Gelber Lehm: kalkhaltig, Löss (windabgelagert)
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:loam_yellow",
    wherein         = {"sti_core:stone","sti_core:limestone"},
    clust_scarcity  = 13 * 13 * 13,
    clust_size      = 6,
    y_max           = -5,
    y_min           = -60,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.2, spread={x=8,y=8,z=8},
                       seed=7742, octaves=1, persist=0.0},
})

-- Roter Lehm: stark eisenoxidiert (Laterit), warme/tropische Klimate
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:loam_red",
    wherein         = {"sti_core:stone"},
    clust_scarcity  = 14 * 14 * 14,
    clust_size      = 6,
    y_max           = 10,
    y_min           = -50,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.2, spread={x=8,y=8,z=8},
                       seed=6631, octaves=1, persist=0.0},
    biomes = {"st_savanna","st_desert","st_rainforest"},
})

-- Grauer Lehm: reduziert, tonig, kalt (Gley-Böden)
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:loam_grey",
    wherein         = {"sti_core:stone","sti_core:limestone"},
    clust_scarcity  = 13 * 13 * 13,
    clust_size      = 7,
    y_max           = -10,
    y_min           = -80,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.2, spread={x=8,y=8,z=8},
                       seed=5520, octaves=1, persist=0.0},
})

-------------------------------------------------------------------------------
-- BLOB: BASALT-INTRUSIONEN (magmatische Gänge und Plutone)
-------------------------------------------------------------------------------

-- Flache Basalt-Gänge (Dykes/Sills nahe vulkanischer Oberfläche)
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:basalt",
    wherein         = {"sti_core:stone","sti_core:granite"},
    clust_scarcity  = 20 * 20 * 20,
    clust_size      = 9,
    y_max           = 60,
    y_min           = -150,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.3, spread={x=12,y=12,z=12},
                       seed=9901, octaves=1, persist=0.0},
})

-- Mittlere Basalt-Körper
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:basalt",
    wherein         = {"sti_core:stone","sti_core:granite"},
    clust_scarcity  = 15 * 15 * 15,
    clust_size      = 14,
    y_max           = -150,
    y_min           = -500,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.35, spread={x=16,y=16,z=16},
                       seed=9912, octaves=1, persist=0.0},
})

-- Tiefe Basalt-Massen (ozeanische Kruste, sehr groß)
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:basalt",
    wherein         = {"sti_core:stone","sti_core:granite"},
    clust_scarcity  = 11 * 11 * 11,
    clust_size      = 20,
    y_max           = -500,
    y_min           = -31000,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.4, spread={x=20,y=20,z=20},
                       seed=9923, octaves=1, persist=0.0},
})

-------------------------------------------------------------------------------
-- BLOB: GRANIT-KÖRPER (plutonisches Tiefengestein)
-------------------------------------------------------------------------------

-- Mittlere Granit-Körper (Stocks, kleinere Plutone)
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:granite",
    wherein         = {"sti_core:stone"},
    clust_scarcity  = 16 * 16 * 16,
    clust_size      = 13,
    y_max           = -80,
    y_min           = -400,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.35, spread={x=20,y=20,z=20},
                       seed=3301, octaves=1, persist=0.0},
})

-- Tiefe Granit-Batholithen (dominierendes kontinentales Tiefengestein)
minetest.register_ore({
    ore_type        = "blob",
    ore             = "sti_core:granite",
    wherein         = {"sti_core:stone"},
    clust_scarcity  = 10 * 10 * 10,
    clust_size      = 22,
    y_max           = -400,
    y_min           = -31000,
    noise_threshold = 0.0,
    noise_params    = {offset=0.5, scale=0.45, spread={x=28,y=28,z=28},
                       seed=3302, octaves=1, persist=0.0},
})

minetest.log("action", "[st_terrain] Geologische Schichten registriert.")

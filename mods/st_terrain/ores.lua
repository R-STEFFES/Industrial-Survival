-- st_terrain/ores.lua
-- Geologisch korrekte Erzverteilung
--
-- PRINZIP:
--   Jedes Erz hat ein oder mehrere geologisch passende Trägergesteine.
--   Drei Dichten (sparse/medium/dense) bilden die natürliche Varianz ab:
--     sparse  = verbreitete arme Vorkommen   (häufig, wenig Ertrag)
--     medium  = typische Lagerstätte          (mittel)
--     dense   = reiche Vererzung              (selten, viel Ertrag)
--
-- TIEFENZONEN (Kurzreferenz):
--   Oberfläche   : y 0..+200
--   Sediment     : y 0..-200   (Kalkstein, Lehm)
--   Übergang     : y -80..-400 (Stein + erste Granite)
--   Tiefengestein: y -200..-1000 (Granit, Basalt dominierend)
--   Tiefstes     : y < -1000  (dichte Granite, Basalt)

-------------------------------------------------------------------------------
-- HILFSFUNKTION
-- Registriert ein Erz in allen drei Dichten auf einem Trägergestein.
-- Parameter:
--   mat       : Trägergestein als String ("sti_core:stone") oder Tabelle
--   elem      : Element-Name aus sti_core (z.B. "iron")
--   y_max/min : Tiefenfenster
--   scarcity  : Würfelkante für sparse (medium = *0.65, dense = *1.6)
--   biomes    : optional, Biom-Filter (Tabelle oder nil)
-------------------------------------------------------------------------------
local function reg3(mat, elem, y_max, y_min, scarcity, biomes)
    local wherein
    if type(mat) == "string" then
        wherein = {mat}
    else
        wherein = mat
    end

    -- Trägername für den Node-Namen extrahieren (Teil nach "sti_core:")
    local mat_key = wherein[1]:match("sti_core:(.+)")

    local sc_sparse = scarcity
    local sc_medium = math.max(4, math.floor(scarcity * 0.65))
    local sc_dense  = math.floor(scarcity * 1.6)

    -- SPARSE: weit verbreitet, kleine Cluster
    minetest.register_ore({
        ore_type       = "scatter",
        ore            = "sti_core:" .. mat_key .. "_with_" .. elem .. "_sparse",
        wherein        = wherein,
        clust_scarcity = sc_sparse ^ 3,
        clust_num_ores = 3,
        clust_size     = 3,
        y_max          = y_max,
        y_min          = y_min,
        biomes         = biomes,
    })

    -- MEDIUM: typische Lagerstätte
    minetest.register_ore({
        ore_type       = "scatter",
        ore            = "sti_core:" .. mat_key .. "_with_" .. elem .. "_medium",
        wherein        = wherein,
        clust_scarcity = sc_medium ^ 3,
        clust_num_ores = 6,
        clust_size     = 4,
        y_max          = y_max,
        y_min          = y_min,
        biomes         = biomes,
    })

    -- DENSE: reiche, seltene Vererzung
    minetest.register_ore({
        ore_type       = "scatter",
        ore            = "sti_core:" .. mat_key .. "_with_" .. elem .. "_dense",
        wherein        = wherein,
        clust_scarcity = sc_dense ^ 3,
        clust_num_ores = 10,
        clust_size     = 5,
        y_max          = y_max,
        y_min          = y_min,
        biomes         = biomes,
    })
end

-------------------------------------------------------------------------------
-- EISEN (Fe) — Hämatit / Magnetit / Siderit
-- Häufigstes Erz der Erdkruste; in allen Gesteinen, von Oberfläche bis tief.
-------------------------------------------------------------------------------
reg3("sti_core:stone",     "iron", 200,    -150,  8)   -- Oberfläche bis Sediment
reg3("sti_core:stone",     "iron", -150, -31000,  7)   -- tief, etwas häufiger
reg3("sti_core:limestone", "iron",  -20,   -200, 10)   -- Siderit in Karbonat
reg3("sti_core:basalt",    "iron",   50,  -31000,  9)  -- Magnetit in Basalt

-------------------------------------------------------------------------------
-- KUPFER (Cu) — Chalkopyrit / Bornit
-- Porphyrische Kupfer-Lagerstätten: Basalt-nah, mitteltiefe Zonen.
-------------------------------------------------------------------------------
reg3("sti_core:stone",  "copper",  50,   -120, 11)   -- obere Kruste, Sekundär
reg3("sti_core:basalt", "copper",  50,   -400,  9)   -- primäre Lagerstätte
reg3("sti_core:basalt", "copper", -400, -31000, 10)  -- tiefe Fortsetzung

-------------------------------------------------------------------------------
-- GOLD (Au) — Freigold / Telluride in Quarzgängen
-- Hydrothermale Goldadern, tief in Granit. An Oberfläche nur Seifen-Analog.
-------------------------------------------------------------------------------
reg3("sti_core:stone",   "gold",    0,   -80, 20)   -- Seifen-Analogon
reg3("sti_core:granite", "gold",  -80,  -600, 16)   -- primäre Granit-Adern
reg3("sti_core:granite", "gold", -600, -31000, 13)  -- tiefe reiche Vorkommen

-------------------------------------------------------------------------------
-- SILBER (Ag) — Argentit / Akanthit
-- Oft mit Gold und Blei assoziiert; etwas häufiger als Gold.
-------------------------------------------------------------------------------
reg3("sti_core:stone",     "silver",   0,   -200, 16)
reg3("sti_core:granite",   "silver", -100,  -600, 13)
reg3("sti_core:limestone", "silver",  -20,  -200, 17)

-------------------------------------------------------------------------------
-- PLATIN (Pt) — PGM (Platingruppen-Metalle)
-- Ultrabasisches Gestein / komatiitische Laven: tief in Basalt, extrem selten.
-------------------------------------------------------------------------------
reg3("sti_core:basalt", "platinum", -500, -31000, 22)

-------------------------------------------------------------------------------
-- BLEI (Pb) — Galenit
-- Mississippi-Valley-Type oder SEDEX: Sedimentgestein, mittel tief.
-------------------------------------------------------------------------------
reg3("sti_core:limestone", "lead", -10,  -300, 13)
reg3("sti_core:stone",     "lead", -50,  -400, 14)

-------------------------------------------------------------------------------
-- ZINK (Zn) — Sphalerit
-- Fast immer gemeinsam mit Blei (Pb-Zn-Lagerstätten).
-------------------------------------------------------------------------------
reg3("sti_core:limestone", "zinc", -10,  -300, 12)
reg3("sti_core:stone",     "zinc", -30,  -350, 13)

-------------------------------------------------------------------------------
-- ZINN (Sn) — Kassiterit
-- Granit-Apex-Zonen und Greisen-Pegmatite; tief, Granit-gebunden.
-------------------------------------------------------------------------------
reg3("sti_core:granite", "tin",  -80,  -400, 14)
reg3("sti_core:stone",   "tin",  -50,  -300, 16)   -- Kontaktzone

-------------------------------------------------------------------------------
-- NICKEL (Ni) — Pentlandit / Millerit
-- Komatiit / Basalt-Schmelz-assoziiert; tief.
-------------------------------------------------------------------------------
reg3("sti_core:basalt",  "nickel", -100,  -600, 14)
reg3("sti_core:stone",   "nickel", -150,  -500, 16)

-------------------------------------------------------------------------------
-- ALUMINIUM (Al) — Bauxit (lateritische Verwitterung)
-- Entsteht durch intensive Verwitterung in warmen Klimaten;
-- flach, biom-gebunden.
-------------------------------------------------------------------------------
reg3("sti_core:stone",     "aluminum",  30,  -60, 12,
    {"st_savanna","st_rainforest","st_desert","st_rocky_desert"})
reg3("sti_core:limestone", "aluminum",  10,  -80, 13,
    {"st_savanna","st_rainforest"})
-- Gemäßigte Zonen: seltener
reg3("sti_core:stone",     "aluminum",  20,  -40, 16)

-------------------------------------------------------------------------------
-- TITAN (Ti) — Ilmenit / Rutil
-- Akzessoriell in Basalt; tiefe magmatische Differentiation.
-------------------------------------------------------------------------------
reg3("sti_core:basalt", "titanium", -150,  -800, 15)
reg3("sti_core:stone",  "titanium", -100,  -500, 17)

-------------------------------------------------------------------------------
-- WOLFRAM (W) — Wolframit / Scheelit
-- Kontakt-/Skarn-Lagerstätten an Granit-Kalkstein-Grenzen; sehr tief.
-------------------------------------------------------------------------------
reg3("sti_core:granite",   "tungsten", -300, -31000, 18)
reg3("sti_core:limestone", "tungsten", -250,  -400,  20)  -- Skarn-Kontakt

-------------------------------------------------------------------------------
-- LITHIUM (Li) — Spodumen (Pegmatit) / Sole (Sediment)
-- Zwei genetisch verschiedene Typen.
-------------------------------------------------------------------------------
reg3("sti_core:granite",   "lithium", -150,  -600, 16)  -- Pegmatit-Typ
reg3("sti_core:limestone", "lithium",  -10,   -80, 18)  -- Sole/Evaporit-Typ

-------------------------------------------------------------------------------
-- SCHWEFEL (S) — Pyrit / Elementarschwefel
-- Vulkanische Entgasung (nahe Basalt) und diagenetischer Pyrit (Sediment).
-------------------------------------------------------------------------------
reg3("sti_core:basalt",  "sulfur",  50,  -200, 13)   -- vulkanisch
reg3("sti_core:stone",   "sulfur", -10,  -150, 15)   -- diagenetisch
reg3("sti_core:limestone","sulfur", -20, -100, 15)   -- Pyrit in Karbonat

-------------------------------------------------------------------------------
-- SILIZIUM (Si) — Quarz (SiO2)
-- Mit ~60% der Erdkruste das häufigste Element nach Sauerstoff.
-- In ALLEN Gesteinen sehr verbreitet.
-------------------------------------------------------------------------------
reg3("sti_core:stone",     "silicon", 200, -31000,  7)
reg3("sti_core:granite",   "silicon",  -80, -31000, 6)
reg3("sti_core:limestone", "silicon",  -20,  -200,  9)
reg3("sti_core:basalt",    "silicon",   50, -31000,  8)

-------------------------------------------------------------------------------
-- KOHLENSTOFF (C) — Kohle / Anthrazit / Graphit
-- Kohle = fossile Biomasse in Sedimentgestein nahe Oberfläche.
-- Graphit = metamorphe Umwandlung tief in der Kruste.
-------------------------------------------------------------------------------
reg3("sti_core:stone",     "carbon",  50,  -200,  9)  -- Kohle (Karbon)
reg3("sti_core:limestone", "carbon", -20,  -250, 10)  -- Kohle in Karbonat
reg3("sti_core:granite",   "carbon", -300, -31000, 14) -- Graphit (metamorph)

-------------------------------------------------------------------------------
-- URAN (U) — Uraninit / Pechblende
-- Kristallin in tiefen Graniten; radioaktiv. Sehr selten.
-- Nur unterhalb y -400.
-------------------------------------------------------------------------------
reg3("sti_core:granite", "uranium", -400, -31000, 20)

-------------------------------------------------------------------------------
-- THORIUM (Th) — Thorianit / Monazit
-- Mit Uran assoziiert; noch seltener. Nur tiefstes Gestein.
-------------------------------------------------------------------------------
reg3("sti_core:granite", "thorium", -600, -31000, 24)

minetest.log("action", "[st_terrain] Erzverteilung registriert.")

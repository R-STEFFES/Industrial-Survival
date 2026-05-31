-- st_terrain/ores.lua
-- Geologisch exakte und vollständige Erzverteilung für Industrial Survival
-- Synchronisiert mit allen 43 Elementen aus sti_core/elements.lua
--
-- PRINZIP:
--   Jedes Erz hat geologisch passende Trägergesteine oder Lockersedimente (Tone/Lehme).
--   Drei Dichten (sparse/medium/dense) bilden die natürliche Varianz ab.
--
-- TIEFENZONEN (Kurzreferenz):
--   Oberfläche / Sedimente : y 200..-15   (Tone, Lehme, Silt, Torf, Sand, Kies)
--   Sedimentgestein        : y 0..-250    (Kalkstein, Sediment-Stein)
--   Übergangszone          : y -80..-400  (Stein + erste Granite)
--   Tiefengestein          : y -200..-1000 (Granit, Basalt dominierend)
--   Tiefste Kruste         : y < -1000    (Dichte Batholithen, ultrabasische Magmatite)

-------------------------------------------------------------------------------
-- HILFSFUNKTION
-- Registriert ein Erz in allen drei Dichten auf einem Trägergestein.
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
    if not mat_key then return end

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
-- GRUPPE 1: EDELMETALLE & SCHMUCKMETALLE
-------------------------------------------------------------------------------

-- GOLD (Au): Primär tief im Granit. Sekundär als Seifengold ("Placer Gold")
-- extrem realistisch in alluvialen Flusssedimenten, Tonen und Sanden!
reg3("sti_core:granite",     "gold",  -80,  -600, 16)
reg3("sti_core:granite",     "gold", -600, -31000, 13)
reg3("sti_core:stone",       "gold",    0,   -100, 19)
reg3("sti_core:clay",        "gold",  200,    -15, 16) -- Gold in Tonlinsen
reg3("sti_core:sand",        "gold",  200,    -15, 14) -- Flussseifen
reg3("sti_core:gravel",      "gold",  200,    -15, 15)
reg3("sti_core:silt",        "gold",  200,    -15, 17)

-- SILBER (Ag): In hydrothermalen Gängen und als sekundäre Zementationszone in Lehmen.
reg3("sti_core:granite",     "silver", -100,  -600, 13)
reg3("sti_core:stone",       "silver",    0,  -200, 16)
-- Silberanreicherung in grauen/reduzierten Tonschichten
reg3("sti_core:loam_grey",   "silver", 200,    -15, 18)
reg3("sti_core:limestone",   "silver",  -20,  -200, 17)

-- PLATIN (Pt): Fast ausschließlich in tiefen mafischen/ultramafischen Basalten.
reg3("sti_core:basalt",      "platinum", -400, -31000, 22)


-------------------------------------------------------------------------------
-- GRUPPE 2: INDUSTRIELLE HAUPTMETALLE
-------------------------------------------------------------------------------

-- EISEN (Fe): Überall zu finden. Wichtig: "Raseneisenerz" (Bog Iron) in Torf und Lehm!
reg3("sti_core:stone",       "iron",  200,   -150,  8)
reg3("sti_core:stone",       "iron", -150, -31000,  7)
reg3("sti_core:basalt",      "iron",   50, -31000,  8)
reg3("sti_core:limestone",   "iron",  -20,   -200, 10)
reg3("sti_core:peat",        "iron",  200,    -10, 10) -- Biogenes Raseneisenerz im Moor
reg3("sti_core:loam_grey",   "iron",  200,    -15, 11) -- Eisenhydroxide im Lehm
reg3("sti_core:clay",        "iron",  200,    -15, 12)

-- KUPFER (Cu): Primär in Basalt, sekundär im berühmten "Kupferschiefer"-Sedimentanalog (Lehm).
reg3("sti_core:basalt",      "copper",  50,  -400,  9)
reg3("sti_core:basalt",      "copper", -400, -31000, 10)
reg3("sti_core:stone",       "copper",  50,  -120, 12)
reg3("sti_core:loam_grey",   "copper", 200,    -15, 14) -- Sedimentäres Kupfer

-- ALUMINIUM (Al): In Bauxit-Form durch tropische Verwitterung (Roter/Brauner Lehm und Ton).
reg3("sti_core:loam_red",    "aluminum", 200,    -5,  9, {"st_savanna", "st_rainforest"})
reg3("sti_core:loam_brown",  "aluminum", 200,   -10, 11)
reg3("sti_core:clay",        "aluminum", 200,   -15, 12)
reg3("sti_core:stone",       "aluminum",  30,   -60, 14)

-- TITAN (Ti): Als Ilmenit/Rutil in Basalt und akkumuliert in schweren Küsten-Mineralsanden.
reg3("sti_core:basalt",      "titanium", -150, -800, 14)
reg3("sti_core:sand",        "titanium",  200,   -5, 15) -- Titanhaltiger Sand
reg3("sti_core:silt",        "titanium",  200,   -5, 16)

-- NICKEL (Ni): Magmatische Segregation im Basalt.
reg3("sti_core:basalt",      "nickel", -100,  -600, 13)
reg3("sti_core:stone",       "nickel", -150,  -500, 16)

-- ZINK (Zn): Zusammen mit Blei in Kalksteinen (MVT-Lagerstätten).
reg3("sti_core:limestone",   "zinc",    -10,  -300, 11)
reg3("sti_core:stone",       "zinc",    -30,  -350, 13)

-- BLEI (Pb): Galenit in Karbonaten und hydrothermalen Systemen.
reg3("sti_core:limestone",   "lead",    -10,  -300, 12)
reg3("sti_core:stone",       "lead",    -50,  -400, 14)

-- ZINN (Sn): In Granit-Greisen und als extrem verwitterungsbeständiger Zinnsand (Kassiterit) in Flusskies.
reg3("sti_core:granite",     "tin",     -80,  -400, 13)
reg3("sti_core:gravel",      "tin",     200,   -15, 15) -- Zinnseifen im Flussbett
reg3("sti_core:sand",        "tin",     200,   -15, 16)


-------------------------------------------------------------------------------
-- GRUPPE 3: REAKTIVE ALKALI- & ERDALKALIMETALLE
-------------------------------------------------------------------------------

-- LITHIUM (Li): Tief im Granit (Pegmatite) oder in Salztonen getrockneter Seen (Evaporite).
reg3("sti_core:granite",     "lithium", -150,  -600, 15)
reg3("sti_core:clay",        "lithium",  200,   -15, 16) -- Salar-Ton-Ablagerung
reg3("sti_core:loam_yellow", "lithium",  200,   -15, 17)

-- MAGNESIUM (Mg): In Basalt und marinen Karbonat-Sedimenten.
reg3("sti_core:basalt",      "magnesium",  50, -1000, 10)
reg3("sti_core:limestone",   "magnesium", -10,  -250, 12)

-- CALCIUM (Ca): Hauptbestandteil von Kalkstein, kommt reichlich vor.
reg3("sti_core:limestone",   "calcium",    20,  -250,  6)
reg3("sti_core:loam_brown",  "calcium",   200,   -10, 14)

-- BARIUM (Ba): Als Baryt (Schwerspat) in hydrothermalen Gängen und Sedimentgestein.
reg3("sti_core:stone",       "barium",    -20,  -400, 13)
reg3("sti_core:limestone",   "barium",    -10,  -200, 14)

-- STRONTIUM (Sr): Tritt oft akzessoriell in Kalksteinen auf.
reg3("sti_core:limestone",   "strontium", -20,  -250, 15)

-- NATRIUM (Na): In Steinsalz-Evaporiten und salzigen Tonen.
reg3("sti_core:clay",        "sodium",    200,   -15, 13) -- Salztone
reg3("sti_core:limestone",   "sodium",    -10,  -150, 14)

-- KALIUM (K): In Feldspat (Granit) und stark gebunden in verwitterten Illit-Tonen.
reg3("sti_core:granite",     "potassium", -50, -31000, 11)
reg3("sti_core:clay",        "potassium", 200,   -15, 12) -- Tonmineralien
reg3("sti_core:loam_brown",  "potassium", 200,   -10, 13)


-------------------------------------------------------------------------------
-- GRUPPE 4: TECHNOLOGIE- & REFRAKTÄRMETALLE
-------------------------------------------------------------------------------

-- WOLFRAM (W): Hoch-temperierte Skarn-Kontakte (Kalkstein/Granit).
reg3("sti_core:granite",     "tungsten", -300, -31000, 17)
reg3("sti_core:limestone",   "tungsten", -200,  -450, 19)

-- MANGAN (Mn): In Kalkstein oder als "Manganknollen" in tiefen/reduzierten Tonschichten.
-- Perfekt für die Stahlproduktion!
reg3("sti_core:limestone",   "manganese", -10,  -200, 12)
reg3("sti_core:loam_grey",   "manganese", 200,   -15, 14) -- Manganknollen-Analog
reg3("sti_core:clay",        "manganese", 200,   -15, 15)

-- CHROM (Cr): Als Chromit streng an ultrabasische tiefe Basaltschichten gebunden.
reg3("sti_core:basalt",      "chromium", -200, -31000, 14)

-- KOBALT (Co): Geochemisch eng verwandt mit Nickel und Eisen.
reg3("sti_core:basalt",      "cobalt",   -100,  -800, 15)
reg3("sti_core:stone",       "cobalt",   -100,  -400, 17)

-- VANADIUM (V): Akzessoriell in Titanomagnetit (Basalt) und organischen Schwarztonen.
reg3("sti_core:basalt",      "vanadium", -100,  -600, 15)
reg3("sti_core:loam_grey",   "vanadium",  200,   -15, 16) -- Organischer Schwarzschlamm

-- ZIRKONIUM (Zr): Als Zirkon extrem stabil; in Graniten und schweren Ufersanden.
-- Hält extremen Temperaturen stand.
reg3("sti_core:granite",     "zirconium", -50,  -800, 15)
reg3("sti_core:sand",        "zirconium", 200,    -5, 16)

-- MOLYBDÄN (Mo): Porphyrische Erze in Granit- und Kontaktzonen.
reg3("sti_core:granite",     "molybdenum",-150, -2000, 16)

-- QUECKSILBER (Hg): Als Zinnober (Cinnabar) in kühlen hydrothermalen Spalten im Stein.
reg3("sti_core:stone",       "mercury",    20,  -200, 16)

-- CADMIUM (Cd): Folgt als treuer Begleiter immer dem Zink in Zinkblenden.
reg3("sti_core:limestone",   "cadmium",   -10,  -300, 16)

-- ANTIMON (Sb): In hydrothermalen Quarzgängen (Stibnit).
reg3("sti_core:stone",       "antimony",  -50,  -500, 16)

-- BISMUT (Bi): Spätmagmatisch in Granit-Pegmatiten.
reg3("sti_core:granite",     "bismuth",   -80,  -600, 16)

-- GERMANIUM (Ge): Extrem selten. Lagert sich organisch in Steinkohleflözen (Carbon) ab!
reg3("sti_core:stone",       "germanium",  50,  -200, 18) -- In Kohleschichten gebunden


-------------------------------------------------------------------------------
-- GRUPPE 5: KERNBRENNSTOFFE (RADIOAKTIV)
-------------------------------------------------------------------------------

-- URAN (U): Hochgradig realistisch. Lagert sich kristallin in tiefem Granit ab,
-- ODER lagert sich durch Reduktion in organischen Sedimenten wie Torf (Peat) und grauen Tonen ab!
reg3("sti_core:granite",     "uranium",  -400, -31000, 19)
reg3("sti_core:peat",        "uranium",   200,   -10, 20) -- Roll-front/Biogene Fixierung
reg3("sti_core:loam_grey",   "uranium",   200,   -15, 21)

-- THORIUM (Th): Begleitet Uran, konzentriert in Monazitsanden und tiefen Plutonen.
reg3("sti_core:granite",     "thorium",  -500, -31000, 22)


-------------------------------------------------------------------------------
-- GRUPPE 6: NICHTMETALLE, HALOGENE & REAKTIVE ELEMENTE
-------------------------------------------------------------------------------

-- SCHWEFEL (S): Vulkanische Entgasung (Basalt) oder biogene Sulfide in Mooren/Tonen (Pyrit).
reg3("sti_core:basalt",      "sulfur",     50,  -200, 12)
reg3("sti_core:peat",        "sulfur",    200,   -10, 13) -- Organischer Schwefel im Moor
reg3("sti_core:loam_grey",   "sulfur",    200,   -15, 14)
reg3("sti_core:limestone",   "sulfur",    -20,  -100, 15)

-- SILIZIUM (Si): Macht einen riesigen Teil der Erdkruste aus (Quarz). Überall massenhaft!
reg3("sti_core:stone",       "silicon",   200, -31000,  6)
reg3("sti_core:granite",     "silicon",   -80, -31000,  5)
reg3("sti_core:sand",        "silicon",   200,    -5,  5) -- Reiner Quarzsand
reg3("sti_core:gravel",      "silicon",   200,    -5,  6)

-- KOHLENSTOFF (C): Kohleflöze, tiefer Graphit und unvollständig zersetzter Torf an der Oberfläche.
reg3("sti_core:stone",       "carbon",     50,  -200,  8) -- Kohleschicht
reg3("sti_core:limestone",   "carbon",    -20,  -250, 10)
reg3("sti_core:granite",     "carbon",   -300, -31000, 13) -- Graphit
reg3("sti_core:peat",        "carbon",    200,   -10,  7) -- Vorstufe der Inkohlung

-- PHOSPHOR (P): In biologischen Ablagerungen (Apatit/Guano/Knochenbetten) in Mooren und Tonen.
reg3("sti_core:peat",        "phosphorus", 200,   -10, 14)
reg3("sti_core:clay",        "phosphorus", 200,   -15, 15)
reg3("sti_core:limestone",   "phosphorus", -10,  -150, 15)

-- SAUERSTOFF (O): Gebunden in Oxiden fast überall, besonders in Oberflächenlehmen.
reg3("sti_core:loam_brown",  "oxygen",    200,   -10, 10)
reg3("sti_core:stone",       "oxygen",    100,  -500, 11)

-- WASSERSTOFF (H): Biologisch und chemisch in Hydratwasser (Kaolinit-Tone) und Torf gebunden!
reg3("sti_core:clay",        "hydrogen",  200,   -15, 11) -- In wasserhaltigen Tonmineralen
reg3("sti_core:peat",        "hydrogen",  200,   -10, 10) -- In Kohlenwasserstoffen

-- FLUOR (F): Flussspat (Fluorit) in Kalkstein und magmatischen Restlösungen.
reg3("sti_core:limestone",   "fluorine",  -10,  -250, 14)
reg3("sti_core:granite",     "fluorine",  -80,  -800, 15)

-- CHLOR (Cl): In marinen Evaporit-Schichten (Kalkstein/Tonschnittstellen).
reg3("sti_core:clay",        "chlorine",  200,   -15, 13)
reg3("sti_core:limestone",   "chlorine",  -10,  -150, 14)

-- BROM (Bromine, Br): Konzentriert sich in urzeitlichen Salzgashalden und marinen Tonen.
reg3("sti_core:clay",        "bromine",   200,   -15, 16)

-- IOD (Iodine, I): Stark biogen angereichert, daher perfekt im Torf (Alte Meeresarme/Sümpfe) und Silt.
reg3("sti_core:peat",        "iodine",    200,   -10, 15)
reg3("sti_core:silt",        "iodine",    200,    -5, 16)

-- ARSEN (As): Als Arsenopyrit eng an Goldadern und giftige hydrothermale Erze gekoppelt.
reg3("sti_core:granite",     "arsenic",   -80,  -600, 16)
reg3("sti_core:stone",       "arsenic",     0,  -300, 17)

-- GERMANIUM (Ge): (Bereits oben unter Tech-Metallen logisch in Kohleschichten einsortiert).

minetest.log("action", "[st_terrain] Geologisch-realistische Erzverteilung (43 Elemente) erfolgreich registriert.")

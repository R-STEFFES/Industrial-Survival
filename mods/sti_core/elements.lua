-- sti_core/elements.lua

elements = {
    ---------------------------------------------------------------------------
    -- 1. DEINE URSPRÜNGLICHEN 18 ELEMENTE
    ---------------------------------------------------------------------------
    {
        name = "gold",
        desc = "Gold",
        color = "#ffd700",
        uses = 15,          -- Weich, geht schnell kaputt
        speed = 4.0,        -- Baut dafür extrem schnell ab
        damage = 4
    },
    {
        name = "silver",
        desc = "Silber",
        color = "#e5e5e5",
        uses = 22,
        speed = 2.5,
        damage = 5
    },
    {
        name = "platinum",
        desc = "Platin",
        color = "#e5e4e2",
        uses = 40,
        speed = 3.0,
        damage = 6
    },
    {
        name = "iron",
        desc = "Eisen",
        color = "#8b4513",
        uses = 30,
        speed = 2.0,
        damage = 6
    },
    {
        name = "copper",
        desc = "Kupfer",
        color = "#d2691e",
        uses = 20,
        speed = 1.8,
        damage = 5
    },
    {
        name = "aluminum",
        desc = "Aluminium",
        color = "#b2beb5",
        uses = 25,
        speed = 2.2,
        damage = 5
    },
    {
        name = "titanium",
        desc = "Titan",
        color = "#708090",
        uses = 65,          -- Sehr hohe Haltbarkeit
        speed = 3.2,
        damage = 8          -- Hoher Schaden
    },
    {
        name = "nickel",
        desc = "Nickel",
        color = "#aca79e",
        uses = 28,
        speed = 2.0,
        damage = 5
    },
    {
        name = "zinc",
        desc = "Zink",
        color = "#bac4c8",
        uses = 18,
        speed = 1.8,
        damage = 4
    },
    {
        name = "lead",
        desc = "Blei",
        color = "#4f5d65",
        uses = 35,
        speed = 1.2,        -- Schwer und träge
        damage = 5
    },
    {
        name = "tin",
        desc = "Zinn",
        color = "#ebebeb",
        uses = 15,
        speed = 1.6,
        damage = 4
    },
    {
        name = "lithium",
        desc = "Lithium",
        color = "#e0e0e0",
        uses = 12,          -- Extrem reaktiv/weich
        speed = 1.5,
        damage = 3
    },
    {
        name = "tungsten",
        desc = "Wolfram",
        color = "#3d4246",
        uses = 80,          -- Höchste Haltbarkeit (sehr robust)
        speed = 2.5,
        damage = 7
    },
    {
        name = "sulfur",
        desc = "Schwefel",
        color = "#e6e6fa",
        uses = 10,          -- Spröde
        speed = 1.2,
        damage = 3
    },
    {
        name = "silicon",
        desc = "Silizium",
        color = "#555555",
        uses = 15,
        speed = 2.0,
        damage = 4
    },
    {
        name = "carbon",
        desc = "Kohlenstoff",
        color = "#222222",
        uses = 50,          -- In Richtung Diamant/Karbon gedacht
        speed = 3.5,
        damage = 7
    },
    {
        name = "uranium",
        desc = "Uran",
        color = "#39ff14",
        uses = 45,
        speed = 2.8,
        damage = 9          -- Hoher Schaden durch Radioaktivität
    },
    {
        name = "thorium",
        desc = "Thorium",
        color = "#4a5d4e",
        uses = 50,
        speed = 2.6,
        damage = 8
    },

    ---------------------------------------------------------------------------
    -- 2. ERGÄNZUNG: HÄUFIGE METALLE & ERDALKALIMETALLE
    ---------------------------------------------------------------------------
    {
        name = "magnesium",
        desc = "Magnesium",
        color = "#e3e4e5",
        uses = 22,          -- Sehr leichtes Metall
        speed = 2.4,
        damage = 4
    },
    {
        name = "manganese",
        desc = "Mangan",
        color = "#b5a6a5",
        uses = 45,          -- Wichtig für zähe Legierungen
        speed = 2.2,
        damage = 6
    },
    {
        name = "chromium",
        desc = "Chrom",
        color = "#dedffc",
        uses = 55,          -- Sehr hart
        speed = 2.8,
        damage = 7
    },
    {
        name = "cobalt",
        desc = "Kobalt",
        color = "#2b5182",
        uses = 42,
        speed = 2.4,
        damage = 6
    },
    {
        name = "calcium",
        desc = "Calcium",
        color = "#ebe1d2",
        uses = 15,
        speed = 1.5,
        damage = 3
    },
    {
        name = "barium",
        desc = "Barium",
        color = "#d1ffd1",
        uses = 25,
        speed = 1.8,
        damage = 4
    },
    {
        name = "strontium",
        desc = "Strontium",
        color = "#e0eed0",
        uses = 20,
        speed = 1.6,
        damage = 4
    },

    ---------------------------------------------------------------------------
    -- 3. ERGÄNZUNG: REAKTIVE ALKALIMETALLE & NICHTMETALLE
    ---------------------------------------------------------------------------
    {
        name = "sodium",
        desc = "Natrium",
        color = "#dadbdc",
        uses = 8,           -- Extrem weich
        speed = 1.2,
        damage = 2
    },
    {
        name = "potassium",
        desc = "Kalium",
        color = "#b0c4de",
        uses = 7,
        speed = 1.1,
        damage = 2
    },
    {
        name = "phosphorus",
        desc = "Phosphor",
        color = "#e6cd91",
        uses = 10,
        speed = 1.0,
        damage = 3
    },
    {
        name = "oxygen",
        desc = "Sauerstoff",
        color = "#b0e0e6",  -- Hellblau (als verflüssigtes Element visualisiert)
        uses = 18,
        speed = 2.5,
        damage = 3
    },
    {
        name = "hydrogen",
        desc = "Wasserstoff",
        color = "#db7093",
        uses = 12,
        speed = 1.8,
        damage = 2
    },

    ---------------------------------------------------------------------------
    -- 4. ERGÄNZUNG: WEITERE SELTENE & SPEZIELLE ÜBERGANGSMETALLE
    ---------------------------------------------------------------------------
    {
        name = "vanadium",
        desc = "Vanadium",
        color = "#93a3a3",
        uses = 50,          -- Robust
        speed = 2.5,
        damage = 7
    },
    {
        name = "zirconium",
        desc = "Zirkonium",
        color = "#ccd7d7",
        uses = 58,
        speed = 2.7,
        damage = 6
    },
    {
        name = "molybdenum",
        desc = "Molybdän",
        color = "#a2b5cd",
        uses = 60,          -- Sehr hitze- und verschleißfest
        speed = 2.6,
        damage = 7
    },
    {
        name = "mercury",
        desc = "Quecksilber",
        color = "#9c9c9c",  -- Flüssiges Silber-Grau
        uses = 10,          -- Schlechte Haltbarkeit (da eigentlich flüssig)
        speed = 1.0,
        damage = 5          -- Gift-Aspekt
    },
    {
        name = "cadmium",
        desc = "Cadmium",
        color = "#dfdfdf",
        uses = 20,
        speed = 1.7,
        damage = 4
    },
    {
        name = "antimony",
        desc = "Antimon",
        color = "#cd7f32",
        uses = 22,
        speed = 1.9,
        damage = 5
    },
    {
        name = "bismuth",
        desc = "Wismut",
        color = "#e5c5e5",  -- Schimmernder Rosa/Violett-Ton
        uses = 24,
        speed = 1.5,
        damage = 5
    },

    ---------------------------------------------------------------------------
    -- 5. ERGÄNZUNG: REAKTIVE HALOGENE & HALBMETALLE
    ---------------------------------------------------------------------------
    {
        name = "fluorine",
        desc = "Fluor",
        color = "#99ffcc",
        uses = 5,           -- Extrem reaktiv, nutzt sich sofort ab
        speed = 1.0,
        damage = 2
    },
    {
        name = "chlorine",
        desc = "Chlor",
        color = "#ccff99",
        uses = 5,
        speed = 1.0,
        damage = 2
    },
    {
        name = "bromine",
        desc = "Brom",
        color = "#a52a2a",  -- Rotbraun
        uses = 8,
        speed = 1.2,
        damage = 3
    },
    {
        name = "iodine",
        desc = "Iod",
        color = "#4b0082",  -- Tiefes Violett
        uses = 12,
        speed = 1.4,
        damage = 4
    },
    {
        name = "arsenic",
        desc = "Arsen",
        color = "#5f9ea0",
        uses = 14,
        speed = 1.6,
        damage = 6          -- Hoher "Gift"-Schaden
    },
    {
        name = "germanium",
        desc = "Germanium",
        color = "#9fb6cd",
        uses = 25,
        speed = 2.1,
        damage = 4
    }
}

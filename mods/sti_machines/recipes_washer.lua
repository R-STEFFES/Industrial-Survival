-- =======================================================================
-- STI MACHINES - REZEPTE FÜR GOLDWASCHANLAGE (ÜBERARBEITET)
-- =======================================================================

sti_machines = sti_machines or {}
sti_machines.washer_recipes = {}

-- Hilfsfunktion zum einfachen Hinzufügen von Rezepten
local function register_washer_recipe(input_item, guaranteed_output, extra_drops)
    sti_machines.washer_recipes[input_item] = {
        output = guaranteed_output or "",
        drops = extra_drops or {}
    }
end

-- =======================================================================
-- 1. REZEPTE FÜR ALLE ROHEN LEHMSORTEN (RAW CLAY)
-- =======================================================================
-- Verarbeitet alle Lehmsorten aus sti_core zu gereinigtem Ton + seltene Erze
local clay_types = {
    {
        name = "brown",
        drops = {
            { item = "sti_core:nugget_iron", chance = 0.05 },
            { item = "sti_core:nugget_copper", chance = 0.02 }
        }
    },
    {
        name = "yellow",
        drops = {
            { item = "sti_core:nugget_gold", chance = 0.001 } -- 0.1% Gold
        }
    },
    {
        name = "red",
        drops = {
            { item = "sti_core:nugget_iron",     chance = 0.08 }, -- 8% Eisen
            { item = "sti_core:nugget_aluminum", chance = 0.02 }  -- 2% Alu
        }
    },
    {
        name = "grey",
        drops = {
            { item = "sti_core:nugget_silver", chance = 0.03 },
            { item = "sti_core:nugget_tin",    chance = 0.02 }
        }
    },
}

for _, c in ipairs(clay_types) do
    register_washer_recipe("sti_core:clay_raw_" .. c.name, "sti_core:clay_clean_" .. c.name, c.drops)
end

-- =======================================================================
-- 2. REZEPTE FÜR KIES (GRAVEL)
-- =======================================================================
-- Gibt standardmäßig Flint (Feuerstein) und selten Nuggets ab
local gravel_drops = {
    { item = "sti_core:nugget_iron",   chance = 0.06 },  -- 6%
    { item = "sti_core:nugget_copper", chance = 0.04 },  -- 4%
    { item = "sti_core:nugget_gold",   chance = 0.002 }, -- 0.2%
    { item = "sti_core:nugget_silver", chance = 0.01 },  -- 1%
}

-- Registrierung für den sti_core-Kies und den Minetest-Standard-Kies
register_washer_recipe("sti_core:gravel", "default:flint", gravel_drops)
register_washer_recipe("default:gravel", "default:flint", gravel_drops)

-- =======================================================================
-- 3. REZEPTE FÜR SAND
-- =======================================================================
-- Sand wird weggeschwemmt (guaranteed = ""), droppt aber Nuggets & gelben Ton
local sand_drops = {
    { item = "sti_core:clay_clean_yellow", chance = 0.15 }, -- 15% Chance auf sauberen gelben Ton
    { item = "sti_core:nugget_gold",       chance = 0.005 }, -- 0.5% Gold
    { item = "sti_core:nugget_copper",     chance = 0.03 },  -- 3% Kupfer
    { item = "sti_core:nugget_iron",       chance = 0.05 },  -- 5% Eisen
}

-- Registrierung für den sti_core-Sand und den Minetest-Standard-Sand
register_washer_recipe("sti_core:sand", "", sand_drops)
register_washer_recipe("default:sand", "", sand_drops)

-- =======================================================================
-- 4. ERGÄNZENDE STANDARD-REZEPTE (COMPAT)
-- =======================================================================
register_washer_recipe("default:dirt", "default:clay_lump", {
    { item = "default:sand",            chance = 0.40 },
    { item = "default:gravel",          chance = 0.20 },
    { item = "sti_core:nugget_iron",    chance = 0.02 },
    { item = "sti_core:nugget_silver",  chance = 0.005 }
})

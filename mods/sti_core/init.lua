-- sti_core/init.lua

sti_core = {}

-- Definition der natürlichen Elemente (Name, Beschreibung, Farbe für die Texturierung)
local elements = {
    -- Edelmetalle
    {name = "gold", desc = "Gold", color = "#ffd700", MaxDepth = -31000, MinDepth = -256},
    {name = "silver", desc = "Silber", color = "#e5e5e5", MaxDepth = -1000, MinDepth = -64},
    {name = "platinum", desc = "Platin", color = "#e5e4e2", MaxDepth = -31000, MinDepth = -512},

    -- Basis- / Industriemetalle
    {name = "iron", desc = "Eisen", color = "#8b4513", MaxDepth = -31000, MinDepth = 64},
    {name = "copper", desc = "Kupfer", color = "#d2691e", MaxDepth = -2000, MinDepth = -16},
    {name = "aluminum", desc = "Aluminium", color = "#b2beb5", MaxDepth = -1000, MinDepth = 0},
    {name = "titanium", desc = "Titan", color = "#708090", MaxDepth = -31000, MinDepth = -1024},
    {name = "nickel", desc = "Nickel", color = "#aca79e", MaxDepth = -5000, MinDepth = -128},
    {name = "zinc", desc = "Zink", color = "#bac4c8", MaxDepth = -2000, MinDepth = -64},
    {name = "lead", desc = "Blei", color = "#4f5d65", MaxDepth = -4000, MinDepth = -32},
    {name = "tin", desc = "Zinn", color = "#ebebeb", MaxDepth = -2000, MinDepth = 0},

    -- Seltene Erden / Spezialmetalle
    {name = "lithium", desc = "Lithium", color = "#e0e0e0", MaxDepth = -1000, MinDepth = -32},
    {name = "tungsten", desc = "Wolfram", color = "#3d4246", MaxDepth = -31000, MinDepth = -2048},

    -- Nichtmetalle / Halbleiter / Kristalle
    {name = "sulfur", desc = "Schwefel", color = "#e6e6fa", MaxDepth = -500, MinDepth = 32},
    {name = "silicon", desc = "Silizium", color = "#555555", MaxDepth = -2000, MinDepth = -64},
    {name = "carbon", desc = "Kohlenstoff (Graphit)", color = "#222222", MaxDepth = -31000, MinDepth = 128},

    -- Radioaktive Elemente
    {name = "uranium", desc = "Uran", color = "#39ff14", MaxDepth = -31000, MinDepth = -1024},
    {name = "thorium", desc = "Thorium", color = "#4a5d4e", MaxDepth = -31000, MinDepth = -512},
}

-- Schleife zur automatischen Registrierung aller Blöcke, Items und Erz-Generierungen
for _, elem in ipairs(elements) do

    -- 1. Das Rohmaterial (Lump / Bruchstück)
    minetest.register_craftitem("sti_core:lump_" .. elem.name, {
        description = elem.desc .. "-Brocken",
        inventory_image = "sti_core_lump.png^[multiply:" .. elem.color,
    })

    -- 2. Der verarbeitete Barren (Ingot)
    minetest.register_craftitem("sti_core:ingot_" .. elem.name, {
        description = elem.desc .. "-Barren",
        inventory_image = "sti_core_ingot.png^[multiply:" .. elem.color,
    })

    -- 3. Der solide Materialblock
    minetest.register_node("sti_core:block_" .. elem.name, {
        description = elem.desc .. "-Block",
        tiles = {"sti_core_block.png^[multiply:" .. elem.color},
        is_ground_content = false,
        groups = {cracky = 2, stone = 1},
        sounds = default.node_sound_stone_defaults(),
    })

    -- 4. Das Erz-Erscheinungsbild in der Welt
    minetest.register_node("sti_core:ore_" .. elem.name, {
        description = elem.desc .. "-Erz",
        -- Wir legen deine Erz-Adern direkt über die originale Stein-Textur von default
        tiles = {"default_stone.png^sti_core_ore_template.png^[multiply:" .. elem.color},
        groups = {cracky = 3},
        sounds = default.node_sound_stone_defaults(),
        drop = "sti_core:lump_" .. elem.name,
    })

    -- 5. Die Mapgen-Erzverteilung im Standard-Stein
    minetest.register_ore({
        ore_type       = "scatter",
        ore            = "sti_core:ore_" .. elem.name,
        wherein        = "default:stone",
        clust_scarcity = 12 * 12 * 12,
        clust_num_ores = 5,
        clust_size     = 3,
        y_max          = elem.MinDepth,
        y_min          = elem.MaxDepth,
    })

    -- 6. Standard-Schmelz-Rezept im default:furnace (Brocken -> Barren)
    minetest.register_craft({
        type = "cooking",
        output = "sti_core:ingot_" .. elem.name,
        recipe = "sti_core:lump_" .. elem.name,
        cooktime = 5,
    })
end

print("[sti_core] Alle " .. #elements .. " natuerlichen Elemente erfolgreich mit Default-Support geladen!")

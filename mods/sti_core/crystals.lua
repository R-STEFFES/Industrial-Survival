-- sti_core/crystals.lua
-- Registriert 16 Farbvarianten für Höhlenkristalle inklusive Items, Tools & Armor.

sti_core.crystals = {}

local crystal_colors = {
    {name = "white",      desc = "Weißer",      color = "#ffffff"},
    {name = "grey",       desc = "Grauer",       color = "#858585"},
    {name = "black",      desc = "Schwarzer",    color = "#242424"},
    {name = "red",        desc = "Roter",        color = "#ff2424"},
    {name = "orange",     desc = "Orangener",    color = "#ff8800"},
    {name = "yellow",     desc = "Gelber",       color = "#ffee00"},
    {name = "green",      desc = "Grüner",       color = "#12d312"},
    {name = "lime",       desc = "Lindgrüner",   color = "#00ff88"},
    {name = "cyan",       desc = "Türkiser",     color = "#00e5ff"},
    {name = "skyblue",    desc = "Hellblauer",   color = "#0088ff"},
    {name = "blue",       desc = "Blauer",       color = "#2424ff"},
    {name = "violet",     desc = "Violetter",    color = "#7700ff"},
    {name = "magenta",    desc = "Magenta",      color = "#ff00dd"},
    {name = "purple",     desc = "Purpurner",    color = "#a000a0"},
    {name = "pink",       desc = "Rosa",         color = "#ff99aa"},
    {name = "brown",      desc = "Brauner",      color = "#8b5a2b"}
}

for _, c in ipairs(crystal_colors) do
    local nodename = "sti_core:crystal_" .. c.name
    local itemname = "sti_core:crystal_shard_" .. c.name

    -- Für den Mapgen exportieren
    table.insert(sti_core.crystals, nodename)

    ---------------------------------------------------------------------------
    -- A. DER KRISTALL-NODE (Graustufen-Pflanzentextur einfärben)
    ---------------------------------------------------------------------------
    minetest.register_node(nodename, {
        description = c.desc .. " Höhlenkristall",
        drawtype = "plantlike",
        visual_scale = 0.8,
        tiles = {"sti_core_crystal.png^[multiply:" .. c.color},
        inventory_image = "sti_core_crystal.png^[multiply:" .. c.color,
        paramtype = "light",
        light_source = 12, -- Alle Kristalle leuchten im Dunkeln!
        walkable = false,
        climbable = false,
        sunlight_propagates = true,
        selection_box = {
            type = "fixed",
            fixed = {-0.2, -0.5, -0.2, 0.2, 0.3, 0.2}
        },
        groups = {snappy = 3, attached_node = 1, crystal = 1},
        sounds = {footstep = {name = "default_glass_footstep", gain = 0.5}},
        drop = itemname, -- Droppt den Splitter
    })

    ---------------------------------------------------------------------------
    -- B. DAS SPLITTER-ITEM (Das Rohmaterial)
    ---------------------------------------------------------------------------
    minetest.register_craftitem(itemname, {
        description = c.desc .. " Kristallsplitter",
        inventory_image = "sti_core_crystal_shard.png^[multiply:" .. c.color,
    })

    ---------------------------------------------------------------------------
    -- C. WERKZEUGE (Balance: Ähnlich wie Titan, aber magisch/schnell)[cite: 9, 11]
    ---------------------------------------------------------------------------
    local tools = {
        {"pick",   "Spitzhacke"},
        {"axe",    "Axt"},
        {"shovel", "Schaufel"},
        {"sword",  "Schwert"}
    }

    for _, t in ipairs(tools) do
        local tool_texture = "sti_core_tool_head_" .. t[1] .. ".png^[multiply:" .. c.color .. "^sti_core_" .. t[1] .. "_handle.png"

        minetest.register_tool("sti_core:" .. t[1] .. "_crystal_" .. c.name, {
            description = c.desc .. " Kristall-" .. t[2],
            inventory_image = tool_texture,
            wield_image = tool_texture,
            tool_capabilities = {
                full_punch_interval = 0.9,
                max_drop_level = 2,
                groupcaps = {
                    cracky = {times={[1]=2.5, [2]=1.5, [3]=0.8}, uses=45, maxlevel=2},
                    crumbly = {times={[1]=2.5, [2]=1.5, [3]=0.8}, uses=45, maxlevel=2},
                    choppy = {times={[1]=2.5, [2]=1.5, [3]=0.8}, uses=45, maxlevel=2},
                },
                damage_groups = {fleshy=(t[1] == "sword" and 7 or 3)},
            }
        })
    end

    ---------------------------------------------------------------------------
    -- D. RÜSTUNG (Nutzt das bestehende 3d_armor System)[cite: 9]
    ---------------------------------------------------------------------------
    local armor_types = {
        {suffix = "helmet",     desc = "Helm",       element = "armor_head",  armor_val = 12},
        {suffix = "chestplate", desc = "Brustplatte", element = "armor_torso", armor_val = 24},
        {suffix = "leggings",   desc = "Beinschutz",  element = "armor_legs",  armor_val = 18},
        {suffix = "boots",      desc = "Stiefel",     element = "armor_feet",  armor_val = 6}
    }

    for _, arm in ipairs(armor_types) do
        armor:register_armor("sti_core:" .. arm.suffix .. "_crystal_" .. c.name, {
            description = c.desc .. " Kristall-" .. arm.desc,
            inventory_image = "sti_core_inv_" .. arm.suffix .. ".png^[multiply:" .. c.color,
            texture = "sti_core_armor_" .. arm.suffix .. ".png^[multiply:" .. c.color .. "^[combine:1x1:0,0=blank",
            preview = "sti_core_preview_" .. arm.suffix .. ".png^[multiply:" .. c.color .. "^[combine:1x1:0,0=blank",
            groups = {
                armor = 1,
                [arm.element] = 1,
                armor_heal = 5, -- Kristalle geben einen kleinen Heilbonus
                armor_use = 400,
            },
            armor_groups = {fleshy = arm.armor_val},
            damage_groups = {cracky=3, snappy=3, choppy=3, crumbly=3, level=2},
        })
    end

    ---------------------------------------------------------------------------
    -- E. CRAFTING REZEPTE (Aus Splittern)[cite: 9]
    ---------------------------------------------------------------------------
    local stick = "default:stick"

    -- Tools
    minetest.register_craft({ output = "sti_core:pick_crystal_" .. c.name, recipe = {{itemname, itemname, itemname}, {"", stick, ""}, {"", stick, ""}} })
    minetest.register_craft({ output = "sti_core:axe_crystal_" .. c.name, recipe = {{itemname, itemname, ""}, {itemname, stick, ""}, {"", stick, ""}} })
    minetest.register_craft({ output = "sti_core:shovel_crystal_" .. c.name, recipe = {{itemname, "", ""}, {stick, "", ""}, {stick, "", ""}} })
    minetest.register_craft({ output = "sti_core:sword_crystal_" .. c.name, recipe = {{itemname, "", ""}, {itemname, "", ""}, {stick, "", ""}} })

    -- Armor
    minetest.register_craft({ output = "sti_core:helmet_crystal_" .. c.name, recipe = {{itemname, itemname, itemname}, {itemname, "", itemname}} })
    minetest.register_craft({ output = "sti_core:chestplate_crystal_" .. c.name, recipe = {{itemname, "", itemname}, {itemname, itemname, itemname}, {itemname, itemname, itemname}} })
    minetest.register_craft({ output = "sti_core:leggings_crystal_" .. c.name, recipe = {{itemname, itemname, itemname}, {itemname, "", itemname}, {itemname, "", itemname}} })
    minetest.register_craft({ output = "sti_core:boots_crystal_" .. c.name, recipe = {{itemname, "", itemname}, {itemname, "", itemname}} })
end

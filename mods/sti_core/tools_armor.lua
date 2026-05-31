-- tools_armor.lua

-- Schleife durch alle Elemente aus deiner init.lua
for _, elem in ipairs(elements) do

    ---------------------------------------------------------------------------
    -- 1. WERKZEUGE REGISTRIEREN
    ---------------------------------------------------------------------------
    local tools = {
        {"pick",   "Spitzhacke"},
        {"axe",    "Axt"},
        {"shovel", "Schaufel"},
        {"sword",  "Schwert"}
    }

    for _, t in ipairs(tools) do
        -- DYNAMISCHER STIEL: Baut den Handle-Dateinamen passend zum Werkzeugtyp (t[1])
        local tool_texture = "sti_core_tool_head_" .. t[1] .. ".png^[multiply:" .. elem.color .. "^sti_core_" .. t[1] .. "_handle.png"

        minetest.register_tool("sti_core:" .. t[1] .. "_" .. elem.name, {
            description = elem.desc .. " " .. t[2],
            inventory_image = tool_texture,
            wield_image = tool_texture,

            tool_capabilities = {
                full_punch_interval = 1.0,
                max_drop_level = 1,
                groupcaps = {
                    cracky = {times={[1]=3.0, [2]=2.0, [3]=1.0}, uses=20, maxlevel=1},
                    crumbly = {times={[1]=3.0, [2]=2.0, [3]=1.0}, uses=20, maxlevel=1},
                    choppy = {times={[1]=3.0, [2]=2.0, [3]=1.0}, uses=20, maxlevel=1},
                },
                damage_groups = {fleshy=(t[1] == "sword" and 6 or 2)},
            }
        })
    end

    ---------------------------------------------------------------------------
    -- 2. RÜSTUNGEN REGISTRIEREN (Der saubere Luanti-Texture-Hack)
    ---------------------------------------------------------------------------
    local armor_types = {
        {suffix = "helmet",     desc = "Helm",       element = "armor_head",  armor_val = 10},
        {suffix = "chestplate", desc = "Brustplatte", element = "armor_torso", armor_val = 20},
        {suffix = "leggings",   desc = "Beinschutz",  element = "armor_legs",  armor_val = 15},
        {suffix = "boots",      desc = "Stiefel",     element = "armor_feet",  armor_val = 5}
    }

    for _, arm in ipairs(armor_types) do
        local armor_name = "sti_core:" .. arm.suffix .. "_" .. elem.name

        -- Das Inventar-Icon
        local inv_image = "sti_core_inv_" .. arm.suffix .. ".png^[multiply:" .. elem.color

        -- Der 3d_armor Konsolen-Fehler-Fix
        local dynamic_texture = "sti_core_armor_" .. arm.suffix .. ".png^[multiply:" .. elem.color .. "^[combine:1x1:0,0=blank"
        local dynamic_preview = "sti_core_preview_" .. arm.suffix .. ".png^[multiply:" .. elem.color .. "^[combine:1x1:0,0=blank"

        armor:register_armor(armor_name, {
            description = elem.desc .. " " .. arm.desc,
            inventory_image = inv_image,

            texture = dynamic_texture,
            preview = dynamic_preview,

            groups = {
                armor = 1,
                [arm.element] = 1,
                armor_heal = 0,
                armor_use = 500,
            },
            armor_groups = {fleshy = arm.armor_val},
            damage_groups = {cracky=3, snappy=3, choppy=3, crumbly=3, level=1},
        })
    end

    ---------------------------------------------------------------------------
    -- 3. CRAFTING REZEPTE
    ---------------------------------------------------------------------------
    local ingot = "sti_core:ingot_" .. elem.name
    local stick = "default:stick"

    -- Werkzeuge
    minetest.register_craft({
        output = "sti_core:pick_" .. elem.name,
        recipe = {
            {ingot, ingot, ingot},
            {"",    stick, ""},
            {"",    stick, ""}
        }
    })

    minetest.register_craft({
        output = "sti_core:axe_" .. elem.name,
        recipe = {
            {ingot, ingot, ""},
            {ingot, stick, ""},
            {"",    stick, ""}
        }
    })

    minetest.register_craft({
        output = "sti_core:shovel_" .. elem.name,
        recipe = {
            {ingot, "", ""},
            {stick, "", ""},
            {stick, "", ""}
        }
    })

    minetest.register_craft({
        output = "sti_core:sword_" .. elem.name,
        recipe = {
            {ingot, "", ""},
            {ingot, "", ""},
            {stick, "", ""}
        }
    })

    -- Rüstungen
    minetest.register_craft({
        output = "sti_core:helmet_" .. elem.name,
        recipe = {
            {ingot, ingot, ingot},
            {ingot, "",    ingot},
            {"",    "",    ""}
        }
    })

    minetest.register_craft({
        output = "sti_core:chestplate_" .. elem.name,
        recipe = {
            {ingot, "",    ingot},
            {ingot, ingot, ingot},
            {ingot, ingot, ingot}
        }
    })

    minetest.register_craft({
        output = "sti_core:leggings_" .. elem.name,
        recipe = {
            {ingot, ingot, ingot},
            {ingot, "",    ingot},
            {ingot, "",    ingot}
        }
    })

    minetest.register_craft({
        output = "sti_core:boots_" .. elem.name,
        recipe = {
            {ingot, "",    ingot},
            {ingot, "",    ingot},
            {"",    "",    ""}
        }
    })
end

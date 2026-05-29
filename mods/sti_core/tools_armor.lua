-- tools_armor.lua

for _, elem in ipairs(elements) do
    local tools = {
        {"pick", "Spitzhacke"},
        {"axe",  "Axt"},
        {"shovel", "Schaufel"},
        {"sword", "Schwert"}
    }

    for _, t in ipairs(tools) do
        -- HIER IST DIE KORREKTE REIHENFOLGE:
        -- 1. Wir nehmen den Kopf: "sti_core_tool_head_pick.png"
        -- 2. Wir färben NUR den Kopf ein: "^[multiply:FARBE"
        -- 3. Wir fügen den ungefärbten Stiel hinzu: "^sti_core_tool_handle.png"

        local tool_texture = "sti_core_tool_head_" .. t[1] .. ".png^[multiply:" .. elem.color .. "^sti_core_tool_handle.png"

        minetest.register_tool("sti_core:" .. t[1] .. "_" .. elem.name, {
            description = elem.desc .. "-" .. t[2],
            inventory_image = tool_texture,
            wield_image = tool_texture,

            tool_capabilities = {
                full_punch_interval = 1.0,
                groupcaps = {
                    cracky = {times={[1]=3.0, [2]=2.0, [3]=1.0}, uses=20, maxlevel=1},
                }
            }
        })
    end
end

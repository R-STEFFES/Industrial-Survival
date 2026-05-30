-- =======================================================================
-- STI MACHINES - LIQUID WORKBENCH (CRAFTING MIT FLÜSSIGKEIT & STROM)
-- =======================================================================

local function update_lwb_formspec(pos)
    local meta = minetest.get_meta(pos)
    local tank = meta:get_int("tank_amount")
    local tank_max = 8000
    local energy = meta:get_int("energy")
    local energy_max = 8000

    -- Symmetrisches und sauberes GUI
    local formspec = "size[9,10]" ..
        "label[0.5,0.3;--- LIQUID WORKBENCH ---]" ..

        -- Flüssigkeits-Tank (Blau)
        "label[0.5,1.0;Wasser:]" ..
        "label[0.5,1.4;" .. tank .. " / " .. tank_max .. " mb]" ..
        "box[0.5,1.8;0.6,3.0;#333333]" ..
        (tank > 0 and "box[0.5," .. (1.8 + (3.0 - (tank / tank_max * 3))) .. ";0.6," .. (tank / tank_max * 3) .. ";#00d4ff]" or "") ..

        -- Energie-Akku (Gelb)
        "label[1.8,1.0;Energie:]" ..
        "label[1.8,1.4;" .. energy .. " / " .. energy_max .. " EU]" ..
        "box[1.8,1.8;0.6,3.0;#333333]" ..
        (energy > 0 and "box[1.8," .. (1.8 + (3.0 - (energy / energy_max * 3))) .. ";0.6," .. (energy / energy_max * 3) .. ";#ffff00]" or "") ..

        -- 3x3 Crafting Grid
        "label[3.2,1.4;Rezept Grid:]" ..
        "list[context;recipe;3.2,1.8;3,3;]" ..

        -- Pfeil-Indikator
        "image[6.2,2.8;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..

        -- Output Slot
        "label[7.5,2.4;Ausgabe:]" ..
        "list[context;output;7.5,2.8;1,1;]" ..

        -- Spieler-Inventar
        "label[0.5,5.6;Inventar:]" ..
        "list[current_player;main;0.5,6.0;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;recipe]" ..
        "listring[context;output]"

    meta:set_string("formspec", formspec)
end

minetest.register_node("sti_machines:liquid_workbench", {
    description = "Liquid Workbench",
    tiles = {
        "stimachines_lwb_top.png", "stimachines_lwb_bottom.png",
        "stimachines_lwb_side.png", "stimachines_lwb_side.png",
        "stimachines_lwb_side.png", "stimachines_lwb_side.png"
    },
    paramtype2 = "facedir",

    groups = {
        cracky = 2,
        machine_fluid = 1,
        machine_item = 1,
        machine_power = 1,
        technic_machine = 1
    },
    is_energy_consumer = true,

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("recipe", 9)
        inv:set_size("output", 1)

        meta:set_int("tank_amount", 0)
        meta:set_int("energy", 0)
        meta:set_int("max_energy", 8000)

        -- Alle Richtungen fest auf Fluid Input (3), damit Leitungen immer andocken
        meta:set_int("side_top", 3)
        meta:set_int("side_bottom", 3)
        meta:set_int("side_front", 3)
        meta:set_int("side_back", 3)
        meta:set_int("side_left", 3)
        meta:set_int("side_right", 3)

        update_lwb_formspec(pos)
    end,

    -- Callbacks für Itemducts (Eingang/Ausgang)
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "recipe" then return stack:get_count() end
        return 0
    end,

    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if listname == "output" then return stack:get_count() end
        return 0
    end,

    -- FIX: Kommas am Zeilenende hinzugefügt, um Tabellensyntax zu korrigieren
    on_metadata_inventory_move = function(pos) minetest.get_node_timer(pos):start(0.2) end,
    on_metadata_inventory_put = function(pos) minetest.get_node_timer(pos):start(0.2) end,
    on_metadata_inventory_take = function(pos) minetest.get_node_timer(pos):start(0.2) end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local tank = meta:get_int("tank_amount")
        local energy = meta:get_int("energy")
        local recipe = inv:get_list("recipe")

        -- Crafting Logik
        if recipe[1] and recipe[1]:get_name() == "default:steel_ingot" then
            if tank >= 1000 and energy >= 200 then
                if inv:room_for_item("output", "default:obsidian_shard") then
                    meta:set_int("tank_amount", tank - 1000)
                    meta:set_int("energy", energy - 200)

                    local stack = recipe[1]
                    stack:take_item(1)
                    inv:set_stack("recipe", 1, stack)

                    inv:add_item("output", "default:obsidian_shard")
                end
            end
        end

        update_lwb_formspec(pos)
        return true
    end,
})

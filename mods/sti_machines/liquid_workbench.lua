-- =======================================================================
-- STI MACHINES - LIQUID WORKBENCH (CRAFTING MIT FLÜSSIGKEIT)
-- =======================================================================

local function update_lwb_formspec(pos)
    local meta = minetest.get_meta(pos)
    local tank = meta:get_int("tank_amount")

    local formspec = "size[8,9.5]" ..
        "label[0.5,0.3;--- LIQUID WORKBENCH ---]" ..

        -- Tank Anzeige links
        "label[0.5,1.0;Flüssigkeit:]" ..
        "label[0.5,1.4;" .. tank .. " / 8000 mb]" ..
        "box[0.5,1.8;0.4,3.0;#333333]" ..
        (tank > 0 and "box[0.5," .. (1.8 + (3.0 - (tank/8000*3))) .. ";0.4," .. (tank/8000*3) .. ";#00d4ff]" or "") ..

        -- 3x3 Crafting Feld
        "list[context;recipe;1.5,1.5;3,3;]" ..
        "image[5.0,2.5;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..

        -- Output Slot
        "list[context;output;6.5,2.5;1,1;]" ..

        "list[current_player;main;0,5.3;8,4;]"
    meta:set_string("formspec", formspec)
end

minetest.register_node("sti_machines:liquid_workbench", {
    description = "Liquid Workbench",
    tiles = {"stimachines_lwb_top.png", "stimachines_lwb_bottom.png", "stimachines_lwb_side.png"},
    groups = {cracky = 2, machine_fluid = 1},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("recipe", 9)
        inv:set_size("output", 1)
        meta:set_int("tank_amount", 0)
        update_lwb_formspec(pos)
    end,

    -- Logik für Flüssigkeits-Rezepte
    on_metadata_inventory_move = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local tank = meta:get_int("tank_amount")

        -- Beispiel: Ein spezielles Rezept, das Wasser braucht
        -- Hier prüfen wir, ob das 3x3 Feld ein "Rezept" ergibt
        local recipe = inv:get_list("recipe")

        -- Logik-Beispiel: Wenn 1 Eisen im Slot 1 liegt UND 1000mb Wasser da sind -> "Nasser Stahl"
        if recipe[1]:get_name() == "default:steel_ingot" and tank >= 1000 then
            inv:set_stack("output", 1, "default:obsidian_shard") -- Beispiel Resultat
        end
        update_lwb_formspec(pos)
    end,
})

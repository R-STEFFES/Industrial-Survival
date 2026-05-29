-- =======================================================================
-- STI MACHINES - AUTOCRAFTER (3x3 AUTOMATISCHE FERTIGUNG)
-- =======================================================================

local function update_autocrafter_formspec(pos)
    local meta = minetest.get_meta(pos)
    local energy = meta:get_int("energy")
    local energy_max = meta:get_int("energy_max")
    local status = meta:get_string("status_msg") or "Bereit"

    local formspec = "size[10,10]" ..
        "label[0.5,0.2;--- AUTOCRAFTER ---]" ..
        "label[0.5,0.6;Status: " .. status .. "]" ..
        "label[0.5,1.2;Rezept-Muster:]" ..
        "list[context;recipe;0.5,1.6;3,3;]" ..
        "image[3.7,2.6;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
        "label[0.5,4.7;Energie: " .. energy .. " / " .. energy_max .. " EU]" ..
        "box[0.5,5.1;3.0,0.2;#333333]" ..
        (energy > 0 and "box[0.5,5.1;" .. (energy / energy_max * 3.0) .. ",0.2;#ffff00]" or "") ..
        "label[5.0,1.2;Material-Vorrat:]" ..
        "list[context;main_inv;5.0,1.6;4,3;]" ..
        "label[5.0,4.7;Ausgabe:]" ..
        "list[context;dst;6.5,4.7;1,1;]" ..
        "list[current_player;main;1,6;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;main_inv]"
    meta:set_string("formspec", formspec)
end

minetest.register_node("sti_machines:autocrafter", {
    description = "Autocrafter",
    tiles = {
        "stimachines_crafter_top.png", "stimachines_machine_bottom.png",
        "stimachines_machine_side.png", "stimachines_machine_side.png",
        "stimachines_machine_side.png", "stimachines_crafter_front.png"
    },
    paramtype2 = "facedir",
    groups = {cracky = 2, technic_machine = 1, machine_item = 1},
    is_energy_consumer = true, -- Flag für Energieaufnahme

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("recipe", 9)
        inv:set_size("main_inv", 12)
        inv:set_size("dst", 1)
        meta:set_int("energy", 0)
        meta:set_int("energy_max", 8000)
        meta:set_string("status_msg", "Bereit.")
        -- Timer starten, damit Energie geladen werden kann
        minetest.get_node_timer(pos):start(1.0)
        update_autocrafter_formspec(pos)
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local energy = meta:get_int("energy")

        -- HIER: Energie aus Netzwerk laden (Logik muss hier rein)
        -- energy = energy + (technic_input oder ähnliches)

        local recipe_list = inv:get_list("recipe")
        local craft_result, _ = minetest.get_craft_result({method = "normal", width = 3, items = recipe_list})

        if not craft_result.item:is_empty() then
            if energy < 100 then
                meta:set_string("status_msg", "Zu wenig Energie!")
            else
                local needed_items = {}
                for _, item in ipairs(recipe_list) do
                    if not item:is_empty() then
                        local name = item:get_name()
                        needed_items[name] = (needed_items[name] or 0) + 1
                    end
                end

                local has_all = true
                for name, count in pairs(needed_items) do
                    if not inv:contains_item("main_inv", name .. " " .. count) then
                        has_all = false
                        break
                    end
                end

                if has_all and inv:room_for_item("dst", craft_result.item) then
                    for name, count in pairs(needed_items) do
                        inv:remove_item("main_inv", name .. " " .. count)
                    end
                    inv:add_item("dst", craft_result.item)
                    meta:set_int("energy", energy - 100)
                    meta:set_string("status_msg", "Produziert...")
                elseif not has_all then
                    meta:set_string("status_msg", "Material fehlt!")
                else
                    meta:set_string("status_msg", "Ausgang voll!")
                end
            end
        else
            meta:set_string("status_msg", "Kein Rezept.")
        end

        update_autocrafter_formspec(pos)
        return true -- Timer läuft weiter
    end,
})

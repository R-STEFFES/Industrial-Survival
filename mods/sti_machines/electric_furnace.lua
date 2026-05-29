-- =======================================================================
-- 3. ELEKTRISCHER OFEN (Strom -> Items schmelzen) mit Active-State
-- =======================================================================

function sti_machines.update_elecfurnace_formspec(pos)
    local meta = minetest.get_meta(pos)
    local energy = meta:get_int("energy")
    local max_energy = meta:get_int("max_energy")
    local cook_time = meta:get_float("cook_time")
    local max_cook_time = meta:get_float("max_cook_time")

    local formspec = "size[8,9]" ..
        "label[0.5,0.5;--- ELEKTRISCHER OFEN ---]" ..
        "label[1.5,1.2;Eingabe]" ..
        "list[context;src;1.5,1.7;1,1;]" ..
        "label[5.5,1.2;Ausgabe]" ..
        "list[context;dst;5.5,1.7;2,1;]" ..
        "label[1.5,3.0;Energie: " .. energy .. " / " .. max_energy .. " EU]" ..
        "box[3.0,2.0;2,0.3;#333333]"

    if cook_time > 0 and max_cook_time > 0 then
        local bar_width = (cook_time / max_cook_time) * 2
        formspec = formspec .. "box[3.0,2.0;" .. bar_width .. ",0.3;#ff0000]"
    end

    formspec = formspec ..
        "list[current_player;main;0,4.8;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;src]" ..
        "listring[context;dst]"

    meta:set_string("formspec", formspec)
end

local furnace_def = {
    description = "Elektrischer Ofen",
    paramtype2 = "facedir",
    groups = {cracky = 2, technic_machine = 1, machine_item = 1},
    is_energy_consumer = true, -- Direktes Flag für das Kabel

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("src", 1)
        inv:set_size("dst", 2)

        meta:set_int("energy", 0)
        meta:set_int("max_energy", 4000)
        meta:set_int("energy_usage", 40)
        meta:set_float("cook_time", 0.0)
        meta:set_float("max_cook_time", 0.0)
        meta:set_string("infotext", "E-Ofen: Bereit.")

        update_elecfurnace_formspec(pos)
    end,

    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        minetest.get_node_timer(pos):start(1.0)
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        local energy = meta:get_int("energy")
        local usage = meta:get_int("energy_usage")
        local cook_time = meta:get_float("cook_time")
        local max_cook_time = meta:get_float("max_cook_time")

        local node = minetest.get_node(pos)
        local is_smelting = false

        local src_stack = inv:get_stack("src", 1)
        local result, _ = minetest.get_craft_result({method = "cooking", width = 1, items = {src_stack}})

        if result and result.time and result.time > 0 then
            max_cook_time = result.time
            meta:set_float("max_cook_time", max_cook_time)

            if energy >= usage then
                energy = energy - usage
                cook_time = cook_time + 1.0
                is_smelting = true

                meta:set_string("infotext", "E-Ofen: Schmilzt... (" .. energy .. " EU)")

                if cook_time >= max_cook_time then
                    if inv:room_for_item("dst", result.item) then
                        src_stack:take_item(1)
                        inv:set_stack("src", 1, src_stack)
                        inv:add_item("dst", result.item)
                        cook_time = 0.0
                    else
                        meta:set_string("infotext", "E-Ofen: Ausgang voll!")
                        is_smelting = false
                    end
                end
            else
                meta:set_string("infotext", "E-Ofen: Zu wenig Energie! (" .. energy .. " EU)")
            end
        else
            cook_time = 0.0
            max_cook_time = 0.0
            meta:set_string("infotext", "E-Ofen: Bereit.\nEnergie: " .. energy .. " EU")
        end

        if is_smelting then
            if node.name ~= "sti_machines:electric_furnace_active" then
                minetest.swap_node(pos, {name = "sti_machines:electric_furnace_active", param2 = node.param2})
            end
        else
            if node.name ~= "sti_machines:electric_furnace" then
                minetest.swap_node(pos, {name = "sti_machines:electric_furnace", param2 = node.param2})
            end
        end

        meta:set_int("energy", energy)
        meta:set_float("cook_time", cook_time)
        sti_machines.update_elecfurnace_formspec(pos)

        return (not src_stack:is_empty() or energy > 0)
    end
}

local furn_inactive = table.copy(furnace_def)
furn_inactive.tiles = {
    "stimachines_efurnace_top.png", "stimachines_efurnace_bottom.png",
    "stimachines_efurnace_side.png", "stimachines_efurnace_side.png",
    "stimachines_efurnace_side.png", "stimachines_efurnace_front.png"
}
minetest.register_node("sti_machines:electric_furnace", furn_inactive)

local furn_active = table.copy(furnace_def)
furn_active.tiles = {
    "stimachines_efurnace_top.png", "stimachines_efurnace_bottom.png",
    "stimachines_efurnace_side.png", "stimachines_efurnace_side.png",
    "stimachines_efurnace_side.png", "stimachines_efurnace_front_active.png"
}
furn_active.groups = {cracky = 2, technic_machine = 1, machine_item = 1, not_in_creative_inventory = 1}
furn_active.light_source = 8
minetest.register_node("sti_machines:electric_furnace_active", furn_active)

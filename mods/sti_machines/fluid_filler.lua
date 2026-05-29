-- =======================================================================
-- STI MACHINES - FLUID FILLER (ABFÜLLER)
-- =======================================================================

local sides = {"top", "bottom", "front", "back", "left", "right"}

local function get_side_color(mode)
    if mode == 1 then return "#3366ff" end -- Blau (Input)
    if mode == 2 then return "#ffaa00" end -- Orange (Output)
    return "#555555" -- Grau
end

local function update_filler_formspec(pos)
    local meta = minetest.get_meta(pos)
    local tank_amount = meta:get_int("tank_amount")
    local tank_max = 8000
    local energy = meta:get_int("energy")
    local energy_max = 4000
    local status = meta:get_string("status_msg") or "Bereit"

    local m_top    = meta:get_int("side_top")
    local m_bottom = meta:get_int("side_bottom")
    local m_front  = meta:get_int("side_front")
    local m_back   = meta:get_int("side_back")
    local m_left   = meta:get_int("side_left")
    local m_right  = meta:get_int("side_right")

    local formspec = "size[9,9.5]" ..
        "label[0.5,0.3;--- FLUID FILLER (ABFÜLLER) ---]" ..
        "label[0.5,0.8;Status: " .. status .. "]" ..

        -- Tankanzeige (Analog zur Pumpe)
        "label[0.5,1.3;Interner Tank: " .. tank_amount .. " / " .. tank_max .. " mb]" ..
        "box[0.5,1.7;3.5,0.2;#333333]" ..
        (tank_amount > 0 and "box[0.5,1.7;" .. (tank_amount / tank_max * 3.5) .. ",0.2;#00d4ff]" or "") ..

        -- Energieanzeige
        "label[4.5,1.3;Energie: " .. energy .. " / " .. energy_max .. " EU]" ..
        "box[4.5,1.7;3.5,0.2;#333333]" ..
        (energy > 0 and "box[4.5,1.7;" .. (energy / energy_max * 3.5) .. ",0.2;#ffff00]" or "") ..

        -- Slots
        "label[0.5,2.3;Leeres Gefäß:]" ..
        "list[context;src;0.5,2.7;1,1;]" ..
        "image[2.0,2.7;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
        "label[3.5,2.3;Abgefüllt:]" ..
        "list[context;dst;3.5,2.7;1,1;]" ..

        -- Seiten-Konfiguration
        "label[5.5,2.3;Seiten-Konfiguration:]" ..
        "style[btn_top;bgcolor=" .. get_side_color(m_top) .. "]" ..
        "button[6.5,2.8;1.0,0.6;btn_top;Oben]" ..
        "style[btn_bottom;bgcolor=" .. get_side_color(m_bottom) .. "]" ..
        "button[6.5,4.0;1.0,0.6;btn_bottom;Unten]" ..
        "style[btn_left;bgcolor=" .. get_side_color(m_left) .. "]" ..
        "button[5.3,3.4;1.0,0.6;btn_left;Links]" ..
        "style[btn_front;bgcolor=" .. get_side_color(m_front) .. "]" ..
        "button[6.5,3.4;1.0,0.6;btn_front;Vorn]" ..
        "style[btn_right;bgcolor=" .. get_side_color(m_right) .. "]" ..
        "button[7.7,3.4;1.0,0.6;btn_right;Rechts]" ..

        "list[current_player;main;0.5,5.3;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;src]" ..
        "listring[context;dst]"

    meta:set_string("formspec", formspec)
end

minetest.register_node("sti_machines:fluid_filler", {
    description = "Fluid Filler (Abfüller)",
    tiles = {
        "stimachines_machine_top.png", "stimachines_machine_bottom.png",
        "stimachines_machine_side.png", "stimachines_machine_side.png",
        "stimachines_machine_side.png", "stimachines_filler_front.png"
    },
    paramtype2 = "facedir",
    groups = {cracky = 2, machine_fluid = 1, machine_item = 1},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("src", 1)
        inv:set_size("dst", 1)
        meta:set_int("tank_amount", 0)
        meta:set_int("energy", 0)
        meta:set_int("side_top", 1) -- Standard: Oben Input (Blau)
        update_filler_formspec(pos)
    end,

    on_receive_fields = function(pos, formname, fields, sender)
        local meta = minetest.get_meta(pos)
        for _, side in ipairs(sides) do
            if fields["btn_" .. side] then
                local mode = meta:get_int("side_" .. side)
                meta:set_int("side_" .. side, (mode + 1) % 3)
                update_filler_formspec(pos)
            end
        end
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local tank = meta:get_int("tank_amount")
        local energy = meta:get_int("energy")
        local src_stack = inv:get_stack("src", 1)

        if src_stack:is_empty() then
            meta:set_string("status_msg", "Wartet auf leere Gefäße...")
            update_filler_formspec(pos)
            return true
        end

        -- Abfüllen (Beispiel für Standard-Eimer)
        if src_stack:get_name() == "bucket:bucket_empty" then
            if tank >= 1000 and energy >= 20 then
                if inv:room_for_item("dst", "bucket:bucket_water") then
                    meta:set_int("tank_amount", tank - 1000)
                    meta:set_int("energy", energy - 20)
                    src_stack:take_item(1)
                    inv:set_stack("src", 1, src_stack)
                    inv:add_item("dst", "bucket:bucket_water")
                    meta:set_string("status_msg", "Fülle Eimer...")
                else
                    meta:set_string("status_msg", "Ausgang voll!")
                end
            else
                meta:set_string("status_msg", "Nicht genug Wasser/Energie!")
            end
        else
            meta:set_string("status_msg", "Ungültiges Gefäß!")
        end

        update_filler_formspec(pos)
        return true
    end,

    on_metadata_inventory_put = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,
})

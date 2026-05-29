-- =======================================================================
-- STI MACHINES - GOLDWASCHANLAGE (WASSER + ENERGIE)
-- =======================================================================

local sides = {"top", "bottom", "front", "back", "left", "right"}

local function get_side_color(mode)
    if mode == 1 then return "#3366ff" end -- Blau (Input)
    if mode == 2 then return "#ffaa00" end -- Orange (Output)
    return "#555555" -- Grau
end

local function update_washer_formspec(pos)
    local meta = minetest.get_meta(pos)
    local tank_amount = meta:get_int("tank_amount")
    local energy = meta:get_int("energy")
    local status = meta:get_string("status_msg") or "Bereit"

    local m_top    = meta:get_int("side_top")
    local m_bottom = meta:get_int("side_bottom")
    local m_front  = meta:get_int("side_front")
    local m_back   = meta:get_int("side_back")
    local m_left   = meta:get_int("side_left")
    local m_right  = meta:get_int("side_right")

    local formspec = "size[9,9.5]" ..
        "label[0.5,0.3;--- GOLDWASCHANLAGE ---]" ..
        "label[0.5,0.8;Status: " .. status .. "]" ..

        -- Tank & Energie Anzeige
        "label[0.5,1.3;Wasser: " .. tank_amount .. " / 8000 mb]" ..
        "box[0.5,1.7;3.5,0.2;#333333]" ..
        (tank_amount > 0 and "box[0.5,1.7;" .. (tank_amount / 8000 * 3.5) .. ",0.2;#00d4ff]" or "") ..

        "label[4.5,1.3;Energie: " .. energy .. " / 4000 EU]" ..
        "box[4.5,1.7;3.5,0.2;#333333]" ..
        (energy > 0 and "box[4.5,1.7;" .. (energy / 4000 * 3.5) .. ",0.2;#ffff00]" or "") ..

        -- Inventar Slots
        "label[0.5,2.2;Input (Erde/Sand):]" ..
        "list[context;src;0.5,2.6;1,1;]" ..
        "label[2.5,2.2;Output (Nuggets/Lehm):]" ..
        "list[context;dst;2.5,2.6;4,2;]" ..

        -- Seiten-Konfiguration
        "label[7.0,2.2;Seiten:]" ..
        "style[btn_top;bgcolor=" .. get_side_color(m_top) .. "]" ..
        "button[7.0,2.6;1.5,0.6;btn_top;Oben]" ..
        "style[btn_bottom;bgcolor=" .. get_side_color(m_bottom) .. "]" ..
        "button[7.0,3.3;1.5,0.6;btn_bottom;Unten]" ..

        "list[current_player;main;0.5,5.3;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;src]" ..
        "listring[context;dst]"

    meta:set_string("formspec", formspec)
end

minetest.register_node("sti_machines:gold_washer", {
    description = "Goldwaschanlage",
    tiles = {
        "stimachines_washer_top.png", "stimachines_machine_bottom.png",
        "stimachines_machine_side.png", "stimachines_machine_side.png",
        "stimachines_machine_side.png", "stimachines_washer_front.png"
    },
    paramtype2 = "facedir",
    groups = {cracky = 2, machine_fluid = 1, machine_item = 1},
    is_energy_consumer = true, -- Pflicht: damit push_energy_network ihn findet

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("src", 1)
        inv:set_size("dst", 8)
        meta:set_int("tank_amount", 0)
        meta:set_int("energy", 0)
        meta:set_int("max_energy", 4000) -- WICHTIG: muss "max_energy" heißen für push_energy_network
        meta:set_int("side_top", 1) -- Oben Wasser-In
        update_washer_formspec(pos)
    end,

    on_receive_fields = function(pos, formname, fields, sender)
        local meta = minetest.get_meta(pos)
        for _, side in ipairs(sides) do
            if fields["btn_" .. side] then
                local mode = meta:get_int("side_" .. side)
                meta:set_int("side_" .. side, (mode + 1) % 3)
                update_washer_formspec(pos)
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
            meta:set_string("status_msg", "Wartet auf Erde/Sand...")
            update_washer_formspec(pos)
            return true
        end

        -- Kosten pro Waschgang: 100mb Wasser + 50 EU
        if tank >= 100 and energy >= 50 then
            -- Chance auf Erfolg (Simulation des Waschens)
            if math.random(1, 5) == 1 then
                local res = "default:clay_lump"
                local rand = math.random(1, 100)

                -- Beute-Tabelle basierend auf Wahrscheinlichkeiten
                if rand > 95 then res = "sti_core:gold_nugget"
                elseif rand > 90 then res = "sti_core:silver_nugget"
                elseif rand > 70 then res = "default:clay_lump"
                elseif rand > 40 then res = "default:gravel"
                else res = "default:sand" end

                if inv:room_for_item("dst", res) then
                    inv:add_item("dst", res)
                    src_stack:take_item(1)
                    inv:set_stack("src", 1, src_stack)
                    meta:set_int("tank_amount", tank - 100)
                    meta:set_int("energy", energy - 50)
                end
            end
            meta:set_string("status_msg", "Wäscht...")
        else
            meta:set_string("status_msg", "Mangel an Wasser/Strom!")
        end

        update_washer_formspec(pos)
        return true
    end,

    on_metadata_inventory_put = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,
})

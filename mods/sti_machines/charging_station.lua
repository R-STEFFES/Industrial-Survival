-- =======================================================================
-- STI MACHINES - LADESTATION (STROM -> ITEMS AUFLADEN)
-- =======================================================================

local function update_charging_formspec(pos)
    local meta = minetest.get_meta(pos)
    local energy = meta:get_int("energy")
    local energy_max = meta:get_int("max_energy")
    local status = meta:get_string("status_msg") or "Bereit"

    local formspec = "size[8,9]" ..
        "label[0.5,0.5;--- LADESTATION ---]" ..
        "label[0.5,1.0;Status: " .. status .. "]" ..

        -- Energieanzeige
        "label[0.5,1.8;Speicher: " .. energy .. " / " .. energy_max .. " EU]" ..
        "box[0.5,2.2;7,0.3;#333333]" ..
        (energy > 0 and "box[0.5,2.2;" .. (energy / energy_max * 7) .. ",0.3;#ffff00]" or "") ..

        -- Lade-Slot
        "label[3.5,3.0;Item zum Laden:]" ..
        "list[context;src;3.5,3.5;1,1;]" ..

        -- Spieler-Inventar
        "list[current_player;main;0,5;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;src]"
    meta:set_string("formspec", formspec)
end

minetest.register_node("sti_machines:charging_station", {
    description = "Ladestation",
    tiles = {
        "stimachines_machine_top.png", "stimachines_machine_bottom.png",
        "stimachines_machine_side.png", "stimachines_machine_side.png",
        "stimachines_machine_side.png", "stimachines_charge_front.png"
    },
    paramtype2 = "facedir", -- Erlaubt Rotation[cite: 3]
    groups = {cracky = 2, technic_machine = 1, machine_item = 1}, -- Flags für Netzwerk-Erkennung[cite: 3]
    is_energy_consumer = true, -- Flag für Energieaufnahme[cite: 3]

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("src", 1)
        meta:set_int("energy", 0)
        meta:set_int("max_energy", 10000)
        meta:set_string("status_msg", "Bereit.")
        update_charging_formspec(pos)
    end,

    on_metadata_inventory_put = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local energy = meta:get_int("energy")
        local stack = inv:get_stack("src", 1)

        -- 1. Status prüfen
        if stack:is_empty() then
            meta:set_string("status_msg", "Warte auf Item...")
        elseif stack:get_wear() == 0 then
            meta:set_string("status_msg", "Vollständig geladen!")
        else
            -- 2. Ladevorgang
            if energy >= 100 then
                local charge_step = 1000
                local new_wear = math.max(0, stack:get_wear() - charge_step)
                stack:set_wear(new_wear)
                inv:set_stack("src", 1, stack)
                meta:set_int("energy", energy - 100)
                meta:set_string("status_msg", "Lädt...")
            else
                meta:set_string("status_msg", "Mangel an Energie!")
            end
        end

        update_charging_formspec(pos)
        -- Timer läuft weiter, solange Item vorhanden oder Energie im Speicher
        return (not stack:is_empty() or energy > 0)
    end,
})

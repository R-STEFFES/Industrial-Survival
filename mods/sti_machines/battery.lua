-- =======================================================================
-- 2. AKKU BLOCK (Konfigurierbar: Input / Output)
-- =======================================================================

function sti_machines.update_battery_formspec(pos)
    local meta = minetest.get_meta(pos)
    local energy = meta:get_int("energy")
    local max_energy = meta:get_int("max_energy")
    local mode = meta:get_string("mode")

    local mode_label = mode == "input" and "MODUS: LADEN (INPUT)" or "MODUS: ENTLADEN (OUTPUT)"
    local button_label = mode == "input" and "Zu Output wechseln" or "Zu Input wechseln"

    local formspec = "size[8,5]" ..
        "label[0.5,0.5;--- RECONFIGURABLE BATTERY ---]" ..
        "label[0.5,1.2;Speicher: " .. energy .. " / " .. max_energy .. " EU]" ..
        "label[0.5,1.8;" .. mode_label .. "]" ..
        "button[0.5,2.3;4,0.8;toggle_mode;" .. button_label .. "]" ..
        "box[0.5,3.5;7,0.3;#333333]"

    if energy > 0 and max_energy > 0 then
        local bar_width = (energy / max_energy) * 7
        formspec = formspec .. "box[0.5,3.5;" .. bar_width .. ",0.3;#00aaff]"
    end

    meta:set_string("formspec", formspec)
end

minetest.register_node("sti_machines:battery", {
    description = "Akkumulator (Konfigurierbar)",
    tiles = {"stimachines_battery_top.png", "stimachines_battery_bottom.png", "stimachines_battery_side.png"},
    groups = {cracky = 2, technic_machine = 1, machine_power = 1},
    is_energy_consumer = true, -- Im Input-Modus: Energie vom Netz aufnehmen

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("energy", 0)
        meta:set_int("max_energy", 50000)
        meta:set_string("mode", "input")
        meta:set_string("infotext", "Akku: Bereit.\nModus: INPUT")
        sti_machines.update_battery_formspec(pos)
    end,

    on_receive_fields = function(pos, formname, fields, player)
        local meta = minetest.get_meta(pos)
        if fields.toggle_mode then
            local current_mode = meta:get_string("mode")
            local new_mode = current_mode == "input" and "output" or "input"
            meta:set_string("mode", new_mode)

            minetest.get_node_timer(pos):start(1.0)
            sti_machines.update_battery_formspec(pos)
        end
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local mode = meta:get_string("mode")
        local energy = meta:get_int("energy")
        local max_energy = meta:get_int("max_energy")

        meta:set_string("infotext", "Akku: Aktiv (" .. mode:upper() .. ")\nEnergie: " .. energy .. " / " .. max_energy .. " EU")

        -- Wenn der Akku im Output-Modus ist, lädt er aktiv Maschinen daneben auf
        if mode == "output" and energy > 0 then
            local neighbors = {
                {x=pos.x+1, y=pos.y, z=pos.z}, {x=pos.x-1, y=pos.y, z=pos.z},
                {x=pos.x, y=pos.y+1, z=pos.z}, {x=pos.x, y=pos.y-1, z=pos.z},
                {x=pos.x, y=pos.y, z=pos.z+1}, {x=pos.x, y=pos.y, z=pos.z-1}
            }
            for _, npos in ipairs(neighbors) do
                local nmeta = minetest.get_meta(npos)
                -- Wenn der Nachbar ein Ofen/Verbraucher ist, fülle ihn ab
                if nmeta and nmeta:get_int("max_energy") and nmeta:get_string("mode") ~= "output" then
                    local n_energy = nmeta:get_int("energy")
                    local n_max = nmeta:get_int("max_energy")
                    if n_energy < n_max then
                        local transfer = math.min(200, energy, n_max - n_energy)
                        energy = energy - transfer
                        nmeta:set_int("energy", n_energy + transfer)

                        local n_timer = minetest.get_node_timer(npos)
                        if not n_timer:is_started() then n_timer:start(1.0) end
                    end
                end
            end
        end

        meta:set_int("energy", energy)
        sti_machines.update_battery_formspec(pos)
        return (mode == "output" and energy > 0)
    end
})

-- Externe API zum Laden der Batterie (für Kabel oder Generatoren daneben)
function sti_machines.charge_battery(pos, amount)
    local meta = minetest.get_meta(pos)
    if not meta then return 0 end

    -- Prüfen, ob es wirklich eine Batterie im Input-Modus ist
    if meta:get_int("max_energy") == 50000 and meta:get_string("mode") == "input" then
        local energy = meta:get_int("energy")
        local max_energy = meta:get_int("max_energy")
        local accepted = math.min(max_energy - energy, amount)

        if accepted > 0 then
            meta:set_int("energy", energy + accepted)
            local timer = minetest.get_node_timer(pos)
            if not timer:is_started() then timer:start(1.0) end
            return accepted
        end
    end
    return 0
end

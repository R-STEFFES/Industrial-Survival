-- =======================================================================
-- 3. STROMKABEL (Aktivierte Energieverteilung)
-- =======================================================================

minetest.register_node("mylogistics:cable", {
    description = "Stromkabel (Kupfer)",
    drawtype = "nodebox",
    paramtype = "light",
    tiles = {"mylogistics_cable.png"},
    groups = {cracky = 3, cable = 1, technic_cable = 1},
    node_box = {
        type = "connected",
        fixed = {{-0.1, -0.1, -0.1, 0.1, 0.1, 0.1}},
        connect_top = {{-0.1, 0.1, -0.1, 0.1, 0.5, 0.1}},
        connect_bottom = {{-0.1, -0.5, -0.1, 0.1, -0.1, 0.1}},
        connect_front = {{-0.1, -0.1, -0.5, 0.1, 0.1, -0.1}},
        connect_back = {{-0.1, -0.1, 0.1, 0.1, 0.1, 0.5}},
        connect_left = {{-0.5, -0.1, -0.1, -0.1, 0.1, 0.1}},
        connect_right = {{0.1, -0.1, -0.1, 0.5, 0.1, 0.1}},
    },
    connects_to = {"mylogistics:cable", "group:technic_machine", "group:machine_power"},

    on_construct = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,

    on_timer = function(pos, elapsed)
        -- Alle 6 Richtungen prüfen, um verbundene Maschinen zu finden
        local directions = {
            {x=0, y=1, z=0}, {x=0, y=-1, z=0},
            {x=1, y=0, z=0}, {x=-1, y=0, z=0},
            {x=0, y=0, z=1}, {x=0, y=0, z=-1}
        }

        local sources = {}
        local consumers = {}
        local total_available = 0

        for _, dir in ipairs(directions) do
            local neighbor_pos = vector.add(pos, dir)
            local nmeta = minetest.get_meta(neighbor_pos)

            if nmeta then
                local n_max = nmeta:get_int("max_energy")
                if n_max > 0 then
                    local n_mode = nmeta:get_string("mode") -- Hauptsächlich für Akkus
                    local n_energy = nmeta:get_int("energy")

                    -- Node-Definition holen, um Gruppen abzufragen
                    local n_name = minetest.get_node(neighbor_pos).name
                    local n_def = minetest.registered_nodes[n_name]

                    if n_def and n_def.groups then
                        -- Ist es eine Energiequelle? (Gruppe machine_power ODER Akku auf Output)
                        if n_def.groups.machine_power == 1 or (n_max == 50000 and n_mode == "output") then
                            if n_energy > 0 then
                                table.insert(sources, neighbor_pos)
                                total_available = total_available + n_energy
                            end
                        -- Ist es ein Verbraucher? (Gruppe machine_item ODER Akku auf Input)
                        elseif n_def.groups.machine_item == 1 or (n_max == 50000 and n_mode == "input") then
                            if n_energy < n_max then
                                table.insert(consumers, {pos = neighbor_pos, meta = nmeta, current = n_energy, max = n_max})
                            end
                        end
                    end
                end
            end
        end

        -- Wenn wir sowohl Stromquellen als auch Verbraucher am Kabel haben, transferieren wir Energie
        if total_available > 0 and #consumers > 0 then
            -- Wie viel Energie will das Netzwerk maximal übertragen pro Kabel-Tick (z.B. max 200 EU)
            local max_transfer = math.min(total_available, 200)
            local per_consumer = math.floor(max_transfer / #consumers)

            if per_consumer > 0 then
                for _, consumer in ipairs(consumers) do
                    local needed = consumer.max - consumer.current
                    local to_give = math.min(per_consumer, needed)

                    if to_give > 0 then
                        -- Ziehe die Energie anteilig aus den verfügbaren Quellen ab
                        local drawn = 0
                        for _, source_pos in ipairs(sources) do
                            if sti_machines and sti_machines.draw_energy_from_node then
                                local p = sti_machines.draw_energy_from_node(source_pos, to_give - drawn)
                                drawn = drawn + p
                                if drawn >= to_give then break end
                            end
                        end

                        -- Speise die gezogene Energie in den Verbraucher ein
                        consumer.meta:set_int("energy", consumer.current + drawn)

                        -- Wecke den Timer des Verbrauchers auf, falls er schläft
                        local t = minetest.get_node_timer(consumer.pos)
                        if not t:is_started() then t:start(1.0) end
                    end
                end
            end
        end

        return true -- Kabel-Timer läuft endlos weiter
    end
})

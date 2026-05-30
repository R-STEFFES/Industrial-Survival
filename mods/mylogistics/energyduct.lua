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
        local directions = {
            {x=0, y=1, z=0}, {x=0, y=-1, z=0},
            {x=1, y=0, z=0}, {x=-1, y=0, z=0},
            {x=0, y=0, z=1}, {x=0, y=0, z=-1}
        }

        local sources = {}
        local consumers = {}
        local neighbor_cables = {}

        -- Scan der direkten Umgebung
        for _, dir in ipairs(directions) do
            local neighbor_pos = vector.add(pos, dir)
            local n_name = minetest.get_node(neighbor_pos).name
            local n_def = minetest.registered_nodes[n_name]

            if n_def then
                -- Falls es ein anderes Kabel ist, merken zum Aufwecken
                if n_name == "mylogistics:cable" then
                    table.insert(neighbor_cables, neighbor_pos)
                else
                    local nmeta = minetest.get_meta(neighbor_pos)
                    if nmeta then
                        -- Ist es eine explizite Energiequelle?
                        if n_def.is_energy_source then
                            local n_energy = nmeta:get_int("energy")
                            if n_energy > 0 then
                                table.insert(sources, neighbor_pos)
                            end
                        -- Ist es ein expliziter Verbraucher?
                        elseif n_def.is_energy_consumer then
                            local n_energy = nmeta:get_int("energy")
                            local n_max = nmeta:get_int("max_energy")
                            if n_energy < n_max then
                                table.insert(consumers, {pos = neighbor_pos, meta = nmeta, current = n_energy, max = n_max})
                            end
                        end
                    end
                end
            end
        end

        -- Energie-Transfer ausführen
        if #sources > 0 and #consumers > 0 then
            -- Jedes Kabel verarbeitet maximal 200 EU pro Sekunde
            local max_transfer = 200
            local per_consumer = math.floor(max_transfer / #consumers)

            if per_consumer > 0 then
                for _, consumer in ipairs(consumers) do
                    local needed = consumer.max - consumer.current
                    local to_give = math.min(per_consumer, needed)

                    if to_give > 0 then
                        local drawn = 0
                        for _, source_pos in ipairs(sources) do
                            if sti_machines and sti_machines.draw_energy_from_node then
                                local p = sti_machines.draw_energy_from_node(source_pos, to_give - drawn)
                                drawn = drawn + p
                                if drawn >= to_give then break end
                            end
                        end

                        consumer.meta:set_int("energy", consumer.current + drawn)

                        -- Verbraucher-Timer starten falls nötig
                        local t = minetest.get_node_timer(consumer.pos)
                        if not t:is_started() then t:start(1.0) end

                        -- Angrenzende Kabel ebenfalls aufwecken, damit der Strom fließt
                        for _, c_pos in ipairs(neighbor_cables) do
                            local ct = minetest.get_node_timer(c_pos)
                            if not ct:is_started() then ct:start(1.0) end
                        end
                    end
                end
            end
        end

        return true
    end
})

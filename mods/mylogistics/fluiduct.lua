-- =======================================================================
-- 1. FLUIDUCTS (Flüssigkeitsleitungen) & TANK-INTEGRATION
-- =======================================================================

minetest.register_node("mylogistics:fluiduct", {
    description = "Fluiduct (Flüssigkeitsleitung)",
    drawtype = "nodebox",
    paramtype = "light",
    tiles = {"mylogistics_fluiduct.png"},
    groups = {cracky = 3, fluiduct = 1},
    node_box = {
        type = "connected",
        fixed = {{-0.2, -0.2, -0.2, 0.2, 0.2, 0.2}},
        connect_top = {{-0.2, 0.2, -0.2, 0.2, 0.5, 0.2}},
        connect_bottom = {{-0.2, -0.5, -0.2, 0.2, -0.2, 0.2}},
        connect_front = {{-0.2, -0.2, -0.5, 0.2, 0.2, -0.2}},
        connect_back = {{-0.2, -0.2, 0.2, 0.2, 0.2, 0.5}},
        connect_left = {{-0.5, -0.2, -0.2, -0.2, 0.2, 0.2}},
        connect_right = {{0.2, -0.2, -0.2, 0.5, 0.2, 0.2}},
    },
    -- Verbindet sich mit anderen Fluiducts, Inlets und Outlets
    connects_to = {"mylogistics:fluiduct", "mytank:inlet", "mytank:outlet", "group:machine_fluid"},

    on_construct = function(pos)
        minetest.get_node_timer(pos):start(1.0) -- Taktet jede Sekunde für den Transport
    end,

    on_timer = function(pos, elapsed)
        -- Logik: Suche nach Tanks/Maschinen in der Umgebung und befördere Flüssigkeit weiter
        local directions = {
            {x=0, y=1, z=0}, {x=0, y=-1, z=0},
            {x=1, y=0, z=0}, {x=-1, y=0, z=0},
            {x=0, y=0, z=1}, {x=0, y=0, z=-1}
        }

        local buffer_fluid = nil
        local buffer_amount = 0

        -- 1. Scan: Gibt es ein Outlet oder eine Maschine, die Flüssigkeit abgibt?
        for _, dir in ipairs(directions) do
            local neighbor_pos = vector.add(pos, dir)
            local node = minetest.get_node(neighbor_pos)

            if node.name == "mytank:outlet" then
                -- Hier müssten wir den dazugehörigen Controller finden.
                -- Für dieses Beispiel nehmen wir an, der Controller ist max. 10 Blöcke entfernt.
                local controller_pos = minetest.find_node_near(neighbor_pos, 10, {"mytank:controller_active"})
                if controller_pos then
                    local meta = minetest.get_meta(controller_pos)
                    local amount = meta:get_int("amount")
                    if amount > 0 then
                        buffer_fluid = meta:get_string("fluid")
                        buffer_amount = math.min(100, amount) -- 100mb pro Takt transportieren
                        break
                    end
                end
            end
        end

        -- 2. Scan: Wenn wir Flüssigkeit in der Leitung haben, suchen wir ein Inlet/Ziel
        if buffer_fluid and buffer_amount > 0 then
            for _, dir in ipairs(directions) do
                local neighbor_pos = vector.add(pos, dir)
                local node = minetest.get_node(neighbor_pos)

                if node.name == "mytank:inlet" then
                    local controller_pos = minetest.find_node_near(neighbor_pos, 10, {"mytank:controller_active"})
                    if controller_pos then
                        -- Nutze die API aus deinem ersten Mod!
                        -- Wir rufen die globale Funktion deines Tank-Mods auf:
                        if mytank and mytank.insert_fluid then
                            local inserted = mytank.insert_fluid(controller_pos, buffer_fluid, buffer_amount)
                            if inserted > 0 then
                                -- Ziehe die Flüssigkeit aus dem Quelltank ab
                                local source_controller = minetest.find_node_near(pos, 11, {"mytank:controller_active"})
                                if source_controller then
                                    local smeta = minetest.get_meta(source_controller)
                                    smeta:set_int("amount", smeta:get_int("amount") - inserted)
                                    -- Grafik-Update für den Quelltank triggern
                                    mytank.check_and_calculate_tank(source_controller)
                                end
                                break
                            end
                        end
                    end
                end
            end
        end

        return true -- Timer läuft weiter
    end
})

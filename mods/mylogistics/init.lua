local pipe = {}

-- =======================================================================
-- 1. FLUIDUCTS (Flüssigkeitsleitungen) & TANK-INTEGRATION
-- =======================================================================

-- Die Fluiduct-Leitung selbst
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
        local target_inlet_pos = nil

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

-- =======================================================================
-- 2. ITEMDUCTS (Gegenstandsleitungen)
-- =======================================================================

minetest.register_node("mylogistics:itemduct", {
    description = "Itemduct (Gegenstandsleitung)",
    drawtype = "nodebox",
    paramtype = "light",
    tiles = {"mylogistics_itemduct.png"},
    groups = {cracky = 3, itemduct = 1},
    node_box = {
        type = "connected",
        fixed = {{-0.15, -0.15, -0.15, 0.15, 0.15, 0.15}},
        connect_top = {{-0.15, 0.15, -0.15, 0.15, 0.5, 0.15}},
        connect_bottom = {{-0.15, -0.5, -0.15, 0.15, -0.15, 0.15}},
        connect_front = {{-0.15, -0.15, -0.5, 0.15, 0.15, -0.15}},
        connect_back = {{-0.15, -0.15, 0.15, 0.15, 0.15, 0.5}},
        connect_left = {{-0.5, -0.15, -0.15, -0.15, 0.15, 0.15}},
        connect_right = {{0.15, -0.15, -0.15, 0.5, 0.15, 0.15}},
    },
    connects_to = {"mylogistics:itemduct", "group:chest", "group:machine_item"},

    on_construct = function(pos)
        minetest.get_node_timer(pos):start(0.5) -- Schnellerer Takt für Items
    end,

    on_timer = function(pos, elapsed)
        local directions = {
            {x=0, y=-1, z=0}, {x=0, y=1, z=0},
            {x=1, y=0, z=0},  {x=-1, y=0, z=0},
            {x=0, y=0, z=1},  {x=0, y=0, z=-1}
        }

        local source_inv = nil
        local target_inv = nil
        local target_pos = nil

        -- Suche Kiste/Maschine am Leitungsende
        for _, dir in ipairs(directions) do
            local n_pos = vector.add(pos, dir)
            local meta = minetest.get_meta(n_pos)
            local inv = meta:get_inventory()

            if inv and inv:get_size("main") > 0 then
                -- Wenn es "main" hat, ist es eine gültige Kiste/Maschine
                if not source_inv then
                    source_inv = inv
                else
                    target_inv = inv
                    target_pos = n_pos
                    break
                end
            end
        end

        -- Item von Quelle zu Ziel schieben
        if source_inv and target_inv then
            for i = 1, source_inv:get_size("main") do
                local stack = source_inv:get_stack("main", i)
                if not stack:is_empty() then
                    if target_inv:room_for_item("main", stack:get_name()) then
                        local leftover = target_inv:add_item("main", stack:take_item(1))
                        source_inv:set_stack("main", i, stack)
                        break
                    end
                end
            end
        end
        return true
    end
})

-- =======================================================================
-- 3. STROMKABEL (Kompatibel mit universellen Systemen)
-- =======================================================================

-- Lokales Stromnetzwerk-Register (für kabellose Leistungsberechnung)
local power_networks = {}

minetest.register_node("mylogistics:cable", {
    description = "Stromkabel (Kupfer)",
    drawtype = "nodebox",
    paramtype = "light",
    tiles = {"mylogistics_cable.png"},
    -- groups: "technic_cable" macht es direkt kompatibel mit Technic!
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
        -- Hier definieren wir eine API-Schnittstelle, die du in deiner zukünftigen
        -- Maschinen-Mod aufrufen kannst, um Strom abzufragen:
        -- `mylogistics.get_power_from_network(pos)`
        return true
    end
})

-- Global zugängliche Funktionen für deine zukünftige Maschinen-Mod
mylogistics = {}

function mylogistics.register_machine_as_consumer(pos, power_demand)
    -- Funktion wird später von deinen Maschinen aufgerufen
    -- Erlaubt es, Energie aus dem Kabelnetzwerk zu ziehen
end

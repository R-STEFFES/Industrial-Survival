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

-- =======================================================================
-- ALLOY SMELTER (2 Items + Strom -> Legierung)
-- =======================================================================

minetest.register_node("sti_machines:alloy_smelter", {
    description = "Alloy Smelter",
    tiles = {"stimachines_alloy_top.png", "stimachines_machine_bottom.png", "stimachines_machine_side.png",
             "stimachines_machine_side.png", "stimachines_machine_side.png", "stimachines_alloy_front.png"},
    groups = {cracky=2, technic_machine=1},
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:get_inventory():set_size("src", 2)
        meta:get_inventory():set_size("dst", 1)
        meta:set_int("energy", 0)
        meta:set_int("max_energy", 8000)
    end,
    on_timer = function(pos, elapsed)
        local inv = minetest.get_meta(pos):get_inventory()
        local s1 = inv:get_stack("src", 1):get_name()
        local s2 = inv:get_stack("src", 2):get_name()

        -- Beispielrezept: Kupfer + Zinn = Bronze
        if (s1 == "sti_core:ingot_copper" and s2 == "sti_core:ingot_tin") or
           (s1 == "sti_core:ingot_tin" and s2 == "sti_core:ingot_copper") then
            -- Schmelzvorgang Logik hier analog zum E-Ofen
        end
        return true
    end,
})

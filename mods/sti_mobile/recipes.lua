minetest.register_craft({
    output = "sti_mobile:airplane_item",
    recipe = {
        {"",   "default:wood",   ""},
        {"sti_core:ingot_iron", "default:furnace",    "sti_core:ingot_iron"},
        {"",   "sti_core:ingot_iron",   ""},
    }
})

minetest.register_craft({
    output = "is_mobile:airplane_item",
    recipe = {
        {"",   "default:wood",   ""},
        {"is_core:ingot_iron", "default:furnace",    "is_core:ingot_iron"},
        {"",   "is_core:ingot_iron",   ""},
    }
})

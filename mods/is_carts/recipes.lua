minetest.register_craft({
    output = "is_carts:motor_cart",
    recipe = {
        {"is_core:ingot_iron",   "",   "is_core:ingot_iron"},
        {"is_core:ingot_iron", "default:furnace",    "is_core:ingot_iron"},
        {"is_core:ingot_iron",   "is_core:ingot_iron",   "is_core:ingot_iron"},
    }
})

minetest.register_craft({
	output = "is_carts:coupling_chain",
	recipe = {
		{"default:steel_ingot", "", ""},
		{"", "default:steel_ingot", ""},
		{"", "", "default:steel_ingot"},
	}
})

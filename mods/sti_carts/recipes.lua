minetest.register_craft({
    output = "sti_carts:motor_cart",
    recipe = {
        {"sti_core:ingot_iron",   "",   "sti_core:ingot_iron"},
        {"sti_core:ingot_iron", "default:furnace",    "sti_core:ingot_iron"},
        {"sti_core:ingot_iron",   "sti_core:ingot_iron",   "sti_core:ingot_iron"},
    }
})

minetest.register_craft({
	output = "sti_carts:coupling_chain",
	recipe = {
		{"default:steel_ingot", "", ""},
		{"", "default:steel_ingot", ""},
		{"", "", "default:steel_ingot"},
	}
})

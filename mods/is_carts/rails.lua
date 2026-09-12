

carts:register_rail("is_carts:hyperspeed_rail", {
	description = "Hyperspeed-Schiene (Kein Boost)",
	tiles = {
		-- Ersetze diese Texturen durch deine eigenen PNGs im /textures Ordner
		"is_carts_rail_hyper.png", "is_carts_rail_hyper_curved.png",
		"is_carts_rail_hyper_t.png", "is_carts_rail_hyper_crossing.png"
	},
	groups = carts:get_rail_groups(),
}, {
	acceleration = 0, -- 0 bedeutet: Absolut kein eigener Anschub/Boost!
	speed_max = 25    -- Das neue Tempolimit auf dieser Schiene (z.B. 25 m/s statt 7 m/s)
})

-- Crafting-Rezept für deine neue Schiene (Beispiel: Mit Gold)
minetest.register_craft({
	output = "is_carts:hyperspeed_rail 1",
	recipe = {
		{"default:steel_ingot", "default:wood", "default:steel_ingot"},
		{"default:steel_ingot", "default:wood", "default:steel_ingot"},
		{"default:steel_ingot", "default:wood", "default:steel_ingot"},
	}
})

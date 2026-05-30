-- sti_backpacks: backpack.lua

-- Liste aller Standard-Minetest-Wollfarben und deren Hex-Farbcodes
local colors = {
	{"white",      "#ffffff"},
	{"grey",       "#808080"},
	{"black",      "#151515"},
	{"red",        "#ff0000"},
	{"yellow",     "#ffff00"},
	{"green",      "#00ff00"},
	{"cyan",       "#00ffff"},
	{"blue",       "#0000ff"},
	{"magenta",    "#ff00ff"},
	{"orange",     "#ff8000"},
	{"violet",     "#8000ff"},
	{"brown",      "#a5532a"},
	{"pink",       "#ffc0cb"},
	{"dark_grey",  "#404040"},
	{"dark_green", "#008000"}
}

-- Zentrale Funktion zum Öffnen des Rucksacks
local function open_backpack(itemstack, user)
	if not user or not user:is_player() then return itemstack end

	local ctrl = user:get_player_control()

	if ctrl.sneak then
		local name = user:get_player_name()
		local meta = itemstack:get_meta()

		local detached_inv = minetest.get_inventory({type="detached", name="sti_backpacks_" .. name})

		if detached_inv then
			local saved_content = meta:get_string("contents")
			if saved_content ~= "" then
				local table_content = minetest.deserialize(saved_content) or {}
				local inv_list = {}
				for i = 1, sti_backpacks.slots do
					inv_list[i] = ItemStack(table_content[i] or "")
				end
				detached_inv:set_list("main", inv_list)
			else
				detached_inv:set_list("main", {})
			end

			local formspec = "size[8,9.5]" ..
				"label[0,0;STI Rucksack]" ..
				"list[detached:sti_backpacks_" .. name .. ";main;0,0.5;8,4;]" ..
				"label[0,4.75;Inventar]" ..
				"list[current_player;main;0,5.3;8,1;]" ..
				"list[current_player;main;0,6.5;8,3;8]" ..
				"listring[detached:sti_backpacks_" .. name .. ";main]" ..
				"listring[current_player;main]"

			minetest.show_formspec(name, "sti_backpacks:backpack_fs", formspec)
			return itemstack
		end
	end
	return nil
end

-- Schleife generiert automatisch alle Rucksack-Varianten
for _, color_data in ipairs(colors) do
	local color_name = color_data[1]
	local hex_code = color_data[2]

	-- Erster Buchstabe für die Beschreibung groß machen (z.B. red -> Red)
	local uppercase_name = color_name:gsub("^%l", string.upper)

	minetest.register_craftitem("sti_backpacks:backpack_" .. color_name, {
		description = "STI Rucksack (" .. uppercase_name .. ")",

		-- Hier ist die magische Textur-Kombination aus 2 Layern:
		-- Layer 1 (Wolle) wird mit der Hexfarbe multipliziert (gefärbt)
		-- Layer 2 (Kistendetails) wird unverändert drübergelegt (Transparenz beachten!)
		inventory_image = "sti_backpacks_base.png^[multiply:" .. hex_code .. "^sti_backpacks_overlay.png",

		stack_max = 1,

		on_secondary_use = function(itemstack, user, pointed_thing)
			local result = open_backpack(itemstack, user)
			return result or itemstack
		end,

		on_place = function(itemstack, user, pointed_thing)
			local result = open_backpack(itemstack, user)
			if result then
				return result
			end
			return itemstack
		end,
	})
end

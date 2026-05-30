-- sti_backpacks: init.lua
sti_backpacks = {} -- Globaler Namespace
sti_backpacks.slots = 32

-- Hilfsfunktion zum Speichern des Inventars im Item, das der Spieler hält
local function save_backpack_data(inv, player)
	local sheet = player:get_wielded_item()

	-- Sicherere Prüfung via Pattern Matching (findet alles, was so anfängt)
	if sheet:get_name():find("^sti_backpacks:backpack_") then
		local meta = sheet:get_meta()
		local inv_list = inv:get_list("main")
		local serialized = {}
		for i, stack in ipairs(inv_list) do
			serialized[i] = stack:to_string()
		end
		meta:set_string("contents", minetest.serialize(serialized))
		player:set_wielded_item(sheet)
	end
end

-- Registrierung des detached Inventars
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()

	local inv = minetest.create_detached_inventory("sti_backpacks_" .. name, {
		-- Verhindert das Verschieben von Rucksäcken INNERHALB des Rucksack-Inventars
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			local stack = inv:get_stack(from_list, from_index)
			if stack:get_name():find("^sti_backpacks:backpack_") then
				return 0
			end
			return count
		end,

		-- Verhindert das Reinschmeißen von Rucksäcken aus dem Spieler-Inventar
		allow_put = function(inv, listname, index, stack, player)
			if stack:get_name():find("^sti_backpacks:backpack_") then
				return 0 -- Blockiert das Ablegen im Rucksack
			end
			return stack:get_count()
		end,

		allow_take = function(inv, listname, index, stack, player)
			return stack:get_count()
		end,

		-- Bei jeder erlaubten Aktion sofort im Itemstack des Spielers speichern
		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			save_backpack_data(inv, player)
		end,
		on_put = function(inv, listname, index, stack, player)
			save_backpack_data(inv, player)
		end,
		on_take = function(inv, listname, index, stack, player)
			save_backpack_data(inv, player)
		end,
	})

	inv:set_size("main", sti_backpacks.slots)
end)

-- Weitere Dateien laden
local modpath = minetest.get_modpath("sti_backpacks")
dofile(modpath .. "/backpack.lua")
dofile(modpath .. "/recepies.lua")

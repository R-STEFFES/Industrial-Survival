-- sti_carts/init.lua

local S = minetest.get_translator("sti_carts")
local default_speed_max = carts.speed_max or 7

-- Wir holen uns das Basis-Cart aus dem Register
local base_cart = minetest.registered_entities["carts:cart"]

if base_cart then
	-- 1. PERSISTENZ-PATCH (Sichert die IDs und Kopplungen beim Neustart)
	local original_get_staticdata = base_cart.get_staticdata
	function base_cart:get_staticdata()
		local original_str = original_get_staticdata(self)
		local data = minetest.deserialize(original_str) or {}
		data.sti_cart_id = self.cart_id
		data.sti_leader_id = self.leader_id
		return minetest.serialize(data)
	end

	local original_on_activate = base_cart.on_activate
	function base_cart:on_activate(staticdata, dtime_s)
		original_on_activate(self, staticdata, dtime_s)
		if staticdata and staticdata ~= "" then
			local data = minetest.deserialize(staticdata)
			if data and type(data) == "table" then
				self.cart_id = data.sti_cart_id
				self.leader_id = data.sti_leader_id
			end
		end
		if not self.cart_id then
			self.cart_id = tostring(math.random(100000, 999999))
		end
	end

	-- 2. PHYSIK- UND BEWEGUNGS-PATCH
	local original_on_step = base_cart.on_step
	function base_cart:on_step(dtime)
		if not self.cart_id then
			self.cart_id = tostring(math.random(100000, 999999))
		end

		local leader_obj = nil
		-- FIX: Erhöhter Radius (15 Blöcke) fängt den Highspeed-Frame-Lag langer Züge ab
		if self.leader_id then
			for _, obj in pairs(minetest.get_objects_inside_radius(self.object:get_pos(), 15)) do
				local ent = obj:get_luaentity()
				if ent and ent.cart_id == self.leader_id then
					leader_obj = obj
					break
				end
			end

			if leader_obj then
				self.leader_lost_frames = 0 -- Lag-Zähler zurücksetzen
				self._saved_driver = self.driver
				self.driver = nil
			else
				-- FIX: Toleranz gegen Server-Lag. Erst nach 10 verpassten Frames entkoppeln!
				self.leader_lost_frames = (self.leader_lost_frames or 0) + 1
				if self.leader_lost_frames > 10 then
					self.leader_id = nil
					self.leader_lost_frames = 0
				end
			end
		end

		-- DYNAMISCHES TEMPOLIMIT
		local pos = self.object:get_pos()
		if pos then
			local node = minetest.get_node(vector.round(pos))
			local params = carts.railparams[node.name]
			if params and params.speed_max then
				carts.speed_max = params.speed_max
			else
				carts.speed_max = default_speed_max
			end
		end

		-- Zuerst die originale Physik rechnen lassen, damit das Cart sauber einlenkt
		original_on_step(self, dtime)

		-- NACHBESSERUNG FÜR DIE KOPPLUNG (Verhindert das Kurven-Glitschen)
		if leader_obj and leader_obj:get_pos() then
			if self._saved_driver then
				self.driver = self._saved_driver
				self._saved_driver = nil
			end

			local leader_pos = leader_obj:get_pos()
			local current_pos = self.object:get_pos()

			if current_pos and leader_pos then
				local dist = vector.distance(current_pos, leader_pos)
				local leader_vel = leader_obj:get_velocity()
				local leader_speed = vector.length(leader_vel)

				-- ANTI-GLITSCH CRITICAL FIX:
				-- Wir holen uns die exakte Fahrtrichtung, die das Cart auf den Schienen hat.
				local my_vel = self.object:get_velocity()
				local my_dir = carts:velocity_to_dir(my_vel)

				-- Wenn das Cart steht, schauen wir in welche Richtung die Schienen zum Anführer zeigen
				if vector.equals(my_dir, {x=0, y=0, z=0}) then
					my_dir = carts:velocity_to_dir(vector.direction(current_pos, leader_pos))
				end

				-- Abstand einhalten (Perfekt sind 1.4 Blöcke)
				local target_gap = 1.4
				local speed_correction = (dist - target_gap) * 8.0 -- Reaktionsstärke
				local target_speed = leader_speed + speed_correction

				-- Werte absichern
				if target_speed < 0 then target_speed = 0 end
				local max_s = carts.speed_max or 7
				if target_speed > max_s then target_speed = max_s end

				-- FIX: Geschwindigkeit NUR entlang der eigenen Schienenachse erzwingen!
				self.object:set_velocity(vector.multiply(my_dir, target_speed))

				-- ANTI-DESYNC TELEPORT:
				-- Falls bei extremem Speed (25m/s+) ein Cart doch mal springt,
				-- ziehen wir es sanft auf die Schiene zurück, bevor es entgleist.
				if dist > 2.8 then
					local rounded_pos = vector.round(current_pos)
					if carts:is_rail(rounded_pos) then
						local snap_pos = vector.add(current_pos, vector.multiply(my_dir, (dist - target_gap) * 0.5))
						self.object:set_pos(snap_pos)
					end
				end
			end
		end
	end
end

-- ===================================================================
-- 3. DIE KOPPELKETTE (Das Werkzeug zum Verbinden)
-- ===================================================================
minetest.register_craftitem("sti_carts:coupling_chain", {
	description = "Koppelkette\n(Nutze sie nacheinander auf zwei Carts zum Verbinden)",
	inventory_image = "sti_carts_coupling_chain.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		if not user or pointed_thing.type ~= "object" then return end

		local obj = pointed_thing.ref
		local ent = obj:get_luaentity()

		if not ent or not ent.name:find("cart") then return end

		local player_name = user:get_player_name()
		local meta = user:get_meta()
		local first_cart_id = meta:get_string("sti_carts_selected_id")

		if first_cart_id == "" then
			if not ent.cart_id then ent.cart_id = tostring(math.random(100000, 999999)) end

			meta:set_string("sti_carts_selected_id", ent.cart_id)
			minetest.chat_send_player(player_name, "=> Erstes Cart ausgewählt! Klicke jetzt auf das Cart dahinter.")
		else
			if not ent.cart_id then ent.cart_id = tostring(math.random(100000, 999999)) end

			if first_cart_id == ent.cart_id then
				ent.leader_id = nil
				meta:set_string("sti_carts_selected_id", "")
				minetest.chat_send_player(player_name, "=> Kopplung gelöst / Auswahl aufgehoben.")
			else
				ent.leader_id = first_cart_id
				meta:set_string("sti_carts_selected_id", "")
				minetest.chat_send_player(player_name, "=> Carts erfolgreich zusammengekoppelt!")
			end
		end
		return itemstack
	end,
})

minetest.register_craft({
	output = "sti_carts:coupling_chain",
	recipe = {
		{"default:steel_ingot", "", ""},
		{"", "default:steel_ingot", ""},
		{"", "", "default:steel_ingot"},
	}
})

-- ===================================================================
-- 4. HYPERSPEED-SCHIENE & CUSTOM CARTS LADEN
-- ===================================================================
carts:register_rail("sti_carts:hyperspeed_rail", {
	description = S("Hyperspeed-Schiene (Kein Boost)"),
	tiles = {
		"sti_carts_rail_hyper.png", "sti_carts_rail_hyper_curved.png",
		"sti_carts_rail_hyper_t.png", "sti_carts_rail_hyper_crossing.png"
	},
	groups = carts:get_rail_groups(),
}, {
	acceleration = 0,
	speed_max = 25
})

local modpath = minetest.get_modpath("sti_carts")
dofile(modpath .. "/custom_carts.lua")

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

	-- 2. PHYSIK- UND KETTEN-RENDER-PATCH
	local original_on_step = base_cart.on_step
	function base_cart:on_step(dtime)
		if not self.cart_id then
			self.cart_id = tostring(math.random(100000, 999999))
		end

		local leader_obj = nil
		if self.leader_id then
			for _, obj in pairs(minetest.get_objects_inside_radius(self.object:get_pos(), 15)) do
				local ent = obj:get_luaentity()
				if ent and ent.cart_id == self.leader_id then
					leader_obj = obj
					break
				end
			end

			if leader_obj then
				self.leader_lost_frames = 0
				self._saved_driver = self.driver
				self.driver = nil
			else
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

		-- Originale Bewegung ausführen
		original_on_step(self, dtime)

		-- RECHTLICHE STANGE & GRAFISCHE KETTE
		if leader_obj and leader_obj:get_pos() then
			if self._saved_driver then
				self.driver = self._saved_driver
				self._saved_driver = nil
			end

			local leader_pos = leader_obj:get_pos()
			local current_pos = self.object:get_pos()

			if current_pos and leader_pos then
				local leader_vel = leader_obj:get_velocity()

				-- Ermitteln, in welche Richtung der Zug fährt
				local leader_dir = carts:velocity_to_dir(leader_vel)
				if vector.equals(leader_dir, {x=0, y=0, z=0}) then
					leader_dir = carts:velocity_to_dir(vector.direction(current_pos, leader_pos))
				end
				if vector.equals(leader_dir, {x=0, y=0, z=0}) then
					leader_dir = {x=1, y=0, z=0} -- Absicherung/Fallback
				end

				-- DIE "STANGE": Errechnet die exakte starre Position hinter dem Vordermann
				local bar_length = 1.45 -- Abstand zwischen den Mittelpunkten der Carts
				local target_pos = vector.subtract(leader_pos, vector.multiply(leader_dir, bar_length))

				-- Position und Geschwindigkeit knallhart erzwingen (Kein Glitschen mehr möglich!)
				self.object:set_pos(target_pos)
				self.object:set_velocity(leader_vel)

				-- DIE VISUELLE KETTE:
				-- Startpunkt am Heck des vorderen Carts berechnen
				local chain_start = vector.subtract(leader_pos, vector.multiply(leader_dir, 0.55))
				-- Endpunkt an der Schnauze des hinteren Carts berechnen
				local chain_end = vector.add(target_pos, vector.multiply(leader_dir, 0.55))

				-- Wir spannen 5 Kettenglieder-Partikel zwischen den Punkten auf
				local links = 5
				for i = 0, links do
					local t = i / links
					-- Lineare Interpolation (Punkt auf der Linie zwischen Start und Ende)
					local p_pos = vector.add(chain_start, vector.multiply(vector.subtract(chain_end, chain_start), t))

					minetest.add_particle({
						pos = p_pos,
						velocity = leader_vel, -- Die Kette bewegt sich exakt mit dem Zug mit
						acceleration = {x=0, y=0, z=0},
						expirationtime = 0.05, -- Hält nur bis zum nächsten Frame, wird permanent erneuert
						size = 2.5,
						collisiondetection = false,
						vertical = false,
						-- Wir nutzen eine Textur aus dem Spiel. Du kannst auch ein eigenes "sti_carts_chain.png" erstellen!
						texture = "default_steel_ingot.png^[resize:16x16",
					})
				end
			end
		end
	end
end

-- ===================================================================
-- 3. DIE KOPPELKETTE (Das Werkzeug zum Verbinden)
-- ===================================================================
minetest.register_craftitem("sti_carts:coupling_chain", {
	description = "Koppelkette\n(Klicke nacheinander auf zwei Carts)",
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

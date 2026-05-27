-- sti_carts/init.lua

local S = minetest.get_translator("sti_carts")
local default_speed_max = carts.speed_max or 7

local base_cart = minetest.registered_entities["carts:cart"]

if base_cart then
	-- 1. PERSISTENZ (IDs speichern)
	local original_get_staticdata = base_cart.get_staticdata
	function base_cart:get_staticdata()
		local data = minetest.deserialize(original_get_staticdata(self)) or {}
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
		self.cart_id = self.cart_id or tostring(math.random(100000, 999999))
	end

	-- 2. GUMMIBAND-PHYSIK (Verhindert das Ineinanderglitschen)
	local original_on_step = base_cart.on_step
	function base_cart:on_step(dtime)
		self.cart_id = self.cart_id or tostring(math.random(100000, 999999))

		-- Vordermann suchen
		local leader_obj = nil
		if self.leader_id then
			for _, obj in ipairs(minetest.get_objects_inside_radius(self.object:get_pos(), 15)) do
				local ent = obj:get_luaentity()
				if ent and ent.cart_id == self.leader_id then
					leader_obj = obj
					break
				end
			end
			-- Timeout, falls Vordermann gelöscht wurde
			if not leader_obj then
				self.lost_ticks = (self.lost_ticks or 0) + 1
				if self.lost_ticks > 10 then self.leader_id = nil end
			else
				self.lost_ticks = 0
			end
		end

		-- Eigene Schienen-Physik ausführen (Hält das Cart in der Spur!)
		original_on_step(self, dtime)

		-- GESCHWINDIGKEITS-KONTROLLE (Nur für angehängte Waggons)
		if leader_obj then
			local pos = self.object:get_pos()
			local leader_pos = leader_obj:get_pos()
			local dist = vector.distance(pos, leader_pos)

			-- ANTI-GLITSCH-NOTBREMSE: Wenn sie fast kollidieren, sofort stehenbleiben
			if dist < 0.7 then
				self.object:set_velocity({x=0, y=0, z=0})
				return
			end

			local leader_vel = leader_obj:get_velocity()
			local leader_speed = vector.length(leader_vel)

			local my_vel = self.object:get_velocity()
			local my_dir = carts:velocity_to_dir(my_vel)

			-- Wenn wir stehen, Blickrichtung zum Vordermann auf Schienenachse einrasten
			if vector.equals(my_dir, {x=0, y=0, z=0}) then
				local dir_to_leader = vector.direction(pos, leader_pos)
				if math.abs(dir_to_leader.x) > math.abs(dir_to_leader.z) then
					my_dir = {x = (dir_to_leader.x > 0 and 1 or -1), y = 0, z = 0}
				else
					my_dir = {x = 0, y = 0, z = (dir_to_leader.z > 0 and 1 or -1)}
				end
			end

			-- P-CONTROLLER: Berechnet die nötige Geschwindigkeit anhand des Abstands
			local target_dist = 1.5 -- Perfekter Abstand zwischen den Loren
			local error_dist = dist - target_dist

			-- Multiplikator bestimmt, wie aggressiv der Waggon Gas gibt, um aufzuholen
			local correction = error_dist * 4.0
			local target_speed = leader_speed + correction

			-- Rückwärtsfahren durch Überschwingen verbieten
			if target_speed < 0 then target_speed = 0 end

			-- Speedlimit beachten
			local max_s = carts.speed_max or 7
			if target_speed > max_s then target_speed = max_s end

			-- Neue Geschwindigkeit strikt auf der eigenen Schienenachse anwenden
			self.object:set_velocity(vector.multiply(my_dir, target_speed))
		end
	end
end

-- ===================================================================
-- 3. DAS IDIOTENSICHERE KOPPEL-TOOL
-- ===================================================================

-- Temporärer Speicher für Klick-Reihenfolgen
local coupling_memory = {}

minetest.register_craftitem("sti_carts:coupling_chain", {
	description = "Koppelkette\nKlicke erst die Lok, dann Waggon 1, dann Waggon 2...",
	inventory_image = "sti_carts_coupling_chain.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		if not user or pointed_thing.type ~= "object" then return end

		local obj = pointed_thing.ref
		local ent = obj:get_luaentity()
		if not ent or not ent.name:find("cart") then return end

		local pname = user:get_player_name()
		ent.cart_id = ent.cart_id or tostring(math.random(100000, 999999))

		local prev_obj = coupling_memory[pname]

		if prev_obj and prev_obj:get_pos() then
			local prev_ent = prev_obj:get_luaentity()

			if prev_obj == obj then
				-- Klick auf das SELBE Cart bricht die Kettenbildung ab
				coupling_memory[pname] = nil
				ent.leader_id = nil
				minetest.chat_send_player(pname, "[Kopplung] Gelöst! Dieses Cart ist jetzt wieder frei.")
				return
			end

			-- Das angeklickte Cart an das vorherige anhängen
			ent.leader_id = prev_ent.cart_id

			-- WICHTIG: Das aktuelle Cart wird nun als neues "Vorheriges" gespeichert.
			-- So kannst du direkt das nächste Cart anklicken, um einen langen Zug zu bauen!
			coupling_memory[pname] = obj

			minetest.chat_send_player(pname, "[Kopplung] Verbunden! Klicke jetzt auf den NÄCHSTEN Waggon dahinter (oder klicke diesen Waggon nochmal, um aufzuhören).")
		else
			-- Start der Kettenbildung
			coupling_memory[pname] = obj
			minetest.chat_send_player(pname, "[Kopplung] Lokomotive markiert! Klicke jetzt auf den Waggon direkt dahinter.")
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
-- 4. HYPERSPEED-SCHIENE & CUSTOM CARTS
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

-- sti_carts/custom_carts.lua
local S = carts.get_translator

-- Basis-Cart als Klon-Vorlage holen
local base_cart = minetest.registered_entities["carts:cart"]
if not base_cart then return end

local motor_cart = table.copy(base_cart)
motor_cart.initial_properties.textures = {"sti_carts_motor_cart.png"}

-- ===================================================================
-- 1. SPEICHER-LOGIK (Damit der Sprit beim Server-Neustart nicht verschwindet)
-- ===================================================================
function motor_cart:get_staticdata()
	-- Wir packen die originalen Cart-Daten und unsere Sprit-Daten in eine Tabelle
	local data = {
		velocity = self.velocity,
		old_dir = self.old_dir,
		old_pos = self.old_pos,
		old_switch = self.old_switch,
		railtype = self.railtype,
		fuel_time = self.fuel_time or 0,
		fuel_max_time = self.fuel_max_time or 1,
		fuel_item = self.fuel_item or ""
	}
	return minetest.serialize(data)
end

function motor_cart:on_activate(staticdata, dtime_s)
	-- Erst die originale Aktivierung durchlaufen lassen
	base_cart.on_activate(self, staticdata, dtime_s)

	-- Eigene Werte mit Standardwerten initialisieren
	self.fuel_time = 0
	self.fuel_max_time = 1
	self.fuel_item = ""

	if staticdata and staticdata ~= "" then
		local data = minetest.deserialize(staticdata)
		if data and type(data) == "table" then
			self.fuel_time = data.fuel_time or 0
			self.fuel_max_time = data.fuel_max_time or 1
			self.fuel_item = data.fuel_item or ""
		end
	end
end
-- ===================================================================
-- 2. GUI / RECHTSKLICK-LOGIK (Korrigerte & Sichere Version)
-- ===================================================================
function motor_cart:on_rightclick(clicker)
	if not clicker or not clicker:is_player() then return end
	local player_name = clicker:get_player_name()

	-- Wenn der Spieler SNEAKT -> GUI für Kohle öffnen
	if clicker:get_player_control().sneak then
		local inv_name = "sti_carts_motor_" .. player_name

		-- Ein temporäres, spielerspezifisches Inventar für das GUI erstellen
		local inv = minetest.create_detached_inventory(inv_name, {
			allow_put = function(inv, listname, index, stack)
				-- Nur Items erlauben, die man auch verbrennen kann
				local fuel_res = minetest.get_craft_result({method="fuel", width=1, items={stack}})
				if fuel_res.time > 0 then
					return stack:get_count()
				end
				return 0
			end,
			on_put = function(inv, listname, index, stack)
				self.fuel_item = inv:get_stack(listname, index):to_string()
			end,
			on_take = function(inv, listname, index, stack)
				self.fuel_item = inv:get_stack(listname, index):to_string()
			end,
			allow_move = function() return 0 end
		})

		inv:set_size("fuel", 1)
		if self.fuel_item and self.fuel_item ~= "" then
			inv:set_stack("fuel", 1, ItemStack(self.fuel_item))
		end

		-- ABSICHERUNG: Falls Werte nil sind, Standardwerte setzen (beugt Abstürzen vor)
		local fuel_time = self.fuel_time or 0
		local fuel_max_time = self.fuel_max_time or 1
		if fuel_max_time <= 0 then fuel_max_time = 1 end

		-- Prozent berechnen und zwischen 0 und 100 festnageln
		local percent = math.floor((fuel_time / fuel_max_time) * 100)
		percent = math.max(0, math.min(100, percent))

		-- Das Formspec (Text-Anzeige statt fehlerhafter Bild-Logik)
		local formspec = "size[8,6.5]" ..
			"label[1.8,0.3;Motor-Cart Treibstoff (Kohle, Holz etc.)]" ..
			"list[detached:" .. inv_name .. ";fuel;3.5,0.8;1,1]" ..
			"label[3.3,2.0;Energie: " .. percent .. "%]" .. -- Text-Anzeige: Sicher und bildunabhängig!
			"list[current_player;main;0,2.5;8,4]" ..
			"listring[detached:" .. inv_name .. ";fuel]" ..
			"listring[current_player;main]"

		minetest.show_formspec(player_name, "sti_carts:motor_fuel", formspec)
	else
		-- Normaler Klick -> Einsteigen / Aussteigen
		base_cart.on_rightclick(self, clicker)
	end
end
-- ===================================================================
-- 3. INTERNEN MOTOR & W/S STEUERUNG BERECHNEN
-- ===================================================================
function motor_cart:on_step(dtime)
	local driver_name = self.driver

	if driver_name then
		local player = minetest.get_player_by_name(driver_name)
		if player then
			local ctrl = player:get_player_control()

			-- BRENNSTOFF-VERBRAUCH
			if self.fuel_time and self.fuel_time > 0 then
				-- Wenn aktiv Gas gegeben wird (W), verbraucht es voll Sprit, im Leerlauf nur 20%
				local usage = ctrl.up and dtime or (dtime * 0.2)
				self.fuel_time = self.fuel_time - usage
			else
				-- Ofen ist leer -> Versuchen das nächste Item aus dem Slot zu verbrennen
				if self.fuel_item and self.fuel_item ~= "" then
					local stack = ItemStack(self.fuel_item)
					local fuel_res = minetest.get_craft_result({method="fuel", width=1, items={stack}})

					if fuel_res.time > 0 then
						self.fuel_time = fuel_res.time
						self.fuel_max_time = fuel_res.time
						stack:take_item(1)
						self.fuel_item = stack:to_string()

						-- Detached Inventory updaten, falls der Spieler das GUI offen hat
						local inv = minetest.get_inventory({type="detached", name="sti_carts_motor_" .. driver_name})
						if inv then
							inv:set_stack("fuel", 1, stack)
						end
					end
				end
			end
		end
	end

	-- Erst die originale Physik rechnen lassen (damit Schienenkurven und Weichen greifen)
	base_cart.on_step(self, dtime)

	-- JETZT DIE MANUELLE STEUERUNG ÜBERNEHMEN (Nachdem die Basisphysik gerechnet hat)
	if driver_name then
		local player = minetest.get_player_by_name(driver_name)
		if player then
			local ctrl = player:get_player_control()
			local vel = self.object:get_velocity()

			-- W-TASTE: Gas geben (Nur wenn Sprit vorhanden ist!)
			if ctrl.up and self.fuel_time and self.fuel_time > 0 then
				local dir = carts:velocity_to_dir(vel)

				-- Wenn das Cart komplett steht, nutzen wir die Blickrichtung des Spielers
				if vector.equals(dir, {x=0, y=0, z=0}) then
					local yaw = player:get_look_horizontal()
					local x = -math.sin(yaw)
					local z = math.cos(yaw)
					if math.abs(x) > math.abs(z) then
						dir = {x = (x > 0 and 1 or -1), y = 0, z = 0}
					else
						dir = {x = 0, y = 0, z = (z > 0 and 1 or -1)}
					end
				end

				local speed = vector.length(vel)
				local max_s = carts.speed_max or 7 -- Nutzt automatisch das Limit der Hyperspeed-Schiene!

				if speed < max_s then
					local speed_gain = 6.0 * dtime -- Beschleunigungs-Power des Motors
					local new_vel = vector.add(vel, vector.multiply(dir, speed_gain))

					if vector.length(new_vel) > max_s then
						new_vel = vector.multiply(vector.normalize(new_vel), max_s)
					end
					self.object:set_velocity(new_vel)
				end

			-- S-TASTE: Bremsen
			elseif ctrl.down then
				if vector.length(vel) > 0.1 then
					-- Reduziert die Geschwindigkeit pro Frame drastisch (Gegenlenken/Bremsen)
					local brake_factor = math.max(0, 1 - (10.0 * dtime))
					self.object:set_velocity(vector.multiply(vel, brake_factor))
				else
					self.object:set_velocity({x=0, y=0, z=0})
				end
			end
		end
	end
end

-- Registrierung der Entität unter unserem Mod-Namen
minetest.register_entity("sti_carts:motor_cart", motor_cart)

-- Das tragbare Item zum Platzieren
minetest.register_craftitem("sti_carts:motor_cart", {
	description = "Motor-Cart (STI-Edition)",
	inventory_image = "sti_carts_motor_cart_item.png",
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then return end
		if carts:is_rail(pointed_thing.under) then
			minetest.add_entity(pointed_thing.under, "sti_carts:motor_cart")
			itemstack:take_item()
		elseif carts:is_rail(pointed_thing.above) then
			minetest.add_entity(pointed_thing.above, "sti_carts:motor_cart")
			itemstack:take_item()
		end
		return itemstack
	end,
})

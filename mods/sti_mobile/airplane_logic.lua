-- ==========================================================================
-- sti_mobile - Flugzeug Logik & Physik (airplane_logic.lua)
-- ==========================================================================

-- Lokale Hilfsfunktion für die Formspec (Treibstoff & 16 Frachtslots)
local function get_airplane_formspec(id, fuel, fuel_max)
    local inv_name = "sti_mobile:airplane_" .. id
    local formspec = "size[9,11.5]" ..
        "label[0.5,0.5;--- FLUGZEUG COCKPIT ---]" ..
        "label[0.5,1.2;Treibstoff: " .. math.floor(fuel) .. " / " .. fuel_max .. " L]" ..
        "box[0.5,1.6;8,0.3;#333333]" ..
        "box[0.5,1.6;" .. ((fuel / fuel_max) * 8) .. ",0.3;#ffcc00]" ..

        "label[0.5,2.2;Brennstoff (z.B. Kohle):]" ..
        "list[detached:" .. inv_name .. ";fuel_slot;0.5,2.7;1,1;]" ..

        "label[2.5,2.2;Frachtraum (16 Slots):]" ..
        "list[detached:" .. inv_name .. ";cargo;2.5,2.7;4,4;]" ..

        "list[current_player;main;0.5,7.2;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[detached:" .. inv_name .. ";cargo]"
    return formspec
end

minetest.register_entity("sti_mobile:airplane", {
    physical = true,
    collisionbox = {-1.5, -0.5, -1.5, 1.5, 1.5, 1.5},
    visual = "mesh",
    mesh = "Platzhalter_flieger.obj",
    textures = {"sti_mobile_flieger.png"},
    stepheight = 0.6,

    -- Interne Zustände & Physik
    driver = nil,
    fuel = 0,
    max_fuel = 100,
    propeller_aktiv = false,
    current_speed = 0,
    pitch = 0,
    roll = 0,
    is_stalled = false,
    id = nil,
    aux1_pressed = false,

    -- Initialisierung beim Spawnen / Laden
    on_activate = function(self, staticdata, dtime_s)
        self.object:set_armor_groups({fleshy = 100})

        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then
                self.fuel = data.fuel or 0
                self.id = data.id
                self.cargo_items = data.cargo_items or {}
                self.fuel_items = data.fuel_items or {}
            end
        end

        if not self.id then
            self.id = tostring(math.random(100000, 999999))
        end

        local inv_name = "sti_mobile:airplane_" .. self.id
        local inv = minetest.get_inventory({type = "detached", name = inv_name})

        if not inv then
            inv = minetest.create_detached_inventory(inv_name, {
                allow_put = function(inv, listname, index, stack, player) return stack:get_count() end,
                allow_take = function(inv, listname, index, stack, player) return stack:get_count() end,
                allow_move = function(inv, from_list, from_index, to_list, to_index, count, player) return count end,
            })
        end
        inv:set_size("fuel_slot", 1)
        inv:set_size("cargo", 16)

        if self.cargo_items then
            for i, itemstring in ipairs(self.cargo_items) do
                inv:set_stack("cargo", i, ItemStack(itemstring))
            end
        end
        if self.fuel_items then
            for i, itemstring in ipairs(self.fuel_items) do
                inv:set_stack("fuel_slot", i, ItemStack(itemstring))
            end
        end
    end,

    -- Daten permanent speichern beim Entladen des Chunks / Server-Stopp
    get_staticdata = function(self)
        local cargo_items = {}
        local fuel_items = {}
        local inv = minetest.get_inventory({type = "detached", name = "sti_mobile:airplane_" .. (self.id or "")})

        if inv then
            for i = 1, inv:get_size("cargo") do
                cargo_items[i] = inv:get_stack("cargo", i):to_string()
            end
            for i = 1, inv:get_size("fuel_slot") do
                fuel_items[i] = inv:get_stack("fuel_slot", i):to_string()
            end
        end

        return minetest.serialize({
            fuel = self.fuel,
            id = self.id,
            cargo_items = cargo_items,
            fuel_items = fuel_items,
        })
    end,

    -- Interaktion (Rechtsklick = Ein- und Aussteigen)
    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local name = clicker:get_player_name()

        if self.driver and name == self.driver then
            self.driver = nil
            clicker:set_detach()
            if player_api and player_api.set_animation then
                player_api.set_animation(clicker, "stand")
            end
        elseif not self.driver then
            self.driver = name
            clicker:set_attach(self.object, "", {x = 0, y = 5, z = -3}, {x = 0, y = 0, z = 0})
            if player_api and player_api.set_animation then
                player_api.set_animation(clicker, "sit")
            end
        end
    end,

    -- Kern-Logik (Flugphysik & Tastenabfrage)
    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        local vel = self.object:get_velocity()

        if not self.driver then
            if math.abs(vel.x) > 0.1 or math.abs(vel.z) > 0.1 then
                self.object:set_velocity({x = vel.x * 0.9, y = vel.y, z = vel.z * 0.9})
            end
            return
        end

        local player = minetest.get_player_by_name(self.driver)
        if not player then return end

        local ctrl = player:get_player_control()
        local rotation = self.object:get_rotation()

        -- GUI öffnen mit der Taste 'E' (aux1)
        if ctrl.aux1 then
            if not self.aux1_pressed then
                self.aux1_pressed = true
                minetest.show_formspec(self.driver, "sti_mobile:airplane_inv", get_airplane_formspec(self.id, self.fuel, self.max_fuel))
            end
        else
            self.aux1_pressed = false
        end

        -- Automatische Betankung aus dem Slot
        if self.fuel < self.max_fuel then
            local inv = minetest.get_inventory({type = "detached", name = "sti_mobile:airplane_" .. self.id})
            if inv then
                local fuel_stack = inv:get_stack("fuel_slot", 1)
                if not fuel_stack:is_empty() then
                    local fuel_time, _ = minetest.get_craft_result({method = "fuel", width = 1, items = {fuel_stack}})
                    if fuel_time and fuel_time.time > 0 then
                        fuel_stack:take_item()
                        inv:set_stack("fuel_slot", 1, fuel_stack)
                        self.fuel = math.min(self.fuel + fuel_time.time, self.max_fuel)
                    end
                end
            end
        end

        -- 1. Triebwerk & Beschleunigung (W / S)
        if ctrl.up and self.fuel > 0 then
            self.current_speed = math.min(self.current_speed + (4.0 * dtime), 22)
            self.fuel = self.fuel - (0.5 * dtime)
            if not self.propeller_aktiv then self:starte_propeller() end
        elseif ctrl.down then
            self.current_speed = math.max(self.current_speed - (6.0 * dtime), 0)
        else
            self.current_speed = math.max(self.current_speed - (1.5 * dtime), 0)
        end

        -- ==================================================================
        -- KORREKTUR: minetest.clamp durch sauberes math.min/math.max ersetzt
        -- ==================================================================
        if ctrl.left then
            rotation.y = rotation.y + (1.2 * dtime)
            self.roll = math.max(self.roll - 0.1, -0.5)
        elseif ctrl.right then
            rotation.y = rotation.y - (1.2 * dtime)
            self.roll = math.min(self.roll + 0.1, 0.5) -- Hier gefixt!
        else
            self.roll = self.roll * 0.9
        end

        -- 3. Höhensteuerung (Jump / Sneak -> Pitch)
        if ctrl.jump and self.current_speed > 12 then
            rotation.x = rotation.x + (0.8 * dtime)
        elseif ctrl.sneak then
            rotation.x = rotation.x - (1.0 * dtime)
        end

        -- 4. Auftrieb & Stall-Logik
        local lift = (self.current_speed / 12) * 9.81
        if self.current_speed < 10 then
            lift = lift * 0.2
            self.is_stalled = true
        else
            self.is_stalled = false
        end

        -- Vektor-Berechnung
        local yaw = rotation.y
        local pitch = rotation.x
        local new_vel = {
            x = math.sin(yaw) * math.cos(pitch) * self.current_speed * -1,
            y = (math.sin(pitch) * self.current_speed) + (lift - 9.81),
            z = math.cos(yaw) * math.cos(pitch) * self.current_speed
        }

        self.object:set_rotation({x = pitch, y = yaw, z = self.roll})
        self.object:set_velocity(new_vel)

        if self.fuel <= 0 and self.propeller_aktiv then
            self:stoppe_propeller()
        end
    end,

    starte_propeller = function(self)
        self.object:set_animation({x = 1, y = 20}, 40, 0, true)
        self.propeller_aktiv = true
    end,

    stoppe_propeller = function(self)
        self.object:set_animation({x = 0, y = 0}, 0, 0, false)
        self.propeller_aktiv = false
    end,
})

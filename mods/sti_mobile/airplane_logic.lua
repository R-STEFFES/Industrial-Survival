-- ==========================================================================
-- sti_mobile - Flugzeug Logik & Physik (airplane_logic.lua)
-- ==========================================================================

-- Lokale Hilfsfunktionen für die Formspec (Treibstoff & Fracht)
local function get_airplane_formspec(fuel, fuel_max, inventory_list)
    local fuel_percent = (fuel / fuel_max) * 100
    local formspec = "size[8,9]" ..
        "label[0.5,0.5;--- FLUGZEUG COCKPIT ---]" ..
        "label[0.5,1.2;Treibstoff: " .. math.floor(fuel) .. " / " .. fuel_max .. " L]" ..
        "box[0.5,1.6;7,0.3;#333333]" ..
        "box[0.5,1.6;" .. (fuel / fuel_max * 7) .. ",0.3;#ffcc00]" ..

        "label[0.5,2.2;Treibstoff-Slot:]" ..
        "list[context;fuel_slot;0.5,2.6;1,1;]" ..

        "label[3.0,2.2;Frachtraum:]" ..
        "list[context;cargo;3.0,2.6;4,2;]" ..

        "list[current_player;main;0,5;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;cargo]"
    return formspec
end

minetest.register_entity("sti_mobile:airplane", {
    physical = true,
    collisionbox = {-1.5, -0.5, -1.5, 1.5, 1.5, 1.5},
    visual = "mesh",
    mesh = "Platzhalter_flieger.obj", -- Falls du b3d nutzt, sonst .obj
    textures = {"sti_mobile_flieger.png"},
    stepheight = 0.6,

    -- Interne Zustände & Physik
    driver = nil,
    fuel = 0,
    max_fuel = 100,
    propeller_aktiv = false,
    current_speed = 0,
    pitch = 0, -- Neigung (hoch/runter)
    roll = 0,  -- Rollen (links/rechts)
    is_stalled = false,

    -- Initialisierung beim Spawnen
    on_activate = function(self, staticdata, dtime_s)
        self.object:set_armor_groups({fleshy = 100})
        local inv = minetest.get_meta(self.object:get_pos()):get_inventory()
        inv:set_size("fuel_slot", 1)
        inv:set_size("cargo", 8)

        if staticdata then
            local data = minetest.deserialize(staticdata)
            if data then
                self.fuel = data.fuel or 0
                -- Weitere Daten hier laden
            end
        end
    end,

    -- Daten speichern beim Entladen
    get_staticdata = function(self)
        return minetest.serialize({
            fuel = self.fuel,
        })
    end,

    -- Interaktion (Einsteigen / Inventar)
    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local name = clicker:get_player_name()

        if self.driver and name == self.driver then
            -- Wenn man bereits fliegt: Inventar öffnen (Shift + Klick)
            if clicker:get_player_control().sneak then
                minetest.show_formspec(name, "sti_mobile:airplane_inv", get_airplane_formspec(self.fuel, self.max_fuel))
            else
                -- Aussteigen
                self.driver = nil
                clicker:set_detach()
                player_api.set_animation(clicker, "stand")
            end
        elseif not self.driver then
            -- Einsteigen
            self.driver = name
            clicker:set_attach(self.object, "", {x = 0, y = 5, z = -3}, {x = 0, y = 0, z = 0})
            player_api.set_animation(clicker, "sit")
        end
    end,

    -- Kern-Logik (Flugphysik)
    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        local vel = self.object:get_velocity()

        if not self.driver then
            -- Reibung am Boden, wenn kein Pilot da ist
            if math.abs(vel.x) > 0.1 or math.abs(vel.z) > 0.1 then
                self.object:set_velocity({x = vel.x * 0.9, y = vel.y, z = vel.z * 0.9})
            end
            return
        end

        local player = minetest.get_player_by_name(self.driver)
        if not player then return end

        local ctrl = player:get_player_control()
        local rotation = self.object:get_rotation()

        -- 1. Triebwerk & Beschleunigung (W / S)
        if ctrl.up and self.fuel > 0 then
            self.current_speed = math.min(self.current_speed + (4.0 * dtime), 22)
            self.fuel = self.fuel - (0.5 * dtime)
            if not self.propeller_aktiv then self:starte_propeller() end
        elseif ctrl.down then
            self.current_speed = math.max(self.current_speed - (6.0 * dtime), 0)
        else
            -- Natürlicher Luftwiderstand
            self.current_speed = math.max(self.current_speed - (1.5 * dtime), 0)
        end

        -- 2. Lenkung (A / D -> Rollen & Gieren)
        if ctrl.left then
            rotation.y = rotation.y + (1.2 * dtime)
            self.roll = math.min(self.roll + 0.1, 0.5)
        elseif ctrl.right then
            rotation.y = rotation.y - (1.2 * dtime)
            self.roll = math.max(self.roll - 0.1, -0.5)
        else
            self.roll = self.roll * 0.9 -- Stabilisierung
        end

        -- 3. Höhensteuerung (Jump / Sneak -> Pitch)
        if ctrl.jump and self.current_speed > 12 then
            rotation.x = rotation.x + (0.8 * dtime) -- Nase hoch
        elseif ctrl.sneak then
            rotation.x = rotation.x - (1.0 * dtime) -- Nase runter
        end

        -- 4. Auftrieb & Stall-Logik
        local lift = (self.current_speed / 12) * 9.81
        if self.current_speed < 10 then
            lift = lift * 0.2 -- Strömungsabriss
            self.is_stalled = true
        else
            self.is_stalled = false
        end

        -- Geschwindigkeit in Richtungs-Vektor umwandeln
        local yaw = rotation.y
        local pitch = rotation.x
        local new_vel = {
            x = math.sin(yaw) * math.cos(pitch) * self.current_speed * -1,
            y = (math.sin(pitch) * self.current_speed) + (lift - 9.81),
            z = math.cos(yaw) * math.cos(pitch) * self.current_speed
        }

        -- Finale Updates
        self.object:set_rotation({x = pitch, y = yaw, z = self.roll})
        self.object:set_velocity(new_vel)

        -- Treibstoff-Check
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

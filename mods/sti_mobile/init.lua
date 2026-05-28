-- ==========================================================================
-- Mod: sti_mobile - Erweitertes Realismus-Flugzeug (Luanti / Minetest)
-- ==========================================================================

sti_mobile = {
    open_planes = {} -- Speichert, welcher Spieler gerade welches Flugzeug-GUI offen hat
}

-- CONFIGURATION (Hier kannst du das Flugverhalten feintunen)
local MAX_SPEED = 22          -- Normale Höchstgeschwindigkeit (geradeaus)
local TERMINAL_SPEED = 35     -- Absolute Höchstgeschwindigkeit im Sturzflug
local TAKEOFF_SPEED = 12      -- Mindestgeschwindigkeit zum Abheben
local STALL_SPEED = 10        -- Geschwindigkeit, unter der ein Strömungsabriss droht
local ACCELERATION = 4.0      -- Triebwerksleistung
local DECELERATION = 1.5      -- Luftwiderstand beim Ausrollen
local TURN_SPEED = 1.2        -- Wendigkeit

minetest.register_entity("sti_mobile:airplane", {
    physical = true,
    collisionbox = {-1.5, -0.5, -1.5, 1.5, 1.5, 1.5},
    visual = "mesh",
    mesh = "Platzhalter_flieger.obj",
    textures = {"sti_mobile_flieger.png"},

    -- Interne Zustände
    driver = nil,
    fuel = 0,
    max_fuel = 100,
    propeller_aktiv = false,

    -- Physik-Variablen
    current_speed = 0,
    pitch = 0,
    roll = 0,
    is_stalled = false,
    aux1_was_pressed = false,
    particle_timer = 0,

    -- Inventar-Speicher
    stored_fuel_item = "",
    stored_cargo_items = {"", "", "", "", "", "", "", ""},

    -- Inventar abspeichern
    save_inventory = function(self, inv)
        self.stored_fuel_item = inv:get_stack("fuel", 1):to_string()
        self.stored_cargo_items = {}
        for i = 1, 8 do
            self.stored_cargo_items[i] = inv:get_stack("cargo", i):to_string()
        end
    end,

    -- Cockpit-GUI (Formspec)
    open_gui = function(self, player)
        local name = player:get_player_name()
        sti_mobile.open_planes[name] = self

        local inv = minetest.get_inventory({type = "detached", name = "sti_mobile_plane_" .. name})
        if not inv then
            inv = minetest.create_detached_inventory("sti_mobile_plane_" .. name, {
                allow_put = function(inv, listname, index, stack, player)
                    if listname == "fuel" then
                        if stack:get_name() == "default:coal_lump" then return stack:get_count() end
                        return 0
                    end
                    return stack:get_count()
                end,
                on_put = function(inv, listname, index, stack, player)
                    local ent = sti_mobile.open_planes[player:get_player_name()]
                    if ent and ent.object:get_pos() then ent:save_inventory(inv) end
                end,
                on_take = function(inv, listname, index, stack, player)
                    local ent = sti_mobile.open_planes[player:get_player_name()]
                    if ent and ent.object:get_pos() then ent:save_inventory(inv) end
                end,
                on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                    local ent = sti_mobile.open_planes[player:get_player_name()]
                    if ent and ent.object:get_pos() then ent:save_inventory(inv) end
                end,
            })
        end

        inv:set_size("fuel", 1)
        inv:set_size("cargo", 8)
        inv:set_stack("fuel", 1, ItemStack(self.stored_fuel_item))
        for i = 1, 8 do
            inv:set_stack("cargo", i, ItemStack(self.stored_cargo_items[i] or ""))
        end

        local formspec = "size[8,9]" ..
            "label[0.5,0.3;Flugzeug-Cockpit & Laderaum]" ..
            "label[0.5,1.0;Brennstoff (Kohle)]" ..
            "list[detached:sti_mobile_plane_" .. name .. ";fuel;0.5,1.5;1,1;]" ..
            "label[3.0,1.0;Laderaum (8 Slots)]" ..
            "list[detached:sti_mobile_plane_" .. name .. ";cargo;3.0,1.5;4,2;]" ..
            "list[current_player;main;0,4.8;8,3;8]" ..
            "list[current_player;main;0,8.1;8,1;]" ..
            "list_ring[]"

        minetest.show_formspec(name, "sti_mobile:airplane_gui", formspec)
    end,

    board_plane = function(self, player)
        self.driver = player
        player:set_attach(self.object, "", {x = 0, y = 5, z = -2}, {x = 0, y = 0, z = 0})
        player:set_eye_offset({x = 0, y = 3, z = 0}, {x = 0, y = 3, z = 0})
    end,

    exit_plane = function(self, player)
        player:set_detach()
        player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        self.driver = nil
        self.current_speed = 0
        self.is_stalled = false
        self:stoppe_propeller()
    end,

    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end

        if self.driver then
            if self.driver == clicker then self:exit_plane(clicker) end
            return
        end

        local ctrl = clicker:get_player_control()
        if ctrl.sneak then
            self:open_gui(clicker)
        else
            self:board_plane(clicker)
        end
    end,

    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        if not pos then return end

        -- 1. AUTOMATISCHE BETANKUNG
        if self.fuel <= 0 then
            local fuel_stack = ItemStack(self.stored_fuel_item)
            if fuel_stack:get_name() == "default:coal_lump" and fuel_stack:get_count() > 0 then
                fuel_stack:take_item(1)
                self.stored_fuel_item = fuel_stack:to_string()
                self.fuel = 100

                for p_name, ent in pairs(sti_mobile.open_planes) do
                    if ent == self then
                        local inv = minetest.get_inventory({type = "detached", name = "sti_mobile_plane_" .. p_name})
                        if inv then inv:set_stack("fuel", 1, fuel_stack) end
                    end
                end
            end
        end

        -- Bodenprüfung (Grounded Check)
        local node_below = minetest.get_node({x = pos.x, y = pos.y - 0.6, z = pos.z})
        local is_grounded = node_below.name ~= "air"

        -- VERHALTEN OHNE PILOT
        if not self.driver then
            self.current_speed = math.max(0, self.current_speed - dtime * DECELERATION)
            local vel = self.object:get_velocity()
            self.object:set_velocity({x = vel.x * 0.95, y = vel.y - 9.81 * dtime, z = vel.z * 0.95})

            self.pitch = self.pitch * 0.9
            self.roll = self.roll * 0.9
            self.object:set_rotation({x = self.pitch, y = self.object:get_rotation().y, z = self.roll})
            if self.propeller_aktiv then self:stoppe_propeller() end
            return
        end

        local ctrl = self.driver:get_player_control()
        local yaw = self.object:get_yaw()

        -- In-Flight GUI via E-Taste (AUX1)
        if ctrl.aux1 then
            if not self.aux1_was_pressed then
                self:open_gui(self.driver)
                self.aux1_was_pressed = true
            end
        else
            self.aux1_was_pressed = false
        end

        -- MOTOR LÄUFT & HAT SPRIT
        if self.fuel > 0 then
            if not self.propeller_aktiv then self:starte_propeller() end

            -- Dynamischer Verbrauch: Vollgas + Steigen kostet mehr Sprit
            local burn_rate = 1.0
            if ctrl.up then burn_rate = burn_rate + 0.8 end
            if self.pitch > 0.1 then burn_rate = burn_rate + 0.7 end
            self.fuel = self.fuel - (dtime * burn_rate)

            -- Partikeleffekt (Auspuffqualm)
            self.particle_timer = self.particle_timer + dtime
            if self.particle_timer > 0.15 then
                self.particle_timer = 0
                minetest.add_particle({
                    pos = {x = pos.x, y = pos.y + 0.2, z = pos.z},
                    velocity = {x = (math.random() - 0.5) * 0.5, y = 0.5 + math.random(), z = (math.random() - 0.5) * 0.5},
                    acceleration = {x = 0, y = 0.5, z = 0},
                    expirationtime = 1.0 + math.random(),
                    size = 2 + math.random() * 3,
                    collisiondetection = true,
                    glow = 2,
                    texture = "default_smoke.png^[opacity:120",
                })
            end

            -- 2. SCHWERKRAFT-EFFEKT AUF GESCHWINDIGKEIT (Energieerhaltung)
            -- Nase unten (pitch < 0) bringt Speed, Nase oben (pitch > 0) bremst massiv.
            local gravity_acceleration = -self.pitch * 12.0

            if ctrl.up then
                -- Vortrieb durch Motor
                self.current_speed = self.current_speed + (ACCELERATION * dtime)
            else
                -- Luftwiderstand bremst aus
                self.current_speed = self.current_speed - (DECELERATION * dtime)
            end

            -- Schwerkraft einrechnen
            self.current_speed = self.current_speed + (gravity_acceleration * dtime)
            -- Speed-Limits einhalten
            self.current_speed = math.max(0, math.min(TERMINAL_SPEED, self.current_speed))

            -- 3. STALL-MECHANIK (Strömungsabriss)
            if not is_grounded and (self.current_speed < STALL_SPEED or self.pitch > 0.6) then
                if not self.is_stalled then
                    self.is_stalled = true
                    minetest.chat_send_player(self.driver:get_player_name(), "⚠️ STRÖMUNGSABRISS! (Stall) - Nase runter!")
                end
            end
            if self.is_stalled and self.current_speed > TAKEOFF_SPEED then
                self.is_stalled = false -- Abgefangen!
            end

            -- Steuerungs-Sollwerte ermitteln
            local target_pitch = 0
            local target_roll = 0

            if self.is_stalled then
                -- Im Stall sackt die Nase unkontrolliert ab und Lenken ist unmöglich
                target_pitch = -0.5
                target_roll = (math.random() - 0.5) * 0.2 -- Trudeln
            else
                -- Normale Steuerung, wenn kein Strömungsabriss vorliegt
                -- Kurvenflug (A/D) mit Neigung
                if self.current_speed > 3 then
                    local actual_turn = dtime * TURN_SPEED * (self.current_speed / MAX_SPEED)
                    if ctrl.left then
                        yaw = yaw + actual_turn
                        target_roll = -0.45 -- Korrigiert: Legt sich nach links in die Kurve
                    elseif ctrl.right then
                        yaw = yaw - actual_turn
                        target_roll = 0.45  -- Korrigiert: Legt sich nach rechts in die Kurve
                    end
                end

                -- Höhenruder (Leertaste / Shift)
                if ctrl.jump then
                    if self.current_speed >= TAKEOFF_SPEED or not is_grounded then
                        target_pitch = 0.35 -- Korrigiert: Nase hoch beim Steigen
                    else
                        target_pitch = 0.05 -- Reicht am Boden nicht zum Abheben
                    end
                elseif ctrl.sneak then
                    if not is_grounded then
                        target_pitch = -0.30 -- Korrigiert: Nase runter beim Sinken
                    end
                end
            end

            -- Sanfte Winkel-Interpolation (Lerp) für ultra-geschmeidige Bewegungen
            self.pitch = self.pitch + (target_pitch - self.pitch) * dtime * 3.0
            self.roll = self.roll + (target_roll - self.roll) * dtime * 4.0

            -- Rotation auf das Entity anwenden
            self.object:set_rotation({x = self.pitch, y = yaw, z = self.roll})

            -- 4. 3D-VEKTOR-BERECHNUNG FÜR DIE BEWEGUNG
            local cos_pitch = math.cos(self.pitch)
            local x_vel = -math.sin(yaw) * cos_pitch * self.current_speed
            local z_vel =  math.cos(yaw) * cos_pitch * self.current_speed

            -- Vertikale Fluggeschwindigkeit berechnen
            local y_vel = 0
            if is_grounded and target_pitch <= 0.05 and not ctrl.jump then
                y_vel = -1 -- Presst das Flugzeug beim Rollen sanft an den Boden
            else
                -- Berechnet sich physikalisch exakt aus Pitch und Speed
                y_vel = math.sin(self.pitch) * self.current_speed
                if self.is_stalled then y_vel = y_vel - 6.0 end -- Zusätzliches Absacken im Stall
            end

            self.object:set_velocity({x = x_vel, y = y_vel, z = z_vel})
        else
            -- SYSTEMAUSFALL (KEIN SPRIT MEHR)
            self.current_speed = math.max(0, self.current_speed - (dtime * 3.0))
            if self.propeller_aktiv then self:stoppe_propeller() end

            self.pitch = self.pitch + (-0.25 - self.pitch) * dtime * 1.5 -- Nase sinkt schwerfällig nach unten
            self.roll = self.roll * 0.95 -- Richtet sich flach aus

            self.object:set_rotation({x = self.pitch, y = yaw, z = self.roll})
            local x_vel = -math.sin(yaw) * math.cos(self.pitch) * self.current_speed
            local z_vel =  math.cos(yaw) * math.cos(self.pitch) * self.current_speed
            self.object:set_velocity({x = x_vel, y = -4.0, z = z_vel}) -- Gleitflug nach unten
        end
    end,

    -- Beim Schlagen das Flugzeug mitsamt Inventar abbauen
    on_punch = function(self, puncher)
        if not puncher or self.driver then return end
        local pos = self.object:get_pos()
        if pos then
            minetest.add_item(pos, "sti_mobile:airplane_item")
            if self.stored_fuel_item ~= "" then minetest.add_item(pos, self.stored_fuel_item) end
            for _, item_str in pairs(self.stored_cargo_items) do
                if item_str ~= "" then minetest.add_item(pos, item_str) end
            end
        end
        self.object:remove()
    end,

    -- Welt-Speicherung sichern
    get_staticdata = function(self)
        return minetest.serialize({
            fuel = self.fuel,
            stored_fuel_item = self.stored_fuel_item,
            stored_cargo_items = self.stored_cargo_items,
        })
    end,

    on_activate = function(self, staticdata, dtime_s)
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then
                self.fuel = data.fuel or 0
                self.stored_fuel_item = data.stored_fuel_item or ""
                self.stored_cargo_items = data.stored_cargo_items or {"", "", "", "", "", "", "", ""}
            end
        end
    end,

    starte_propeller = function(self)
        local props = self.object:get_properties()
        if props.mesh and props.mesh:sub(-4) == ".b3d" then
            self.object:set_animation({x = 1, y = 20}, 40, 0, true)
        end
        self.propeller_aktiv = true
    end,

    stoppe_propeller = function(self)
        local props = self.object:get_properties()
        if props.mesh and props.mesh:sub(-4) == ".b3d" then
            self.object:set_animation({x = 0, y = 0}, 0, 0, false)
        end
        self.propeller_aktiv = false
    end,
})

-- Spawnhilfe-Item
minetest.register_craftitem("sti_mobile:airplane_item", {
    description = "Flugzeug (sti_mobile)",
    inventory_image = "sti_mobile_flieger_item.png",
    wield_image = "sti_mobile_flieger_item.png",
    stack_max = 1,

    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end
        local pos = pointed_thing.above
        pos.y = pos.y + 0.5

        local ent = minetest.add_entity(pos, "sti_mobile:airplane")
        if ent and placer then
            ent:set_yaw(placer:get_look_horizontal())
            if not minetest.settings:get_bool("creative_mode") then
                itemstack:take_item()
            end
        end
        return itemstack
    end,
})

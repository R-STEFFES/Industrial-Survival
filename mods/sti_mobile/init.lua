-- Globaler Tisch für Mod-Daten (wichtig für das GUI-Management)
sti_mobile = {
    open_planes = {} -- Speichert, welcher Spieler gerade welches Flugzeug-GUI offen hat
}

-- Flugzeug Entity registrieren
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

    -- Inventar-Speicher (wird beim Verlassen der Welt serialisiert)
    stored_fuel_item = "",
    stored_cargo_items = {"", "", "", "", "", "", "", ""}, -- 8 Frachtslots

    -- Speichert das Inventar aus dem GUI direkt im Flugzeug-Objekt
    save_inventory = function(self, inv)
        self.stored_fuel_item = inv:get_stack("fuel", 1):to_string()
        self.stored_cargo_items = {}
        for i = 1, 8 do
            self.stored_cargo_items[i] = inv:get_stack("cargo", i):to_string()
        end
    end,

    -- Öffnet das grafische Menü (Formspec)
    open_gui = function(self, player)
        local name = player:get_player_name()
        sti_mobile.open_planes[name] = self -- Referenz merken

        -- Detached Inventar für diesen Spieler holen oder erstellen
        local inv = minetest.get_inventory({type = "detached", name = "sti_mobile_plane_" .. name})
        if not inv then
            inv = minetest.create_detached_inventory("sti_mobile_plane_" .. name, {
                allow_put = function(inv, listname, index, stack, player)
                    if listname == "fuel" then
                        -- Nur normale Kohle im Treibstoff-Fach erlauben
                        if stack:get_name() == "default:coal_lump" then
                            return stack:get_count()
                        end
                        return 0
                    end
                    return stack:get_count() -- Alles andere im Laderaum erlauben
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

        -- Inventargrößen definieren & mit gespeicherten Daten beladen
        inv:set_size("fuel", 1)
        inv:set_size("cargo", 8)
        inv:set_stack("fuel", 1, ItemStack(self.stored_fuel_item))
        for i = 1, 8 do
            inv:set_stack("cargo", i, ItemStack(self.stored_cargo_items[i] or ""))
        end

        -- Das GUI-Layout zusammenbauen
        local formspec = "size[8,9]" ..
            "label[0.5,0.3;Flugzeug-Cockpit & Laderaum]" ..

            -- Treibstoff-Slot
            "label[0.5,1.0;Brennstoff (Kohle)]" ..
            "list[detached:sti_mobile_plane_" .. name .. ";fuel;0.5,1.5;1,1;]" ..

            -- 4x2 Fracht-Inventar
            "label[3.0,1.0;Laderaum (8 Slots)]" ..
            "list[detached:sti_mobile_plane_" .. name .. ";cargo;3.0,1.5;4,2;]" ..

            -- Spieler-Inventar Anzeigen
            "list[current_player;main;0,4.8;8,3;8]" ..
            "list[current_player;main;0,8.1;8,1;]" ..
            "list_ring[]"

        minetest.show_formspec(name, "sti_mobile:airplane_gui", formspec)
    end,

    -- Logik beim Einsteigen
    board_plane = function(self, player)
        self.driver = player
        player:set_attach(self.object, "", {x = 0, y = 5, z = -2}, {x = 0, y = 0, z = 0})
        player:set_eye_offset({x = 0, y = 3, z = 0}, {x = 0, y = 3, z = 0})
    end,

    -- Logik beim Aussteigen
    exit_plane = function(self, player)
        player:set_detach()
        player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        self.driver = nil
        self:stoppe_propeller()
    end,

    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end

        -- Falls bereits jemand fliegt
        if self.driver then
            if self.driver == clicker then
                self:exit_plane(clicker)
            end
            return
        end

        -- Prüfen, ob der Spieler schleicht (Shift-Taste hält)
        local ctrl = clicker:get_player_control()
        if ctrl.sneak then
            self:open_gui(clicker) -- GUI öffnen
        else
            self:board_plane(clicker) -- Einsteigen
        end
    end,

    on_step = function(self, dtime)
        -- AUTOMATISCHE BETANKUNG AUS DEM SLOT
        if self.fuel <= 0 then
            local fuel_stack = ItemStack(self.stored_fuel_item)
            if fuel_stack:get_name() == "default:coal_lump" and fuel_stack:get_count() > 0 then
                fuel_stack:take_item(1)
                self.stored_fuel_item = fuel_stack:to_string()
                self.fuel = 100 -- Ein Stück Kohle füllt den Flieger jetzt voll auf!

                -- Live-Update im GUI falls ein Spieler es gerade offen hat
                for p_name, ent in pairs(sti_mobile.open_planes) do
                    if ent == self then
                        local inv = minetest.get_inventory({type = "detached", name = "sti_mobile_plane_" .. p_name})
                        if inv then inv:set_stack("fuel", 1, fuel_stack) end
                    end
                end
            end
        end

        -- Verhalten ohne Fahrer
        if not self.driver then
            local vel = self.object:get_velocity()
            self.object:set_velocity({x = vel.x * 0.95, y = vel.y - 9.81 * dtime, z = vel.z * 0.95})
            if self.propeller_aktiv then self:stoppe_propeller() end
            return
        end

        local ctrl = self.driver:get_player_control()
        local vel = self.object:get_velocity()
        local yaw = self.object:get_yaw()

        if self.fuel > 0 then
            -- Motor läuft! Propeller aktivieren, falls noch nicht geschehen
            if not self.propeller_aktiv then self:starte_propeller() end

            -- Spritverbrauch (Kombiniert zeitlich)
            self.fuel = self.fuel - (dtime * 1.5)

            -- FLUGSTEUERUNG
            local speed = 12
            if ctrl.up then
                local x = -math.sin(yaw) * speed
                local z =  math.cos(yaw) * speed
                local y = ctrl.jump and 4 or (ctrl.sneak and -4 or 0.5)
                self.object:set_velocity({x = x, y = vel.y * 0.2 + y, z = z})
            else
                self.object:set_velocity({x = vel.x * 0.98, y = vel.y - 2 * dtime, z = vel.z * 0.98})
            end

            if ctrl.left then
                self.object:set_yaw(yaw + dtime * 1.5)
            elseif ctrl.right then
                self.object:set_yaw(yaw - dtime * 1.5)
            end
        else
            -- Tank komplett leer und keine Kohle nachgerutscht
            self.fuel = 0
            if self.propeller_aktiv then self:stoppe_propeller() end
            self.object:set_velocity({x = vel.x * 0.98, y = -3, z = vel.z * 0.98})
        end
    end,

    -- Beim Schlagen des Flugzeugs alles fallen lassen und abbauen
    on_punch = function(self, puncher)
        if not puncher or self.driver then return end

        local pos = self.object:get_pos()
        if pos then
            -- Flugzeug-Item droppen
            minetest.add_item(pos, "sti_mobile:airplane_item")

            -- Gelagerten Treibstoff droppen
            if self.stored_fuel_item ~= "" then
                minetest.add_item(pos, self.stored_fuel_item)
            end

            -- Gelagerte Fracht droppen
            for _, item_str in pairs(self.stored_cargo_items) do
                if item_str ~= "" then minetest.add_item(pos, item_str) end
            end
        end
        self.object:remove()
    end,

    -- SPEICHER-FUNKTIONEN (Server-Restarts/Karten-Reloads)
    get_staticdata = function(self)
        local data = {
            fuel = self.fuel,
            stored_fuel_item = self.stored_fuel_item,
            stored_cargo_items = self.stored_cargo_items,
        }
        return minetest.serialize(data)
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

-- Spawnhilfe-Item Registrierung
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

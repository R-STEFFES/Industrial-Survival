-- =======================================================================
-- STI MACHINES - DAMPFPUMPE (MIT INTERNEM TANK & STATUS-MONITOR)
-- =======================================================================

local function get_fuel_time(itemstack)
    local fuel = minetest.get_craft_result({method = "fuel", width = 1, items = {itemstack}})
    if fuel and fuel.time and fuel.time > 0 then return fuel.time end
    return 0
end

local function get_side_color(mode)
    if mode == 1 then return "#3366ff" end -- Blau (Input)
    if mode == 2 then return "#ffaa00" end -- Orange (Output)
    return "#555555" -- Grau
end

local sides = {"top", "bottom", "front", "back", "left", "right"}

-- GUI UPDATE (Mit dynamischer Statusmeldung und Tankanzeige)
function sti_machines.update_pump_formspec(pos)
    local meta = minetest.get_meta(pos)
    local burn_time = meta:get_int("burn_time")
    local max_burn_time = meta:get_int("max_burn_time")

    -- Tank-Werte auslesen
    local tank_amount = meta:get_int("tank_amount")
    local tank_max = 8000
    local status_text = meta:get_string("status_msg") or "Bereit"

    -- Farbige Markierung für den Status im GUI
    local status_color = "#ffffff"
    if status_text:find("Aktiv") or status_text:find("Fördert") then
        status_color = "#00ff00" -- Grün für Betrieb
    elseif status_text:find("Keine Kohle") or status_text:find("voll") then
        status_color = "#ffaa00" -- Orange für Warnung/Stop
    end

    local m_top    = meta:get_int("side_top")
    local m_bottom = meta:get_int("side_bottom")
    local m_front  = meta:get_int("side_front")
    local m_back   = meta:get_int("side_back")
    local m_left   = meta:get_int("side_left")
    local m_right  = meta:get_int("side_right")

    local formspec = "size[9,9.5]" ..
        "label[0.5,0.3;--- DAMPFPUMPE KONTROLLE ---]" ..

        -- STATUS UND TANKANZEIGE
        "label[0.5,0.9;Status:]" ..
        "label[1.5,0.9;" .. status_text .. "]" ..
        "label[0.5,1.4;Interner Tank: " .. tank_amount .. " / " .. tank_max .. " mb]" ..
        "box[0.5,1.8;3.5,0.2;#333333]"

    -- Fortschrittsbalken für den internen Wassertank (Hellblau)
    if tank_amount > 0 then
        local tank_bar = (tank_amount / tank_max) * 3.5
        formspec = formspec .. "box[0.5,1.8;" .. tank_bar .. ",0.2;#00d4ff]"
    end

    -- BRENNSTOFF-ANZEIGE
    formspec = formspec ..
        "label[0.5,2.3;Brennstoff-Slot:]" ..
        "list[context;fuel;0.5,2.7;1,1;]" ..
        "box[0.5,4.0;1.5,0.2;#333333]"

    if burn_time > 0 and max_burn_time > 0 then
        local fuel_bar = (burn_time / max_burn_time) * 1.5
        formspec = formspec .. "box[0.5,4.0;" .. fuel_bar .. ",0.2;#ffaa00]"
    end

    -- SEITEN-KONFIGURATOR MATRIX
    formspec = formspec ..
        "label[4.5,1.0;Seiten-Konfiguration (Klicken):]" ..
        "label[4.5,1.3;Blau = Input | Orange = Output | Grau = Aus]" ..

        "style[btn_top;bgcolor=" .. get_side_color(m_top) .. ";textcolor=#ffffff]" ..
        "button[5.5,1.8;1.2,0.8;btn_top;Oben]" ..

        "style[btn_left;bgcolor=" .. get_side_color(m_left) .. ";textcolor=#ffffff]" ..
        "button[4.2,2.7;1.2,0.8;btn_left;Links]" ..

        "style[btn_front;bgcolor=" .. get_side_color(m_front) .. ";textcolor=#ffffff]" ..
        "button[5.5,2.7;1.2,0.8;btn_front;Vorne]" ..

        "style[btn_right;bgcolor=" .. get_side_color(m_right) .. ";textcolor=#ffffff]" ..
        "button[6.8,2.7;1.2,0.8;btn_right;Rechts]" ..

        "style[btn_back;bgcolor=" .. get_side_color(m_back) .. ";textcolor=#ffffff]" ..
        "button[8.1,2.7;1.2,0.8;btn_back;Hinten]" ..

        "style[btn_bottom;bgcolor=" .. get_side_color(m_bottom) .. ";textcolor=#ffffff]" ..
        "button[5.5,3.6;1.2,0.8;btn_bottom;Unten]"

    -- Spieler-Inventar
    formspec = formspec ..
        "list[current_player;main;0.5,5.3;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;fuel]"

    meta:set_string("formspec", formspec)
end

-- REGISTRIERUNG DER PUMPE
minetest.register_node("sti_machines:steam_pump", {
    description = "Dampfbetriebene Wasserpumpe (Mit 8000mb Tank)",
    tiles = {"stimachines_pump_top.png", "stimachines_pump_bottom.png",
             "stimachines_pump_side.png", "stimachines_pump_side.png",
             "stimachines_pump_side.png", "stimachines_pump_side.png"},
    paramtype2 = "facedir",
    groups = {cracky = 2, machine_fluid = 1, machine_item = 1},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("fuel", 1)

        -- Standard-Zustände setzen
        meta:set_int("side_front", 2) -- Vorne = Output
        meta:set_int("burn_time", 0)
        meta:set_int("max_burn_time", 0)

        -- Tank initialisieren
        meta:set_int("tank_amount", 0)
        meta:set_string("status_msg", "Bereit. Wartet auf Kohle.")

        sti_machines.update_pump_formspec(pos)
    end,

    on_rightclick = function(pos, node, clicker)
        sti_machines.update_pump_formspec(pos)
    end,

    on_receive_fields = function(pos, formname, fields, sender)
        local meta = minetest.get_meta(pos)
        local changed = false
        for _, side in ipairs(sides) do
            if fields["btn_" .. side] then
                local mode = meta:get_int("side_" .. side)
                meta:set_int("side_" .. side, (mode + 1) % 3)
                changed = true
            end
        end
        if changed then sti_machines.update_pump_formspec(pos) end
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "fuel" and get_fuel_time(stack) > 0 then return stack:get_count() end
        return 0
    end,

    on_metadata_inventory_put = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local burn_time = meta:get_int("burn_time")
        local max_burn_time = meta:get_int("max_burn_time")
        local tank_amount = meta:get_int("tank_amount")
        local tank_max = 8000

        -- 1. PRÜFUNG: Wenn der interne Tank randvoll ist, pausiert die Pumpe brennstoffsparend
        if tank_amount >= tank_max then
            meta:set_string("status_msg", "Pausiert: Interner Tank voll.")
            meta:set_string("infotext", "Pumpe: Tank voll (8000mb)")
            sti_machines.update_pump_formspec(pos)
            return true -- Timer bleibt aktiv, um auf Entleerung zu warten
        end

        local active = false

        -- 2. BRENNSTOFF-VERARBEITUNG
        if burn_time <= 0 then
            local fuel_stack = inv:get_stack("fuel", 1)
            local fuel_duration = get_fuel_time(fuel_stack)
            if fuel_duration > 0 then
                fuel_stack:take_item(1)
                inv:set_stack("fuel", 1, fuel_stack)
                burn_time = fuel_duration
                max_burn_time = fuel_duration
                meta:set_int("max_burn_time", max_burn_time)
                active = true
            end
        else
            burn_time = burn_time - 1
            active = true
        end

        meta:set_int("burn_time", burn_time)

        -- 3. PUMP-LOGIK (Füllt den internen Tank auf)
        if active then
            -- Wir generieren 400mb Wasser pro Sekunde aus dem Boden/der Luft
            local new_amount = math.min(tank_max, tank_amount + 400)
            meta:set_int("tank_amount", new_amount)

            meta:set_string("status_msg", "Aktiv: Fördert Wasser... (+400mb/s)")
            meta:set_string("infotext", "Pumpe: Aktiv - Tank: " .. new_amount .. " mb")

            -- Berechne absolute Richtungen für das visuelle Partikel-Feedback an den Outputs
            local node = minetest.get_node(pos)
            local p2 = node.param2
            local relative_dirs = {
                top    = {x=0,  y=1,  z=0}, bottom = {x=0,  y=-1, z=0},
                front  = minetest.facedir_to_dir(p2),
                back   = vector.multiply(minetest.facedir_to_dir(p2), -1),
                left   = {x = minetest.facedir_to_dir(p2).z,  y=0, z = -minetest.facedir_to_dir(p2).x},
                right  = {x = -minetest.facedir_to_dir(p2).z, y=0, z = minetest.facedir_to_dir(p2).x}
            }

            for _, side in ipairs(sides) do
                if meta:get_int("side_" .. side) == 2 then
                    local target_pos = vector.add(pos, relative_dirs[side])
                    local target_node = minetest.get_node(target_pos)
                    if target_node.name:sub(1, 12) == "mylogistics:" then
                        minetest.add_particle({
                            pos = vector.add(target_pos, {x=0, y=0.1, z=0}),
                            velocity = {x=0, y=0.3, z=0},
                            expirationtime = 0.5,
                            size = 2,
                            texture = "bubble.png",
                        })
                    end
                end
            end

            sti_machines.update_pump_formspec(pos)
            return true
        else
            meta:set_string("status_msg", "Wartet: Keine Kohle vorhanden.")
            meta:set_string("infotext", "Pumpe: Fehlender Brennstoff.")
            sti_machines.update_pump_formspec(pos)
            return false -- Schaltet den Timer ab, bis neue Kohle reingelegt wird
        end
    end
})

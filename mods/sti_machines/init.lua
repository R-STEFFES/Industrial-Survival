sti_machines = {}

-- Hilfsfunktion: Prüft, ob ein Gegenstand als Brennstoff gilt (z.B. Kohle)
local function get_fuel_time(itemstack)
    local fuel, tipped = minetest.get_craft_result({method = "fuel", width = 1, items = {itemstack}})
    if fuel and fuel.time and fuel.time > 0 then
        return fuel.time
    end
    return 0
end

-- =======================================================================
-- 1. REGISTRIERUNG DER DAMPFPUMPE
-- =======================================================================

minetest.register_node("sti_machines:steam_pump", {
    description = "Dampfbetriebene Wasserpumpe",
    -- 6 Texturen: Oben, Unten, Rechts, Links, Hinten (Input), Vorne (Output)
    tiles = {
        "stimachines_pump_top.png",
        "stimachines_pump_bottom.png",
        "stimachines_pump_side.png",
        "stimachines_pump_side.png",
        "stimachines_pump_back.png",  -- Hier kommen Items (Kohle) rein
        "stimachines_pump_front.png"  -- Hier kommt das Fluiduct-Rohr dran
    },
    paramtype2 = "facedir", -- Erlaubt das Drehen der Maschine mit dem Screwdriver
    groups = {cracky = 2, machine_fluid = 1, machine_item = 1},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        -- Inventar erstellen: 1 Slot für Brennstoff
        inv:set_size("fuel", 1)

        meta:set_int("burn_time", 0)
        meta:set_int("max_burn_time", 0)
        meta:set_string("infotext", "Pumpe: Bereit. Wartet auf Brennstoff.")

        sti_machines.update_pump_formspec(pos)
    end,

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        sti_machines.update_pump_formspec(pos)
    end,

    -- Erlaubt es Itemducts oder Trichtern, Kohle in den Brennstoff-Slot zu legen
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "fuel" and get_fuel_time(stack) > 0 then
            return stack:get_count()
        end
        return 0
    end,

    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        -- Starte den Timer, sobald Kohle eingelegt wird
        minetest.get_node_timer(pos):start(1.0)
    end,

    -- Der Kern-Arbeitszyklus der Pumpe
    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local burn_time = meta:get_int("burn_time")
        local max_burn_time = meta:get_int("max_burn_time")

        local active = false

        -- 1. Brennstoff-Logik: Wenn die Pumpe kalt ist, hole neue Kohle
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
            -- Pumpe läuft bereits, ziehe Zeit ab
            burn_time = burn_time - 1
            active = true
        end

        meta:set_int("burn_time", burn_time)

        -- 2. Pump-Logik: Wenn aktiv, generiere Wasser und drücke es in die Fluiducts
        if active then
            meta:set_string("infotext", "Pumpe: Arbeitet... (Brennzeit: " .. burn_time .. "s)")

            -- Richtungsvektoren basierend auf der Rotation (facedir) der Maschine ermitteln
            local node = minetest.get_node(pos)
            local dir = minetest.facedir_to_dir(node.param2)

            -- Vorne (dir) ist unser konfigurierter Output für Flüssigkeiten
            local output_pos = vector.add(pos, dir)
            local output_node = minetest.get_node(output_pos)

            -- Wenn vorne ein Fluiduct angeschlossen ist, schicken wir Wasser durch das Logistiknetzwerk
            if output_node.name == "mylogistics:fluiduct" then
                -- Wir suchen nach dem nächsten angeschlossenen Tank-Inlet in der Kette (max 12 Blöcke weit)
                local inlet_pos = minetest.find_node_near(output_pos, 12, {"mytank:inlet"})
                if inlet_pos then
                    -- Wir suchen den dazugehörigen aktiven Controller des Multiblocks
                    local controller_pos = minetest.find_node_near(inlet_pos, 5, {"mytank:controller_active"})
                    if controller_pos and mytank and mytank.insert_fluid then
                        -- Wir pumpen 200 Millibuckets "default:water_source" pro Sekunde in deinen Tank
                        local pumped = mytank.insert_fluid(controller_pos, "default:water_source", 200)
                        if pumped > 0 then
                            -- Kurzer visueller Partikeleffekt am Rohr bei erfolgreichem Pumpen
                            minetest.add_particle({
                                pos = vector.add(output_pos, {x=0, y=0.5, z=0}),
                                velocity = {x=0, y=1, z=0},
                                acceleration = {x=0, y=0, z=0},
                                expirationtime = 1.0,
                                size = 4,
                                collisiondetection = false,
                                vertical = false,
                                texture = "bubble.png",
                            })
                        end
                    end
                end
            end

            sti_machines.update_pump_formspec(pos)
            return true -- Timer läuft weiter, da die Maschine befeuert ist
        else
            meta:set_string("infotext", "Pumpe: Keine Kohle vorhanden.")
            sti_machines.update_pump_formspec(pos)
            return false -- Stoppt den Timer, spart Serverleistung
        end
    end
})

-- =======================================================================
-- 2. GUI (Formspec) FÜR DIE PUMPE
-- =======================================================================

function sti_machines.update_pump_formspec(pos)
    local meta = minetest.get_meta(pos)
    local burn_time = meta:get_int("burn_time")
    local max_burn_time = meta:get_int("max_burn_time")

    local progress = 0
    if max_burn_time > 0 then
        progress = (burn_time / max_burn_time) * 100
    end

    local formspec = "size[8,9]" ..
        "label[0.5,0.5;--- DAMPFPUMPE (WASSER) ---]" ..
        -- Brennstoff-Slot (Eingabe)
        "label[3.5,1.5;Brennstoff]" ..
        "list[context;fuel;3.5,2.0;1,1;]" ..

        -- Kleines Info-Segment über die Anschlüsse
        "label[0.5,1.5;INFO:]" ..
        "label[0.5,1.9;Ruckseite (Input): Kohle]" ..
        "label[0.5,2.3;Vorderseite (Output): Wasser]" ..

        -- Fortschrittsbalken für das Verbrennen der Kohle
        "box[2.5,3.3;3,0.3;#333333]"

    if burn_time > 0 then
        local bar_width = (burn_time / max_burn_time) * 3
        formspec = formspec .. "box[2.5,3.3;" .. bar_width .. ",0.3;#ffaa00]"
    end

    formspec = formspec ..
        -- Spieler-Inventar anzeigen, damit man Kohle hineinziehen kann
        "list[current_player;main;0,4.8;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;fuel]"

    meta:set_string("formspec", formspec)
end

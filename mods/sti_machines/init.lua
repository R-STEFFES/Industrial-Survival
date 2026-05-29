-- =======================================================================
-- STI MACHINES - INITIALISIERUNG & KERN-LOGIK
-- =======================================================================

-- 1. Globale Mod-Tabelle definieren
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
-- 2. REGISTRIERUNG DER DAMPFPUMPE (BESTEHEND)
-- =======================================================================

minetest.register_node("sti_machines:steam_pump", {
    description = "Dampfbetriebene Wasserpumpe",
    tiles = {
        "stimachines_pump_top.png",
        "stimachines_pump_bottom.png",
        "stimachines_pump_side.png",
        "stimachines_pump_side.png",
        "stimachines_pump_back.png",  -- Input für Items (Kohle)
        "stimachines_pump_front.png"  -- Output für Fluiducts
    },
    paramtype2 = "facedir",
    groups = {cracky = 2, machine_fluid = 1, machine_item = 1},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        inv:set_size("fuel", 1)
        meta:set_int("burn_time", 0)
        meta:set_int("max_burn_time", 0)
        meta:set_string("infotext", "Pumpe: Bereit. Wartet auf Brennstoff.")

        sti_machines.update_pump_formspec(pos)
    end,

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        sti_machines.update_pump_formspec(pos)
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "fuel" and get_fuel_time(stack) > 0 then
            return stack:get_count()
        end
        return 0
    end,

    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        minetest.get_node_timer(pos):start(1.0)
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local burn_time = meta:get_int("burn_time")
        local max_burn_time = meta:get_int("max_burn_time")

        local active = false

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

        if active then
            meta:set_string("infotext", "Pumpe: Arbeitet... (Brennzeit: " .. burn_time .. "s)")

            local node = minetest.get_node(pos)
            local dir = minetest.facedir_to_dir(node.param2)
            local output_pos = vector.add(pos, dir)
            local output_node = minetest.get_node(output_pos)

            if output_node.name == "mylogistics:fluiduct" then
                local inlet_pos = minetest.find_node_near(output_pos, 12, {"mytank:inlet"})
                if inlet_pos then
                    local controller_pos = minetest.find_node_near(inlet_pos, 5, {"mytank:controller_active"})
                    if controller_pos and mytank and mytank.insert_fluid then
                        local pumped = mytank.insert_fluid(controller_pos, "default:water_source", 200)
                        if pumped > 0 then
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
            return true
        else
            meta:set_string("infotext", "Pumpe: Keine Kohle vorhanden.")
            sti_machines.update_pump_formspec(pos)
            return false
        end
    end
})

-- GUI FÜR DIE PUMPE
function sti_machines.update_pump_formspec(pos)
    local meta = minetest.get_meta(pos)
    local burn_time = meta:get_int("burn_time")
    local max_burn_time = meta:get_int("max_burn_time")

    local formspec = "size[8,9]" ..
        "label[0.5,0.5;--- DAMPFPUMPE (WASSER) ---]" ..
        "label[3.5,1.5;Brennstoff]" ..
        "list[context;fuel;3.5,2.0;1,1;]" ..
        "label[0.5,1.5;INFO:]" ..
        "label[0.5,1.9;Ruckseite (Input): Kohle]" ..
        "label[0.5,2.3;Vorderseite (Output): Wasser]" ..
        "box[2.5,3.3;3,0.3;#333333]"

    if burn_time > 0 and max_burn_time > 0 then
        local bar_width = (burn_time / max_burn_time) * 3
        formspec = formspec .. "box[2.5,3.3;" .. bar_width .. ",0.3;#ffaa00]"
    end

    formspec = formspec ..
        "list[current_player;main;0,4.8;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;fuel]"

    meta:set_string("formspec", formspec)
end

-- =======================================================================
-- 3. EXTERNE MASCHINEN-DATEIEN LADEN
-- =======================================================================

local modpath = minetest.get_modpath("sti_machines")

-- Lädt den Kohle-Generator, die Batterie und den elektrischen Ofen
dofile(modpath .. "/generator.lua")
dofile(modpath .. "/battery.lua")
dofile(modpath .. "/electric_furnace.lua")

minetest.log("action", "[sti_machines] Mod erfolgreich geladen! (Pumpe, Generator, Batterie, E-Ofen)")

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

-- In init.lua einfügen
function sti_machines.push_energy_network(start_pos, energy_available)
    local visited = {}
    local consumers = {}
    local queue = {start_pos}
    local hash = minetest.hash_node_position

    visited[hash(start_pos)] = true

    -- 1. Netzwerk absuchen (BFS)
    while #queue > 0 do
        local pos = table.remove(queue, 1)
        local dirs = {
            {x=1,y=0,z=0}, {x=-1,y=0,z=0},
            {x=0,y=1,z=0}, {x=0,y=-1,z=0},
            {x=0,y=0,z=1}, {x=0,y=0,z=-1}
        }

        for _, dir in ipairs(dirs) do
            local npos = vector.add(pos, dir)
            local nhash = hash(npos)

            if not visited[nhash] then
                visited[nhash] = true
                local node = minetest.get_node(npos)
                local def = minetest.registered_nodes[node.name]

                if def then
                    -- Wenn es ein Kabel ist, weiter in diese Richtung suchen
                    if minetest.get_item_group(node.name, "cable") > 0 then
                        table.insert(queue, npos)

                    -- Wenn es ein Verbraucher ist, zur Liste hinzufügen
                    -- Batterie im Output-Modus NICHT als Verbraucher zählen
                    elseif def.is_energy_consumer then
                        local meta = minetest.get_meta(npos)
                        if meta then
                            -- Batterie im Output-Modus überspringen (sie liefert, nicht verbraucht)
                            local mode = meta:get_string("mode")
                            if mode == "output" then
                                -- ignorieren
                            else
                                local e_current = meta:get_int("energy")
                                local e_max = meta:get_int("max_energy")
                                if e_current < e_max then
                                    table.insert(consumers, {pos=npos, meta=meta, current=e_current, max=e_max})
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 2. Energie gleichmäßig verteilen
    if #consumers > 0 and energy_available > 0 then
        local max_transfer = math.min(energy_available, 200) -- Maximaler Transfer pro Tick
        local per_consumer = math.floor(max_transfer / #consumers)
        local actually_drawn = 0

        if per_consumer > 0 then
            for _, consumer in ipairs(consumers) do
                local needed = consumer.max - consumer.current
                local to_give = math.min(per_consumer, needed)

                if to_give > 0 then
                    consumer.meta:set_int("energy", consumer.current + to_give)
                    actually_drawn = actually_drawn + to_give

                    -- Verbraucher aufwecken, falls er schläft
                    local t = minetest.get_node_timer(consumer.pos)
                    if not t:is_started() then t:start(1.0) end
                end
            end
        end
        return actually_drawn -- Rückgabe, wie viel Strom wirklich ins Netz geflossen ist
    end

    return 0
end

-- =======================================================================
-- 2. EXTERNE MASCHINEN-DATEIEN LADEN
-- =======================================================================

local modpath = minetest.get_modpath("sti_machines")

-- Lädt den Kohle-Generator, die Batterie und den elektrischen Ofen
-- In der init.lua unter "3. EXTERNE MASCHINEN-DATEIEN LADEN" einfügen:
dofile(modpath .. "/pump.lua")
dofile(modpath .. "/generator.lua")
dofile(modpath .. "/battery.lua")
dofile(modpath .. "/electric_furnace.lua")
dofile(modpath .. "/pulverizer.lua")
dofile(modpath .. "/alloy_smelter.lua")
dofile(modpath .. "/charging_station.lua")
dofile(modpath .. "/fluid_filler.lua")
dofile(modpath .. "/autocrafter.lua")
dofile(modpath .. "/gold_washer.lua")
dofile(modpath .. "/liquid_workbench.lua")
dofile(modpath .. "/recipes.lua")
dofile(modpath .. "/recipes_washer.lua")
dofile(modpath .. "/quarry.lua")

minetest.log("action", "[sti_machines] Mod erfolgreich geladen! (Pumpe, Generator, Batterie, E-Ofen)")

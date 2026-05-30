-- =======================================================
-- 1. FURNACE GENERATOR (Kohle -> Strom) mit Active-State (Netzwerk-Push)
-- =======================================================

local function get_fuel_time(itemstack)
    local fuel, _ = minetest.get_craft_result({method = "fuel", width = 1, items = {itemstack}})
    if fuel and fuel.time and fuel.time > 0 then
        return fuel.time
    end
    return 0
end

function sti_machines.update_generator_formspec(pos)
    local meta = minetest.get_meta(pos)
    local burn_time = meta:get_int("burn_time")
    local max_burn_time = meta:get_int("max_burn_time")
    local energy = meta:get_int("energy")
    local max_energy = meta:get_int("max_energy")

    local formspec = "size[8,9]" ..
        "label[0.5,0.5;--- KOHLE-GENERATOR ---]" ..
        "label[3.5,1.2;Brennstoff]" ..
        "list[context;fuel;3.5,1.7;1,1;]" ..
        "label[0.5,1.7;Speicher: " .. energy .. " / " .. max_energy .. " EU]" ..
        "box[0.5,3.0;7,0.3;#333333]"

    if burn_time > 0 and max_burn_time > 0 then
        local burn_width = (burn_time / max_burn_time) * 7
        formspec = formspec .. "box[0.5,3.0;" .. burn_width .. ",0.3;#ffaa00]"
    end

    formspec = formspec .. "box[0.5,3.5;7,0.3;#333333]"
    if energy > 0 and max_energy > 0 then
        local energy_width = (energy / max_energy) * 7
        formspec = formspec .. "box[0.5,3.5;" .. energy_width .. ",0.3;#00ff00]"
    end

    formspec = formspec ..
        "list[current_player;main;0,4.8;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;fuel]"

    meta:set_string("formspec", formspec)
end

local generator_def = {
    description = "Kohle-Generator",
    paramtype2 = "facedir",
    groups = {cracky = 2, technic_machine = 1, machine_power = 1},
    is_energy_source = true,

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("fuel", 1)

        meta:set_int("burn_time", 0)
        meta:set_int("max_burn_time", 0)
        meta:set_int("energy", 0)
        meta:set_int("max_energy", 10000)
        meta:set_int("production_rate", 50)
        meta:set_string("infotext", "Generator: Bereit.")

        sti_machines.update_generator_formspec(pos)
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
        local energy = meta:get_int("energy")
        local max_energy = meta:get_int("max_energy")
        local production = meta:get_int("production_rate")

        local burning = false
        local node = minetest.get_node(pos)

        -- Generiere Energie aus Kohle
        if energy < max_energy then
            if burn_time <= 0 then
                local fuel_stack = inv:get_stack("fuel", 1)
                local fuel_duration = get_fuel_time(fuel_stack)

                if fuel_duration > 0 then
                    fuel_stack:take_item(1)
                    inv:set_stack("fuel", 1, fuel_stack)
                    burn_time = fuel_duration
                    max_burn_time = fuel_duration
                    meta:set_int("max_burn_time", max_burn_time)
                    burning = true
                end
            else
                burn_time = burn_time - 1
                burning = true
            end
        end

        if burning or burn_time > 0 then
            energy = math.min(energy + production, max_energy)
            meta:set_string("infotext", "Generator: Aktiv (" .. production .. " EU/s)\nEnergie: " .. energy .. " EU")
            if node.name ~= "sti_machines:generator_active" then
                minetest.swap_node(pos, {name = "sti_machines:generator_active", param2 = node.param2})
            end
        else
            meta:set_string("infotext", "Generator: Inaktiv\nEnergie: " .. energy .. " EU")
            if node.name ~= "sti_machines:generator" then
                minetest.swap_node(pos, {name = "sti_machines:generator", param2 = node.param2})
            end
        end

        meta:set_int("burn_time", burn_time)
        meta:set_int("energy", energy)
        sti_machines.update_generator_formspec(pos)

        -- Energie über das Kabelnetzwerk pushen
        if energy > 0 then
            if sti_machines.push_energy_network then
                local drawn = sti_machines.push_energy_network(pos, energy)
                if drawn > 0 then
                    energy = energy - drawn
                    meta:set_int("energy", energy)
                end
            else
                minetest.log("error", "[sti_machines] push_energy_network fehlt in init.lua!")
            end
        end

        -- FIX 1: Der Timer bleibt AUCH aktiv, wenn noch Kohle im Inventar liegt!
        local has_fuel = get_fuel_time(inv:get_stack("fuel", 1)) > 0
        return (burn_time > 0 or energy > 0 or has_fuel)
    end
}

-- Inaktiven Generator registrieren
local def_inactive = table.copy(generator_def)
def_inactive.tiles = {
    "stimachines_generator_top.png", "stimachines_generator_bottom.png",
    "stimachines_generator_side.png", "stimachines_generator_side.png",
    "stimachines_generator_side.png", "stimachines_generator_front.png"
}
minetest.register_node("sti_machines:generator", def_inactive)

-- Aktiven Generator registrieren
local def_active = table.copy(generator_def)
def_active.tiles = {
    "stimachines_generator_top.png", "stimachines_generator_bottom.png",
    "stimachines_generator_side.png", "stimachines_generator_side.png",
    "stimachines_generator_side.png", "stimachines_generator_front_active.png"
}
def_active.groups = {cracky = 2, technic_machine = 1, machine_power = 1, not_in_creative_inventory = 1}
def_active.light_source = 9
minetest.register_node("sti_machines:generator_active", def_active)

function sti_machines.draw_energy_from_node(pos, amount)
    local meta = minetest.get_meta(pos)
    if not meta then return 0 end

    local energy = meta:get_int("energy")
    if energy <= 0 then return 0 end

    local to_draw = math.min(energy, amount)
    meta:set_int("energy", energy - to_draw)

    local timer = minetest.get_node_timer(pos)
    if not timer:is_started() then timer:start(1.0) end

    return to_draw
end

-- =======================================================
-- FIX 2: LBM (Loading Block Modifier)
-- Startet den Timer neu, sobald die Welt/der Chunk geladen wird
-- =======================================================
minetest.register_lbm({
    name = "sti_machines:rekindle_generators",
    nodenames = {"sti_machines:generator", "sti_machines:generator_active"},
    run_at_every_load = true,
    action = function(pos, node)
        local timer = minetest.get_node_timer(pos)
        if not timer:is_started() then
            timer:start(1.0)
        end
    end,
})

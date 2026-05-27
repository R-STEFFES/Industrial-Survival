local tank = {}

-- =======================================================================
-- 1. GEOMETRISCHE MULTIBLOCK-ERKENNUNG
-- =======================================================================

function tank.check_and_calculate_tank(controller_pos)
    local current_node = minetest.get_node(controller_pos)

    local min_p = {x = controller_pos.x, y = controller_pos.y, z = controller_pos.z}
    local max_p = {x = controller_pos.x, y = controller_pos.y, z = controller_pos.z}

    local function is_tank_part(name)
        return name == "mytank:wall" or
               name == "mytank:glass" or
               name == "mytank:inlet" or
               name == "mytank:outlet" or
               name == "mytank:controller" or
               name == "mytank:controller_active"
    end

    local visited = {}
    local queue = {controller_pos}

    local function pos_to_string(pos)
        return pos.x .. "," .. pos.y .. "," .. pos.z
    end

    visited[pos_to_string(controller_pos)] = true

    local safety_limit = 3000
    local block_count = 0

    while #queue > 0 do
        local current_pos = table.remove(queue, 1)

        block_count = block_count + 1
        if block_count > safety_limit then
            break
        end

        min_p.x = math.min(min_p.x, current_pos.x)
        min_p.y = math.min(min_p.y, current_pos.y)
        min_p.z = math.min(min_p.z, current_pos.z)

        max_p.x = math.max(max_p.x, current_pos.x)
        max_p.y = math.max(max_p.y, current_pos.y)
        max_p.z = math.max(max_p.z, current_pos.z)

        for _, dir in ipairs({
            {x=1,y=0,z=0},
            {x=-1,y=0,z=0},
            {x=0,y=1,z=0},
            {x=0,y=-1,z=0},
            {x=0,y=0,z=1},
            {x=0,y=0,z=-1}
        }) do
            local next_pos = vector.add(current_pos, dir)
            local pos_str = pos_to_string(next_pos)

            if not visited[pos_str] then
                local node = minetest.get_node(next_pos)

                if is_tank_part(node.name) then
                    visited[pos_str] = true
                    table.insert(queue, next_pos)
                end
            end
        end
    end

    local size_x = (max_p.x - min_p.x) + 1
    local size_y = (max_p.y - min_p.y) + 1
    local size_z = (max_p.z - min_p.z) + 1

    if size_x < 3 or size_y < 3 or size_z < 3 then
        tank.set_tank_invalid(controller_pos, current_node)
        return false, {}
    end

    local air_blocks = {}
    local valid_structure = true

    for x = min_p.x, max_p.x do
        for y = min_p.y, max_p.y do
            for z = min_p.z, max_p.z do

                local current_pos = {x=x,y=y,z=z}
                local node = minetest.get_node(current_pos)

                local is_edge_x = (x == min_p.x or x == max_p.x)
                local is_edge_y = (y == min_p.y or y == max_p.y)
                local is_edge_z = (z == min_p.z or z == max_p.z)

                if is_edge_x and is_edge_y and is_edge_z then

                    if node.name ~= "mytank:wall" then
                        valid_structure = false
                        break
                    end

                elseif not is_edge_x and not is_edge_y and not is_edge_z then

                    if node.name == "air" then
                        table.insert(air_blocks, current_pos)
                    else
                        valid_structure = false
                        break
                    end

                else

                    if not is_tank_part(node.name) then
                        valid_structure = false
                        break
                    end
                end
            end

            if not valid_structure then
                break
            end
        end

        if not valid_structure then
            break
        end
    end

    if valid_structure and #air_blocks > 0 then

        local meta = minetest.get_meta(controller_pos)

        local total_capacity = #air_blocks * 8000

        meta:set_int("capacity", total_capacity)
        meta:set_int("block_size", #air_blocks)

        if current_node.name == "mytank:controller" then
            minetest.swap_node(controller_pos, {
                name = "mytank:controller_active",
                param1 = current_node.param1,
                param2 = current_node.param2
            })
        end

        tank.show_formspec(controller_pos, nil)
        tank.update_visuals(controller_pos, air_blocks)

        return true, air_blocks
    end

    tank.set_tank_invalid(controller_pos, current_node)
    return false, {}
end

function tank.set_tank_invalid(pos, current_node)
    local meta = minetest.get_meta(pos)

    meta:set_int("capacity", 0)
    meta:set_int("amount", 0)
    meta:set_int("block_size", 0)

    if current_node.name == "mytank:controller_active" then
        minetest.swap_node(pos, {
            name = "mytank:controller",
            param1 = current_node.param1,
            param2 = current_node.param2
        })
    end

    tank.show_formspec(pos, nil)
    tank.update_visuals(pos, nil)
end

-- =======================================================================
-- 2. AUTOMATISCHE EIMER-LOGIK
-- =======================================================================

function tank.process_items(pos)

    local meta = minetest.get_meta(pos)

    local capacity = meta:get_int("capacity")

    if capacity <= 0 then
        return
    end

    local inv = meta:get_inventory()

    local amount = meta:get_int("amount")
    local fluid = meta:get_string("fluid")

    local changed = false

    -- INPUT SLOT

    local input_stack = inv:get_stack("input", 1)

    if not input_stack:is_empty() then

        local item_name = input_stack:get_name()

        local detected_fluid = nil

        if item_name == "bucket:bucket_water" then
            detected_fluid = "water"

        elseif item_name == "bucket:bucket_river_water" then
            detected_fluid = "river_water"

        elseif item_name == "bucket:bucket_lava" then
            detected_fluid = "lava"
        end

        if detected_fluid and (capacity - amount >= 1000) then

            if fluid == "" or fluid == detected_fluid or amount == 0 then

                amount = amount + 1000

                fluid = detected_fluid

                meta:set_string("fluid", fluid)
                meta:set_int("amount", amount)

                inv:set_stack("input", 1, ItemStack("bucket:bucket_empty"))

                changed = true
            end
        end
    end

    -- OUTPUT SLOT

    local output_stack = inv:get_stack("output", 1)

    if not output_stack:is_empty()
    and output_stack:get_name() == "bucket:bucket_empty" then

        if amount >= 1000 and fluid ~= "" then

            local new_bucket = nil

            if fluid == "water" then
                new_bucket = "bucket:bucket_water"

            elseif fluid == "river_water" then
                new_bucket = "bucket:bucket_river_water"

            elseif fluid == "lava" then
                new_bucket = "bucket:bucket_lava"
            end

            if new_bucket then

                amount = amount - 1000

                if amount == 0 then
                    fluid = ""
                end

                meta:set_string("fluid", fluid)
                meta:set_int("amount", amount)

                inv:set_stack("output", 1, ItemStack(new_bucket))

                changed = true
            end
        end
    end

    if changed then
        tank.show_formspec(pos, nil)

        local _, air_blocks = tank.check_and_calculate_tank(pos)

        tank.update_visuals(pos, air_blocks)
    end
end

-- =======================================================================
-- 3. GUI
-- =======================================================================

function tank.show_formspec(pos, player_name)

    local meta = minetest.get_meta(pos)

    local fluid = meta:get_string("fluid")

    if fluid == "" then
        fluid = "Keine"
    end

    local amount = meta:get_int("amount")
    local capacity = meta:get_int("capacity")
    local block_size = meta:get_int("block_size")

    local inv = meta:get_inventory()

    if inv:get_size("input") == 0 then
        inv:set_size("input", 1)
    end

    if inv:get_size("output") == 0 then
        inv:set_size("output", 1)
    end

    if inv:get_size("storage") == 0 then
        inv:set_size("storage", 1)
    end

    local status = "STATUS: UNGUELTIG"

    if capacity > 0 then
        status = "STATUS: BEREIT (AKTIV)"
    end

    local formspec =
        "size[8,9]" ..
        "label[0.5,0.2;--- " .. status .. " ---]" ..
        "label[0.5,1.0;Flussigkeit: " .. fluid .. "]" ..
        "label[0.5,1.4;Inhalt: " .. amount .. " mb / " .. capacity .. " mb]" ..
        "label[0.5,1.8;Grose: " .. block_size .. " Blocke]" ..
        "box[0.5,2.4;7,0.3;#333333]"

    if capacity > 0 then

        local bar_width = (amount / capacity) * 7

        formspec = formspec ..
            "box[0.5,2.4;" .. bar_width .. ",0.3;#00d4ff]" ..
            "button[5.2,0.9;2.3,0.5;btn_connect;Neu messen]"

    else

        formspec = formspec ..
            "button[5.2,0.9;2.3,0.5;btn_connect;Connect]"
    end

    formspec = formspec ..

        "label[0.5,2.9;In Tank leeren:]" ..
        "list[context;input;0.5,3.4;1,1;]" ..

        "label[3.0,2.9;Aus Tank befullen:]" ..
        "list[context;output;3.0,3.4;1,1;]" ..

        "label[5.5,2.9;Trage-Slot / Lager:]" ..
        "list[context;storage;5.5,3.4;1,1;]" ..

        "list[current_player;main;0,4.8;8,1;]" ..
        "list[current_player;main;0,6.0;8,3;8]" ..

        "list_ring[current_player;main]" ..
        "list_ring[context;input]" ..
        "list_ring[context;output]" ..
        "list_ring[context;storage]"

    meta:set_string("formspec", formspec)

    if player_name then

        local formname =
            "mytank:controller_" ..
            pos.x .. "_" ..
            pos.y .. "_" ..
            pos.z

        minetest.show_formspec(
            player_name,
            formname,
            formspec
        )
    end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)

    local x, y, z =
        formname:match(
            "^mytank:controller_([%-%d]+)_([%-%d]+)_([%-%d]+)$"
        )

    if x and y and z then

        local pos = {
            x = tonumber(x),
            y = tonumber(y),
            z = tonumber(z)
        }

        local player_name = player:get_player_name()

        if fields.btn_connect then

            local success =
                tank.check_and_calculate_tank(pos)

            if success then
                minetest.chat_send_player(
                    player_name,
                    "[Tank] Struktur erfolgreich aufgebaut!"
                )
            else
                minetest.chat_send_player(
                    player_name,
                    "[Tank] Fehlerhafte Struktur!"
                )
            end

            tank.show_formspec(pos, player_name)
        end

        return true
    end
end)

-- =======================================================================
-- 4. NODES
-- =======================================================================

minetest.register_node("mytank:controller", {
    description = "Tank Controller",
    tiles = {"mytank_controller.png"},
    groups = {cracky = 2},

    on_construct = function(pos)

        local meta = minetest.get_meta(pos)

        meta:set_string("fluid", "")
        meta:set_int("amount", 0)
        meta:set_int("capacity", 0)
        meta:set_int("block_size", 0)

        local inv = meta:get_inventory()

        inv:set_size("input", 1)
        inv:set_size("output", 1)
        inv:set_size("storage", 1)

        tank.show_formspec(pos, nil)

        minetest.get_node_timer(pos):start(1.0)
    end,

    on_rightclick = function(pos, node, clicker)

        if clicker and clicker:is_player() then

            local timer =
                minetest.get_node_timer(pos)

            if not timer:is_started() then
                timer:start(1.0)
            end

            tank.show_formspec(
                pos,
                clicker:get_player_name()
            )
        end
    end,

    on_timer = function(pos)

        tank.process_items(pos)

        return true
    end,

    on_destruct = function(pos)
        tank.update_visuals(pos, nil)
    end
})

minetest.register_node("mytank:controller_active", {
    description = "Tank Controller Aktiv",
    tiles = {"mytank_controller_active.png"},
    light_source = 8,
    groups = {
        cracky = 2,
        not_in_creative_inventory = 1
    },

    on_rightclick = function(pos, node, clicker)

        if clicker and clicker:is_player() then

            local timer =
                minetest.get_node_timer(pos)

            if not timer:is_started() then
                timer:start(1.0)
            end

            tank.show_formspec(
                pos,
                clicker:get_player_name()
            )
        end
    end,

    on_timer = function(pos)

        tank.process_items(pos)

        return true
    end,

    on_destruct = function(pos)
        tank.update_visuals(pos, nil)
    end
})

minetest.register_node("mytank:wall", {
    description = "Tank Wand",
    tiles = {"mytank_wall.png"},
    groups = {cracky = 3}
})

minetest.register_node("mytank:glass", {
    description = "Tank Glas",
    drawtype = "glasslike",
    tiles = {"mytank_glass.png"},
    paramtype = "light",
    sunlight_propagates = true,
    use_texture_alpha = "clip",
    groups = {
        snappy = 3,
        cracky = 3
    }
})

minetest.register_node("mytank:inlet", {
    description = "Tank Einlass",
    tiles = {"mytank_inlet.png"},
    groups = {cracky = 3}
})

minetest.register_node("mytank:outlet", {
    description = "Tank Auslass",
    tiles = {"mytank_outlet.png"},
    groups = {cracky = 3}
})

-- =======================================================================
-- 5. FLUID DISPLAY
-- =======================================================================

minetest.register_entity("mytank:fluid_display", {

    initial_properties = {

        visual = "cube",

        textures = {
            "default_water.png",
            "default_water.png",
            "default_water.png",
            "default_water.png",
            "default_water.png",
            "default_water.png"
        },

        visual_size = {
            x = 1,
            y = 1,
            z = 1
        },

        physical = false,
        pointable = false
    },

    on_activate = function(self, staticdata)

        if staticdata and staticdata ~= "" then

            local data =
                minetest.deserialize(staticdata)

            if data then
                self.controller_pos = data.controller_pos
            end
        end
    end,

    get_staticdata = function(self)

        return minetest.serialize({
            controller_pos = self.controller_pos
        })
    end
})

function tank.update_visuals(controller_pos, air_blocks)

    local meta = minetest.get_meta(controller_pos)

    local amount = meta:get_int("amount")
    local capacity = meta:get_int("capacity")

    if capacity == 0
    or amount == 0
    or not air_blocks
    or #air_blocks == 0 then

        local objects =
            minetest.get_objects_inside_radius(
                controller_pos,
                20
            )

        for _, obj in ipairs(objects) do

            local ent = obj:get_luaentity()

            if ent
            and ent.name == "mytank:fluid_display"
            and ent.controller_pos
            and vector.equals(
                ent.controller_pos,
                controller_pos
            ) then
                obj:remove()
            end
        end

        return
    end

    local min_p = {
        x = air_blocks[1].x,
        y = air_blocks[1].y,
        z = air_blocks[1].z
    }

    local max_p = {
        x = air_blocks[1].x,
        y = air_blocks[1].y,
        z = air_blocks[1].z
    }

    for _, p in ipairs(air_blocks) do

        min_p.x = math.min(min_p.x, p.x)
        min_p.y = math.min(min_p.y, p.y)
        min_p.z = math.min(min_p.z, p.z)

        max_p.x = math.max(max_p.x, p.x)
        max_p.y = math.max(max_p.y, p.y)
        max_p.z = math.max(max_p.z, p.z)
    end

    local center = {
        x = min_p.x + (max_p.x - min_p.x) / 2,
        y = min_p.y + (max_p.y - min_p.y) / 2,
        z = min_p.z + (max_p.z - min_p.z) / 2
    }

    local size_x = (max_p.x - min_p.x) + 1
    local size_y = (max_p.y - min_p.y) + 1
    local size_z = (max_p.z - min_p.z) + 1

    local fill_ratio = amount / capacity

    local current_visual_y =
        size_y * fill_ratio

    center.y =
        min_p.y - 0.5 +
        (current_visual_y / 2)

    local fluid_obj = nil

    local objects =
        minetest.get_objects_inside_radius(
            controller_pos,
            20
        )

    for _, obj in ipairs(objects) do

        local ent = obj:get_luaentity()

        if ent
        and ent.name == "mytank:fluid_display"
        and ent.controller_pos
        and vector.equals(
            ent.controller_pos,
            controller_pos
        ) then
            fluid_obj = obj
            break
        end
    end

    if not fluid_obj then

        fluid_obj =
            minetest.add_entity(
                center,
                "mytank:fluid_display"
            )

        if fluid_obj then
            fluid_obj:get_luaentity().controller_pos =
                controller_pos
        end
    end

    if fluid_obj then

        local fluid =
            meta:get_string("fluid")

        local texture = "default_water.png"

        if fluid == "water" then
            texture = "default_water.png"

        elseif fluid == "river_water" then
            texture = "default_river_water.png"

        elseif fluid == "lava" then
            texture = "default_lava.png"
        end

        fluid_obj:set_pos(center)

        fluid_obj:set_properties({

            textures = {
                texture,
                texture,
                texture,
                texture,
                texture,
                texture
            },

            visual_size = {
                x = size_x - 0.01,
                y = math.max(
                    0.01,
                    current_visual_y - 0.01
                ),
                z = size_z - 0.01
            }
        })
    end
end

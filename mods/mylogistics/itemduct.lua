-- =======================================================================
-- ITEMDUCT SYSTEM WITH PATH-FINDING & PHYSICAL TRAVEL
-- =======================================================================

local function dir_to_string(dir)
    if dir.y == 1  then return "top"    end
    if dir.y == -1 then return "bottom" end
    if dir.x == 1  then return "right"  end
    if dir.x == -1 then return "left"   end
    if dir.z == 1  then return "back"   end
    if dir.z == -1 then return "front"  end
    return "unknown"
end

local ALL_DIRS = {
    {x=0,y=1,z=0}, {x=0,y=-1,z=0},
    {x=1,y=0,z=0}, {x=-1,y=0,z=0},
    {x=0,y=0,z=1}, {x=0,y=0,z=-1},
}

-- Mapping von Richtung zu Luantis Kachel-Index {up, down, right, left, back, front}
local TILE_INDICES = {
    top    = 1,
    bottom = 2,
    right  = 3,
    left   = 4,
    back   = 5,
    front  = 6
}

-- Gegenüberliegende Richtungen für die korrekte Texturprojektion
local OPPOSITE_DIRS = {
    top    = "bottom",
    bottom = "top",
    right  = "left",
    left   = "right",
    back   = "front",
    front  = "back"
}

local DIRS_DATA = {
    top    = {dir = {x=0,  y=1,  z=0},  box = {-0.25,  0.35, -0.25,  0.25,  0.50,  0.25}, steg = {-0.15,  0.15, -0.15,  0.15,  0.35,  0.15}},
    bottom = {dir = {x=0,  y=-1, z=0},  box = {-0.25, -0.50, -0.25,  0.25, -0.35,  0.25}, steg = {-0.15, -0.35, -0.15,  0.15, -0.15,  0.15}},
    right  = {dir = {x=1,  y=0,  z=0},  box = { 0.35, -0.25, -0.25,  0.50,  0.25,  0.25}, steg = { 0.15, -0.15, -0.15,  0.35,  0.15,  0.15}},
    left   = {dir = {x=-1, y=0,  z=0},  box = {-0.50, -0.25, -0.25, -0.35,  0.25,  0.25}, steg = {-0.35, -0.15, -0.15, -0.15,  0.15,  0.15}},
    back   = {dir = {x=0,  y=0,  z=1},  box = {-0.25, -0.25,  0.35,  0.25,  0.25,  0.50}, steg = {-0.15, -0.15,  0.15,  0.15,  0.15,  0.35}},
    front  = {dir = {x=0,  y=0,  z=-1}, box = {-0.25, -0.25, -0.50,  0.25,  0.25, -0.35}, steg = {-0.15, -0.15, -0.35,  0.15,  0.15, -0.15}},
}

local connected_nodebox_template = {
    type = "connected",
    connect_top    = { {-0.15,  0.15, -0.15, 0.15, 0.5,  0.15} },
    connect_bottom = { {-0.15, -0.5,  -0.15, 0.15, -0.15, 0.15} },
    connect_front  = { {-0.15, -0.15, -0.5,  0.15, 0.15, -0.15} },
    connect_back   = { {-0.15, -0.15,  0.15, 0.15, 0.15,  0.5 } },
    connect_left   = { {-0.5,  -0.15, -0.15, -0.15, 0.15, 0.15} },
    connect_right  = { { 0.15, -0.15, -0.15, 0.5,  0.15, 0.15} },
}

local DUCT_TYPES = {
    { suffix = "", desc = "Itemduct", tiles = { "mylogistics_itemduct.png" }, alpha = nil },
    { suffix = "_transparent", desc = "Transparentes Itemduct", tiles = { "mylogistics_itemduct_transparent.png" }, alpha = "blend" }
}

-- =========================================================
-- Inventar-Helfer
-- =========================================================
local function get_inventory_at(pos)
    local meta = minetest.get_meta(pos)
    if not meta then return nil end
    local inv = meta:get_inventory()
    if not inv then return nil end
    local lists = inv:get_lists()
    if lists.main or lists.input or lists.output or lists.src or lists.dst or lists.fuel then
        return inv
    end
    return nil
end

local function get_target_list(inv, is_source)
    local lists = inv:get_lists()
    if is_source then
        if lists.output then return "output" end
        if lists.dst    then return "dst"    end
        if lists.main   then return "main"   end
    else
        if lists.input  then return "input"  end
        if lists.src    then return "src"    end
        if lists.main   then return "main"   end
    end
    return nil
end

local function get_container_direction(pos)
    for _, dir in ipairs(ALL_DIRS) do
        local p = vector.add(pos, dir)
        local node = minetest.get_node(p)
        if minetest.get_item_group(node.name, "itemduct") == 0 then
            if get_inventory_at(p) then
                return dir
            end
        end
    end
    return nil
end

local function get_item_texture(item_name)
    local def = minetest.registered_items[item_name]
    if not def then return "unknown_node.png" end

    if def.inventory_image and def.inventory_image ~= "" then
        return def.inventory_image
    elseif def.tiles and def.tiles[1] then
        if type(def.tiles[1]) == "string" then
            return def.tiles[1]
        elseif type(def.tiles[1]) == "table" and def.tiles[1].name then
            return def.tiles[1].name
        end
    end
    return "unknown_node.png"
end

-- =========================================================
-- Netzwerk-Traversierung
-- =========================================================
local function find_network_destinations(start_pos, chest_dir)
    local visited = {}
    local queue   = {}
    local destinations = {}

    visited[minetest.pos_to_string(start_pos)] = true

    local source_chest_pos = vector.add(start_pos, chest_dir)
    visited[minetest.pos_to_string(source_chest_pos)] = true

    for _, dir in ipairs(ALL_DIRS) do
        if not vector.equals(dir, chest_dir) then
            local neighbor = vector.add(start_pos, dir)
            local key = minetest.pos_to_string(neighbor)
            if not visited[key] then
                visited[key] = true
                table.insert(queue, { pos = neighbor, path = { start_pos, neighbor } })
            end
        end
    end

    while #queue > 0 do
        local current = table.remove(queue, 1)
        local pos = current.pos
        local path = current.path
        local node = minetest.get_node(pos)

        if minetest.get_item_group(node.name, "itemduct") > 0 then
            for _, dir in ipairs(ALL_DIRS) do
                local neighbor = vector.add(pos, dir)
                local key = minetest.pos_to_string(neighbor)
                if not visited[key] then
                    visited[key] = true
                    local new_path = { unpack(path) }
                    table.insert(new_path, neighbor)
                    table.insert(queue, { pos = neighbor, path = new_path })
                end
            end
        else
            local inv = get_inventory_at(pos)
            if inv then
                table.insert(destinations, { pos = pos, path = path })
            end
        end
    end

    return destinations
end

-- =========================================================
-- VISUELLER EFFEKT: 2 Sekunden pro Block Reisegeschwindigkeit
-- =========================================================
local step_duration = 2.0

local function animate_item_travel(path, item_name)
    local texture_file = get_item_texture(item_name)

    for i = 1, #path - 1 do
        local p1 = path[i]
        local p2 = path[i+1]

        minetest.after((i - 1) * step_duration, function()
            local dir = vector.direction(p1, p2)
            local vel = vector.multiply(dir, 1 / step_duration)

            minetest.add_particle({
                pos = p1,
                velocity = vel,
                acceleration = {x=0, y=0, z=0},
                expirationtime = step_duration,
                size = 3.0,
                collisiondetection = false,
                vertical = false,
                texture = texture_file,
                glow = 10,
            })
        end)
    end
end

-- =========================================================
-- Formspec GUI (MIT AUTOMATISCHER 9-SLOT-MIGRATION)
-- =========================================================
local function open_upgrade_formspec(pos, player, upgrade_type, dir_str)
    local pos_string = pos.x .. "," .. pos.y .. "," .. pos.z
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()

    -- FIX: Automatische Migration für bereits in der Welt platzierte Rohre!
    if upgrade_type == "servo" and inv:get_size("servo_filter") ~= 9 then
        inv:set_size("servo_filter", 9)
    elseif upgrade_type == "filter" and inv:get_size("filter_slot") ~= 9 then
        inv:set_size("filter_slot", 9)
    end

    -- Fenstergröße für das 3x3 Gitter
    local formspec = "size[8,9.6]" ..
        "label[0,0;Upgrade am Rohr (" .. string.upper(dir_str) .. ")]"

    local filter_mode = meta:get_int("filter_mode")
    local filter_text = (filter_mode == 1) and "Modus: Blacklist" or "Modus: Whitelist"

    if upgrade_type == "servo" then
        local mode = meta:get_int("servo_active")
        local mode_text = (mode == 1) and "Aktiv (Extraktion)" or "Deaktiviert (Passiv)"

        formspec = formspec ..
            "button[0,0.6;3.8,0.8;toggle_servo;" .. mode_text .. "]" ..
            "button[4,0.6;3.8,0.8;toggle_filter_mode;" .. filter_text .. "]" ..
            "label[0,1.6;Filter-Slots (3x3):]" ..
            "list[nodemeta:" .. pos_string .. ";servo_filter;0,2.1;3,3;]"
    elseif upgrade_type == "filter" then
        formspec = formspec ..
            "button[0,0.6;3.8,0.8;toggle_filter_mode;" .. filter_text .. "]" ..
            "label[0,1.6;Filter-Slots (3x3):]" ..
            "list[nodemeta:" .. pos_string .. ";filter_slot;0,2.1;3,3;]"
    end

    formspec = formspec ..
        "list[current_player;main;0,5.4;8,4;]" ..
        "listring[nodemeta:" .. pos_string .. ";" .. (upgrade_type == "servo" and "servo_filter" or "filter_slot") .. "]" ..
        "listring[current_player;main]"

    minetest.show_formspec(
        player:get_player_name(),
        "mylogistics:upgrade_" .. pos_string,
        formspec
    )
end

-- =======================================================================
-- CRAFTITEMS
-- =======================================================================

minetest.register_craftitem("mylogistics:servo", {
    description = "Servo\nRechtsklicke ein Rohr neben einer Kiste, um es anzuheften.",
    inventory_image = "mylogistics_servo.png",

    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end
        local pos  = pointed_thing.under
        local node = minetest.get_node(pos)

        if minetest.get_item_group(node.name, "itemduct") == 0 then return itemstack end

        local dir = get_container_direction(pos)
        if not dir then
            minetest.chat_send_player(placer:get_player_name(), "Keine Kiste am Rohr gefunden!")
            return itemstack
        end

        local dir_str = dir_to_string(dir)
        local is_trans = string.find(node.name, "_transparent") and "_transparent" or ""

        minetest.swap_node(pos, {name = "mylogistics:itemduct" .. is_trans .. "_servo_" .. dir_str})
        local meta = minetest.get_meta(pos)
        meta:set_int("servo_active", 1)
        meta:set_int("filter_mode", 1)
        meta:set_string("direction", dir_str)

        local inv = meta:get_inventory()
        inv:set_size("servo_filter", 9)

        minetest.chat_send_player(placer:get_player_name(), "Servo zur Kiste installiert!")
        if not minetest.settings:get_bool("creative_mode") then itemstack:take_item() end
        return itemstack
    end,
})

minetest.register_craftitem("mylogistics:filter", {
    description = "Filter\nRechtsklicke ein Rohr neben einer Kiste, um es anzuheften.",
    inventory_image = "mylogistics_filter.png",

    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end
        local pos  = pointed_thing.under
        local node = minetest.get_node(pos)

        if minetest.get_item_group(node.name, "itemduct") == 0 then return itemstack end

        local dir = get_container_direction(pos)
        if not dir then
            minetest.chat_send_player(placer:get_player_name(), "Keine Kiste am Rohr gefunden!")
            return itemstack
        end

        local dir_str = dir_to_string(dir)
        local is_trans = string.find(node.name, "_transparent") and "_transparent" or ""

        minetest.swap_node(pos, {name = "mylogistics:itemduct" .. is_trans .. "_filter_" .. dir_str})
        local meta = minetest.get_meta(pos)
        meta:set_int("filter_mode", 0)
        meta:set_string("direction", dir_str)

        local inv  = meta:get_inventory()
        inv:set_size("filter_slot", 9)

        minetest.chat_send_player(placer:get_player_name(), "Filter zur Kiste installiert!")
        if not minetest.settings:get_bool("creative_mode") then itemstack:take_item() end
        return itemstack
    end,
})

-- =======================================================================
-- PIPELINE NODES
-- =======================================================================

for _, t in ipairs(DUCT_TYPES) do
    minetest.register_node("mylogistics:itemduct" .. t.suffix, {
        description = t.desc,
        drawtype = "nodebox",
        paramtype = "light",
        sunlight_propagates = true,
        use_texture_alpha = t.alpha,
        tiles = t.tiles,
        groups = { cracky = 3, oddly_breakable_by_hand = 2, itemduct = 1 },
        node_box = {
            type = "connected",
            fixed = { {-0.15, -0.15, -0.15, 0.15, 0.15, 0.15} },
            connect_top    = connected_nodebox_template.connect_top,
            connect_bottom = connected_nodebox_template.connect_bottom,
            connect_front  = connected_nodebox_template.connect_front,
            connect_back   = connected_nodebox_template.connect_back,
            connect_left   = connected_nodebox_template.connect_left,
            connect_right  = connected_nodebox_template.connect_right,
        },
        connect_sides = { "top", "bottom", "front", "back", "left", "right" },
        connects_to = {
            "group:itemduct",
            "group:machine_item",
            "default:chest", "default:chest_locked",
            "default:furnace", "default:furnace_active",
        },
    })

    for dname, data in pairs(DIRS_DATA) do
        local opposite_direction = OPPOSITE_DIRS[dname]
        local servo_side = TILE_INDICES[opposite_direction]

        local servo_tiles = { t.tiles[1], t.tiles[1], t.tiles[1], t.tiles[1], t.tiles[1], t.tiles[1] }
        servo_tiles[servo_side] = "mylogistics_itemduct_servo.png"

        minetest.register_node("mylogistics:itemduct" .. t.suffix .. "_servo_" .. dname, {
            description = t.desc .. " mit Servo",
            drawtype = "nodebox",
            paramtype = "light",
            sunlight_propagates = true,
            use_texture_alpha = t.alpha,
            tiles = servo_tiles,
            groups = { cracky = 3, itemduct = 1, itemduct_servo = 1, not_in_creative_inventory = 1 },
            drop = "mylogistics:itemduct" .. t.suffix,
            node_box = {
                type = "connected",
                fixed = {
                    {-0.15, -0.15, -0.15,  0.15, 0.15,  0.15},
                    data.box, data.steg
                },
                connect_top    = connected_nodebox_template.connect_top,
                connect_bottom = connected_nodebox_template.connect_bottom,
                connect_front  = connected_nodebox_template.connect_front,
                connect_back   = connected_nodebox_template.connect_back,
                connect_left   = connected_nodebox_template.connect_left,
                connect_right  = connected_nodebox_template.connect_right,
            },
            connect_sides = { "top", "bottom", "front", "back", "left", "right" },
            connects_to = {
                "group:itemduct",
                "default:chest", "default:chest_locked",
                "default:furnace", "default:furnace_active",
            },
            on_rightclick = function(pos, node, clicker)
                if not clicker or not clicker:is_player() then return end
                open_upgrade_formspec(pos, clicker, "servo", dname)
            end,
        })

        local filter_tiles = { t.tiles[1], t.tiles[1], t.tiles[1], t.tiles[1], t.tiles[1], t.tiles[1] }
        filter_tiles[servo_side] = "mylogistics_itemduct_filter.png"

        minetest.register_node("mylogistics:itemduct" .. t.suffix .. "_filter_" .. dname, {
            description = t.desc .. " mit Filter",
            drawtype = "nodebox",
            paramtype = "light",
            sunlight_propagates = true,
            use_texture_alpha = t.alpha,
            tiles = filter_tiles,
            groups = { cracky = 3, itemduct = 1, itemduct_filter = 1, not_in_creative_inventory = 1 },
            drop = "mylogistics:itemduct" .. t.suffix,
            node_box = {
                type = "connected",
                fixed = {
                    {-0.15, -0.15, -0.15,  0.15, 0.15,  0.15},
                    data.box, data.steg
                },
                connect_top    = connected_nodebox_template.connect_top,
                connect_bottom = connected_nodebox_template.connect_bottom,
                connect_front  = connected_nodebox_template.connect_front,
                connect_back   = connected_nodebox_template.connect_back,
                connect_left   = connected_nodebox_template.connect_left,
                connect_right  = connected_nodebox_template.connect_right,
            },
            connect_sides = { "top", "bottom", "front", "back", "left", "right" },
            connects_to = {
                "group:itemduct",
                "default:chest", "default:chest_locked",
                "default:furnace", "default:furnace_active",
            },
            on_rightclick = function(pos, node, clicker)
                if not clicker or not clicker:is_player() then return end
                open_upgrade_formspec(pos, clicker, "filter", dname)
            end,
        })
    end
end

-- =======================================================================
-- TRANSPORT LOGIK
-- =======================================================================

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 1.0 then return end
    timer = 0

    local processed = {}

    for _, player in ipairs(minetest.get_connected_players()) do
        local p = player:get_pos()
        local servos = minetest.find_nodes_in_area(
            {x=p.x-30, y=p.y-30, z=p.z-30},
            {x=p.x+30, y=p.y+30, z=p.z+30},
            {"group:itemduct_servo"}
        )

        for _, pos in ipairs(servos) do
            local key = minetest.pos_to_string(pos)
            if not processed[key] then
                processed[key] = true

                local meta = minetest.get_meta(pos)
                if meta:get_int("servo_active") ~= 1 then goto continue end

                local dname = meta:get_string("direction")
                local rdata = DIRS_DATA[dname]
                if not rdata then goto continue end
                local dir = rdata.dir

                local source_pos = vector.add(pos, dir)
                local source_inv = get_inventory_at(source_pos)
                if not source_inv then goto continue end

                local source_list = get_target_list(source_inv, true)
                if not source_list then goto continue end

                local servo_inv = meta:get_inventory()
                local filter_mode = meta:get_int("filter_mode")

                local item_stack = nil
                local item_slot  = nil

                for i = 1, source_inv:get_size(source_list) do
                    local s = source_inv:get_stack(source_list, i)
                    if not s:is_empty() then

                        local has_filter_items = false
                        local matches = false
                        for f = 1, 9 do
                            local f_stack = servo_inv:get_stack("servo_filter", f)
                            if f_stack and not f_stack:is_empty() then
                                has_filter_items = true
                                if f_stack:get_name() == s:get_name() then
                                    matches = true
                                    break
                                end
                            end
                        end

                        local item_allowed = true
                        if has_filter_items then
                            if filter_mode == 0 then
                                item_allowed = matches
                            else
                                item_allowed = not matches
                            end
                        else
                            item_allowed = (filter_mode == 1)
                        end

                        if item_allowed then
                            item_stack = s
                            item_slot  = i
                            break
                        end
                    end
                end
                if not item_stack then goto continue end

                local destinations = find_network_destinations(pos, dir)

                for _, dest in ipairs(destinations) do
                    local dest_pos = dest.pos
                    local dest_inv  = get_inventory_at(dest_pos)
                    if not dest_inv then goto next_dest_node end

                    local dest_list = get_target_list(dest_inv, false)
                    if not dest_list then goto next_dest_node end

                    local is_allowed = true
                    for _, fdir in ipairs(ALL_DIRS) do
                        local pipe_pos  = vector.add(dest_pos, fdir)
                        local pipe_node = minetest.get_node(pipe_pos)
                        if minetest.get_item_group(pipe_node.name, "itemduct_filter") > 0 then
                            local pipe_meta   = minetest.get_meta(pipe_pos)
                            local pipe_inv    = pipe_meta:get_inventory()
                            local f_mode      = pipe_meta:get_int("filter_mode")

                            local has_f_items = false
                            local f_matches = false
                            for f = 1, 9 do
                                local f_stack = pipe_inv:get_stack("filter_slot", f)
                                if f_stack and not f_stack:is_empty() then
                                    has_f_items = true
                                    if f_stack:get_name() == item_stack:get_name() then
                                        f_matches = true
                                        break
                                    end
                                end
                            end

                            local current_filter_allowed = true
                            if has_f_items then
                                if f_mode == 0 then
                                    current_filter_allowed = f_matches
                                else
                                    current_filter_allowed = not f_matches
                                end
                            else
                                current_filter_allowed = (f_mode == 1)
                            end

                            if not current_filter_allowed then
                                is_allowed = false
                                break
                            end
                        end
                    end

                    if not is_allowed then goto next_dest_node end

                    local item_to_send = ItemStack(item_stack)
                    item_to_send:set_count(1)

                    if dest_inv:room_for_item(dest_list, item_to_send) then
                        item_stack:take_item(1)
                        source_inv:set_stack(source_list, item_slot, item_stack)

                        animate_item_travel(dest.path, item_to_send:get_name())

                        local total_travel_time = (#dest.path - 1) * step_duration

                        minetest.after(total_travel_time, function()
                            local current_dest_inv = get_inventory_at(dest_pos)
                            if current_dest_inv then
                                local current_dest_list = get_target_list(current_dest_inv, false)
                                if current_dest_list and current_dest_inv:room_for_item(current_dest_list, item_to_send) then
                                    current_dest_inv:add_item(current_dest_list, item_to_send)
                                    return
                                end
                            end
                            minetest.add_item(dest_pos, item_to_send)
                        end)
                        break
                    end

                    ::next_dest_node::
                end

                ::continue::
            end
        end
    end
end)

-- =======================================================================
-- FORMSPEC CALLBACKS
-- =======================================================================
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if string.sub(formname, 1, 20) ~= "mylogistics:upgrade_" then return end
    local pos_str = string.sub(formname, 21)
    local pos = minetest.string_to_pos(pos_str)
    if not pos then return end

    local meta = minetest.get_meta(pos)
    local dstr = meta:get_string("direction")
    local node = minetest.get_node(pos)

    local upgrade_type = "servo"
    if minetest.get_item_group(node.name, "itemduct_filter") > 0 then
        upgrade_type = "filter"
    end

    if fields.toggle_servo and upgrade_type == "servo" then
        local current = meta:get_int("servo_active")
        meta:set_int("servo_active", (current == 1) and 0 or 1)
        open_upgrade_formspec(pos, player, "servo", dstr)
    elseif fields.toggle_filter_mode then
        local current = meta:get_int("filter_mode")
        meta:set_int("filter_mode", (current == 1) and 0 or 1)
        open_upgrade_formspec(pos, player, upgrade_type, dstr)
    end
end)

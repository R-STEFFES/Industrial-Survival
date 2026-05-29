-- =======================================================================
-- ITEMDUCT SYSTEM
-- =======================================================================

-- BUG-FIX #1: Minetests facedir (param2 0-5) gibt die Richtung an, in die
-- der VORDERSEITE des Knotens zeigt. Die Zuordnung war komplett falsch.
--   0 = Süden  (z=-1)
--   1 = Westen (x=-1)
--   2 = Norden (z=+1)
--   3 = Osten  (x=+1)
--   4 = Nach oben   (y=+1)  [selten genutzt]
--   5 = Nach unten  (y=-1)  [selten genutzt]
local facedir_to_dir = {
    [0] = {x=0,  y=0,  z=-1}, -- Süden
    [1] = {x=-1, y=0,  z=0},  -- Westen
    [2] = {x=0,  y=0,  z=1},  -- Norden
    [3] = {x=1,  y=0,  z=0},  -- Osten
    [4] = {x=0,  y=1,  z=0},  -- Oben
    [5] = {x=0,  y=-1, z=0},  -- Unten
}

local function dir_to_facedir(dir)
    if dir.z == -1 then return 0 end
    if dir.x == -1 then return 1 end
    if dir.z == 1  then return 2 end
    if dir.x == 1  then return 3 end
    if dir.y == 1  then return 4 end
    if dir.y == -1 then return 5 end
    return 0
end

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

-- Findet den ersten benachbarten Nicht-Rohr-Container eines Rohrknotens
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

-- =========================================================
-- BUG-FIX #2: Netzwerk-Traversierung (Flood-Fill)
-- Das alte System schaute nur 1 Block weit. Jetzt wird das gesamte
-- zusammenhängende Rohrnetz per Breitensuche durchsucht und alle
-- angeschlossenen Ziel-Container gesammelt.
-- =========================================================
local function find_network_destinations(start_pos, source_dir)
    local visited = {}
    local queue   = {}
    local destinations = {}

    -- Startpunkt: alle Nachbarn des Servos außer die Quell-Kiste
    for _, dir in ipairs(ALL_DIRS) do
        -- Quellrichtung überspringen (da ist die Kiste, aus der wir saugen)
        if not vector.equals(dir, source_dir) then
            local neighbor = vector.add(start_pos, dir)
            local key = minetest.pos_to_string(neighbor)
            if not visited[key] then
                visited[key] = true
                table.insert(queue, neighbor)
            end
        end
    end

    while #queue > 0 do
        local pos = table.remove(queue, 1)
        local node = minetest.get_node(pos)

        if minetest.get_item_group(node.name, "itemduct") > 0 then
            -- Es ist ein Rohr → Nachbarn in die Queue aufnehmen
            for _, dir in ipairs(ALL_DIRS) do
                local neighbor = vector.add(pos, dir)
                local key = minetest.pos_to_string(neighbor)
                if not visited[key] then
                    visited[key] = true
                    table.insert(queue, neighbor)
                end
            end
        else
            -- Kein Rohr → prüfen ob hier ein Inventar ist
            local inv = get_inventory_at(pos)
            if inv then
                table.insert(destinations, pos)
            end
        end
    end

    return destinations
end

-- =========================================================
-- Formspec GUI
-- =========================================================
local function open_upgrade_formspec(pos, player, upgrade_type, dir_str)
    local pos_string = pos.x .. "," .. pos.y .. "," .. pos.z

    local formspec = "size[8,8.5]" ..
        "label[0,0;Upgrade am Rohr (" .. string.upper(dir_str) .. ")]"

    if upgrade_type == "servo" then
        local meta = minetest.get_meta(pos)
        local mode = meta:get_int("servo_active")
        local mode_text = (mode == 1) and "Aktiv (Extraktion)" or "Deaktiviert (Passiv)"
        formspec = formspec .. "button[0,0.8;4,0.8;toggle_servo;" .. mode_text .. "]"
    elseif upgrade_type == "filter" then
        formspec = formspec ..
            "label[0,1.5;Filter-Slot (Nur dieses Item erlauben):]" ..
            "list[nodemeta:" .. pos_string .. ";filter_slot;0,2;1,1;]"
    end

    formspec = formspec ..
        "list[current_player;main;0,4.5;8,4;]" ..
        "listring[nodemeta:" .. pos_string .. ";filter_slot]" ..
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

        if node.name ~= "mylogistics:itemduct" then return itemstack end

        local dir = get_container_direction(pos)
        if not dir then
            minetest.chat_send_player(placer:get_player_name(), "Keine Kiste am Rohr gefunden!")
            return itemstack
        end

        minetest.swap_node(pos, {name = "mylogistics:itemduct_servo", param2 = dir_to_facedir(dir)})
        local meta = minetest.get_meta(pos)
        meta:set_int("servo_active", 1)
        meta:set_string("direction", dir_to_string(dir))

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

        if node.name ~= "mylogistics:itemduct" then return itemstack end

        local dir = get_container_direction(pos)
        if not dir then
            minetest.chat_send_player(placer:get_player_name(), "Keine Kiste am Rohr gefunden!")
            return itemstack
        end

        minetest.swap_node(pos, {name = "mylogistics:itemduct_filter", param2 = dir_to_facedir(dir)})
        local meta = minetest.get_meta(pos)
        local inv  = meta:get_inventory()
        inv:set_size("filter_slot", 1)
        meta:set_string("direction", dir_to_string(dir))

        minetest.chat_send_player(placer:get_player_name(), "Filter zur Kiste installiert!")
        if not minetest.settings:get_bool("creative_mode") then itemstack:take_item() end
        return itemstack
    end,
})

-- =======================================================================
-- PIPELINE NODES
-- =======================================================================

minetest.register_node("mylogistics:itemduct", {
    description = "Itemduct",
    drawtype = "nodebox",
    paramtype = "light",
    sunlight_propagates = true,
    tiles = { "mylogistics_itemduct.png" },
    groups = { cracky = 3, oddly_breakable_by_hand = 2, itemduct = 1 },
    node_box = {
        type = "connected",
        fixed = { {-0.15, -0.15, -0.15, 0.15, 0.15, 0.15} },
        connect_top    = { {-0.15,  0.15, -0.15, 0.15, 0.5,  0.15} },
        connect_bottom = { {-0.15, -0.5,  -0.15, 0.15, -0.15, 0.15} },
        connect_front  = { {-0.15, -0.15, -0.5,  0.15, 0.15, -0.15} },
        connect_back   = { {-0.15, -0.15,  0.15, 0.15, 0.15,  0.5 } },
        connect_left   = { {-0.5,  -0.15, -0.15, -0.15, 0.15, 0.15} },
        connect_right  = { { 0.15, -0.15, -0.15, 0.5,  0.15, 0.15} },
    },
    connect_sides = { "top", "bottom", "front", "back", "left", "right" },
    connects_to = {
        "group:itemduct",
        "default:chest", "default:chest_locked",
        "default:furnace", "default:furnace_active",
    },
})

local upgrade_nodebox = {
    type = "fixed",
    fixed = {
        {-0.15, -0.15, -0.15,  0.15, 0.15,  0.15}, -- Kern
        {-0.25, -0.25, -0.50,  0.25, 0.25, -0.35}, -- Manschette (zeigt zu Kiste)
        {-0.15, -0.15, -0.35,  0.15, 0.15, -0.15}, -- Steg
    }
}

minetest.register_node("mylogistics:itemduct_servo", {
    description = "Itemduct mit Servo",
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    tiles = {
        "mylogistics_itemduct.png",
        "mylogistics_itemduct.png",
        "mylogistics_itemduct.png",
        "mylogistics_itemduct.png",
        "mylogistics_itemduct.png",
        "mylogistics_itemduct_servo.png",
    },
    groups = { cracky = 3, itemduct = 1, not_in_creative_inventory = 1 },
    drop = "mylogistics:itemduct",
    node_box = upgrade_nodebox,
    connect_sides = { "top", "bottom", "front", "back", "left", "right" },
    connects_to = {
        "group:itemduct",
        "default:chest", "default:chest_locked",
        "default:furnace", "default:furnace_active",
    },

    on_rightclick = function(pos, node, clicker)
        if not clicker or not clicker:is_player() then return end
        open_upgrade_formspec(pos, clicker, "servo", minetest.get_meta(pos):get_string("direction"))
    end,
})

minetest.register_node("mylogistics:itemduct_filter", {
    description = "Itemduct mit Filter",
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    tiles = {
        "mylogistics_itemduct.png",
        "mylogistics_itemduct.png",
        "mylogistics_itemduct.png",
        "mylogistics_itemduct.png",
        "mylogistics_itemduct.png",
        "mylogistics_itemduct_filter.png",
    },
    groups = { cracky = 3, itemduct = 1, not_in_creative_inventory = 1 },
    drop = "mylogistics:itemduct",
    node_box = upgrade_nodebox,
    connect_sides = { "top", "bottom", "front", "back", "left", "right" },
    connects_to = {
        "group:itemduct",
        "default:chest", "default:chest_locked",
        "default:furnace", "default:furnace_active",
    },

    on_rightclick = function(pos, node, clicker)
        if not clicker or not clicker:is_player() then return end
        open_upgrade_formspec(pos, clicker, "filter", minetest.get_meta(pos):get_string("direction"))
    end,
})

-- =======================================================================
-- TRANSPORT LOGIK
-- =======================================================================

-- BUG-FIX #5: Deduplizierung — ein Set bereits verarbeiteter Servos
-- verhindert, dass ein Servo mehrfach pro Takt ausgeführt wird,
-- wenn mehrere Spieler in der Nähe sind.
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
            {"mylogistics:itemduct_servo"}
        )

        for _, pos in ipairs(servos) do
            local key = minetest.pos_to_string(pos)
            if not processed[key] then
                processed[key] = true

                local meta = minetest.get_meta(pos)
                if meta:get_int("servo_active") ~= 1 then goto continue end

                local node = minetest.get_node(pos)

                -- BUG-FIX #1: Korrekte facedir → Richtung Umrechnung
                local dir = facedir_to_dir[node.param2]
                if not dir then goto continue end

                -- Quell-Kiste in Richtung des Servos
                local source_pos = vector.add(pos, dir)
                local source_inv = get_inventory_at(source_pos)
                if not source_inv then goto continue end

                local source_list = get_target_list(source_inv, true)
                if not source_list then goto continue end

                -- Erstes nicht-leeres Item aus der Quelle suchen
                local item_stack = nil
                local item_slot  = nil
                for i = 1, source_inv:get_size(source_list) do
                    local s = source_inv:get_stack(source_list, i)
                    if not s:is_empty() then
                        item_stack = s
                        item_slot  = i
                        break
                    end
                end
                if not item_stack then goto continue end

                -- BUG-FIX #2: Gesamtes Rohrnetz nach Ziel-Containern absuchen
                -- source_dir ist die Richtung ZUR Quelle (also negiertes dir)
                local source_dir = vector.multiply(dir, -1)
                local destinations = find_network_destinations(pos, source_dir)

                for _, dest_pos in ipairs(destinations) do
                    local dest_inv  = get_inventory_at(dest_pos)
                    if not dest_inv then goto next_dest end

                    local dest_list = get_target_list(dest_inv, false)
                    if not dest_list then goto next_dest end

                    -- BUG-FIX #3: Filter-Prüfung am ZIEL-Knoten.
                    -- Korrekt: Wir prüfen, ob der Ziel-Container ein Rohr-NACHBAR
                    -- mit Filter ist, nicht den Container selbst.
                    local is_allowed = true
                    for _, fdir in ipairs(ALL_DIRS) do
                        local pipe_pos  = vector.add(dest_pos, fdir)
                        local pipe_node = minetest.get_node(pipe_pos)
                        if pipe_node.name == "mylogistics:itemduct_filter" then
                            local pipe_meta   = minetest.get_meta(pipe_pos)
                            local pipe_inv    = pipe_meta:get_inventory()
                            local filter_item = pipe_inv:get_stack("filter_slot", 1)
                            if not filter_item:is_empty()
                               and filter_item:get_name() ~= item_stack:get_name() then
                                is_allowed = false
                                break
                            end
                        end
                    end

                    if not is_allowed then goto next_dest end

                    -- BUG-FIX #4: room_for_item braucht einen ItemStack, keinen String
                    if dest_inv:room_for_item(dest_list, item_stack) then
                        local taken = item_stack:take_item(1)
                        dest_inv:add_item(dest_list, taken)
                        source_inv:set_stack(source_list, item_slot, item_stack)
                        break -- Nur 1 Item pro Takt transportieren
                    end

                    ::next_dest::
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

    if fields.toggle_servo then
        local meta    = minetest.get_meta(pos)
        local current = meta:get_int("servo_active")
        meta:set_int("servo_active", (current == 1) and 0 or 1)
        open_upgrade_formspec(pos, player, "servo", meta:get_string("direction"))
    end
end)

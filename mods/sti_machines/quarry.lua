-- =======================================================================
-- QUARRY (MINENBOHRER) - Mit Vorschau, 4 Upgrades (Unstapelbar) & Freiräumung
-- =======================================================================

-- Hilfsfunktion: Berechnet die exakten Min/Max Abmessungen basierend auf Blickrichtung
local function calculate_dimensions(pos, meta)
    local node = minetest.get_node(pos)
    local dir = minetest.facedir_to_dir(node.param2)
    local size_x = meta:get_int("size_x")
    local size_z = meta:get_int("size_z")
    local depth = meta:get_int("depth")

    local min_x, max_x, min_z, max_z

    if dir.x ~= 0 then
        if dir.x > 0 then
            min_x = pos.x + 2
            max_x = pos.x + 1 + size_x
        else
            max_x = pos.x - 2
            min_x = pos.x - 1 - size_x
        end
        min_z = pos.z - math.floor(size_z / 2)
        max_z = pos.z + math.floor(size_z / 2)
    else
        local z_dir = dir.z ~= 0 and dir.z or 1
        if z_dir > 0 then
            min_z = pos.z + 2
            max_z = pos.z + 1 + size_z
        else
            max_z = pos.z - 2
            min_z = pos.z - 1 - size_z
        end
        min_x = pos.x - math.floor(size_x / 2)
        max_x = pos.x + math.floor(size_x / 2)
    end

    local min_y = pos.y - depth
    local max_y = pos.y

    return min_x, max_x, min_y, max_y, min_z, max_z
end

-- Hilfsfunktion: Löscht alle platzierten Gerüstblöcke und alle Gantry-Entitäten
local function clear_quarry_frames(pos, meta)
    local queue_str = meta:get_string("frame_queue")
    if queue_str and queue_str ~= "" then
        local frame_queue = minetest.deserialize(queue_str)
        if frame_queue then
            for _, fpos in ipairs(frame_queue) do
                if minetest.get_node(fpos).name == "sti_machines:quarry_frame" then
                    minetest.remove_node(fpos)
                end
            end
        end
    end

    -- Alle Gantry/Bohrkopf-Entitäten im Umkreis suchen und entfernen
    for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 30)) do
        local ent = obj:get_luaentity()
        if ent and ent.quarry_pos and vector.equals(ent.quarry_pos, pos) then
            if ent.name == "sti_machines:gantry_x" or
               ent.name == "sti_machines:gantry_carrier" or
               ent.name == "sti_machines:drill_pipe" then
                obj:remove()
            end
        end
    end
end

-- Formspec-Aktualisierung
function sti_machines.update_quarry_formspec(pos)
    local meta = minetest.get_meta(pos)
    local energy = meta:get_int("energy")
    local max_energy = meta:get_int("max_energy")
    local size_x = meta:get_int("size_x")
    local size_z = meta:get_int("size_z")
    local depth = meta:get_int("depth")
    local status = meta:get_string("status")
    local limit_depth = meta:get_string("limit_depth")
    local preview = meta:get_string("preview_enabled")

    -- Aktuelles Range-Limit basierend auf den 4 Slots berechnen
    local inv = meta:get_inventory()
    local range_cards = 0
    if inv then
        for i = 1, 4 do
            local stack = inv:get_stack("upgrades", i)
            if stack:get_name() == "sti_machines:upgrade_range" then
                range_cards = range_cards + 1 -- Da unstackable reicht +1 pro Slot
            end
        end
    end
    local max_allowed_size = 16 * math.pow(2, range_cards)

    -- Status-Text übersetzen
    local status_msg = "Bereit."
    if status == "building" then status_msg = "Räume & Baue Gerüst..."
    elseif status == "building_full" then status_msg = "Gerüstbau blockiert: VOLL!"
    elseif status == "clearing" then status_msg = "Räume Innenraum frei..."
    elseif status == "clearing_full" then status_msg = "Innenraum blockiert: VOLL!"
    elseif status == "digging" then status_msg = "Gräbt..."
    elseif status == "full" then status_msg = "Inventar VOLL! (Warte...)"
    elseif status == "paused" then status_msg = "Pausiert."
    elseif status == "completed" then status_msg = "Abgesteckt/Fertig."
    end

    local formspec = "size[8,12.5]" ..
        "label[0.5,0.5;--- QUARRY (MINENBOHRER) ---]" ..

        -- Einstellungen
        "field[0.5,1.5;1.5,1;size_x;Breite (X);" .. size_x .. "]" ..
        "field[2.3,1.5;1.5,1;size_z;Länge (Z);" .. size_z .. "]"

    if limit_depth == "true" then
        formspec = formspec .. "field[4.1,1.5;1.5,1;depth;Tiefe (Y);" .. depth .. "]"
    else
        formspec = formspec .. "field[4.1,1.5;1.5,1;depth;Tiefe (Y);Unendlich]"
    end

    -- Dynamische Buttons
    if status == "idle" or status == "completed" then
        formspec = formspec .. "button[6.0,1.2;1.5,0.8;start;Start]"
        local preview_lbl = (preview == "true") and "Vorschau: AN" or "Vorschau: AUS"
        formspec = formspec .. "button[6.0,2.1;1.5,0.6;toggle_preview;" .. preview_lbl .. "]"
    elseif status == "paused" then
        formspec = formspec .. "button[6.0,1.2;1.5,0.6;resume;Fortsetzen]"
        formspec = formspec .. "button[6.0,2.0;1.5,0.6;stop;Stopp (Abbruch)]"
    else
        formspec = formspec .. "button[6.0,1.2;1.5,0.6;pause;Pause]"
        formspec = formspec .. "button[6.0,2.0;1.5,0.6;stop;Stopp (Abbruch)]"
    end

    local limit_btn_label = (limit_depth == "true") and "Limit: AN" or "Limit: AUS"
    formspec = formspec .. "button[4.1,2.3;1.5,0.6;toggle_depth;" .. limit_btn_label .. "]"

    formspec = formspec ..
        "label[0.5,2.7;Status: " .. status_msg .. " (Max. Größe: " .. max_allowed_size .. "x" .. max_allowed_size .. ")]" ..
        "label[0.5,3.2;Energie: " .. energy .. " / " .. max_energy .. " EU]" ..

        -- 4 Upgrade Slots (Kompakter angeordnet)
        "label[0.5,3.8;Erweiterungen (4 Slots max.):]" ..
        "list[context;upgrades;0.5,4.3;4,1;]" ..

        -- Ausgangs-Inventar
        "label[2.0,5.6;Geförderte Ressourcen:]" ..
        "list[context;dst;2,6.1;4,2;]" ..

        -- Spieler-Inventar
        "list[current_player;main;0,8.3;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;dst]" ..
        "listring[current_player;main]" ..
        "listring[context;upgrades]"

    meta:set_string("formspec", formspec)
end

local quarry_def = {
    description = "Quarry (Minenbohrer)",
    paramtype2 = "facedir",
    groups = {cracky = 2, technic_machine = 1, machine_item = 1},
    is_energy_consumer = true,

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("dst", 8)
        inv:set_size("upgrades", 4) -- Auf 4 Slots reduziert!

        meta:set_int("energy", 0)
        meta:set_int("max_energy", 60000)
        meta:set_int("energy_usage", 60)

        meta:set_int("size_x", 5)
        meta:set_int("size_z", 5)
        meta:set_int("depth", 20)
        meta:set_string("limit_depth", "false")
        meta:set_string("preview_enabled", "false")
        meta:set_string("status", "idle")
        meta:set_string("speed_acc", "0")

        sti_machines.update_quarry_formspec(pos)
    end,

    on_destruct = function(pos)
        local meta = minetest.get_meta(pos)
        clear_quarry_frames(pos, meta)
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "upgrades" then
            local meta = minetest.get_meta(pos)
            local status = meta:get_string("status")

            if status ~= "idle" and status ~= "completed" then
                if stack:get_name() == "sti_machines:upgrade_range" then
                    return 0 -- Sperre Range im Betrieb
                end
            end

            if stack:get_name() == "sti_machines:upgrade_range" or stack:get_name():find("sti_machines:upgrade_speed_") then
                return stack:get_count()
            end
            return 0
        end
        return stack:get_count()
    end,

    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if listname == "upgrades" then
            local meta = minetest.get_meta(pos)
            local status = meta:get_string("status")
            if status ~= "idle" and status ~= "completed" then
                if stack:get_name() == "sti_machines:upgrade_range" then
                    return 0 -- Lock Range Upgrade
                end
            end
        end
        return stack:get_count()
    end,

    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        local meta = minetest.get_meta(pos)
        local status = meta:get_string("status")
        if status ~= "idle" and status ~= "completed" then
            local inv = meta:get_inventory()
            if from_list == "upgrades" or to_list == "upgrades" then
                local stack = inv:get_stack(from_list, from_index)
                if stack:get_name() == "sti_machines:upgrade_range" then return 0 end
            end
        end
        return count
    end,

    on_receive_fields = function(pos, formname, fields, sender)
        local meta = minetest.get_meta(pos)
        local status = meta:get_string("status")
        local inv = meta:get_inventory()

        if fields.toggle_depth then
            if status == "idle" or status == "completed" then
                local current_limit = meta:get_string("limit_depth")
                meta:set_string("limit_depth", (current_limit == "true") and "false" or "true")
                sti_machines.update_quarry_formspec(pos)
            end
            return
        end

        if fields.toggle_preview then
            if status == "idle" or status == "completed" then
                local current = meta:get_string("preview_enabled")
                if current == "true" then
                    meta:set_string("preview_enabled", "false")
                else
                    meta:set_string("preview_enabled", "true")
                    minetest.get_node_timer(pos):start(1.0)
                end
                sti_machines.update_quarry_formspec(pos)
            end
            return
        end

        if fields.pause then
            if status == "building" or status == "building_full" or status == "clearing" or status == "clearing_full" or status == "digging" or status == "full" then
                meta:set_string("paused_status", status)
                meta:set_string("status", "paused")
                sti_machines.update_quarry_formspec(pos)
            end
            return
        end

        if fields.resume then
            if status == "paused" then
                local orig_status = meta:get_string("paused_status")
                if orig_status == "" then orig_status = "digging" end
                meta:set_string("status", orig_status)
                sti_machines.update_quarry_formspec(pos)
            end
            return
        end

        if status == "idle" or status == "completed" then
            local range_cards = 0
            for i = 1, 4 do
                local stack = inv:get_stack("upgrades", i)
                if stack:get_name() == "sti_machines:upgrade_range" then
                    range_cards = range_cards + 1
                end
            end
            local max_allowed_size = 16 * math.pow(2, range_cards)

            if fields.size_x then meta:set_int("size_x", math.max(3, math.min(max_allowed_size, tonumber(fields.size_x) or 5))) end
            if fields.size_z then meta:set_int("size_z", math.max(3, math.min(max_allowed_size, tonumber(fields.size_z) or 5))) end
            if fields.depth and meta:get_string("limit_depth") == "true" then
                meta:set_int("depth", math.max(1, math.min(256, tonumber(fields.depth) or 20)))
            end
        end

        -- START
        if fields.start and (status == "idle" or status == "completed") then
            meta:set_string("preview_enabled", "false")

            local min_x, max_x, min_y, max_y, min_z, max_z = calculate_dimensions(pos, meta)

            meta:set_int("min_x", min_x)
            meta:set_int("max_x", max_x)
            meta:set_int("min_y", min_y)
            meta:set_int("max_y", max_y)
            meta:set_int("min_z", min_z)
            meta:set_int("max_z", max_z)

            local frame_positions = {}
            local f_min_x = min_x - 1
            local f_max_x = max_x + 1
            local f_min_z = min_z - 1
            local f_max_z = max_z + 1

            -- Unterer Ring
            for x = f_min_x, f_max_x do
                table.insert(frame_positions, {x=x, y=pos.y, z=f_min_z})
                table.insert(frame_positions, {x=x, y=pos.y, z=f_max_z})
            end
            for z = f_min_z + 1, f_max_z - 1 do
                table.insert(frame_positions, {x=f_min_x, y=pos.y, z=z})
                table.insert(frame_positions, {x=f_max_x, y=pos.y, z=z})
            end

            -- Oberer Ring (Aufhängungshöhe pos.y + 3)
            for x = f_min_x, f_max_x do
                table.insert(frame_positions, {x=x, y=pos.y + 3, z=f_min_z})
                table.insert(frame_positions, {x=x, y=pos.y + 3, z=f_max_z})
            end
            for z = f_min_z + 1, f_max_z - 1 do
                table.insert(frame_positions, {x=f_min_x, y=pos.y + 3, z=z})
                table.insert(frame_positions, {x=f_max_x, y=pos.y + 3, z=z})
            end

            -- Ecksäulen
            for y = pos.y + 1, pos.y + 2 do
                table.insert(frame_positions, {x=f_min_x, y=y, z=f_min_z})
                table.insert(frame_positions, {x=f_max_x, y=y, z=f_min_z})
                table.insert(frame_positions, {x=f_min_x, y=y, z=f_max_z})
                table.insert(frame_positions, {x=f_max_x, y=y, z=f_max_z})
            end

            meta:set_string("frame_queue", minetest.serialize(frame_positions))
            meta:set_int("frame_index", 1)

            -- Initialwerte Abbau
            meta:set_int("cur_x", min_x)
            meta:set_int("cur_y", pos.y - 1)
            meta:set_int("cur_z", min_z)

            meta:set_string("status", "building")
            meta:set_string("speed_acc", "0")
            minetest.get_node_timer(pos):start(1.0)

        elseif fields.stop then
            clear_quarry_frames(pos, meta)
            meta:set_string("status", "idle")
            meta:set_string("preview_enabled", "false")
        end

        sti_machines.update_quarry_formspec(pos)
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local status = meta:get_string("status")
        local energy = meta:get_int("energy")
        local usage = meta:get_int("energy_usage")
        local node = minetest.get_node(pos)
        local preview = meta:get_string("preview_enabled") == "true"

        -- Vorschau-Modus (Grüne Punkte lückenlos)
        if status == "idle" or status == "completed" then
            if preview then
                local min_x, max_x, _, _, min_z, max_z = calculate_dimensions(pos, meta)
                local f_min_x = min_x - 1
                local f_max_x = max_x + 1
                local f_min_z = min_z - 1
                local f_max_z = max_z + 1
                local top_y = pos.y + 3
                local bottom_y = pos.y

                local function spawn_preview_dot(p)
                    minetest.add_particle({
                        pos = p,
                        velocity = {x=0, y=0, z=0},
                        acceleration = {x=0, y=0, z=0},
                        expirationtime = 1.0,
                        size = 4, glow = 14,
                        texture = "unknown_node.png^[resize:4x4^[colorize:#00ff00:255",
                    })
                end

                for x = f_min_x, f_max_x do
                    spawn_preview_dot({x=x, y=bottom_y, z=f_min_z})
                    spawn_preview_dot({x=x, y=bottom_y, z=f_max_z})
                    spawn_preview_dot({x=x, y=top_y, z=f_min_z})
                    spawn_preview_dot({x=x, y=top_y, z=f_max_z})
                end
                for z = f_min_z + 1, f_max_z - 1 do
                    spawn_preview_dot({x=f_min_x, y=bottom_y, z=z})
                    spawn_preview_dot({x=f_max_x, y=bottom_y, z=z})
                    spawn_preview_dot({x=f_min_x, y=top_y, z=z})
                    spawn_preview_dot({x=f_max_x, y=top_y, z=z})
                end
                for y = bottom_y + 1, top_y - 1 do
                    spawn_preview_dot({x=f_min_x, y=y, z=f_min_z})
                    spawn_preview_dot({x=f_max_x, y=y, z=f_min_z})
                    spawn_preview_dot({x=f_min_x, y=y, z=f_max_z})
                    spawn_preview_dot({x=f_max_x, y=y, z=f_max_z})
                end
                return true
            else
                return false
            end
        end

        -- Arbeits-Modus
        if status ~= "paused" then

            -- Blockaden vorab prüfen
            if status == "building_full" then
                local frame_queue = minetest.deserialize(meta:get_string("frame_queue"))
                local idx = meta:get_int("frame_index")
                if frame_queue and idx <= #frame_queue then
                    local current_node = minetest.get_node(frame_queue[idx])
                    local drops = minetest.get_node_drops(current_node.name, "")
                    local space_found = true
                    for _, drop in ipairs(drops) do
                        if not inv:room_for_item("dst", drop) then space_found = false; break end
                    end
                    if space_found then status = "building"; meta:set_string("status", "building") end
                end
            end

            if status == "clearing_full" then
                local cx = meta:get_int("clear_x")
                local cy = meta:get_int("clear_y")
                local cz = meta:get_int("clear_z")
                local current_node = minetest.get_node({x=cx, y=cy, z=cz})
                local drops = minetest.get_node_drops(current_node.name, "")
                local space_found = true
                for _, drop in ipairs(drops) do
                    if not inv:room_for_item("dst", drop) then space_found = false; break end
                end
                if space_found then status = "clearing"; meta:set_string("status", "clearing") end
            end

            if status == "full" then
                local cur_x = meta:get_int("cur_x")
                local cur_y = meta:get_int("cur_y")
                local cur_z = meta:get_int("cur_z")
                local next_node = minetest.get_node({x=cur_x, y=cur_y, z=cur_z})
                local drops = minetest.get_node_drops(next_node.name, "")
                local space_found = true
                for _, drop in ipairs(drops) do
                    if not inv:room_for_item("dst", drop) then space_found = false; break end
                end
                if space_found then status = "digging"; meta:set_string("status", "digging") end
            end

            -- Loop-Abarbeitung mit Geschwindigkeitskarten (1 bis 4)
            if status == "building" or status == "clearing" or status == "digging" then
                local speed_boost = 0
                local energy_boost = 0
                for i = 1, 4 do
                    local stack = inv:get_stack("upgrades", i)
                    local name = stack:get_name()
                    if name:find("sti_machines:upgrade_speed_") then
                        local lvl = tonumber(name:match("sti_machines:upgrade_speed_(%d+)"))
                        if lvl then
                            speed_boost = speed_boost + (lvl * 0.10)
                            energy_boost = energy_boost + (lvl * 0.20)
                        end
                    end
                end

                local speed_mult = 1.0 + speed_boost
                local energy_mult = 1.0 + energy_boost

                local speed_acc = tonumber(meta:get_string("speed_acc")) or 0
                speed_acc = speed_acc + speed_mult
                local operations = math.floor(speed_acc)
                speed_acc = speed_acc - operations
                meta:set_string("speed_acc", tostring(speed_acc))

                local current_usage = math.ceil(usage * energy_mult / speed_mult)

                for op = 1, operations do
                    status = meta:get_string("status")
                    energy = meta:get_int("energy")

                    if status ~= "building" and status ~= "clearing" and status ~= "digging" then break end
                    if energy < current_usage then break end

                    -- PHASE 1: Gerüstbau
                    if status == "building" then
                        local frame_queue = minetest.deserialize(meta:get_string("frame_queue"))
                        local idx = meta:get_int("frame_index")

                        if frame_queue and idx <= #frame_queue then
                            local fpos = frame_queue[idx]
                            local current_node = minetest.get_node(fpos)

                            if current_node.name ~= "air" and current_node.name ~= "ignore" and current_node.name ~= "sti_machines:quarry_frame" then
                                if not minetest.is_protected(fpos, "") then
                                    local drops = minetest.get_node_drops(current_node.name, "")
                                    local fits = true
                                    for _, drop in ipairs(drops) do
                                        if not inv:room_for_item("dst", drop) then fits = false; break end
                                    end

                                    if fits then
                                        for _, drop in ipairs(drops) do inv:add_item("dst", drop) end
                                        minetest.set_node(fpos, {name = "sti_machines:quarry_frame"})
                                        energy = energy - current_usage
                                        meta:set_int("energy", energy)
                                        meta:set_int("frame_index", idx + 1)
                                    else
                                        status = "building_full"; meta:set_string("status", "building_full")
                                    end
                                else
                                    meta:set_int("frame_index", idx + 1)
                                end
                            else
                                if current_node.name == "air" or minetest.get_item_group(current_node.name, "liquid") > 0 then
                                    minetest.set_node(fpos, {name = "sti_machines:quarry_frame"})
                                end
                                energy = energy - current_usage
                                meta:set_int("energy", energy)
                                meta:set_int("frame_index", idx + 1)
                            end
                        else
                            -- Wechsel in NEUE Phase: Freiräumung des Volumens
                            status = "clearing"
                            meta:set_string("status", "clearing")
                            meta:set_int("clear_x", meta:get_int("min_x"))
                            meta:set_int("clear_y", pos.y)
                            meta:set_int("clear_z", meta:get_int("min_z"))
                        end

                    -- PHASE 2: Volumen innerhalb des Rahmens komplett leeren (Nur Luft erlaubt!)
                    elseif status == "clearing" then
                        local cx = meta:get_int("clear_x")
                        local cy = meta:get_int("clear_y")
                        local cz = meta:get_int("clear_z")
                        local min_x = meta:get_int("min_x")
                        local max_x = meta:get_int("max_x")
                        local min_z = meta:get_int("min_z")
                        local max_z = meta:get_int("max_z")

                        local cleared_something = false
                        local scanned = 0

                        while scanned < 30 and not cleared_something and status == "clearing" do
                            local cpos = {x=cx, y=cy, z=cz}
                            local cnode = minetest.get_node(cpos)

                            if cnode.name ~= "air" and cnode.name ~= "ignore" and cnode.name ~= "sti_machines:quarry_frame" then
                                if not minetest.is_protected(cpos, "") then
                                    local drops = minetest.get_node_drops(cnode.name, "")
                                    local fits = true
                                    for _, drop in ipairs(drops) do
                                        if not inv:room_for_item("dst", drop) then fits = false; break end
                                    end

                                    if fits then
                                        for _, drop in ipairs(drops) do inv:add_item("dst", drop) end
                                        minetest.remove_node(cpos)
                                        energy = energy - current_usage
                                        meta:set_int("energy", energy)
                                        cleared_something = true
                                    else
                                        status = "clearing_full"; meta:set_string("status", "clearing_full")
                                    end
                                end
                            end

                            if status == "clearing" then
                                cx = cx + 1
                                if cx > max_x then
                                    cx = min_x
                                    cz = cz + 1
                                    if cz > max_z then
                                        cz = min_z
                                        cy = cy + 1
                                        if cy > pos.y + 3 then
                                            -- Jetzt ist alles frei! Bohrvorgang nach unten darf starten
                                            status = "digging"
                                            meta:set_string("status", "digging")
                                        end
                                    end
                                end
                            end
                            scanned = scanned + 1
                        end

                        meta:set_int("clear_x", cx)
                        meta:set_int("clear_y", cy)
                        meta:set_int("clear_z", cz)

                    -- PHASE 3: Normales Bohren (Nach unten)
                    elseif status == "digging" then
                        local cur_x = meta:get_int("cur_x")
                        local cur_y = meta:get_int("cur_y")
                        local cur_z = meta:get_int("cur_z")
                        local min_x = meta:get_int("min_x")
                        local max_x = meta:get_int("max_x")
                        local min_y = meta:get_int("min_y")
                        local min_z = meta:get_int("min_z")
                        local max_z = meta:get_int("max_z")

                        local scanned_nodes = 0
                        local block_broken = false

                        while scanned_nodes < 30 and not block_broken and status == "digging" do
                            local cpos = {x=cur_x, y=cur_y, z=cur_z}
                            local cnode = minetest.get_node(cpos)

                            if cnode.name ~= "air" and cnode.name ~= "ignore" and cnode.name ~= "sti_machines:quarry_frame" then
                                if not minetest.is_protected(cpos, "") then
                                    local drops = minetest.get_node_drops(cnode.name, "")
                                    local fits = true
                                    for _, drop in ipairs(drops) do
                                        if not inv:room_for_item("dst", drop) then fits = false; break end
                                    end

                                    if fits then
                                        for _, drop in ipairs(drops) do inv:add_item("dst", drop) end
                                        minetest.remove_node(cpos)
                                        energy = energy - current_usage
                                        meta:set_int("energy", energy)
                                        block_broken = true
                                    else
                                        status = "full"; meta:set_string("status", "full")
                                    end
                                end
                            end

                            if status == "digging" then
                                cur_x = cur_x + 1
                                if cur_x > max_x then
                                    cur_x = min_x
                                    cur_z = cur_z + 1
                                    if cur_z > max_z then
                                        cur_z = min_z
                                        cur_y = cur_y - 1

                                        if cur_y < min_y then
                                            status = "completed"
                                            meta:set_string("status", "completed")
                                            clear_quarry_frames(pos, meta)
                                        end
                                    end
                                end
                            end
                            scanned_nodes = scanned_nodes + 1
                        end

                        meta:set_int("cur_x", cur_x)
                        meta:set_int("cur_y", cur_y)
                        meta:set_int("cur_z", cur_z)

                        if status == "digging" then
                            minetest.add_particle({
                                pos = {x = cur_x, y = cur_y + 0.5, z = cur_z},
                                velocity = {x = math.random(-1, 1) * 0.4, y = math.random(1, 2), z = math.random(-1, 1) * 0.4},
                                acceleration = {x = 0, y = -3, z = 0},
                                expirationtime = 0.5, size = math.random(2, 4),
                                collisiondetection = true, glow = 14,
                                texture = "unknown_node.png^[resize:4x4^[colorize:#ffaa00:255",
                            })
                        end
                    end
                end
            end
        end

        -- Spawnen der Entitäten falls sie fehlen (Steuerung läuft komplett flüssig via on_step)
        if status == "clearing" or status == "clearing_full" or status == "digging" or status == "full" or status == "paused" then
            local gantry_x_obj, carrier_obj, pipe_obj
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 30)) do
                local ent = obj:get_luaentity()
                if ent and ent.quarry_pos and vector.equals(ent.quarry_pos, pos) then
                    if ent.name == "sti_machines:gantry_x" then gantry_x_obj = obj
                    elseif ent.name == "sti_machines:gantry_carrier" then carrier_obj = obj
                    elseif ent.name == "sti_machines:drill_pipe" then pipe_obj = obj end
                end
            end

            if not gantry_x_obj then
                gantry_x_obj = minetest.add_entity({x=pos.x, y=pos.y+3, z=pos.z}, "sti_machines:gantry_x")
                if gantry_x_obj then gantry_x_obj:get_luaentity().quarry_pos = vector.new(pos) end
            end
            if not carrier_obj then
                carrier_obj = minetest.add_entity({x=pos.x, y=pos.y+3, z=pos.z}, "sti_machines:gantry_carrier")
                if carrier_obj then carrier_obj:get_luaentity().quarry_pos = vector.new(pos) end
            end
            if not pipe_obj then
                pipe_obj = minetest.add_entity({x=pos.x, y=pos.y+3, z=pos.z}, "sti_machines:drill_pipe")
                if pipe_obj then pipe_obj:get_luaentity().quarry_pos = vector.new(pos) end
            end
        end

        local active_node_name = "sti_machines:quarry_active"
        local inactive_node_name = "sti_machines:quarry"
        if (status == "digging" or status == "building" or status == "clearing") and node.name ~= active_node_name then
            minetest.swap_node(pos, {name = active_node_name, param2 = node.param2})
        elseif (status == "paused" or status == "full" or status == "clearing_full" or status == "idle" or status == "completed") and node.name ~= inactive_node_name then
            minetest.swap_node(pos, {name = inactive_node_name, param2 = node.param2})
        end

        meta:set_int("energy", energy)
        meta:set_string("infotext", "Quarry: " .. status .. "\nEnergie: " .. energy .. " EU")
        sti_machines.update_quarry_formspec(pos)

        return true
    end
}

-- =======================================================================
-- GANTRY ENTITÄTEN: FLÜSSIGE BEWEGUNG UND SCHUTZ VOR GRAFIK-ARTEFAKTEN
-- =======================================================================

local entity_base = {
    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then self.quarry_pos = data.quarry_pos end
        end
    end,
    get_staticdata = function(self)
        return minetest.serialize({quarry_pos = self.quarry_pos})
    end,
}

-- 1. X-Achsen Schiene (Gantry X)
local gantry_x_def = table.copy(entity_base)
gantry_x_def.initial_properties = {
    visual = "cube",
    textures = {
        "stimachines_machine_side.png^[colorize:#ffcc00:180", "stimachines_machine_side.png^[colorize:#111111:200",
        "stimachines_machine_side.png^[colorize:#ffcc00:180", "stimachines_machine_side.png^[colorize:#ffcc00:180",
        "stimachines_machine_side.png^[colorize:#ffcc00:180", "stimachines_machine_side.png^[colorize:#ffcc00:180"
    },
    visual_size = {x = 1, y = 0.2, z = 0.2},
    physical = false, pointable = false,
}
gantry_x_def.on_step = function(self, dtime)
    if not self.quarry_pos then return end
    local meta = minetest.get_meta(self.quarry_pos)
    local status = meta:get_string("status")
    if status == "idle" or status == "completed" or minetest.get_node(self.quarry_pos).name == "air" then
        self.object:remove(); return
    end

    local min_x = meta:get_int("min_x")
    local max_x = meta:get_int("max_x")
    local top_y = self.quarry_pos.y + 3
    local target_z = (status == "clearing" or status == "clearing_full") and meta:get_int("clear_z") or meta:get_int("cur_z")
    local center_x = (min_x + max_x) / 2

    -- SET PROPERTIES NUR EINMAL AUFRUFEN (Verhindert Flackern/Artefakte!)
    if not self.initialized_size then
        local size_x = (max_x - min_x) + 1
        self.object:set_properties({ visual_size = {x = size_x, y = 0.2, z = 0.2} })
        self.initialized_size = true
    end

    local pos = self.object:get_pos()
    if pos then
        local target = {x = center_x, y = top_y, z = target_z}
        local dist = vector.distance(pos, target)
        if dist > 0.02 then
            local dir = vector.direction(pos, target)
            self.object:set_velocity(vector.multiply(dir, math.min(15, dist * 8))) -- Flüssiges Anfahren/Abbremsen
        else
            self.object:set_velocity({x=0, y=0, z=0})
            self.object:set_pos(target)
        end
    end
end
minetest.register_entity("sti_machines:gantry_x", gantry_x_def)

-- 2. Laufkatze (Gantry Carrier)
local gantry_carrier_def = table.copy(entity_base)
gantry_carrier_def.initial_properties = {
    visual = "cube",
    textures = {
        "stimachines_machine_top.png^[colorize:#333333:150", "stimachines_machine_bottom.png^[colorize:#ffaa00:180",
        "stimachines_machine_side.png^[colorize:#333333:150", "stimachines_machine_side.png^[colorize:#333333:150",
        "stimachines_machine_side.png^[colorize:#333333:150", "stimachines_machine_side.png^[colorize:#333333:150"
    },
    visual_size = {x = 0.6, y = 0.3, z = 0.6},
    physical = false, pointable = false,
}
gantry_carrier_def.on_step = function(self, dtime)
    if not self.quarry_pos then return end
    local meta = minetest.get_meta(self.quarry_pos)
    local status = meta:get_string("status")
    if status == "idle" or status == "completed" or minetest.get_node(self.quarry_pos).name == "air" then
        self.object:remove(); return
    end

    local target_x, target_z
    local top_y = self.quarry_pos.y + 3

    if status == "clearing" or status == "clearing_full" then
        target_x = meta:get_int("clear_x")
        target_z = meta:get_int("clear_z")
        top_y = meta:get_int("clear_y") + 0.5 -- Verfolgt das Freiräumen direkt visuell
    else
        target_x = meta:get_int("cur_x")
        target_z = meta:get_int("cur_z")
    end

    local pos = self.object:get_pos()
    if pos then
        local target = {x = target_x, y = top_y, z = target_z}
        local dist = vector.distance(pos, target)
        if dist > 0.02 then
            local dir = vector.direction(pos, target)
            self.object:set_velocity(vector.multiply(dir, math.min(15, dist * 8)))
        else
            self.object:set_velocity({x=0, y=0, z=0})
            self.object:set_pos(target)
        end
    end
end
minetest.register_entity("sti_machines:gantry_carrier", gantry_carrier_def)

-- 3. Bohrstange (Drill Pipe)
local drill_pipe_def = table.copy(entity_base)
drill_pipe_def.initial_properties = {
    visual = "cube",
    textures = {
        "stimachines_machine_side.png^[colorize:#555555:200", "stimachines_machine_bottom.png^[colorize:#aa0000:200",
        "stimachines_machine_side.png^[colorize:#777777:200", "stimachines_machine_side.png^[colorize:#777777:200",
        "stimachines_machine_side.png^[colorize:#777777:200", "stimachines_machine_side.png^[colorize:#777777:200"
    },
    visual_size = {x = 0.15, y = 1.0, z = 0.15},
    physical = false, pointable = false,
}
drill_pipe_def.on_step = function(self, dtime)
    if not self.quarry_pos then return end
    local meta = minetest.get_meta(self.quarry_pos)
    local status = meta:get_string("status")

    -- Ausblenden oder Löschen während dem Freiräumen, da noch kein Tiefen-Bohren stattfindet
    if status == "clearing" or status == "clearing_full" then
        self.object:set_properties({ visual_size = {x = 0, y = 0, z = 0} })
        return
    elseif status == "idle" or status == "completed" or minetest.get_node(self.quarry_pos).name == "air" then
        self.object:remove(); return
    end

    local cur_x = meta:get_int("cur_x")
    local cur_y = meta:get_int("cur_y")
    local cur_z = meta:get_int("cur_z")
    local top_y = self.quarry_pos.y + 3

    local height = top_y - cur_y
    if height < 0.1 then height = 0.1 end

    -- Nur neu skalieren, wenn sich die Tiefe wirklich geändert hat!
    if not self.last_height or math.abs(self.last_height - height) > 0.05 then
        self.object:set_properties({ visual_size = {x = 0.15, y = height, z = 0.15} })
        self.last_height = height
    end

    local pos = self.object:get_pos()
    if pos then
        local target = {x = cur_x, y = top_y - (height / 2), z = cur_z}
        local dist = vector.distance(pos, target)
        if dist > 0.02 then
            local dir = vector.direction(pos, target)
            self.object:set_velocity(vector.multiply(dir, math.min(15, dist * 8)))
        else
            self.object:set_velocity({x=0, y=0, z=0})
            self.object:set_pos(target)
        end
    end
end
minetest.register_entity("sti_machines:drill_pipe", drill_pipe_def)

-- =======================================================================
-- REGISTRIERUNG RAHMEN-NODE & QUARRY NODES
-- =======================================================================

minetest.register_node("sti_machines:quarry_frame", {
    description = "Quarry Gerüst",
    drawtype = "nodebox",
    tiles = {"stimachines_quarry_frame.png"},
    paramtype = "light", sunlight_propagates = true, light_source = 4,
    groups = {cracky = 3, not_in_creative_inventory = 1},
    pointable = false, walkable = true,
    node_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, -0.4,  0.5, -0.4}, {-0.5, -0.5,  0.4, -0.4,  0.5,  0.5},
            { 0.4, -0.5, -0.5,  0.5,  0.5, -0.4}, { 0.4, -0.5,  0.4,  0.5,  0.5,  0.5},
            {-0.5, -0.5, -0.5,  0.5, -0.4, -0.4}, {-0.5, -0.5,  0.4,  0.5, -0.4,  0.5},
            {-0.5, -0.5, -0.5, -0.4, -0.4,  0.5}, { 0.4, -0.5, -0.5,  0.5, -0.4,  0.5},
            {-0.5,  0.4, -0.5,  0.5,  0.5, -0.4}, {-0.5,  0.4,  0.4,  0.5,  0.5,  0.5},
            {-0.5,  0.4, -0.5, -0.4,  0.5,  0.5}, { 0.4,  0.4, -0.5,  0.5,  0.5,  0.5},
        }
    }
})

local q_inactive = table.copy(quarry_def)
q_inactive.tiles = {
    "stimachines_machine_top.png",    "stimachines_machine_bottom.png",
    "stimachines_machine_side.png",   "stimachines_machine_side.png",
    "stimachines_machine_side.png",   "stimachines_quarry_front.png"
}
minetest.register_node("sti_machines:quarry", q_inactive)

local q_active = table.copy(quarry_def)
q_active.tiles = {
	"stimachines_machine_top.png",    "stimachines_machine_bottom.png",
    "stimachines_machine_side.png",   "stimachines_machine_side.png",
    "stimachines_machine_side.png",   "stimachines_quarry_front_active.png"
}
q_active.groups = {cracky = 2, technic_machine = 1, machine_item = 1, not_in_creative_inventory = 1}
q_active.light_source = 7
minetest.register_node("sti_machines:quarry_active", q_active)

-- =======================================================================
-- CRAFTITEMS REGISTRIERUNG (UNSTAPELBAR: stack_max = 1)
-- =======================================================================

for i = 1, 10 do
    minetest.register_craftitem("sti_machines:upgrade_speed_" .. i, {
        description = "Quarry Geschwindigkeits-Upgrade (Stufe " .. i .. ")\n+ " .. (i * 10) .. "% Tempo, + " .. (i * 20) .. "% Stromverbrauch",
        inventory_image = "stimachines_upgrade_speed.png^[colorize:#ff0000:" .. math.floor(i * 25.5),
        stack_max = 1, -- Verhindert das Stapeln im Inventar komplett!
    })
end

minetest.register_craftitem("sti_machines:upgrade_range", {
    description = "Quarry Reichweiten-Upgrade\nVerdoppelt die maximale Baugröße",
    inventory_image = "stimachines_upgrade_range.png^[colorize:#0000ff:150",
    stack_max = 1, -- Verhindert das Stapeln im Inventar komplett!
})

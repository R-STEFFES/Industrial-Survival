-- =======================================================================
-- STI MACHINES - AUTOCRAFTER (3x3 AUTOMATISCHE FERTIGUNG MIT SEITENSTEUERUNG)
-- =======================================================================

local sides = {"top", "bottom", "front", "back", "left", "right"}

-- Farbdefinitionen für die Item-Zustände (Synchronisiert mit deinen restlichen Maschinen)
local function get_side_color(mode)
    if mode == 1 then return "#3366ff" end -- Blau (Item Input -> Vorrat)
    if mode == 2 then return "#ffaa00" end -- Orange (Item Output -> Auswurf)
    return "#555555" -- Grau (Aus / Keine Interaktion)
end

local function get_side_text(mode)
    if mode == 1 then return "Item In" end
    if mode == 2 then return "Item Out" end
    return "Aus"
end

local function update_autocrafter_formspec(pos)
    local meta = minetest.get_meta(pos)
    local energy = meta:get_int("energy")
    local max_energy = meta:get_int("max_energy")
    local status = meta:get_string("status_msg") or "Bereit"

    local m_top    = meta:get_int("side_top")
    local m_bottom = meta:get_int("side_bottom")
    local m_front  = meta:get_int("side_front")
    local m_back   = meta:get_int("side_back")
    local m_left   = meta:get_int("side_left")
    local m_right  = meta:get_int("side_right")

    local formspec = "size[11,10]" ..
        "label[0.5,0.2;--- AUTOCRAFTER ---]" ..
        "label[0.5,0.6;Status: " .. status .. "]" ..

        -- Rezept-Muster (Ändert sich nicht durch Automation)
        "label[0.5,1.2;Rezept-Muster:]" ..
        "list[context;recipe;0.5,1.6;3,3;]" ..
        "image[3.7,2.6;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..

        -- Energieanzeige (Auf max_energy angepasst)
        "label[0.5,4.7;Energie: " .. energy .. " / " .. max_energy .. " EU]" ..
        "box[0.5,5.1;3.0,0.2;#333333]" ..
        (energy > 0 and "box[0.5,5.1;" .. (energy / max_energy * 3.0) .. ",0.2;#ffff00]" or "") ..

        -- Material-Vorrat
        "label[5.0,1.2;Material-Vorrat:]" ..
        "list[context;main_inv;5.0,1.6;4,3;]" ..

        -- Ausgabe-Slot
        "label[5.0,4.7;Ausgabe:]" ..
        "list[context;dst;6.5,4.7;1,1;]" ..

        -- Seiten-Konfiguration (Kompaktes D-Pad für Itemducts)
        "label[9.3,1.2;Richtungen:]" ..
        "style[btn_top;bgcolor=" .. get_side_color(m_top) .. "]" ..
        "button[9.5,1.6;1.0,0.5;btn_top;Oben]" ..
        "style[btn_bottom;bgcolor=" .. get_side_color(m_bottom) .. "]" ..
        "button[9.5,2.8;1.0,0.5;btn_bottom;Unten]" ..
        "style[btn_left;bgcolor=" .. get_side_color(m_left) .. "]" ..
        "button[8.4,2.2;1.0,0.5;btn_left;Links]" ..
        "style[btn_front;bgcolor=" .. get_side_color(m_front) .. "]" ..
        "button[9.5,2.2;1.0,0.5;btn_front;Vorn]" ..
        "style[btn_right;bgcolor=" .. get_side_color(m_right) .. "]" ..
        "button[10.6,2.2;1.0,0.5;btn_right;Rechts]" ..
        "style[btn_back;bgcolor=" .. get_side_color(m_back) .. "]" ..
        "button[9.5,3.4;1.0,0.5;btn_back;Hinten]" ..

        -- Legenden-Anzeige für die Knöpfe
        "label[9.2,4.1;Blau: In]" ..
        "label[9.2,4.4;Orange: Out]" ..

        -- Spieler-Inventar
        "list[current_player;main;0.5,5.8;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;main_inv]"

    meta:set_string("formspec", formspec)
end

minetest.register_node("sti_machines:autocrafter", {
    description = "Autocrafter",
    tiles = {
        "stimachines_crafter_top.png", "stimachines_machine_bottom.png",
        "stimachines_machine_side.png", "stimachines_machine_side.png",
        "stimachines_machine_side.png", "stimachines_crafter_front.png"
    },
    paramtype2 = "facedir",

    -- FIX: groups erweitert um machine_power für Stromkabel
    groups = {
        cracky = 2,
        technic_machine = 1,
        machine_item = 1,
        machine_power = 1
    },
    is_energy_consumer = true,

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("recipe", 9)
        inv:set_size("main_inv", 12)
        inv:set_size("dst", 1)

        -- FIX: Umstellung auf globale Variable 'max_energy' passend zum Kabelnetzwerk
        meta:set_int("energy", 0)
        meta:set_int("max_energy", 8000)
        meta:set_string("status_msg", "Bereit.")

        -- Standard-Seitenmodi für Items (0 = Aus, 1 = Item In, 2 = Item Out)
        meta:set_int("side_top", 0)
        meta:set_int("side_bottom", 0)
        meta:set_int("side_front", 0)
        meta:set_int("side_back", 0)
        meta:set_int("side_left", 1)   -- Links standardmäßig Input (Blau)
        meta:set_int("side_right", 2)  -- Rechts standardmäßig Output (Orange)

        minetest.get_node_timer(pos):start(0.5) -- Schnellerer Intervall für flüssige Automation
        update_autocrafter_formspec(pos)
    end,

    on_receive_fields = function(pos, formname, fields, sender)
        local meta = minetest.get_meta(pos)
        for _, side in ipairs(sides) do
            if fields["btn_" .. side] then
                local mode = meta:get_int("side_" .. side)
                -- Schaltet durch: 0 (Aus) -> 1 (Item In) -> 2 (Item Out)
                meta:set_int("side_" .. side, (mode + 1) % 3)
                update_autocrafter_formspec(pos)
            end
        end
    end,

    -- Logik für ankommende Items aus Itemducts (NUR in den Materialvorrat!)
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "main_inv" then
            return stack:get_count()
        end
        return 0 -- Verhindert, dass Rohre das Rezept-Muster überschreiben
    end,

    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if listname == "dst" then
            return stack:get_count()
        end
        return 0
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local energy = meta:get_int("energy")
        local max_energy = meta:get_int("max_energy")

        -- 1. AUTOMATISCHER AUSWURF (Falls etwas im dst-Slot liegt)
        local dst_stack = inv:get_stack("dst", 1)
        if not dst_stack:is_empty() then
            -- Suche nach Itemducts an den konfigurierten "Item Out"-Seiten (Mode 2)
            local node = minetest.get_node(pos)
            local p2 = node.param2 or 0

            local directions = {
                top    = {x=0,  y=1,  z=0}, bottom = {x=0,  y=-1, z=0},
                front  = minetest.facedir_to_dir(p2),
                back   = vector.multiply(minetest.facedir_to_dir(p2), -1),
                left   = {x=minetest.facedir_to_dir(p2).z,  y=0, z=-minetest.facedir_to_dir(p2).x},
                right  = {x=-minetest.facedir_to_dir(p2).z, y=0, z=minetest.facedir_to_dir(p2).x}
            }

            for side, dir in pairs(directions) do
                if meta:get_int("side_" .. side) == 2 then -- Wenn Seite auf "Item Out" steht
                    local target_pos = vector.add(pos, dir)
                    local target_node = minetest.get_node(target_pos)

                    -- Prüfen, ob dort ein Itemduct liegt
                    if minetest.get_item_group(target_node.name, "machine_item") > 0 or
                       minetest.get_item_group(target_node.name, "itemduct") > 0 then

                        local target_meta = minetest.get_meta(target_pos)
                        local target_inv = target_meta:get_inventory()

                        -- Wenn das Rohr/die Ziel-Maschine Platz hat, drücke das Item rein
                        if target_inv and target_inv:room_for_item("main", dst_stack) then
                            target_inv:add_item("main", dst_stack)
                            inv:set_stack("dst", 1, "") -- Slot leeren
                            break
                        end
                    end
                end
            end
        end

        -- 2. CRAFTING LOGIK
        local recipe_list = inv:get_list("recipe")
        local craft_result, _ = minetest.get_craft_result({method = "normal", width = 3, items = recipe_list})

        if not craft_result.item:is_empty() then
            if energy < 100 then
                meta:set_string("status_msg", "Zu wenig Energie!")
            else
                -- Zählen, welche Materialien das Rezept fordert
                local needed_items = {}
                for _, item in ipairs(recipe_list) do
                    if not item:is_empty() then
                        local name = item:get_name()
                        needed_items[name] = (needed_items[name] or 0) + 1
                    end
                end

                -- Prüfen, ob alle benötigten Materialien im VORRAT (main_inv) liegen
                local has_all = true
                for name, count in pairs(needed_items) do
                    if not inv:contains_item("main_inv", name .. " " .. count) then
                        has_all = false
                        break
                    end
                end

                -- Crafting ausführen, wenn Vorrat da ist und der Output Platz hat
                if has_all and inv:room_for_item("dst", craft_result.item) then
                    for name, count in pairs(needed_items) do
                        inv:remove_item("main_inv", name .. " " .. count)
                    end
                    inv:add_item("dst", craft_result.item)
                    meta:set_int("energy", energy - 100)
                    meta:set_string("status_msg", "Produziert...")
                elseif not has_all then
                    meta:set_string("status_msg", "Material fehlt!")
                else
                    meta:set_string("status_msg", "Ausgang voll!")
                end
            end
        else
            meta:set_string("status_msg", "Kein Rezept.")
        end

        update_autocrafter_formspec(pos)
        return true
    end,
})

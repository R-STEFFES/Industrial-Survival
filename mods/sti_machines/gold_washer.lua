-- =======================================================================
-- STI MACHINES - GOLDWASCHANLAGE (INTELLIGENTE SEITENSTEUERUNG)
-- =======================================================================

local sides = {"top", "bottom", "front", "back", "left", "right"}

-- Erweiterte Farbdefinitionen für die Seitenmodi
local function get_side_color(mode)
    if mode == 1 then return "#3366ff" end -- Blau (Item Input)
    if mode == 2 then return "#ffaa00" end -- Orange (Item Output)
    if mode == 3 then return "#00cc44" end -- Grün (Fluid Input)
    if mode == 4 then return "#b300b3" end -- Lila (Fluid Output)
    if mode == 5 then return "#ff3333" end -- Rot (Input/Output / ME-Interface)
    return "#555555" -- Grau (Deaktiviert)
end

local function get_side_text(mode)
    if mode == 1 then return "Item In" end
    if mode == 2 then return "Item Out" end
    if mode == 3 then return "Fluid In" end
    if mode == 4 then return "Fluid Out" end
    if mode == 5 then return "I/O (ME)" end
    return "Aus"
end

local function update_washer_formspec(pos)
    local meta = minetest.get_meta(pos)
    local tank_amount = meta:get_int("tank_amount")
    local energy = meta:get_int("energy")
    local status = meta:get_string("status_msg") or "Bereit"

    local m_top    = meta:get_int("side_top")
    local m_bottom = meta:get_int("side_bottom")
    local m_front  = meta:get_int("side_front")
    local m_back   = meta:get_int("side_back")
    local m_left   = meta:get_int("side_left")
    local m_right  = meta:get_int("side_right")

    local formspec = "size[11,9.5]" ..
        "label[0.5,0.3;--- GOLDWASCHANLAGE ---]" ..
        "label[0.5,0.8;Status: " .. status .. "]" ..

        -- Tank & Energie Anzeige
        "label[0.5,1.3;Wasser: " .. tank_amount .. " / 8000 mb]" ..
        "box[0.5,1.7;3.5,0.2;#333333]" ..
        (tank_amount > 0 and "box[0.5,1.7;" .. (tank_amount / 8000 * 3.5) .. ",0.2;#00d4ff]" or "") ..

        "label[4.5,1.3;Energie: " .. energy .. " / 4000 EU]" ..
        "box[4.5,1.7;3.5,0.2;#333333]" ..
        (energy > 0 and "box[4.5,1.7;" .. (energy / 4000 * 3.5) .. ",0.2;#ffff00]" or "") ..

        -- Inventar Slots
        "label[0.5,2.2;Input (Erde/Sand):]" ..
        "list[context;src;0.5,2.6;1,1;]" ..
        "label[2.5,2.2;Output (Nuggets/Lehm):]" ..
        "list[context;dst;2.5,2.6;4,2;]" ..

        -- Seiten-Konfiguration (Erweitertes GUI-Layout)
        "label[7.5,2.2;Seiten-Konfiguration:]" ..

        "style[btn_top;bgcolor=" .. get_side_color(m_top) .. "]" ..
        "button[7.5,2.6;3.0,0.6;btn_top;Oben: " .. get_side_text(m_top) .. "]" ..

        "style[btn_bottom;bgcolor=" .. get_side_color(m_bottom) .. "]" ..
        "button[7.5,3.3;3.0,0.6;btn_bottom;Unten: " .. get_side_text(m_bottom) .. "]" ..

        "style[btn_front;bgcolor=" .. get_side_color(m_front) .. "]" ..
        "button[7.5,4.0;3.0,0.6;btn_front;Vorne: " .. get_side_text(m_front) .. "]" ..

        "style[btn_back;bgcolor=" .. get_side_color(m_back) .. "]" ..
        "button[7.5,4.7;3.0,0.6;btn_back;Hinten: " .. get_side_text(m_back) .. "]" ..

        "style[btn_left;bgcolor=" .. get_side_color(m_left) .. "]" ..
        "button[7.5,5.4;3.0,0.6;btn_left;Links: " .. get_side_text(m_left) .. "]" ..

        "style[btn_right;bgcolor=" .. get_side_color(m_right) .. "]" ..
        "button[7.5,6.1;3.0,0.6;btn_right;Rechts: " .. get_side_text(m_right) .. "]" ..

        "list[current_player;main;0.5,7.0;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;src]" ..
        "listring[context;dst]"

    meta:set_string("formspec", formspec)
end

minetest.register_node("sti_machines:gold_washer", {
    description = "Goldwaschanlage",
    tiles = {
        "stimachines_washer_top.png", "stimachines_machine_bottom.png",
        "stimachines_machine_side.png", "stimachines_machine_side.png",
        "stimachines_machine_side.png", "stimachines_washer_front.png"
    },
    paramtype2 = "facedir",

    -- FIX: Gruppen hinzugefügt, damit Kabel und Itemducts andocken können!
    groups = {
        cracky = 2,
        machine_fluid = 1,
        machine_item = 1,
        machine_power = 1,      -- Wichtig für energyduct.lua (Kabelverbindung)
        technic_machine = 1     -- Zur Absicherung für andere Stromleitungen
    },
    is_energy_consumer = true,

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("src", 1)
        inv:set_size("dst", 8)
        meta:set_int("tank_amount", 0)
        meta:set_int("energy", 0)
        meta:set_int("max_energy", 4000)

        -- Standard-Seiten-Modi (0 = Aus, 1 = Item In, 2 = Item Out, 3 = Fluid In, 4 = Fluid Out, 5 = I/O)
        meta:set_int("side_top", 3)    -- Oben standardmäßig Fluid Input (Wasser)
        meta:set_int("side_bottom", 0)
        meta:set_int("side_front", 0)
        meta:set_int("side_back", 0)
        meta:set_int("side_left", 1)   -- Links standardmäßig Item Input
        meta:set_int("side_right", 2)  -- Rechts standardmäßig Item Output

        update_washer_formspec(pos)
    end,

    on_receive_fields = function(pos, formname, fields, sender)
        local meta = minetest.get_meta(pos)
        for _, side in ipairs(sides) do
            if fields["btn_" .. side] then
                local mode = meta:get_int("side_" .. side)
                -- Modus-Umschaltung von 0 bis 5 (6 Zustände)
                meta:set_int("side_" .. side, (mode + 1) % 6)
                update_washer_formspec(pos)
            end
        end
    end,

    -- Logik für Item-Pipelines (itemduct.lua benötigt diese Callbacks bei Direktanschluss)
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "src" then return stack:get_count() end
        return 0
    end,

    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if listname == "dst" then return stack:get_count() end
        return 0
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local tank = meta:get_int("tank_amount")
        local energy = meta:get_int("energy")
        local src_stack = inv:get_stack("src", 1)

        -- 1. Überprüfung auf Input
        if src_stack:is_empty() then
            meta:set_string("status_msg", "Wartet auf Material...")
            update_washer_formspec(pos)
            return true
        end

        -- 2. Rezept-Lookup aus der externen Tabelle
        local input_name = src_stack:get_name()
        local recipe = sti_machines.washer_recipes[input_name]

        if not recipe then
            meta:set_string("status_msg", "Rezept nicht unterstützt!")
            update_washer_formspec(pos)
            return true
        end

        -- 3. Überprüfung von Ressourcen (Kosten pro Waschgang: 100mb Wasser + 50 EU)
        if tank < 100 or energy < 50 then
            meta:set_string("status_msg", "Mangel an Wasser/Strom!")
            update_washer_formspec(pos)
            return true
        end

        -- 4. Platzprüfung im Output für das garantierte Hauptprodukt
        if not inv:room_for_item("dst", recipe.output) then
            meta:set_string("status_msg", "Ausgabe voll!")
            update_washer_formspec(pos)
            return true
        end

        -- Wenn alle Bedingungen erfüllt sind, startet der Waschprozess
        meta:set_string("status_msg", "Wäscht...")

        -- Ressourcen abziehen
        meta:set_int("tank_amount", tank - 100)
        meta:set_int("energy", energy - 50)

        -- Input-Item verbrauchen
        src_stack:take_item(1)
        inv:set_stack("src", 1, src_stack)

        -- Hauptprodukt dem Ausgangsinventar hinzufügen
        inv:add_item("dst", recipe.output)

        -- Extra Drops basierend auf ihren individuellen Wahrscheinlichkeiten auswürfeln
        for _, drop in ipairs(recipe.drops) do
            if math.random() <= drop.chance then
                -- Nur hinzufügen, wenn im dst-Inventar noch Platz für den seltenen Drop ist
                if inv:room_for_item("dst", drop.item) then
                    inv:add_item("dst", drop.item)
                end
            end
        end

        update_washer_formspec(pos)
        return true
    end,

    on_metadata_inventory_put = function(pos)
        local timer = minetest.get_node_timer(pos)
        if not timer:is_started() then timer:start(1.0) end
    end,
})

-- =======================================================================
-- PULVERIZER (Strom -> Verdopplung von Erzen zu Staub)
-- =======================================================================

local function update_formspec(pos)
    local meta = minetest.get_meta(pos)
    local energy = meta:get_int("energy")
    local max_energy = meta:get_int("max_energy")
    local progress = meta:get_float("progress")

    local formspec = "size[8,9]" ..
        "label[0.5,0.5;--- PULVERIZER ---]" ..
        "label[1.5,1.2;Eingabe]" ..
        "list[context;src;1.5,1.7;1,1;]" ..
        "label[5.5,1.2;Ausgabe]" ..
        "list[context;dst;5.5,1.7;2,2;]" ..

        -- Energieanzeige (Zahlen und Balken)
        "label[1.5,3.0;Energie: " .. energy .. " / " .. max_energy .. " EU]" ..
        "box[3.0,2.0;2,0.3;#333333]"

    -- Fortschrittsbalken (Orange)
    if progress > 0 then
        local bar_width = progress * 2
        formspec = formspec .. "box[3.0,2.0;" .. bar_width .. ",0.3;#ffaa00]"
    end

    formspec = formspec ..
        "list[current_player;main;0,4.8;8,4;]" ..
        "listring[current_player;main]" ..
        "listring[context;src]" ..
        "listring[context;dst]"

    meta:set_string("formspec", formspec)
end

minetest.register_node("sti_machines:pulverizer", {
    description = "Pulverizer (Zerkleinerer)",
    tiles = {
        "stimachines_pulver_top.png", "stimachines_machine_bottom.png",
        "stimachines_machine_side.png", "stimachines_machine_side.png",
        "stimachines_machine_side.png", "stimachines_pulver_front.png"
    },
    groups = {cracky = 2, technic_machine = 1, machine_item = 1},
    is_energy_consumer = true, -- Sorgt dafür, dass das Kabelnetzwerk den Strom liefert

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("src", 1)
        inv:set_size("dst", 4)

        meta:set_int("energy", 0)
        meta:set_int("max_energy", 5000)
        meta:set_float("progress", 0.0)
        meta:set_string("infotext", "Pulverizer: Bereit.")

        update_formspec(pos)
    end,

    -- WICHTIG: Startet den Timer, sobald der Spieler manuell ein Erz einlegt
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        minetest.get_node_timer(pos):start(1.0)
    end,

    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local energy = meta:get_int("energy")
        local src = inv:get_stack("src", 1)

        local progress = meta:get_float("progress")
        local is_active = false

        -- Prüfen, ob Material zum Verarbeiten da ist
        if not src:is_empty() then
            local name = src:get_name()
            local output = name .. "_dust" -- Logik: item_name -> item_name_dust

            -- Prüfen, ob genug Strom da ist
            if energy >= 50 then
                -- Prüfen, ob das Endprodukt in den Ausgang passt
                if inv:room_for_item("dst", output .. " 2") then
                    progress = progress + 0.2
                    energy = energy - 50
                    is_active = true
                    meta:set_string("infotext", "Pulverizer: Zerkleinert... (" .. energy .. " EU)")

                    -- Wenn Verarbeitung abgeschlossen (1.0 = 100%)
                    if progress >= 1.0 then
                        src:take_item(1)
                        inv:set_stack("src", 1, src)
                        inv:add_item("dst", output .. " 2")
                        progress = 0.0
                    end
                else
                    meta:set_string("infotext", "Pulverizer: Ausgang voll!")
                    progress = 0.0
                end
            else
                meta:set_string("infotext", "Pulverizer: Zu wenig Energie! (" .. energy .. " EU)")
            end
        else
            -- Wenn kein Item da ist, setze Fortschritt zurück und zeige Bereitschaft
            progress = 0.0
            meta:set_string("infotext", "Pulverizer: Bereit.\nEnergie: " .. energy .. " EU")
        end

        -- Aktualisierte Werte speichern
        meta:set_int("energy", energy)
        meta:set_float("progress", progress)

        -- WICHTIG: GUI IMMER updaten, damit der Energiestand sichtbar steigt
        update_formspec(pos)

        -- Timer läuft weiter, solange Strom im System ist ODER ein Item im Eingang liegt
        return (not src:is_empty() or energy > 0)
    end,
})

-- =========================================================================
-- Custom HUD Mod für Luanti (Survival Pack) - All in One (Mit 3D-Armor)
-- =========================================================================

survival_hud_data = {} -- Globale Tabelle für alle HUD-IDs
local player_states = {} -- Tabelle für Sprint- und Ausdauer-Logik

-- Setzt die 3D-Armor Einstellung im Code auf Fehl, damit deren eigenes HUD nicht lädt
if minetest.settings then
    minetest.settings:set_bool("armor_hud", false)
end

-- =========================================================================
-- 1. HUD REGISTRIEREN & AUFBAUEN
-- =========================================================================

local function add_hud_element(player, name, def)
    local name_str = player:get_player_name()
    if not survival_hud_data[name_str] then survival_hud_data[name_str] = {} end

    if survival_hud_data[name_str][name] then
        player:hud_remove(survival_hud_data[name_str][name])
    end

    survival_hud_data[name_str][name] = player:hud_add(def)
end

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()

    player:hud_set_flags({
        healthbar = false,
        breathbar = false,
    })

    local hotbar_width = 360
    local half_hotbar = hotbar_width / 2

    -- LINKS: Leben & Rüstung
    add_hud_element(player, "health", {
        hud_elem_type = "statbar", position = {x = 0.5, y = 1},
        text = "heart_full.png", background = "heart_empty.png",
        number = player:get_hp(), max = 20,
        offset = {x = -half_hotbar, y = -90}, size = {x = 16, y = 16}, alignment = {x = 1, y = 1},
    })

    add_hud_element(player, "armor", {
        hud_elem_type = "statbar", position = {x = 0.5, y = 1},
        text = "armor_full.png", background = "armor_empty.png",
        number = 0, max = 20, -- Startet bei 0 ohne Rüstung
        offset = {x = -half_hotbar, y = -110}, size = {x = 16, y = 16}, alignment = {x = 1, y = 1},
    })

    -- RECHTS: Hunger & Durst
    add_hud_element(player, "hunger", {
        hud_elem_type = "statbar", position = {x = 0.5, y = 1},
        text = "hunger_full.png", background = "hunger_empty.png",
        number = 20, max = 20,
        offset = {x = half_hotbar, y = -90}, size = {x = 16, y = 16}, direction = 1, alignment = {x = -1, y = 1},
    })

    add_hud_element(player, "thirst", {
        hud_elem_type = "statbar", position = {x = 0.5, y = 1},
        text = "thirst_full.png", background = "thirst_empty.png",
        number = 20, max = 20,
        offset = {x = half_hotbar, y = -110}, size = {x = 16, y = 16}, direction = 1, alignment = {x = -1, y = 1},
    })

    -- OBEN: Temperatur, Ausdauer, Sauerstoff
    add_hud_element(player, "temp_bar", {
        hud_elem_type = "statbar", position = {x = 0.5, y = 1},
        text = "bar_temp.png", background = "bar_background.png",
        number = 20, max = 20,
        offset = {x = -half_hotbar, y = -125}, size = {x = 38, y = 8}, alignment = {x = 1, y = 0},
    })

    add_hud_element(player, "stamina_bar", {
        hud_elem_type = "statbar", position = {x = 0.5, y = 1},
        text = "bar_stamina.png", background = "bar_background.png",
        number = 20, max = 20,
        offset = {x = -half_hotbar, y = -137}, size = {x = 38, y = 8}, alignment = {x = 1, y = 0},
    })

    add_hud_element(player, "oxygen_bar", {
        hud_elem_type = "statbar", position = {x = 0.5, y = 1},
        text = "bar_oxygen.png", background = "bar_background.png",
        number = 10, max = 10,
        offset = {x = -half_hotbar, y = -150}, size = {x = 76, y = 10}, alignment = {x = 1, y = 0},
    })

    -- Initiale Werte laden
    local meta = player:get_meta()

    local current_hunger = meta:get_int("survival_hunger")
    if current_hunger == 0 and not meta:contains("survival_hunger") then current_hunger = 20 end
    player:hud_change(survival_hud_data[name]["hunger"], "number", current_hunger)
    meta:set_int("survival_hunger", current_hunger)

    local current_thirst = meta:get_int("survival_thirst")
    if current_thirst == 0 and not meta:contains("survival_thirst") then current_thirst = 20 end
    player:hud_change(survival_hud_data[name]["thirst"], "number", current_thirst)
    meta:set_int("survival_thirst", current_thirst)

    local current_temp = meta:get_float("survival_temp")
    if current_temp == 0 and not meta:contains("survival_temp") then current_temp = 10 end
    player:hud_change(survival_hud_data[name]["temp_bar"], "number", math.floor(current_temp))
    meta:set_float("survival_temp", current_temp)

    player_states[name] = { stamina = 20, last_w_press_time = 0, was_w_pressed = false, is_sprinting = false }
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    survival_hud_data[name] = nil
    player_states[name] = nil
end)


-- =========================================================================
-- 2. ESSEN (HUNGER AUFFÜLLEN)
-- =========================================================================
minetest.register_on_item_eat(function(hp_change, replace_with_item, itemstack, user, pointed_thing)
    if user and user:is_player() then
        local meta = user:get_meta()
        local hunger = meta:get_int("survival_hunger")

        local hunger_restore = hp_change * 2
        if hunger_restore <= 0 then hunger_restore = 2 end

        hunger = hunger + hunger_restore
        if hunger > 20 then hunger = 20 end

        meta:set_int("survival_hunger", hunger)
        local name = user:get_player_name()
        if survival_hud_data[name] and survival_hud_data[name]["hunger"] then
            user:hud_change(survival_hud_data[name]["hunger"], "number", hunger)
        end
    end
    return nil
end)


-- =========================================================================
-- 3. LEBEN EVENT-LISTENER
-- =========================================================================
minetest.register_on_player_hpchange(function(player, hp_change, reason)
    local name = player:get_player_name()
    minetest.after(0, function()
        local p = minetest.get_player_by_name(name)
        if p and survival_hud_data[name] and survival_hud_data[name]["health"] then
            p:hud_change(survival_hud_data[name]["health"], "number", p:get_hp())
        end
    end)
    return hp_change
end)


-- =========================================================================
-- 4. GLOBALE UPDATES (SAUERSTOFF, TRINKEN, RÜSTUNG, SPRINTEN, HUNGER, TEMP)
-- =========================================================================
local timer_fast = 0
local timer_slow = 0

minetest.register_globalstep(function(dtime)
    timer_fast = timer_fast + dtime
    timer_slow = timer_slow + dtime

    -- ==========================================
    -- Schnelle Updates (Läuft jeden Frame / 0.5s)
    -- ==========================================
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local controls = player:get_player_control()

        if timer_fast >= 0.5 and survival_hud_data[name] then
            -- SAUERSTOFF
            local breath = player:get_breath()
            if breath > 10 then breath = 10 end
            if breath < 0 then breath = 0 end
            player:hud_change(survival_hud_data[name]["oxygen_bar"], "number", breath)

            -- RÜSTUNG (3D Armor API Integration)
            if armor and armor.def and armor.def[name] then
                local armor_level = armor.def[name].level or 0
                -- Umrechnung von 0-100% auf deine 20 HUD-Punkte
                local armor_hud_val = math.floor(armor_level / 5)
                if armor_hud_val > 20 then armor_hud_val = 20 end

                player:hud_change(survival_hud_data[name]["armor"], "number", armor_hud_val)
            else
                player:hud_change(survival_hud_data[name]["armor"], "number", 0)
            end

            -- TRINKEN (IM WASSER + SNEAK)
            local pos = player:get_pos()
            local node_feet = minetest.get_node({x = pos.x, y = pos.y + 0.1, z = pos.z}).name
            local node_head = minetest.get_node({x = pos.x, y = pos.y + 1.5, z = pos.z}).name

            local in_water = string.find(node_feet, "water") or string.find(node_head, "water")

            if in_water and controls.sneak then
                local meta = player:get_meta()
                local thirst = meta:get_int("survival_thirst")

                if thirst < 20 then
                    thirst = thirst + 2
                    if thirst > 20 then thirst = 20 end

                    meta:set_int("survival_thirst", thirst)
                    player:hud_change(survival_hud_data[name]["thirst"], "number", thirst)

                    minetest.sound_play("default_water_footstep", {
                        to_player = name, gain = 0.5
                    }, true)
                end
            end
        end

        -- AUSDAUER & SPRINTEN
        local state = player_states[name]
        if state then
            local current_time = minetest.get_us_time() / 1000000

            if controls.up and not state.was_w_pressed then
                if (current_time - state.last_w_press_time) <= 0.3 then
                    if state.stamina > 0 then
                        state.is_sprinting = true
                        player:set_physics_override({speed = 1.8})
                    end
                end
                state.last_w_press_time = current_time
            end
            state.was_w_pressed = controls.up

            if not controls.up or state.stamina <= 0 then
                if state.is_sprinting then
                    state.is_sprinting = false
                    player:set_physics_override({speed = 1.0})
                end
            end

            local changed = false
            if state.is_sprinting then
                state.stamina = state.stamina - (dtime * 4)
                if state.stamina < 0 then state.stamina = 0 end
                changed = true
            else
                if state.stamina < 20 then
                    state.stamina = state.stamina + (dtime * 1.5)
                    if state.stamina > 20 then state.stamina = 20 end
                    changed = true
                end
            end

            if changed and survival_hud_data[name] and survival_hud_data[name]["stamina_bar"] then
                player:hud_change(survival_hud_data[name]["stamina_bar"], "number", math.floor(state.stamina))
            end
        end
    end

    if timer_fast >= 0.5 then timer_fast = 0 end

    -- ==========================================
    -- Langsame Updates (Alle 10 Sekunden)
    -- ==========================================
    if timer_slow >= 10.0 then
        timer_slow = 0
        for _, player in ipairs(minetest.get_connected_players()) do
            local name = player:get_player_name()
            local meta = player:get_meta()
            local pos = player:get_pos()

            -- HUNGER
            local hunger = meta:get_int("survival_hunger")
            if hunger > 0 then
                hunger = hunger - 1
                meta:set_int("survival_hunger", hunger)
                if survival_hud_data[name] then
                    player:hud_change(survival_hud_data[name]["hunger"], "number", hunger)
                end
            else
                player:set_hp(player:get_hp() - 1)
            end

            -- DURST
            local thirst = meta:get_int("survival_thirst")
            if thirst > 0 then
                thirst = thirst - 1
                meta:set_int("survival_thirst", thirst)
                if survival_hud_data[name] then
                    player:hud_change(survival_hud_data[name]["thirst"], "number", thirst)
                end
            else
                player:set_hp(player:get_hp() - 1)
            end

            -- TEMPERATUR
            local temp = meta:get_float("survival_temp")
            local env_mod = 0

            local heat_nodes = minetest.find_nodes_in_area(
                {x = pos.x - 3, y = pos.y - 3, z = pos.z - 3},
                {x = pos.x + 3, y = pos.y + 3, z = pos.z + 3},
                {"default:lava_source", "default:lava_flowing", "fire:basic_flame"}
            )

            if pos.y > 50 then env_mod = -1
            elseif #heat_nodes > 0 then env_mod = 2
            else
                if temp < 10 then env_mod = 1 end
                if temp > 10 then env_mod = -1 end
            end

            temp = temp + env_mod
            if temp > 20 then temp = 20 end
            if temp < 0 then temp = 0 end

            meta:set_float("survival_temp", temp)
            if survival_hud_data[name] then
                player:hud_change(survival_hud_data[name]["temp_bar"], "number", math.floor(temp))
            end
        end
    end
end)

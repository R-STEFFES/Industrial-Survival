-- =========================================================================
-- Custom HUD Mod für Luanti (Survival Pack) - All in One (v9 - Real Fly & Celsius)
-- =========================================================================

survival_hud_data = {}   -- Globale Tabelle für alle HUD-IDs
local player_states = {} -- Tabelle für Sprint-, Ausdauer- und Verbrauchs-Logik

-- =========================================================================
-- CONFIGURATION
-- =========================================================================
local SPRINT_STAMINA_DRAIN = 2.0  -- Ausdauer-Abzug beim Sprinten

-- Wie viele Sekunden vergehen, bis 1 Punkt HUNGER abgezogen wird:
local SECONDS_PER_HUNGER_STAND  = 90.0
local SECONDS_PER_HUNGER_WALK   = 50.0
local SECONDS_PER_HUNGER_SPRINT = 15.0

-- Wie viele Sekunden vergehen, bis 1 Punkt DURST abgezogen wird:
local SECONDS_PER_THIRST_STAND  = 70.0
local SECONDS_PER_THIRST_WALK   = 40.0
local SECONDS_PER_THIRST_SPRINT = 10.0

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
        number = 0, max = 20,
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

    -- Biom & Temperatur Textanzeige
    add_hud_element(player, "biome_text", {
        hud_elem_type = "text", position = {x = 0.5, y = 1},
        offset = {x = -half_hotbar, y = -165},
        text = "Biom: Laden... | 0°C",
        number = 0xFFFFFF,
        alignment = {x = 1, y = 0},
        scale = {x = 200, y = 20},
    })

    -- Initiale Werte laden
    local meta = player:get_meta()

    local current_hunger = meta:get_int("survival_hunger")
    if current_hunger == 0 and not meta:contains("survival_hunger") then current_hunger = 20 end

    local current_thirst = meta:get_int("survival_thirst")
    if current_thirst == 0 and not meta:contains("survival_thirst") then current_thirst = 20 end

    local current_temp = meta:get_float("survival_temp")
    if current_temp == 0 and not meta:contains("survival_temp") then current_temp = 10 end
    meta:set_float("survival_temp", current_temp)

    player_states[name] = {
        stamina = 20,
        last_w_press_time = 0,
        was_w_pressed = false,
        is_sprinting = false,
        hunger = current_hunger,
        thirst = current_thirst,
        last_creative_state = nil,
        is_flying = false,
        last_jump_press_time = 0,
        was_jump_pressed = false
    }
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    survival_hud_data[name] = nil
    player_states[name] = nil
end)


-- =========================================================================
-- 2. ESSEN & TRINKEN EVENTS
-- =========================================================================
minetest.register_on_item_eat(function(hp_change, replace_with_item, itemstack, user, pointed_thing)
    if user and user:is_player() then
        local name = user:get_player_name()
        if minetest.is_creative_enabled(name) then return nil end

        local state = player_states[name]
        if state then
            local hunger_restore = hp_change * 2
            if hunger_restore <= 0 then hunger_restore = 2 end

            state.hunger = state.hunger + hunger_restore
            if state.hunger > 20 then state.hunger = 20 end

            user:get_meta():set_int("survival_hunger", math.floor(state.hunger))
            if survival_hud_data[name] and survival_hud_data[name]["hunger"] then
                user:hud_change(survival_hud_data[name]["hunger"], "number", math.floor(state.hunger))
            end
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
-- 4. GLOBALE UPDATES (DTIME STEUERUNG)
-- =========================================================================
local timer_fast = 0
local timer_slow = 0
local timer_temp = 0

minetest.register_globalstep(function(dtime)
    timer_fast = timer_fast + dtime
    timer_slow = timer_slow + dtime
    timer_temp = timer_temp + dtime

    -- ==========================================
    -- JEVEN FRAME: Minecraft Flugmechanik & Sprinten
    -- ==========================================
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local controls = player:get_player_control()
        local state = player_states[name]

        if state then
            local is_creative = minetest.is_creative_enabled(name)

            -- DETEKTION: DOPPEL-LEERTASTE FÜR FLUGMODUS
            if is_creative then
                local current_time = minetest.get_us_time() / 1000000
                if controls.jump and not state.was_jump_pressed then
                    if (current_time - state.last_jump_press_time) <= 0.35 then
                        state.is_flying = not state.is_flying

                        if state.is_flying then
                            -- Schwerkraft aufheben und Reibung erhöhen für perfektes Schweben
                            player:set_physics_override({gravity = 0, speed = 1.0})
                        else
                            -- Normale Physik wiederherstellen
                            player:set_physics_override({gravity = 1.0, speed = 1.0})
                            player:set_velocity({x=0, y=-2, z=0}) -- Sanft nach unten bewegen
                        end
                    end
                    state.last_jump_press_time = current_time
                end
                state.was_jump_pressed = controls.jump

                -- FLUGSTEUERUNG (Minecraft Style Höhenkontrolle)
                if state.is_flying then
                    local vel = player:get_velocity() or {x=0, y=0, z=0}
                    local fly_speed = 6.0

                    if controls.jump then
                        player:set_velocity({x = vel.x, y = fly_speed, z = vel.z})
                    elseif controls.sneak then
                        player:set_velocity({x = vel.x, y = -fly_speed, z = vel.z})
                    else
                        -- Absolut fixes Schweben auf der Y-Achse, wenn nichts gedrückt wird
                        player:set_velocity({x = vel.x, y = 0, z = vel.z})
                    end
                end
            else
                -- Sicherheits-Reset für Survival-Modus
                if state.is_flying or state.last_creative_state ~= false then
                    state.is_flying = false
                    player:set_physics_override({gravity = 1.0, fly = false, speed = 1.0})
                end
            end

            -- MODUS-WECHSEL CLEANDOWN
            if state.last_creative_state ~= is_creative then
                local privs = minetest.get_player_privs(name)
                if is_creative then
                    privs.fly = true
                else
                    privs.fly = nil
                    state.is_flying = false
                    player:set_physics_override({gravity = 1.0, fly = false, speed = 1.0})
                end
                minetest.set_player_privs(name, privs)
                state.last_creative_state = is_creative
            end

            -- AUSDAUER & SPRINT LOGIK
            local current_time = minetest.get_us_time() / 1000000
            if controls.up and not state.was_w_pressed then
                if (current_time - state.last_w_press_time) <= 0.3 then
                    if state.stamina > 0 or is_creative then
                        state.is_sprinting = true
                        player:set_physics_override({speed = 1.8})
                    end
                end
                state.last_w_press_time = current_time
            end
            state.was_w_pressed = controls.up

            if not controls.up or (state.stamina <= 0 and not is_creative) then
                if state.is_sprinting then
                    state.is_sprinting = false
                    player:set_physics_override({speed = 1.0})
                end
            end

            local stamina_changed = false
            if is_creative then
                if state.stamina ~= 20 then
                    state.stamina = 20
                    stamina_changed = true
                end
            else
                if state.is_sprinting then
                    state.stamina = state.stamina - (dtime * SPRINT_STAMINA_DRAIN)
                    if state.stamina < 0 then state.stamina = 0 end
                    stamina_changed = true
                else
                    if state.stamina < 20 then
                        state.stamina = state.stamina + (dtime * 1.5)
                        if state.stamina > 20 then state.stamina = 20 end
                        stamina_changed = true
                    end
                end
            end

            if stamina_changed and survival_hud_data[name] and survival_hud_data[name]["stamina_bar"] then
                player:hud_change(survival_hud_data[name]["stamina_bar"], "number", math.floor(state.stamina))
            end

            -- HUNGER & DURST VERBRAUCH
            if not is_creative then
                local hunger_loss_per_second = 1.0 / SECONDS_PER_HUNGER_STAND
                local thirst_loss_per_second = 1.0 / SECONDS_PER_THIRST_STAND

                if state.is_sprinting then
                    hunger_loss_per_second = 1.0 / SECONDS_PER_HUNGER_SPRINT
                    thirst_loss_per_second = 1.0 / SECONDS_PER_THIRST_SPRINT
                elseif controls.up or controls.down or controls.left or controls.right or controls.jump then
                    hunger_loss_per_second = 1.0 / SECONDS_PER_HUNGER_WALK
                    thirst_loss_per_second = 1.0 / SECONDS_PER_THIRST_WALK
                end

                state.hunger = state.hunger - (dtime * hunger_loss_per_second)
                state.thirst = state.thirst - (dtime * thirst_loss_per_second)

                if state.hunger < 0 then state.hunger = 0 end
                if state.thirst < 0 then state.thirst = 0 end
            end
        end
    end

    -- ==========================================
    -- SCHNELLE UPDATES (Alle 0.5s - HUD Sync & Biom/Celsius)
    -- ==========================================
    if timer_fast >= 0.5 then
        timer_fast = 0
        for _, player in ipairs(minetest.get_connected_players()) do
            local name = player:get_player_name()
            local controls = player:get_player_control()
            local pos = player:get_pos()
            local state = player_states[name]

            if survival_hud_data[name] and state then
                local is_creative = minetest.is_creative_enabled(name)
                local meta = player:get_meta()

                if is_creative then
                    player:hud_change(survival_hud_data[name]["hunger"], "max", 0)
                    player:hud_change(survival_hud_data[name]["hunger"], "number", 0)
                    player:hud_change(survival_hud_data[name]["thirst"], "max", 0)
                    player:hud_change(survival_hud_data[name]["thirst"], "number", 0)
                    player:hud_change(survival_hud_data[name]["stamina_bar"], "max", 0)
                    player:hud_change(survival_hud_data[name]["stamina_bar"], "number", 0)
                else
                    local display_hunger = math.floor(state.hunger)
                    local display_thirst = math.floor(state.thirst)

                    meta:set_int("survival_hunger", display_hunger)
                    meta:set_int("survival_thirst", display_thirst)

                    player:hud_change(survival_hud_data[name]["hunger"], "max", 20)
                    player:hud_change(survival_hud_data[name]["hunger"], "number", display_hunger)
                    player:hud_change(survival_hud_data[name]["thirst"], "max", 20)
                    player:hud_change(survival_hud_data[name]["thirst"], "number", display_thirst)
                    player:hud_change(survival_hud_data[name]["stamina_bar"], "max", 20)
                    player:hud_change(survival_hud_data[name]["stamina_bar"], "number", math.floor(state.stamina))
                end

                -- DYNAMISCHER SAUERSTOFF
                local breath = player:get_breath()
                if breath >= 10 then
                    player:hud_change(survival_hud_data[name]["oxygen_bar"], "text", "")
                    player:hud_change(survival_hud_data[name]["oxygen_bar"], "background", "")
                    player:hud_change(survival_hud_data[name]["oxygen_bar"], "number", 0)
                else
                    player:hud_change(survival_hud_data[name]["oxygen_bar"], "text", "bar_oxygen.png")
                    player:hud_change(survival_hud_data[name]["oxygen_bar"], "background", "bar_background.png")
                    local display_breath = breath
                    if display_breath > 10 then display_breath = 10 end
                    if display_breath < 0 then display_breath = 0 end
                    player:hud_change(survival_hud_data[name]["oxygen_bar"], "number", display_breath)
                end

                -- BIOM-ANZEIGE & CELSIUS UMRECHNUNG
                local temp_val = meta:get_float("survival_temp")
                -- Umrechnung: Skala 0 bis 20 wird gemappt auf -15°C bis +45°C
                local celsius = math.floor((temp_val * 3) - 15)

                local biome_data = minetest.get_biome_data(pos)
                local display_biome_name = "Unbekannt"
                if biome_data and biome_data.biome then
                    local raw_name = minetest.get_biome_name(biome_data.biome) or "Unbekannt"
                    local clean_name = raw_name:match(":(.+)") or raw_name
                    display_biome_name = clean_name:sub(1,1):upper() .. clean_name:sub(2):gsub("_", " ")
                end

                player:hud_change(survival_hud_data[name]["biome_text"], "text", "Biom: " .. display_biome_name .. " | " .. celsius .. "°C")

                -- RÜSTUNG
                if armor and armor.def and armor.def[name] then
                    local armor_level = armor.def[name].level or 0
                    local armor_hud_val = math.floor(armor_level / 5)
                    if armor_hud_val > 20 then armor_hud_val = 20 end
                    player:hud_change(survival_hud_data[name]["armor"], "number", armor_hud_val)
                else
                    player:hud_change(survival_hud_data[name]["armor"], "number", 0)
                end

                -- TRINKEN
                if not is_creative then
                    local node_feet = minetest.get_node({x = pos.x, y = pos.y + 0.1, z = pos.z}).name
                    local node_head = minetest.get_node({x = pos.x, y = pos.y + 1.5, z = pos.z}).name
                    local in_water = string.find(node_feet, "water") or string.find(node_head, "water")

                    if in_water and controls.sneak then
                        if state.thirst < 20 then
                            state.thirst = state.thirst + 2
                            if state.thirst > 20 then state.thirst = 20 end
                            meta:set_int("survival_thirst", math.floor(state.thirst))
                            player:hud_change(survival_hud_data[name]["thirst"], "number", math.floor(state.thirst))
                            minetest.sound_play("default_water_footstep", { to_player = name, gain = 0.5 }, true)
                        end
                    end
                end
            end
        end
    end

    -- ==========================================
    -- MITTELSCHNELLE UPDATES (Alle 2s - Temperatur-Skript)
    -- ==========================================
    if timer_temp >= 2.0 then
        timer_temp = 0
        for _, player in ipairs(minetest.get_connected_players()) do
            local name = player:get_player_name()
            local meta = player:get_meta()
            local pos = player:get_pos()

            if survival_hud_data[name] then
                local temp = meta:get_float("survival_temp")
                local biome_data = minetest.get_biome_data(pos)
                local b_heat = 50
                if biome_data and biome_data.heat then b_heat = biome_data.heat end

                if pos.y > 30 then
                    b_heat = b_heat - (pos.y - 30) * 0.25
                end

                local heat_nodes = minetest.find_nodes_in_area(
                    {x = pos.x - 3, y = pos.y - 3, z = pos.z - 3},
                    {x = pos.x + 3, y = pos.y + 3, z = pos.z + 3},
                    {"default:lava_source", "default:lava_flowing", "fire:basic_flame"}
                )
                if #heat_nodes > 0 then b_heat = 100 end

                local target_temp = math.floor(b_heat / 5)
                if target_temp > 20 then target_temp = 20 end
                if target_temp < 0 then target_temp = 0 end

                if temp < target_temp then
                    temp = temp + 1
                elseif temp > target_temp then
                    temp = temp - 1
                end

                meta:set_float("survival_temp", temp)
                player:hud_change(survival_hud_data[name]["temp_bar"], "number", temp)

                -- Schutz im Kreativmodus greift absolut!
                if (temp >= 20 or temp <= 0) and not minetest.is_creative_enabled(name) then
                    player:set_hp(player:get_hp() - 1)
                end
            end
        end
    end

    -- ==========================================
    -- LANGSAME UPDATES (Alle 10s - Schaden)
    -- ==========================================
    if timer_slow >= 10.0 then
        timer_slow = 0
        for _, player in ipairs(minetest.get_connected_players()) do
            local name = player:get_player_name()
            local state = player_states[name]

            if state and not minetest.is_creative_enabled(name) then
                if state.hunger <= 0 or state.thirst <= 0 then
                    player:set_hp(player:get_hp() - 1)
                end
            end
        end
    end
end)

-- stamina.lua
local STAMINA_MAX = 20
local double_tap_time = 0.3 -- Zeitfenster für Doppel-W in Sekunden

-- Tabellen für Spieler-Status
local player_states = {}

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    player_states[name] = {
        stamina = STAMINA_MAX,
        last_w_press_time = 0,
        was_w_pressed = false,
        is_sprinting = false
    }
    if survival_hud_data[name] then
        player:hud_change(survival_hud_data[name]["stamina_bar"], "number", STAMINA_MAX)
    end
end)

minetest.register_on_leaveplayer(function(player)
    player_states[player:get_player_name()] = nil
end)

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local state = player_states[name]
        if not state then return end

        local controls = player:get_player_control()
        local current_time = minetest.get_us_time() / 1000000 -- Zeit in Sekunden

        -- Doppel-W Erkennung
        if controls.up and not state.was_w_pressed then
            -- W wurde gerade gedrückt
            if (current_time - state.last_w_press_time) <= double_tap_time then
                if state.stamina > 0 then
                    state.is_sprinting = true
                    player:set_physics_override({speed = 1.8}) -- Sprint-Geschwindigkeit
                end
            end
            state.last_w_press_time = current_time
        end
        state.was_w_pressed = controls.up

        -- Sprint abbrechen wenn W losgelassen wird oder Ausdauer leer ist
        if not controls.up or state.stamina <= 0 then
            if state.is_sprinting then
                state.is_sprinting = false
                player:set_physics_override({speed = 1.0}) -- Normale Geschwindigkeit
            end
        end

        -- Ausdauer verbrauchen oder regenerieren
        local changed = false
        if state.is_sprinting then
            state.stamina = state.stamina - (dtime * 4) -- Verbrauch pro Sekunde
            if state.stamina < 0 then state.stamina = 0 end
            changed = true
        else
            if state.stamina < STAMINA_MAX then
                state.stamina = state.stamina + (dtime * 1.5) -- Regeneration pro Sekunde
                if state.stamina > STAMINA_MAX then state.stamina = STAMINA_MAX end
                changed = true
            end
        end

        -- HUD Update (Werte auf ganze Zahlen runden)
        if changed and survival_hud_data[name] and survival_hud_data[name]["stamina_bar"] then
            player:hud_change(survival_hud_data[name]["stamina_bar"], "number", math.floor(state.stamina))
        end
    end
end)

-- temperature.lua
local TEMP_MAX = 20
local TEMP_OPTIMAL = 10 -- Mitte der Leiste ist optimale Temperatur
local temp_timer = 0

minetest.register_globalstep(function(dtime)
    temp_timer = temp_timer + dtime
    if temp_timer < 2.0 then return end -- Nur alle 2 Sekunden prüfen
    temp_timer = 0

    for _, player in ipairs(minetest.get_connected_players()) do
        local meta = player:get_meta()
        -- Initiale Temperatur auf optimal setzen, falls noch nicht vorhanden
        local body_temp = meta:get_float("survival_temp")
        if body_temp == 0 and not meta:contains("survival_temp") then
            body_temp = TEMP_OPTIMAL
        end

        local pos = player:get_pos()
        local env_temp_modifier = 0

        -- Einfacher Check: Ist Lava oder Feuer in der Nähe? (Radius 3 Blöcke)
        local heat_nodes = minetest.find_nodes_in_area(
            {x = pos.x - 3, y = pos.y - 3, z = pos.z - 3},
            {x = pos.x + 3, y = pos.y + 3, z = pos.z + 3},
            {"default:lava_source", "default:lava_flowing", "fire:basic_flame"}
        )

        -- Wenn man hoch in der Luft oder tief im Schnee ist, wird es kalt (Beispiel)
        if pos.y > 50 then
            env_temp_modifier = -1
        elseif #heat_nodes > 0 then
            env_temp_modifier = 2 -- Sehr warm
        else
            -- Tendenz zurück zur optimalen Temperatur, wenn keine Extreme herrschen
            if body_temp < TEMP_OPTIMAL then env_temp_modifier = 0.5 end
            if body_temp > TEMP_OPTIMAL then env_temp_modifier = -0.5 end
        end

        -- Temperatur anpassen
        body_temp = body_temp + env_temp_modifier

        -- Grenzen festlegen
        if body_temp > TEMP_MAX then body_temp = TEMP_MAX end
        if body_temp < 0 then body_temp = 0 end

        meta:set_float("survival_temp", body_temp)

        -- HUD Update
        local name = player:get_player_name()
        if survival_hud_data[name] and survival_hud_data[name]["temp_bar"] then
            player:hud_change(survival_hud_data[name]["temp_bar"], "number", math.floor(body_temp))
        end

        -- Schaden bei Extremwerten (Optional)
        if body_temp >= TEMP_MAX or body_temp <= 0 then
            player:set_hp(player:get_hp() - 1)
        end
    end
end)

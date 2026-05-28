-- hunger.lua
local HUNGER_MAX = 20
local HUNGER_TICK_RATE = 75.0 -- Alle 10 Sekunden wird geprüft
local hunger_timer = 0

-- Hilfsfunktion um Hunger zu setzen und HUD zu updaten
function set_player_hunger(player, value)
    local meta = player:get_meta()
    if value > HUNGER_MAX then value = HUNGER_MAX end
    if value < 0 then value = 0 end

    meta:set_int("survival_hunger", value)

    local name = player:get_player_name()
    if survival_hud_data[name] and survival_hud_data[name]["hunger"] then
        player:hud_change(survival_hud_data[name]["hunger"], "number", value)
    end
end

-- Initiale Werte beim Joinen laden
minetest.register_on_joinplayer(function(player)
    local meta = player:get_meta()
    local current_hunger = meta:get_int("survival_hunger")
    -- Wenn noch kein Wert existiert (neuer Spieler), auf Max setzen
    if current_hunger == 0 and not meta:contains("survival_hunger") then
        current_hunger = HUNGER_MAX
    end
    set_player_hunger(player, current_hunger)
end)

-- Hunger über Zeit verringern
minetest.register_globalstep(function(dtime)
    hunger_timer = hunger_timer + dtime
    if hunger_timer >= HUNGER_TICK_RATE then
        hunger_timer = 0
        for _, player in ipairs(minetest.get_connected_players()) do
            local meta = player:get_meta()
            local current_hunger = meta:get_int("survival_hunger")

            if current_hunger > 0 then
                -- Zieht 1 Hungerpunkt ab. (Kann später an Bewegung gekoppelt werden)
                set_player_hunger(player, current_hunger - 1)
            else
                -- Spieler nimmt Schaden, wenn er verhungert
                player:set_hp(player:get_hp() - 1)
            end
        end
    end
end)

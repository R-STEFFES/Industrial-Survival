-- health_oxygen.lua
local timer = 0
print("Health-Logik geladen!")
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 0.5 then return end -- Update nur alle 0.5 Sekunden spart Leistung
    timer = 0

    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        if survival_hud_data[name] then
            -- Leben updaten (Standard Max: 20)
            local hp = player:get_hp()
            player:hud_change(survival_hud_data[name]["health"], "number", hp)

            -- Sauerstoff updaten
            -- Minetest Breath ist standardmäßig 11 an der Oberfläche, dein HUD hat Max 10.
            local breath = player:get_breath()
            if breath > 10 then breath = 10 end
            if breath < 0 then breath = 0 end

            player:hud_change(survival_hud_data[name]["oxygen_bar"], "number", breath)
        end
    end
end)

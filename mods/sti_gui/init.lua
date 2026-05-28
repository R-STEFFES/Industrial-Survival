-- Custom HUD Mod für Luanti (Survival Pack)

local players_hud = {}

-- Hilfsfunktion zum Registrieren eines HUD-Elements
local function add_hud_element(player, name, def)
    local name_str = player:get_player_name()
    if not players_hud[name_str] then players_hud[name_str] = {} end

    if players_hud[name_str][name] then
        player:hud_remove(players_hud[name_str][name])
    end

    players_hud[name_str][name] = player:hud_add(def)
end

minetest.register_on_joinplayer(function(player)
    -- Deaktiviere das Standard-HUD
    player:hud_set_flags({
        healthbar = false,
        breathbar = false,
    })

    local hotbar_width = 360
    local half_hotbar = hotbar_width / 2

    -- =========================================================================
    -- LINKS: Leben & Rüstung
    -- =========================================================================

    add_hud_element(player, "health", {
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "heart_full.png",
        background = "heart_empty.png",
        number = 20,
        max = 20,
        offset = {x = -half_hotbar, y = -90},
        size = {x = 16, y = 16},
        alignment = {x = 1, y = 1},
    })

    add_hud_element(player, "armor", {
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "armor_full.png",
        background = "armor_empty.png",
        number = 20,
        max = 20,
        offset = {x = -half_hotbar, y = -110},
        size = {x = 16, y = 16},
        alignment = {x = 1, y = 1},
    })

    -- =========================================================================
    -- RECHTS: Hunger & Durst
    -- =========================================================================

    add_hud_element(player, "hunger", {
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "hunger_full.png",
        background = "hunger_empty.png",
        number = 20,
        max = 20,
        offset = {x = half_hotbar, y = -90},
        size = {x = 16, y = 16},
        direction = 1,
        alignment = {x = -1, y = 1},
    })

    add_hud_element(player, "thirst", {
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "thirst_full.png",
        background = "thirst_empty.png",
        number = 20,
        max = 20,
        offset = {x = half_hotbar, y = -110},
        size = {x = 16, y = 16},
        direction = 1,
        alignment = {x = -1, y = 1},
    })

    -- =========================================================================
    -- OBEN: Temperatur, Ausdauer, Sauerstoff (Max 360px breit)
    -- =========================================================================

    -- Temperatur (Unten, 20 Schritte á 18px = 360px)
    add_hud_element(player, "temp_bar", {
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "bar_temp.png",
        background = "bar_background.png",
        number = 20,
        max = 20,
        offset = {x = -half_hotbar, y = -125},
        size = {x = 38, y = 8},
        alignment = {x = 1, y = 0},
    })

    -- Ausdauer (Mitte, 20 Schritte á 18px = 360px)
    add_hud_element(player, "stamina_bar", {
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "bar_stamina.png",
        background = "bar_background.png",
        number = 20,
        max = 20,
        offset = {x = -half_hotbar, y = -137},
        size = {x = 38, y = 8},
        alignment = {x = 1, y = 0},
    })

    -- Sauerstoff (Oben, 10 Schritte á 36px = 360px)
    add_hud_element(player, "oxygen_bar", {
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "bar_oxygen.png",
        background = "bar_background.png",
        number = 10,
        max = 10,
        offset = {x = -half_hotbar, y = -150},
        size = {x = 76, y = 10},
        alignment = {x = 1, y = 0},
    })
end)

minetest.register_on_leaveplayer(function(player)
    players_hud[player:get_player_name()] = nil
end)

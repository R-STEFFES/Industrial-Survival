-- ==========================================================================
-- Mod: sti_mobile - Initialisierung
-- ==========================================================================

sti_mobile = {
    open_planes = {} -- Speichert, welcher Spieler gerade welches Flugzeug-GUI offen hat
}

local modpath = minetest.get_modpath(minetest.get_current_modname())

-- Lade die Flugzeug-Logik (Entity)
dofile(modpath .. "/airplane_logic.lua")

-- Lade die Rezepte
dofile(modpath .. "/recipes.lua")

-- Spawnhilfe-Item (Das Item, das man in der Hand hält)
minetest.register_craftitem("sti_mobile:airplane_item", {
    description = "Flugzeug (sti_mobile)",
    inventory_image = "sti_mobile_flieger_item.png",
    wield_image = "sti_mobile_flieger_item.png",
    stack_max = 1,

    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end
        local pos = pointed_thing.above
        pos.y = pos.y + 0.5

        -- Entity spawnen
        local ent = minetest.add_entity(pos, "sti_mobile:airplane")
        if ent and not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

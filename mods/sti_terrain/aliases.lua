-- st_terrain/aliases.lua
-- Mapgen-Node-Aliases
-- Verknüpft die internen Mapgen-Namen mit sti_core- und default-Nodes.

-------------------------------------------------------------------------------
-- PFLICHT: Basis-Gestein des Mapgens
-- Der Mapgen füllt die Welt damit. sti_core:stone ersetzt default:stone.
-------------------------------------------------------------------------------
minetest.register_alias("mapgen_stone", "sti_core:stone")

-------------------------------------------------------------------------------
-- WASSER UND LAVA
-- Falls default vorhanden, werden dessen Nodes genutzt.
-- Sonst müsstest du eigene Wasser-Nodes in sti_core anlegen.
-------------------------------------------------------------------------------
if minetest.registered_nodes["default:water_source"] then
    minetest.register_alias("mapgen_water_source",       "default:water_source")
    minetest.register_alias("mapgen_river_water_source", "default:river_water_source")
    minetest.register_alias("mapgen_lava_source",        "default:lava_source")
else
    minetest.log("warning", "[st_terrain] default:water_source nicht gefunden! " ..
        "Bitte mapgen_water_source manuell in aliases.lua setzen.")
end

-------------------------------------------------------------------------------
-- OBERFLÄCHEN-MATERIALIEN FÜR DEN MAPGEN
-- Diese Aliases werden von Biomen und Dekorationen genutzt.
-------------------------------------------------------------------------------

-- Standardoberfläche → brauner Lehm (allgemeiner Boden)
minetest.register_alias("mapgen_dirt",            "sti_core:loam_brown")

-- Gras-Boden → in st_terrain nutzen wir loam_brown als Basis;
-- Biome überschreiben die Oberfläche mit eigenen Nodes.
-- Falls default:dirt_with_grass existiert, bleibt es für Biom-Kompatibilität.
if minetest.registered_nodes["default:dirt_with_grass"] then
    minetest.register_alias("mapgen_dirt_with_grass", "default:dirt_with_grass")
end

-- Sand
minetest.register_alias("mapgen_sand", "sti_core:sand")

-- Kies
minetest.register_alias("mapgen_gravel", "sti_core:gravel")

-- Schnee / Eis (falls default vorhanden)
if minetest.registered_nodes["default:snowblock"] then
    minetest.register_alias("mapgen_dirt_with_snow", "default:dirt_with_snow")
    minetest.register_alias("mapgen_snowblock",      "default:snowblock")
    minetest.register_alias("mapgen_snow",           "default:snow")
    minetest.register_alias("mapgen_ice",            "default:ice")
end

minetest.log("action", "[st_terrain] Aliases gesetzt.")

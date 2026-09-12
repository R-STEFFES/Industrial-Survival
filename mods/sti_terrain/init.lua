-- st_terrain/init.lua
-- Einstiegspunkt des Weltgenerator-Mods
-- Lädt alle Teilmodule in der richtigen Reihenfolge

st_terrain = {}

local modpath = minetest.get_modpath("st_terrain")
local mg_name = minetest.get_mapgen_setting("mg_name")

minetest.log("action", "[st_terrain] Lade realistischen Weltgenerator (Mapgen: " .. mg_name .. ")")

-------------------------------------------------------------------------------
-- MAPGEN-ALIASES
-------------------------------------------------------------------------------
dofile(modpath .. "/aliases.lua")

-------------------------------------------------------------------------------
-- WICHTIG: BIOME IMMER LADEN!
-- Die Biome müssen zwingend vor allem anderen registriert werden, damit
-- Geologie, Erze, Dekorationen und der Custom-Mapgen darauf zugreifen können.
-------------------------------------------------------------------------------
dofile(modpath .. "/biomes.lua")

-------------------------------------------------------------------------------
-- WEICHE: Singlenode vs. normaler Mapgen
-------------------------------------------------------------------------------

if mg_name == "singlenode" then
    ----------------------------------------------------------------------------
    -- SINGLENODE-PFAD
    ----------------------------------------------------------------------------
    minetest.log("action", "[st_terrain] Singlenode-Modus: Custom Terrain Generator Pipeline aktiv.")

    -- Geologische Schichten
    dofile(modpath .. "/geology.lua")

    -- Erzverteilung
    dofile(modpath .. "/ores.lua")

    -- Dekorationen
    dofile(modpath .. "/decorations.lua")

    -- Custom Terrain Generator (on_generated-Callback)
    dofile(modpath .. "/mapgen_custom.lua")

else
    ----------------------------------------------------------------------------
    -- NORMALER MAPGEN-PFAD (v7, v5, flat, carpathian, …)
    ----------------------------------------------------------------------------
    minetest.log("action", "[st_terrain] Normaler Mapgen-Modus (" .. mg_name .. "): Standard-Pipeline aktiv.")

    -- Geologische Schichten
    dofile(modpath .. "/geology.lua")

    -- Erzverteilung
    dofile(modpath .. "/ores.lua")

    -- Dekorationen
    dofile(modpath .. "/decorations.lua")

end

minetest.log("action", "[st_terrain] Weltgenerator vollständig geladen.")

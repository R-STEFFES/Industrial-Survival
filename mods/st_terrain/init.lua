-- st_terrain/init.lua
-- Einstiegspunkt des Weltgenerator-Mods
-- Lädt alle Teilmodule in der richtigen Reihenfolge

st_terrain = {}

local modpath = minetest.get_modpath("st_terrain")
local mg_name = minetest.get_mapgen_setting("mg_name")

minetest.log("action", "[st_terrain] Lade realistischen Weltgenerator (Mapgen: " .. mg_name .. ")")

-------------------------------------------------------------------------------
-- MAPGEN-ALIASES
-- sti_core:stone wird als Basis-Gestein des Mapgens gesetzt.
-- Wasser und Lava bleiben bei default (falls vorhanden), sonst Fallback.
-------------------------------------------------------------------------------
dofile(modpath .. "/aliases.lua")

-------------------------------------------------------------------------------
-- BIOME-DEFINITIONEN
-- Eigene Biome die sti_core-Materialien als Oberfläche nutzen
-------------------------------------------------------------------------------
dofile(modpath .. "/biomes.lua")

-------------------------------------------------------------------------------
-- GESTEINSSCHICHTEN
-- Stratum- und Blob-Registrierungen für Kalkstein, Granit, Basalt, Böden
-- MUSS vor den Erzen geladen werden!
-------------------------------------------------------------------------------
dofile(modpath .. "/geology.lua")

-------------------------------------------------------------------------------
-- ERZVERTEILUNG
-- Geologisch korrekte Platzierung aller sti_core-Erze
-------------------------------------------------------------------------------
dofile(modpath .. "/ores.lua")

-------------------------------------------------------------------------------
-- DEKORATIONEN
-- Oberflächendetails: Steine, Felsbrocken, Gesteinsaufschlüsse
-------------------------------------------------------------------------------
dofile(modpath .. "/decorations.lua")

minetest.log("action", "[st_terrain] Weltgenerator vollständig geladen.")

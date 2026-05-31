-- st_terrain/mapgen_custom.lua
-- Benutzerdefinierter Terrain-Generator für den Singlenode-Mapgen.
-- Synchronisiert sich exakt mit den Biomen aus biomes.lua (st_terrain)
-- und patcht die Engine, damit HUD-Mods korrekte Biome anzeigen!

local mg_name = minetest.get_mapgen_setting("mg_name")
if mg_name ~= "singlenode" then
    return
end

minetest.log("action", "[st_terrain] Singlenode erkannt – Custom Terrain Generator wird aktiviert.")

-------------------------------------------------------------------------------
-- DYNAMISCHE NODE-REFERENZEN & BIOM-CACHE
-------------------------------------------------------------------------------
local function get_node_id(nodename, fallback)
    if nodename and minetest.registered_nodes[nodename] then
        return minetest.get_content_id(nodename)
    end
    if fallback and minetest.registered_nodes[fallback] then
        return minetest.get_content_id(fallback)
    end
    return minetest.get_content_id("air")
end

local c_air     = get_node_id("air")
local c_water   = get_node_id("mapgen_water_source", "default:water_source")
local c_stone   = get_node_id("sti_core:stone")
local c_basalt  = get_node_id("sti_core:basalt")
local c_granite = get_node_id("sti_core:granite")

local SEA_LEVEL = 0
local cached_biomes = {}

-- Hilfsfunktion zum Hinzufügen eines Bioms in unseren Mapgen-Cache
local function cache_biome(name, b_def)
    table.insert(cached_biomes, {
        name = name,
        engine_id = minetest.get_biome_id(name),
        top = get_node_id(b_def.node_top, "air"),
        top_depth = b_def.depth_top or 1,
        filler = get_node_id(b_def.node_filler, "air"),
        filler_depth = b_def.depth_filler or 3,
        stone = get_node_id(b_def.node_stone, "sti_core:stone"),
        heat_point = b_def.heat_point or 50,
        humidity_point = b_def.humidity_point or 50,
        y_max = b_def.y_max or 31000,
        y_min = b_def.y_min or -31000,
    })
end

-- 1. Versuch: Biome gezielt NUR aus der st_terrain.biome_list laden
if st_terrain and st_terrain.biome_list then
    for _, name in ipairs(st_terrain.biome_list) do
        local b_def = minetest.registered_biomes[name]
        if b_def then
            cache_biome(name, b_def)
        end
    end
end

-- 2. Fallback: Falls die Liste leer ist, alle registrierten Biome nehmen, die mit "st_" beginnen
if #cached_biomes == 0 then
    for name, b_def in pairs(minetest.registered_biomes) do
        if name:sub(1, 3) == "st_" then
            cache_biome(name, b_def)
        end
    end
end

minetest.log("action", "[st_terrain] " .. #cached_biomes .. " st_terrain-Biome erfolgreich in Custom Mapgen geladen.")

-------------------------------------------------------------------------------
-- NOISE-PARAMETER
-------------------------------------------------------------------------------
local NP_TERRAIN_BASE = {
    offset     = 18,
    scale      = 65,
    spread     = {x = 250, y = 250, z = 250},
    seed       = 5842,
    octaves    = 5,
    persist    = 0.45,
    lacunarity = 2.0,
    flags      = "defaults",
}

local NP_TERRAIN_DETAIL = {
    offset     = 0,
    scale      = 15,
    spread     = {x = 45, y = 45, z = 45},
    seed       = 1337,
    octaves    = 4,
    persist    = 0.5,
    lacunarity = 2.2,
    flags      = "defaults",
}

local NP_HUMIDITY = {
    offset     = 0.5,
    scale      = 0.5,
    spread     = {x = 512, y = 512, z = 512},
    seed       = 7771,
    octaves    = 3,
    persist    = 0.6,
}

local NP_TEMPERATURE = {
    offset     = 0.5,
    scale      = 0.5,
    spread     = {x = 768, y = 768, z = 768},
    seed       = 3391,
    octaves    = 3,
    persist    = 0.55,
}

-------------------------------------------------------------------------------
-- VORONOI BIOM-FINDER (Exakt wie die Minetest-Engine)
-------------------------------------------------------------------------------
local function get_biome(heat, humidity, y)
    local best_biome = nil
    local min_dist = math.huge

    for _, b in ipairs(cached_biomes) do
        -- Prüfen, ob die Höhe innerhalb der Biom-Grenzen liegt
        if y >= b.y_min and y <= b.y_max then
            -- Euklidische Distanz im 2D-Klimaraum (Temperatur & Feuchtigkeit) berechnen
            local d_heat = heat - b.heat_point
            local d_hum = humidity - b.humidity_point
            local dist = (d_heat * d_heat) + (d_hum * d_hum)

            -- Das Biom mit dem geringsten Abstand gewinnt
            if dist < min_dist then
                min_dist = dist
                best_biome = b
            end
        end
    end

    return best_biome or cached_biomes[1]
end

-------------------------------------------------------------------------------
-- ENGINE MONKEY-PATCH (Lösen des HUD-Biom-Problems bei Singlenode)
-------------------------------------------------------------------------------
local original_get_biome_data = minetest.get_biome_data
local perlin_base, perlin_detail, perlin_hum, perlin_temp

function minetest.get_biome_data(pos)
    if not pos then return nil end

    -- Falls aus irgendeinem Grund kein Singlenode aktiv ist, alten Engine-Weg nutzen
    if minetest.get_mapgen_setting("mg_name") ~= "singlenode" then
        return original_get_biome_data(pos)
    end

    -- Noises sicher erst bei Abfrage initialisieren (verhindert nil-Objekt-Fehler)
    perlin_base   = perlin_base   or minetest.get_perlin(NP_TERRAIN_BASE)
    perlin_detail = perlin_detail or minetest.get_perlin(NP_TERRAIN_DETAIL)
    perlin_hum    = perlin_hum    or minetest.get_perlin(NP_HUMIDITY)
    perlin_temp   = perlin_temp   or minetest.get_perlin(NP_TEMPERATURE)

    local pos2d = {x = pos.x, y = pos.z}
    local nv_base   = perlin_base:get_2d(pos2d) or 0
    local nv_detail = perlin_detail:get_2d(pos2d) or 0
    local surface_y = math.floor(nv_base + nv_detail)

    local hum_v  = perlin_hum:get_2d(pos2d) or 0.5
    local temp_v = perlin_temp:get_2d(pos2d) or 0.5

    local hum = math.max(0, math.min(1, hum_v))
    local temp_base = math.max(0, math.min(1, temp_v))

    local height_penalty = math.max(0, surface_y) * 0.005
    local temp = math.max(0, math.min(1, temp_base - height_penalty))

    local heat_val = temp * 100
    local hum_val = hum * 100

    -- Sucht das exakte Custom-Biom für die HUD-Anfrage heraus
    local biome = get_biome(heat_val, hum_val, pos.y)

    if biome and biome.engine_id then
        return {
            biome = biome.engine_id,
            heat = heat_val,
            humidity = hum_val
        }
    end

    return original_get_biome_data(pos)
end

-------------------------------------------------------------------------------
-- MAPGEN-CALLBACK
-------------------------------------------------------------------------------
local nm_base, nm_detail, nm_hum, nm_temp
local last_sx, last_sz = 0, 0

minetest.register_on_generated(function(minp, maxp, seed)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()
    local biome_map = minetest.get_mapgen_object("biomemap")

    local sx = maxp.x - minp.x + 1
    local sz = maxp.z - minp.z + 1

    -- Noise-Maps bei Chunkgrößenänderung initialisieren
    if sx ~= last_sx or sz ~= last_sz then
        local dims = {x = sx, y = sz, z = 1}
        nm_base   = minetest.get_perlin_map(NP_TERRAIN_BASE,   dims)
        nm_detail = minetest.get_perlin_map(NP_TERRAIN_DETAIL, dims)
        nm_hum    = minetest.get_perlin_map(NP_HUMIDITY,       dims)
        nm_temp   = minetest.get_perlin_map(NP_TEMPERATURE,    dims)
        last_sx, last_sz = sx, sz
    end

    local pos2d = {x = minp.x, y = minp.z}
    local nv_base   = nm_base:get_2d_map_flat(pos2d)
    local nv_detail = nm_detail:get_2d_map_flat(pos2d)
    local nv_hum    = nm_hum:get_2d_map_flat(pos2d)
    local nv_temp   = nm_temp:get_2d_map_flat(pos2d)

    for zi = 0, sz - 1 do
        for xi = 0, sx - 1 do
            local x = minp.x + xi
            local z = minp.z + zi
            local ni = zi * sx + xi + 1

            -- Geländehöhe berechnen
            local surface_y = math.floor((nv_base[ni] or 0) + (nv_detail[ni] or 0))

            -- Klima-Noise Werte (0.0 bis 1.0)
            local hum_v = nv_hum[ni] or 0.5
            local temp_v = nv_temp[ni] or 0.5

            local hum = math.max(0, math.min(1, hum_v))
            local temp_base = math.max(0, math.min(1, temp_v))

            -- Höhen-Temperatur-Malus
            local height_penalty = math.max(0, surface_y) * 0.005
            local temp = math.max(0, math.min(1, temp_base - height_penalty))

            -- Skalierung auf den Standardbereich der Engine (0 bis 100)
            local heat_val = temp * 100
            local hum_val = hum * 100

            -- Passendes Biom via Voronoi-Zuteilung holen
            local biome = get_biome(heat_val, hum_val, surface_y)

            -- Biom-Map schreiben, damit Engine-Dekorationen und Erze greifen
            if biome_map and biome.engine_id then
                biome_map[ni] = biome.engine_id
            end

            -- Spaltenweise Befüllung der Nodes von unten nach oben
            for y = emin.y, emax.y do
                local vi = area:index(x, y, z)

                if y > surface_y then
                    -- Über der Oberfläche: Wasser oder Luft
                    if y <= SEA_LEVEL then
                        data[vi] = c_water
                    else
                        data[vi] = c_air
                    end
                elseif y == surface_y then
                    -- Exakt auf der Oberfläche
                    if surface_y < SEA_LEVEL then
                        data[vi] = biome.stone
                    else
                        data[vi] = biome.top
                    end
                elseif y > surface_y - biome.top_depth then
                    -- Obere Deckschicht (node_top)
                    data[vi] = biome.top
                elseif y > surface_y - biome.top_depth - biome.filler_depth then
                    -- Füllschicht (node_filler)
                    data[vi] = biome.filler
                else
                    -- Geologische Tiefenschichten
                    if y < -400 then
                        data[vi] = (biome.stone == c_basalt) and c_basalt or c_granite
                    elseif y < -80 then
                        data[vi] = biome.stone
                    else
                        data[vi] = c_stone
                    end
                end
            end
        end
    end

    -- 1. Basis-Terrain (deine Biome & Tiefengesteine) in den VM laden
    vm:set_data(data)

    -- 2. ENGINE-PIPELINE MANUELL TRIGGERN (Löst dein Erz- & Dekorationen-Problem!)
    -- Da geology.lua vor ores.lua geladen wird, platziert die Engine hier zuerst
    -- die Schichten/Blobs (wie Schluff/Silt). Direkt danach sucht sie nach passenden
    -- Trägergesteinen für Erze – und findet den frisch generierten Schluff im VM!
    minetest.generate_ores(vm, minp, maxp)
    minetest.generate_decorations(vm, minp, maxp)

    -- 3. Licht, Flüssigkeiten berechnen und finaler Write-Abfluss
    vm:set_lighting({day = 15, night = 0}, emin, emax)
    vm:calc_lighting()
    vm:update_liquids()
    vm:write_to_map()
end)

-------------------------------------------------------------------------------
-- SPAWN- & RESPAWN-POSITIONIERUNG
-------------------------------------------------------------------------------
local function get_surface_y_spawn(x, z)
    perlin_base   = perlin_base   or minetest.get_perlin(NP_TERRAIN_BASE)
    perlin_detail = perlin_detail or minetest.get_perlin(NP_TERRAIN_DETAIL)

    local base_v   = perlin_base:get_2d({x = x, y = z}) or 0
    local detail_v = perlin_detail:get_2d({x = x, y = z}) or 0
    return math.floor(base_v + detail_v)
end

local function find_safe_spawn_pos()
    local radius = 0
    local max_radius = 1200
    local step = 16

    while radius < max_radius do
        for x = -radius, radius, step do
            for z = -radius, radius, step do
                if math.abs(x) == radius or math.abs(z) == radius then
                    local surface_y = get_surface_y_spawn(x, z)
                    if surface_y > 3 and surface_y < 85 then
                        return {x = x, y = surface_y + 2, z = z}
                    end
                end
            end
        end
        radius = radius + step
    end
    return {x = 0, y = 25, z = 0}
end

minetest.register_on_newplayer(function(player)
    player:set_pos(find_safe_spawn_pos())
end)

minetest.register_on_respawnplayer(function(player)
    player:set_pos(find_safe_spawn_pos())
    return true
end)

minetest.log("action", "[st_terrain] Custom Terrain Generator & HUD-Patch erfolgreich initialisiert!")

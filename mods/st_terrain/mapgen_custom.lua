-- st_terrain/mapgen_custom.lua
-- Benutzerdefinierter Terrain-Generator für den Singlenode-Mapgen.

local mg_name = minetest.get_mapgen_setting("mg_name")
if mg_name ~= "singlenode" then
    return
end

minetest.log("action", "[st_terrain] Singlenode erkannt – Custom Terrain Generator wird aktiviert.")

-------------------------------------------------------------------------------
-- NODE-REFERENZEN
-------------------------------------------------------------------------------
local c_air            = minetest.get_content_id("air")
local c_stone          = minetest.get_content_id("sti_core:stone")
local c_limestone      = minetest.get_content_id("sti_core:limestone")
local c_granite        = minetest.get_content_id("sti_core:granite")
local c_basalt         = minetest.get_content_id("sti_core:basalt")
local c_sand           = minetest.get_content_id("sti_core:sand")
local c_gravel         = minetest.get_content_id("sti_core:gravel")
local c_gravel_coarse  = minetest.get_content_id("sti_core:gravel_coarse")
local c_peat           = minetest.get_content_id("sti_core:peat")
local c_silt           = minetest.get_content_id("sti_core:silt")
local c_loam_brown     = minetest.get_content_id("sti_core:loam_brown")
local c_loam_yellow    = minetest.get_content_id("sti_core:loam_yellow")
local c_loam_red       = minetest.get_content_id("sti_core:loam_red")
local c_loam_grey      = minetest.get_content_id("sti_core:loam_grey")

local function node_id(preferred, fallback)
    if minetest.registered_nodes[preferred] then
        return minetest.get_content_id(preferred)
    end
    return minetest.get_content_id(fallback)
end

local c_grass       = node_id("default:dirt_with_grass",        "sti_core:loam_brown")
local c_dirt        = node_id("default:dirt",                   "sti_core:loam_brown")
local c_water       = node_id("default:water_source",           "air")
local c_snow_dirt   = node_id("default:dirt_with_snow",         "sti_core:loam_grey")
local c_snowblock   = node_id("default:snowblock",              "sti_core:gravel")
local c_dry_grass   = node_id("default:dry_dirt_with_dry_grass","sti_core:loam_red")
local c_desert_stone= node_id("default:desert_stone",          "sti_core:limestone")

local SEA_LEVEL = 0

-------------------------------------------------------------------------------
-- NOISE-PARAMETER (Für echte 3D-Flächenausdehnung)
-------------------------------------------------------------------------------
local NP_TERRAIN_BASE = {
    offset     = 18,         -- Durchschnittshöhe über Meeresspiegel
    scale      = 65,         -- Maximale Berghöhen
    spread     = {x = 250, y = 250, z = 250},
    seed       = 5842,
    octaves    = 5,
    persist    = 0.45,
    lacunarity = 2.0,
    flags      = "defaults",
}

local NP_TERRAIN_DETAIL = {
    offset     = 0,
    scale      = 15,         -- Hügeligkeit/Erosion
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
-- BIOM-TABELLE
-------------------------------------------------------------------------------
local BIOMES = {
    { name="st_polar", temp_min=0.0, temp_max=0.12, hum_min=0.0, hum_max=1.0, top=c_snowblock, top_depth=2, filler=c_loam_grey, filler_depth=2, stone=c_stone },
    { name="st_tundra", temp_min=0.12, temp_max=0.28, hum_min=0.0, hum_max=0.6, top=c_gravel_coarse, top_depth=1, filler=c_loam_grey, filler_depth=2, stone=c_granite },
    { name="st_snowy_grassland", temp_min=0.12, temp_max=0.32, hum_min=0.6, hum_max=1.0, top=c_snowblock, top_depth=1, filler=c_loam_grey, filler_depth=3, stone=c_stone },
    { name="st_taiga", temp_min=0.28, temp_max=0.42, hum_min=0.45, hum_max=1.0, top=c_snow_dirt, top_depth=1, filler=c_loam_grey, filler_depth=3, stone=c_granite },
    { name="st_alpine", temp_min=0.0, temp_max=0.35, hum_min=0.0, hum_max=0.45, top=c_granite, top_depth=1, filler=c_gravel_coarse, filler_depth=2, stone=c_granite },
    { name="st_grassland", temp_min=0.40, temp_max=0.58, hum_min=0.35, hum_max=0.65, top=c_grass, top_depth=1, filler=c_dirt, filler_depth=3, stone=c_stone },
    { name="st_deciduous_forest", temp_min=0.42, temp_max=0.62, hum_min=0.60, hum_max=1.0, top=c_grass, top_depth=1, filler=c_loam_brown, filler_depth=4, stone=c_stone },
    { name="st_swamp", temp_min=0.45, temp_max=0.65, hum_min=0.80, hum_max=1.0, top=c_peat, top_depth=2, filler=c_loam_grey, filler_depth=5, stone=c_limestone },
    { name="st_savanna", temp_min=0.58, temp_max=0.78, hum_min=0.15, hum_max=0.50, top=c_dry_grass, top_depth=1, filler=c_loam_red, filler_depth=4, stone=c_stone },
    { name="st_rainforest", temp_min=0.68, temp_max=1.0, hum_min=0.65, hum_max=1.0, top=c_grass, top_depth=1, filler=c_loam_yellow, filler_depth=5, stone=c_stone },
    { name="st_rocky_desert", temp_min=0.70, temp_max=1.0, hum_min=0.0, hum_max=0.10, top=c_desert_stone, top_depth=1, filler=c_gravel_coarse, filler_depth=3, stone=c_limestone },
    { name="st_desert", temp_min=0.72, temp_max=1.0, hum_min=0.0, hum_max=0.20, top=c_sand, top_depth=10, filler=c_gravel, filler_depth=3, stone=c_limestone },

    { name="st_mudflat", top=c_silt, top_depth=2, filler=c_loam_grey, filler_depth=3, stone=c_limestone },
    { name="st_beach", top=c_sand, top_depth=2, filler=c_gravel, filler_depth=2, stone=c_stone },
    { name="st_ocean", top=c_sand, top_depth=2, filler=c_gravel, filler_depth=3, stone=c_basalt },
}

local special_biomes = {}
for _, b in ipairs(BIOMES) do
    if b.name == "st_ocean" or b.name == "st_beach" or b.name == "st_mudflat" or b.name == "st_alpine" or b.name == "st_swamp" then
        special_biomes[b.name] = b
    end
end

local BIOME_DEFAULT = {
    name="st_fallback",
    top=c_grass, top_depth=1,
    filler=c_dirt, filler_depth=3,
    stone=c_stone,
}

local function get_biome(temp, hum, surface_y)
    if surface_y < SEA_LEVEL - 2 then
        return special_biomes["st_ocean"] or BIOME_DEFAULT
    end
    if surface_y >= SEA_LEVEL - 2 and surface_y <= SEA_LEVEL + 3 then
        if hum > 0.65 and temp > 0.30 and temp < 0.60 then
            return special_biomes["st_mudflat"] or BIOME_DEFAULT
        end
        return special_biomes["st_beach"] or BIOME_DEFAULT
    end
    if surface_y > 100 and temp < 0.38 then
        return special_biomes["st_alpine"] or BIOME_DEFAULT
    end
    if surface_y >= SEA_LEVEL and surface_y <= SEA_LEVEL + 4 then
        if hum > 0.80 and temp > 0.45 and temp < 0.65 then
            return special_biomes["st_swamp"] or BIOME_DEFAULT
        end
    end
    for _, b in ipairs(BIOMES) do
        if b.temp_min and temp >= b.temp_min and temp < b.temp_max
        and hum >= b.hum_min and hum < b.hum_max then
            return b
        end
    end
    return BIOME_DEFAULT
end

-------------------------------------------------------------------------------
-- MAPGEN-CALLBACK
-------------------------------------------------------------------------------
local nm_base, nm_detail, nm_hum, nm_temp
local last_sx, last_sz = 0, 0

minetest.register_on_generated(function(minp, maxp, seed)
    local t0 = os.clock()

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()

    local sx = maxp.x - minp.x + 1
    local sz = maxp.z - minp.z + 1

    -- Korrektur für flächige Noise-Auslesung
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

            local base_v   = nv_base[ni] or 0
            local detail_v = nv_detail[ni] or 0
            local hum_v    = nv_hum[ni] or 0.5
            local temp_v   = nv_temp[ni] or 0.5

            local surface_y = math.floor(base_v + detail_v)

            local hum = math.max(0, math.min(1, hum_v))
            local temp_base = math.max(0, math.min(1, temp_v))
            local height_penalty = math.max(0, surface_y) * 0.005
            local temp = math.max(0, math.min(1, temp_base - height_penalty))

            local biome = get_biome(temp, hum, surface_y)

            for y = emin.y, emax.y do
                local vi = area:index(x, y, z)

                if y > surface_y then
                    if y <= SEA_LEVEL then
                        data[vi] = c_water
                    else
                        data[vi] = c_air
                    end
                elseif y == surface_y then
                    if surface_y < SEA_LEVEL then
                        data[vi] = biome.stone
                    else
                        data[vi] = biome.top
                    end
                elseif y > surface_y - biome.top_depth then
                    data[vi] = biome.top
                elseif y > surface_y - biome.top_depth - biome.filler_depth then
                    data[vi] = biome.filler
                else
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

    vm:set_data(data)
    vm:set_lighting({day = 15, night = 0}, emin, emax)
    vm:calc_lighting()
    vm:update_liquids()
    vm:write_to_map()
end)

-------------------------------------------------------------------------------
-- SPAWN- & RESPAWN-SICHERUNG (Sicherer Festland-Spawn)
-------------------------------------------------------------------------------

-- Hilfsfunktion: Berechnet die genaue Oberfläche an einer X/Z Koordinate unabgängig von Voxelmanip
local function get_surface_y(x, z)
    local noise_base = minetest.get_perlin(NP_TERRAIN_BASE)
    local noise_detail = minetest.get_perlin(NP_TERRAIN_DETAIL)

    local base_v = noise_base:get_2d({x = x, y = z}) or 0
    local detail_v = noise_detail:get_2d({x = x, y = z}) or 0

    return math.floor(base_v + detail_v)
end

-- Suchschleife nach sicherem, flachem Festland
local function find_safe_spawn_pos()
    local radius = 0
    local max_radius = 1200
    local step = 16

    minetest.log("action", "[st_terrain] Analysiere Weltkarte für sicheren Festland-Spawn...")

    while radius < max_radius do
        for x = -radius, radius, step do
            for z = -radius, radius, step do
                if math.abs(x) == radius or math.abs(z) == radius then
                    local surface_y = get_surface_y(x, z)

                    -- Filter: y > 3 (Kein Ozean, kein Strand) und y < 85 (Keine extremen Klippen)
                    if surface_y > 3 and surface_y < 85 then
                        minetest.log("action", string.format("[st_terrain] Sicherer Festland-Spawn fixiert bei X=%d, Y=%d, Z=%d", x, surface_y + 2, z))
                        return {x = x, y = surface_y + 2, z = z}
                    end
                end
            end
        end
        radius = radius + step
    end

    return {x = 0, y = 25, z = 0} -- Ultimativer Nothalt
end

-- Hook für neue Spieler (Erst-Spawn)
minetest.register_on_newplayer(function(player)
    local safe_pos = find_safe_spawn_pos()
    player:set_pos(safe_pos)
end)

-- Hook für den Tod (Sicherer Wiederaufstieg)
minetest.register_on_respawnplayer(function(player)
    local safe_pos = find_safe_spawn_pos()
    player:set_pos(safe_pos)
    return true -- Standard-Engine-Spawn überschreiben
end)

minetest.log("action", "[st_terrain] Custom Terrain Generator (Singlenode) erfolgreich initialisiert.")

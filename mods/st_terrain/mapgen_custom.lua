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

local c_air           = get_node_id("air")
local c_water         = get_node_id("mapgen_water_source", "default:water_source")
local c_lava          = get_node_id("mapgen_lava_source", "default:lava_source")
local c_stone         = get_node_id("sti_core:stone")
local c_basalt        = get_node_id("sti_core:basalt")
local c_granite       = get_node_id("sti_core:granite")

-- DYNAMISCHES KRISTALL-ARRAY
local crystal_ids = {}

minetest.register_on_mods_loaded(function()
    if sti_core and sti_core.crystals then
        for _, nodename in ipairs(sti_core.crystals) do
            local id = minetest.get_content_id(nodename)
            if id then
                table.insert(crystal_ids, id)
            end
        end
    end

    if #crystal_ids == 0 then
        local fallbacks = {"sti_core:crystal_red", "sti_core:crystal_blue", "sti_core:crystal_green"}
        for _, name in ipbacks do
            local id = get_node_id(name, "air")
            if id ~= c_air then
                table.insert(crystal_ids, id)
            end
        end
    end
end)

local SEA_LEVEL = 0
local cached_biomes = {}

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

if st_terrain and st_terrain.biome_list then
    for _, name in ipairs(st_terrain.biome_list) do
        local b_def = minetest.registered_biomes[name]
        if b_def then
            cache_biome(name, b_def)
        end
    end
end

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

-- 1. SYSTEM: Verbindungshöhlen (Tunnel von Oberfläche bis -850)
local NP_CAVES_UPPER = {
    offset     = 0,
    scale      = 1,
    spread     = {x = 55, y = 40, z = 55},  -- Etwas größerer Spread für längere Tunnelketten
    seed       = 2468,
    octaves    = 3,
    persist    = 0.60,
    lacunarity = 2.0,
    flags      = "defaults",
}

-- 2. SYSTEM: Gigantische Nether-Hallen (Erst ab -800 abwärts)
local NP_CAVES_DEEP = {
    offset     = 0,
    scale      = 1,
    spread     = {x = 220, y = 90, z = 220}, -- Gewaltiger Spread für epische Höhlendimensionen
    seed       = 9112,
    octaves    = 4,
    persist    = 0.60,
    lacunarity = 2.0,
    flags      = "defaults",
}

-------------------------------------------------------------------------------
-- VORONOI BIOM-FINDER
-------------------------------------------------------------------------------
local function get_biome(heat, humidity, y)
    local best_biome = nil
    local min_dist = math.huge

    for _, b in ipairs(cached_biomes) do
        if y >= b.y_min and y <= b.y_max then
            local d_heat = heat - b.heat_point
            local d_hum = humidity - b.humidity_point
            local dist = (d_heat * d_heat) + (d_hum * d_hum)

            if dist < min_dist then
                min_dist = dist
                best_biome = b
            end
        end
    end

    return best_biome or cached_biomes[1]
end

-------------------------------------------------------------------------------
-- ENGINE MONKEY-PATCH (HUD-Biom-Fix)
-------------------------------------------------------------------------------
local original_get_biome_data = minetest.get_biome_data
local perlin_base, perlin_detail, perlin_hum, perlin_temp

function minetest.get_biome_data(pos)
    if not pos then return nil end

    if minetest.get_mapgen_setting("mg_name") ~= "singlenode" then
        return original_get_biome_data(pos)
    end

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
local nm_base, nm_detail, nm_hum, nm_temp, nm_caves_upper, nm_caves_deep
local last_sx, last_sz, last_sy = 0, 0, 0

minetest.register_on_generated(function(minp, maxp, seed)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()
    local biome_map = minetest.get_mapgen_object("biomemap")

    local sx = maxp.x - minp.x + 1
    local sz = maxp.z - minp.z + 1
    local sy = maxp.y - minp.y + 1

    if sx ~= last_sx or sz ~= last_sz or sy ~= last_sy then
        local dims2d = {x = sx, y = sz, z = 1}
        local dims3d = {x = sx, y = sy, z = sz}
        nm_base        = minetest.get_perlin_map(NP_TERRAIN_BASE,   dims2d)
        nm_detail      = minetest.get_perlin_map(NP_TERRAIN_DETAIL, dims2d)
        nm_hum         = minetest.get_perlin_map(NP_HUMIDITY,       dims2d)
        nm_temp        = minetest.get_perlin_map(NP_TEMPERATURE,    dims2d)
        nm_caves_upper = minetest.get_perlin_map(NP_CAVES_UPPER,    dims3d)
        nm_caves_deep  = minetest.get_perlin_map(NP_CAVES_DEEP,     dims3d)
        last_sx, last_sz, last_sy = sx, sz, sy
    end

    local pos2d = {x = minp.x, y = minp.z}
    local nv_base        = nm_base:get_2d_map_flat(pos2d)
    local nv_detail      = nm_detail:get_2d_map_flat(pos2d)
    local nv_hum         = nm_hum:get_2d_map_flat(pos2d)
    local nv_temp        = nm_temp:get_2d_map_flat(pos2d)
    local nv_caves_upper = nm_caves_upper:get_3d_map_flat(minp)
    local nv_caves_deep  = nm_caves_deep:get_3d_map_flat(minp)

    for zi = 0, sz - 1 do
        for xi = 0, sx - 1 do
            local x = minp.x + xi
            local z = minp.z + zi
            local ni = zi * sx + xi + 1

            local surface_y = math.floor((nv_base[ni] or 0) + (nv_detail[ni] or 0))

            local hum_v = nv_hum[ni] or 0.5
            local temp_v = nv_temp[ni] or 0.5

            local hum = math.max(0, math.min(1, hum_v))
            local temp_base = math.max(0, math.min(1, temp_v))

            local height_penalty = math.max(0, surface_y) * 0.005
            local temp = math.max(0, math.min(1, temp_base - height_penalty))

            local heat_val = temp * 100
            local hum_val = hum * 100

            local biome = get_biome(heat_val, hum_val, surface_y)

            if biome_map and biome.engine_id then
                biome_map[ni] = biome.engine_id
            end

            local was_solid = true
            if minp.y > emin.y then
                local vi_below = area:index(x, minp.y - 1, z)
                local node_below = data[vi_below]
                was_solid = (node_below ~= c_air and node_below ~= c_water and node_below ~= c_lava)
            end

            for y = minp.y, maxp.y do
                local vi = area:index(x, y, z)
                local current_node = data[vi]

                if y > surface_y then
                    if current_node == c_air or current_node == c_water then
                        if y <= SEA_LEVEL then
                            data[vi] = c_water
                        else
                            data[vi] = c_air
                        end
                    end
                    was_solid = false
                else
                    local node_to_place = c_stone
                    local current_is_solid = true

                    if y == surface_y then
                        if surface_y < SEA_LEVEL then
                            node_to_place = biome.stone
                        else
                            node_to_place = biome.top
                        end
                    elseif y > surface_y - biome.top_depth then
                        node_to_place = biome.top
                    elseif y > surface_y - biome.top_depth - biome.filler_depth then
                        node_to_place = biome.filler
                    else
                        if y < -400 then
                            node_to_place = (biome.stone == c_basalt) and c_basalt or c_granite
                        elseif y < -80 then
                            node_to_place = biome.stone
                        else
                            node_to_place = c_stone
                        end
                    end

                    -----------------------------------------------------------
                    -- DUAL-HÖHLEN LOGIK
                    -----------------------------------------------------------
                    local is_cave = false
                    local fill_with = c_air

                    local yi = y - minp.y
                    local ni3d = zi * sx * sy + yi * sx + xi + 1

                    -- SYSTEM 1: Obere Verbindungshöhlen (Oberfläche bis -850)
                    if y <= surface_y and y >= -850 then
                        -- Erlaubt Ausbrüche an der Oberfläche (Eingänge!), verhindert aber Löcher im Meeresboden
                        if surface_y >= SEA_LEVEL or y < surface_y - 4 then
                            -- Schwellenwert auf 0.12 gesenkt -> Höhlen sind deutlich häufiger und größer!
                            if nv_caves_upper[ni3d] and nv_caves_upper[ni3d] > 0.12 then
                                is_cave = true
                                fill_with = c_air
                            end
                        end
                    end

                    -- SYSTEM 2: Tiefe Riesenhöhlen (Nether-artig erst AB -800)
                    if y < -800 then
                        -- Schwellenwert auf 0.10 gesenkt -> Extrem massive Hallenräume
                        if nv_caves_deep[ni3d] and nv_caves_deep[ni3d] > 0.10 then
                            is_cave = true
                            -- Lavaspiegel innerhalb der Riesenhöhlen ab -1000
                            if y <= -1000 then
                                fill_with = c_lava
                            else
                                fill_with = c_air
                            end
                        end
                    end

                    -----------------------------------------------------------
                    -- NODE PLATZIERUNG & KRISTALLE
                    -----------------------------------------------------------
                    if is_cave then
                        data[vi] = fill_with

                        if was_solid and fill_with == c_air then
                            local pseudo_rand = (x * 17 + y * 31 + z * 43) % 100
                            if pseudo_rand < 8 and #crystal_ids > 0 then
                                local c_idx = (math.abs(x + y + z) % #crystal_ids) + 1
                                data[vi] = crystal_ids[c_idx]
                            end
                        end
                        was_solid = false
                    else
                        data[vi] = node_to_place
                        was_solid = current_is_solid
                    end
                end
            end
        end
    end

    vm:set_data(data)
    minetest.generate_ores(vm, minp, maxp)
    minetest.generate_decorations(vm, minp, maxp)
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

-- 1. MENÜ-EINSTELLUNGEN AUSLESEN (mit Fallback-Werten)
local map_scale      = tonumber(minetest.settings:get("sti_terrain_scale")) or 1.0
local continent_size = tonumber(minetest.settings:get("sti_terrain_continent_size")) or 8000
local river_depth_mod = tonumber(minetest.settings:get("sti_terrain_river_depth")) or 1.0

-- Lokale Math-Funktionen für massiv bessere Performance in LVM-Schleifen
local math_floor  = math.floor
local math_abs    = math.abs
local math_random = math.random

-- 2. IDs UND CONFIGS
local c_air, c_water, c_stone, c_clay_gold
local ids_initialized = false

-- 🌲 BIOM-DEFINITIONEN (Jetzt mit Bäumen und Erzen aus sti_core)
local biomes = {
    -- 🏔️ ALPINE BIOME (Hohe Berge)
    {
        name = "Gletscher", min_height = 450, max_height = 1000, min_temp = -2, max_temp = 0.2, min_humid = -1, max_humid = 1,
        top_node = "default:snowblock", filler_node = "default:ice", depth = 4,
        ores = {
            {name = "sti_core:stone_with_silver_dense", chance = 300},
            {name = "sti_core:stone_with_titanium_medium", chance = 500}
        }
    },
    {
        name = "Alpines Hochland", min_height = 300, max_height = 450, min_temp = -1, max_temp = 0.5, min_humid = -1, max_humid = 1,
        top_node = "default:dirt_with_snow", filler_node = "default:dirt", depth = 3,
        tree_type = "pine", tree_chance = 60, -- 1 zu 60 Chance pro Oberflächenblock
        ores = {
            {name = "sti_core:stone_with_iron_dense", chance = 200},
            {name = "sti_core:stone_with_lead_sparse", chance = 400}
        }
    },
    -- 🌋 VULKAN
    {
        name = "Vulkanisches Ödland", min_height = 250, max_height = 800, min_temp = 0.8, max_temp = 2.0, min_humid = -1, max_humid = -0.4,
        top_node = "default:gravel", filler_node = "default:desert_stone", depth = 5,
        ores = {
            {name = "sti_core:stone_with_sulfur_dense", chance = 150},
            {name = "sti_core:stone_with_carbon_medium", chance = 200},
            {name = "sti_core:stone_with_uranium_sparse", chance = 800}
        }
    },
    -- 🌲 GEMÄSSIGTE BIOME
    {
        name = "Nadelwald", min_height = 5, max_height = 300, min_temp = 0.0, max_temp = 0.5, min_humid = 0.2, max_humid = 1,
        top_node = "default:dirt_with_coniferous_litter", filler_node = "default:dirt", depth = 4,
        tree_type = "pine", tree_chance = 25,
        ores = {
            {name = "sti_core:stone_with_copper_medium", chance = 250},
            {name = "sti_core:stone_with_zinc_sparse", chance = 400}
        }
    },
    {
        name = "Grüne Wiese / Felder", min_height = 3, max_height = 120, min_temp = 0.3, max_temp = 0.8, min_humid = -0.2, max_humid = 0.4,
        top_node = "default:dirt_with_grass", filler_node = "default:dirt", depth = 3,
        tree_type = "apple", tree_chance = 80, -- Weniger Bäume, mehr Wiese
        ores = {
            {name = "sti_core:stone_with_iron_medium", chance = 300},
            {name = "sti_core:stone_with_tin_sparse", chance = 350}
        }
    },
    -- ⏳ TROCKENE BIOME
    {
        name = "Wüste", min_height = 2, max_height = 150, min_temp = 0.7, max_temp = 2.0, min_humid = -1, max_humid = -0.3,
        top_node = "default:desert_sand", filler_node = "default:desert_stone", depth = 6,
        ores = {
            {name = "sti_core:stone_with_silicon_dense", chance = 200},
            {name = "sti_core:stone_with_aluminum_medium", chance = 300}
        }
    },
    -- 🏖️ KÜSTEN
    {
        name = "Sandstrand", min_height = -1, max_height = 3, min_temp = 0.2, max_temp = 1.5, min_humid = -1, max_humid = 1,
        top_node = "default:sand", filler_node = "default:sand", depth = 4,
        ores = {} -- Strände haben meist keine tiefen Erze direkt unter der Oberfläche
    },
}

-- Noise-Parameter nutzen jetzt die Werte aus dem Menü
local np_continents = { offset = -0.1, scale = 1.2, spread = {x = continent_size, y = continent_size, z = continent_size}, seed = 42069, octaves = 5, persist = 0.5, lacunarity = 2.2 }
local np_ridges     = { offset = 0, scale = 1, spread = {x = 1200, y = 1200, z = 1200}, seed = 71113, octaves = 6, persist = 0.45, lacunarity = 2.14 }
local np_temp       = { offset = 0.4, scale = 0.6, spread = {x = 10000, y = 10000, z = 10000}, seed = 12345, octaves = 3, persist = 0.5, lacunarity = 2.0 }
local np_humidity   = { offset = 0, scale = 1, spread = {x = 6000, y = 6000, z = 6000}, seed = 54321, octaves = 3, persist = 0.5, lacunarity = 2.0 }
local np_rivers     = { offset = 0, scale = 1, spread = {x = 800, y = 800, z = 800}, seed = 9876, octaves = 4, persist = 0.5, lacunarity = 2.0 }

local perlin_continents, perlin_ridges, perlin_rivers

local function get_biome(height, temp, humid)
    for _, b in ipairs(biomes) do
        if height >= b.min_height and height <= b.max_height and temp >= b.min_temp and temp <= b.max_temp and humid >= b.min_humid and humid <= b.max_humid then
            return b
        end
    end
    return biomes[5] -- Fallback: Grüne Wiese
end

local function get_terrain_height(x, z)
    if not perlin_continents then
        perlin_continents = minetest.get_perlin(np_continents)
        perlin_ridges     = minetest.get_perlin(np_ridges)
        perlin_rivers     = minetest.get_perlin(np_rivers)
    end

    local cont_val   = perlin_continents:get_2d({x = x, y = z})
    local ridge_val  = perlin_ridges:get_2d({x = x, y = z})
    local river_val  = perlin_rivers:get_2d({x = x, y = z})

    local sharp_ridge = (1.0 - math_abs(ridge_val)) ^ 2
    local target_height = 0

    if cont_val > 0 then
        local max_regional_height = cont_val * (600 * map_scale)
        target_height = sharp_ridge * max_regional_height + (cont_val * 15)

        local river_threshold = math_abs(river_val)
        if river_threshold < 0.04 and target_height < 150 then
            local river_depth = ((0.04 - river_threshold) / 0.04) * river_depth_mod
            target_height = target_height * (1.0 - river_depth) - (river_depth * 4)
        end
    else
        target_height = cont_val * 120
    end
    return math_floor(target_height)
end

-- 3. DER GENERATOR
minetest.register_on_generated(function(minp, maxp, blockseed)
    -- Initialisiere alle Block-IDs beim ersten Durchlauf
    if not ids_initialized then
        c_stone = minetest.get_content_id("default:stone")
        c_air = minetest.get_content_id("air")
        c_water = minetest.get_content_id("default:water_source")

        -- Spezielles Fluss-Erz (Dein Wunsch: Clay + Gold)
        c_clay_gold = minetest.get_content_id("sti_core:clay_with_gold_medium")

        for _, b in ipairs(biomes) do
            b.c_top = minetest.get_content_id(b.top_node)
            b.c_filler = minetest.get_content_id(b.filler_node)
            if b.c_top == minetest.CONTENT_UNKNOWN then b.c_top = c_stone end
            if b.c_filler == minetest.CONTENT_UNKNOWN then b.c_filler = c_stone end

            -- Lade die Content-IDs für die Erze dieses Bioms
            if b.ores then
                for _, ore in ipairs(b.ores) do
                    ore.c_id = minetest.get_content_id(ore.name)
                end
            end
        end
        ids_initialized = true
    end

    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    local data = vm:get_data()
    local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

    local sidelen = maxp.x - minp.x + 1
    local chsize = {x = sidelen, y = sidelen, z = sidelen}
    local chunk_2d = {x = minp.x, y = minp.z}

    local n_cont   = minetest.get_perlin_map(np_continents, chsize):get_2d_map_flat(chunk_2d)
    local n_ridge  = minetest.get_perlin_map(np_ridges, chsize):get_2d_map_flat(chunk_2d)
    local n_temp   = minetest.get_perlin_map(np_temp, chsize):get_2d_map_flat(chunk_2d)
    local n_humid  = minetest.get_perlin_map(np_humidity, chsize):get_2d_map_flat(chunk_2d)
    local n_rivers = minetest.get_perlin_map(np_rivers, chsize):get_2d_map_flat(chunk_2d)

    local nixz = 1
    local trees_to_place = {} -- Speichert Positionen für Bäume

    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            local cont_val   = n_cont[nixz]
            local ridge_val  = n_ridge[nixz]
            local base_temp  = n_temp[nixz]
            local humid_val  = n_humid[nixz]
            local river_val  = n_rivers[nixz]

            local sharp_ridge = (1.0 - math_abs(ridge_val)) ^ 2
            local target_height = 0
            local is_river = false

            if cont_val > 0 then
                local max_regional_height = cont_val * (600 * map_scale)
                target_height = sharp_ridge * max_regional_height + (cont_val * 15)

                local river_threshold = math_abs(river_val)
                if river_threshold < 0.04 and target_height < 150 then
                    local river_depth = ((0.04 - river_threshold) / 0.04) * river_depth_mod
                    target_height = target_height * (1.0 - river_depth) - (river_depth * 4)
                    is_river = true -- Markiere diese X/Z-Spalte als Fluss!
                end
            else
                target_height = cont_val * 120
            end

            local surface_y = math_floor(target_height)
            local actual_temp = base_temp - (surface_y * 0.003)
            local biome = get_biome(surface_y, actual_temp, humid_val)

            for y = minp.y, maxp.y do
                local vi = area:index(x, y, z)
                if y <= surface_y then
                    local depth = surface_y - y
                    if depth == 0 then
                        data[vi] = biome.c_top

                        -- BAUM-LOGIK: Vormerken, wenn wir über Wasser sind
                        if y > 1 and biome.tree_type and math_random(1, biome.tree_chance) == 1 then
                            table.insert(trees_to_place, {pos = {x=x, y=y+1, z=z}, type = biome.tree_type})
                        end

                    elseif depth <= biome.depth then
                        data[vi] = biome.c_filler
                    else
                        -- TIEFERER STEIN & ERZ-GENERIERUNG
                        local node_to_place = c_stone

                        -- 1. Fluss-Erze priorisieren (Clay + Gold knapp unter dem Flussbett)
                        if is_river and depth < 10 and math_random(1, 40) == 1 then
                            node_to_place = c_clay_gold

                        -- 2. Normale Biom-Erze
                        elseif biome.ores then
                            for _, ore in ipairs(biome.ores) do
                                if math_random(1, ore.chance) == 1 then
                                    node_to_place = ore.c_id
                                    break -- Nur ein Erz pro Block platzieren
                                end
                            end
                        end

                        data[vi] = node_to_place
                    end
                elseif y <= 0 then
                    data[vi] = c_water
                else
                    data[vi] = c_air
                end
            end
            nixz = nixz + 1
        end
    end

    vm:set_data(data)
    vm:calc_lighting()
    vm:update_liquids()
    vm:write_to_map()

    -- 🌳 BÄUME PFLANZEN (Sicher nach dem LVM-Durchlauf)
    for _, tree in ipairs(trees_to_place) do
        if tree.type == "pine" then
            default.grow_pine_tree(tree.pos)
        elseif tree.type == "apple" then
            -- 25% Chance auf einen Apfelbaum, sonst normaler Baum
            default.grow_tree(tree.pos, math_random(1, 4) == 1)
        end
    end

end)

-- --- 🚪 INTELLIGENTES SPAWN-SYSTEM ---
minetest.register_on_newplayer(function(player)
    local x, z = 0, 0
    local attempts = 0
    local max_attempts = 100
    local step = 80

    minetest.log("action", "[sti_terrain] Suche sicheren Spawnpoint auf dem Festland...")

    while attempts < max_attempts do
        local height = get_terrain_height(x, z)

        if height > 3 then
            player:set_pos({x = x, y = height + 2, z = z})
            minetest.log("action", "[sti_terrain] Sicherer Spawn gefunden bei X="..x.." Z="..z)
            return
        end

        attempts = attempts + 1
        x = x + math.sin(attempts) * (attempts * step)
        z = z + math.cos(attempts) * (attempts * step)
    end

    player:set_pos({x = 0, y = 50, z = 0})
end)

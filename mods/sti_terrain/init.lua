-- Wir definieren die IDs als lokale Variablen, weisen sie aber erst später zu
local c_stone, c_water, c_air
local ids_initialized = false

-- 1. RAUSCH-PARAMETER
local np_continents = {
    offset = -0.1,
    scale = 1.2,
    spread = {x = 8000, y = 8000, z = 8000},
    seed = 42069,
    octaves = 5,
    persist = 0.5,
    lacunarity = 2.2,
}

local np_ridges = {
    offset = 0,
    scale = 1,
    spread = {x = 1200, y = 1200, z = 1200},
    seed = 71113,
    octaves = 6,
    persist = 0.45,
    lacunarity = 2.14,
}

-- 2. DER GENERATOR
minetest.register_on_generated(function(minp, maxp, blockseed)

    -- IDs einmalig initialisieren, wenn der erste Chunk generiert wird
    if not ids_initialized then
        c_stone = minetest.get_content_id("mapgen_stone")
        if c_stone == minetest.CONTENT_IGNORE or c_stone == minetest.CONTENT_UNKNOWN then
            c_stone = minetest.get_content_id("default:stone")
        end

        c_water = minetest.get_content_id("mapgen_water_source")
        if c_water == minetest.CONTENT_IGNORE or c_water == minetest.CONTENT_UNKNOWN then
            c_water = minetest.get_content_id("default:water_source")
        end

        c_air = minetest.get_content_id("air")
        ids_initialized = true
    end

    -- KORREKTUR FÜR SINGLENODE:
    -- Manuell ein VoxelManip-Objekt für diesen Chunk erzeugen statt es vom Mapgen zu holen
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)

    local data = vm:get_data()
    local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

    local sidelen = maxp.x - minp.x + 1
    local chsize = {x = sidelen, y = sidelen, z = sidelen}

    local noisemapped_cont = minetest.get_perlin_map(np_continents, chsize):get_2d_map_flat({x = minp.x, y = minp.z})
    local noisemapped_ridge = minetest.get_perlin_map(np_ridges, chsize):get_2d_map_flat({x = minp.x, y = minp.z})

    local nixz = 1

    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do

            local cont_val = noisemapped_cont[nixz]
            local ridge_val = noisemapped_ridge[nixz]

            -- Ridged Multi-Fractal Mathematik
            local sharp_ridge = 1.0 - math.abs(ridge_val)
            sharp_ridge = sharp_ridge * sharp_ridge

            local target_height = 0

            if cont_val > 0 then
                local max_regional_height = cont_val * 600
                target_height = sharp_ridge * max_regional_height + (cont_val * 15)
            else
                target_height = cont_val * 120
            end

            for y = minp.y, maxp.y do
                local vi = area:index(x, y, z)

                if y <= target_height then
                    data[vi] = c_stone
                elseif y <= 0 then
                    data[vi] = c_water
                else
                    data[vi] = c_air
                end
            end

            nixz = nixz + 1
        end
    end

    -- Daten manuell in den Map-Speicher zurückschreiben
    vm:set_data(data)
    vm:calc_lighting()
    vm:update_liquids()
    vm:write_to_map()
end)

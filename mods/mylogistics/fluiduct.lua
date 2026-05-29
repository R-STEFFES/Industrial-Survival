-- =======================================================================
-- MYLOGISTICS - FLUIDUCTS (BALANCED FLOW & DIRECTION FIX)
-- =======================================================================

local directions = {
    {x=0, y=1, z=0},  {x=0, y=-1, z=0}, -- Vertikal
    {x=1, y=0, z=0},  {x=-1, y=0, z=0}, -- Horizontal X
    {x=0, y=0, z=1},  {x=0, y=0, z=-1}  -- Horizontal Z
}

local function find_tank_controller(pos)
    return minetest.find_node_near(pos, 10, {"mytank:controller_active", "mytank:controller"})
end

local function process_fluid_transport(pos)
    local meta = minetest.get_meta(pos)
    local fluid = meta:get_string("fluid")
    local amount = meta:get_int("amount")
    local node_name = minetest.get_node(pos).name
    local display_timer = meta:get_int("display_timer") or 0

    -- 1. ABSAUGEN (Pumpe/Outlet)
    if amount < 200 then
        for _, dir in ipairs(directions) do
            local neighbor_pos = vector.add(pos, dir)
            local neighbor_node = minetest.get_node(neighbor_pos)

            if neighbor_node.name == "sti_machines:steam_pump" then
                local pmeta = minetest.get_meta(neighbor_pos)
                local pump_amount = pmeta:get_int("tank_amount")
                if pump_amount > 0 and (fluid == "" or fluid == "water") then
                    local transfer = math.min(200 - amount, pump_amount)
                    fluid = "water"
                    amount = amount + transfer
                    pmeta:set_int("tank_amount", pump_amount - transfer)
                    display_timer = 5
                    break
                end
            elseif neighbor_node.name == "mytank:outlet" then
                local c_pos = find_tank_controller(neighbor_pos)
                if c_pos then
                    local cmeta = minetest.get_meta(c_pos)
                    local t_amt = cmeta:get_int("amount")
                    local t_fl  = cmeta:get_string("fluid")
                    if t_amt > 0 and (fluid == "" or fluid == t_fl) then
                        local transfer = math.min(200 - amount, t_amt)
                        fluid = t_fl
                        amount = amount + transfer
                        cmeta:set_int("amount", t_amt - transfer)
                        display_timer = 5
                        if mytank and mytank.check_and_calculate_tank then mytank.check_and_calculate_tank(c_pos) end
                        break
                    end
                end
            end
        end
    end

    -- 2. VERTEILUNG (Der Fix für die Seiten-Logik)
    if amount > 0 and fluid ~= "" then
        local targets = {}

        -- Erst alle möglichen Ziele in alle Richtungen finden
        for _, dir in ipairs(directions) do
            local npos = vector.add(pos, dir)
            local nnode = minetest.get_node(npos)

            if nnode.name == "mytank:inlet" then
                table.insert(targets, {pos = npos, type = "tank"})
            elseif minetest.get_item_group(nnode.name, "fluiduct") > 0 then
                local nmeta = minetest.get_meta(npos)
                if nmeta:get_int("amount") < 200 and (nmeta:get_string("fluid") == "" or nmeta:get_string("fluid") == fluid) then
                    table.insert(targets, {pos = npos, type = "duct"})
                end
            end
        end

        -- Wenn Ziele gefunden wurden, Flüssigkeit gleichmäßig aufteilen
        if #targets > 0 then
            local share = math.floor(amount / #targets)
            if share < 1 then share = amount end -- Falls sehr wenig drin ist, gib alles an den ersten

            for _, target in ipairs(targets) do
                if amount <= 0 then break end
                local transfer = math.min(amount, share)

                if target.type == "tank" then
                    local c_pos = find_tank_controller(target.pos)
                    if c_pos then
                        local cmeta = minetest.get_meta(c_pos)
                        local c_cap = cmeta:get_int("capacity")
                        local c_amt = cmeta:get_int("amount")
                        local t_final = math.min(transfer, c_cap - c_amt)
                        cmeta:set_string("fluid", fluid)
                        cmeta:set_int("amount", c_amt + t_final)
                        amount = amount - t_final
                        if mytank and mytank.check_and_calculate_tank then mytank.check_and_calculate_tank(c_pos) end
                    end
                else
                    local nmeta = minetest.get_meta(target.pos)
                    local n_amt = nmeta:get_int("amount")
                    local t_final = math.min(transfer, 200 - n_amt)
                    nmeta:set_string("fluid", fluid)
                    nmeta:set_int("amount", n_amt + t_final)
                    nmeta:set_int("display_timer", 5)
                    amount = amount - t_final
                end
            end
        end
    end

    -- Meta & Visualisierung
    meta:set_int("amount", amount)
    meta:set_string("fluid", amount > 0 and fluid or (display_timer > 0 and fluid or ""))

    if display_timer > 0 then display_timer = display_timer - 1 end
    meta:set_int("display_timer", display_timer)

    local base_name = node_name:gsub("_water", ""):gsub("_lava", "")
    local target_node = base_name

    if (amount > 0 or display_timer > 0) and fluid ~= "" then
        if minetest.registered_nodes[base_name .. "_" .. fluid] then
            target_node = base_name .. "_" .. fluid
        end
        meta:set_string("infotext", "Fluiduct (" .. fluid .. ")\nStatus: Aktiv")
    else
        meta:set_string("infotext", "Fluiduct\nStatus: Leer")
    end

    if node_name ~= target_node then
        minetest.swap_node(pos, {name = target_node})
    end
end

-- REGISTRIERUNGS-FUNKTION (Standard & Glas)
local function register_duct(name, desc, tiles, alpha)
    local variants = {
        {suffix = "",       tex = ""},
        {suffix = "_water", tex = "default_water.png^"},
        {suffix = "_lava",  tex = "default_lava.png^"}
    }

    for _, v in ipairs(variants) do
        local node_tiles = table.copy(tiles)
        if v.tex ~= "" then node_tiles[1] = v.tex .. node_tiles[1] end

        minetest.register_node(name .. v.suffix, {
            description = desc,
            drawtype = "nodebox",
            paramtype = "light",
            use_texture_alpha = alpha,
            tiles = node_tiles,
            groups = {cracky = 3, fluiduct = 1, not_in_creative_inventory = (v.suffix == "" and 0 or 1)},
            drop = name,
            node_box = {
                type = "connected",
                fixed = {{-0.2, -0.2, -0.2, 0.2, 0.2, 0.2}},
                connect_top = {{-0.2, 0.2, -0.2, 0.2, 0.5, 0.2}},
                connect_bottom = {{-0.2, -0.5, -0.2, 0.2, -0.2, 0.2}},
                connect_front = {{-0.2, -0.2, -0.5, 0.2, 0.2, -0.2}},
                connect_back = {{-0.2, -0.2, 0.2, 0.2, 0.2, 0.5}},
                connect_left = {{-0.5, -0.2, -0.2, -0.2, 0.2, 0.2}},
                connect_right = {{0.2, -0.2, -0.2, 0.5, 0.2, 0.2}},
            },
            connects_to = {"group:fluiduct", "mytank:inlet", "mytank:outlet", "group:machine_fluid"},
            on_construct = function(pos)
                minetest.get_node_timer(pos):start(0.2)
            end,
            on_timer = function(pos, elapsed)
                process_fluid_transport(pos)
                return true
            end,
        })
    end
end

register_duct("mylogistics:fluiduct", "Fluiduct (Standard)", {"mylogistics_fluiduct.png"}, nil)
register_duct("mylogistics:fluiduct_glass", "Fluiduct (Glas)", {"mylogistics_fluiduct_glass.png"}, "blend")

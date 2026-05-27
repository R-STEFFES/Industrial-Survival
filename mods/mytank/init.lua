local tank = {}

-- =======================================================================
-- 1. GEOMETRISCHE MULTIBLOCK-ERKENNUNG (Box-Validierung)
-- =======================================================================

function tank.check_and_calculate_tank(controller_pos)
    local current_node = minetest.get_node(controller_pos)

    -- Schritt 1: Wir müssen die Dimensionen des Tanks bestimmen.
    -- Wir suchen die minimale und maximale Ecke des Tanks.
    -- Da der Controller Teil der Wand ist, starten wir von dort und tasten uns vor.

    local min_p = {x = controller_pos.x, y = controller_pos.y, z = controller_pos.z}
    local max_p = {x = controller_pos.x, y = controller_pos.y, z = controller_pos.z}

    -- Hilfsfunktion, um zu prüfen, ob ein Block zum Tank-System gehört
    local function is_tank_part(name)
        return name == "mytank:wall" or name == "mytank:glass" or
               name == "mytank:inlet" or name == "mytank:outlet" or
               name == "mytank:controller" or name == "mytank:controller_active"
    end

    -- Erweitere die Box in alle Richtungen, um die Außenwände zu finden
    for _, dir in ipairs({{x=1,y=0,z=0}, {x=-1,y=0,z=0}, {x=0,y=1,z=0}, {x=0,y=-1,z=0}, {x=0,y=0,z=1}, {x=0,y=0,z=-1}}) do
        local check_pos = vector.new(controller_pos)
        while true do
            local next_pos = vector.add(check_pos, dir)
            local node = minetest.get_node(next_pos)
            if is_tank_part(node.name) then
                check_pos = next_pos
                -- Grenzen updaten
                min_p.x = math.min(min_p.x, check_pos.x)
                min_p.y = math.min(min_p.y, check_pos.y)
                min_p.z = math.min(min_p.z, check_pos.z)
                max_p.x = math.max(max_p.x, check_pos.x)
                max_p.y = math.max(max_p.y, check_pos.y)
                max_p.z = math.max(max_p.z, check_pos.z)
            else
                break
            end
        end
    end

    -- Plausibilitätsprüfung der Größe (z.B. Mindestens 3x3x3 außen)
    local size_x = (max_p.x - min_p.x) + 1
    local size_y = (max_p.y - min_p.y) + 1
    local size_z = (max_p.z - min_p.z) + 1

    if size_x < 3 or size_y < 3 or size_z < 3 then
        tank.set_tank_invalid(controller_pos, current_node)
        return false, {}
    end

    -- Schritt 2: Jedes einzelne Feld innerhalb der berechneten Box validieren
    local air_blocks = {}
    local valid_structure = true

    for x = min_p.x, max_p.x do
        for y = min_p.y, max_p.y do
            for z = min_p.z, max_p.z do
                local current_pos = {x = x, y = y, z = z}
                local node = minetest.get_node(current_pos)

                -- Bestimmen, wo wir uns im Würfel befinden
                local is_edge_x = (x == min_p.x or x == max_p.x)
                local is_edge_y = (y == min_p.y or y == max_p.y)
                local is_edge_z = (z == min_p.z or z == max_p.z)

                -- 1. Fall: Es ist eine der 8 Ecken des Würfels (Schnittpunkt aller 3 Außenkanten)
                if is_edge_x and is_edge_y and is_edge_z then
                    if node.name ~= "mytank:wall" then
                        valid_structure = false
                        break
                    end

                -- 2. Fall: Es ist das Innere des Tanks (Keine Außenkante)
                elseif not is_edge_x and not is_edge_y and not is_edge_z then
                    if node.name == "air" then
                        table.insert(air_blocks, current_pos)
                    else
                        -- Innenraum ist nicht hohl!
                        valid_structure = false
                        break
                    end

                -- 3. Fall: Es ist eine Seitenfläche oder Kante
                else
                    if not is_tank_part(node.name) then
                        -- Loch in der Wand oder falscher Block
                        valid_structure = false
                        break
                    end
                end
            end
            if not valid_structure then break end
        end
        if not valid_structure then break end
    end

    -- Schritt 3: Auswertung
    if valid_structure and #air_blocks > 0 then
        local meta = minetest.get_meta(controller_pos)
        local total_capacity = #air_blocks * 8000
        meta:set_int("capacity", total_capacity)
        meta:set_int("block_size", #air_blocks)

        -- Aktivierungs-Zustand umschalten
        if current_node.name == "mytank:controller" then
            minetest.swap_node(controller_pos, {name = "mytank:controller_active", param1 = current_node.param1, param2 = current_node.param2})
        end

        tank.update_formspec(controller_pos)
        tank.update_visuals(controller_pos, air_blocks)
        return true, air_blocks
    else
        tank.set_tank_invalid(controller_pos, current_node)
        return false, {}
    end
end

-- Hilfsfunktion: Setzt den Tank zurück
function tank.set_tank_invalid(pos, current_node)
    local meta = minetest.get_meta(pos)
    meta:set_int("capacity", 0)
    meta:set_int("amount", 0)
    meta:set_int("block_size", 0)

    if current_node.name == "mytank:controller_active" then
        minetest.swap_node(pos, {name = "mytank:controller", param1 = current_node.param1, param2 = current_node.param2})
    end

    tank.update_formspec(pos)
    tank.update_visuals(pos, nil)
end

-- =======================================================================
-- 2. CONTROLLER, BLÖCKE & RECHTSKLICK
-- =======================================================================

minetest.register_node("mytank:controller", {
    description = "Tank Controller (Inaktiv)",
    tiles = {"mytank_controller.png"},
    groups = {cracky = 2},
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("fluid", "")
        meta:set_int("amount", 0)
        meta:set_int("capacity", 0)
        meta:set_int("block_size", 0)
        tank.update_formspec(pos)
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        tank.check_and_calculate_tank(pos)
    end,
    on_destruct = function(pos) tank.update_visuals(pos, nil) end
})

minetest.register_node("mytank:controller_active", {
    description = "Tank Controller (Aktiv)",
    tiles = {"mytank_controller_active.png"},
    light_source = 8,
    groups = {cracky = 2, not_in_creative_inventory = 1},
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        tank.check_and_calculate_tank(pos)
    end,
    on_destruct = function(pos) tank.update_visuals(pos, nil) end
})

minetest.register_node("mytank:wall", { description = "Tank Wand", tiles = {"mytank_wall.png"}, groups = {cracky = 3} })
minetest.register_node("mytank:glass", {
    description = "Tank Glas",
    drawtype = "glasslike",
    tiles = {"mytank_glass.png"},
    paramtype = "light",
    sunlight_propagates = true,
    use_texture_alpha = "clip",
    groups = {snappy = 3, cracky = 3}
})
minetest.register_node("mytank:inlet", { description = "Tank Einlass", tiles = {"mytank_inlet.png"}, groups = {cracky = 3} })
minetest.register_node("mytank:outlet", { description = "Tank Auslass", tiles = {"mytank_outlet.png"}, groups = {cracky = 3} })

-- =======================================================================
-- 3. ENTITY FÜR VISUELLE FLÜSSIGKEIT (Unverändert, aber nutzt optimierte Box)
-- =======================================================================

minetest.register_entity("mytank:fluid_display", {
    initial_properties = {
        visual = "cube",
        textures = {"mytank_fluid.png", "mytank_fluid.png", "mytank_fluid.png", "mytank_fluid.png", "mytank_fluid.png", "mytank_fluid.png"},
        visual_size = {x = 1, y = 1, z = 1},
        physical = false,
        pointable = false,
    },
    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then self.controller_pos = data.controller_pos end
        end
    end,
    get_staticdata = function(self) return minetest.serialize({controller_pos = self.controller_pos}) end,
})

function tank.update_visuals(controller_pos, air_blocks)
    local meta = minetest.get_meta(controller_pos)
    local amount = meta:get_int("amount")
    local capacity = meta:get_int("capacity")

    if capacity == 0 or amount == 0 or not air_blocks or #air_blocks == 0 then
        local objects = minetest.get_objects_inside_radius(controller_pos, 20)
        for _, obj in ipairs(objects) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "mytank:fluid_display" and ent.controller_pos and vector.equals(ent.controller_pos, controller_pos) then
                obj:remove()
            end
        end
        return
    end

    local min_p = {x = air_blocks[1].x, y = air_blocks[1].y, z = air_blocks[1].z}
    local max_p = {x = air_blocks[1].x, y = air_blocks[1].y, z = air_blocks[1].z}
    for _, p in ipairs(air_blocks) do
        min_p.x = math.min(min_p.x, p.x)
        min_p.y = math.min(min_p.y, p.y)
        min_p.z = math.min(min_p.z, p.z)
        max_p.x = math.max(max_p.x, p.x)
        max_p.y = math.max(max_p.y, p.y)
        max_p.z = math.max(max_p.z, p.z)
    end

    local center = {
        x = min_p.x + (max_p.x - min_p.x) / 2,
        y = min_p.y + (max_p.y - min_p.y) / 2,
        z = min_p.z + (max_p.z - min_p.z) / 2
    }

    local size_x = (max_p.x - min_p.x) + 1
    local size_y = (max_p.y - min_p.y) + 1
    local size_z = (max_p.z - min_p.z) + 1

    local fill_ratio = amount / capacity
    local current_visual_y = size_y * fill_ratio
    center.y = min_p.y - 0.5 + (current_visual_y / 2)

    local fluid_obj = nil
    local objects = minetest.get_objects_inside_radius(controller_pos, 20)
    for _, obj in ipairs(objects) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "mytank:fluid_display" and ent.controller_pos and vector.equals(ent.controller_pos, controller_pos) then
            fluid_obj = obj
            break
        end
    end

    if not fluid_obj then
        fluid_obj = minetest.add_entity(center, "mytank:fluid_display")
        if fluid_obj then fluid_obj:get_luaentity().controller_pos = controller_pos end
    end

    if fluid_obj then
        fluid_obj:set_pos(center)
        fluid_obj:set_properties({
            visual_size = {x = size_x * 10, y = current_visual_y * 10, z = size_z * 10}
        })
    end
end

-- =======================================================================
-- 4. FORMSPEC & LOGIK
-- =======================================================================

function tank.update_formspec(pos)
    local meta = minetest.get_meta(pos)
    local fluid = meta:get_string("fluid")
    if fluid == "" then fluid = "Keine" end
    local amount = meta:get_int("amount")
    local capacity = meta:get_int("capacity")
    local block_size = meta:get_int("block_size")

    local status = "STATUS: UNGUELTIG"
    if capacity > 0 then status = "STATUS: BEREIT (AKTIV)" end

    local formspec = "size[8,5]" ..
        "label[0.5,0.5;--- " .. status .. " ---]" ..
        "label[0.5,1.5;Gespeicherte Flussigkeit: " .. fluid .. "]" ..
        "label[0.5,2.0;Inhalt: " .. amount .. " mb / " .. capacity .. " mb]" ..
        "label[0.5,2.5;Hohlraum-Grose: " .. block_size .. " Blocke]" ..
        "box[0.5,3.5;7,0.5;#333333]"

    if capacity > 0 then
        local bar_width = (amount / capacity) * 7
        formspec = formspec .. "box[0.5,3.5;" .. bar_width .. ",0.5;#00d4ff]"
    end

    formspec = formspec .. "button_exit[3,4.2;2,0.5;close;Schliesen]"
    meta:set_string("formspec", formspec)
end

function tank.insert_fluid(controller_pos, fluid_name, amount)
    local success, air_blocks = tank.check_and_calculate_tank(controller_pos)
    if not success then return 0 end

    local meta = minetest.get_meta(controller_pos)
    local current_fluid = meta:get_string("fluid")
    local current_amount = meta:get_int("amount")
    local capacity = meta:get_int("capacity")

    if current_fluid ~= "" and current_fluid ~= fluid_name and current_amount > 0 then return 0 end

    local space = capacity - current_amount
    local to_add = math.min(space, amount)

    if to_add > 0 then
        meta:set_string("fluid", fluid_name)
        meta:set_int("amount", current_amount + to_add)
        tank.update_formspec(controller_pos)
        tank.update_visuals(controller_pos, air_blocks)
        return to_add
    end
    return 0
end

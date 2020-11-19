------------------
-- Draconis API --
------------------
----- Ver 1.0 ----

local random = math.random
local abs = math.abs
local min = math.min
local max = math.max
local floor = math.floor

local creative = minetest.settings:get_bool("creative_mode")

local terrain_destruction = minetest.settings:get_bool("terrain_destruction", true)

local function R(x) -- Round number up
	return x + 0.5 - (x + 0.5) % 1
end

----------------------
-- Helper Functions --
----------------------

local function hitbox(ent)
    if not ent then return nil end
    if type(ent) == 'userdata' then ent = ent:get_luaentity() end
    return ent.object:get_properties().collisionbox
end

function draconis.calc_forceload(pos)
    local radius = 2
    local minpos = vector.subtract(pos, vector.new(radius, radius, radius))
    local maxpos = vector.add(pos, vector.new(radius, radius, radius))
    local minbpos = {}
    local maxbpos = {}
    for _, coord in ipairs({"x", "y", "z"}) do
        minbpos[coord] = math.floor(minpos[coord] / 16) * 16
        maxbpos[coord] = math.floor(maxpos[coord] / 16) * 16
    end
    local flposes = {}
    for x = minbpos.x, maxbpos.x do
        for y = minbpos.y, maxbpos.y do
            for z = minbpos.z, maxbpos.z do
                table.insert(flposes, vector.new(x, y, z))
            end
        end
    end
    return flposes
end

function draconis.forceload(pos)
    local fl = draconis.calc_forceload(pos)
    for i = 1, #fl do
        if minetest.forceload_block(fl[i]) then
            minetest.log("action", "[Draconis 1.0] Forceloaded 4x4x4 area around "..minetest.pos_to_string(pos))
        end
    end
end

function draconis.random_id()
    local idst = ""
    for _ = 0, 5 do idst = idst .. (random(0, 9)) end
    return idst
end

function draconis.get_biome_name(pos)
    if not pos then return end
    return minetest.get_biome_name(minetest.get_biome_data(pos).biome)
end

function draconis.random_sound(self, chance)
    if not chance then chance = 150 end
    if random(1, chance) == 1 then
        mobkit.make_sound(self, "random_" .. random(1, 3))
    end
end

---------------------
-- Visual Entities --
---------------------

minetest.register_entity("draconis:dragon_ice_entity", {
    hp_max = 1,
    physical = false,
    collisionbox = {0, 0, 0, 0, 0, 0},
    visual = "cube",
    visual_size = {x = 1, y = 1},
    textures = {
        "draconis_dragon_ice_alpha.png", "draconis_dragon_ice_alpha.png",
        "draconis_dragon_ice_alpha.png", "draconis_dragon_ice_alpha.png",
        "draconis_dragon_ice_alpha.png", "draconis_dragon_ice_alpha.png"
    },
    is_visible = true,
    makes_footstep_sound = false,
    use_texture_alpha = true,
    static_save = true,
    timer = 1,
    on_activate = function(self)
        self.object:set_armor_groups({immortal = 1})
    end,
    on_step = function(self)
        local pos = self.object:get_pos()
        local parent = self.object:get_attach()
        if parent then
            local parent_pos = parent:get_pos()
            parent_pos.x = pos.x
            parent_pos.z = pos.z
            local vel = parent:get_velocity()
            vel.x = 0
            vel.z = 0
            parent:set_velocity(vel)
            parent:set_pos(parent_pos)
            parent:get_luaentity().in_ice_cube = true
            self.timer = self.timer + 1
            if self.timer > 300 then
                parent:get_luaentity().in_ice_cube = nil
                self.object:remove()
            end
        else
            self.object:remove()
        end
    end
})

local function set_eyes(self, ent)
    local eyes = minetest.add_entity(self.object:get_pos(), ent)
    eyes:set_attach(self.object, "Head", {x = 0, y = -1.476, z = -1.455},
                    {x = 66, y = 0, z = 180})
    return eyes
end

-----------------
-- On Activate --
-----------------

function draconis.set_drops(self)
    local name = self.name:split(":")[2]
    if self.cavern_spawn == true then
        self.drops_level = mobkit.remember(self, "drops_level", 5)
        return
    end
    if self.drops_level ~= self.growth_stage and self.drops_level ~= 5 then
        self.drops_level = mobkit.remember(self, "drops_level",
                                           self.growth_stage)
    end
    if self.drops_level <= 2 or self.tamed then
        self.drops = nil
    end
    if self.drops_level == 3 then
        self.drops = {
            {name = "draconis:blood_".. name, chance = 64, min = 4, max = 8},
            {name = "draconis:scales_".. name .. "_" .. self.color, chance = 1, min = 2, max = 12},
            {name = "draconis:dragon_bone", chance = 1, min = 2, max = 8}
        }
    end
    if self.drops_level == 4 then
        self.drops = {
            {name = "draconis:blood_".. name, chance = 32, min = 4, max = 8},
            {name = "draconis:scales_".. name .. "_" .. self.color, chance = 1, min = 6, max = 24},
            {name = "draconis:dragon_bone", chance = 1, min = 6, max = 18}
        }
    end
    if self.drops_level == 5 then
        if self.gender == "male" then
            self.drops = {
                {name = "draconis:blood_".. name, chance = 16, min = 4, max = 8},
                {name = "draconis:scales_".. name .. "_" .. self.color, chance = 1, min = 12, max = 38},
                {name = "draconis:dragon_bone", chance = 1, min = 12, max = 32}
            }
        else
            self.drops = {
                {name = "draconis:blood_".. name, chance = 16, min = 4, max = 8},
                {name = "draconis:scales_".. name .. "_" .. self.color, chance = 1, min = 12, max = 32},
                {name = "draconis:dragon_bone", chance = 1, min = 12, max = 24},
                {
                    name = "draconis:egg_" .. name .. "_" ..
                        self.colors[random(1, 4)],
                    chance = 1,
                    min = 1,
                    max = 1
                }, {
                    name = "draconis:egg_" .. name .. "_" ..
                        self.colors[random(1, 4)],
                    chance = 8,
                    min = 0,
                    max = 1
                }
            }
        end
    end
end

function draconis.set_color_string(self)
    if self.name == "draconis:fire_dragon" then
        if self.texture_no == 1 then
            self.color = "black"
        elseif self.texture_no == 2 then
            self.color = "bronze"
        elseif self.texture_no == 3 then
            self.color = "green"
        else
            self.color = "red"
        end
    elseif self.name == "draconis:ice_dragon" then
        if self.texture_no == 1 then
            self.color = "light_blue"
        elseif self.texture_no == 2 then
            self.color = "sapphire"
        elseif self.texture_no == 3 then
            self.color = "slate"
        else
            self.color = "white"
        end
    end
end

function draconis.on_activate(self, staticdata, dtime_s)
    mob_core.on_activate(self, staticdata, dtime_s)
    self.dragon_id = mobkit.recall(self, "dragon_id") or 1
    if self.dragon_id == 1 then
        self.dragon_id =
            mobkit.remember(self, "dragon_id", draconis.random_id())
    end
    if self.name:find("ice") then
        self.eyes = set_eyes(self, "draconis:ice_eyes")
    elseif self.name:find("fire") then
        self.eyes = set_eyes(self, "draconis:fire_eyes")
    end
    self.flight_timer = mobkit.recall(self, "flight_timer") or 1
    self.age = mobkit.recall(self, "age") or 100
    self.growth_scale = mobkit.recall(self, "growth_scale") or 1
    self._growth_timer = mobkit.recall(self, "_growth_timer") or 4500
    self.drops_level = mobkit.recall(self, "drops_level") or 0
    self.breath_meter = mobkit.recall(self, "breath_meter") or 100
    self.breath_meter_max = mobkit.recall(self, "breath_meter_max") or 100
    self.breath_meter_bottomed = mobkit.recall(self, "breath_meter_bottomed") or false
    self.cavern_spawn = mobkit.recall(self, "cavern_spawn") or nil
    self.order = mobkit.recall(self, "order") or "wander"
    self.fly_allowed = mobkit.recall(self, "fly_allowed") or false
    self.survey_range = mobkit.recall(self, "survey_range") or 16
    self.attacks = mobkit.recall(self, "attacks") or "nothing"
    self.stance = mobkit.recall(self, "stance") or "neutral"
    self.hunger = mobkit.recall(self, "hunger") or self.max_hunger / 2
    self.feed_timer = mobkit.recall(self, "feed_timer") or 32
    self.sleep_timer = mobkit.recall(self, "sleep") or 0
    self.stuck_timer = 0
    self.flap_sound_timer = 1.5
    draconis.set_color_string(self)
    mob_core.set_scale(self, self.growth_scale)
    draconis.set_drops(self)
end

-------------------------
-- Terrain Destruction --
-------------------------

local function hitbox_index(self)
    local pos = mobkit.get_stand_pos(self)
    local width = self.object:get_properties().collisionbox[4] + 1
    local height = self.height + 1
    local corner1 = {x = pos.x + width, y = pos.y + height, z = pos.z + width}
    local corner2 = {x = pos.x - width, y = pos.y, z = pos.z - width}
    local area = minetest.find_nodes_in_area(corner1, corner2,
                                             draconis.walkable_nodes)
    return area
end

function draconis.break_free(self)
    if not terrain_destruction then return end
    if self.stuck_timer < 5 then return end
    local collision = hitbox_index(self)
    for i = #collision, 1, -1 do
        local pos = mobkit.get_stand_pos(self)
        if collision[i].y > pos.y + 1 then
            local node = minetest.get_node(collision[i])
            if draconis.find_value_in_table(draconis.all_trees, node.name) or
                draconis.find_value_in_table(draconis.all_leaves, node.name) then
                minetest.set_node(collision[i], {name = "air"})
            end
        end
    end
    if mobkit.timer(self, 3) then self.stuck_timer = 0 end
end

function draconis.scorch_nodes(pos)
    if not terrain_destruction then return end
    local minpos = vector.new(pos.x - 3, pos.y - 3, pos.z - 3)
    local maxpos = vector.new(pos.x + 3, pos.y + 3, pos.z + 3)
    for x = minpos.x, maxpos.x do
        for y = minpos.y, maxpos.y do
            for z = minpos.z, maxpos.z do
                local npos = vector.new(x, y, z)
                local name = minetest.get_node(npos).name
                if vector.distance(pos, npos) < 4 and name then
                    if draconis.find_value_in_table(draconis.all_stone, name) then
                        minetest.set_node(npos,
                                          {name = "draconis:scorched_stone"})
                    end
                    if draconis.find_value_in_table(draconis.all_soil, name) then
                        minetest.set_node(npos,
                                          {name = "draconis:scorched_soil"})
                    end
                    if draconis.find_value_in_table(draconis.all_trees, name) then
                        minetest.set_node(npos,
                                          {name = "draconis:scorched_tree"})
                    end
                    if draconis.find_value_in_table(draconis.all_leaves, name) then
                        minetest.set_node(npos, {name = "air"})
                    end
                    if draconis.find_value_in_table(draconis.all_flora, name) then
                        minetest.set_node(npos, {name = "air"})
                    end
                    if draconis.find_value_in_table(draconis.walkable_nodes,
                                                    name) then
                        local top = vector.new(npos.x, npos.y + 1, npos.z)
                        if minetest.get_node(top).name == "air" then
                            minetest.set_node(top, {name = "fire:basic_flame"})
                        end
                    end
                end
            end
        end
    end
end

function draconis.freeze_nodes(pos)
    if not terrain_destruction then return end
    local minpos = vector.new(pos.x - 3, pos.y - 3, pos.z - 3)
    local maxpos = vector.new(pos.x + 3, pos.y + 3, pos.z + 3)
    for x = minpos.x, maxpos.x do
        for y = minpos.y, maxpos.y do
            for z = minpos.z, maxpos.z do
                local npos = vector.new(x, y, z)
                local name = minetest.get_node(npos).name
                if vector.distance(pos, npos) < 4 and name then
                    if draconis.find_value_in_table(draconis.all_stone, name) then
                        minetest.set_node(npos, {name = "draconis:frozen_stone"})
                    end
                    if draconis.find_value_in_table(draconis.all_soil, name) then
                        minetest.set_node(npos, {name = "draconis:frozen_soil"})
                    end
                    if draconis.find_value_in_table(draconis.all_trees, name) then
                        minetest.set_node(npos, {name = "draconis:frozen_tree"})
                    end
                    if draconis.find_value_in_table(draconis.all_leaves, name) then
                        minetest.set_node(npos, {name = "air"})
                    end
                    if draconis.find_value_in_table(draconis.all_flora, name) then
                        minetest.set_node(npos, {name = "air"})
                    end
                    if draconis.find_value_in_table(draconis.all_ice, name) then
                        minetest.set_node(npos, {name = "air"})
                    end
                end
            end
        end
    end
end

-------------------
-- Dragon Breath --
-------------------

local breath_timer

local function breath_sound(self)
    if not self.breath_timer then self.breath_timer = 2 end
    self.breath_timer = self.breath_timer - self.dtime
    if self.breath_timer <= 0 then
        self.breath_timer = 2
        minetest.sound_play("draconis_breath",{
            object = self.object,
            gain = 1.0,
            max_hear_distance = 32,
            loop = false,
        })
    end
end

local function fuel_forge(pos, forge_name)
    local minpos = vector.new(pos.x - 1, pos.y - 1, pos.z - 1)
    local maxpos = vector.new(pos.x + 1, pos.y + 1, pos.z + 1)
    for x = minpos.x, maxpos.x do
        for y = minpos.y, maxpos.y do
            for z = minpos.z, maxpos.z do
                local npos = vector.new(x, y, z)
                local name = minetest.get_node(npos).name
                local on_fired = minetest.registered_nodes[forge_name].on_fired
                if name then
                    if name == forge_name then
                        on_fired(npos)
                    end
                end
            end
        end
    end
end

local function get_line(a, b)
    local steps = vector.distance(a, b)
    local nodes = {}

    for i = 0, steps do
        local c

        if steps > 0 then
            c = {
                x = a.x + (b.x - a.x) * (i / steps),
                y = a.y + (b.y - a.y) * (i / steps),
                z = a.z + (b.z - a.z) * (i / steps)
            }
        else
            c = a
        end

        table.insert(nodes, {pos = c, node = minetest.get_node_or_nil(c)})
    end

    return nodes
end

local function ray_distance(a, b)
    local ray = minetest.raycast(a, b, false, false)
    for pointed_thing in ray do
        if pointed_thing.type == "node" then
            local dist = vector.distance(a, pointed_thing.under)
            return dist
        end
    end
    return 24
end

function draconis.fire_breath(self, goal, range)
    if self.breath_meter_bottomed then return end
    breath_sound(self)
    local yaw = self.object:get_yaw()
    local pos = self.object:get_pos()
    pos = vector.add(pos, vector.multiply(minetest.yaw_to_dir(yaw),
                                          10 * self.growth_scale))
    local dir = vector.direction(pos, goal)
    local dest = vector.add(pos, vector.multiply(dir, range))
    local length = ray_distance(pos, dest)
    dest = vector.add(pos, vector.multiply(dir, length))
    local path = get_line(pos, dest)
    self.breath_meter = self.breath_meter - 0.25
    mobkit.remember(self, "breath_meter", self.breath_meter)
    if self.breath_meter <= 1 then
        self.breath_meter_bottomed = mobkit.remember(self, "breath_meter_bottomed", true)
    end
    for i = 1, #path do
        minetest.add_particlespawner({
            amount = 8,
            time = 0.25,
            minpos = path[1].pos,
            maxpos = path[1].pos,
            minvel = vector.multiply(dir, 32),
            maxvel = vector.multiply(dir, 48),
            minacc = {x = -2, y = -3, z = -2},
            maxacc = {x = 2, y = 3, z = 2},
            minexptime = 0.02 * length,
            maxexptime = 0.04 * length,
            minsize = 16 * self.growth_scale,
            maxsize = 24 * self.growth_scale,
            collisiondetection = false,
            vertical = false,
            glow = 16,
            texture = "fire_basic_flame.png"
        })
        local objects = minetest.get_objects_inside_radius(
                            path[random(1, #path)].pos, 8)
        for _, object in ipairs(objects) do
            if object and object ~= self.object then
                if object:get_armor_groups().fleshy
                or object:get_luaentity()
                and object:get_luaentity().name:match("^petz:") then
                    if vector.distance(path[i].pos, object:get_pos()) < 2
                    and random(1, R(i/2)) == 1 then
                        object:punch(self.object, 1, {
                            full_punch_interval = 1,
                            damage_groups = {fleshy = 2}
                        }, nil)
                    end
                end
            end
        end
        fuel_forge(path[i].pos, "draconis:draconic_steel_forge_fire")
        draconis.scorch_nodes(path[i].pos)
        if minetest.get_modpath("tnt")
        and self.age >= 100
        and terrain_destruction then
            if random(1, #path * 32) == 1 then
                tnt.boom(path[i].pos, {radius = 2})
            end
        end
    end
end

function draconis.ice_breath(self, goal, range)
    if self.breath_meter_bottomed then return end
    local yaw = self.object:get_yaw()
    local pos = self.object:get_pos()
    pos = vector.add(pos, vector.multiply(minetest.yaw_to_dir(yaw),
                                          10 * self.growth_scale))
    local dir = vector.direction(pos, goal)
    local dest = vector.add(pos, vector.multiply(dir, range))
    local length = ray_distance(pos, dest)
    dest = vector.add(pos, vector.multiply(dir, length))
    local path = get_line(pos, dest)
    self.breath_meter = self.breath_meter - 0.25
    mobkit.remember(self, "breath_meter", self.breath_meter)
    if self.breath_meter <= 1 then
        self.breath_meter_bottomed = mobkit.remember(self, "breath_meter_bottomed", true)
    end
    for i = 1, #path do
        minetest.add_particlespawner({
            amount = 3,
            time = 1,
            minpos = path[i].pos,
            maxpos = path[i].pos,
            minvel = vector.multiply(dir, 32),
            maxvel = vector.multiply(dir, 48),
            minacc = {x = -4, y = -4, z = -4},
            maxacc = {x = 4, y = 4, z = 4},
            minexptime = 0.02 * length,
            maxexptime = 0.04 * length,
            minsize = 8 * self.growth_scale,
            maxsize = 12 * self.growth_scale,
            collisiondetection = true,
            vertical = false,
            glow = 8,
            texture = "draconis_ice_particle_" .. random(1, 3) .. ".png"
        })
        local objects = minetest.get_objects_inside_radius(path[i].pos, 8)
        for _, object in ipairs(objects) do
            if object and object ~= self.object then
                if object:get_armor_groups().fleshy
                or (object:get_luaentity()
                and object:get_luaentity().name:match("^petz:")) then
                    if not object:is_player() and
                    not object:get_luaentity().in_ice_cube then
                        local cube = minetest.add_entity(object:get_pos(),
                                                         "draconis:dragon_ice_entity")
                        local box = object:get_properties().collisionbox
                        local parent_scale = object:get_properties().visual_size
                        local scale = (math.abs(box[5]) + math.abs(box[2])) * 2
                        if cube then
                            cube:set_properties(
                                {
                                    visual_size = {
                                        x = scale / parent_scale.x,
                                        y = scale / parent_scale.y
                                    }
                                })
                            cube:set_attach(object, "", {x = 0, y = 0, z = 0},
                                            {x = 0, y = 0, z = 0})
                        end
                    end
                    if vector.distance(path[i].pos, object:get_pos()) < 2
                    and random(1, R(i/2)) == 1 then
                        object:punch(self.object, 1, {
                            full_punch_interval = 1,
                            damage_groups = {fleshy = 2}
                        }, nil)
                    end
                end
            end
        end
        fuel_forge(path[i].pos, "draconis:draconic_steel_forge_ice")
        draconis.freeze_nodes(path[i].pos)
        if minetest.get_modpath("tnt")
        and self.age >= 100
        and terrain_destruction then
            if random(1, #path * 32) == 1 then
                tnt.boom(path[i].pos, {radius = 2})
            end
        end
    end
end

-----------------------------
-- Tamed Dragon Management --
-----------------------------

function draconis.feed(self, clicker, feed_count)
    local item = clicker:get_wielded_item()
    local pos = self.object:get_pos()
    if mob_core.follow_holding(self, clicker) then
        if creative == false then
            item:take_item()
            clicker:set_wielded_item(item)
        end
        mobkit.heal(self, self.max_hp / feed_count)
        if self.hp >= self.max_hp then self.hp = self.max_hp end
        if self.hunger < self.max_hunger then
            self.hunger = mobkit.remember(self, "hunger", self.hunger + 4)
            self.food = mobkit.remember(self, "food", self.food + 1)
            local minppos = vector.add(pos, hitbox(self)[4])
            local maxppos = vector.subtract(pos, hitbox(self)[4])
            local def = minetest.registered_items[item:get_name()]
            local texture = def.inventory_image
            if not texture or texture == "" then
                texture = def.wield_image
            end
            minetest.add_particlespawner({
                amount = 25*self.growth_scale,
                time = 0.1,
                minpos = minppos,
                maxpos = maxppos,
                minvel = {x=-1, y=1, z=-1},
                maxvel = {x=1, y=2, z=1},
                minacc = {x=0, y=-5, z=0},
                maxacc = {x=0, y=-9, z=0},
                minexptime = 1,
                maxexptime = 1,
                minsize = 4*self.growth_scale,
                maxsize = 6*self.growth_scale,
                collisiondetection = true,
                vertical = false,
                texture = texture,
            })
            if self.food >= feed_count then
                self.food = mobkit.remember(self, "food", 0)
            end
        end
    end
    return false
end

local function set_order(self, player, order)
    if order == "stand" then
        if self.isinliquid then return end
        mobkit.clear_queue_high(self)
        mobkit.clear_queue_low(self)
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
        self.status = "stand"
        self.order = "stand"
        mobkit.animate(self, "stand")
    end
    if order == "wander" then
        mobkit.clear_queue_high(self)
        mobkit.clear_queue_low(self)
        self.status = ""
        self.order = "wander"
    end
    if order == "follow" then
        mobkit.clear_queue_low(self)
        self.status = "following"
        self.order = "follow"
        draconis.hq_follow(self, 20, player)
    end
    mobkit.remember(self, "status", self.status)
    mobkit.remember(self, "order", self.order)
end

local mob_obj = {}

function draconis.formspec(self, clicker)
    local form = function(self)
        local name = self.nametag or "No Name"
        local health = R(self.hp) .. "/" .. R(self.max_hp * self.growth_scale)
        local hunger = R(self.hunger) .. "/" .. R(self.max_hunger)
        local mob_name = self.name:split(":")[2]
        local formspec = {
            "formspec_version[3]", "size[10.75,10.5]",
            "label[4.75,0.5;",
            draconis.string_format(self.name), "]",
            "image[0.5,0.75;9,2.475;draconis_" .. mob_name .. "_form_" .. self.texture_no .. ".png]",
            "label[4,3.5;", name, "]",
            "label[4,3.8;", "Health:" .. health, "]",
            "label[4,4.1;", "Age:" .. self.age, "]",
            "label[4,4.4;", "Hunger:" .. hunger, "]",
            "label[4,4.7;", "Owner:" .. self.owner or "", "]",
            "button[4,6.3;3,0.8;btn_flight;Flight Allowed: " .. tostring(self.fly_allowed), "]",
            "button[4,7.3;3,0.8;btn_stance;Stance: " .. draconis.string_format(self.stance), "]",
            "button[4,8.3;3,0.8;btn_order;Order: " .. draconis.string_format(self.order), "]"
        }
        return table.concat(formspec, "")
    end
    minetest.show_formspec(clicker:get_player_name(),
                           "draconis:" .. self.name:split(":")[2] .. "_vitals",
                           form(self))
    mob_obj[clicker:get_player_name()] = self
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if not mob_obj[name] then return end
    if formname == "draconis:" .. mob_obj[name].name:split(":")[2] .. "_vitals" then
        if fields.btn_flight then
            if not mob_obj[name].object then return end
            if mob_obj[name].fly_allowed == true then
                mob_obj[name].fly_allowed =
                    mobkit.remember(mob_obj[name], "fly_allowed", false)
            else
                mob_obj[name].fly_allowed =
                    mobkit.remember(mob_obj[name], "fly_allowed", true)
            end
            draconis.formspec(mob_obj[name], player)
        end
        if fields.btn_stance then
            if not mob_obj[name].object then return end
            if mob_obj[name].stance == "neutral" then
                mob_obj[name].stance =
                    mobkit.remember(mob_obj[name], "stance", "aggressive")
            elseif mob_obj[name].stance == "aggressive" then
                mob_obj[name].stance =
                    mobkit.remember(mob_obj[name], "stance", "passive")
            elseif mob_obj[name].stance == "passive" then
                mob_obj[name].stance =
                    mobkit.remember(mob_obj[name], "stance", "neutral")
            end
            draconis.formspec(mob_obj[name], player)
        end
        if fields.btn_order then
            if not mob_obj[name].object then return end
            local mob_name = draconis.string_format(mob_obj[name].name)
            if mob_obj[name].order == "follow" then
                set_order(mob_obj[name], player, "stand")
                minetest.chat_send_player(name, ("" .. mob_name .. " is standing."))
            elseif mob_obj[name].order == "stand" then
                set_order(mob_obj[name], player, "wander")
                minetest.chat_send_player(name, ("" .. mob_name .. " is wandering."))
            elseif mob_obj[name].order == "wander" then
                set_order(mob_obj[name], player, "follow")
                minetest.chat_send_player(name, ("" .. mob_name .. " is following."))
            end
            draconis.formspec(mob_obj[name], player)
        end
        if fields.quit or fields.key_enter then
            mob_obj[name] = nil
        end
    end
end)

--------------
-- Spawning --
--------------

function draconis.spawn_child(pos, mob, color_no, owner) -- Spawn a mob with child presets
    local obj = minetest.add_entity(pos, mob)
    local luaent = obj:get_luaentity()
    luaent.child = mobkit.remember(luaent, "child", true)
    luaent.age = mobkit.remember(luaent, "age", 1)
    luaent.growth_scale = mobkit.remember(luaent, "growth_scale", 0.1)
    luaent.growth_stage = mobkit.remember(luaent, "growth_stage", 1)
    luaent.texture_no = color_no
    if owner ~= "" then mob_core.set_owner(luaent, owner) end
    mob_core.set_scale(luaent, luaent.growth_scale)
    mob_core.set_textures(luaent)
    return
end

function draconis.spawn_dragon(pos, mob, cavern, age)
    if not pos then return false end
    local dragon = minetest.add_entity(pos, mob)
    if dragon and dragon:get_luaentity() then
        local ent = dragon:get_luaentity()
        if cavern == true then
            ent.cavern_spawn = mobkit.remember(ent, "cavern_spawn", true)
        end
        ent.age = mobkit.remember(ent, "age", age)
        ent.growth_scale = mobkit.remember(ent, "growth_scale", age * 0.01)
        if age <= 25 then
            ent.child = mobkit.remember(ent, "child", true)
            ent.growth_stage = mobkit.remember(ent, "growth_stage", 1)
        end
        if age <= 50 then
            ent.growth_stage = mobkit.remember(ent, "growth_stage", 2)
        end
        if age <= 75 then
            ent.growth_stage = mobkit.remember(ent, "growth_stage", 3)
        end
        if age > 75 then
            ent.growth_stage = mobkit.remember(ent, "growth_stage", 4)
        end
        mob_core.set_scale(ent, ent.growth_scale)
        mob_core.set_textures(ent)
        return true
    end
    return false
end

-------------
-- On Step --
-------------

local function flash_red(self)
	minetest.after(0.0, function()
		self.object:settexturemod("^[colorize:#FF000040")
		core.after(0.2, function()
			if mobkit.is_alive(self) then
				self.object:settexturemod("")
			end
		end)
	end)
end

function draconis.is_stuck(self)
    if not mobkit.is_alive(self) then return end
    if not self.moveresult then return end
    local moveresult = self.moveresult
    if self.height < 1 then return false end
    for _, collision in ipairs(moveresult.collisions) do
        if collision.type == "node" then
            local pos = mobkit.get_stand_pos(self)
            local node_pos = collision.node_pos
            if node_pos.y > pos.y + 1 then
                local node = minetest.get_node(node_pos)
                if minetest.registered_nodes[node.name].walkable then
                    self.stuck_timer = self.stuck_timer + self.dtime
                    return true
                end
            end
        end
    end
    return false
end

function draconis.fire_vitals(self)
    if self.lung_capacity then
        local colbox = self.object:get_properties().collisionbox
        local headnode = mobkit.nodeatpos(
                             mobkit.pos_shift(self.object:get_pos(),
                                              {y = colbox[5]})) -- node at hitbox top
        if headnode and headnode.drawtype == 'liquid' then
            self.oxygen = self.oxygen - self.dtime
        else
            self.oxygen = self.lung_capacity
        end

        if self.oxygen <= 0 then
            if mobkit.timer(self, 2) then
                minetest.after(0.0, function()
                    self.object:settexturemod("^[colorize:#FF000040")
                    core.after(0.2, function()
                        if mobkit.is_alive(self) then
                            self.object:settexturemod("")
                        end
                    end)
                end)
                mobkit.hurt(self, self.max_hp / self.lung_capacity)
            end
        end
    end
end

function draconis.physics(self)
	local vel=self.object:get_velocity()
		-- dumb friction
    if self.isonground
    and not self.isinliquid
    and not self.driver then
		self.object:set_velocity({x= vel.x> 0.2 and vel.x*0.4 or 0,
								y=vel.y,
								z=vel.z > 0.2 and vel.z*0.4 or 0})
	end

	local surface = nil
	local surfnodename = nil
	local spos = mobkit.get_stand_pos(self)
	spos.y = spos.y+0.01
	local snodepos = mobkit.get_node_pos(spos)
	local surfnode = mobkit.nodeatpos(spos)
	while surfnode and surfnode.drawtype == 'liquid' do
		surfnodename = surfnode.name
		surface = snodepos.y+0.5
		if surface > spos.y+self.height then break end
		snodepos.y = snodepos.y+1
		surfnode = mobkit.nodeatpos(snodepos)
	end
	self.isinliquid = surfnodename
	if surface then
		local submergence = min(surface-spos.y,self.height)/self.height
		local buoyacc = 9.8*(self.buoyancy-submergence)
		mobkit.set_acceleration(self.object,
			{x=-vel.x*self.water_drag,y=buoyacc-vel.y*abs(vel.y)*0.4,z=-vel.z*self.water_drag})
    else
		self.object:set_acceleration({x=0,y=-9.8,z=0})
    end
end
	

function draconis.ice_vitals(self)
	if not self.igniter_damage then
		self.igniter_damage = true
	end

	if self.igniter_damage then
		local pos = mobkit.get_stand_pos(self)
		local node = minetest.get_node(pos)
		if node and minetest.registered_nodes[node.name].groups.igniter then
			if mobkit.timer(self,1) then
				flash_red(self)
				mobkit.make_sound(self, "hurt")
				mobkit.hurt(self, self.max_hp/12)
			end
		end
	end
end

function draconis.flap_sound(self)
    if not self._anim then return end
    if self._anim:match("fly") then
        self.flap_sound_timer = self.flap_sound_timer - self.dtime
    end
    if self.flap_sound_timer <= 0  then
        mobkit.make_sound(self, 'flap')
        self.flap_sound_timer = 1.5
    end
end

function draconis.increase_age(self)
    self.age = mobkit.remember(self, "age", self.age + 1)
    if self.age < 100 then
        self.growth_scale = mobkit.remember(self, "growth_scale",
                                            self.growth_scale + 0.01)
        mob_core.set_scale(self, self.growth_scale)
        draconis.set_drops(self)
    end
end

function draconis.growth(self)
    self._growth_timer = self._growth_timer - 1
    if self._growth_timer <= 0 then
        draconis.increase_age(self)
        self._growth_timer = 4500
    end
    if self.age <= 25 then
        self.growth_stage = 1
    elseif self.age <= 50 then
        self.child = mobkit.remember(self, "child", false)
        self.growth_stage = 2
        mob_core.set_textures(self)
    elseif self.age <= 75 then
        self.growth_stage = 3
    elseif self.age <= 100 then
        self.growth_stage = 4
    end
    if self.hp > self.max_hp * self.growth_scale then
        self.hp = self.max_hp * self.growth_scale
    end
    if self.max_hunger ~= self.max_hp * self.growth_scale / 2 then
        self.max_hunger = self.max_hp * self.growth_scale / 2
    end
    mobkit.remember(self, "growth_stage", self.growth_stage)
    mobkit.remember(self, "_growth_timer", self._growth_timer)
end

function draconis.breath_cooldown(self)
    if self.age < 200 then
        self.breath_meter_max = mobkit.remember(self, "breath_meter_max",
                                                self.age)
    else
        self.breath_meter_max = mobkit.remember(self, "breath_meter_max", 200)
    end
    if self.breath_meter > self.breath_meter_max then
        self.breath_meter = self.breath_meter_max
    end
    if self.breath_meter_bottomed
    and self.breath_meter > self.breath_meter_max/4 then
        self.breath_meter_bottomed = mobkit.remember(self, "breath_meter_bottomed", false)
    end
    if self.breath_meter < self.breath_meter_max then
        self.breath_meter = self.breath_meter + 1
    end
    mobkit.remember(self, "breath_meter", self.breath_meter)
end

function draconis.hunger(self)
    if not self.tamed then self.hunger = self.max_hunger return end
    if self.hunger > self.max_hunger then self.hunger = self.max_hunger end
    if mobkit.timer(self, 240) then self.hunger = self.hunger - 1 end
    if mobkit.timer(self, 3) then
        if self.hunger < self.max_hunger / 3 then mobkit.hurt(self, 1) end
    end
    mobkit.remember(self, "hunger", self.hunger)
end

function draconis.on_step(self, dtime, moveresult)
    mob_core.on_step(self, dtime, moveresult)
    if not mobkit.is_alive(self) then return end
    local pos = self.object:get_pos()
    if self.owner
    and pos then
        draconis.bonded_dragons[self.owner] =
            {id = self.dragon_id, last_pos = pos}
    end
    if not self.eyes:get_yaw() then
        if self.name:find("ice") then
            self.eyes = set_eyes(self, "draconis:ice_eyes")
        elseif self.name:find("fire") then
            self.eyes = set_eyes(self, "draconis:fire_eyes")
        end
    end
    draconis.is_stuck(self) -- Find if stuck
    draconis.hunger(self) -- Hunger
    if mobkit.timer(self, 1) then
        draconis.growth(self) -- Gradual Growth
        draconis.breath_cooldown(self) -- Increase Breath Meter if empty
        if draconis.get_time() == "night" and self.sleep_timer > 0 then
            self.sleep_timer = self.sleep_timer - 1
        end
        mobkit.remember(self, "sleep_timer", self.sleep_timer)
    end
    if self.isonground or self.isinliquid then
        self.max_speed = 6
    else
        self.max_speed = 12
    end
    if self.stuck_timer > 1.5 then draconis.break_free(self) end
    draconis.flap_sound(self)
end

-------------------
-- Register Eggs --
-------------------

function draconis.register_egg(mob, def)

    local desc = draconis.string_format(mob)

    local mob_s = mob:split(":")[2]

    local function pickup_egg(self, player)
        if not player:is_player() then return end
        local inv = player:get_inventory()
        if creative and
            inv:contains_item("main", {
                name = "draconis:egg_" .. mob_s .. "_" .. def.color
            }) then
            self.object:remove()
            return
        end
        if inv:room_for_item("main", {
            name = "draconis:egg_" .. mob_s .. "_" .. def.color
        }) then
            player:get_inventory():add_item("main", "draconis:egg_" .. mob_s ..
                                                "_" .. def.color)
        else
            local pos = self.object:get_pos()
            pos.y = pos.y + 0.5
            minetest.add_item(pos, {
                name = "draconis:egg_" .. mob_s .. "_" .. def.color
            })
        end
        self.object:remove()
    end

    minetest.register_craftitem("draconis:egg_" .. mob_s .. "_" .. def.color, {
        description = desc .. " Egg\n" ..
            minetest.colorize("#a9a9a9", draconis.string_format(def.color)),
        groups = {egg = 1},
        inventory_image = def.inventory_image,
        on_place = function(itemstack, _, pointed_thing)
            local pos = minetest.get_pointed_thing_position(pointed_thing, true)
            pos.y = pos.y + 0.5
            minetest.add_entity(pos, "draconis:" .. mob_s .. "_egg_" ..
                                    def.color .. "_ent")
            if not creative then
                itemstack:take_item()
                return itemstack
            end
        end
    })

    minetest.register_entity("draconis:" .. mob_s .. "_egg_" .. def.color ..
                                 "_ent", {
        -- Stats
        max_hp = 10,
        armor_groups = {immortal = 1},
        -- Movement & Physics
        max_speed = 0,
        stepheight = 0,
        jump_height = 0,
        buoyancy = 0.5,
        springiness = 0,
        -- Visual
        collisionbox = {-0.225, -0.75, -0.225, 0.225, 0.0, 0.225},
        visual_size = {x = 15, y = 15},
        visual = "mesh",
        mesh = "draconis_egg.b3d",
        textures = {"draconis_" .. mob_s .. "_egg_" .. def.color .. "_mesh.png"},
        -- Basic
        mob_id = mob,
        progress = 0,
        physical = true,
        collide_with_objects = true,
        static_save = true,
        timeout = 0,
        logic = function() end,
        get_staticdata = mobkit.statfunc,
        on_activate = function(self, staticdata, dtime_s)
            mobkit.actfunc(self, staticdata, dtime_s)
            self.progress = mobkit.recall(self, "progress")
            self.placed_in_liquid = mobkit.recall(self, "placed_in_liquid") or false
            self.owner_name = mobkit.recall(self, "owner_name") or ""
            self.color = def.color
            if self.color == "black" or self.color == "light_blue" then
                self.tex_no = 1
            elseif self.color == "bronze" or self.color == "sapphire" then
                self.tex_no = 2
            elseif self.color == "green" or self.color == "slate" then
                self.tex_no = 3
            elseif self.color == "red" or self.color == "white" then
                self.tex_no = 4
            end
        end,
        on_step = function(self, dtime)
            mobkit.stepfunc(self, dtime)
            local pos = self.object:get_pos()
            mob_core.collision_detection(self)
            mobkit.remember(self, "progress", self.progress)
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 6)) do
                if obj and obj:is_player() then
                    minetest.after(1.5, function()
                        self.owner_name =
                            mobkit.remember(self, "owner_name",
                                            obj:get_player_name())
                    end)
                end
            end
            if self.name:match("fire") then
                if minetest.get_node(pos).name == "fire:permanent_flame" then
                    self.progress = self.progress + self.dtime
                    if self.progress >= 900 and not self.hatching then
                        self.hatching = true
                        self.object:set_animation({x = 1, y = 40}, 30, 0)
                    end
                    if self.progress >= 1000 then
                        draconis.spawn_child(pos, mob, self.tex_no,
                                             self.owner_name)
                        minetest.set_node(pos, {name = "air"})
                        self.object:remove()
                    end
                else
                    self.progress = 0
                    self.hatching = false
                    self.object:set_animation({x = 0, y = 0}, 0, 0)
                end
            elseif self.name:match("ice") then
                if minetest.get_node(pos).name == "default:water_source" then
                    self.placed_in_liquid = true
                    minetest.set_node(pos, {name = "default:ice"})
                end
                if minetest.get_node(pos).name == "default:ice"
                and self.placed_in_liquid then
                    self.progress = self.progress + self.dtime
                    if self.progress >= 900 and not self.hatching then
                        self.hatching = true
                        self.object:set_animation({x = 1, y = 40}, 30, 0)
                    end
                    if self.progress >= 1000 then
                        draconis.spawn_child(pos, mob, self.tex_no,
                                             self.owner_name)
                        minetest.set_node(pos, {name = "air"})
                        self.object:remove()
                    end
                else
                    self.progress = 0
                    self.hatching = false
                    self.placed_in_liquid = false
                    self.object:set_animation({x = 0, y = 0}, 0, 0)
                end
                mobkit.remember(self, "placed_in_liquid", self.placed_in_liquid)
            end
        end,
        on_rightclick = function(self, clicker) pickup_egg(self, clicker) end,
        on_punch = function(self, puncher) pickup_egg(self, puncher) end
    })
end

for _, color in pairs(draconis.fire_colors) do
    draconis.register_egg("draconis:fire_dragon", {
        color = color,
        inventory_image = "draconis_fire_dragon_egg_" .. color .. ".png"
    })
end

for _, color in pairs(draconis.ice_colors) do
    draconis.register_egg("draconis:ice_dragon", {
        color = color,
        inventory_image = "draconis_ice_dragon_egg_" .. color .. ".png"
    })
end

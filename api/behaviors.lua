--------------
-- Behavior --
--------------

local abs = math.abs
local random = math.random
local ceil = math.ceil
local floor = math.floor
local atan2 = math.atan2
local sin = math.sin
local cos = math.cos
local function diff(a, b) -- Get difference between 2 angles
    return atan2(sin(b - a), cos(b - a))
end
local function clamp(val, _min, _max)
	if val < _min then
		val = _min
	elseif _max < val then
		val = _max
	end
	return val
end

local vec_dist = vector.distance
local vec_dir = vector.direction
local vec_add = vector.add
local vec_multi = vector.multiply

local is_night = false

local dir2yaw = minetest.dir_to_yaw
local yaw2dir = minetest.yaw_to_dir

local function check_for_night()
    local time = (minetest.get_timeofday() or 0) * 24000
    if time > 19500 or time < 4500 then
        is_night = true
    else
        is_night = false
    end
    minetest.after(15, check_for_night)
end
minetest.after(1, check_for_night)

------------
-- Tables --
------------

draconis.fire_dragon_targets = {}

draconis.ice_dragon_targets = {}

minetest.register_on_mods_loaded(function()
    for name, def in pairs(minetest.registered_entities) do
        local is_mobkit = (def.logic ~= nil or def.brainfuc ~= nil)
        local is_creatura = def._creatura_mob
        if (is_mobkit
        or is_creatura) then
            if name ~= "draconis:fire_dragon" then
                table.insert(draconis.fire_dragon_targets, name)
            end
            if name ~= "draconis:ice_dragon" then
                table.insert(draconis.ice_dragon_targets, name)
            end
        end
    end
end)

-----------------------
-- Utility Functions --
-----------------------

local function shared_owner(obj1, obj2)
    if not obj1 or not obj2 then return false end
    obj1 = creatura.is_valid(obj1)
    obj2 = creatura.is_valid(obj2)
    if obj1
    and obj2
    and obj1:get_luaentity()
    and obj2:get_luaentity() then
        obj1 = obj1:get_luaentity()
        obj2 = obj2:get_luaentity()
        return obj1.owner and obj2.owner and obj1.owner == obj2.owner
    end
    return false
end

local function is_node_walkable(name)
    local def = minetest.registered_nodes[name]
    return def and def.walkable
end

local function get_ground_level(pos2, max_height)
    local node = minetest.get_node(pos2)
    local node_under = minetest.get_node({
        x = pos2.x,
        y = pos2.y - 1,
        z = pos2.z
    })
    local height = 0
    local walkable = is_node_walkable(node_under.name) and not is_node_walkable(node.name)
    if walkable then
        return pos2
    elseif not walkable then
        if not is_node_walkable(node_under.name) then
            while not is_node_walkable(node_under.name)
            and height < max_height do
                pos2.y = pos2.y - 1
                node_under = minetest.get_node({
                    x = pos2.x,
                    y = pos2.y - 1,
                    z = pos2.z
                })
                height = height + 1
            end
        else
            while is_node_walkable(node.name)
            and height < max_height do
                pos2.y = pos2.y + 1
                node = minetest.get_node(pos2)
                height = height + 1
            end
        end
        return pos2
    end
end

local moveable = creatura.is_pos_moveable
local fast_ray_sight = creatura.fast_ray_sight

local function get_line_of_sight(self, a, b)
    local steps = floor(vector.distance(a, b))
    local line = {}

    local width = self.width
    local height = self.height

    for i = 0, steps do
        local pos

        if steps > 0 then
            pos = {
                x = a.x + (b.x - a.x) * (i / steps),
                y = a.y + (b.y - a.y) * (i / steps),
                z = a.z + (b.z - a.z) * (i / steps)
            }
        else
            pos = a
        end
        table.insert(line, pos)
    end

    if #line < 1 then
        return false
    else
        for i = 1, #line, ceil(width) do
            if not moveable(line[i], width, height) then
                return false
            end
        end
    end
    return true
end

-- Movement Method --

local function movement_fly(self, pos2)
    -- Initial Properties
    local pos = self.object:get_pos()
    local yaw = self.object:get_yaw()
    self:set_gravity(0)
    -- Collision Avoidance
    local temp_goal = self._movement_data.temp_goal
    if not temp_goal
    or self:pos_in_box({x = temp_goal.x, y = pos.y + self.height * 0.5, z = temp_goal.z}, 1) then
        self._movement_data.temp_goal = creatura.get_next_move_3d(self, pos2)
        temp_goal = self._movement_data.temp_goal
    end
    -- Calculate Movement
    local dir = vector.direction(pos, pos2)
    local tyaw = minetest.dir_to_yaw(dir)
    local turn_rate = 4
    local speed = self.speed or 2
    local path_goal = math.ceil(self.width)
    if self._path
    and #self._path > 2 then
        if #self._path < path_goal then
            path_goal = #self._path
        end
        temp_goal = self._path[path_goal]
        dir = vector.direction(pos, temp_goal)
        tyaw = minetest.dir_to_yaw(dir)
        local dir2goal = vec_dir(pos, temp_goal)
        local diff2goal = abs(diff(dir2yaw(dir2goal), yaw)) * 1.5
        if self:pos_in_box(temp_goal, self.width + diff2goal) then
            table.remove(self._path, 1)
        end
    elseif not get_line_of_sight(self, pos, pos2) then
        self._path = creatura.find_theta_path(self, pos, pos2, self.width, self.height, 500, false, true)
    end
    if temp_goal
    and not get_line_of_sight(self, pos, pos2) then
        dir = vector.direction(pos, temp_goal)
        tyaw = minetest.dir_to_yaw(dir)
    end
    -- Apply Movement
    self:tilt_to(tyaw, turn_rate)
    self:set_weighted_velocity(speed, dir)
    local v_speed = speed * dir.y
    local vel = self.object:get_velocity()
    vel.y = vel.y + (v_speed - vel.y) * 0.2
    self:set_vertical_velocity(vel.y)
    if self:pos_in_box(pos2) then
        self:halt()
        self._path_data = {}
    end
end

creatura.register_movement_method("draconis:fly_path", movement_fly)

-- Actions --

function draconis.action_hover(self, time, anim)
    local timer = time
    local function func(self)
        self:halt()
        self:set_forward_velocity(0)
        self:set_vertical_velocity(0)
        self:set_gravity(0)
        self:animate(anim or "fly_idle")
        timer = timer - self.dtime
        if timer <= 0 then
            return true
        end
    end
    self:set_action(func)
end

function draconis.action_idle_fire(self, target, time)
    local timer = time
    local start_angle = math.rad(45)
    local end_angle = math.rad(-45)
    if random(2) < 2 then
        start_angle = math.rad(-45)
        end_angle = math.rad(45)
    end
    local function func(self)
        self.head_tracking = nil
        local tgt_pos = target:get_pos()
        if not tgt_pos then
            return true
        end
        local dir = vector.direction(self.object:get_pos(), tgt_pos)
        local dist = vector.distance(self.object:get_pos(), tgt_pos)
        local yaw = self.object:get_yaw()
        local yaw_to_tgt = minetest.dir_to_yaw(dir) + start_angle
        start_angle = start_angle + (end_angle - start_angle) * self.dtime
        if abs(diff(yaw, yaw_to_tgt)) > 0.5 then
            self:turn_to(minetest.dir_to_yaw(dir), 4)
        end
        local aim_dir = yaw2dir(yaw_to_tgt)
        aim_dir.y = dir.y
        tgt_pos = vec_add(self.object:get_pos(), vector.multiply(aim_dir, dist + 10))
        self:move_head(yaw_to_tgt, aim_dir.y)
        self:set_gravity(-9.8)
        self:halt()
        self:animate("stand_fire")
        self:breath_attack(tgt_pos)
        timer = timer - self.dtime
        if timer <= 0
        or math.abs(end_angle - start_angle) < 0.1 then
            return true
        end
    end
    self:set_action(func)
end

function draconis.action_ground_attack(self, target)
    local anim = self.animations["punch"]
    local anim_time = (anim.range.y - anim.range.x) / anim.speed
    local timer = anim_time
    local damage_init = false
    local function func(self)
        self.head_tracking = target
        local pos = self:get_center_pos()
        local tgt_pos = target:get_pos()
        self:set_gravity(-9.8)
        self:halt()
        self:animate("punch")
        timer = timer - self.dtime
        if timer < anim_time * 0.5
        and not damage_init then
            local objects = minetest.get_objects_inside_radius(tgt_pos, 12 * self.growth_scale)
            for i = 1, #objects do
                local object = objects[i]
                if object ~= self.object then
                    if object:get_luaentity() then
                        local ent = object:get_luaentity()
                        local is_mobkit = (ent.logic ~= nil or ent.brainfuc ~= nil)
                        local is_creatura = ent._creatura_mob
                        if is_mobkit
                        or is_creatura then
                            target = object
                            tgt_pos = object:get_pos()
                        end
                    elseif object:is_player() then
                        target = object
                        tgt_pos = object:get_pos()
                    end
                end
                if tgt_pos then
                    local vel = vector.multiply(vector.direction(pos, tgt_pos), 8 * self.growth_scale)
                    vel.y = 6 * self.growth_scale
                    target:add_velocity(vel)
                    self:punch_target(target)
                end
            end
            damage_init = true
        end
        if timer <= 0 then
            self:animate("stand")
            return true
        end
    end
    self:set_action(func)
end

function draconis.action_knockback_attack(self, target)
    local anim = self.animations["wing_beat"]
    local anim_time = (anim.range.y - anim.range.x) / anim.speed
    local timer = anim_time
    local damage_init = false
    local function func(self)
        self.head_tracking = target
        local pos = self:get_center_pos()
        self:set_gravity(-9.8)
        self:halt()
        self:animate("wing_beat")
        timer = timer - self.dtime
        if timer < anim_time * 0.7
        and not damage_init then
            local objects = minetest.get_objects_inside_radius(pos, 12 * self.growth_scale)
            for i = 1, #objects do
                local object = objects[i]
                local tgt_pos
                if object ~= self.object then
                    if object:get_luaentity() then
                        local ent = object:get_luaentity()
                        local is_mobkit = (ent.logic ~= nil or ent.brainfuc ~= nil)
                        local is_creatura = ent._creatura_mob
                        if is_mobkit
                        or is_creatura then
                            target = object
                            tgt_pos = object:get_pos()
                        end
                    elseif object:is_player() then
                        target = object
                        tgt_pos = object:get_pos()
                    end
                end
                if tgt_pos then
                    local vel = vector.multiply(vector.direction(pos, tgt_pos), 28 * self.growth_scale)
                    vel.y = 18 * self.growth_scale
                    target:add_velocity(vel)
                end
            end
            damage_init = true
        end
        if timer <= 0 then
            self:animate("stand")
            return true
        end
    end
    self:set_action(func)
end

------------------------
-- Register Utilities --
------------------------

creatura.register_utility("draconis:wander", function(self)
    local function func(self)
        local scale = self.growth_scale
        local width = self:get_hitbox()[4]
        local pos = self.object:get_pos()
        local pos2
        if self:timer(random(6)) then
            local offset = random(width + 10 * scale, width + 20 * scale)
            if random(2) < 2 then
                offset = offset * -1
            end
            pos2 = {
                x = pos.x + offset,
                y = pos.y,
                z = pos.z + offset
            }
        end
        if not self:get_action() then
            if pos2 then
                pos2 = get_ground_level(pos2, 6)
                creatura.action_walk(self, pos2, 6, "creatura:theta_pathfind", 0.6)
            else
                creatura.action_idle(self, 0.1)
            end
        end
    end
    self:set_utility(func)
end)

creatura.register_utility("draconis:fly_wander", function(self)
    local function func(self)
        local scale = self.growth_scale
        local dist2floor = creatura.sensor_floor(self, 13, true)
        local dist2ceil = creatura.sensor_ceil(self, 13, true)
        if not self:get_action()
        or (dist2floor < 12 * scale
        or dist2ceil < 12 * scale) then
            local pos = self.object:get_pos()
            local pos2 = self:get_wander_pos_3d(24 * scale, 96 * scale)
            if dist2floor < 12 * scale then
                pos2.y = pos.y + 16
            elseif dist2ceil < 12 * scale then
                pos2.y = pos.y - 16
            end
            self._path_data = {}
            self.turn_rate = 2
            self:animate("fly")
            creatura.action_fly(self, pos2, 3, "draconis:fly_path", 1)
        end
    end
    self:set_utility(func)
end)

creatura.register_utility("draconis:land", function(self)
    local function func(self)
        if self.touching_ground then return true end
        if self.in_liquid
        and self.flight_allowed then
            self.flight_stamina = self.flight_stamina + 200
            self.is_landed = false
            return true
        end
        local scale = self.growth_scale
        local width = self.width
        local pos = self.object:get_pos()
        if not self:get_action() then
            local pos2 = self:get_wander_pos_3d(width + 10 * scale, width + 20 * scale, nil, random(-1, -10) * 0.1)
            self.turn_rate = 4
            self:animate("fly")
            creatura.action_walk(self, pos2, 3, "draconis:fly_path", 1)
        end
    end
    self:set_utility(func)
end)

creatura.register_utility("draconis:terrestrial_attack", function(self, target)
    local next_attack = random(2)
    local in_range = false
    local start_stamina = self.attack_stamina
    local function func(self)
        local target_alive, line_of_sight, tpos = self:get_target(target)
        if not target_alive then
            return true
        end
        local scale = self.growth_scale
        local pos = self.object:get_pos()
        local dist = vec_dist(pos, tpos)
        if not self:get_action() then
            in_range = false
            if next_attack > 1
            and line_of_sight
            and start_stamina - self.attack_stamina < 15 then
                draconis.action_idle_fire(self, target, 3.5)
                next_attack = random(2)
            else
                creatura.action_walk(self, tpos, 2, "creatura:pathfind", 1)
                next_attack = random(2)
            end
        end
        if dist <= self.width + 8 * scale
        and not in_range then
            if next_attack > 1 then
                draconis.action_knockback_attack(self, target)
            else
                draconis.action_ground_attack(self, target)
            end
            in_range = true
        end
    end
    self:set_utility(func)
end)

creatura.register_utility("draconis:aerial_overhead_attack", function(self, target)
    local timer = 20
    local start_pos = self.object:get_pos()
    local end_pos
    local stage = 1
    local function func(self)
        local pos = self.object:get_pos()
        local target_alive, _, tpos = self:get_target(target)
        if not target_alive then
            return true
        end
        local scale = clamp(self.growth_scale, 0.2, 1)
        local flight_dir = vec_dir(start_pos, tpos)
        flight_dir.y = -0.1
        local dist = vec_dist(start_pos, tpos)

        if not end_pos then
            end_pos = vec_add(pos, vec_multi(flight_dir, dist + 5))
        end
        if not self:get_action() then
            if stage > 1 then
                end_pos = self:get_wander_pos_3d(8 * scale, 32 * scale)
            else
                end_pos.y = tpos.y + 16 * scale
            end
            local pos2 = end_pos
            creatura.action_walk(self, pos2, 2, "draconis:fly_path", 1)
        end
        local yaw = self.object:get_yaw()
        local yaw_to_tgt = minetest.dir_to_yaw(vec_dir(pos, tpos))
        if abs(diff(yaw, yaw_to_tgt)) < 0.5
        and fast_ray_sight(pos, tpos)
        and stage < 2 then
            self:breath_attack(tpos)
            self:animate("fly_fire")
        else
            self:animate("fly")
        end
        if vec_dist(pos, end_pos) < 8 * scale then
            if stage < 2
            and end_pos.y - pos.y < 12 * scale then
                stage = 2
            else
                self.is_landed = self:memorize("is_landed", true)
                return true
            end
        end
        timer = timer - self.dtime
        if timer < 0 then
            return true
        end
    end
    self:set_utility(func)
end)

creatura.register_utility("draconis:sleep", function(self)
    local function func(self)
        if not is_night then return true end
        if not self:get_action() then
            creatura.action_idle(self, 3, "sleep")
        end
    end
    self:set_utility(func)
end)

creatura.register_utility("draconis:stay", function(self)
    local function func(self)
        local order = self.order
        if not order
        or order ~= "stay" then
            return true
        end
        if not self:get_action() then
            creatura.action_idle(self, 2, "stand")
        end
    end
    self:set_utility(func)
end)

creatura.register_utility("draconis:follow_player", function(self, player)
    local function func(self)
        local order = self.order
        if not order
        or order ~= "follow" then
            return true
        end
        if not player then
            return true
        end
        local scale = self.growth_scale
        local pos = self.object:get_pos()
        local tgt_pos = player:get_pos()
        local dist = vector.distance(pos, tgt_pos)
        local dist_to_ground = creatura.sensor_floor(self, 8, true)
        if not self:get_action() then
            if dist < clamp(8 * scale, 2, 12) then
                if dist_to_ground > 2 then
                    draconis.action_hover(self, 2, "fly_idle")
                else
                    creatura.action_idle(self, 2, "stand")
                end
            else
                local height_diff = tgt_pos.y - pos.y
                if height_diff > 8
                or dist_to_ground > 2 then
                    self:animate("fly")
                    creatura.action_walk(self, tgt_pos, 2, "draconis:fly_path", 1)
                else
                    creatura.action_walk(self, tgt_pos, 2, "creatura:pathfind", 1)
                end
            end
        end
    end
    self:set_utility(func)
end)

-- Utility Stack --

draconis.dragon_behavior = {
    [1] = {
        utility = "draconis:wander",
        get_score = function(self)
            return 0.1, {self}
        end
    },
    [2] = {
        utility = "draconis:fly_wander",
        get_score = function(self)
            if not self.is_landed then
                return 0.2, {self}
            end
            return 0
        end
    },
    [3] = {
        utility = "draconis:terrestrial_attack",
        get_score = function(self)
            if self.age < 15 then return 0 end
            local stance = self.stance
            local owner
            if self.owner then
                owner = minetest.get_player_by_name(self.owner)
            end

            local target = creatura.get_nearby_player(self)

            local targets = draconis[self.name:split(":")[2] .. "_targets"]

            for i = 1, #targets do
                local entity = creatura.get_nearby_entity(self, targets[i])
                if entity
                and not shared_owner(self, entity) then
                    target = entity
                    break
                end
            end

            if not target
            or (owner and target == owner) then
                return 0
            end

            self._util_target = target

            if self.owner_target
            and creatura.is_valid(self.owner_target) then
                target = self.owner_target
                if stance == "neutral" then
                    stance = "aggressive"
                end
            end

            if stance ~= "aggressive" then return 0 end

            local pos = self.object:get_pos()

            if is_night
            and vector.distance(pos, target:get_pos()) > 16 * self.growth_scale
            and self.alert_timer <= 0 then
                return 0
            end

            if self.is_landed then
                self.alert_timer = self:memorize("alert_timer", 15)
                return 0.9, {self, target}
            end

            return 0
        end
    },
    [4] = {
        utility = "draconis:aerial_overhead_attack",
        get_score = function(self)
            if self.age < 15 then return 0 end
            if self:get_utility() ~= "draconis:terrestrial_attack"
            and self:get_utility() ~= "draconis:aerial_overhead_attack"
            and self:get_utility() ~= "draconis:fly_wander" then
                return 0
            end
            if not self.is_landed
            and self.flight_stamina >= 100
            and self._util_target then
                self.alert_timer = self:memorize("alert_timer", 15)
                return 0.9, {self, self._util_target}
            end
            return 0
        end
    },
    [5] = {
        utility = "draconis:sleep",
        get_score = function(self)
            if self.alert_timer > 0 then return 0 end
            if is_night then
                return 0.8, {self}
            end
            return 0
        end
    },
    [6] = {
        utility = "draconis:stay",
        get_score = function(self)
            if not self.owner then return 0 end
            local order = self.order
            if order == "stay" then
                return 1, {self}
            end
            return 0
        end
    },
    [7] = {
        utility = "draconis:follow_player",
        get_score = function(self)
            if not self.owner then return 0 end
            local owner = minetest.get_player_by_name(self.owner)
            if not owner then return 0 end
            local order = self.order
            if order == "follow" then
                local stance = self.stance
                local score = 1
                if stance == "aggressive"
                or stance == "neutral"
                and self.owner_target then
                    score = 0.8
                end
                return score, {self, owner}
            end
            return 0
        end
    },
    [8] = {
        utility = "draconis:mount",
        get_score = function(self)
            if not self.owner
            or not self.rider
            or not self.rider:get_look_horizontal() then return 0 end
            return 1, {self}
        end
    },
    [9] = {
        utility = "draconis:land",
        get_score = function(self)
            local dist2floor = creatura.sensor_floor(self, clamp(16 * self.growth_scale, 4, 16), true)
            if self.is_landed
            or (self.owner and not self.fly_allowed)
            or self.flight_stamina < 15
            or dist2floor > clamp(16 * self.growth_scale, 4, 16) - 1 then
                if self:get_utility() == "draconis:fly_wander"
                or self:get_utility() == "draconis:mount"
                or (dist2floor > 2
                and not self.touching_ground) then
                    local score = 0.3
                    if self.flight_stamina < 15
                    or (self.owner
                    and not self.rider
                    and not self.fly_allowed) then
                        score = 1
                    end
                    return score, {self}
                end
            end
            return 0
        end
    }
}
---------------------
-- HQ/LQ Functions --
---------------------
------ Ver 1.0 ------

----------
-- Math --
----------

local abs = math.abs
local pi = math.pi
local ceil = math.ceil
local min = math.min
local floor = math.floor
local random = math.random
local function diff(a, b) -- Get difference between 2 angles
    return math.atan2(math.sin(b - a), math.cos(b - a))
end
local function clamp(num, _min, _max)
	if num < _min then
		num = _min
	elseif num > _max then
		num = _max
	end
	return num
end
local function lerp(a, b, w)
    if abs(a - b) > pi then
        if a < b then
            return (a + (b - a) * 1) + (pi * 2)
        elseif a > b then
            return (a + (b - a) * 1) - (pi * 2)
        end
    end
    return a + (b - a) * w
end

local vec_dist = vector.distance
local vec_dir = vector.direction
local function dist_2d(pos1, pos2)
    local a = vector.new(
        pos1.x,
        0,
        pos1.z
    )
    local b = vector.new(
        pos2.x,
        0,
        pos2.z
    )
    return vec_dist(a, b)
end
local function vec_abs(vec)
    local v = {
        x = abs(vec.x),
        y = abs(vec.y),
        z = abs(vec.z)
    }
    return v
end

----------------------
-- Helper Functions --
----------------------

local hitbox = mob_core.get_hitbox

local str_find = string.find

local function set_lift(self, val)
    local vel = self.object:get_velocity()
    local accel = self.object:get_acceleration()
    local rot = self.object:get_rotation()
    vel.y = vel.y + (val - vel.y) * 0.2
    self.object:set_velocity(vel)
    accel.y = accel.y + vel.y
    self.object:set_acceleration(accel)
    self.object:set_rotation({
        x = math.rad(vel.y),
        y = rot.y,
        z = rot.z
    })
end

local function find_closest_pos(tbl, pos)
    local iter = 2
    if #tbl < 2 then return end
    local closest = tbl[1]
    while iter < #tbl do
        if vec_dist(pos, closest) < vec_dist(pos, tbl[iter + 1]) then
            iter = iter + 1
        else
            closest = tbl[iter]
            iter = iter + 1
        end
    end
    if iter >= #tbl and closest then return closest end
end

-- Sensors --

local sensor_floor = mob_core.sensor_floor

local get_line_of_sight = draconis.get_line_of_sight

local moveable = mob_core.is_moveable

local function can_fly_to_pos(self, pos2)
    local pos = self.object:get_pos()
    local steps = floor(vec_dist(pos, pos2))
    local line = {}

    for i = 0, steps do
        local pos3

        if steps > 0 then
            pos3 = {
                x = pos.x + (pos2.x - pos.x) * (i / steps),
                y = pos.y + (pos2.y - pos.y) * (i / steps),
                z = pos.z + (pos2.z - pos.z) * (i / steps)
            }
        else
            pos3 = pos
        end
        table.insert(line, pos3)
    end

    if #line < 1 then
        return false
    else
        local width = ceil(hitbox(self)[4])
        for i = 1, #line, width do
            if line[i]
            and not moveable(line[i], width, self.height) then
                return false
            end
        end
    end
    return true
end

local function is_on_ground(object)
    if type(object) == 'table' then
        object = object.object
    end
    if object then
        local pos = object:get_pos()
        local sub = 1
        if not object:is_player() then
            sub = math.abs(hitbox(object)[2]) + 1
        end
        pos.y = pos.y - sub
        if minetest.registered_nodes[minetest.get_node(pos).name].walkable then
            return true
        end
        pos.y = pos.y - 1
        if minetest.registered_nodes[minetest.get_node(pos).name].walkable then
            return true
        end
    end
    return false
end

local function is_above_water(object)
    if type(object) == "table" then
        object = object.object
    end
    if object then
        local pos = object:get_pos()
        local sub = 1
        if not object:is_player() then
            sub = math.abs(hitbox(object)[2]) + 1
        end
        pos.y = pos.y - sub
        if minetest.registered_nodes[minetest.get_node(pos).name].drawtype == "liquid" then
            return true
        end
        pos.y = pos.y - 1
        if minetest.registered_nodes[minetest.get_node(pos).name].drawtype == "liquid" then
            return true
        end
    end
    return false
end

--------------
-- Movement --
--------------

function draconis.go_to_pos(self, tpos, speed_factor, anim)
    speed_factor = speed_factor or 1
    local pos = self.object:get_pos()
    tpos = draconis.adjust_pos(self, tpos)
    local dist = vec_dist(pos, tpos)
    if dist < 32 * self.growth_scale
    and get_line_of_sight(draconis.get_head_pos(self, tpos), tpos)
    and not draconis.is_stuck(self) then
        local path = mob_core.find_path(pos, tpos, hitbox(self)[4] - 0.1, self.height, 75)
        if path and #path > 2 then
            draconis.lq_follow_path(self, path, speed_factor, anim)
            return
        end
    else
        local path = mob_core.find_path(pos, tpos, hitbox(self)[4] - 0.1, self.height, 100)
        if path and #path > 2 then
            draconis.lq_follow_path(self, path, speed_factor, anim)
            return
        end
    end
    draconis.lq_dumb_walk(self, tpos, speed_factor, anim)
end

function draconis.fly_to_pos(self, tpos, speed_factor, anim)
    speed_factor = speed_factor or 1
    local pos = self.object:get_pos()
    tpos = draconis.adjust_pos(self, tpos)
    if can_fly_to_pos(self, tpos) then
        draconis.lq_dumb_fly(self, tpos, 1, anim)
        return true
    else
        local path = mob_core.find_path(pos, tpos, hitbox(self)[4] - 0.1, self.height, 400, false, true)
        if path and #path > 2 then
            draconis.lq_follow_aerial_path(self, path, speed_factor, anim)
            return true
        end
    end
    draconis.lq_dumb_fly(self, tpos, 1, anim)
    return false
end

function draconis.set_velocity(self, v, weight)
    local cur_v = self.object:get_velocity()
    weight = weight or self.dtime
    cur_v.x = cur_v.x + (v.x - cur_v.x) * weight
    if v.y == 0 then
        cur_v.y = cur_v.y
    else
        cur_v.y = v.y
    end
    cur_v.z = cur_v.z + (v.z - cur_v.z) * weight
    if vector.length{x = abs(cur_v.x), y = 0, z = abs(cur_v.z)} > self.max_speed * 1.5 then
        self.object:set_velocity(self.object:get_velocity())
    else
        self.object:set_velocity({x = v.x, y = cur_v.y, z = v.z})
    end
end

------------------
-- LQ Functions --
------------------

function draconis.lq_idle(self, duration, anim, tyaw)
	anim = anim or 'stand'
	local init = true
	local func = function(self)
		if init then
			mobkit.animate(self, anim)
			init = false
		end
		duration = duration - self.dtime
        if tyaw
        and abs(diff(self.object:get_yaw(), tyaw)) > 1 then
            mobkit.turn2yaw(self, tyaw, 3)
        end
		if duration <= 0 then return true end
	end
	mobkit.queue_low(self, func)
end

function draconis.lq_dumb_fly(self, dest, speed_factor, anim)
    local timer = abs(dist_2d(self.object:get_pos(), dest))
    local height = self.height
    local width = clamp(mob_core.get_hitbox(self)[4] * 1.5, 1, 2.45)
    speed_factor = speed_factor or 1
    anim = anim or "fly"
    local avoidance_path
    local avoiding_collision = false
    local func = function(self)
        mobkit.animate(self, anim)
        timer = timer - self.dtime
        local pos = self.object:get_pos()
        pos.y = pos.y + (height * 0.5)
        local yaw = self.object:get_yaw()
        if timer <= 0 then return true end

        if dist_2d(pos, dest) <= width
        and abs(pos.y - dest.y) <= ceil(height) then
            return true
        end

        local tyaw = minetest.dir_to_yaw(vec_dir(pos, dest))
        local ray_col = draconis.ray_collision_detect(self)
        if ray_col
        and diff(yaw, ray_col) > 0.25 then
            tyaw = ray_col
        end

        mob_core.tilt_to_yaw(self, tyaw, 4 + (1.5 * clamp(self.growth_scale, 0.5, 1.5)))
        local dir = vec_dir(pos, dest)
        local move_dir = minetest.yaw_to_dir(yaw)
        local yaw_diff = abs(diff(yaw, minetest.dir_to_yaw(dir)))
        local vel = self.object:get_velocity()
        draconis.set_velocity(self, {
            x = (move_dir.x * self.max_speed),
            y = 0,
            z = (move_dir.z * self.max_speed),
        }, (self.dtime * 5) - (yaw_diff * 0.066))
        local dist_to_ground = sensor_floor(self, 16)
        if dist_to_ground < 3 then
            dir.y = 1.5
        end
        set_lift(self, (self.max_speed * speed_factor) * dir.y)
    end
    mobkit.queue_low(self, func)
end

function draconis.lq_fly_idle(self, duration, anim, tyaw)
	anim = anim or "fly_idle"
	local init = false
	local func = function(self)
		if not init then
			mobkit.animate(self, anim)
			init = true
		end
        local vel = self.object:get_velocity()
        self.object:set_velocity({
            x = vel.x * 0.2,
            y = 0,
            z = vel.z * 0.2
        })
        local accel = self.object:get_acceleration()
        self.object:set_velocity({
            x = accel.x,
            y = 0,
            z = accel.z
        })
        if tyaw then mob_core.tilt_to_yaw(self, tyaw, 4) end
		duration = duration - self.dtime
		if duration <= 0 then return true end
	end
	mobkit.queue_low(self, func)
end

function draconis.lq_follow_path(self, path_data, speed_factor, anim)
    speed_factor = speed_factor or 1
    anim = anim or "walk"
    local dest = nil
    local timer = #path_data -- failsafe
    local width = hitbox(self)[4]
    local init = false
	local func = function(self)
        local pos = mobkit.get_stand_pos(self)
		local yaw = self.object:get_yaw()
        local s_fctr = speed_factor
        if path_data and #path_data > 1 then
            if #path_data >= ceil(width) then
                dest = path_data[1]
            else
                return true
            end
        else
            return true
        end

        if not self.isonground then
            table.remove(path_data, 1)
            timer = timer - 1
            s_fctr = 0.25
        end

        timer = timer - self.dtime
        if timer < 0 then return true end

        local y = self.object:get_velocity().y

        local tyaw = minetest.dir_to_yaw(vector.direction(pos, dest))

        mobkit.turn2yaw(self, tyaw, self.turn_rate or 4)

        if vec_dist(pos, path_data[#path_data]) < ceil(width) then
            if not self.isonground and not self.isinliquid and
                mob_core.fall_check(self, pos, self.max_fall or self.jump_height) then
                self.object:set_velocity({x = 0, y = y, z = 0})
            end
            return true
        end

        if vec_dist(pos, path_data[1]) < 2.5
        and diff(yaw, tyaw) < 1.5 then
            table.remove(path_data, 1)
            timer = timer - 1
        end

        if self.isonground or self.isinliquid then
            local forward_dir = vector.normalize(minetest.yaw_to_dir(yaw))
            forward_dir = vector.multiply(forward_dir,
                                          self.max_speed * s_fctr)
            forward_dir.y = y
            self.object:set_velocity(forward_dir)
            if not init then
                mobkit.animate(self, anim)
                init = true
            end
        end
    end
    mobkit.queue_low(self, func)
end

function draconis.lq_follow_aerial_path(self, path_data, speed_factor, anim)
    speed_factor = speed_factor or 1
    anim = anim or "fly"
    if not path_data
    or #path_data < 1 then
        return true
    end
    local timer = #path_data -- failsafe
    local width = hitbox(self)[4]
    local init = false
	local func = function(self)
        local pos = self.object:get_pos()
        pos.y = pos.y + (self.height * 0.5)
		local yaw = self.object:get_yaw()
        local path_iter = clamp(ceil(width), 1, #path_data)
        if path_data
        and #path_data > 1 then
            if #path_data < path_iter then
                return true
            end
        else
            return true
        end
        local dest = path_data[#path_data]

        if draconis.is_stuck(self)
        or vec_dist(pos, path_data[path_iter]) > width then
            path_iter = 1
        end

        timer = timer - self.dtime
        if timer < 0 then return true end

        local tpos = path_data[path_iter]

        local tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos))

        mob_core.tilt_to_yaw(self, tyaw, self.turn_rate or 4)

        if dist_2d(pos, dest) <= width
        and abs(pos.y - dest.y) <= self.height then
            return true
        end

        local yaw_diff = diff(yaw, tyaw)

        if dist_2d(pos, path_data[path_iter]) <= width
        and abs(pos.y - path_data[path_iter].y) <= self.height then
            table.remove(path_data, 1)
            timer = timer - 1
        end

        local dir = vec_dir(pos, tpos)
        local move_dir = minetest.yaw_to_dir(yaw)
        local vel = self.object:get_velocity()
        self.object:set_velocity({
            x = (dir.x * self.max_speed) + move_dir.x,
            y = vel.y,
            z = (dir.z * self.max_speed) + move_dir.z,
        })
        set_lift(self, (self.max_speed * speed_factor) * dir.y)
        if not init then
            mobkit.animate(self, anim)
            init = true
        end
    end
    mobkit.queue_low(self, func)
end

function draconis.lq_dumb_walk(self, dest, speed_factor, anim)
    local timer = 3 -- failsafe
    local width = mob_core.get_hitbox(self)[4]
    speed_factor = speed_factor or 1
    anim = anim or "walk"
    local avoidance_dir
    local func = function(self)
        mobkit.animate(self, anim)
        timer = timer - self.dtime
        if timer < 0 then return true end
        local s_fctr = speed_factor
        local pos = mobkit.get_stand_pos(self)
        local dir = vector.direction({x = pos.x, y = 0, z = pos.z},
                                     {x = dest.x, y = 0, z = dest.z})
        local y = self.object:get_velocity().y

        local yaw = self.object:get_yaw()

        local collison_avoidance = mob_core.collision_avoidance(self)

        if not self.isonground then s_fctr = 0.2 end

        if mobkit.isnear2d(pos, dest, clamp(width * 0.3125, 0.25, 1.5))
        and abs(dest.y - pos.y) < 1 then
            if (not self.isonground and not self.isinliquid) or
                abs(dest.y - pos.y) > 0.1 then
                self.object:set_velocity({x = 0, y = y, z = 0})
            end
            return true
        end

        local tyaw = minetest.dir_to_yaw(vec_dir(pos, dest))
        if timer < 1.5 and
        not avoidance_dir then
            avoidance_dir = collison_avoidance
        end
        if collison_avoidance
        and avoidance_dir then
            tyaw = lerp(tyaw, minetest.dir_to_yaw(avoidance_dir), 2.33)
            local particle_pos = vector.add(pos, vector.multiply(minetest.yaw_to_dir(tyaw), 6))
        end
        local yaw_diff = abs(yaw - tyaw)
        if yaw_diff > 0.1 then
            mobkit.turn2yaw(self, tyaw, self.turn_rate or 6)
        end
        if self.isonground
        or self.isinliquid then
            mobkit.go_forward_horizontal(self, self.max_speed * speed_factor)
        end
    end
    mobkit.queue_low(self, func)
end

------------------
-- HQ Functions --
------------------

------------
-- Follow --
------------

function draconis.hq_land_and_wander(self, prty)
    local goal
    local stuck_timer = 4
    local func = function(self)
        local pos = self.object:get_pos()
        if goal then
            local dir = vec_dir(pos, goal)
            local tyaw = minetest.dir_to_yaw(dir)
            self.head_tracking = nil
            draconis.move_head(self, tyaw, dir.y, 0.44)
        end
        local scale_factor = clamp(self.growth_scale, 0.5, 1.5)
        local dist_to_ground = sensor_floor(self, 16)
        if dist_to_ground < 3 * scale_factor then
            draconis.hq_wander(self, prty)
            return true
        end
        if mobkit.is_queue_empty_low(self) then
            if not goal then
                local offset = 14 * scale_factor
                goal = {
                    x = pos.x + random(-offset, offset),
                    y = pos.y - dist_to_ground,
                    z = pos.z + random(-offset, offset)
                }
            end
            draconis.fly_to_pos(self, goal, 0.75)
        elseif stuck_timer > 0
        and draconis.is_stuck(self) then
            stuck_timer = stuck_timer - self.dtime
        end
        if stuck_timer <= 0 then
            draconis.hq_aerial_wander(self, prty)
            return true
        end
    end
    mobkit.queue_high(self, func, prty)
end

function draconis.hq_follow(self, prty, target)
    if not mobkit.is_alive(target) then return true end
    local is_flying = false
    if not self.isonground then
        is_flying = true
    end
    local func = function(self)
        if not mobkit.is_alive(target) then return true end
        if not self.isinliquid then
            local pos = mobkit.get_stand_pos(self)
            local tpos = target:get_pos()
            local scale = self.growth_scale
            if scale < 0.15 then
                scale = 0.15
            end
            if mobkit.is_queue_empty_low(self) then
                if not is_on_ground(target)
                or not is_on_ground(self) then -- uses this function instead of self.isonground to avoid flight when falling a single node
                    is_flying = true
                else
                    is_flying = false
                end
                if not is_flying then
                    if vec_dist(pos, tpos) < 16 * scale then
                        mobkit.lq_idle(self, 1)
                    else
                        draconis.go_to_pos(self, tpos, scale)
                    end
                else
                    if vec_dist(pos, tpos) > 18 * scale then
                        draconis.fly_to_pos(self, tpos)
                    else
                        draconis.lq_fly_idle(self, 1.5, "fly_idle", minetest.dir_to_yaw(vec_dir(pos, tpos)))
                    end
                end
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

------------
-- Wander --
------------

local function get_ground_level(pos, pos2)
    local node = minetest.get_node(pos2)
    local node_under = minetest.get_node({
        x = pos2.x,
        y = pos2.y - 1,
        z = pos2.z
    })
    local height = 0
    local dist = dist_2d(pos, pos2)
    local walkable = minetest.registered_nodes[node_under.name].walkable and not minetest.registered_nodes[node.name].walkable
    if walkable then
        return pos2
    elseif not walkable then
        if not minetest.registered_nodes[node_under.name].walkable then
            while not minetest.registered_nodes[node_under.name].walkable
            and height <= dist do
                pos2.y = pos2.y - 1
                node_under = minetest.get_node({
                    x = pos2.x,
                    y = pos2.y - 1,
                    z = pos2.z
                })
                height = height + 1
            end
        else
            while minetest.registered_nodes[node.name].walkable
            and height <= dist do
                pos2.y = pos2.y + 1
                node = minetest.get_node(pos2)
                height = height + 1
            end
        end
        return pos2
    end
end

function draconis.hq_wander(self, prty)
    local idle_time = 3
    local move_probability = 3
    local width = hitbox(self)[4]
    local path
    local func = function(self)
        if mobkit.is_queue_empty_low(self) then
            local pos = self.object:get_pos()
            local random_goal = vector.new(
                pos.x + random(-width, width),
                pos.y,
                pos.z + random(-width, width)
            )
            random_goal = get_ground_level(pos, random_goal)
            local node = minetest.get_node({x = random_goal.x, y = random_goal.y + 1, z = random_goal.z})
            if minetest.registered_nodes[node.name].drawtype == "liquid" then
                random_goal = nil
            else
                path = mob_core.find_path(pos, random_goal, width - 0.1, self.height, ceil(dist_2d(pos, random_goal) * 1.5))
            end
            if random(move_probability) < 2
            and random_goal
            and path
            and #path > 1 then
                mob_core.lq_dumbwalk(self, path[2], 0.5)
                path[1] = nil
            else
                draconis.lq_idle(self, idle_time)
                path = nil
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

-----------
-- Sleep --
-----------

function draconis.hq_sleep(self, prty)
    local func = function(self)
        local time = minetest.get_timeofday()
        if not time then return end
        time = time * 24000
        if self.status ~= "sleeping" and (time < 4500 or time > 19500) then
            self.status = mobkit.remember(self, "status", "sleeping")
        elseif (self.status == "sleeping" and (time < 19500 and time > 4500)) or self.isinliquid then
            self.status = mobkit.remember(self, "status", "")
            return true
        end
        if self.status == "sleeping" and (time < 4500 or time > 19500) then
            draconis.animate(self, "sleep")
        end
    end
    mobkit.queue_high(self, func, prty)
end

------------
-- Attack --
------------

local get_head_pos = draconis.get_head_pos

function draconis.hq_landed_attack(self, prty, target)
    local dist
    local func = function(self)
        if not mobkit.is_alive(target) then return true end
        self.logic_state = mobkit.remember(self, "logic_state", "landed")
        if self.fall_distance > 3
        or self.isinliquid then
            draconis.hq_aerial_attack(self, prty, target)
            return true
        end
        local tpos = target:get_pos()
        local pos = get_head_pos(self, tpos)
        local yaw = self.object:get_yaw()
        local dir = vec_dir(pos, tpos)
        local tyaw = minetest.dir_to_yaw(dir)
        self.head_tracking = nil
        draconis.move_head(self, tyaw, dir.y, 0.44)
        if not dist
        or mobkit.timer(self, 2) then
            dist = vec_dist(pos, tpos)
        end
        local scale_factor = clamp(self.growth_scale, 0.5, 1.5)
        if mobkit.is_queue_empty_low(self) then
            if tpos.y - pos.y > 12 * scale_factor then
                draconis.hq_aerial_attack(self, prty, target)
                self.logic_state = "flying"
                mobkit.remember(self, "logic_state", self.logic_state)
                return true
            end
            if get_line_of_sight(pos, tpos)
            and not self.breath_meter_bottomed
            and dist < 48  * scale_factor then
                if dist > 16 * scale_factor then
                    if random(14) < 2 then
                        draconis.hq_aerial_attack(self, prty, target)
                        self.logic_state = "flying"
                        mobkit.remember(self, "logic_state", self.logic_state)
                        return true
                    end
                    draconis.lq_idle(self, 0.1, "stand_fire", tyaw)
                else
                    target:punch(self.object, 1.0, {
                        full_punch_interval = 0.1,
                        damage_groups = {fleshy = 12 * scale_factor}
                    }, nil)
                    local knockback_dir = minetest.yaw_to_dir(yaw)
                    local knockback = vector.multiply(dir, (32 + diff(yaw, tyaw)) * scale_factor)
                    knockback.y = 8 * scale_factor
                    target:add_velocity(knockback)
                    mobkit.lq_idle(self, 1, "wing_flap")
                    dist = 18 * scale_factor
                end
            else
                if dist <= 16 * scale_factor then
                    target:punch(self.object, 1.0, {
                        full_punch_interval = 0.1,
                        damage_groups = {fleshy = 12 * scale_factor}
                    }, nil)
                    local knockback_dir = minetest.yaw_to_dir(yaw)
                    local knockback = vector.multiply(dir, (32 + diff(yaw, tyaw)) * scale_factor)
                    knockback.y = 8 * scale_factor
                    target:add_velocity(knockback)
                    mobkit.lq_idle(self, 1, "wing_flap")
                    dist = 18 * scale_factor
                end
                if not get_line_of_sight(pos, tpos)
                or (self.breath_meter_bottomed
                and dist > 16 * scale_factor) then
                    draconis.go_to_pos(self, tpos, 1)
                else
                    draconis.go_to_pos(self, tpos, 1)
                end
            end
        end
        if diff(yaw, tyaw) < 1
        and self._anim
        and str_find(self._anim, "fire") then
            if self.name == "draconis:ice_dragon" then
                draconis.ice_breath(self, tpos, 48)
            elseif self.name == "draconis:fire_dragon" then
                draconis.fire_breath(self, tpos, 48)
            end
        elseif self._anim
        and str_find(self._anim, "fire") then
            mobkit.turn2yaw(self, tyaw)
        end
    end
    mobkit.queue_high(self, func, prty)
end

function draconis.hq_land_and_attack(self, prty, target)
    local goal
    local stuck_timer = 4
    local func = function(self)
        if not mobkit.is_alive(target) then return true end
        local pos = self.object:get_pos()
        if goal then
            local dir = vec_dir(pos, goal)
            local tyaw = minetest.dir_to_yaw(dir)
            self.head_tracking = nil
            draconis.move_head(self, tyaw, dir.y, 0.44)
        end
        local scale_factor = clamp(self.growth_scale, 0.5, 1.5)
        local dist_to_ground = sensor_floor(self, 16)
        if dist_to_ground < 3 * scale_factor then
            draconis.hq_landed_attack(self, prty, target)
            return true
        end
        if mobkit.is_queue_empty_low(self) then
            if not goal then
                local offset = 14 * scale_factor
                goal = {
                    x = pos.x + random(-offset, offset),
                    y = pos.y - dist_to_ground,
                    z = pos.z + random(-offset, offset)
                }
            end
            draconis.fly_to_pos(self, goal, 0.75)
        elseif stuck_timer > 0
        and draconis.is_stuck(self) then
            stuck_timer = stuck_timer - self.dtime
        end
        if stuck_timer <= 0 then
            draconis.hq_aerial_attack(self, prty, target)
            return true
        end
    end
    mobkit.queue_high(self, func, prty)
end

function draconis.hq_swoop_attack(self, prty, target)
    if not mobkit.is_alive(target) then return true end
    local point_a = self.object:get_pos()
    local point_b = target:get_pos()
    if point_a.y - point_b.y < 12 then return true end
    point_b.y = point_b.y + ((point_a.y - point_b.y) * 0.5)
    local point_c = {
        x = point_b.x + random(-16, 16),
        y = point_a.y,
        z = point_b.z + random(-16, 16)
    }
    local point_cap = 0
    while not minetest.line_of_sight(point_b, point_c)
    and point_cap < 6 do
        point_c = {
            x = point_b.x + random(-16, 16),
            y = point_a.y,
            z = point_b.z + random(-16, 16)
        }
        point_cap = point_cap + 1
    end
    local stage = 1
    local func = function(self)
        if not mobkit.is_alive(target) then return true end
        local tpos = target:get_pos()
        if mobkit.is_queue_empty_low(self) then
            if stage == 1 then
                draconis.fly_to_pos(self, point_b, 1, "fly_fire")
                stage = 2
            elseif stage == 2 then
                draconis.fly_to_pos(self, point_c, 1, "fly")
                stage = 3
            elseif stage == 3 then
                return true
            end
        end
        if self._anim
        and str_find(self._anim, "fire") then
            if self.name == "draconis:ice_dragon" then
                draconis.ice_breath(self, tpos, 48)
            elseif self.name == "draconis:fire_dragon" then
                draconis.fire_breath(self, tpos, 48)
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

function draconis.hq_aerial_attack(self, prty, target)
    local dist
    local fdist
    local vantage_pos
    local stuck_time = 0
    local func = function(self)
        if not mobkit.is_alive(target) then return true end
        if mob_core.find_val(self.target_blacklist, target) then return true end
        self.logic_state = mobkit.remember(self, "logic_state", "flying")
        local tpos = target:get_pos()
        tpos.y = tpos.y + 1
        local pos = get_head_pos(self, tpos)
        local yaw = self.object:get_yaw()
        local dir = vec_dir(pos, tpos)
        local tyaw = minetest.dir_to_yaw(dir)
        self.head_tracking = nil
        draconis.move_head(self, tyaw, dir.y, 0.44)
        if not dist
        or mobkit.timer(self, 2) then
            dist = vec_dist(pos, tpos)
            fdist = dist_2d(pos, tpos)
        end
        local scale_factor = clamp(self.growth_scale, 0.5, 1.5)
        local dist_to_ground = sensor_floor(self, 16)

        if mobkit.is_queue_empty_low(self) then
            if get_line_of_sight(pos, tpos)
            and not self.breath_meter_bottomed then -- If we have stamina, a line of sight, and the target is close enough
                if dist < 48 * scale_factor then
                    if fdist > 24 * scale_factor then
                        draconis.lq_fly_idle(self, 0.5, "fly_idle_fire", tyaw)
                    elseif fdist < 14 * scale_factor
                    and is_on_ground(target) then
                        if pos.y - tpos.y > 12 * scale_factor then
                            draconis.hq_swoop_attack(self, prty + 1, target)
                        else
                            local outset = vector.add(tpos, vector.multiply(dir, 12 * scale_factor))
                            outset.y = outset.y + (32 * scale_factor)
                            if not minetest.registered_nodes[minetest.get_node(outset).name].walkable then
                                tpos = outset
                            end
                            draconis.fly_to_pos(self, tpos, 1, "fly")
                        end
                    else
                        local outset = vector.add(tpos, vector.multiply(dir, 6 * scale_factor))
                        if not minetest.registered_nodes[minetest.get_node(outset).name].walkable then
                            tpos = outset
                        end
                        draconis.fly_to_pos(self, tpos, 1, "fly_fire")
                    end
                else
                    if pos.y - tpos.y > 16 * scale_factor then
                        draconis.hq_swoop_attack(self, prty + 1, target)
                    else
                        draconis.fly_to_pos(self, tpos, 1, "fly_fire")
                    end
                end
                vantage_pos = nil
            elseif not get_line_of_sight(pos, tpos) then
                if fdist <= hitbox(self)[4] + (6 * self.growth_scale) then
                    draconis.hq_land_and_attack(self, prty, target)
                    return true
                elseif not vantage_pos then
                    local minp = vector.subtract(pos, 32)
                    local maxp = vector.add(pos, 32)
                    for z = minp.z, maxp.z do
                        for y = minp.y, maxp.y do
                            for x = minp.x, maxp.x do
                                local i_pos = vector.new(x, y, z)
                                if minetest.line_of_sight(i_pos, tpos) then
                                    vantage_pos = i_pos
                                    tpos = vantage_pos
                                    break
                                end
                            end
                        end
                    end
                end
                if vantage_pos then
                    local can_reach = draconis.fly_to_pos(self, tpos, 1, "fly")
                    if not can_reach then
                        draconis.hq_land_and_attack(self, prty, target)
                    end
                elseif not vantage_pos then
                    local outset = vector.add(tpos, vector.multiply(dir, 12 * scale_factor))
                    outset.y = outset.y + (32 * scale_factor)
                    if not minetest.registered_nodes[minetest.get_node(outset).name].walkable then
                        tpos = outset
                    end
                    draconis.fly_to_pos(self, tpos, 1, "fly")
                end
            else
                if is_on_ground(target) then
                    draconis.hq_land_and_attack(self, prty, target)
                    return true
                elseif not self.breath_meter_bottomed then
                    draconis.lq_fly_idle(self, 0.5, "fly_idle_fire", tyaw)
                else
                    draconis.hq_land_and_attack(self, prty, target)
                    return true
                end
            end
        end
        if dist <= 14 * scale_factor then
            target:punch(self.object, 1.0, {
                full_punch_interval = 0.1,
                damage_groups = {fleshy = 12 * scale_factor}
            }, nil)
            local knockback = vector.multiply(dir, 32 * scale_factor)
            knockback.y = 14 * scale_factor
            target:add_velocity(knockback)
            dist = 18 * scale_factor
        end
        if diff(yaw, tyaw) < 1
        and self._anim
        and str_find(self._anim, "fire") then
            if self.name == "draconis:ice_dragon" then
                draconis.ice_breath(self, tpos, 48)
            elseif self.name == "draconis:fire_dragon" then
                draconis.fire_breath(self, tpos, 48)
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

--------------------------------
-- Aerial Wandering Functions --
--------------------------------

function draconis.lq_takeoff(self)
    local init = false
    local timer = 2
    local func = function(self)
        if not init then
            draconis.animate(self, "takeoff")
            init = true
        elseif timer <= 1.7 then
            set_lift(self, 6)
        end
        if timer <= 0 then
            return true
        elseif timer < 1 then
            draconis.animate(self, "fly_idle")
        end
        timer = timer - self.dtime
    end
    mobkit.queue_low(self, func)
end

function draconis.hq_aerial_wander(self, prty)
    local goal
    local init = false
    local flight_started = false
    local goal_reset_timer = 6
    local func = function(self)

        if not init then
            if self.isonground then
                draconis.lq_takeoff(self)
            end
            init = true
        end
        if not self.isonground then
            flight_started = true
        elseif flight_started then
            draconis.hq_wander(self, prty)
            return true
        end
        local pos = self.object:get_pos()
        -- Find a position to fly to
        if not goal then
            goal = {
                x = pos.x + random(-64, 64),
                y = pos.y,
                z = pos.z + random(-64, 64)
            }
            local dist_to_ground = sensor_floor(self, 16)
            if dist_to_ground <= 8 then
                goal.y = pos.y + random(4, 8)
            else
                goal.y = pos.y + random(-8, 8)
            end
            if self.tamed
            and minetest.get_player_by_name(self.owner) then
                local owner = minetest.get_player_by_name(self.owner)
                local owner_pos = owner:get_pos()
                if vec_dist(goal, owner_pos) > 48
                or vec_dist(goal, owner_pos) > 48 then
                    local move_dir = vec_dir(pos, owner_pos)
                    local move_factor = goal.x - pos.x
                    local move_pos = vector.add(pos, vector.multiply(move_dir, abs(move_factor)))
                    goal.x = move_pos.x
                    goal.y = goal.y * clamp(move_dir.y, -1, 1)
                    goal.z = move_pos.z
                end
            end
            goal = draconis.adjust_pos(self, goal)
            goal_reset_timer = random(6, 9) -- Nice.
        elseif mobkit.is_queue_empty_low(self) then
            if self.isinliquid then
                goal.y = goal.y + 8
            end
            draconis.fly_to_pos(self, goal)
            if not can_fly_to_pos(self, goal)
            or vec_dist(pos, goal) < ceil(hitbox(self)[4]) * 4 then
                goal = nil
            end
        end
        goal_reset_timer = goal_reset_timer - self.dtime
        if goal_reset_timer <= 0 then
            goal = nil
        end
    end
    mobkit.queue_high(self, func, prty)
end
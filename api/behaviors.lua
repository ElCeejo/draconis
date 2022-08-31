---------------
-- Behaviors --
---------------

draconis.fire_dragon_targets = {}

draconis.ice_dragon_targets = {}

draconis.wyvern_targets = {}

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_entities) do
		local is_mobkit = (def.logic ~= nil or def.brainfuc ~= nil)
		local is_creatura = def._creatura_mob
		if is_mobkit
		or is_creatura
		or def._cmi_is_mob then
			if name ~= "draconis:fire_dragon" then
				table.insert(draconis.fire_dragon_targets, name)
			end
			if name ~= "draconis:ice_dragon" then
				table.insert(draconis.ice_dragon_targets, name)
			end
			local hp = def.max_health or def.max_hp or 21
			if hp < 21 then
				table.insert(draconis.wyvern_targets, name)
			end
		end
	end
end)

-- Local Math --

local atan2 = math.atan2
local cos = math.cos
local sin = math.sin
local abs = math.abs
local ceil = math.ceil
local random = math.random
local rad = math.rad

local function clamp(val, _min, _max)
	if val < _min then
		val = _min
	elseif _max < val then
		val = _max
	end
	return val
end

local function diff(a, b) -- Get difference between 2 angles
	return atan2(sin(b - a), cos(b - a))
end

local function vec_raise(v, n)
	return {x = v.x, y = v.y + n, z = v.z}
end

local vec_normal = vector.normalize
local vec_len = vector.length
local vec_dir = vector.direction
local vec_dist = vector.distance
local vec_multi = vector.multiply
local vec_sub = vector.subtract
local vec_add = vector.add
local yaw2dir = minetest.yaw_to_dir
local dir2yaw = minetest.dir_to_yaw

---------------------
-- Local Utilities --
---------------------

local is_night = true

local function check_time()
    local time = (minetest.get_timeofday() or 0) * 24000
    is_night = time > 19500 or time < 4500
    minetest.after(10, check_time)
end

check_time()

local moveable = creatura.is_pos_moveable

local function is_target_flying(target)
	if not target or not target:get_pos() then return end
	local pos = target:get_pos()
	if not pos then return end
	local node = minetest.get_node(pos)
	if not node then return false end
	if minetest.get_item_group(node.name, "igniter") > 0
	or creatura.get_node_def(node.name).drawtype == "liquid"
	or creatura.get_node_def(vec_raise(pos, -1)).drawtype == "liquid" then return false end
	local flying = true
	for i = 1, 8 do
		local fly_pos = {
			x = pos.x,
			y = pos.y - i,
			z = pos.z
		}
		if creatura.get_node_def(fly_pos).walkable then
			flying = false
			break
		end
	end
	return flying
end

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

local function get_target_group(target, radius)
	local pos = target:get_pos()
	local objects = minetest.get_objects_in_area(vec_sub(pos, radius or 8), vec_add(pos, radius or 8))
	local group = {}
	for _, object in ipairs(objects) do
		local ent = object and object:get_luaentity()
		if ent
		and not ent._ignore then
			table.insert(group, object)
		end
	end
	return group
end

local function find_target(self, list)
	local owner = self.owner and minetest.get_player_by_name(self.owner)
	local targets = creatura.get_nearby_players(self)
	if #targets > 0 then -- If there are players nearby
		local target = targets[random(#targets)]
		local is_creative = target:is_player() and minetest.is_creative_enabled(target)
		local is_owner = owner and target == owner
		if is_creative or is_owner then targets = {} end
	end
	targets = (#targets < 1 and list and creatura.get_nearby_objects(self, list)) or targets
	if #targets < 1 then return end
	return targets[random(#targets)]
end

local function destroy_terrain(self, dir)
	local moveresult = self.moveresult
	if not terrain_destruction
	or not moveresult
	or not moveresult.collisions then
		return
	end
	local pos = self.object:get_pos()
	if not pos then return end
	for _, collision in ipairs(moveresult.collisions) do
		if collision.type == "node" then
			local n_pos = collision.node_pos
			if n_pos.y - pos.y >= 1
			or dir.y < 0 then
				local node = minetest.get_node(n_pos)
				if minetest.get_item_group(node.name, "cracky") ~= 1
				and minetest.get_item_group(node.name, "unbreakable") < 1 then
					if random(6) < 2 then
						minetest.dig_node(n_pos)
					else
						minetest.remove_node(n_pos)
					end
				end
			end
		end
	end
end

-- Movement Methods --

--[[local function get_collision(self, yaw)
	local width = self.width
	local height = self.height
	local total_height = height + self.stepheight
	local pos = self.object:get_pos()
	if not pos then return end
	local ground = creatura.get_ground_level(pos, (self.stepheight or 2))
	if ground.y > pos.y then
		pos = ground
	end
	local pos2 = vec_add(pos, vec_multi(yaw2dir(yaw), width + 3))
	ground = creatura.get_ground_level(pos2, (self.stepheight or 2))
	if ground.y > pos2.y then
		pos2 = ground
	end
	for x = -width, width, width / ceil(width) do
		local step_flag = false
		for y = 0, total_height, total_height / ceil(total_height) do
			if y > height
			and not step_flag then -- if we don't have to step up, no need to check if step is clear
				break
			end
			local vec1 = {
				x = cos(yaw) * ((pos.x + x) - pos.x) + pos.x,
				y = pos.y + y,
				z = sin(yaw) * ((pos.x + x) - pos.x) + pos.z
			}
			local vec2 = {
				x = cos(yaw) * ((pos2.x + x) - pos2.x) + pos2.x,
				y = vec1.y,
				z = sin(yaw) * ((pos2.x + x) - pos2.x) + pos2.z
			}
			local ray = raycast(vec1, vec2, true)
			if ray then
				local ray_pos = ray.intersection_point
				if y > (self.stepheight or 1.1)
				or y > height then
					return true, ray.intersection_point
				else
					step_flag = true
				end
			end
		end
	end
	return false
end]]

local function get_collision_ranged(self, range)
	local yaw = self.object:get_yaw()
	local pos = self.object:get_pos()
	if not pos then return end
	local width = self.width
	local height = self.height
	pos.y = pos.y + 0.01
	local m_dir = vec_normal(self.object:get_velocity())
	local ahead = vec_add(pos, vec_multi(m_dir, width + 1)) -- 1 node out from edge of box
	-- Loop
	local pos_x, pos_y, pos_z = ahead.x, ahead.y, ahead.z
	for i = 0, range or 4 do
		pos_x = pos_x + m_dir.x * i
		pos_y = pos_y + m_dir.y * i
		pos_z = pos_z + m_dir.z * i
		for x = -width, width, width / ceil(width) do
			for y = 0, height, height / ceil(height) do
				local pos2 = {
					x = cos(yaw) * ((pos_x + x) - pos_x) + pos_x,
					y = pos.y + y,
					z = sin(yaw) * ((pos_x + x) - pos_x) + pos_z
				}
				if pos2.y - pos.y > (self.stepheight or 1.1)
				and creatura.get_node_def(pos2).walkable then
					return true, pos2
				end
			end
		end
	end
	return false
end

local function debugpart(pos, time, tex)
	minetest.add_particle({
		pos = pos,
		texture = tex or "creatura_particle_red.png",
		expirationtime = time or 0.55,
		glow = 6,
		size = 8
	})
end

local function get_avoidance_dir(self)
	local pos = self.object:get_pos()
	if not pos then return end
	local _, col_pos = get_collision_ranged(self)
	if col_pos then
		local vel = self.object:get_velocity()
		vel.y = 0
		local vel_len = vec_len(vel)
		local ahead = vec_add(pos, vec_normal(vel))
		local avoidance_force = vector.subtract(ahead, col_pos)
		avoidance_force = vec_multi(vec_normal(avoidance_force), (vel_len > 1 and vel_len) or 1)
		return vec_dir(pos, vec_add(ahead, avoidance_force))
	end
end

creatura.register_movement_method("draconis:fly_pathfind", function(self)
	local path = {}
	local tick = 4
	self:set_gravity(0)
	local function func(_self, goal, speed_x)
		local pos = _self.object:get_pos()
		if not pos then return end
		-- Return true when goal is reached
		if vec_dist(pos, goal) < _self.width * 1.5 then
			_self:halt()
			return true
		end
		local steer_to
		tick = tick - 1
		if tick <= 0 then
			steer_to = get_avoidance_dir(_self)
			tick = 4
		end
		-- Get movement direction
		local goal_dir = vec_dir(pos, goal)
		if steer_to then
			goal_dir = steer_to
			if #path < 2 then
				path = creatura.find_path(_self, pos, goal, _self.width, _self.height, 200, false, true) or {}
			end
		end
		if #path > 1 then
			goal_dir = vec_dir(pos, path[2])
			if vec_dist(pos, path[1]) < _self.width then
				table.remove(path, 1)
			end
		end
		local goal_yaw = dir2yaw(goal_dir)
		local speed = (_self.speed or 24) * speed_x
		_self:tilt_to(goal_yaw, _self.turn_rate or 6)
		-- Set Velocity
		_self:set_forward_velocity(speed)
		_self:set_vertical_velocity(speed * goal_dir.y)
	end
	return func
end)

creatura.register_movement_method("draconis:fly_obstacle_avoidance", function(self)
	self:set_gravity(0)
	local avd_step = 15
	local steer_to
	local function func(_self, goal, speed_x)
		local pos = _self.object:get_pos()
		if not pos then return end
		-- Return true when goal is reached
		if vec_dist(pos, goal) < _self.width * 1.5 then
			_self:set_forward_velocity(2)
			_self:set_vertical_velocity(0)
			_self:halt()
			return true
		end
		-- Get movement direction
		avd_step = (avd_step <= 0 and 15) or avd_step - 1
		steer_to = (avd_step > 1 and steer_to) or (avd_step <= 0 and get_avoidance_dir(self, goal))
		local goal_dir = steer_to or vec_dir(pos, goal)
		local goal_yaw = dir2yaw(goal_dir)
		_self:tilt_to(goal_yaw, _self.turn_rate or 6)
		-- Set Velocity
		local speed = (_self.speed or 24) * speed_x
		_self:set_forward_velocity(speed)
		_self:set_vertical_velocity(speed * goal_dir.y)
	end
	return func
end)

-- Actions --

function draconis.action_flight_fire(self, target, timeout)
	local timer = timeout or 12
	local goal
	local function func(_self)
		local pos = _self.stand_pos
		if timer <= 0 then return true end
		local target_alive, los, tgt_pos = _self:get_target(target)
		if not target_alive then return true end
		self.head_tracking = target
		if not goal or _self:timer(4) then
			goal = _self:get_wander_pos_3d(6, 8, vec_dir(pos, tgt_pos))
		end
		if _self:move_to(goal, "draconis:fly_obstacle_avoidance", 0.5) then
			goal = nil
		end
		if los then
			_self:breath_attack(tgt_pos)
			_self:animate("fly_fire")
		else
			_self:animate("fly")
		end
		timer = timer - _self.dtime
	end
	self:set_action(func)
end

function draconis.action_pursue(self, target, timeout, method, speed_factor, anim)
	local timer = timeout or 4
	local goal
	local function func(_self)
		local target_alive, line_of_sight, tgt_pos = _self:get_target(target)
		if not target_alive then
			return true
		end
		self.head_tracking = target
		local pos = _self.object:get_pos()
		if not pos then return end
		timer = timer - _self.dtime
		if timer <= 0 then return true end
		if not goal
		or (line_of_sight
		and vec_dist(goal, tgt_pos) > 3) then
			goal = tgt_pos
		end
		if timer <= 0
		or _self:move_to(goal, method or "creatura:obstacle_avoidance", speed_factor or 0.5) then
			_self:halt()
			return true
		end
		_self:animate(anim or "walk")
	end
	self:set_action(func)
end

function draconis.action_fly(self, pos2, timeout, method, speed_factor, anim)
	local timer = timeout or 4
	local function func(_self)
		timer = timer - _self.dtime
		if timer <= 0
		or _self:move_to(pos2, method or "draconis:fly_obstacle_avoidance", speed_factor) then
			return true
		end
		_self:animate(anim or "fly")
	end
	self:set_action(func)
end

function draconis.action_hover(self, time)
	local timer = time or 3
	local function func(_self)
		_self:set_gravity(0)
		_self:set_forward_velocity(0)
		_self:set_vertical_velocity(0)
		_self:animate("hover")
		timer = timer - _self.dtime
		if timer <= 0 then
			return true
		end
	end
	self:set_action(func)
end

function draconis.action_idle_fire(self, target, time)
	local timer = time
	local start_angle = rad(45)
	local end_angle = rad(-45)
	if random(2) < 2 then
		start_angle = rad(-45)
		end_angle = rad(45)
	end
	local function func(_self)
		_self.head_tracking = nil
		local pos = _self.object:get_pos()
		if not pos then return true end
		local tgt_pos = target:get_pos()
		if not tgt_pos then return true end
		local dir = vec_dir(pos, tgt_pos)
		local dist = vec_dist(pos, tgt_pos)
		local yaw = _self.object:get_yaw()
		local yaw_to_tgt = minetest.dir_to_yaw(dir) + start_angle
		start_angle = start_angle + (end_angle - start_angle) * _self.dtime
		if abs(diff(yaw, yaw_to_tgt)) > 0.5 then
			_self:turn_to(minetest.dir_to_yaw(dir), 4)
		end
		local aim_dir = yaw2dir(yaw_to_tgt)
		aim_dir.y = dir.y
		tgt_pos = vec_add(pos, vector.multiply(aim_dir, dist + 10))
		_self:move_head(yaw_to_tgt, aim_dir.y)
		_self:set_gravity(-9.8)
		_self:halt()
		_self:animate("stand_fire")
		_self:breath_attack(tgt_pos)
		timer = timer - _self.dtime
		if timer <= 0
		or math.abs(end_angle - start_angle) < 0.1 then
			return true
		end
	end
	self:set_action(func)
end

function draconis.action_hover_fire(self, target, time)
	local timer = time
	local start_angle = rad(45)
	local end_angle = rad(-45)
	if random(2) < 2 then
		start_angle = rad(-45)
		end_angle = rad(45)
	end
	local function func(_self)
		_self.head_tracking = nil
		local pos = _self.object:get_pos()
		if not pos then return end
		local tgt_pos = target:get_pos()
		if not tgt_pos then return true end
		local dir = vec_dir(pos, tgt_pos)
		local dist = vec_dist(pos, tgt_pos)
		local yaw = _self.object:get_yaw()
		local yaw_to_tgt = minetest.dir_to_yaw(dir) + start_angle
		start_angle = start_angle + (end_angle - start_angle) * _self.dtime
		if abs(diff(yaw, yaw_to_tgt)) > 0.5 then
			_self:turn_to(minetest.dir_to_yaw(dir), 4)
		end
		local aim_dir = yaw2dir(yaw_to_tgt)
		aim_dir.y = dir.y
		tgt_pos = vec_add(pos, vector.multiply(aim_dir, dist + 10))
		_self:move_head(yaw_to_tgt, aim_dir.y)
		_self:set_gravity(0)
		_self:set_forward_velocity(-2)
		_self:set_vertical_velocity(0.5)
		_self:animate("hover_fire")
		_self:breath_attack(tgt_pos)
		timer = timer - _self.dtime
		if timer <= 0
		or math.abs(end_angle - start_angle) < 0.1 then
			return true
		end
	end
	self:set_action(func)
end

function draconis.action_land(self)
	local init = false
	local anim = self.animations["land"]
	local anim_time = (anim.range.y - anim.range.x) / anim.speed
	local timer = anim_time * 0.5
	local function func(_self)
		if not init then
			-- Apply gravity
			_self:set_gravity(-9.8)
			-- Begin Animation
			_self.object:set_yaw(_self.object:get_yaw())
			_self:animate("land")
			init = true
		end
		timer = timer - _self.dtime
		if timer <= 0 then
			return true
		end
	end
	self:set_action(func)
end

-- Close-range Attacks

function draconis.action_slam(self)
	local anim = self.animations["slam"]
	local anim_time = (anim.range.y - anim.range.x) / anim.speed
	local timeout = anim_time
	local damage_init = false
	local scale = self.growth_scale
	self:set_gravity(-9.8)
	self:halt()
	local function func(_self)
		local yaw = _self.object:get_yaw()
		local pos = _self.object:get_pos()
		if not pos then return end
		_self:animate("slam")
		timeout = timeout - _self.dtime
		if timeout < anim_time * 0.5
		and not damage_init then
			local terrain_dir
			local aoe_center = vec_add(pos, vec_multi(yaw2dir(yaw), _self.width))
			local affected_objs = minetest.get_objects_inside_radius(aoe_center, 8 * scale)
			for _, object in ipairs(affected_objs) do
				local tgt_pos = object and object ~= self.object and object:get_pos()
				if tgt_pos then
					local ent = object:get_luaentity()
					local is_player = object:is_player()
					if (creatura.is_alive(ent)
					and not ent._ignore)
					or is_player then
						local dir = vec_dir(pos, tgt_pos)
						terrain_dir = terrain_dir or dir
						local vel = {
							x = dir.x * _self.damage,
							y = dir.y * _self.damage * 0.5,
							z = dir.z * _self.damage
						}
						object:add_velocity(vel)
						_self:punch_target(object, _self.damage)
					end
				end
			end
			if terrain_dir then
				destroy_terrain(self, terrain_dir)
			end
			minetest.sound_play("draconis_slam", {
				object = _self.object,
				gain = 1.0,
				max_hear_distance = 64,
				loop = false,
			})
			damage_init = true
		end
		if timeout <= 0 then self:animate("stand") return true end
	end
	self:set_action(func)
end

function draconis.action_repel(self)
	local anim = self.animations["repel"]
	local anim_time = (anim.range.y - anim.range.x) / anim.speed
	local timeout = anim_time
	local damage_init = false
	local scale = self.growth_scale
	self:set_gravity(-9.8)
	self:halt()
	minetest.sound_play("draconis_repel", {
		object = self.object,
		gain = 1.0,
		max_hear_distance = 64,
		loop = false,
	})
	local function func(_self)
		local yaw = _self.object:get_yaw()
		local pos = _self.object:get_pos()
		if not pos then return end
		_self:animate("repel")
		timeout = timeout - _self.dtime
		if timeout < anim_time * 0.5
		and not damage_init then
			local aoe_center = vec_add(pos, vec_multi(yaw2dir(yaw), _self.width))
			local affected_objs = minetest.get_objects_inside_radius(aoe_center, 8 * scale)
			for _, object in ipairs(affected_objs) do
				local tgt_pos = object and object ~= self.object and object:get_pos()
				if tgt_pos then
					local ent = object:get_luaentity()
					local is_player = object:is_player()
					if (creatura.is_alive(ent)
					and not ent._ignore)
					or is_player then
						local dir = vec_dir(pos, tgt_pos)
						local vel = {
							x = dir.x * _self.damage * 1.5,
							y = dir.y * _self.damage * 2,
							z = dir.z * _self.damage * 1.5
						}
						object:add_velocity(vel)
					end
				end
			end
			minetest.sound_play("draconis_slam", {
				object = _self.object,
				gain = 1.0,
				max_hear_distance = 64,
				loop = false,
			})
			damage_init = true
		end
		if timeout <= 0 then self:animate("stand") return true end
	end
	self:set_action(func)
end

function draconis.action_punch(self)
	local anim = self.animations["bite"]
	local anim_time = (anim.range.y - anim.range.x) / anim.speed
	local timeout = anim_time
	local damage_init = false
	self:set_gravity(-9.8)
	self:halt()
	local function func(_self)
		local yaw = _self.object:get_yaw()
		local pos = _self.object:get_pos()
		if not pos then return end
		_self:animate("bite")
		timeout = timeout - _self.dtime
		if timeout < anim_time * 0.5
		and not damage_init then
			local aoe_center = vec_add(pos, vec_multi(yaw2dir(yaw), _self.width))
			local affected_objs = minetest.get_objects_inside_radius(aoe_center, 2)
			for _, object in ipairs(affected_objs) do
				local tgt_pos = object and object ~= self.object and object:get_pos()
				if tgt_pos then
					local ent = object:get_luaentity()
					local is_player = object:is_player()
					if (creatura.is_alive(ent)
					and not ent._ignore)
					or is_player then
						_self:punch_target(object, _self.damage)
					end
				end
			end
			minetest.sound_play("draconis_jungle_wyvern_bite", {
				object = _self.object,
				gain = 1.0,
				max_hear_distance = 16,
				loop = false,
			})
			damage_init = true
		end
		if timeout <= 0 then self:animate("stand") return true end
	end
	self:set_action(func)
end

local function can_takeoff(self, pos)
	local height = self.height
	local pos2 = {
		x = pos.x,
		y = pos.y + height + 0.5,
		z = pos.z
	}
	if not moveable(pos2, self.width, height) then
		return false
	end
	return true
end

function draconis.action_takeoff(self, tgt_height)
	local init = false
	local height
	local anim = self.animations["takeoff"]
	local anim_time = (anim.range.y - anim.range.x) / anim.speed
	local timer = anim_time
	tgt_height = tgt_height or 4
	local function func(_self)
		local pos = _self.object:get_pos()
		if not pos then return end
		timer = timer - _self.dtime
		if timer <= 0 then
			_self:animate("hover")
			_self:set_vertical_velocity(0)
			return true
		end
		if not init then
			height = pos.y
			init = true
			_self:animate("takeoff")
		end
		local height_diff = pos.y - height
		if height_diff < tgt_height
		and timer < anim_time * 0.5 then
			_self:set_forward_velocity(0)
			_self:set_vertical_velocity(anim_time * tgt_height)
			_self:set_gravity(0)
		end
	end
	self:set_action(func)
end

--------------
-- Behavior --
--------------

-- Sleep

creatura.register_utility("draconis:sleep", function(self)
	local function func(_self)
		if not _self:get_action() then
			_self.object:set_yaw(_self.object:get_yaw())
			creatura.action_idle(_self, 3, "sleep")
		end
	end
	self:set_utility(func)
end)

-- Wander

creatura.register_utility("draconis:wander", function(self)
	local center = self.object:get_pos()
	if not center then return end
	local function func(_self)
		if not _self:get_action() then
			local move = random(5) < 2
			if move then
				local pos2 = _self:get_wander_pos(3, 6)
				if vec_dist(pos2, center) > 16 then
					creatura.action_idle(_self, random(2, 5))
				else
					creatura.action_move(_self, pos2, 4, "creatura:obstacle_avoidance", 0.5)
				end
			else
				creatura.action_idle(_self, random(2, 5))
			end
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("draconis:die", function(self)
	local timer = 1.5
	local init = false
	local function func(_self)
		if not init then
			_self:play_sound("death")
			creatura.action_fallover(_self)
			init = true
		end
		timer = timer - _self.dtime
		if timer <= 0 then
			local pos = _self.object:get_pos()
			if not pos then return end
			minetest.add_particlespawner({
				amount = 8,
				time = 0.25,
				minpos = {x = pos.x - 0.1, y = pos.y, z = pos.z - 0.1},
				maxpos = {x = pos.x + 0.1, y = pos.y + 0.1, z = pos.z + 0.1},
				minacc = {x = 0, y = 2, z = 0},
				maxacc = {x = 0, y = 3, z = 0},
				minvel = {x = random(-1, 1), y = -0.25, z = random(-1, 1)},
				maxvel = {x = random(-2, 2), y = -0.25, z = random(-2, 2)},
				minexptime = 0.75,
				maxexptime = 1,
				minsize = 4,
				maxsize = 4,
				texture = "creatura_smoke_particle.png",
				animation = {
					type = 'vertical_frames',
					aspect_w = 4,
					aspect_h = 4,
					length = 1,
				},
				glow = 1
			})
			creatura.drop_items(_self)
			_self.object:remove()
		end
	end
	self:set_utility(func)
end)

-- Wander Flight

creatura.register_utility("draconis:aerial_wander", function(self, speed_x)
	local center = self.object:get_pos()
	if not center then return end
	local height_tick = 0
	local function func(_self)
		local pos = _self.object:get_pos()
		if not pos then return end
		height_tick = height_tick - 1
		if height_tick <= 0 then
			local dist2floor = creatura.sensor_floor(_self, 10, true)
			center.y = center.y + (10 - dist2floor)
			height_tick = 30
		end
		if _self.nest_pos
		and vec_dist(pos, _self.nest_pos) > 128 then
			center = _self.nest_pos
		end
		if not _self:get_action() then
			local move_dir = (vec_dist(pos, center) > 42 and vec_dir(pos, center)) or nil
			local pos2 = _self:get_wander_pos_3d(6, 9, move_dir)
			creatura.action_move(_self, pos2, 5, "draconis:fly_obstacle_avoidance", speed_x or 0.5, "fly")
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("draconis:fly_to_land", function(self)
	local landed = false
	local function func(_self)
		if not _self:get_action() then
			if landed then return true end
			if _self.touching_ground then
				draconis.action_land(_self)
				landed = true
			else
				local pos2 = _self:get_wander_pos_3d(3, 6)
				if pos2 then
					local dist2floor = creatura.sensor_floor(_self, 10, true)
					pos2.y = pos2.y - dist2floor
					creatura.action_move(_self, pos2, 3, "draconis:fly_obstacle_avoidance", 0.6, "fly")
					_self:animate("fly")
				end
			end
		end
	end
	self:set_utility(func)
end)

-- Wyvern Breaking

creatura.register_utility("draconis:wyvern_breaking", function(self, player)
	local center
	local taming = 0
	local feed_timer = 10
	local function func(_self)
		if not player
		or not player:get_pos() then
			return true
		end
		local pos = _self.object:get_pos()
		if not pos then return end
		if player:get_player_control().sneak then
			draconis.detach_player(_self, player)
			return true
		end
		feed_timer = feed_timer - _self.dtime
		if feed_timer <= 0 then
			local inv = player:get_inventory()
			local stack = inv:get_stack("main", 1)
			local _, item_name = _self:follow_item(stack)
			if item_name then
				stack:take_item(1)
				inv:set_stack("main", 1, stack)
				taming = taming + 10
				local move_dir = vector.normalize(_self.object:get_velocity())
				local part_pos = vector.add(pos, vector.multiply(move_dir, 12))
				local def = minetest.registered_items[item_name]
				local texture = def.inventory_image
				if not texture or texture == "" then
					texture = def.wield_image
				end
				minetest.add_particlespawner({
					amount = 8,
					time = 0.1,
					minpos = part_pos,
					maxpos = part_pos,
					minvel = {x=-1, y=1, z=-1},
					maxvel = {x=1, y=2, z=1},
					minacc = {x=0, y=-5, z=0},
					maxacc = {x=0, y=-9, z=0},
					minexptime = 1,
					maxexptime = 1,
					minsize = 4,
					maxsize = 6,
					collisiondetection = true,
					vertical = false,
					texture = texture,
				})
				minetest.chat_send_player(player:get_player_name(),
					"The Jungle Wyvern ate some " .. def.description .. "! Taming is at " .. taming .. "%")
			else
				draconis.detach_player(_self, player)
				return true
			end
			feed_timer = 10
		end
		if taming >= 100 then
			minetest.chat_send_player(player:get_player_name(), "The Jungle Wyvern has been tamed!")
			_self.owner = _self:memorize("owner", player:get_player_name())
			return true
		end
		if not _self:get_action() then
			if _self.touching_ground then
				if not can_takeoff(_self, pos) then
					draconis.detach_player(_self, player)
					return true
				end
				draconis.action_takeoff(_self)
			else
				local pos2 = _self:get_wander_pos_3d(4, 8)
				local dist2floor, floor_node = creatura.sensor_floor(_self, 10, true)
				if creatura.get_node_def(floor_node).drawtype == "liquid" then
					pos2.y = pos2.y + 6
				end
				if not center
				and dist2floor > 9 then
					center = pos2
				end
				if center
				and vec_dist(pos2, center) > 28 then
					pos2 = center
				end
				draconis.action_fly(_self, pos2, 3, "draconis:fly_obstacle_avoidance", 0.6)
				if pos.y - pos2.y > 1 then
					_self:animate("dive")
				else
					_self:animate("fly")
				end
			end
		end
	end
	self:set_utility(func)
end)

-- Attack

creatura.register_utility("draconis:attack", function(self, target)
	local is_landed = true
	local takeoff_init = false
	local land_init = false
	local hidden_timer = 0
	local fov_timer = 0
	local switch_timer = 20
	local function func(_self)
		local target_alive, los, tgt_pos = _self:get_target(target)
		if not target_alive then _self._target = nil return true end
		local pos = _self.object:get_pos()
		local yaw = _self.object:get_yaw()
		if not pos then return end
		local yaw2tgt = dir2yaw(vec_dir(pos, tgt_pos))
		if abs(diff(yaw, yaw2tgt)) > 0.3 then
			fov_timer = fov_timer + _self.dtime
		end
		switch_timer = switch_timer - _self.dtime
		if not self:get_action() then
			-- Decide to attack from ground or air
			if init then
				local dist2floor = creatura.sensor_floor(_self, 7, true)
				if dist2floor > 6
				or is_target_flying(target) then -- Fly if too far from ground
					is_landed = false
				end
			elseif switch_timer <= 0 then
				local switch_chance = (is_landed and 6) or 3
				is_landed = random(switch_chance) > 1
				takeoff_init = not is_landed
				land_init = is_landed
				switch_timer = 20
			end
			local current_anim = self._anim or ""
			-- Land if flying while in landed state
			if land_init then
				if not self.touching_ground then
					pos2 = tgt_pos
					if is_target_flying(target) then
						pos2 = {x = pos.x, y = pos.y - 7, z = pos.z}
					end
					creatura.action_move(_self, pos2, 3, "draconis:fly_obstacle_avoidance", 1, "fly")
				else
					draconis.action_land(self)
					land_init = false
				end
				return
			end
			-- Takeoff if walking while in flying state
			if takeoff_init
			and self.touching_ground then
				draconis.action_takeoff(self)
				takeoff_init = false
				return
			end
			-- Choose Attack
			local dist = vec_dist(pos, tgt_pos)
			local attack_range = (is_landed and 8) or 16
			if dist <= attack_range then -- Close-range Attacks
				if is_landed then
					if fov_timer < 1 then
						draconis.action_repel(_self, target)
					else
						draconis.action_slam(_self, target)
						is_landed = false
						fov_timer = 0
					end
				else
					if random(3) < 2 then
						draconis.action_flight_fire(_self, target, 12)
					else
						draconis.action_hover_fire(_self, target, 3)
					end
				end
			else
				if is_landed then
					draconis.action_pursue(_self, target, 2, "creatura:obstacle_avoidance", 0.5, "walk_slow")
				else
					tgt_pos.y = tgt_pos.y + 14
					creatura.action_move(_self, tgt_pos, 5, "draconis:fly_obstacle_avoidance", 1, "fly")
				end
			end
		end
	end
	self:set_utility(func)
end)

--[[creatura.register_utility("draconis:attack", function(self, target)
	local do_fly = false
	local hidden_timer = 0
	local fov_timer = 0
	local function func(_self)
		local target_alive, line_of_sight, tgt_pos = _self:get_target(target)
		if not target_alive then
			_self._target = nil
			return true
		end
		-- If the target can't be seen for too long, ignore it and any group members
		if not line_of_sight then
			hidden_timer = hidden_timer + _self.dtime
			if hidden_timer > 15 then
				_self._ignore_obj[target] = true
				local group = get_target_group(target)
				if #group > 0 then
					for _, v in pairs(group) do
						_self._ignore_obj[v] = true
					end
				end
				_self._target = nil
				return true
			end
			_self.head_tracking = nil
		else
			hidden_timer = 0
			_self.head_tracking = target
		end
		local pos = _self.object:get_pos()
		local yaw = _self.object:get_yaw()
		local yaw2tgt = dir2yaw(vec_dir(pos, tgt_pos))
		if abs(diff(yaw, yaw2tgt)) > 0.3 then
			fov_timer = fov_timer + _self.dtime
		end
		-- Perform Actions
		if not _self:get_action() then
			_self.alert_timer = _self:memorize("alert_timer", 15)
			local dist = vec_dist(pos, tgt_pos)
			if do_fly then
				do_fly = false
				_self:initiate_utility("draconis:hover_attack", _self, target)
				_self:set_utility_score(1)
			end
			if dist > 24 then
				local dist2floor = creatura.sensor_floor(_self, 6, true)
				if dist < 64
				and dist2floor > 5 then
					draconis.action_pursue(_self, target, 6, "creatura:pathfind", 1, "walk")
				else
					_self:initiate_utility("draconis:flight_attack", _self, target)
					_self:set_utility_score(1)
				end
			else
				if dist < 6 * _self.growth_scale then
					if fov_timer < 1 then
						draconis.action_repel(_self, target)
					else
						draconis.action_slam(_self, target)
						do_fly = true
						fov_timer = 0
					end
				elseif dist < 12 * _self.growth_scale then
					if fov_timer > 2
					or random(3) < 2 then
						draconis.action_slam(_self, target)
						do_fly = true
					else
						draconis.action_pursue(_self, target, 3, "creatura:obstacle_avoidance", 0.5, "walk_slow")
					end
				else
					local do_fire = random(3) < 2 and line_of_sight
					if do_fire then
						draconis.action_idle_fire(_self, target, 2)
					else
						draconis.action_pursue(_self, target, 2, "creatura:obstacle_avoidance", 0.7, "walk_slow")
					end
				end
			end
		end
	end
	self:set_utility(func)
end)]]

creatura.register_utility("draconis:wyvern_attack", function(self, target)
	local hidden_timer = 10
	local attack_init = false
	local function func(_self)
		local yaw = _self.object:get_yaw()
		local pos = _self.object:get_pos()
		if not pos then return end
		local target_alive, line_of_sight, tgt_pos = _self:get_target(target)
		if not target_alive then
			_self._target = nil
			return true
		end
		if not line_of_sight then
			hidden_timer = hidden_timer + _self.dtime
			if hidden_timer > 10 then
				_self._ignore_obj[target] = true
				local group = get_target_group(target)
				if #group > 0 then
					for _, v in pairs(group) do
						_self._ignore_obj[v] = true
					end
				end
				_self._target = nil
				return true
			end
			_self.head_tracking = nil
		else
			hidden_timer = 0
			_self.head_tracking = target
		end
		if not _self:get_action() then
			if attack_init then return true end
			local dist = vec_dist(pos, tgt_pos)
			if dist < 4 then
				local yaw2tgt = dir2yaw(vec_dir(pos, tgt_pos))
				self:turn_to(yaw2tgt)
				if abs(diff(yaw, yaw2tgt)) < 0.2 then
					draconis.action_punch(_self, target)
					attack_init = true
					_self.attack_cooldown[target] = 5
				end
			else
				draconis.action_pursue(_self, target, 3, "creatura:obstacle_avoidance", 1, "walk")
			end
		end
	end
	self:set_utility(func)
end)

-- Tamed Behavior --

creatura.register_utility("draconis:stay", function(self)
	local function func(_self)
		local order = _self.order
		if not order
		or order ~= "stay" then
			return true
		end
		if not _self:get_action() then
			creatura.action_idle(_self, 2, "stand")
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("draconis:follow_player", function(self, player)
	local function func(_self)
		local order = _self.order
		if not order
		or order ~= "follow" then
			return true
		end
		if not player then
			return true
		end
		local scale = _self.growth_scale or 1
		local pos = _self.object:get_pos()
		if not pos then return end
		local tgt_pos = player:get_pos()
		if not tgt_pos then _self.order = "stay" return true end
		local dist = vec_dist(pos, tgt_pos)
		local dist_to_ground = creatura.sensor_floor(_self, 8, true)
		if not _self:get_action() then
			if dist < clamp(8 * scale, 2, 12) then
				if dist_to_ground > 2 then
					draconis.action_hover(_self, 2, "hover")
				else
					creatura.action_idle(_self, 2, "stand")
				end
			else
				local height_diff = tgt_pos.y - pos.y
				if height_diff > 8
				or dist_to_ground > 2 then
					creatura.action_move(_self, tgt_pos, 2, "draconis:fly_obstacle_avoidance", 1, "fly")
				else
					creatura.action_move(_self, tgt_pos, 3, "creatura:pathfind", 0.5, "walk")
				end
			end
		end
	end
	self:set_utility(func)
end)

-- Utility Stack --

draconis.dragon_behavior = {
	{ -- Wander
		utility = "draconis:wander",
		get_score = function(self)
			return 0.1, {self}
		end
	},
	{ -- Wander (Flight)
		utility = "draconis:aerial_wander",
		get_score = function(self)
			local pos = self.object:get_pos()
			if not pos then return end
			local flight_allowed = not self.owner or self.flight_allowed
			if not flight_allowed then return 0 end
			if flight_allowed
			or self.in_liquid then
				self.flight_stamina = self:memorize("flight_stamina", self.flight_stamina + 200)
				self.is_landed = self:memorize("is_landed", false)
				return 1, {self, 0.7}
			end
			if not owner
			and self.nest_pos
			and vec_dist(pos, self.nest_pos) > 128 then
				self.flight_stamina = self:memorize("flight_stamina", self.flight_stamina + 200)
				self.is_landed = self:memorize("is_landed", false)
				return 0.8, {self, 0.7}
			end
			if not self.is_landed then
				return 0.2, {self, 0.5}
			end
			return 0
		end
	},
	{ -- Attack
		utility = "draconis:attack",
		get_score = function(self)
			local pos = self.object:get_pos()
			if not pos then return end
			local stance = (self.owner and self.stance) or "aggressive"
			local skip = self.age < 20 or stance == "passive"
			if skip then return 0 end -- Young/Passive Dragons don't attack
			local target = self._target
			if not target then
				if stance ~= "aggressive" then return 0 end -- Neutral Dragons with no set target
				local target_list = draconis[self.name:split(":")[2] .. "_targets"]
				target = find_target(self, target_list)
				if not target or not target:get_pos() then return 0 end
				local is_far = self.nest_pos and vec_dist(target:get_pos(), self.nest_pos) > 192
				if is_far
				or self._ignore_obj[target]
				or shared_owner(self, target) then
					self._target = nil
					return 0
				end
			end
			local scale = self.growth_scale
			local dist2floor = creatura.sensor_floor(self, 3, true)
			if not self.owner
			and dist2floor < 3
			and target:get_pos()
			and vec_dist(pos, target:get_pos()) > 48 * scale
			and self.alert_timer <= 0 then
				-- Wild Dragons sleep until approached
				self._target = nil
				return 0
			end
			local name = target:is_player() and target:get_player_name()
			if name then
				local inv = minetest.get_inventory({type = "player", name = name})
				if draconis.contains_libri(inv) then
					draconis.add_page(inv, "dragons")
				end
			end
			self._target = target
			return 0.9, {self, target}
		end
	},
	{ -- Sleep
		utility = "draconis:sleep",
		get_score = function(self)
			if self.alert_timer > 0 then return 0 end
			if (self.touching_ground
			and not self._target
			and not self.owner)
			or (self.owner
			and is_night) then
				return 0.7, {self}
			end
			return 0
		end
	},
	{ -- Stay (Order)
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
	{ -- Follow (Order)
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
	{ -- Mounted
		utility = "draconis:mount",
		get_score = function(self)
			if not self.owner
			or not self.rider
			or not self.rider:get_look_horizontal() then return 0 end
			return 1, {self}
		end
	},
	{ -- Fly to Land
		utility = "draconis:fly_to_land",
		get_score = function(self)
			local dist2floor = creatura.sensor_floor(self, 4, true)
			if dist2floor < 4 then return 0 end
			local util = self:get_utility() or ""
			if self.in_liquid
			or util == "draconis:hover_attack"
			or util == "draconis:follow_player" then return 0 end
			local is_landed = self.is_landed or self.flight_stamina < 15
			local is_grounded = (self.owner and not self.fly_allowed) or self.order == "stay"
			local is_sleepy = not util:match("attack") and (not self.owner or is_night)

			local current_anim = self._anim
			local is_flying = current_anim and current_anim:find("fly")
			if is_landed
			or is_grounded
			or is_sleepy
			or self._target then
				if util == "draconis:wander_flight"
				or util == "draconis:mount"
				or (dist2floor > 2
				and is_flying
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

draconis.wyvern_behavior = {
	{ -- Wander
		utility = "draconis:wander",
		step_delay = 0.3,
		get_score = function(self)
			return 0.1, {self}
		end
	},
	{ -- Wander (Flight)
		utility = "draconis:aerial_wander",
		--step_delay = 0.3,
		get_score = function(self)
			if self.in_liquid
			and (not self.owner
			or self.flight_allowed) then
				self.flight_stamina = self:memorize("flight_stamina", self.flight_stamina + 200)
				self.is_landed = self:memorize("is_landed", false)
				return 0.9, {self, 0.5}
			end
			if not self.is_landed
			and (not self.owner
			or self.flight_allowed) then
				return 0.2, {self, 0.3}
			end
			return 0
		end
	},
	{ -- Attack
		utility = "draconis:wyvern_attack",
		get_score = function(self)
			local pos = self.object:get_pos()
			if not pos then return end
			local stance = (self.owner and self.stance) or "aggressive"
			if stance == "passive" then return 0 end
			local target = self._target
			if not target then
				target = find_target(self, draconis.wyvern_targets)
				if not target or not target:get_pos() then return 0 end
				if shared_owner(self, target) then
					self._target = nil
					return 0
				end
			elseif stance == "neutral" then
				stance = "aggressive"
			end
			if stance ~= "aggressive" then
				self._target = nil
				return 0
			end
			local name = target:is_player() and target:get_player_name()
			if name then
				local inv = minetest.get_inventory({type = "player", name = target:get_player_name()})
				if draconis.contains_libri(inv) then
					draconis.add_page(inv, "wyverns")
				end
			end
			self._target = target
			return 0.9, {self, target}
		end
	},
	{ -- Taming
		utility = "draconis:wyvern_breaking",
		get_score = function(self)
			if self.rider
			and not self.owner then
				return 0.8, {self, self.rider}
			end
			return 0
		end
	},
	{ -- Stay (Order)
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
	{ -- Follow (Order)
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
	{ -- Mounted
		utility = "draconis:wyvern_mount",
		get_score = function(self)
			if self.rider
			and self.owner then
				return 1, {self}
			end
			return 0
		end
	},
	{ -- Fly to Land
		utility = "draconis:fly_to_land",
		get_score = function(self)
			local dist2floor = creatura.sensor_floor(self, 12, true)
			local is_landed = self.is_landed or self.flight_stamina < 15
			local is_grounded = (self.owner and not self.fly_allowed) or self.order == "stay"
			local attacking_tgt = self._target and creatura.is_alive(self._target)
			if is_landed
			or is_grounded
			or attacking_tgt then
				local util = self:get_utility() or ""
				if ((util == "draconis:wander_flight"
				or util == "draconis:wyvern_mount")
				or (dist2floor > 2
				and not self.touching_ground))
				and util ~= "draconis:wyvern_breaking" then
					local score = 0.3
					if self.flight_stamina < 15
					or (self.owner
					and not self.rider
					and not self.fly_allowed)
					or self._target then
						score = 1
					end
					return score, {self}
				end
			end
			return 0
		end
	}
}
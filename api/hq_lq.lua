---------------------
-- HQ/LQ Functions --
---------------------
------ Ver 1.0 ------

local abs = math.abs
local pi = math.pi
local min = math.min

----------------------
-- Helper Functions --
----------------------

local function diff(a, b)
	return math.abs(a-b)
end

local function dist_2d(pos1, pos2)
    pos1.y = 0
    pos2.y = 0
    return vector.distance(pos1, pos2)
end

local function set_lift(self, val)
    local vel = self.object:get_velocity()
    vel.y = val
    self.object:set_velocity(vel)
end

local function hitbox(ent)
    if not ent then return nil end
    if type(ent) == 'userdata' then
		ent = ent:get_luaentity()
	end
    return ent.object:get_properties().collisionbox
end

local function find_collision(self)
    local pos = mobkit.get_stand_pos(self)
    local radius = hitbox(self)[4]*3
    local pos1 = vector.new(pos.x + radius, pos.y + self.height, pos.z + radius)
    local pos2 = vector.new(pos.x - radius, pos.y, pos.z - radius)
    local collision = nil
    for x = pos1.x, pos2.x do
		for y = pos1.y, pos2.y do
			for z = pos1.z, pos2.z do
                local npos = vector.new(x, y, z)
                local yaw = self.object:get_yaw()
                local yaw_to_node = minetest.dir_to_yaw(vector.direction(pos, npos))
				if minetest.get_node(npos).walkable
				and abs(yaw - yaw_to_node) <= 1.5 then
                    collision = npos
                    break
				end
			end
		end
	end
    return collision
end

--------------
-- Movement --
--------------

function draconis.lq_dumbwalk(self, dest, speed_factor)
	local timer = 3			-- failsafe
    speed_factor = speed_factor or 1
    local init = true
    local func = function(self)
        if init then
            mobkit.animate(self, "stand")
        end
		timer = timer - self.dtime
		if timer < 0 then return true end

		local pos = mobkit.get_stand_pos(self)
		local y = self.object:get_velocity().y

		if mobkit.is_there_yet2d(pos,minetest.yaw_to_dir(self.object:get_yaw()),dest) then
--		if mobkit.isnear2d(pos,dest,0.25) then
			if not self.isonground or abs(dest.y-pos.y) > 0.1 then		-- prevent uncontrolled fall when velocity too high
--			if abs(dest.y-pos.y) > 0.1 then	-- isonground too slow for speeds > 4
				self.object:set_velocity({x=0,y=y,z=0})
			end
			return true
		end

        if self.isonground then
            mobkit.animate(self, "walk")
			local dir = vector.normalize(vector.direction({x=pos.x,y=0,z=pos.z},
														{x=dest.x,y=0,z=dest.z}))
			dir = vector.multiply(dir,self.max_speed*speed_factor)
			mobkit.turn2yaw(self,minetest.dir_to_yaw(dir))
			dir.y = y
			self.object:set_velocity(dir)
		end
	end
	mobkit.queue_low(self,func)
end

function draconis.goto_next_waypoint(self, tpos)
    local pos2 = tpos
    draconis.find_path(self, tpos)
    if self.path_data and #self.path_data > 2 then
        pos2 = self.path_data[3]
    end
    if draconis.is_stuck(self) then
        mobkit.animate(self, "stand")
    end
    if pos2 then
		local yaw = self.object:get_yaw()
        local tyaw = minetest.dir_to_yaw(vector.direction(self.object:get_pos(),pos2))
        if abs(tyaw-yaw) > 0.1 then
            mobkit.turn2yaw(self, tyaw)
        end
        draconis.lq_dumbwalk(self, pos2, 1)
		return true
    end
end

-----------
-- Logic --
-----------

function draconis.logic_attack_mob(self, prty, target)
    if target
    and target:get_pos()
    and vector.distance(self.object:get_pos(), target:get_pos()) < self.view_range
    and mobkit.is_alive(target) then
        if not mob_core.shared_owner(self, target) or not self.tamed then
            if self.isonground then
                draconis.hq_attack_target(self, prty, target)
            else
                draconis.hq_aerial_attack_target(self, prty, target)
            end
            return
        end
    end
end

function draconis.logic_attack_nearby_mobs(self, prty)
    for i = 1, #self.targets do
        local target = mobkit.get_closest_entity(self, self.targets[i])
        if target
        and target:get_pos()
        and vector.distance(self.object:get_pos(), target:get_pos()) < self.view_range
        and mobkit.is_alive(target) then
            if not mob_core.shared_owner(self, target) or not self.tamed then
                if self.isonground then
                    draconis.hq_attack_target(self, prty, target)
                else
                    draconis.hq_aerial_attack_target(self, prty, target)
                end
            end
        end
    end
end

function draconis.logic_attack_nearby_player(self, prty, player)
    if player
    and player:get_pos()
    and vector.distance(self.object:get_pos(), player:get_pos()) < self.view_range
    and mobkit.is_alive(player) then
        if (self.tamed == true and player:get_player_name() ~= self.owner) or
        not self.tamed then
            if self.isonground then
                draconis.hq_attack_target(self, prty, player)
            else
                draconis.hq_aerial_attack_target(self, prty, player)
            end
        end
    end
end

------------------
-- LQ Functions --
------------------

function draconis.lq_breath_attack(self, target, min_range, max_range, anim)
    anim = anim or "stand_fire"
    local func = function(self)
        if not mobkit.is_alive(target) then
            mobkit.clear_queue_high(self)
            return true
        end
        local pos = mobkit.get_stand_pos(self)
        local tpos = mobkit.get_stand_pos(target)
        local dist = vector.distance(pos, tpos)
        if dist > max_range or dist < min_range then return true end
        if self._anim ~= anim then
            mobkit.animate(self, anim)
        end
        if self.name == "draconis:fire_dragon" then
            draconis.fire_breath(self, tpos, self.view_range)
        end
        if self.name == "draconis:ice_dragon" then
            draconis.ice_breath(self, tpos, self.view_range)
        end
    end
    mobkit.queue_low(self, func)
end

function draconis.lq_dumb_punch(self, target)
    local func = function(self)
		local vel = self.object:get_velocity()
		local pos = self.object:get_pos()
		local yaw = self.object:get_yaw()
		local tpos = target:get_pos()
		local tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos))
		if abs(tyaw-yaw) > 0.1 then
			mobkit.turn2yaw(self, tyaw)
		elseif dist_2d(pos, tpos) < hitbox(self)[4]*6
        and self.punch_timer <= 0 then
			mobkit.animate(self, "punch")
			target:punch(self.object, 1.0, {
				full_punch_interval = 0.1,
				damage_groups = {fleshy = self.damage}
			}, nil)
			mob_core.punch_timer(self, self.punch_cooldown)
			return true
		end
	end
	mobkit.queue_low(self, func)
end

------------------
-- HQ Functions --
------------------

function draconis.hq_eat_items(self, prty)
    local func = function(self)
        local pos = self.object:get_pos()
        local objs = minetest.get_objects_inside_radius(pos, self.view_range)
        if #objs < 1 then return true end
        for _, obj in ipairs(objs) do
            local ent = obj:get_luaentity()
            if mobkit.is_queue_empty_low(self) then
                for i = 1, #self.follow do
                    if ent and ent.name == "__builtin:item" and
                        ent.itemstring:match(self.follow[i]) then
                        local food = obj:get_pos()
                        if vector.distance(pos, food) > hitbox(self)[4] + 2 then
                            draconis.goto_next_waypoint(self, food)
                        else
                            mobkit.lq_turn2pos(self, food)
                            mobkit.lq_idle(self, 1, "punch")
                            local stack = ItemStack(ent.itemstring)
                            local max_count = stack:get_stack_max()
                            local count = min(stack:get_count(), max_count)
                            self.hunger =
                                mobkit.remember(self, "hunger",
                                                self.hunger + count)
                            obj:punch(self.object, 1.0, {
                                full_punch_interval = 0.1,
                                damage_groups = {}
                            }, nil)
                            return true
                        end
                    else
                        return true
                    end
                end
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

function draconis.hq_attack_target(self, prty, target)
    local func = function(self)
        if not mobkit.is_alive(target) then
            mobkit.clear_queue_high(self)
            return true
        end
        mob_core.punch_timer(self)
        local pos = mobkit.get_stand_pos(self)
        local tpos = mobkit.get_stand_pos(target)
        local dist = vector.distance(pos, tpos)
        local yaw = self.object:get_yaw()
        local tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos))

        if tpos.y - pos.y > 12
        or self.stuck_timer > 1.5 then
            draconis.hq_aerial_attack_target(self, prty + 1, target)
        end

        if abs(tyaw - yaw) > 0.1 then
            mobkit.turn2yaw(self, tyaw)
        end

        if dist > 16 then
            if not self.breath_meter_bottomed then
                draconis.lq_breath_attack(self, target, 12, self.view_range)
            else
                if not mobkit.is_queue_empty_low(self) then
                    mobkit.clear_queue_low(self)
                end
                draconis.goto_next_waypoint(self, tpos)
            end
        else
            if not mobkit.is_queue_empty_low(self)
            and dist_2d(pos, tpos) > hitbox(self)[4]*6 then
                mobkit.clear_queue_low(self)
            end
            draconis.goto_next_waypoint(self, tpos)
            if dist_2d(pos, tpos) < hitbox(self)[4]*6 then
                draconis.lq_dumb_punch(self, target)
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

function draconis.hq_aerial_attack_target(self, prty, target)
    local tyaw = 0
	local lift = 0
    local init = true
    local func = function(self)
        if not mobkit.is_alive(target) then
            mobkit.clear_queue_high(self)
            return true
        end
        mob_core.punch_timer(self)
        if init then
            mobkit.animate(self,"fly")
            init = false
        end
        local pos = mobkit.get_stand_pos(self)
        local tpos = target:get_pos()
        local dist = vector.distance(pos, tpos)
        local yaw = self.object:get_yaw()

        local right = vector.add(pos, vector.multiply(minetest.yaw_to_dir(yaw-1), 6))
        local left = vector.add(pos, vector.multiply(minetest.yaw_to_dir(yaw+1), 6))
        -- Collision
		local collision = find_collision(self)
        --  Height Control
        local hdiff = abs(tpos.y - pos.y)

        if tpos.y > pos.y
        and hdiff > self.height then
			if lift < 1 then
				lift = lift + 0.2
			end
        end
        if tpos.y < pos.y
        and hdiff > self.height then
			if lift > -1 then
				lift = lift - 0.2
			end
        end
        if hdiff < self.height then
			if lift > 0 then
				lift = lift - 0.2
            end
            if lift < 0 then
				lift = lift + 0.2
			end
        end

        if dist < 12 then
            tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos)) - (pi/2)
        end

		if collision then
            local left_dist = vector.distance(collision, left)
			local right_dist = vector.distance(collision, right)
			if collision.y > pos.y - self.height then
				if lift > -1 then
					lift = lift - 0.2
				end
			end
			if min(diff(left_dist, right_dist)) <= 3 then
				tyaw = minetest.dir_to_yaw(vector.direction(pos, collision)) - pi/2
			end
			if left_dist > right_dist then
                tyaw = minetest.dir_to_yaw(vector.direction(pos, left))
            elseif right_dist > left_dist then
                tyaw = minetest.dir_to_yaw(vector.direction(pos, right))
            end
        else
            tyaw = minetest.dir_to_yaw(vector.direction(pos, tpos))
        end

        -- Set Velocity
        set_lift(self, lift)

        if lift < 0 then
			self.object:set_acceleration({x=0,y=0.1,z=0})
		else
			self.object:set_acceleration({x=0,y=0,z=0})
        end

        mobkit.turn2yaw(self, tyaw, 3)

        if dist > 16 then
            if not self.breath_meter_bottomed then
                self.isonground = false
                self.object:set_velocity({x=0,y=0,z=0})
                draconis.lq_breath_attack(self, target, 14, self.view_range, "fly_idle_fire")
            else
                if not mobkit.is_queue_empty_low(self) then
                    mobkit.clear_queue_low(self)
                end
                if not init then init = true end
                mobkit.go_forward_horizontal(self, self.max_speed)
            end
        else
            if not mobkit.is_queue_empty_low(self)
            and dist_2d(pos, tpos) > hitbox(self)[4]*6 then
                if not init then init = true end
                    mobkit.clear_queue_low(self)
                end
            mobkit.go_forward_horizontal(self, self.max_speed)
            if dist_2d(pos, tpos) < hitbox(self)[4]*6 then
                draconis.lq_dumb_punch(self, target)
            end
        end
	end
	mobkit.queue_high(self, func, prty)
end

------------
-- Follow --
------------

function draconis.hq_follow(self, prty, target)
    local center = self.object:get_pos()
    local timer = 5
    local func = function(self)
        if not mobkit.is_alive(target) then
            return true
        end
        if mobkit.is_queue_empty_low(self) and not self.isinliquid then
            local pos = mobkit.get_stand_pos(self)
            local opos = target:get_pos()
            if target:is_player() then opos.y = opos.y + 1 end
            if vector.distance(pos, opos) > 12 then
                timer = timer - self.dtime
            end
            if timer <= 0
            and vector.distance(pos, center) < 12 then
                self.object:add_velocity({x = 0, y = 2, z = 0})
            end
            if self.isonground then
                if opos.y - pos.y > 4 then
                    self.object:add_velocity({x = 0, y = 2, z = 0})
                end
                if vector.distance(pos, opos) > 3*self.growth_stage then
                    draconis.goto_next_waypoint(self, opos)
                else
                    mobkit.lq_idle(self, 1)
                end
            end
            if not self.isonground
            or self.stuck_timer > 1.5 then
                mob_core.fly_to_next_waypoint(self, opos)
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

-----------
-- Sleep --
-----------

function draconis.get_time()
    local time
    local timeofday = minetest.get_timeofday()
	if not timeofday then return nil end
	timeofday = timeofday  * 24000
    if timeofday < 4500 or timeofday > 19500 then
		time = "night"
	else
		time = "day"
    end
    return time
end

function draconis.lq_go_to_sleep(self)
    local transition_timer = 0.75
    local func = function(self)
        local time = draconis.get_time()
        if time ~= "night"
        or self.cavern_spawn then return end
        if self._anim ~= "sleep" then
            transition_timer = transition_timer - self.dtime
            mobkit.animate(self, "goto_sleep")
        end
        if transition_timer <= 0 then
            mobkit.animate(self, "sleep")
            self.status = mobkit.remember(self, "status", "sleeping")
            mobkit.clear_queue_low(self)
            return true
        end
    end
    mobkit.queue_low(self,func)
end

function draconis.lq_wakeup(self)
    local transition_timer = 0.5
    local func = function(self)
        if self._anim == "sleep" then
            mobkit.animate(self, "wakeup")
        end
        transition_timer = transition_timer - self.dtime
        if transition_timer <= 0 then
            mobkit.animate(self, "stand")
            self.status = mobkit.remember(self, "status", "")
            mobkit.clear_queue_high(self)
            mobkit.clear_queue_low(self)
            return true
        end
    end
    mobkit.queue_low(self,func)
end

function draconis.hq_sleep(self, prty)
    local func = function(self)
        local time = draconis.get_time()
        if self.cavern_spawn then
            mobkit.animate(self, "sleep")
            self.status = mobkit.remember(self, "status", "sleeping")
            return true
        end
        if self.status ~= "sleeping"
        and time ~= "night" then
            self.sleep_timer = mobkit.remember(self, "sleep_timer", 10)
            return true
        end
        if self.status ~= "sleeping"
        and time == "night" then
            draconis.lq_go_to_sleep(self)
        end
        if self.status == "sleeping"
        and time == "night" then
            mobkit.animate(self, "sleep")
        end
        if self.status == "sleeping"
        and time ~= "night" then
            draconis.lq_wakeup(self)
        end
    end
    mobkit.queue_high(self, func, prty)
end
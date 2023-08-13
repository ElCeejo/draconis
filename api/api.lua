---------
-- API --
---------

-- Math --

local pi = math.pi
local pi2 = pi * 2
local abs = math.abs
local deg = math.deg
local min = math.min
local random = math.random
local ceil = math.ceil
local floor = math.floor
local atan2 = math.atan2
local sin = math.sin
local sqrt = math.sqrt
local cos = math.cos
local rad = math.rad
local function diff(a, b) -- Get difference between 2 angles
	return atan2(sin(b - a), cos(b - a))
end
local function interp_angle(a, b, w)
	local cs = (1 - w) * cos(a) + w * cos(b)
	local sn = (1 - w) * sin(a) + w * sin(b)
	return atan2(sn, cs)
end

local function clamp(val, _min, _max)
	if val < _min then
		val = _min
	elseif _max < val then
		val = _max
	end
	return val
end

-- Vector Math --

local vec_dir = vector.direction
local vec_dist = vector.distance
local vec_sub = vector.subtract
local vec_add = vector.add
local vec_multi = vector.multiply
local vec_new = vector.new
local vec_normal = vector.normalize
local vec_round = vector.round

local dir2yaw = minetest.dir_to_yaw
local yaw2dir = minetest.yaw_to_dir

--------------
-- Settings --
--------------

local terrain_destruction = minetest.settings:get_bool("dragon_terrain_destruction", true)

---------------------
-- Local Utilities --
---------------------

local function activate_nametag(self)
	self.nametag = self:recall("nametag") or nil
	if not self.nametag then return end
	self.object:set_properties({
		nametag = self.nametag,
		nametag_color = "#FFFFFF"
	})
end

local function is_value_in_table(tbl, val)
	for _, v in pairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

local function correct_name(str)
	if str then
		if str:match(":") then str = str:split(":")[2] end
		return (string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("_", " "))
	end
end

local function get_pointed_mob(a, b)
	local steps = ceil(vec_dist(a, b))

	for i = 1, steps do
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
		if creatura.get_node_def(pos).walkable then
			break
		end
		local objects = minetest.get_objects_in_area(vec_sub(pos, 6), vec_add(pos, 6))
		for _, object in pairs(objects) do
			if object
			and object:get_luaentity() then
				local ent = object:get_luaentity()
				if ent.name:match("^draconis:") then
					return object, ent
				end
			end
		end
	end
end

------------------
-- Local Tables --
------------------

local walkable_nodes = {}

local scorched_conversions = {}
local frozen_conversions = {}

local flame_node

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_nodes) do
		if name ~= "air" and name ~= "ignore" then
			if def.walkable then
				table.insert(walkable_nodes, name)
				if minetest.get_item_group(name, "stone") > 0 then
					scorched_conversions[name] = "draconis:stone_scorched" -- Scorched Stone
					frozen_conversions[name] = "draconis:stone_frozen" -- Frozen Stone
				elseif minetest.get_item_group(name, "soil") > 0 then
					scorched_conversions[name] = "draconis:soil_scorched" -- Scorched Soil
					frozen_conversions[name] = "draconis:soil_frozen" -- Frozen Soil
				elseif minetest.get_item_group(name, "tree") > 0 then
					scorched_conversions[name] = "draconis:log_scorched" -- Scorched Log
					frozen_conversions[name] = "draconis:log_frozen" -- Frozen Log
				elseif minetest.get_item_group(name, "flora") > 0
				or minetest.get_item_group(name, "leaves") > 0
				or minetest.get_item_group(name, "snowy") > 0 then
					scorched_conversions[name] = "air"
				end
			elseif def.drawtype == "liquid"
			and minetest.get_item_group(name, "water") > 0 then
				frozen_conversions[name] = draconis.global_nodes["ice"]
			end
		end
	end
end)

minetest.after(0.1, function()
	flame_node = draconis.global_nodes["flame"]
end)

local fire_eye_textures = {
	"green",
	"orange",
	"red"
}

local ice_eye_textures = {
	"blue",
	"purple"
}


----------------------
-- Global Utilities --
----------------------

function draconis.spawn_dragon(pos, mob, mapgen, age)
	if not pos then return false end
	local dragon = minetest.add_entity(pos, mob)
	if dragon then
		local ent = dragon:get_luaentity()
		ent._mem = ent:memorize("_mem", true)
		ent.age = ent:memorize("age", age)
		ent.growth_scale = ent:memorize("growth_scale", age * 0.01)
		ent.mapgen_spawn = ent:memorize("mapgen_spawn", mapgen)
		if age <= 25 then
			ent.child = ent:memorize("child", true)
			ent.growth_stage = ent:memorize("growth_stage", 1)
		end
		if age <= 50 then
			ent.growth_stage = ent:memorize("growth_stage", 2)
		end
		if age <= 75 then
			ent.growth_stage = ent:memorize("growth_stage", 3)
		end
		if age > 75 then
			ent.growth_stage = ent:memorize("growth_stage", 4)
		end
		if random(3) < 2 then
			ent.gender = ent:memorize("gender", "male")
		else
			ent.gender = ent:memorize("gender", "female")
		end
		ent:set_scale(ent.growth_scale)
	end
end

function draconis.generate_id()
	local idst = ""
	for _ = 0, 5 do idst = idst .. (random(0, 9)) end
	if draconis.dragons[idst] then
		local fail_safe = 20
		while draconis.dragons[idst]
		and fail_safe > 0 do
			for _ = 0, 5 do idst = idst .. (random(0, 9)) end
			fail_safe = fail_safe - 1
		end
	end
	return idst
end

-------------------
-- Mob Functions --
-------------------

local function get_head_pos(self, pos2)
	local pos = self.object:get_pos()
	if not pos then return end
	local scale = self.growth_scale or 1
	pos.y = pos.y + 4.5 * scale
	local yaw = self.object:get_yaw()
	local dir = vec_dir(pos, pos2)
	local yaw_diff = diff(yaw, minetest.dir_to_yaw(dir))
	if yaw_diff > 1 then
		local look_dir = minetest.yaw_to_dir(yaw + 1)
		dir.x = look_dir.x
		dir.z = look_dir.z
	elseif yaw_diff < -1 then
		local look_dir = minetest.yaw_to_dir(yaw - 1)
		dir.x = look_dir.x
		dir.z = look_dir.z
	end
	local head_yaw = yaw + (yaw_diff * 0.33)
	return vec_add(pos, vec_multi(minetest.yaw_to_dir(head_yaw), (7 - abs(yaw_diff)) * scale)), dir
end

draconis.get_head_pos = get_head_pos

local wing_colors = {
	-- Fire
	black = {
		"#d20000", -- Red
		"#d92e00", -- Orange
		"#edad00" -- Yellow
	},
	bronze = {
		"#d20000", -- Red
		"#d92e00", -- Orange
		"#edad00", -- Yellow
		"#a724ff" -- Purple
	},
	gold = {
		"#d20000", -- Red
		"#d92e00", -- Orange
		"#edad00", -- Yellow
		"#a724ff" -- Purple
	},
	green = {
		"#d20000", -- Red
		"#d92e00", -- Orange
		"#edad00", -- Yellow
	},
	red = {
		"#edad00", -- Yellow
	},
	-- Ice
	light_blue = {
		"#07084f", -- Dark Blue
	},
	sapphire = {
		"#a724ff" -- Purple
	},
	slate = {
		"#a724ff" -- Purple
	},
	white = {
		"#07084f", -- Dark Blue
	},
	silver = {
		"#07084f", -- Dark Blue
	}
}

local function generate_texture(self, force)
	draconis.set_color_string(self)
	local def = minetest.registered_entities[self.name]
	local textures = {
		def.textures[self.texture_no]
	}
	self.wing_overlay = self:recall("wing_overlay") or nil
	if not self.wing_overlay then
		local color = wing_colors[self.color][random(#wing_colors[self.color])]
		self.wing_overlay = "(draconis_wing_fade.png^[multiply:" .. color .. ")"
		self:memorize("wing_overlay", self.wing_overlay)
	end
	if self:get_props().textures[1]:find("wing_fade") and not force then return end
	textures[1] = textures[1] .. "^" .. self.wing_overlay
	self:set_texture(1, textures)
end

draconis.generate_texture = generate_texture

function draconis.drop_items(self)
	if not creatura.is_valid(self)
	or not self.object:get_pos() then return end
	if not self.drop_queue then
		self.drop_queue = {}
		for i = 1, #self.drops do
			local drop_def = self.drops[i]
			local name = drop_def.name
			local min_amount = drop_def.min
			local max_amount = drop_def.max
			local chance = drop_def.chance
			local amount = random(min_amount, max_amount)
			if random(chance) < 2 then
				table.insert(self.drop_queue, {name = name, amount = amount})
			end
		end
		self:memorize("drop_queue", self.drop_queue)
	else
		local pos = self.object:get_pos()
		pos.y = pos.y + self.height * 0.5
		local minpos = {
			x = pos.x - 18 * self.growth_scale,
			y = pos.y,
			z = pos.z - 18 * self.growth_scale
		}
		local maxpos = {
			x = pos.x + 18 * self.growth_scale,
			y = pos.y,
			z = pos.z + 18 * self.growth_scale
		}
		minetest.add_particlespawner({
			amount = math.ceil(48 * self.growth_scale),
			time = 0.25,
			minpos = minpos,
			maxpos = maxpos,
			minacc = {x = 0, y = 2, z = 0},
			maxacc = {x = 0, y = 3, z = 0},
			minvel = {x = math.random(-1, 1), y = -0.25, z = math.random(-1, 1)},
			maxvel = {x = math.random(-2, 2), y = -0.25, z = math.random(-2, 2)},
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
		if #self.drop_queue > 0 then
			for i = #self.drop_queue, 1, -1 do
				local drop_def = self.drop_queue[i]
				if drop_def then
					local name = drop_def.name
					local amount = random(1, drop_def.amount)
					local item = minetest.add_item(pos, ItemStack(name .. " " .. amount))
					if item then
						item:add_velocity({
							x = random(-2, 2),
							y = 1.5,
							z = random(-2, 2)
						})
					end
					self.drop_queue[i].amount = drop_def.amount - amount
					if self.drop_queue[i].amount <= 0 then
						self.drop_queue[i] = nil
					end
				end
			end
			self:memorize("drop_queue", self.drop_queue)
		else
			return true
		end
	end
	return false
end

-------------
-- Visuals --
-------------

function draconis.set_color_string(self)
	if self.name == "draconis:fire_dragon" then
		if self.texture_no == 1 then
			self.color = "black"
		elseif self.texture_no == 2 then
			self.color = "bronze"
		elseif self.texture_no == 3 then
			self.color = "green"
		elseif self.texture_no == 4 then
			self.color = "red"
		else
			self.color = "gold"
		end
	elseif self.name == "draconis:ice_dragon" then
		if self.texture_no == 1 then
			self.color = "light_blue"
		elseif self.texture_no == 2 then
			self.color = "sapphire"
		elseif self.texture_no == 3 then
			self.color = "slate"
		elseif self.texture_no == 4 then
			self.color = "white"
		else
			self.color = "silver"
		end
	end
end

-----------------------
-- Dynamic Animation --
-----------------------

function draconis.rotate_to_pitch(self, flying)
	local rot = self.object:get_rotation()
	if flying then
		local vel = vec_normal(self.object:get_velocity())
		local step = min(self.dtime * 4, abs(diff(rot.x, vel.y)) % (pi2))
		local n_rot = interp_angle(rot.x, vel.y, step)
		self.object:set_rotation({
			x = clamp(n_rot, -0.75, 0.75),
			y = rot.y,
			z = rot.z
		})
	elseif rot.x ~= 0 then
		self.object:set_rotation({
			x = 0,
			y = rot.y,
			z = 0
		})
	end
end

function draconis.head_tracking(self)
	if self.rider then return end
	local yaw = self.object:get_yaw()
	local pos = self.object:get_pos()
	if not pos then return end
	local anim = self._anim or "stand"
	if anim == "sleep"
	or self.hp <= 0 then
		self:move_head(yaw)
		return
	end
	-- Calculate Head Position
	local y_dir = yaw2dir(yaw)
	local scale = self.growth_scale or 1
	local offset_h, offset_v = self.width + 3 * scale, self.height + 1.5 * scale
	if anim:match("^fly_idle") then
		offset_v = self.height + 2 * scale
	end
	pos = {
		x = pos.x + y_dir.x * offset_h,
		y = pos.y + offset_v,
		z = pos.z + y_dir.z * offset_h
	}
	local player = self.head_tracking
	local plyr_pos = player and player:get_pos()
	if plyr_pos then
		plyr_pos.y = plyr_pos.y + 1.4
		local dir = vec_dir(pos, plyr_pos)
		local dist = vec_dist(pos, plyr_pos)
		if dist > 24 * scale then self.head_tracking = nil return end
		local tyaw = dir2yaw(dir)
		self:move_head(tyaw, dir.y)
		return
	elseif self:timer(random(4, 6)) then
		local players = creatura.get_nearby_players(self, 12 * scale)
		self.head_tracking = #players > 0 and players[random(#players)]
	end
	self:move_head(yaw, 0)
end

------------
-- Breath --
------------

local effect_cooldown = {}

minetest.register_entity("draconis:dragon_ice", {
	max_hp = 40,
	physical = true,
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	visual = "mesh",
	mesh = "draconis_dragon_ice.obj",
	textures = {
		"draconis_dragon_ice.png^[opacity:170"
	},
	use_texture_alpha = true,
	active_time = 0,
	on_activate = function(self)
		self.object:set_armor_groups({immortal = 1, fleshy = 0})
		self.object:set_acceleration({x = 0, y = -9.8, z = 0})
	end,
	on_step = function(self, dtime)
		if self.active_time > 0
		and (not self.child
		or not self.child:get_pos()) then
			self.object:remove()
			return
		end
		self.active_time = self.active_time + dtime
		if self.active_time > 10 then
			if self.child then
				self.child:set_properties({
					visual_size = self.mob_scale,
				})
			end
			self.object:remove()
		end
	end
})

minetest.register_entity("draconis:dragon_fire", {
	max_hp = 40,
	physical = false,
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	visual = "mesh",
	mesh = "draconis_dragon_fire.obj",
	textures = {
		"draconis_fire_animated.png^[verticalframe:8:1"
	},
	glow = 12,
	active_time = 0,
	fire_time = 0.07,
	fire_frame = 1,
	on_activate = function(self)
		self.object:set_armor_groups({immortal = 1, fleshy = 0})
	end,
	on_step = function(self, dtime)
		if not self.child
		or not self.child:get_pos() then
			self.object:remove()
			return
		end
		local child_pos = self.child:get_pos()
		if creatura.get_node_def(child_pos).drawtype == "liquid" then
			self.object:remove()
			return
		end
		self.active_time = self.active_time + dtime
		self.fire_time = self.fire_time - dtime
		if self.fire_time < 0 then
			self.fire_time = 0.07
			self.fire_frame = self.fire_frame + 1
			if self.fire_frame > 6 then
				self.fire_frame = 1
			end
			self.object:set_properties({
				textures = {"draconis_fire_animated.png^[verticalframe:8:" .. self.fire_frame}
			})
		end
		if self.active_time - math.floor(self.active_time) < 0.1
		and (self.child:get_luaentity()
		or self.child:is_player()) then
			local ent = self.child:get_luaentity()
			if ((ent and ent.hp) or 0) > 0 then
				self.child:punch(self.object, 0, {fleshy=2})
			end
			if ent
			and ent._creatura_mob
			and ((ent and ent.hp) or 0) <= 0
			and ent.drops then
				if #ent.drops
				and #ent.drops > 0 then
					local n_drops = table.copy(ent.drops)
					for n = 1, #n_drops do
						local name = n_drops[n].name
						if minetest.get_item_group(name, "food_meat") > 0 then
							local output = minetest.get_craft_result({
								method = "cooking",
								width = 1,
								items = {name}
							})
							if output.item
							and output.item:get_name()
							and output.item:get_name() ~= "" then
								local cooked_name = output.item:get_name()
								n_drops[n].name = cooked_name
							end
						end
					end
					self.child:get_luaentity().drops = n_drops
				end
			end
		end
		if self.active_time > 10 then
			self.object:remove()
		end
	end
})

local function freeze_object(object)
	if not creatura.is_valid(object)
	or object:get_attach()
	or effect_cooldown[object] then return end
	local pos = object:get_pos()
	local box = object:get_properties().collisionbox
	local ice_obj = minetest.add_entity(pos, "draconis:dragon_ice")
	object:set_attach(ice_obj, nil, {z = 0, y = abs(box[2]), x = 0})
	ice_obj:set_armor_groups({immortal = 1})
	local obj_scale = object:get_properties().visual_size
	local ice_scale = (box[4] or 0.5) * 30
	ice_obj:get_luaentity().mob_scale = obj_scale
	ice_obj:get_luaentity().child = object
	ice_obj:set_properties({
		visual_size = {
			x = ice_scale,
			y = ice_scale
		}
	})
	local obj_yaw = object:get_yaw()
	if object:is_player() then
		obj_yaw = object:get_look_horizontal()
	end
	ice_obj:set_yaw(obj_yaw)
	object:set_properties({
		visual_size = {
			x = obj_scale.x / ice_scale,
			y = obj_scale.y / ice_scale
		},
	})
	effect_cooldown[object] = 40
end

draconis.freeze_object = freeze_object

local function burn_object(object)
	if not creatura.is_valid(object)
	or effect_cooldown[object] then return end
	local pos = object:get_pos()
	local box = object:get_properties().collisionbox
	local fire_obj = minetest.add_entity(pos, "draconis:dragon_fire")
	fire_obj:set_attach(object, nil, {z = 0, y = abs(box[2]), x = 0})
	fire_obj:set_armor_groups({immortal = 1})
	local obj_scale = object:get_properties().visual_size.x
	fire_obj:get_luaentity().child = object
	fire_obj:set_properties({
		visual_size = {
			x = (box[4] * 32) / obj_scale,
			y = (box[4] * 32) / obj_scale
		}
	})
	effect_cooldown[object] = 15
end

draconis.burn_object = burn_object

local function do_cooldown()
	for k, v in pairs(effect_cooldown) do
		if v > 1 then
			effect_cooldown[k] = v - 1
		else
			effect_cooldown[k] = nil
		end
	end
	minetest.after(1, do_cooldown)
end

do_cooldown()

local function damage_objects(self, pos, radius)
	local objects = minetest.get_objects_inside_radius(pos, radius)
	for _, object in ipairs(objects) do
		local ent = object and object:get_luaentity()
		local damage = object:is_player()
		if (self.rider and object == self.rider)
		or (self.passenger and object == self.passenger) then
			damage = false
		elseif ent then
			local is_mob = ent.logic ~= nil or ent._creatura_mob or ent._cmi_is_mob
			damage = is_mob and (ent.hp or ent.health or 0) > 0
		end
		if damage then
			object:punch(self.object, 1.0, {damage_groups = {fleshy = math.ceil(self.damage * 0.33)}})
			--self:punch_target(object, math.ceil(self.damage * 0.2))
			if self.name == "draconis:ice_dragon" then
				freeze_object(object)
			end
			if self.name == "draconis:fire_dragon" then
				burn_object(object)
			end
		end
		if ent and ent.name == "__builtin:item" then
			local stack = ItemStack(ent.itemstring)
			if stack
			and stack:get_count() > 98
			and stack:get_name():match("stone")
			and minetest.get_item_group(stack:get_name(), "cracky") > 0 then
				local dragonstone_no = floor(stack:get_count() / 99)
				local leftover_no = stack:get_count() - 99 * dragonstone_no
				if self.name == "draconis:ice_dragon" then
					minetest.add_item(object:get_pos(), "draconis:dragonstone_block_ice " .. dragonstone_no)
				end
				if self.name == "draconis:fire_dragon" then
					minetest.add_item(object:get_pos(), "draconis:dragonstone_block_fire " .. dragonstone_no)
				end
				if leftover_no then
					minetest.add_item(object:get_pos(), stack:get_name() .. " " .. leftover_no)
				end
				object:remove()
			end
		end
	end
end

local function freeze_nodes(pos, radius)
	local h_stride = radius
	local v_stride = math.ceil(radius * 0.5)
	local pos1= {
		x = pos.x - h_stride,
		y = pos.y - v_stride,
		z = pos.z - h_stride
	}
	local pos2 = {
		x = pos.x + h_stride,
		y = pos.y + v_stride,
		z = pos.z + h_stride
	}
	local y_stride = 0
	for z = pos1.z, pos2.z do
		y_stride = y_stride + 1
		for x = pos1.x, pos2.x do
			local noise = random(5)
			if noise < 2 then
				local npos = {
					x = x,
					y = pos1.y + y_stride,
					z = z
				}
				if minetest.is_protected(npos, "") then
					return
				end
				local name = minetest.get_node(npos).name
				if name
				and not name:find("frozen")
				and name ~= "air"
				and name ~= "ignore" then
					local convert_to = frozen_conversions[name]
					if convert_to
					and (convert_to ~= draconis.global_nodes["ice"]
					or minetest.get_node({x = x, y = npos.y + 1, z = z}).name == "air") then
						minetest.set_node(npos, {name = convert_to})
					end
				end
			end
		end
	end
end

local function scorch_nodes(pos, radius)
	local h_stride = radius
	local v_stride = math.ceil(radius * 0.5)
	local pos1= {
		x = pos.x - h_stride,
		y = pos.y - v_stride,
		z = pos.z - h_stride
	}
	local pos2 = {
		x = pos.x + h_stride,
		y = pos.y + v_stride,
		z = pos.z + h_stride
	}
	local y_stride = 0
	for z = pos1.z, pos2.z do
		y_stride = y_stride + 1
		for x = pos1.x, pos2.x do
			local noise = random(5)
			if noise < 2 then
				local npos = {
					x = x,
					y = pos1.y + y_stride,
					z = z
				}
				if minetest.is_protected(npos, "") then
					return
				end
				local name = minetest.get_node(npos).name
				if name
				and not name:find("scorched")
				and name ~= "air"
				and name ~= "ignore" then
					local convert_to = scorched_conversions[name]
					if convert_to then
						minetest.set_node(npos, {name = convert_to})
					end
					if minetest.registered_nodes[flame_node]
					and creatura.get_node_def(name).walkable then
						local above = {x = npos.x, y = npos.y + 1, z = npos.z}
						if not creatura.get_node_def(above).walkable then
							minetest.set_node(above, {name = flame_node})
						end
					end
				end
			end
		end
	end
end

local function do_forge(pos, node, id)
	local forge = minetest.find_nodes_in_area(vec_sub(pos, 4), vec_add(pos, 4), node)
	if forge[1] then
		local func = minetest.registered_nodes[node].on_breath
		func(forge[1], id)
	end
end

local function breath_sound(self, sound)
	self.breath_timer = (self.breath_timer or 0.1) - self.dtime
	if self.breath_timer <= 0 then
		self.breath_timer = 2
		minetest.sound_play(sound, {
			object = self.object,
			gain = 1.0,
			max_hear_distance = 64,
			loop = false,
		})
	end
end

function draconis.fire_breath(self, pos2)
	if self.attack_stamina <= 0 then
		self.attack_disabled = true
		self:memorize("attack_disabled", self.attack_disabled)
		return
	elseif self.attack_stamina > 25
	and self.attack_disabled then
		self.attack_disabled = false
		self:memorize("attack_disabled", self.attack_disabled)
	end
	breath_sound(self, "draconis_fire_breath")
	local pos, dir = get_head_pos(self, pos2)
	dir.y = vec_dir(pos, pos2).y
	pos.y = pos.y + self.object:get_rotation().x
	local breath_delay = (self.breath_delay or 0) - 1
	if breath_delay <= 0 then
		local vel = self.object:get_velocity()
		local particle_origin = {
			x = pos.x + vel.x * 0.25,
			y = pos.y + vel.y * 0.25,
			z = pos.z + vel.z * 0.25
		}
		local scale = self.growth_scale
		if minetest.has_feature("particlespawner_tweenable") then
			minetest.add_particlespawner({
				amount = 3,
				time = 0.25,
				collisiondetection = true,
				collision_removal = true,
				pos = particle_origin,
				vel = {min = vec_multi(dir, 32), max = vec_multi(dir, 48)},
				acc = {min = vec_new(-4, -4, -4), max = vec_new(4, 4, 4)},
				size = {min = 8 * scale, max = 12 * scale},
				glow = 16,
				texture = {
					name = "draconis_fire_particle.png",
					alpha_tween = {0.75, 0.25},
					blend = "alpha"
				}
			})
		else
			minetest.add_particlespawner({
				amount = 3,
				time = 0.25,
				minpos = particle_origin,
				maxpos = particle_origin,
				minvel = vec_multi(dir, 32),
				maxvel = vec_multi(dir, 48),
				minacc = {x = -4, y = -4, z = -4},
				maxacc = {x = 4, y = 4, z = 4},
				minexptime = 0.02 * 32,
				maxexptime = 0.04 * 32,
				minsize = 8 * scale,
				maxsize = 12 * scale,
				collisiondetection = true,
				collision_removal = true,
				vertical = false,
				glow = 16,
				texture = "draconis_fire_particle.png"
			})
		end
		local spread = clamp(3 * scale, 1, 5)
		local breath_end = vec_add(pos, vec_multi(dir, 32))
		for i = 1, 32, floor(spread) do
			local fire_pos = vec_add(pos, vec_multi(dir, i))
			scorch_nodes(fire_pos, spread)
			if random(5) < 2 then
				damage_objects(self, fire_pos, spread + 2)
			end
			local def = creatura.get_node_def(fire_pos)
			if def.walkable
			or def.drawtype == "liquid" then
				breath_end = fire_pos
				break
			end
		end
		do_forge(breath_end, "draconis:draconic_forge_fire", self.dragon_id)
		breath_delay = 4
	end
	self.breath_delay = breath_delay
	if self.owner then
		self.attack_stamina = self.attack_stamina - self.dtime * 4
	end
	self:memorize("attack_stamina", self.attack_stamina)
end

function draconis.ice_breath(self, pos2)
	if self.attack_stamina <= 0 then
		self.attack_disabled = true
		self:memorize("attack_disabled", self.attack_disabled)
		return
	elseif self.attack_stamina > 25
	and self.attack_disabled then
		self.attack_disabled = false
		self:memorize("attack_disabled", self.attack_disabled)
	end
	breath_sound(self, "draconis_fire_breath")
	local pos, dir = get_head_pos(self, pos2)
	dir.y = vec_dir(pos, pos2).y
	pos.y = pos.y + self.object:get_rotation().x
	local breath_delay = (self.breath_delay or 0) - 1
	if breath_delay <= 0 then
		local vel = self.object:get_velocity()
		local particle_origin = {
			x = pos.x + vel.x * 0.25,
			y = pos.y + vel.y * 0.25,
			z = pos.z + vel.z * 0.25
		}
		local scale = self.growth_scale
		if minetest.has_feature("particlespawner_tweenable") then
			minetest.add_particlespawner({
				amount = 3,
				time = 0.25,
				collisiondetection = true,
				collision_removal = true,
				pos = particle_origin,
				vel = {min = vec_multi(dir, 32), max = vec_multi(dir, 48)},
				acc = {min = vec_new(-4, -4, -4), max = vec_new(4, 4, 4)},
				size = {min = 6 * scale, max = 8 * scale},
				glow = 16,
				texpool = {
					{name = "draconis_ice_particle_1.png", alpha_tween = {1, 0}, blend = "alpha"},
					{name = "draconis_ice_particle_2.png", alpha_tween = {1, 0}, blend = "alpha"},
					{name = "draconis_ice_particle_3.png", alpha_tween = {1, 0}, blend = "alpha"},
				}
			})
		else
			minetest.add_particlespawner({
				amount = 3,
				time = 0.25,
				minpos = particle_origin,
				maxpos = particle_origin,
				minvel = vec_multi(dir, 32),
				maxvel = vec_multi(dir, 48),
				minacc = {x = -4, y = -4, z = -4},
				maxacc = {x = 4, y = 4, z = 4},
				minexptime = 0.02 * 32,
				maxexptime = 0.04 * 32,
				minsize = 6 * scale,
				maxsize = 8 * scale,
				collisiondetection = true,
				collision_removal = true,
				vertical = false,
				glow = 16,
				texture = "draconis_ice_particle_" .. random(3) .. ".png"
			})
		end
		local spread = floor(clamp(2.5 * scale, 1, 4))
		local breath_end = vec_add(pos, vec_multi(dir, 32))
		for i = 1, 32, spread do
			local ice_pos = vec_add(pos, vec_multi(dir, i))
			freeze_nodes(ice_pos, spread)
			if random(5) < 2 then
				damage_objects(self, ice_pos, spread + 2)
			end
			local def = creatura.get_node_def(ice_pos)
			if def.walkable then
				breath_end = ice_pos
				break
			end
		end
		do_forge(breath_end, "draconis:draconic_forge_ice", self.dragon_id)
		breath_delay = 4
	end
	self.breath_delay = breath_delay
	if self.owner then
		self.attack_stamina = self.attack_stamina - self.dtime * 4
	end
	self:memorize("attack_stamina", self.attack_stamina)
end

--------------------
-- Initialize API --
--------------------


draconis.dragon_api = {
	animate = function(self, anim)
		if self.animations and self.animations[anim] then
			if self._anim == anim then return end
			local old_anim = nil
			if self._anim then
				old_anim = self._anim
			end
			self._anim = anim
			local old_prty = 1
			if old_anim
			and self.animations[old_anim].prty then
				old_prty = self.animations[old_anim].prty
			end
			local prty = 1
			if self.animations[anim].prty then
				prty = self.animations[anim].prty
			end
			local aparms
			if #self.animations[anim] > 0 then
				aparms = self.animations[anim][random(#self.animations[anim])]
			else
				aparms = self.animations[anim]
			end
			aparms.frame_blend = aparms.frame_blend or 0
			if old_prty > prty then
				aparms.frame_blend = self.animations[old_anim].frame_blend or 0
			end
			self.anim_frame = -aparms.frame_blend
			self.frame_offset = 0
			self.object:set_animation(aparms.range, aparms.speed, aparms.frame_blend, aparms.loop)
		else
			self._anim = nil
		end
	end,
	increase_age = function(self)
		self.age = self:memorize("age", self.age + 1)
		local age = self.age
		if age < 150
		or (age > 150
		and age < 1.5) then -- second check ensures pre-1.2 dragons grow to new limit
			self.growth_scale = self:memorize("growth_scale", self.growth_scale + 0.0099)
			self:set_scale(self.growth_scale)
			if age < 25 then
				self.growth_stage = 1
			elseif age == 25 then
				self.growth_stage = 1
			elseif age <= 50 then
				self.growth_stage = 2
			elseif age <= 75 then
				self.growth_stage = 3
			elseif age <= 100 then
				self.growth_stage = 4
			end
		end
		self:memorize("growth_stage", self.growth_stage)
		self:set_drops()
	end,
	do_growth = function(self)
		self.growth_timer = self.growth_timer - 1
		if self.growth_timer <= 0 then
			self:increase_age()
			self.growth_timer = self.growth_timer + 1200
		end
		if self.hp > self.max_health * self.growth_scale then
			self.hp = self.max_health * self.growth_scale
		end
		if self.hunger > (self.max_health * 0.5) * self.growth_scale then
			self.hunger = (self.max_health * 0.5) * self.growth_scale
		end
		self:memorize("growth_timer", self.growth_timer)
		self:memorize("hunger", self.hunger)
	end,
	set_drops = function(self)
		local type = "ice"
		if self.name == "draconis:fire_dragon" then
			type = "fire"
		end
		draconis.set_color_string(self)
		local stage = self.growth_stage
		local drops = {
			[1] = {
				{name = "draconis:scales_" .. type .. "_dragon_" .. self.color, min = 1, max = 3, chance = 2},
			},
			[2] = {
				{name = "draconis:scales_" .. type .. "_dragon_" .. self.color, min = 4, max = 12, chance = 2},
				{name = "draconis:dragon_bone", min = 1, max = 3, chance = 3}
			},
			[3] = {
				{name = "draconis:scales_" .. type .. "_dragon_" .. self.color, min = 8, max = 20, chance = 1},
				{name = "draconis:dragon_bone", min = 3, max = 8, chance = 1}
			},
			[4] = {
				{name = "draconis:scales_" .. type .. "_dragon_" .. self.color, min = 16, max = 24, chance = 1},
				{name = "draconis:dragon_bone", min = 6, max = 10, chance = 1},
			},
		}
		if not self.owner then
			if type == "ice" then
				table.insert(drops[4], {name = "draconis:egg_ice_" .. self.color, min = 1, max = 1, chance = 6})
			else
				table.insert(drops[4], {name = "draconis:egg_fire_" .. self.color, min = 1, max = 1, chance = 6})
			end
		end
		self.drops = drops[stage]
	end,
	play_sound = function(self, sound)
		if self.time_from_last_sound < 6 then return end
		local sounds = self.sounds
		if self.age < 15 then
			sounds = self.child_sounds
		end
		local spec = sounds and sounds[sound]
		local parameters = {object = self.object}
		if type(spec) == "table" then
			local name = spec.name
			if spec.variations then
				name = name .. "_" .. random(spec.variations)
			elseif #spec
			and #spec > 1 then
				spec = sounds[sound][random(#sounds[sound])]
				name = spec.name
			end
			local pitch = 1.0
			pitch = pitch - (random(-10, 10) * 0.005)
			parameters.gain = spec.gain or 1
			parameters.max_hear_distance = spec.distance or 8
			parameters.fade = spec.fade or 1
			parameters.pitch = pitch
			self.roar_anim_length = parameters.length or 1
			self.time_from_last_sound = 0
			self.jaw_init = true
			return minetest.sound_play(name, parameters)
		end
		return minetest.sound_play(spec, parameters)
	end,
	destroy_terrain = function(self)
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
				if n_pos.y - pos.y >= 1 then
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
	end,
	-- Textures
	update_emission = function(self, force)
		local pos = self.object:get_pos()
		local level = minetest.get_node_light(pos, minetest.get_timeofday())
		if not level then return end
		local texture = self:get_props().textures[1]
		local eyes_open = string.find(texture, "eyes")
		if self._glow_level == level
		and ((self._anim ~= "sleep" and eyes_open)
		or (self._anim == "sleep" and not eyes_open))
		and not force then return end
		local def = minetest.registered_entities[self.name]
		local textures = {
			def.textures[self.texture_no]
		}
		texture = textures[1]
		if self.wing_overlay then
			texture = texture .. "^" .. self.wing_overlay
		end
		self._glow_level = level
		local color = math.ceil(level / minetest.LIGHT_MAX * 255)
		if color > 255 then
			color = 255
		end
		local modifier = ("^[multiply:#%02X%02X%02X"):format(color, color, color)
		local dragon_type = "ice"
		if self.name == "draconis:fire_dragon" then
			dragon_type = "fire"
		end
		local eyes =  "draconis_" .. dragon_type .. "_eyes_".. self.eye_color .. ".png"
		if self.growth_scale < 0.25 then
			eyes = "draconis_" .. dragon_type .. "_eyes_child_".. self.eye_color .. ".png"
		end
		if self._anim == "sleep" then
			self.object:set_properties({
				textures = {"(" .. texture .. modifier .. ")"}
			})
		else
			self.object:set_properties({
				textures = {"(" .. texture .. modifier .. ")^" .. eyes}
			})
		end
	end,
	-- Dynamic Animation Methods
	tilt_to = function(self, tyaw, rate)
		self._tyaw = tyaw
		rate = self.dtime * (rate or 5)
		local rot = self.object:get_rotation()
		if not rot then return end
		-- Calc Yaw
		local yaw = rot.y
		local y_step = math.min(rate, abs(diff(yaw, tyaw)) % (pi2))
		local n_yaw = interp_angle(yaw, tyaw, y_step)
		-- Calc Roll
		local roll = diff(tyaw, yaw) / 2
		local r_step = math.min(rate, abs(diff(rot.z, tyaw)) % (pi2))
		local n_roll = interp_angle(rot.z, roll, r_step)
		self.object:set_rotation({x = rot.x, y = n_yaw, z = n_roll})
	end,
	set_weighted_velocity = function(self, speed, goal)
		self._tyaw = dir2yaw(goal)
		speed = speed or self._movement_data.speed
		local current_vel = self.object:get_velocity()
		local goal_vel = vec_multi(vec_normal(goal), speed)
		local vel = current_vel
		vel.x = vel.x + (goal_vel.x - vel.x) * 0.05
		vel.y = vel.y + (goal_vel.y - vel.y) * 0.05
		vel.z = vel.z + (goal_vel.z - vel.z) * 0.05
		self.object:set_velocity(vel)
	end,
	open_jaw = function(self)
		if not self._anim then return end
		local _, rot = self.object:get_bone_position("Jaw.CTRL")
		local tgt_angle
		local open_angle = pi / 4
		if self.jaw_init then
			local end_anim = self._anim:find("fire") or floor(rot.x) == deg(-open_angle)
			if end_anim
			or self.roar_anim_length <= 0 then
				self.jaw_init = false
				self.roar_anim_length = 0
				local step = math.min(self.dtime * 5, abs(diff(rad(rot.x), 0)) % (pi2))
				tgt_angle = interp_angle(rad(rot.x), 0, step)
			else
				local step = math.min(self.dtime * 5, abs(diff(rad(rot.x), -open_angle)) % (pi2))
				tgt_angle = interp_angle(rad(rot.x), -open_angle, step)
				self.roar_anim_length = self.roar_anim_length - self.dtime
			end
		else
			local step = math.min(self.dtime * 5, abs(diff(rad(rot.x), 0)) % (pi2))
			tgt_angle = interp_angle(rad(rot.x), 0, step)
		end
		if tgt_angle < -45 then tgt_angle = -45 end
		if tgt_angle > 0 then tgt_angle = 0 end
		self.object:set_bone_position("Jaw.CTRL", {x = 0, y = 0.15, z = -0.29}, {x = deg(tgt_angle), y = 0, z = 0})
	end,
	move_tail = function(self)
		if self._anim == "stand"
		or self._anim == "stand_fire" then
			self.last_yaw = self.object:get_yaw()
		end
		local anim_data = self.dynamic_anim_data
		local yaw = self.object:get_yaw()
		for seg = 1, #anim_data.tail do
			local data = anim_data.tail[seg]
			local _, rot = self.object:get_bone_position("Tail.".. seg .. ".CTRL")
			rot = rot.z
			local y_diff = diff(yaw, self.last_yaw)
			local tgt_rot = -y_diff * 10
			if self.dtime then
				tgt_rot = clamp(tgt_rot, -0.3, 0.3)
				if abs(y_diff) < 0.01 then
					y_diff = rad(rot)
					tgt_rot = 0
				end
				rot = interp_angle(rad(rot), tgt_rot, math.min(self.dtime * 3, abs(y_diff * 10) % (pi2)))
			end
			self.object:set_bone_position("Tail.".. seg .. ".CTRL", data.pos,
				{x = data.rot.x, y = data.rot.y, z = math.deg(rot) * (data.rot.z or 1)})
		end
	end,
	move_head = function(self, tyaw, pitch)
		local yaw = self.object:get_yaw()
		local seg_no = #self.dynamic_anim_data.head
		for seg = 1, seg_no do
			-- Data
			local data = self.dynamic_anim_data.head[seg]
			local bone_name = "Neck.".. seg .. ".CTRL"
			if seg == seg_no then
				bone_name = "Head.CTRL"
			end
			if not data then return end
			-- Calculation
			local _, rot = self.object:get_bone_position(bone_name)
			if not rot then return end
			local y_diff = diff(tyaw, yaw)
			local n_yaw = (tyaw ~= yaw and y_diff / 6) or 0
			if abs(deg(n_yaw)) > 22 then n_yaw = 0 end
			local dir = yaw2dir(n_yaw)
			dir.y = pitch or 0
			local n_pitch = -(sqrt(dir.x^2 + dir.y^2) / dir.z) / 4
			if abs(deg(n_pitch)) > 22 then n_pitch = 0 end
			if self.dtime then
				local rate = self.dtime * 3
				if abs(y_diff) < 0.01 then
					y_diff = rad(rot.z)
					n_yaw = 0
				end
				local yaw_w = math.min(rate, abs(y_diff) % (pi2))
				n_yaw = interp_angle(rad(rot.z), n_yaw, yaw_w)
				local pitch_w = math.min(rate, abs(diff(rad(rot.x), n_pitch)) % (pi2))
				n_pitch = interp_angle(rad(rot.x), n_pitch, pitch_w)
			end
			self.object:set_bone_position(bone_name, data.pos, {x = deg(n_pitch), y = data.rot.y, z = deg(n_yaw)})
		end
	end,
	feed = function(self, player)
		local name = player:get_player_name()
		if not self.owner
		or self.owner ~= name then
			return
		end
		local item, item_name = self:follow_wielded_item(player)
		if item_name then
			if not minetest.is_creative_enabled(player) then
				item:take_item()
				player:set_wielded_item(item)
			end
			local scale = self.growth_scale or 1
			if self.hp < (self.max_health * scale) then
				self:heal(self.max_health / 5)
			end
			if self.hunger
			and self.hunger < (self.max_health * 0.5) * scale then
				self.hunger = self.hunger + 5
				self:memorize("hunger", self.hunger)
			end
			if item_name:find("cooked") then
				self.food = (self.food or 0) + 1
			end
			if self.food
			and self.food >= 20
			and self.age then
				self.food = 0
				self:increase_age()
			end
			local pos = draconis.get_head_pos(self, player:get_pos())
			local minppos = vec_add(pos, 0.2 * scale)
			local maxppos = vec_sub(pos, 0.2 * scale)
			local def = minetest.registered_items[item_name]
			local texture = def.inventory_image
			if not texture or texture == "" then
				texture = def.wield_image
			end
			minetest.add_particlespawner({
				amount = 3,
				time = 0.1,
				minpos = minppos,
				maxpos = maxppos,
				minvel = {x=-1, y=1, z=-1},
				maxvel = {x=1, y=2, z=1},
				minacc = {x=0, y=-5, z=0},
				maxacc = {x=0, y=-9, z=0},
				minexptime = 1,
				maxexptime = 1,
				minsize = 4 * scale,
				maxsize = 6 * scale,
				collisiondetection = true,
				vertical = false,
				texture = texture,
			})
			return true
		end
		return false
	end,
	play_wing_sound = function(self)
		local offset = self.frame_offset or 0
		if offset > 20
		and not self.flap_sound_played then
			minetest.sound_play("draconis_flap", {
				object = self.object,
				gain = 3.0,
				max_hear_distance = 128,
				loop = false,
			})
			self.flap_sound_played = true
		elseif offset < 10 then
			self.flap_sound_played = false
		end
	end
}

draconis.wyvern_api = {
	animate = function(self, anim)
		if self.animations and self.animations[anim] then
			if self._anim == anim then return end
			local old_anim = nil
			if self._anim then
				old_anim = self._anim
			end
			self._anim = anim
			local old_prty = 1
			if old_anim
			and self.animations[old_anim].prty then
				old_prty = self.animations[old_anim].prty
			end
			local prty = 1
			if self.animations[anim].prty then
				prty = self.animations[anim].prty
			end
			local aparms
			if #self.animations[anim] > 0 then
				aparms = self.animations[anim][random(#self.animations[anim])]
			else
				aparms = self.animations[anim]
			end
			aparms.frame_blend = aparms.frame_blend or 0
			if old_prty > prty then
				aparms.frame_blend = self.animations[old_anim].frame_blend or 0
			end
			self.anim_frame = -aparms.frame_blend
			self.frame_offset = 0
			self.object:set_animation(aparms.range, aparms.speed, aparms.frame_blend, aparms.loop)
		else
			self._anim = nil
		end
	end,
	play_sound = function(self, sound)
		if self.time_from_last_sound < 6 then return end
		local sounds = self.sounds
		if self.age < 15 then
			sounds = self.child_sounds
		end
		local spec = sounds and sounds[sound]
		local parameters = {object = self.object}
		if type(spec) == "table" then
			local name = spec.name
			if spec.variations then
				name = name .. "_" .. random(spec.variations)
			elseif #spec
			and #spec > 1 then
				spec = sounds[sound][random(#sounds[sound])]
				name = spec.name
			end
			local pitch = 1.0
			pitch = pitch - (random(-10, 10) * 0.005)
			parameters.gain = spec.gain or 1
			parameters.max_hear_distance = spec.distance or 8
			parameters.fade = spec.fade or 1
			parameters.pitch = pitch
			self.roar_anim_length = parameters.length or 1
			self.time_from_last_sound = 0
			self.jaw_init = true
			return minetest.sound_play(name, parameters)
		end
		return minetest.sound_play(spec, parameters)
	end,
	-- Dynamic Animation Methods
	tilt_to = draconis.dragon_api.tilt_to,
	set_weighted_velocity = function(self, speed, goal)
		self._tyaw = dir2yaw(goal)
		speed = speed or self._movement_data.speed
		local current_vel = self.object:get_velocity()
		local goal_vel = vec_multi(vec_normal(goal), speed)
		local momentum = vector.length(current_vel) * 0.003
		if momentum > 0.04 then momentum = 0.04 end
		local vel = current_vel
		vel.x = vel.x + (goal_vel.x - vel.x) * 0.05 - momentum
		vel.y = vel.y + (goal_vel.y - vel.y) * 0.05
		vel.z = vel.z + (goal_vel.z - vel.z) * 0.05 - momentum
		self.object:set_velocity(vel)
	end,
	open_jaw = function(self)
		if not self._anim then return end
		local anim_data = self.dynamic_anim_data.jaw
		local _, rot = self.object:get_bone_position("Jaw.CTRL")
		local tgt_angle
		local step = self.dtime * 5
		local open_angle = pi / 4
		if self.jaw_init then
			local end_anim = self._anim:find("fire") or floor(rot.x) == deg(-open_angle)
			if end_anim then
				self.jaw_init = false
				self.roar_anim_length = 0
				return
			end
			tgt_angle = interp_angle(rad(rot.x), -open_angle, step)
			self.roar_anim_length = self.roar_anim_length - self.dtime
		else
			tgt_angle = interp_angle(rad(rot.x), 0, step)
		end
		local offset = {x = 0, y = anim_data.pos.y, z = anim_data.pos.z}
		self.object:set_bone_position("Jaw.CTRL", offset, {x = clamp(tgt_angle, -45, 0), y = 0, z = 0})
	end,
	move_tail = draconis.dragon_api.move_tail,
	move_head = draconis.dragon_api.move_head,
	feed = function(self, player)
		local name = player:get_player_name()
		if not self.owner
		or self.owner ~= name then
			return
		end
		local item, item_name = self:follow_wielded_item(player)
		if item_name then
			if not minetest.is_creative_enabled(player) then
				item:take_item()
				player:set_wielded_item(item)
			end
			local scale = self.growth_scale or 1
			if self.hp < (self.max_health * scale) then
				self:heal(self.max_health / 5)
			end
			if self.hunger
			and self.hunger < (self.max_health * 0.5) * scale then
				self.hunger = self.hunger + 5
				self:memorize("hunger", self.hunger)
			end
			if item_name:find("cooked") then
				self.food = (self.food or 0) + 1
			end
			if self.food
			and self.food >= 20
			and self.age then
				self.food = 0
				self:increase_age()
			end
			local pos = draconis.get_head_pos(self, player:get_pos())
			local minppos = vec_add(pos, 0.2 * scale)
			local maxppos = vec_sub(pos, 0.2 * scale)
			local def = minetest.registered_items[item_name]
			local texture = def.inventory_image
			if not texture or texture == "" then
				texture = def.wield_image
			end
			minetest.add_particlespawner({
				amount = 3,
				time = 0.1,
				minpos = minppos,
				maxpos = maxppos,
				minvel = {x=-1, y=1, z=-1},
				maxvel = {x=1, y=2, z=1},
				minacc = {x=0, y=-5, z=0},
				maxacc = {x=0, y=-9, z=0},
				minexptime = 1,
				maxexptime = 1,
				minsize = 4 * scale,
				maxsize = 6 * scale,
				collisiondetection = true,
				vertical = false,
				texture = texture,
			})
			return true
		end
		return false
	end,
	play_wing_sound = function(self)
		local offset = self.frame_offset or 0
		if offset > 20
		and not self.flap_sound_played then
			minetest.sound_play("draconis_flap", {
				object = self.object,
				gain = 3.0,
				max_hear_distance = 128,
				loop = false,
			})
			self.flap_sound_played = true
		elseif offset < 10 then
			self.flap_sound_played = false
		end
	end
}

dofile(minetest.get_modpath("draconis") .. "/api/forms.lua")

minetest.register_on_mods_loaded(function()
	for k, v in pairs(draconis.dragon_api) do
		minetest.registered_entities["draconis:fire_dragon"][k] = v
		minetest.registered_entities["draconis:ice_dragon"][k] = v
	end
	for k, v in pairs(draconis.wyvern_api) do
		minetest.registered_entities["draconis:jungle_wyvern"][k] = v
	end
end)

--------------
-- Commands --
--------------

minetest.register_privilege("draconis_admin", {
	description = "Allows Player to customize and force tame Dragons",
	give_to_singleplayer = false,
	give_to_admin = true
})

minetest.register_chatcommand("tamedragon", {
	description = "Tames pointed Dragon",
	privs = {draconis_admin = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		local dir = player:get_look_dir()
		local pos = player:get_pos()
		pos.y = pos.y + player:get_properties().eye_height or 1.625
		local dest = vec_add(pos, vec_multi(dir, 40))
		local object, ent = get_pointed_mob(pos, dest)
		if object
		and ent.name:match("^draconis:")
		and ent.memorize then
			local ent_pos = object:get_pos()
			local particle = "creatura_particle_green.png"
			if not ent.owner then
				ent.owner = name
				ent:memorize("owner", ent.owner)
				minetest.chat_send_player(name, correct_name(ent.name) .. " has been tamed!")
			else
				minetest.chat_send_player(name, correct_name(ent.name) .. " is already tamed.")
				particle = "creatura_particle_red.png"
			end
			minetest.add_particlespawner({
				amount = 16,
				time = 0.25,
				minpos = {
					x = ent_pos.x - ent.width,
					y = ent_pos.y - ent.width,
					z = ent_pos.z - ent.width
				},
				maxpos = {
					x = ent_pos.x + ent.width,
					y = ent_pos.y + ent.width,
					z = ent_pos.z + ent.width
				},
				minacc = {x = 0, y = 0.25, z = 0},
				maxacc = {x = 0, y = -0.25, z = 0},
				minexptime = 0.75,
				maxexptime = 1,
				minsize = 4,
				maxsize = 4,
				texture = particle,
				glow = 16
			})
		else
			minetest.chat_send_player(name, "You must be pointing at a mob.")
		end
	end
})

minetest.register_chatcommand("set_dragon_owner", {
	description = "Sets owner of pointed Dragon",
	params = "<name>",
	privs = {draconis_admin = true},
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		local param_name = params:match("%S+")
		if not player or not param_name then return false end
		local dir = player:get_look_dir()
		local pos = player:get_pos()
		pos.y = pos.y + player:get_properties().eye_height or 1.625
		local dest = vec_add(pos, vec_multi(dir, 40))
		local object, ent = get_pointed_mob(pos, dest)
		if object then
			local ent_pos = ent:get_center_pos()
			local particle = "creatura_particle_green.png"
			ent.owner = param_name
			ent:memorize("owner", ent.owner)
			minetest.chat_send_player(name, correct_name(ent.name) .. " is now owned by " .. param_name)
			minetest.add_particlespawner({
				amount = 16,
				time = 0.25,
				minpos = {
					x = ent_pos.x - ent.width,
					y = ent_pos.y - ent.width,
					z = ent_pos.z - ent.width
				},
				maxpos = {
					x = ent_pos.x + ent.width,
					y = ent_pos.y + ent.width,
					z = ent_pos.z + ent.width
				},
				minacc = {x = 0, y = 0.25, z = 0},
				maxacc = {x = 0, y = -0.25, z = 0},
				minexptime = 0.75,
				maxexptime = 1,
				minsize = 4,
				maxsize = 4,
				texture = particle,
				glow = 16
			})
		else
			minetest.chat_send_player(name, "You must be pointing at a mob.")
		end
	end
})

minetest.register_chatcommand("revive_dragon", {
	description = "Revives pointed Dragon",
	privs = {draconis_admin = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		local dir = player:get_look_dir()
		local pos = player:get_pos()
		pos.y = pos.y + player:get_properties().eye_height or 1.625
		local dest = vec_add(pos, vec_multi(dir, 40))
		local object, ent = get_pointed_mob(pos, dest)
		if object
		and ent.hp <= 0 then
			local ent_pos = ent:get_center_pos()
			local particle = "creatura_particle_green.png"
			ent.hp = ent.max_health
			ent:memorize("hp", ent.hp)
			minetest.chat_send_player(name, correct_name(ent.name) .. " has been revived!")
			minetest.add_particlespawner({
				amount = 16,
				time = 0.25,
				minpos = {
					x = ent_pos.x - ent.width,
					y = ent_pos.y - ent.width,
					z = ent_pos.z - ent.width
				},
				maxpos = {
					x = ent_pos.x + ent.width,
					y = ent_pos.y + ent.width,
					z = ent_pos.z + ent.width
				},
				minacc = {x = 0, y = 0.25, z = 0},
				maxacc = {x = 0, y = -0.25, z = 0},
				minexptime = 0.75,
				maxexptime = 1,
				minsize = 4,
				maxsize = 4,
				texture = particle,
				glow = 16
			})
		else
			minetest.chat_send_player(name, "You must be pointing at a mob.")
		end
	end
})

minetest.register_chatcommand("dragon_attack_blacklist_add", {
	description = "Adds player to attack blacklist",
	params = "<name>",
	privs = {draconis_admin = true},
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		local param_name = params:match("%S+")
		if not player or not param_name then return false end
		if draconis.attack_blacklist[param_name] then
			minetest.chat_send_player(name, param_name .. " is already on the Dragon attack blacklist.")
			return false
		end
		draconis.attack_blacklist[param_name] = true
		minetest.chat_send_player(name, param_name .. " has been added to the Dragon attack blacklist.")
	end
})

minetest.register_chatcommand("dragon_attack_blacklist_remove", {
	description = "Removes player to attack blacklist",
	params = "<name>",
	privs = {draconis_admin = true},
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		local param_name = params:match("%S+")
		if not player or not param_name then return false end
		if not draconis.attack_blacklist[param_name] then
			minetest.chat_send_player(name, param_name .. " isn't on the Dragon attack blacklist.")
			return false
		end
		draconis.attack_blacklist[param_name] = nil
		minetest.chat_send_player(name, param_name .. " has been removed from the Dragon attack blacklist.")
	end
})

----------------------
-- Target Assigning --
----------------------

local function get_dragon_by_id(dragon_id)
	for _, ent in pairs(minetest.luaentities) do
		if ent.dragon_id
		and ent.dragon_id == dragon_id then
			return ent
		end
	end
end

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_entities) do
		if (minetest.registered_entities[name].logic
		or minetest.registered_entities[name].brainfunc)
		or minetest.registered_entities[name]._cmi_is_mob
		or minetest.registered_entities[name]._creatura_mob then
			local old_punch = def.on_punch
			if not old_punch then
				old_punch = function() end
			end
			local on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
				old_punch(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
				local pos = self.object:get_pos()
				if not pos then return end
				if not puncher:is_player() then
					return
				end
				local player_name = puncher:get_player_name()
				if draconis.bonded_dragons[player_name]
				and #draconis.bonded_dragons[player_name] > 0 then
					for i = 1, #draconis.bonded_dragons[player_name] do
						local ent = get_dragon_by_id(draconis.bonded_dragons[player_name][i])
						if ent then
							ent._target = self.object
						end
					end
				end
				for object, data in pairs(draconis.wyverns) do
					if object
					and object:get_pos()
					and data.owner
					and data.owner == player_name
					and vec_dist(pos, object:get_pos()) < 64 then
						object:get_luaentity()._target = self.object
					end
				end
			end
			minetest.registered_entities[name].on_punch = on_punch
		end
	end
end)
-----------------
-- On Activate --
-----------------

-- Dragon

function draconis.dragon_activate(self)
	local dragon_type = "ice"
	if self.name == "draconis:fire_dragon" then
		dragon_type = "fire"
	end
	generate_texture(self)
	self.eye_color = self:recall("eye_color")
	if not self.eye_color then
		if dragon_type == "fire" then
			self.eye_color = fire_eye_textures[random(3)]
		else
			self.eye_color = ice_eye_textures[random(2)]
		end
		self:memorize("eye_color", self.eye_color)
	end
	self.gender = self:recall("gender") or nil
	if not self.gender then
		local genders = {"male", "female"}
		self.gender = self:memorize("gender", genders[random(2)])
	end
	if self.growth_scale then
		self:memorize("growth_scale", self.growth_scale) -- This is for spawning children
	end
	self.growth_scale = self:recall("growth_scale") or 1
	self.growth_timer = self:recall("growth_timer") or 1200
	self.age = self:recall("age") or 100
	local age = self.age
	if age <= 25 then
		self.growth_stage = 1
	elseif age <= 50 then
		self.growth_stage = 2
	elseif age <= 75 then
		self.growth_stage = 3
	else
		self.growth_stage = 4
	end
	self.hunger = self:recall("hunger") or ((self.max_health * 0.5) * self.growth_scale) * 0.5
	self:set_scale(self.growth_scale)
	self:do_growth()
	self:set_drops()
	self.drop_queue = self:recall("drop_queue") or nil
	if self.growth_scale < 0.25 then
		if not self.texture_no then
			self.texture_no = random(#self.child_textures)
		end
		self.textures = self.child_textures
		self:set_texture(self.texture_no, self.child_textures)
	end
	-- Tamed Data
	self.owner = self:recall("owner") or false
	self.stance = self:recall("stance") or "neutral"
	self.order = self:recall("order") or "wander"
	self.fly_allowed = self:recall("fly_allowed") or false
	self.aux_setting = self:recall("aux_setting") or "toggle_view"
	self.pitch_fly = self:recall("pitch_fly") or false
	self.shoulder_mounted = false
	activate_nametag(self)
	-- Movement Data
	self.is_landed = self:recall("is_landed") or false
	self.attack_stamina = self:recall("attack_stamina") or 100
	self.attack_disabled = self:recall("attack_disabled") or false
	self.flight_stamina = self:recall("flight_stamina") or 900
	-- Sound Data
	self.flap_sound_timer = 1.5
	self.flap_sound_played = false
	self.time_from_last_sound = 0
	-- World Data
	self.nest_pos = self:recall("nest_pos")
	self._path = {}
	self._ignore_obj = {}
	self.alert_timer = self:recall("alert_timer") or 0
	self._remove = self:recall("_remove") or nil
	self.dragon_id = self:recall("dragon_id") or 1
	if self.dragon_id == 1 then
		self.dragon_id = draconis.generate_id()
		self:memorize("dragon_id", self.dragon_id)
	end
	local global_data = draconis.dragons[self.dragon_id] or {}
	if global_data.removal_queue
	and #global_data.removal_queue > 0 then
		for i = #global_data.removal_queue, 1, -1 do
			if global_data.removal_queue[i]
			and vector.equals(vec_round(global_data.removal_queue[i]), vec_round(self.object:get_pos())) then
				draconis.dragons[self.dragon_id].removal_queue[i] = nil
				self.object:remove()
				return
			end
		end
	end
	draconis.dragons[self.dragon_id] = {
		last_pos = self.object:get_pos(),
		owner = self.owner or nil,
		staticdata = self:get_staticdata(),
		removal_queue = global_data.removal_queue or {},
		stored_in_item = global_data.stored_in_item or false
	}
	local owner = draconis.dragons[self.dragon_id].owner
	if owner
	and minetest.get_player_by_name(owner)
	and (not draconis.bonded_dragons[owner]
	or not is_value_in_table(draconis.bonded_dragons[owner], self.dragon_id)) then
		draconis.bonded_dragons[owner] = draconis.bonded_dragons[owner] or {}
		table.insert(draconis.bonded_dragons[owner], self.dragon_id)
	end
end

-- Wyvern

function draconis.wyvern_activate(self)
	self.attack_cooldown = {}
	-- Tamed Data
	self.rider = nil
	self.owner = self:recall("owner") or false
	self.stance = self:recall("stance") or "neutral"
	self.order = self:recall("order") or "wander"
	self.flight_allowed = self:recall("flight_allowed") or false
	self.hunger = self:recall("hunger") or self.max_hunger
	activate_nametag(self)
	-- Movement Data
	self.is_landed = self:recall("is_landed") or false
	-- World Data
	self._ignore_obj = {}
	self.flight_stamina = self:recall("flight_stamina") or 1600
	-- Sound Data
	self.time_from_last_sound = 0
	draconis.wyverns[self.object] = {owner = self.owner}
end

-------------
-- On Step --
-------------

-- Dragon

function draconis.dragon_step(self, dtime)
	self:update_emission()
	self:destroy_terrain()
	-- Animation Tracking
	local current_anim = self._anim
	local is_flying = current_anim and current_anim:find("fly")
	--local is_idle = current_anim and (current_anim:find("idle") or current_anim:find("stand"))
	--local is_walking = current_anim and current_anim:find("walk")
	local is_firing = current_anim and current_anim:find("fire")
	if current_anim then
		local aparms = self.animations[current_anim]
		if self.anim_frame ~= -1 then
			self.anim_frame = self.anim_frame + dtime
			self.frame_offset = floor(self.anim_frame * aparms.speed)
			if self.frame_offset > aparms.range.y - aparms.range.x then
				self.anim_frame = 0
				self.frame_offset = 0
			end
		end
	end
	-- Dynamic Animation
	draconis.head_tracking(self)
	self:open_jaw()
	self:move_tail()
	draconis.rotate_to_pitch(self, is_flying)
	-- Shoulder Mounting
	if self.shoulder_mounted then
		self:clear_action()
		self:animate("shoulder_idle")
		local player = minetest.get_player_by_name(self.owner)
		if not player
		or player:get_player_control().sneak == true
		or self.age > 4 then
			self.object:set_detach()
			self.shoulder_mounted = self:memorize("shoulder_mounted", false)
		end
		is_flying = false
		--is_idle = true
	end
	-- Dynamic Physics
	self.speed = 24 * clamp((self.growth_scale), 0.1, 1) -- Speed increases with size
	self.turn_rate = 6 - 3 * clamp((self.growth_scale), 0.1, 1) -- Turning radius widens with size
	if not is_flying
	or self.in_liquid then
		self.speed = self.speed * 0.3 -- Speed reduced when landed
		self.turn_rate = self.turn_rate * 1.5 -- Turning radius reduced when landed
	end
	-- Timers
	if self:timer(1) then
		self:do_growth()
		-- Misc
		self.time_from_last_sound = self.time_from_last_sound + 1
		if self.time_in_horn then
			self.growth_timer = self.growth_timer - self.time_in_horn / 2
			self.time_in_horn = nil
		end
		if random(16) < 2
		and not is_firing then
			self:play_sound("random")
		end
		-- Dynamic Stats
		local fly_stam = self.flight_stamina or 900
		local atk_stam = self.attack_stamina or 100
		local alert_timer = self.alert_timer or 0
		if is_flying
		and not self.in_liquid then -- Drain Stamina when flying
			fly_stam = fly_stam - 1
		else
			if fly_stam < 900 then -- Regen Stamina when landed
				fly_stam = fly_stam + self.dtime * 8
			end
		end
		if atk_stam < 100 then -- Regen Stamina constantly
			atk_stam = atk_stam + 1
		end
		if alert_timer > 0 then
			alert_timer = alert_timer - 1
		end
		self.flight_stamina = self:memorize("flight_stamina", fly_stam)
		self.attack_stamina = self:memorize("attack_stamina", atk_stam)
		self.alert_timer = self:memorize("alert_timer", alert_timer)
	end
	if self:timer(5) then
		local obj = next(self._ignore_obj)
		if obj then self._ignore_obj[obj] = nil end
	end
	if is_flying then
		self:play_wing_sound()
	end
	-- Switch Aerial/Terrestrial States
	if not self.is_landed
	and not self.fly_allowed
	and self.owner then
		self.is_landed = self:memorize("is_landed", true)
	elseif self:timer(16)
	and random(4) < 2 then
		if self.is_landed
		and self.flight_stamina > 300 then
			self.is_landed = self:memorize("is_landed", false)
		else
			self.is_landed = self:memorize("is_landed", true)
		end
	end
	-- Global Info
	if self.hp <= 0 then
		draconis.dragons[self.dragon_id] = nil
		return
	end
	local global_data = draconis.dragons[self.dragon_id] or {}
	draconis.dragons[self.dragon_id] = {
		last_pos = self.object:get_pos(),
		owner = self.owner or nil,
		name = self.nametag or nil,
		staticdata = self:get_staticdata(),
		removal_queue = global_data.removal_queue or {},
		stored_in_item = global_data.stored_in_item or false
	}
	if draconis.dragons[self.dragon_id].stored_in_item then
		self.object:remove()
	end
end

-- Wyvern

function draconis.wyvern_step(self, dtime)
	-- Animation Tracking
	local current_anim = self._anim
	local is_flying = current_anim and (current_anim == "fly" or current_anim == "dive")
	--local is_idle = current_anim and (current_anim == "stand" or current_anim == "hover")
	if current_anim then
		local aparms = self.animations[current_anim]
		if self.anim_frame ~= -1 then
			self.anim_frame = self.anim_frame + dtime
			self.frame_offset = floor(self.anim_frame * aparms.speed)
			if self.frame_offset > aparms.range.y - aparms.range.x then
				self.anim_frame = 0
				self.frame_offset = 0
			end
		end
	end
	-- Dynamic Animation
	draconis.head_tracking(self)
	self:open_jaw()
	self:move_tail()
	draconis.rotate_to_pitch(self, is_flying)
	-- Timers
	if self:timer(1) then
		if random(16) < 2 then
			self:play_sound("random")
		end
		self.speed = 32
		self.turn_rate = 5
		-- Dynamic Stats
		local fly_stam = self.flight_stamina or 1600
		if is_flying
		and not self.in_liquid
		and fly_stam > 0 then -- Drain Stamina when flying
			fly_stam = fly_stam - 1
			self.turn_rate = self.turn_rate * 0.75 -- Turning radius incrased when flying
		else
			self.speed = self.speed * 0.2 -- Speed reduced when landed
			if fly_stam < 1600 then -- Regen Stamina when landed
				fly_stam = fly_stam + self.dtime * 8
			end
		end
		self.flight_stamina = self:memorize("flight_stamina", fly_stam)
		-- Attack Cooldown
		if #self.attack_cooldown > 0 then
			for obj, cooldown in pairs(self.attack_cooldown) do
				if obj
				and obj:get_pos() then
					if cooldown - 1 <= 0 then
						self.attack_cooldown[obj] = nil
					else
						self.attack_cooldown[obj] = cooldown - 1
					end
				else
					self.attack_cooldown[obj] = nil
				end
			end
		end
	end
	if self:timer(15) then
		local obj = next(self._ignore_obj)
		if obj then self._ignore_obj[obj] = nil end
	end
	if not draconis.wyverns[self.object] then
		draconis.wyverns[self.object] = {owner = self.owner}
	end
end

-------------------
-- On Rightclick --
-------------------

-- Dragon

function draconis.dragon_rightclick(self, clicker)
	local name = clicker:get_player_name()
	local inv = minetest.get_inventory({type = "player", name = name})
	if draconis.contains_libri(inv) then
		draconis.add_page(inv, "dragons")
	end
	if self.hp <= 0 then
		if draconis.drop_items(self) then
			draconis.dragons[self.dragon_id] = nil
			self.object:remove()
		end
		return
	end
	if self:feed(clicker) then
		return
	end
	local item_name = clicker:get_wielded_item():get_name() or ""
	if self.owner
	and name == self.owner
	and item_name == "" then
		if clicker:get_player_control().sneak then
			self:show_formspec(clicker)
		elseif not self.rider
		and self.age >= 35 then
			draconis.attach_player(self, clicker)
		elseif self.age < 5 then
			self.shoulder_mounted = self:memorize("shoulder_mounted", true)
			self.object:set_attach(clicker, "",
				{x = 3 - self.growth_scale, y = 11.5,z = -1.5 - (self.growth_scale * 5)}, {x=0,y=0,z=0})
		end
	end
	if self.rider
	and not self.passenger
	and name ~= self.owner
	and item_name == "" then
		draconis.send_passenger_request(self, clicker)
	end
end

-- Wyvern

function draconis.wyvern_rightclick(self, clicker)
	if self.hp <= 0 then return end
	local name = clicker:get_player_name()
	local inv = minetest.get_inventory({type = "player", name = name})
	if draconis.contains_libri(inv) then
		draconis.add_page(inv, "wyverns")
	end
	if self:feed(clicker) then
		return
	end
	local item_name = clicker:get_wielded_item():get_name() or ""
	if (not self.owner
	or name == self.owner)
	and not self.rider
	and item_name == "" then
		if clicker:get_player_control().sneak then
			self:show_formspec(clicker)
		else
			draconis.attach_player(self, clicker)
		end
	end
end

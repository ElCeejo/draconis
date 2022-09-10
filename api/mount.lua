---------------
-- Mount API --
---------------

draconis.mounted_player_data = {}

local abs = math.abs
local ceil = math.ceil

-------------------
-- Player Visual --
-------------------

minetest.register_entity("draconis:mounted_player_visual", {
	initial_properties = {
		mesh = "character.b3d",
		visual = "mesh",
		collisionbox = {0, 0, 0, 0, 0, 0},
		stepheight = 0,
		physical = false,
		collide_with_objects = false
	},
	on_activate = function(self, static)
		static = minetest.deserialize(static) or {}

		if not static.player then
			self.object:remove()
			return
		end

		self.player = static.player
		local player = minetest.get_player_by_name(self.player)

		if not player then
			self.object:remove()
			return
		end

		self.object:set_properties({
			textures = player:get_properties().textures,
			nametag = self.player
		})
		self.object:set_armor_groups({immortal = 1})
		self.object:set_yaw(player:get_look_horizontal())
	end,
	get_staticdata = function() return "" end,
	on_step = function(self) self.object:set_velocity(vector.new()) end
})

function draconis.set_fake_player(self, player, passenger)
	if not player
	or not player:get_look_horizontal()
	or not player:is_player() then
		return
	end
	local player_name = player:get_player_name()
	if draconis.mounted_player_data[player_name]
	and draconis.mounted_player_data[player_name].fake_player
	and draconis.mounted_player_data[player_name].fake_player:get_pos() then
		draconis.unset_fake_player(player)
		return
	end
	local player_pos = player:get_pos()
	local fake_player = minetest.add_entity(
		player_pos,
		"draconis:mounted_player_visual",
		minetest.serialize({player = player_name})
	)
	-- Cache Player Data
	draconis.mounted_player_data[player_name] = {
		collision = table.copy(player:get_properties().collisionbox),
		textures = table.copy(player:get_properties().textures),
		visual_size = table.copy(player:get_properties().visual_size),
		mesh = player:get_properties().mesh,
		eye_offset_first = player:get_eye_offset().offset_first,
		eye_offset_third = player:get_eye_offset().offset_third,
		vertical = player:get_look_vertical(),
		horizontal = player:get_look_horizontal(),
		inventory = player:get_inventory():get_lists(),
		formspec = player:get_inventory_formspec(),
		hotbar = player:hud_get_hotbar_itemcount(),
		nametag = player:get_nametag_attributes(),
		dragon = self,
		fake_player = fake_player
	}
	-- Set Players Data
	player:set_properties({
		visual_size = {x = 0, y = 0, z = 0},
		textures = {}
	})
	player:set_nametag_attributes({text = " ", bgcolor = false})
	-- Attach Fake Player
	if passenger then
		fake_player:set_attach(self.object, "Torso.2", {x = 0, y = -0.3, z = 0.2}, {x = 90, y = 0, z = 180})
	else
		fake_player:set_attach(self.object, "Torso.2", {x = 0, y = 0.75, z = 0.2}, {x = 90, y = 0, z = 180})
	end
	fake_player:set_animation({x = 81, y = 160}, 30, 0)
	local player_size = fake_player:get_properties().visual_size
	local dragon_size = self.object:get_properties().visual_size
	fake_player:set_properties({
		visual_size = {
			x = player_size.x / dragon_size.x,
			y = player_size.y / dragon_size.y
		},
		mesh = draconis.mounted_player_data[player_name].mesh,
		pointable = false
	})
	player:set_properties({
		collisionbox = {0, 0, 0, 0, 0, 0}
	})
end

function draconis.unset_fake_player(player)
	if not player
	or not player:get_look_horizontal()
	or not player:is_player() then
		return
	end
	local player_name = player:get_player_name()
	if not draconis.mounted_player_data[player_name]
	or not draconis.mounted_player_data[player_name].fake_player
	or not draconis.mounted_player_data[player_name].fake_player:get_pos() then
		return
	end
	-- Cache Player Data
	local data = draconis.mounted_player_data[player_name]
	local fake_player = data.fake_player
	-- Set Players Data
	player:set_properties({
		collisionbox = data.collision,
		visual_size = data.visual_size,
		textures = data.textures
	})
	player:set_nametag_attributes(data.nametag)
	player:set_eye_offset(data.eye_offset_first, data.eye_offset_third)
	-- Unset Data
	draconis.mounted_player_data[player_name] = nil
	-- Remove Fake Player
	fake_player:remove()
end

----------------
-- Attachment --
----------------

local function set_hud(player, def)
	local hud = {
		hud_elem_type = "image",
		position = def.position,
		text = def.text,
		scale = {x = 3, y = 3},
		alignment = {x = 1, y = -1},
		offset = {x = 0, y = -5}
	}
	return player:hud_add(hud)
end

function draconis.attach_player(self, player)
	if not player
	or not player:get_look_horizontal()
	or not player:is_player() then
		return
	end
	local scale = self.growth_scale or 1
	-- Attach Player
	player:set_attach(self.object, "Torso.2", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
	-- Set Players Eye Offset
	player:set_eye_offset({
		x = 0,
		y = 50 * scale,
		z = -160 * scale
	}, {x = 0, y = 0, z = 0}) -- 3rd person eye offset is limited to 15 on each axis (Fix this, devs.)
	player:set_look_horizontal(self.object:get_yaw() or 0)
	-- Set Fake Player (Using a fake player and changing 1st person eye offset works around the above issue)
	draconis.set_fake_player(self, player)
	-- Set Dragon Data
	self.rider = player
	-- Set HUD
	if not self.attack_stamina then
		return
	end
	local data = draconis.mounted_player_data[player:get_player_name()]
	if not data.huds then
		local health = self.hp / math.ceil(self.max_health * scale) * 100
		local hunger = self.hunger / math.ceil(self.max_hunger * scale) * 100
		local stamina = self.flight_stamina / 900 * 100
		local breath = self.attack_stamina / 100 * 100
		player:hud_set_flags({wielditem = false})
		draconis.mounted_player_data[player:get_player_name()].huds = {
			["health"] = set_hud(player, {
				text = "draconis_forms_health_bg.png^[lowpart:" .. health .. ":draconis_forms_health_fg.png",
				position = {x = 0, y = 0.7}
			}),
			["hunger"] = set_hud(player, {
				text = "draconis_forms_hunger_bg.png^[lowpart:" .. hunger .. ":draconis_forms_hunger_fg.png",
				position = {x = 0, y = 0.8}
			}),
			["stamina"] = set_hud(player, {
				text = "draconis_forms_stamina_bg.png^[lowpart:" .. stamina .. ":draconis_forms_stamina_fg.png",
				position = {x = 0, y = 0.9}
			}),
			["breath"] = set_hud(player, {
				text = "draconis_forms_breath_bg.png^[lowpart:" .. breath .. ":draconis_forms_breath_fg.png",
				position = {x = 0, y = 1}
			})
		}
	end
end

function draconis.attach_passenger(self, player)
	if not player
	or not player:get_look_horizontal()
	or not player:is_player() then
		return
	end
	local scale = self.growth_scale
	-- Attach Player
	player:set_attach(self.object, "Torso.2", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
	-- Set Players Eye Offset
	player:set_eye_offset({
		x = 0,
		y = 50 * scale,
		z = -160 * scale
	}, {x = 0, y = 0, z = 0}) -- 3rd person eye offset is limited to 15 on each axis (Fix this, devs.)
	player:set_look_horizontal(self.object:get_yaw() or 0)
	-- Set Fake Player (Using a fake player and changing 1st person eye offset works around the above issue)
	draconis.set_fake_player(self, player, true)
	-- Set Dragon Data
	self.passenger = player
	-- Set HUD
	local data = draconis.mounted_player_data[player:get_player_name()]
	if not data.huds then
		local health = self.hp / math.ceil(self.max_health * scale) * 100
		local hunger = self.hunger / math.ceil(self.max_hunger * scale) * 100
		local stamina = self.flight_stamina / 900 * 100
		local breath = self.attack_stamina / 100 * 100
		player:hud_set_flags({wielditem = false})
		draconis.mounted_player_data[player:get_player_name()].huds = {
			["health"] = set_hud(player, {
				text = "draconis_forms_health_bg.png^[lowpart:" .. health .. ":draconis_forms_health_fg.png",
				position = {x = 0, y = 0.7}
			}),
			["hunger"] = set_hud(player, {
				text = "draconis_forms_hunger_bg.png^[lowpart:" .. hunger .. ":draconis_forms_hunger_fg.png",
				position = {x = 0, y = 0.8}
			}),
			["stamina"] = set_hud(player, {
				text = "draconis_forms_stamina_bg.png^[lowpart:" .. stamina .. ":draconis_forms_stamina_fg.png",
				position = {x = 0, y = 0.9}
			}),
			["breath"] = set_hud(player, {
				text = "draconis_forms_breath_bg.png^[lowpart:" .. breath .. ":draconis_forms_breath_fg.png",
				position = {x = 0, y = 1}
			})
		}
	end
end

function draconis.detach_player(self, player)
	if not player
	or not player:get_look_horizontal()
	or not player:is_player() then
		return
	end
	local player_name = player:get_player_name()
	local data = draconis.mounted_player_data[player_name]
	-- Attach Player
	player:set_detach()
	-- Set HUD
	if self.attack_stamina then
		player:hud_remove(data.huds["health"])
		player:hud_remove(data.huds["hunger"])
		player:hud_remove(data.huds["stamina"])
		player:hud_remove(data.huds["breath"])
	end
	player:hud_set_flags({wielditem = true})
	-- Set Fake Player (Using a fake player and changing 1st person eye offset works around the above issue)
	draconis.unset_fake_player(player)
	-- Set Dragon Data
	if player == self.rider then
		self.rider = nil
	else
		self.passenger = nil
	end
end

local requesting_passenger = {}

local function passenger_form(player)
	local name = player:get_player_name()
	local formspec = {
		"size[6,3.476]",
		"real_coordinates[true]",
		"label[0.25,1;" .. name .. " would like to ride as a passenger]",
		"button_exit[0.25,1.3;2.3,0.8;btn_accept_pssngr;Accept]",
		"button_exit[3.5,1.3;2.3,0.8;btn_decline_pssngr;Decline]",
	}
	return table.concat(formspec, "")
end

function draconis.send_passenger_request(self, clicker)
	if not self.rider
	or not self.rider:get_look_horizontal()
	or not clicker:get_look_horizontal() then return end
	local rider = self.rider
	minetest.show_formspec(rider:get_player_name(), "draconis:passenger_request", passenger_form(clicker))
	requesting_passenger[rider:get_player_name()] = {
		player = clicker,
		entity = self
	}
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if formname == "draconis:passenger_request" then
		if not requesting_passenger[name] then
			return
		end
		local pssngr = requesting_passenger[name].player
		local ent = requesting_passenger[name].entity
		if fields.btn_accept_pssngr
		and pssngr
		and pssngr:get_look_horizontal() then
			draconis.attach_passenger(ent, pssngr)
			requesting_passenger[name] = nil
			return false
		end
		if fields.btn_decline_pssngr
		or fields.quit
		or fields.key_enter then
			requesting_passenger[name] = nil
		end
	end
end)

--------------
-- Settings --
--------------

local function menu_form()
	local formspec = {
		"size[6,3.476]",
		"real_coordinates[true]",
		"button[0.25,1.3;2.3,0.8;btn_view_point;Change View Point]",
		"button[3.5,1.3;2.3,0.8;btn_pitch_toggle;Toggle Pitch Flight]",
	}
	return table.concat(formspec, "")
end

minetest.register_chatcommand("dragon_mount_settings", {
	privs = {
		interact = true,
	},
	func = function(name)
		minetest.show_formspec(name, "draconis:dragon_mount_settings", menu_form())
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if formname == "draconis:dragon_mount_settings" then
		if fields.btn_view_point then
			draconis.aux_key_setting[name] = "pov"
			minetest.chat_send_player(name, "Sprint key now changes point of view")
		end
		if fields.btn_pitch_toggle then
			draconis.aux_key_setting[name] = "vert_method"
			minetest.chat_send_player(name, "Sprint key now changes vertical movement method")
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if not draconis.aux_key_setting[name] then
		draconis.aux_key_setting[name] = "pov"
	end
end)

minetest.register_on_dieplayer(function(player)
	local name = player:get_player_name()
	if name
	and draconis.mounted_player_data[name] then
		draconis.detach_player(draconis.mounted_player_data[name].dragon, player)
	end
end)

-------------------
-- Data Handling --
-------------------

minetest.register_on_leaveplayer(function(player)
	draconis.unset_fake_player(player)
end)

local function update_hud(self, player)
	local name = player:get_player_name()
	if not name then return end
	-- Get Stats
	local scale = self.growth_scale
	local health = self.hp / ceil(self.max_health * scale) * 100
	local hunger = self.hunger / ceil(self.max_hunger * scale) * 100
	local stamina = self.flight_stamina / 900 * 100
	local breath = self.attack_stamina / 100 * 100
	local hud_data = draconis.mounted_player_data[name].huds
	-- Update Elements
	player:hud_remove(hud_data["health"])
	player:hud_remove(hud_data["hunger"])
	player:hud_remove(hud_data["stamina"])
	player:hud_remove(hud_data["breath"])
	draconis.mounted_player_data[name].huds = {
		["health"] = set_hud(player, {
			text = "draconis_forms_health_bg.png^[lowpart:" .. health .. ":draconis_forms_health_fg.png",
			position = {x = 0, y = 0.7}
		}),
		["hunger"] = set_hud(player, {
			text = "draconis_forms_hunger_bg.png^[lowpart:" .. hunger .. ":draconis_forms_hunger_fg.png",
			position = {x = 0, y = 0.8}
		}),
		["stamina"] = set_hud(player, {
			text = "draconis_forms_stamina_bg.png^[lowpart:" .. stamina .. ":draconis_forms_stamina_fg.png",
			position = {x = 0, y = 0.9}
		}),
		["breath"] = set_hud(player, {
			text = "draconis_forms_breath_bg.png^[lowpart:" .. breath .. ":draconis_forms_breath_fg.png",
			position = {x = 0, y = 1}
		})
	}
end

--------------
-- Behavior --
--------------

creatura.register_utility("draconis:mount", function(self)
	local is_landed = creatura.sensor_floor(self, 5, true) < 4
	local view_held = false
	local view_point = 3
	local first_person_height = 45
	--local initial_age = self.age
	self:halt()
	local func = function(_self)
		local player = _self.rider
		if not player or not player:get_pos() then return true end
		local pssngr = _self.passenger

		local player_name = player:get_player_name()
		local control = player:get_player_control()

		local look_dir = player:get_look_dir()
		local look_yaw = minetest.dir_to_yaw(look_dir)

		local scale = _self.growth_scale
		local player_data = draconis.mounted_player_data[player_name]

		if not player_data then return true end

		update_hud(self, player)

		local player_props = player:get_properties()

		if player_props.visual_size.x ~= 0 then
			player:set_properties({
				visual_size = {x = 0, y = 0, z = 0},
			})
		end

		if not _self:get_action() then
			if control.aux1 then
				if draconis.aux_key_setting[player_name] == "pov" then
					if not view_held then
						if view_point == 3 then
							view_point = 1
							player_data.fake_player:set_properties({
								visual_size = {x = 0, y = 0, z = 0},
							})
							player:set_eye_offset({
								x = 0,
								y = 45 * scale,
								z = 20 * scale
							}, {x = 0, y = 0, z = 0})
							player:hud_set_flags({wielditem = true})
						elseif view_point == 1 then
							view_point = 2
							local dragon_size = _self.object:get_properties().visual_size
							player_data.fake_player:set_properties({
								visual_size = {
									x = 1 / dragon_size.x,
									y = 1 / dragon_size.y
								}
							})
							player:set_eye_offset({
								x = 45 * scale,
								y = 80 * scale,
								z = -110 * scale
							}, {x = 0, y = 0, z = 0})
							player:hud_set_flags({wielditem = false})
						elseif view_point == 2 then
							view_point = 3
							local dragon_size = _self.object:get_properties().visual_size
							player_data.fake_player:set_properties({
								visual_size = {
									x = 1 / dragon_size.x,
									y = 1 / dragon_size.y
								}
							})
							player:set_eye_offset({
								x = 0,
								y = 80 * scale,
								z = -160 * scale
							}, {x = 0, y = 0, z = 0})
							player:hud_set_flags({wielditem = false})
						end
						view_held = true
					end
				else
					view_held = true
					if _self.pitch_fly then
						_self.pitch_fly = _self:memorize("pitch_fly", false)
					else
						_self.pitch_fly = _self:memorize("pitch_fly", true)
					end
				end
			else
				view_held = false
			end

			local anim

			if is_landed then
				_self:set_gravity(-9.8)
				anim = "stand"
				if control.up then
					_self:set_forward_velocity(12)
					_self:turn_to(look_yaw, 4)
					anim = "walk"
				end
				if control.jump then
					is_landed = false
					draconis.action_takeoff(_self)
				end
			else
				_self:set_gravity(0)
				anim = "hover"
				if control.up then
					anim = "fly"
					if _self.pitch_fly then
						_self:set_vertical_velocity(12 * look_dir.y)
					end
					_self:set_forward_velocity(24)
				else
					_self:set_vertical_velocity(0)
					_self:set_forward_velocity(0)
				end
				_self:tilt_to(look_yaw, 2)
				if not _self.pitch_fly then
					if control.jump then
						_self:set_vertical_velocity(12)
					elseif control.down then
						_self:set_vertical_velocity(-12)
					else
						_self:set_vertical_velocity(0)
					end
				end
				if _self.touching_ground
				and control.down then
					is_landed = true
					draconis.action_land(_self)
				end
			end

			if control.LMB then
				local start = _self.object:get_pos()
				local offset = player:get_eye_offset()
				local eye_correction = vector.multiply({x = look_dir.x, y = 0, z= look_dir.z}, offset.z * 0.125)
				start = vector.add(start, eye_correction)
				start.y = start.y + (offset.y * 0.125)
				local tpos = vector.add(start, vector.multiply(look_dir, 64))
				local head_dir = vector.direction(start, tpos)
				look_dir.y = head_dir.y
				_self:breath_attack(tpos)
				anim = anim .. "_fire"
			end

			if anim then
				_self:animate(anim)
				if view_point == 1 then
					if anim:match("idle")
					or (anim:match("fly")
					and control.jump)then
						first_person_height = first_person_height + (65 - first_person_height) * 0.2
					else
						first_person_height = first_person_height + (45 - first_person_height) * 0.2
					end
					player:set_eye_offset({
						x = 0,
						y = first_person_height * scale,
						z = 20 * scale
					}, {x = 0, y = 0, z = 0})
				end
			end
		end

		_self:move_head(look_yaw, look_dir.y)

		if control.sneak
		or player:get_player_name() ~= _self.owner then
			draconis.detach_player(_self, player)
			if pssngr then
				draconis.detach_player(_self, _self.passenger)
			end
			return true
		end
		if pssngr
		and pssngr:get_player_control().sneak then
			draconis.detach_player(_self, pssngr)
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("draconis:wyvern_mount", function(self)
	local is_landed = creatura.sensor_floor(self, 5, true) < 4
	local view_held = false
	local view_point = 2
	local momentum = 0
	self:halt()
	local func = function(_self)
		local player = _self.rider
		if not player
		or not player:get_look_horizontal() then
			return true
		end

		local player_name = player:get_player_name()
		local control = player:get_player_control()

		local look_dir = player:get_look_dir()
		local look_yaw = minetest.dir_to_yaw(look_dir)

		local player_data = draconis.mounted_player_data[player_name]

		if not player_data then return true end

		local player_props = player:get_properties()

		if player_props.visual_size.x ~= 0 then
			player:set_properties({
				visual_size = {x = 0, y = 0, z = 0},
			})
		end

		if control.aux1 then
			if not view_held then
				if view_point == 2 then
					view_point = 1
					player_data.fake_player:set_properties({
						visual_size = {x = 0, y = 0, z = 0},
					})
					player:hud_set_flags({wielditem = true})
				elseif view_point == 1 then
					view_point = 2
					local dragon_size = _self.object:get_properties().visual_size
					player_data.fake_player:set_properties({
						visual_size = {
							x = 1 / dragon_size.x,
							y = 1 / dragon_size.y
						}
					})
					player:hud_set_flags({wielditem = false})
				end
				view_held = true
			end
		else
			view_held = false
		end

		if not _self:get_action() then

			local anim

			if is_landed then
				_self:set_gravity(-9.8)
				anim = "stand"
				if control.up then
					_self:set_forward_velocity(12)
					_self:turn_to(look_yaw, 4)
					anim = "walk"
				end
				if control.jump then
					is_landed = false
					draconis.action_takeoff(_self)
				end
				if control.LMB then
					draconis.action_punch(_self)
				end
			else
				_self:set_gravity(0)
				anim = "hover"
				if control.up then
					anim = "fly"
					_self:set_weighted_velocity(32, look_dir)
					if look_dir.y < -0.33
					and control.LMB then
						if momentum < 28 then
							momentum = momentum + (_self.dtime * 20) * abs(look_dir.y)
						end
					elseif momentum > 0 then
						momentum = momentum - _self.dtime * 15
						if momentum < 0 then momentum = 0 end
					end
				else
					_self:set_vertical_velocity(0)
					_self:set_forward_velocity(0)
				end
				_self:tilt_to(look_yaw, 4)
				if _self.touching_ground
				and control.down then
					is_landed = true
					draconis.action_land(_self)
				end
			end

			if control.LMB
			and anim == "fly"
			and momentum > 0 then
				_self:set_weighted_velocity(32 + momentum, look_dir)
				anim = "dive"
			end

			if anim then
				_self:animate(anim)
			end
		end

		if view_point == 2 then
			local goal_y = 0 - 60 * look_dir.y
			local goal_z = -120 + 60 * abs(look_dir.y)
			if _self._anim == "dive" then
				local accel_offset = 60 + momentum
				goal_y = 40 - accel_offset * look_dir.y
				goal_z = -160 + accel_offset * abs(look_dir.y)
			end
			local offset = player:get_eye_offset()
			if abs(goal_y - offset.y) > 0.1
			or abs(goal_z - offset.z) > 0.1 then
				local lerp_w = _self.dtime * 2
				player:set_eye_offset({
					x = 0,
					y = offset.y + (goal_y - offset.y) * lerp_w,
					z = offset.z + (goal_z - offset.z) * lerp_w},
				{x = 0, y = 0, z = 0})
			end
		else
			local goal_y = 25
			local goal_z = 10
			if _self._anim == "fly" then
				goal_y = goal_y + 15 * look_dir.y
				goal_z = goal_z - 20 * look_dir.y
			elseif _self._anim == "dive" then
				local accel_offset = momentum * 0.5
				goal_y = goal_y + accel_offset * look_dir.y
				goal_z = goal_z - accel_offset * look_dir.y
			end
			local offset = player:get_eye_offset()
			if abs(goal_y - offset.y) > 0.1
			or abs(goal_z - offset.z) > 0.1 then
				local lerp_w = _self.dtime * 4
				player:set_eye_offset({
					x = 0,
					y = offset.y + (goal_y - offset.y) * lerp_w,
					z = offset.z + (goal_z - offset.z) * lerp_w},
				{x = 0, y = 0, z = 0})
			end
		end

		if control.sneak
		or player:get_player_name() ~= _self.owner then
			draconis.detach_player(_self, player)
			return true
		end
	end
	self:set_utility(func)
end)

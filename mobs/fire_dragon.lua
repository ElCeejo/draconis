-----------------
-- Fire Dragon --
-----------------

local creative = minetest.settings:get_bool("creative_mode")

local function is_value_in_table(tbl, val)
	for _, v in pairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

local colors = {"black", "bronze", "green", "red", "gold"}

creatura.register_mob("draconis:fire_dragon", {
	-- Stats
	max_health = 1000,
	max_hunger = 500,
	max_breath = 600,
	fire_resistance = 1,
	armor_groups = {fleshy = 50},
	damage = 20,
	turn_rate = 2,
	speed = 24,
	tracking_range = 128,
	-- Entity Physics
	stepheight = 2.51,
	max_fall = 0,
	-- Visuals
	mesh = "draconis_fire_dragon.b3d",
	hitbox = {
		width = 2.5,
		height = 5
	},
	visual_size = {x = 20, y = 20},
	glow = 12,
	backface_culling = false,
	use_texture_alpha = false,
	textures = {
		"draconis_fire_dragon_" .. colors[1] .. ".png^draconis_baked_in_shading.png",
		"draconis_fire_dragon_" .. colors[2] .. ".png^draconis_baked_in_shading.png",
		"draconis_fire_dragon_" .. colors[3] .. ".png^draconis_baked_in_shading.png",
		"draconis_fire_dragon_" .. colors[4] .. ".png^draconis_baked_in_shading.png",
		"draconis_fire_dragon_" .. colors[5] .. ".png^draconis_baked_in_shading.png"
	},
	child_textures = {
		"draconis_fire_dragon_" .. colors[1] .. ".png^draconis_baked_in_shading.png",
		"draconis_fire_dragon_" .. colors[2] .. ".png^draconis_baked_in_shading.png",
		"draconis_fire_dragon_" .. colors[3] .. ".png^draconis_baked_in_shading.png",
		"draconis_fire_dragon_" .. colors[4] .. ".png^draconis_baked_in_shading.png",
		"draconis_fire_dragon_" .. colors[5] .. ".png^draconis_baked_in_shading.png"
	},
	animations = {
		stand = {range = {x = 1, y = 59}, speed = 20, frame_blend = 0.3, loop = true},
		stand_fire = {range = {x = 61, y = 119}, speed = 20, frame_blend = 0.3, loop = true},
		slam = {range = {x = 121, y = 159}, speed = 30, frame_blend = 0.3, loop = false},
		repel = {range = {x = 161, y = 209}, speed = 30, frame_blend = 0.3, loop = false},
		walk = {range = {x = 211, y = 249}, speed = 40, frame_blend = 0.3, loop = true},
		walk_slow = {range = {x = 211, y = 249}, speed = 20, frame_blend = 0.3, loop = true},
		walk_fire = {range = {x = 251, y = 289}, speed = 30, frame_blend = 0.3, loop = true},
		takeoff = {range = {x = 291, y = 319}, speed = 30, frame_blend = 0.3, loop = false},
		hover = {range = {x = 321, y = 359}, speed = 30, frame_blend = 0.3, loop = true},
		hover_fire = {range = {x = 361, y = 399}, speed = 30, frame_blend = 0.3, loop = true},
		fly = {range = {x = 401, y = 439}, speed = 30, frame_blend = 0.3, loop = true},
		fly_fire = {range = {x = 441, y = 479}, speed = 30, frame_blend = 0.3, loop = true},
		land = {range = {x = 481, y = 509}, speed = 30, frame_blend = 0.3, loop = false},
		sleep = {range = {x = 511, y = 569}, speed = 30, frame_blend = 1, prty = 2, loop = true},
		death = {range = {x = 571, y = 579}, speed = 30, frame_blend = 5, prty = 3, loop = false},
		shoulder_idle = {range = {x = 581, y = 639}, speed = 30, frame_blend = 0.6, loop = true}
	},
	-- Misc
	sounds = {
		random = {
			name = "draconis_fire_dragon",
			gain = 2,
			distance = 128,
			length = 3.5
		},
		slam = {
			name = "draconis_slam",
			gain = 2,
			distance = 64
		},
		repel = {
			name = "draconis_repel",
			gain = 2,
			distance = 64
		}
	},
	child_sounds = {
		random = {
			{
				name = "draconis_fire_dragon_child_1",
				gain = 1,
				distance = 8,
				length = 1
			},
			{
				name = "draconis_fire_dragon_child_2",
				gain = 1,
				distance = 8,
				length = 2
			}
		}
	},
	drops = {}, -- Set in on_activate
	follow = {
		"group:food_meat"
	},
	dynamic_anim_data = {
		yaw_factor = 0.35,
		swing_factor = -0.2,
		pivot_h = 0.5,
		pivot_v = 0.75,
		tail = {
			{ -- Segment 1
				pos = {
					x = 0,
					y = -0.06,
					z = 0.6
				},
				rot = {
					x = 225,
					y = 180,
					z = 1
				}
			},
			{ -- Segment 2
				pos = {
					x = 0,
					y = 1.45,
					z = 0
				},
				rot = {
					x = 0,
					y = 0,
					z = 1
				}
			},
			{ -- Segment 3
				pos = {
					x = 0,
					y = 1.6,
					z = 0
				},
				rot = {
					x = 0,
					y = 0,
					z = 1
				}
			}
		},
		head = {
			{ -- Segment 1
				pitch_offset = 0,
				bite_angle = -10,
				pitch_factor = 0.11,
				pos = {
					x = 0,
					y = 1.15,
					z = 0
				},
				rot = {
					x = 0,
					y = 0,
					z = 0
				}
			},
			{ -- Segment 2
				pitch_offset = -5,
				bite_angle = 10,
				pitch_factor = 0.11,
				pos = {
					x = 0,
					y = 0.65,
					z = 0
				},
				rot = {
					x = 0,
					y = 0,
					z = 0
				}
			},
			{ -- Head
				pitch_offset = -5,
				bite_angle = 5,
				pitch_factor = 0.22,
				pos = {
					x = 0,
					y = 0.65,
					z = 0.05
				},
				rot = {
					x = 0,
					y = 0,
					z = 0
				}
			}
		},
		jaw = {
			pos = {
				y = 0.15,
				z = -0.29
			}
		}
	},
	-- Function
	breath_attack = draconis.fire_breath,
	utility_stack = draconis.dragon_behavior,
	activate_func = function(self)
		draconis.dragon_activate(self)
	end,
	step_func = function(self, dtime, moveresult)
		draconis.dragon_step(self, dtime, moveresult)
	end,
	on_rightclick = function(self, clicker)
		draconis.dragon_rightclick(self, clicker)
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
		if time_from_last_punch < 0.66
		or (self.passenger and puncher == self.passenger)
		or (self.rider and puncher == self.rider) then return end
		creatura.basic_punch_func(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
		if not self.is_landed then
			self.flight_stamina = self:memorize("flight_stamina", self.flight_stamina - 10)
		end
		self.alert_timer = self:memorize("alert_timer", 15)
	end,
	deactivate_func = function(self)
		if not draconis.dragons[self.dragon_id] then return end
		local owner = draconis.dragons[self.dragon_id].owner
		if not owner then return end
		if not draconis.bonded_dragons then return end
		if draconis.bonded_dragons[owner]
		and is_value_in_table(draconis.bonded_dragons[owner], self.dragon_id) then
			for i = #draconis.bonded_dragons[owner], 1, -1 do
				if draconis.bonded_dragons[owner][i] == self.dragon_id then
					draconis.bonded_dragons[owner][i] = nil
				end
			end
		end
	end,
	death_func = function(self)
		self:clear_action()
		self:clear_utility()
		self:animate("death")
		self:set_gravity(-9.8)
		if self.rider then
			draconis.detach_player(self, self.rider)
		end
		if self.passenger then
			draconis.detach_player(self, self.passenger)
		end
		local rot = self.object:get_rotation()
		if rot.x ~= 0
		or rot.z ~= 0 then
			self.object:set_rotation({x = 0, y = rot.y, z = 0})
		end
	end
})

creatura.register_spawn_item("draconis:fire_dragon", {
	description = "Creative Fire Dragon Egg",
	inventory_image = "draconis_creative_egg_fire.png"
})

local spawn_egg_def = minetest.registered_items["draconis:spawn_fire_dragon"]

spawn_egg_def.on_place = function(itemstack, _, pointed_thing)
	local pos = minetest.get_pointed_thing_position(pointed_thing, true)
	draconis.spawn_dragon(pos, "draconis:fire_dragon", false, 75)
	if not creative then
		itemstack:take_item()
		return itemstack
	end
end

minetest.register_craftitem("draconis:spawn_fire_dragon", spawn_egg_def)
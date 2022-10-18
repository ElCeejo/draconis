-----------------
-- Fire Dragon --
-----------------

local colors = {"amber", "aquamarine", "jade", "ruby"}

creatura.register_mob("draconis:jungle_wyvern", {
	-- Stats
	max_health = 300,
	max_hunger = 200,
	armor_groups = {fleshy = 100},
	damage = 5,
	turn_rate = 6,
	speed = 32,
	tracking_range = 64,
	-- Entity Physics
	stepheight = 1.51,
	max_fall = 0,
	-- Visuals
	mesh = "draconis_jungle_wyvern.b3d",
	hitbox = {
		width = 1.5,
		height = 2
	},
	visual_size = {x = 10, y = 10},
	backface_culling = false,
	use_texture_alpha = false,
	textures = {
		"draconis_jungle_wyvern_" .. colors[1] .. ".png",
		"draconis_jungle_wyvern_" .. colors[2] .. ".png",
		"draconis_jungle_wyvern_" .. colors[3] .. ".png",
		"draconis_jungle_wyvern_" .. colors[4] .. ".png"
	},
	animations = {
		stand = {range = {x = 1, y = 59}, speed = 20, frame_blend = 0.3, loop = true},
		bite = {range = {x = 61, y = 89}, speed = 30, frame_blend = 0.3, loop = false},
		walk = {range = {x = 91, y = 119}, speed = 30, frame_blend = 0.3, loop = true},
		takeoff = {range = {x = 121, y = 149}, speed = 30, frame_blend = 0.3, loop = false},
		hover = {range = {x = 151, y = 179}, speed = 30, frame_blend = 0.3, loop = true},
		fly = {range = {x = 181, y = 209}, speed = 30, frame_blend = 0.3, loop = true},
		dive = {range = {x = 211, y = 239}, speed = 30, frame_blend = 0.3, loop = true},
		fly_punch = {range = {x = 241, y = 279}, speed = 30, frame_blend = 0.3, loop = false},
		land = {range = {x = 281, y = 299}, speed = 30, frame_blend = 1, loop = false}
	},
	-- Misc
	sounds = {
		random = {
			name = "draconis_jungle_wyvern",
			gain = 1,
			distance = 64,
			length = 1
		},
		bite = {
			name = "draconis_jungle_wyvern_bite",
			gain = 1,
			distance = 64,
			length = 1
		}
	},
	drops = {}, -- Set in on_activate
	follow = {
		"group:food_meat"
	},
	dynamic_anim_data = {
		yaw_factor = 0.35,
		swing_factor = -0.4,
		pivot_h = 0.5,
		pivot_v = 0.75,
		tail = {
			{ -- Segment 1
				pos = {
					x = 0,
					y = -0.06,
					z = 0.75
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
					y = 1.25,
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
					y = 0.85,
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
				y = 0,
				z = -0.25
			}
		}
	},
	-- Function
	utility_stack = draconis.wyvern_behavior,
	activate_func = function(self)
		draconis.wyvern_activate(self)
	end,
	step_func = function(self, dtime)
		draconis.wyvern_step(self, dtime)
	end,
	death_func = function(self)
		if self:get_utility() ~= "draconis:die" then
			self:initiate_utility("draconis:die", self)
		end
	end,
	on_rightclick = function(self, clicker)
		draconis.wyvern_rightclick(self, clicker)
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
		if draconis.wyverns[self.object] then
			draconis.wyverns[self.object] = nil
		end
	end
})

creatura.register_spawn_item("draconis:jungle_wyvern", {
	description = "Creative Jungle Wyvern Egg",
	inventory_image = "draconis_creative_egg_jungle.png"
})

local biomes = {}

minetest.register_on_mods_loaded(function()
	for name, def in ipairs(minetest.registered_biomes) do
		if name:find("jungle")
		or name:find("rainforest")
		and (def.y_max or 1) > 0 then
			table.insert(biomes, name)
		end
	end
end)

local spawn_rate = tonumber(minetest.settings:get("wyvern_jungle_spawn_rate")) or 16

creatura.register_mob_spawn("draconis:jungle_wyvern", {
	chance = spawn_rate,
	min_group = 1,
	max_group = 2,
	biomes = biomes,
	nodes = {"group:leaves"}
})
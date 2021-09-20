------------------
-- Draconis API --
------------------
----- Ver 1.1 ----

local l_time = 0
local l_N = 2048
local l_samples = {}
local l_ctr = 0
local l_sumsq = 0
local l_sum = 0
local l_max = 0.1
draconis.global_lag = 0

----------
-- Math --
----------

local pi = math.pi
local random = math.random
local abs = math.abs
local min = math.min
local max = math.max
local floor = math.floor
local ceil = math.ceil
local deg = math.deg
local atan2 = math.atan2
local sin = math.sin
local cos = math.cos
local function R(x) -- Round to nearest multiple of 0.5
	return x + 0.5 - (x + 0.5) % 1
end
local function diff(a, b) -- Get difference between 2 angles
    return atan2(sin(b - a), cos(b - a))
end

local vec_dir = vector.direction
local vec_dist = vector.distance
local vec_new = vector.new
local vec_sub = vector.subtract
local vec_add = vector.add

local dir2yaw = minetest.dir_to_yaw
local yaw2dir = minetest.yaw_to_dir

local function clamp(n)
    if n < -180 then
        n = n + 360
    elseif n > 180 then
        n = n - 360
    end
    if n < -60 then
        n = -60
    elseif n > 60 then
        n = 60
    end
    return n
end

local function interp(a, b, w)
    if abs(a - b) > deg(pi) then
        if a < b then
            return ((a + (b - a) * w) + (deg(pi) * 2))
        elseif a > b then
            return ((a + (b - a) * w) - (deg(pi) * 2))
        end
    end
    return a + (b - a) * w
end

-----------------
-- Lag Tracker --
-----------------

minetest.register_globalstep(function() -- Lag tracker, originally by Orwell
	local news = os.clock() - l_time
	if l_time == 0 then
		news = 0.1
	end
	l_time = os.clock()

	local olds = l_samples[l_ctr+1] or 0
	l_sumsq = l_sumsq - olds*olds + news*news
	l_sum = l_sum - olds + news

	l_samples[l_ctr+1] = news
	l_max = max(l_max, news)

	l_ctr = (l_ctr + 1) % l_N

	if l_ctr == 0 then
		l_sumsq = 0
		l_sum = 0
		l_max = 0
		for i= 1, l_N do
			local sample = l_samples[i]
			l_sumsq = l_sumsq + sample*sample
			l_sum = l_sum + sample
			l_max = max(l_max, sample)
		end
	end
    draconis.global_lag = l_sumsq / l_sum
end)

--------------
-- Settings --
--------------

local creative = minetest.settings:get_bool("creative_mode")

local terrain_destruction = minetest.settings:get_bool("terrain_destruction", true)

local unique_color_chance = tonumber(minetest.settings:get("unique_color_chance")) or 65

----------------------
-- Helper Functions --
----------------------

local str_find = string.find

local hitbox = mob_core.get_hitbox

function draconis.calc_forceload(pos, radius)
    local minpos = vector.subtract(pos, vector.new(radius, radius, radius))
    local maxpos = vector.add(pos, vector.new(radius, radius, radius))
    local minbpos = {}
    local maxbpos = {}
    for _, coord in ipairs({"x", "y", "z"}) do
        minbpos[coord] = floor(minpos[coord] / 16) * 16
        maxbpos[coord] = floor(maxpos[coord] / 16) * 16
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

function draconis.forceload(pos, radius)
    radius = radius or 2
    local fl = draconis.calc_forceload(pos, radius)
    for i = 1, #fl do
        if minetest.forceload_block(fl[i], true) then
            --minetest.log("action", "[Draconis 1.0] Forceloaded 4x4x4 area around "..minetest.pos_to_string(pos))
            minetest.after(4, minetest.forceload_free_block, fl[i], true)
            return true
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

function draconis.load_dragon(id)
    if not draconis.dragons[id] then
        return false
    end
    local info = draconis.dragons[id]
    for _ = 1, 10 do -- 10 attempts
        draconis.forceload(info.last_pos)
    end
    for _, ent in pairs(minetest.luaentities) do
        if ent.dragon_id
        and ent.dragon_id == id then
            return true, ent.object
        end
    end
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

local function get_collision_in_radius(pos, width, height)
    local pos1 = vector.new(pos.x - width, pos.y, pos.z - width)
    local pos2 = vector.new(pos.x + width, pos.y + height, pos.z + width)
    local collisions = {}
    for z = pos1.z, pos2.z do
        for y = pos1.y, pos2.y do
            for x = pos1.x, pos2.x do
                local npos = vector.new(x, y, z)
                local name = minetest.get_node(npos).name
                if minetest.registered_nodes[name].walkable then
                    table.insert(collisions, npos)
                end
            end
        end
    end
    return collisions
end

local moveable = mob_core.is_moveable

function draconis.get_collision_avoidance_pos(self)
    local width = hitbox(self)[4]
    local pos = self.object:get_pos()
    local yaw = self.object:get_yaw()
    local outset = width * 2
    local ahead = vector.add(pos, vector.multiply(minetest.yaw_to_dir(yaw), outset))
    local can_fit = moveable(ahead, width, self.height)
    if not can_fit then
        local collisions = get_collision_in_radius(ahead, width, self.height)
        local obstacle = find_closest_pos(collisions, pos)
        if obstacle then
            local avoidance_path = vector.normalize((vector.subtract(pos, obstacle)))
            local avoidance_pos = vector.add(pos, vector.multiply(avoidance_path, outset))
            local magnitude = (width * 2) - vec_dist(pos, obstacle)
            return avoidance_pos, magnitude
        end
    end
end

function draconis.get_line_of_sight(a, b)
    local steps = floor(vec_dist(a, b))
    local line = {}

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
        for i = 1, #line do
            local node = minetest.get_node(line[i])
            if minetest.registered_nodes[node.name].walkable
            and mobkit.get_node_height(line[i]) >= 4.5 then
                return false
            end
        end
    end
    return true
end

function draconis.get_collision(self, dir, range)
    local pos = self.object:get_pos()
    local pos2 = vector.add(pos, vector.multiply(dir, range or 16))
    local ray = minetest.raycast(pos, pos2, false, false)
    for pointed_thing in ray do
        if pointed_thing.type == "node" then
            return true
        end
    end
    return false
end

function draconis.ray_collision_detect(self)
    for i = 1, 179, 30 do
        local yaw_a = self.object:get_yaw() + math.rad(i)
        local dir_a = minetest.yaw_to_dir(yaw_a)
        local collision_a = draconis.get_collision(self, dir_a, hitbox(self)[4] + 4)
        if collision_a then
            local yaw_b = self.object:get_yaw() + math.rad(-i)
            local dir_b = minetest.yaw_to_dir(yaw_b)
            local collision_b = draconis.get_collision(self, dir_b, hitbox(self)[4] + 4)
            if not collision_b then
                return yaw_b
            end
        else
            return yaw_a
        end
    end
end

------------------
-- Registration --
------------------

function draconis.register_dragon(type, def)
    local colors = def.colors
    minetest.register_entity("draconis:" .. type .. "_dragon", {
        -- Stats
        max_hp = 650,
        armor_groups = {fleshy = 45},
        view_range = 64,
        reach = 12,
        damage = 20,
        knockback = 4,
        lung_capacity = 60,
        floor_avoidance_range = 32,
        -- Movement & Physics
        max_speed = 16,
        stepheight = 1.76,
        jump_height = 1.26,
        max_fall = 100,
        buoyancy = 1,
        springiness = 0,
        turn_rate = 4,
        -- Visual
        collisionbox = {-2.45, 0, -2.45, 2.45, 5, 2.45},
        visual_size = {x = 35, y = 35},
        visual = "mesh",
        mesh = "draconis_" .. type .. "_dragon.b3d",
        textures = {
            "draconis_" .. type .. "_dragon_" .. colors[1] .. ".png^draconis_" .. type .. "_dragon_head_detail.png",
            "draconis_" .. type .. "_dragon_" .. colors[2] .. ".png^draconis_" .. type .. "_dragon_head_detail.png",
            "draconis_" .. type .. "_dragon_" .. colors[3] .. ".png^draconis_" .. type .. "_dragon_head_detail.png",
            "draconis_" .. type .. "_dragon_" .. colors[4] .. ".png^draconis_" .. type .. "_dragon_head_detail.png",
            "draconis_" .. type .. "_dragon_" .. colors[5] .. ".png^draconis_" .. type .. "_dragon_head_detail.png"
        },
        child_textures = {
            "draconis_" .. type .. "_dragon_" .. colors[1] .. ".png",
            "draconis_" .. type .. "_dragon_" .. colors[2] .. ".png",
            "draconis_" .. type .. "_dragon_" .. colors[3] .. ".png",
            "draconis_" .. type .. "_dragon_" .. colors[4] .. ".png",
            "draconis_" .. type .. "_dragon_" .. colors[5] .. ".png"
        },
        animation = {
            stand = {range = {x = 1, y = 60}, speed = 15, frame_blend = 0.3, loop = true},
            stand_fire = {range = {x = 70, y = 130}, speed = 15, frame_blend = 0.3, loop = true},
            wing_flap = {range = {x = 140, y = 200}, speed = 15, frame_blend = 0.3, loop = false},
            walk = {range = {x = 210, y = 250}, speed = 35, frame_blend = 0.3, loop = true},
            walk_fire = {range = {x = 260, y = 300}, speed = 35, frame_blend = 0.3, loop = true},
            takeoff = {range = {x = 310, y = 330}, speed = 25, frame_blend = 0.3, loop = false},
            fly_idle = {range = {x = 340, y = 380}, speed = 25, frame_blend = 0.3, loop = true},
            fly_idle_fire = {range = {x = 390, y = 430}, speed = 25, frame_blend = 0.3, loop = true},
            fly = {range = {x = 440, y = 480}, speed = 25, frame_blend = 0.3, loop = true},
            fly_fire = {range = {x = 490, y = 530}, speed = 25, frame_blend = 0.3, loop = true},
            dive_bomb = {range = {x = 540, y = 580}, speed = 25, frame_blend = 0.3, loop = true},
            sleep = {range = {x = 590, y = 660}, speed = 5, frame_blend = 1, prty = 2, loop = true},
            death = {range = {x = 670, y = 670}, speed = 1, frame_blend = 2, prty = 3, loop = true},
            shoulder_idle = {range = {x = 680, y = 740}, speed = 10, frame_blend = 0.6, loop = true}
        },
        dynamic_anim_data = {
            yaw_factor = 0.11,
            swing_factor = 0.33,
            pivot_h = 0.5,
            pivot_v = 0.75,
            tail = {
                { -- Segment 1
                    pos = {
                        x = 0,
                        y = 0,
                        z = 0
                    },
                    rot = {
                        x = 180,
                        y = 180,
                        z = 1
                    }
                },
                { -- Segment 2
                    pos = {
                        x = 0,
                        y = 0.7,
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
                        y = 1,
                        z = 0
                    },
                    rot = {
                        x = 0,
                        y = 0,
                        z = 1
                    }
                },
                { -- Segment 4
                    pos = {
                        x = 0,
                        y = 1,
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
                    pitch_offset = 20,
                    bite_angle = -20,
                    pitch_factor = 0.22,
                    pos = {
                        x = 0,
                        y = 0.83,
                        z = 0.036
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
                    pitch_factor = 0.22,
                    pos = {
                        x = 0,
                        y = 0.45,
                        z = 0
                    },
                    rot = {
                        x = 0,
                        y = 0,
                        z = 0
                    }
                },
                { -- Segment 3
                    pitch_offset = -5,
                    bite_angle = 10,
                    pitch_factor = 0.22,
                    pos = {
                        x = 0,
                        y = 0.45,
                        z = 0
                    },
                    rot = {
                        x = 0,
                        y = 0,
                        z = 0
                    }
                },
                { -- Head
                    pitch_offset = -20,
                    bite_angle = 5,
                    pitch_factor = 0.44,
                    pos = {
                        x = 0,
                        y = 0.41,
                        z = 0
                    },
                    rot = {
                        x = 0,
                        y = 0,
                        z = 0
                    }
                }
            }
        },
        -- Sound
        child_sounds = {
            random = {
                {
                    name = "draconis_" .. type .. "_dragon_child_1",
                    gain = 1,
                    distance = 16,
                    length = 1
                },
                {
                    name = "draconis_" .. type .. "_dragon_child_2",
                    gain = 1,
                    distance = 16,
                    length = 1
                }
            },
            hurt = {
                {
                    name = "draconis_" .. type .. "_dragon_child_1",
                    gain = 1,
                    distance = 16,
                    length = 1
                },
            },
            flap = ""
        },
        teen_sounds = {
            random = {
                {
                    name = "draconis_" .. type .. "_dragon_teen_random_1",
                    gain = 1,
                    distance = 32,
                    length = 1
                },
                {
                    name = "draconis_" .. type .. "_dragon_teen_random_2",
                    gain = 1,
                    distance = 32,
                    length = 1
                },
                {
                    name = "draconis_" .. type .. "_dragon_teen_roar",
                    gain = 1,
                    distance = 64,
                    length = 2.5
                }
            },
            hurt = {
                {
                    name = "draconis_" .. type .. "_dragon_hurt",
                    gain = 1,
                    distance = 16
                },
                {
                    name = "draconis_" .. type .. "_dragon_hurt",
                    gain = 1,
                    pitch = 0.5,
                    distance = 16
                },
                {
                    name = "draconis_" .. type .. "_dragon_hurt",
                    gain = 1,
                    pitch = 0.25,
                    distance = 16
                },
            },
            flap = {
                name = "draconis_flap",
                gain = 0.5,
                distance = 512
            }
        },
        adult_sounds = {
            random = {
                {
                    name = "draconis_" .. type .. "_dragon_adult_1",
                    gain = 1,
                    distance = 32,
                    length = 2
                },
                {
                    name = "draconis_" .. type .. "_dragon_adult_2",
                    gain = 1,
                    distance = 32,
                    length = 3.5
                },
                {
                    name = "draconis_" .. type .. "_dragon_adult_3",
                    gain = 1,
                    distance = 32,
                    length = 4
                }
            },
            hurt = {
                {
                    name = "draconis_" .. type .. "_dragon_hurt",
                    gain = 1.5,
                    distance = 32
                },
                {
                    name = "draconis_" .. type .. "_dragon_hurt",
                    gain = 1.5,
                    pitch = 0.75,
                    distance = 32
                },
                {
                    name = "draconis_" .. type .. "_dragon_hurt",
                    gain = 1.5,
                    pitch = 0.5,
                    distance = 32
                },
            },
            flap = {
                name = "draconis_flap",
                gain = 1,
                distance = 512
            }
        },
        sounds = {},
        -- Basic
        physical = true,
        collide_with_objects = false,
        static_save = true,
        defend_owner = true,
        push_on_collide = true,
        punch_cooldown = 0.25,
        max_hunger = 325,
        colors = colors,
        follow = draconis.global_meat,
        timeout = 0,
        open_jaw = draconis.open_jaw,
        move_head = draconis.move_head,
        move_tail = draconis.move_tail,
        physics = draconis.physics,
        logic = def.logic,
        get_staticdata = mobkit.statfunc,
        on_activate = draconis.on_activate,
        on_step = draconis.on_step,
        on_deactivate = draconis.reattach,
        on_rightclick = function(self, clicker)
            if self.hp <= 0 then
                local pos = self.object:get_pos()
                mob_core.item_drop(self)
                minetest.add_particlespawner({
                    amount = 64 * self.growth_scale,
                    time = 0.25,
                    minpos = {x = pos.x - (16 * self.growth_scale), y = pos.y - 2, z = pos.z - (16 * self.growth_scale)},
                    maxpos = {x = pos.x + (16 * self.growth_scale), y = pos.y + (16 * self.growth_scale), z = pos.z + (16 * self.growth_scale)},
                    minacc = {x = 0, y = 0.5, z = 0},
                    maxacc = {x = 0, y = 0.25, z = 0},
                    minvel = {x = math.random(-3, 3), y = 0.25, z = math.random(-3, 3)},
                    maxvel = {x = math.random(-5, 5), y = 0.25, z = math.random(-5, 5)},
                    minexptime = 2,
                    maxexptime = 3,
                    minsize = 4,
                    maxsize = 4,
                    texture = "draconis_smoke_particle.png",
                    animation = {
                        type = 'vertical_frames',
                        aspect_w = 4,
                        aspect_h = 4,
                        length = 1,
                    },
                    glow = 1
                })
                self.object:remove()
                return
            end
            if self.driver then return end
            local item = clicker:get_wielded_item()
            local name = clicker:get_player_name()
            if draconis.feed(self, clicker, 64 * self.growth_scale) then
                return
            end
            if not self.owner
            or name ~= self.owner then return end
            mob_core.protect(self, clicker, true)
            if item:get_name() == "" then
                if clicker:get_player_control().sneak == true then
                    draconis.formspec(self, clicker)
                    return
                elseif self.age >= 50 and self.owner == name then
                    draconis.mount(self, clicker)
                    return
                elseif self.age <= 4 and self.owner == name then
                    mobkit.clear_queue_low(self)
                    mobkit.clear_queue_high(self)
                    self.object:set_properties({
                        physical = false,
                        collide_with_objects = false
                    })
                    self.shoulder_mounted = mobkit.remember(self, "shoulder_mounted", true)
                    self.object:set_attach(clicker, "", {x = 3 - self.growth_scale, y = 11.5,z = -1.5 - (self.growth_scale * 5)}, {x=0,y=0,z=0})
                    return
                end
            end
            if item:get_name() == "draconis:growth_essence_" .. type then
                draconis.increase_age(self)
                if not creative then
                    item:take_item()
                    clicker:set_wielded_item(item)
                end
            end
            mob_core.nametag(self, clicker)
        end,
        on_punch = function(self, puncher, _, tool_capabilities, dir)
            if self.driver and puncher == minetest.get_player_by_name(self.driver) then return end
            self.idle_timer = mobkit.remember(self, "idle_timer", 0)
            mob_core.on_punch_basic(self, puncher, tool_capabilities, dir)
            if self.status == "sleeping" then
                self.status = mobkit.remember(self, "status", "")
            end
            if not self.tamed
            or (self.stance == "neutral"
            and (not puncher:is_player()
            or puncher:get_player_name() ~= self.owner)) then
                if self.isonground then
                    draconis.hq_landed_attack(self, 7, puncher)
                else
                    draconis.hq_aerial_attack(self, 7, puncher)
                end
            end
        end
    })
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
    timer = 10,
    on_activate = function(self)
        self.object:set_armor_groups({immortal = 1})
    end,
    on_step = function(self, dtime)
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
            self.timer = self.timer - dtime
            if self.timer <= 0 then
                parent:get_luaentity().in_ice_cube = nil
                self.object:remove()
            end
        else
            self.object:remove()
        end
    end
})

local function set_eyes(self, ent, color)
    local eyes = minetest.add_entity(self.object:get_pos(), ent)
    if eyes then
        eyes:set_attach(self.object, "Head", {x = 0, y = -0.975, z = -2.5}, {x = 69, y = 0, z = 180})
        eyes:get_luaentity().color = color
        return eyes
    end
end

-----------------------
-- Dynamic Animation --
-----------------------

function draconis.head_tracking(self)
    local yaw = self.object:get_yaw()
    if self.driver then return end
    if self.status == "sleeping"
    or self.hp <= 0 then
        self:move_head(yaw)
        return
    end
    local pos = mobkit.get_stand_pos(self)
    local v = vector.add(pos, vector.multiply(yaw2dir(yaw), 8 * self.growth_scale))
    local head_height = 6 * self.growth_scale
    if self._anim == "fly_idle"
    or self._anim == "fly_idle_fire" then
        head_height = 11 * self.growth_scale
    end
    pos.x = v.x
    pos.y = pos.y + head_height
    pos.z = v.z
    if not self.head_tracking then
        local objects = minetest.get_objects_inside_radius(pos, 16)
        for _, object in ipairs(objects) do
            if object:is_player() then
                local dir_2_plyr = vector.direction(pos, object:get_pos())
                local yaw_2_plyr = dir2yaw(dir_2_plyr)
                if abs(yaw - yaw_2_plyr) < 1
                or abs(yaw - yaw_2_plyr) > 5.3 then
                    self.head_tracking = object
                end
                break
            end
        end
        if self._anim == "stand" then
            self:move_head(yaw)
        else
            self:move_head(self._tyaw)
        end
    else
        if not mobkit.exists(self.head_tracking) then
            self.head_tracking = nil
            return
        end
        local ppos = self.head_tracking:get_pos()
        ppos.y = ppos.y + 1.4
        local dir = vector.direction(pos, ppos)
        local tyaw = minetest.dir_to_yaw(dir)
        if abs(yaw - tyaw) > 1
        and abs(yaw - tyaw) < 5.3 then
            self.head_tracking = nil
            dir.y = 0
            return
        end
        self:move_head(tyaw, dir.y)
    end
end

-----------------
-- On Activate --
-----------------

function draconis.set_drops(self)
    local name = self.name:split(":")[2]
    if self.mapgen_spawn then
        self.drops_level = mobkit.remember(self, "drops_level", 5)
    elseif self.drops_level ~= self.growth_stage then
        self.drops_level = mobkit.remember(self, "drops_level", self.growth_stage)
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
        if self.gender == "female"
        and minetest.settings:get_bool("simple_spawning") then
            self.drops = {
                {name = "draconis:blood_".. name, chance = 32, min = 4, max = 8},
                {name = "draconis:scales_".. name .. "_" .. self.color, chance = 1, min = 6, max = 24},
                {name = "draconis:dragon_bone", chance = 1, min = 6, max = 18},
                {
                    name = "draconis:egg_" .. name .. "_" ..
                        self.colors[random(1, 5)],
                    chance = 1,
                    min = 1,
                    max = 1
                },
                {
                    name = "draconis:egg_" .. name .. "_" ..
                        self.colors[random(1, 5)],
                    chance = 8,
                    min = 1,
                    max = 1
                }
            }
        end
    end
    if self.drops_level == 5 then
        if self.gender == "male" then
            self.drops = {
                {name = "draconis:blood_".. name, chance = 8, min = 4, max = 8},
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
                        self.colors[random(1, 5)],
                    chance = 1,
                    min = 1,
                    max = 1
                }, {
                    name = "draconis:egg_" .. name .. "_" ..
                        self.colors[random(1, 5)],
                    chance = 8,
                    min = 1,
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

local fire_dragon_mutations = {
    black = {
        "ff1f0033", -- Red
        "ff6d0033" -- Orange
    },
    bronze = {
        "f6c35c80", -- Yellow
        "ff30304d", -- Red
    },
    gold = {
        "fff1c3s73", -- Cream
        "ea65234d" -- Orange
    },
    green = {
        "ffdf6566", -- Yellow
        "ea65234d" -- Orange
    },
    red = {
        "f6c35c4d", -- Yellow
        "ff6d0033" -- Orange
    }
}

function draconis.set_secondary_color(self, pallete)
    if mobkit.recall(self, "mutation") then
        local mutation = mobkit.recall(self, "mutation")
        local texture = self.object:get_properties().textures[1]
        self.object:set_properties({
            textures = {texture .. "^" .. mutation}
        })
    else
        local color = pallete[random(#pallete)]
        local overlay = "(draconis_dragon_alt_color_layout.png^[colorize:#"..color..")"
        if random(100) > unique_color_chance then
            overlay = "transparency.png"
        end
        local texture = self.object:get_properties().textures[1]
        self.object:set_properties({
            textures = {texture .. "^" .. overlay}
        })
        mobkit.remember(self, "mutation", overlay)
    end
end

function draconis.on_activate(self, staticdata, dtime_s)
    mob_core.on_activate(self, staticdata, dtime_s)
    draconis.set_color_string(self)
    self.dragon_id = mobkit.recall(self, "dragon_id") or 1
    if self.dragon_id == 1 then
        local random_id = draconis.random_id()
        while mob_core.find_val(draconis.dragons, random_id) do -- Prevents multiple dragons with the same ID
            random_id = draconis.random_id()
        end
        self.dragon_id = mobkit.remember(self, "dragon_id", random_id)
    end
    while not self.eyes do
        if self.name == "draconis:ice_dragon" then
            self.eye_color = mobkit.recall(self, "eye_color") or nil
            if not self.eye_color then
                local colors = {
                    "blue",
                    "purple"
                }
                self.eye_color = mobkit.remember(self, "eye_color", colors[random(#colors)])
            end
            self.eyes = set_eyes(self, "draconis:ice_eyes", self.eye_color or "blue")
        elseif self.name == "draconis:fire_dragon" then
            self.eye_color = mobkit.recall(self, "eye_color") or nil
            if not self.eye_color then
                local colors = {
                    "red",
                    "orange",
                    "green"
                }
                self.eye_color = mobkit.remember(self, "eye_color", colors[random(#colors)])
            end
            self.eyes = set_eyes(self, "draconis:fire_eyes", self.eye_color or "orange")
        end
    end
    self.driver = mobkit.recall(self, "driver") or nil
    if self.driver
    and minetest.get_player_by_name(self.driver) then
        local driver = minetest.get_player_by_name(self.driver)
        draconis.attach(self, driver)
    end
    self.logic_state = mobkit.recall(self, "logic_state") or "landed"
    self.flight_timer = mobkit.recall(self, "flight_timer") or 1
    self.age = mobkit.recall(self, "age") or 100
    self.growth_scale = mobkit.recall(self, "growth_scale") or 1
    self._growth_timer = mobkit.recall(self, "_growth_timer") or 1200
    self.time_from_last_sound = 0
    self.drops_level = mobkit.recall(self, "drops_level") or 0
    self.breath_meter = mobkit.recall(self, "breath_meter") or 300
    self.breath_meter_max = mobkit.recall(self, "breath_meter_max") or 300
    self.breath_meter_bottomed = mobkit.recall(self, "breath_meter_bottomed") or false
    self.mapgen_spawn = mobkit.recall(self, "mapgen_spawn") or nil
    self.order = mobkit.recall(self, "order") or "wander"
    self.fly_allowed = mobkit.recall(self, "fly_allowed") or false
    self.stance = mobkit.recall(self, "stance") or "neutral"
    self.hunger = mobkit.recall(self, "hunger") or self.max_hunger / 2
    self.idle_timer = mobkit.recall(self, "idle_timer") or 0
    self.target_blacklist = {}
    self.fall_distance = 0
    self.flap_sound_timer = 1.5
    self.flap_sound_played = false
    self.roar_anim_length = 0
    self.anim_frame = 0
    self.frame_offset = 0
    self.shoulder_mounted = false
    if self.age <= 25 then
        table.insert_all(self.sounds, self.child_sounds)
    elseif self.age <= 50 then
        table.insert_all(self.sounds, self.teen_sounds)
    elseif self.age <= 75 then
        table.insert_all(self.sounds, self.adult_sounds)
    end
    draconis.set_color_string(self)
    mob_core.set_scale(self, self.growth_scale)
    draconis.set_drops(self)
    if self.name == "draconis:fire_dragon" then
        draconis.set_secondary_color(self, fire_dragon_mutations[self.color])
    elseif self.name == "draconis:ice_dragon" then
        draconis.set_secondary_color(self, {
            "9881e333",
            "e0fffe33"
        })
    end
    if self.dynamic_anim_data then
        local data = self.dynamic_anim_data
        if data.tail then
            draconis.move_tail(self)
        end
    end
    self.dtime = 0.1
    self:move_head(self.object:get_yaw())
    draconis.growth(self)
    draconis.dragons[self.dragon_id] = {owner = self.owner, last_pos = self.object:get_pos()}
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
        if self.frame_offset > 30
        and not self.flap_sound_played then
            minetest.sound_play("draconis_flap", {
                object = self.object,
                gain = 1.0,
                max_hear_distance = 128,
                loop = false,
            })
            self.flap_sound_played = true
        elseif self.frame_offset < 10 then
            self.flap_sound_played = false
        end
    end
end

function draconis.increase_age(self)
    self.age = mobkit.remember(self, "age", self.age + 1)
    if self.age < 150
    or (self.age > 150
    and self.growth_scale < 1.5) then -- second check ensures pre-1.2 dragons grow to new limit
        self.growth_scale = mobkit.remember(self, "growth_scale",
                                            self.growth_scale + 0.0099)
        mob_core.set_scale(self, self.growth_scale)
        draconis.set_drops(self)
        if self.age <= 25 then
            self.growth_stage = 1
            self.sounds = self.child_sounds
        elseif self.age <= 50 then
            draconis.set_adult_textures(self)
            self.child = mobkit.remember(self, "child", false)
            self.growth_stage = 2
            self.sounds = self.juvi_sounds
        elseif self.age <= 75 then
            draconis.set_adult_textures(self)
            self.growth_stage = 3
            self.sounds = self.adult_sounds
        elseif self.age <= 100 then
            draconis.set_adult_textures(self)
            self.growth_stage = 4
        end
    end
end

function draconis.set_adult_textures(self)
    local texture = self.object:get_properties().textures[1]
    local adult_overlay = "draconis_fire_dragon_head_detail.png"
    if self.name == "draconis:ice_dragon" then
        adult_overlay = "draconis_ice_dragon_head_detail.png"
    end
    self.object:set_properties({
        textures = {texture .. "^" .. adult_overlay}
    })
end

function draconis.growth(self)
    self._growth_timer = self._growth_timer - 1
    if self._growth_timer <= 0 then
        draconis.increase_age(self)
        self._growth_timer = self._growth_timer + 1200
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
    self.breath_meter_max = mobkit.remember(self, "breath_meter_max", self.age * 3)
    if self.breath_meter > self.breath_meter_max then
        self.breath_meter = self.breath_meter_max
    end
    if self.breath_meter_bottomed
    and self.breath_meter > self.breath_meter_max * 0.33 then
        self.breath_meter_bottomed = mobkit.remember(self, "breath_meter_bottomed", false)
    end
    if self.breath_meter < self.breath_meter_max then
        self.breath_meter = self.breath_meter + 1
    end
    mobkit.remember(self, "breath_meter", self.breath_meter)
end

function draconis.hunger(self)
    if not self.tamed then self.hunger = self.max_hunger return end
    if self.hunger > self.max_hunger then self.hunger = self.max_hunger return end
    local hunger = self.hunger
    if mobkit.timer(self, 900) then self.hunger = self.hunger - 1 end
    if self.hunger < self.max_hunger / 3 then
        if mobkit.timer(self, 3) then
            mobkit.hurt(self, 1)
        end
    end
    if hunger ~= self.hunger then
        mobkit.remember(self, "hunger", self.hunger)
    end
end

function draconis.on_step(self, dtime, moveresult)
    if self._anim then
        local aparms = self.animation[self._anim]
        if self.anim_frame ~= -1 then
            self.anim_frame = self.anim_frame + dtime
            self.frame_offset = floor(self.anim_frame * aparms.speed)
            if self.frame_offset > aparms.range.y - aparms.range.x then
                self.anim_frame = 0
                self.frame_offset = 0
            end
        end
    end
    self.turn_rate = 6 - (self.growth_scale * 1.5)
    mob_core.on_step(self, dtime, moveresult)
    if not mobkit.is_alive(self) then return end
    local pos = self.object:get_pos()
    if self.owner
    and pos then
        draconis.dragons[self.dragon_id] = {owner = self.owner, last_pos = pos}
    end
    if not self.eyes:get_yaw() then
        if self.name == "draconis:ice_dragon" then
            self.eyes = set_eyes(self, "draconis:ice_eyes")
        elseif self.name == "draconis:fire_dragon" then
            self.eyes = set_eyes(self, "draconis:fire_eyes")
        end
    end
    draconis.hunger(self) -- Hunger
    if mobkit.timer(self, 1) then
        draconis.growth(self) -- Gradual Growth
        self.time_from_last_sound = self.time_from_last_sound + 1
        if self.time_in_horn then
            self._growth_timer = self._growth_timer - self.time_in_horn / 2
            self.time_in_horn = nil
        end
    end
    if mobkit.timer(self, 5) then
        draconis.breath_cooldown(self) -- Increase Breath Meter if empty
        if #self.target_blacklist > 0 then
            table.remove(self.target_blacklist, 1)
        end
    end
    if self.isonground or self.isinliquid then
        self.max_speed = 12
    else
        self.max_speed = 24
    end
    draconis.flap_sound(self)
    if self.isonground 
    and (self.object:get_rotation().x ~= 0
    or self.object:get_rotation().z ~= 0) then
        self.object:set_yaw(self.object:get_yaw())
    end
    draconis.head_tracking(self)
    self:open_jaw()
    if self.dynamic_anim_data then
        local data = self.dynamic_anim_data
        if data.tail then
            draconis.move_tail(self)
        end
    end
end

-----------------------------
-- Tamed Dragon Management --
-----------------------------

local function set_order(self, player, order)
    if order == "stand" then
        if self.isinliquid then return end
        mobkit.clear_queue_high(self)
        mobkit.clear_queue_low(self)
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
        self.status = "stand"
        self.order = "stand"
        draconis.animate(self, "stand")
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
        draconis.hq_follow(self, 5, player)
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
        local frame_range = self.animation["fly"].range
        local frame_loop = frame_range.x .. "," ..  frame_range.y
        local eye_overlay
        if self.name == "draconis:ice_dragon" then
            eye_overlay = "draconis_ice_eyes_"..self.eye_color..".png"
            if self.child then
                eye_overlay = "draconis_ice_eyes_child_"..self.eye_color..".png"
            end
        elseif self.name == "draconis:fire_dragon" then
            eye_overlay = "draconis_fire_eyes_"..self.eye_color..".png"
            if self.child then
                eye_overlay = "draconis_fire_eyes_child_"..self.eye_color..".png"
            end
        end

        local texture = self.object:get_properties().textures[1] .. "^" .. eye_overlay
        local formspec = {
            "formspec_version[3]", "size[10.75,10.5]",
            "label[4.75,0.5;",
            draconis.string_format(self.name), "]",
            "model[0.5,0;9,4;mob_mesh;", self.mesh, ";", texture, ";-10,-130;false;false;", frame_loop, "]",
            "label[4,3.5;", name, "]",
            "label[4,3.8;", "Health: " .. health, "]",
            "label[4,4.1;", "Age: " .. self.age, "]",
            "label[4,4.4;", "Hunger: " .. hunger, "]",
            "label[4,4.7;", "Gender: " .. draconis.string_format(self.gender), "]",
            "label[4,5;", "Owner: " .. (self.owner or ""), "]",
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
    luaent.growth_scale = mobkit.remember(luaent, "growth_scale", 0.03)
    luaent.growth_stage = mobkit.remember(luaent, "growth_stage", 1)
    luaent.texture_no = color_no
    if owner ~= "" then mob_core.set_owner(luaent, owner) end
    mob_core.set_scale(luaent, luaent.growth_scale)
    mob_core.set_textures(luaent)
    if mob == "draconis:fire_dragon" then
        draconis.set_secondary_color(luaent, fire_dragon_mutations[luaent.color])
    else
        draconis.set_secondary_color(luaent, {
            "9881e333",
            "e0fffe33"
        })
    end
end

local function spawn_dragon(pos, mob, mapgen, age)
    if not pos then return false end
    local dragon = minetest.add_entity(pos, mob)
    if dragon then
        local ent = dragon:get_luaentity()
        ent._mem = mobkit.remember(ent, "_mem", true)
        ent.age = mobkit.remember(ent, "age", age)
        ent.growth_scale = mobkit.remember(ent, "growth_scale", age * 0.01)
        ent.mapgen_spawn = mobkit.remember(ent, "mapgen_spawn", mapgen)
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
        if random(3) < 2 then
            ent.gender = mobkit.remember(ent, "gender", "male")
        else
            ent.gender = mobkit.remember(ent, "gender", "female")
        end
        mob_core.set_scale(ent, ent.growth_scale)
        mob_core.set_textures(ent)
        draconis.set_drops(ent)
    end
end

function draconis.spawn_dragon(pos, mob, mapgen, age)
    minetest.forceload_block(pos, false)
    minetest.after(4, function()
        spawn_dragon(pos, mob, mapgen, age)
        minetest.after(0.01, function()
            local loop = true
            local objects = minetest.get_objects_inside_radius(pos, 0.5)
            for i = 1, #objects do
                local object = objects[i]
                if object
                and object:get_luaentity()
                and object:get_luaentity().name == mob then
                    loop = false
                end
            end
            minetest.after(1, function()
                minetest.forceload_free_block(pos)
            end)
            if loop then
                draconis.spawn_dragon(pos, mob, mapgen, age)
            end 
        end)
    end)
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
        collisionbox = {-0.15, 0, -0.15, 0.15, 0.5, 0.15},
        visual_size = {x = 10, y = 10},
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
        get_staticdata = function(self)
            mobkit.statfunc(self)
        end,
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
            elseif self.color == "gold" or self.color == "silver" then
                self.tex_no = 5
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
                    if not self.hatching then
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
                    if not self.hatching then
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

-----------------
-- Pathfinding --
-----------------

function draconis.adjust_pos(self, pos2)
    local width = hitbox(self)[4] + 2
    local can_fit = moveable(pos2, width, self.height)
    if not can_fit then
        local minp = vector.new(pos2.x - width, pos2.y - 1, pos2.z - width)
        local maxp = vector.new(pos2.x + width, pos2.y + 1, pos2.z + width)
        for z = minp.z, maxp.z do
            for y = minp.y, maxp.y do
                for x = minp.x, maxp.x do
                    local npos = vector.new(x, y, z)
                    local under = vector.new(npos.x, npos.y - 1, npos.z)
                    local is_walkable =
                        minetest.registered_nodes[minetest.get_node(under).name]
                            .walkable
                    if can_fit and is_walkable then
                        return npos
                    end
                end
            end
        end
    end
    return pos2
end

-------------
-- Mob API --
-------------

function draconis.is_stuck(self)
    if not mobkit.is_alive(self) then return end
    if not self.moveresult then return end
    local moveresult = self.moveresult
    if self.height < 1 then return false end
    for _, collision in ipairs(moveresult.collisions) do
        if collision.type == "node" then
            local pos = mobkit.get_stand_pos(self)
            local node_pos = collision.node_pos
            local yaw = self.object:get_yaw()
            local yaw_to_node = minetest.dir_to_yaw(vec_dir(pos, node_pos))
            if node_pos.y >= pos.y + 1
            and abs(diff(yaw, yaw_to_node)) <= 1.5 then
                local node = minetest.get_node(node_pos)
                if minetest.registered_nodes[node.name].walkable then
                    return true
                end
            end
        end
    end
    return false
end

function draconis.play_sound(self, sound)
    if self.time_from_last_sound < 6 then return end
    local sounds = self.adult_sounds
    if self.age < 50 then
        sounds = self.teen_sounds
    end
    if self.age < 15 then
        sounds = self.child_sounds
    end
    local params = sounds[sound]
	local param_table = {object = self.object}

	if #params > 0 then
        params = params[random(#params)]
    end

	param_table.gain = params.gain
	param_table.pitch = (params.pitch or 1) + (random(-5, 5) * 0.01)
    self.roar_anim_length = params.length
    self.time_from_last_sound = 0
    self.jaw_init = true
	return minetest.sound_play(params.name, param_table)
end

function draconis.handle_sounds(self)
    if self._anim
    and self._anim:find("fire") then
        return
    end
    local time_from_last_sound = self.time_from_last_sound
    if time_from_last_sound > 6 then
        local r = random(ceil(16 * self.growth_scale))
        if r < 2 then
            draconis.play_sound(self, "random")
        end
    end
end

function draconis.animate(self, anim)
	if self.animation and self.animation[anim] then
		if self._anim == anim then return end
        local old_anim = nil
        if self._anim then
            old_anim = self._anim
        end
		self._anim = anim

        local old_prty = 1
        if old_anim
        and self.animation[old_anim].prty then
            old_prty = self.animation[old_anim].prty
        end
        local prty = 1
        if self.animation[anim].prty then
            prty = self.animation[anim].prty
        end

		local aparms
		if #self.animation[anim] > 0 then
			aparms = self.animation[anim][random(#self.animation[anim])]
		else
			aparms = self.animation[anim]
		end

        aparms.frame_blend = aparms.frame_blend or 0
        if old_prty > prty then
            aparms.frame_blend = self.animation[old_anim].frame_blend or 0
        end

        self.anim_frame = -aparms.frame_blend
        self.frame_offset = 0

		self.object:set_animation(aparms.range, aparms.speed, aparms.frame_blend, aparms.loop)
	else
		self._anim = nil
	end
end

function draconis.get_head_pos(self, pos2)
    local pos = self.object:get_pos()
    pos.y = pos.y + 6 * self.growth_scale
    local yaw = self.object:get_yaw()
    local dir = vector.direction(pos, pos2)
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
    return vector.add(pos, vector.multiply(minetest.yaw_to_dir(head_yaw), (7 - abs(yaw_diff)) * self.growth_scale)), dir
end

local get_head_pos = draconis.get_head_pos

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
            pos = draconis.get_head_pos(self, self.object:get_pos())
            local minppos = vector.add(pos, 1 * self.growth_scale)
            local maxppos = vector.subtract(pos, 1 * self.growth_scale)
            local def = minetest.registered_items[item:get_name()]
            local texture = def.inventory_image
            if not texture or texture == "" then
                texture = def.wield_image
            end
            minetest.add_particlespawner({
                amount = 25 * self.growth_scale,
                time = 0.1,
                minpos = minppos,
                maxpos = maxppos,
                minvel = {x=-1, y=1, z=-1},
                maxvel = {x=1, y=2, z=1},
                minacc = {x=0, y=-5, z=0},
                maxacc = {x=0, y=-9, z=0},
                minexptime = 1,
                maxexptime = 1,
                minsize = 4 * self.growth_scale,
                maxsize = 6 * self.growth_scale,
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

-- Dynamic Animation --

local function clamp_bone_rot(n) -- Fixes issues with bones jittering when yaw clamps
    if n < -180 then
        n = n + 360
    elseif n > 180 then
        n = n - 360
    end
    if n < -60 then
        n = -60
    elseif n > 60 then
        n = 60
    end
    return n
end

local function interp_bone_rot(a, b, w) -- Smoothens bone movement
    local pi = math.pi
    if math.abs(a - b) > math.deg(pi) then
        if a < b then
            return ((a + (b - a) * w) + (math.deg(pi) * 2))
        elseif a > b then
            return ((a + (b - a) * w) - (math.deg(pi) * 2)) 
        end
    end
    return a + (b - a) * w
end

function draconis.open_jaw(self)
    if not self._anim then return end
    if draconis.global_lag >= 3.5 then
        self.object:set_bone_position("Jaw.CTRL", {x=0,y=0.455,z=-0.255}, {x=0,y=0,z=0})
        return
    end
    if self.jaw_init then
        if self._anim:find("fire") then
            self.jaw_init = false
            self.roar_anim_length = 0
            return
        end
        local _, rot = self.object:get_bone_position("Jaw.CTRL")
        local b_rot = interp_bone_rot(rot.x, -45, 0.2)
        self.object:set_bone_position("Jaw.CTRL", {x=0,y=0.455,z=-0.255}, {x=b_rot,y=0,z=0})
        self.roar_anim_length = self.roar_anim_length - self.dtime
        if floor(rot.x) == -45
        and self.roar_anim_length <= 0 then
            self.jaw_init = false
            self.roar_anim_length = 0
        end
    else
        local _, rot = self.object:get_bone_position("Jaw.CTRL")
        local b_rot = interp_bone_rot(rot.x, 0, self.dtime * 3)
        self.object:set_bone_position("Jaw.CTRL", {x=0,y=0.455,z=-0.255}, {x=b_rot,y=0,z=0})
    end
end

function draconis.move_tail(self)
    local tyaw = self._tyaw
    if self._anim == "stand"
    or self._anim == "stand_fire"
    or self._anim == "fly_idle"
    or self._anim == "fly_idle_fire" then
        tyaw = self.object:get_yaw()
    end
    local yaw = self.object:get_yaw()
    for seg = 1, #self.dynamic_anim_data.tail do
        local data = self.dynamic_anim_data.tail[seg]
        local _, rot = self.object:get_bone_position("Tail.".. seg .. ".CTRL")
        rot = rot.z
        local tgt_rot = clamp_bone_rot(-math.deg(yaw - tyaw)) * self.dynamic_anim_data.swing_factor
        local new_rot = 0
        if self.dtime then
            new_rot = interp_bone_rot(rot, tgt_rot, self.dtime * 1.5)
        end
        self.object:set_bone_position("Tail.".. seg .. ".CTRL", data.pos, {x = data.rot.x, y = data.rot.y, z = new_rot * data.rot.z})
    end
end

function draconis.move_head(self, tyaw, pitch)
    local yaw = self.object:get_yaw()
    for seg = 1, #self.dynamic_anim_data.head do
        local seg_no = #self.dynamic_anim_data.head
        local data = self.dynamic_anim_data.head[seg]
        local bone_name = "Neck.".. seg .. ".CTRL"
        if seg == seg_no then
            bone_name = "Head.CTRL"
        end
        local _, rot = self.object:get_bone_position(bone_name)
        local look_yaw = clamp_bone_rot(math.deg(yaw - tyaw))
        local look_pitch = data.rot.x
        if pitch then
            look_pitch = clamp_bone_rot(math.deg(pitch)) * data.pitch_factor
        end
        if tyaw ~= yaw then
            look_yaw = look_yaw * self.dynamic_anim_data.yaw_factor
        end
        local bone_yaw = look_yaw
        local bone_pitch = look_pitch + (data.pitch_offset or 0)
        if self.jaw_init
        and data.bite_angle then
            look_pitch = look_pitch + data.bite_angle
        end
        if self.dtime then
            bone_yaw = interp_bone_rot(rot.z, look_yaw, self.dtime * 1.5)
            bone_pitch = interp_bone_rot(rot.x, look_pitch + (data.pitch_offset or 0), self.dtime * 1.5)
        end
        self.object:set_bone_position(bone_name, data.pos, {x = bone_pitch, y = data.rot.y, z = bone_yaw})
    end
end

-- Dragon Breath --

local function scorch_nodes(pos, radius)
    if not terrain_destruction then return end
    local h_stride = random(-radius, radius)
    local v_stride = random(-radius, math.ceil(radius * 0.5))
    local npos = {
        x = pos.x + h_stride,
        y = pos.y + v_stride,
        z = pos.z + h_stride
    }
    if minetest.is_protected(npos, "") then
        return
    end
    local name = minetest.get_node(npos).name
    if name
    and name ~= "air"
    and name ~= "ignore" then
        if minetest.get_item_group(minetest.get_node(vector.new(npos.x, npos.y - 1, npos.z)).name, "snowy") > 0 then
            minetest.set_node(npos, {name = "air"})
        elseif minetest.get_item_group(name, "stone") > 0 then
            minetest.set_node(npos, {name = "draconis:scorched_stone"})
        elseif minetest.get_item_group(name, "soil") > 0 then
            minetest.set_node(npos, {name = "draconis:scorched_soil"})
        elseif minetest.get_item_group(name, "tree") > 0 then
            minetest.set_node(npos, {name = "draconis:scorched_tree"})
        elseif minetest.get_item_group(name, "flora") > 0
        or minetest.get_item_group(name, "leaves") > 0 then
            minetest.set_node(npos, {name = "air"})
        end
        if draconis.find_value_in_table(draconis.walkable_nodes, name) then
            local above = vector.new(npos.x, npos.y + 1, npos.z)
            if minetest.get_node(above).name == "air" then
                minetest.set_node(above, {name = "fire:basic_flame"})
            end
        end
    end
end

local function freeze_nodes(pos, radius)
    if not terrain_destruction then return end
    local h_stride = random(-radius, radius)
    local v_stride = random(-radius, math.ceil(radius * 0.5))
    local npos = {
        x = pos.x + h_stride,
        y = pos.y + v_stride,
        z = pos.z + h_stride
    }
    if minetest.is_protected(npos, "") then
        return
    end
    local name = minetest.get_node(npos).name
    if name
    and name ~= "air"
    and name ~= "ignore" then
        if minetest.get_item_group(name, "stone") > 0 then
            minetest.set_node(npos, {name = "draconis:frozen_stone"})
        elseif minetest.get_item_group(name, "soil") > 0 then
            minetest.set_node(npos, {name = "draconis:frozen_soil"})
        elseif minetest.get_item_group(name, "tree") > 0 then
            minetest.set_node(npos, {name = "draconis:frozen_tree"})
        elseif minetest.get_item_group(name, "flora") > 0
        or minetest.get_item_group(name, "leaves") > 0
        or (minetest.registered_nodes[name].groups
        and minetest.registered_nodes[name].groups.fire) then
            minetest.set_node(npos, {name = "air"})
        end
        local above = vector.new(npos.x, npos.y + 1, npos.z)
        if str_find(name, "water")
        and (str_find(name, "source")
        or str_find(name, "flowing"))
        and minetest.get_node(above).name == "air" then
            minetest.set_node(npos, {name = "default:ice"})
        end
    end
end

local function breath_sound(self, sound)
    if not self.breath_timer then self.breath_timer = 0.1 end
    self.breath_timer = self.breath_timer - self.dtime
    if self.breath_timer <= 0 then
        self.breath_timer = 2
        minetest.sound_play(sound,{
            object = self.object,
            gain = 1.0,
            max_hear_distance = 64,
            loop = false,
        })
    end
end

local function fuel_forge(pos, forge_name)
    local minpos = vector.new(pos.x - 3, pos.y - 3, pos.z - 3)
    local maxpos = vector.new(pos.x + 3, pos.y + 3, pos.z + 3)
    for z = minpos.z, maxpos.z do
        for y = minpos.y, maxpos.y do
            for x = minpos.x, maxpos.x do
                local npos = vector.new(x, y, z)
                local name = minetest.get_node(npos).name
                local on_fired = minetest.registered_nodes[forge_name].on_fired
                if name then
                    if name == forge_name then
                        on_fired(npos)
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function get_line(pos1, pos2)
    local steps = floor(vec_dist(pos1, pos2))
    local line = {}

    for i = 0, steps do
        local pos

        if steps > 0 then
            pos = {
                x = pos1.x + (pos2.x - pos1.x) * (i / steps),
                y = pos1.y + (pos2.y - pos1.y) * (i / steps),
                z = pos1.z + (pos2.z - pos1.z) * (i / steps)
            }
        else
            pos = pos1
        end
        table.insert(line, pos)
    end
    table.sort(line, function(a, b) return vec_dist(a, pos2) > vec_dist(b, pos2) end)
    if #line < 1 then
        return nil
    else
        local halt = nil
        for i = #line, 1, -1 do
            local node = minetest.get_node(line[i])
            if minetest.registered_nodes[node.name].walkable
            and mobkit.get_node_height(line[i]) > 4.5 then
                if not halt then
                    halt = i
                    table.remove(line, i)
                elseif i > halt then
                    table.remove(line, i)
                end
            end
        end
    end
    return line, vec_dist(pos1, line[#line])
end

local function is_driver(self, player)
    if player:is_player()
    and self.driver
    and minetest.get_player_by_name(self.driver)
    and player == minetest.get_player_by_name(self.driver) then
        return true
    end
    return false
end

local flame_colors = {
    black = "000000e6",
    bronze = "a77f5a80",
    green = "157a0080",
    red = "ff000080",
    gold = "ffb00080"
}

local world_breath_timer = 0.4

local world_particle_timer = 0.1

function draconis.fire_breath(self, goal, range)
    if self.breath_meter_bottomed then return end
    breath_sound(self, "draconis_fire_breath")
    local pos
    local dir
    pos, dir = get_head_pos(self, goal)
    dir.y = vec_dir(pos, goal).y
    pos.y = pos.y + self.object:get_rotation().x
    local dest = vector.add(pos, vector.multiply(dir, range))
    local path, length = get_line(pos, dest)
    if mobkit.timer(self, 0.5) then
        self.breath_meter = mobkit.remember(self, "breath_meter", self.breath_meter - 1)
    end
    if self.breath_meter <= 1 then
        self.breath_meter_bottomed = mobkit.remember(self, "breath_meter_bottomed", true)
    end
    if world_particle_timer <= 0 then
        minetest.add_particlespawner({
            amount = 3,
            time = 0.25,
            minpos = vector.add(path[1], vector.multiply(self.object:get_velocity(), 0.22)),
            maxpos = vector.add(path[1], vector.multiply(self.object:get_velocity(), 0.22)),
            minvel = vector.multiply(dir, 32),
            maxvel = vector.multiply(dir, 48),
            minacc = {x = -4, y = -4, z = -4},
            maxacc = {x = 4, y = 4, z = 4},
            minexptime = 0.02 * length,
            maxexptime = 0.04 * length,
            minsize = 16 * self.growth_scale,
            maxsize = 24 * self.growth_scale,
            collisiondetection = false,
            vertical = false,
            glow = 16,
            texture = "fire_basic_flame.png^[colorize:#".. flame_colors[self.color]
        })
        world_particle_timer = 0.1
    end
    if world_breath_timer <= 0 then
        if #path > 9 then
            for i = 1, #path, 9 do
                local objects = minetest.get_objects_inside_radius(path[i], 9)
                for _, object in ipairs(objects) do
                    if object
                    and object ~= self.object
                    and not is_driver(self, object) then
                        if (object:get_armor_groups().fleshy
                        or (object:get_luaentity()
                        and object:get_luaentity().name:match("^petz:")))
                        and not mobkit.is_in_deep(object) then
                            object:punch(self.object, 1, {
                                full_punch_interval = 0.1,
                                damage_groups = {fleshy = 12 * self.growth_scale}
                            }, nil)
                        end
                    end
                end
            end
        else
            local objects = minetest.get_objects_inside_radius(path[#path], 9)
            for _, object in ipairs(objects) do
                if object
                and object ~= self.object
                and not is_driver(self, object) then
                    if (object:get_armor_groups().fleshy
                    or (object:get_luaentity()
                    and object:get_luaentity().name:match("^petz:")))
                    and not mobkit.is_in_deep(object) then
                        object:punch(self.object, 1, {
                            full_punch_interval = 0.1,
                            damage_groups = {fleshy = 12 * self.growth_scale}
                        }, nil)
                    end
                end
            end
        end
        world_breath_timer = 0.4
    end
    local forging = fuel_forge(path[#path], "draconis:draconic_steel_forge_fire")
    if not forging then
        local scale_factor = ceil(4 * clamp(self.growth_scale, 0.25, 1.5))
        if scale_factor < #path then
            for i = 1, #path, ceil(#path / scale_factor) do
                scorch_nodes(path[i], scale_factor)
                if minetest.get_modpath("tnt")
                and self.age >= 100
                and terrain_destruction then
                    if random(1, #path * 32) == 1 then
                        tnt.boom(path[i], {radius = 2})
                    end
                end
            end
        else
            scorch_nodes(path[#path], scale_factor)
            if minetest.get_modpath("tnt")
            and self.age >= 100
            and terrain_destruction then
                if random(1, #path * 32) == 1 then
                    tnt.boom(path[#path], {radius = 2})
                end
            end
        end
    else
        minetest.chat_send_all("bruh")
    end
    world_breath_timer = world_breath_timer - self.dtime
    world_particle_timer = world_particle_timer - self.dtime
end

function draconis.ice_breath(self, goal, range)
    if self.breath_meter_bottomed then return end
    breath_sound(self, "draconis_ice_breath")
    local pos
    local dir
    pos, dir = get_head_pos(self, goal)
    dir.y = vec_dir(pos, goal).y
    pos.y = pos.y + self.object:get_rotation().x
    local dest = vector.add(pos, vector.multiply(dir, range))
    local path, length = get_line(pos, dest)
    if mobkit.timer(self, 0.5) then
        self.breath_meter = self.breath_meter - 1
    end
    mobkit.remember(self, "breath_meter", self.breath_meter)
    if self.breath_meter <= 1 then
        self.breath_meter_bottomed = mobkit.remember(self, "breath_meter_bottomed", true)
    end
    if world_particle_timer <= 0 then
        minetest.add_particlespawner({
            amount = 3,
            time = 1,
            minpos = vector.add(path[1], vector.multiply(self.object:get_velocity(), 0.22)),
            maxpos = vector.add(path[1], vector.multiply(self.object:get_velocity(), 0.22)),
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
        world_particle_timer = 0.1
    end
    if world_breath_timer <= 0 then
        if #path > 9 then
            for i = 1, #path, 9 do
                local objects = minetest.get_objects_inside_radius(path[i], 9)
                for _, object in ipairs(objects) do
                    if object
                    and object ~= self.object
                    and not is_driver(self, object) then
                        if (object:get_armor_groups().fleshy
                        or (object:get_luaentity()
                        and object:get_luaentity().name:match("^petz:")))
                        and not mobkit.is_in_deep(object) then
                            object:punch(self.object, 1, {
                                full_punch_interval = 0.1,
                                damage_groups = {fleshy = 12 * self.growth_scale}
                            }, nil)
                        end
                    end
                end
            end
        else
            local objects = minetest.get_objects_inside_radius(path[#path], 9)
            for _, object in ipairs(objects) do
                if object
                and object ~= self.object
                and not is_driver(self, object) then
                    if (object:get_armor_groups().fleshy
                    or (object:get_luaentity()
                    and object:get_luaentity().name:match("^petz:")))
                    and not mobkit.is_in_deep(object) then
                        object:punch(self.object, 1, {
                            full_punch_interval = 0.1,
                            damage_groups = {fleshy = 12 * self.growth_scale}
                        }, nil)
                    end
                end
            end
        end
        world_breath_timer = 0.4
    end
    local forging = fuel_forge(path[#path], "draconis:draconic_steel_forge_ice")
    if not forging then
        local scale_factor = ceil(4 * clamp(self.growth_scale, 0.25, 1.5))
        if scale_factor < #path then
            for i = 1, #path, ceil(#path / scale_factor) do
                freeze_nodes(path[i], scale_factor)
                if minetest.get_modpath("tnt")
                and self.age >= 100
                and terrain_destruction then
                    if random(1, #path * 32) == 1 then
                        tnt.boom(path[i], {radius = 2})
                    end
                end
            end
        else
            freeze_nodes(path[#path], scale_factor)
            if minetest.get_modpath("tnt")
            and self.age >= 100
            and terrain_destruction then
                if random(1, #path * 32) == 1 then
                    tnt.boom(path[#path], {radius = 2})
                end
            end
        end
    end
    world_breath_timer = world_breath_timer - self.dtime
    world_particle_timer = world_particle_timer - self.dtime
end
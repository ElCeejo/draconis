---------
-- API --
---------

-- Math --

local pi = math.pi
local abs = math.abs
local min = math.min
local random = math.random
local ceil = math.ceil
local floor = math.floor
local atan2 = math.atan2
local sin = math.sin
local cos = math.cos
local function diff(a, b) -- Get difference between 2 angles
    return atan2(sin(b - a), cos(b - a))
end
local function lerp(a, b, w) -- Linear Interpolation
    if abs(a - b) > pi then
        if a < b then
            return (a + (b - a) * 1) + (pi * 2)
        elseif a > b then
            return (a + (b - a) * 1) - (pi * 2)
        end
    end
    return a + (b - a) * w
end
local function clamp(val, _min, _max)
	if val < _min then
		val = _min
	elseif _max < val then
		val = _max
	end
	return val
end

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
    if math.abs(a - b) > math.deg(pi) then
        if a < b then
            return ((a + (b - a) * w) + (math.deg(pi) * 2))
        elseif a > b then
            return ((a + (b - a) * w) - (math.deg(pi) * 2))
        end
    end
    return a + (b - a) * w
end

-- Vector Math --

local vec_dir = vector.direction
local vec_dist = vector.distance
local vec_sub = vector.subtract
local vec_add = vector.add
local vec_multi = vector.multiply
local vec_normal = vector.normalize
local function vec_center(v)
    return {x = floor(v.x + 0.5), y = floor(v.y + 0.5), z = floor(v.z + 0.5)}
end

local dir2yaw = minetest.dir_to_yaw
local yaw2dir = minetest.yaw_to_dir

local function vec_cross(a, b)
    return {
        x = a.y * b.z - a.z * b.y,
        y = a.z * b.x - a.x * b.z,
        z = a.x * b.y - a.y * b.x
    }
end

--------------
-- Settings --
--------------

local creative = minetest.settings:get_bool("creative_mode")

local terrain_destruction = minetest.settings:get_bool("terrain_destruction") or false

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

local function is_node_walkable(pos)
    local name = minetest.get_node(pos).name
    if not name then return false end
    local def = minetest.registered_nodes[name]
    return def and def.walkable
end

local function get_line(a, b)
    local steps = ceil(vec_dist(a, b))
    local line = {}

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
        if is_node_walkable(pos) then
            break
        end
        if #line < 1
        or vec_dist(pos, line[#line]) > 3 then
            table.insert(line, pos)
        end
    end
    return line or {a}
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
        if is_node_walkable(pos) then
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
local flame_texture

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
    flame_texture = minetest.registered_nodes[flame_node].inventory_image
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
    pos.y = pos.y + 6 * self.growth_scale
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
    return vec_add(pos, vec_multi(minetest.yaw_to_dir(head_yaw), (7 - abs(yaw_diff)) * self.growth_scale)), dir
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
    if self.object:get_properties().textures[1]:find("wing_fade") and not force then return end
    textures[1] = textures[1] .. "^" .. self.wing_overlay
    self:set_texture(1, textures)
end

function draconis.activate(self)
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
    self._path = {}
    self.alert_timer = self:recall("alert_timer") or 15
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
            if vector.equals(vec_center(global_data.removal_queue[i]), vec_center(self.object:get_pos())) then
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

function draconis.head_tracking(self)
    local yaw = self.object:get_yaw()
    if self.driver then return end
    if self.status == "sleeping"
    or self.hp <= 0 then
        self:move_head(yaw)
        return
    end
    local pos = self.object:get_pos()
    local v = vec_add(pos, vec_multi(yaw2dir(yaw), 8 * self.growth_scale))
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
                local dir_2_plyr = vec_dir(pos, object:get_pos())
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
        if not creatura.is_valid(self.head_tracking) then
            self.head_tracking = nil
            return
        end
        local ppos = self.head_tracking:get_pos()
        ppos.y = ppos.y + 1.4
        local dir = vec_dir(pos, ppos)
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

------------
-- Breath --
------------

local last_breath_tick = minetest.get_us_time()
local last_damage_tick = minetest.get_us_time()

local function damage_objects(self, pos, radius)
    local objects = minetest.get_objects_inside_radius(pos, radius)
    for i = 1, #objects do
        local object = objects[i]
        if object ~= self.object then
            local deal_damage = object:is_player()
            if object:get_luaentity() then
                local ent = object:get_luaentity()
                local is_mobkit = (ent.logic ~= nil or ent.brainfuc ~= nil)
                local is_creatura = ent._creatura_mob
                if is_mobkit
                or is_creatura
                or ent._cmi_is_mob then
                    deal_damage = true
                end
            end
            if deal_damage then
                self:punch_target(object)
            end
        end
    end
end

local function freeze_nodes(pos, radius)
    local start_time = minetest.get_us_time()
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
    for z = pos1.z, pos2.z do
        for y = pos1.y, pos2.y do
            for x = pos1.x, pos2.x do
                local current_time = minetest.get_us_time()
                if current_time - start_time > 750 then return end
                local noise = random(5)
                if noise < 2 then
                    local npos = {
                        x = x,
                        y = y,
                        z = z
                    }
                    if minetest.is_protected(npos, "") then
                        return
                    end
                    local name = minetest.get_node(npos).name
                    if name
                    and name ~= "air"
                    and name ~= "ignore" then
                        local convert_to = frozen_conversions[name]
                        if convert_to
                        and (convert_to ~= draconis.global_nodes["ice"]
                        or minetest.get_node({x = x, y = y + 1, z = z}).name == "air") then
                            minetest.set_node(npos, {name = convert_to})
                        end
                    end
                end
            end
        end
    end
end

local function scorch_nodes(pos, radius)
    local start_time = minetest.get_us_time()
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
    for z = pos1.z, pos2.z do
        for y = pos1.y, pos2.y do
            for x = pos1.x, pos2.x do
                local current_time = minetest.get_us_time()
                if current_time - start_time > 750 then return end
                local noise = random(5)
                if noise < 2 then
                    local npos = {
                        x = x,
                        y = y,
                        z = z
                    }
                    if minetest.is_protected(npos, "") then
                        return
                    end
                    local name = minetest.get_node(npos).name
                    if name
                    and name ~= "air"
                    and name ~= "ignore" then
                        local convert_to = scorched_conversions[name]
                        if convert_to then
                            minetest.set_node(npos, {name = convert_to})
                        end
                        if is_node_walkable(npos) then
                            local above = {x = npos.x, y = npos.y + 1, z = npos.z}
                            if not is_node_walkable(above) then
                                minetest.set_node(above, {name = flame_node})
                            end
                        end
                    end
                end
            end
        end
    end
end

local function do_forge(pos, node)
    local forge = minetest.find_nodes_in_area(vec_sub(pos, 2), vec_add(pos, 2), node)
    if forge[1] then
        local func = minetest.registered_nodes[node].on_breath
        func(forge[1])
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
    local dest = vec_add(pos, vec_multi(dir, 32))
    local nodes = get_line(pos, dest)
    if #nodes < 1 then return end
    local us = minetest.get_us_time()
    local breath_tick = (us - last_breath_tick) / 100000
    if breath_tick > 0.25 then
        last_breath_tick = minetest.get_us_time()
        minetest.add_particlespawner({
            amount = 3,
            time = 0.25,
            minpos = vec_add(nodes[1], vec_multi(self.object:get_velocity(), 0.22)),
            maxpos = vec_add(nodes[1], vec_multi(self.object:get_velocity(), 0.22)),
            minvel = vec_multi(dir, 32),
            maxvel = vec_multi(dir, 48),
            minacc = {x = -4, y = -4, z = -4},
            maxacc = {x = 4, y = 4, z = 4},
            minexptime = 0.02 * 32,
            maxexptime = 0.04 * 32,
            minsize = 16 * self.growth_scale,
            maxsize = 24 * self.growth_scale,
            collisiondetection = false,
            vertical = false,
            glow = 16,
            texture = flame_texture
        })
        us = minetest.get_us_time()
        local damage_tick = (us - last_damage_tick) / 100000
        for i = 1, #nodes do
            scorch_nodes(nodes[i], 2.5)
            if damage_tick > 0.5 then
                damage_objects(self, nodes[i], 8, 8)
            end
        end
        do_forge(nodes[#nodes], "draconis:draconic_forge_fire")
        last_damage_tick = minetest.get_us_time()
    end
    self.attack_stamina = self.attack_stamina - self.dtime * 2
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
    local dest = vec_add(pos, vec_multi(dir, 32))
    local nodes = get_line(pos, dest)
    if #nodes < 1 then return end
    local us = minetest.get_us_time()
    local breath_tick = (us - last_breath_tick) / 100000
    if breath_tick > 0.25 then
        last_breath_tick = minetest.get_us_time()
        minetest.add_particlespawner({
            amount = 4,
            time = 0.25,
            minpos = vec_add(nodes[1], vec_multi(self.object:get_velocity(), 0.22)),
            maxpos = vec_add(nodes[1], vec_multi(self.object:get_velocity(), 0.22)),
            minvel = vec_multi(dir, 32),
            maxvel = vec_multi(dir, 48),
            minacc = {x = -4, y = -4, z = -4},
            maxacc = {x = 4, y = 4, z = 4},
            minexptime = 0.02 * 32,
            maxexptime = 0.04 * 32,
            minsize = 6 * self.growth_scale,
            maxsize = 12 * self.growth_scale,
            collisiondetection = false,
            vertical = false,
            glow = 16,
            texture = "draconis_ice_particle_" .. random(1, 3) .. ".png"
        })
        us = minetest.get_us_time()
        local damage_tick = (us - last_damage_tick) / 100000
        for i = 1, #nodes do
            freeze_nodes(nodes[i], 2.5)
            if damage_tick > 0.5 then
                damage_objects(self, nodes[i], 8, 8)
            end
        end
        do_forge(nodes[#nodes], "draconis:draconic_forge_ice")
        last_damage_tick = minetest.get_us_time()
    end
    self.attack_stamina = self.attack_stamina - self.dtime * 2
    self:memorize("attack_stamina", self.attack_stamina)
end

---------------
-- Formspecs --
---------------

local dragon_form_obj = {}

local function get_dragon_formspec(self)
    -- Stats
    local current_age = self.age or 100
    local health = self.hp / math.ceil(self.max_health * self.growth_scale) * 100
    local hunger = self.hunger / math.ceil(self.max_hunger * self.growth_scale) * 100
    local stamina = self.flight_stamina / 900 * 100
    local breath = self.attack_stamina / 100 * 100
    -- Visuals
    local frame_range = self.animations["stand"].range
    local frame_loop = frame_range.x .. "," ..  frame_range.y
    local texture = self.object:get_properties().textures[1]
    local health_ind = "draconis_forms_health_bg.png^[lowpart:" .. health .. ":draconis_forms_health_fg.png"
    local hunger_ind = "draconis_forms_hunger_bg.png^[lowpart:" .. hunger .. ":draconis_forms_hunger_fg.png"
    local stamina_ind = "draconis_forms_stamina_bg.png^[lowpart:" .. stamina .. ":draconis_forms_stamina_fg.png"
    local breath_ind = "draconis_forms_breath_bg.png^[lowpart:" .. breath .. ":draconis_forms_breath_fg.png"
    -- Settings
    local fly_allowed = "Flight Allowed"
    local fly_image = "draconis_forms_flight_allowed.png"
    if not self.fly_allowed then
        fly_allowed = "Flight Not Allowed"
        fly_image = "draconis_forms_flight_disallowed.png"
    end
    local form = {
        "formspec_version[4]",
        "size[16,10]",
        --"no_prepend[]",
        "bgcolor[#000000;false]",
        "background[0,0;16,10;draconis_forms_bg_b.png]",
        "label[6.8,0.8;" .. correct_name(self.name) .. " (" .. correct_name(self.gender) .. ")]",
        "label[7,1.5;" .. current_age .." Days Old]",
        "button[6.75,8.75;2.6,0.5;btn_dragon_name;" .. (self.nametag or "Set Name") .. "]",
        "model[3,1.7;10,7;mob_mesh;" .. self.mesh .. ";" .. texture .. ";-10,-130;false;false;" .. frame_loop .. ";15]",
        "image[1.1,1.3;1,1;" .. health_ind .."]",
        "image[1.1,3.3;1,1;" .. hunger_ind .."]",
        "image[1.1,5.3;1,1;" .. stamina_ind .."]",
        "image[1.1,7.3;1,1;" .. breath_ind .."]",
        "tooltip[13.45,7.6;1.9,1.9;" .. correct_name(self.stance) .. "]",
        "image_button[13.45,7.6;1.9,1.9;draconis_forms_dragon_" .. self.stance .. ".png;btn_dragon_stance;;false;false;]",
        "tooltip[13.45,3.9;1.9,1.9;" .. correct_name(self.order) .. "]",
        "image_button[13.45,3.9;1.9,1.9;draconis_forms_dragon_" .. self.order .. ".png;btn_dragon_order;;false;false;]",
        "tooltip[13.45,0.3;1.9,1.9;" .. fly_allowed .. "]",
        "image_button[13.45,0.3;1.9,1.9;" .. fly_image .. ";btn_dragon_fly;;false;false;]"
    }
    if minetest.check_player_privs(self.owner, {draconis_admin = true}) then
        table.insert(form, "button[9.75,8.75;2.6,0.5;btn_customize;Customize]")
    end
    return table.concat(form, "")
end

local function get_rename_formspec(self)
    local tag = self.nametag or ""
    local form = {
        "size[8,4]",
        "field[0.5,1;7.5,0;name;" .. minetest.formspec_escape("Enter name:") .. ";" .. tag .. "]",
        "button_exit[2.5,3.5;3,1;mob_rename;" .. minetest.formspec_escape("Rename") .. "]"
    }
    return table.concat(form, "")
end

local function get_customize_formspec(self)
    local texture = self.object:get_properties().textures[1]
    local frame_range = self.animations["stand"].range
    local frame_loop = frame_range.x .. "," ..  frame_range.y
    local form
    if self.name == "draconis:fire_dragon" then
        form = {
            "formspec_version[4]",
            "size[12,6]",
            "dropdown[0.5,1.1;3,0.6;drp_wing;Orange,Purple,Red,Yellow;1]",
            "label[1.1,0.8;Wing Color]",
            "dropdown[4.5,1.1;3,0.6;drp_eyes;Orange,Red,Green;1]",
            "label[5.1,0.8;Eye Color]",
            "dropdown[8.5,1.1;3,0.6;drp_body;Black,Bronze,Green,Red,Gold;1]",
            "label[9.1,0.8;Body Color]",
            "model[1.5,1.7;10,7;mob_mesh;" .. self.mesh .. ";" .. texture .. ";-10,-130;false;false;" .. frame_loop .. ";15]"
        }
    elseif self.name == "draconis:ice_dragon" then
        form = {
            "formspec_version[4]",
            "size[12,6]",
            "dropdown[0.5,1.1;3,0.6;drp_wing;Dark Blue,Purple;1]",
            "label[1.1,0.8;Wing Color]",
            "dropdown[4.5,1.1;3,0.6;drp_eyes;Blue,Purple;1]",
            "label[5.1,0.8;Eye Color]",
            "dropdown[8.5,1.1;3,0.6;drp_body;Light Blue,Sapphire,Slate,White,Silver;1]",
            "label[9.1,0.8;Body Color]",
            "model[1.5,1.7;10,7;mob_mesh;" .. self.mesh .. ";" .. texture .. ";-10,-130;false;false;" .. frame_loop .. ";15]"
        }
    end
    return table.concat(form, "")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if not dragon_form_obj[name] then return end
    local ent = dragon_form_obj[name]
    if formname == "draconis:dragon_forms" then
        if fields.btn_dragon_stance then
            if not ent.object then return end
            if ent.stance == "neutral" then
                ent.stance = ent:memorize("stance", "aggressive")
            elseif ent.stance == "aggressive" then
                ent.stance = ent:memorize("stance", "passive")
            elseif ent.stance == "passive" then
                ent.stance = ent:memorize("stance", "neutral")
            end
            ent:show_formspec(player)
        end
        if fields.btn_dragon_order then
            if not ent.object then return end
            if ent.order == "wander" then
                ent.order = ent:memorize("order", "follow")
            elseif ent.order == "follow" then
                ent.order = ent:memorize("order", "stay")
            elseif ent.order == "stay" then
                ent.order = ent:memorize("order", "wander")
            else
                ent.order = ent:memorize("order", "stay")
            end
            ent:show_formspec(player)
        end
        if fields.btn_dragon_fly then
            if not ent.object then return end
            if ent.fly_allowed then
                ent.fly_allowed = ent:memorize("fly_allowed", false)
            else
                ent.fly_allowed = ent:memorize("fly_allowed", true)
            end
            ent:show_formspec(player)
        end
        if fields.btn_dragon_name then
            minetest.show_formspec(name, "draconis:set_name", get_rename_formspec(ent))
        end
        if fields.btn_customize then
            minetest.show_formspec(name, "draconis:customize", get_customize_formspec(ent))
        end
        if fields.quit or fields.key_enter then
            dragon_form_obj[name] = nil
        end
    end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "draconis:set_name" and fields.name then
        local name = player:get_player_name()
        if not dragon_form_obj[name] or not dragon_form_obj[name].object then
            return
        end
        local ent = dragon_form_obj[name]
        if string.len(fields.name) > 64 then
            fields.name = string.sub(fields.name, 1, 64)
        end
        ent.nametag = ent:memorize("nametag", fields.name)
        activate_nametag(dragon_form_obj[name])
        if fields.quit or fields.key_enter then
            dragon_form_obj[name] = nil
        end
    elseif formname == "draconis:customize" then
        local name = player:get_player_name()
        if not dragon_form_obj[name] or not dragon_form_obj[name].object then
            return
        end
        local ent = dragon_form_obj[name]
        local type = "ice"
        if ent.name == "draconis:fire_dragon" then
            type = "fire"
        end
        local wings = {
            ice = {
                ["Dark Blue"] = "#07084f",
                ["Purple"] = "#a724ff"
            },
            fire = {
                ["Red"] = "#d20000",
                ["Orange"] = "#d92e00",
                ["Yellow"] = "#edad00",
                ["Purple"] = "#a724ff"
            }
        }
        local eyes = {
            ice = {
                ["Blue"] = "blue",
                ["Purple"] = "purple"
            },
            fire = {
                ["Red"] = "red",
                ["Orange"] = "orange",
                ["Green"] = "green"
            }
        }
        local body = {
            ice = {
                ["Light Blue"] = 1,
                ["Sapphire"] = 2,
                ["Slate"] = 3,
                ["White"] = 4,
                ["Silver"] = 5
            },
            fire = {
                ["Black"] = 1,
                ["Bronze"] = 2,
                ["Green"] = 3,
                ["Red"] = 4,
                ["Gold"] = 5
            }
        }
        if fields.drp_wing
        and wings[type][fields.drp_wing] then
            ent.wing_overlay = "(draconis_wing_fade.png^[multiply:" .. wings[type][fields.drp_wing] .. ")"
            ent:memorize("wing_overlay", ent.wing_overlay)
            generate_texture(ent, true)
        end
        if fields.drp_eyes
        and eyes[type][fields.drp_eyes] then
            ent.eye_color = eyes[type][fields.drp_eyes]
            ent:memorize("eye_color", ent.eye_color)
        end
        if fields.drp_body
        and body[type][fields.drp_body] then
            ent.texture_no = body[type][fields.drp_body]
            draconis.set_color_string(ent)
            generate_texture(ent, true)
        end
        ent:update_emission(true)
        minetest.show_formspec(name, "draconis:customize", get_customize_formspec(ent))
        if fields.quit or fields.key_enter then
            dragon_form_obj[name] = nil
        end
    end
end)

------------
-- Growth --
------------

local function set_adult_textures(self)
    local texture = self.object:get_properties().textures[1]
    local adult_overlay = "draconis_fire_dragon_head_detail.png"
    if self.name == "draconis:ice_dragon" then
        adult_overlay = "draconis_ice_dragon_head_detail.png"
    end
    self.object:set_properties({
        textures = {texture .. "^" .. adult_overlay}
    })
end

local function increase_age(self)
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
            set_adult_textures(self)
        elseif age <= 50 then
            set_adult_textures(self)
            self.growth_stage = 2
        elseif age <= 75 then
            set_adult_textures(self)
            self.growth_stage = 3
        elseif age <= 100 then
            set_adult_textures(self)
            self.growth_stage = 4
        end
    end
    self:memorize("growth_stage", self.growth_stage)
    self:set_drops()
end

--------------------
-- Initialize API --
--------------------

minetest.register_on_mods_loaded(function()
    -- Misc Methods
    local dragons = {
        "draconis:fire_dragon",
        "draconis:ice_dragon"
    }
    for i = 1, 2 do
        local dragon = dragons[i]
        minetest.registered_entities[dragon].animate = function(self, anim)
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
        end
        minetest.registered_entities[dragon].do_growth = function(self)
            self.growth_timer = self.growth_timer - 1
            if self.growth_timer <= 0 then
                increase_age(self)
                self.growth_timer = self.growth_timer + 1200
            end
            if self.hp > self.max_health * self.growth_scale then
                self.hp = self.max_health * self.growth_scale
            end
            if self.hunger > (self.max_health * 0.5) * self.growth_scale then
                self.hunger = (self.max_health * 0.5) * self.growth_scale
            end
            self:memorize("growth_timer", self.growth_timer)
        end
        minetest.registered_entities[dragon].set_drops = function(self)
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
        end
        minetest.registered_entities[dragon].play_sound = function(self, sound)
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
                self.roar_anim_length = parameters.length or 0
                self.time_from_last_sound = 0
                self.jaw_init = true
                return minetest.sound_play(name, parameters)
            end
            return minetest.sound_play(spec, parameters)
        end
        minetest.registered_entities[dragon].show_formspec = function(self, player)
            minetest.show_formspec(player:get_player_name(), "draconis:dragon_forms", get_dragon_formspec(self))
            dragon_form_obj[player:get_player_name()] = self
        end
        minetest.registered_entities[dragon].destroy_terrain = function(self, moveresult)
            if not terrain_destruction
            or not moveresult
            or not moveresult.collisions then
                return
            end
            local pos = self.object:get_pos()
            for _, collision in pairs(moveresult.collisions) do
                if collision.type == "node" then
                    local n_pos = collision.node_pos
                    if n_pos.y - pos.y >= self.stepheight - 0.5 then
                        local node = minetest.get_node(n_pos)
                        if (minetest.get_item_group(node.name, "cracky") > 1
                        or minetest.get_item_group(node.name, "cracky") <= 0)
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
        -- Textures
        minetest.registered_entities[dragon].update_emission = function(self, force)
            local pos = self.object:get_pos()
            local level = minetest.get_node_light(pos, minetest.get_timeofday())
            if not level then return end
            local texture = self.object:get_properties().textures[1]
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
        end
        -- Dynamic Animation Methods
        minetest.registered_entities[dragon].tilt_to = function(self, tyaw, rate)
            self._tyaw = tyaw
            tyaw = tyaw or 0 -- temp
            rate = rate or 6
            local rot = self.object:get_rotation()
            local yaw = self.object:get_yaw()
            yaw = yaw + pi
            tyaw = (tyaw + pi) % (pi * 2)
            local step = min(self.dtime * rate, abs(tyaw - yaw) % (pi * 2))
            local dir = abs(tyaw - yaw) > pi and -1 or 1
            dir = tyaw > yaw and dir * 1 or dir * -1
            local nyaw = (yaw + step * dir) % (pi * 2)
            local nroll = vec_cross(minetest.yaw_to_dir(yaw), minetest.yaw_to_dir(tyaw)).y
            local roll = lerp(rot.z, nroll, 0.1)
            self.object:set_rotation({x = rot.x, y = nyaw - pi, z = roll})
            if nyaw == tyaw then
                return true, nyaw - pi
            else
                return false, nyaw - pi
            end
        end
        minetest.registered_entities[dragon].set_weighted_velocity = function(self, speed, goal)
            speed = speed or self._movement_data.speed
            local current_vel = self.object:get_velocity()
            local goal_vel = vec_multi(vec_normal(goal), speed)
            local vel = current_vel
            vel.x = vel.x + (goal_vel.x - vel.x) * 0.05
            vel.z = vel.z + (goal_vel.z - vel.z) * 0.05
            self.object:set_velocity(vel)
        end
        minetest.registered_entities[dragon].open_jaw = function(self)
            if not self._anim then return end
            if self.jaw_init then
                if self._anim:find("fire") then
                    self.jaw_init = false
                    self.roar_anim_length = 0
                    return
                end
                local _, rot = self.object:get_bone_position("Jaw.CTRL")
                local b_rot = interp_bone_rot(rot.x, -45, 0.2)
                self.object:set_bone_position("Jaw.CTRL", {x=0,y=0.37,z=-0.2}, {x=b_rot,y=0,z=0})
                self.roar_anim_length = self.roar_anim_length - self.dtime
                if floor(rot.x) == -45
                and self.roar_anim_length <= 0 then
                    self.jaw_init = false
                    self.roar_anim_length = 0
                end
            else
                local _, rot = self.object:get_bone_position("Jaw.CTRL")
                local b_rot = interp_bone_rot(rot.x, 0, self.dtime * 3)
                self.object:set_bone_position("Jaw.CTRL", {x=0,y=0.37,z=-0.2}, {x=b_rot,y=0,z=0})
            end
        end
        minetest.registered_entities[dragon].move_tail = function(self)
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
        minetest.registered_entities[dragon].move_head = function(self, tyaw, pitch)
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
        minetest.registered_entities[dragon].feed = function(self, player)
            local name = player:get_player_name()
            if not self.owner
            or self.owner ~= name then
                return
            end
            local item, item_name = self:follow_wielded_item(player)
            if item_name then
                if not creative then
                    item:take_item()
                    player:set_wielded_item(item)
                end
                if self.hp < (self.max_health * self.growth_scale) then
                    self:heal(self.max_health / 5)
                end
                if self.hunger < (self.max_health * 0.5) * self.growth_scale then
                    self.hunger = self.hunger + 5
                    self:memorize("hunger", self.hunger)
                end
                if item_name:find("cooked") then
                    self.food = (self.food or 0) + 1
                end
                if self.food
                and self.food >= 20 then
                    self.food = 0
                    increase_age(self)
                end
                local pos = draconis.get_head_pos(self, player:get_pos())
                local minppos = vec_add(pos, 1 * self.growth_scale)
                local maxppos = vec_sub(pos, 1 * self.growth_scale)
                local def = minetest.registered_items[item_name]
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
                return true
            end
            return false
        end
        minetest.registered_entities[dragon].play_wing_sound = function(self)
            if not self._anim
            or self.growth_stage < 2 then return end
            if self._anim:match("fly") then
                if self.frame_offset > 20
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
        if object then
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
                if not pos then
                    return
                end
                if not puncher:is_player() then
                    return
                end
                local player_name = puncher:get_player_name()
                if draconis.bonded_dragons[player_name]
                and #draconis.bonded_dragons[player_name] > 0 then
                    for i = 1, #draconis.bonded_dragons[player_name] do
                        local ent = get_dragon_by_id(draconis.bonded_dragons[player_name][i])
                        if ent then
                            ent.owner_target = self.object
                        end
                    end
                end
            end
            minetest.registered_entities[name].on_punch = on_punch
        end
	end
end)

----------------------
-- Entity Utilities --
----------------------

function draconis.step(self, dtime, moveresult)
    self:update_emission()
    self:destroy_terrain(moveresult)
    -- Animation tracking
    if self._anim then
        local aparms = self.animations[self._anim]
        if self.anim_frame ~= -1 then
            self.anim_frame = self.anim_frame + dtime
            self.frame_offset = floor(self.anim_frame * aparms.speed)
            if self.frame_offset > aparms.range.y - aparms.range.x then
                self.anim_frame = 0
                self.frame_offset = 0
            end
        end
    end
    -- Timers
    if self:timer(1) then
        self:do_growth()
        self.time_from_last_sound = self.time_from_last_sound + 1
        if self.time_in_horn then
            self.growth_timer = self.growth_timer - self.time_in_horn / 2
            self.time_in_horn = nil
        end
    end
    if self:timer(5) then
        self:play_sound("random")
    end
    self:play_wing_sound()
    -- Dynamic Animation
    draconis.head_tracking(self)
    self:open_jaw()
    self:move_tail()
    if self:get_utility() ~= "draconis:mount" then
        if self._anim == "fly"
        or self._anim == "fly_fire" then
            local vel_y = self.object:get_velocity().y
            local rot = self.object:get_rotation()
            local goal = clamp(vel_y * 0.25, -0.3, 0.3)
            self.object:set_rotation({
                x = lerp(rot.x, goal, 0.1),
                y = rot.y,
                z = rot.z
            })
        elseif self._anim == "stand"
        or self._anim == "stand_fire" then
            local rot = self.object:get_rotation()
            if rot.x ~= rot.z then
                self.object:set_rotation({
                    x = 0,
                    y = rot.y,
                    z = 0
                })
            end
        end
    end
    if self.shoulder_mounted then
        self:clear_action()
        self:animate("shoulder_idle")
        local player = minetest.get_player_by_name(self.owner)
        if player:get_player_control().sneak == true
        or self.age > 4 then
            self.object:set_detach()
            self.shoulder_mounted = self:memorize("shoulder_mounted", false)
        end
    end
    -- Speed/Stamina Tracking
    if not self.fly_allowed
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
    self.speed = 24 * clamp((self.growth_scale), 0.1, 1)
    if not self.touching_ground
    and not self.in_liquid
    and self.flight_stamina > 0 then
        self.flight_stamina = self.flight_stamina - self.dtime
    else
        self.speed = self.speed * 0.5
        if self.flight_stamina < 900 then
            self.flight_stamina = self.flight_stamina + self.dtime * 2
        end
    end
    self:memorize("flight_stamina", self.flight_stamina)
    if self.attack_stamina < 100 then
        self.attack_stamina = self.attack_stamina + self.dtime
    end
    self:memorize("attack_stamina", self.attack_stamina)
    local alert_timer = self.alert_timer or 0
    if alert_timer > 0 then
        self.alert_timer = self:memorize("alert_timer", alert_timer - self.dtime)
    end
    -- Dragon ID Tracking
    local global_data = draconis.dragons[self.dragon_id]
    draconis.dragons[self.dragon_id] = {
        last_pos = self.object:get_pos(),
        owner = self.owner or nil,
        staticdata = self:get_staticdata(),
        removal_queue = global_data.removal_queue or {},
        stored_in_item = global_data.stored_in_item or false
    }
    if draconis.dragons[self.dragon_id].stored_in_item then
        self.object:remove()
    end
end

function draconis.rightclick(self, clicker)
    local name = clicker:get_player_name()
    local inv = minetest.get_inventory({type = "player", name = name})
    if draconis.contains_libri(inv) then
        local libri, list_i = draconis.get_libri(inv)
        local pages = minetest.deserialize(libri:get_meta():get_string("pages")) or {}
        if #pages > 0 then
            local add_page = true
            for i = 1, #pages do
                if pages[i].name == "dragons" then
                    add_page = false
                    break
                end
            end
            if add_page then
                table.insert(pages, {name = "dragons", form = "pg_dragons;Dragons"})
                libri:get_meta():set_string("pages", minetest.serialize(pages))
                inv:set_stack("main", list_i, libri)
            end
        else
            table.insert(pages, {name = "dragons", form = "pg_dragons;Dragons"})
            libri:get_meta():set_string("pages", minetest.serialize(pages))
            inv:set_stack("main", list_i, libri)
        end
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
            self.object:set_attach(clicker, "", {x = 3 - self.growth_scale, y = 11.5,z = -1.5 - (self.growth_scale * 5)}, {x=0,y=0,z=0})
        end
    end
end

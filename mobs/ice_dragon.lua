----------------
-- Ice Dragon --
----------------

local target_list = {}

minetest.register_on_mods_loaded(function()
    for name in pairs(minetest.registered_entities) do
        if minetest.registered_entities[name].get_staticdata == mobkit.statfunc and
        minetest.registered_entities[name].logic and name ~=
        "draconis:ice_dragon" then table.insert(target_list, name) end
    end
end)

minetest.register_entity("draconis:ice_eyes", {
    hp_max = 1,
    armor_groups = {immortal = 1},
    physical = false,
    collisionbox = {0, 0, 0, 0, 0, 0},
    visual = "mesh",
    mesh = "draconis_eyes.b3d",
    visual_size = {x = 1.01, y = 1.01},
    textures = {"draconis_ice_eyes.png"},
    is_visible = true,
    makes_footstep_sound = false,
    glow = 11,
    blink_timer = 18,
    on_step = function(self, dtime)
        self.object:set_armor_groups({immortal = 1})
        if not self.object:get_attach() then self.object:remove() end
        if self.object:get_attach() and self.object:get_attach():get_luaentity() then
            local parent = self.object:get_attach():get_luaentity()
            if parent.status ~= "sleeping" then
                self.blink_timer = self.blink_timer - dtime
                if parent.age < 25 then
                    self.object:set_properties(
                        {textures = {"draconis_ice_eyes_child.png"}})
                else
                    self.object:set_properties(
                        {textures = {"draconis_ice_eyes.png"}})
                end
                if self.blink_timer <= 0 then
                    local tex = self.object:get_properties().textures[1]
                    self.object:set_properties({textures = {"transparency.png"}})
                    minetest.after(0.25, function()
                        self.object:set_properties({textures = {tex}})
                        self.blink_timer = math.random(6, 18)
                    end)
                end
            else
                self.blink_timer = 18
                self.object:set_properties({textures = {"transparency.png"}})
            end
        end
    end
})

--------------
-- Behavior --
--------------

local function ice_dragon_logic(self)

    if self.hp <= 0 then
        if self.driver then
            draconis.detach(self.driver)
        end
        mob_core.on_die(self)
        return
    end

    local get_sounds = function(self)
        local age = self.age
        if age < 25 then
            self.sounds = self.child_sounds
            return
        end
        if age < 50 then
            self.sounds = self.juvi_sounds
            return
        end
        self.sounds = self.adult_sounds
        return
    end

    local prty = mobkit.get_queue_priority(self)
    local player = mobkit.get_nearby_player(self)

    if mobkit.timer(self, 1) then

        get_sounds(self)
        draconis.ice_vitals(self)
        mob_core.random_sound(self, 4 * self.growth_stage)

        if self.order == "stand"
        and not self.driver then
            mobkit.animate(self, "stand")
            return
        end

        if prty < 20 then
            if self.cavern_spawn then
                draconis.hq_sleep(self, 20)
                return
            end
            if self.driver then
                draconis.hq_mount_logic(self, 20)
                return
            end
        end

        if prty < 16 and self.isinliquid then
            self.flight_timer = mobkit.remember(self, "flight_timer", 30)
            mob_core.hq_takeoff(self, 16, 6)
            return
        end

        if prty < 12 and self.owner_target then
            draconis.logic_attack_mob(self, 12, self.owner_target)
        end

        if self.isonground then

            if self.flight_timer <= 1 then
                self.flight_timer = mobkit.remember(self, "flight_timer",
                                                    math.random(30, 60))
            end

            if prty < 8 then
                if not self.tamed or self.stance == "aggressive" then
                    draconis.logic_attack_nearby_mobs(self, 8)
                end
            end

            if prty < 6 then
                if player then
                    if not self.tamed or
                        (self.stance == "aggressive" and
                            player:get_player_name() ~= self.owner) then
                        draconis.logic_attack_nearby_player(self, 6, player)
                    end
                end
            end

            if prty < 4 then
                if math.random(1, 64) == 1 and self.fly_allowed then
                    mob_core.hq_takeoff(self, 4, 6)
                    return
                end
            end

            if prty < 2 then
                if self.sleep_timer <= 0 then
                    draconis.hq_sleep(self, 2)
                end
            end

            if mobkit.is_queue_empty_high(self) then
                mobkit.hq_roam(self, 0)
            end
        end

        if not self.isonground and not self.isinliquid then -- Flight behavior

            if self.flight_timer > 1 then
                self.flight_timer = mobkit.remember(self, "flight_timer",
                                                    self.flight_timer - 1)
            end

            if prty < 6 then
                if not self.tamed or self.stance == "aggressive" then
                    if self.breath_meter > self.breath_meter_max / 4 then
                        draconis.logic_attack_nearby_mobs(self, 6)
                    else
                        mob_core.hq_land(self, 6)
                        return
                    end
                end
            end

            if prty < 4 then
                if player then
                    if not self.tamed or
                        (self.stance == "aggressive" and
                            player:get_player_name() ~= self.owner) then
                        draconis.logic_attack_nearby_player(self, 4, player)
                    end
                end
            end

            if prty < 2 then
                if self.flight_timer <= 1 then
                    mob_core.hq_land(self, 2)
                    return
                end
            end

            if mobkit.is_queue_empty_high(self) then
                mob_core.hq_aerial_roam(self, 0, 1)
            end
        end
    end
end

----------------
-- Definition --
----------------

minetest.register_entity("draconis:ice_dragon", {
    -- Stats
    max_hp = 650,
    armor_groups = {fleshy = 45},
    view_range = 64,
    reach = 12,
    damage = 20,
    knockback = 4,
    lung_capacity = 60,
    soar_height = 32,
    -- Movement & Physics
    max_speed = 12,
    stepheight = 1.1,
    jump_height = 1.26,
    max_fall = 100,
    buoyancy = 1,
    springiness = 0,
    -- Visual
    collisionbox = {-1.95, -2.7, -1.95, 1.95, 1.8, 1.95},
    visual_size = {x = 35, y = 35},
    visual = "mesh",
    mesh = "draconis_ice_dragon.b3d",
    textures = {
        "draconis_ice_dragon_light_blue.png",
        "draconis_ice_dragon_sapphire.png", "draconis_ice_dragon_slate.png",
        "draconis_ice_dragon_white.png"
    },
    child_textures = {
        "draconis_ice_dragon_light_blue_child.png",
        "draconis_ice_dragon_sapphire_child.png",
        "draconis_ice_dragon_slate_child.png",
        "draconis_ice_dragon_white_child.png"
    },
    animation = {
        stand = {range = {x = 1, y = 60}, speed = 15, loop = true},
        stand_fire = {range = {x = 70, y = 120}, speed = 15, loop = true},
        walk = {range = {x = 140, y = 180}, speed = 25, loop = true},
        walk_fire = {range = {x = 190, y = 230}, speed = 25, loop = true},
        goto_sleep = {range = {x = 231, y = 240}, speed = 10, loop = false},
        sleep = {range = {x = 240, y = 280}, speed = 10, loop = true},
        wakeup = {range = {x = 280, y = 291}, speed = 10, loop = false},
        fly = {range = {x = 300, y = 340}, speed = 25, loop = true},
        fly_fire = {range = {x = 350, y = 390}, speed = 25, loop = true},
        fly_idle = {range = {x = 400, y = 440}, speed = 25, loop = true},
        fly_idle_fire = {range = {x = 450, y = 490}, speed = 25, loop = true}
    },
    -- Mount
    mount_speed = 18,
    mount_speed_sprint = 26,
    -- Sound
    child_sounds = {
        random = {
            {
                name = "draconis_child_random_1",
                gain = 1,
                distance = 16
            },
            {
                name = "draconis_child_random_2",
                gain = 1,
                distance = 16
            },
            {
                name = "draconis_child_random_3",
                gain = 1,
                distance = 16
            }
        },
        hurt = {
            {
                name = "draconis_child_random_1",
                gain = 1,
                distance = 16
            },
            {
                name = "draconis_child_random_2",
                gain = 1,
                distance = 16
            },
            {
                name = "draconis_child_random_3",
                gain = 1,
                distance = 16
            }
        },
        flap = ""
    },
    juvi_sounds = {
        random = {
            {
                name = "draconis_ice_dragon_juvi_1",
                gain = 1,
                distance = 24
            },
            {
                name = "draconis_ice_dragon_juvi_2",
                gain = 1,
                distance = 24
            },
            {
                name = "draconis_ice_dragon_juvi_3",
                gain = 1,
                distance = 24
            }
        },
        hurt = {
            {
                name = "draconis_ice_dragon_juvi_1",
                gain = 1,
                distance = 16
            },
            {
                name = "draconis_ice_dragon_juvi_2",
                gain = 1,
                distance = 16
            },
            {
                name = "draconis_ice_dragon_juvi_3",
                gain = 1,
                distance = 16
            }
        },
        flap = "draconis_flap"
    },
    adult_sounds = {
        random = {
            {
                name = "draconis_ice_dragon_adult_1",
                gain = 1,
                distance = 32
            },
            {
                name = "draconis_ice_dragon_adult_2",
                gain = 1,
                distance = 32
            },
            {
                name = "draconis_ice_dragon_adult_3",
                gain = 1,
                distance = 32
            }
        },
        hurt = {
            {
                name = "draconis_ice_dragon_adult_1",
                gain = 1,
                distance = 24
            },
            {
                name = "draconis_ice_dragon_adult_2",
                gain = 1,
                distance = 24
            },
            {
                name = "draconis_ice_dragon_adult_3",
                gain = 1,
                distance = 24
            }
        },
        flap = "draconis_flap"
    },
    sounds = {},
    -- Basic
    physical = true,
    collide_with_objects = true,
    static_save = true,
    defend_owner = true,
    push_on_collide = true,
    punch_cooldown = 0.25,
    max_hunger = 325,
    colors = {"light_blue", "sapphire", "slate", "white"},
    targets = target_list,
    follow = draconis.global_meat,
    timeout = 0,
    physics = draconis.physics,
    logic = ice_dragon_logic,
    get_staticdata = mobkit.statfunc,
    on_activate = function(self, staticdata, dtime_s)
        draconis.on_activate(self, staticdata, dtime_s)
    end,
    on_step = draconis.on_step,
    on_rightclick = function(self, clicker)
        if self.driver then return end
        local item = clicker:get_wielded_item():get_name()
        local name = clicker:get_player_name()
        if draconis.feed(self, clicker, 64 * self.growth_scale) then
            return
        end
        draconis.capture_with_flute(self, clicker)
        mob_core.protect(self, clicker, true)
        if item == "" then
            if clicker:get_player_control().sneak == true then
                draconis.formspec(self, clicker)
                return
            elseif self.age >= 50 and self.owner and self.owner == name then
                draconis.mount(self, clicker)
                return
            end
        end
        if item == "draconis:growth_essence_ice" then
            draconis.increase_age(self)
        end
        mob_core.nametag(self, clicker)
    end,
    on_punch = function(self, puncher, _, tool_capabilities, dir)
        if self.driver and puncher == self.driver then return end
        mob_core.on_punch_basic(self, puncher, tool_capabilities, dir)
        if self.cavern_spawn then
            self.cavern_spawn = nil
            mobkit.forget(self, "cavern_spawn")
        end
        if self.status == "sleeping" then
            self.sleep_timer = mobkit.remember(self, "sleep_timer",
                                               self.sleep_timer + 30)
            draconis.lq_wakeup(self)
            mobkit.clear_queue_low(self)
            mobkit.clear_queue_high(self)
            self.status = mobkit.remember(self, "status", "")
            draconis.logic_attack_nearby_player(self, 20, puncher)
        end
        if not self.tamed or
            (self.stance == "neutral" and puncher:is_player() and
                puncher:get_player_name() ~= self.owner) then
            draconis.logic_attack_nearby_player(self, 20, puncher)
        end
        if not puncher:is_player() then mobkit.clear_queue_high(self) end
    end
})

mob_core.register_spawn_egg("draconis:ice_dragon", "a3bcd1cc", "527fa3d9")

if minetest.settings:get_bool("simple_spawning") then
    local spawn_rate = minetest.settings:get("dragon_spawn_rate")
    draconis.register_spawn({
        name = "draconis:ice_dragon",
        biomes = draconis.cold_biomes,
        nodes = draconis.cold_biome_nodes,
        min_height = 1,
        max_height = 310
    }, 16, spawn_rate)
end
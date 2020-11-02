-------------
--- Tools ---
-------------
-- Ver 1.0 --

local SF = draconis.string_format

----------------
-- Dragonbone --
----------------

minetest.register_tool("draconis:pick_dragonbone", {
    description = "Dragonbone Pickaxe",
    inventory_image = "draconis_dragonbone_pick.png",
    wield_scale = {x = 1.5, y = 1.5, z = 1},
    tool_capabilities = {
        full_punch_interval = 0.6,
        max_drop_level = 3,
        groupcaps = {
            cracky = {
                times = {[1] = 1.2, [2] = 0.8, [3] = 0.6},
                uses = 40,
                maxlevel = 3
            }
        },
        damage_groups = {fleshy = 4}
    },
    sound = {breaks = "default_tool_breaks"},
    groups = {pickaxe = 1}
})

minetest.register_tool("draconis:shovel_dragonbone", {
    description = "Dragonbone Shovel",
    inventory_image = "draconis_dragonbone_shovel.png",
    wield_image = "draconis_dragonbone_shovel.png",
    wield_scale = {x = 1.5, y = 1.5, z = 1},
    tool_capabilities = {
        full_punch_interval = 0.6,
        max_drop_level = 1,
        groupcaps = {
            crumbly = {
                times = {[1] = 0.8, [2] = 0.6, [3] = 0.4},
                uses = 40,
                maxlevel = 3
            }
        },
        damage_groups = {fleshy = 4}
    },
    sound = {breaks = "default_tool_breaks"},
    groups = {shovel = 1}
})

minetest.register_tool("draconis:axe_dragonbone", {
    description = "Dragonbone Axe",
    inventory_image = "draconis_dragonbone_axe.png",
    wield_scale = {x = 1.5, y = 1.5, z = 1},
    tool_capabilities = {
        full_punch_interval = 0.6,
        max_drop_level = 1,
        groupcaps = {
            choppy = {
                times = {[1] = 1.2, [2] = 0.8, [3] = 0.6},
                uses = 40,
                maxlevel = 3
            }
        },
        damage_groups = {fleshy = 6}
    },
    sound = {breaks = "default_tool_breaks"},
    groups = {axe = 1}
})

minetest.register_tool("draconis:sword_dragonbone", {
    description = "Dragonbone Sword",
    inventory_image = "draconis_dragonbone_sword.png",
    wield_scale = {x = 1.5, y = 1.5, z = 0.5},
    tool_capabilities = {
        full_punch_interval = 0.1,
        max_drop_level = 1,
        groupcaps = {
            snappy = {
                times = {[1] = 0.4, [2] = 0.2, [3] = 0.1},
                uses = 40,
                maxlevel = 3
            }
        },
        damage_groups = {fleshy = 8}
    },
    sound = {breaks = "default_tool_breaks"},
    groups = {sword = 1}
})

--------------------
-- Draconic Steel --
--------------------

local elements = {"ice", "fire"}

for _, element in pairs(elements) do

minetest.register_tool("draconis:pick_"..element.."_draconic_steel", {
    description = SF(element).."-Forged Draconic Steel Pickaxe",
    inventory_image = "draconis_"..element.."_draconic_steel_pick.png",
    tool_capabilities = {
        full_punch_interval = 4,
        max_drop_level = 3,
        groupcaps = {
			cracky = {
                times={[1]=0.3, [2]=0.15, [3]=0.075},
                uses=100,
                maxlevel=3},
			crumbly = {
                times={[1]=0.5, [2]=0.25, [3]=0.2},
                uses=100,
                maxlevel=3
            },
        },
        damage_groups = {fleshy = 35}
    },
    range = 6,
    sound = {breaks = "default_tool_breaks"},
    groups = {pickaxe = 1}
})

minetest.register_tool("draconis:shovel_"..element.."_draconic_steel", {
    description = SF(element).."-Forged Draconic Steel Shovel",
    inventory_image = "draconis_"..element.."_draconic_steel_shovel.png",
    tool_capabilities = {
        full_punch_interval = 5.5,
        max_drop_level = 1,
        groupcaps = {
            crumbly = {
                times = {[1] = 0.4, [2] = 0.2, [3] = 0.1},
                uses = 100,
                maxlevel = 3
            }
        },
        damage_groups = {fleshy = 30}
    },
    range = 6,
    sound = {breaks = "default_tool_breaks"},
    groups = {shovel = 1}
})

minetest.register_tool("draconis:axe_"..element.."_draconic_steel", {
    description = SF(element).."-Forged Draconic Steel Axe",
    inventory_image = "draconis_"..element.."_draconic_steel_axe.png",
    wield_scale = {x = 1.5, y = 1.5, z = 1},
    tool_capabilities = {
        full_punch_interval = 3,
        max_drop_level = 1,
        groupcaps = {
            choppy = {
                times={[1]=0.3, [2]=0.15, [3]=0.075},
                uses = 100,
                maxlevel = 3
            }
        },
        damage_groups = {fleshy = 55}
    },
    range = 6,
    sound = {breaks = "default_tool_breaks"},
    groups = {axe = 1}
})

minetest.register_tool("draconis:sword_"..element.."_draconic_steel", {
    description = SF(element).."-Forged Draconic Steel Sword",
    inventory_image = "draconis_"..element.."_draconic_steel_sword.png",
    wield_scale = {x = 2, y = 2, z = 1},
    tool_capabilities = {
        full_punch_interval = 1.2,
        max_drop_level = 1,
        groupcaps = {
            snappy = {
                times = {[1] = 0.05, [2] = 0.025, [3] = 0.01},
                uses = 100,
                maxlevel = 3
            }
        },
        damage_groups = {fleshy = 60}
    },
    range = 6,
    sound = {breaks = "default_tool_breaks"},
    groups = {sword = 1}
})
end
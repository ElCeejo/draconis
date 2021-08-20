local mod_storage = minetest.get_mod_storage()

local data = {
    ice_caverns = minetest.deserialize(mod_storage:get_string("ice_caverns")) or {},
    fire_caverns = minetest.deserialize(mod_storage:get_string("fire_caverns")) or {},
    ice_roosts = minetest.deserialize(mod_storage:get_string("ice_roosts")) or {},
    fire_roosts = minetest.deserialize(mod_storage:get_string("fire_roosts")) or {},
    dragons = minetest.deserialize(mod_storage:get_string("dragons")) or {}
}

local function save()
    mod_storage:set_string("ice_caverns", minetest.serialize(data.ice_caverns))
    mod_storage:set_string("fire_caverns", minetest.serialize(data.fire_caverns))
    mod_storage:set_string("ice_roosts", minetest.serialize(data.ice_roosts))
    mod_storage:set_string("fire_roosts", minetest.serialize(data.fire_roosts))
    mod_storage:set_string("dragons", minetest.serialize(data.dragons))
end

minetest.register_on_shutdown(save)
minetest.register_on_leaveplayer(save)

local function periodic_save()
    save()
    minetest.after(120, periodic_save)
end
minetest.after(120, periodic_save)

return data
local mod_storage = minetest.get_mod_storage()

local data = {
    dragons = minetest.deserialize(mod_storage:get_string("dragons")) or {},
    bonded_dragons = minetest.deserialize(mod_storage:get_string("bonded_dragons")) or {},
    aux_key_setting = minetest.deserialize(mod_storage:get_string("aux_key_setting")) or {}
}

local function save()
    mod_storage:set_string("dragons", minetest.serialize(data.dragons))
    mod_storage:set_string("bonded_dragons", minetest.serialize(data.bonded_dragons))
    mod_storage:set_string("aux_key_setting", minetest.serialize(data.aux_key_setting))
end

minetest.register_on_shutdown(save)
minetest.register_on_leaveplayer(save)

local function periodic_save()
    save()
    minetest.after(120, periodic_save)
end
minetest.after(120, periodic_save)

return data
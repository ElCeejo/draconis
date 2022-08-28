local mod_storage = minetest.get_mod_storage()

local data = {
    dragons = minetest.deserialize(mod_storage:get_string("dragons")) or {},
    bonded_dragons = minetest.deserialize(mod_storage:get_string("bonded_dragons")) or {},
    aux_key_setting = minetest.deserialize(mod_storage:get_string("aux_key_setting")) or {},
    attack_blacklist = minetest.deserialize(mod_storage:get_string("attack_blacklist")) or {},
	libri_font_size = minetest.deserialize(mod_storage:get_string("libri_font_size")) or {}
}

local function save()
    mod_storage:set_string("dragons", minetest.serialize(data.dragons))
    mod_storage:set_string("bonded_dragons", minetest.serialize(data.bonded_dragons))
    mod_storage:set_string("aux_key_setting", minetest.serialize(data.aux_key_setting))
    mod_storage:set_string("attack_blacklist", minetest.serialize(data.attack_blacklist))
	mod_storage:set_string("libri_font_size", minetest.serialize(data.libri_font_size))
end

minetest.register_on_shutdown(save)
minetest.register_on_leaveplayer(save)

local function periodic_save()
    save()
    minetest.after(120, periodic_save)
end
minetest.after(120, periodic_save)

minetest.register_globalstep(function()
	if draconis.force_storage_save then
		save()
		draconis.force_storage_save = false
	end
end)

return data
max_line_length = 120

globals = {
	"minetest",
	"core", -- todo: change to core namespace completely
	"VoxelArea",
	"creatura",
	"draconis",
	"default",
	"stairs",
	"armor",
}

read_globals = {
	"vector",
	"ItemStack",
	table = {fields = {"copy"}}
}

ignore = {"212/self", "212/this"}
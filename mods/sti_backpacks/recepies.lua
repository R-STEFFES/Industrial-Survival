-- sti_backpacks: recepies.lua

-- sti_backpacks: recepies.lua

local colors = {
	"white", "grey", "black", "red", "yellow", "green", "cyan",
	"blue", "magenta", "orange", "violet", "brown", "pink",
	"dark_grey", "dark_green"
}

for _, color in ipairs(colors) do
	minetest.register_craft({
		output = "sti_backpacks:backpack_" .. color,
		recipe = {
			{"wool:" .. color, "wool:" .. color,     "wool:" .. color},
			{"wool:" .. color, "default:chest",     "wool:" .. color},
			{"wool:" .. color, "wool:" .. color,     "wool:" .. color}
		}
	})
end

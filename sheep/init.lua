--try to register the first entity.

mila:add_entity("milasheep:sheep", { -- define and access functions on Lua tables using the ":" operator
	hp_max = 10,
	collisionbox = {-0.5, -0.1, -0.5,  0.5, 1.1, 0.5},
	visual_size = 1,
	mesh = "sheep.x",
	visual = "mesh",
	textures = {"mila_sheep.png^mila_sheep_wool.png"},
	speed = 2,
	gravity = 5,
	view_range = 5,
	range = 2,
	rotate = 0,
	status = "passive",
})
   
--then the egg

mila:add_egg("milasheep:sheep", {
	description = "Sheep Egg",
	inventory_image = "mobs_sheep.png",
})

-- and a spawn

mila:add_spawn("milasheep:sheep")

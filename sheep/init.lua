--try to register the first entity.

mila:add_entity("milasheep:sheep", { -- define and access functions on Lua tables using the ":" operator
	hp_max = 10,
	collisionbox = {-0.5, -0.1, -0.5,  0.5, 1.1, 0.5},
	visual_size = 1,
	mesh = "sheep.x",
	visual = "mesh",
	textures = {"sheep.png^sheep_wool.png"},
	speed = 2,
	fall_speed = -5,
	view_range = 5,
	rotate = 90,
})
   
--then the egg

mila:add_egg("milasheep:sheep", {
	description = "Sheep Egg",
	inventory_image = "sheep.png^sheep_wool.png",
	wield_image = "sheep.png^sheep_wool.png",
})
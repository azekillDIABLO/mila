--try to register the first entity.

mila:add_entity("milasheep:sheep", { -- define and access functions on Lua tables using the ":" operator
	hp_max = 10,
	collisionbox = {-0.5, -0.5, -0.5,  0.5, 0.5, 0.5},
	mesh = "sheep.x",
	textures = {"sheep.png"},
	speed = 1,
	view_range = 5,
})
   
--then the egg

mila:add_egg("milasheep:sheep", {
	description = "Sheep Egg",
	inventory_image = "sheep.png",
	wield_image = "sheep.png",
	on_place = on_place,
})

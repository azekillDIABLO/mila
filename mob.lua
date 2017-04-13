--try to register the first entity

mila:add_entity("mila:evil_knight", { 
	damage = 9,
	collisionbox = {-0.4,-2.55,-0.4, 0.4, 1.6, 0.4},
	status = "hostile",
	visual_size = {x=5, y=5},
	mesh = "armour.b3d",
	textures = {"armour.png"},
	makes_footstep_sound = true,
	physical = true,		
	collide_with_objects = true,
	stepheight = 5,
	hp_max = 175,
	speed = 1, 
	range = 3, 	
	view_range = 40,	
})
   
--then the egg

mila:add_egg("mila:evil_knight", {
	description = "Evil Knight",
	inventory_image = "default_steel_ingot.png",
	wield_image = "default_steel_ingot.png",
})

--finally the spawning

mila:add_spawn("mila:evil_knight", {
	nodenames = {"default:steel_block"},
	neighbors = {"air"},
	interval = 440,
	chance = 1000,
})

--try to register the second entity

mila:add_entity("mila:bat", { -- define and access functions on Lua tables using the ":" operator
	collisionbox = {-0.1,-0.1,-0.1, 0.1,0.1,0.1},
	status = "passive",
	visual_size = {x=1, y=1},
	gravity = 0,
	mesh = "bat.b3d",
	textures = {"bat.png"},
	makes_footstep_sound = false,
	physical = true,		
	collide_with_objects = true,
	automatic_face_movement_dir = 0,
	hp_max = 4,
	speed = 4, 	
	stepheight = 3.5,
	view_range = 55,	
})
   
--then the egg

mila:add_egg("mila:bat", {
	description = "Minecraft Bat",
	inventory_image = "bat_inv.png",
	wield_image = "bat_inv.png",
})

mila:add_spawn("mila:bat", {
	nodenames = {"air"},
	neighbors = {"default:stone"},
	interval = 240,
	chance = 1000,
})

--Ranged entity

mila:add_entity("mila:skeleton", {
	collisionbox = {-0.4,-0.8,-0.4, 0.4,0.6,0.4},
	status = "shooter",
	visual_size = {x=1, y=1},
	visual = "mesh",
	mesh = "skeleton.b3d",
	textures = {"skeleton.png"},
	makes_footstep_sound = true,
	physical = true,		
	collide_with_objects = true,
	hp_max = 25,
	speed = 3, 
	range = 10, 	
	stepheight = 2,
	view_range = 15,
	arrow = "mila:arrow",
})

mila:add_entity("mila:arrow", {
	damage = 4,
	gravity = 0,
	collisionbox = {-0.2,-0.2,-0.2, 0.2,0.2,0.2},
	status = "arrow",
	visual_size = {x=1, y=1},
	visual = "upright_sprite",
	textures = {"arrow.png"},
	makes_footstep_sound = false,
	physical = true,		
	collide_with_objects = true,
	hp_max = 5,
	speed = 8,
	range = 20,
})

--then the egg

mila:add_egg("mila:skeleton", {
	description = "Minecraft skeleton",
	inventory_image = "skeleton.png",
	wield_image = "skeleton.png",
})

-- Bomba! == bomber tes

mila:add_entity("mila:bomba", { 
	damage = 9,
	collisionbox = {-0.4,-0.7,-0.4, 0.4, 0.6, 0.4},
	status = "bomber",
	visual_size = {x=1, y=1},
	mesh = "armour.b3d",
	textures = {"armour.png"},
	makes_footstep_sound = true,
	physical = true,		
	collide_with_objects = true,
	stepheight = 2,
	hp_max = 175,
	speed = 1, 
	range = 3, 	
	view_range = 40,	
})
   
--then the egg

mila:add_egg("mila:bomba", {
	description = "BOMBA!",
	inventory_image = "default_dirt.png",
	wield_image = "default_dirt.png",
})

--Dungeon master

mila:add_entity("mila:DM", {
	collisionbox = {-0.6,-1,-0.6, 0.6,1,0.6},
	status = "shooter",
	visual_size = {x=1, y=1},
	visual = "mesh",
	mesh = "DM.b3d",
	textures = {"DM.png"},
	makes_footstep_sound = true,
	physical = true,		
	collide_with_objects = true,
	hp_max = 45,
	speed = 3, 
	range = 10, 	
	stepheight = 2,
	view_range = 15,
	arrow = "mila:fireball",
})

mila:add_entity("mila:fireball", {
	damage = 6,
	gravity = 0,
	collisionbox = {-0.3,-0.3,-0.3, 0.3,0.3,0.3},
	status = "fireball",
	visual_size = {x=1, y=1},
	visual = "cube",
	textures = {"default_lava.png","default_lava.png",
			"default_lava.png","default_lava.png",
			"default_lava.png","default_lava.png"},
	makes_footstep_sound = false,
	physical = true,		
	collide_with_objects = false,
	hp_max = 5,
	speed = 8,
	range = 20,
})

--then the egg

mila:add_egg("mila:DM", {
	description = "Dungeon Master",
	inventory_image = "DM.png",
	wield_image = "DM.png",
})

--Minecraft steve == Melee test

mila:add_entity("mila:steve_minecraft", { -- define and access functions on Lua tables using the ":" operator
	damage = 6,
	collisionbox = {-0.4,-1,-0.4, 0.4,1,0.4},
	status = "hostile",
	visual_size = {x=1, y=1},
	mesh = "character.b3d",
	textures = {"character.png"},
	makes_footstep_sound = true,
	physical = true,		
	collide_with_objects = true,
	hp_max = 20,
	speed = 3, 
	range = 1.5, 	
	stepheight = 3.5,
	view_range = 55,	
})
   
--then the egg

mila:add_egg("mila:steve_minecraft", {
	description = "Minecraft Steve",
	inventory_image = "character.png",
	wield_image = "character.png",
})

mila:add_spawn("mila:steve_minecraft", {
	nodenames = {"default:dirt_with_grass"},
	neighbors = {"air"},
	interval = 440,
	chance = 1200,
})
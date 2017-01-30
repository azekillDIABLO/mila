--[[	api_help.lua
Welcome to the Help for Mila engine,
where you can discover things on the mod!
This is a .lua file, but it's not loaded, so comment isn't needed,
but I prefer to use them to show what is part of code and what isn't.
]]

--the entity registering function
function mila:add_entity(name,def)
	minetest.register_entity(name, {

--##BUGGY/UNUSED
		sounds = def.sounds,
	--supposed to set entity sounds
	
		rotate = def.rotate or 0,					
	--deprecated, replace with automatic_face_movement_dir 
	
--##OBLIGATORY THINGS
	
		physical = def.physical,					
	--if false, monster will ghost trough any blocks
	
		collide_with_objects = def.collide_with_objects,
	--if false, monster will ghost trough any objects
	
		textures = def.textures,
	--define textures used by entity
	
		mesh = def.mesh,
	--say which mesh you want to use
	
		
		
--##OPTIONAL FUNCTIONS
		
		gravity = def.gravity or 11,
	--falling speed of the entity
	
		damage = def.damage or 1,
	--damage done on hit by the entity
	
		range = def.range or 1,
	--distance from where the mob can punch you
	
		status = def.status or "re",					
	--"passive" for animals; "hostile" for ennemies; "re" for rotating entities.
	
		makes_footstep_sound = def.makes_footstep_sounds,
	--make sound on ground? true or false
	
		stepheight = def.stepheight or 2,	
	--at least 2 if you want the mob pass over blocks!
	
		collisionbox = def.collisionbox or {-0.5, -0.5, -0.5,  0.5, 0.5, 0.5},
	--collision box size
		
		visual_size = def.visual_size or {x=1, y=1},
	--size of the entity
	
		visual = def.visual or "mesh",
	--only mesh, i think... maybe sprite too... idk
	
		automatic_face_movement_dir = def.automatic_face_movement_dir or -90,	
	--replaces rotate and make the mob face the direction they are going (and can correct bad orientation of a mesh)
	
		hp_max = def.hp_max or 1,
	--amount of health (at least 1)
	
		drops = def.drops or "mila:steak 4",
	--drops on death of the mod, for example "default:dirt 8, mine:crafting_bench"
	
		speed = def.speed or 4,
	--the entity's speed. '2' is slow and '8' is fast
	
		view_range = def.view_range or 5,			
	--distance from where the mob can see you
						
	})
end

--Egg adding function

mila:add_egg("milaent:ent", {

--##OBLIGATORY
		description = "<what you want>",
	--the name of the item, in inventory all characters allowed
	
		inventory_image = "<what you want>.png",
	--sets the image in inventory, hotbar, and in hand if no "wield_image" set
	
--##OPTIONAL
		wield_image = "<what you want>.png",
	--sets a special image when in hand
})

--Thank you, this is the end of the Mila help file!
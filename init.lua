--define a global mila table
mila = {}

--define the version of the engine
mila.version = 1.2

--set little things, for deletion and else
clean = false
ent_num = 0
local counter = 1

--define modpath, not local for other files
milapath = minetest.get_modpath("mila") 

--open the api, the most important thing of all
dofile(milapath .."/api.lua")
dofile(milapath .."/boomapi.lua")


--open the settings file (you can change things in it!!!)
dofile(milapath .."/settings.lua")

--open the misc files, for registering items, node, crafts
dofile(milapath .."/misc.lua")

--open the mob files, for registering the entities
--loaded at the end to be sure every function is
--registered and ready to be used by this file :
if mila.template_mobs == true then
		dofile(milapath .."/mob.lua")
end --## load only if actived :P

--REALLY STUPID DEBUG STUFF
--=============================

--nametag mod
if mila.nametag == 1 then --add health in coloured numbers and mob name
	minetest.debug("M.I.L.A " ..mila.version..": Nametag with mob name and health in numbers actived!")
elseif mila.nametag == 2 then --add coloured health bar 
	minetest.debug("M.I.L.A " ..mila.version..": Nametag with coloured healthbar activated!")
elseif mila.nametag == 3 then --add colored shape
	minetest.debug("M.I.L.A " ..mila.version..": Nametag with color indicator activated!")
elseif mila.nametag == 4 then --disable nametag
	minetest.debug("M.I.L.A " ..mila.version..": Nametag disabled!")
end

--explosion damage on blocks
if mila.break_blocks == false then 
	minetest.debug("M.I.L.A " ..mila.version..": Mob explosions can't destroy blocks!")
elseif mila.break_blocks == true then 
	minetest.debug("M.I.L.A " ..mila.version..": Mob explosions can destroy blocks!")
end

--peaceful state
if mila.peaceful == true then
	minetest.debug("M.I.L.A " ..mila.version..": Only peaceful mobs can spawn!")
elseif mila.peaceful == false then
	minetest.debug("M.I.L.A " ..mila.version..": All type of mobs can spawn!")
end

--bleed type
if bleed_type == 1 then
	minetest.debug("M.I.L.A " ..mila.version..": Realistic Blood Actived!")
elseif bleed_type == 2 then
	minetest.debug("M.I.L.A " ..mila.version..": Blood Trail Actived!")
elseif bleed_type == 3 then
	minetest.debug("M.I.L.A " ..mila.version..": Massive Butchery Actived!")
elseif bleed_type == 4 then
	minetest.debug("M.I.L.A " ..mila.version..": Blood Splashes Disabled!")
end

--egg state
if mila.egg == true then
	minetest.debug("M.I.L.A " ..mila.version..": Eggs are actived!")
elseif mila.egg == false then
	minetest.debug("M.I.L.A " ..mila.version..": Eggs are not actived!")
end

--spawning state
if mila.spawning == true then
	minetest.debug("M.I.L.A " ..mila.version..": Spawning is actived!")
elseif mila.spawning == false then
	minetest.debug("M.I.L.A " ..mila.version..": Spawning is not actived!")
end

--template mob activation
if mila.template_mobs == true then
	minetest.debug("M.I.L.A " ..mila.version..": Template mobs are actived!")
elseif mila.template_mobs == false then
	minetest.debug("M.I.L.A " ..mila.version..": Template mobs are not actived!")
end

--say that every little thing is gonna be allright 
minetest.debug("M.I.L.A " ..mila.version..": Everything is OK and running. Have Fun!")
minetest.debug("M.I.L.A " ..mila.version..": Remember to report any bug on forum...")
minetest.debug("M.I.L.A " ..mila.version..": I'm a (great) mod from azekill_DIABLO!")

--[[	settings.lua
Welcome to the global M.I.L.A. settings file,
where you can set different parameters for the mod!
This is a .lua file, so comment is needed. --like this
]]

--say that we are loading:
minetest.debug("M.I.L.A " ..mila.version..": Settings file found, loading...")

-- 1 for realistic blood, 2 for blood trail, 3 for the massive butchery (laggy) and 4 to disable:
mila.bleed_type = 1

-- 1 for nametag with health in numbers and internal name, 2 for health bar, 3 for coloured shape (ugly) and 4 to disable:
mila.nametag = 2

--active "template" mobs:
mila.template_mobs = true --(low quality mobs only used for testing, nearly unusable for a real game)

--mobs parameters:
mila.egg = true --allow registering eggs
mila.spawning = true --make all mobs spawn
mila.peaceful = false --make all mobs passive
--WIP settings
mila.break_blocks = false --break blocks on explosion ### EXPERIMENTAL OPTION | SET TO FALSE PLEASE !!! ####

-- global step counter for speed (0.5 is good)
-- if self.attack_speed is lower, it won't count
mila.globalcounter = 0.5 --seconds

-- limit number of mobs active on chunks loaded (50 is good)
mila.maxhandled = 50 --mobs (note: it can raise higher if you move a lot around, but I didn't found a way to manage unloaded entities)

--say that we are ready!
minetest.debug("M.I.L.A " ..mila.version..": Settings file fully loaded, have fun!")
--Have fun! -azekill_DIABLO
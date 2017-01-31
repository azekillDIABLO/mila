--say that we are loading
minetest.debug("M.I.L.A " ..mila.version..": Misc OK!")

--##steaks are used as default mob drops

--raw steak, <poisonous>
minetest.register_craftitem("mila:steak", {
	description = "Raw steak",
	inventory_image = "mila_steak.png",
	on_use = minetest.item_eat(-4),
})

--cooked steak, <healthy>
minetest.register_craftitem("mila:cooked_steak", {
	description = "Cooked steak",
	inventory_image = "mila_steak_2.png",
	on_use = minetest.item_eat(5),
})

--the "cooking" method to obtain the steaks
minetest.register_craft({
	type = "cooking",
	output = "mila:cooked_steak",
	recipe = "mila:steak",
})

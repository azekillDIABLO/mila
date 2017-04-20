--say that we are loading
print("M.I.L.A " ..mila.version..": Misc OK!")

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

--the FANG weapon
minetest.register_tool("mila:fang", {
	description = "Fang",
	wield_image = "mila_fang.png",
	inventory_image = "mila_fang.png",
	tool_capabilities = {
		full_punch_interval = 0.1,
		max_drop_level=0,
		groupcaps={
			cracky = {times={[3]=1.60}, uses=10, maxlevel=1},
		},
		damage_groups = {fleshy=3},
	},
	groups = {flammable = 2},
	sound = {breaks = "default_tool_breaks"},
})
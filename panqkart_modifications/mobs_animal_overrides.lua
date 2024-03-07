local animals = {
    "bee",
    "bunny",
    "chicken",
    "cow",
    "kitten",
    "panda",
    "penguin",
    "rat",
    "sheep",
    "warthog"
}

-- From https://codeberg.org/tenplus1/mobs_animal/src/branch/master/sheep.lua#L5
-- Thanks!
local all_colors = {
	"black",
	"blue",
	"brown",
	"cyan",
	"dark_green",
	"dark_grey",
	"green",
	"grey",
	"magenta",
	"orange",
	"pink",
	"red",
	"violet",
	"white",
	"yellow"
}

local function modify(entity_def)
	entity_def.passive = true
    entity_def.armor = 0
    entity_def.runaway = false
    entity_def.water_damage = 0
	entity_def.lava_damage = 0
	entity_def.light_damage = 0
	entity_def.fall_damage = 0
	entity_def.fear_height = 20
    entity_def.attack_type = nil
    entity_def.owner_loyal = true
    entity_def.damage = 0
end

minetest.register_on_mods_loaded(function()
    for _,animal in ipairs(animals) do
        local entity_def = minetest.registered_entities["mobs_animal:" .. animal]

		if animal == "sheep" then
		    for _,color in ipairs(all_colors) do
				local sheep_color_ent_def = minetest.registered_entities["mobs_animal:" .. animal .. "_" .. color]
			    if not sheep_color_ent_def then goto continue end

			    modify(sheep_color_ent_def)
			    ::continue::
		    end
	    end

        if not entity_def then goto continue end
	    modify(entity_def)

        ::continue::
    end
end)

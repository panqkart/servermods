----------------
-- Overrides --
----------------

local S = minetest.get_translator(minetest.get_current_modname())
local modpath = minetest.get_modpath(minetest.get_current_modname())

-- Overrides the animals to have specific values, such as being invencible.
if minetest.get_modpath("mobs_animal") then
	dofile(modpath .. "/mobs_animal_overrides.lua")
end

local old_grant_revoke = core_game.grant_revoke
function core_game.grant_revoke(name)
	local player = minetest.get_player_by_name(name)
	if not player then return end

	local privs = minetest.get_player_privs(name)

	-- Builders
	if privs.builder == true then
		player:set_nametag_attributes({
			text = "[BUILDER] " .. player:get_player_name(),
			color = {r = 0, g = 196, b = 0},
			bgcolor = false
		})
	else
		player:set_nametag_attributes({
			text = player:get_player_name(),
			color = {r = 255, g = 255, b = 255},
			bgcolor = false
		})
	end

    return old_grant_revoke(name)
end

-- Override the hand item
-- Do not let users break any nodes but let them rightclick on items
minetest.register_on_mods_loaded(function()
	minetest.after(0, function()
		minetest.override_item("", {
			tool_capabilities = { }
		})
	end)
end)

-- Don't allow players without the `core_admin` or `builder` privilege to interact with nodes.
local old_default_can_interact_with_node = default.can_interact_with_node
function default.can_interact_with_node(player, pos)
	if minetest.check_player_privs(player, { core_admin = true }) or minetest.check_player_privs(player, { builder = true }) then
		return true
	end
	return old_default_can_interact_with_node(player, pos)
end

-- Do not allow players to dig/place nodes if they don't have the `core_admin` or `builder` privilege
local old_minetest_item_place_node = minetest.item_place_node
function minetest.item_place_node(itemstack, placer, pointed_thing)
	if minetest.check_player_privs(placer, { core_admin = true }) or minetest.check_player_privs(placer, { builder = true }) then
		return old_minetest_item_place_node(itemstack, placer, pointed_thing)
	end

	minetest.chat_send_player(placer:get_player_name(), S("You're not allowed to place nodes unless you are a staff/builder. Contact the server administrator if this is a mistake."))
	return itemstack
end

local old_minetest_node_dig = minetest.node_dig
function minetest.node_dig(pos, node, digger)
	if minetest.check_player_privs(digger, { core_admin = true }) or minetest.check_player_privs(digger, { builder = true })  then
		return old_minetest_node_dig(pos, node, digger)
	end

	minetest.chat_send_player(digger:get_player_name(), S("You're not allowed to dig nodes unless you are a staff/builder. Contact the server administrator if this is a mistake."))
end

local sign_types = { "wood", "steel" }

-- Override the signs to make sure that no one can modify them.
minetest.register_on_mods_loaded(function()
	for _,type in ipairs(sign_types) do
		local node_def = minetest.registered_nodes["default:sign_wall_" .. type]
		if not node_def then goto continue end

		local old_on_receive_fields = node_def and node_def.on_receive_fields

		minetest.override_item("default:sign_wall_" .. type, {
			on_receive_fields = function(pos, formname, fields, sender)
				if not default.can_interact_with_node(sender, pos) and type ~= "wood" then
					return minetest.record_protection_violation(pos, sender:get_player_name())
				end

				return old_on_receive_fields(pos, formname, fields, sender)
			end,
		})

		::continue::
	end
end)

-- Do not let players sleep in beds as the spawnpoint could get messed up.
if minetest.get_modpath("beds") then
	local old_beds_on_rightclick = beds.on_rightclick
	function beds.on_rightclick(pos, player)
		if minetest.check_player_privs(player, { core_admin = true }) then
			return old_beds_on_rightclick(pos, player)
		end

		return false, S("You're not allowed to use beds unless you have higher privileges. Contact the server administrator if this is a mistake.")
	end
end

-- Start: code taken and modified from https://notabug.org/TenPlus1/mobs_redo
-- This code is licensed under the MIT license.
if minetest.get_modpath("mobs_redo") or minetest.get_modpath("mobs") then
	function mobs.mob_class:do_env_damage()

		-- feed/tame text timer (so mob 'full' messages dont spam chat)
		if self.htimer > 0 then
			self.htimer = self.htimer - 1
		end

		-- reset nametag after showing health stats
	--	if self.htimer < 1 and self.nametag2 then

	--		self.nametag = self.nametag2
	--		self.nametag2 = nil

			self:update_tag()
	--	end

		local pos = self.object:get_pos() ; if not pos then return end

		self.time_of_day = minetest.get_timeofday()

		-- halt mob if standing inside ignore node
		if self.standing_in == "ignore" then

			self.object:set_velocity(vector.new(0,0,0))

			return true
		end

		-- particle appears at random mob height
		local py = vector.new(pos.x, pos.y + math.random(self.collisionbox[2], self.collisionbox[5]), pos.z)
		local nodef = minetest.registered_nodes[self.standing_in]

		-- water
		if self.water_damage ~= 0 and nodef.groups.water then

			self.health = self.health - self.water_damage

			mobs:effect(py, 5, "bubble.png", nil, nil, 1, nil)

			if self:check_for_death({type = "environment",
					pos = pos, node = self.standing_in}) then
				return true
			end

		-- lava damage
		elseif self.lava_damage ~= 0 and nodef.groups.lava  then

			self.health = self.health - self.lava_damage

			mobs:effect(py, 15, "fire_basic_flame.png", 1, 5, 1, 0.2, 15, true)

			if self:check_for_death({type = "environment", pos = pos,
					node = self.standing_in, hot = true}) then
				return true
			end

		-- fire damage
		elseif self.fire_damage ~= 0 and nodef.groups.fire then

			self.health = self.health - self.fire_damage

			mobs:effect(py, 15, "fire_basic_flame.png", 1, 5, 1, 0.2, 15, true)

			if self:check_for_death({type = "environment", pos = pos,
					node = self.standing_in, hot = true}) then
				return true
			end

		-- damage_per_second node check (not fire and lava)
		elseif nodef.damage_per_second ~= 0
		and nodef.groups.lava == nil and nodef.groups.fire == nil then

			self.health = self.health - nodef.damage_per_second

			mobs:effect(py, 5, "tnt_smoke.png")

			if self:check_for_death({type = "environment",
					pos = pos, node = self.standing_in}) then
				return true
			end
		end

		-- air damage
		if self.air_damage ~= 0 and self.standing_in == "air" then

			self.health = self.health - self.air_damage

			mobs:effect(py, 3, "bubble.png", 1, 1, 1, 0.2)

			if self:check_for_death({type = "environment",
					pos = pos, node = self.standing_in}) then
				return true
			end
		end

		-- is mob light sensative, or scared of the dark :P
		if self.light_damage ~= 0 then

			local light = minetest.get_node_light(pos) or 0

			if light >= self.light_damage_min
			and light <= self.light_damage_max then

				self.health = self.health - self.light_damage

				mobs:effect(py, 5, "tnt_smoke.png")

				if self:check_for_death({type = "light"}) then
					return true
				end
			end
		end

		--- suffocation inside solid node
		if (self.suffocation and self.suffocation ~= 0)
		and (nodef.walkable == nil or nodef.walkable == true)
		and (nodef.collision_box == nil or nodef.collision_box.type == "regular")
		and (nodef.node_box == nil or nodef.node_box.type == "regular")
		and (nodef.groups.disable_suffocation ~= 1) then

			local damage

			if self.suffocation == true then
				damage = 2
			else
				damage = (self.suffocation or 2)
			end

			-- Added by team PanqKart to prevent tamed animals from dying.
			if not self.tamed then
				self.health = self.health - damage
			end

			if self:check_for_death({type = "suffocation",
					pos = pos, node = self.standing_in}) then
				return true
			end
		end

		return self:check_for_death({type = "unknown"})
	end
end
-- End: code taken and modified from https://notabug.org/TenPlus1/mobs_redo

-------------------------------
-- Privileges/miscellaneous --
-------------------------------

if minetest.get_modpath("abripanes") and minetest.get_modpath("dye") then
	abripanes.register_pane("abriglass_pane_dark", {
		description = "Dark Glass Pane",
		textures = {"abriglass_plainglass.png^[colorize:#292421:122", "abriglass_plainglass.png^[colorize:#292421:122",
			"abriglass_plainglass.png^[colorize:#292421:122"},
		groups = {cracky = 3},
		use_texture_alpha = "blend",
		wield_image = "abriglass_plainglass.png^[colorize:#292421:122",
		inventory_image = "abriglass_plainglass.png^[colorize:#292421:122",
		sounds = default.node_sound_glass_defaults(),
		recipe = {
			{ "default:glass", "default:glass", "default:glass" },
			{ "default:glass", "default:glass", "default:glass" },
			{ "", 			   "dye:black", 	"" }
		}
	})

	minetest.register_alias("xpanes:abriglass_pane_dark_flat", "xpanes:abriglass_pane_black_flat")
end

minetest.register_privilege("builder", {
    description = S("Can remove and add nodes, but doesn't have administrator privileges."),
    give_to_singleplayer = false,
    give_to_admin = false,

    on_grant = core_game.grant_revoke,
    on_revoke = core_game.grant_revoke
})

minetest.register_on_joinplayer(function(player)
    -- Secret! 🤫
    if player:get_player_name() == "Panquesito7" then
        player_api.set_texture(player, 1, "panqkart_modifications_panq_skin.png")
    elseif player:get_player_name() == "Crystal741" then
        player_api.set_texture(player, 1, "panqkart_modifications_crystal_skin.png")
    end
end)

minetest.register_on_newplayer(function(player)
    if minetest.check_player_privs(player, { ban = true, kick = true }) then -- Security reasons.
        minetest.set_player_privs(player, { ban = false, kick = false })
    end
end)

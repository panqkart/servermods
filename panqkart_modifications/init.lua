--[[
Extra modifications for the PanqKart server.

Copyright (C) 2022-2023 David Leal (halfpacho@gmail.com)
Copyright (C) Various other Minetest contributors and developers

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
USA
--]]

----------------
-- Overrides --
----------------

local S = minetest.get_translator(minetest.get_current_modname())

local old_grant_revoke = core_game.grant_revoke
function core_game.grant_revoke(name)
	local player = minetest.get_player_by_name(name)
	if not player then return end

	local privs = minetest.get_player_privs(name)
	if privs.core_admin == true then return old_grant_revoke(name) end

	-- Builders
	if privs.builder == true then
		player:set_nametag_attributes({
			text = "[BUILDER] " .. player:get_player_name(),
			color = {r = 0, g = 196, b = 0},
			bgcolor = false
		})
		return
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
			range = 4,
			tool_capabilities = {
				full_punch_interval = 0.5,
				max_drop_level = 3,
				groupcaps = {
					crumbly = nil,
					cracky  = nil,
					snappy  = nil,
					choppy  = nil,
					oddly_breakable_by_hand = nil,
					-- dig_immediate group doesn't use value 1. Value 3 is instant dig
					dig_immediate =
						{times = {[2] = nil, [3] = nil}, uses = 0, maxlevel = 0},
				},
				damage_groups = {fleshy = 1},
			}
		})
	end)
end)

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

	minetest.chat_send_player(placer:get_player_name(), "You're not allowed to place nodes unless you are a staff/builder. If this is a mistake, please contact the server administrator.")
	return itemstack
end

local old_minetest_node_dig = minetest.node_dig
function minetest.node_dig(pos, node, digger)
	if minetest.check_player_privs(digger, { core_admin = true }) or minetest.check_player_privs(digger, { builder = true })  then
		return old_minetest_node_dig(pos, node, digger)
	end

	minetest.chat_send_player(digger:get_player_name(), "You're not allowed to dig nodes unless you are a staff/builder. If this is a mistake, please contact the server administrator.")
end

-- Override the signs to make them unbreakable and uneditable, only by owners or those who have permissions.
local function register_sign(material, desc, def)
	minetest.register_node(":default:sign_wall_" .. material, {
		description = desc,
		drawtype = "nodebox",
		tiles = {"default_sign_wall_" .. material .. ".png"},
		inventory_image = "default_sign_" .. material .. ".png",
		wield_image = "default_sign_" .. material .. ".png",
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		is_ground_content = false,
		walkable = false,
		use_texture_alpha = "opaque",
		node_box = {
			type = "wallmounted",
			wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
			wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
			wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
		},
		groups = def.groups,
		legacy_wallmounted = true,
		sounds = def.sounds,

		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", "field[text;;${text}]")
			meta:set_string("owner", "") -- Added by team PanqKart
		end,
		after_place_node = function(pos, placer)
			-- Added by team PanqKart

			local meta = minetest.get_meta(pos)
			meta:set_string("owner", placer:get_player_name() or "")
			meta:set_string("infotext", '')
		end,
		can_dig = function(pos, player)
			-- Added by team PanqKart

			local meta = minetest.get_meta(pos)
			if meta:get_string("infotext") ~= '' then return end

			return default.can_interact_with_node(player, pos)
		end,
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			-- Added by team PanqKart
			local player_name = clicker:get_player_name()
			local meta = minetest.get_meta(pos)
			if minetest.is_protected(pos, player_name) or default.can_interact_with_node(clicker, pos) == false then
				minetest.record_protection_violation(pos, player_name)
				meta:set_string("formspec", "")
				return
			else
				meta:set_string("formspec", "field[text;;${text}]")
			end
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			local player_name = sender:get_player_name()

			-- Added by team PanqKart
			if minetest.is_protected(pos, player_name) or default.can_interact_with_node(sender, pos) == false and not material == "wood" then
				minetest.record_protection_violation(pos, player_name)
				return
			end
			local text = fields.text
			if not text then
				return
			end
			if string.len(text) > 512 then
				minetest.chat_send_player(player_name, minetest.get_translator("default")("Text too long"))
				return
			end
			minetest.log("action", player_name .. " wrote \"" .. text ..
				"\" to the sign at " .. minetest.pos_to_string(pos))
			local meta = minetest.get_meta(pos)
			meta:set_string("text", text)

			if #text > 0 then
				meta:set_string("infotext", minetest.get_translator("default")('"@1"', text))
			else
				meta:set_string("infotext", '')
			end
		end,
	})
end

register_sign("wood", minetest.get_translator("default")("Wooden Sign"), {
	sounds = default.node_sound_wood_defaults(),
	groups = {choppy = 2, attached_node = 1, flammable = 2, oddly_breakable_by_hand = 3}
})

register_sign("steel", minetest.get_translator("default")("Steel Sign"), {
	sounds = default.node_sound_metal_defaults(),
	groups = {cracky = 2, attached_node = 1}
})

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

minetest.register_privilege("builder", {
    description = S("Can remove and add nodes, while doesn't have administrator privileges."),
    give_to_singleplayer = false,
    give_to_admin = false,

    on_grant = core_game.grant_revoke,
    on_revoke = core_game.grant_revoke
})

minetest.register_on_joinplayer(function(player)
    -- Secret! 🤫
    if player:get_player_name() == "Panquesito7" then
        player_api.set_texture(player, 1, "panqkart_modifications_panq_skin.png")
    --elseif player:get_player_name() == "Crystal741" then
        --player_api.set_texture(player, 1, "panqkart_modifications_crystal_skin.png")
    end
end)

minetest.register_on_newplayer(function(player)
    if minetest.check_player_privs(player, { ban = true, kick = true }) then -- Security reasons.
        minetest.set_player_privs(player, { ban = false, kick = false })
    end
end)

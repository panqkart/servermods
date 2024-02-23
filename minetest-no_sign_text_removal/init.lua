local sign_types = { "wood", "steel" }

minetest.register_on_mods_loaded(function()
	for _,type in ipairs(sign_types) do
		local node_def = minetest.registered_nodes["default:sign_wall_" .. type]
		if not node_def then goto continue end

		minetest.override_item("default:sign_wall_" .. type, {
			can_dig = function(pos)
				local meta = minetest.get_meta(pos)
				return meta:get_string("infotext") == ""
			end
		})

		::continue::
	end
end)

unused_args = false
allow_defined_top = true
max_line_length = false

globals = {
    "minetest", "core_game", "default",
    "lucky_block", "player_api", "mobs"
}

read_globals = {
    string = {fields = {"split", "trim"}},
    table = {fields = {"copy", "getn"}},

    "ItemStack", "intllib", "cmi",
    "invisibility", "toolranks", "tnt",

    "vector", "farming", "player_monoids"
}

-- We don't wanna mess up Mobs REDO API.
-- An issue has been made on the original repository to discuss this.
files["mobs_redo/api.lua"].ignore = { "" }
files["mobs_animal/locale/po2tr.lua"].ignore = { "" }

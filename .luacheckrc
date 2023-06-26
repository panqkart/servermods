unused_args = false
allow_defined_top = true
max_line_length = false

globals = {
    "minetest", "core_game", "default",
    "lucky_block", "player_api", "mobs", "beds"
}

read_globals = {
    string = {fields = {"split", "trim"}},
    table = {fields = {"copy", "getn"}},

    "ItemStack", "intllib", "cmi",
    "invisibility", "toolranks", "tnt",

    "vector", "farming", "player_monoids"
}

-- Ignore Mobs Redo warnings. Those should be fixed/reported upstream.
files["mobs_redo/*.lua"].ignore = { "" }
files["mobs_animal/locale/po2tr.lua"].ignore = { "" }

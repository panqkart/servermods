local config = {
    labels_update = "dependencies"
}

local repos = {
    {
        name = "cozy",
        url = "https://github.com/minetest-mods/cozy",
        dir = ""
    },
    {
        name = "mobs_redo",
        url = "https://codeberg.org/tenplus1/mobs_redo",
        dir = "",
        def_branch = "master"
    },
    {
        name = "minetest-no_sign_text_removal",
        url = "https://github.com/Panquesito7/minetest-no_sign_text_removal",
        dir = ""
    }
}

return {
    repos = repos,
    config = config
}

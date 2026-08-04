-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Catppuccin Mocha パレット (https://catppuccin.com/palette)
local mocha = {
    mauve    = "cba6f7",
    lavender = "b4befe",
    blue     = "89b4fa",
    surface1 = "45475a",
    overlay0 = "6c7086",
    base     = "1e1e2e",
    crust    = "11111b",
}

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 2,

        col = {
            -- アクティブ: mauve → lavender のグラデーション
            active_border   = { colors = { "rgba(" .. mocha.mauve .. "ee)", "rgba(" .. mocha.lavender .. "ee)" }, angle = 45 },
            inactive_border = "rgba(" .. mocha.surface1 .. "aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee11111b, -- mocha.crust
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },
})

return mocha

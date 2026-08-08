-----------------------
---- LOOK AND FEEL ----
-----------------------

-- グレー寄りの青パレット (Nord 風)
local palette = {
    blue     = "81a1c1", -- くすんだ青
    frost    = "a3b8d8", -- 明るめのグレーブルー
    steel    = "5e81ac", -- 濃いめのスチールブルー
    surface1 = "434c5e",
    overlay0 = "6c7689",
    base     = "20242e",
    crust    = "14171f",
}

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 2,

        col = {
            -- アクティブ: くすんだ青 → 明るいグレーブルー のグラデーション
            active_border   = { colors = { "rgba(" .. palette.blue .. "ee)", "rgba(" .. palette.frost .. "ee)" }, angle = 45 },
            inactive_border = "rgba(" .. palette.surface1 .. "aa)",
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
            color        = 0xee14171f, -- palette.crust
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },
})

return palette

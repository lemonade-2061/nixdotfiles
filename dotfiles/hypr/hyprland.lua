-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- HYPRLAND CONFIG (エントリポイント)                     --
-- マシン固有の設定 + 分割ファイルの require              --
-- https://wiki.hypr.land/Configuring/Start/             --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- 分割ファイル:
--   programs.lua   … 共有プログラム変数 (binds.lua から require)
--   theme.lua      … グレーブルーパレット + general/decoration
--   animations.lua … カーブ + アニメーション定義
--   binds.lua      … キーバインド
--   rules.lua      … ウィンドウルール


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function ()
    hl.exec_cmd("fcitx5 --replace -d")  -- 日本語入力
    hl.exec_cmd("qs")                   -- Quickshell バー
    hl.exec_cmd("awww-daemon")          -- 壁紙デーモン (swww後継、パッケージ名はswwwのまま)
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- 日本語入力 (fcitx5) 用の入力メソッド環境変数
-- waylandFrontend = true なので GTK/Qt は text-input-v3 経由で入力する。
-- GTK_IM_MODULE / QT_IM_MODULE を設定すると D-Bus モジュール経由になり、
-- Firefox 等で候補ウィンドウの位置ずれ・確定不能が起きるため設定しない。
hl.env("XMODIFIERS", "@im=fcitx")   -- XWayland アプリ用
hl.env("SDL_IM_MODULE", "fcitx")    -- SDL は text-input 非対応


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


---------------------
---- LOOK & FEEL ----
---------------------

require("theme")
require("animations")


-----------------
---- LAYOUTS ----
-----------------

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------------
---- BINDS & RULES ----
---------------------------

require("binds")
require("rules")

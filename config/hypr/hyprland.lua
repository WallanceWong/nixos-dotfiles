--  ╭──────────────────────────────────────────────────────────────╮
--  │  eva — UNIT-01 / NERV HQ          Super+Shift+U switches     │
--  ╰──────────────────────────────────────────────────────────────╯
-- Hyprland's Lua config (hyprlang .conf is gone from 0.57 on). The API is in
-- <hyprland>/share/hypr/stubs/hl.meta.lua.

local home = os.getenv("HOME")
local hypr = home .. "/nixos-dotfiles/config/hypr"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- the active setup: border colours, rounding and motion, generated from
-- theme/setups/<id>.json by theme/eva.nix. eva-switch flips the link and runs
-- it again (`hyprctl eval 'EvaLoadSetup()'`), so a switch needs no full reload.
local function loadSetup()
    local ok, err = pcall(dofile, home .. "/.config/eva/current/hypr.lua")
    if not ok then hl.notification.create({ text = "eva: setup file failed: " .. tostring(err), timeout = 8000 }) end
end
loadSetup()
EvaLoadSetup = loadSetup

-- ── autostart ────────────────────────────────────────────────────
-- The desktop itself — living wallpaper, bar, notifications, panels — is
-- nerv-shell (Quickshell), a systemd user service that starts with the session
-- target below. Super+Ctrl+R restarts it; Super+Ctrl+B falls back to the
-- waybar setup if it ever breaks.
hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("fcitx5 -d -r")
    -- systemd's graphical session (needed by xdg-desktop-portal and hypridle.service)
    hl.exec_cmd("dbus-update-activation-environment --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XMODIFIERS && systemctl --user stop hyprland-session.target; systemctl --user start hyprland-session.target")
    -- Autologin skips the password, so lock once at login (the Eva-01 boot lock).
    -- Unlocking also unlocks the keyring, but only once its components are
    -- initialised, so start them first.
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,pkcs11 > /dev/null; " .. hypr .. "/lock.sh login")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- ── input ────────────────────────────────────────────────────────
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            disable_while_typing = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = function() hl.dispatch(hl.dsp.global("quickshell:overview")) end })

-- ── look (colours, rounding and animations come from the setup file) ──
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 14,
        border_size = 2,
        resize_on_border = true,
        layout = "dwindle",
        -- lets games skip vsync for lower input lag (only windows with "immediate")
        allow_tearing = true,
    },
    decoration = {
        active_opacity = 1.0,
        inactive_opacity = 0.96,
        dim_inactive = true,
        dim_strength = 0.05,
        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            vibrancy = 0.2,
            noise = 0.015,
            popups = true,
        },
        shadow = {
            enabled = true,
            range = 22,
            render_power = 3,
        },
    },
    dwindle = { preserve_split = true },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        -- if the lock screen ever crashes, a restarted shell (or hyprlock) can take over
        allow_session_lock_restore = true,
    },
    cursor = { inactive_timeout = 8 },
})

-- ── rules ────────────────────────────────────────────────────────
hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true, size = { 720, 480 }, center = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true, size = { 760, 520 }, center = true })
hl.window_rule({ match = { class = "^(mpv)$" }, float = true, center = true })
hl.window_rule({ match = { title = "^(File Operation Progress)$" }, float = true })
-- file open/save dialogs: without a size they open screen-sized and the
-- Save/Cancel header row ends up hidden under the bar
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, float = true, size = { "(monitor_w*0.6)", "(monitor_h*0.7)" }, center = true })
hl.window_rule({ match = { class = ".*" }, idle_inhibit = "fullscreen" })

-- VS Code and Cursor: frosted glass over the wallpaper, like kitty
hl.window_rule({ match = { class = "^([Cc]ode|[Cc]ursor)$" }, opacity = "0.95 override 0.9 override" })

-- Roblox (Sober): no effects, and tearing allowed for lower latency
hl.window_rule({ match = { class = "^(org.vinegarhq.Sober)$" }, immediate = true, no_blur = true, no_anim = true, no_shadow = true, no_dim = true })

-- scratch terminal that drops in over everything (Super + `)
hl.workspace_rule({ workspace = "special:term", on_created_empty = "kitty --class scratch" })
hl.window_rule({ match = { class = "^(scratch)$" }, float = true, size = { "(monitor_w*0.66)", "(monitor_h*0.6)" }, center = true, suppress_event = "maximize fullscreen" })

-- frosted glass behind every nerv-shell surface (not the wallpaper itself)
hl.layer_rule({ match = { namespace = "^(eva-(bar|control|dashboard|launcher|notifications|osd|overview|power|polkit|cheatsheet|settings))$" }, blur = true, ignore_alpha = 0.2 })
-- rescue desktop (Super+Ctrl+B)
hl.layer_rule({ match = { namespace = "^(waybar|rofi|notifications|logout_dialog)$" }, blur = true, ignore_alpha = 0.2 })

-- ── keys ─────────────────────────────────────────────────────────
local function key(keys, desc, dispatcher, opts)
    opts = opts or {}
    opts.description = desc
    hl.bind(keys, dispatcher, opts)
end
local exec, global = hl.dsp.exec_cmd, hl.dsp.global

key("SUPER + Q", "Terminal", exec("kitty"))
key("SUPER + C", "Close window", hl.dsp.window.close())
key("SUPER + M", "Log out (quit Hyprland)", hl.dsp.exit())
key("SUPER + E", "Files", exec("thunar"))
key("SUPER + SHIFT + E", "Code editor (VS Code)", exec("code"))
key("SUPER + V", "Float / tile window", hl.dsp.window.float({ action = "toggle" }))
key("SUPER + R", "App launcher", global("quickshell:launcher"))
key("SUPER + SPACE", "App launcher", global("quickshell:launcher"))
key("SUPER + P", "Pseudo-tile window", hl.dsp.window.pseudo())
key("SUPER + J", "Flip split direction", hl.dsp.layout("togglesplit"))
key("SUPER + F", "Fullscreen", hl.dsp.window.fullscreen({ action = "toggle" }))
key("SUPER + L", "Lock screen", exec(hypr .. "/lock.sh"))
key("SUPER + ESCAPE", "Power menu", global("quickshell:power"))
key("SUPER + TAB", "Workspace overview", global("quickshell:overview"))
key("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "previous" }))
key("SUPER + grave", "Drop-down terminal", hl.dsp.workspace.toggle_special("term"))
-- "minimize": park the window in a hidden drawer; Super+Shift+H shows/hides
-- the drawer (move a window out of it with Super+Shift+1..5)
key("SUPER + H", "Minimize window", hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
key("SUPER + SHIFT + H", "Show minimized windows", hl.dsp.workspace.toggle_special("minimized"))
key("SUPER + W", "Window switcher", global("quickshell:windows"))
key("SUPER + SHIFT + V", "Clipboard history", global("quickshell:clipboard"))
key("SUPER + PERIOD", "Emoji picker", global("quickshell:emoji"))
key("SUPER + N", "Control centre", global("quickshell:control"))
key("SUPER + SHIFT + N", "Do not disturb", global("quickshell:dnd"))
key("SUPER + D", "Dashboard", global("quickshell:dashboard"))
key("SUPER + G", "Game mode", global("quickshell:gamemode"))
key("SUPER + SLASH", "Keyboard shortcuts", global("quickshell:cheatsheet"))
key("SUPER + COMMA", "Settings", global("quickshell:settings"))
key("SUPER + SHIFT + U", "Switch setup (UNIT-01 / NERV HQ)", global("quickshell:setup"))

-- recording, drawing on screenshots, colour picker
key("SUPER + SHIFT + R", "Record a region", global("quickshell:record"))
key("SUPER + ALT + R", "Record the whole screen", global("quickshell:recordscreen"))
key("SUPER + SHIFT + A", "Draw on a screenshot", exec(hypr .. "/annotate.sh"))
key("SUPER + SHIFT + C", "Pick a colour", exec(hypr .. "/picker.sh"))
key("SUPER + ALT + C", "Auto clicker on/off", exec(hypr .. "/autoclick.sh"))

-- shell rescue: restart it, or fall back to the waybar setup
key("SUPER + CTRL + R", "Restart the shell", exec("systemctl --user restart nerv-shell"))
key("SUPER + CTRL + T", "Reset the touchpad", exec("systemctl start touchpad-reset && notify-send \"Touchpad reset\" \"Driver reloaded\""))
key("SUPER + CTRL + B", "Fallback desktop (waybar)", exec("systemctl --user stop nerv-shell; hyprpaper & waybar & mako & /run/current-system/sw/libexec/hyprpolkitagent &"))

for _, d in ipairs({ { "left", "l" }, { "right", "r" }, { "up", "u" }, { "down", "d" } }) do
    key("SUPER + " .. d[1], "Focus window", hl.dsp.focus({ direction = d[2] }))
    key("SUPER + SHIFT + " .. d[1], "Move window", hl.dsp.window.move({ direction = d[2] }))
end
for i = 1, 5 do
    key("SUPER + " .. i, "Go to workspace", hl.dsp.focus({ workspace = i }))
    key("SUPER + SHIFT + " .. i, "Move window to workspace", hl.dsp.window.move({ workspace = i }))
end
key("SUPER + mouse_down", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
key("SUPER + mouse_up", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume and brightness keys (repeat when held, work while locked). nerv-shell
-- shows the popup: it watches the volume itself, and is told about brightness
-- through "global".
key("XF86AudioRaiseVolume", "Volume up", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
key("XF86AudioLowerVolume", "Volume down", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
key("XF86AudioMute", "Mute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
key("XF86AudioMicMute", "Mute microphone", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
key("XF86MonBrightnessUp", "Brightness up", function()
    hl.dispatch(exec("brightnessctl -q set 5%+"))
    hl.dispatch(global("quickshell:brightness"))
end, { repeating = true, locked = true })
key("XF86MonBrightnessDown", "Brightness down", function()
    hl.dispatch(exec("brightnessctl -q set 5%-"))
    hl.dispatch(global("quickshell:brightness"))
end, { repeating = true, locked = true })
key("XF86AudioPlay", "Play / pause", exec("playerctl play-pause"), { locked = true })
key("XF86AudioNext", "Next track", exec("playerctl next"), { locked = true })
key("XF86AudioPrev", "Previous track", exec("playerctl previous"), { locked = true })

-- screenshots: saved to ~/Pictures/Screenshots and copied to the clipboard
key("Print", "Screenshot (whole screen)", exec(hypr .. "/screenshot.sh full"))
key("SHIFT + Print", "Screenshot (region)", exec(hypr .. "/screenshot.sh region"))
key("SUPER + SHIFT + S", "Screenshot (region)", exec(hypr .. "/screenshot.sh region"))

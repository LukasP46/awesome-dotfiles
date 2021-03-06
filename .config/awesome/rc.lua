-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")
local dpi = require("beautiful.xresources").apply_dpi

local spotify_widget = require("awesome-wm-widgets.spotify-widget.spotify")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_configuration_dir() .. "themes/gtk/theme.lua")
--beautiful.init(gears.filesystem.get_themes_dir() .. "gtk/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "alacritty"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    awful.layout.suit.floating,
    awful.layout.suit.fair,
    --awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Wibar

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    if s.geometry.width > s.geometry.height then
        awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
    else
        awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[2])
    end

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter = function (t) return t.selected or #t:clients() > 0 end,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    --[[s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.focused,
        style = {
            tasklist_disable_icon = true,
            align = "center",
            background = "black"
        }
    }]]
    s.mytasklist = awful.widget.tasklist {
        screen   = s,
        filter   = awful.widget.tasklist.filter.currenttags,
        buttons  = tasklist_buttons,
        style    = {
            tasklist_disable_icon = true,
            align = "center",
            background = "black"
        },
        layout   = {
            spacing = 10,
            spacing_widget = {
                {
                    forced_width = 5,
                    shape        = gears.shape.circle,
                    widget       = wibox.widget.separator
                },
                valign = "center",
                halign = "center",
                widget = wibox.container.place,
            },
            layout  = wibox.layout.flex.horizontal
        },
        -- Notice that there is *NO* wibox.wibox prefix, it is a template,
        -- not a widget instance.
        widget_template = {
            {
                {
                    {
                        id     = "text_role",
                        align = "center",
                        widget = wibox.widget.textbox,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                left  = 5,
                right = 5,
                widget = wibox.container.margin
            },
            id     = "background_role",
            widget = wibox.container.background,
        },
    }

    -- Overlay 
    s.myoverlaly = wibox({
        border_width = 0,
        ontop = true,
        visible = false,
        x = s.geometry.x,
        y = s.geometry.y,
        height = s.geometry.height,
        width = s.geometry.width,
        bg = beautiful.transparent_bg
    })
    s.myoverlaly.brightness_widget = wibox.widget{
        max_value     = 255,
        value         = 255,
        forced_height = 20,
        forced_width  = 100,
        shape         = gears.shape.rounded_bar,
        widget        = wibox.widget.progressbar,
        background_color = beautiful.wibar_fg
    }
    s.myoverlaly.volume_widget = wibox.widget{
        max_value     = 100,
        value         = 20,
        forced_height = 20,
        forced_width  = 100,
        shape         = gears.shape.rounded_bar,
        widget        = wibox.widget.progressbar,
        background_color = beautiful.wibar_fg
    }
    s.myoverlaly:setup {
        {
            {
                widget  = wibox.widget.textclock,
                refresh = 1,
                format  = "%d.%m.%y",
                align   = "center",
                font    = beautiful.font_normal_raw .. " 16"
            },
            {
                widget  = wibox.widget.textclock,
                refresh = 1,
                format  = "%H:%M:%S",
                align   = "center",
                font    = beautiful.font_raw .. " 64"
            },
            {
                {
                    {
                        image  = beautiful.icon_dir .. "16x16/actions/brightnesssettings.svg",
                        resize = false,
                        widget = wibox.widget.imagebox
                    },
                    right   = dpi(10),
                    widget  = wibox.container.margin
                },
                s.myoverlaly.brightness_widget,
                layout = wibox.layout.align.horizontal,
            },
            {
                {
                    {
                        image  = beautiful.icon_dir .. "16x16/actions/audio-volume-high.svg",
                        resize = false,
                        widget = wibox.widget.imagebox
                    },
                    right   = dpi(10),
                    widget  = wibox.container.margin
                },
                s.myoverlaly.volume_widget,
                layout = wibox.layout.align.horizontal,
            },
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(10)
        },
        widget = wibox.container.margin,
        margins = dpi(200)
    }


    local command = "brightnessctl get"
    awful.spawn.easy_async_with_shell(command, function(stdout)
        s.myoverlaly.brightness_widget:set_value(tonumber(stdout))
    end)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            require("battery-widget") {
                percent_colors = {
                    { 25, "red"   },
                    {999, beautiful.wibar_fg },
                },
                widget_text = "${AC_BAT}${color_on}${percent}%${color_off} ",
                tooltip_text = "Battery ${state}${time_est}",
                alert_threshold = 5,
                alert_timeout = 0,
                alert_title = "Low battery !",
                alert_text = "${AC_BAT}${time_est}"
            },
            wibox.widget.systray(),
            wibox.widget.textclock(" %H:%M:%S ", 1),
            s.mylayoutbox,
        },
    }
end)
-- }}}


root.buttons(gears.table.join(
    awful.button({ modkey }, 4, awful.tag.viewnext),
    awful.button({ modkey }, 5, awful.tag.viewprev)
))

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),

    -- More

    -- Overlay Stuff
    awful.key({ }, "XF86WakeUp",
    function()
        awful.screen.focused().myoverlaly.visible = true
    end,
    {description = "Show Overlay", group = "awesome"}),
    awful.key({ }, "XF86WakeUp", nil,
    function()
        -- ToDo: Add refresh to values
        awful.screen.focused().myoverlaly.visible = false
    end,
    {description = "Hide Overlay", group = "awesome"}),

    --awful.key({ modkey }, "F12",
    awful.key({ modkey }, "F12",
    function()
        awful.spawn.with_shell("bash ~/.scripts/theme-switch.sh")
        --awful.screen.connect_for_each_screen(beautiful.at_screen_connect)
        awesome.restart()
    end,
    {description = "switch dark/light", group = "awesome"}),
    awful.key({ modkey }, "b",
    function ()
        awful.util.spawn("xset s activate")
    end,
    {description = "lock screen", group = "awesome"}),
    awful.key({ }, "Print",
    function ()
        awful.util.spawn("flameshot full -c -p /home/lukas/pictures/screenshots/")
    end,
    {description = "screenshot full screen", group = "awesome"}),
    awful.key({ modkey }, "Print",
    function ()
        awful.util.spawn("flameshot gui -p /home/lukas/pictures/screenshots/")
    end,
    {description = "screenshot section screen", group = "awesome"}),

    -- Volume and Mute
    awful.key({ }, "XF86AudioMute", function () awful.spawn.with_shell("amixer sset -q -D pulse Master toggle") end,
              {description = "mute audio", group = "awesome"}),
    awful.key({ }, "XF86AudioRaiseVolume", function ()
        local command = "amixer -D pulse sset Master 1%+"
        awful.spawn.easy_async_with_shell(command, function(stdout)
            awful.screen.focused().myoverlaly.volume_widget:set_value(tonumber(string.sub(stdout:match("%d+%%"), 1, -2)))
        end)
    end,
    {description = "audio +5% volume", group = "awesome"}),
    awful.key({ }, "XF86AudioLowerVolume", function ()
        local command = "amixer -D pulse sset Master 1%-"
        awful.spawn.easy_async_with_shell(command, function(stdout)
            awful.screen.focused().myoverlaly.volume_widget:set_value(tonumber(string.sub(stdout:match("%d+%%"), 1, -2)))
        end)
    end,
    {description = "audio -5% volume", group = "awesome"}),
    awful.key({ }, "XF86AudioMicMute", function () awful.spawn.with_shell("amixer sset -q -D pulse Capture toggle") end,
              {description = "mute mic", group = "awesome"}),

    -- Brightness
    awful.key({ }, "XF86MonBrightnessDown", function ()
        local command = "brightnessctl -q set 1%-; brightnessctl get"
        awful.spawn.easy_async_with_shell(command, function(stdout)
            awful.screen.focused().myoverlaly.brightness_widget:set_value(tonumber(stdout))
        end)
    end,
    {description = "brighten screen", group = "awesome"}),
    awful.key({ }, "XF86MonBrightnessUp", function ()
        local command = "brightnessctl -q set +1%; brightnessctl get"
        awful.spawn.easy_async_with_shell(command, function(stdout)
            awful.screen.focused().myoverlaly.brightness_widget:set_value(tonumber(stdout))
        end)
    end,
    {description = "brighten dimm", group = "awesome"}),
    -- Paste just Text
    awful.key({ modkey }, "v", function ()
        os.execute("xsel | tr -s '\n' ' ' | xsel -i; xdotool click --clearmodifiers 2; xdotool keyup Super_L; xdotool keyup --clearmodifiers Super_L")
    end,
    {description = "paste", group = "awesome"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"}),
        awful.key({ modkey, "Shift"   }, "f",
            function (c)
                c.maximized = not c.maximized
                c:raise()
            end ,
            {description = "(un)maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end),
    awful.button({ modkey }, 4, function (c)
        awful.tag.viewnext(awful.mouse.screen)
    end),
    awful.button({ modkey }, 5, function (c)
        awful.tag.viewprev(awful.mouse.screen)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to dnew clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },

    -- ulauncher
    { rule = { instance = "ulauncher" },
    properties = {
        float = true,
        fullscreen = true,
        border_width = 0,
        ontop = true,
    }  },

    -- windows VM
    { rule = { name = "windows-remote" },
    properties = {
        border_width = 0
    }  },

    -- windows VM
    { rule = { class = "win10window" },
    properties = {
        float = false,
        maximized = false,
        border_width = 0,
        type = "normal"
    }  }
    

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) 
    --if not string.match(c.instance, "ulauncher") then
        c.border_color = beautiful.border_focus
    --end
end)
client.connect_signal("unfocus", function(c)
    --if not string.match(c.instance, "ulauncher") then
        c.border_color = beautiful.border_normal
    --end
end)
-- }}}

-- Auto-run
-- Fix for Mic LED, set Master Volume to 20% and mute it
--awful.spawn.with_shell("amixer -c 1 sset Capture nocap; amixer -D pulse sset Capture nocap; amixer -D pulse sset Master 20%; amixer -D pulse sset Master mute")

do
    local cmds =
    {
      --"picom -b --experimental-backends",
      "ulauncher --hide-window",
      "nm-applet",
      "blueman-applet",
      "redshift-gtk -l 49.87167:8.65027"
    }
  
    for _,i in pairs(cmds) do
      awful.util.spawn(i)
    end
  end

-- Fix for ulauncher
awesome.connect_signal(
    'exit',
    function(args)
        awful.spawn.with_shell('pkill -f "python3 /usr/local/bin/ulauncher --hide-window"')
        awful.spawn.with_shell('pkill -f "redshift-gtk"')
    end
)

-- Overlaysetuo
--overlay_setup(s)

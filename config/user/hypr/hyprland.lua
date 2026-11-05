-- OrkaOS: your Hyprland config.
--
-- The OrkaOS defaults live in /usr/share/orka/hypr/orka/ and are loaded
-- first; the files next to this one are yours and are loaded afterwards, so
-- anything you set there wins. Check your changes with:
--   Hyprland --verify-config -c ~/.config/hypr/hyprland.lua

-- Change default apps here (see /usr/share/orka/hypr/orka/apps.lua), e.g.
-- ORKA_APPS = { browser = "chromium" }

package.path = "/usr/share/orka/hypr/?.lua;/usr/share/orka/hypr/?/init.lua;" .. package.path
require("orka")

-- Your settings (in ~/.config/hypr/).
require("monitors")
require("input")
require("looknfeel")
require("bindings")
require("autostart")

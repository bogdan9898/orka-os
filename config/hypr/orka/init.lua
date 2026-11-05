-- OrkaOS Hyprland defaults. Loaded from ~/.config/hypr/hyprland.lua with
--   package.path = "/usr/share/orka/hypr/?.lua;/usr/share/orka/hypr/?/init.lua;" .. package.path
--   require("orka")
-- Don't edit these files: they are replaced when OrkaOS updates. Put changes
-- in ~/.config/hypr/*.lua instead (loaded after these, so they win).

require("orka.envs")
require("orka.theme")
require("orka.looknfeel")
require("orka.input")
require("orka.windows")
require("orka.autostart")
require("orka.bindings.tiling")
require("orka.bindings.media")
require("orka.bindings.clipboard")
require("orka.bindings.apps")
require("orka.bindings.utilities")

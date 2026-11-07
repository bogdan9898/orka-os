-- Values from the OrkaOS settings app: theme colors, monitors, keyboard,
-- mouse cursor, animations.
-- orka-settings writes them to ~/.config/orka/current/hyprland.lua and runs
-- `hyprctl reload`. Missing file or values: the OrkaOS defaults stay.
local path = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/orka/current/hyprland.lua"
local ok, values = pcall(dofile, path)
if not ok or type(values) ~= "table" then
    values = {}
end
values.colors = values.colors or {}
values.monitors = values.monitors or {}
values.input = values.input or {}
values.cursor = values.cursor or {}
values.animations = values.animations or {}

-- Applied after the other OrkaOS defaults (orka/init.lua); your own files in
-- ~/.config/hypr/ come after this and still win.
function values.apply()
    for _, monitor in ipairs(values.monitors) do
        hl.monitor(monitor)
    end
    if next(values.input) then
        hl.config({ input = values.input })
    end
end

return values

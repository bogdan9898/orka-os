-- Key binding helper with sections. The section goes into the description
-- as "Section: text", which is all `hyprctl binds` reports about a Lua
-- binding, so the cheat sheet (SUPER + K) and orka-keybindings can group by
-- it. Bindings without a section are listed under "Your bindings".
--
--   local bind = require("orka.keys").section("Apps")
--   bind("SUPER + RETURN", "ghostty", "Terminal")        -- a command
--   bind("SUPER + W", hl.dsp.window.close(), "Close")    -- a dispatcher
--   bind("XF86AudioMute", "...", "Mute", { locked = true })
local keys = {}

function keys.section(name)
    return function(combo, action, description, opts)
        if type(action) == "string" then
            action = hl.dsp.exec_cmd(action)
        end
        opts = opts or {}
        opts.description = name .. ": " .. description
        hl.bind(combo, action, opts)
    end
end

return keys

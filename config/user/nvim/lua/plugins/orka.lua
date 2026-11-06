-- OrkaOS plugin settings. The colorscheme follows the OrkaOS theme
-- (Settings → Theme, "neovim" in ~/.config/orka/current/theme.json), also in
-- a running Neovim when it gets focus again. Without a theme: Tokyo Night.
local theme_file = vim.fn.expand("~/.config/orka/current/theme.json")

local function orka_colorscheme()
  local f = io.open(theme_file, "r")
  if f then
    local ok, theme = pcall(vim.json.decode, f:read("*a"))
    f:close()
    if ok and type(theme) == "table" and type(theme.neovim) == "string" and theme.neovim ~= "" then
      return theme.neovim
    end
  end
  return "tokyonight-night"
end

vim.api.nvim_create_autocmd("FocusGained", {
  desc = "Follow the OrkaOS theme",
  callback = function()
    local scheme = orka_colorscheme()
    if vim.g.colors_name ~= scheme then
      pcall(vim.cmd.colorscheme, scheme)
    end
  end,
})

return {
  { "folke/tokyonight.nvim", priority = 1000, opts = { style = "night" } },
  { "LazyVim/LazyVim", opts = { colorscheme = orka_colorscheme() } },
}

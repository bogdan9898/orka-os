-- OrkaOS plugin settings. Placeholder theme until the Orka theme exists
-- (roadmap TODO): Tokyo Night, Omarchy's default.
return {
  { "folke/tokyonight.nvim", priority = 1000, opts = { style = "night" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}

# OrkaOS themes

One directory per theme. Installed to `/usr/share/orka/themes/`; your own go in `~/.config/orka/themes/<id>/` (a theme there with the same `<id>` replaces the built-in one). Pick one in Settings → Theme or with `orka-settings set .theme '"<id>"'`.

`theme.json`:

```json
{
  "name": "Tokyo Night",
  "mode": "dark",                 // or "light": GTK/portal color scheme
  "colors": {                     // the shell, Hyprland borders, plain wallpaper
    "background": "#1a1b26", "foreground": "#c0caf5",
    "accent": "#7aa2f7", "accent2": "#bb9af7",
    "urgent": "#f7768e", "inactive": "#414868"
  },
  "ghostty": "TokyoNight Night",  // a built-in Ghostty theme (`ghostty +list-themes`), "" = Ghostty's default
  "neovim": "tokyonight-night",   // a Neovim colorscheme (tokyonight-*, catppuccin-* work offline)
  "wallpaper": "wallpaper.jpg"    // optional: an image in this directory, the theme's default wallpaper
}
```

Optional files next to it: `ghostty.conf` (used instead of the `ghostty` name, for custom colors). tmux follows the terminal's colors and needs nothing.

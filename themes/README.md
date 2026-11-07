# OrkaOS themes

One directory per theme. Installed to `/usr/share/orka/themes/`; your own go in `~/.config/orka/themes/<id>/` (a theme there with the same `<id>` replaces the built-in one). Settings → Theme has one choice for dark mode (themes with `"mode": "dark"`) and one for light mode (`"mode": "light"`); dark mode is switched with SUPER + CTRL + D. From a terminal: `orka-settings set .appearance.dark '"<id>"'` (or `.appearance.light`), `orka-settings mode toggle`.

`theme.json`:

```json
{
  "name": "Tokyo Night",
  "mode": "dark",                 // or "light": which mode it's offered for; GTK/portal color scheme
  "colors": {                     // the shell, Hyprland borders, plain wallpaper
    "background": "#1a1b26", "foreground": "#c0caf5",
    "accent": "#7aa2f7", "accent2": "#bb9af7",
    "urgent": "#f7768e", "inactive": "#414868"
  },
  "ghostty": "TokyoNight Night",  // a built-in Ghostty theme (`ghostty +list-themes`), "" = Ghostty's default
  "neovim": "tokyonight-night",   // a Neovim colorscheme (tokyonight-*, catppuccin-* work offline)
  "wallpaper": "wallpaper.jpg",   // optional: an image in this directory, the theme's default wallpaper
  "icons": "Papirus-Dark"         // optional: icon theme; default Papirus-Dark, or Papirus-Light for "mode": "light"
}
```

Optional files next to it: `ghostty.conf` (used instead of the `ghostty` name, for custom colors). tmux follows the terminal's colors and needs nothing. GTK and Qt apps get colors generated from `colors` (see [docs/settings.md](../docs/settings.md#themes)).

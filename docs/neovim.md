# Neovim

[LazyVim](https://lazyvim.org), like Omarchy (which ships it through its own `omarchy-nvim` package). Neovim 0.12. Open it with `n` in a terminal or `SUPER + SHIFT + N`.

## Works offline from the first start

LazyVim normally downloads its plugins, treesitter parsers and language servers from GitHub the first time Neovim starts. On OrkaOS that already happened while the ISO was built:

1. `iso/build.sh nvim` runs Neovim headless in a scratch home with our config, installs the plugins at the commits pinned in `config/user/nvim/lazy-lock.json` (`Lazy! restore`), then `iso/nvim-bundle.lua` installs LazyVim's parsers and Mason packages and checks that nothing is missing. The result (`~/.local/share/nvim`, ~170 MB) is packed as `nvim-data.tar.zst` on the ISO.
2. The installer unpacks it into the new user's `~/.local/share/nvim` and rewrites the build path inside Mason's wrapper scripts (`lua-language-server`) to the user's home. (Six compiled parsers still contain the build path as a source-file name in assert messages; it's never used.)

Tested 2026-11-06 in the VM install test (self-test line `nvim`): 32 plugins, none missing, Tokyo Night loaded, `lua_ls` attached to a Lua file, treesitter active, no build paths left in text files.

Language servers for other languages still download when you enable them (`:LazyExtras`, `:Mason`). Automatic update checks are off (`checker`), so Neovim never goes online by itself; run `:Lazy update` when you want new plugin versions.

## Files

| Where (installed) | From the repo | What |
|---|---|---|
| `~/.config/nvim/init.lua`, `lua/config/lazy.lua` | `config/user/nvim/` | LazyVim starter: loads lazy.nvim, LazyVim, then `lua/plugins/` |
| `~/.config/nvim/lua/config/{options,keymaps,autocmds}.lua` | same | Empty, for your settings |
| `~/.config/nvim/lua/plugins/orka.lua` | same | Theme: Tokyo Night (night), a placeholder until the Orka theme exists |
| `~/.config/nvim/lazy-lock.json` | same | Plugin versions. Changes when you `:Lazy update` |
| `~/.local/share/nvim/` | built by `build.sh nvim` | Plugins (`lazy/`), parsers (`site/`), Mason tools (`mason/`) |

Seeded by `orka-setup-user` like the other user files: changes you make are kept, new defaults arrive as `*.orka-new`.

**Updating the pinned versions** (in the repo): run `:Lazy update` in a Neovim that uses `config/user/nvim`, copy its `lazy-lock.json` into `config/user/nvim/`, rebuild with `build.sh nvim iso`. The `nvim` stage stops if the lockfile and the plugin list don't match.

## Basics

| Keys | Action |
|---|---|
| `SPACE` (wait) | Menu of all `SPACE` bindings (which-key) |
| `SPACE SPACE` / `SPACE /` | Find file / search text in the project |
| `SPACE e` | File tree |
| `SPACE ,` / `SHIFT + H`, `SHIFT + L` | Switch buffer / previous, next buffer |
| `SPACE g g` | lazygit |
| `g d`, `K`, `SPACE c a`, `SPACE c r` | Go to definition, docs, code action, rename |
| `SPACE l` / `SPACE x` | Lazy (plugins) / LazyVim extras (`:LazyExtras`) |
| `CTRL + /` | Terminal |

Full list: https://www.lazyvim.org/keymaps

## Included

32 plugins (LazyVim's default set: blink.cmp completion, snacks.nvim picker/explorer/dashboard, treesitter, LSP + Mason, conform formatting, nvim-lint, gitsigns, which-key, noice, lualine, bufferline, flash, trouble, ...). Parsers: bash, c, diff, html, javascript, jsdoc, json, lua, luadoc, luap, markdown, markdown_inline, printf, python, query, regex, toml, tsx, typescript, vim, vimdoc, xml, yaml. Mason: `lua-language-server`, `stylua`, `shfmt`.

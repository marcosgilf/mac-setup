# mac-setup

Opinionated macOS development environment with one shared Tokyo Night theme.

## Included tools

- **[zsh](https://github.com/zsh-users/zsh)** — interactive shell configured with:
  - [Starship](https://github.com/starship/starship) — customizable prompt.
  - [fzf](https://github.com/junegunn/fzf) — fuzzy finder for files and history.
  - [zoxide](https://github.com/ajeetdsouza/zoxide) — frecency-based directory
    navigation.
  - [eza](https://github.com/eza-community/eza) — modern `ls` replacement.
  - [bat](https://github.com/sharkdp/bat) — `cat` replacement with syntax
    highlighting.
  - [fd](https://github.com/sharkdp/fd) — fast, user-friendly file finder.
  - [ripgrep](https://github.com/BurntSushi/ripgrep) — fast recursive text search.
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) —
    suggests commands from history as you type.
  - [History substring search](https://github.com/zsh-users/zsh-history-substring-search) —
    searches history using the current command line.
  - [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode) — vi-style editing
    modes and keybindings.
  - [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) —
    highlights shell syntax while editing commands.

  Zsh plugins clone from GitHub on first shell startup.
- **[Neovim](https://github.com/neovim/neovim)** — editor configured with:
  - [LazyVim](https://github.com/LazyVim/LazyVim) — opinionated setup and plugin
    collection.
  - [lazy.nvim](https://github.com/folke/lazy.nvim) — plugin manager used by
    LazyVim.
  - [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) — LSP client
    configurations.
  - [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) —
    syntax parsing and highlighting.
  - [blink.cmp](https://github.com/Saghen/blink.cmp) — completion engine.
  - [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) — Git change
    indicators in the sign column.
  - [Tokyo Night](https://github.com/folke/tokyonight.nvim) — Neovim color
    scheme.
- **Node.js and nvm** — runtime and version manager:
  - [Node.js](https://github.com/nodejs/node) — JavaScript runtime; fresh setups
    default to v22, and Pi requires v22.19+.
  - [nvm](https://github.com/nvm-sh/nvm) — manages Node versions; existing
    selections are preserved.
- **[Pi](https://github.com/earendil-works/pi)** — terminal coding agent,
  installed globally with npm.
- **[Superfile](https://github.com/yorukot/superfile)** — terminal file manager,
  launched with `spf`.
- **Optional tools:**
  - [Ghostty](https://github.com/ghostty-org/ghostty) — GPU-accelerated terminal.
  - [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts) — font
    installed with Ghostty.
  - [Herdr](https://github.com/herdrdev/herdr) — terminal multiplexer for
    persistent workspaces and coding agents.

Homebrew manages core tools through `Brewfile`; installer prompts for optional
tools and links only their selected configs. Theme values live in
`theme/tokyo-night.sh`; `scripts/render-configs.sh` generates app-specific
configuration from those constants.

## Install

Requirements: macOS 13+. Install Apple Command Line Tools first if missing;
Git may open the installer prompt on a new Mac:

```sh
xcode-select --install
```

Wait for installation to finish, then clone and run setup. Installer installs
Homebrew if missing.

```sh
git clone https://github.com/marcosgilf/mac-setup ~/mac-setup
~/mac-setup/install.sh
```

Installer:

- installs core tools from `Brewfile` and prompts for Ghostty and Herdr only
  when they are not already installed
- preserves an existing nvm default/active version; sets Node.js 22 as default
  when no nvm Node is selected
- installs Pi if missing and runs `pi update --all` when Node.js is 22.19+;
  warns and skips Pi otherwise
- prints dependency progress and first-install launch steps; reruns report
  `Update completed.`
- renders configuration files from the shared theme
- links managed files into standard macOS config paths
- preserves existing configs as timestamped backups
- preserves untracked local zsh functions under `zsh/functions/local/`
- is safe to run again; it never pulls or overwrites managed repositories

Keep this repository at a stable path because managed symlinks point into it.

## Use

```sh
open -a Ghostty
herdr
pi
spf
nvim
```

Start a new shell after installation. Neovim plugins install on first launch;
`nvim/lazy-lock.json` records their versions.

## Update

```sh
cd ~/mac-setup
git pull
./install.sh
```

Run `:Lazy sync` inside Neovim when intentionally updating plugins, then commit
`nvim/lazy-lock.json`.

## Test

```sh
./scripts/test-install.sh
```

Smoke test stubs Homebrew, NVM, npm, and Pi; uses temporary home directories.

## Privacy boundary

Only portable configuration belongs here. Never add shell history, cloud or
Git credentials, Herdr sessions/logs, local environment files, private keys,
or work-specific commands. Put machine-only functions in
`zsh/functions/local/`; that directory is ignored.

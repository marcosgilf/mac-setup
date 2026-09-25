# mac-setup

Opinionated macOS development environment with one shared Tokyo Night theme.

## Included tools

- **zsh** — modular shell config with Starship, fzf, zoxide, eza, bat, fd, and
  syntax highlighting.
- **Neovim** — LazyVim configuration with sensible defaults, LSP support,
  Treesitter, completion, Git signs, and Tokyo Night.
- **Node.js 22 + nvm** — Node version manager with v22 as default.
- **Pi** — terminal coding agent, installed globally with npm.
- **Optional:** Ghostty terminal, Herdr multiplexer.

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

- installs core tools from `Brewfile` and prompts before installing Ghostty
  and Herdr (press Enter to accept each default)
- installs nvm, sets Node.js 22 as default, then installs Pi
- renders configuration files from the shared theme
- links managed files into standard macOS config paths
- preserves existing configs as timestamped backups
- preserves untracked local zsh functions under `zsh/functions/local/`
- is safe to run again; it never pulls or overwrites managed repositories

Keep this repository at a stable path because managed symlinks point into it.

## Use

```sh
open -a Ghostty
nvim
herdr
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

## Privacy boundary

Only portable configuration belongs here. Never add shell history, cloud or
Git credentials, Herdr sessions/logs, local environment files, private keys,
or work-specific commands. Put machine-only functions in
`zsh/functions/local/`; that directory is ignored.

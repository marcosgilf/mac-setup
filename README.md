# mac-setup

Opinionated macOS development environment with one shared Tokyo Night theme.

## Included tools

- **Ghostty** — GPU terminal with JetBrainsMono Nerd Font, generous padding,
  block cursor, and useful TUI keybindings.
- **zsh** — modular shell config with Starship, fzf, zoxide, eza, bat, fd, and
  syntax highlighting.
- **Neovim** — LazyVim configuration with sensible defaults, LSP support,
  Treesitter, completion, Git signs, and Tokyo Night.
- **Herdr** — persistent terminal workspace and agent multiplexer.

Homebrew manages installation through `Brewfile`. Theme values live in
`theme/tokyo-night.sh`; `scripts/render-configs.sh` generates app-specific
configuration from those constants.

## Install

Requirements: macOS 13+, Git, Homebrew.

```sh
git clone https://github.com/marcosgilf/mac-setup ~/mac-setup
~/mac-setup/install.sh
```

Installer:

- installs tools and font from `Brewfile`
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

#!/bin/zsh
set -euo pipefail

readonly ROOT=${0:A:h}
readonly CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
readonly ZSH_DIR="$CONFIG_HOME/zsh"
readonly NVIM_DIR="$CONFIG_HOME/nvim"

backup_target() {
  local target=$1
  [[ -e "$target" || -L "$target" ]] || return 0
  local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
  mv "$target" "$backup"
  print "backup: $target -> $backup"
}

link_config() {
  local source=$1 target=$2
  mkdir -p "${target:h}"
  [[ -L "$target" && "$(readlink "$target")" == "$source" ]] && return 0
  backup_target "$target"
  ln -s "$source" "$target"
  print "linked: $target"
}

preserve_local_zsh() {
  local source="$ZSH_DIR" file relative
  [[ -d "$source" && ! -L "$source" ]] || return 0

  for file in "$source"/functions/*.zsh; do
    [[ -f "$file" ]] || continue
    relative=${file#$source/}
    git -C "$source" ls-files --error-unmatch "$relative" >/dev/null 2>&1 && continue
    mkdir -p "$ROOT/zsh/functions/local"
    cp -p "$file" "$ROOT/zsh/functions/local/${file:t}"
    print "preserved local function: ${file:t}"
  done
}

command -v brew >/dev/null || { print -u2 'Homebrew required'; exit 1; }
brew bundle --file="$ROOT/Brewfile"

preserve_local_zsh
"$ROOT/scripts/render-configs.sh"

link_config "$ROOT/zsh" "$ZSH_DIR"
link_config "$ROOT/ghostty/config.ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
link_config "$ROOT/herdr/config.toml" "$CONFIG_HOME/herdr/config.toml"
link_config "$ROOT/nvim" "$NVIM_DIR"
link_config "$ROOT/bootstrap/zshenv" "$HOME/.zshenv"

print 'done: restart Ghostty and start a new shell'

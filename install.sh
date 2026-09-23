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

if ! xcode-select -p >/dev/null 2>&1; then
  print 'Install Command Line Tools, then rerun this script.'
  xcode-select --install || true
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  print 'Installing Homebrew...'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
else
  print -u2 'Homebrew installation failed'
  exit 1
fi

ask() {
  local reply
  read -r "reply?$1 [Y/n] " || { print -u2 'Input closed; aborting.'; exit 1; }
  [[ -z "$reply" || "$reply" == [Yy]* ]]
}

install_ghostty=0
install_herdr=0
install_tuicr=0
ask 'Install Ghostty terminal?' && install_ghostty=1
ask 'Install Herdr multiplexer?' && install_herdr=1
ask 'Install Tuicr?' && install_tuicr=1

brew bundle --file="$ROOT/Brewfile"
(( install_ghostty )) && brew install --cask font-jetbrains-mono-nerd-font ghostty
(( install_herdr )) && brew install herdr
(( install_tuicr )) && brew install tuicr

mkdir -p "$HOME/.nvm"
export NVM_DIR="$HOME/.nvm"
set +u # nvm.sh reads optional unset variables.
source "$(brew --prefix nvm)/nvm.sh"
nvm install 22
nvm alias default 22
nvm use default
npm install --global @mariozechner/pi-coding-agent

preserve_local_zsh
"$ROOT/scripts/render-configs.sh"

link_config "$ROOT/zsh" "$ZSH_DIR"
(( install_ghostty )) && link_config "$ROOT/ghostty/config.ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
(( install_herdr )) && link_config "$ROOT/herdr/config.toml" "$CONFIG_HOME/herdr/config.toml"
(( install_tuicr )) && link_config "$ROOT/tuicr/config.toml" "$CONFIG_HOME/tuicr/config.toml"
(( install_tuicr )) && link_config "$ROOT/tuicr/themes/tokyo-night.toml" "$CONFIG_HOME/tuicr/themes/tokyo-night.toml"
link_config "$ROOT/nvim" "$NVIM_DIR"
link_config "$ROOT/bootstrap/zshenv" "$HOME/.zshenv"

print 'done: start a new shell'

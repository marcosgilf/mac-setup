#!/bin/zsh
set -euo pipefail

readonly ROOT=${0:A:h}
readonly CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
readonly ZSH_DIR="$CONFIG_HOME/zsh"
readonly NVIM_DIR="$CONFIG_HOME/nvim"
is_update=0
[[ -L "$ZSH_DIR" && "$(readlink "$ZSH_DIR")" == "$ROOT/zsh" ]] && is_update=1

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

if [[ -n "${BREW_BIN:-}" ]]; then
  [[ -x "$BREW_BIN" ]] || { print -u2 "Invalid BREW_BIN: $BREW_BIN"; exit 1; }
  brew() { "$BREW_BIN" "$@"; }
  eval "$("$BREW_BIN" shellenv)"
else
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
fi

trace() {
  print -P "%F{green}✔︎%f $1"
}

ask() {
  local reply
  read -r "reply?$1 [Y/n] " || { print -u2 'Input closed; aborting.'; exit 1; }
  [[ -z "$reply" || "$reply" == [Yy]* ]]
}

ask_optional() {
  local type=$1 package=$2 prompt=$3
  if brew list "$type" "$package" >/dev/null 2>&1; then
    print "Using $package"
    return 0
  fi
  ask "$prompt"
}

install_if_missing() {
  local type=$1 package=$2
  brew list "$type" "$package" >/dev/null 2>&1 || brew install "$type" "$package"
}

install_ghostty=0
install_herdr=0
ask_optional --cask ghostty 'Install Ghostty terminal?' && install_ghostty=1
ask_optional --formula herdr 'Install Herdr multiplexer?' && install_herdr=1

(( install_ghostty )) && install_if_missing --cask font-jetbrains-mono-nerd-font
(( install_ghostty )) && install_if_missing --cask ghostty
(( install_herdr )) && install_if_missing --formula herdr
trace 'Optional dependencies updated'

HOMEBREW_COLOR=1 brew bundle --file="$ROOT/Brewfile" 2>&1 | awk '
  {
    line = tolower($0)
    gsub(/\033\[[0-9;]*m/, "", line)
    if (line !~ /brew bundle.*complete!/) print
  }
'
trace 'Brewfile dependencies updated'

mkdir -p "$HOME/.nvm"
export NVM_DIR="$HOME/.nvm"
set +u # nvm.sh reads optional unset variables.
source "$(brew --prefix nvm)/nvm.sh"
current_node=$(nvm current)
if [[ "$current_node" == system || "$current_node" == none ]]; then
  if [[ -s "$NVM_DIR/alias/default" ]]; then
    nvm use default
  else
    nvm install 22
    nvm alias default 22
  fi
else
  print "Using existing Node $current_node; leaving NVM default unchanged"
fi
current_node=$(nvm current)
pi_supported=1
if ! node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || (major === 22 && minor >= 19) ? 0 : 1)'; then
  print -u2 "Warning: Pi requires Node.js 22.19 or newer; active Node is $current_node. Pi install/update skipped. Run 'nvm install 22 && nvm use 22', then rerun ./install.sh; NVM default stays unchanged."
  pi_supported=0
fi
if (( pi_supported )); then
  if npm list --global --depth=0 @mariozechner/pi-coding-agent >/dev/null 2>&1; then
    npm uninstall --global @mariozechner/pi-coding-agent
  fi
  if ! npm list --global --depth=0 @earendil-works/pi-coding-agent >/dev/null 2>&1; then
    npm install --global --ignore-scripts --no-fund @earendil-works/pi-coding-agent
  fi
  pi update --all
fi

preserve_local_zsh
"$ROOT/scripts/render-configs.sh"

link_config "$ROOT/zsh" "$ZSH_DIR"
(( install_ghostty )) && link_config "$ROOT/ghostty/config.ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
(( install_herdr )) && link_config "$ROOT/herdr/config.toml" "$CONFIG_HOME/herdr/config.toml"
link_config "$ROOT/nvim" "$NVIM_DIR"
link_config "$ROOT/bootstrap/zshenv" "$HOME/.zshenv"

if (( is_update )); then
  if (( pi_supported )); then
    trace 'Update completed. Have fun!'
  else
    trace 'Update completed; Pi update skipped.'
  fi
else
  trace 'Install complete.'
  if (( pi_supported == 0 )); then
    print 'Next: run nvm install 22 && nvm use 22, then rerun ./install.sh to install Pi.'
  elif (( install_ghostty && install_herdr )); then
    print 'Next: open Ghostty, run herdr, then start a Pi session in Herdr.'
  elif (( install_ghostty )); then
    print 'Next: open Ghostty, then start a Pi session with pi.'
  elif (( install_herdr )); then
    print 'Next: run herdr, then start a Pi session in Herdr.'
  else
    print 'Next: start a Pi session with pi in your terminal.'
  fi
fi

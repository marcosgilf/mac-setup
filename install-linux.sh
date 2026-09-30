#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
ZSH_DIR="$CONFIG_HOME/zsh"
NVIM_DIR="$CONFIG_HOME/nvim"
is_update=0
[[ -L "$ZSH_DIR" && "$(readlink "$ZSH_DIR")" == "$ROOT/zsh" ]] && is_update=1

[[ "$(uname -s)" == Linux ]] || { echo 'This installer supports Linux only.' >&2; exit 1; }
[[ -r /etc/os-release ]] || { echo 'Cannot identify Linux distribution.' >&2; exit 1; }
source /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *' debian '*|*' ubuntu '*) ;;
  *) echo 'Supported distributions: Debian and Ubuntu (and derivatives).' >&2; exit 1 ;;
esac
(( EUID != 0 )) || { echo 'Run as a normal user with sudo access, not as root.' >&2; exit 1; }

brew_bin=${BREW_BIN:-}
if [[ -z "$brew_bin" ]]; then
  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    brew_bin=/home/linuxbrew/.linuxbrew/bin/brew
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    brew_bin="$HOME/.linuxbrew/bin/brew"
  elif command -v brew >/dev/null 2>&1; then
    brew_bin=$(command -v brew)
  fi
fi

apt_packages=()
if [[ -z "$brew_bin" ]]; then
  apt_packages=(build-essential procps curl file git)
fi
[[ -x /bin/zsh ]] || apt_packages+=(zsh)
if (( ${#apt_packages[@]} )); then
  if ! command -v sudo >/dev/null 2>&1; then
    echo 'sudo is required to install Linux prerequisites.' >&2
    exit 1
  fi
  if ! command -v apt-get >/dev/null 2>&1; then
    echo 'apt-get is required for Debian/Ubuntu setup.' >&2
    exit 1
  fi
  sudo apt-get update
  sudo apt-get install -y "${apt_packages[@]}"
fi

if [[ -z "$brew_bin" ]]; then
  NONINTERACTIVE=1 /bin/bash -c "$(
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
  )"
  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    brew_bin=/home/linuxbrew/.linuxbrew/bin/brew
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    brew_bin="$HOME/.linuxbrew/bin/brew"
  else
    echo 'Homebrew installation failed.' >&2
    exit 1
  fi
fi
[[ -x "$brew_bin" ]] || { echo "Invalid Homebrew path: $brew_bin" >&2; exit 1; }
brew() { "$brew_bin" "$@"; }
eval "$("$brew_bin" shellenv)"

trace() { printf '\033[32m✔︎\033[0m %s\n' "$1"; }

ask() {
  local reply
  read -r -p "$1 [Y/n] " reply || { echo 'Input closed; aborting.' >&2; exit 1; }
  [[ -z "$reply" || "$reply" == [Yy]* ]]
}

install_herdr=0
if brew list --formula herdr >/dev/null 2>&1; then
  echo 'Using herdr'
  install_herdr=1
elif ask 'Install Herdr multiplexer?'; then
  install_herdr=1
fi

if (( install_herdr )) && ! brew list --formula herdr >/dev/null 2>&1; then
  brew install --formula herdr
fi
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
set +u
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
  echo "Using existing Node $current_node; leaving NVM default unchanged"
fi
current_node=$(nvm current)
pi_supported=1
if ! node -e '
  const [major, minor] = process.versions.node.split(".").map(Number);
  process.exit(major > 22 || (major === 22 && minor >= 19) ? 0 : 1);
'; then
  printf 'Warning: Pi needs Node.js 22.19+; active Node is %s. Pi install/update skipped.\n' \
    "$current_node" >&2
  printf "Run 'nvm install 22 && nvm use 22', then rerun ./install-linux.sh.\n" >&2
  echo 'NVM default remains unchanged.' >&2
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

preserve_local_zsh() {
  local file relative
  [[ -d "$ZSH_DIR" && ! -L "$ZSH_DIR" ]] || return 0
  for file in "$ZSH_DIR"/functions/*.zsh; do
    [[ -f "$file" ]] || continue
    relative=${file#"$ZSH_DIR"/}
    git -C "$ZSH_DIR" ls-files --error-unmatch "$relative" >/dev/null 2>&1 && continue
    mkdir -p "$ROOT/zsh/functions/local"
    cp -p "$file" "$ROOT/zsh/functions/local/$(basename "$file")"
    echo "Preserved local function: $(basename "$file")"
  done
}

backup_target() {
  local target=$1 backup
  [[ -e "$target" || -L "$target" ]] || return 0
  backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
  mv "$target" "$backup"
  echo "backup: $target -> $backup"
}

link_config() {
  local source=$1 target=$2
  mkdir -p "$(dirname "$target")"
  [[ -L "$target" && "$(readlink "$target")" == "$source" ]] && return 0
  backup_target "$target"
  ln -s "$source" "$target"
  echo "linked: $target"
}

preserve_local_zsh
"$ROOT/scripts/render-configs.sh"
link_config "$ROOT/zsh" "$ZSH_DIR"
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
  if (( pi_supported )); then
    if (( install_herdr )); then
      echo 'Next: start zsh, run herdr, then start a Pi session.'
    else
      echo 'Next: start zsh, then start a Pi session with pi.'
    fi
  else
    echo 'Next: run nvm install 22 && nvm use 22, then rerun ./install-linux.sh.'
    echo 'This installs Pi without changing your NVM default.'
  fi
fi

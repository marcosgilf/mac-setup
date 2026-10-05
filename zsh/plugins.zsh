# =========================================================
# Plugins
# =========================================================

ZSH_CONFIG_DIR="${ZDOTDIR:-$HOME/.config/zsh}"
ZPLUGINDIR="${ZSH_CONFIG_DIR}/plugins"
PLUGIN_SELECTION="${XDG_CONFIG_HOME:-$HOME/.config}/mac-setup/zsh-plugins"
typeset -a _MAC_SETUP_ENABLED_ZSH_PLUGINS
_MAC_SETUP_ENABLED_ZSH_PLUGINS=(
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-vi-mode
  fast-syntax-highlighting
)
if [[ -r "$PLUGIN_SELECTION" ]]; then
  _MAC_SETUP_ENABLED_ZSH_PLUGINS=()
  typeset selected_plugin
  while IFS= read -r selected_plugin; do
    [[ -n "$selected_plugin" ]] && _MAC_SETUP_ENABLED_ZSH_PLUGINS+=("$selected_plugin")
  done < "$PLUGIN_SELECTION"
fi

_zplugin_load() {
  local owner=$1 name=$2 plugin_path
  plugin_path="${ZPLUGINDIR}/${name}"
  [[ " ${_MAC_SETUP_ENABLED_ZSH_PLUGINS[*]} " == *" ${name} "* ]] || return 0
  if [[ ! -d "$plugin_path" ]]; then
    mkdir -p "$ZPLUGINDIR"
    echo "Installing ${name}..."
    git clone --depth=1 "https://github.com/${owner}/${name}" "$plugin_path" \
      || { echo "ERROR: failed to install ${name}" >&2; return 1; }
  fi
  source "${plugin_path}/${name}.plugin.zsh"
}

zplugin-update() {
  local dir
  for dir in "${ZPLUGINDIR}"/*/; do
    echo "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
  done
}

_zplugin_load zsh-users zsh-autosuggestions
_zplugin_load zsh-users zsh-history-substring-search
_zplugin_load jeffreytse zsh-vi-mode
_zplugin_load zdharma-continuum fast-syntax-highlighting

#!/bin/zsh
set -euo pipefail

readonly ROOT=${0:A:h}
readonly CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
readonly ZDOTDIR=${ZDOTDIR:-$CONFIG_HOME/zsh}
readonly NVM_DIR="$HOME/.nvm"
readonly NVIM_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/${NVIM_APPNAME:-nvim}/lazy"
dry_run=0

case "${1:-}" in
  '') ;;
  --dry-run) dry_run=1 ;;
  *) print -u2 'Usage: ./uninstall.sh [--dry-run]'; exit 2 ;;
esac

brew_bin=${BREW_BIN:-}
if [[ -z "$brew_bin" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin=/opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_bin=/usr/local/bin/brew
  elif command -v brew >/dev/null 2>&1; then
    brew_bin=$(command -v brew)
  fi
fi
if [[ -n "$brew_bin" && ! -x "$brew_bin" ]]; then
  print -u2 "Invalid Homebrew path: $brew_bin"
  exit 1
fi

print 'This removes mac-setup dependencies but keeps the repository and config files:'
print -r -- "- Homebrew formulae from $ROOT/Brewfile, Herdr, Ghostty, and JetBrainsMono Nerd Font"
print -r -- "- all Node versions and global npm packages in $NVM_DIR"
print -r -- "- mac-setup zsh plugin clones and Neovim plugins in $NVIM_PLUGIN_DIR"
print 'Pi settings, credentials, sessions, config symlinks, Homebrew, and Xcode CLT stay.'
print 'Homebrew shared dependencies are left alone; brew autoremove will not run.'

if (( ! dry_run )); then
  confirmation=''
  read -r "confirmation?Type UNINSTALL to continue: " || exit 1
  [[ "$confirmation" == UNINSTALL ]] || { print 'Cancelled.'; exit 0; }
else
  print 'Dry run: no changes will be made.'
fi

uninstall_failed=0

remove_formula() {
  local package=$1
  [[ -n "$brew_bin" ]] || return 0
  "$brew_bin" list --formula "$package" >/dev/null 2>&1 || return 0

  if [[ "$package" == zsh && -n "${SHELL:-}" ]]; then
    local brew_zsh
    brew_zsh=$("$brew_bin" --prefix zsh)/bin/zsh
    if [[ -x "$brew_zsh" && "$SHELL" -ef "$brew_zsh" ]]; then
      print "Keeping zsh: it is the current login shell ($SHELL)."
      uninstall_failed=1
      return 0
    fi
  fi

  if (( dry_run )); then
    print "Would uninstall formula: $package"
  elif "$brew_bin" uninstall --formula "$package"; then
    print "Uninstalled formula: $package"
  else
    print -u2 "Could not uninstall formula: $package (possibly needed by another formula)."
    uninstall_failed=1
  fi
}

remove_cask() {
  local package=$1
  [[ -n "$brew_bin" ]] || return 0
  "$brew_bin" list --cask "$package" >/dev/null 2>&1 || return 0

  if (( dry_run )); then
    print "Would uninstall cask: $package"
  elif "$brew_bin" uninstall --cask "$package"; then
    print "Uninstalled cask: $package"
  else
    print -u2 "Could not uninstall cask: $package."
    uninstall_failed=1
  fi
}

if [[ -n "$brew_bin" ]]; then
  while IFS= read -r package; do
    remove_formula "$package"
  done < <(awk -F '"' '$1 == "brew " { print $2 }' "$ROOT/Brewfile")
  remove_formula herdr

  for package in ghostty font-jetbrains-mono-nerd-font; do
    remove_cask "$package"
  done
else
  print 'Homebrew not found; skipping formula and cask removal.'
  uninstall_failed=1
fi

if [[ -L "$NVM_DIR" ]]; then
  print -u2 "Keeping symlinked NVM directory: $NVM_DIR"
  uninstall_failed=1
elif [[ -d "$NVM_DIR" ]]; then
  if (( dry_run )); then
    print "Would remove NVM data: $NVM_DIR"
  else
    rm -rf "$NVM_DIR"
    print "Removed NVM data: $NVM_DIR"
  fi
fi

for plugin in zsh-autosuggestions zsh-history-substring-search zsh-vi-mode fast-syntax-highlighting; do
  plugin_path="$ZDOTDIR/plugins/$plugin"
  if [[ -e "$plugin_path" || -L "$plugin_path" ]]; then
    if (( dry_run )); then
      print "Would remove zsh plugin: $plugin_path"
    else
      rm -rf "$plugin_path"
      print "Removed zsh plugin: $plugin"
    fi
  fi
done

if [[ -d "$NVIM_PLUGIN_DIR" ]]; then
  if [[ -L "$NVIM_PLUGIN_DIR" ]]; then
    print -u2 "Keeping symlinked Neovim plugin directory: $NVIM_PLUGIN_DIR"
    uninstall_failed=1
  elif (( dry_run )); then
    print "Would remove Neovim plugins: $NVIM_PLUGIN_DIR"
  else
    rm -rf "$NVIM_PLUGIN_DIR"
    print "Removed Neovim plugins: $NVIM_PLUGIN_DIR"
  fi
fi

if (( uninstall_failed )); then
  print -u2 'Some Homebrew packages remain; review failures above and rerun if needed.'
  exit 1
fi

if (( dry_run )); then
  print 'Dry run complete. No dependencies removed.'
else
  print 'Uninstall complete. Repository, configs, and app data preserved.'
  print 'Run ./install.sh when ready to reinstall dependencies.'
fi

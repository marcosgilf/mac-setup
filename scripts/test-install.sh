#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/mac-setup-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
BIN="$TMP/bin"
FAKE_BREW_PREFIX="$TMP/homebrew"
mkdir -p "$BIN" "$FAKE_BREW_PREFIX/opt/nvm"

cat > "$BIN/xcode-select" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "$BIN/brew" <<'EOF'
#!/bin/sh
case "$1" in
  shellenv) printf 'export HOMEBREW_PREFIX="%s"\n' "$FAKE_BREW_PREFIX" ;;
  --prefix) printf '%s/opt/nvm\n' "$FAKE_BREW_PREFIX" ;;
  list) exit 0 ;;
  bundle)
    printf 'Using bat\n'
    printf '\033[32m`brew bundle` complete! 11 Brewfile dependencies now installed.\033[0m\n'
    printf 'Warning: retained stderr warning\n' >&2
    ;;
  *) printf 'Unexpected brew args: %s\n' "$*" >&2; exit 2 ;;
esac
EOF

cat > "$FAKE_BREW_PREFIX/opt/nvm/nvm.sh" <<'EOF'
nvm() {
  case "$1" in
    current) print -r -- "${FAKE_NVM_CURRENT:-system}" ;;
    install)
      export FAKE_NVM_CURRENT=v22.19.0 FAKE_NODE_VERSION=22.19.0
      ;;
    alias)
      mkdir -p "$NVM_DIR/alias"
      print -r -- "$3" > "$NVM_DIR/alias/default"
      ;;
    use)
      export FAKE_NVM_CURRENT="${FAKE_NVM_DEFAULT:-v22.19.0}"
      export FAKE_NODE_VERSION="${FAKE_NVM_VERSION_FOR_DEFAULT:-22.19.0}"
      ;;
    *) print -u2 "Unexpected nvm args: $*"; return 2 ;;
  esac
}
EOF

cat > "$BIN/node" <<'EOF'
#!/bin/sh
[ "$1" = -e ] || exit 2
case "${FAKE_NODE_VERSION:-22.19.0}" in
  v22.18.*|22.18.*) exit 1 ;;
  *) exit 0 ;;
esac
EOF

cat > "$BIN/npm" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_LOG/npm"
case "$1" in
  list)
    case "$*" in
      *@mariozechner/pi-coding-agent*) exit 1 ;;
      *@earendil-works/pi-coding-agent*) [ "${FAKE_PI_INSTALLED:-0}" = 1 ] ;;
      *) exit 2 ;;
    esac
    ;;
  install|uninstall) ;;
  *) printf 'Unexpected npm args: %s\n' "$*" >&2; exit 2 ;;
esac
EOF

cat > "$BIN/curl" <<'EOF'
#!/bin/sh
[ "$*" = '-fsSL https://pi.dev/install.sh' ] || { printf 'Unexpected curl args: %s\n' "$*" >&2; exit 2; }
printf '%s\n' "$*" >> "$TEST_LOG/curl"
cat <<'INSTALLER'
#!/bin/sh
printf '%s\n' 'managed install invoked' >> "$TEST_LOG/managed"
cat > "$TEST_BIN/pi" <<'PI'
#!/bin/sh
[ "$1" = update ] && [ "$2" = --all ] || exit 2
printf '%s %s\n' "$npm_config_fund" "$*" >> "$TEST_LOG/pi"
PI
chmod +x "$TEST_BIN/pi"
INSTALLER
EOF

chmod +x "$BIN"/*

run_installer() {
  home=$1
  output=$2
  answers=${7:-$TMP/plugin-answers}
  HOME="$home" \
  XDG_CONFIG_HOME="$home/.config" \
  ZDOTDIR="$home/.zsh" \
  BREW_BIN="$BIN/brew" \
  FAKE_BREW_PREFIX="$FAKE_BREW_PREFIX" \
  FAKE_NVM_CURRENT="$3" \
  FAKE_NODE_VERSION="$4" \
  FAKE_PI_INSTALLED="$5" \
  TEST_LOG="$6" \
  TEST_BIN="$BIN" \
  PATH="$BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
    "$ROOT/install.sh" <"$answers" >"$output" 2>&1 || { cat "$output" >&2; return 1; }
}

contains() { grep -F "$2" "$1" >/dev/null || { printf 'Missing output: %s\n' "$2" >&2; return 1; }; }
absent() { ! grep -F "$2" "$1" >/dev/null || { printf 'Unexpected output: %s\n' "$2" >&2; return 1; }; }

printf 'y\ny\ny\ny\n' > "$TMP/plugin-answers"

# Fresh install initializes Node 22 and installs/updates Pi.
fresh_home="$TMP/fresh"
fresh_log="$TMP/fresh-log"
mkdir -p "$fresh_home" "$fresh_log"
run_installer "$fresh_home" "$TMP/fresh.out" system system 0 "$fresh_log"
contains "$TMP/fresh.out" 'Optional dependencies updated'
contains "$TMP/fresh.out" 'Brewfile dependencies updated'
contains "$TMP/fresh.out" 'Warning: retained stderr warning'
absent "$TMP/fresh.out" '`brew bundle` complete!'
contains "$TMP/fresh.out" 'Install complete.'
grep -Fx '22' "$fresh_home/.nvm/alias/default" >/dev/null
[ "$(readlink "$fresh_home/.config/superfile/config.toml")" = "$ROOT/superfile/config.toml" ]
[ "$(readlink "$fresh_home/.config/superfile/hotkeys.toml")" = "$ROOT/superfile/hotkeys.toml" ]
[ "$(readlink "$fresh_home/.config/superfile/theme/tokyo-night.toml")" = "$ROOT/superfile/themes/tokyo-night.toml" ]
contains "$ROOT/superfile/config.toml" 'theme = "tokyo-night"'
contains "$ROOT/superfile/config.toml" 'zoxide_support = true'
contains "$ROOT/superfile/themes/tokyo-night.toml" 'full_screen_bg = "#1a1b26"'
absent "$ROOT/superfile/themes/tokyo-night.toml" '@BACKGROUND@'
contains "$ROOT/superfile/hotkeys.toml" "list_up = ['k', '']"
contains "$ROOT/superfile/hotkeys.toml" "parent_directory = ['h', 'left', 'backspace']"
contains "$ROOT/superfile/hotkeys.toml" "open_zoxide = ['z', '']"
contains "$fresh_log/curl" 'pi.dev/install.sh'
contains "$fresh_log/managed" 'managed install invoked'
absent "$fresh_log/npm" 'install --global'
contains "$fresh_log/pi" 'false update --all'
contains "$fresh_home/.config/mac-setup/zsh-plugins" 'zsh-autosuggestions'
contains "$fresh_home/.config/mac-setup/zsh-plugins" 'fast-syntax-highlighting'

# Existing npm-installed Pi migrates and user can decline individual Zsh plugins.
migration_home="$TMP/migration"
migration_log="$TMP/migration-log"
mkdir -p "$migration_home" "$migration_log"
migration_answers="$TMP/migration-answers"
printf 'y\nn\ny\nn\n' > "$migration_answers"
run_installer "$migration_home" "$TMP/migration.out" v22.19.0 22.19.0 1 "$migration_log" "$migration_answers"
contains "$migration_log/curl" 'pi.dev/install.sh'
contains "$migration_log/managed" 'managed install invoked'
contains "$migration_log/pi" 'false update --all'
contains "$TMP/migration.out" 'Searches history by typed text with Up/Down.'
contains "$migration_home/.config/mac-setup/zsh-plugins" 'zsh-autosuggestions'
contains "$migration_home/.config/mac-setup/zsh-plugins" 'zsh-vi-mode'
absent "$migration_home/.config/mac-setup/zsh-plugins" 'zsh-history-substring-search'
absent "$migration_home/.config/mac-setup/zsh-plugins" 'fast-syntax-highlighting'

# Selected plugins load; declined plugins stay unloaded.
runtime_config="$TMP/runtime-config"
runtime_zsh="$TMP/runtime-zsh"
plugin_log="$TMP/loaded-plugins"
mkdir -p "$runtime_config/mac-setup" "$runtime_zsh/plugins"
printf 'zsh-vi-mode\n' > "$runtime_config/mac-setup/zsh-plugins"
for plugin in zsh-autosuggestions zsh-history-substring-search zsh-vi-mode fast-syntax-highlighting; do
  mkdir -p "$runtime_zsh/plugins/$plugin"
  printf 'print -r -- %s >> "$TEST_PLUGIN_LOG"\n' "$plugin" > "$runtime_zsh/plugins/$plugin/$plugin.plugin.zsh"
done
XDG_CONFIG_HOME="$runtime_config" ZDOTDIR="$runtime_zsh" TEST_PLUGIN_LOG="$plugin_log" ROOT="$ROOT" \
  /bin/zsh -c 'source "$ROOT/zsh/plugins.zsh"'
[ "$(cat "$plugin_log")" = 'zsh-vi-mode' ]

# Older active Node warns, skips Pi, and does not change the existing default.
old_home="$TMP/old-node"
old_log="$TMP/old-log"
mkdir -p "$old_home/.config" "$old_home/.nvm/alias" "$old_log"
ln -s "$ROOT/zsh" "$old_home/.config/zsh"
printf '20\n' > "$old_home/.nvm/alias/default"
run_installer "$old_home" "$TMP/old.out" v22.18.0 22.18.0 1 "$old_log"
contains "$TMP/old.out" 'Pi requires Node.js 22.19 or newer'
contains "$TMP/old.out" 'Pi update skipped.'
contains "$TMP/old.out" 'Update completed; Pi update skipped.'
grep -Fx '20' "$old_home/.nvm/alias/default" >/dev/null
[ ! -e "$old_log/pi" ]
[ ! -e "$old_log/npm" ]

printf 'Installer smoke tests passed.\n'

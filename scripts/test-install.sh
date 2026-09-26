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
    printf '\033[32m`brew bundle` complete! 10 Brewfile dependencies now installed.\033[0m\n'
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
case "$1" in
  list)
    case "$*" in
      *@mariozechner/pi-coding-agent*) exit 1 ;;
      *@earendil-works/pi-coding-agent*) [ "${FAKE_PI_INSTALLED:-0}" = 1 ] ;;
      *) exit 2 ;;
    esac
    ;;
  install|uninstall) printf '%s\n' "$*" >> "$TEST_LOG/npm" ;;
  *) printf 'Unexpected npm args: %s\n' "$*" >&2; exit 2 ;;
esac
EOF

cat > "$BIN/pi" <<'EOF'
#!/bin/sh
[ "$1" = update ] && [ "$2" = --all ] || exit 2
printf '%s\n' "$*" >> "$TEST_LOG/pi"
EOF

chmod +x "$BIN"/*

run_installer() {
  home=$1
  output=$2
  HOME="$home" \
  XDG_CONFIG_HOME="$home/.config" \
  ZDOTDIR="$home/.zsh" \
  BREW_BIN="$BIN/brew" \
  FAKE_BREW_PREFIX="$FAKE_BREW_PREFIX" \
  FAKE_NVM_CURRENT="$3" \
  FAKE_NODE_VERSION="$4" \
  FAKE_PI_INSTALLED="$5" \
  TEST_LOG="$6" \
  PATH="$BIN:$PATH" \
    "$ROOT/install.sh" </dev/null >"$output" 2>&1 || { cat "$output" >&2; return 1; }
}

contains() { grep -F "$2" "$1" >/dev/null || { printf 'Missing output: %s\n' "$2" >&2; return 1; }; }
absent() { ! grep -F "$2" "$1" >/dev/null || { printf 'Unexpected output: %s\n' "$2" >&2; return 1; }; }

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
contains "$fresh_log/npm" 'install --global'
contains "$fresh_log/pi" 'update --all'

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

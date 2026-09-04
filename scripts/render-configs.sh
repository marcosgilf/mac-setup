#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/theme/tokyo-night.sh"

render() {
  input=$1
  output=$2
  mkdir -p "$(dirname -- "$output")"
  sed \
    -e "s|@THEME_NAME@|$THEME_NAME|g" \
    -e "s|@TUICR_THEME@|$TUICR_THEME|g" \
    -e "s|@HERDR_THEME@|$HERDR_THEME|g" \
    -e "s|@NVIM_COLORSCHEME@|$NVIM_COLORSCHEME|g" \
    -e "s|@BACKGROUND@|$BACKGROUND|g" \
    -e "s|@DARK_BACKGROUND@|$DARK_BACKGROUND|g" \
    -e "s|@DARKER_BACKGROUND@|$DARKER_BACKGROUND|g" \
    -e "s|@LIGHTER_BACKGROUND@|$LIGHTER_BACKGROUND|g" \
    -e "s|@FOREGROUND@|$FOREGROUND|g" \
    -e "s|@DARK_FOREGROUND@|$DARK_FOREGROUND|g" \
    -e "s|@LIGHT_FOREGROUND@|$LIGHT_FOREGROUND|g" \
    -e "s|@BRIGHT_FOREGROUND@|$BRIGHT_FOREGROUND|g" \
    -e "s|@MUTED@|$MUTED|g" \
    -e "s|@RED@|$RED|g" \
    -e "s|@YELLOW@|$YELLOW|g" \
    -e "s|@ORANGE@|$ORANGE|g" \
    -e "s|@GREEN@|$GREEN|g" \
    -e "s|@CYAN@|$CYAN|g" \
    -e "s|@BLUE@|$BLUE|g" \
    -e "s|@MAGENTA@|$MAGENTA|g" \
    -e "s|@BROWN@|$BROWN|g" \
    -e "s|@BRIGHT_RED@|$BRIGHT_RED|g" \
    -e "s|@BRIGHT_YELLOW@|$BRIGHT_YELLOW|g" \
    -e "s|@BRIGHT_GREEN@|$BRIGHT_GREEN|g" \
    -e "s|@BRIGHT_CYAN@|$BRIGHT_CYAN|g" \
    -e "s|@BRIGHT_BLUE@|$BRIGHT_BLUE|g" \
    -e "s|@BRIGHT_MAGENTA@|$BRIGHT_MAGENTA|g" \
    -e "s|@SELECTION@|$SELECTION|g" \
    -e "s|@SELECTION_FOREGROUND@|$SELECTION_FOREGROUND|g" \
    -e "s|@SELECTION_BACKGROUND@|$SELECTION_BACKGROUND|g" \
    -e "s|@ACCENT@|$ACCENT|g" \
    "$input" > "$output"
}

render "$ROOT/ghostty/config.ghostty.tmpl" "$ROOT/ghostty/config.ghostty"
render "$ROOT/herdr/config.toml.tmpl" "$ROOT/herdr/config.toml"
render "$ROOT/nvim/lua/plugins/tokyo-night.lua.tmpl" "$ROOT/nvim/lua/plugins/tokyo-night.lua"
render "$ROOT/tuicr/config.toml.tmpl" "$ROOT/tuicr/config.toml"
render "$ROOT/tuicr/themes/tokyo-night.toml.tmpl" "$ROOT/tuicr/themes/tokyo-night.toml"
render "$ROOT/zsh/starship.toml.tmpl" "$ROOT/zsh/starship.toml"

FUNCTIONSDIR="${ZDOTDIR:-$HOME/.config/zsh}/functions"

for function_file in "$FUNCTIONSDIR"/*.zsh(N) "$FUNCTIONSDIR"/local/*.zsh(N); do
  source "$function_file"
done

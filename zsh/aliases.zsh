# Better ls
alias ls='eza --icons'

# Detailed listing
alias ll='eza -lh --icons --git'

# Detailed listing including hidden files
alias la='eza -lah --icons --git'

# Tree view
alias tree='eza --tree --icons'

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls

# Better cat
alias cat='bat'

# =========================================================
# Core utilities
# =========================================================

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'
alias mkdir='mkdir -p'

# =========================================================
# Navigation
# =========================================================

alias -- -='cd -'  # -- prevents - being parsed as a flag; cd - jumps to previous directory

# =========================================================
# Editor
# =========================================================

alias vim='nvim'

# =========================================================
# Configs
# =========================================================

alias edit-zsh='nvim "$ZDOTDIR/.zshrc"'
alias edit-starship='nvim "$ZDOTDIR/starship.toml.tmpl"'
alias edit-nvim='nvim "$XDG_CONFIG_HOME/nvim/init.lua"'

alias reload-zsh='source ~/.config/zsh/.zshrc'

# =========================================================
# Git
# =========================================================

alias glog='PAGER="less -F -X" git log'                              # -F quit if one screen, -X no clear on exit
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpf='git push -f'
alias gpn='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gl='git pull'
alias gd='git diff'
alias gr='git rebase origin/main'
alias gfr='git fetch && gr'
alias gco='git checkout'
alias gb='git branch'
alias gbr='git rev-parse --abbrev-ref HEAD'

# =========================================================
# npm
# =========================================================

alias ni='npm install'
alias nup='npm run dependencies:update'
alias nr='rm -rf node_modules package-lock.json && npm install'
alias nt='npm test'
alias ntc='npm run test:coverage'
alias ntw='npm run test:watch'

# =========================================================
# Terraform
# =========================================================

alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply -auto-approve'
alias tfwd='terraform workspace select dev'
alias tfwp='terraform workspace select prod'

# =========================================================
# Video
# =========================================================

alias stream='mpv av://v4l2:/dev/video4 --fullscreen --demuxer-lavf-o=input_format=mjpeg,framerate=30 --profile=low-latency --untimed'

# =========================================================
# pi
# =========================================================

alias q='pi --model claude-haiku-4.5 -p'

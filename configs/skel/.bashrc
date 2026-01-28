# Quantonium OS - Developer Shell Configuration
# A no-nonsense shell setup for people who live in terminals.

# Exit if not interactive
[[ $- != *i* ]] && return

# =============================================================================
# Shell Options
# =============================================================================

shopt -s histappend          # Append to history, don't overwrite
shopt -s checkwinsize        # Update LINES/COLUMNS after each command
shopt -s globstar            # ** matches recursively
shopt -s nocaseglob          # Case-insensitive globbing
shopt -s cdspell             # Autocorrect typos in cd
shopt -s dirspell            # Autocorrect directory names
shopt -s autocd              # Type directory name to cd into it
shopt -s cmdhist             # Save multi-line commands as one entry

# =============================================================================
# History
# =============================================================================

HISTCONTROL=ignoreboth:erasedups
HISTSIZE=50000
HISTFILESIZE=100000
HISTTIMEFORMAT="%F %T  "
HISTIGNORE="ls:ll:cd:pwd:exit:clear:c"

# Save history after each command (survive crashes)
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a"

# =============================================================================
# Prompt
# =============================================================================

__git_info() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null)
    [[ -z "$branch" ]] && return

    local status=""
    local git_status
    git_status=$(git status --porcelain 2>/dev/null)

    [[ -n "$git_status" ]] && status="*"

    echo " ($branch$status)"
}

__exit_code() {
    local code=$?
    [[ $code -ne 0 ]] && echo " [$code]"
}

# Colors (256-color)
C_PURPLE='\[\e[38;5;141m\]'
C_CYAN='\[\e[38;5;51m\]'
C_PINK='\[\e[38;5;205m\]'
C_RED='\[\e[38;5;203m\]'
C_GREEN='\[\e[38;5;114m\]'
C_GRAY='\[\e[38;5;245m\]'
C_WHITE='\[\e[38;5;255m\]'
C_RESET='\[\e[0m\]'

# Prompt: user@host:dir (branch) [exit_code]
PS1="${C_PURPLE}\u${C_GRAY}@${C_CYAN}\h${C_GRAY}:${C_WHITE}\w${C_GREEN}\$(__git_info)${C_RED}\$(__exit_code)${C_RESET}\n${C_PURPLE}\$${C_RESET} "

# =============================================================================
# Environment
# =============================================================================

export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LESS='-R -F -X -i -M -S'
export MANPAGER="less -R"

# Use bat for man pages if available
command -v bat &>/dev/null && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# =============================================================================
# Path
# =============================================================================

path_prepend() {
    [[ -d "$1" ]] && PATH="$1:${PATH//:$1:/:}"
}

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/go/bin"
path_prepend "$HOME/.npm-global/bin"

export PATH

# Go
[[ -d "$HOME/go" ]] && export GOPATH="$HOME/go"

# =============================================================================
# Modern Tool Integration
# =============================================================================

# ripgrep > grep
if command -v rg &>/dev/null; then
    alias grep='rg'
    export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"
fi

# fd > find
if command -v fdfind &>/dev/null; then
    alias fd='fdfind'
    alias find='fdfind'
fi

# bat > cat
if command -v batcat &>/dev/null; then
    alias cat='batcat --paging=never'
    alias bat='batcat'
elif command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
fi

# zoxide > cd
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
    alias cd='z'
fi

# direnv - per-directory environments
if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi

# fzf - fuzzy finder
if command -v fzf &>/dev/null; then
    # fzf keybindings and completion
    [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]] && source /usr/share/doc/fzf/examples/key-bindings.bash
    [[ -f /usr/share/doc/fzf/examples/completion.bash ]] && source /usr/share/doc/fzf/examples/completion.bash

    # fzf defaults
    export FZF_DEFAULT_OPTS='
        --height 40%
        --layout=reverse
        --border
        --color=fg:#c0c0c0,bg:#1a1a2e,hl:#00d9ff
        --color=fg+:#ffffff,bg+:#2d2d44,hl+:#00d9ff
        --color=info:#6b4c9a,prompt:#ff6b9d,pointer:#00d9ff
        --color=marker:#ff6b9d,spinner:#6b4c9a,header:#6b4c9a
    '

    # Use fd for fzf if available
    if command -v fdfind &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'
    fi
fi

# =============================================================================
# Aliases - Keep it Simple
# =============================================================================

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# Listing
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lAh'
alias la='ls -A'
alias lt='ls -lAht'                    # Sort by time
alias lS='ls -lAhS'                    # Sort by size

# Safety nets
alias rm='rm -I'                       # Prompt before removing >3 files
alias cp='cp -iv'
alias mv='mv -iv'
alias ln='ln -iv'

# Disk
alias df='df -h'
alias du='du -h'
alias dud='du -d 1 -h'                 # Directory sizes
alias duf='du -sh *'                   # File sizes in current dir

# Process
alias ps='ps auxf'
alias psg='ps aux | grep -v grep | grep -i'

# Network
alias ports='ss -tulanp'
alias myip='curl -s ifconfig.me'
alias ping='ping -c 5'

# =============================================================================
# Git Aliases (short, memorable)
# =============================================================================

alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull --rebase'
alias gf='git fetch --all --prune'
alias gd='git diff'
alias gds='git diff --staged'
alias glog='git log --oneline --graph --all -20'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch -vv'
alias gbd='git branch -d'
alias gst='git stash'
alias gstp='git stash pop'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gcp='git cherry-pick'
alias grs='git reset'
alias grsh='git reset --hard'

# =============================================================================
# Docker Aliases
# =============================================================================

alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -q)'
alias dprune='docker system prune -af'

# =============================================================================
# Kubernetes Aliases
# =============================================================================

alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs -f'
alias kex='kubectl exec -it'

# =============================================================================
# Functions
# =============================================================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [[ ! -f "$1" ]]; then
        echo "'$1' is not a valid file"
        return 1
    fi
    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.tar.xz)  tar xJf "$1" ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.rar)     unrar x "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.tar)     tar xf "$1" ;;
        *.tbz2)    tar xjf "$1" ;;
        *.tgz)     tar xzf "$1" ;;
        *.zip)     unzip "$1" ;;
        *.Z)       uncompress "$1" ;;
        *.7z)      7z x "$1" ;;
        *.zst)     unzstd "$1" ;;
        *)         echo "'$1': unknown archive format" ;;
    esac
}

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    echo "Serving on http://localhost:$port"
    python3 -m http.server "$port" --bind 127.0.0.1
}

# JSON pretty print
json() {
    if [[ -t 0 ]]; then
        cat "$@" | jq .
    else
        jq .
    fi
}

# Quick file/content search
f() {
    if [[ -n "$2" ]]; then
        # Search in files: f "pattern" "path"
        rg "$1" "$2"
    else
        # Find files: f "name"
        fdfind "$1" 2>/dev/null || find . -iname "*$1*" 2>/dev/null
    fi
}

# Quick process kill
pskill() {
    local pid
    pid=$(ps aux | grep -v grep | grep -i "$1" | awk '{print $2}')
    [[ -n "$pid" ]] && echo "$pid" | xargs kill -9
}

# Git clone and cd
gclone() {
    git clone "$1" && cd "$(basename "$1" .git)"
}

# Diff with delta or diff
diff() {
    if command -v delta &>/dev/null; then
        command diff "$@" | delta
    else
        command diff --color=auto "$@"
    fi
}

# Quick benchmark
bench() {
    local cmd="$*"
    echo "Running: $cmd"
    time (eval "$cmd") 2>&1
}

# Show listening ports
listening() {
    ss -tulanp | grep LISTEN
}

# =============================================================================
# Completions
# =============================================================================

if ! shopt -oq posix; then
    [[ -f /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion
    [[ -f /etc/bash_completion ]] && source /etc/bash_completion
fi

# kubectl completions
command -v kubectl &>/dev/null && source <(kubectl completion bash)

# =============================================================================
# Local Overrides
# =============================================================================

# Source local customizations if they exist
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local

# =============================================================================
# Quick Reference (displayed once on first login)
# =============================================================================

if [[ ! -f "$HOME/.quantonium_welcomed" ]]; then
    cat << 'EOF'

  Quantonium OS - Quick Reference
  ================================

  Modern tools installed:
    rg (ripgrep)  - fast search      fd   - fast find
    bat           - better cat       fzf  - fuzzy finder (Ctrl+R, Ctrl+T)
    zoxide        - smart cd         jq   - JSON processor
    delta         - better diffs     tldr - simplified man

  Key bindings:
    Ctrl+R  - fuzzy search history
    Ctrl+T  - fuzzy find files
    Alt+C   - fuzzy cd to directory

  Run 'tldr <command>' for quick help.
  This message won't appear again.

EOF
    touch "$HOME/.quantonium_welcomed"
fi

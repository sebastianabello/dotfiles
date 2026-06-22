# ──────────────────────────────────────────────────────────────────────────────
# .zshrc — Configuración principal de zsh
# ──────────────────────────────────────────────────────────────────────────────

# ── PATH — todos los exports primero, antes de cualquier eval ────────────────
export PATH="$HOME/.local/bin:$PATH"                      # uv, zoxide, tldr
export PATH="$HOME/.cargo/bin:$PATH"                      # rust/cargo tools
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"        # go
export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"                      # bun
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
export FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
    export PATH="$FNM_PATH:$PATH"
fi

# ── Rust / Cargo env ─────────────────────────────────────────────────────────
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# ── Oh My Zsh ────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Starship gestiona el prompt

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    docker
    docker-compose
    sudo
    direnv
)

source "$ZSH/oh-my-zsh.sh"

# ── Evals de herramientas (PATH ya completo arriba) ──────────────────────────

# Starship prompt
eval "$(starship init zsh)"

# Zoxide (cd inteligente)
eval "$(zoxide init zsh --cmd cd)"

# fnm (Node.js version manager)
if [ -d "$FNM_PATH" ]; then
    eval "$(fnm env --use-on-cd --shell zsh)"
fi

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ── Aliases modernos ─────────────────────────────────────────────────────────
# Navegación
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --git --group-directories-first'
alias lt='eza --tree --icons --level=2'
alias lta='eza --tree --icons --level=3 -a'

# Búsqueda y lectura
alias cat='bat --style=auto'
alias find='fd'
alias grep='rg'
alias top='btop'

# Git
alias g='git'
alias lg='lazygit'
alias gst='git status'
alias glog='git log --oneline --graph --decorate'

# Docker
alias d='docker'
alias dc='docker compose'
alias lzd='lazydocker'

# Productividad
alias zj='zellij'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias path='echo $PATH | tr ":" "\n"'
alias reload='source ~/.zshrc'

# Python / uv
alias py='python3'
alias venv='uv venv'
alias pip='uv pip'

# Herramientas
alias tldr='tldr --color always'

# ── Funciones útiles ─────────────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }

extract() {
    case "$1" in
        *.tar.bz2)  tar xjf "$1" ;;
        *.tar.gz)   tar xzf "$1" ;;
        *.tar.xz)   tar xJf "$1" ;;
        *.bz2)      bunzip2 "$1" ;;
        *.gz)       gunzip "$1"  ;;
        *.tar)      tar xf "$1"  ;;
        *.zip)      unzip "$1"   ;;
        *.7z)       7z x "$1"    ;;
        *)          echo "Formato desconocido: $1" ;;
    esac
}

fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf +m) && cd "$dir"
}

gclone() { git clone "$1" && cd "$(basename "$1" .git)"; }

# ── direnv hook ──────────────────────────────────────────────────────────────
eval "$(direnv hook zsh)"

# ── Miniconda — bloque gestionado por conda init ──────────────────────────────
# shellcheck source=/dev/null
__conda_setup="$("$HOME/miniconda3/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
fi
unset __conda_setup
# conda auto_activate_base = false → no activa 'base' al abrir terminal

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

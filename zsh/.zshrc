# ──────────────────────────────────────────────────────────────────────────────
# .zshrc — Configuración principal de zsh
# ──────────────────────────────────────────────────────────────────────────────

# Ayuda para comprobar si un comando existe
_has() { command -v "$1" &>/dev/null; }

# ── PATH — sin duplicados (typeset -U) ───────────────────────────────────────
typeset -U path PATH

export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/.local/share/pnpm"
export FNM_PATH="$HOME/.local/share/fnm"

path=(
    "$HOME/.local/bin"        # uv, zoxide, tldr
    "$HOME/.cargo/bin"        # rust/cargo tools
    "$GOROOT/bin" "$GOPATH/bin"
    "$BUN_INSTALL/bin"
    "$PNPM_HOME/bin" "$PNPM_HOME"   # pnpm ≥ 11 instala en $PNPM_HOME/bin
    "$FNM_PATH"
    $path
)

# ── Editor ───────────────────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"

# ── Historial ────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt SHARE_HISTORY EXTENDED_HISTORY
setopt AUTO_CD INTERACTIVE_COMMENTS

# ── Oh My Zsh ────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Starship gestiona el prompt

# zsh-syntax-highlighting siempre el último
plugins=(
    git
    docker
    docker-compose
    sudo
    zsh-autosuggestions
    zsh-completions
    zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# ── Herramientas (cada una solo si está instalada) ───────────────────────────
_has starship && eval "$(starship init zsh)"

[ -d "$FNM_PATH" ] && _has fnm && eval "$(fnm env --use-on-cd --shell zsh)"

# fzf: Ctrl+R (historial), Ctrl+T (archivos), Alt+C (directorios)
if _has fzf; then
    source <(fzf --zsh)
    if _has fd; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

_has direnv && eval "$(direnv hook zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ── Aliases ──────────────────────────────────────────────────────────────────
# Se dejan intactos find/grep/pip para no romper scripts y one-liners POSIX.
if _has eza; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lah --icons --git --group-directories-first'
    alias lt='eza --tree --icons --level=2'
    alias lta='eza --tree --icons --level=3 -a'
fi

_has bat  && alias cat='bat --style=auto --paging=never'
_has fd   && alias ff='fd'
_has rg   && alias rgi='rg -i'
_has btop && alias top='btop'

alias g='git'
alias lg='lazygit'
alias gst='git status'
alias glog='git log --oneline --graph --decorate'
# El plugin git de oh-my-zsh ya define ga gaa gp gl gd gb gco gsw; aquí solo lo que falta.
alias gs='git status -sb'
cm()  { git commit -m "$*"; }                    # cm mensaje sin comillas
cma() { git add -A && git commit -m "$*"; }

# npm
alias nd='npm run dev'
alias nb='npm run build'
alias ns='npm start'
alias ni='npm install'
alias nt='npm test'

alias d='docker'
alias dc='docker compose'
alias lzd='lazydocker'

alias zj='zellij'
alias v='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias path='echo $PATH | tr ":" "\n"'
alias reload='exec zsh'

alias py='python3'
alias venv='uv venv'
alias uvp='uv pip'

# ── Funciones útiles ─────────────────────────────────────────────────────────
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

extract() {
    [ -f "$1" ] || { echo "No es un archivo: $1" >&2; return 1; }
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz|*.txz)   tar xJf "$1" ;;
        *.tar.zst)        tar --zstd -xf "$1" ;;
        *.tar)            tar xf "$1"  ;;
        *.bz2)            bunzip2 "$1" ;;
        *.gz)             gunzip "$1"  ;;
        *.xz)             unxz "$1"    ;;
        *.zip)            unzip "$1"   ;;
        *.rar)            unrar x "$1" ;;
        *.7z)             7z x "$1"    ;;
        *) echo "Formato desconocido: $1" >&2; return 1 ;;
    esac
}

fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf +m) && cd -- "$dir"
}

gclone() { git clone "$1" && cd -- "$(basename "$1" .git)"; }

# ── Miniconda (carga diferida: solo cuesta tiempo al usar `conda`) ───────────
if [ -x "$HOME/miniconda3/bin/conda" ]; then
    conda() {
        unfunction conda
        local setup
        setup="$("$HOME/miniconda3/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)" && eval "$setup"
        conda "$@"
    }
fi

# ── Configuración local de esta máquina (no versionada) ──────────────────────
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# ── Zoxide: debe inicializarse al final ──────────────────────────────────────
_has zoxide && eval "$(zoxide init zsh --cmd cd)"

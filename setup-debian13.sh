#!/usr/bin/env bash
# =============================================================================
# setup-debian13.sh
# Configuración automática de entorno de desarrollo en Debian 13 (Trixie)
# Autor: Generado para perfil: Ingeniero de Sistemas y Computación
# Uso: bash setup-debian13.sh
# =============================================================================

set -euo pipefail

# ─── Colores para output ─────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${GREEN}[✔]${NC} $1"; }
info()    { echo -e "${BLUE}[→]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
section() { echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}\n"; }
err()     { echo -e "${RED}[✘]${NC} $1" >&2; exit 1; }

# ─── Variables globales ───────────────────────────────────────────────────────
USER_HOME="${HOME}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}"
GO_VERSION="1.26.4"         # Actualiza según https://go.dev/dl/
ZSHRC="$USER_HOME/.zshrc"

# Verifica que no se ejecute como root
[[ "$EUID" -eq 0 ]] && err "No ejecutes este script como root. Usa tu usuario normal (tiene sudo configurado)."

# ─────────────────────────────────────────────────────────────────────────────
# SECCIÓN 1: CONFIGURACIÓN INICIAL DE DEBIAN 13
# ─────────────────────────────────────────────────────────────────────────────
section "1/7 · Configuración inicial del sistema"

info "Configurando repositorios (formato DEB822 moderno de Debian 13)..."
# Debian 13 Trixie usa /etc/apt/sources.list.d/0000debian.sources (DEB822).
# NO sobreescribimos /etc/apt/sources.list para evitar duplicados.
# Solo actualizamos el archivo .sources para añadir contrib, non-free y non-free-firmware.
sudo tee /etc/apt/sources.list.d/0000debian.sources > /dev/null <<'EOF'
Types: deb deb-src
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb deb-src
URIs: http://deb.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# Vaciar /etc/apt/sources.list si contiene entradas (evita duplicados con el .sources)
if grep -qE '^deb ' /etc/apt/sources.list 2>/dev/null; then
    warn "Vaciando /etc/apt/sources.list para evitar duplicados con 0000debian.sources..."
    sudo truncate -s 0 /etc/apt/sources.list
fi

info "Actualizando sistema..."
sudo apt-get update -qq && sudo apt-get upgrade -y

info "Instalando paquetes base esenciales..."
sudo apt-get install -y \
    build-essential \
    curl \
    wget \
    git \
    gh \
    git-lfs \
    gnupg2 \
    ca-certificates \
    lsb-release \
    apt-transport-https \
    unzip \
    zip \
    tar \
    xz-utils \
    jq \
    htop \
    man-db \
    tree \
    vim \
    neovim \
    stow \
    direnv \
    pkg-config \
    libssl-dev \
    libffi-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses-dev \
    libxml2-dev \
    libxmlsec1-dev \
    liblzma-dev \
    tk-dev \
    llvm \
    fontconfig

log "Sistema base configurado."

# ─────────────────────────────────────────────────────────────────────────────
# SECCIÓN 2: SHELL — ZSH + OH MY ZSH + STARSHIP + ZELLIJ
# ─────────────────────────────────────────────────────────────────────────────
section "2/7 · Shell: zsh + Oh My Zsh + Starship + Zellij"

# ── zsh ──────────────────────────────────────────────────────────────────────
info "Instalando zsh..."
sudo apt-get install -y zsh
sudo chsh -s "$(which zsh)" "$USER"
log "zsh instalado. Shell cambiado a zsh para $USER."

# ── Oh My Zsh ────────────────────────────────────────────────────────────────
if [[ ! -d "$USER_HOME/.oh-my-zsh" ]]; then
    info "Instalando Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    warn "Oh My Zsh ya está instalado, omitiendo."
fi

# ── Plugins de zsh ───────────────────────────────────────────────────────────
info "Instalando plugins de zsh: zsh-autosuggestions y zsh-syntax-highlighting..."

[[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]] && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"

[[ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]] && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
        "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

[[ ! -d "${ZSH_CUSTOM}/plugins/zsh-completions" ]] && \
    git clone --depth=1 https://github.com/zsh-users/zsh-completions \
        "${ZSH_CUSTOM}/plugins/zsh-completions"

# ── Starship ─────────────────────────────────────────────────────────────────
info "Instalando Starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- --yes

mkdir -p "$USER_HOME/.config"
cat > "$USER_HOME/.config/starship.toml" <<'EOF'
# starship.toml — configuración mínima y funcional

"$schema" = 'https://starship.rs/config-schema.json'

# 1. TU FORMATO PERSONALIZADO EN DOS LÍNEAS (Expandido con soporte para todos los módulos)
format = """
[╭─](bold green)$username$hostname$directory$git_branch$git_commit$git_state$git_status$kubernetes$aws$azure$gcloud$openstack$docker_context$package$buf$bun$c$cpp$cmake$cobol$conda$container$crystal$dart$deno$direnv$dotnet$elixir$elm$erlang$fennel$fortran$gleam$golang$gradle$guix_shell$haskell$haxe$helm$java$julia$kotlin$lua$maven$memory_usage$meson$mojo$nats$netns$nim$nix_shell$nodejs$ocaml$odin$opa$purescript$python$raku$red$rlang$ruby$rust$scala$solidity$spack$sudo$swift$terraform$vlang$typst$vagrant$xmake$zig$status$shlvl$battery
[╰─](bold green)$character"""

# 2. CONFIGURACIÓN DE TUS MÓDULOS PRINCIPALES (CON FORMATOS CORREGIDOS)

[username]
style_user = "bold cyan"
style_root = "bold red"
show_always = false
format = "[$user]($style) "

[hostname]
ssh_only = true
style = "bold yellow"
ssh_symbol = " "
format = "on [$ssh_symbol$hostname]($style) "

[directory]
style = "bold blue"
truncation_length = 3
truncate_to_repo = true
read_only = " 󰌾"
truncation_symbol = "…/"

[git_branch]
symbol = " "
style = "bold purple"
format = "on [$symbol$branch]($style) "

[git_status]
style = "bold red"
disabled = false
format = '[✖ $status]($style) '

[character]
success_symbol = "[❯](bold green) "
error_symbol = "[❯](bold red) "

# 3. TODOS LOS MÓDULOS Y GLIFOS DEL SEGUNDO ARCHIVO (FUSIONADOS)

[aws]
symbol = " "

[azure]
symbol = " "

[battery]
full_symbol = "󰁹 "
charging_symbol = "󰂄 "
discharging_symbol = "󰂃 "
unknown_symbol = "󰂑 "
empty_symbol = "󰂎 "

[buf]
symbol = " "

[bun]
symbol = " "

[c]
symbol = " "

[cpp]
symbol = " "

[cmake]
symbol = " "

[cobol]
symbol = " "

[conda]
symbol = " "

[container]
symbol = " "

[crystal]
symbol = " "

[dart]
symbol = " "

[deno]
symbol = " "

[direnv]
symbol = " "

[docker_context]
symbol = " "

[dotnet]
symbol = " "

[elixir]
symbol = " "

[elm]
symbol = " "

[erlang]
symbol = " "

[fennel]
symbol = " "

[fortran]
symbol = " "

[fossil_branch]
symbol = " "

[gcloud]
symbol = "󱇶 "
format = 'on [$symbol$account(@$project)(\($region\))]($style) '

[gcloud.region_aliases]
europe-west4 = 'eu-w4'

[gleam]
symbol = " "

[git_commit]
tag_symbol = '  '

[golang]
symbol = " "
style = "bold cyan"

[gradle]
symbol = " "

[guix_shell]
symbol = " "

[haskell]
symbol = " "

[haxe]
symbol = " "

[helm]
symbol = " "

[hg_branch]
symbol = " "

[java]
symbol = " "

[julia]
symbol = " "

[kotlin]
symbol = " "

[kubernetes]
disabled = false
symbol = "󱃾 "

[lua]
symbol = " "

[maven]
symbol = " "

[memory_usage]
symbol = "󰍛 "

[meson]
symbol = "󰔷 "

[mojo]
symbol = "󰈸 "

[nats]
symbol = " "

[netns]
symbol = "󰛳 "

[nim]
symbol = " "

[nix_shell]
symbol = " "

[nodejs]
symbol = " "
style = "bold green"

[ocaml]
symbol = " "

[odin]
symbol = "󰟢 "

[opa]
symbol = " "

[openstack]
symbol = " "

[os.symbols]
AIX = " "
AlmaLinux = " "
Alpaquita = " "
Alpine = " "
ALTLinux = " "
Amazon = " "
Android = " "
AOSC = " "
Arch = " "
Artix = " "
Bluefin = " "
CachyOS = " "
CentOS = " "
Debian = " "
DragonFly = " "
Elementary = " "
Emscripten = " "
EndeavourOS = " "
Fedora = " "
FreeBSD = " "
Garuda = " "
Gentoo = " "
HardenedBSD = "󰞌 "
Illumos = " "
InstantOS = " "
Ios = "󰀷 "
Kali = " "
Linux = " "
Mabox = " "
Macos = " "
Manjaro = " "
Mariner = " "
MidnightBSD = " "
Mint = " "
NetBSD = " "
NixOS = " "
Nobara = " "
OpenBSD = " "
OpenCloudOS = " "
openEuler = " "
openSUSE = " "
OracleLinux = "󰺡 "
PikaOS = " "
Pop = " "
Raspbian = " "
Redhat = "󱄛 "
RedHatEnterprise = "󱄛 "
Redox = "󰀘 "
RockyLinux = " "
Solus = " "
SUSE = " "
Ubuntu = " "
Ultramarine = " "
Unknown = " "
Uos = " "
Void = " "
Windows = "󰍲 "
Zorin = " "

[package]
symbol = "󰏗 "

[perl]
symbol = " "

[php]
symbol = " "

[pijul_channel]
symbol = " "

[pixi]
symbol = "󰏗 "

[pulumi]
symbol = " "

[purescript]
symbol = " "

[python]
symbol = " "
style = "bold yellow"

[raku]
symbol = "󱖊 "

[red]
symbol = "󱍼 "

[rlang]
symbol = "󰟔 "

[ruby]
symbol = " "

[rust]
symbol = "󱘗 "
style = "bold red"

[scala]
symbol = " "

[shlvl]
symbol = "󰹍 "

[singularity]
symbol = " "

[solidity]
symbol = " "

[spack]
symbol = " "

[sudo]
symbol = " "

[swift]
symbol = " "

[terraform]
symbol = " "

[vlang]
symbol = " "

[typst]
symbol = " "

[vagrant]
symbol = " "

[xmake]
symbol = " "

[zig]
symbol = " "
EOF

log "Starship configurado."

# ── Zellij ───────────────────────────────────────────────────────────────────
# Elegimos Zellij sobre tmux porque:
#   - Configuración en YAML/KDL (legible y versionable)
#   - UI con layouts y pestañas visibles por defecto
#   - Plugin system moderno
#   - Modo "sin prefijo": atajos de teclado intuitivos sin Ctrl-b
info "Instalando Zellij (multiplexor de terminal moderno)..."
ZELLIJ_VERSION=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest \
    | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"
curl -fsSL "$ZELLIJ_URL" | tar -xz -C /tmp
sudo install -m 0755 /tmp/zellij /usr/local/bin/zellij

mkdir -p "$USER_HOME/.config/zellij"
cat > "$USER_HOME/.config/zellij/config.kdl" <<'EOF'
// zellij config.kdl — configuración mínima
default_shell "zsh"
pane_frames false
mouse_mode true
copy_on_select true

keybinds clear-defaults=false {
    normal {
        bind "Ctrl a" { SwitchToMode "Tmux"; }
    }
}

theme "catppuccin-mocha"

layout_dir "~/.config/zellij/layouts"
EOF

log "Zellij instalado y configurado."
# El .zshrc se genera en la sección 3, después de conda init zsh,
# para que nuestro archivo sea el último en escribirse.

# ─────────────────────────────────────────────────────────────────────────────
# SECCIÓN 3: PYTHON — uv + Miniconda
# ─────────────────────────────────────────────────────────────────────────────
section "3/7 · Python: uv + Miniconda"

# ── uv ───────────────────────────────────────────────────────────────────────
info "Instalando uv (gestor moderno de Python)..."
curl -LsSf https://astral.sh/uv/install.sh | sh

log "uv instalado. Uso básico:"
info "  uv init mi-proyecto      # nuevo proyecto"
info "  uv add requests          # añadir dependencia"
info "  uv run main.py           # ejecutar"
info "  uv sync                  # sincronizar entorno"

# ── Miniconda ────────────────────────────────────────────────────────────────
CONDA="$USER_HOME/miniconda3/bin/conda"

if [[ ! -d "$USER_HOME/miniconda3" ]]; then
    info "Instalando Miniconda3..."
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    curl -fsSLo /tmp/miniconda.sh "$MINICONDA_URL"
    bash /tmp/miniconda.sh -b -p "$USER_HOME/miniconda3"
    rm /tmp/miniconda.sh
else
    warn "Miniconda ya está instalado, continuando configuración..."
fi

# Aceptar ToS de los canales oficiales (requerido desde 2024)
info "Aceptando Terms of Service de los canales de Anaconda..."
"$CONDA" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main || true
"$CONDA" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r    || true

# Inicializa conda (modifica .zshrc temporalmente — lo sobrescribiremos luego)
"$CONDA" init zsh
"$CONDA" config --set auto_activate_base false

info "Creando entorno 'ai' para IA/ML (python 3.12 + stack ML)..."
"$CONDA" create -y -n ai python=3.12 \
    --channel conda-forge \
    numpy pandas scikit-learn matplotlib seaborn jupyter ipykernel \
    || warn "El entorno 'ai' no pudo crearse. Créalo manualmente: conda create -n ai python=3.12"

log "Entorno 'ai' listo. Actívalo con: conda activate ai"
log "Python configurado."

# ── .zshrc completo (se escribe aquí, DESPUÉS de conda init) ─────────────────
# conda init ya escribió su bloque en .zshrc; lo sobreescribimos con nuestra
# config completa que incluye el bloque de conda al final.
info "Generando .zshrc definitivo..."
cat > "$ZSHRC" <<'ZSHRC_EOF'
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
__conda_setup="$('/home/$(whoami)/miniconda3/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
fi
unset __conda_setup
# conda auto_activate_base = false → no activa 'base' al abrir terminal

ZSHRC_EOF

log ".zshrc generado."

# ─────────────────────────────────────────────────────────────────────────────
# SECCIÓN 4: NODE.JS — fnm + pnpm + bun
# ─────────────────────────────────────────────────────────────────────────────
section "4/7 · Node.js: fnm + pnpm + bun"

# ── fnm ──────────────────────────────────────────────────────────────────────
info "Instalando fnm (Fast Node Manager)..."
curl -fsSL https://fnm.vercel.app/install | bash

# Carga fnm en esta sesión para poder usarlo ya
export FNM_PATH="$HOME/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
eval "$(fnm env --use-on-cd --shell bash)"  # bash porque aún no estamos en zsh

info "Instalando Node.js LTS..."
fnm install --lts
fnm default "$(fnm list | grep lts | tail -1 | awk '{print $2}')"
fnm use default

log "Node.js $(node --version) instalado con fnm."

# ── pnpm ─────────────────────────────────────────────────────────────────────
info "Instalando pnpm via script oficial (standalone)..."
# NO usamos 'npm install -g pnpm' porque falla al crear symlinks con fnm.
# El script oficial instala pnpm como binario standalone independiente de npm.
curl -fsSL https://get.pnpm.io/install.sh | sh -s --

# Cargar pnpm en esta sesión
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Esperar a que el binario esté disponible
sleep 1

log "pnpm $(pnpm --version 2>/dev/null || echo 'instalado') instalado."
info "Uso básico de pnpm:"
info "  pnpm create vite mi-app  # nuevo proyecto"
info "  pnpm add express         # añadir dependencia"
info "  pnpm run dev             # ejecutar script"

# ── bun ──────────────────────────────────────────────────────────────────────
info "Instalando bun (runtime y tooling moderno)..."
curl -fsSL https://bun.sh/install | bash

log "bun instalado."
info "Uso de bun:"
info "  bun run script.ts        # ejecutar TS directamente"
info "  bun build ./src/index.ts # bundling"
info "  bun x vite               # usar sin instalar (como npx)"
info "  Para proyectos nuevos: puedes usar 'bun init' o seguir con pnpm."

# ─────────────────────────────────────────────────────────────────────────────
# SECCIÓN 5: GO
# ─────────────────────────────────────────────────────────────────────────────
section "5/7 · Go (desde tarball oficial)"

GO_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
info "Descargando Go ${GO_VERSION}..."
curl -fsSLo /tmp/go.tar.gz "$GO_URL"

info "Instalando en /usr/local/go..."
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

# Añadir al PATH para esta sesión
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
mkdir -p "$GOPATH/bin"

log "Go $(go version) instalado."

# ── Herramientas Go útiles ────────────────────────────────────────────────────
info "Instalando herramientas Go útiles..."
go install golang.org/x/tools/gopls@latest          # LSP para Go
go install github.com/go-delve/delve/cmd/dlv@latest # Debugger
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
log "Herramientas Go instaladas en $GOPATH/bin."

# ─────────────────────────────────────────────────────────────────────────────
# SECCIÓN 6: RUST
# ─────────────────────────────────────────────────────────────────────────────
section "6/7 · Rust (rustup)"

info "Instalando Rust via rustup..."
# rustup-init NO acepta --component; los componentes se añaden después
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    --default-toolchain stable

# Carga cargo en esta sesión
source "$HOME/.cargo/env"

info "Añadiendo componentes al toolchain stable..."
rustup component add clippy rustfmt rust-analyzer

info "Añadiendo toolchains adicionales..."
rustup toolchain install beta
rustup toolchain install nightly

info "Instalando herramientas del ecosistema Rust..."
# --locked: usa las versiones exactas del Cargo.lock del proyecto (más rápido y reproducible)
# --quiet:  suprime el output de compilación (sigue tardando igual, pero sin spam)
cargo install --locked --quiet cargo-audit       # auditoría de seguridad en deps
cargo install --locked --quiet cargo-outdated    # detecta deps desactualizadas
cargo install --locked --quiet cargo-watch       # rebuild automático en desarrollo
cargo install --locked --quiet cargo-expand      # expande macros para debuggear
cargo install --locked --quiet cargo-nextest     # test runner moderno (más rápido que cargo test)

log "Rust $(rustc --version) instalado. Toolchains: stable, beta, nightly."
info "Nota: cargo install compila desde fuente — es normal que tarde varios minutos."

# ─────────────────────────────────────────────────────────────────────────────
# SECCIÓN 7: DOCKER ENGINE + COMPOSE V2
# ─────────────────────────────────────────────────────────────────────────────
section "7a/7 · Docker Engine (repo oficial)"

info "Configurando repositorio oficial de Docker para Debian..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -qq
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

info "Añadiendo $USER al grupo docker (requiere re-login para activarse)..."
sudo usermod -aG docker "$USER"

info "Habilitando y arrancando Docker..."
sudo systemctl enable docker
sudo systemctl start docker

log "Docker $(docker --version) instalado."
log "Docker Compose $(docker compose version) instalado."
warn "IMPORTANTE: Cierra sesión y vuelve a entrar para usar Docker sin sudo."

# ── Ejemplo docker-compose ────────────────────────────────────────────────────
mkdir -p "$USER_HOME/docker-examples/webapp"
cat > "$USER_HOME/docker-examples/webapp/compose.yml" <<'EOF'
# compose.yml — Stack mínimo: app web + PostgreSQL
services:
  app:
    image: node:lts-alpine
    working_dir: /app
    volumes:
      - ./app:/app
    command: sh -c "npm install && npm start"
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgres://user:password@db:5432/mydb
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mydb"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
EOF

log "Ejemplo compose.yml creado en ~/docker-examples/webapp/"

# ─────────────────────────────────────────────────────────────────────────────
# SECCIÓN 7b: CLI STACK MODERNO
# ─────────────────────────────────────────────────────────────────────────────
section "7b/7 · CLI Stack Moderno"

# ── Herramientas disponibles en apt ──────────────────────────────────────────
info "Instalando desde apt: ripgrep, bat, fd-find, fzf, btop, git-delta..."
sudo apt-get install -y \
    ripgrep \
    bat \
    fd-find \
    fzf \
    btop \
    git-delta

# Crear symlinks para comandos con nombre diferente en Debian
sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true

log "Herramientas base instaladas desde apt."

# ── tldr → tealdeer (implementación en Rust, no está en apt de Debian 13) ────
info "Instalando tealdeer (tldr en Rust)..."
TLDR_URL="https://github.com/dbrgn/tealdeer/releases/latest/download/tealdeer-linux-x86_64-musl"
curl -fsSLo /tmp/tldr "$TLDR_URL"
sudo install -m 0755 /tmp/tldr /usr/local/bin/tldr
rm /tmp/tldr
# Descargar caché de páginas al instalar
tldr --update 2>/dev/null || true
log "tealdeer (tldr) instalado."

# ── eza (ls moderno) ──────────────────────────────────────────────────────────
info "Instalando eza..."
# eza no está en apt de Debian 13 estable, instalar desde GitHub
EZA_VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest \
    | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
curl -fsSLo /tmp/eza.tar.gz "$EZA_URL"
tar -xzf /tmp/eza.tar.gz -C /tmp
sudo install -m 0755 /tmp/eza /usr/local/bin/eza
rm /tmp/eza.tar.gz /tmp/eza 2>/dev/null || true
log "eza instalado."

# ── zoxide (cd inteligente) ───────────────────────────────────────────────────
info "Instalando zoxide..."
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
log "zoxide instalado."

# ── lazygit ───────────────────────────────────────────────────────────────────
info "Instalando lazygit..."
LG_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -fsSLo /tmp/lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz"
tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
sudo install -m 0755 /tmp/lazygit /usr/local/bin/lazygit
rm /tmp/lazygit.tar.gz /tmp/lazygit 2>/dev/null || true
log "lazygit instalado."

# ── lazydocker ────────────────────────────────────────────────────────────────
info "Instalando lazydocker..."
curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
sudo install -m 0755 "$HOME/.local/bin/lazydocker" /usr/local/bin/lazydocker 2>/dev/null || true
log "lazydocker instalado."

# ── yazi (file manager TUI) ───────────────────────────────────────────────────
info "Instalando yazi..."
YAZI_VERSION=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest \
    | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -fsSLo /tmp/yazi.zip \
    "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
unzip -q /tmp/yazi.zip -d /tmp/yazi-extracted
sudo install -m 0755 "/tmp/yazi-extracted/yazi-x86_64-unknown-linux-gnu/yazi" /usr/local/bin/yazi
sudo install -m 0755 "/tmp/yazi-extracted/yazi-x86_64-unknown-linux-gnu/ya" /usr/local/bin/ya
rm -rf /tmp/yazi.zip /tmp/yazi-extracted
log "yazi instalado."

# ── Glow (markdown renderer TUI) ───────────────────────────────────────────────────
info "Instalando Glow..."
GLOW_VERSION=$(curl -s https://api.github.com/repos/charmbracelet/glow/releases/latest \
    | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -fsSLo /tmp/glow.tar.gz \
    "https://github.com/charmbracelet/glow/releases/latest/download/glow_${GLOW_VERSION}_Linux_x86_64.tar.gz"
# Extrae solo el ejecutable directo a /tmp/glow
tar -xzf /tmp/glow.tar.gz -C /tmp --strip-components=1 "glow_${GLOW_VERSION}_Linux_x86_64/glow"
sudo install -m 0755 /tmp/glow /usr/local/bin/glow
rm /tmp/glow.tar.gz /tmp/glow 2>/dev/null || true
log "Glow instalado."

# ── Configurar git-delta como pager por defecto ───────────────────────────────
info "Configurando delta como git pager..."
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.line-numbers true
git config --global delta.side-by-side true
git config --global delta.syntax-theme "Dracula"
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default
log "delta configurado como pager de git."

# ── Configuración global de git ───────────────────────────────────────────────
info "Configuración global de git (actualiza con tus datos)..."
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global fetch.prune true
git config --global rebase.autoStash true
git config --global push.autoSetupRemote true
git config --global rerere.enabled true

# ─────────────────────────────────────────────────────────────────────────────
# SECCIÓN 8: NERD FONTS
# Necesarias para que eza --icons, starship, lazygit, yazi rendericen símbolos
# ─────────────────────────────────────────────────────────────────────────────
section "8/9 · Nerd Fonts"

# fontconfig provee fc-cache y fc-list (puede no estar en instalaciones mínimas)
command -v fc-cache &>/dev/null || sudo apt-get install -y fontconfig

FONTS_DIR="$USER_HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

# Fuentes a instalar: JetBrainsMono (coding), FiraCode (ligaduras), CascadiaCode (moderna)
declare -A NERD_FONTS=(
    ["JetBrainsMono"]="JetBrainsMono.tar.xz"
    ["FiraCode"]="FiraCode.tar.xz"
    ["CascadiaCode"]="CascadiaCode.tar.xz"
)

NF_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

for font_name in "${!NERD_FONTS[@]}"; do
    font_file="${NERD_FONTS[$font_name]}"
    info "Descargando Nerd Font: ${font_name}..."
    if curl -fsSLo "/tmp/${font_file}" "${NF_BASE_URL}/${font_file}"; then
        mkdir -p "/tmp/nf_${font_name}"
        tar -xf "/tmp/${font_file}" -C "/tmp/nf_${font_name}" 2>/dev/null || true
        # Copiar solo los archivos .ttf y .otf, excluir Windows fonts
        find "/tmp/nf_${font_name}" -name "*.ttf" -o -name "*.otf" | \
            grep -v -i "windows\|Win\| NF " | \
            xargs -I{} cp {} "$FONTS_DIR/" 2>/dev/null || true
        rm -rf "/tmp/${font_file}" "/tmp/nf_${font_name}"
        log "${font_name} Nerd Font instalada."
    else
        warn "No se pudo descargar ${font_name}, continuando..."
    fi
done

info "Actualizando caché de fuentes del sistema..."
fc-cache -f "$FONTS_DIR"
log "Fuentes instaladas en $FONTS_DIR"
info "Fuentes disponibles para usar en Ghostty/terminal:"
fc-list | grep -i "NerdFont" | awk -F: '{print $2}' | sort -u | head -20

# -----------------------------------------------------------------------------
# SECCION 9: GHOSTTY (emulador de terminal moderno)
# Fuente: repo unofficial de Dario Griffo para Debian (Trixie soportado)
# https://github.com/dariogriffo/ghostty-debian
# -----------------------------------------------------------------------------
section "9/9 · Ghostty"

info "Configurando repo unofficial de Ghostty para Debian (debian.griffo.io)..."

# 1. Clave GPG del repositorio
sudo curl -fsSL https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
    | sudo gpg --dearmor -o /usr/share/keyrings/debian.griffo.io.gpg

# 2. Repositorio — lsb_release -sc detecta 'trixie' automaticamente
echo "deb [signed-by=/usr/share/keyrings/debian.griffo.io.gpg] \
https://debian.griffo.io/apt $(lsb_release -sc) main" \
    | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list > /dev/null

# 3. Instalar
sudo apt-get update -qq
if sudo apt-get install -y ghostty; then
    log "Ghostty instalado correctamente."
else
    warn "No se pudo instalar Ghostty. Instala manualmente:"
    warn "  https://github.com/dariogriffo/ghostty-debian"
fi


# ── Configuración de Ghostty ─────────────────────────────────────────────────
mkdir -p "$USER_HOME/.config/ghostty"
cat > "$USER_HOME/.config/ghostty/config" <<'EOF'
# ─────────────────────────────────────────────────────
# Ghostty config — stack de desarrollo en Debian 13
# ─────────────────────────────────────────────────────

# Fuente — usar la Nerd Font instalada
# Opciones: "JetBrainsMono Nerd Font", "FiraCode Nerd Font", "CaskaydiaCove Nerd Font"
font-family = "JetBrainsMono Nerd Font"
font-size = 10
font-feature = calt
font-feature = liga

# Tema de color


# Ventana
window-padding-x = 10
window-padding-y = 8
window-decoration = none
unfocused-split-opacity = 0.9

# Shell
command = /usr/bin/zsh

# Cursor
cursor-style = block
cursor-style-blink = false

# Performance
window-vsync = true

# Integración con shell (habilita OSC 133 para prompts)
shell-integration = zsh
shell-integration-features = cursor,sudo,title

# Copiar al seleccionar
copy-on-select = clipboard

# URLs clickeables
link-url = true

# Scrollback
scrollback-limit = 10000

# Keybindings útiles
# Ghostty usa Ctrl+Shift por defecto para no colisionar con Zellij
keybind = ctrl+shift+c=copy_to_clipboard
keybind = ctrl+shift+v=paste_from_clipboard
keybind = ctrl+shift+t=new_tab
keybind = ctrl+shift+w=close_surface
keybind = ctrl+shift+equal=increase_font_size:1
keybind = ctrl+shift+minus=decrease_font_size:1
keybind = ctrl+shift+0=reset_font_size
EOF

log "Ghostty configurado en ~/.config/ghostty/config"
info "Fuente configurada: JetBrainsMono Nerd Font (cámbiala en ~/.config/ghostty/config)"
info "Para cambiar tema: edita 'theme = ' — ghostty incluye catppuccin, gruvbox, tokyo-night, etc."

# ─────────────────────────────────────────────────────────────────────────────
# SECCIÓN 10: Visual Studio Code + Brave Browser
# ─────────────────────────────────────────────────────────────────────────────
section "10/10 · Visual Studio Code + Brave Browser"

info "Configurando repositorio de Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg

sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

info "Configurando repositorio de Brave Browser..."
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
    https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

info "Actualizando índices de paquetes..."
sudo apt-get update -qq

info "Instalando Visual Studio Code y Brave Browser..."
sudo apt-get install -y code brave-browser

log "Visual Studio Code $(code --version | head -n 1) instalado."
log "Brave Browser instalado."

# ─────────────────────────────────────────────────────────────────────────────
# RESUMEN FINAL
# ─────────────────────────────────────────────────────────────────────────────
section "✅ Instalación completa"

echo -e "${BOLD}Stack instalado:${NC}"
echo ""
echo -e "  ${GREEN}Shell${NC}        zsh + Oh My Zsh + Starship + Zellij"
echo -e "  ${GREEN}Python${NC}       uv + Miniconda3 (entorno ai con Python 3.12)"
echo -e "  ${GREEN}Node.js${NC}      fnm + Node LTS + pnpm + bun"
echo -e "  ${GREEN}Go${NC}           ${GO_VERSION} en /usr/local/go"
echo -e "  ${GREEN}Rust${NC}         rustup (stable/beta/nightly) + cargo tools"
echo -e "  ${GREEN}Docker${NC}       Engine + Compose v2 (plugin)"
echo -e "  ${GREEN}CLI Tools${NC}    eza, fd, bat, rg, fzf, zoxide, yazi, lazygit,"
echo -e "               lazydocker, delta, btop, tldr, zellij"
echo -e "  ${GREEN}Editor/Web${NC}   Visual Studio Code + Brave Browser"
echo -e "  ${GREEN}Fuentes${NC}      JetBrainsMono / FiraCode / CascadiaCode (Nerd Fonts)"
echo -e "  ${GREEN}Terminal${NC}     Ghostty + config en ~/.config/ghostty/config"
echo ""
echo -e "${YELLOW}⚠ Acciones manuales necesarias:${NC}"
echo ""
echo -e "  1. ${BOLD}Cierra sesión y vuelve a entrar${NC} para:"
echo -e "     - Que Docker funcione sin sudo (grupo docker)"
echo -e "     - Que zsh sea tu shell activo"
echo ""
echo -e "  2. ${BOLD}Configura tu identidad en git:${NC}"
echo -e "     git config --global user.name \"Tu Nombre\""
echo -e "     git config --global user.email \"tu@email.com\""
echo ""
echo -e "  3. ${BOLD}Actualiza GO_VERSION${NC} en este script a la versión más reciente:"
echo -e "     https://go.dev/dl/"
echo ""
echo -e "  4. ${BOLD}Para activar conda:${NC}"
echo -e "     source ~/miniconda3/etc/profile.d/conda.sh"
echo -e "     conda activate ai"
echo ""
echo -e "  5. ${BOLD}Selecciona la fuente en Ghostty${NC} (ya configurada):"
echo -e "     Abre Ghostty → la fuente JetBrainsMono Nerd Font se aplica automáticamente."
echo -e "     Para cambiarla: edita ~/.config/ghostty/config → font-family"
echo ""
echo -e "  6. ${BOLD}Abre una nueva terminal Ghostty${NC} (o ejecuta: exec zsh) para activar todo."
echo ""
echo -e "${CYAN}Happy hacking! 🚀${NC}"

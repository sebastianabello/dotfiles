#!/usr/bin/env bash
# =============================================================================
# setup-debian13.sh
# Entorno de desarrollo completo en Debian 13 (Trixie). Idempotente: se puede
# ejecutar varias veces; lo ya instalado se omite. Soporta x86_64 y arm64.
#
# Uso:   bash setup-debian13.sh
# Vars:  GO_VERSION=1.xx.x      fuerza una versión de Go (por defecto la última)
#        SKIP_CARGO_TOOLS=1     omite la compilación de herramientas cargo
# =============================================================================

set -euo pipefail

# ─── Salida ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()     { echo -e "${GREEN}[✔]${NC} $1"; }
info()    { echo -e "${BLUE}[→]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
section() { echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}\n"; }
err()     { echo -e "${RED}[✘]${NC} $1" >&2; exit 1; }

has() { command -v "$1" &>/dev/null; }

# ─── Comprobaciones previas ──────────────────────────────────────────────────
[[ "$EUID" -eq 0 ]] && err "No ejecutes este script como root. Usa tu usuario normal (con sudo)."
has sudo || err "Se necesita sudo."

# shellcheck source=/dev/null
. /etc/os-release
if [[ "${ID:-}" != "debian" || "${VERSION_CODENAME:-}" != "trixie" ]]; then
    warn "Este script está pensado para Debian 13 (trixie); detectado: ${PRETTY_NAME:-desconocido}."
    warn "Continúa bajo tu responsabilidad (Ctrl+C para cancelar, 5 s)..."
    sleep 5
fi

case "$(uname -m)" in
    x86_64)        ARCH="x86_64";  ARCH_ALT="amd64" ;;
    aarch64|arm64) ARCH="aarch64"; ARCH_ALT="arm64" ;;
    *) err "Arquitectura no soportada: $(uname -m)" ;;
esac

USER_HOME="${HOME}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Directorio temporal propio, siempre limpiado al salir
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$USER_HOME/.local/bin" "$USER_HOME/.config"
export PATH="$USER_HOME/.local/bin:$PATH"

# ─── Helpers ─────────────────────────────────────────────────────────────────

# Última versión publicada de un repo de GitHub, sin usar la API (sin rate limit)
latest_tag() {
    curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" \
        | sed 's#.*/tag/##'
}

# install_release <nombre> <url> [binario...]
# Descarga un binario o archivo (.tar.gz/.tar.xz/.zip), busca los ejecutables
# indicados (por defecto <nombre>) y los instala en /usr/local/bin.
install_release() {
    local name="$1" url="$2"; shift 2
    local bins=("$@"); [[ ${#bins[@]} -eq 0 ]] && bins=("$name")
    local dir="$TMP/$name"; mkdir -p "$dir"
    local file="$dir/download"
    curl -fsSL -o "$file" "$url"
    case "$url" in
        *.tar.gz|*.tgz|*.tar.xz) tar -xf "$file" -C "$dir" ;;
        *.zip)                   unzip -q "$file" -d "$dir" ;;
        *)                       mv "$file" "$dir/$name" ;;
    esac
    local b path
    for b in "${bins[@]}"; do
        path="$(find "$dir" -type f -name "$b" | head -n1)"
        [[ -n "$path" ]] || err "No se encontró '$b' dentro de $url"
        sudo install -m 0755 "$path" "/usr/local/bin/$b"
    done
}

# ─────────────────────────────────────────────────────────────────────────────
section "1/10 · Sistema base"
# ─────────────────────────────────────────────────────────────────────────────

SOURCES_FILE="/etc/apt/sources.list.d/debian.sources"
[[ -f "$SOURCES_FILE" ]] || SOURCES_FILE="/etc/apt/sources.list.d/0000debian.sources"
if [[ -f "$SOURCES_FILE" ]] && ! grep -q "non-free" "$SOURCES_FILE"; then
    info "Añadiendo contrib/non-free/non-free-firmware a $SOURCES_FILE (con copia de seguridad)..."
    sudo cp -n "$SOURCES_FILE" "${SOURCES_FILE}.bak"
    sudo sed -i -E '/^Components:/ s/$/ contrib non-free non-free-firmware/' "$SOURCES_FILE"
else
    info "Repositorios de Debian: sin cambios necesarios."
fi

info "Actualizando sistema..."
sudo apt-get update -qq
sudo apt-get upgrade -y

info "Instalando paquetes base..."
sudo apt-get install -y \
    build-essential curl wget git gh git-lfs gnupg2 ca-certificates lsb-release \
    apt-transport-https unzip zip tar xz-utils jq htop man-db tree vim neovim \
    stow direnv pkg-config libssl-dev libffi-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncurses-dev libxml2-dev libxmlsec1-dev \
    liblzma-dev tk-dev llvm fontconfig

log "Sistema base listo."

# ── Neovim ≥ 0.11 (la config usa la API vim.lsp.config) ──────────────────────
nvim_minor() { nvim --version 2>/dev/null | head -n1 | sed -E 's/^NVIM v[0-9]+\.([0-9]+).*/\1/'; }
if ! has nvim || [[ "$(nvim_minor)" -lt 11 ]]; then
    info "Neovim de apt es antiguo (o falta). Instalando la última versión oficial..."
    NVIM_ARCH="$ARCH"; [[ "$ARCH" == "aarch64" ]] && NVIM_ARCH="arm64"
    curl -fsSL -o "$TMP/nvim.tar.gz" \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
    sudo rm -rf /opt/nvim && sudo mkdir -p /opt/nvim
    sudo tar -xzf "$TMP/nvim.tar.gz" -C /opt/nvim --strip-components=1
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
fi
log "Neovim $(nvim --version | head -n1)."

# ─────────────────────────────────────────────────────────────────────────────
section "2/10 · Shell: zsh + Oh My Zsh + Starship + Zellij"
# ─────────────────────────────────────────────────────────────────────────────

has zsh || sudo apt-get install -y zsh
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != *zsh ]]; then
    info "Cambiando shell por defecto a zsh..."
    sudo chsh -s "$(command -v zsh)" "$USER"
fi

if [[ ! -d "$USER_HOME/.oh-my-zsh" ]]; then
    info "Instalando Oh My Zsh..."
    # KEEP_ZSHRC: no tocar el .zshrc (lo gestiona este repo vía stow)
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    if [[ ! -d "${ZSH_CUSTOM}/plugins/${plugin}" ]]; then
        info "Plugin zsh: ${plugin}"
        git clone --depth=1 "https://github.com/zsh-users/${plugin}" "${ZSH_CUSTOM}/plugins/${plugin}"
    fi
done

if ! has starship; then
    info "Instalando Starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$USER_HOME/.local/bin"
fi

if ! has zellij; then
    info "Instalando Zellij..."
    install_release zellij \
        "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ARCH}-unknown-linux-musl.tar.gz"
fi
log "Shell listo."

# ─────────────────────────────────────────────────────────────────────────────
section "3/10 · Python: uv + Miniconda"
# ─────────────────────────────────────────────────────────────────────────────

if ! has uv; then
    info "Instalando uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

CONDA="$USER_HOME/miniconda3/bin/conda"
if [[ ! -x "$CONDA" ]]; then
    info "Instalando Miniconda3..."
    curl -fsSLo "$TMP/miniconda.sh" \
        "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${ARCH}.sh"
    bash "$TMP/miniconda.sh" -b -p "$USER_HOME/miniconda3"
fi

# NO se ejecuta `conda init`: el .zshrc de este repo ya carga conda de forma
# diferida y `conda init` volvería a ensuciarlo con su bloque.
"$CONDA" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main 2>/dev/null || true
"$CONDA" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r    2>/dev/null || true
"$CONDA" config --set auto_activate_base false

if ! "$CONDA" env list | grep -qE '^ai\s'; then
    info "Creando entorno 'ai' (python 3.12 + stack ML)..."
    "$CONDA" create -y -n ai python=3.12 --channel conda-forge \
        numpy pandas scikit-learn matplotlib seaborn jupyter ipykernel \
        || warn "No se pudo crear 'ai'. Créalo a mano: conda create -n ai python=3.12"
fi
log "Python listo."

# ─────────────────────────────────────────────────────────────────────────────
section "4/10 · Node.js: fnm + pnpm + bun"
# ─────────────────────────────────────────────────────────────────────────────

export FNM_PATH="$USER_HOME/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
if ! has fnm; then
    info "Instalando fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi
eval "$(fnm env --shell bash)"
if ! has node; then
    info "Instalando Node.js LTS..."
    fnm install --lts
    fnm default lts-latest
    fnm use lts-latest
fi
log "Node $(node --version) con fnm."

export PNPM_HOME="$USER_HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
if ! has pnpm; then
    info "Instalando pnpm (standalone)..."
    curl -fsSL https://get.pnpm.io/install.sh | env PNPM_HOME="$PNPM_HOME" SHELL="$(command -v zsh)" sh -s --
fi

export BUN_INSTALL="$USER_HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
if ! has bun; then
    info "Instalando bun..."
    curl -fsSL https://bun.sh/install | bash
fi
log "Node.js listo."

# ─────────────────────────────────────────────────────────────────────────────
section "5/10 · Go"
# ─────────────────────────────────────────────────────────────────────────────

GO_VERSION="${GO_VERSION:-$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1 | sed 's/^go//')}"
[[ -n "$GO_VERSION" ]] || err "No se pudo determinar la versión de Go."
export PATH="/usr/local/go/bin:$PATH"
if [[ "$(go version 2>/dev/null || true)" != *"go${GO_VERSION} "* ]]; then
    info "Instalando Go ${GO_VERSION}..."
    curl -fsSLo "$TMP/go.tar.gz" "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH_ALT}.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$TMP/go.tar.gz"
fi
export GOPATH="$USER_HOME/go"
export PATH="$GOPATH/bin:$PATH"
mkdir -p "$GOPATH/bin"

for tool in gopls:golang.org/x/tools/gopls dlv:github.com/go-delve/delve/cmd/dlv \
            golangci-lint:github.com/golangci/golangci-lint/cmd/golangci-lint; do
    bin="${tool%%:*}"; pkg="${tool#*:}"
    has "$bin" || { info "go install $bin"; go install "${pkg}@latest"; }
done
log "$(go version)"

# ─────────────────────────────────────────────────────────────────────────────
section "6/10 · Rust"
# ─────────────────────────────────────────────────────────────────────────────

if ! has rustup && [[ ! -x "$USER_HOME/.cargo/bin/rustup" ]]; then
    info "Instalando Rust (rustup)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
fi
set +u; . "$USER_HOME/.cargo/env"; set -u

rustup component add clippy rustfmt rust-analyzer
rustup toolchain list | grep -q '^beta'    || rustup toolchain install beta
rustup toolchain list | grep -q '^nightly' || rustup toolchain install nightly

if [[ -z "${SKIP_CARGO_TOOLS:-}" ]]; then
    info "Herramientas cargo (compilan desde fuente: pueden tardar varios minutos)..."
    for crate in cargo-audit cargo-outdated cargo-watch cargo-expand cargo-nextest; do
        has "$crate" || cargo install --locked --quiet "$crate"
    done
fi
log "$(rustc --version)"

# ─────────────────────────────────────────────────────────────────────────────
section "7/10 · Docker Engine + Compose v2"
# ─────────────────────────────────────────────────────────────────────────────

if ! has docker; then
    info "Configurando repositorio oficial de Docker..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=${ARCH_ALT} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
sudo usermod -aG docker "$USER"
sudo systemctl enable --now docker
log "$(docker --version)"

# ─────────────────────────────────────────────────────────────────────────────
section "8/10 · CLI moderno"
# ─────────────────────────────────────────────────────────────────────────────

sudo apt-get install -y ripgrep bat fd-find fzf btop git-delta

# En Debian bat→batcat y fd→fdfind: symlinks en ~/.local/bin (sin sudo)
has bat || ln -sf /usr/bin/batcat "$USER_HOME/.local/bin/bat"
has fd  || ln -sf /usr/bin/fdfind "$USER_HOME/.local/bin/fd"

has tldr || {
    info "Instalando tealdeer (tldr)..."
    install_release tldr \
        "https://github.com/tealdeer-rs/tealdeer/releases/latest/download/tealdeer-linux-${ARCH}-musl"
    tldr --update 2>/dev/null || true
}

has eza || {
    info "Instalando eza..."
    install_release eza \
        "https://github.com/eza-community/eza/releases/latest/download/eza_${ARCH}-unknown-linux-gnu.tar.gz"
}

has zoxide || {
    info "Instalando zoxide..."
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

has lazygit || {
    info "Instalando lazygit..."
    LG_ARCH="$ARCH"; [[ "$ARCH" == "aarch64" ]] && LG_ARCH="arm64"
    LG_VERSION="$(latest_tag jesseduffield/lazygit)"
    install_release lazygit \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VERSION#v}_Linux_${LG_ARCH}.tar.gz"
}

has lazydocker || {
    info "Instalando lazydocker..."
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | DIR="$USER_HOME/.local/bin" bash
}

has yazi || {
    info "Instalando yazi..."
    install_release yazi \
        "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${ARCH}-unknown-linux-gnu.zip" yazi ya
}

has glow || {
    info "Instalando glow..."
    GL_ARCH="$ARCH"; [[ "$ARCH" == "aarch64" ]] && GL_ARCH="arm64"
    GL_VERSION="$(latest_tag charmbracelet/glow)"
    install_release glow \
        "https://github.com/charmbracelet/glow/releases/latest/download/glow_${GL_VERSION#v}_Linux_${GL_ARCH}.tar.gz"
}
log "CLI moderno listo."

# ─────────────────────────────────────────────────────────────────────────────
section "9/10 · Nerd Fonts + Ghostty"
# ─────────────────────────────────────────────────────────────────────────────

FONTS_DIR="$USER_HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"
NF_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

# archivo → patrón con el que fc-list reconoce la familia ya instalada
declare -A NERD_FONTS=(
    ["JetBrainsMono"]="JetBrainsMono Nerd"
    ["FiraCode"]="FiraCode Nerd"
    ["CascadiaCode"]="CaskaydiaCove Nerd"
)
for font in "${!NERD_FONTS[@]}"; do
    if fc-list | grep -qi "${NERD_FONTS[$font]}"; then
        continue
    fi
    info "Descargando Nerd Font: ${font}..."
    if curl -fsSLo "$TMP/${font}.tar.xz" "${NF_BASE_URL}/${font}.tar.xz"; then
        mkdir -p "$TMP/nf_${font}"
        tar -xf "$TMP/${font}.tar.xz" -C "$TMP/nf_${font}"
        find "$TMP/nf_${font}" \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "$FONTS_DIR/" \;
    else
        warn "No se pudo descargar ${font}, continuando..."
    fi
done
fc-cache -f "$FONTS_DIR"

# Ghostty: repo no oficial de Dario Griffo para Debian
# https://github.com/dariogriffo/ghostty-debian
if ! has ghostty; then
    info "Instalando Ghostty (repo debian.griffo.io)..."
    sudo curl -fsSL https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
        | sudo gpg --dearmor --yes -o /usr/share/keyrings/debian.griffo.io.gpg
    echo "deb [signed-by=/usr/share/keyrings/debian.griffo.io.gpg] https://debian.griffo.io/apt ${VERSION_CODENAME} main" \
        | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y ghostty \
        || warn "No se pudo instalar Ghostty. Ver https://github.com/dariogriffo/ghostty-debian"
fi

# ─────────────────────────────────────────────────────────────────────────────
section "10/10 · Visual Studio Code + Brave"
# ─────────────────────────────────────────────────────────────────────────────

if ! has code; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | sudo gpg --dearmor --yes -o /usr/share/keyrings/microsoft.gpg
    sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
fi
if ! has brave-browser; then
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
        https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
fi
sudo apt-get update -qq
sudo apt-get install -y code brave-browser
log "VS Code y Brave listos."

# ─────────────────────────────────────────────────────────────────────────────
section "Dotfiles (GNU Stow) + Neovim"
# ─────────────────────────────────────────────────────────────────────────────

if [[ -f "$DOTFILES_DIR/install.sh" ]]; then
    bash "$DOTFILES_DIR/install.sh" --all
else
    warn "install.sh no encontrado en $DOTFILES_DIR"
fi

# Neovim: plugins (lazy.nvim), servidores/formateadores (mason) y parsers (treesitter)
if has nvim && [[ -d "$USER_HOME/.config/nvim" ]]; then
    info "Preparando Neovim (plugins, LSP y parsers; puede tardar)..."
    nvim --headless "+Lazy! sync" +qa || warn "Falló Lazy sync; ábrelo con nvim y ejecuta :Lazy sync"
    nvim --headless "+MasonToolsInstallSync" +qa || warn "Falló la instalación de herramientas de mason"
    nvim --headless "+TSInstallAll" +qa || warn "Falló la instalación de parsers de treesitter"
fi

# ─────────────────────────────────────────────────────────────────────────────
section "✅ Instalación completa"
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${BOLD}Stack:${NC}"
echo -e "  ${GREEN}Shell${NC}      zsh + Oh My Zsh + Starship + Zellij"
echo -e "  ${GREEN}Editor${NC}     Neovim (Lua, lazy.nvim) + VS Code"
echo -e "  ${GREEN}Python${NC}     uv + Miniconda3 (entorno 'ai')"
echo -e "  ${GREEN}Node.js${NC}    fnm + pnpm + bun"
echo -e "  ${GREEN}Go / Rust${NC}  Go ${GO_VERSION} · rustup (stable/beta/nightly)"
echo -e "  ${GREEN}Docker${NC}     Engine + Compose v2"
echo -e "  ${GREEN}CLI${NC}        eza fd bat rg fzf zoxide yazi lazygit lazydocker delta btop tldr glow"
echo -e "  ${GREEN}Terminal${NC}   Ghostty + Nerd Fonts"
echo ""
echo -e "${YELLOW}Pasos manuales:${NC}"
echo -e "  1. Cierra sesión y vuelve a entrar (grupo docker + zsh como shell)."
echo -e "  2. ${BOLD}gh auth login${NC}  y luego  ${BOLD}gh auth setup-git${NC}  (credenciales de GitHub)."
echo -e "  3. Abre una terminal nueva (o ejecuta: exec zsh)."
echo ""
echo -e "${CYAN}Happy hacking!${NC}"

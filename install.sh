#!/usr/bin/env bash
# install.sh — Gestor de dotfiles con GNU Stow
# Uso: ./install.sh [--all] [--dry-run] [módulo1 módulo2 ...]
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
log()  { echo -e "${GREEN}[✔]${NC} $1"; }
info() { echo -e "${BLUE}[→]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✘]${NC} $1" >&2; exit 1; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}"
BACKUP_DIR="${HOME}/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
MODULES_TO_INSTALL=()
INSTALL_ALL=false

# Autodetecta módulos: cualquier subdirectorio que no sea un directorio especial del repo
SKIP_DIRS=("scripts" ".git")
AVAILABLE_MODULES=()
for d in "$DOTFILES_DIR"/*/; do
    [[ ! -d "$d" ]] && continue
    module="$(basename "$d")"
    skip=false
    for s in "${SKIP_DIRS[@]}"; do [[ "$module" == "$s" ]] && skip=true && break; done
    $skip || AVAILABLE_MODULES+=("$module")
done

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)      INSTALL_ALL=true ;;
        --dry-run)  DRY_RUN=true ;;
        --help|-h)
            echo "Uso: $0 [--all] [--dry-run] [módulo1 módulo2 ...]"
            echo "Módulos disponibles: ${AVAILABLE_MODULES[*]}"
            exit 0 ;;
        -*) err "Flag desconocido: $1" ;;
        *)  MODULES_TO_INSTALL+=("$1") ;;
    esac
    shift
done

$INSTALL_ALL && MODULES_TO_INSTALL=("${AVAILABLE_MODULES[@]}")

if [[ ${#MODULES_TO_INSTALL[@]} -eq 0 ]]; then
    echo "Módulos disponibles: ${AVAILABLE_MODULES[*]}"
    err "Especifica al menos un módulo o usa --all"
fi

command -v stow &>/dev/null || err "GNU Stow no está instalado: sudo apt-get install stow"

# Hace backup de un archivo si existe y no está ya gestionado por este repo
backup_if_needed() {
    local target="$1"
    [[ ! -e "$target" && ! -L "$target" ]] && return 0

    if [[ -L "$target" ]]; then
        local dest
        dest=$(readlink -f "$target" 2>/dev/null || true)
        [[ "$dest" == "$DOTFILES_DIR"/* ]] && return 0  # ya gestionado por stow
    fi

    if ! $DRY_RUN; then
        mkdir -p "$BACKUP_DIR"
        local rel="${target#"$HOME/"}"
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        mv "$target" "$BACKUP_DIR/$rel"
        warn "Backup: $target → $BACKUP_DIR/$rel"
    else
        warn "[DRY-RUN] Haría backup de: $target"
    fi
}

install_module() {
    local module="$1"
    local module_dir="$DOTFILES_DIR/$module"
    [[ -d "$module_dir" ]] || { warn "Módulo no encontrado: $module"; return 1; }
    info "Procesando módulo: $module"

    # Backup preventivo de todos los archivos que stow va a enlazar
    while IFS= read -r src; do
        local rel="${src#"$module_dir/"}"
        backup_if_needed "$TARGET_DIR/$rel"
    done < <(find "$module_dir" -type f -not -name '.gitignore')

    local stow_flags=(--dir="$DOTFILES_DIR" --target="$TARGET_DIR" --restow)
    if $DRY_RUN; then
        stow --simulate "${stow_flags[@]}" "$module" \
            && info "[DRY-RUN] OK: $module" \
            || warn "[DRY-RUN] Conflicto en módulo: $module"
    else
        stow "${stow_flags[@]}" "$module"
        log "Instalado: $module"
    fi
}

echo -e "\n${BOLD}dotfiles installer${NC} — target: $TARGET_DIR\n"
$DRY_RUN && warn "MODO DRY-RUN activo — no se realizarán cambios\n" || true

ok=0; fail=0
for module in "${MODULES_TO_INSTALL[@]}"; do
    if install_module "$module"; then
        ok=$((ok + 1))
    else
        fail=$((fail + 1))
    fi
done

echo ""
log "$ok módulo(s) instalado(s) correctamente"
[[ $fail -gt 0 ]] && warn "$fail módulo(s) con errores" || true
[[ -d "$BACKUP_DIR" ]] && info "Backups guardados en: $BACKUP_DIR" || true

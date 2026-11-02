#!/usr/bin/env bash
# install.sh — Gestor de dotfiles con GNU Stow
# Uso: ./install.sh [--all] [--dry-run] [--uninstall] [módulo1 módulo2 ...]
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
UNINSTALL=false

# Autodetecta módulos: cualquier subdirectorio que no sea un directorio especial del repo
SKIP_DIRS=(".git" ".github" ".omc")
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
        --uninstall) UNINSTALL=true ;;
        --help|-h)
            echo "Uso: $0 [--all] [--dry-run] [--uninstall] [módulo1 módulo2 ...]"
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

    # Ruta real, resolviendo también symlinks en directorios padre: stow "pliega"
    # carpetas enteras (~/.config/nvim -> repo), y mover un archivo de ahí
    # vaciaría el propio repo.
    local dest
    dest=$(readlink -f "$target" 2>/dev/null || true)
    [[ "$dest" == "$DOTFILES_DIR"/* ]] && return 0  # ya gestionado por stow

    if [[ -L "$target" ]]; then
        # Symlink hacia otra ubicación: se retira (no hay contenido propio que respaldar)
        if [[ "$dest" == */dotfiles/* ]]; then
            if $DRY_RUN; then warn "[DRY-RUN] Reemplazaría symlink: $target → $dest"
            else rm "$target"; warn "Symlink reemplazado: $target (apuntaba a $dest)"; fi
            return 0
        fi
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
    if ! $UNINSTALL; then
        while IFS= read -r src; do
            local rel="${src#"$module_dir/"}"
            backup_if_needed "$TARGET_DIR/$rel"
        done < <(find "$module_dir" -type f)
    fi

    local stow_flags=(--dir="$DOTFILES_DIR" --target="$TARGET_DIR" --restow)
    # ~/.claude guarda historial y credenciales: nunca debe plegarse a un symlink
    # hacia el repo, o Claude Code escribiría esos datos dentro del clon.
    [[ "$module" == "claude" ]] && stow_flags+=(--no-folding)
    if $UNINSTALL; then
        local un=(--dir="$DOTFILES_DIR" --target="$TARGET_DIR" --delete)
        $DRY_RUN && un+=(--simulate)
        stow "${un[@]}" "$module" && log "Desinstalado: $module" || return 1
        return 0
    fi
    if $DRY_RUN; then
        if stow --simulate "${stow_flags[@]}" "$module"; then
            info "[DRY-RUN] OK: $module"
        else
            warn "[DRY-RUN] Conflicto en módulo: $module"
        fi
    else
        if stow "${stow_flags[@]}" "$module"; then
            log "Instalado: $module"
        else
            warn "Stow falló en: $module"
            return 1
        fi
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

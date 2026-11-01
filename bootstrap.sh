#!/usr/bin/env bash
# bootstrap.sh — deja un Debian 13 recién instalado listo con un solo comando:
#
#   curl -fsSL https://raw.githubusercontent.com/sebastianabello/dotfiles/main/bootstrap.sh | bash
#
# Variables: DOTFILES_REPO (url del repo), DOTFILES_DIR (destino, por defecto ~/.dotfiles)
set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/sebastianabello/dotfiles.git}"
DEST="${DOTFILES_DIR:-$HOME/.dotfiles}"

echo "[→] Instalando git, curl y stow..."
sudo apt-get update -qq
sudo apt-get install -y git curl stow

if [[ -d "$DEST/.git" ]]; then
    echo "[→] Actualizando $DEST..."
    git -C "$DEST" pull --ff-only
else
    echo "[→] Clonando $REPO en $DEST..."
    git clone "$REPO" "$DEST"
fi

exec bash "$DEST/setup-debian13.sh"

# Dotfiles — Debian 13 Trixie

Configuración personal gestionada con **GNU Stow**. Cada herramienta vive en su propio módulo; un solo script crea todos los symlinks con backup automático.

Sistema base: **Debian 13 (Trixie)** · Arquitectura: `x86_64`

---

## Inicio rápido

```sh
# En una máquina nueva: clonar e instalar todo
git clone https://github.com/sebastianabello/dotfiles.git
cd dotfiles

# 1. Instalar todo el software del sistema
bash setup-debian13.sh

# 2. (O solo los dotfiles, si el software ya está instalado)
./install.sh --all
```

---

## Gestión de dotfiles con install.sh

```sh
./install.sh --all              # instalar todos los módulos
./install.sh zsh git starship   # instalar módulos específicos
./install.sh --dry-run --all    # previsualizar sin cambios
./install.sh --help             # ver módulos disponibles
```

- **Backup automático**: si el archivo de destino ya existe, se mueve a `~/.dotfiles-backup/YYYYMMDD_HHMMSS/` antes de crear el symlink.
- **Idempotente**: se puede ejecutar varias veces sin crear backups redundantes (detecta symlinks ya gestionados).
- **Motor**: [GNU Stow](https://www.gnu.org/software/stow/) — la estructura de cada módulo espeja la ruta relativa a `$HOME`.

---

## Estructura del repositorio

```
dotfiles/
├── install.sh                    ← orquestador de symlinks
├── setup-debian13.sh             ← instala todo el software del sistema
│
├── zsh/
│   ├── .zshrc                    → ~/.zshrc
│   └── .zshenv                   → ~/.zshenv
│
├── git/
│   └── .gitconfig                → ~/.gitconfig
│
├── starship/
│   └── .config/
│       └── starship.toml         → ~/.config/starship.toml
│
├── ghostty/
│   └── .config/
│       └── ghostty/
│           └── config            → ~/.config/ghostty/config
│
├── zellij/
│   └── .config/
│       └── zellij/
│           └── config.kdl        → ~/.config/zellij/config.kdl
│
├── lazygit/
│   └── .config/
│       └── lazygit/
│           └── config.yml        → ~/.config/lazygit/config.yml
│
├── btop/
│   └── .config/
│       └── btop/
│           └── btop.conf         → ~/.config/btop/btop.conf
│
├── glow/
│   └── .config/
│       └── glow/
│           └── glow.yml          → ~/.config/glow/glow.yml
│
└── gh/
    └── .config/
        └── gh/
            └── config.yml        → ~/.config/gh/config.yml
```

> `~/.config/gh/hosts.yml` (tokens OAuth) está excluido por `.gitignore`.

---

## Añadir un módulo nuevo

```sh
# Ejemplo: añadir configuración de neovim
mkdir -p dotfiles/neovim/.config/nvim
cp -r ~/.config/nvim/* dotfiles/neovim/.config/nvim/
./install.sh neovim
```

La estructura dentro del módulo debe esperar la ruta relativa a `$HOME`. Stow crea el symlink automáticamente.

---

## Software instalado por setup-debian13.sh

### Shell

| Herramienta | Función |
|---|---|
| `zsh` | Shell principal |
| `oh-my-zsh` | Framework de plugins |
| `zsh-autosuggestions` | Sugerencias por historial |
| `zsh-syntax-highlighting` | Coloreado en tiempo real |
| `zsh-completions` | Completado ampliado |
| `starship` | Prompt personalizado de dos líneas |
| `zellij` | Multiplexor de terminal (modo Ctrl+a) |

### Python

| Herramienta | Función |
|---|---|
| `uv` | Gestor moderno de paquetes y proyectos |
| `miniconda3` | Entorno `ai` con Python 3.12 + stack ML |

```sh
uv init mi-proyecto && cd mi-proyecto
uv add requests fastapi
uv run main.py

conda activate ai   # numpy, pandas, scikit-learn, matplotlib, jupyter
```

### Node.js

| Herramienta | Función |
|---|---|
| `fnm` | Gestor de versiones de Node |
| `pnpm` | Package manager principal |
| `bun` | Runtime y tooling moderno |

```sh
fnm install --lts && fnm default lts-latest
pnpm create vite mi-app
bun run script.ts
```

### Go

Instalado desde tarball oficial en `/usr/local/go`.

| Variable | Valor |
|---|---|
| `GOROOT` | `/usr/local/go` |
| `GOPATH` | `~/go` |

Herramientas: `gopls` · `dlv` · `golangci-lint`

### Rust

Instalado con `rustup`. Toolchains: `stable` · `beta` · `nightly`

Componentes: `clippy` · `rustfmt` · `rust-analyzer`

Cargo tools: `cargo-audit` · `cargo-outdated` · `cargo-watch` · `cargo-expand` · `cargo-nextest`

### Docker

Docker Engine + Compose v2 desde repositorio oficial.

```sh
docker compose up -d
docker compose logs -f
```

Stack de ejemplo en `~/docker-examples/webapp/compose.yml` (Node + PostgreSQL).

### CLI Stack

| Herramienta | Reemplaza | Función |
|---|---|---|
| `eza` | `ls` | Listado con iconos y colores |
| `fd` | `find` | Búsqueda rápida |
| `bat` | `cat` | Visualización con syntax highlighting |
| `rg` (ripgrep) | `grep` | Búsqueda en contenido |
| `fzf` | — | Fuzzy finder (`Ctrl+R`, `Ctrl+T`) |
| `zoxide` | `cd` | Navegación por historial |
| `yazi` | — | File manager TUI |
| `lazygit` | — | Git TUI (`lg`) |
| `lazydocker` | — | Docker TUI (`lzd`) |
| `delta` | — | Pager de diffs para git |
| `btop` | `top` | Monitor de recursos |
| `tldr` | `man` | Manual resumido con ejemplos |
| `glow` | — | Renderizado de Markdown en terminal |

### Nerd Fonts

Instaladas en `~/.local/share/fonts/`:

| Fuente | Uso |
|---|---|
| JetBrainsMono Nerd Font | Por defecto en Ghostty |
| FiraCode Nerd Font | Ligaduras de código |
| CascadiaCode Nerd Font | Alternativa moderna |

### Ghostty

Terminal instalada desde el repositorio unofficial de Dario Griffo (`debian.griffo.io`).

| Opción | Valor |
|---|---|
| Fuente | JetBrainsMono Nerd Font, tamaño 10 |
| Tema | catppuccin-mocha |
| Shell | `/usr/bin/zsh` |
| Cursor | bloque, sin parpadeo |
| Scrollback | 10 000 líneas |

---

## Aliases principales

| Alias | Comando |
|---|---|
| `ls` / `ll` / `lt` | `eza` con flags |
| `cat` | `bat --style=auto` |
| `find` | `fd` |
| `grep` | `rg` |
| `top` | `btop` |
| `g` | `git` |
| `lg` | `lazygit` |
| `d` / `dc` | `docker` / `docker compose` |
| `zj` | `zellij` |
| `py` | `python3` |
| `pip` / `venv` | `uv pip` / `uv venv` |
| `reload` | `source ~/.zshrc` |

## Funciones de shell

| Función | Uso |
|---|---|
| `mkcd <dir>` | Crea directorio y entra en él |
| `extract <archivo>` | Extrae cualquier formato comprimido |
| `fcd` | Navega a directorio con fzf |
| `gclone <url>` | Clona repo y entra en el directorio |

---

## PATH (orden de precedencia)

```
~/.local/share/fnm      ← fnm (Node versions)
~/.bun/bin              ← bun
~/.local/share/pnpm     ← pnpm
~/.cargo/bin            ← herramientas Rust
~/go/bin                ← herramientas Go
/usr/local/go/bin       ← compilador Go
~/.local/bin            ← uv, zoxide, tldr
```

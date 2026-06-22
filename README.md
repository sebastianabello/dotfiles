# Entorno de Desarrollo — Debian 13 Trixie

Sistema operativo base: **Debian 13 (Trixie)** · Arquitectura: `x86_64`

---

## Tabla de contenido

- [Sistema base](#sistema-base)
- [Shell](#shell)
- [Python](#python)
- [Node.js](#nodejs)
- [Go](#go)
- [Rust](#rust)
- [Docker](#docker)
- [CLI Stack](#cli-stack)
- [Nerd Fonts](#nerd-fonts)
- [Ghostty](#ghostty)
- [Aliases](#aliases)
- [Funciones de shell](#funciones-de-shell)
- [Archivos de configuración](#archivos-de-configuración)

---

## Sistema base

### Repositorios APT

Configurados en formato DEB822 (`/etc/apt/sources.list.d/0000debian.sources`):

| Suite | Componentes |
|---|---|
| `trixie` + `trixie-updates` | `main contrib non-free non-free-firmware` |
| `trixie-security` | `main contrib non-free non-free-firmware` |

### Paquetes base instalados

`build-essential` · `curl` · `wget` · `git` · `git-lfs` · `gnupg2` · `ca-certificates` · `lsb-release` · `apt-transport-https` · `unzip` · `zip` · `tar` · `xz-utils` · `jq` · `htop` · `man-db` · `tree` · `vim` · `neovim` · `stow` · `direnv` · `pkg-config` · `fontconfig`

Librerías de compilación: `libssl-dev` · `libffi-dev` · `zlib1g-dev` · `libbz2-dev` · `libreadline-dev` · `libsqlite3-dev` · `libncurses-dev` · `libxml2-dev` · `libxmlsec1-dev` · `liblzma-dev` · `tk-dev` · `llvm`

---

## Shell

### zsh

Shell principal. Configurado como shell por defecto del usuario.

### Oh My Zsh

Framework de configuración de zsh. Instalado en `~/.oh-my-zsh`.

**Plugins activos:**

| Plugin | Función |
|---|---|
| `git` | Aliases y funciones de git |
| `zsh-autosuggestions` | Sugerencias basadas en historial |
| `zsh-syntax-highlighting` | Coloreado de sintaxis en tiempo real |
| `zsh-completions` | Completado de comandos ampliado |
| `docker` | Completado de comandos Docker |
| `docker-compose` | Completado de Docker Compose |
| `sudo` | Doble `Esc` para añadir sudo al comando anterior |
| `direnv` | Carga `.envrc` al entrar en directorios |

### Starship

Prompt personalizado. Configurado en `~/.config/starship.toml`.

Formato de dos líneas:
```
╭─ usuario directorio rama-git contexto-lenguaje contexto-docker
╰─ ❯
```

Muestra automáticamente el contexto del lenguaje activo en el directorio (Python, Node, Go, Rust, etc.) y el contexto de Docker, Kubernetes, AWS, GCP y Azure cuando están activos.

### Zellij

Multiplexor de terminal. Configurado en `~/.config/zellij/config.kdl`.

| Opción | Valor |
|---|---|
| Shell | `zsh` |
| Tema | `catppuccin-mocha` |
| Mouse | activado |
| Copy on select | activado |
| Frames de paneles | desactivados |
| Atajo modo tmux | `Ctrl+a` |

---

## Python

### uv

Gestor moderno de paquetes y proyectos Python. Instalado en `~/.local/bin/`.

**Flujo de trabajo:**

```sh
uv init mi-proyecto        # crear proyecto nuevo
cd mi-proyecto
uv add requests fastapi    # añadir dependencias
uv run main.py             # ejecutar con entorno gestionado
uv sync                    # sincronizar entorno desde pyproject.toml
uv venv                    # crear virtualenv manualmente
```

> Los aliases `pip` y `venv` apuntan a `uv pip` y `uv venv`.

### Miniconda3

Instalado en `~/miniconda3`. No se activa automáticamente al abrir la terminal (`auto_activate_base = false`).

**Entorno `ai` preconfigurado** con Python 3.12:

| Paquete | Uso |
|---|---|
| `numpy` · `pandas` | Manipulación de datos |
| `scikit-learn` | Machine Learning |
| `matplotlib` · `seaborn` | Visualización |
| `jupyter` · `ipykernel` | Notebooks |

```sh
conda activate ai          # activar entorno
conda deactivate           # desactivar
conda env list             # listar entornos
```

---

## Node.js

### fnm (Fast Node Manager)

Gestor de versiones de Node.js. Instalado en `~/.local/share/fnm`.

```sh
fnm install --lts          # instalar LTS más reciente
fnm install 22             # instalar versión específica
fnm use 22                 # cambiar versión en la sesión actual
fnm default 22             # establecer versión por defecto
fnm list                   # listar versiones instaladas
```

El fichero `.node-version` o `.nvmrc` en un proyecto activa la versión automáticamente al entrar al directorio.

### pnpm

Package manager principal. Instalado como binario standalone en `~/.local/share/pnpm`.

```sh
pnpm create vite mi-app    # crear proyecto
pnpm add express           # añadir dependencia
pnpm add -D typescript     # añadir dev dependency
pnpm run dev               # ejecutar script
pnpm dlx cowsay            # ejecutar sin instalar (como npx)
```

### bun

Runtime y tooling moderno. Instalado en `~/.bun/bin`.

```sh
bun init                   # nuevo proyecto
bun run script.ts          # ejecutar TypeScript directamente
bun build ./src/index.ts   # bundling
bun x vite                 # usar paquete sin instalar
bun test                   # test runner integrado
```

---

## Go

Versión instalada desde tarball oficial en `/usr/local/go`.

| Variable | Valor |
|---|---|
| `GOROOT` | `/usr/local/go` |
| `GOPATH` | `~/go` |
| Binarios | `/usr/local/go/bin` y `~/go/bin` en `PATH` |

**Herramientas instaladas:**

| Herramienta | Uso |
|---|---|
| `gopls` | Language Server (LSP) para Go |
| `dlv` | Debugger Delve |
| `golangci-lint` | Linter agregado |

---

## Rust

Instalado con `rustup`. Toolchains disponibles:

| Toolchain | Uso |
|---|---|
| `stable` | Por defecto para proyectos |
| `beta` | Pruebas previas al release |
| `nightly` | Features experimentales |

**Componentes en stable:** `clippy` · `rustfmt` · `rust-analyzer`

**Herramientas de cargo instaladas:**

| Herramienta | Uso |
|---|---|
| `cargo-audit` | Auditoría de seguridad en dependencias |
| `cargo-outdated` | Detecta dependencias desactualizadas |
| `cargo-watch` | Rebuild automático al guardar (`cargo watch -x run`) |
| `cargo-expand` | Expande macros para debuggear |
| `cargo-nextest` | Test runner moderno, más rápido que `cargo test` |

```sh
rustup toolchain list                  # ver toolchains
rustup update                          # actualizar todo
cargo audit                            # auditar dependencias
cargo watch -x run                     # desarrollo con hot-reload
cargo nextest run                      # ejecutar tests
```

---

## Docker

### Docker Engine

Instalado desde el repositorio oficial de Docker (`download.docker.com`). El usuario está añadido al grupo `docker` (requiere re-login para activarse).

**Componentes instalados:** `docker-ce` · `docker-ce-cli` · `containerd.io` · `docker-buildx-plugin` · `docker-compose-plugin`

```sh
docker ps                  # contenedores activos
docker images              # imágenes locales
docker system prune -a     # limpiar todo lo sin uso
```

### Docker Compose v2

Disponible como plugin integrado (`docker compose`, no `docker-compose`).

```sh
docker compose up -d       # levantar stack en background
docker compose down        # detener y eliminar contenedores
docker compose logs -f     # seguir logs
docker compose ps          # estado de servicios
```

Ejemplo de stack Node + PostgreSQL disponible en `~/docker-examples/webapp/compose.yml`.

---

## CLI Stack

### Navegación y archivos

| Herramienta | Reemplaza a | Uso |
|---|---|---|
| `eza` | `ls` | Listado de archivos con iconos y colores |
| `fd` | `find` | Búsqueda de archivos rápida y ergonómica |
| `zoxide` | `cd` | Navegación inteligente con historial de directorios |
| `yazi` | — | File manager TUI (lanzar con `yazi`) |

### Búsqueda y lectura

| Herramienta | Reemplaza a | Uso |
|---|---|---|
| `bat` | `cat` | Visualización con syntax highlighting y numeración |
| `rg` (ripgrep) | `grep` | Búsqueda en contenido de archivos, ultra rápido |
| `fzf` | — | Fuzzy finder interactivo (`Ctrl+R` historial, `Ctrl+T` archivos) |
| `tldr` (tealdeer) | `man` | Páginas de manual resumidas con ejemplos |
| `glow` | — | Renderizado de Markdown en terminal |

### Git

| Herramienta | Uso |
|---|---|
| `lazygit` | TUI completo para Git (lanzar con `lg`) |
| `delta` | Pager de diffs con syntax highlighting y vista side-by-side |

### Docker / Sistema

| Herramienta | Uso |
|---|---|
| `lazydocker` | TUI completo para Docker (lanzar con `lzd`) |
| `btop` | Monitor de recursos moderno (reemplaza `top`/`htop`) |

### Configuración de git con delta

| Opción | Valor |
|---|---|
| Pager | `delta` |
| Vista | side-by-side |
| Numeración de líneas | activada |
| Tema de syntax | Dracula |
| Merge conflict style | `diff3` |
| `pull.rebase` | `true` |
| `rerere.enabled` | `true` |
| `push.autoSetupRemote` | `true` |
| `rebase.autoStash` | `true` |
| Rama por defecto | `main` |

---

## Nerd Fonts

Instaladas en `~/.local/share/fonts/`. Caché generada con `fc-cache`.

| Fuente | Característica |
|---|---|
| **JetBrainsMono Nerd Font** | Legibilidad para código, usada por defecto en Ghostty |
| **FiraCode Nerd Font** | Ligaduras de código (`->`, `=>`, `===`, `!==`) |
| **CascadiaCode Nerd Font** | Ligaduras modernas, fuente oficial de VS Code |

Verificar fuentes instaladas:
```sh
fc-list | grep -i NerdFont | awk -F: '{print $2}' | sort -u
```

---

## Ghostty

Terminal instalada desde el repositorio unofficial de Dario Griffo (`debian.griffo.io`), que soporta Debian Trixie.

Configuración en `~/.config/ghostty/config`:

| Opción | Valor |
|---|---|
| Fuente | JetBrainsMono Nerd Font, tamaño 14 |
| Ligaduras | `calt` + `liga` activadas |
| Tema | `catppuccin-mocha` |
| Shell | `/usr/bin/zsh` |
| Cursor | bloque, sin parpadeo |
| Shell integration | `zsh` (OSC 133, título dinámico) |
| Copy on select | activado (clipboard) |
| Scrollback | 10 000 líneas |
| Decoraciones | ninguna (`window-decoration = none`) |

**Atajos de teclado:**

| Atajo | Acción |
|---|---|
| `Ctrl+Shift+C` | Copiar |
| `Ctrl+Shift+V` | Pegar |
| `Ctrl+Shift+T` | Nueva pestaña |
| `Ctrl+Shift+W` | Cerrar panel |
| `Ctrl+Shift++` | Aumentar fuente |
| `Ctrl+Shift+-` | Reducir fuente |
| `Ctrl+Shift+0` | Resetear fuente |

---

## Aliases

### Navegación

| Alias | Comando real |
|---|---|
| `ls` | `eza --icons --group-directories-first` |
| `ll` | `eza -lah --icons --git --group-directories-first` |
| `lt` | `eza --tree --icons --level=2` |
| `lta` | `eza --tree --icons --level=3 -a` |
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |

### Búsqueda y lectura

| Alias | Comando real |
|---|---|
| `cat` | `bat --style=auto` |
| `find` | `fd` |
| `grep` | `rg` |
| `top` | `btop` |
| `tldr` | `tldr --color always` |

### Git

| Alias | Comando real |
|---|---|
| `g` | `git` |
| `lg` | `lazygit` |
| `gst` | `git status` |
| `glog` | `git log --oneline --graph --decorate` |

### Docker

| Alias | Comando real |
|---|---|
| `d` | `docker` |
| `dc` | `docker compose` |
| `lzd` | `lazydocker` |

### Python

| Alias | Comando real |
|---|---|
| `py` | `python3` |
| `venv` | `uv venv` |
| `pip` | `uv pip` |

### Productividad

| Alias | Comando real |
|---|---|
| `zj` | `zellij` |
| `cls` | `clear` |
| `path` | `echo $PATH \| tr ":" "\n"` |
| `reload` | `source ~/.zshrc` |

---

## Funciones de shell

### `mkcd <dir>`
Crea un directorio y entra en él de una sola vez.
```sh
mkcd proyecto/src/components
```

### `extract <archivo>`
Extrae cualquier formato comprimido sin recordar los flags.
```sh
extract archivo.tar.gz
extract datos.zip
extract backup.tar.bz2
```
Soporta: `.tar.gz` · `.tar.bz2` · `.tar.xz` · `.tar` · `.gz` · `.bz2` · `.zip` · `.7z`

### `fcd`
Abre `fzf` para navegar a cualquier directorio del sistema de forma interactiva.
```sh
fcd
```

### `gclone <url>`
Clona un repositorio git y entra automáticamente en el directorio clonado.
```sh
gclone https://github.com/usuario/repo
```

---

## Archivos de configuración

| Archivo | Contenido |
|---|---|
| `~/.zshrc` | Configuración principal del shell |
| `~/.config/starship.toml` | Prompt Starship |
| `~/.config/zellij/config.kdl` | Configuración de Zellij |
| `~/.config/ghostty/config` | Configuración de Ghostty |
| `~/.gitconfig` | Configuración global de git (delta, opciones) |
| `~/miniconda3/` | Instalación de Miniconda |
| `~/docker-examples/webapp/compose.yml` | Ejemplo de stack Docker Compose |

### Rutas en PATH (orden de precedencia)

```
~/.local/share/fnm      ← fnm (Node versions)
~/.bun/bin              ← bun
~/.local/share/pnpm     ← pnpm
~/.cargo/bin            ← herramientas Rust
~/go/bin                ← herramientas Go
/usr/local/go/bin       ← compilador Go
~/.local/bin            ← uv, zoxide, tldr
/usr/local/bin          ← herramientas instaladas manualmente
```

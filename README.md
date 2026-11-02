# Dotfiles — Debian 13 Trixie

Configuración personal gestionada con **GNU Stow**. Cada herramienta vive en su propio módulo; un script crea los symlinks con backup automático y otro instala todo el software.

Sistema base: **Debian 13 (Trixie)** · Arquitecturas: `x86_64` y `arm64`

---

## Inicio rápido

### Máquina nueva (un solo comando)

```sh
curl -fsSL https://raw.githubusercontent.com/sebastianabello/dotfiles/main/bootstrap.sh | bash
```

Instala `git`, `curl` y `stow`, clona el repo en `~/.dotfiles` y ejecuta `setup-debian13.sh` (software + dotfiles + Neovim).

### Con el repo ya clonado

```sh
make setup          # software + dotfiles + Neovim  (= bash setup-debian13.sh)
make install        # solo los dotfiles             (= ./install.sh --all)
make help           # todas las tareas
```

`setup-debian13.sh` es **idempotente**: se puede repetir y omite lo ya instalado.

### Pasos manuales tras instalar

1. Cerrar sesión y volver a entrar (grupo `docker` y zsh como shell).
2. `gh auth login` y `gh auth setup-git` (credenciales de GitHub).
3. Abrir una terminal nueva (o `exec zsh`).

---

## install.sh

```sh
./install.sh --all                # instalar todos los módulos
./install.sh zsh git nvim         # módulos concretos
./install.sh --dry-run --all      # simular sin cambios
./install.sh --all --uninstall    # quitar los symlinks (stow -D)
./install.sh --help               # módulos disponibles
```

- **Backup automático**: un archivo real existente se mueve a `~/.dotfiles-backup/YYYYMMDD_HHMMSS/`. Los symlinks que apuntan a otro clon de este repo se reemplazan directamente.
- **Errores aislados**: si un módulo falla, se informa y se continúa con los demás.
- **Motor**: [GNU Stow](https://www.gnu.org/software/stow/); cada módulo espeja la ruta relativa a `$HOME`.

> Nota: `--dry-run` puede avisar de conflictos que desaparecen en la instalación real (la simulación no retira los symlinks viejos).

---

## Estructura

```
dotfiles/
├── bootstrap.sh            ← instalación en una máquina nueva
├── setup-debian13.sh       ← instala todo el software
├── install.sh              ← enlaza los dotfiles (stow)
├── Makefile                ← atajos: install, setup, lint, nvim-sync...
├── .github/workflows/      ← CI: shellcheck, zsh -n, stylua
│
├── zsh/        .zshrc  .zshenv
├── git/        .gitconfig
├── nvim/       .config/nvim/  (Lua + lazy.nvim)
├── starship/   .config/starship.toml
├── alacritty/  .config/alacritty/alacritty.toml
├── claude/     .claude/{settings.json, CLAUDE.md, statusline.js}
├── zellij/     .config/zellij/{config.kdl, layouts/dev.kdl}
├── lazygit/    .config/lazygit/config.yml
├── btop/       .config/btop/btop.conf
├── glow/       .config/glow/glow.yml
└── gh/         .config/gh/config.yml
```

> `~/.config/gh/hosts.yml` (tokens OAuth) está excluido por `.gitignore`.
> `claude/` versiona `settings.json`, `CLAUDE.md` y la statusline; credenciales, historial y plugins de `~/.claude/` quedan fuera (stow enlaza archivos sueltos, no la carpeta).
> Configuración propia de cada máquina (sin versionar): `~/.zshrc.local`.

### Añadir un módulo

```sh
mkdir -p mimodulo/.config/mimodulo
cp ~/.config/mimodulo/* mimodulo/.config/mimodulo/
./install.sh mimodulo
```

---

## Neovim (Lua)

Configuración modular con [lazy.nvim](https://github.com/folke/lazy.nvim), que se instala solo en el primer arranque. Requiere Neovim ≥ 0.11 (el script lo instala si hace falta).

```
nvim/.config/nvim/
├── init.lua
├── lazy-lock.json                  ← versiones fijadas de los plugins
└── lua/
    ├── config/   options · keymaps · autocmds · lazy
    └── plugins/  colorscheme · treesitter · lsp · completion · format
                  telescope · ui · git
```

| Área | Plugin |
|---|---|
| Tema | catppuccin (mocha) |
| LSP | mason + nvim-lspconfig (`lua_ls`, `bashls`, `pyright`, `ts_ls`, `jsonls`) |
| Completado | blink.cmp |
| Formato | conform (stylua, shfmt, prettier, ruff) al guardar |
| Sintaxis | nvim-treesitter (rama `main`) |
| Búsqueda | telescope + fzf-native |
| UI | lualine · which-key · neo-tree · gitsigns |

Teclas (líder = `Espacio`): `<leader>ff` archivos · `<leader>fg` texto · `<leader>e` explorador · `gd` definición · `<leader>ca` acciones · `<leader>rn` renombrar · `gc` comentar.

Instalación desatendida: `make nvim-sync`.

---

## Shell

- **PATH sin duplicados** (`typeset -U`), orden: `~/.local/bin` › `~/.cargo/bin` › Go › bun › pnpm › fnm.
- **fzf**: `Ctrl+R` historial · `Ctrl+T` archivos · `Alt+C` directorios.
- **conda** con carga diferida (no ralentiza el arranque).
- Cada herramienta se activa solo si está instalada.

### Aliases

| Alias | Comando |
|---|---|
| `ls` `ll` `lt` | `eza` con iconos |
| `cat` | `bat --paging=never` |
| `ff` · `rgi` | `fd` · `rg -i` |
| `v` | `nvim` |
| `g` `lg` `lzd` | `git` · `lazygit` · `lazydocker` |
| `d` `dc` | `docker` · `docker compose` |
| `zj` | `zellij` |
| `py` `venv` `uvp` | `python3` · `uv venv` · `uv pip` |
| `gs` · `cm` · `cma` | `git status -sb` · commit con mensaje sin comillas · add -A + commit |
| `nd` `nb` `ns` `ni` `nt` | `npm run dev` · `build` · `start` · `install` · `test` |
| `reload` | `exec zsh` |

`find`, `grep` y `pip` **no** están aliasados, para no romper scripts POSIX.

### Funciones

`mkcd <dir>` · `extract <archivo>` · `fcd` (cd con fzf) · `gclone <url>`

---

## Claude Code

`claude/.claude/statusline.js` (adaptada de [fazt/dotfiles](https://github.com/fazt/dotfiles), con paleta Catppuccin) dibuja usuario, ruta, rama git (`✗` si hay cambios), modelo y barras de contexto y de cuota 5h/7d. Necesita `node` (lo instala fnm).

## Terminal y multiplexor

- **Alacritty**: tema Catppuccin Mocha, JetBrainsMono Nerd Font 12, cursor bloque (sin pestañas ni splits: de eso se encarga Zellij).
- **Zellij**: prefijo `Ctrl b` (modo tmux), `Ctrl g` bloquea. Layout por defecto `dev` (editor + terminal + lazygit).

---

## Software instalado por setup-debian13.sh

| Categoría | Herramientas |
|---|---|
| Shell | zsh, oh-my-zsh (+autosuggestions, syntax-highlighting, completions), starship, zellij |
| Editores | Neovim, Visual Studio Code |
| Python | uv, miniconda3 (entorno `ai`, Python 3.12 + stack ML) |
| Node.js | fnm (LTS), pnpm, bun |
| Go | última versión oficial en `/usr/local/go` + gopls, dlv, golangci-lint |
| Rust | rustup (stable/beta/nightly), clippy, rustfmt, rust-analyzer, cargo-audit/outdated/watch/expand/nextest |
| Docker | Engine + Compose v2 (repo oficial) |
| CLI | eza, fd, bat, ripgrep, fzf, zoxide, yazi, lazygit, lazydocker, delta, btop, tldr, glow |
| Fuentes | JetBrainsMono, FiraCode, CascadiaCode (Nerd Fonts) |
| Apps | Alacritty, Brave |

Variables útiles: `GO_VERSION=1.xx.x` fija la versión de Go; `SKIP_CARGO_TOOLS=1` omite la compilación de herramientas cargo.

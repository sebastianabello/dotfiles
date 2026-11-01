.PHONY: help install uninstall dry-run setup lint nvim-sync

help:       ## Muestra esta ayuda
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'

install:    ## Enlaza todos los dotfiles con stow
	./install.sh --all

uninstall:  ## Quita los enlaces de stow
	./install.sh --all --uninstall

dry-run:    ## Simula la instalación sin cambiar nada
	./install.sh --all --dry-run

setup:      ## Instala todo el software (Debian 13) y los dotfiles
	bash setup-debian13.sh

nvim-sync:  ## Sincroniza plugins, LSP y parsers de Neovim
	nvim --headless "+Lazy! sync" +qa
	nvim --headless "+MasonToolsInstallSync" +qa
	nvim --headless "+TSInstallAll" +qa

lint:       ## shellcheck + comprobación de sintaxis de zsh
	shellcheck install.sh setup-debian13.sh bootstrap.sh
	zsh -n zsh/.zshrc zsh/.zshenv

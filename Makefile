MODE ?= install
DRY ?= no
LINK_CONFIGS = bash_profile bashrc inputrc_linux inputrc_macos fontconfig \
               looking-glass-client mpv neofetch qutebrowser bspwm sxhkd \
               polybar yabai skhd ubersicht tmux vim
COPY_CONFIGS = dolphin gwenview konsole

.PHONY: $(LINK_CONFIGS) $(COPY_CONFIGS)

DOTFILES_DIR ?= ${PWD}
HOME_DIR ?= ${HOME}
CONFIG_DIR ?= $(HOME_DIR)/.config

.DEFAULT:;
all:;

$(LINK_CONFIGS):
ifeq ($(MODE),install)
ifeq ($(DRY),yes)
	@printf "[dry] '%s' -> '%s'\\n" "$(strip $(subst $<,,$^))" "$<"
else
	@if [ ! -e "$(CONFIG_DIR)" ]; then \
		mkdir "$(CONFIG_DIR)"; \
	fi
	@if [ -L "$(strip $(subst $<,,$^))" ]; then \
		rm -f "$(strip $(subst $<,,$^))"; \
	fi
	@ln -svf "$<" "$(strip $(subst $<,,$^))"
endif # ifeq ($(DRY),yes)
endif # ifeq ($(MODE),install)
ifeq ($(MODE),uninstall)
ifeq ($(DRY),yes)
	@printf "[dry] removed '%s'\\n" "$(strip $(subst $<,,$^))"
else
	@if [ -L "$(strip $(subst $<,,$^))" ]; then \
		rm -fv "$(strip $(subst $<,,$^))"; \
	fi
endif # ifeq ($(DRY),yes)
endif # ifeq ($(MODE),uninstall)
ifneq ($(MODE),uninstall)
ifneq ($(MODE),install)
	@printf "%s: unknown mode: %s\\n" "$@" "$(MODE)"
	@exit 1
endif # ifneq ($(MODE),install)
endif # ifneq ($(MODE),uninstall)


$(COPY_CONFIGS):
ifeq ($(MODE),install)
ifeq ($(DRY),yes)
	@printf "[dry] '%s' -> '%s'\\n" "$(strip $(subst $<,,$^))" "$<"
else
	@if [ ! -e "$(CONFIG_DIR)" ]; then \
		mkdir "$(CONFIG_DIR)"; \
	fi
	@if [ -e "$(strip $(subst $<,,$^))" ]; then \
		rm -f "$(strip $(subst $<,,$^))"; \
	fi
	@cp -v "$<" "$(strip $(subst $<,,$^))"
endif # ifeq ($(DRY),yes)
endif # ifeq ($(MODE),install)
ifeq ($(MODE),uninstall)
ifeq ($(DRY),yes)
	@printf "[dry] removed '%s'\\n" "$(strip $(subst $<,,$^))"
else
	@if [ -e "$(strip $(subst $<,,$^))" ]; then \
		rm -fv "$(strip $(subst $<,,$^))"; \
	fi
endif # ifeq ($(DRY),yes)
endif # ifeq ($(MODE),uninstall)
ifneq ($(MODE),uninstall)
ifneq ($(MODE),install)
	@printf "%s: unknown mode: %s\\n" "$@" "$(MODE)"
	@exit 1
endif # ifneq ($(MODE),install)
endif # ifneq ($(MODE),uninstall)

# format:
# application-config: \
#     source-file \
#     destination-file


### LINK_CONFIGS

# Bash configuration files is os dependant.
# It also includes .bash_profile, .bashrc and .inputrc
bash_linux: bash inputrc_linux
bash_macos: bash inputrc_macos
bash: bash_profile bashrc

bash_profile: \
    $(DOTFILES_DIR)/bashrc/bash_profile \
    $(HOME_DIR)/.bash_profile

bashrc: \
    $(DOTFILES_DIR)/bashrc/bashrc \
    $(HOME_DIR)/.bashrc

inputrc_linux: \
    $(DOTFILES_DIR)/bashrc/inputrc_linux \
    $(HOME_DIR)/.inputrc

inputrc_macos: \
    $(DOTFILES_DIR)/bashrc/inputrc_macos \
    $(HOME_DIR)/.inputrc

fontconfig: \
    $(DOTFILES_DIR)/fontconfig \
    $(CONFIG_DIR)/fontconfig

looking-glass-client: \
    $(DOTFILES_DIR)/looking-glass-client/looking-glass-client.ini \
    $(HOME_DIR)/.looking-glass-client.ini

mpv: \
    $(DOTFILES_DIR)/mpv \
    $(CONFIG_DIR)/mpv

neofetch: \
    $(DOTFILES_DIR)/neofetch \
    $(CONFIG_DIR)/neofetch

qutebrowser: \
    $(DOTFILES_DIR)/qutebrowser \
    $(CONFIG_DIR)/qutebrowser

bspwm: \
    $(DOTFILES_DIR)/bspwm \
    $(CONFIG_DIR)/bspwm

sxhkd: \
    $(DOTFILES_DIR)/sxhkd \
    $(CONFIG_DIR)/sxhkd

polybar: \
    $(DOTFILES_DIR)/polybar \
    $(CONFIG_DIR)/polybar

yabai: \
    $(DOTFILES_DIR)/yabai/yabairc \
    $(HOME_DIR)/.yabairc

skhd: \
    $(DOTFILES_DIR)/skhd/skhdrc \
    $(HOME_DIR)/.skhdrc

ubersicht: \
    $(DOTFILES_DIR)/ubersicht \
    $(HOME_DIR)/Library/Application\ Support/Übersicht/widgets

tmux: \
    $(DOTFILES_DIR)/tmux/tmux.conf \
    $(HOME_DIR)/.tmux.conf

vim: \
    $(DOTFILES_DIR)/vimrc \
    $(HOME_DIR)/.vim


### COPY_CONFIGS

dolphin: \
    $(DOTFILES_DIR)/plasma/dolphin/dolphinrc \
    $(CONFIG_DIR)/dolphinrc

gwenview: \
    $(DOTFILES_DIR)/plasma/gwenview/gwenviewrc \
    $(CONFIG_DIR)/gwenviewrc

konsole: \
    $(DOTFILES_DIR)/plasma/konsole/konsolerc \
    $(CONFIG_DIR)/konsolerc

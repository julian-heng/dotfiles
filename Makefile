MODE ?= install
DRY ?= no
LINK_CONFIGS = bash_profile bashrc inputrc_linux inputrc_macos \
               looking-glass-client mpv neofetch qutebrowser bspwm sxhkd \
               systemd-wallpaper-service systemd-wallpaper-timer polybar \
               yabai skhd ubersicht tmux vim
COPY_CONFIGS = bashrc_custom dolphin fontconfig gwenview htop konsole

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
		rm -rf "$(strip $(subst $<,,$^))"; \
	fi
	@ln -svf "$<" "$(strip $(subst $<,,$^))"
endif # ifeq ($(DRY),yes)
endif # ifeq ($(MODE),install)
ifeq ($(MODE),uninstall)
ifeq ($(DRY),yes)
	@printf "[dry] removed '%s'\\n" "$(strip $(subst $<,,$^))"
else
	@if [ -L "$(strip $(subst $<,,$^))" ]; then \
		rm -rfv "$(strip $(subst $<,,$^))"; \
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
		rm -rf "$(strip $(subst $<,,$^))"; \
	fi
	@cp -r -v "$<" "$(strip $(subst $<,,$^))"
endif # ifeq ($(DRY),yes)
endif # ifeq ($(MODE),install)
ifeq ($(MODE),uninstall)
ifeq ($(DRY),yes)
	@printf "[dry] removed '%s'\\n" "$(strip $(subst $<,,$^))"
else
	@if [ -e "$(strip $(subst $<,,$^))" ]; then \
		rm -rfv "$(strip $(subst $<,,$^))"; \
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

# Systemd services and timers requires linking multiple files
systemd-wallpaper: systemd-wallpaper-service systemd-wallpaper-timer

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

systemd-wallpaper-service: \
    $(DOTFILES_DIR)/systemd/wallpaper.service \
    $(CONFIG_DIR)/systemd/user/wallpaper.service

systemd-wallpaper-timer: \
    $(DOTFILES_DIR)/systemd/wallpaper.timer \
    $(CONFIG_DIR)/systemd/user/wallpaper.timer

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

bashrc_custom:\
    $(DOTFILES_DIR)/bashrc/bashrc_custom \
    $(HOME_DIR)/.bashrc_custom

dolphin: \
    $(DOTFILES_DIR)/plasma/dolphin/dolphinrc \
    $(CONFIG_DIR)/dolphinrc

fontconfig: \
    $(DOTFILES_DIR)/fontconfig \
    $(CONFIG_DIR)/fontconfig

gwenview: \
    $(DOTFILES_DIR)/plasma/gwenview/gwenviewrc \
    $(CONFIG_DIR)/gwenviewrc

htop: \
    $(DOTFILES_DIR)/htop \
	$(CONFIG_DIR)/htop

konsole: \
    $(DOTFILES_DIR)/plasma/konsole/konsolerc \
    $(CONFIG_DIR)/konsolerc

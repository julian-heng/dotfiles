MODE ?= install
DRY ?= no
LINK_CONFIGS = \
    bash_profile \
    bashrc \
    inputrc_linux \
    inputrc_macos \
    looking-glass-client \
    mpv \
    neofetch \
    picom \
    qutebrowser \
    bspwm \
    sxhkd \
    systemd-wallpaper-service \
    systemd-wallpaper-timer \
    polybar \
    yabai \
    skhd \
    ubersicht \
    tmux \
    vim

COPY_CONFIGS = \
    bashrc_custom \
    dolphin \
    fontconfig \
    gwenview \
    htop \
    konsole

.PHONY: $(LINK_CONFIGS) $(COPY_CONFIGS)

DOTFILES_DIR ?= ${PWD}
HOME_DIR ?= ${HOME}
CONFIG_DIR ?= $(HOME_DIR)/.config

.DEFAULT:;
all:;

$(LINK_CONFIGS):
	$(eval $@_DEST := $(strip $(subst $<,,$^)))
	$(eval $@_BASEDIR := $(shell dirname "$($@_DEST)"))
ifeq ($(MODE),install)
ifeq ($(DRY),yes)
	@printf "[dry] '%s' -> '%s'\\n" "$($@_DEST)" "$<"
else
	@# Remove previous link if it exists
	@if [ -L "$($@_DEST)" ]; then \
		rm -f "$($@_DEST)"; \
	fi

	@# Create parent directory if it does not exist
	@mkdir -p "$($@_BASEDIR)"

	@# Link the source to the destination
	@ln -svf "$<" "$($@_DEST)"
endif # ifeq ($(DRY),yes)
endif # ifeq ($(MODE),install)
ifeq ($(MODE),uninstall)
ifeq ($(DRY),yes)
	@printf "[dry] removed '%s'\\n" "$($@_DEST)"
else
	@if [ -L "$($@_DEST)" ]; then \
		rm -rfv "$($@_DEST)"; \
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
	$(eval $@_DEST := $(strip $(subst $<,,$^)))
	$(eval $@_BASEDIR := $(shell dirname "$($@_DEST)"))
ifeq ($(MODE),install)
ifeq ($(DRY),yes)
	@printf "[dry] '%s' -> '%s'\\n" "$<" "$($@_DEST)"
else
	@# If source is a file, destination should also be a file
	@# If destination is a directory, the source file will be copied into the
	@# destination directory. Exit if that's the case
	@if [ -e "$($@_DEST)" ] && [ -d "$($@_DEST)" ] && [ -f "$<" ]; then \
		printf "Source '%s' is a file. " "$<"; \
		printf "Target '%s' is a directory. " "$($@_DEST)"; \
		printf "Copying to this directory breaks the path.\\n" "$($@_DEST)"; \
		printf "Exiting...\\n"; \
		exit 1; \
	fi

	@# Overwrite the destination directory if the source is a directory
	@if [ -e "$($@_DEST)" ] && [ -d "$<" ]; then \
		rm -rf "$($@_DEST)"; \
	fi

	@# Create parent directory if it does not exist
	@mkdir -p "$($@_BASEDIR)"

	@# Copy the source to the destination
	@cp -r -v "$<" "$($@_DEST)"
endif # ifeq ($(DRY),yes)
endif # ifeq ($(MODE),install)
ifeq ($(MODE),uninstall)
ifeq ($(DRY),yes)
	@printf "[dry] removed '%s'\\n" "$($@_DEST)"
else
	@if [ -e "$($@_DEST)" ]; then \
		rm -rfv "$($@_DEST)"; \
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
    $(HOME_DIR)/.mpv

neofetch: \
    $(DOTFILES_DIR)/neofetch \
    $(CONFIG_DIR)/neofetch

picom: \
    $(DOTFILES_DIR)/picom \
    $(CONFIG_DIR)/picom

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
    $(HOME_DIR)/Library/Application\ Support/Übersicht/widgets/dotfiles-bar

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

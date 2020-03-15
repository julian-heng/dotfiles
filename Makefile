# Default mode is install
MODE ?= install

# Source and destination
SCRIPT_DIR := ${PWD}
CONFIG_DIR := ${HOME}/.config

BASHRC_DIR := $(SCRIPT_DIR)/bashrc
BASHRC_DEST := ${HOME}

BSPWM_DIR := $(SCRIPT_DIR)/bspwm
BSPWM_DEST := $(CONFIG_DIR)/bspwm

MPV_DIR := $(SCRIPT_DIR)/mpv
MPV_DEST := $(CONFIG_DIR)/mpv

NEOFETCH_DIR := $(SCRIPT_DIR)/neofetch
NEOFETCH_DEST := $(CONFIG_DIR)/neofetch

POLYBAR_DIR := $(SCRIPT_DIR)/polybar
POLYBAR_DEST := $(CONFIG_DIR)/polybar

QUTEBROWSER_DIR := $(SCRIPT_DIR)/qutebrowser
QUTEBROWSER_DEST := $(CONFIG_DIR)/qutebrowser

SKHD_FILE := $(SCRIPT_DIR)/skhd/skhdrc
SKHD_DEST := ${HOME}/.skhdrc

SXHKD_DIR := $(SCRIPT_DIR)/sxhkd
SXHKD_DEST := $(CONFIG_DIR)/sxhkd

TMUX_DIR := $(SCRIPT_DIR)/tmux/tmux.conf
TMUX_DEST := ${HOME}/.tmux.conf

UBERSICHT_DIR := $(SCRIPT_DIR)/ubersicht
UBERSICHT_DEST := ${HOME}/Library/Application\ Support/Übersicht/widgets

VIM_DIR := $(SCRIPT_DIR)/vimrc
VIM_DEST := ${HOME}/.vim

YABAI_FILE := $(SCRIPT_DIR)/yabai/yabairc
YABAI_DEST := ${HOME}/.yabairc

# Make config dir if it does not exist
$(shell mkdir -p $(CONFIG_DIR))

# Functions
define link
	@if [ "$(MODE)" = "install" ]; then \
		$(call remove_link,$(2),); \
		ln -svf $(1) $(2); \
	elif [ "$(MODE)" = "uninstall" ]; then \
		$(call remove_link,$(2),-v); \
	else \
		printf "Unknown mode: %s\n" "$(MODE)"; \
	fi
endef


define remove_link
	if [ -L $(1) ]; then \
		rm -f $(2) $(1); \
	fi
endef

# Submodule aliases
submodule_init:
	@git submodule update --init --recursive

submodule_update:
	@git submodule update --remote --recursive

# Make links
bashrc_linux: bashrc_common
	$(call link,$(BASHRC_DIR)/inputrc_linux,$(BASHRC_DEST)/.inputrc)

bashrc_macos: bashrc_common
	$(call link,$(BASHRC_DIR)/inputrc_macos,$(BASHRC_DEST)/.inputrc)

bashrc_common:
	$(call link,$(BASHRC_DIR)/bash_profile,$(BASHRC_DEST)/.bash_profile)
	$(call link,$(BASHRC_DIR)/bashrc,$(BASHRC_DEST)/.bashrc)

mpv:
	$(call link,$(MPV_DIR),$(MPV_DEST))

neofetch:
	$(call link,$(NEOFETCH_DIR),$(NEOFETCH_DEST))

qutebrowser:
	$(call link,$(QUTEBROWSER_DIR),$(QUTEBROWSER_DEST))

bspwm:
	$(call link,$(BSPWM_DIR),$(BSPWM_DEST))

sxhkd:
	$(call link,$(SXHKD_DIR),$(SXHKD_DEST))

polybar:
	$(call link,$(POLYBAR_DIR),$(POLYBAR_DEST))

yabai:
	$(call link,$(YABAI_FILE),$(YABAI_DEST))

skhd:
	$(call link,$(SKHD_FILE),$(SKHD_DEST))

ubersicht:
	$(call link,$(UBERSICHT_DIR),$(UBERSICHT_DEST))

tmux:
	$(call link,$(TMUX_DIR),$(TMUX_DEST))

vim:
	$(call link,$(VIM_DIR),$(VIM_DEST))

.PHONY: submodule_init submodule_update bashrc_linux bashrc_macos \
        bashrc_common mpv neofetch qutebrowser bspwm sxhkd polybar yabai \
        skhd ubersicht tmux vim

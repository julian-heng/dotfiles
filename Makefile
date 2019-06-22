   #######################
######## Environment ########
   #######################

MODE ?= install

SCRIPT_DIR := ${PWD}
CONFIG_DIR := ${HOME}/.config
BASHRC_DIR := $(SCRIPT_DIR)/bashrc
COMPTON_DIR := $(SCRIPT_DIR)/compton
MPV_DIR := $(SCRIPT_DIR)/mpv
NEOFETCH_DIR := $(SCRIPT_DIR)/neofetch
RANGER_DIR := $(SCRIPT_DIR)/ranger
TMUX_DIR := $(SCRIPT_DIR)/tmux/tmux.conf
UBERSICHT_DIR := $(SCRIPT_DIR)/ubersicht
VIM_DIR := $(SCRIPT_DIR)/vimrc

YABAI_FILE := $(SCRIPT_DIR)/yabai/yabairc
SKHD_FILE := $(SCRIPT_DIR)/skhd/skhdrc

BASHRC_DEST := ${HOME}
COMPTON_DEST := $(CONFIG_DIR)/compton.conf
YABAI_DEST := ${HOME}/.yabairc
MPV_DEST := $(CONFIG_DIR)/mpv
NEOFETCH_DEST := $(CONFIG_DIR)/neofetch
RANGER_DEST := $(CONFIG_DIR)/ranger
SKHD_DEST := ${HOME}/.skhdrc
TMUX_DEST := ${HOME}/.tmux.conf
UBERSICHT_DEST := ${HOME}/Library/Application\ Support/Übersicht/widgets
VIM_DEST := ${HOME}/.vim

$(shell mkdir -p $(CONFIG_DIR))

   ####################
######## Functions ########
   ####################

define link
	@if [ "$(MODE)" = "install" ]; then \
		$(call remove_link,$(2),); \
		ln -svf $(1) $(2); \
	elif [ "$(MODE)" = "uninstall" ]; then \
		$(call remove_link,$(2),-v); \
	fi
endef


define remove_link
	if [ -L $(1) ]; then \
		rm -f $(2) $(1); \
	fi
endef

   ###############
######## Git ########
   ###############

submodule_init:
	@git submodule update --init --recursive

submodule_update:
	@git submodule update --remote --recursive

   ###################
######## Profiles ########
   ###################

linux_headless: bashrc_linux neofetch ranger tmux vim
linux_lite: bashrc_linux compton_noblur mpv neofetch ranger tmux vim
linux: bashrc_linux compton_blur mpv neofetch ranger tmux vim
mac: bashrc_macos mpv neofetch chunkwm skhd ranger tmux ubersicht vim
windows: bashrc_common neofetch

   ##################
######## Bashrc ########
   ##################

bashrc_linux: bashrc_common
	$(call link,$(BASHRC_DIR)/inputrc_linux,$(BASHRC_DEST)/.inputrc)

bashrc_macos: bashrc_common
	$(call link,$(BASHRC_DIR)/inputrc_macos,$(BASHRC_DEST)/.inputrc)

bashrc_common:
	$(call link,$(BASHRC_DIR)/bash_profile,$(BASHRC_DEST)/.bash_profile)
	$(call link,$(BASHRC_DIR)/bashrc,$(BASHRC_DEST)/.bashrc)

   ###################
######## Compton ########
   ###################

compton_blur:
	$(call link,$(COMPTON_DIR)/blur.conf,$(COMPTON_DEST))

compton_noblur:
	$(call link,$(COMPTON_DIR)/no-blur.conf,$(COMPTON_DEST))

   ###############
######## Mpv ########
   ###############

mpv:
	$(call link,$(MPV_DIR),$(MPV_DEST))

   ####################
######## Neofetch ########
   ####################

neofetch:
	$(call link,$(NEOFETCH_DIR),$(NEOFETCH_DEST))

   ##################
######## Ranger ########
   ##################

ranger:
	$(call link,$(RANGER_DIR),$(RANGER_DEST))

   #################
######## Yabai ########
   #################

yabai:
	$(call link,$(YABAI_FILE),$(YABAI_DEST))

   ################
######## Skhd ########
   ################

skhd:
	$(call link,$(SKHD_FILE),$(SKHD_DEST))

   ################
######## Tmux ########
   ################

tmux:
	$(call link,$(TMUX_DIR),$(TMUX_DEST))

   #####################
######## Ubersicht ########
   #####################

ubersicht:
	$(call link,$(UBERSICHT_DIR),$(UBERSICHT_DEST))

   ###############
######## Vim ########
   ###############

vim:
	$(call link,$(VIM_DIR),$(VIM_DEST))

.PHONY: submodule_init submodule_update linux_headless linux_lite linux mac \
		windows bashrc_linux bashrc_macos bashrc_common compton_blur \
		compton_noblur mpv neofetch ranger yabai skhd tmux ubersicht \
		vim

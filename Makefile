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
SKHD_DIR := $(SCRIPT_DIR)/skhd
TMUX_DIR := $(SCRIPT_DIR)/tmux/tmux.conf
VIM_DIR := $(SCRIPT_DIR)/vimrc

BASHRC_DEST := ${HOME}
COMPTON_DEST := $(CONFIG_DIR)/compton.conf
MPV_DEST := $(CONFIG_DIR)/mpv
NEOFETCH_DEST := $(CONFIG_DIR)/neofetch
RANGER_DEST := $(CONFIG_DIR)/ranger
SKHD_DEST := ${HOME}/.skhdrc
TMUX_DEST := ${HOME}/.tmux.conf
VIM_DEST := ${HOME}/.vim

   ###############
######## Git ########
   ###############

.PHONY: submodule_init
submodule_init:
	@git submodule update --init --recursive

.PHONY: submodule_update
submodule_update:
	@git submodule update --remote --recursive

   ###################
######## Profiles ########
   ###################

.PHONY: linux_headless
linux_headless: bashrc_linux neofetch ranger tmux vim

.PHONY: linux_lite
linux_lite: bashrc_linux compton_noblur mpv neofetch ranger tmux vim

.PHONY: linux
linux: bashrc_linux compton_blur mpv neofetch ranger tmux vim

.PHONY: mac
mac: bashrc_macos mpv neofetch skhd ranger tmux vim

.PHONY: windows
windows: bashrc_common neofetch

.PHONY: check_dir
check_dir:
	@if [ ! -e "$(CONFIG_DIR)" ]; then \
		mkdir "$(CONFIG_DIR)"; \
	fi

   ##################
######## Bashrc ########
   ##################

.PHONY: bashrc_linux
bashrc_linux: bashrc_common
	@if [ -L $(BASHRC_DEST)/.inputrc ]; then \
		rm -f $(BASHRC_DEST)/.inputrc; \
	fi
ifeq ($(MODE), install)
	@ln -svf $(BASHRC_DIR)/inputrc_linux $(BASHRC_DEST)/.inputrc
endif

.PHONY: bashrc_macos
bashrc_macos: bashrc_common
	@if [ -L $(BASHRC_DEST)/.inputrc ]; then \
		rm -f $(BASHRC_DEST)/.inputrc; \
	fi
ifeq ($(MODE), install)
	@ln -svf $(BASHRC_DIR)/inputrc_macos $(BASHRC_DEST)/.inputrc
endif

.PHONY: bashrc_common
bashrc_common:
	@if [ -L $(BASHRC_DEST)/.bash_profile ]; then \
		rm -f $(BASHRC_DEST)/.bash_profile; \
	fi
	@if [ -L $(BASHRC_DEST)/.bashrc ]; then \
		rm -f $(BASHRC_DEST)/.bashrc; \
	fi
ifeq ($(MODE), install)
	@ln -svf $(BASHRC_DIR)/bash_profile $(BASHRC_DEST)/.bash_profile
	@ln -svf $(BASHRC_DIR)/bashrc $(BASHRC_DEST)/.bashrc
endif

   ###################
######## Compton ########
   ###################

.PHONY: compton_blur
compton_blur: check_dir
	@if [ -L $(COMPTON_DEST) ]; then \
		rm -f $(COMPTON_DEST); \
	fi
ifeq ($(MODE), install)
	@ln -svf $(COMPTON_DIR)/blur.conf $(COMPTON_DEST)
endif

.PHONY: compton_noblur
compton_noblur: check_dir
	@if [ -L $(COMPTON_DEST) ]; then \
		rm -f $(COMPTON_DEST); \
	fi
ifeq ($(MODE), install)
	@ln -svf $(COMPTON_DIR)/no-blur.conf $(COMPTON_DEST)
endif

   ###############
######## Mpv ########
   ###############

.PHONY: mpv
mpv: check_dir
	@if [ -L $(MPV_DEST) ]; then \
		rm -f $(MPV_DEST); \
	fi
ifeq ($(MODE), install)
	@ln -svf $(MPV_DIR) $(MPV_DEST)
endif

   ####################
######## Neofetch ########
   ####################

.PHONY: neofetch
neofetch: check_dir
	@if [ -L $(NEOFETCH_DEST) ]; then \
		rm -f $(NEOFETCH_DEST); \
	fi
ifeq ($(MODE), install)
	@ln -svf $(NEOFETCH_DIR) $(NEOFETCH_DEST)
endif

   ##################
######## Ranger ########
   ##################

.PHONY: ranger
ranger: check_dir
	@if [ -L $(RANGER_DEST) ]; then \
		rm -f $(RANGER_DEST); \
	fi
ifeq ($(MODE), install)
	@ln -svf $(RANGER_DIR) $(RANGER_DEST)
endif

   ################
######## Skhd ########
   ################

.PHONY: skhd
skhd:
	@if [ -L $(SKHD_DEST) ]; then \
		rm -f $(SKHD_DEST); \
	fi
ifeq ($(MODE), install)
	@ln -svf $(SKHD_DIR) $(SKHD_DEST)
endif

   ################
######## Tmux ########
   ################

.PHONY: tmux
tmux:
	@if [ -L $(TMUX_DEST) ]; then \
		rm -f $(TMUX_DEST); \
	fi
ifeq ($(MODE), install)
	@ln -svf $(TMUX_DIR) $(TMUX_DEST)
endif

   ###############
######## Vim ########
   ###############

.PHONY: vim
vim:
	@if [ -L $(VIM_DEST) ]; then \
		rm -f $(VIM_DEST); \
	fi
ifeq ($(MODE), install)
	@ln -svf $(VIM_DIR) $(VIM_DEST)
endif

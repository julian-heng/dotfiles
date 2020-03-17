MODE ?= install
DRY ?= no
TARGETS = bash_profile bashrc inputrc_linux inputrc_macos mpv neofetch \
          qutebrowser bspwm sxhkd polybar yabai skhd ubersicht tmux vim
.PHONY: $(TARGETS)

DOTFILES_DIR ?= ${PWD}
HOME_DIR ?= ${HOME}
CONFIG_DIR ?= $(HOME_DIR)/.config

.DEFAULT:;
all:;

$(TARGETS):
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

# format:
# application-config: source-file destination-file

# Bash configuration files is os dependant.
# It also includes .bash_profile, .bashrc and .inputrc
bash_linux: bash inputrc_linux
bash_macos: bash inputrc_macos
bash: bash_profile bashrc

bash_profile: ${PWD}/bashrc/bash_profile ${HOME}/.bash_profile
bashrc: ${PWD}/bashrc/bashrc ${HOME}/.bashrc
inputrc_linux: ${PWD}/bashrc/inputrc_linux ${HOME}/.inputrc
inputrc_macos: ${PWD}/bashrc/inputrc_macos ${HOME}/.inputrc

mpv: ${PWD}/mpv ${HOME}/.config/mpv
neofetch: ${PWD}/neofetch ${HOME}/.config/neofetch
qutebrowser: ${PWD}/qutebrowser ${HOME}/.config/qutebrowser
bspwm: ${PWD}/bspwm ${HOME}/.config/bspwm
sxhkd: ${PWD}/sxhkd ${HOME}/.config/sxhkd
polybar: ${PWD}/polybar ${HOME}/.config/polybar
yabai: ${PWD}/yabai/yabairc ${HOME}/.yabairc
skhd: ${PWD}/skhd/skhdrc ${HOME}/.skhdrc
ubersicht: ${PWD}/ubersicht ${HOME}/Library/Application\ Support/Übersicht/widgets
tmux: ${PWD}/tmux/tmux.conf ${HOME}/.tmux.conf
vim: ${PWD}/vimrc ${HOME}/.vim

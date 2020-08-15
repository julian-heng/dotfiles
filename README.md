# Dotfiles
This repository contains all of the dotfiles that I use across multiple
machines. It is platform agnostic and works on Linux, macOS and FreeBSD. The
repo resides in the ~/.dotfiles folder because some scripts and configurations
have this path hard coded in them. However, if you're like me and like to keep
all of your git repositories in one folder, then you can symlink ~/.dotfiles to
where ever you clone this repository.

## Table of Contents
[[_TOC_]]

## Usage
### Install
```sh
$ git clone https://gitlab.com/julian-heng/dotfiles.git ~/.dotfiles --recursive
$ cd ~/.dotfiles
$ make DRY=yes [targets] # Dry run
$ make [targets]
```

Note: For FreeBSD, you need to install `gmake` as a dependency because the
Makefile uses the GNU extensions

### Uninstall
```sh
$ cd ~/.dotfiles
$ make DRY=yes MODE=uninstall [targets] # Dry run
$ make MODE=uninstall [targets]
```

## Makefile
Installation of the dotfiles is done through a Makefile.

It is very important to note that by installing these configurations, they will
overwrite the current configuration that you are currently using. If you are
going to use this Makefile and have configurations that you want to keep,
please make a backup before installing.

### Options
Setting the environment variable `MODE` and `DRY` changes the actions applied
to the targets. Other environment variables also exists, like `DOTFILES_DIR`,
`HOME_DIR` and `CONFIG_DIR` exists as well, but it is not recommended to change
these.

| Option | Valid Values       | Default |
|--------|--------------------|---------|
| MODE   | install, uninstall | install |
| DRY    | yes, no            | no      |

### Link and Copy
Some configuration files are not modified by the program at runtime, thus we
are able to simply link these files to where they are normally stored. However,
some configuration files are modified as the program is running, meaning that
we cannot link the file or else the file will get modified in the repository.
To circumvent this, we just copy the file to where it should be in order to
keep the clean copy in the repo.

The targets that are copied to the destination are stored in `COPY_CONFIGS`,
whilst targets that are symlinked are stored in `LINK_CONFIGS`.

## Dotfiles Details
### BASH
#### Aliases
##### update
The `update` alias uses the `distro` variable that is set in `.bashrc` in order
to determine which command it uses to update the system packages. If it is run
on an unknown distribution, `update` will not be set.

#### Environment Variables
##### PATH
The script directory `scripts/info` and `scripts/utils` is appended to the
`PATH` environment variable to allow running these scripts anywhere. On macOS,
`~/Library/Python/*/bin` and `/usr/local/opt/qt/bin` will be added if they
exists. Otherwise, `~/.local/bin` will be added instead.

##### DISPLAY
On macOS, if Xquartz is installed, the DISPLAY environment variable will be set
and exported.

#### ~/.inputrc
BASH is generally portable in that the configurations will work across
different operating systems. However, the `.inputrc` file works differently
between Linux and macOS/FreeBSD. As such, in order to install the BASH
configurations, use `bash_linux` for Linux and `bash_macos` for macOS/FreeBSD.
To install just the BASH configurations without the `.inputrc` file, use the
`bash` target.

#### ~/.bashrc_custom
If `~/.bashrc_custom` exists, `~/.bashrc` will automatically source this file.
This is useful if you need to add your own custom BASH configuration after
sourcing the main configuration. For example, after logging in on `tty1`, start
an X session, otherwise go to the `tty` console. `~/.bashrc_custom` would check
the current `tty` is `tty1` and executes `xinit`.

### Scripts
#### Info
Polybar, Tmux and Übersicht uses
[sys-line](https://www.gitlab.com/julian-heng/sys-line) in order to fetch
system information. If `sys-line` is not installed, the output will be
incomplete. The Tmux configuration does use the info scripts in `scripts/info`
as a fallback if `sys-line` is not installed.

#### Utils
`scripts/utils` contains simple BASH and Python scripts. Some of these are
written just for fun, while some are written because I needed to automate a
task.

##### `iommu`
Prints the IOMMU groups and the PCI devices under that group. Used to determine
if it is possible to pass through PCI devices into a QEMU/KVM virtual machine.

##### `nvidia_toggle`
Toggles between the `vfio_pci` and the `nvidia` kernel module.

##### `update-git-repos`
Performs a `git pull` in a directory containing multiple git repositories.

##### `feh-wal`, `xfce-wal` and `wal`
These scripts changes the wallpaper, with `wal` and `feh-wal` using feh, while
`xfce-wal` uses `xfconf-query`. `wal` was written first before being rewritten
to `feh-wal`.

### Vim
The plugin manager used is [Pathogen](https://github.com/tpope/vim-pathogen).
The plugins used are as follows.

| Plugin               | Author         | Repository                                             |
|----------------------|----------------|--------------------------------------------------------|
| indentLine           | Yggdroot       | [link](https://github.com/Yggdroot/indentLine)         |
| lightline            | itchyny        | [link](https://github.com/itchyny/lightline.vim)       |
| tabular              | Matt Wozniski  | [link](https://github.com/godlygeek/tabular)           |
| vim-markdown-preview | Jamshed Vesuna | [link](https://github.com/iamcco/markdown-preview.vim) |
| vim-pathogen         | Tim Pope       | [link](https://github.com/tpope/vim-pathogen)          |
| vim-repeat           | Time Pope      | [link](https://github.com/tpope/vim-repeat)            |
| vim-surround         | Tim Pope       | [link](https://github.com/tpope/vim-surround)          |

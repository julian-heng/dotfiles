#!/usr/bin/env bash

check_apps()
{
    app_list=("sudo" "make" "curl" "patch")

    for i in "${app_list[@]}"; do
        printf "%s" "Checking for $i..."
        if ! type -p "$i" > /dev/null; then
            missing+=("$i")
            printf "%s\\n" "Not OK"
        else
            printf "%s\\n" "OK"
        fi
    done

    ((${#missing[@]} > 0)) && {
        for i in "${missing[@]}"; do
            printf "%s\\n" "Dependency: $i is not installed"
        done
        exit 1
    }
}

check_git_repo_url()
{
    if [[ "$(git -C "$1" config --get remote.origin.url)" == "$2" ]]; then
        return 0
    else
        return 1
    fi
}

clone()
{
    dir="${HOME}/Git"
    printf "%s" "Checking for ${dir}..."

    if [[ ! -e "${dir}" || ! -d "${dir}" ]]; then
        printf "%s\\n" "Does not exist, cloning to ${HOME}"
        dir="${HOME}"
    else
        printf "%s\\n" "OK"
    fi

    if [[ ! -e "${dir}/st" ]]; then
        clone_dir="${dir}/st"
        printf "%s\\n" "Cloning \"git://git.suckless.org/st\" to ${clone_dir}"
    elif check_git_repo_url "${dir}/st" "git://git.suckless.org/st"; then
        clone="${clone:-false}"
        clone_dir="${dir}/st"
        printf "%s\\n" "Git repo for st already exist"
    else
        clone="${clone:-true}"
        printf -v clone_dir "%s%(%d-%m-%Y-%T)T" "${dir}/st-" "-1"
        printf "%s\\n" "Directory is not empty, using ${clone_dir}"
    fi

    [[ "${clone}" == "true" ]] && \
        git clone git://git.suckless.org/st "${clone_dir}"
}

copy_config()
{
    [[ "${copy}" == "false" ]] && \
        return 0

    [[ -e "${clone_dir}/config.h" ]] && {
        printf "%s\\n" "Warning: Config file already exist. Backing up to config.h.bootstrap"
        mv "${clone_dir}/config.h" "${clone_dir}/config.h.bootstrap"
    }

    printf "%s\\n" "Copying config file"
    cp "${BASH_SOURCE%/*}/config.h" "${clone_dir}/config.h"
}

apply_patches()
{
    [[ "${patch}" == "false" ]] && \
        return 0

    cd "${clone_dir}" || exit 1

    for url in "${urls[@]}"; do
        printf "%s\\n" "Getting ${url}"
        patches+=("$(curl -L "${url}" 2> /dev/null)")
    done

    for patch in "${patches[@]}"; do
        patch -p1 <<< "${patch}"
    done
}

make_and_install()
{
    [[ "${install}" == "false" ]] && \
        return 0

    cd "${clone_dir}" || exit 1
    make
    sudo make install
    mkdir -p "${HOME}/.local/share/applications"

    desktop_entry='[Desktop Entry]
Name=Simple Terminal
GenericName=Terminal
Comment=standard terminal emulator for the X window system
Exec=st
Terminal=false
Type=Application
Encoding=UTF-8
Icon=terminal
Categories=System;TerminalEmulator;
Keywords=shell;prompt;command;commandline;cmd;'

    printf "%s" "${desktop_entry}" > "${HOME}/.local/share/applications/st.desktop"
}

show_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} -o --option

    Options:

    [-scl|--skip-clone]     Skip cloning the st git repo
    [-sc|--skip-copy]       Skip copying config file
    [-sp|--skip-patch]      Skip patching
    [-si|--skip-install]    Skip installing st
    [-h|--help]             Show this message
"
}

show_patches()
{
    for url in "${urls[@]}"; do
        printf "%s\\n" "${url}"
    done
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "-scl"|"--skip-clone")  clone="false" ;;
            "-sc"|"--skip-copy")    copy="false" ;;
            "-sp"|"--skip-patch")   patch="false" ;;
            "-si"|"--skip-install") install="false" ;;
            "-p"|"--show-patches")  show_patches; exit 0 ;;
            "-h"|"--help")          show_usage; exit 0 ;;
        esac
        shift
    done
}

main()
{
    urls=(
        "https://st.suckless.org/patches/alpha/st-alpha-0.8.1.diff"
        "https://st.suckless.org/patches/scrollback/st-scrollback-0.8.diff"
        "https://st.suckless.org/patches/scrollback/st-scrollback-mouse-0.8.diff"
        "https://st.suckless.org/patches/scrollback/st-scrollback-mouse-altscreen-0.8.diff"
    )

    get_args "$@"
    check_apps
    clone
    copy_config
    apply_patches
    make_and_install
}

main "$@"

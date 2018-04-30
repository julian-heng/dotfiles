#!/usr/bin/env bash

function get_os
{
    case "$(uname -s)" in
        "Darwin")
            distro="MacOS"
        ;;
        "Linux") 
            if type -p lsb_release >/dev/null; then
                distro="$(lsb_release -si)"
            elif [[ -f "/etc/lsb-release" ]]; then
                distro_file="$(< /etc/lsb-release)"
                distro="$(awk '/DISTRIB_ID/ {print $1}' <<< "${distro_file}")"
                distro="${distro/DISTRIB_ID=/}"
            elif [[ -f "/etc/os-release" ]]; then
                distro_file="$(< /etc/os-release)"
                distro="$(awk 'NR==1 {print}' <<< "${distro_file}")"
                distro="${distro/NAME=/}"
                distro="${distro//\"/}"
            fi
        ;;
        "")
            printf "%s\\n" "Error: Cannot detect os"
        ;;
    esac
}

function print_header
{
    function print_line
    {
        for ((i=0;i<"${#1}";i++)); do
            printf "%s" "="
        done
        printf "\\n"
    }

    string="$1"
    print_line "${string}"
    printf "%s\\n" "${string}"
    print_line "${string}"
}

function prepare_dir
{
    if [[ -d "${0%/*}" ]]; then
        cwd="${PWD}"
        cd ${0%/*}
        script_dir="${PWD}"
        cd "${cwd}"
    else
        script_dir="${PWD}"
    fi

    config_dir="${HOME}/.config"

    dirs=(
        "${script_dir}/htop,      ${config_dir}/htop"
        "${script_dir}/mpv,       ${config_dir}/mpv"
        "${script_dir}/neofetch,  ${config_dir}/neofetch"
        "${script_dir}/ranger,    ${config_dir}/ranger"
    )

    files=(
        "${script_dir}/bashrc/bash_profile, ${HOME}/.bash_profile"
        "${script_dir}/bashrc/bashrc,       ${HOME}/.bashrc"
        "${script_dir}/vimrc/vimrc,         ${HOME}/.vimrc"
    )

    if [[ "${distro}" == "MacOS" ]]; then
        files+=("${script_dir}/skhd/skhdrc,             ${HOME}/.skhdrc")
        files+=("${script_dir}/bashrc/inputrc_macos,    ${HOME}/.inputrc")
    else
        files+=("${script_dir}/bashrc/inputrc_linux,    ${HOME}/.inputrc")
    fi
}

function install_files
{
    print_header "Installing dotfile files"
    for entry in "${files[@]}" ; do
        entry="${entry//,/ }"
        read -r _file link <<< "${entry}"
        if [[ -L "${link}" ]]; then
            if [[ "$@" == *"overwrite"* ]]; then
                printf "%s\\n" "Warning: \"${link}\" is already symlinked, overwriting"
                printf "%s\\n" "Install: Running \"rm ${link}\""
                rm "${link}"

                printf "%s\\n\\n" "Install: Running \"ln -s ${_file} ${link}\""
                [[ "$@" != *"dry"* ]] && ln -s "${_file}" "${link}"
            else
                printf "%s\\n" "Warning: \"${link}\" is already symlinked"
            fi
        elif [[ -e "${link}" ]]; then
            if [[ "$@" == *"overwrite"* ]]; then
                printf "%s\\n" "Warning: \"${link}\" already exist, overwriting"
                printf "%s\\n" "Install: Running \"rm ${link}\""
                rm "${link}"

                printf "%s\\n\\n" "Install: Running \"ln -s ${_file} ${link}\""
                [[ "$@" != *"dry"* ]] && ln -s "${_file}" "${link}"
            else
                printf "%s\\n" "Warning: \"${link}\" already exist"
            fi
        else
            printf "%s\\n" "Install: Running \"ln -s ${_file} ${link}\""
            [[ "$@" != *"dry"* ]] && ln -s "${_file}" "${link}"
        fi
    done
    printf "\\n"
}

function install_dirs
{
    print_header "Installing dotfile directories"
    for entry in "${dirs[@]}"; do
        entry="${entry//,/ }"
        read -r dir link <<< "${entry}"
        if [[ -L "${link}" ]]; then
            if [[ "$@" == *"overwrite"* ]]; then
                printf "%s\\n" "Install: \"${link}\" is already symlinked, overwriting"
                printf "%s\\n" "Install: Running \"rm ${link}\""
                [[ "$@" != *"dry"* ]] && rm "${link}"

                printf "%s\\n\\n" "Install: Running \"ln -s ${dir} ${config_dir}\""
                [[ "$@" != *"dry"* ]] && ln -s "${dir}" "${config_dir}"
            else
                printf "%s\\n" "Warning: \"${config_dir}\" is already symlinked"
            fi
            
        elif [[ -d "${link}" ]]; then
            if [[ "$@" == *"overwrite"* ]]; then
                printf "%s\\n" "Install: \"${link}\" already exist, overwriting"
                printf "%s\\n" "Install: Running \"rm -rf ${link}\""
                [[ "$@" != *"dry"* ]] && rm -rf "${link}"

                printf "%s\\n\\n" "Install: Running \"ln -s ${dir} ${config_dir}\""
                [[ "$@" != *"dry"* ]] && ln -s "${dir}" "${config_dir}"
            else
                printf "%s\\n" "Warning: \"${dir}\" already exist"
            fi

        else
            printf "%s\\n" "Install: Running \"ln -s ${script_dir}/${dir} ${config_dir}\""
            [[ "$@" != *"dry"* ]] && ln -s "${script_dir}/${dir}" "${config_dir}"
        fi
    done
    printf "\\n"
}

function uninstall
{
    print_header "Uninstalling dotfiles"
    for entry in "${dirs[@]}"; do
        entry="${entry//,/ }"
        read -r dir link <<< "${entry}"
        if [[ -L "${link}" ]]; then
            printf "%s\\n" "Uninstall: Running \"rm ${link}\""
            [[ "$@" != *"dry"* ]] && rm "${link}"
        elif [[ -d "${link}" ]]; then
            printf "%s\\n" "Warning: Cannot uninstall \"${link}\", not from dotfiles"
        else
            printf "%s\\n" "Warning: Cannot find \"${link}\""
        fi
    done

    for entry in "${files[@]}" ; do
        entry="${entry//,/ }"
        read -r _file link <<< "${entry}"
        if [[ -L "${link}" ]]; then
            printf "%s\\n" "Uninstall: Running \"rm ${link}\""
            [[ "$@" != *"dry"* ]] && rm "${link}"
        elif [[ -e "${link}" ]]; then
            printf "%s\\n" "Warning: Cannot uninstall \"${link}\", not from dotfiles"
        else
            printf "%s\\n" "Warning: Cannot find \"${link}\""
        fi
    done
    printf "\\n"
}

function main
{
    if [[ "$((${BASH_VERSINFO[0]} < 4 || ${BASH_VERSINFO[1]} < 4))" ]]; then
        printf "%s\\n" "Error: Bash 4.4+ required"
        exit 1
    fi
    get_os
    prepare_dir "$@"
    if [[ "$@" == *"uninstall"* ]]; then
        uninstall "$@"
    else
        install_files "$@"
        install_dirs "$@"
    fi
}

main "$@"

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

function print_run
{
    line="${1}"
    _command="${2}"
    prin "${line} \"${_command}\""
    [[ "${dry}" != "true" ]] && eval "${_command}"
}

function prin
{
    if [[ "$dry" == "true" ]]; then
        printf "%s\\n" "[Dry] $@"
    else
        printf "%s\\n" "$@"
    fi
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
}

function get_profile
{
    if [[ ! "${profile}" ]]; then
        case "${distro}" in
            "MacOS")    profile="${script_dir}/profiles/macos_profile"   ;;
            *)          profile="${script_dir}/profiles/linux_profile"   ;;
        esac
    fi

    if [[ ! "${profile}" ]]; then
        prin "Error: No profile selected"
        exit 1
    else
        if [[ -f "${profile}" ]]; then
            source "${profile}"
        else
            prin "Error: Invalid profile"
        fi
    fi
}

function install
{
    print_header "Installing dotfile files"
    for entry in "${dirs[@]}" "${files[@]}" ; do
        entry="${entry//,/ }"
        read -r _file _link <<< "${entry}"
        if [[ -L "${_link}" ]]; then
            if [[ "$overwrite" == "true" ]]; then
                prin "Warning: \"${_link}\" is already symlinked, overwriting"
                print_run "Install: Running" "rm ${_link}"
                print_run "Install: Running" "ln -s ${_file} ${_link}"
            else
                prin "Warning: \"${_link}\" is already symlinked"
            fi
        elif [[ -d "${_link}" || -e "${_link}" ]]; then
            if [[ "$overwrite" == "true" ]]; then
                prin "Warning: \"${_link}\" already exist, overwriting"
                print_run "Install: Running" "rm ${_link}"
                print_run "Install: Running" "ln -s ${_file} ${_link}"
            else
                prin "Warning: \"${_link}\" already exist"
            fi
        else
            print_run "Install: Running" "ln -s ${_file} ${_link}"
        fi
    done
    printf "\\n"
}

function uninstall
{
    print_header "Uninstalling dotfiles"
    for _link in "${dirs[@]}" "${files[@]}"; do
        _link="${_link##*,}"
        _link="${_link// /}"
        if [[ -L "${_link}" ]]; then
            print_run "Uninstall: Running" "rm ${_link}"
        elif [[ -d "${_link}" || -e "${_link}" ]]; then
            prin "Warning: Cannot uninstall \"${_link}\", not from dotfiles"
        else
            prin "Warning: Cannot find \"${_link}\""
        fi
    done
    printf "\\n"
}

function check_version
{
    if ((${BASH_VERSINFO[0]} < 4 || ${BASH_VERSINFO[1]} < 4)); then
        printf "%s\\n" "Error: Bash 4.4+ required"
        exit 1
    fi
}

function get_args
{
    while [[ $1 ]]; do
        case "$1" in
            "-x")               set -x ;;
            "-u"|"--uninstall") uninstall="true" ;;
            "-d"|"--dry")       dry="true" ;;
            "-o"|"--overwrite") overwrite="true" ;;
            "-p"|"--profile")   profile="$2" ;;
            "-i"|"--install")   install="true" ;;
        esac
        shift
    done
}

function main
{
    check_version
    get_args "$@"
    get_os
    prepare_dir "$0"
    get_profile

    if [[ "${uninstall}" == "true" ]]; then
        uninstall
    else
        install
    fi
}

main "$@"

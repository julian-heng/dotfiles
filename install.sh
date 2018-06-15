#!/usr/bin/env bash
# shellcheck disable=1090,2034,2154

function get_os
{
    local distro
    case "$(uname -s)" in
        "Darwin")
            distro="MacOS"
        ;;

        "Linux") 
            if type -p lsb_release >/dev/null; then
                distro="$(lsb_release -si)"
            elif [[ -f "/etc/lsb-release" ]]; then
                distro="$(awk '/DISTRIB_ID/ {print $1}' /etc/lsb-release)"
                distro="${distro/DISTRIB_ID=/}"
            elif [[ -f "/etc/os-release" ]]; then
                distro="$(awk 'NR==1 {print}' /etc/os-release)"
                distro="${distro/NAME=/}"
                distro="${distro//\"/}"
            fi
        ;;

        "")
            printf "%s\\n" "Error: Cannot detect os"
        ;;
    esac
    printf "%s" "${distro}"
}

function print_header
{
    local string="$1"
    eval printf "%0.s=" "{0..${#string}}" && printf "\\n"
    printf "%s\\n" "${string}"
    eval printf "%0.s=" "{0..${#string}}" && printf "\\n"
}

function print_run
{
    local line="$1"
    local _command="$2"
    prin "${line} \"${_command}\""
    [[ "${dry}" != "true" ]] && eval "${_command}"
}

function prin
{
    if [[ "${dry}" == "true" ]]; then
        printf "%s\\n" "[Dry] $*"
    else
        printf "%s\\n" "$*"
    fi
}

function get_full_path
{
    local cwd
    local target="$1"
    local filename
    local full_path

    cwd="${PWD}"
    if [[ -f "${target}" ]]; then
        filename="${1##*/}"
        cd "${target%/*}" || exit
        full_path="${PWD}/${filename}"
    elif [[ -d "${target}" ]]; then
        cd "${target}" || exit
        full_path="${PWD}"
    fi

    cd "${cwd}" || exit
    printf "%s" "${full_path%/}"
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

function check_git_modules
{
    while read -r module_dir && [[ "${check}" != "false" ]]; do
        ! { grep --quiet . < <(find "${module_dir}" -mindepth 1 -print -quit); } \
            && check="false"
    done < <(awk -v sd="${script_dir}" '/path =/ {print sd"/"$3}' "${script_dir}/.gitmodules")

    if [[ "${check}" == "false" ]]; then
        prin "Warning: Git submodules are not initialised. Initialising..."
        print_run "Install: Running" "git submodule update --init --recursive"
    fi
}

function install
{
    local install_list=("$@")
    local entry
    local _file
    local _link

    print_header "Installing dotfile files"
    check_git_modules
    for entry in "${install_list[@]}"; do
        entry="${entry//,/ }"
        read -r _file _link <<< "${entry}"
        if [[ -L "${_link}" ]]; then
            if [[ "${overwrite}" == "true" ]]; then
                prin "Warning: \"${_link}\" is already symlinked, overwriting"
                print_run "Install: Running" "rm ${_link}"
                print_run "Install: Running" "ln -s ${_file} ${_link}"
            else
                prin "Warning: \"${_link}\" is already symlinked"
            fi
        elif [[ -d "${_link}" || -e "${_link}" ]]; then
            if [[ "${overwrite}" == "true" ]]; then
                prin "Warning: \"${_link}\" already exist, overwriting"
                print_run "Install: Running" "rm -rf ${_link}"
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
    local uninstall_list=("$@")
    local _link

    print_header "Uninstalling dotfiles"
    for _link in "${uninstall_list[@]}"; do
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
    if ((BASH_VERSINFO[0] < 4 || BASH_VERSINFO[1] < 4)); then
        printf "%s\\n" "Error: Bash 4.4+ required"
        exit 1
    fi
}

function get_args
{
    while [[ "$1" ]]; do
        case "$1" in
            "-x")                       set -x ;;
            "-f"|"--force-install")     force="true" ;;
            "-u"|"--uninstall")         action="uninstall" ;;
            "-d"|"--dry")               dry="true" ;;
            "-o"|"--overwrite")         overwrite="true" ;;
            "-i"|"--install")           action="install" ;;
            "-g"|"--check-git-modules") action="check_git" ;;
            "-p"|"--profile")
                if [[ "${profile}" ]]; then
                    prin "Warning: \"${profile}\" is already selected"
                else
                    profile="$(get_full_path "$2")"
                fi
            ;;

        esac
        shift
    done
}

function main
{
    get_args "$@"
    [[ "${force}" != "true" ]] && check_version

    distro="$(get_os)"
    script_dir="$(get_full_path "${0%/*}")"
    config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}"
    get_profile

    case "${action:-install}" in
        "install") install "${dirs[@]}" "${files[@]}" ;;
        "uninstall") uninstall "${dirs[@]}" "${files[@]}" ;;
        "check_git") check_git_modules ;;
    esac
}

main "$@"

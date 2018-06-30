#!/usr/bin/env bash
# shellcheck disable=1090,2034,2154

function get_os
(
    case "${OSTYPE:-$(uname -s)}" in
        "Darwin"|"darwin"*)
            : "MacOS"
        ;;
        "Linux"|"linux"*)
            if type -p lsb_release >/dev/null; then
                : "$(lsb_release -si)"
            elif [[ -f "/etc/lsb-release" ]]; then
                : "$(awk '/DISTRIB_ID/ {print $1}' /etc/lsb-release)"
                : "${_/DISTRIB_ID=/}"
            elif [[ -f "/etc/os-release" ]]; then
                : "$(awk -F "=" '/NAME/ {print $2; exit}' /etc/os-release)"
                : "${_/NAME=/}"
                : "${_//\"/}"
            fi
        ;;
        "FreeBSD"|"freebsd"*)
            : "FreeBSD"
        ;;
        "MSYS"*|"msys")
            : "Windows"
        ;;
        "")
            printf "%s\\n" "Error: Cannot detect os"
        ;;
    esac
    printf "%s" "${_}"
)

function print_header
(
    eval printf "%0.s=" "{1..${#1}}" && printf "\\n"
    printf "%s\\n" "$1"
    eval printf "%0.s=" "{1..${#1}}" && printf "\\n"
)

function print_run
(
    local line="$1"
    local _command="$2"
    prin "${line} \"${_command}\""
    [[ "${dry}" != "true" ]] && eval "${_command}"
)

function prin
(
    if [[ "${dry}" == "true" ]]; then
        printf "%s\\n" "[Dry] $*"
    else
        printf "%s\\n" "$*"
    fi
)

function get_full_path
(
    target="$1"

    if [[ -f "${target}" ]]; then
	filename="${target##*/}"
        [[ "${filename}" == "${target}" ]] && \
		target="./${target}"
        target="${target%/*}"
        cd "${target}" || exit
        : "${PWD}/${filename}"
    elif [[ -d "${target}" ]]; then
        cd "${target}" || exit
        : "${PWD}"
    fi

    full_path="${_}"
    printf "%s" "${full_path%/}"
)

function count
(
    : "$#"
    printf "%s" "${_}"
)

function get_profile
{
    [[ ! "${profile}" ]] && {
        case "${distro}" in
            "MacOS")    : "${script_dir}/profiles/macos_profile" ;;
            "Windows")  : "${script_dir}/profiles/windows_profile" ;;
            *)          : "${script_dir}/profiles/linux_profile" ;;
        esac
        profile="${_}"
    }

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
(
    while read -r module_dir && [[ "${check}" != "false" ]]; do
        : "$(count "${module_dir}/"*)"
        ((${_} == 1)) && check="false"
    done < <(awk -v sd="${script_dir}" '/path =/ {print sd"/"$3}' "${script_dir}/.gitmodules")

    [[ "${check}" == "false" ]] && {
        prin "Warning: Git submodules are not initialised. Initialising..."
        print_run "Install: Running" "git submodule update --init --recursive"
    }
)

function install
(
    print_header "Installing dotfile files"
    check_git_modules
    for entry in "$@"; do
        : "${entry//,}"
        read -r _file _link <<< "${_}"
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
)

function uninstall
(
    print_header "Uninstalling dotfiles"
    for _link in "$@"; do
        : "${_link##*,}"
        : "${_// }"
        if [[ -L "${_}" ]]; then
            print_run "Uninstall: Running" "rm ${_}"
        elif [[ -d "${_}" || -e "${_}" ]]; then
            prin "Warning: Cannot uninstall \"${_}\", not from dotfiles"
        else
            prin "Warning: Cannot find \"${_}\""
        fi
    done
    printf "\\n"
)

function check_version
{
    ((BASH_VERSINFO[0] < 4 || BASH_VERSINFO[1] < 4)) && {
        printf "%s\\n" "Error: Bash 4.4+ required"
        exit 1
    }
}

function get_args
{
    while (($# > 0)); do
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
(
    get_args "$@"
    [[ "${force}" != "true" ]] && check_version

    distro="$(get_os)"
    script_dir="$(get_full_path "${0%/*}")"
    config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}"
    get_profile

    case "${action:-install}" in
        "install")      install "${dirs[@]}" "${files[@]}" ;;
        "uninstall")    uninstall "${dirs[@]}" "${files[@]}" ;;
        "check_git")    check_git_modules ;;
    esac
)

main "$@"

#!/usr/bin/env bash
# shellcheck disable=1090,2034,2154

get_os()
{
    case "${OSTYPE:-$(uname -s)}" in
        "Darwin"|"darwin"*)     os="MacOS" ;;
        "Linux"|"linux"*)       os="Linux" ;;
        "FreeBSD"|"freebsd"*)   os="FreeBSD" ;;
        "MSYS"*|"msys")         os="Windows" ;;
        "")
            printf "%s\\n" "Error: Cannot detect Operating System" >&2
        ;;
    esac
    printf "%s" "${os}"
}

prin()
{
    if [[ "${dry}" == "true" ]]; then
        printf "%s\\n" "[Dry] $*"
    else
        printf "%s\\n" "$*"
    fi
}

prin_header()
{
    eval printf "%0.s=" "{1..${#1}}" && printf "\\n"
    printf "%s\\n" "$1"
    eval printf "%0.s=" "{1..${#1}}" && printf "\\n"
}

prin_run()
{
    prin "$1 \"$2\""
    [[ "${dry}" != "true" ]] && \
        eval "$2"
}

prin_err()
{
    prin "$*" >&2
}

get_full_path()
{
    target="$1"

    if [[ -f "${target}" ]]; then
        filename="${target##*/}"
        [[ "${filename}" == "${target}" ]] && \
            target="./${target}"
        target="${target%/*}"
        cd "${target}" || exit
        full_path="${PWD}/${filename}"
    elif [[ -d "${target}" ]]; then
        cd "${target}" || exit
        full_path="${PWD}"
    fi

    printf "%s" "${full_path%/}"
}

count()
{
    printf "%s" "$#"
}

get_profile()
{
    [[ ! "${profile}" ]] && \
        case "${os}" in
            "MacOS")    profile="${script_dir}/profiles/macos_profile" ;;
            "Windows")  profile="${script_dir}/profiles/windows_profile" ;;
            *)          profile="${script_dir}/profiles/linux_profile" ;;
        esac

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

check_git_modules()
{
    while read -r module_dir && [[ "${check}" != "false" ]]; do
        (($(count "${module_dir}/"*) == 1)) && \
            check="false"
    done < <(awk -v sd="${script_dir}" '/path =/ {printf "%s\n", sd"/"$3}' "${script_dir}/.gitmodules")

    [[ "${check}" == "false" ]] && {
        prin_err "Warning: Git submodules are not initialised. Initialising..."
        prin_run "Install: Running" "git submodule update --init --recursive"
    }
}

install()
{
    prin_header "Installing dotfile files"
    check_git_modules

    [[ ! -e "${config_dir}" ]] && {
        prin_err "Warning: Config directory does not exist"
        prin_run "Install: Running" "mkdir -p ${config_dir}"
    }

    while read -r _file _link; do
        if [[ -L "${_link}" ]]; then
            if [[ "${overwrite}" == "true" ]]; then
                prin_err "Warning: \"${_link}\" is already symlinked, overwriting"
                prin_run "Install: Running" "rm ${_link}"
                prin_run "Install: Running" "ln -s ${_file} ${_link}"
            else
                prin_err "Warning: \"${_link}\" is already symlinked"
            fi
        elif [[ -d "${_link}" || -e "${_link}" ]]; then
            if [[ "${overwrite}" == "true" ]]; then
                prin_err "Warning: \"${_link}\" already exist, overwriting"
                prin_run "Install: Running" "rm -rf ${_link}"
                prin_run "Install: Running" "ln -s ${_file} ${_link}"
            else
                prin_err "Warning: \"${_link}\" already exist"
            fi
        else
            prin_run "Install: Running" "ln -s ${_file} ${_link}"
        fi
    done < <(printf "%s\\n" "${@//,}")
    printf "\\n"
}

uninstall()
{
    prin_header "Uninstalling dotfiles"
    while read -r _link; do
        if [[ -L "${_link}" ]]; then
            prin_run "Uninstall: Running" "rm ${_link}"
        elif [[ -d "${_link}" || -e "${_link}" ]]; then
            prin_err "Warning: Cannot uninstall \"${_link}\", not from dotfiles"
        else
            prin_err "Warning: Cannot find \"${_link}\""
        fi
    done < <(printf "%s\\n" "${@##*,}")
    printf "\\n"
}

check_version()
{
    ((BASH_VERSINFO[0] < 4 || BASH_VERSINFO[1] < 4)) && {
        printf "%s\\n" "Error: Bash 4.4+ required" >&2
        exit 1
    }
}

print_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} -o --option --option \"VALUE\"

    Options:

    [-i|--install]              Install dotfiles
    [-u|--uninstall]            Uninstall dotfiles
    [-d|--dry]                  Don't finalise any actions
    [-f|--force-install]        Skip checking for correct bash version
    [-o|--overwrite]            Overwrite files when installing
    [-p|--profile \"FILE\"]       Use selected profile
    [-g|--check-git-modules]    Check if git submodules are intialised
    [-x]                        Set xtrace on
    [-h|--help]                 Show this message
"
}

get_args()
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
            "-h"|"--help")              print_usage; exit 0 ;;
            "-p"|"--profile")
                if [[ "${profile}" ]]; then
                    prin_err "Warning: \"${profile}\" is already selected"
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
    [[ "${force}" != "true" ]] && \
        check_version

    os="$(get_os)"
    script_dir="$(get_full_path "${0%/*}")"
    config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}"
    get_profile

    case "${action:-install}" in
        "install")      install "${dirs[@]}" "${files[@]}" ;;
        "uninstall")    uninstall "${dirs[@]}" "${files[@]}" ;;
        "check_git")    check_git_modules ;;
    esac
}

main "$@"

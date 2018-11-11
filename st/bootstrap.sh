#!/usr/bin/env bash

get_full_path()
(
    target="$1"
    filename="${target##*/}"

    [[ "${filename}" == "${target}" ]] && \
        target="./${target}"
    target="${target%/*}"
    cd "${target}" || exit
    full_path="${PWD}/${filename}"

    printf "%s" "${full_path}"
)

check_apps()
{
    app_list=("sudo" "make" "pkg-config" "gcc" "curl" "patch")

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

confirm_dependencies()
{
    [[ "${dependency_check}" == "false" ]] && \
        return 0

    prompt="Please confirm that you have installed all of
the dependencies required for st to build.
    - libxft-dev
    - libx11-dev
    - libfontconfig-dev

Enter yes or no: "

    printf "\\n%s" "${prompt}"

    while read -r ans; do
        case "${ans}" in
            "yes")  return 0 ;;
            "no")   return 1 ;;
            *)      printf "%s" "Please enter yes or no: " ;;
        esac
    done
}

download()
{
    [[ "${source_dir}" && ! -e "${source_dir}/st.c" ]] && {
        printf "%s\\n" "\"${source_dir}\" does not contain st source files"
        download="true"
    }

    [[ ! "${source_dir}" ]] && \
        source_dir="${PWD}/${download_url##*/}"

    if [[ "${download}" != "false" ]]; then
        printf "%s\\n" "Downloading from \"${download_url}\" to \"${source_dir}\""
        if curl "${download_url}" -o "${source_dir}"; then
            tar -xf "${source_dir}"
            source_dir="${source_dir/'.tar.gz'}"
        else
            printf "%s\\n" "Error: Download failed"
            exit 1
        fi
    else
        source_dir="${source_dir/'.tar.gz'}"
    fi
}

copy_config()
{
    [[ "${copy}" == "false" ]] && \
        return 0

    [[ -e "${source_dir}/config.h" ]] && {
        printf "%s\\n" "Warning: Config file already exist. Backing up to config.h.bootstrap"
        mv "${source_dir}/config.h" "${source_dir}/config.h.bootstrap"
    }

    printf "%s\\n" "Copying config file"
    cp "${BASH_SOURCE%/*}/config.h" "${source_dir}/config.h"
}

apply_patches()
{
    [[ "${patch}" == "false" ]] && \
        return 0

    cd "${source_dir}" || exit 1

    for url in "${urls[@]}"; do
        [[ "${url}" ]] && {
            printf "%s\\n" "Getting ${url}"
            patches+=("$(curl -L "${url}" 2> /dev/null)")
        }
    done

    for patch in "${patches[@]}"; do
        patch -p1 <<< "${patch}"
    done
}

make_and_install()
{
    [[ "${install}" == "false" ]] && \
        return 0

    cd "${source_dir}" || exit 1
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

    [-sd|--skip-download]       Skip downloading st source files
    [-sc|--skip-copy]           Skip copying config file
    [-sp|--skip-patch \"num\"]    Skip patching by selected indexes
                                If no indexes are given, the skip all patches
    [-si|--skip-install]        Skip installing st
    [-d|--source-dir \"dir\"]     Use \"dir\" for st source files
                                Implies --skip-download
    [-p|--show-patches]         Show patches to be applied
    [-h|--help]                 Show this message
"
}

show_patches()
{
    index="-1"
    for url in "${urls[@]}"; do
        printf "%s\\n" "[$((++index))] ${url}"
    done
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "-sd"|"--skip-download")        download="false" ;;
            "-scd"|"--skip-dependencies")   dependency_check="false" ;;
            "-sc"|"--skip-copy")            copy="false" ;;
            "-sp"|"--skip-patch")
                p_flag="true"
                shift
                for i in "$@"; do
                    case "$1" in
                        "-"*)   break ;;
                        *)      skip_patch+=("$1"); shift ;;
                    esac
                done

                [[ ! "${skip_patch[*]}" ]] && \
                    patch="false"
            ;;

            "-si"|"--skip-install")         install="false" ;;
            "-d"|"--source-dir")
                source_dir="$(get_full_path "$2")"
                download="false"
                shift
            ;;

            "-p"|"--show-patches")          show_patches; exit 0 ;;
            "-h"|"--help")                  show_usage; exit 0 ;;
        esac

        if [[ "${p_flag}" == "true" ]]; then
            p_flag="false"
        else
            shift
        fi
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

    download_url="https://dl.suckless.org/st/st-0.8.1.tar.gz"

    get_args "$@"

    [[ "${skip_patch[*]}" ]] && \
        for index in "${skip_patch[@]}"; do
            [[ "${urls[${index}]}" ]] && \
                urls[${index}]=""
        done

    check_apps
    confirm_dependencies && {
        download
        copy_config
        apply_patches
        make_and_install
    }
}

main "$@"

#!/usr/bin/env bash

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

    dirs=(
        "htop"
        "mpv"
        "neofetch"
        "ranger"
    )

    files=(
        "${script_dir}/bashrc/"*
        "${script_dir}/skhd/skhdrc"
        "${script_dir}/vimrc/vimrc"
    )

    config_dir="${HOME}/.config"
}

function install_files
{
    print_header "Installing dotfile files"
    for _file in "${files[@]}" ; do
        if [[ -f "${_file}" ]]; then
            _filename="${_file##*/}"
            _filename="${_filename%.*}"
            if [[ -L "${HOME}/.${_filename}" ]]; then
                if [[ "$1" == "overwrite" ]]; then
                    printf "%s\\n" "Warning: \"${HOME}/.${_filename}\" is already symlinked, overwriting"
                    printf "%s\\n" "Install: Running \"rm ${HOME}/.${_filename}\""
                    rm "${HOME}/.${_filename}"
                    printf "%s\\n\\n" "Install: Running \"ln -s ${_file} ${HOME}/.${_filename}\""
                    ln -s "${_file}" "${HOME}/.${_filename}"
                else
                    printf "%s\\n" "Warning: \"${HOME}/.${_filename}\" is already symlinked"
                fi
            elif [[ -e "${HOME}/.${_filename}" ]]; then
                if [[ "$1" == "overwrite" ]]; then
                    printf "%s\\n" "Warning: \"${HOME}/.${_filename}\" already exist, overwriting"
                    printf "%s\\n" "Install: Running \"rm ${HOME}/.${_filename}\""
                    rm "${HOME}/.${_filename}"
                    printf "%s\\n\\n" "Install: Running \"ln -s ${_file} ${HOME}/.${_filename}\""
                    ln -s "${_file}" "${HOME}/.${_filename}"
                else
                    printf "%s\\n" "Warning: \"${HOME}/.${_filename}\" already exist"
                fi
            else
                printf "%s\\n" "Install: Running \"ln -s ${_file} ${HOME}/.${_filename}\""
                ln -s "${_file}" "${HOME}/.${_filename}"
            fi
        fi
    done
    printf "\\n"
}

function install_dirs
{
    print_header "Installing dotfile directories"
    for dir in "${dirs[@]}"; do
        if [[ -L "${config_dir}/${dir}" ]]; then
            if [[ "$1" == "overwrite" ]]; then
                printf "%s\\n" "Install: \"${config_dir}/${dir}\" is already symlinked, overwriting"
                printf "%s\\n" "Install: Running \"rm ${config_dir}/${dir}\""
                rm "${config_dir}/${dir}"
                printf "%s\\n\\n" "Install: Running \"ln -s ${script_dir}/${dir} ${config_dir}\""
                ln -s "${script_dir}/${dir}" "${config_dir}"
            else
                printf "%s\\n" "Warning: \"${config_dir}\" is already symlinked"
            fi
            
        elif [[ -d "${config_dir}/${dir}" ]]; then
            if [[ "$1" == "overwrite" ]]; then
                printf "%s\\n" "Install: \"${config_dir}/${dir}\" already exist, overwriting"
                printf "%s\\n" "Install: Running \"rm -rf ${config_dir}/${dir}\""
                rm -rf "${config_dir}/${dir}"
                printf "%s\\n\\n" "Install: Running \"ln -s ${script_dir}/${dir} ${config_dir}\""
                ln -s "${script_dir}/${dir}" "${config_dir}"
            else
                printf "%s\\n" "Warning: \"${script_dir}/${dir}\" already exist"
            fi

        else
            printf "%s\\n" "Install: Running \"ln -s ${script_dir}/${dir} ${config_dir}\""
            ln -s "${script_dir}/${dir}" "${config_dir}"
        fi
    done
    printf "\\n"
}

function uninstall
{
    print_header "Uninstalling dotfiles"
    for dir in "${dirs[@]}"; do
        if [[ -L "${config_dir}/${dir}" ]]; then
            printf "%s\\n" "Uninstall: Running \"rm ${config_dir}/${dir}\""
            rm "${config_dir}/${dir}"
        elif [[ -d "${config_dir}/${dir}" ]]; then
            printf "%s\\n" "Warning: Cannot uninstall \"${config_dir}/${dir}\", not from dotfiles"
        else
            printf "%s\\n" "Warning: Cannot find \"${config_dir}/${dir}\""
        fi
    done

    for _file in "${files[@]}" ; do
        if [[ -f "${_file}" ]]; then
            _filename="${_file##*/}"
            _filename="${_filename%.*}"
            if [[ -L "${HOME}/.${_filename}" ]]; then
                printf "%s\\n" "Uninstall: Running \"rm ${HOME}/.${_filename}\""
                rm "${HOME}/.${_filename}"
            elif [[ -e "${HOME}/.${_filename}" ]]; then
                printf "%s\\n" "Warning: Cannot uninstall \"${HOME}/.${_filename}\", not from dotfiles"
            else
                printf "%s\\n" "Warning: Cannot find \"${HOME}/.${_filename}\""
            fi
        fi
    done
    printf "\\n"
}

function main
{
    prepare_dir "$@"
    case "$1" in
        "--uninstall")
            uninstall
        ;;
        "--overwrite")
            install_files "overwrite"
            install_dirs "overwrite"
        ;;
        "")
            install_files
            install_dirs
        ;;
    esac
}

main "$@"

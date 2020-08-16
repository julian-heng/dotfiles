#!/usr/bin/env bash
# shellcheck disable=SC2048,SC2086

trim()
{
    [[ "$*" ]] && {
        set -f
        set -- $*
        printf "%s" "$*"
        set +f
    }
}

get_desktop()
{
    while [[ ! "${desktop_index}" ]] && IFS=":," read -r k v; do
        [[ "$k" =~ 'index' ]] && \
            desktop_index="$v"
    done < <("${yabai_exe}" -m query --spaces --space)
}

get_window()
{
    while IFS=":" read -r k v; do
        case "$k" in
            *"app"*) window_owner="${v//\"}" ;;
            *"title"*) window_name="${v//\"}" ;;
        esac
    done < <("${yabai_exe}" -m query --windows --window)

    window_owner="${window_owner:0:${#window_owner} - 1}"
    window_name="${window_name:0:${#window_name} - 1}"
}

main()
{
    max_length="50"
    yabai_exe="/usr/local/bin/yabai"
    { ! pgrep -x yabai > /dev/null || ! type -p "${yabai_exe}"; } > /dev/null 2>&1 && \
        exit 1

    get_desktop
    get_window

    out="[ ${desktop_index} "

    [[ "${window_owner}" ]] && {
        out+="| ${window_owner}"

        [[ "${window_name}" && "${window_name}" != "${window_owner}" ]] && {
            window_name="$(trim "${window_name//${window_owner}/}")"
            if ((${#window_owner} + ${#window_name} + 2 > max_length)); then
                out+=": ${window_name:0:${max_length}}..."
            else
                out+=": ${window_name}"
            fi
        }
    }

    out="$(trim "${out} ]")"
    printf "%s" "${out}"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main

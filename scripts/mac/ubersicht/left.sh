#!/usr/bin/env bash

: "${max_length:=50}"

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
    desktop_id="$("${chunkc_exec}" tiling::query --desktop id)"
}

get_window()
{
    current_window="$("${chunkc_exec}" tiling::query --window id)"

    ((current_window != 0)) && \
        while IFS=":" read -r a b; do
            case "$a" in
                "name")     window_name="$b" ;;
                "owner")    window_owner="$b" ;;
            esac
        done < <("${chunkc_exec}" tiling::query --window "${current_window}")

    window_name="$(trim "${window_name}")"
    window_owner="$(trim "${window_owner}")"
}

main()
{
    ! pgrep -x chunkwm 2>&1 > /dev/null && \
        exit 1

    chunkc_exec="/usr/local/bin/chunkc"

    get_desktop
    get_window

    out="[ ${desktop_id} "

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

[[ "${BASH_SOURCE}" == "$0" ]] && \
    main

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

    ((current_window != 0)) && {
        awk_script='
            /name/ { name = $2 }
            /owner/ { owner = $2 }
            END {
                printf "%s,%s", name, owner
            }'

        current_window_info="$("${chunkc_exec}" tiling::query --window "${current_window}")"

        IFS="," \
        read -r window_name \
                window_owner \
                < <(awk -F":" "${awk_script}" <<< "${current_window_info}")

        window_name="$(trim "${window_name}")"
        window_owner="$(trim "${window_owner}")"
    }
}

main()
{
    chunkc_exec="/usr/local/bin/chunkc"

    get_desktop
    get_window

    out="[ ${desktop_id} "

    [[ "${window_owner}" ]] && {
        out+="| ${window_owner}"

        [[ "${window_name}" ]] && \
            if ((${#window_owner} + ${#window_name} + 2 > max_length)); then
                out+=": ${window_name:0:${max_length}}..."
            else
                out+=": ${window_name}"
            fi
    }

    out="$(trim "${out} ]")"
    printf "%s" "${out}"
}

main

#!/usr/bin/env bash
# shellcheck disable=2030,2031

## Settings
: "${wal_dir:=/usr/share/wal}"
: "${xfce_property:=/backdrop/screen0/monitor0/workspace0/last-image}"

function change_wal
(
    img="$1"
    : "$(pgrep xfce4-session)"
    IFS="=" \
    read -rd '' _ dbus_session \
        < <(grep -z DBUS_SESSION_BUS_ADDRESS "/proc/${_}/environ")
    export DBUS_SESSION_BUS_ADDRESS="${dbus_session}"
    xfconf-query --channel xfce4-desktop \
                 --property "${xfce_property}" \
                 --set "${img}"
)

function main
(
    [[ "$1" ]] && wal_dir="${1%/}"
    img_path=("${wal_dir}/"*/*)

    [[ -f "${HOME}/.last_wal" ]] && \
        last_wal="$(< "${HOME}/.last_wal")"

    until [[ "${img}" && "${last_wal}" != "${img}" ]]; do
        index="$((RANDOM % ${#img_path[@]}))"
        img="${img_path[${index}]}"
    done

    printf "%s" "${img}" > "${HOME}/.last_wal"
    printf "%s\\n" "Changing wallpaper to \"${img}\""
    change_wal "${img}"
)

main "$@"

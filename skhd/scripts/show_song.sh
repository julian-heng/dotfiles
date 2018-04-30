#!/usr/bin/env bash

determine_state() {
    case "$1" in
        0|"paused")  paused="$2" ;;
        1|"playing") playing="$2" ;;
    esac
}

check_app_state() {

    if [[ "$1" ]]; then
        apps=("$1")
    else
        apps=("Spotify" "iTunes" "cmus")
    fi

    for app in "${apps[@]}"; do

        if [[ "${app}" == "cmus" ]]; then
            if pgrep -x "cmus" > /dev/null; then
                app_state="true"
                app_playing="$(awk '/status/ { print $2 }' < <(cmus-remote -Q))"
                determine_state "${app_playing}" "${app}"
            fi
        else
            ! app_state="$(osascript -e "application \"${app}\" is running")" && exit
            if [[ "${app_state}" == "true" && -z "${track}" ]]; then
                app_playing="$(osascript -e "tell application \"${app}\" to player state as string")"
                determine_state "${app_playing}" "${app}"
            fi
        fi

    done

}

get_song_info() {

    if [[ "${app}" == "cmus" ]]; then

        IFS=":" \
        read -r track \
                artist \
                album \
                < <(cmus-remote -C "format_print %{title}:%{artist}:%{album}")

    else

        track_cmd="name of current track as string"
        artist_cmd="artist of current track as string"
        album_cmd="album of current track as string"

        IFS=":" \
        read -r track \
                artist \
                album \
                < <(/usr/bin/env osascript << EOF
                        tell application "${app}"
                            ${track_cmd} & ":" & \
                            ${artist_cmd} & ":" & \
                            ${album_cmd}
                        end tell
EOF
)

    fi

}

main() {

    source "${0%/*}/notify.sh"
    check_app_state "$@"

    if [[ -z "${playing}" && -z "${paused}" ]]; then
        title="Now Playing"
        subtitle=""
        message="No music playing"
    else
        if [[ "${playing}" ]]; then
            app="${playing}"
        else
            app="${paused}"
        fi
        
        get_song_info

        title="Now Playing on ${app}"
        subtitle="${artist} - ${track}"
        message="${album}"

        case "1" in
            "$((${#subtitle} >= 50))")      subtitle="${track}"; message="${artist} - ${album}" ;&
            "$((${#message} >= 50))")       message="${artist}" ;;
        esac

    fi

    display_notification "${title:-}" "${subtitle:-}" "${message:-}"

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

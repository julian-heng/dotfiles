#!/usr/bin/env bash

function check_app_state
(
    if pgrep -x cmus > /dev/null; then
        awk '/status/ { printf "%s", $2 }' <(cmus-remote -Q)
    else
        printf "%s" "none"
    fi
)

function get_song_info
(
    case "$1" in
        "track")    cmus-remote -C "format_print %{title}" ;;
        "artist")   cmus-remote -C "format_print %{artist}" ;;
        "album")    cmus-remote -C "format_print %{album}" ;;
        *)          cmus-remote -C "format_print %{title}:%{artist}:%{album}" ;;
    esac
)

function print_usage
(
    printf "%s\\n" "
Usage: $0 --option --option \"value\"

    Options:

    [--stdout]              Print to stdout
    [--show \"func\"]         Show a specific info
    [--track]               Show name of current track
    [--artist]              Show name of artist
    [--album]               Show name of album
    [-h|--help]             Show this message

    Available functions:
        - track
        - artist
        - album

    If notify-send is not installed, then the script will
    print to standard output.
"
)

function get_args
{
    [[ ! "$*" ]] && \
        return 0

    while (($# > 0)); do
        case "$1" in
            "--stdout") stdout="true" ;;
            "--show")
                for i in "$@"; do
                    case "$i" in
                        "--show") continue ;;
                        "-"*) break ;;
                        *) show+=("$i") ;;
                    esac
                done
            ;;

            "--track") show+=("track") ;;
            "--artist") show+=("artist") ;;
            "--album") show+=("album") ;;
            "-h"|"--help") print_usage; exit ;;
        esac
        shift
    done
}

function main
(
    ! source "${BASH_SOURCE[0]//${0##*/}}format.sh" && \
        exit 1

    get_args "$@"

    ! type -p notify-send > /dev/null && \
        stdout="true"

    state="$(check_app_state)"

    case "${state}" in
        "none"|"stopped")
            title_parts=("Now Playing")
            subtitle_parts=()
            message_parts=("No Music Playing")
        ;;

        *)
            if [[ ! "${show[*]}" ]]; then
                IFS=":" \
                read -r track \
                        artist \
                        album \
                        < <(get_song_info)
                title_parts+=("Now Playing")
            else
                for i in "${show[@]}"; do
                    declare "$i=$(get_song_info "$i")"
                done
            fi

            if [[ "${artist}" ]]; then
                subtitle_parts+=("${artist}")
                [[ "${track}" ]] && \
                    subtitle_parts+=("-" "${track}")
            elif [[ "${track}" ]]; then
                subtitle_parts+=("${track}")
            fi

            [[ "${album}" ]] && \
                message_parts+=("${album}")
        ;;
    esac

    title="$(format "${title_parts[@]}")"
    subtitle="$(format "${subtitle_parts[@]}")"
    message="$(format "${message_parts[@]}")"

    if [[ "${stdout}" ]]; then
        [[ "${title}" ]] && \
            display+=("${title}")
        [[ "${subtitle}" ]] && \
            display+=("${subtitle}")
        [[ "${message}" ]] && \
            display+=("${message}")
        printf "%s\\n" "${display[@]}"
    else
        if [[ "${subtitle}" && "${message}" ]]; then
            body="${subtitle}\\n${message}"
        elif [[ ! "${subtitle}" || ! "${message}" ]]; then
            body+="${subtitle}"
            body+="${message}"
        elif [[ ! "${subtitle}" && ! "${message}" ]]; then
            body=""
        fi
        notify-send --icon=dialog-information "${title:-Now Playing}" "${body}"
    fi
)

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

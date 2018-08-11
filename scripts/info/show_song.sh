#!/usr/bin/env bash

function notify
(
    title="${title_parts[*]}"
    subtitle="${subtitle_parts[*]}"
    message="${message_parts[*]}"

    [[ "${title:0:1}" == "|" ]] && \
        title="${title##'| '}"

    [[ "${title:-1:1}" == "|" ]] && \
        title="${title%%' |'}"

    [[ "${subtitle:0:1}" == "|" ]] && \
        subtitle="${subtitle##'| '}"

    [[ "${subtitle:-1:1}" == "|" ]] && \
        subtitle="${subtitle%%' |'}"

    [[ "${message:0:1}" == "|" ]] && \
        message="${message##'| '}"

    [[ "${message:-1:1}" == "|" ]] && \
        message="${message%%' |'}"

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
        notify-send --icon=dialog-information "${title}" "${body}"
    fi
)

function check_app_state
(
    if pgrep -x cmus > /dev/null; then
        awk '/status/ { printf "%s", $2 }' <(cmus-remote -Q)
    else
        printf "%s" "none"
    fi
)

function get_song_info
{
    format="format_print %{title}:%{artist}:%{album}"
    IFS=":" \
    read -r track \
            artist \
            album \
            < <(cmus-remote -C "${format}")
}

function print_usage
(
    printf "%s\\n" "
Usage: $0 --option --option \"value\"

    Options:

    [--stdout]              Print to stdout
    [-h|--help]             Show this message

    If notify-send is not installed, then the script will
    print to standard output.
"
)

function get_args
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") stdout="true" ;;
            "-h"|"--help") print_usage; exit ;;
        esac
        shift
    done

    ! type -p notify-send > /dev/null && \
        stdout="true"
}

function main
(
    get_args "$@"

    case "$(check_app_state)" in
        "none"|"stopped")
            title_parts=("Now Playing")
            subtitle_parts=()
            message_parts=("No Music Playing")
        ;;

        *)
            get_song_info
            title_parts+=("Now Playing")

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

    notify
)

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

#!/usr/bin/env bash

has()
{
    if type -p "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

print_stdout()
{
    [[ "${title}" ]] && printf "%s\\n" "${title}"
    [[ "${subtitle}" ]] && printf "%s\\n" "${subtitle}"
    [[ "${message}" ]] && printf "%s\\n" "${message}"
}

notify()
{
    title="${title_parts[*]}"
    subtitle="${subtitle_parts[*]}"
    message="${message_parts[*]}"

    [[ "${title:0:1}" == "|" ]] && \
        title="${title##'| '}"

    [[ "${title:(-1):1}" == "|" ]] && \
        title="${title%%' |'}"

    [[ "${subtitle:0:1}" == "|" ]] && \
        subtitle="${subtitle##'| '}"

    [[ "${subtitle:(-1):1}" == "|" ]] && \
        subtitle="${subtitle%%' |'}"

    [[ "${message:0:1}" == "|" ]] && \
        message="${message##'| '}"

    [[ "${message:(-1):1}" == "|" ]] && \
        message="${message%%' |'}"

    [[ "${title:0:1}" == "|" ]] && \
        title="${title##'| '}"

    if [[ "${out}" == "stdout" ]]; then
        print_stdout
    else
        if has "notify-send" || has "osascript"; then
            if [[ "${subtitle}" && "${message}" ]]; then
                body="${subtitle}\\n${message}"
            elif [[ ! "${subtitle}" || ! "${message}" ]]; then
                body+="${subtitle}"
                body+="${message}"
            else
                body=""
            fi

            case "${os}" in
                "MacOS")
                    script="display notification \"${message}\" \
                            with title \"${title}\" \
                            subtitle \"${subtitle}\""
                    /usr/bin/env osascript <<< "${script}"
                ;;

                "Linux")
                    notify-send --icon=dialog-information "${title}" "${body}"
                ;;
            esac
        else
            print_stdout
        fi
    fi
}

trim()
{
    [[ "$*" ]] && {
        set -f
        set -- $*
        printf "%s" "${*//\"}"
        set +f
    }
}

get_os()
{
    case "${OSTYPE:-$(uname -s)}" in
        "Darwin"|"darwin"*)
            os="MacOS"
        ;;

        "Linux"|"linux"*)
            os="Linux"
        ;;
    esac
}

check_app_state()
{
    if pgrep -x "cmus" > /dev/null; then
        app="cmus"
        while read -r line && [[ ! "${app_state}" ]]; do
            [[ "${line}" =~ ^'status' ]] && \
                read -r _ app_state <<< "${line}"
        done < <(cmus-remote -Q)
    elif [[ "${os}" == "MacOS" && \
            "$(osascript -e "application \"iTunes\" is running")" == "true" ]]; then
        app="iTunes"
        app_state="$(osascript -e "tell application \"iTunes\" to player state as string")"
    else
        app="none"
        app_state="none"
    fi

    song_info["app"]="${app}"
    song_info["app_state"]="${app_state}"
}

get_song()
{
    case "${app}" in
        "cmus")
            format="format_print %{title}:%{artist}:%{album}"
            song_info="$(cmus-remote -C "${format}")"
        ;;

        "iTunes")
            cmd="_ of current track as string"
            osa_script="tell application \"${app}\"
                            ${cmd/_/'track'} & \":\" & \
                            ${cmd/_/'artist'} & \":\" & \
                            ${cmd/_/'album'}
                        end tell"
            song_info="$(/usr/bin/env osascript <<< "${osa_script}")"
        ;;
    esac

    IFS=":" \
    read -r track artist album <<< "${song_info}"

    song_info["track"]="${track}"
    song_info["artist"]="${artist}"
    song_info["album"]="${album}"
}

print_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} info_name --option --option [value] ...

Options:
    --stdout            Print to stdout
    -r, --raw           Print in csv form
    -h, --help          Show this message

Info:
    info_name           Print the output of func_name

Valid Names:
    app
    app_state
    artist
    track
    album

Output:
    -f, --format \"str\"    Print info_name in a formatted string
                          Used in conjuction with info_name

Syntax:
    {}  Output of info_name

Examples:
    Print all information as a notification:
    \$ ${0##*/}

    Print to standard out:
    \$ ${0##*/} --stdout

    Print playing track:
    \$ ${0##*/} track

    Print current music player and state:
    \$ ${0##*/} --format '{} | {}' app app_state

Misc:
    If notify-send if not installed, then the script will
    print to standard output.
"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") [[ ! "${out}" ]] && out="stdout" ;;
            "-r"|"--raw") [[ ! "${out}" ]] && out="raw" ;;
            "-f"|"--format") [[ "$2" ]] && { str_format="$2"; shift; } ;;
            "-h"|"--help") print_usage; exit ;;
            *)
                [[ ! "${out}" ]] && out="string"
                func+=("$1")
            ;;
        esac
        shift
    done
}

main()
{
    declare -A song_info
    get_args "$@"
    get_os

    [[ ! "${func[*]}" ]] && \
        func=("app" "app_state" "artist" "track" "album")

    check_app_state

    case "${app_state}" in
        "none"|"stopped")
            title_parts=("Now Playing")
            subtitle_parts=()
            message_parts=("No Music Playing")
        ;;

        *)
            get_song
        ;;
    esac

    case "${out}" in
        "raw")
            raw="${func[0]}:${song_info[${func[0]}]}"
            for function in "${func[@]:1}"; do
                raw="${raw},${function}:${song_info[${function}]}"
            done
            printf "%s\\n" "${raw}"
        ;;

        "string")
            if [[ "${str_format}" ]]; then
                out="${str_format}"
                for function in "${func[@]}"; do
                    [[ "${song_info[${function}]}" ]] && \
                        out="${out/'{}'/${song_info[${function}]}}"
                done
                printf "%s" "${out}"
            else
                for function in "${func[@]}"; do
                    [[ "${song_info[${function}]}" ]] && \
                        printf "%s\\n" "${song_info[${function}]}"
                done
            fi
        ;;

        *)
            title_parts=("Now Playing")

            if [[ "${song_info["artist"]}" ]]; then
                subtitle_parts+=("${song_info["artist"]}")
                [[ "${song_info["track"]}" ]] && \
                    subtitle_parts+=("-" "${song_info["track"]}")
            elif [[ "${song_info["track"]}" ]]; then
                subtitle_parts+=("${song_info["track"]}")
            fi

            [[ "${song_info["album"]}" ]] && \
                message_parts+=("${song_info["album"]}")

            notify
    esac
}

main "$@"

#!/usr/bin/env bash
# shellcheck disable=SC2048,SC2086

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

get_app()
{
    [[ "${app}" && "${song_info[app]}" ]] && \
        return

    if pgrep -x cmus > /dev/null 2>&1; then
        app="cmus"
    elif [[ "${os}" == "MacOS" \
         && "$(osascript -e "application \"iTunes\" is running")" == "true" ]]; then
        app="iTunes"
    else
        app="none"
    fi

    song_info[app]="${app}"
}

get_app_state()
{
    [[ "${app_state}" && "${song_info[app_state]}" ]] && \
        return

    [[ ! "${song_info[app]}" ]] && \
        get_app

    case "${song_info[app]}" in
        "cmus")
            while [[ ! "${app_state}" ]] && read -r line; do
                [[ "${line}" =~ ^'status' ]] && \
                    read -r _ app_state <<< "${line}"
            done < <(cmus-remote -Q)
        ;;

        "iTunes")
            osa_script='tell application "iTunes" to player state as string'
            app_state="$(osascript -e "${osa_script}")"
        ;;

        "none") app_state="none" ;;
    esac

    song_info[app_state]="${app_state}"
}

get_track()
{
    [[ "${track}" && "${song_info[track]}" ]] && \
        return

    [[ ! "${app_state}" && ! "${song_info[app_state]}" ]] && \
        get_app_state

    case "${app_state}" in
        "none"|"stopped")
            return
        ;;
    esac

    case "${app}" in
        "cmus")
            format="format_print %{title}"
            track="$(cmus-remote -C "${format}")"
        ;;

        "iTunes")
            osa_script='tell application "iTunes"
                            track of current track as string
                        end tell'
            track="$(/usr/bin/env osascript <<< "${osa_script}")"
        ;;
    esac

    song_info[track]="${track}"
}

get_artist()
{
    [[ "${artist}" && "${song_info[artist]}" ]] && \
        return

    [[ ! "${app_state}" && ! "${song_info[app_state]}" ]] && \
        get_app_state

    case "${app_state}" in
        "none"|"stopped")
            return
        ;;
    esac

    case "${app}" in
        "cmus")
            format="format_print %{artist}"
            artist="$(cmus-remote -C "${format}")"
        ;;

        "iTunes")
            osa_script='tell application "iTunes"
                            artist of current artist as string
                        end tell'
            artist="$(/usr/bin/env osascript <<< "${osa_script}")"
        ;;
    esac

    song_info[artist]="${artist}"
}

get_album()
{
    [[ "${album}" && "${song_info[album]}" ]] && \
        return

    [[ ! "${app_state}" && ! "${song_info[app_state]}" ]] && \
        get_app_state

    case "${app_state}" in
        "none"|"stopped")
            return
        ;;
    esac

    case "${app}" in
        "cmus")
            format="format_print %{album}"
            album="$(cmus-remote -C "${format}")"
        ;;

        "iTunes")
            osa_script='tell application "iTunes"
                            album of current album as string
                        end tell'
            album="$(/usr/bin/env osascript <<< "${osa_script}")"
        ;;
    esac

    song_info[album]="${album}"
}

print_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} info_name --option --option [value] ...

Options:
    --stdout            Print to stdout
    --jsong             Print in json format
    -r, --raw           Print in csv format
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
    If notify-send is not installed, then the script will
    print to standard output.
"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") : "${out:=stdout}" ;;
            "--json") : "${out:=json}" ;;
            "-r"|"--raw") : "${out:=raw}" ;;
            "-f"|"--format") [[ "$2" ]] && { str_format="$2"; shift; } ;;
            "-h"|"--help") print_usage; exit ;;
            *)
                : "${out:=string}"
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
        func=("app" "app_state" "track" "artist" "album")

    for function in "${func[@]}"; do
        [[ "$(type -t "get_${function}")" == "function" ]] && \
            "get_${function}"
    done

    for i in "${!func[@]}"; do
        [[ ! "${song_info[${func[$i]}]}" ]] && \
            unset 'func[$i]'
    done

    [[ ! "${func[*]}" ]] && \
        exit 1

    case "${app_state}" in
        "none"|"stopped") message_parts=("No Music Playing") ;;
    esac

    case "${out}" in
        "raw")
            raw="${func[0]}:${song_info[${func[0]}]}"
            for function in "${func[@]:1}"; do
                raw="${raw},${function}:${song_info[${function}]}"
            done
            printf "%s\\n" "${raw}"
        ;;

        "json")
            printf "{\\n"
            for function in "${func[@]::${#func[@]} - 1}"; do
                printf "    \"%s\": \"%s\",\\n" "${function}" "${song_info[${function}]}"
            done

            last="${func[*]:(-1):1}"
            printf "    \"%s\": \"%s\"\\n" "${last}" "${song_info[${last}]}"
            printf "}\\n"
        ;;

        "string")
            if [[ "${str_format}" ]]; then
                out="${str_format}"
                for function in "${func[@]}"; do
                    out="${out/'{}'/${song_info[${function}]}}"
                done
                printf "%s" "${out}"
            else
                for function in "${func[@]}"; do
                    printf "%s\\n" "${song_info[${function}]}"
                done
            fi
        ;;

        *)
            title_parts=("Now Playing")

            if [[ "${song_info[artist]}" ]]; then
                subtitle_parts+=("${song_info[artist]}")
                [[ "${song_info[track]}" ]] && \
                    subtitle_parts+=("-" "${song_info[track]}")
            elif [[ "${song_info[track]}" ]]; then
                subtitle_parts+=("${song_info[track]}")
            fi

            [[ "${song_info[album]}" ]] && \
                message_parts+=("${song_info[album]}")

            notify
    esac
}

main "$@"

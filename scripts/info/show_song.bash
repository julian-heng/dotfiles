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
            case "${line}" in
                "status"*) read -r _ app_state <<< "${line}" ;;
            esac
        done < <(cmus-remote -Q)
    elif [[ "${os}" == "MacOS" && \
            "$(osascript -e "application \"iTunes\" is running")" == "true" ]]; then
        app="iTunes"
        app_state="$(osascript -e "tell application \"iTunes\" to player state as string")"
    else
        app="none"
        app_state="none"
    fi
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
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") out="stdout" ;;
            "-r"|"--raw") out="raw" ;;
        esac
        shift
    done
}

main()
{
    get_args "$@"
    get_os

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
            printf -v raw "%s," \
                "${app}" \
                "${app_state}" \
                "${artist:-none}" \
                "${album:-none}"
            printf -v raw "%s%s" "${raw}" "${track:-none}"
            printf "%s\\n" "${raw}"
        ;;

        *)
            title_parts=("Now Playing")

            if [[ "${artist}" ]]; then
                subtitle_parts+=("${artist}")
                [[ "${track}" ]] && \
                    subtitle_parts+=("-" "${track}")
            elif [[ "${track}" ]]; then
                subtitle_parts+=("${track}")
            fi

            [[ "${album}" ]] && \
                message_parts+=("${album}")

            notify
    esac
}

main "$@"

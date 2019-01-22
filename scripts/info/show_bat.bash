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

percent()
{
    [[ "$1" && "$2" ]] && (($2 > 0)) && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", (a / b) * 100 }'
}

div()
{
    [[ "$1" && "$2" ]] && (($2 != 0)) && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", a / b }'
}

multi()
{
    [[ "$1" && "$2" ]] && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", a * b }'
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

get_bat()
{
    case "${os}" in
        "MacOS")
            while IFS='="' read -r _ a _ b; do
                case "$a" in
                    "MaxCapacity") capacity_max="$(trim "$b")" ;;
                    "CurrentCapacity") capacity_now="$(trim "$b")" ;;
                    "CycleCount") cycles="$(trim "$b")" ;;
                    "DesignCapacity") capacity_design="$(trim "$b")" ;;
                    "Temperature") temp="$(trim "$b")" ;;
                    "InstantAmperage") current="$(trim "$b")" ;;
                    "Voltage") volt="$(trim "$b")" ;;
                    "FullyCharged")
                        if [[ "$(trim "$b")" == "Yes" ]]; then
                            is_full="true"
                        else
                            is_full="false"
                        fi
                    ;;

                    "IsCharging")
                        if [[ "$(trim "$b")" == "Yes" ]]; then
                            is_charging="true"
                        else
                            is_charging="false"
                        fi
                    ;;
                esac
            done < <(ioreg -rc AppleSmartBattery)

            ((${#current} >= 20)) && \
                current="$(bc <<< "${current} - (2 ^ 64)")"

            ((temp *= 10))
        ;;

        "Linux")
        ;;
    esac

    current="${current/'-'}"
    percent="$(percent "${capacity_now}" "${capacity_max}")"
    condition="$(percent "${capacity_max}" "${capacity_design}")"

    printf -v percent "%.*f" "1" "${percent}"
    printf -v condition "%.*f" "1" "${condition}"

    if [[ "${is_charging}" == "Yes" ]]; then
        is_charging="true"
        time="$(div "$((capacity_max - capacity_now))" "${current}")"
    else
        is_charging="false"
        time="$(div "${capacity_now}" "${current}")"
    fi
    time="$(multi "${time}" "3600")"
    printf -v time "%.*f" "0" "${time}"

    if ((time != 0)); then
        hours="$((time / 60 / 60 % 24))h "
        mins="$((time / 60 % 60))m "
        secs="$(((time % 60) % 60))s"

        ((${hours/h*} == 0)) && unset hours
        ((${mins/m*} == 0)) && unset mins
        ((${secs/s*} == 0)) && unset secs

        time="${hours}${mins}${secs}"
    else
        time="0h 0m 0s"
    fi

    power="$(div "$((current * volt))" "$((10 ** 6))")"
    current="$(div "${current}" "1000")"

    printf -v power "%.*f" "2" "${power}"
    printf -v current "%.*f" "2" "${current}"

    temp="$(div "${temp}" "1000")"
    printf -v temp "%.*f" "1" "${temp}"

    if [[ "${is_full}" == "true" ]] || ((${percent/.*} == 100)); then
        is_full="true"
    else
        is_full="false"
    fi

    bat["condition"]="${condition}%"
    bat["current"]="${current}A"
    bat["cycles"]="${cycles} Cycles"
    bat["is_charging"]="${is_charging}"
    bat["is_full"]="${is_full}"
    bat["percent"]="${percent}%"
    bat["power"]="${power}W"
    bat["temp"]="${temp}°C"
    bat["time"]="${time}"
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
    percent
    time
    temp
    cycles
    is_charging
    condition
    current
    power

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

    Print battery condition and temp
    \$ ${0##*/} condition temp

    Print battery percentage and time remaining with a format string
    \$ ${0##*/} --format '{} | {}' percent time

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
        esac
        shift
    done
}

main()
{
    declare -A bat
    get_args "$@"
    get_os

    [[ ! "${func[*]}" ]] && \
        func=(
            "condition"
            "current"
            "cycles"
            "is_charging"
            "is_full"
            "percent"
            "power"
            "temp"
            "time"
        )

    get_bat

    case "${out}" in
        "raw")
            raw="${func[0]}:${bat[${func[0]}]}"
            for function in "${func[@]:1}"; do
                raw="${raw},${function}:${bat[${function}]}"
            done
            printf "%s\\n" "${raw}"
        ;;

        "string")
            if [[ "${str_format}" ]]; then
                out="${str_format}"
                for function in "${func[@]}"; do
                    [[ "${bat[${function}]}" ]] && \
                        out="${out/'{}'/${bat[${function}]}}"
                done
                printf "%s" "${out}"
            else
                for function in "${func[@]}"; do
                    [[ "${bat[${function}]}" ]] && \
                        printf "%s\\n" "${bat[${function}]}"
                done
            fi
        ;;

        *)
            title_parts+=("Battery")
            [[ "${bat["percent"]}" ]] && \
                title_parts+=("(${bat["percent"]})")

            [[ "${bat["time"]}" ]] && \
                subtitle_parts+=("${bat["time"]}")
            [[ "${bat["condition"]}" ]] && \
                subtitle_parts+=("|" "Condition: ${bat["condition"]}")
            [[ "${bat["temp"]}" ]] && \
                subtitle_parts+=("|" "${bat["temp"]}")
            [[ "${bat["cycles"]}" ]] && \
                subtitle_parts+=("|" "${bat["cycles"]}")

            [[ "${bat["is_full"]}" ]] && \
                if [[ "${bat["is_full"]}" == "true" ]]; then
                    message_parts+=("Full")
                elif [[ "${bat["is_charging"]}" == "true" ]]; then
                    message_parts+=("Charging")
                elif [[ "${bat["is_charging"]}" == "false" ]]; then
                    message_parts+=("Discharging")
                else
                    message_parts+=("Unknown")
                fi
            [[ "${bat["current"]}" ]] && \
                message_parts+=("|" "${bat["current"]}")
            [[ "${bat["power"]}" ]] && \
                message_parts+=("|" "${bat["power"]}")

            notify
        ;;
    esac
}

main "$@"

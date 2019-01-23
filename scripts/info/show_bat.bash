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

read_file()
{
    local file="$1"
    [[ -f "${file}" ]] && \
        printf "%s" "$(< "${file}")"
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
                    "MaxCapacity") bat_capacity_max="$(trim "$b")" ;;
                    "CurrentCapacity") bat_capacity_now="$(trim "$b")" ;;
                    "CycleCount") bat_cycles="$(trim "$b")" ;;
                    "DesignCapacity") bat_capacity_design="$(trim "$b")" ;;
                    "Temperature") bat_temp="$(trim "$b")" ;;
                    "InstantAmperage") bat_current="$(trim "$b")" ;;
                    "Voltage") bat_volt="$(trim "$b")" ;;
                    "FullyCharged")
                        if [[ "$(trim "$b")" == "Yes" ]]; then
                            bat_is_full="true"
                        else
                            bat_is_full="false"
                        fi
                    ;;

                    "IsCharging")
                        if [[ "$(trim "$b")" == "Yes" ]]; then
                            bat_is_charging="true"
                        else
                            bat_is_charging="false"
                        fi
                    ;;
                esac
            done < <(ioreg -rc AppleSmartBattery)

            ((${#bat_current} >= 20)) && \
                bat_current="$(bc <<< "${bat_current} - (2 ^ 64)")"

            ((bat_temp *= 10))
        ;;

        "Linux")
            while [[ ! "${bat_driver}" ]] && read -r line; do
                [[ "${line}" =~ 'tp_smapi' ]] && \
                    bat_driver="tp_smapi"
            done < /proc/modules

            [[ ! "${bat_driver}" ]] && bat_driver="generic"

            case "${bat_driver}" in
                "tp_smapi") power_dir="/sys/devices/platform/smapi" ;;
                "generic") power_dir="/sys/class/power_supply" ;;
            esac

            while [[ ! "${bat_dir}" ]] && read -r dir; do
                [[ "${dir##"${power_dir}/"}" =~ ^'BAT'[0-9] ]] && \
                    bat_dir="${dir}"
            done < <(printf "%s\\n" "${power_dir}/"*)

            case "${bat_driver}" in
                "tp_smapi")
                    bat_capacity_design="$(< "${bat_dir}/design_capacity")"
                    bat_capacity_max="$(< "${bat_dir}/last_full_capacity")"
                    bat_capacity_now="$(< "${bat_dir}/remaining_capacity")"
                    bat_cycles="$(< "${bat_dir}/cycle_count")"
                    bat_power="$(< "${bat_dir}/power_now")"
                    bat_temp="$(< "${bat_dir}/temperature")"
                    bat_volt="$(< "${bat_dir}/voltage")"
                    bat_volt_design="$(< "${bat_dir}/design_voltage")"

                    if [[ "$(< "${bat_dir}/state")" == "discharging" ]]; then
                        bat_is_charging="false"
                    else
                        bat_is_charging="true"
                    fi

                    bat_current="$(
                        div "$((bat_power * 1000))" "${bat_volt_design}"
                    )"
                    bat_capacity_design="$(
                        div "$((bat_capacity_design * 1000))" "${bat_volt_design}"
                    )"
                    bat_capacity_max="$(
                        div "$((bat_capacity_max * 1000))" "${bat_volt_design}"
                    )"
                    bat_capacity_now="$(
                        div "$((bat_capacity_now * 1000))" "${bat_volt_design}"
                    )"

                    printf -v bat_current "%.*f" "0" "${bat_current}"
                    printf -v bat_capacity_design "%.*f" "0" "${bat_capacity_design}"
                    printf -v bat_capacity_max "%.*f" "0" "${bat_capacity_max}"
                    printf -v bat_capacity_now "%.*f" "0" "${bat_capacity_now}"
                ;;

                "generic")
                    if [[ -f "${bat_dir}/current_now" ]]; then
                        bat_capacity_design="$(read_file "${bat_dir}/charge_full_design")"
                        bat_capacity_max="$(read_file "${bat_dir}/charge_full")"
                        bat_capacity_now="$(read_file "${bat_dir}/charge_now")"
                        bat_cycles="$(read_file "${bat_dir}/cycle_count")"
                        bat_power="$(read_file "${bat_dir}/power_now")"
                        bat_temp="$(read_file "${bat_dir}/temp")"
                        bat_volt="$(read_file "${bat_dir}/voltage_now")"
                        bat_volt_design="$(read_file "${bat_dir}/voltage_min_design")"

                        if [[ "$(read_file "${bat_dir}/status")" == "Discharging" ]]; then
                            bat_is_charging="false"
                        else
                            bat_is_charging="true"
                        fi

                        bat_capacity_design="$((bat_capacity_design / 1000))"
                        bat_capacity_max="$((bat_capacity_max / 1000))"
                        bat_capacity_now="$((bat_capacity_now / 1000))"
                        [[ "${bat_power}" ]] && \
                            bat_power="$((bat_power / 1000))"
                        bat_volt="$((bat_volt / 1000))"
                        bat_volt_design="$((bat_volt_design / 1000))"
                    elif [[ -f "${bat_dir}/power_now" ]]; then
                        bat_capacity_design="$(read_file "${bat_dir}/energy_full_design")"
                        bat_capacity_max="$(read_file "${bat_dir}/energy_full")"
                        bat_capacity_now="$(read_file "${bat_dir}/energy_now")"
                        bat_cycles="$(read_file "${bat_dir}/cycle_count")"
                        bat_power="$(read_file "${bat_dir}/power_now")"
                        bat_temp="$(read_file "${bat_dir}/temp")"
                        bat_volt="$(read_file "${bat_dir}/voltage_now")"
                        bat_volt_design="$(read_file "${bat_dir}/voltage_min_design")"

                        if [[ "$(read_file "${bat_dir}/status")" == "Discharging" ]]; then
                            bat_is_charging="false"
                        else
                            bat_is_charging="true"
                        fi

                        bat_capacity_design="$((bat_capacity_design / 1000))"
                        bat_capacity_max="$((bat_capacity_max / 1000))"
                        bat_capacity_now="$((bat_capacity_now / 1000))"
                        bat_power="$((bat_power / 1000))"
                        bat_volt="$((bat_volt / 1000))"
                        bat_volt_design="$((bat_volt_design / 1000))"

                        bat_current="$(
                            div "$((bat_power * 1000))" "${bat_volt_design}"
                        )"
                        bat_capacity_design="$(
                            div "$((bat_capacity_design * 1000))" "${bat_volt_design}"
                        )"
                        bat_capacity_max="$(
                            div "$((bat_capacity_max * 1000))" "${bat_volt_design}"
                        )"
                        bat_capacity_now="$(
                            div "$((bat_capacity_now * 1000))" "${bat_volt_design}"
                        )"

                        printf -v bat_current "%.*f" "0" "${bat_current}"
                        printf -v bat_capacity_design "%.*f" "0" "${bat_capacity_design}"
                        printf -v bat_capacity_max "%.*f" "0" "${bat_capacity_max}"
                        printf -v bat_capacity_now "%.*f" "0" "${bat_capacity_now}"
                    fi
                ;;
            esac
        ;;
    esac

    bat_current="${bat_current/'-'}"
    bat_power="${bat_power/'-'}"
    bat_percent="$(percent "${bat_capacity_now}" "${bat_capacity_max}")"
    bat_condition="$(percent "${bat_capacity_max}" "${bat_capacity_design}")"

    printf -v bat_percent "%.*f" "1" "${bat_percent}"
    printf -v bat_condition "%.*f" "1" "${bat_condition}"

    if [[ "${bat_is_charging}" == "true" ]]; then
        bat_time="$(div "$((bat_capacity_max - bat_capacity_now))" "${bat_current}")"
    else
        bat_is_charging="false"
        bat_time="$(div "${bat_capacity_now}" "${bat_current}")"
    fi
    bat_time="$(multi "${bat_time}" "3600")"
    printf -v bat_time "%.*f" "0" "${bat_time}"

    if ((bat_time != 0)); then
        hours="$((bat_time / 60 / 60 % 24))h "
        mins="$((bat_time / 60 % 60))m "
        secs="$(((bat_time % 60) % 60))s"

        ((${hours/h*} == 0)) && unset hours
        ((${mins/m*} == 0)) && unset mins
        ((${secs/s*} == 0)) && unset secs

        bat_time="${hours}${mins}${secs}"
    else
        bat_time="0h 0m 0s"
    fi

    if [[ ! "${bat_power}" ]]; then
        bat_power="$(div "$((bat_current * bat_volt))" "$((10 ** 6))")"
    else
        bat_power="$(div "${bat_power}" "1000")"
    fi
    bat_current="$(div "${bat_current}" "1000")"
    bat_volt="$(div "${bat_volt}" "1000")"

    printf -v bat_power "%.*f" "2" "${bat_power}"
    printf -v bat_current "%.*f" "2" "${bat_current}"
    printf -v bat_volt "%.*f" "2" "${bat_volt}"

    bat_temp="$(div "${bat_temp}" "1000")"
    printf -v bat_temp "%.*f" "1" "${bat_temp}"

    if [[ "${bat_is_full}" == "true" ]] || ((${bat_percent/.*} == 100)); then
        bat_is_full="true"
    else
        bat_is_full="false"
    fi

    bat_info["bat_condition"]="${bat_condition}%"
    bat_info["bat_current"]="${bat_current}A"
    bat_info["bat_cycles"]="${bat_cycles} Cycles"
    bat_info["bat_is_charging"]="${bat_is_charging}"
    bat_info["bat_is_full"]="${bat_is_full}"
    bat_info["bat_percent"]="${bat_percent}%"
    bat_info["bat_power"]="${bat_power}W"
    bat_info["bat_temp"]="${bat_temp}°C"
    bat_info["bat_time"]="${bat_time}"
    bat_info["bat_volt"]="${bat_volt}"
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
    bat_condition
    bat_current
    bat_cycles
    bat_is_charging
    bat_percent
    bat_power
    bat_temp
    bat_time
    bat_volt

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

    Print battery condition and temp:
    \$ ${0##*/} bat_condition bat_temp

    Print battery percentage and time remaining with a format string:
    \$ ${0##*/} --format '{} | {}' percent bat_time

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
    declare -A bat_info
    get_args "$@"
    get_os

    [[ ! "${func[*]}" ]] && \
        func=(
            "bat_condition"
            "bat_current"
            "bat_cycles"
            "bat_is_charging"
            "bat_is_full"
            "bat_percent"
            "bat_power"
            "bat_temp"
            "bat_time"
            "bat_volt"
        )

    get_bat

    case "${out}" in
        "raw")
            raw="${func[0]}:${bat_info[${func[0]}]}"
            for function in "${func[@]:1}"; do
                raw="${raw},${function}:${bat_info[${function}]}"
            done
            printf "%s\\n" "${raw}"
        ;;

        "string")
            if [[ "${str_format}" ]]; then
                out="${str_format}"
                for function in "${func[@]}"; do
                    [[ "${bat_info[${function}]}" ]] && \
                        out="${out/'{}'/${bat_info[${function}]}}"
                done
                printf "%s" "${out}"
            else
                for function in "${func[@]}"; do
                    [[ "${bat_info[${function}]}" ]] && \
                        printf "%s\\n" "${bat_info[${function}]}"
                done
            fi
        ;;

        *)
            title_parts+=("Battery")
            [[ "${bat_info["bat_percent"]}" ]] && \
                title_parts+=("(${bat_info["bat_percent"]})")

            [[ "${bat_info["bat_time"]}" && \
               "${bat_info["bat_time"]}" != "0h 0m 0s" ]] && \
                subtitle_parts+=("${bat_info["bat_time"]}")
            [[ "${bat_info["bat_condition"]}" ]] && \
                subtitle_parts+=("|" "Condition: ${bat_info["bat_condition"]}")
            [[ "${bat_info["bat_temp"]}" ]] && \
                subtitle_parts+=("|" "${bat_info["bat_temp"]}")
            [[ "${bat_info["bat_cycles"]}" ]] && \
                subtitle_parts+=("|" "${bat_info["bat_cycles"]}")

            [[ "${bat_info["bat_is_full"]}" ]] && \
                if [[ "${bat_info["bat_is_full"]}" == "true" ]]; then
                    message_parts+=("Full")
                elif [[ "${bat_info["bat_is_charging"]}" == "true" ]]; then
                    message_parts+=("Charging")
                elif [[ "${bat_info["bat_is_charging"]}" == "false" ]]; then
                    message_parts+=("Discharging")
                else
                    message_parts+=("Unknown")
                fi
            [[ "${bat_info["bat_current"]}" ]] && \
                message_parts+=("|" "${bat_info["bat_current"]}")
            [[ "${bat_info["bat_power"]}" ]] && \
                message_parts+=("|" "${bat_info["bat_power"]}")

            notify
        ;;
    esac
}

main "$@"

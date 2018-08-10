#!/usr/bin/env bash

function notify
(
    title="${title_parts[*]}"
    subtitle="${subtitle_parts[*]}"
    message="${message_parts[*]}"

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

function get_bat_info
{
    bat_dir="/sys/class/power_supply"

    for file in "${bat_dir}"/*; do
        [[ "${file##${bat_dir}/}" =~ ^'BAT' && "$(< "${file}/type")" == "Battery" ]] && {
            bat_dir="${file}"
        }
    done

    if [[ ! -f "${bat_dir}/uevent" || ! -f "${bat_dir}/current_now" ]]; then
        exit 1
    else
        bat_file="${bat_dir}/uevent"
    fi

    awk_script='
        /POWER_SUPPLY_STATUS/ { state = $2 }
        /POWER_SUPPLY_CHARGE_NOW/ { charge_now = $2 }
        /POWER_SUPPLY_CHARGE_FULL/ { charge_full = $2}
        /POWER_SUPPLY_CHARGE_FULL_DESIGN/ { charge_design = $2 }
        /POWER_SUPPLY_CURRENT_NOW/ { current_now = $2 }
        /POWER_SUPPLY_TEMP/ { temp = $2 }
        /POWER_SUPPLY_CYCLE_COUNT/ { cycles = $2 }
        END {
            percent = (charge_now / charge_full) * 100

            if (state == "Charging")
                time = (charge_full - charge_now) / current_now
            else
                time = charge_now / current_now
            time *= 3600
            time -= time % 1

            temp /= 10

            condition = (charge_full / charge_design) * 100

            printf "%s %0.2f %s %0.2f %d %0.2f",
                state, percent, time, temp, cycles, condition
        }'

    read -r bat_state \
            bat_percent \
            bat_time \
            bat_temp \
            bat_cycles \
            bat_condition \
            < <(awk -F"=" "${awk_script}" "${bat_file}")

    hours="$((bat_time / 60 / 60 % 24))"
    mins="$((bat_time / 60 % 60))"
    secs="$(((bat_time % 60) % 60))"

    hours+="h "
    mins+="m "
    secs+="s"

    ((${hours/h*} == 0)) && unset hours
    ((${mins/m*} == 0)) && unset mins
    ((${secs/s} == 0)) && unset secs

    bat_time="${hours}${mins}${secs}"
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
    get_bat_info

    title_parts+=("Battery")
    [[ "${bat_percent}" ]] && \
        title_parts+=("(${bat_percent}%)")

    [[ "${bat_time}" ]] && \
        subtitle_parts+=("${bat_time}")

    [[ "${bat_condition}" ]] && \
        subtitle_parts+=("|" "Condition: ${bat_condition}%")

    [[ "${bat_temp}" ]] && \
        subtitle_parts+=("|" "${bat_temp}°C")

    [[ "${bat_cycles}" ]] && \
        subtitle_parts+=("|" "${bat_cycles} cycles")

    [[ "${bat_state}" ]] && \
        message_parts+=("${bat_state}")

    notify
)

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

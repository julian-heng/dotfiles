#!/usr/bin/env bash

trim()
{
    [[ "$*" ]] && {
        set -f
        set -- $*
        printf "%s" "$*"
        set +f
    }
}

notify()
{
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
}

get_bat_info()
{
    if [[ -d "/sys/devices/platform/smapi" ]]; then
        bat_dir="/sys/devices/platform/smapi"
    else
        bat_dir="/sys/class/power_supply"
    fi

    for file in "${bat_dir}"/*; do
        [[ "${file##${bat_dir}/}" =~ ^'BAT' ]] && {
            bat_dir="${file}"
            break
        }
    done

    if [[ -f "${bat_dir}/status" ]]; then
        bat_status="$(< "${bat_dir}/status")"
    elif [[ -f "${bat_dir}/state" ]]; then
        bat_status="$(< "${bat_dir}/state")"
    else
        exit 1
    fi

    if [[ -f "${bat_dir}/charge_full" ]]; then
        bat_charge_full="$(< "${bat_dir}/charge_full")"
    elif [[ -f "${bat_dir}/energy_full" ]]; then
        bat_charge_full="$(< "${bat_dir}/energy_full")"
    elif [[ -f "${bat_dir}/last_full_capacity" ]]; then
        bat_charge_full="$(($(< "${bat_dir}/last_full_capacity") * 100))"
    else
        exit 1
    fi

    if [[ -f "${bat_dir}/charge_now" ]]; then
        bat_charge_now="$(< "${bat_dir}/charge_now")"
    elif [[ -f "${bat_dir}/energy_now" ]]; then
        bat_charge_now="$(< "${bat_dir}/energy_now")"
    elif [[ -f "${bat_dir}/remaining_capacity" ]]; then
        bat_charge_now="$(($(< "${bat_dir}/remaining_capacity") * 100))"
        [[ "${bat_status}" == "Charging" ]] && \
            bat_charge_now="$((bat_charge_full - bat_charge_now))"
    else
        exit 1
    fi

    if [[ -f "${bat_dir}/charge_full_design" ]]; then
        bat_charge_full_design="$(< "${bat_dir}/charge_full_design")"
    elif [[ -f "${bat_dir}/energy_full_design" ]]; then
        bat_charge_full_design="$(< "${bat_dir}/energy_full_design")"
    elif [[ -f "${bat_dir}/design_capacity" ]]; then
        bat_charge_full_design="$(($(< "${bat_dir}/design_capacity") * 100))"
    else
        exit 1
    fi

    if [[ -f "${bat_dir}/current_now" ]]; then
        if [[ "${bat_dir}" =~ 'smapi' ]]; then
            bat_current_now="$(($(< "${bat_dir}/current_now") * 1000))"
            [[ "${bat_current_now}" =~ ^'-' ]] && \
                bat_current_now="$((-bat_current_now))"
        else
            bat_current_now="$(< "${bat_dir}/current_now")"
        fi
    else
        exit 1
    fi

    if [[ -f "${bat_dir}/temp" ]]; then
        bat_temp="$(< "${bat_dir}/temp")"
    elif [[ -f "${bat_dir}/temperature" ]]; then
        bat_temp="$(($(< "${bat_dir}/temperature") / 100))"
    else
        exit 1
    fi

    if [[ -f "${bat_dir}/cycle_count" ]]; then
        bat_cycles="$(< "${bat_dir}/cycle_count")"
    else
        exit 1
    fi

    awk_script='
        BEGIN {
            percent = (charge_now / charge_full) * 100

            if (current_now == "" || current_now == 0)
                time = -1
            else
            {
                if (state == "Charging")
                    time = (charge_full - charge_now) / current_now
                else
                    time = charge_now / current_now
                time *= 3600
                time -= time % 1
            }

            temp /= 10
            condition = (charge_full / charge_design) * 100

            printf "%0.2f %d %d %0.2f",
                percent, time, temp, condition
        }'

    bat_stats="$(awk -v state="${bat_status^}" \
                     -v current_now="${bat_current_now}" \
                     -v charge_now="${bat_charge_now}" \
                     -v charge_full="${bat_charge_full}" \
                     -v charge_design="${bat_charge_full_design}" \
                     -v temp="${bat_temp}" \
                     "${awk_script}")"

    read -r bat_percent \
            bat_time \
            bat_temp \
            bat_condition \
            <<< "${bat_stats}"

    if ((bat_time != -1)); then
        hours="$((bat_time / 60 / 60 % 24))"
        mins="$((bat_time / 60 % 60))"
        secs="$(((bat_time % 60) % 60))"

        hours+="h "
        mins+="m "
        secs+="s"

        ((${hours/h*} == 0)) && unset hours
        ((${mins/m*} == 0)) && unset mins
        ((${secs/s} == 0)) && unset secs

        bat_time="$(trim "${hours}${mins}${secs}")"
    else
        bat_time="Unknown"
    fi
}

print_usage()
{
    printf "%s\\n" "
Usage: $0 --option --option \"value\"

    Options:

    [--stdout]              Print to stdout
    [-h|--help]             Show this message

    If notify-send is not installed, then the script will
    print to standard output.
"
}

get_args()
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

main()
{
    get_args "$@"
    get_bat_info

    title_parts+=("Battery")
    [[ "${bat_percent}" ]] && \
        title_parts+=("(${bat_percent}%)")

    [[ ! "${bat_status}" =~ (Full|idle) && "${bat_time}" ]] && \
        subtitle_parts+=("${bat_time}")

    [[ "${bat_condition}" ]] && \
        subtitle_parts+=("|" "Condition: ${bat_condition}%")

    [[ "${bat_temp}" ]] && \
        subtitle_parts+=("|" "${bat_temp}°C")

    [[ "${bat_cycles}" ]] && \
        subtitle_parts+=("|" "${bat_cycles} Cycles")

    [[ "${bat_status}" ]] && \
        message_parts+=("${bat_status^}")

    notify
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

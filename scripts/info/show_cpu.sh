#!/usr/bin/env bash

function trim
(
    set -f
    set -- $*
    printf "%s" "$*"
    set +f
)

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

function get_cores
{
    for line in "${cpu_file[@]}"; do
        [[ "${line}" =~ ^processor ]] && \
            ((cores++))
    done
}

function get_cpu
{
    speed_dir="/sys/devices/system/cpu"

    for i in "${cpu_file[@]}"; do
        [[ "$i" =~ 'model name' ]] && {
            cpu="$i"
            break
        }
    done

    shopt -s globstar
    for i in "${speed_dir}"/**/*; do
        [[ "$i" =~ bios_limit|scaling_max|cpuinfo_max ]] && {
            speed_file="$i"
            break
        }
    done
    shopt -u globstar

    [[ "${speed_file}" ]] && \
        speed="$(awk 'END { printf "%0.1f", $1 / 1000000}' "${speed_file}")"

    cpu="${cpu//*:}"
    cpu="${cpu//:}"
    cpu="${cpu//CPU}"
    cpu="${cpu//(R)}"
    cpu="${cpu//(TM)}"

    if [[ "${speed}" ]]; then
        cpu="${cpu//@*}"
        cpu="${cpu}(${cores}) @ ${speed}GHz"
    else
        cpu="${cpu//@/(${cores}) @}"
    fi

    cpu="$(trim "${cpu}")"
}

function get_load
{
    load_file="/proc/loadavg"
    read -ra load_arr < "${load_file}"
    load_avg="${load_arr[*]:0:3}"
}

function get_cpu_usage
{
    awk_script='
        { sum += $3 }
        END {
            printf "%0.0f", sum / cores
        }'

    cpu_usage="$(awk -v cores="${cores:-1}" \
                     -v sum="0" "${awk_script}" <(ps aux))"
}

function get_temp
{
    temp_dir="/sys/class/hwmon"

    for file in "${temp_dir}"/*; do
        [[ -f "${file}/name" ]] && {
            [[ "$(< "${file}/name")" =~ temp ]] && \
                for i in "${file}/temp"*; do
                    [[ "$i" =~ '_input'$ ]] && {
                        temp_file="$i"
                        break
                    }
                done
        }
    done

    [[ ! "${temp_file}" ]] && \
        return 1

    temp="$(($(< "${temp_file}") / 1000))"
    temp+="°C"
}

function get_fan
{
    fan_dir="/sys/devices/platform"

    shopt -s globstar
    for i in "${fan_dir}"/**/*; do
        [[ "$i" =~ 'fan1_input'$ ]] && {
            fan_file="$i"
            break
        }
    done
    shopt -u globstar

    if [[ ! "${fan_file}" ]]; then
        return 1
    else
        fan="$(< "${fan_file}")"
    fi
    fan="${fan:-0} RPM"
}

function get_uptime
{
    uptime_file="/proc/uptime"

    read -r secs _ < "${uptime_file}"
    secs="${secs%.*}"

    days="$((secs / 60 / 60 / 24))"
    hours="$((secs / 60 / 60 % 24))"
    mins="$((secs / 60 % 60))"
    secs="$(((secs % 60) % 60))"

    days+="d "
    hours+="h "
    mins+="m "
    secs+="s"

    ((${days/d*} == 0)) && unset days
    ((${hours/h*} == 0)) && unset hours
    ((${mins/m*} == 0)) && unset mins
    ((${secs/s} == 0)) && unset secs

    uptime="${days}${hours}${mins}${secs}"
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
            "--stdout")     stdout="true" ;;
            "-h"|"--help")  print_usage; exit ;;
        esac
        shift
    done

    ! type -p notify-send > /dev/null && \
        stdout="true"
}

function main
(
    mapfile -t cpu_file < "/proc/cpuinfo"

    get_args "$@"

    get_cores
    get_cpu
    get_load
    get_cpu_usage
    get_temp
    get_fan
    get_uptime

    title_parts+=("${cpu:-CPU}")

    [[ "${load_avg}" ]] && \
        subtitle_parts+=("Load avg:" "${load_avg}")

    [[ "${cpu_usage}" ]] && \
        subtitle_parts+=("|" "${cpu_usage}%")

    [[ "${temp}" ]] && \
        subtitle_parts+=("|" "${temp}")

    [[ "${fan}" ]] && \
        subtitle_parts+=("|" "${fan}")

    [[ "${uptime}" ]] && \
        message_parts+=("Uptime:" "${uptime}")

    notify
)

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

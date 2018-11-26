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

get_cores()
{
    for line in "${cpu_file[@]}"; do
        [[ "${line}" =~ ^processor ]] && \
            ((cores++))
    done
}

get_cpu()
{
    speed_dir="/sys/devices/system/cpu"

    for i in "${cpu_file[@]}"; do
        [[ "$i" =~ 'model name' ]] && {
            cpu="$i"
            break
        }
    done

    case "${speed_type}" in
        "max")  search="bios_limit|scaling_max|cpuinfo_max" ;;
        *)      search="scaling_cur" ;;
    esac

    shopt -s globstar
    for i in "${speed_dir}"/**/*; do
        [[ "$i" =~ ${search} ]] && {
            speed_file="$i"
            break
        }
    done
    shopt -u globstar

    [[ "${speed_file}" ]] && \
        speed="$(awk 'END { printf "%0.2f", $1 / 1000000}' "${speed_file}")"

    cpu="${cpu//*:}"
    cpu="${cpu//:}"
    cpu="${cpu//CPU}"
    cpu="${cpu//(R)}"
    cpu="${cpu//(TM)}"

    if [[ "${speed}" ]]; then
        cpu="${cpu//@*}"
        cpu="${cpu} (${cores}) @ ${speed}GHz"
    else
        cpu="${cpu//@/(${cores}) @}"
    fi

    cpu="$(trim "${cpu}")"
}

get_load()
{
    load_file="/proc/loadavg"
    read -ra load_arr < "${load_file}"
    load_avg="${load_arr[*]:0:3}"
}

get_cpu_usage()
{
    awk_script='
        { sum += $3 }
        END {
            printf "%0.0f", sum / cores
        }'

    cpu_usage="$(awk -v cores="${cores:-1}" \
                     -v sum="0" "${awk_script}" <(ps aux))"
}

get_temp()
{
    temp_dir="/sys/class/hwmon"

    for file in "${temp_dir}"/*; do
        [[ -f "${file}/name" && "$(< "${file}/name")" =~ temp ]] && {
            for i in "${file}/temp"*; do
                [[ "$i" =~ '_input'$ ]] && {
                    temp_file="$i"
                    break
                }
            done
            break
        }
    done

    [[ ! "${temp_file}" ]] && \
        return 1

    temp="$(($(< "${temp_file}") / 1000))"
    temp+="°C"
}

get_fan()
{
    fan_dir="/sys/devices/platform"

    shopt -s globstar
    for i in "${fan_dir}"/**/*; do
        [[ "$i" =~ 'fan1_input'$ ]] && {
            fan_files+=("$i")
        }
    done
    shopt -u globstar

    if [[ ! "${fan_files[*]}" ]]; then
        return 1
    else
        for fan_file in "${fan_files[@]}"; do
            fan="$(< "${fan_file}")"
            ((fan != 0)) && \
                break
        done
    fi
    fan="${fan:-0} RPM"
}

get_uptime()
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

print_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} --option --option \"value\"

    Options:

    [--stdout]              Print to stdout
    [-r|--raw]              Print raw values delimited by commas
    [-s|--speed-type]       Use [current] or [max]imum cpu frequency
                            Default is current
    [-h|--help]             Show this message

    If notify-send is not installed, then the script will
    print to standard output.
"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout")             stdout="true" ;;
            "-r"|"--raw")           raw="true" ;;
            "-s"|"--speed-type")    speed_type="$2"; shift ;;
            "-h"|"--help")          print_usage; exit ;;
        esac
        shift
    done

    ! type -p notify-send > /dev/null && \
        stdout="true"
}

main()
{
    mapfile -t cpu_file < "/proc/cpuinfo"

    get_args "$@"

    get_cores
    get_cpu
    get_load
    get_cpu_usage
    get_temp
    get_fan
    get_uptime

    [[ "${raw}" ]] && {
        printf -v out "%s," \
            "${cpu}" \
            "${cpu_usage}%" \
            "${temp}" \
            "${fan}"
        printf -v out "%s%s" "${out}" "${uptime}"
        printf "%s\\n" "${out}"
        exit 0
    }

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
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

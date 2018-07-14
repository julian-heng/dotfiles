#!/usr/bin/env bash

function trim
(
    set -f
    set -- $*
    printf "%s" "$*"
    set +f
)

function get_cores
(
    for line in "${cpu_file[@]}"; do
        [[ "${line}" =~ ^processor ]] && \
            ((cores++))
    done
    printf "%s" "${cores}"
)

function get_cpu
(
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

    printf "%s" "${cpu}"
)

function get_load
(
    load_file="/proc/loadavg"
    read -r a b c _ _ < "${load_file}"
    load_avg="$a $b $c"
    printf "%s" "${load_avg}"
)

function get_cpu_usage
(
    awk_script='
        { sum += $3 }
        END {
            printf "%0.0f", sum / cores
        }'

    cpu_usage="$(awk -v cores="${cores:-1}" \
                     -v sum="0" "${awk_script}" <(ps aux))"
    printf "%s" "${cpu_usage}"
)

function get_temp
(
    temp_dir="/sys/class/hwmon"

    for file in "${temp_dir}"/*; do
        [[ "$(< "${file}/name")" =~ temp ]] && \
            temp_file="${file}/temp1_input"
    done

    [[ ! "${temp_file}" ]] && \
        return 1

    temp="$(($(< "${temp_file}") / 1000))"
    temp+="°C"
    printf "%s" "${temp}"
)

function get_fan
(
    fan_dir="/sys/devices/platform"

    shopt -s globstar
    for i in "${fan_dir}"/**/*; do
        [[ "$i" =~ 'fan1_input'$ ]] && {
            fan_file="$i"
            break
        }
    done
    shopt -u globstar

    fan="$(< "${fan_file}")"
    fan="${fan:-0} RPM"
    printf "%s" "${fan}"
)

function get_uptime
(
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
    printf "%s" "${uptime}"
)

function print_usage
(
    printf "%s\\n" "
Usage: $0 --option --option \"value\"

    Options:

    [--stdout]              Print to stdout
    [--disable \"func\"]      Disable a specific info
    [--show \"func\"]         Show a specific info
    [--cpu]                 Show cpu info
    [--load]                Show load average
    [--cpu-usage]           Show cpu usage
    [--temp]                Show cpu temperature (Celcius)
    [--fan]                 Show cpu fan speed
    [--uptime]              Show uptime
    [-h|--help]             Show this message

    Available functions:
        - cpu
        - load
        - cpu-usage
        - temp
        - fan
        - uptime

    If notify-send is not installed, then the script will
    print to standard output.
"
)

function get_args
{
    [[ ! "$*" ]] && \
        return 0

    while (($# > 0)); do
        case "$1" in
            "--stdout") stdout="true" ;;
            "--disable")
                for i in "$@"; do
                    case "$i" in
                        "--disable") continue ;;
                        "-"*) break ;;
                        *) unset -f "get_$i" ;;
                    esac
                done
            ;;

            "--show")
                for i in "$@"; do
                    case "$i" in
                        "--show") continue ;;
                        "-"*) break ;;
                        *) show+=("$i") ;;
                    esac
                done
            ;;

            "--cpu") show+=("cpu") ;;
            "--load") show+=("load") ;;
            "--cpu-usage") show+=("cpu_usage") ;;
            "--temp") show+=("temp") ;;
            "--fan") show+=("fan") ;;
            "--uptime") show+=("uptime") ;;
            "-h"|"--help") print_usage; exit ;;
        esac
        shift
    done

    [[ "${show[*]}" =~ cpu ]] && \
        show=("cores" "${show[@]}")
}

function main
(
    ! [[ "$-" =~ x ]] && \
        exec 2> /dev/null

    ! source "${BASH_SOURCE[0]//${0##*/}}format.sh" && \
        exit 1

    get_args "$@"

    ! type -p notify-send > /dev/null && \
        stdout="true"

    if [[ ! "${show[*]}" ]]; then
        cores="$(get_cores)"
        cpu="$(get_cpu)"
        load="$(get_load)"
        cpu_usage="$(get_cpu_usage)"
        temp="$(get_temp)"
        fan="$(get_fan)"
        uptime="$(get_uptime)"
    else
        for i in "${show[@]}"; do
            declare "$i=$(get_"$i")"
        done
    fi

    [[ ! "${stdout}" || "${cpu}" ]] && \
        title_parts+=("${cpu:-CPU}")

    [[ "${load}" ]] && \
        subtitle_parts+=("Load avg:" "${load}" "|")

    [[ "${cpu_usage}" ]] && \
        subtitle_parts+=("${cpu_usage}" "%" "|")

    [[ "${temp}" ]] && \
        subtitle_parts+=("${temp}" "|")

    [[ "${fan}" ]] && \
        subtitle_parts+=("${fan}")

    [[ "${uptime}" ]] && \
        message_parts+=("Uptime:" "${uptime}")

    title="$(format "${title_parts[@]}")"
    subtitle="$(format "${subtitle_parts[@]}")"
    message="$(format "${message_parts[@]}")"

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

mapfile -t cpu_file < "/proc/cpuinfo"
[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

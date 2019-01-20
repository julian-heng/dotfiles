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

get_cores()
{
    cores="0"
    case "${os}" in
        "MacOS")
            cores="$(sysctl -n hw.logicalcpu_max)"
        ;;

        "Linux")
            while read -r line; do
                [[ "${line}" =~ ^processor ]] && \
                    ((cores++))
            done < /proc/cpuinfo
        ;;
    esac

    cpu_info["cores"]="${cores}"
}

get_cpu()
{
    case "${os}" in
        "MacOS")
            cpu="$(sysctl -n machdep.cpu.brand_string)"
        ;;

        "Linux")
            while read -r line; do
                [[ "${line}" =~ 'model name' ]] && cpu="${line}"
                [[ "${cpu}" ]] && break
            done < /proc/cpuinfo

            shopt -s globstar
            for file in "/sys/devices/system/cpu/"**/*; do
                [[ "${file}" =~ "bios_limit|scaling_max|cpuinfo_max" ]] && \
                    speed_file="${file}"
                [[ "${speed_file}" ]] && break
            done
            shopt -u globstar

            [[ "${speed_file}" ]] && \
                printf -v speed "%.*f" "2" "$(div "$(< "${speed_file}")" 1000000)"
        ;;
    esac

    [[ ! "${cores}" ]] && get_cores

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
    cpu_info["cpu"]="${cpu}"
}

get_load()
{
    case "${os}" in
        "MacOS")
            read -r _ a b c _ < <(sysctl -n vm.loadavg)
        ;;

        "Linux")
            read -r a b c _ < /proc/loadavg
        ;;
    esac

    load_avg="$a $b $c"
    cpu_info["load"]="${load_avg}"
}

get_cpu_usage()
{
    awk_script='
        { sum += $3 }
        END {
            printf "%f", sum / cores
        }'

    cpu_usage="$(awk -v cores="${cores:-1}" \
                     -v sum="0" "${awk_script}" <(ps aux))"
    printf -v cpu_usage "%.*f" "1" "${cpu_usage}"
    cpu_info["cpu_usage"]="${cpu_usage}%"
}

get_temp()
{
    case "${os}" in
        "MacOS")
            type -p osx-cpu-temp 2>&1 > /dev/null && {
                while read -r line; do
                    [[ "${line}" =~ 'CPU' ]] && \
                        temp="${line#*:}"
                done < <(osx-cpu-temp -f -c)

                printf -v temp "%.*f" "1" "${temp/'°C'}"
            }
        ;;

        "Linux")
            for file in "/sys/class/hwmon/"*; do
                [[ -f "${file}/name" && "$(< "${file}/name")" =~ temp ]] && {
                    for i in "${file}/temp"*; do
                        [[ "$i" =~ '_input'$ ]] && \
                            temp_file="$i"
                        [[ "${temp_file}" ]] && break 2
                    done
                }
            done

            [[ "${temp_file}" ]] && \
                temp="$(($(< "${temp_file}") / 1000))"
        ;;
    esac
    cpu_info["temp"]="${temp}°C"
}

get_fan()
{
    case "${os}" in
        "MacOS")
            type -p osx-cpu-temp 2>&1 > /dev/null && {
                while read -r line; do
                    [[ "${line}" =~ 'Fan '[0-9] ]] && \
                        fan="${line/'Fan '}"
                done < <(osx-cpu-temp -f -c)

                fan="${fan/*at }"
                fan="${fan/ RPM*}"
            }
        ;;

        "Linux")
            shopt -s globstar
            for file in "/sys/devices/platform/"**/*; do
                [[ "${file}" =~ 'fan1_input'$ ]] && \
                    fan_files+=("${file}")
            done
            shopt -u globstar

            [[ "${fan_files[*]}" ]] && \
                for fan_file in "${fan_files[@]}"; do
                    fan="$(< "${fan_file}")"
                    ((fan != 0)) && break
                done
        ;;
    esac
    cpu_info["fan"]="${fan} RPM"
}

get_uptime()
{
    case "${os}" in
        "MacOS")
            boot="$(sysctl -n kern.boottime)"
            boot="${boot/'{ sec = '}"
            boot="${boot/,*}"
            secs="$(($(printf "%(%s)T" "-1") - boot))"
        ;;

        "Linux")
            read -r secs _ < "/proc/uptime"
            secs="${secs%.*}"
        ;;
    esac

    days="$((secs / 60 / 60 / 24))d "
    hours="$((secs / 60 / 60 % 24))h "
    mins="$((secs / 60 % 60))m "
    secs="$(((secs % 60) % 60))s"

    ((${days/d*} == 0)) && unset days
    ((${hours/h*} == 0)) && unset hours
    ((${mins/m*} == 0)) && unset mins
    ((${secs/s*} == 0)) && unset secs

    uptime="${days}${hours}${mins}${secs}"
    cpu_info["uptime"]="${uptime}"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") [[ ! "${out}" ]] && out="stdout" ;;
            "-r"|"--raw") [[ ! "${out}" ]] && out="raw" ;;
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
    declare -A cpu_info
    get_args "$@"
    get_os

    [[ ! "${func[*]}" ]] && \
        func=(
            "cores" "cpu" "load"
            "cpu_usage" "fan" "temp"
            "uptime"
        )

    for function in "${func[@]}"; do
        [[ "$(type -t "get_${function}")" == "function" ]] && \
            "get_${function}"
    done

    case "${out}" in
        "raw")
            raw="${cpu_info[${func[0]}]}"
            for function in "${func[@]:1}"; do
                raw="${raw},${cpu_info[${function}]}"
            done
            printf "%s\\n" "${raw}"
        ;;

        "string")
            for function in "${func[@]}"; do
                [[ "${cpu_info[${function}]}" ]] && \
                    printf "%s\\n" "${cpu_info[${function}]}"
            done
        ;;

        *)
            title_parts+=("${cpu_info["cpu"]:-CPU}")

            [[ "${cpu_info["load"]}" ]] && \
                subtitle_parts+=("Load avg:" "${cpu_info["load"]}")
            [[ "${cpu_info["cpu_usage"]}" ]] && \
                subtitle_parts+=("|" "${cpu_info["cpu_usage"]}")
            [[ "${cpu_info["temp"]}" ]] && \
                subtitle_parts+=("|" "${cpu_info["temp"]}")
            [[ "${cpu_info["fan"]}" ]] && \
                subtitle_parts+=("|" "${cpu_info["fan"]}")

            [[ "${cpu_info["uptime"]}" ]] && \
                message_parts+=("Uptime:" "${cpu_info["uptime"]}")

            notify
        ;;
    esac
}

main "$@"

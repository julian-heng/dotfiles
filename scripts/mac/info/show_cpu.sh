#!/usr/bin/env bash

check_apps()
{
    if ! type -p sysctl osascript 2>&1 > /dev/null; then
        return 1
    fi
}

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
        osa_script="display notification \"${message}\" \
                    with title \"${title}\" \
                    subtitle \"${subtitle}\""

        /usr/bin/env osascript <<< "${osa_script}"
    fi
}

get_cpu()
{
    cpu="${cpu_info[0]/@/(${cpu_info[1]}) @}"
    cpu="${cpu/(R)}"
    cpu="${cpu/(TM)}"
    cpu="${cpu/ CPU}"
}

get_load()
{
    load_avg="${cpu_info[2]}"
    load_avg="${load_avg/'{ '}"
    load_avg="${load_avg/' }'}"
}

get_cpu_usage()
{
    awk_script='
        { sum += $3 }
        END {
            printf "%0.0f", sum / cores
        }'
    cpu_usage="$(awk -v cores="${cpu_info[1]:-1}" \
                     -v sum="0" \
                     "${awk_script}" <(ps aux))"
    cpu_usage="$(trim "${cpu_usage}")"
}

get_uptime()
{
    boot="${cpu_info[3]/'{ sec = '}"
    boot="${boot/,*}"
    printf -v now "%(%s)T" "-1"
    seconds="$((now - boot))"

    days="$((seconds / 60 / 60 / 24))d "
    hours="$((seconds / 60 / 60 % 24))h "
    mins="$((seconds / 60 % 60))m "
    secs="$(((seconds % 60) % 60))s"

    ((${days/d*} == 0)) && unset days
    ((${hours/h*} == 0)) && unset hours
    ((${mins/m*} == 0)) && unset mins
    ((${secs/s} == 0)) && unset secs

    uptime="${days}${hours}${mins}${secs}"
}

print_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} --option

    Options:

    [--stdout]      Print to stdout
    [-h|--help]     Show this message
"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout")     stdout="true" ;;
            "-h"|"--help")  print_usage; exit ;;
        esac
        shift
    done
}

main()
{
    ! check_apps && exit 1
    get_args "$@"

    sysctl_args=(
        "machdep.cpu.brand_string"
        "hw.logicalcpu_max"
        "vm.loadavg"
        "kern.boottime"
    )

    mapfile -t cpu_info < <(sysctl -n ${sysctl_args[@]})
    get_cpu
    get_load
    get_cpu_usage
    #get_temp
    #get_fan
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
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

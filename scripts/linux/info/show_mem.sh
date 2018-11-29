#!/usr/bin/env bash

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

    if [[ "${out_mode}" == "stdout" ]] || ! type -p notify-send > /dev/null 2>&1; then
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

get_mem_info()
{
    awk_script='
        /MemTotal/ { total = used = $2}
        /Shmem/ { used += $2 }
        /MemFree|Buffers|Cached|SReclaimable/ {
            used -= $2
        }
        /SwapTotal/ { swap_total = $2 }
        /SwapFree/ { swap_used = swap_total - $2 }
        END {
            percent = (used / total) * 100
            used /= 1024
            total /= 1024
            swap_used /= 1024
            swap_total /= 1024

            printf "%0.0f %0.0f %0.0f %0.0f %0.0f", \
                percent, used, total, swap_used, swap_total
        }'

    read -r mem_percent \
            mem_used \
            mem_total \
            swap_used \
            swap_total \
            < <(awk "${awk_script}" "/proc/meminfo")
}

print_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} --option --option \"value\"

    Options:

    [--stdout]              Print to stdout
    [-r|--raw]              Print raw values delimited by commas
    [-h|--help]             Show this message

    If notify-send is not installed, then the script will
    print to standard output.
"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout")     out_mode="stdout" ;;
            "-r"|"--raw")   out_mode="raw" ;;
            "-h"|"--help")  print_usage; exit ;;
        esac
        shift
    done
}

main()
{
    get_args "$@"
    get_mem_info

    case "${out_mode}" in
        "stdout"|"")
            [[ "${mem_percent}" ]] && \
                title_parts+=("Memory" "(${mem_percent}%)")

            [[ "${mem_used}" ]] && \
                subtitle_parts+=("${mem_used}" "MiB")

            [[ "${mem_total}" ]] && \
                subtitle_parts+=("|" "${mem_total}" "MiB")

            [[ "${swap_used}" ]] && \
                message_parts+=("Swap:" "${swap_used}" "MiB")

            [[ "${swap_total}" ]] && \
                message_parts+=("|" "${swap_total}" "MiB")

            notify
        ;;

        "raw")
            printf -v out "%s," \
                "${mem_percent}%" \
                "${mem_used} MiB" \
                "${mem_total} MiB" \
                "${swap_used} MiB"
            printf -v out "%s%s" "${out}" "${swap_total} MiB"
            printf "%s\\n" "${out}"
        ;;
    esac
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

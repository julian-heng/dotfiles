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

function get_mem_info
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
    get_mem_info

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
)

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

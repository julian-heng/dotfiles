#!/usr/bin/env bash

function get_mem_total
(
    total="$(awk '/MemTotal/ { printf "%0.0f", $2 / 1024 }' "${mem_file}")"
    printf "%s" "${total}"
)

function get_mem_used
(
    awk_script='
        /MemTotal/ { used = $2 }
        /Shmem/ { used += $2 }
        /MemFree|Buffers|Cached|SReclaimable/ {
            used -= $2
        }
        END {
            printf "%0.0f", used / 1024
        }'
    used="$(awk "${awk_script}" "${mem_file}")"
    printf "%s" "${used}"
)

function get_mem_percent
(
    if [[ ! "$1" || ! "$2" ]]; then
        used="$(get_mem_used)"
        total="$(get_mem_total)"
    else
        used="$1"
        total="$2"
    fi

    percent="$(awk -v a="${used}" -v b="${total}" \
        'BEGIN { printf "%0.0f", (a / b) * 100 }')"
    printf "%s" "${percent}"
)

function get_swap_used
(
    awk_script='
        /SwapTotal/ { total = $2 }
        /SwapFree/ { used = total - $2 }
        END {
            printf "%0.0f", used / 1024
        }'
    used="$(awk "${awk_script}" "${mem_file}")"
    printf "%s" "${used}"
)

function get_swap_total
(
    total="$(awk '/SwapTotal/ { printf "%0.0f", $2 / 1024 }' "${mem_file}")"
    printf "%s" "${total}"
)

function get_mem_info
(
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

    awk "${awk_script}" "${mem_file}"
)

function print_usage
(
    printf "%s\\n" "
Usage: $0 --option --option \"value\"

    Options:

    [--stdout]              Print to stdout
    [--show \"func\"]         Show a specific info
    [--mem-percent]         Show percentage memory used
    [--mem-used]            Show memory used
    [--mem-total]           Show total memory
    [--swap-used]           Show swap used
    [--swap-total]          Show swap total
    [-h|--help]             Show this message

    Available functions:
        - mem_percent
        - mem_used
        - mem_total
        - swap_used
        - swap_total

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
            "--show")
                for i in "$@"; do
                    case "$i" in
                        "--show") continue ;;
                        "-"*) break ;;
                        *) show+=("$i") ;;
                    esac
                done
            ;;

            "--mem-percent") show+=("mem_percent") ;;
            "--mem-used") show+=("mem_used") ;;
            "--mem-total") show+=("mem_total") ;;
            "--swap-used") show+=("swap_used") ;;
            "--swap-total") show+=("swap_total") ;;
            "-h"|"--help") print_usage; exit ;;
        esac
        shift
    done
}

function main
(
    ! source "${BASH_SOURCE[0]//${0##*/}}format.sh" && \
        exit 1

    get_args "$@"

    ! type -p notify-send > /dev/null && \
        stdout="true"

    if [[ ! "${show[*]}" ]]; then
        read -r mem_percent \
                mem_used \
                mem_total \
                swap_used \
                swap_total \
                < <(get_mem_info)
    else
        for i in "${show[@]}"; do
            declare "$i=$(get_"$i")"
        done
    fi

    [[ "${mem_percent}" ]] && \
        title_parts+=("Memory" "(" "${mem_percent}" "%" ")")

    [[ "${mem_used}" ]] && \
        subtitle_parts+=("${mem_used}" "MiB" "|")

    [[ "${mem_total}" ]] && \
        subtitle_parts+=("${mem_total}" "MiB")

    [[ "${swap_used}" ]] && \
        message_parts+=("Swap:" "${swap_used}" "MiB" "|")

    [[ "${swap_total}" ]] && \
        message_parts+=("${swap_total}" "MiB")

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

mem_file="/proc/meminfo"
[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

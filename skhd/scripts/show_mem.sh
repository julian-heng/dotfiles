#!/usr/bin/env bash
# shellcheck disable=1004,1090

function trim_digits
{
    case "${1##*.}" in
        "00")   printf "%s" "${1/.*}" ;;
        *)      printf "%s" "$1" ;;
    esac
}

function get_mem_info
{
    mapfile -t mem_cache < <(vm_stat)
    mem_cache+=("$(sysctl vm.swapusage)")

    read -r mem_wired \
            mem_compressed \
            swap_total \
            swap_used \
            < <(awk '
                    /wired/ { a=$4 }
                    /occupied/ { b=$5 }
                    /vm/ { c=$4; d=$7 }
                    END {
                        printf "%s %s %s %s", \
                        a, b, c, d
                    }' < <(printf "%s\\n" "${mem_cache[@]}"))

    mem_total="$(($(sysctl -n hw.memsize) / 1024 ** 2))"
    mem_used="$(((${mem_wired//.} + ${mem_compressed//.}) * 4 / 1024))"
    mem_percent="$(awk \
                    -v a="${mem_total}" \
                    -v b="${mem_used}" \
                        'BEGIN {
                            percent = b / a * 100
                            printf "%0.0f", percent
                        }'
                    )"

    swap_total="$(trim_digits "${swap_total/M*}")"
    swap_used="$(trim_digits "${swap_used/M*}")"
}

function main
{
    source "${0%/*}/notify.sh"
    get_mem_info

    title="Memory (${mem_percent}%)"
    subtitle="${mem_used}MiB | ${mem_total}MiB"
    message="Swap: ${swap_used}MiB | ${swap_total}MiB"

    display_notification "${title:-}" "${subtitle:-}" "${message:-}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

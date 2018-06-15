#!/usr/bin/env bash
# shellcheck disable=1004,1090

function trim_digits
{
    case "${1##*.}" in
        "00")   printf "%s" "${1/.*}" ;;
        *)      printf "%s" "$1" ;;
    esac
}

function get_mem_total
{
    : $(($(sysctl -n hw.memsize) / 1024 ** 2))
    printf "%s" "${_}"
}

function get_mem_used
{
    : "$(awk '
        /wired/ {a = substr($4, 1, length($4)-1)}
        /occupied/ {b = substr($5, 1, length($5)-1)}
        END {printf "%0.2f", ((a + b) * 4) / 1024}' \
        < <(printf "%s\\n" "$@"))"
    printf "%s" "${_}"
}

function get_mem_percent
{
    : "$(awk -v a="$1" -v b="$2" \
            'BEGIN {printf "%0.2f", (a / b) * 100}')"
    printf "%s" "${_}"
}

function get_swap_used
{
    : "$(awk \
        '/vm/ { print $4 }' < <(printf "%s\\n" "$@"))"
    : "$(trim_digits "${_/M*}")"
    printf "%s" "${_}"
}

function get_swap_total
{
    : "$(awk \
        '/vm/ { print $7 }' < <(printf "%s\\n" "$@"))"
    : "$(trim_digits "${_/M*}")"
    printf "%s" "${_}"
}

function main
{
    ! { source "${BASH_SOURCE[0]//${0##*/}/}notify.sh" \
        && source "${BASH_SOURCE[0]//${0##*/}/}format.sh"; } \
            && exit 1

    mapfile -t mem_cache < <(vm_stat; sysctl vm.swapusage)

    mem_total="$(get_mem_total)"
    mem_used="$(get_mem_used "${mem_cache[@]}")"
    mem_percent="$(get_mem_percent "${mem_used}" "${mem_total}")"
    swap_used="$(get_swap_used "${mem_cache[@]}")"
    swap_total="$(get_swap_total "${mem_cache[@]}")"

    title_parts=(
        "Memory" "(" "${mem_percent}" "%" ")"
    )

    subtitle_parts=(
        "${mem_used}" "MiB" "|" "${mem_total}" "MiB"
    )

    message_parts=(
        "Swap:" "${swap_used}" "MiB" "|" "${swap_total}" "MiB"
    )

    title="$(format "${title_parts[@]}")"
    subtitle="$(format "${subtitle_parts[@]}")"
    message="$(format "${message_parts[@]}")"

    notify "${title:-}" "${subtitle:-}" "${message:-}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

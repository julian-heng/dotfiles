#!/usr/bin/env bash
# shellcheck disable=1004,1090

function check_apps
(
    if ! type -p vm_stat sysctl > /dev/null; then
        return 1
    fi
)

function trim_digits
(
    case "${1##*.}" in
        "00")   printf "%s" "${1/.*}" ;;
        *)      printf "%s" "$1" ;;
    esac
)

function get_mem_cache
(
    vm_stat; sysctl vm.swapusage hw.memsize
)

function get_mem_total
(
    : "$(awk \
        '/hw/ {printf "%0.0f", $2 / (1024 ^ 2)}' < <(printf "%s\\n" "$@"))"
    printf "%s" "${_}"
)

function get_mem_used
(
    : "$(awk '
        /wired/ {a = substr($4, 1, length($4)-1)}
        /occupied/ {b = substr($5, 1, length($5)-1)}
        END {printf "%0.0f", ((a + b) * 4) / 1024}' \
        < <(printf "%s\\n" "$@"))"
    printf "%s" "${_}"
)

function get_mem_percent
(
    if [[ ! "$1" && ! "$2" ]]; then
        cache="$(get_mem_cache)"
        used="$(get_mem_used "${cache}")"
        total="$(get_mem_total "${cache}")"
    else
        used="$1"
        total="$2"
    fi

    : "$(awk -v a="${used}" -v b="${total}" \
        'BEGIN {printf "%0.0f", (a / b) * 100}')"
    printf "%s" "${_}"
)

function get_swap_used
(
    : "$(awk \
        '/vm/ { print $4 }' < <(printf "%s\\n" "$@"))"
    : "$(trim_digits "${_/M*}")"
    printf "%s" "${_}"
)

function get_swap_total
(
    : "$(awk \
        '/vm/ { print $7 }' < <(printf "%s\\n" "$@"))"
    : "$(trim_digits "${_/M*}")"
    printf "%s" "${_}"
)

function get_mem_info
(
    read -r mem_percent \
            mem_used \
            mem_total \
            swap_used \
            swap_total \
            < <(awk '
                    /hw/ {total = $2 / (1024 ^ 2)}
                    /wired/ {a = substr($4, 1, length($4)-1)}
                    /occupied/ {b = substr($5, 1, length($5)-1)}
                    /vm/ {c = $4; d = $7}
                    END {
                        used = ((a + b) * 4) / 1024
                        printf "%0.0f %0.0f %0.0f %s %s", \
                            ((used / total) * 100), used, total, c, d
                    }' < <(get_mem_cache))

    swap_total="$(trim_digits "${swap_total/M*}")"
    swap_used="$(trim_digits "${swap_used/M*}")"

    printf "%s;%s;%s;%s;%s" \
        "${mem_percent}" \
        "${mem_used}" \
        "${mem_total}" \
        "${swap_used}" \
        "${swap_total}"
)

function main
(
    ! { source "${BASH_SOURCE[0]//${0##*/}}notify.sh" && \
        source "${BASH_SOURCE[0]//${0##*/}}format.sh"; } && \
            exit 1

    IFS=";"\
    read -r mem_percent \
            mem_used \
            mem_total \
            swap_used \
            swap_total \
            < <(get_mem_info)

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
)

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && \
    { check_apps && main "$@"; } || :

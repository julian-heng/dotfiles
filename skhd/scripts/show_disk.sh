#!/usr/bin/env bash
# shellcheck disable=1004,1090

function spacify
{
    : "${1//:/ }"
    : "${_:1}"
    printf "%s" "${_}"
}

function get_search
{
    local search="$1"
    local count="0"
    local match="false"

    local -a disk_cache
    mapfile -t disk_cache <<< "${@:2}"

    if [[ "${search}" ]]; then
        while [[ "${match}" != "true" ]] && ((count < ${#disk_cache[@]})); do
            if [[ "${disk_cache[${count}]}" == *"${search}"* ]]; then
                match="true"
                : "${disk_cache[${count}]%% *}"
            else
                ((count++))
            fi
        done
    else
        : "${disk_cache[1]}"
        : "${_%% *}"
    fi

    if [[ "${match}" == "true" ]]; then
        printf "%s" "${_}"
    else
        return 1
    fi
}

function get_df_output
{
    local df_line
    local -a disk_cache

    while read -r df_line; do
        [[ "${df_line}" != *"TimeMachine"* ]] && disk_cache+=("${df_line}")
    done < <(df -P -k)
    printf "%s\\n" "${disk_cache[@]}"
}

function get_diskutil_out
{
    local -a diskutil_out
    mapfile -t diskutil_out < <(diskutil info "$1")
    printf "%s\\n" "${diskutil_out[@]}"
}

function get_disk_device
{
    : "$(awk -v disk="$1" \
        '$0 ~ disk {print $1; exit}' < \
            <(printf "%s\\n" "${@:2}"))"
    printf "%s" "${_}"
}

function get_disk_capacity
{
    : "$(awk -v disk="$1" \
        '$0 ~ disk {printf "%0.2f", $2 / (1024 ^ 2); exit}' < \
            <(printf "%s\\n" "${@:2}"))"
    printf "%s" "${_}"
}

function get_disk_used
{
    : "$(awk -v disk="$1" \
        '$0 ~ disk {printf "%0.2f",  $3 / (1024 ^ 2); exit}' < \
            <(printf "%s\\n" "${@:2}"))"
    printf "%s" "${_}"
}

function get_disk_percent
{
    : "$(awk -v a="$1" -v b="$2" \
        'BEGIN {printf "%0.2f", (a / b) * 100}')"
    printf "%s" "${_}"
}

function get_disk_name
{
    : "$(awk '
        /Volume Name/ {
            for (i = 3; i <= NF; i++) {
                a = a":"$i
            }
        }
        END {
            print a
        }' < <(printf "%s\\n" "$@"))"
    : "$(spacify "${_}")"
    printf "%s" "${_}"
}

function get_disk_part
{
    : "$(awk '
        /File System Personality:/ {
            for (i = 4; i <= NF; i++) {
                a = a":"$i
            }
        }
        END {
            print a
        }' < <(printf "%s\\n" "$@"))"
    : "$(spacify "${_}")"
    printf "%s" "${_}"
}

function get_disk_mount
{
    : "$(awk '
        /Mount Point:/ {
            for (i = 3; i <= NF; i++) {
                a = a":"$i
            }
        }
        END {
            print a
        }' < <(printf "%s\\n" "$@"))"
    : "$(spacify "${_}")"
    printf "%s" "${_}"
}

function main
{
    ! { source "${BASH_SOURCE[0]//${0##*/}/}notify.sh" \
        && source "${BASH_SOURCE[0]//${0##*/}/}format.sh"; } \
            && exit 1

    disk_cache=("$(get_df_output "$@")")
    ! search="$(get_search "${@:-}" "${disk_cache[@]}")" && return 1
    diskutil_out=("$(get_diskutil_out "${search}")")

    disk_device="$(get_disk_device "${search}" "${disk_cache[@]}")"
    disk_capacity="$(get_disk_capacity "${search}" "${disk_cache[@]}")"
    disk_used="$(get_disk_used "${search}" "${disk_cache[@]}")"
    disk_percent="$(get_disk_percent "${disk_used}" "${disk_capacity}")"
    disk_name="$(get_disk_name "${diskutil_out[@]}")"
    disk_part="$(get_disk_part "${diskutil_out[@]}") "
    disk_mount="$(get_disk_mount "${diskutil_out[@]}")"

    [[ "${disk_device}" == "" \
    || "${disk_capacity}" == "0.00" \
    || "${disk_used}" == "0.00" \
    || "${disk_percent}" == "0.00" \
    ]] && exit 1

    title_parts=(
        "${disk_name:-Disk}" "(" "${disk_mount}" ")"
    )

    subtitle_parts=(
        "${disk_used}" "GiB" "|" "${disk_capacity}" "GiB"
        "(" "${disk_percent}" "%" ")"
    )

    message_parts=(
        "${disk_device}" "|" "${disk_part}"
    )

    title="$(format "${title_parts[@]}")"
    subtitle="$(format "${subtitle_parts[@]}")"
    message="$(format "${message_parts[@]}")"

    notify "${title:-}" "${subtitle:-}" "${message:-}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

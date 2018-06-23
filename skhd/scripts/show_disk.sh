#!/usr/bin/env bash
# shellcheck disable=1004,1090

function check_apps
(
    if ! type -p df diskutil > /dev/null; then
        return 1
    fi
)

function get_search
(
    search="$1"
    count="0"
    match="false"

    if [[ "${search}" ]]; then
        while [[ "${match}" != "true" ]] && read -r df_line; do
            if [[ "${df_line}" == *"${search}"* ]]; then
                match="true"
                : "${df_line%% *}"
            else
                ((count++))
            fi
        done < <(get_df_output)
    else
        match="true"
        : "$(get_df_output 1)"
        : "${_%% *}"
    fi

    if [[ "${match}" == "true" ]]; then
        printf "%s" "${_}"
    else
        return 1
    fi
)

function get_df_output
(
    while read -r line; do
        [[ "${line}" != *"TimeMachine"* ]] && \
            disk_cache+=("${line}")
    done < <(df)
    printf "%s\\n" "${disk_cache[@]:${1:-1}}"
)

function get_diskutil_out
(
    while read -r line; do
        printf "%s\\n" "${line}"
    done < <(diskutil info "$1")
)

function get_disk_device
(
    : "$(awk '/Device Node/ {print $3}' \
            < <(printf "%s\\n" "$@"))"
    printf "%s" "${_}"
)

function get_disk_name
(
    awk_script='
        /Volume Name/ {
            for (i = 3; i <= NF; i++) {
                if (a == "")
                    a = $i
                else
                    a = a":"$i
            }
        }
        END {
            print a
        }'
    : "$(awk "${awk_script}" < <(printf "%s\\n" "$@"))"
    : "${_//:/ }"
    printf "%s" "${_}"
)

function get_disk_part
(
    awk_script='
        /File System Personality:/ {
            for (i = 4; i <= NF; i++) {
                if (a == "")
                    a = $i
                else
                    a = a":"$i
            }
        }
        END {
            print a
    }'
    : "$(awk "${awk_script}" < <(printf "%s\\n" "$@"))"
    : "${_//:/ }"
    printf "%s" "${_}"
)

function get_disk_mount
(
    awk_script='
        /Mount Point:/ {
            for (i = 3; i <= NF; i++) {
                if (a == "")
                    a = $i
                else
                    a = a":"$i
            }
        }
        END {
            print a
        }'
    : "$(awk "${awk_script}" < <(printf "%s\\n" "$@"))"
    : "${_//:/ }"
    printf "%s" "${_}"
)

function get_disk_capacity
(
    if diskutil apfs > /dev/null; then
        awk_script='/Volume Total Space/ {printf "%0.2f", ($9 / (2 * (1024 ^ 2)))}'
    else
        awk_script='/Total Size/ {printf "%0.2f", ($8 / (2 * (1024 ^ 2)))}'
    fi
    : "$(awk "${awk_script}" < <(printf "%s\\n" "$@"))"
    printf "%s" "${_}"
)

function get_disk_used
(
    if diskutil apfs > /dev/null; then
        awk_script='/Volume Used Space/ {printf "%0.2f", ($9 / (2 * (1024 ^ 2)))}'
    else
        disk_capacity="${disk_capacity:=$(get_disk_capacity "$@")}"
        awk_script='/Volume Free Space/ {printf "%0.2f", total - ($9 / (2 * (1024 ^ 2)))}'
    fi
    : "$(awk -v total="${disk_capacity}" "${awk_script}" < <(printf "%s\\n" "$@"))"
    printf "%s" "${_}"
)

function get_disk_percent
(
    : "$(awk -v a="$1" -v b="$2" \
        'BEGIN {printf "%0.2f", (a / b) * 100}')"
    printf "%s" "${_}"
)

function get_disk_info
(
    if diskutil apfs > /dev/null; then
        awk_script='
            function strloop(a)
            {
                j = ""
                for (i = a; i <= NF; i++) {
                    if (j == "")
                        j = $i
                    else
                        j = j":"$i
                }
                return j
            }
            /Device Node/ {a = $3}
            /Volume Name/ {b = strloop(3)}
            /File System Personality:/ {c = strloop(4)}
            /Mount Point/ {d = strloop(3)}
            /Volume Total Space/ {e = $9 / (2 * (1024 ^ 2))}
            /Volume Used Space/ {f = $9 / (2 * (1024 ^ 2))}
            END {
                printf "%s %s %s %s %0.2f %0.2f %0.2f", \
                    a, b, c, d, \
                    e, f, ((f / e) * 100)
            }'
    else
        awk_script='
            function strloop(a)
            {
                j = ""
                for (i = a; i <= NF; i++) {
                    if (j == "")
                        j = $i
                    else
                        j = j":"$i
                }
                return j
            }
            /Device Node/ {a = $3}
            /Volume Name/ {b = strloop(3)}
            /File System Personality:/ {c = strloop(4)}
            /Mount Point/ {d = strloop(3)}
            /Total Size/ {e = $8 / (2 * (1024 ^ 2))}
            /Volume Free Space/ {f = e - ($9 / (2 * (1024 ^ 2)))}
            END {
                printf "%s %s %s %s %0.2f %0.2f %0.2f", \
                    a, b, c, d, \
                    e, f, ((f / e) * 100)
            }'
    fi

    ! search="$(get_search "${@:-}")" && return 1
    read -r disk_device \
            disk_name \
            disk_part \
            disk_mount \
            disk_capacity \
            disk_used \
            disk_percent \
            < <(awk "${awk_script}" < <(get_diskutil_out "${search}"))

    disk_name="${disk_name//:/ }"
    disk_part="${disk_part//:/ }"
    disk_mount="${disk_mount//:/ }"

    printf "%s;%s;%s;%s;%s;%s;%s" \
        "${disk_device}" \
        "${disk_name}" \
        "${disk_part}" \
        "${disk_mount}" \
        "${disk_capacity}" \
        "${disk_used}" \
        "${disk_percent}"
)

function main
(
    ! { source "${BASH_SOURCE[0]//${0##*/}}notify.sh" && \
        source "${BASH_SOURCE[0]//${0##*/}}format.sh"; } && \
            exit 1

    IFS=";" \
    read -r disk_device \
            disk_name \
            disk_part \
            disk_mount \
            disk_capacity \
            disk_used \
            disk_percent \
            < <(get_disk_info "$@")

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
)

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && \
    { check_apps && main "$@"; } || :

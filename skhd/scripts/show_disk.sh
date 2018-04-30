#!/usr/bin/env bash

function spacify
{
    string="$1"
    string="${string//:/ }"
    string="${string:1}"
    printf "%s" "${string}"
}

function get_df_output
{
    mapfile -t df_out < <(df -P -k)

    for i in "${df_out[@]}"; do
        [[ "${i}" != *"TimeMachine"* ]] && disk_cache+=("${i}")
    done

    if [[ "${1}" ]]; then
        search="${1}"
        for i in "${disk_cache[@]}"; do
            if [[ "${i}" == *"${search}"* ]]; then
                search="${i%% *}"
                match="True"
                break
            fi
        done
        [[ -z "${match}" ]] && exit 1
    else
        default_disk="${df_out[1]}"
        default_disk="${default_disk%% *}"
        search="${default_disk}"
    fi

    [[ ! "${search}" ]] && search="/dev/disk1s1"
}

function get_disk
{
    get_df_output "$@"
    mapfile -t diskutil_out < <(diskutil info "${search}")

    read -r disk_device \
            disk_capacity \
            disk_used \
            disk_percent \
            < <(awk -v disk="${search}" \
                    '$0 ~ disk { 
                        a = $1
                        b = $2 / (1024 ^ 2)
                        c = $3 / (1024 ^ 2)
                        d = c / b * 100
                    }
                    END {
                        printf "%s %0.2f %0.2f %0.2f", \
                        a, b, c, d
                    }' < <(printf "%s\\n" "${disk_cache[@]}"))

    read -r disk_name \
            disk_part \
            disk_mount \
            < <(awk '
                    /Volume Name/ {
                        a = ""
                        for(i = 3; i <= NF; i++) {
                            a = a":"$i
                        }
                    }
                    /File System Personality:/ {
                        b = ""
                        for(i = 4; i <= NF; i++) {
                            b = b":"$i
                        }
                    }
                    /Mount Point:/ {
                        c = ""
                        for(i = 3; i <= NF; i++) {
                            c = c":"$i
                        }
                    }
                    END {
                        printf "%s %s %s", a, b, c
                    }' < <(printf "%s\\n" "${diskutil_out[@]}"))

    disk_name="$(spacify "${disk_name}")"
    disk_part="$(spacify "${disk_part}")"
    disk_mount="$(spacify "${disk_mount}")"

    disk_part=" | ${disk_part}"
}

function main
{
    source "${0%/*}/notify.sh"
    
    get_disk "$@"

    title="${disk_name:-Disk} (${disk_mount})"
    subtitle="${disk_used}GiB | ${disk_capacity}GiB (${disk_percent}%)"
    message="${disk_device}${disk_part}"

    display_notification "${title:-}" "${subtitle:-}" "${message:-}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

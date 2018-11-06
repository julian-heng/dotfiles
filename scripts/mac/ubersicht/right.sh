#!/usr/bin/env bash

options()
{
    : "${disk:=/dev/disk1s1}"
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

percent()
{
    printf "%s" "$((200 * $1 / $2 % 2 + 100 * $1 / $2))"
}

get_cpu_load()
{
    load_avg="${sysctl_out[0]}"
    load_avg="${load_avg/'{ '}"
    load_avg="${load_avg/' }'}"
}

get_fan_temp()
{
    temp_path="/usr/local/bin/osx-cpu-temp"
    type -p "${temp_path}" 2>&1 > /dev/null && {
        while read -r line; do
            case "${line}" in
                "CPU"*)         temp="${line#*:}" ;;
                "Fan "[0-9]*)   fan="${line/'Fan '}" ;;
            esac
        done < <("${temp_path}" -f -c)

        printf -v temp "%.*f" "0" "${temp/'°C'}"
        fan="${fan/*at}"
        fan="${fan/RPM*}"
        fan="$(trim "${fan}")"
    }
}

get_mem_info()
{
    while IFS=":" read a b; do
        case "$a" in
            *" wired"*)     wired="${b//.}" ;;
            *" active"*)    active="${b//.}" ;;
            *" occupied"*)  occupied="${b//.}" ;;
        esac
    done < <(vm_stat)

    mem_used="$(((wired + active + occupied) * 4 * 1024))"
    mem_percent="$(percent "${mem_used}" "${sysctl_out[1]}")"
}

get_disk()
{
    [[ ! "${disk}" ]] && \
        return 1

    while read -r df_line && [[ ! "${df_line}" =~ ${disk} ]]; do
        :
    done < <(df -P -k)

    read -ra disk_info <<< "${df_line}"
    disk_percent="$(percent "${disk_info[2]}" "${disk_info[1]}")"
    disk="${disk//\/dev\//}"
}

get_wifi()
{
    while read -r a b && [[ "$a" != "SSID:" ]]; do
        :
    done < <(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport --getinfo)

    wifi_name="$b"
    [[ ! "${wifi_name}" ]] && \
        wifi_name="Not Connected"
}

get_bat_info()
{
    awk_script='
        /id=/ { percent = $3; time = $5 }
        END {
            printf "%s %s", percent, time
        }'

    read -r bat_percent \
            bat_time \
            < <(awk "${awk_script}" <(pmset -g batt))

    bat_percent="${bat_percent//%;/}"
    bat_info="${bat_percent}%"

    [[ "${bat_time}" != "0:00" && "${bat_time}" != "(no" ]] && \
        bat_info+=" | ${bat_time}"
}

get_date_time()
{
    printf -v date "%(%a, %d %h)T" "-1"
    printf -v time "%(%H:%M)T" "-1"
}

main()
{
    options

    sys_args=(
        "vm.loadavg"
        "hw.memsize"
    )

    mapfile -t sysctl_out < <(sysctl -n "${sys_args[@]}")
    mapfile -t bat_out < <(pmset -g batt)

    get_cpu_load
    get_fan_temp
    get_mem_info
    get_disk
    get_wifi
    get_bat_info
    get_date_time

    [[ "${fan}" ]] && \
        cpu_str+=" | ${fan} RPM"

    [[ "${temp}" ]] && \
        cpu_str+=" | ${temp}°C"

    cpu_str+=" | ${load_avg}"

    [[ "${cpu_str:0:2}" == " |" ]] && \
        cpu_str="${cpu_str##' |'}"

    printf -v out "[ %s ] " \
        "${cpu_str}" \
        "Mem: ${mem_percent}%" \
        "${disk:-Disk}: ${disk_percent}%" \
        "${wifi_name}" \
        "Bat: ${bat_info}" \
        "${date} | ${time}"

    out="$(trim "${out#\/}")"
    printf "%s" "${out}"
}

main

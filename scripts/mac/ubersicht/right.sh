#!/usr/bin/env bash

trim()
{
    [[ "$*" ]] && {
        set -f
        set -- $*
        printf "%s" "$*"
        set +f
    }
}

trim_digits()
{
    case "${1##*.}" in
        "00")   printf "%s" "${1/.*}" ;;
        *)      printf "%s" "$1" ;;
    esac
}

get_cpu_load()
{
    load_avg="$(sysctl -n vm.loadavg)"
    load_avg="${load_avg/'{ '}"
    load_avg="${load_avg/' }'}"
}

get_fan_temp()
{
    temp_path="/usr/local/bin/osx-cpu-temp"
    type -p "${temp_path}" 2>&1 > /dev/null && {
        awk_script='
            /CPU/ { a = $2 }
            /Fan [0-9]/ { b = $2 }
            END {
                printf "%s %s", a, b
            }'
        read -r temp \
                fan \
                < <(awk "${awk_script}" <("${temp_path}" -f -c))
    }
}

get_mem_info()
{
    awk_script='
        /hw/ { total = $2 / (1024 ^ 3) }
        /wired/ { a = substr($4, 1, length($4) - 1) }
        /active/ { b = substr($3, 1, length($3) - 1) }
        /occupied/ { c = substr($5, 1, length($5) - 1) }
        END {
        used = ((a + b + c) * 4) / (1024 ^ 2)
            printf "%0.2f %0.2f", used, total
        }'

    read -r mem_used \
            mem_total \
            < <(awk "${awk_script}" < <(vm_stat; sysctl vm.swapusage hw.memsize))

    mem_used="$(trim_digits "${mem_used}")"
    mem_total="$(trim_digits "${mem_total}")"
}

get_wifi()
{
    awk_script='
        /SSID:/ { name = $2 }
        END {
            printf "%s", name
        }'

    wifi_name="$(awk -F":" "${awk_script}" \
        <(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport --getinfo))"
    wifi_name="$(trim "${wifi_name}")"
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
    get_cpu_load
    get_fan_temp
    get_mem_info
    get_wifi
    get_bat_info
    get_date_time

    [[ "${fan}" ]] && \
        cpu_str+=" | ${fan} RPM"

    [[ "${temp}" ]] && \
        cpu_str+=" | ${temp}"

    cpu_str+=" | ${load_avg}"

    [[ "${cpu_str:0:2}" == " |" ]] && \
        cpu_str="${cpu_str##' |'}"

    printf -v out "[ %s ] " \
        "${cpu_str}" \
        "${mem_used} GiB | ${mem_total} GiB" \
        "${wifi_name}" \
        "${bat_info}" \
        "${date} | ${time}"

    out="$(trim "${out#\/}")"
    printf "%s" "${out}"
}

main

#!/usr/bin/env bash

function main
{
    function convert_mem
    {
        awk -v a="$1" 'BEGIN { b = a / 1024; printf "%0.2f", b }'
    }

    script_dir="${0%/*}"

    source "${script_dir}/show_bat.sh"
    source "${script_dir}/show_cpu.sh"
    source "${script_dir}/show_disk.sh"
    source "${script_dir}/show_mem.sh"
    source "${script_dir}/notify.sh"

    printf -v current_time "%(%H:%M)T" -1
    printf -v current_date "%(%a %d %h)T" -1

    case "$1" in
        "all")
            get_bat_info
            get_mem_info
            get_disk
            cpu_usage="$(get_cpu_usage)"

            temp="$(get_temp)"

            mem_used="$(trim_digits "$(convert_mem "${mem_used}")")"
            mem_total="$(trim_digits "$(convert_mem "${mem_total}")")"

            disk_used="$(trim_digits "${disk_used}")"
            disk_capacity="$(trim_digits "${disk_capacity}")"

            title="${current_date} | ${current_time}"
            subtitle="CPU: ${cpu_usage} (${temp}) | Mem: ${mem_used}GiB / ${mem_total}GiB"
            message="Bat: ${bat_percent} | Disk: ${disk_used}GiB / ${disk_capacity}GiB (${disk_percent}%)"
        ;;

        "simple")
            get_bat_info
            get_mem_info
            get_disk
            cpu_usage="$(get_cpu_usage)"

            title="${current_date} | ${current_time}"
            subtitle="CPU: ${cpu_usage} | Mem: ${mem_percent}% | Disk: ${disk_percent}%"
            message="Battery: ${bat_percent}"
        ;;

        "")
          title="${current_date} | ${current_time}"  
        ;;
    esac

    display_notification "${title:-}" "${subtitle:-}" "${message:-}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

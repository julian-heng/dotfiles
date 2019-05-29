#!/usr/bin/env bash

get_window_size()
{
    mapfile -t sizes < <(tmux list-windows -F '#{window_width}')
    window_size="${sizes[0]}"
}

get_status_length()
{
    # Assuming 3 characters in between every entry
    status_length="2"
    while (($# > 0)); do
        ((status_length += ${#1}))
        shift
    done

    printf "%d" "${status_length}"
}

main()
{
    get_window_size

    script_dir="$(type -p show_cpu)"
    script_dir="${script_dir%/*}"
    script_dir="${script_dir:-${HOME}/.dotfiles/scripts/info}"

    mapfile -t cpu_info < <(bash "-$-" "${script_dir}/show_cpu" load temp)
    mapfile -t mem_info < <(bash "-$-" "${script_dir}/show_mem" --prefix GiB --round 2 mem_used mem_percent)
    mapfile -t disk_info < <(bash "-$-" "${script_dir}/show_disk" --short-device disk_device disk_used disk_percent)

    mem_info[1]="${mem_info[1]/'%'}"
    disk_info[2]="${disk_info[2]/'%'}"

    if (($(get_status_length "${cpu_info[@]}" "${mem_info[@]}" "${disk_info[@]}") < (window_size / 2))); then
        printf -v cpu_out "| %s " "${cpu_info[@]}"
        printf -v mem_out "| Mem: %s (%.*f%%) " "${mem_info[0]}" "0" "${mem_info[1]}"
        printf -v disk_out "| %s: %s (%.*f%%) " "${disk_info[0]}" "${disk_info[1]}" "0" "${disk_info[2]}"
    else
        printf -v cpu_out "| %s " "${cpu_info[0]%% *}" "${cpu_info[@]:1}"
        printf -v mem_out "| Mem: %.*f%% " "0" "${mem_info[1]}"
        printf -v disk_out "| Disk: %.*f%% " "0" "${disk_info[2]}"
    fi

    printf -v time_out "| %(%a, %d %h)T | %(%H:%M)T |" "-1"
    time_out="${time_out:-$(date '+| %a, %d %h | %H:%M |')}"

    printf "%s" "${cpu_out}" "${mem_out}" "${disk_out}" "${time_out}"
}

main

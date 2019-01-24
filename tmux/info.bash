#!/usr/bin/env bash

main()
{
    script_dir="${HOME}/.dotfiles/scripts/info"

    mapfile -t cpu < <(bash "${script_dir}/show_cpu.bash" load temp fan)
    mapfile -t disk < <(bash "${script_dir}/show_disk.bash" disk_device disk_percent)
    mem="$(bash "${script_dir}/show_mem.bash" mem_percent)"
    bat="$(bash "${script_dir}/show_bat.bash" bat_percent 2> /dev/null)"

    user_host="${USER}@${HOSTNAME}"

    [[ "${cpu[0]}" ]] && cpu_out="${cpu_out}${cpu[0]}"
    [[ "${cpu[1]}" ]] && cpu_out="${cpu_out} | ${cpu[1]}"
    [[ "${cpu[2]}" ]] && cpu_out="${cpu_out} | ${cpu[2]}"

    [[ "${mem}" ]] && mem_out="Mem: ${mem}"

    [[ "${disk[0]}" ]] && disk_out="${disk[0]##*/}"
    [[ "${disk[1]}" ]] && \
        printf -v disk_out "%s: %.*f%%" "${disk_out}" "0" "${disk[1]/'%'}"

    [[ "${bat}" ]] && bat_out="Bat: ${bat}"

    printf -v time_out "%(%a, %d %h)T | %(%H:%M)T" "-1"

    [[ "${user_host}" ]] && printf "| %s " "${user_host}"
    [[ "${cpu_out}" ]]   && printf "| %s " "${cpu_out}"
    [[ "${mem_out}" ]]   && printf "| %s " "${mem_out}"
    [[ "${disk_out}" ]]  && printf "| %s " "${disk_out}"
    [[ "${bat_out}" ]]   && printf "| %s " "${bat_out}"
    [[ "${time_out}" ]]  && printf "| %s " "${time_out}"

    printf "|"
}

main

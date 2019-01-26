#!/usr/bin/env bash

main()
{
    script_dir="${HOME}/.dotfiles/scripts/info"

    mapfile -t cpu < <(bash "${script_dir}/show_cpu.bash" load temp)
    mapfile -t mem < <(bash "${script_dir}/show_mem.bash" mem_used mem_total)

    mem[0]="${mem[0]/' MiB'}"
    mem[1]="${mem[1]/' MiB'}"

    printf -v mem[0] "%.*f" "2" "${mem[0]:0:(${#mem[0]} - 3)}.${mem[0]:(-3)}"
    printf -v mem[1] "%.*f" "2" "${mem[1]:0:(${#mem[1]} - 3)}.${mem[1]:(-3)}"

    [[ "${cpu[0]}" ]] && cpu_out="${cpu_out}${cpu[0]}"
    [[ "${cpu[1]}" ]] && cpu_out="${cpu_out} | ${cpu[1]}"
    [[ "${mem[*]}" ]] && mem_out="${mem[0]} GiB / ${mem[1]} GiB"

    printf -v time_out "%(%a, %d %h)T | %(%H:%M)T" "-1"

    [[ "${cpu_out}" ]]   && printf "| %s " "${cpu_out}"
    [[ "${mem_out}" ]]   && printf "| %s " "${mem_out}"
    [[ "${time_out}" ]]  && printf "| %s " "${time_out}"

    printf "|"
}

main

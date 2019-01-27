#!/usr/bin/env bash

main()
{
    script_dir="${HOME}/.dotfiles/scripts/info"

    mapfile -t cpu < <(bash "${script_dir}/show_cpu.bash" load temp)
    mapfile -t mem < <(bash "${script_dir}/show_mem.bash" mem_used mem_total)

    mem[0]="${mem[0]/' MiB'}"
    mem[1]="${mem[1]/' MiB'}"

    awk_script='BEGIN { printf "%f %f", a / 1024, b / 1024 }'

    read -r mem[0] \
            mem[1] \
            < <(awk -v a="${mem[0]}" -v b="${mem[1]}" "${awk_script}")

    printf -v mem[0] "%.*f" "2" "${mem[0]}"
    printf -v mem[1] "%.*f" "2" "${mem[1]}"

    [[ "${cpu[0]}" ]] && cpu_out="${cpu_out}${cpu[0]}"
    [[ "${cpu[1]}" ]] && cpu_out="${cpu_out} | ${cpu[1]}"
    [[ "${mem[*]}" ]] && mem_out="${mem[0]/'.00'} GiB / ${mem[1]/'.00'} GiB"

    printf -v time_out "%(%a, %d %h)T | %(%H:%M)T" "-1"

    [[ "${cpu_out}" ]]   && printf "| %s " "${cpu_out}"
    [[ "${mem_out}" ]]   && printf "| %s " "${mem_out}"
    [[ "${time_out}" ]]  && printf "| %s " "${time_out}"

    printf "|"
}

main

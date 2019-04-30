#!/usr/bin/env bash

main()
{
    script_dir="$(type -p show_cpu)"
    script_dir="${script_dir%/*}"
    script_dir="${script_dir:-${HOME}/.dotfiles/scripts/info}"

    while read -r info; do
        cpu_out+="| ${info} "
    done < <(bash "-$-" "${script_dir}/show_cpu" load temp)

    while read -r info; do
        info="$(awk -v a="${info}" 'BEGIN { printf "%0.2f", a / 1024 }')"
        [[ ! "${mem_out}" ]] && \
            mem_out="| ${info/'.00'} " || mem_out+="/ ${info/'.00'} "
        mem_out+="GiB "
    done < <(bash "-$-" "${script_dir}/show_mem" mem_used mem_total)

    printf -v time_out "| %(%a, %d %h)T | %(%H:%M)T |" "-1"
    time_out="${time_out:-$(date '+| %a, %d %h | %H:%M |')}"

    [[ "${cpu_out}" ]]  && printf "%s" "${cpu_out}"
    [[ "${mem_out}" ]]  && printf "%s" "${mem_out}"
    [[ "${time_out}" ]] && printf "%s" "${time_out}"
}

main

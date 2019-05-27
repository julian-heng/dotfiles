#!/usr/bin/env bash

main()
{
    bash_exec="/usr/local/bin/bash"
    script_dir="${HOME}/.dotfiles/scripts/info"

    vol="$(/usr/bin/osascript -e 'output volume of (get volume settings)')"
    while [[ ! "${bright}" ]] && read -r line; do
        [[ "${line}" =~ IODisplayParameters ]] && {
            bright="${line//\"}"
            bright="${bright##*',brightness={'}"
            bright="${bright%%"},"*}"
            IFS="=," read -r _ max _ _ _ val <<< "${bright}"
            bright="$(awk -v a="${val}" -v b="${max}" 'BEGIN { printf "%d", (a / b) * 100}')"
        }
    done < <(ioreg -rc AppleBacklightDisplay)

    printf "[ %s ] " "$("${bash_exec}" "-$-" "${script_dir}/show_cpu" --format '{load}{temp? | {}}{fan? | {}}')"
    printf "[ Mem: %s ] " "$("${bash_exec}" "-$-" "${script_dir}/show_mem" --format '{mem_percent}')"

    mapfile -t disk < <("${bash_exec}" "-$-" "${script_dir}/show_disk" disk_device disk_percent)
    printf "[ %s: %.*f%% ] " "${disk[0]##*/}" "0" "${disk[1]/'%'}"

    printf "[ Bat: %s ] " "$("${bash_exec}" "-$-" "${script_dir}/show_bat" --format '{bat_percent}{bat_time? | {}}')"
    printf "[ %s ] " "$("${bash_exec}" "-$-" "${script_dir}/show_net" network_ssid)"
    printf "[ vol: %s%% | scr: %s%% ] " "${vol}" "${bright}"
    printf "[ %(%a, %d %h)T | %(%H:%M)T ]" "-1"
}

main

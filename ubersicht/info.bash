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

    "${bash_exec}" "-$-" "${script_dir}/show_cpu" --format '[ {load}{temp? | {}}{fan? | {}} ] '
    "${bash_exec}" "-$-" "${script_dir}/show_mem" --format '[ Mem: {mem_percent} ] '
    "${bash_exec}" "-$-" "${script_dir}/show_disk" --short-device --format '[ {disk_device}: {disk_percent}% ] '
    "${bash_exec}" "-$-" "${script_dir}/show_bat" --format '[ Bat: {bat_percent}{bat_time? | {}} ] '
    "${bash_exec}" "-$-" "${script_dir}/show_net" --format '[ {network_ssid} ] '
    printf "[ vol: %s%% | scr: %s%% ] " "${vol}" "${bright}"
    printf "[ %(%a, %d %h)T | %(%H:%M)T ]" "-1"
}

main

#!/usr/bin/env bash

main()
{
    bash_exec="/usr/local/bin/bash"
    script_dir="${HOME}/.dotfiles/scripts/info"

    mapfile -t cpu < <("${bash_exec}" "${script_dir}/show_cpu" load temp fan)
    mem="$("${bash_exec}" "${script_dir}/show_mem" mem_percent)"
    mapfile -t disk < <("${bash_exec}" "${script_dir}/show_disk" disk_device disk_percent)
    mapfile -t bat < <("${bash_exec}" "${script_dir}/show_bat" bat_percent bat_time)
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

    wifi_name="$("${bash_exec}" "${script_dir}/show_net" network_ssid)"
    [[ ! "${wifi_name}" ]] && \
        wifi_name="Not Connected"

    printf -v cpu_out "[ %s | %s | %s ]" "${cpu[@]}"
    printf -v mem_out "[ Mem: %s ]" "${mem}"
    printf -v disk_out "[ %s: %.*f%% ]" "${disk[0]##*/}" "0" "${disk[1]/'%'}"
    printf -v wifi_out "[ %s ]" "${wifi_name}"

    if [[ "${bat[1]}" == "0h 0m 0s" ]]; then
        printf -v bat_out "[ Bat: %s ]" "${bat[0]}"
    else
        printf -v bat_out "[ Bat: %s | %s ]" "${bat[@]}"
    fi

    printf -v vol_bright_out "[ vol: %s%% | scr: %s%% ]" "${vol}" "${bright}"
    printf -v time_out "[ %(%a, %d %h)T | %(%H:%M)T ]" "-1"

    printf "%s " \
        "${cpu_out}" \
        "${mem_out}" \
        "${disk_out}" \
        "${bat_out}" \
        "${wifi_out}" \
        "${vol_bright_out}" \
        "${time_out}"
}

main

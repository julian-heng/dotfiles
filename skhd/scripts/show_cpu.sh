#!/usr/bin/env bash
# shellcheck disable=1090,2194

function strip
{
    case "$2" in
        "0")    unset "$1" ;;
        *)      printf "%s" "$2${1:0:1} " ;;
    esac
}

function get_cpu
{
    cpu="$(sysctl -n machdep.cpu.brand_string)"
    cpu="${cpu/@/(${cores}) @}"
    printf "%s" "${cpu}"
}

function get_load
{
    load="$(sysctl -n vm.loadavg)"
    load="${load/' }'}"
    load="${load/'{ '}"
    printf "%s" "${load}"
}

function get_cpu_usage
{
    cpu_usage="$(awk 'BEGIN {sum=0} {sum+=$3}; END {print sum}' < <(ps aux))"
    cpu_usage="$((${cpu_usage/\.*} / ${cores:-1}))%"
    printf "%s" "${cpu_usage}"
}

function get_temp
{
    temp="$(osx-cpu-temp)"
    printf "%s" "${temp}"
}

function get_fan_speed
{
    fan="$(awk 'NR==2{print; exit}' < <(istats fan --value-only))"
    fan="${fan// } RPM"
    printf "%s" "${fan:-0 RPM}"
}

function get_uptime
{
    boot="$(sysctl -n kern.boottime)"
    boot="${boot/'{ sec = '}"
    boot="${boot/,*}"
    printf -v now "%(%s)T" -1
    seconds="$((now - boot))"

    days="$((seconds / 60 / 60 / 24))"
    hours="$((seconds / 60 / 60 % 24))"
    mins="$((seconds / 60 % 60))"
    secs="$((seconds % 60 % 60 % 24))"

    days="$(strip days ${days})"
    hours="$(strip hours ${hours})"
    mins="$(strip mins ${mins})"
    secs="$(strip secs ${secs})"
    uptime="${days:-}${hours:-}${mins:-}${secs// }"

    printf "%s" "${uptime}"
}

function main
{
    source "${0%/*}/notify.sh"
    cores="$(sysctl -n hw.logicalcpu_max)"

    cpu="$(get_cpu)"
    load="$(get_load)"
    cpu_usage="$(get_cpu_usage)"
    temp="$(get_temp)"
    fan="$(get_fan_speed)"
    uptime="$(get_uptime)"

    title="${cpu}"
    subtitle="Load avg: ${load} | ${cpu_usage} | ${temp} | ${fan}"
    message="Uptime: ${uptime}"

    case "1" in
        "$((${#subtitle} >= 50))")    subtitle="${subtitle/ avg/}" ;&
        "$((${#subtitle} >= 50))")    subtitle="${subtitle/Load: /}" ;;
    esac

    display_notification "${title:-}" "${subtitle:-}" "${message:-}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

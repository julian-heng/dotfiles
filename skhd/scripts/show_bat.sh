#!/usr/bin/env bash
# shellcheck disable=1004,1090

function get_bat_info
{
    mapfile -t bat_cache < <(pmset -g batt)
    bat_cache+=("$(system_profiler SPPowerDataType)")

    read -r bat_state \
            bat_percent \
            bat_time \
            bat_cycles \
            bat_condition \
            < <(awk '
                    /drawing/ { a=$4 }
                    /id=/ { b=$3; c=$5 }
                    /Cycle Count/ { d=$3 }
                    /Condition/ { e=$2 }
                    END { 
                        printf "%s %s %s %s %s", \
                        a, b, c, d, e 
                    }' < <(printf "%s\\n" "${bat_cache[@]}"))

    bat_percent="${bat_percent//;}"

    bat_state="${bat_state//\'/}"

    case "${bat_time}" in
        "(no"|"charge;") bat_time="Unknown" ;;
        *) bat_time="${bat_time} remaining" ;;
    esac

    [[ "${bat_time}" == "0:00 remaining" \
    && "${bat_state}" == "AC" ]] \
        && bat_time="Fully charged"
}

function main
{
    source "${0%/*}/notify.sh"
    get_bat_info

    title="Battery (${bat_percent})"
    subtitle="${bat_time} | ${bat_condition} | ${bat_cycles} cycles"
    message="Source: ${bat_state}"
    
    display_notification "${title:-}" "${subtitle:-}" "${message:-}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

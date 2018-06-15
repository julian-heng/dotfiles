#!/usr/bin/env bash
# shellcheck disable=1004,1090

function get_bat_state
{
    : "$(awk '/drawing/ {print $4}' < <(printf "%s\n" "${bat_cache[@]}"))"
    : "${_//\'}"
    printf "%s" "${_}"
}

function get_bat_percent
{
    : "$(awk '/id=/ {print $3}' < <(printf "%s\n" "${bat_cache[@]}"))"
    : ${_//;}
    printf "%s" "${_}"
}

function get_bat_time
{
    : "$(awk '/id=/ {print $5}' < <(printf "%s\n" "${bat_cache[@]}"))"
    if [[ "${_}" =~ ^(\(no|charge;)$ ]]; then
        : "Unknown"
    elif [[ "${_}" == "0:00"* && "${bat_state}" == "AC" ]]; then
        : "Fully Charged"
    else
        : "${_} remaining"
    fi
    printf "%s" "${_}"
}

function get_bat_cycles
{
    : "$(awk '/Cycle Count/ {print $3}' < <(printf "%s\n" "${bat_cache[@]}"))"
    printf "%s" "${_}"
}

function get_bat_condition
{
    : "$(awk '/Condition/ {print $2}' < <(printf "%s\n" "${bat_cache[@]}"))"
    printf "%s" "${_}"
}

function main
{
    ! { source "${BASH_SOURCE[0]//${0##*/}/}notify.sh" \
        && source "${BASH_SOURCE[0]//${0##*/}/}format.sh"; } \
            && exit 1

    mapfile -t bat_cache < <(pmset -g batt; system_profiler SPPowerDataType)

    bat_state="$(get_bat_state)"
    bat_percent="$(get_bat_percent)"
    bat_time="$(get_bat_time)"
    bat_cycles="$(get_bat_cycles)"
    bat_condition="$(get_bat_condition)"

    title_parts=(
        "Battery" "(" "${bat_percent}" ")"
    )

    subtitle_parts=(
        "${bat_time}" "|" "${bat_condition}" "|" "${bat_cycles}" "cycles"
    )

    message_parts=(
        "Source:" "${bat_state}"
    )

    title="$(format "${title_parts[@]}")"
    subtitle="$(format "${subtitle_parts[@]}")"
    message="$(format "${message_parts[@]}")"

    notify "${title:-}" "${subtitle:-}" "${message:-}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

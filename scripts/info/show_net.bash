#!/usr/bin/env bash

has()
{
    if type -p "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

print_stdout()
{
    [[ "${title}" ]] && printf "%s\\n" "${title}"
    [[ "${subtitle}" ]] && printf "%s\\n" "${subtitle}"
    [[ "${message}" ]] && printf "%s\\n" "${message}"
}

notify()
{
    title="${title_parts[*]}"
    subtitle="${subtitle_parts[*]}"
    message="${message_parts[*]}"

    [[ "${title:0:1}" == "|" ]] && \
        title="${title##'| '}"

    [[ "${title:(-1):1}" == "|" ]] && \
        title="${title%%' |'}"

    [[ "${subtitle:0:1}" == "|" ]] && \
        subtitle="${subtitle##'| '}"

    [[ "${subtitle:(-1):1}" == "|" ]] && \
        subtitle="${subtitle%%' |'}"

    [[ "${message:0:1}" == "|" ]] && \
        message="${message##'| '}"

    [[ "${message:(-1):1}" == "|" ]] && \
        message="${message%%' |'}"

    if [[ "${out}" == "stdout" ]]; then
        print_stdout
    else
        if has "notify-send" || has "osascript"; then
            if [[ "${subtitle}" && "${message}" ]]; then
                body="${subtitle}\\n${message}"
            elif [[ ! "${subtitle}" || ! "${message}" ]]; then
                body+="${subtitle}"
                body+="${message}"
            else
                body=""
            fi

            case "${os}" in
                "MacOS")
                    script="display notification \"${message}\" \
                            with title \"${title}\" \
                            subtitle \"${subtitle}\""
                    /usr/bin/env osascript <<< "${script}"
                ;;

                "Linux")
                    notify-send --icon=dialog-information "${title}" "${body}"
                ;;
            esac
        else
            print_stdout
        fi
    fi
}

trim()
{
    [[ "$*" ]] && {
        set -f
        set -- $*
        printf "%s" "${*//\"}"
        set +f
    }
}

read_file()
{
    local file="$1"
    [[ -f "${file}" ]] && \
        printf "%s" "$(< "${file}")"
}

_get_real_time()
{
    if [[ "${EPOCHREALTIME}" ]]; then
        printf "%s" "${EPOCHREALTIME}"
    else
        case "${os}" in
            "MacOS")
                if has gdate; then
                    gdate '+%s.%N'
                else
                    python -c 'import time; print(time.time())'
                fi
            ;;

            "Linux")
                date '+%s.%N'
            ;;
        esac
    fi
}

percent()
{
    [[ "$1" && "$2" ]] && (($(awk -v a="$2" 'BEGIN { printf "%d", (a > 0) }'))) && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", (a / b) * 100 }'
}

minus()
{
    [[ "$1" && "$2" ]] && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", a - b }'
}

div()
{
    [[ "$1" && "$2" ]] && (($(awk -v a="$2" 'BEGIN { printf "%d", (a != 0) }'))) && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", a / b }'
}

multi()
{
    [[ "$1" && "$2" ]] && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", a * b }'
}

round()
{
    [[ "$1" && "$2" ]] && \
        printf "%.*f" "$1" "$2"
}

get_os()
{
    case "${OSTYPE:-$(uname -s)}" in
        "Darwin"|"darwin"*)
            os="MacOS"
        ;;

        "Linux"|"linux"*)
            os="Linux"
        ;;
    esac
}

get_network_device()
{
    [[ "${network_device}" && "${net_info[network_device]}" ]] && \
        return

    case "${os}" in
        "MacOS")
            while read -r line; do
                [[ "${line}" =~ ^'Device:' ]] && \
                    devices+=("${line##*:}")
            done < <(networksetup -listallhardwareports)

            while [[ ! "${network_device}" ]] && read -r device; do
                [[ "$(ifconfig "${device}")" =~ 'status: active' ]] && \
                    network_device="${device}"
            done < <(printf "%s\\n" "${devices[@]}")
        ;;

        "Linux")
            net_dir="/sys/class/net"
            while [[ ! "${network_device}" ]] && read -r device; do
                [[ "$(read_file "${device}/operstate")" == "up" ]] &&\
                    network_device="${device##*/}"
            done < <(printf "%s\\n" "${net_dir}/"*)
        ;;
    esac

    net_info[network_device]="${network_device}"
}

get_network_local_ip()
{
    [[ "${network_local_ip}" && "${net_info[network_local_ip]}" ]] && \
        return

    [[ ! "${network_device}" && ! "${net_info[network_device]}" ]] && \
        get_network_device

    case "${os}" in
        "MacOS")
            while [[ ! "${network_local_ip}" ]] && read -r ip_type ip _; do
                [[ "${ip_type}" == "inet" ]] && \
                    network_local_ip="${ip}"
            done < <(ifconfig "${device}")
        ;;

        "Linux")
            while [[ ! "${network_local_ip}" ]] && read -r _ _ ip_type ip _; do
                [[ "${ip_type}" == "inet" ]] && \
                    network_local_ip="${ip%%/*}"
            done < <(ip --oneline address show dev "${net_info[network_device]}")
        ;;
    esac

    net_info[network_local_ip]="${network_local_ip}"
}

get_network_download()
{
    [[ "${network_download}" && "${net_info[network_download]}" ]] && \
        return

    [[ ! "${network_device}" && ! "${net_info[network_device]}" ]] && \
        get_network_device

    case "${os}" in
        "MacOS")
            parse_netstat()
            {
                unset delta
                while [[ ! "${delta}" ]] && read -r _ _ _ _ _ _ rx _; do
                    [[ "${rx}" =~ ^[0-9]+$ ]] && \
                        delta="${rx}"
                done < <(netstat -nbiI "${net_info[network_device]}")
                printf "%s" "${delta}"
            }

            rx_1="$(parse_netstat)"
            time_1="$(_get_real_time)"

            until (($(parse_netstat) > rx_1)); do
                read -rst "0.05" -N 999
            done

            rx_2="$(parse_netstat)"
            time_2="$(_get_real_time)"

            ((rx_delta = rx_2 - rx_1))
            time_delta="$(minus "${time_2}" "${time_1}")"
            multiplier="$(div "1" "${time_delta}")"

            rx_delta="$(multi "${rx_delta}" "${multiplier}")"
            network_download="$(round "0" "${rx_delta}")"
        ;;

        "Linux")
            net_dir="/sys/class/net/${net_info[network_device]}/statistics"

            rx_1="$(read_file "${net_dir}/rx_bytes")"
            time_1="$(_get_real_time)"

            until (($(read_file "${net_dir}/rx_bytes") > rx_1)); do
                read -rst "0.05" -N 999
            done

            rx_2="$(read_file "${net_dir}/rx_bytes")"
            time_2="$(_get_real_time)"

            ((rx_delta = rx_2 - rx_1))
            time_delta="$(minus "${time_2}" "${time_1}")"
            multiplier="$(div "1" "${time_delta}")"

            rx_delta="$(multi "${rx_delta}" "${multiplier}")"
            network_download="$(round "0" "${rx_delta}")"
        ;;
    esac

    network_download="$(div "${network_download}" "1024")"
    network_download="$(round "2" "${network_download}")"
    unit="KiB/s"

    ((${network_download/.*} > 1024)) && {
        network_download="$(div "${network_download}" "1024")"
        network_download="$(round "2" "${network_download}")"
        unit="MiB/s"
    }

    net_info[network_download]="${network_download} ${unit}"
}

get_network_upload()
{
    [[ "${network_upload}" && "${net_info[network_upload]}" ]] && \
        return

    [[ ! "${network_device}" && ! "${net_info[network_device]}" ]] && \
        get_network_device

    case "${os}" in
        "MacOS")
            parse_netstat()
            {
                unset delta
                while [[ ! "${delta}" ]] && read -r _ _ _ _ _ _ _ _ _ tx _; do
                    [[ "${tx}" =~ ^[0-9]+$ ]] && \
                        delta="${tx}"
                done < <(netstat -nbiI "${net_info[network_device]}")
                printf "%s" "${delta}"
            }

            tx_1="$(parse_netstat)"
            time_1="$(_get_real_time)"

            until (($(parse_netstat) > tx_1)); do
                read -rst "0.05" -N 999
            done

            tx_2="$(parse_netstat)"
            time_2="$(_get_real_time)"

            ((tx_delta = tx_2 - tx_1))
            time_delta="$(minus "${time_2}" "${time_1}")"
            multiplier="$(div "1" "${time_delta}")"

            tx_delta="$(multi "${tx_delta}" "${multiplier}")"
            network_upload="$(round "0" "${tx_delta}")"
        ;;

        "Linux")
            net_dir="/sys/class/net/${net_info[network_device]}/statistics"

            tx_1="$(read_file "${net_dir}/tx_bytes")"
            time_1="$(_get_real_time)"

            until (($(read_file "${net_dir}/tx_bytes") > tx_1)); do
                read -rst "0.05" -N 999
            done

            tx_2="$(read_file "${net_dir}/tx_bytes")"
            time_2="$(_get_real_time)"

            ((tx_delta = tx_2 - tx_1))
            time_delta="$(minus "${time_2}" "${time_1}")"
            multiplier="$(div "1" "${time_delta}")"

            tx_delta="$(multi "${tx_delta}" "${multiplier}")"
            network_upload="$(round "0" "${tx_delta}")"
        ;;
    esac

    network_upload="$(div "${network_upload}" "1024")"
    network_upload="$(round "2" "${network_upload}")"
    unit="KiB/s"

    ((${network_upload/.*} > 1024)) && {
        network_upload="$(div "${network_upload}" "1024")"
        network_upload="$(round "2" "${network_upload}")"
        unit="MiB/s"
    }

    net_info[network_upload]="${network_upload} ${unit}"
}

print_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} info_name --option --option [value] ...

Options:
    --stdout            Print to stdout
    -r, --raw           Print in csv form
    -h, --help          Show this message

Info:
    info_name           Print the output of func_name

Valid Names:
    network_device
    network_local_ip
    network_download
    network_upload

Output:
    -f, --format \"str\"    Print info_name in a formatted string
                          Used in conjuction with info_name

Syntax:
    {}  Output of info_name

Examples:
    Print all information as a notification:
    \$ ${0##*/}

    Print to standard out:
    \$ ${0##*/} --stdout

    Print local ip address:
    \$ ${0##*/} network_local_ip

    Print download and upload speed:
    \$ ${0##*/} --format '{} | {}' network_download network_upload

Misc:
    If notify-send is not installed, then the script will
    print to standard output.
"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") [[ ! "${out}" ]] && out="stdout" ;;
            "-r"|"--raw") [[ ! "${out}" ]] && out="raw" ;;
            "-f"|"--format") [[ "$2" ]] && { str_format="$2"; shift; } ;;
            "-h"|"--help") print_usage; exit ;;
            *)
                [[ ! "${out}" ]] && out="string"
                func+=("$1")
            ;;
        esac
        shift
    done
}

main()
{
    declare -A net_info
    get_args "$@"
    get_os

    [[ ! "${func[*]}" ]] && \
        func=(
            "network_device" "network_local_ip"
            "network_download" "network_upload"
        )

    for function in "${func[@]}"; do
        [[ "$(type -t "get_${function}")" == "function" ]] && \
            "get_${function}"
    done

    case "${out}" in
        "raw")
            raw="${func[0]}:${net_info[${func[0]}]}"
            for function in "${func[@]:1}"; do
                raw="${raw},${function}:${net_info[${function}]}"
            done
            printf "%s\\n" "${raw}"
        ;;

        "string")
            if [[ "${str_format}" ]]; then
                out="${str_format}"
                for function in "${func[@]}"; do
                    [[ "${net_info[${function}]}" ]] && \
                        out="${out/'{}'/${net_info[${function}]}}"
                done
                printf "%s" "${out}"
            else
                for function in "${func[@]}"; do
                    [[ "${net_info[${function}]}" ]] && \
                        printf "%s\\n" "${net_info[${function}]}"
                done
            fi
        ;;

        *)
            [[ "${net_info[network_device]}" ]] && \
                title_parts+=("Network" "(${net_info[network_device]})")

            [[ "${net_info[network_download]}" ]] && \
                subtitle_parts+=("Down:" "${net_info[network_download]}")

            [[ "${net_info[network_upload]}" ]] && \
                subtitle_parts+=("|" "Up:" "${net_info[network_upload]}")

            [[ "${net_info[network_local_ip]}" ]] && \
                message_parts+=("Local IP:" "${net_info[network_local_ip]}")

            notify
        ;;
    esac
}

main "$@"

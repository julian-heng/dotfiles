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

percent()
{
    [[ "$1" && "$2" ]] && (($2 > 0)) && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", (a / b) * 100 }'
}

div()
{
    [[ "$1" && "$2" ]] && (($2 != 0)) && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", a / b }'
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

get_mem()
{
    case "${os}" in
        "MacOS")
            pow="2"
            mem_total=$(sysctl -n hw.memsize)
            while IFS=":" read -r a b; do
                case "$a" in
                    *" wired"*|*" active"*|*" occupied"*)
                        ((mem_used += ${b/.}))
                    ;;
                esac
            done < <(vm_stat)
            ((mem_used *= 4096))
        ;;

        "Linux")
            pow="1"
            while read -r a b _; do
                case "${a/:}" in
                    "MemTotal") mem_total="$b"; mem_used="$b" ;;
                    "Shmem") ((mem_used += b)) ;;
                    "MemFree"|"Buffers"|"Cached"|"SReclaimable")
                        ((mem_used -= b))
                    ;;
                esac
            done < /proc/meminfo
        ;;
    esac

    printf -v mem_percent "%.*f" "0" "$(percent "${mem_used}" "${mem_total}")"
    printf -v mem_total "%.*f" "0" "$(div "${mem_total}" "$((1024 ** pow))")"
    printf -v mem_used "%.*f" "0" "$(div "${mem_used}" "$((1024 ** pow))")"

    mem_info["mem_percent"]="${mem_percent}%"
    mem_info["mem_total"]="${mem_total} MiB"
    mem_info["mem_used"]="${mem_used} MiB"
}

get_swap()
{
    case "${os}" in
        "MacOS")
            pow="0"
            read -r _ _ swap_total _ _ swap_used _ < <(sysctl -n vm.swapusage)
            swap_total="${swap_total/M}"
            swap_used="${swap_used/M}"
        ;;

        "Linux")
            pow="1"
            while read -r a b _; do
                case "${a/:}" in
                    "SwapTotal") swap_total="$b" ;;
                    "SwapFree") ((swap_used = swap_total - b)) ;;
                esac
            done < /proc/meminfo
        ;;
    esac

    printf -v swap_total "%.*f" "0" "$(div "${swap_total}" "$((1024 ** pow))")"
    printf -v swap_used "%.*f" "0" "$(div "${swap_used}" "$((1024 ** pow))")"
    printf -v swap_percent "%.*f" "0" "$(percent "${swap_used}" "${swap_total}")"

    mem_info["swap_percent"]="${swap_percent}%"
    mem_info["swap_total"]="${swap_total} MiB"
    mem_info["swap_used"]="${swap_used} MiB"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") [[ ! "${out}" ]] && out="stdout" ;;
            "-r"|"--raw") [[ ! "${out}" ]] && out="raw" ;;
            *)
                [[ ! "${out}" ]] && out="string"
                func+=("$1")
        esac
        shift
    done
}

main()
{
    declare -A mem_info
    get_args "$@"
    get_os

    [[ ! "${func[*]}" ]] && \
        func=(
            "mem_percent" "mem_total"
            "mem_used" "swap_total"
            "swap_used"
        )

    get_mem
    get_swap

    case "${out}" in
        "raw")
            raw="${mem_info[${func[0]}]}"
            for function in "${func[@]:1}"; do
                raw="${raw},${mem_info[${function}]}"
            done
            printf "%s\\n" "${raw}"
        ;;

        "string")
            for function in "${func[@]}"; do
                [[ "${mem_info[${function}]}" ]] && \
                    printf "%s\\n" "${mem_info[${function}]}"
            done
        ;;

        *)
            [[ "${mem_info["mem_percent"]}" ]] && \
                title_parts+=("Memory" "(${mem_info["mem_percent"]})")

            [[ "${mem_info["mem_used"]}" ]] && \
                subtitle_parts+=("${mem_info["mem_used"]}")
            [[ "${mem_info["mem_total"]}" ]] && \
                subtitle_parts+=("|" "${mem_info["mem_total"]}")

            [[ "${mem_info["swap_used"]}" ]] && \
                message_parts+=("Swap:" "${mem_info["swap_used"]}")
            [[ "${mem_info["swap_total"]}" ]] && \
                message_parts+=("|" "${mem_info["swap_total"]}")

            notify
        ;;
    esac
}

main "$@"

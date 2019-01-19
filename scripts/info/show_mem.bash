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

    [[ "${title:-1:1}" == "|" ]] && \
        title="${title%%' |'}"

    [[ "${subtitle:0:1}" == "|" ]] && \
        subtitle="${subtitle##'| '}"

    [[ "${subtitle:-1:1}" == "|" ]] && \
        subtitle="${subtitle%%' |'}"

    [[ "${message:0:1}" == "|" ]] && \
        message="${message##'| '}"

    [[ "${message:-1:1}" == "|" ]] && \
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
        printf "%s" "$*"
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
            while IFS=":" read -r a b; do
                case "$a" in
                    *" wired"*|*" active"*|*" occupied"*)
                        ((mem_used += ${b/.}))
                    ;;
                esac
            done < <(vm_stat)

            mem_total=$(sysctl -n hw.memsize)
            read -r _ _ swap_total _ _ swap_used _ < <(sysctl -n vm.swapusage)

            ((mem_used *= 4096))
            printf -v mem_percent "%.*f" "0" "$(percent "${mem_used}" "${mem_total}")"
            printf -v mem_total "%.*f" "0" "$(div "${mem_total}" "$((1024 ** 2))")"
            printf -v mem_used "%.*f" "0" "$(div "${mem_used}" "$((1024 ** 2))")"
            printf -v swap_total "%.*f" "0" "${swap_total/M}"
            printf -v swap_used "%.*f" "0" "${swap_used/M}"
        ;;

        "Linux")
            while read -r a b _; do
                case "${a/:}" in
                    "MemTotal") mem_total="$b"; mem_used="$b" ;;
                    "Shmem") ((mem_used += b)) ;;
                    "MemFree"|"Buffers"|"Cached"|"SReclaimable")
                        ((mem_used -= b))
                    ;;
                    "SwapTotal") swap_total="$b" ;;
                    "SwapFree") ((swap_used = swap_total - b)) ;;
                esac
            done < /proc/meminfo

            printf -v mem_percent "%.*f" "0" "$(percent "${mem_used}" "${mem_total}")"
            printf -v mem_total "%.*f" "0" "$(div "${mem_total}" 1024)"
            printf -v mem_used "%.*f" "0" "$(div "${mem_used}" 1024)"
            printf -v swap_total "%.*f" "0" "$(div "${swap_total}" 1024)"
            printf -v swap_used "%.*f" "0" "$(div "${swap_used}" 1024)"
        ;;
    esac
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") out="stdout" ;;
            "-r"|"--raw") out="raw" ;;
        esac
        shift
    done
}

main()
{
    get_args "$@"
    get_os
    get_mem

    case "${out}" in
        "raw")
            printf -v raw "%s," \
                "${mem_percent}%" \
                "${mem_used} MiB" \
                "${mem_total} MiB" \
                "${swap_used} MiB"
            printf -v raw "%s%s" "${raw}" "${swap_total} MiB"
            printf "%s\\n" "${raw}"
        ;;

        *)
            [[ "${mem_percent}" ]] && title_parts+=("Memory" "(${mem_percent}%)")
            [[ "${mem_used}" ]] && subtitle_parts+=("${mem_used}" "MiB")
            [[ "${mem_total}" ]] && subtitle_parts+=("|" "${mem_total}" "MiB")
            [[ "${swap_used}" ]] && message_parts+=("Swap:" "${swap_used}" "MiB")
            [[ "${swap_total}" ]] && message_parts+=("|" "${swap_total}" "MiB")

            notify
        ;;
    esac
}

main "$@"

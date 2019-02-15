#!/usr/bin/env bash
# shellcheck disable=SC2048,SC2086

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
    [[ "$1" && "$2" ]] && (($(awk -v a="$2" 'BEGIN { printf "%d", (a > 0) }'))) && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", (a / b) * 100 }'
}

div()
{
    [[ "$1" && "$2" ]] && (($(awk -v a="$2" 'BEGIN { printf "%d", (a != 0) }'))) && \
        awk -v a="$1" -v b="$2" 'BEGIN { printf "%f", a / b }'
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

get_mem_percent()
{
    [[ "${mem_percent}" && "${mem_info[mem_percent]}" ]] && \
        return

    [[ ! "${mem_info[mem_total]}" ]] && \
        get_mem_total
    [[ ! "${mem_info[mem_used]}" ]] && \
        get_mem_used

    mem_percent="$(percent "${mem_info[mem_used]/'MiB'}" "${mem_info[mem_total]/'MiB'}")"
    mem_percent="$(round "0" "${mem_percent}")"
    mem_info[mem_percent]="${mem_percent}%"
}

get_mem_used()
{
    [[ "${mem_used}" && "${mem_info[mem_used]}" ]] && \
        return

    case "${os}" in
        "MacOS")
            pow="2"
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
                    "MemTotal") mem_used="$b" ;;
                    "Shmem") ((mem_used += b)) ;;
                    "MemFree"|"Buffers"|"Cached"|"SReclaimable")
                        ((mem_used -= b))
                    ;;
                esac
            done < /proc/meminfo
        ;;
    esac

    mem_used="$(div "${mem_used}" "$((1024 ** pow))")"
    mem_used="$(round "0" "${mem_used}")"
    mem_info["mem_used"]="${mem_used} MiB"
}

get_mem_total()
{
    [[ "${mem_total}" && "${mem_info[mem_total]}" ]] && \
        return

    case "${os}" in
        "MacOS")
            pow="2"
            mem_total=$(sysctl -n hw.memsize)
        ;;

        "Linux")
            pow="1"
            while [[ ! "${mem_total}" ]] && read -r a b _; do
                [[ "$a" =~ 'MemTotal' ]] && \
                    mem_total="$b"
            done < /proc/meminfo
        ;;
    esac

    mem_total="$(div "${mem_total}" "$((1024 ** pow))")"
    mem_total="$(round "0" "${mem_total}")"
    mem_info["mem_total"]="${mem_total} MiB"
}

get_swap_percent()
{
    [[ "${swap_percent}" && "${mem_info[swap_percent]}" ]] && \
        return

    [[ ! "${mem_info[swap_total]}" ]] && \
        get_swap_total
    [[ ! "${mem_info[swap_used]}" ]] && \
        get_swap_used

    swap_percent="$(percent "${mem_info[swap_used]/'MiB'}" "${mem_info[swap_total]/'MiB'}")"
    swap_percent="$(round "0" "${swap_percent}")"
    mem_info[swap_percent]="${swap_percent}%"
}

get_swap_used()
{
    [[ "${swap_used}" && "${mem_info[swap_used]}" ]] && \
        return

    case "${os}" in
        "MacOS")
            pow="0"
            read -r _ _ _ _ _ swap_used _ < <(sysctl -n vm.swapusage)
            swap_used="${swap_used/M}"
        ;;

        "Linux")
            pow="1"
            while [[ ! "${swap_used}" ]] && read -r a b _; do
                if [[ "$a" =~ 'SwapTotal' ]]; then
                    tmp="$b"
                elif [[ "$a" =~ 'SwapFree' ]]; then
                    ((swap_used = tmp - b))
                fi
            done < /proc/meminfo
        ;;
    esac

    swap_used="$(div "${swap_used}" "$((1024 ** pow))")"
    swap_used="$(round "0" "${swap_used}")"
    mem_info["swap_used"]="${swap_used} MiB"
}

get_swap_total()
{
    [[ "${swap_total}" && "${mem_info[swap_total]}" ]] && \
        return

    case "${os}" in
        "MacOS")
            pow="0"
            read -r _ _ swap_total _ < <(sysctl -n vm.swapusage)
            swap_total="${swap_total/M}"
        ;;

        "Linux")
            pow="1"
            while [[ ! "${swap_total}" ]] && read -r a b _; do
                [[ "$a" =~ 'SwapTotal' ]] && \
                    swap_total="$b"
            done < /proc/meminfo
        ;;
    esac

    swap_total="$(div "${swap_total}" "$((1024 ** pow))")"
    swap_total="$(round "0" "${swap_total}")"
    mem_info["swap_total"]="${swap_total} MiB"
}

print_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} info_name --option --option [value] ...

Options:
    --stdout            Print to stdout
    --json              Pirnt in json format
    -r, --raw           Print in csv format
    -h, --help          Show this message

Info:
    info_name           Print the output of func_name

Valid Names:
    mem_percent
    mem_used
    mem_total
    swap_percent
    swap_used
    swap_total

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

    Print memory usage:
    \$ ${0##*/} mem_used mem_total

    Print swap usage with a format string:
    \$ ${0##*/} --format '{} | {}' swap_used swap_total

Misc:
    If notify-send is not installed, then the script will
    print to standard output.
"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") : "${out:=stdout}" ;;
            "--json") : "${out:=json}" ;;
            "-r"|"--raw") : "${out:=raw}" ;;
            "-f"|"--format") [[ "$2" ]] && { str_format="$2"; shift; } ;;
            "-h"|"--help") print_usage; exit ;;
            *)
                : "${out:=string}"
                func+=("$1")
            ;;
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
            "mem_used" "mem_total" "mem_percent"
            "swap_used" "swap_total" "swap_percent"
        )

    for function in "${func[@]}"; do
        [[ "$(type -t "get_${function}")" == "function" ]] && \
            "get_${function}"
    done

    for i in "${!func[@]}"; do
        [[ ! "${mem_info[${func[$i]}]}" ]] && \
            unset 'func[$i]'
    done

    [[ ! "${func[*]}" ]] && \
        exit 1

    case "${out}" in
        "raw")
            raw="${func[0]}:${mem_info[${func[0]}]}"
            for function in "${func[@]:1}"; do
                raw="${raw},${function}:${mem_info[${function}]}"
            done
            printf "%s\\n" "${raw}"
        ;;

        "json")
            printf "{\\n"
            for function in "${func[@]::${#func[@]} - 1}"; do
                printf "    \"%s\": \"%s\",\\n" "${function}" "${mem_info[${function}]}"
            done

            last="${func[*]:(-1):1}"
            printf "    \"%s\": \"%s\"\\n" "${last}" "${mem_info[${last}]}"
            printf "}\\n"
        ;;

        "string")
            if [[ "${str_format}" ]]; then
                out="${str_format}"
                for function in "${func[@]}"; do
                    out="${out/'{}'/${mem_info[${function}]}}"
                done
                printf "%s" "${out}"
            else
                for function in "${func[@]}"; do
                    printf "%s\\n" "${mem_info[${function}]}"
                done
            fi
        ;;

        *)
            title_parts=("Memory")
            [[ "${mem_info["mem_percent"]}" ]] && \
                title_parts+=("(${mem_info["mem_percent"]})")

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

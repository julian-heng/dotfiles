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

get_search()
{
    if [[ ! "$1" ]]; then
        search="/"
        type="mount"
    else
        search="$1"
    fi

    case "${type:-disk}" in
        "disk")
            mapfile -t df_out < <(df -P)
            while [[ ! "${dev}" ]] && read -r line; do
                [[ "${line}" =~ ${search} ]] && \
                    dev="${line%% *}"
            done < <(printf "%s\\n" "${df_out[@]:1}")
        ;;

        "mount")
            mapfile -t df_out < <(df -P "${search}")
            read -r dev _ _ _ _ mount <<< "${df_out[1]}"
            [[ "${mount}" != "${search}" ]] && \
                unset dev
        ;;
    esac

    if [[ "${dev}" ]]; then
        printf "%s" "${dev}"
    else
        return 1
    fi
}

check_diskutil_out()
{
    [[ ! "${diskutil_out[*]}" ]] && \
        mapfile -t diskutil_out < <(diskutil info "${search}")
}

check_lsblk_line()
{
    [[ "${lsblk_line}" ]] && \
        return

    [[ ! "${lsblk_flags[*]}" ]] && \
        lsblk_flags=(
            "--output" "KNAME,NAME,LABEL,PARTLABEL,FSTYPE,MOUNTPOINT"
            "--paths" "--pair"
        )

    lsblk_line="$(lsblk "${lsblk_flags[@]}" "${search}")"
}

check_df_line()
{
    [[ "${df_line}" ]] && \
        return

    [[ ! "${disk_info[disk_mount]}" ]] && \
        get_disk_mount

    [[ ! "${df_flags[*]}" ]] && \
        case "${os}" in
            "MacOS") df_flags=("-P" "-k") ;;
            "Linux") df_flags=("-P") ;;
        esac

    df_line="$(mapfile -t a < <(df "${df_flags[@]}" "${disk_info[disk_mount]}")
               printf "%s" "${a[1]}")"
}

get_disk_name()
{
    [[ "${disk_name}" && "${disk_info[disk_name]}" ]] && \
        return

    case "${os}" in
        "MacOS")
            check_diskutil_out
            while [[ ! "${disk_name}" ]] && IFS=":" read -r a b; do
                [[ "$a" =~ 'Volume Name' ]] && \
                    disk_name="$(trim "$b")"
            done < <(printf "%s\\n" "${diskutil_out[@]}")
        ;;

        "Linux")
            check_lsblk_line
            read -r _ _ disk_label disk_partlabel _ <<< "${lsblk_line}"
            disk_label="$(trim "${disk_label##*=}")"
            disk_partlabel="$(trim "${disk_partlabel##*=}")"
            disk_name="${disk_label:-${disk_partlabel}}"
        ;;
    esac

    disk_info[disk_name]="${disk_name}"
}

get_disk_device()
{
    [[ "${disk_device}" && "${disk_info[disk_device]}" ]] && \
        return

    case "${os}" in
        "MacOS")
            check_diskutil_out
            while [[ ! "${disk_device}" ]] && IFS=":" read -r a b; do
                [[ "$a" =~ 'Device Node' ]] && \
                    disk_device="$(trim "$b")"
            done < <(printf "%s\\n" "${diskutil_out[@]}")
        ;;

        "Linux")
            check_lsblk_line
            read -r disk_device _ <<< "${lsblk_line}"
            disk_device="$(trim "${disk_device##*=}")"
        ;;
    esac

    disk_info[disk_device]="${disk_device}"
}

get_disk_mount()
{
    [[ "${disk_mount}" && "${disk_info[disk_mount]}" ]] && \
        return

    case "${os}" in
        "MacOS")
            check_diskutil_out
            while [[ ! "${disk_mount}" ]] && IFS=":" read -r a b; do
                [[ "$a" =~ 'Mount Point' ]] && \
                    disk_mount="$(trim "$b")"
            done < <(printf "%s\\n" "${diskutil_out[@]}")
        ;;

        "Linux")
            check_lsblk_line
            read -r _ _ _ _ _ disk_mount <<< "${lsblk_line}"
            disk_mount="$(trim "${disk_mount##*=}")"
        ;;
    esac

    disk_info[disk_mount]="${disk_mount}"
}

get_disk_partition()
{
    [[ "${disk_partition}" && "${disk_info[disk_partition]}" ]] && \
        return

    case "${os}" in
        "MacOS")
            check_diskutil_out
            while [[ ! "${disk_partition}" ]] && IFS=":" read -r a b; do
                [[ "$a" =~ 'File System Personality' ]] && \
                    disk_partition="$(trim "$b")"
            done < <(printf "%s\\n" "${diskutil_out[@]}")
        ;;

        "Linux")
            check_lsblk_line
            read -r _ _ _ _ disk_partition _ <<< "${lsblk_line}"
            disk_partition="$(trim "${disk_partition##*=}")"
        ;;
    esac

    disk_info[disk_partition]="${disk_partition}"
}

get_disk_used()
{
    [[ "${disk_used}" && "${disk_info[disk_used]}" ]] && \
        return

    check_df_line
    read -r _ _ disk_used _ <<< "${df_line}"
    disk_used="$(round "2" "$(div "${disk_used}" "$((1024 ** 2))")")"
    disk_info[disk_used]="${disk_used} GiB"
}

get_disk_total()
{
    [[ "${disk_total}" && "${disk_info[disk_total]}" ]] && \
        return

    check_df_line
    read -r _ disk_total _ <<< "${df_line}"
    disk_total="$(div "${disk_total}" "$((1024 ** 2))")"
    disk_total="$(round "2" "${disk_total}")"
    disk_info[disk_total]="${disk_total} GiB"
}

get_disk_percent()
{
    [[ "${disk_percent}" && "${disk_info[disk_percent]}" ]] && \
        return

    [[ ! "${disk_info[disk_used]}" ]] && \
        get_disk_used
    [[ ! "${disk_info[disk_total]}" ]] && \
        get_disk_total

    disk_percent="$(percent "${disk_info[disk_used]/'GiB'}" "${disk_info[disk_total]/'GiB'}")"
    disk_percent="$(round "2" "${disk_percent}")"
    disk_info[disk_percent]="${disk_percent}%"
}

print_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} info_name --option --option [value] ...

Options:
    --stdout            Print to stdout
    --json              Print to json format
    -r, --raw           Print in csv format
    -h, --help          Show this message

Info:
    info_name           Print the output of func_name

Valid Names:
    disk_name
    disk_device
    disk_mount
    disk_partition
    disk_used
    disk_total
    disk_percent

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

    Print disk device and mount:
    \$ ${0##*/} disk_device disk_mount

    Print disk usage with a format string:
    \$ ${0##*/} --format '{} | {}' disk_used disk_capacity

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
            "-d"|"--disk")
                [[ "$2" ]] && {
                    type="disk"
                    search="${2%/}"
                    shift
                }
            ;;

            "-m"|"--mount")
                [[ "$2" ]] && {
                    type="mount"
                    search="${2%/}"
                    shift
                }
            ;;

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
    declare -A disk_info
    get_args "$@"
    get_os

    [[ ! "${func[*]}" ]] && \
        func=(
            "disk_name" "disk_device" "disk_mount" "disk_partition"
            "disk_used" "disk_total" "disk_percent"
        )

    if search="$(get_search "${search}")"; then
        for function in "${func[@]}"; do
            [[ "$(type -t "get_${function}")" == "function" ]] && \
                "get_${function}"
        done
    else
        return 1
    fi

    [[ "${out}" == "stdout" ]] && \
        [[ ! "${disk_info["disk_device"]}" \
        || ! "${disk_info["disk_used"]}" \
        || ! "${disk_info["disk_total"]}" \
        || "${disk_info["disk_total"]}" == "0.00" \
        ]] && exit 1

    for i in "${!func[@]}"; do
        [[ ! "${disk_info[${func[$i]}]}" ]] && \
            unset 'func[$i]'
    done

    [[ ! "${func[*]}" ]] && \
        exit 1

    case "${out}" in
        "raw")
            raw="${func[0]}:${disk_info[${func[0]}]}"
            for function in "${func[@]:1}"; do
                raw="${raw},${function}:${disk_info[${function}]}"
            done
            printf "%s\\n" "${raw}"
        ;;

        "json")
            printf "{\\n"
            for function in "${func[@]::${#func[@]} - 1}"; do
                printf "    \"%s\": \"%s\",\\n" "${function}" "${disk_info[${function}]}"
            done

            last="${func[*]:(-1):1}"
            printf "    \"%s\": \"%s\"\\n" "${last}" "${disk_info[${last}]}"
            printf "}\\n"
        ;;

        "string")
            if [[ "${str_format}" ]]; then
                out="${str_format}"
                for function in "${func[@]}"; do
                    out="${out/'{}'/${disk_info[${function}]}}"
                done
                printf "%s" "${out}"
            else
                for function in "${func[@]}"; do
                    printf "%s\\n" "${disk_info[${function}]}"
                done
            fi
        ;;

        *)
            title_parts+=("${disk_name:-Disk}")
            [[ "${disk_info["disk_mount"]}" ]] && \
                title_parts+=("(${disk_info["disk_mount"]})")

            [[ "${disk_info["disk_used"]}" ]] && \
                subtitle_parts+=("${disk_info["disk_used"]}")
            [[ "${disk_info["disk_total"]}" ]] && \
                subtitle_parts+=("|" "${disk_info["disk_total"]}")
            [[ "${disk_info["disk_percent"]}" ]] && \
                subtitle_parts+=("(${disk_info["disk_percent"]})")

            [[ "${disk_info["disk_device"]}" ]] && \
                message_parts+=("${disk_info["disk_device"]}")
            [[ "${disk_info["disk_partition"]}" ]] && \
                message_parts+=("|" "${disk_info["disk_partition"]}")

            notify
        ;;
    esac
}

main "$@"

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

get_prog_out()
{
    case "${os}" in
        "MacOS")
            df_flags=("-P" "-k")
        ;;

        "Linux")
            df_flags=("-P")
            lsblk_flags=(
                "--output"
                "KNAME,NAME,LABEL,PARTLABEL,FSTYPE,MOUNTPOINT"
                "--paths"
                "--pair"
            )

        ;;
    esac

    [[ "${df_flags[*]}" ]] && \
        mapfile -t df_out < <(df "${df_flags[@]}")
    [[ "${lsblk_flags[*]}" ]] && \
        mapfile -t lsblk_out < <(lsblk "${lsblk_flags[@]}")
}

get_search()
{
    if [[ ! "$1" ]]; then
        search="/"
        type="mount"
    else
        search="$1"
    fi

    while [[ ! "${dev}" ]] && read -r df_line; do
        case "${type:-disk}" in
            "disk")
                [[ "${df_line}" =~ ${search} ]] && \
                    dev="${df_line%% *}"
            ;;

            "mount")
                [[ "${df_line}" =~ ${search}$ ]] && \
                    dev="${df_line%% *}"
            ;;
        esac
    done < <(printf "%s\\n" "${df_out[@]:1}")

    if [[ "${dev}" ]]; then
        printf "%s" "${dev}"
    else
        return 1
    fi
}

get_disk_info()
{
    case "${os}" in
        "MacOS")
            while IFS=":" read -r a b; do
                case "$a" in
                    *"Device Node"*) disk_device="$(trim "$b")" ;;
                    *"Volume Name"*) disk_name="$(trim "$b")" ;;
                    *"File System Personality"*) disk_part="$(trim "$b")" ;;
                    *"Mount Point"*) disk_mount="$(trim "$b")" ;;
                esac
            done < <(diskutil info "${search}")
        ;;

        "Linux")
            match="false"

            while read -r line && [[ "${match}" != "true" ]]; do
                [[ "${line}" =~ ${search} ]] && {
                    read -r disk_device _ \
                            disk_label \
                            disk_partlabel \
                            disk_part \
                            disk_mount <<< "${line}"

                    disk_device="$(trim "${disk_device##*=}")"
                    disk_label="$(trim "${disk_label##*=}")"
                    disk_partlabel="$(trim "${disk_partlabel##*=}")"
                    disk_part="$(trim "${disk_part##*=}")"
                    disk_mount="$(trim "${disk_mount##*=}")"

                    disk_name="${disk_label:-${disk_partlabel}}"
                    match="true"
                }
            done < <(printf "%s\\n" "${lsblk_out[@]}")
        ;;
    esac

    match="false"
    while read -r line && [[ "${match}" != "true" ]]; do
        [[ "${line}" =~ ${search} ]] && {
            read -r _ disk_capacity disk_used _ <<< "${line}"
            match="true"
        }
    done < <(printf "%s\\n" "${df_out[@]}")

    printf -v disk_percent "%.*f" "2" "$(percent "${disk_used}" "${disk_capacity}")"
    printf -v disk_used "%.*f" "2" "$(div "${disk_used}" "$((1024 ** 2))")"
    printf -v disk_capacity "%.*f" "2" "$(div "${disk_capacity}" "$((1024 ** 2))")"

    disk_info["disk_name"]="${disk_name}"
    disk_info["disk_mount"]="${disk_mount}"
    disk_info["disk_used"]="${disk_used} GiB"
    disk_info["disk_capacity"]="${disk_capacity} GiB"
    disk_info["disk_percent"]="${disk_percent}%"
    disk_info["disk_device"]="${disk_device}"
    disk_info["disk_part"]="${disk_part}"
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
    disk_name
    disk_mount
    disk_used
    disk_capacity
    disk_percent
    disk_device
    disk_part

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
    If notify-send if not installed, then the script will
    print to standard output.
"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") [[ ! "${out}" ]] && out="stdout" ;;
            "-r"|"--raw") [[ ! "${out}" ]] && out="raw" ;;
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
                [[ ! "${out}" ]] && out="string"
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
    get_prog_out

    [[ ! "${func[*]}" ]] && \
        func=(
            "disk_name" "disk_mount" "disk_used"
            "disk_capacity" "disk_percent"
            "disk_device" "disk_part"
        )

    if search="$(get_search "${search}")"; then
        get_disk_info
    else
        return 1
    fi

    [[ ! "${disk_info["disk_device"]}" \
    || ! "${disk_info["disk_used"]}" \
    || ! "${disk_info["disk_capacity"]}" \
    || "${disk_info["disk_capacity"]}" == "0.00" \
    ]] && exit 1

    case "${out}" in
        "raw")
            raw="${func[0]}:${disk_info[${func[0]}]}"
            for function in "${func[@]:1}"; do
                raw="${raw},${function}:${disk_info[${function}]}"
            done
            printf "%s\\n" "${raw}"
        ;;

        "string")
            if [[ "${str_format}" ]]; then
                out="${str_format}"
                for function in "${func[@]}"; do
                    [[ "${disk_info[${function}]}" ]] && \
                        out="${out/'{}'/${disk_info[${function}]}}"
                done
                printf "%s" "${out}"
            else
                for function in "${func[@]}"; do
                    [[ "${disk_info[${function}]}" ]] && \
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
            [[ "${disk_info["disk_capacity"]}" ]] && \
                subtitle_parts+=("|" "${disk_info["disk_capacity"]}")
            [[ "${disk_info["disk_percent"]}" ]] && \
                subtitle_parts+=("(${disk_info["disk_percent"]})")

            [[ "${disk_info["disk_device"]}" ]] && \
                message_parts+=("${disk_info["disk_device"]}")
            [[ "${disk_info["disk_part"]}" ]] && \
                message_parts+=("|" "${disk_info["disk_part"]}")

            notify
        ;;
    esac
}

main "$@"

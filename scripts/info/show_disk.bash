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
            mapfile -t df_out < <(df -P -k)
        ;;

        "Linux")
            lsblk_flags=(
                "--output"
                "KNAME,NAME,LABEL,PARTLABEL,FSTYPE,MOUNTPOINT"
                "--paths"
                "--pair"
            )

            mapfile -t df_out < <(df -P)
            mapfile -t lsblk_out < <(lsblk "${lsblk_flags[@]}")
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

                    disk_name="${disk_label:-${disk_partlabel:-Disk}}"
                    match="true"
                }
            done < <(printf "%s\\n" "${lsblk_out[@]}")

            match="false"
            while read -r line && [[ "${match}" != "true" ]]; do
                [[ "${line}" =~ ${search} ]] && {
                    read -r _ disk_capacity disk_used _ <<< "${line}"
                }
            done < <(printf "%s\\n" "${df_out[@]}")

            printf -v disk_percent "%.*f" "2" "$(percent "${disk_used}" "${disk_capacity}")"
            printf -v disk_used "%.*f" "2" "$(div "${disk_used}" "$((1024 ** 2))")"
            printf -v disk_capacity "%.*f" "2" "$(div "${disk_capacity}" "$((1024 ** 2))")"
        ;;
    esac
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout") out="stdout" ;;
            "-r"|"--raw") out="raw" ;;
            "-d"|"--disk") [[ "$2" ]] && { type="disk"; search="${2%/}"; } ;;
            "-m"|"--mount") [[ "$2" ]] && { type="mount"; search="${2%/}"; } ;;
        esac
        shift
    done
}

main()
{
    get_args "$@"
    get_os

    get_prog_out

    if search="$(get_search "${search}")"; then
        get_disk_info
    else
        return 1
    fi

    [[ ! "${disk_device}" \
    || "${disk_capacity}" == "0.00" \
    ]] && exit 1

    case "${out}" in
        "raw")
            printf -v raw "%s," \
                "${disk_name}" \
                "${disk_mount}" \
                "${disk_used} GiB" \
                "${disk_capacity} GiB" \
                "${disk_percent}%" \
                "${disk_device}"
            printf -v raw "%s%s" "${raw}" "${disk_part}"
            printf "%s\\n" "${raw}"
        ;;

        *)
            [[ "${disk_name}" ]] && title_parts+=("${disk_name}")
            [[ "${disk_mount}" ]] && title_parts+=("(${disk_mount})")
            [[ "${disk_used}" ]] && subtitle_parts+=("${disk_used}" "GiB")
            [[ "${disk_capacity}" ]] && subtitle_parts+=("|" "${disk_capacity}" "GiB")
            [[ "${disk_percent}" ]] && subtitle_parts+=("(${disk_percent}%)")
            [[ "${disk_device}" ]] && message_parts+=("${disk_device}")
            [[ "${disk_part}" ]] && message_parts+=("|" "${disk_part}")

            notify
        ;;
    esac
}

main "$@"

#!/usr/bin/env bash

function trim
(
    set -f
    set -- $*
    printf "%s" "${*//\"}"
    set +f
)

function notify
(
    title="${title_parts[*]}"
    subtitle="${subtitle_parts[*]}"
    message="${message_parts[*]}"

    if [[ "${stdout}" ]]; then
        [[ "${title}" ]] && \
            display+=("${title}")
        [[ "${subtitle}" ]] && \
            display+=("${subtitle}")
        [[ "${message}" ]] && \
            display+=("${message}")
        printf "%s\\n" "${display[@]}"
    else
        if [[ "${subtitle}" && "${message}" ]]; then
            body="${subtitle}\\n${message}"
        elif [[ ! "${subtitle}" || ! "${message}" ]]; then
            body+="${subtitle}"
            body+="${message}"
        fi
        notify-send --icon=dialog-information "${title}" "${body}"
    fi
)

function get_search
(
    search="$1"
    match="false"

    if [[ "${search}" ]]; then
        while [[ "${match}" != "true" ]] && read -r df_line; do
            [[ "${df_line}" =~ ${search} ]] && {
                match="true"
                dev_match="${df_line}"
            }
        done < <(printf "%s\\n" "${df_out[@]%% *}")
    else
        match="true"
        dev_match="$(get_root)"
    fi

    if [[ "${match}" == "true" ]]; then
        printf "%s" "${dev_match}"
    else
        return 1
    fi
)

function get_root
(
    root="$(awk -F',|:' '/"\/"\}/ { printf "%s", $2}' \
        <(printf "%s\\n" "${lsblk_out[@]}"))"
    root="$(trim "${root}")"
    printf "%s" "${root}"
)

function get_disk_info
{
    lsblk_script='
        $0 ~ disk {
            device = $2
            name = $4
            if (name == "null")
                name = $6
            part = $8
            mount = $10
        }
        END {
            printf "%s,%s,%s,%s", \
                device, name, part, mount
        }'

    df_script='
        $0 ~ disk {
            used = $3
            total = $2
        }
        END {
            percent = (used / total) * 100
            used /= (1024 ^ 3)
            total /= (1024 ^ 3)

            printf "%0.2f %0.2f %0.2f", \
                used, total, percent
        }'

    IFS="," \
    read -r disk_device \
            disk_name \
            disk_part \
            disk_mount \
            < <(awk -F',|: |}' \
                    -v disk="${search}" \
                    "${lsblk_script}" \
                    <(printf "%s\\n" "${lsblk_out[@]}"))

    read -r disk_used \
            disk_capacity \
            disk_percent \
            < <(awk -v disk="${search}" \
                        "${df_script}" \
                        < <(printf "%s\\n" "${df_out[@]}"))

    disk_device="$(trim "${disk_device}")"
    disk_name="$(trim "${disk_name}")"
    disk_part="$(trim "${disk_part}")"
    disk_mount="$(trim "${disk_mount}")"
}

function print_usage
(
    printf "%s\\n" "
Usage: $0 --option --option \"value\"

    Options:

    [--stdout]              Print to stdout
    [-d|--disk]             Show information for selected disk
                            Defaults to $(get_root)
    [-h|--help]             Show this message

    If notify-send is not installed, then the script will
    print to standard output.
"
)

function get_args
{
    while (($# > 0)); do
        case "$1" in
            "--stdout")     stdout="true" ;;
            "-d"|"--disk")  search="$2" ;;
            "-h"|"--help")  print_usage; exit ;;
        esac
        shift
    done

    ! type -p notify-send > /dev/null && \
        stdout="true"
}

function main
(
    lsblk_flags=(
        "--output"
        "KNAME,LABEL,PARTLABEL,FSTYPE,MOUNTPOINT"
        "--paths"
        "--json"
    )

    mapfile -t df_out < <(df -P --block-size=1)
    mapfile -t lsblk_out < <(lsblk "${lsblk_flags[@]}")

    get_args "$@"

    if search="$(get_search "${search}")"; then
        get_disk_info "$@"
    else
        return 1
    fi

    [[ "${disk_device}" == "" \
    || "${disk_capacity}" == "0.00" \
    ]] && exit 1

    [[ "${disk_name}" ]] && \
        title_parts+=("${disk_name}")

    [[ "${disk_mount}" ]] && \
        title_parts+=("(${disk_mount})")

    [[ "${disk_used}" ]] && \
        subtitle_parts+=("${disk_used}" "GiB" "|")

    [[ "${disk_capacity}" ]] && \
        subtitle_parts+=("${disk_capacity}" "GiB")

    [[ "${disk_percent}" ]] && \
        subtitle_parts+=("(${disk_percent}%)")

    [[ "${disk_device}" ]] && \
        message_parts+=("${disk_device}" "|")

    [[ "${disk_part}" ]] && \
        message_parts+=("${disk_part}")

    notify
)

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

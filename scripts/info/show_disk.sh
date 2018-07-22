#!/usr/bin/env bash

function trim
(
    set -f
    set -- $*
    printf "%s" "${*//\"}"
    set +f
)

function get_search
(
    search="$1"
    count="0"
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

function get_disk_device
(
    awk_script='
        $0 ~ disk {
            printf "%s", $2
        }'

    device="$(awk -F',|: |}' -v disk="${1:-${search}}" "${awk_script}" \
            <(printf "%s\\n" "${lsblk_out[@]}"))"
    device="$(trim "${device}")"

    printf "%s" "${device}"
)

function get_disk_name
(
    awk_script='
        $0 ~ disk {
            if ($4 == "null")
                printf "%s", $6
            else
                printf "%s", $4
        }'

    name="$(awk -F',|: |}' -v disk="${1:-${search}}" "${awk_script}" \
            <(printf "%s\\n" "${lsblk_out[@]}"))"
    name="$(trim "${name}")"
    printf "%s" "${name}"
)

function get_disk_part
(
    awk_script='
        $0 ~ disk {
            printf "%s", $8
        }'

    part="$(awk -F',|: |}' -v disk="${1:-${search}}" "${awk_script}" \
            <(printf "%s\\n" "${lsblk_out[@]}"))"
    part="$(trim "${part}")"
    printf "%s" "${part}"
)

function get_disk_mount
(
    awk_script='
        $0 ~ disk {
            printf "%s", $10
        }'

    mount="$(awk -F',|: |}' -v disk="${1:-${search}}" "${awk_script}" \
            <(printf "%s\\n" "${lsblk_out[@]}"))"
    mount="$(trim "${mount}")"
    printf "%s" "${mount}"
)

function get_disk_used
(
    awk_script='
        $0 ~ disk {
            printf "%0.2f", $3 / (1024 ^ 3)
        }'

    used="$(awk -v disk="${1:-${search}}" "${awk_script}" \
                <(printf "%s\\n" "${df_out[@]}"))"
    printf "%s" "${used}"
)

function get_disk_capacity
(
    awk_script='
        $0 ~ disk {
            printf "%0.2f", $2 / (1024 ^ 3)
        }'

    used="$(awk -v disk="${1:-${search}}" "${awk_script}" \
                <(printf "%s\\n" "${df_out[@]}"))"
    printf "%s" "${used}"
)

function get_disk_percent
(
    used="${1:-$(get_disk_used "${search}")}"
    capacity="${2:-$(get_disk_capacity "${search}")}"

    percent="$(awk -v a="${used}" -v b="${capacity}" \
                'BEGIN { printf "%0.2f", (a / b) * 100 }')"
    printf "%s" "${percent}"
)

function get_disk_info
(
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
            printf "%s %s %s %s", \
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

    printf "%s,%s,%s,%s,%s,%s,%s" \
        "${disk_device}" \
        "${disk_name}" \
        "${disk_part}" \
        "${disk_mount}" \
        "${disk_used}" \
        "${disk_capacity}" \
        "${disk_percent}" \
)

function print_usage
(
    printf "%s\\n" "
Usage: $0 --option --option \"value\"

    Options:

    [--stdout]              Print to stdout
    [--show \"func\"]         Show a specific info
    [--device]              Show disk device
    [--name]                Show disk name
    [--partition]           Show disk partition type
    [--mount]               Show disk mount location
    [--used]                Show amount of disk space used
    [--capacity]            Show total amount of disk space
    [--percent]             Show percentage of disk space used
    [-d|--disk]             Show information for selected disk
                            Defaults to block device used at root
    [-h|--help]             Show this message

    Available functions:
        - device
        - name
        - part
        - mount
        - used
        - capacity
        - percent

    If notify-send is not installed, then the script will
    print to standard output.
"
)

function get_args
{
    [[ ! "$*" ]] && \
        return 0

    while (($# > 0)); do
        case "$1" in
            "--stdout") stdout="true" ;;
            "--show")
                for i in "$@"; do
                    case "$i" in
                        "--show") continue ;;
                        "-"*) break ;;
                        *) 
                            show+=("$i")
                            ((count++))
                        ;;
                    esac
                    shift "${count:-0}"
                done
            ;;

            "--device") show+=("device") ;;
            "--name") show+=("name") ;;
            "--partition") show+=("part") ;;
            "--mount") show+=("mount") ;;
            "--used") show+=("used") ;;
            "--capacity") show+=("capacity") ;;
            "--percent") show+=("percent") ;;
            "-d"|"--disk") search="$2" ;;
            "-h"|"--help") print_usage; exit ;;
        esac
        shift
    done
}

function main
(
    ! source "${BASH_SOURCE[0]//${0##*/}}format.sh" && \
        exit 1

    get_args "$@"

    ! type -p notify-send > /dev/null && \
        stdout="true"

    ! search="$(get_search "${search}")" && \
        return 1

    if [[ ! "${show[*]}" ]]; then
        IFS="," \
        read -r disk_device \
                disk_name \
                disk_part \
                disk_mount \
                disk_used \
                disk_capacity \
                disk_percent \
                < <(get_disk_info "$@")

        [[ "${disk_device}" == "" \
        || "${disk_capacity}" == "0.00" \
        ]] && exit 1

    else
        for i in "${show[@]}"; do
            declare "disk_$i=$(get_disk_"$i")"
        done
    fi

    [[ "${disk_name}" ]] && \
        title_parts+=("${disk_name}")

    [[ "${disk_mount}" ]] && \
        title_parts+=("(" "${disk_mount}" ")")

    [[ "${disk_used}" ]] && \
        subtitle_parts+=("${disk_used}" "GiB" "|")

    [[ "${disk_capacity}" ]] && \
        subtitle_parts+=("${disk_capacity}" "GiB")

    [[ "${disk_percent}" ]] && \
        subtitle_parts+=("(" "${disk_percent}" "%" ")")

    [[ "${disk_device}" ]] && \
        message_parts+=("${disk_device}" "|")

    [[ "${disk_part}" ]] && \
        message_parts+=("${disk_part}")

    title="$(format "${title_parts[@]}")"
    subtitle="$(format "${subtitle_parts[@]}")"
    message="$(format "${message_parts[@]}")"

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
        elif [[ ! "${subtitle}" && ! "${message}" ]]; then
            body=""
        fi
        notify-send --icon=dialog-information "${title}" "${body}"
    fi
)

lsblk_flags=(
    "--output"
    "KNAME,LABEL,PARTLABEL,FSTYPE,MOUNTPOINT"
    "--paths"
    "--json"
)

mapfile -t df_out < <(df -P --block-size=1)
mapfile -t lsblk_out < <(lsblk "${lsblk_flags[@]}")
[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@" || :

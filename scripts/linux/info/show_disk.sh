#!/usr/bin/env bash

trim()
{
    [[ "$*" ]] && {
        set -f
        set -- $*
        printf "%s" "${*//\"}"
        set +f
    }
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
}

get_search()
{
    search="$1"
    match="false"

    if [[ "${search}" ]]; then
        while [[ "${match}" != "true" ]] && read -r df_line; do
            case "${type:-disk}" in
                "disk")
                    [[ "${df_line}" =~ ${search} ]] && {
                        match="true"
                        dev_match="${df_line%% *}"
                    }
                ;;

                "mount")
                    [[ "${df_line}" =~ ${search}$ ]] && {
                        match="true"
                        dev_match="${df_line%% *}"
                    }
                ;;
            esac
        done < <(printf "%s\\n" "${df_out[@]}")
    else
        match="true"
        dev_match="$(get_root)"
    fi

    if [[ "${match}" == "true" ]]; then
        printf "%s" "${dev_match}"
    else
        return 1
    fi
}

get_root()
{
    while read -r line && [[ ! "${root}" ]]; do
        [[ "${line}" =~ 'MOUNTPOINT="/"' ]] && \
            read -r root _ <<< "${line}"
    done < <(printf "%s\\n" "${lsblk_out[@]}")
    root="$(trim "${root/'KNAME='}")"
    printf "%s" "${root}"
}

get_disk_info()
{
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

    match="false"

    while read -r line && [[ "${match}" != "true" ]]; do
        [[ "${line}" =~ ${search} ]] && {
            read -r disk_device \
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

    read -r disk_used \
            disk_capacity \
            disk_percent \
            < <(awk -v disk="${search}" \
                        "${df_script}" \
                        < <(printf "%s\\n" "${df_out[@]}"))
}

print_usage()
{
    printf "%s\\n" "
Usage: ${0##*/} --option --option \"value\"

    Options:

    [--stdout]              Print to stdout
    [-r|--raw]              Print raw values delimited by commas
    [-d|--disk]             Show information for selected disk
                            Defaults to $(get_root)
    [-m|--mount]            Show information for a mounted disk
    [-h|--help]             Show this message

    Note: Does not work with lvm containers.

    If notify-send is not installed, then the script will
    print to standard output.
"
}

get_args()
{
    while (($# > 0)); do
        case "$1" in
            "--stdout")     stdout="true" ;;
            "-r"|"--raw")   raw="true" ;;
            "-d"|"--disk")  type="disk"; search="${2%/}" ;;
            "-m"|"--mount") type="mount"; search="${2%/}" ;;
            "-h"|"--help")  print_usage; exit ;;
        esac
        shift
    done

    ! type -p notify-send > /dev/null && \
        stdout="true"
}

main()
{
    lsblk_flags=(
        "--output"
        "KNAME,LABEL,PARTLABEL,FSTYPE,MOUNTPOINT"
        "--paths"
        "--pair"
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

    [[ "${raw}" ]] && {
        printf -v out "%s," \
            "${disk_name}" \
            "${disk_mount}" \
            "${disk_used} GiB" \
            "${disk_capacity} GiB" \
            "${disk_percent}%" \
            "${disk_device}"
        printf -v out "%s%s" "${out}" "${disk_part}"
        printf "%s\\n" "${out}"
        exit 0
    }

    [[ "${disk_name}" ]] && \
        title_parts+=("${disk_name}")

    [[ "${disk_mount}" ]] && \
        title_parts+=("(${disk_mount})")

    [[ "${disk_used}" ]] && \
        subtitle_parts+=("${disk_used}" "GiB")

    [[ "${disk_capacity}" ]] && \
        subtitle_parts+=("|" "${disk_capacity}" "GiB")

    [[ "${disk_percent}" ]] && \
        subtitle_parts+=("(${disk_percent}%)")

    [[ "${disk_device}" ]] && \
        message_parts+=("${disk_device}")

    [[ "${disk_part}" ]] && \
        message_parts+=("|" "${disk_part}")

    notify
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && \
    main "$@"

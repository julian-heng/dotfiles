#!/usr/bin/env bash

init_colors()
{
    for i in {0..7}; do
        printf -v "f[$i]" "%s" $'\e[3'"$i"'m'
    done
    reset=$'\e[0m'
}

print_line()
{
    local start_x="$1"
    local start_y="$2"
    local end_x="$3"
    local end_y="$4"
    local length_x="$((end_x - start_x))"
    local length_y="$((end_y - start_y))"
    local pat="$5"
    local i j

    printf "\\e[%d;%dH" "${start_x}" "${start_y}"

    for ((i = 0; i < length_y; i++)); do
        for ((j = 0; j < length_x; j++)); do
            printf "\\e[%d;%dH%s" "$((start_y + i))" "$((start_x + j))" "${pat}"
        done
    done
}

main()
{
    init_colors
    printf "%s" $'\e[2J'

    set1=(
        "${f[7]}" "${f[3]}"
        "${f[6]}" "${f[2]}"
        "${f[5]}" "${f[1]}"
        "${f[4]}"
    )

    set2=(
        "${f[4]}" "${f[0]}"
        "${f[5]}" "${f[0]}"
        "${f[6]}" "${f[0]}"
        "${f[7]}"
    )

    set3=(
        "${f[4]}" "${f[7]}"
        "${f[5]}"
    )

    for ((i = 0; i < ${#set1[@]}; i++)); do
        start_x="$((2 + (i * 4)))"
        start_y="1"
        end_x="$((start_x + 4))"
        end_y="$((start_y + 8))"
        print_line "${start_x}" "${start_y}" "${end_x}" "${end_y}" "${set1[$i]}█"
    done

    for ((i = 0; i < ${#set2[@]}; i++)); do
        start_x="$((2 + (i * 4)))"
        start_y="9"
        end_x="$((start_x + 4))"
        end_y="$((start_y + 1))"

        print_line "${start_x}" "${start_y}" "${end_x}" "${end_y}" "${set2[$i]}█"
    done

    for ((i = 0; i < ${#set3[@]}; i++)); do
        start_x="$((2 + (i * 5)))"
        start_y="10"
        end_x="$((start_x + 5))"
        end_y="$((start_y + 2))"

        print_line "${start_x}" "${start_y}" "${end_x}" "${end_y}" "${set3[$i]}█"
    done

    start_x="$((start_x + 5))"
    start_y="10"
    end_x="$((start_x + 13))"
    end_y="$((start_y + 2))"

    print_line "${start_x}" "${start_y}" "${end_x}" "${end_y}" "${f[0]}█"

    printf "%s\\n\\n" "${reset}"
}

main

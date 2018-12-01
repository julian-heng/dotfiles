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

    ((length_x = length_x == 0 ? length_x + 1 : length_x))
    ((length_y = length_y == 0 ? length_y + 1 : length_y))

    ((start_x += ${x_offset:-0}))
    ((start_y += ${y_offset:-0}))

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

    for ((i = 0; i < ${#f[@]}; i++)); do
        (
            x_offset="$((i * 14))"

            print_line "5" "3" "12" "12" "${f[$i]}█"
            print_line "4" "4" "13" "11" "${f[$i]}█"
            print_line "13" "6" "13" "9" "${f[$i]}█"
            print_line "7" "12" "10" "12" "${f[$i]}█"

            print_line "10" "4" "10" "11" "${f[0]}█"
            print_line "7" "10" "10" "10" "${f[0]}█"

            print_line "7" "2" "10" "2" "${f[7]}█"
            print_line "5" "3" "7" "3" "${f[7]}█"
            print_line "4" "4" "5" "4" "${f[7]}█"
            print_line "7" "4" "10" "4" "${f[7]}█"
            print_line "3" "5" "3" "9" "${f[7]}█"
            print_line "7" "4" "7" "10" "${f[7]}█"
            print_line "4" "9" "4" "11" "${f[7]}█"
            print_line "5" "11" "5" "11" "${f[7]}█"
        ) &
    done

    wait
    printf "%s\\n\\n\\n" "${reset}"
}

main

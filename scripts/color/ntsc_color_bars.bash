#!/usr/bin/env bash

init_colors()
{
    for i in {0..7}; do
        printf -v "b[$i]" "%s" $'\e[4'"$i"'m'
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
    local col="$5"
    local i j

    printf "\\e[%d;%dH" "${start_x}" "${start_y}"

    for ((i = 0; i < length_y; i++)); do
        for ((j = 0; j < length_x; j++)); do
            printf "\\e[%d;%dH%s " "$((start_y + i))" "$((start_x + j))" "${col}"
        done
    done
}

main()
{
    init_colors
    printf "%s" $'\e[2J'

    set1=(
        "${b[7]}" "${b[3]}"
        "${b[6]}" "${b[2]}"
        "${b[5]}" "${b[1]}"
        "${b[4]}"
    )

    set2=(
        "${b[4]}" "${b[0]}"
        "${b[5]}" "${b[0]}"
        "${b[6]}" "${b[0]}"
        "${b[7]}"
    )

    set3=(
        "${b[4]}" "${b[7]}"
        "${b[5]}" "${b[0]}"
    )

    for ((i = 0; i < 7; i++)); do
        start_x="$((2 + (i * 4)))"
        start_y="1"
        end_x="$((start_x + 4))"
        end_y="$((start_y + 8))"
        print_line "${start_x}" "${start_y}" "${end_x}" "${end_y}" "${set1[$i]}"
    done

    for ((i = 0; i < 7; i++)); do
        start_x="$((2 + (i * 4)))"
        start_y="9"
        end_x="$((start_x + 4))"
        end_y="$((start_y + 1))"

        print_line "${start_x}" "${start_y}" "${end_x}" "${end_y}" "${set2[$i]}"
    done

    for ((i = 0; i < 4; i++)); do
        start_x="$((2 + (i * 5)))"
        start_y="10"
        end_x="$((start_x + 5))"
        end_y="$((start_y + 2))"

        print_line "${start_x}" "${start_y}" "${end_x}" "${end_y}" "${set3[$i]}"
    done

    printf "%s\\n\\n" "${reset}"
}

main

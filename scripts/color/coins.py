#!/usr/bin/env python3

class colors:
    def __init__(self):
        self.fg_black = "\033[30m"
        self.fg_red = "\033[31m"
        self.fg_green = "\033[32m"
        self.fg_yellow = "\033[33m"
        self.fg_blue = "\033[34m"
        self.fg_purple = "\033[35m"
        self.fg_cyan = "\033[36m"
        self.fg_white = "\033[37m"
        self.fg = [
            self.fg_black,
            self.fg_red,
            self.fg_green,
            self.fg_yellow,
            self.fg_blue,
            self.fg_purple,
            self.fg_cyan,
            self.fg_white
        ]

        self.bg_black = "\033[40m"
        self.bg_red = "\033[41m"
        self.bg_green = "\033[42m"
        self.bg_yellow = "\033[43m"
        self.bg_blue = "\033[44m"
        self.bg_purple = "\033[45m"
        self.bg_cyan = "\033[46m"
        self.bg_white = "\033[47m"
        self.bg = [
            self.bg_black,
            self.bg_red,
            self.bg_green,
            self.bg_yellow,
            self.bg_blue,
            self.bg_purple,
            self.bg_cyan,
            self.bg_white
        ]

        self.reset = "\033[0m"

def print_box(x1, y1, x2, y2, x_off, y_off, pat):
    length_x = abs(x2 - x1)
    length_y = abs(y2 - y1)
    length_x = length_x if length_x != 0 else length_x + 1
    length_y = length_y if length_y != 0 else length_y + 1
    x1 += x_off
    y1 += y_off
    print(f"\033[{y1};{x1}H")
    for i in range(0, length_y, 1):
        for j in range(0, length_x, 1):
            print(f"\033[{y1 + i};{x1 + j}H{pat}")

def main():
    c = colors()
    print("\033[2J\033[H")
    count = 0

    for color in c.fg:
        x_off = 14 * count
        count += 1

        print_box(5, 3, 12, 12, x_off, 0, f"{color}█")
        print_box(4, 4, 13, 11, x_off, 0, f"{color}█")
        print_box(13, 6, 13, 9, x_off, 0, f"{color}█")
        print_box(7, 12, 10, 12, x_off, 0, f"{color}█")

        print_box(10, 4, 10, 11, x_off, 0, f"{c.fg_black}█")
        print_box(7, 10, 10, 10, x_off, 0, f"{c.fg_black}█")

        print_box(7, 2, 10, 2, x_off, 0, f"{c.fg_white}█")
        print_box(5, 3, 7, 3, x_off, 0, f"{c.fg_white}█")
        print_box(4, 4, 5, 4, x_off, 0, f"{c.fg_white}█")
        print_box(7, 4, 10, 4, x_off, 0, f"{c.fg_white}█")
        print_box(3, 5, 3, 9, x_off, 0, f"{c.fg_white}█")
        print_box(7, 4, 7, 10, x_off, 0, f"{c.fg_white}█")
        print_box(4, 9, 4, 11, x_off, 0, f"{c.fg_white}█")
        print_box(5, 11, 5, 11, x_off, 0, f"{c.fg_white}█")

    print(f"{c.reset}\n")

main()

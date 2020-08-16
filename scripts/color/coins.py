#!/usr/bin/env python3
# pylint: disable=invalid-name,too-few-public-methods,too-many-arguments

""" Prints coins """


class Colors:
    """ Contains the color ascii codes """

    def __init__(self):
        self.foreground = ["\033[3{}m".format(i) for i in range(8)]
        self.background = ["\033[4{}m".format(i) for i in range(8)]
        self.reset = "\033[0m"


def print_box(x1, y1, x2, y2, x_off, y_off, col, pat):
    """ Prints a box """
    length_x = abs(x2 - x1)
    length_y = abs(y2 - y1)
    length_x += 1 if length_x == 0 else 0
    length_y += 1 if length_y == 0 else 0

    if x2 < x1:
        x1, x2 = x2, x1
    if y2 < y1:
        y1, y2 = y2, y1

    x1 += x_off
    y1 += y_off

    print("\033[{};{}H{}".format(y1, x1, col))
    for i in range(length_y):
        print("\033[{};{}H{}".format(y1 + i, x1, pat * length_x))


def main():
    """ Main function """
    c = Colors()
    print("\033[2J\033[H")
    count = 0

    for color in c.foreground:
        x_off = 14 * count
        count += 1

        print_box(5, 3, 12, 12, x_off, 0, color, "█")
        print_box(4, 4, 13, 11, x_off, 0, color, "█")
        print_box(13, 6, 13, 9, x_off, 0, color, "█")
        print_box(7, 12, 10, 12, x_off, 0, color, "█")

        print_box(10, 4, 10, 11, x_off, 0, c.foreground[0], "█")
        print_box(7, 10, 10, 10, x_off, 0, c.foreground[0], "█")

        print_box(7, 2, 10, 2, x_off, 0, c.foreground[7], "█")
        print_box(5, 3, 7, 3, x_off, 0, c.foreground[7], "█")
        print_box(4, 4, 5, 4, x_off, 0, c.foreground[7], "█")
        print_box(7, 4, 10, 4, x_off, 0, c.foreground[7], "█")
        print_box(3, 5, 3, 9, x_off, 0, c.foreground[7], "█")
        print_box(7, 4, 7, 10, x_off, 0, c.foreground[7], "█")
        print_box(4, 9, 4, 11, x_off, 0, c.foreground[7], "█")
        print_box(5, 11, 5, 11, x_off, 0, c.foreground[7], "█")

    print("{}\n".format(c.reset))


if __name__ == "__main__":
    main()

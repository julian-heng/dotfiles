#!/usr/bin/env bash

resize()
{
    while [[ "$1" ]]; do
        chunkc tiling::window --use-temporary-ratio "$1" --adjust-window-edge "$2"
        shift; shift
    done
}

main()
{
    case "${1:0:1}" in
        "l") resize "$2" "west" "-$2" "east" ;;
        "r") resize "$2" "east" "-$2" "west" ;;
        "d") resize "$2" "south" "-$2" "north" ;;
        "u") resize "$2" "north" "-$2" "south" ;;
    esac
}

main "$@"

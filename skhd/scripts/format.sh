#!/usr/bin/env bash

function format
{
    local line
    while [[ "$1" ]]; do
        case "$1" in
            "|")
                [[ "$2" ]] && line+=" | $2"
                shift
            ;;
            "(")
                line+=" ("
                while [[ "$2" != ")" && "$1" ]]; do
                    [[ "$2" ]] && line+="$2"
                    shift
                done
            ;;
            *)
                line+="$1"
            ;;
        esac
        shift
    done
    printf "%s" "${line}"
}

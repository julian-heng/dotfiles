#!/usr/bin/env bash

function format
{
    local line
    while [[ "$1" ]]; do
        case "$1" in
            "(")
                line+=" ("
                while [[ "$2" != ")" && "$1" ]]; do
                    [[ "$2" ]] && line+="$2"
                    shift
                done
                line+=")"
                shift
            ;;
            "%")
                line+="$1"
            ;;
            *)
                if [[ "${line}" == "" ]]; then
                    line+="$1"
                else
                    line+=" $1"
                fi
            ;;
        esac
        shift
    done
    printf "%s" "${line}"
}

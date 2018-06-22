#!/usr/bin/env bash

function format
(
    while (($# > 0)); do
        case "$1" in
            "(")
                 if [[ "$2" ]]; then
                     while read -r i && [[ "${i}" != ")" ]]; do
                         ((count++))
                     done < <(printf "%s\\n" "$@")
                     ((count++))
                     : "${*:1:${count}}"
                     : " ${_// }"
                 else
                     while read -r i && [[ "${i}" != "|" ]]; do
                         ((count++))
                     done < <(printf "%s\\n" "$@")
                     ((count++))
                     : ""
                 fi
            ;;
            "|")
                if [[ "$2" ]]; then
                     word="|"
                     shift
                     while read -r i && [[ "${i}" != "(" && "${i}" != "|" ]]; do
                         if [[ "${i}" ]]; then
                             if [[ "${i}" == "%" ]]; then
                                 word+="${i}"
                             else
                                 word+=" ${i}"
                             fi
                         fi
                         ((count++))
                     done < <(printf "%s\\n" "$@")
                     : " ${word}"
                 else
                    while read -r i && [[ "${i}" != "|" ]]; do
                        ((count++))
                    done < <(printf "%s\\n" "$@")
                    : ""
                 fi
            ;;
            *)
                ((count++))
                [[ ! "$1" || "$1" == "%" || ! "${line}" ]] && : "$1" || \
                    : " $1"
            ;;
        esac
        line+="${_}"
        shift "${count}"
        count="0"
    done
    printf "%s" "${line}"
)

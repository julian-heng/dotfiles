#!/usr/bin/env bash

function format
(
    while (($# > 0)); do
        word=""
        count="0"
        case "$1" in
            "(")
                if [[ "$2" ]]; then
                    while read -r i; do
                        if [[ "${i}" != ")" ]]; then
                            ((count++))
                            word+="${i}"
                        else
                            break
                        fi
                    done < <(printf "%s\\n" "$@")
                    ((count++))
                    word=" ${word})"
                else
                    until read -r i && [[ "${i}" != ")" ]]; do
                        ((count++))
                    done < <(printf "%s\\n""$@")
                fi
            ;;
            "|")
                if [[ "$2" ]]; then
                    word="|"
                    count="1"
                    while read -r i; do
                        if [[ "${i}" =~ ^(\||\()$ ]]; then
                            break
                        elif [[ "${i}" == "%" ]]; then
                            ((count++))
                            word="${word}${i}"
                        else
                            ((count++))
                            word+="${word} ${i}"
                        fi
                    done < <(printf "%s\\n" "$@")
                    word=" ${word%*[[:space:]]}"
                else
                    until read -r i && [[ "${i}" != "|" ]]; do
                        ((count++))
                    done < <(printf "%s\\n" "$@")
                fi
            ;;
            *)
                ((count++))
                if [[ ! "$1" || "$1" == "%" || ! "${line}" ]]; then
                    word="$1"
                else
                    word=" $1"
                fi
            ;;
        esac
        line+="${word}"
        shift "${count}"
    done
    printf "%s" "${line}"
)

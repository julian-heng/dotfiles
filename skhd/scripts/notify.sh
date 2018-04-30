#!/usr/bin/env bash

display_notification() {
    /usr/bin/env osascript << EOF
        display notification "$3" with title "$1" subtitle "$2"
EOF
}

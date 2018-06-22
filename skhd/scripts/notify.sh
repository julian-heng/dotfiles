#!/usr/bin/env bash

function notify
(
    type -p osascript > /dev/null && {
        title="$1"
        subtitle="$2"
        content="$3"

        /usr/bin/env osascript << EOF
display notification "${content}" with title "${title}" subtitle "${subtitle}"
EOF
    }
)

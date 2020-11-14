command: "${HOME}/Library/Python/3.9/bin/sys-line '[{wm.desktop_index? {}{wm.app_name? | {}{wm.window_name?: {}}} }]'"

refreshFrequency: 750 # ms

render: (output) ->
  "#{output}"

style: """
  webkit-font-smoothing: antialiased
  color: #c5c8c6
  font: 13px inconsolata
  left: 5px
  bottom: 4px
"""

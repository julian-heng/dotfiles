command: "/usr/local/bin/bash ${HOME}/.dotfiles/ubersicht/wm.bash 2>/dev/null"

refreshFrequency: 750 # ms

render: (output) ->
  "#{output}"

style: """
  webkit-font-smoothing: antialiased
  color: #c5c8c6
  font: 14px inconsolata
  left: 5px
  bottom: 2.5px
"""

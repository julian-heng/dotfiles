command: "/usr/local/bin/bash ${HOME}/.dotfiles/scripts/mac/ubersicht/right.sh"

refreshFrequency: 5000 # ms

render: (output) ->
  "#{output}"

style: """
  webkit-font-smoothing: antialiased
  color: #c5c8c6
  font: 14px inconsolata
  right: 12px
  bottom: 5px
"""
